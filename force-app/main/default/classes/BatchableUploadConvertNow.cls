public class BatchableUploadConvertNow implements Database.Batchable<sObject>,  Database.stateful {

	public Integer leadCount = 0;
	public String mbId;

	public BatchableUploadConvertNow(String strParam) {
		mbId = strParam;
	}

	public Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator([SELECT Id FROM Lead WHERE Batch_Master_Id__c =: mbId]);
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
				ld.Is_Converted__c     = true;
			}
			update leads;
		}
	}

	public void finish(Database.BatchableContext BC) {
		system.debug('Total Lead records: ' + leadCount);
		Membership_Batch_Master__c mbatch = [SELECT Id, Name FROM Membership_Batch_Master__c WHERE Id =: mbId];
		System.Debug('mbatch.Name :>> ' + mbatch.Name);
		mbatch.Converted_Date__c = System.now();
		mbatch.Status__c         = 'Converted';
		update mbatch;
	}
}