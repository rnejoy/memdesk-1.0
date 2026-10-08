public with sharing class ChinaBankService {

    /**
     * Push application details for a Contact (synchronous).
     * Returns response body (string).
     */
    public static String pushApplicationDetails(Id contactId) {
        // 1. Fetch contact (safe query)
        Contact con = [
            SELECT Id, membership_id__c, firstname, middlename, lastname, suffix,
                   birthdate__c, place_of_birth_city__c, gender__c, marital_status__c,
                   nationality__c, mother_maiden_name__c, educational_attainment__c,
                   car_ownership__c, cbcc_id_type__c, cbcc_id_number__c, mobilephone,
                   email, phone, street__c, barangay__c, city__c, province__c, country__c,
                   zip_code__c, Permanent_Address__c, employment_status__c, cbcc_occupation__c,
                   cbcc_major_industry__c, industry_class__c, industry_subclass__c,
                   cbcc_source_of_income__c, company_name__c, employment_tenure__c,
                   business_mobile_number__c, business_phone__c, business_email__c,
                   business_street__c, business_barangay__c, business_city__c,
                   business_province__c, business_country__c, business_address_zip_code__c,
                   cbcc_annual_income__c, preferred_billing_address__c
            FROM Contact
            WHERE Id = :contactId
            LIMIT 1
        ];

        // 2. Generate ref number and request datetime
        String requesterRef = chinabankReferenceUtil.generateReferenceNumber();
        String requestDT = Datetime.now().format('yyyy-MM-dd\'T\'HH:mm:ss.SSS');

        // 3. Build JSON payload using your builder (must accept these params)
        String jsonPayload = chinabankPayloadBuilder.buildPayload(con);

        // 4. Prepare API log object (not inserted yet)
        API_Integration_Logs__c apiLog = new API_Integration_Logs__c(
            Membership_ID__c = con.membership_id__c,
            Requester_Reference_Number__c = requesterRef,
            Request_Payload__c = jsonPayload,
            Status__c = 'Pending'
        );

        // 5. Get token
        String token = ChinaBankTokenService.getAccessToken();

        // 6. Call push endpoint
        ChinaBankConfigUtil.Config cfg = ChinaBankConfigUtil.getConfig();

        HttpRequest req = new HttpRequest();
        req.setEndpoint(cfg.pushUrl);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + token);

        req.setBody(jsonPayload);

        Http http = new Http();
        HttpResponse res;
        try {
            res = http.send(req);

            // populate log from response
            apiLog.Response_Code__c = String.valueOf(res.getStatusCode());
            apiLog.Response_Body__c = res.getBody();
            apiLog.Response_DateTime__c = Datetime.now().format('yyyy-MM-dd HH:mm:ss');
            apiLog.Status__c = (res.getStatusCode() >= 200 && res.getStatusCode() < 300) ? 'Success' : 'Failed';

            // Optionally parse responseContext and providerReferenceNumber if present in body
            try {
                Map<String, Object> respMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                if (respMap.containsKey('responseContext')) {
                    Map<String, Object> rc = (Map<String, Object>) respMap.get('responseContext');
                    if (rc != null && rc.containsKey('providerReferenceNumber')) {
                        apiLog.Provider_Reference_Number__c = String.valueOf(rc.get('providerReferenceNumber'));
                    }
                    if (rc != null && rc.containsKey('responseCode')) {
                        apiLog.Response_Code__c = String.valueOf(rc.get('responseCode'));
                    }
                    if (rc != null && rc.containsKey('responseDescription')) {
                        apiLog.Response_Description__c = String.valueOf(rc.get('responseDescription'));
                    }
                    if (rc != null && rc.containsKey('responseDateTime')) {
                        apiLog.Response_DateTime__c = String.valueOf(rc.get('responseDateTime'));
                    }
                }
            } catch (Exception e) {
                // ignore parse errors; we already saved raw body
            }

        } catch (Exception ex) {
            apiLog.Status__c = 'Error';
            apiLog.Error_Description__c = ex.getMessage();
            apiLog.Response_DateTime__c = Datetime.now().format('yyyy-MM-dd HH:mm:ss');
            res = null;
        }

        // 7. Insert log AFTER callout (safe)
        try {
            insert apiLog;
        } catch (Exception dmlEx) {
            // If even log insert fails, write debug only (do not throw to hide service from caller)
            System.debug('Failed to insert API log: ' + dmlEx.getMessage());
        }

        return (res != null ? res.getBody() : null);
    }

    /**
     * Call the GetResult endpoint. Accepts a requesterReferenceNumber or request body map.
     */
    public static String getResult(String requesterReferenceNumber) {
        ChinaBankConfigUtil.Config cfg = ChinaBankConfigUtil.getConfig();
        String token = ChinaBankTokenService.getAccessToken();

        // Build request body - follow third party spec; here minimal example
        Map<String, Object> requestBody = new Map<String, Object>{
            'requesterReferenceNumber' => requesterReferenceNumber
        };

        HttpRequest req = new HttpRequest();
        req.setEndpoint(cfg.getResultUrl);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setBody(JSON.serialize(requestBody));

        Http http = new Http();
        HttpResponse res;
        API_Integration_Logs__c apiLog = new API_Integration_Logs__c(
            Requester_Reference_Number__c = requesterReferenceNumber,
            Request_Payload__c = JSON.serialize(requestBody),
            Status__c = 'Pending'
        );

        try {
            res = http.send(req);
            apiLog.Response_Code__c = String.valueOf(res.getStatusCode());
            apiLog.Response_Body__c = res.getBody();
            apiLog.Status__c = (res.getStatusCode() >= 200 && res.getStatusCode() < 300) ? 'Success' : 'Failed';
            apiLog.Response_DateTime__c = Datetime.now().format('yyyy-MM-dd HH:mm:ss');
        } catch (Exception ex) {
            apiLog.Status__c = 'Error';
            apiLog.Error_Description__c = ex.getMessage();
            res = null;
        }

        try {
            insert apiLog;
        } catch (Exception dmlEx) {
            System.debug('Failed to insert API log: ' + dmlEx.getMessage());
        }

        return (res != null ? res.getBody() : null);
    }
}