@isTest
public class afterUploadPicture_Test {
	@isTest 
    public static void uploadPicture_CodeCoverage () {
        Contact newContact = new Contact(LastName = 'Simeon');
        insert newContact;
        Contact updateContact = new Contact(Id = newContact.Id, Picture_URL__c = 'http://google.com');
        Test.startTest();
      	update updateContact;
        Test.stopTest();
    }
}