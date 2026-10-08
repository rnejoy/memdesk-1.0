public class ChinabankTokenUtil {
    
    @TestVisible
    static Boolean bypassTestMock = false;

    public class TokenResult {
        public String accessToken;
        public API_Access_Token__c tokenRecord;
        public API_Integration_Logs__c logRecord;
    }

    public static TokenResult refreshTokenNoDML() {
        
        if (Test.isRunningTest() && !bypassTestMock) {
            TokenResult mockResult = new TokenResult();

            mockResult.accessToken = 'TEST_TOKEN';

            mockResult.tokenRecord = new API_Access_Token__c(
                Access_Token__c = 'TEST_TOKEN',
                Token_Expiry__c = DateTime.now().addHours(1).getTime() / 1000,
                Last_Updated_On__c = DateTime.now()
            );

            mockResult.logRecord = new API_Integration_Logs__c(
                Status__c = 'Success',
                Type__c = 'Token Request (Mock)'
            );

            return mockResult;
        }
        
        TokenResult result = new TokenResult();
        
        Chinabank_API_Setting__mdt cfg = Chinabank_API_Setting__mdt.getInstance('Chinabank_Token');

        String requestBody = 'grant_type=' + EncodingUtil.urlEncode(cfg.Grant_Type__c, 'UTF-8') +
                             '&client_id=' + EncodingUtil.urlEncode(cfg.Client_Id__c, 'UTF-8') +
                             '&client_secret=' + EncodingUtil.urlEncode(cfg.Client_Secret__c, 'UTF-8');
        if (!String.isBlank(cfg.Scope__c)) {
            requestBody += '&scope=' + EncodingUtil.urlEncode(cfg.Scope__c, 'UTF-8');
        }

        result.logRecord = new API_Integration_Logs__c(
            Endpoint__c = cfg.Token_URL__c,
            Request_Payload__c = requestBody,
            Type__c = 'Token Request'
        );

        HttpRequest req = new HttpRequest();
        req.setEndpoint(cfg.Token_URL__c);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setBody(requestBody);

        Http http = new Http();
        HttpResponse res;

        try {
            res = http.send(req);
            
            result.logRecord.Status__c = (res.getStatusCode() == 200) ? 'Success' : 'Failed';
            result.logRecord.Response_Body__c = res.getBody();

            if (res.getStatusCode() == 200) {
                Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                String newToken = (String) jsonMap.get('access_token');
                
                if (String.isBlank(newToken)) {
                     throw new CalloutException('Empty access_token received.');
                }

                Long expiresInSeconds = Long.valueOf(String.valueOf(jsonMap.get('expires_in')));
                Long nowTs = DateTime.now().getTime() / 1000;
                Long bufferSeconds = 300;
                Long expiryTs = nowTs + expiresInSeconds - bufferSeconds;

                API_Access_Token__c tokenRecord = [
                    SELECT Id, Access_Token__c, Token_Expiry__c
                    FROM API_Access_Token__c
                    WHERE Service_Name__c = 'Chinabank'
                    LIMIT 1
                ];
                tokenRecord.Access_Token__c = newToken;
                tokenRecord.Token_Expiry__c = expiryTs;
                tokenRecord.Last_Updated_On__c = DateTime.now();

                result.accessToken = newToken;
                result.tokenRecord = tokenRecord;
            } else {
                System.debug('Token Refresh Failed: ' + res.getStatus());
            }

        } catch (Exception e) {
            result.logRecord.Status__c = 'Failed';
            result.logRecord.Response_Body__c = e.getMessage();
            System.debug('Token Exception: ' + e.getMessage());
        }
        
        return result;
    }
    
    public static void refreshAndSaveToken() {
        TokenResult result = refreshTokenNoDML();
        
        if (Test.isRunningTest() && !bypassTestMock) {
            return;
        }
        
        if(result.logRecord != null) insert result.logRecord;
        if(result.tokenRecord != null) update result.tokenRecord;
    }
}