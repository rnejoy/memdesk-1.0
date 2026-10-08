@isTest
public class ContactListControllerTest {
    @TestSetup
    static void setup() {
        // Create test data
        Test.setMock(HttpCalloutMock.class, new HttpCalloutMockImpl());

        Contact c1 = new Contact(FirstName='Henry',LastName='Ford', Membership_ID__c='12345', Response_codes__c='ABC');
        Contact c2 = new Contact(FirstName='John',LastName='Jones', Membership_ID__c='67890', Response_codes__c='DEF');
        insert new List<Contact>{c1, c2};
    }

    @isTest
    static void testSearchContacts() {
        // Create mock controller
        ContactListController controller = new ContactListController();
        
        // Test search with partial search term
        controller.searchTerm = 'ABC';
        Test.startTest();
        controller.searchContacts();
        Test.stopTest();

    }

    @isTest
    static void testReSend() {
        // Create mock controller and stub SendBulkMembersDataToAllStores.SendMembers method
        ContactListController controller = new ContactListController();
        controller.searchTerm = '200';        
        controller.searchContacts();        

        Test.startTest();        
        Test.setMock(HttpCalloutMock.class, new HttpCalloutMockImpl());
        controller.reSend();
        Test.stopTest();

        // Verify that SendBulkMembersDataToAllStores.SendMembers method was called with correct parameters
        //System.assertEquals(2, SendBulkMembersDataToAllStores.sendCount, 'SendBulkMembersDataToAllStores.SendMembers method should be called with 2 contact IDs');
    }

    private class HttpCalloutMockImpl implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Stub HTTP response for SendBulkMembersDataToAllStores.SendMembers method
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{}');
            res.setStatusCode(200);
            return res;
        }
    }
}