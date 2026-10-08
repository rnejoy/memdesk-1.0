@isTest
public class afterLeadInserted_Test {
	@isTest 
    public static void insertLead_CodeCoverage () {
        Lead insertLead = new Lead();
        Campaign insertCampaign = new Campaign();
        insertCampaign.Campaign_Code__c = 123123123;
        insertCampaign.Name = 'Campaign Name';
        insert insertCampaign;
        
        insertLead.LastName = 'Sample';
        insertLead.Company = 'Sample Company';
        insertLead.Campaign_Id__c = insertCampaign.Id;
        Test.startTest();
        insert insertLead;
        Test.stopTest();
    }
}