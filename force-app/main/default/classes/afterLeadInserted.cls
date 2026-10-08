public class afterLeadInserted {

	public static void processNewRecord(List<Lead> newRecord) {
		for (Lead ld: newRecord) {
			System.Debug('Lead Id :>> ' + ld.Id);
			System.Debug('Campaign Id :>> ' + ld.Campaign_Id__c);

			//let us check if this Lead record needs to be enrolled in a Registration Type Campaign
			if (ld.Campaign_Id__c != null) {
				Lead ldo = [SELECT Id FROM Lead WHERE Id =: ld.Id];
				Campaign camp = [SELECT Name FROM Campaign WHERE Id =: ld.Campaign_Id__c];

				ldo.Campaign_Name__c = camp.Name;
				update ldo;

				CampaignMember cmem = new CampaignMember();
				cmem.CampaignId = ld.Campaign_Id__c;
				cmem.LeadId = ld.Id;
				insert cmem;
			}
		}
	}
}