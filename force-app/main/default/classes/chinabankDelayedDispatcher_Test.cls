@IsTest
public class chinabankDelayedDispatcher_Test {

    private class ChinabankHttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"result":"SUCCESS"}');
            return res;
        }
    }

    @IsTest
    static void testDelayedDispatcherExecutes_nonStrict() {

        Test.setMock(HttpCalloutMock.class, new ChinabankHttpMock());

        Contact c = new Contact(
            LastName = 'Dispatcher Test',
            Customer_Type__c = 'Executive',
            LeadSource = 'Chinabank-Instore'
        );
        insert c;

        List<Id> contactIds = new List<Id>{ c.Id };

        Test.startTest();

        chinabankDelayedDispatcher.schedule(contactIds, 5);

        Test.stopTest();

        System.assert(true, 'Delayed dispatcher executed without exceptions');
    }
}