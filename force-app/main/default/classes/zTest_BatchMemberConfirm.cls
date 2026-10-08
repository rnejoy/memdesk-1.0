@isTest
public class zTest_BatchMemberConfirm {

	@isTest
	static void testMyController() {
		Campaign cmpgn = new Campaign();
		cmpgn.Campaign_Code__c = 123123123;
		cmpgn.Name = 'Campaign Name';
		insert cmpgn;

		Membership_Batch_Master__c mbatch = new Membership_Batch_Master__c();
		mbatch.Company_Name__c = 'TheCompany';
		mbatch.Store_Signup_Code__c = '1040';
		insert mbatch;

		Lead ld = new Lead();
		ld.Company  = 'TheCompany';
		ld.LastName = 'Testing';
		ld.Is_Generated__c = true;
		ld.Is_Confirmed__c = true;
		ld.Batch_Master_Id__c = mbatch.Id;
		ld.Campaign_Id__c     = cmpgn.Id;
		ld.Expected_Start_Date__c  = Date.valueOf('2023-05-01');
		ld.Expected_Expiry_Date__c = Date.valueOf('2024-05-01');
		ld.Birthdate__c = Date.valueOf('1990-01-01');
		insert ld;

		Store__c stor = new Store__c();
		stor.Code__c = '1040';
		stor.Machine_Number__c = '99';
		stor.Sequence_Number__c = 0;
		insert stor;

		Test.StartTest();
			System.Debug('we are in testMyController');
			BatchMemberConfirm controller = new BatchMemberConfirm();
			controller.mbId = mbatch.Id;

			controller.confirmBatch();
			controller.cancelBatch();

		Test.StopTest();
	}
}