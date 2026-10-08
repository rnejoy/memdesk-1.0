@isTest
public class Test_Web2CaseService{
    @isTest 
    public static void Web2Case_CodeCoverage(){
        
        Account newAccount = new Account(Name = 'MASTER CASE ACCOUNT');
        insert newAccount;
        insert new Entitlement(AccountId = newAccount.id, Name = 'Entitled');
        insert new Contact(LastName = 'Snap', AccountId = newAccount.Id, Membership_ID__c = '12394349348141');
        
        Test.startTest();
        
        Web2CaseService.myInputs myInput = new Web2CaseService.myInputs();
        myInput.membershipId = '12394349348141';
		myInput.fullName = 'Art Simone';
		myInput.emailAdd = 'email.email@test.com.ph';
		myInput.enqrType = 'Inquiry';
		myInput.esubTyp1 = 'Ask a question';
		myInput.orderNum = '1000';
		myInput.message = 'Message';
        Web2CaseService.receiveCase(myInput);
        
        myInput = new Web2CaseService.myInputs();
		myInput.fullName = 'Ms Simone';
		myInput.emailAdd = 'email.email@test.com.ph';
		myInput.enqrType = 'Inquiry';
		myInput.esubTyp1 = 'Ask a question';
		myInput.orderNum = '1000';
		myInput.message = 'Message';
        myInput.attachment = 'bWFoIG5hbWVzIHNpbW9uZSBhbmQgYW0gaGVyZSBmb3IgZCB0cm93bg==';
        myInput.fileName = 'sample.txt';
        Web2CaseService.receiveCase(myInput);
        
        //This should be error. Filename is required.
        myInput = new Web2CaseService.myInputs();
		myInput.fullName = 'Ms Simonye';
		myInput.emailAdd = 'email.email@test.com.ph';
		myInput.enqrType = 'Inquiry';
		myInput.esubTyp1 = 'Ask a question';
		myInput.orderNum = '1000';
		myInput.message = 'Message';
        myInput.attachment = 'bWFoIG5hbWVzIHNpbW9uZSBhbmQgYW0gaGVyZSBmb3IgZCB0cm93bg==';
        myInput.fileName = null;
        Web2CaseService.receiveCase(myInput);
        
        Test.stopTest();
    }
}