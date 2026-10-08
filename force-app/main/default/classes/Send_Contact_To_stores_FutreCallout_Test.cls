@isTest
public class Send_Contact_To_stores_FutreCallout_Test {
    static testMethod void testPostCalloutSuccess() {
        
        List<Send_Contact_To_stores_FutreCallout.FlowInputs > reqList = new  List<Send_Contact_To_stores_FutreCallout.FlowInputs >();
        Send_Contact_To_stores_FutreCallout.FlowInputs fi = new Send_Contact_To_stores_FutreCallout.FlowInputs();
        
        List<Account> acts = new List<Account>();
        Account myAcc = new Account(Name='TestAct', phone='1001231234');
        acts.add(myAcc);
        
        Account busAcc = new Account(Name = 'TestForMS', phone='4567890999');
        acts.add(busAcc);
        insert acts;
        Contact cont = new Contact(FirstName = 'Test', LastName = 'LastName', phone='4567890999', accountid = busAcc.id);
        insert(cont);
        
        string  contactId = cont.Id;
        fi.recordId =cont.Id;
       
        reqList.add(fi);
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new Send_Contact_To_stores_Mock());  
        Send_Contact_To_stores_FutreCallout.SendMemberDetailsToStores(contactId);
        apiErrorHandler.retriggerFailed();
        Test.stopTest();
        
    }
     static testMethod void testPostCalloutFailure() {
        
        List<Send_Contact_To_stores_FutreCallout.FlowInputs > reqList = new  List<Send_Contact_To_stores_FutreCallout.FlowInputs >();
        Send_Contact_To_stores_FutreCallout.FlowInputs fi = new Send_Contact_To_stores_FutreCallout.FlowInputs();
        
        List<Account> acts = new List<Account>();
        Account myAcc = new Account(Name='TestAct', phone='1001231234');
        acts.add(myAcc);
        
        Account busAcc = new Account(Name = 'TestForMS', phone='4567890999');
        acts.add(busAcc);
        insert acts;
        Contact cont = new Contact(FirstName = 'Test', LastName = 'LastName', phone='4567890999', accountid = busAcc.id);
        insert(cont);
        
        string  contactId = cont.Id;
        fi.recordId =cont.Id;
       
        reqList.add(fi);
        Test.startTest();
        Test.setMock(HttpCalloutMock.class,  new send_Contacts_To_Stores_Mock_Failure());  
        Send_Contact_To_stores_FutreCallout.SendMemberDetailsToStores(contactId);
        apiErrorHandler.retriggerFailed();
        Test.stopTest();        
         
    }
     static testMethod void testPostCalloutSuccessBulk() {
        
        List<Account> acts = new List<Account>();
        Account myAcc = new Account(Name='TestActp', phone='1001231234');
        acts.add(myAcc);
        
        Account busAcc = new Account(Name = 'TestForMSp', phone='4567890999');
        acts.add(busAcc);
        insert acts;
        Contact cont = new Contact(FirstName = 'Testp', LastName = 'LastName', phone='4567890999', accountid = busAcc.id);
        insert(cont);
        
        string  contactId = cont.Id;
         set<Id> conSet = new Set<Id>();
         conset.add(contactId);
           Test.startTest();
        Test.setMock(HttpCalloutMock.class, new Send_Contact_To_stores_Mock()); 
        SendBulkMembersDataToAllStores.SendMembers(conset);
        apiErrorHandler.retriggerFailed();
        Test.stopTest();
        
         
    }
     static testMethod void testPostCalloutFailureBulk() {        
        List<Account> acts = new List<Account>();
        Account myAcc = new Account(Name='TestActf', phone='1001231234');
        acts.add(myAcc);
        
        Account busAcc = new Account(Name = 'TestForMSf', phone='4567890999');
        acts.add(busAcc);
        insert acts;
        Contact cont = new Contact(FirstName = 'Testf', LastName = 'LastName', phone='4567890999', accountid = busAcc.id);
        insert(cont);
        
        string  contactId = cont.Id;
         set<Id> conSet = new Set<Id>();
        conset.add(contactId);
           Test.startTest();
        Test.setMock(HttpCalloutMock.class,  new send_Contacts_To_Stores_Mock_Failure());  
        SendBulkMembersDataToAllStores.SendMembers(conset);
        apiErrorHandler.retriggerFailed();
        Test.stopTest();
        
         
    }
    
}