@isTest
public class contactExtra_Test {
	// @isTest(SeeAllData=true)
		// public static void contactExtra1_CodeCoverage () {
		//     // Lead insertLead = new Lead();
		//     // insertLead.LastName = 'Sample';
		//     // insertLead.Company = 'Sample Company';
		//     // insert insertLead;

		//     // Database.LeadConvert lc = new Database.LeadConvert();
		// 	// lc.setLeadId(insertLead.id);

		//     // LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
		//     // lc.setConvertedStatus(convertStatus.MasterLabel);

		//     // Database.LeadConvertResult lcr = Database.convertLead(lc);

		//     Contact getContact = [SELECT Id FROM Contact WHERE  LIMIT 1];
		//     Test.startTest();
		//     contactExtra1.getContactRec(getContact.Id);
		//     contactExtra1.getLeadRec(getContact.Id);
		//     Test.stopTest();
		// }

    @isTest(SeeAllData=true)
	public static void contactExtra2_CodeCoverage () {
        // Lead insertLead = new Lead();
        // insertLead.LastName = 'Sample';
        // insertLead.Company = 'Sample Company';
        // insert insertLead;

        // Database.LeadConvert lc = new Database.LeadConvert();
		// lc.setLeadId(insertLead.id);

        // LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
        // lc.setConvertedStatus(convertStatus.MasterLabel);

        // Database.LeadConvertResult lcr = Database.convertLead(lc);

        Contact getContact = [SELECT Id FROM Contact LIMIT 1];
        Account getAccount = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        contactExtra2.getContactRec(getContact.Id);
        contactExtra2.getRelatedRecs(getAccount.Id, getContact.Id);
		contactExtra2.getPictureURL();
        Test.stopTest();
    }
}