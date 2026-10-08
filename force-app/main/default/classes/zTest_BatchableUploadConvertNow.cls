@isTest
public class zTest_BatchableUploadConvertNow {
    @isTest
    static void testMyController() {
		Campaign cmpgn = new Campaign();
		cmpgn.Campaign_Code__c = 123123123;
		cmpgn.Name = 'Campaign Name';
		insert cmpgn;

        Membership_Batch_Master__c mbatch = new Membership_Batch_Master__c();
        mbatch.Reference_Number__c = '123456';
        insert mbatch;

		Lead ld = new Lead();
		ld.Company  = 'TheCompany';
		ld.LastName = 'Testing';
		ld.Is_Generated__c = false;
		ld.Is_Confirmed__c = false;
		ld.Batch_Master_Id__c = mbatch.Id;
		ld.Campaign_Id__c     = cmpgn.Id;
		insert ld;

        Test.startTest();
            BatchableUploadConvertNow batch = new BatchableUploadConvertNow(mbatch.Id);
			batch.mbid = mbatch.Id;
            Database.executeBatch(batch);
        Test.stopTest();
    }
}