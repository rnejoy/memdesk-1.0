@IsTest(SeeAllData=true)
private class MembershipBatchControllerTest {
    @isTest static void testCancelBatch() {        
        BatchMemberConfirm mbc = new BatchMemberConfirm();
        mbc.mbId = 'a0x5h00000bZZLjAAO';
        mbc.cancelBatch();
    }

    @isTest static void testConvertBatch() {
        Test.setMock(HttpCalloutMock.class, new ANSIMock());        
        
        BatchMemberConfirm mbc = new BatchMemberConfirm();
        mbc.mbId = 'a0x5h00000bZZLjAAO';
        mbc.confirmBatch();
        mbc.convertNow();
        
        
    }
    
    private class ANSIMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            String fullJson = '200';

            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'text/json');
            res.setBody(fullJson);
            res.setStatusCode(200);
            return res;
        }
    }    
}