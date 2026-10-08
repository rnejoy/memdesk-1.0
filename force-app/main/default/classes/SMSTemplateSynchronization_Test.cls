@isTest
public class SMSTemplateSynchronization_Test {
	@testSetup public static void setup(){
        Insert new SMS_Template__c(Message_Body__c = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', 
                                   Message_Type__c = 'S', Template_Title__c = 'Title', Message_Length__c = '1000');
        Insert new SMS_Template__c(Message_Body__c = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', 
                                   Message_Type__c = 'S', Template_Title__c = 'Title', Message_Length__c = '600');
        Insert new SMS_Template__c(Message_Body__c = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', 
                                   Message_Type__c = 'S', Template_Title__c = 'Title', Message_Length__c = '500');
        Insert new SMS_Template__c(Message_Body__c = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', 
                                   Message_Type__c = 'S', Template_Title__c = 'Title', Message_Length__c = '300');
        Insert new SMS_Template__c(Message_Body__c = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', 
                                   Message_Type__c = 'S', Template_Title__c = 'Title', Message_Length__c = '100');
        Insert new SMS_Template__c(Message_Body__c = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', 
                                   Message_Type__c = 'S', Template_Title__c = 'Title', Message_Length__c = '700');
    }
    @isTest 
    public static void SMSTemplateSynchronization_Coverage(){
        List<Id> temp = new List<Id>();
        Test.setMock(HttpCalloutMock.class, new SMSTemplateSynchronization_Mock());
        Id tempId = [SELECT Id FROM SMS_Template__c WHERE Message_Length__c = '1000' LIMIT 1].Id;
        temp.add(tempId);
        Test.startTest();
        SMSTemplateSynchronization.synchronize(temp);
        Test.stopTest();
    }
    @isTest 
    public static void SMSTemplateSynchronization_Coverage2(){
        List<Id> temp = new List<Id>();
        Test.setMock(HttpCalloutMock.class, new SMSTemplateSynchronization_Mock());
        Id tempId = [SELECT Id FROM SMS_Template__c WHERE Message_Length__c = '600' LIMIT 1].Id;
        temp.add(tempId);
        Test.startTest();
        SMSTemplateSynchronization.synchronize(temp);
        Test.stopTest();
    }
    @isTest 
    public static void SMSTemplateSynchronization_Coverage3(){
        List<Id> temp = new List<Id>();
        Test.setMock(HttpCalloutMock.class, new SMSTemplateSynchronization_Mock());
        Id tempId = [SELECT Id FROM SMS_Template__c WHERE Message_Length__c = '500' LIMIT 1].Id;
        temp.add(tempId);
        Test.startTest();
        SMSTemplateSynchronization.synchronize(temp);
        Test.stopTest();
    }
    @isTest 
    public static void SMSTemplateSynchronization_Coverage4(){
        List<Id> temp = new List<Id>();
        Test.setMock(HttpCalloutMock.class, new SMSTemplateSynchronization_Mock());
        Id tempId = [SELECT Id FROM SMS_Template__c WHERE Message_Length__c = '300' LIMIT 1].Id;
        temp.add(tempId);
        Test.startTest();
        SMSTemplateSynchronization.synchronize(temp);
        Test.stopTest();
    }
    @isTest 
    public static void SMSTemplateSynchronization_Coverage5(){
        List<Id> temp = new List<Id>();
        Test.setMock(HttpCalloutMock.class, new SMSTemplateSynchronization_Mock());
        Id tempId = [SELECT Id FROM SMS_Template__c WHERE Message_Length__c = '100' LIMIT 1].Id;
        temp.add(tempId);
        Test.startTest();
        SMSTemplateSynchronization.synchronize(temp);
        Test.stopTest();
    }
    @isTest 
    public static void SMSTemplateSynchronization_Coverage6(){
        List<Id> temp = new List<Id>();
        Test.setMock(HttpCalloutMock.class, new SMSTemplateSynchronization_Mock());
        Id tempId = [SELECT Id FROM SMS_Template__c WHERE Message_Length__c = '700' LIMIT 1].Id;
        temp.add(tempId);
        Test.startTest();
        SMSTemplateSynchronization.synchronize(temp);
        Test.stopTest();
    }
}