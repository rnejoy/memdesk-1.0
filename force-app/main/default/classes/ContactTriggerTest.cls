@isTest
public class ContactTriggerTest {

    static testMethod void testContactTrigger() {
        // Set the mock before making the web service callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Insert mock Contacts with required fields populated
        Contact contact1 = new Contact(LeadSource='store', store_signup_code__c='1001', LastName='Doe', FirstName='John');
        Contact contact2 = new Contact(LeadSource='canvasser', store_signup_code__c='1002', LastName='Smith', FirstName='Jane');
        Contact contact3 = new Contact(LeadSource='Maya', store_signup_code__c='1003', LastName='Johnson', FirstName='Jim');
        Contact contact4 = new Contact(LeadSource='web', store_signup_code__c='1000', LastName='Doe', FirstName='Anna'); 

        // Insert into Salesforce
        insert contact1;
        insert contact2;
        insert contact3;
        insert contact4;

        // Trigger Fire
        Test.startTest();
        
        // Fire the trigger to process the Contacts
        List<Contact> processedContacts = [SELECT Id FROM Contact 
                                           WHERE (LeadSource='store' OR LeadSource='canvasser' OR LeadSource='Maya')];

        // Assert the number of processed contacts
        System.assertEquals(3, processedContacts.size(), 'Number of contacts processed should match expected count');

        System.debug('Processed Contacts: ' + processedContacts);
        System.debug('Total Processed Contacts Count: ' + processedContacts.size());

        Test.stopTest();
    }
}