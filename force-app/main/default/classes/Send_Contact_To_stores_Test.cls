@isTest
public class Send_Contact_To_stores_Test {
    static testMethod void testPostCalloutStores(){
     List<Send_Contact_To_Stores.FlowInputs> reqList = new  List<Send_Contact_To_stores.FlowInputs>();
        Send_Contact_To_stores.FlowInputs fi = new Send_Contact_To_stores.FlowInputs();
     Account busAcc = new Account(Name = 'TestForMS', phone='4567890999');
        insert busAcc;
        Contact cont = new Contact(FirstName = 'Test', LastName = 'LastName', phone='4567890999', accountid = busAcc.id);
        insert(cont);
        fi.recordId =cont.Id;
        fi.memberId =cont.id;
        reqList.add(fi);
        Test.startTest();  
        Test.setMock(HttpCalloutMock.class, new Send_Contact_To_stores_Mock()); 
        list<string> result = Send_Contact_To_stores.SendMemberDetailsToStores(reqlist);
        reqlist.remove(0);
        result = Send_Contact_To_stores.SendMemberDetailsToStores(reqlist);
        Test.stopTest();
        
}
}