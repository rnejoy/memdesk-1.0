@isTest
public class apiErrorHandlerSchedulerTest {
    public static testMethod void apiErrorHandlerSchTest(){
    String cronExp = '0 0 0 ? * * *';
        Account acc = new Account(name = 'test account');
        insert acc;
        account acq = [select id, name from account where name = 'test account'];
        List<contact> conlist = new List<contact>();
        Contact con1 = new contact(AccountId = acq.id  , LastName = 'con1' , membership_id__c = '12323');
        Contact con2 = new contact(AccountId = acq.id , LastName = 'con2' , membership_id__c = '125445');
        conList.add(con1);
        conList.add(con2);
        
        insert conList;
        contact cont1 = [select id, name from contact where membership_id__c = '12323'];
        contact cont2 = [select id, name from contact where membership_id__c = '125445'];
        
        List<api_log__c>apllist = new List<api_log__c>();
        api_log__c apl1 = new api_log__c(associated_member__c = cont1.id , response_codes__c = '200');
         api_log__c apl2 = new api_log__c(associated_member__c = cont1.id , response_codes__c = '200');
        apllist.add(apl1);
        apllist.add(apl2);
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new Send_Contact_To_stores_Mock());  
        Id JobId = System.schedule('schedulertest' , cronExp , new apiErrorHandlerScheduler());
        Test.stopTest();
     
    
        

}
}