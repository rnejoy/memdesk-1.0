@isTest
public class zTest_BatchableUploadConvert {
    @isTest
    static void testMyController() {
		Campaign cmpgn = new Campaign();
		cmpgn.Campaign_Code__c = 123123123;
		cmpgn.Name = 'Campaign Name';
		insert cmpgn;

        Membership_Batch_Master__c mbatch = new Membership_Batch_Master__c();
        mbatch.Reference_Number__c = '123456';
		mbatch.Status__c = 'Confirmed';
        insert mbatch;

		Lead ld = new Lead();
		ld.Company  = 'TheCompany';
		ld.LastName = 'Testing';
		ld.Is_Generated__c = true;
		ld.Is_Confirmed__c = true;
		ld.Is_Converted__c = false;
		ld.Batch_Master_Id__c = mbatch.Id;
		ld.Campaign_Id__c     = cmpgn.Id;
		insert ld;

        Test.startTest();
            BatchableUploadConvert batch = new BatchableUploadConvert();
            Database.executeBatch(batch);
        Test.stopTest();
    }
}