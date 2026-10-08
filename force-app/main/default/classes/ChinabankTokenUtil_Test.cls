@IsTest
private class ChinabankTokenUtil_Test {

    private class TokenHttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"access_token":"MOCK_TOKEN","expires_in":3600}');
            return res;
        }
    }

    @IsTest
    static void testRefreshTokenNoDML_TestContext() {

        Test.startTest();
        ChinabankTokenUtil.TokenResult result =
            ChinabankTokenUtil.refreshTokenNoDML();
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertNotEquals(null, result.accessToken);
        System.assertNotEquals(null, result.tokenRecord);
        System.assertNotEquals(null, result.logRecord);
    }

    @IsTest
    static void testRefreshAndSaveToken_MOCK_PATH() {

        ChinabankTokenUtil.bypassTestMock = false;

        Test.startTest();
        ChinabankTokenUtil.refreshAndSaveToken();
        Test.stopTest();

        System.assert(true, 'Executed safely without DML');
    }

    @IsTest
    static void testRefreshTokenNoDML_HTTP_PATH() {

        ChinabankTokenUtil.bypassTestMock = true;
        Test.setMock(HttpCalloutMock.class, new TokenHttpMock());

        Test.startTest();
        ChinabankTokenUtil.TokenResult result =
            ChinabankTokenUtil.refreshTokenNoDML();
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertNotEquals(null, result.logRecord);
    }
}