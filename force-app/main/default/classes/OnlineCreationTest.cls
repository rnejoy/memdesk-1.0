@isTest
public class OnlineCreationTest {

    @isTest
    public static void testSendPayload() {
        // Create a test Contact
        Contact testContact = new Contact(
            FirstName = 'RyeJohndasd',
            LastName = 'Doetestasdsas',
            Email = 'johndoetest@example.com',
            membership_id__c = '1234552467899',  // Replace with a valid membership ID
            Membership_Expiry_Date__c = Date.today().addDays(30)  // Replace with a valid expiry date
        );
        insert testContact;

        // Set up the mock HTTP response using MockHttpResponseGenerator
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Call the sendPayload method
        Test.startTest();
        OnlineCreation.sendPayload(testContact.Id);
        Test.stopTest();

        // Perform assertions or checks based on the mock response if needed
    }
}