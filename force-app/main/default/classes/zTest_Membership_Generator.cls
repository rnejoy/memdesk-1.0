@isTest
public class zTest_Membership_Generator {

	@isTest
	static void testMyController() {
		Store__c stor = new Store__c();
		stor.Code__c = '1040';
		stor.Name__c = 'Alabang';
		insert stor;

		Campaign cmpgn = new Campaign();
		cmpgn.Campaign_Code__c = 123123123;
		cmpgn.Name = 'Campaign Name';
		insert cmpgn;

		Test.StartTest();
			System.Debug('we are in testMyController');
			Membership_Generator controller = new Membership_Generator();
			controller.StoreCode   = '1040';
			controller.StoreName   = 'Alabang';
			controller.CompanyName = 'TheCompany';
			controller.Number2Gen  = 1;
			controller.TempNumber  = '000-000-000';
			controller.MemberType  = 'Member';
			controller.MemStartDate = '2023-12-12';
			controller.ExtendExpiry = 0;
			controller.RefNumber	= '1234567890';
			controller.Remarks	 	= 'Test Script';
			controller.CampaignId   = cmpgn.Id;
			controller.generateLeads();

		Test.StopTest();
	}
}