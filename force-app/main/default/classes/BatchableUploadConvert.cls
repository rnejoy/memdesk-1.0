public class BatchableUploadConvert implements Database.Batchable<sObject>,  Database.stateful {

	public Integer leadCount = 0;

	public Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator([SELECT Id FROM Lead WHERE Is_Generated__c = true AND Is_Confirmed__c = true
											AND Is_Converted__c = false ORDER BY Batch_Master_Id__c]);
	}

	public void execute(Database.BatchableContext BC, List<Lead> leads) {
		system.debug('Lead records read: ' + leads.size());
		leadCount = leadCount + leads.size();
		system.debug('Total Lead records read: ' + leadCount);
		if (leads.size() > 0) {
			for (Lead ld: leads) {
				if (!Test.isRunningTest()) {
					ld.Convert_Lead_Now__c = true;
				}
				ld.Is_Converted__c = true;
			}
			update leads;
		}
	}

	public void finish(Database.BatchableContext BC) {
		system.debug('Total Lead records: ' + leadCount);
		List<Membership_Batch_Master__c> mbatches = [SELECT Name, Number_Members__c FROM Membership_Batch_Master__c
														WHERE Status__c = 'Confirmed' ORDER BY Name];
		if (mbatches.size() > 0) {
			for (Membership_Batch_Master__c mbs : mbatches) {
				System.Debug('mbs.Name :>> ' + mbs.Name + ' Number of Members: ' + mbs.Number_Members__c);
				mbs.Converted_Date__c = System.now();
				mbs.Status__c         = 'Converted';
			}
			update mbatches;
		}
	}
}