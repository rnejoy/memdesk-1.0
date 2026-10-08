/**
 * @author : Anoori Muhammed / Satish Lokinindi
 * @date : 15-01-2022
 * @description : Test class For CaseTrigger and Helper Class
 * @last modified on  : 03-02-2022
 * @last modified by  : Anoori Muhammed / Satish Lokinindi

**/
@isTest
public class caseTrigger_Test{
 /*********************************************************************************************** 
 * @description : SetUp method
 **********************************************************************************************/
    @TestSetup
    public static void createData(){
        //Insert Account
        Account acc=new Account();
        acc.Name='TestAccount';
        insert acc;
        
        //Insert Contact
        Contact con=new Contact();
        con.FirstName='testx';
        con.LastName='testy';
        con.AccountId=acc.Id;
        insert con;
        
        //Insert Case
        Case cas=new Case();
        cas.ContactId=con.Id;
        cas.Status='New';
        cas.Origin='Email';
        cas.Reason='Delivery Status';
        cas.Type='Cancellation';
        cas.Sub_Type_1__c ='Account';
        cas.Sub_Type_2__c= 'Agent';
        //Added email 19/07/2022
        cas.SuppliedEmail = 'test.test@test.com';
        //
        insert cas;
        
        Fulfillment_Team__c cs = new Fulfillment_Team__c();
        cs.Name='Fullfillment';
        cs.Email__c ='donotreply@example.com';
        insert cs;
        
        // Added Reason for Critical 19/07/2022
        Case_Critical_Priority_Level_2_Reasons__c ccplr2 = new Case_Critical_Priority_Level_2_Reasons__c();
        ccplr2.Level_2_Value__c = 'Account';
        ccplr2.Name='Account';
        insert ccplr2;
        Case_Critical_Priority_Level_1_Reasons__c ccplr1 = new Case_Critical_Priority_Level_1_Reasons__c();
        ccplr1.Level_1_Value__c = 'Critical';
        ccplr1.Name='Critical';
        insert ccplr1;
		Case_Critical_Priority_Level_3_Reasons__c ccplr3 = new Case_Critical_Priority_Level_3_Reasons__c();
        ccplr3.Level_3_Value__c = 'Agent';
        ccplr3.Name='Agent';
        insert ccplr3;
        // end
        
        Case_High_Priority_Level2_Reasons__c chplr2 = new Case_High_Priority_Level2_Reasons__c();
        chplr2.Level_2_Value__c = 'Account';
        chplr2.Name='Account';
        insert chplr2;
        Case_High_Priority_Level1_Reasons__c chplr1 = new Case_High_Priority_Level1_Reasons__c();
        chplr1.Level_1_Value__c = 'High';
        chplr1.Name='High';
        insert chplr1;
		Case_High_Priority_Level3_Reasons__c chplr3 = new Case_High_Priority_Level3_Reasons__c();
        chplr3.Level_3_Value__c = 'Agent';
        chplr3.Name='Agent';
        insert chplr3;
        
        Case_Low_Priority_Level2_Reasons__c clplr2 = new Case_Low_Priority_Level2_Reasons__c();
        clplr2.Level_2_Value__c = 'Account';
        clplr2.Name='Account';
        insert clplr2;
        Case_Low_Priority_Level1_Reasons__c clplr1 = new Case_Low_Priority_Level1_Reasons__c();
        clplr1.Level_1_Value__c = 'Low';
        clplr1.Name='Low';
        insert clplr1;
		Case_Low_Priority_Level3_Reasons__c clplr3 = new Case_Low_Priority_Level3_Reasons__c();
        clplr3.Level_3_Value__c = 'Agent';
        clplr3.Name='Agent';
        insert clplr3;
        
        Case_Medium_Priority_Level1_Reasons__c cmplr1 = new Case_Medium_Priority_Level1_Reasons__c();
        cmplr1.Level_1_Value__c = 'Medium';
        cmplr1.Name='Medium';
        insert cmplr1;
        Case_Medium_Priority_Level2_Reasons__c cmplr2 = new Case_Medium_Priority_Level2_Reasons__c();
        cmplr2.Level_2_Value__c = 'Account';
        cmplr2.Name='Account';
        insert cmplr2;
		Case_Medium_Priority_Level3_Reasons__c cmplr3 = new Case_Medium_Priority_Level3_Reasons__c();
        cmplr3.Level_3_Value__c = 'Agent';
        cmplr3.Name='Agent';
        insert cmplr3;

        Membership_Team__c membTeamSetting = new Membership_Team__c();
        membTeamSetting.Name = '1000 - Landers.ph';
        membTeamSetting.Email__c = 'anoori.muhammed@criticalriver.com';
        Insert membTeamSetting;

        Action_Settings__c actionSetting =  new Action_Settings__c();
        actionSetting.Name = 'Cancellations_Cancellation_Policy';
        actionSetting.Key__c = 'Cancellation:Cancellation Policy:How to cancel an order';
        actionSetting.Action_Value__c = 'Check order status if applicable for order cancellation';
        Insert actionSetting;
		
    }
 /*********************************************************************************************** 
 * @description : method to send Esclations to department
 **********************************************************************************************/
    @isTest public static void sendEscalationEmailTest(){
        Case cs = [SELECT Id FROM Case WHERE Origin='Email'];
        cs.Escalate_To__c = 'Fullfillment';
        update cs;
    }
 /*********************************************************************************************** 
 * @description : test method to check status change on owner assignment
 **********************************************************************************************/
    @isTest public static void changeCaseStatusTest(){
        
        Case cs = [SELECT Id FROM Case WHERE Origin='Email'];
        Test.startTest();
        
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User usr = new User(FirstName = 'ABC', 
                            lastName = 'XYZ', 
                            email ='sampletestuser@gmail.com', 
                            Username ='sampletestuser@Landers.com', 
                            EmailEncodingKey = 'ISO-8859-1', 
                            Alias = 'suser', 
                            TimeZoneSidKey = 'America/Los_Angeles', 
                            LocaleSidKey = 'en_US', 
                            LanguageLocaleKey = 'en_US', 
                            ProfileId = p.Id
                        );
        
            System.runAs(usr){
            Group tktManagerQ= new Group(Name='Ticket_manager', type='Queue');
            insert tktManagerQ;
            cs.OwnerId = UserInfo.getUserID();
            Update cs;
        }
        Test.stopTest();
    }
/*********************************************************************************************** 
 * @description : test method to handle/cover email messaging
 **********************************************************************************************/
    @isTest public static void EsclationScenarioHandleEmail(){
        Case cs = [SELECT Id FROM Case WHERE Origin='Email'];
        cs.Escalate_To__c = 'Fullfillment';
        cs.Escalated__c =true;
        Test.startTest();
        try{update cs;}catch (exception e){}
        Test.stopTest();
    }

    /*********************************************************************************************** 
 * @description : test method to handle/cover notifyInstoreBuyingTeams
 **********************************************************************************************/
    @isTest public static void notifyInstoreBuyingTeamsTest(){
        Case cs = [SELECT Id FROM Case WHERE Origin='Email'];
        cs.Origin='Web';
        cs.Store__c = '1000 - Landers.ph';
        cs.Reason = 'Problem with Item Received';
        Test.startTest();
        try{update cs;}catch (exception e){}
        Test.stopTest();
    }

    /*********************************************************************************************** 
 * @description : test method to handle/cover caseActionUpsert
 **********************************************************************************************/
@isTest public static void caseActionUpsertTest(){
        Case cs = [SELECT Id FROM Case WHERE Origin='Email'];
        cs.Reason = 'Cancellation';
        cs.Sub_Type_1__c = 'Cancellation Policy';
        cs.Sub_Type_2__c = 'How to cancel an order';
        Test.startTest();
        try{update cs;}catch (exception e){}
        Test.stopTest();
    }
    /*********************************************************************************************** 
 * @description : test method to handle/cover updateCasePriority 19/06/2022
 **********************************************************************************************/
	@isTest public static void updateCasePriorityTest(){
        List<Case> cases = new List<Case>();
    	Case cs = new Case();
        cs.Reason = 'Critical';
        cs.Sub_Type_1__c = 'Account';
        cs.Sub_Type_2__c = 'Agent';
        cases.add(cs);
        
        cs = new Case();
        cs.Reason = 'High';
        cs.Sub_Type_1__c = 'Account';
        cs.Sub_Type_2__c = 'Agent';
        cases.add(cs);
        
        cs = new Case();
        cs.Reason = 'Medium';
        cs.Sub_Type_1__c = 'Account';
        cs.Sub_Type_2__c = 'Agent';
        cases.add(cs);
        
        cs = new Case();
        cs.Reason = 'Low';
        cs.Sub_Type_1__c = 'Account';
        cs.Sub_Type_2__c = 'Agent';
        cases.add(cs);
        
        cs = new Case();
        cs.Reason = 'Critical';
        cs.Sub_Type_1__c = 'Account';
        cases.add(cs);
        
        cs = new Case();
        cs.Reason = 'High';
        cs.Sub_Type_1__c = 'Account';
        cases.add(cs);
        
        cs = new Case();
        cs.Reason = 'Medium';
        cs.Sub_Type_1__c = 'Account';
        cases.add(cs);
        
        cs = new Case();
        cs.Reason = 'Low';
        cs.Sub_Type_1__c = 'Account';
        cases.add(cs);
    	
        Test.startTest();
        try{insert cases;}catch (exception e){}
        Test.stopTest();
    }
}