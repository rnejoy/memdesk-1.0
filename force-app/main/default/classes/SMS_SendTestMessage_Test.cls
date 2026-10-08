@isTest
public class SMS_SendTestMessage_Test {
    @testSetup public static void setup(){
        Test.setMock(HttpCalloutMock.class, new SMSTemplateSynchronization_Mock());
        Insert new SMS_Template__c(Message_Body__c = 'Hello', Message_Type__c = 'S');
    }
    @isTest 
    public static void SMS_SendTestMessage_Coverage(){
        PageReference myVfPage = Page.SMS_TestMessage;
		Test.setCurrentPage(myVfPage);
        ApexPages.currentPage().getParameters().put('id',[SELECT Id FROM SMS_Template__c LIMIT 1].Id);
        SMS_SendTestMessage sms = new SMS_SendTestMessage();
        sms.custom1 = '1';
        sms.custom2 = '2';
        sms.custom3 = '3';
        sms.moblstr = '09882221111';
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SMSTemplateSynchronization_Mock());
        sms.sendSMS();
        Test.stopTest();
    }
}