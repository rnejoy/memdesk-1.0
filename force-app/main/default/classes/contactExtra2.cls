public with sharing class contactExtra2 {

	@AuraEnabled
	public static Contact getContactRec(String conId) {
		System.Debug('conId :>> ' + conId);
		Contact con = [SELECT AccountId, Customer_Sub_Type__c
						FROM Contact
						WHERE Id =: conId];
		return con;
	}

	@AuraEnabled
	public static List<Contact> getRelatedRecs(String accId, String sType) {
		System.Debug('accId :>> ' + accId);
		System.Debug('sType :>> ' + sType);
		List<Contact> contacts = [SELECT Id,
						Name, Membership_ID__c,
						Membership_Start_Date__c, Membership_Expiry_Date__c,
						Picture_URL__c
					FROM Contact
					WHERE AccountId =: accId AND Customer_Sub_Type__c =: sType
					ORDER BY Membership_ID__c ASC];
		return contacts;
	}

	@AuraEnabled
	public static String getPictureURL() {
		return Label.Profile_Picture_URL;
	}
}