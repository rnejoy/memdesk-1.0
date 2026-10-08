public with sharing class chinabankAPIService {
    
    public class ResultWrapper {
        public Contact contactToUpdate;
        public API_Access_Token__c tokenToUpdate;
        public List<API_Integration_Logs__c> logs = new List<API_Integration_Logs__c>();
    }
    
    public static String generateSessionId() {
        String prefix = 'API';
        Long timestamp   = Datetime.now().getTime();
        Long randomLong1 = Crypto.getRandomLong();
        Long randomLong2 = Crypto.getRandomLong();
        String seed = timestamp + '-' + randomLong1 + '-' + randomLong2;
        Blob digest = Crypto.generateDigest('SHA-256', Blob.valueOf(seed));
        String hash = EncodingUtil.convertToHex(digest).toUpperCase();
        return prefix + hash.substring(0, 29);
    }

    @AuraEnabled
    public static String sendToBank(Id contactId) {
        
        ChinaBank_API_Setting__mdt cfg = chinabankConfig.getConfig();
        
        Contact con = [
            SELECT membership_id__c, firstname, middlename, lastname, suffix,
                   birthdate__c, place_of_birth_city__c, gender__c,
                   marital_status__c, nationality__c, educational_attainment__c,
                   mother_maiden_name__c, car_ownership__c, cbcc_id_type__c,
                   cbcc_id_number__c, mobilephone, email, phone, street__c,
                   barangay__c, city__c, province__c, country__c, zip_code__c,
                   Permanent_Address__c, employment_status__c, cbcc_occupation__c,
                   cbcc_major_industry__c, industry_class__c, industry_subclass__c,
                   cbcc_source_of_income__c, company_name__c, employment_tenure__c,
                   business_mobile_number__c, business_phone__c, business_email__c,
                   business_street__c, business_barangay__c, business_city__c,
                   business_province__c, business_country__c,
                   business_address_zip_code__c, cbcc_annual_income__c,
                   preferred_billing_address__c
            FROM Contact WHERE Id = :contactId LIMIT 1
        ];

        API_Access_Token__c tokenToUpdate = null;
        API_Integration_Logs__c tokenLogToInsert = null;
        API_Integration_Logs__c bankLogToInsert = null;
        
        String responseBody = '';
        String accessToken = null;
        
        if (Test.isRunningTest()) {
            accessToken = 'TEST_TOKEN';
        }
        
        API_Access_Token__c dbToken = chinabankTokenService.getTokenRecord();
        Long nowTs = DateTime.now().getTime() / 1000;
        Boolean isExpired = (dbToken.Token_Expiry__c == null || dbToken.Token_Expiry__c <= nowTs);
        if(!isExpired) accessToken = dbToken.Access_Token__c;

        Integer maxRetries = 2;

        for(Integer attempt = 0; attempt <= maxRetries; attempt++) {
            
            if(String.isBlank(accessToken) || isExpired) {
                ChinabankTokenUtil.TokenResult res = ChinabankTokenUtil.refreshTokenNoDML();
                if(res.accessToken != null) {
                    accessToken = res.accessToken;
                    tokenToUpdate = res.tokenRecord; 
                    tokenLogToInsert = res.logRecord; 
                    isExpired = false;
                } else {
                    bankLogToInsert = res.logRecord; 
                    break; 
                }
            }

            String requestDT = Datetime.now().format('MM/dd/yyyy hh:mm a', 'Asia/Manila');
            String sessionId = generateSessionId();
            String authorizationHeader = 'Bearer ' + accessToken;
            
            String rawJson = chinabankPayloadBuilder.buildPayload(con);
            String encryptedJson = chinabankPayloadEncryptor.encryptPayload(rawJson);
            String finalRequestJson = wrapEncryptedPayload(encryptedJson);
            
            String signature = chinabankSignatureService.generateSignature(
                authorizationHeader, cfg.Partner_Id__c, sessionId, requestDT, finalRequestJson, cfg.Hash_Key__c
            );

            HttpRequest req = new HttpRequest();
            req.setEndpoint(cfg.Push_URL__c);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('x-cb-partner-id', cfg.Partner_Id__c);
            req.setHeader('x-cb-session-id', sessionId);
            req.setHeader('x-cb-request-dt', requestDT);
            req.setHeader('Ocp-Apim-Subscription-Key', cfg.Subscription_Key__c);
            req.setHeader('Authorization', authorizationHeader);
            req.setHeader('x-cb-signature', signature);
            req.setHeader('x-cb-clientcert', cfg.Client_Cert__c);
            req.setBody(finalRequestJson);
            req.setTimeout(120000);

            HttpResponse res;
            Integer responseCode = 0;
            String responseDescription = '';
            
            try {
                Http http = new Http();
                res = http.send(req);
                responseBody = res.getBody();
                responseCode = res.getStatusCode();
                responseDescription = res.getStatus();
            } catch (Exception ex) {
                responseBody = ex.getMessage();
                responseDescription = 'Exception: ' + ex.getMessage();
            }

            if (responseCode == 401) {
                isExpired = true; 
                accessToken = null; 
                
                if(attempt == maxRetries) {
                     bankLogToInsert = createLog(contactId, requestDT, rawJson, finalRequestJson, responseBody, '', '', String.valueOf(responseCode), responseDescription, sessionId, 'Push Details');
                }
                continue; 
            }
            
            String decryptedResponse = '';
            String decryptedAppError = '';
            try {
                Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
                Map<String, Object> body = (Map<String, Object>) root.get('body');
                String encryptedResponseData = (String) body.get('responseData');
                Object appErrorObj = body.get('appError');
                decryptedResponse = ChinabankPayloadDecryptor.decrypt(encryptedResponseData);
                if (appErrorObj != null && String.valueOf(appErrorObj) != 'null') {
                    decryptedAppError = ChinabankPayloadDecryptor.decrypt(String.valueOf(appErrorObj));
                }
            } catch (Exception e) {
                decryptedResponse = 'DECRYPT_PARSE_ERROR: ' + e.getMessage();
            }

            String applicationRefNo = null;
            try {
                Map<String, Object> parsedResponse = (Map<String, Object>) JSON.deserializeUntyped(decryptedResponse);
                if (parsedResponse.containsKey('responseHeader')) {
                    Map<String, Object> header = (Map<String, Object>) parsedResponse.get('responseHeader');
                    if (header.containsKey('responseContext')) {
                        Map<String, Object> context = (Map<String, Object>) header.get('responseContext');
                        applicationRefNo = (String) context.get('providerReferenceNumber');
                    }
                }
                if (applicationRefNo == null && parsedResponse.containsKey('responseBody')) {
                    Map<String, Object> rb = (Map<String, Object>) parsedResponse.get('responseBody');
                    applicationRefNo = (String) rb.get('applicationRefNo');
                }
            } catch(Exception ex) {}


            bankLogToInsert = createLog(contactId, requestDT, rawJson, finalRequestJson, responseBody, decryptedResponse, decryptedAppError, String.valueOf(responseCode), responseDescription, sessionId, 'Push Details');
            
            if(responseCode > 0) {
                if (applicationRefNo != null) {
                    try {
                        Contact updateCon = new Contact(Id = contactId, Chinabank_Application_Reference_Number__c = applicationRefNo);
                        update updateCon; 
                    } catch(Exception e) { System.debug('Sched Error: ' + e.getMessage()); }
                }
                break; 
            }
        }

        List<SObject> logsToInsert = new List<SObject>();
        
        if (tokenLogToInsert != null) logsToInsert.add(tokenLogToInsert);
        if (bankLogToInsert != null) logsToInsert.add(bankLogToInsert);
        
        if (!logsToInsert.isEmpty()) insert logsToInsert;
        if (tokenToUpdate != null) update tokenToUpdate;

        return responseBody;
    }
    
    @TestVisible
    public static ResultWrapper getApprovalStatusInternal(Id contactId, String applicationRefNo, String existingToken) {
        ResultWrapper rw = new ResultWrapper();
        ChinaBank_API_Setting__mdt cfg;
        String accessToken = existingToken;
        
        if (String.isBlank(accessToken)) {
            API_Access_Token__c dbToken = chinabankTokenService.getTokenRecord();
            Long nowTs = DateTime.now().getTime() / 1000;
            if (dbToken != null && dbToken.Token_Expiry__c != null && dbToken.Token_Expiry__c > nowTs) {
                accessToken = dbToken.Access_Token__c;
            }
        }
    
        if (String.isBlank(accessToken)) {
            ChinabankTokenUtil.TokenResult res = ChinabankTokenUtil.refreshTokenNoDML();
            if (res.accessToken != null) {
                accessToken = res.accessToken;
                rw.tokenToUpdate = res.tokenRecord;
                if (res.logRecord != null) rw.logs.add(res.logRecord);
            }
        }
    
        if (Test.isRunningTest()) {
            Map<String, Object> mockConfig = new Map<String, Object>{
                'getResult_URL__c' => 'http://mock-url.com',
                'Partner_Id__c' => 'MOCK_PARTNER',
                'Subscription_Key__c' => 'MOCK_SUB',
                'Hash_Key__c' => 'MOCK_HASH',
                'Client_Cert__c' => 'MOCK_CERT'
            };
            cfg = (ChinaBank_API_Setting__mdt) JSON.deserialize(JSON.serialize(mockConfig), ChinaBank_API_Setting__mdt.class);
        } else {
            cfg = [SELECT getResult_URL__c, Partner_Id__c, Subscription_Key__c, Hash_Key__c, Client_Cert__c FROM ChinaBank_API_Setting__mdt WHERE DeveloperName = 'Chinabank_GetResult' LIMIT 1];
        }
        
        String statusResultToUpdate = null;
        Integer maxRetries = 2;
        Boolean isExpired = false; 
    
        for(Integer attempt = 0; attempt <= maxRetries; attempt++) {
            if(String.isBlank(accessToken) || isExpired) {
                ChinabankTokenUtil.TokenResult res = ChinabankTokenUtil.refreshTokenNoDML();
                if(res.accessToken != null) {
                    accessToken = res.accessToken;
                    rw.tokenToUpdate = res.tokenRecord;
                    if(res.logRecord != null) rw.logs.add(res.logRecord);
                    isExpired = false;
                } else {
                    if(res.logRecord != null) rw.logs.add(res.logRecord);
                    break;
                }
            }
    
            String requestDT = Datetime.now().format('MM/dd/yyyy hh:mm a', 'Asia/Manila');
            String sessionId = generateSessionId();
            String authorizationHeader = 'Bearer ' + accessToken;
            String rawJson = chinabankPayloadBuilder.buildGetResultPayload(applicationRefNo);
            String encryptedJson = chinabankPayloadEncryptor.encryptPayload(rawJson);
            String finalRequestJson = wrapEncryptedPayloadGetResult(encryptedJson);
            String signature = chinabankSignatureService.generateSignature(authorizationHeader, cfg.Partner_Id__c, sessionId, requestDT, finalRequestJson, cfg.Hash_Key__c);
    
            HttpRequest req = new HttpRequest();
            req.setEndpoint(cfg.getResult_URL__c);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('x-cb-partner-id', cfg.Partner_Id__c);
            req.setHeader('x-cb-session-id', sessionId);
            req.setHeader('x-cb-request-dt', requestDT);
            req.setHeader('Ocp-Apim-Subscription-Key', cfg.Subscription_Key__c);
            req.setHeader('Authorization', authorizationHeader);
            req.setHeader('x-cb-signature', signature);
            req.setHeader('x-cb-clientcert', cfg.Client_Cert__c);
            req.setBody(finalRequestJson);
            req.setTimeout(120000);
    
            HttpResponse res;
            String responseBody;
            Integer responseCode = 0;
            String responseDescription;
    
            try {
                Http http = new Http();
                res = http.send(req);
                responseBody = res.getBody();
                responseCode = res.getStatusCode();
                responseDescription = res.getStatus();
            } catch (Exception ex) {
                responseBody = ex.getMessage();
                responseDescription = 'Exception: ' + ex.getMessage();
            }
    
            if (responseCode == 401) {
                isExpired = true;
                accessToken = null;
                if(attempt == maxRetries) {
                    rw.logs.add(createLog(contactId, requestDT, rawJson, finalRequestJson, responseBody, '', '', String.valueOf(responseCode), responseDescription, sessionId, 'Get Result'));
                }
                continue;
            }
    
            String decryptedResponse = '';
            try {
                Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
                if(root.containsKey('body')) {
                    Map<String, Object> body = (Map<String, Object>) root.get('body');
                    String encryptedResponseData = (String) body.get('responseData');
                    decryptedResponse = ChinabankPayloadDecryptor.decrypt(encryptedResponseData);
                    Map<String, Object> resultJson = (Map<String, Object>) JSON.deserializeUntyped(decryptedResponse);
                    if (resultJson.containsKey('responseBody')) {
                        Map<String, Object> rb = (Map<String, Object>) resultJson.get('responseBody');
                        if (rb.containsKey('result')) statusResultToUpdate = (String) rb.get('result');
                    }
                }
            } catch (Exception e) {
                decryptedResponse = 'DECRYPT/PARSE_ERROR: ' + e.getMessage();
            }
    
            if (String.isBlank(statusResultToUpdate)) statusResultToUpdate = 'PENDING';
            rw.logs.add(createLog(contactId, requestDT, rawJson, finalRequestJson, responseBody, decryptedResponse, '', String.valueOf(responseCode), responseDescription, sessionId, 'Get Result'));
            break; 
        }
    
        if (statusResultToUpdate != null) {
            rw.contactToUpdate = new Contact(Id = contactId, Chinabank_Application_Status__c = statusResultToUpdate);
            if (statusResultToUpdate == 'APPROVED') {
                rw.contactToUpdate.Chinabank_Approval_Date__c = Date.today().addDays(-1);
            }
        }
        return rw;
    }
    
    @future(callout=true)
    public static void getApprovalStatus(Id contactId, String applicationRefNo) {
        ResultWrapper rw = getApprovalStatusInternal(contactId, applicationRefNo, null);
        if (rw.contactToUpdate != null) update rw.contactToUpdate;
        if (rw.tokenToUpdate != null) update rw.tokenToUpdate;
        if (!rw.logs.isEmpty()) insert rw.logs;
    }

    private static API_Integration_Logs__c createLog(Id contactId, String requestDT, String rawJson, String encryptedPayload, String responseBody, String decryptedResponse, String appError, String code, String description, String sessionId, String type) {
        return new API_Integration_Logs__c(
            Membership_id__c = contactId,
            Request_DateTime__c = requestDT,
            Request_Payload__c = rawJson,
            Encrypted_Payload__c = encryptedPayload,
            Response_Body__c = responseBody,
            Decrypted_Response_Body__c = decryptedResponse,
            Response_App_Error__c = appError,
            Response_Code__c = code,
            Response_Description__c = description,
            Session_Id__c = sessionId,
            Status__c = (code == '200' ? 'Success' : 'Failed'),
            Type__c = type
        );
    }
    
    private static String wrapEncryptedPayloadGetResult(String encryptedBase64) {
        return '{\n    "requestData": "' + encryptedBase64 + '"\n}';
    }

    private static String wrapEncryptedPayload(String encryptedBase64) {
        return '{\n    "requestData": "' + encryptedBase64 + '"\n}';
    }
}