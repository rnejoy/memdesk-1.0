@IsTest
private class ChinabankTokenService_Test {

    @IsTest
    static void testGetTokenRecord_TestContext() {
        API_Access_Token__c token = chinabankTokenService.getTokenRecord();

        System.assertNotEquals(null, token, 'Token should not be null in test context');
        System.assertEquals('TEST_TOKEN', token.Access_Token__c, 'Token value must match test token');
        System.assert(token.Token_Expiry__c > 0, 'Token expiry must be set in test context');
    }

    @IsTest
    static void testGetAccessToken_TestContext() {
        String accessToken = chinabankTokenService.getAccessToken();

        System.assertEquals('TEST_TOKEN', accessToken, 'Access token must match test token');
    }

    @IsTest
    static void testGetTokenRecord_RealData() {

        chinabankTokenService.bypassTestToken = true;

        API_Access_Token__c tokenRec = new API_Access_Token__c(
            Service_Name__c = 'Chinabank',
            Access_Token__c = 'REAL_TOKEN',
            Token_Expiry__c = Decimal.valueOf(DateTime.now().addHours(1).getTime() / 1000)
        );
        insert tokenRec;

        API_Access_Token__c token = chinabankTokenService.getTokenRecord();

        System.assertEquals('REAL_TOKEN', token.Access_Token__c, 'Should return the real token record');
    }

    @IsTest
    static void testGetAccessToken_Expired() {
        chinabankTokenService.bypassTestToken = true;

        API_Access_Token__c expiredToken = new API_Access_Token__c(
            Service_Name__c = 'Chinabank',
            Access_Token__c = 'EXPIRED_TOKEN',
            Token_Expiry__c = Decimal.valueOf(DateTime.now().addHours(-1).getTime() / 1000)
        );
        insert expiredToken;

        String accessToken = chinabankTokenService.getAccessToken();

        System.assert(accessToken == null || accessToken != 'EXPIRED_TOKEN', 'Expired token should not be returned as valid');
    }

    @IsTest
    static void testGetAccessToken_Valid() {
        chinabankTokenService.bypassTestToken = true;

        API_Access_Token__c validToken = new API_Access_Token__c(
            Service_Name__c = 'Chinabank',
            Access_Token__c = 'VALID_TOKEN',
            Token_Expiry__c = Decimal.valueOf(DateTime.now().addHours(2).getTime() / 1000)
        );
        insert validToken;

        String accessToken = chinabankTokenService.getAccessToken();

        System.assert(accessToken != null, 'Should return a valid token');
    }
}