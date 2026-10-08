public class afterUploadPicture {

	public static void processDecodeURL(Map<Id, Contact> newContactMap, Map<Id, Contact> oldContactMap) {
		for (Contact con : newContactMap.values()) {
			System.Debug('we are in processDecodeURL');
			//if (newContactMap.get(con.Id).Picture_URL__c != null && (oldContactMap.get(con.Id).Picture_URL__c != newContactMap.get(con.Id).Picture_URL__c)) {
			//	Contact cn = [SELECT Id FROM Contact WHERE Id =: con.Id];
			//	System.Debug('URL :>> ' + newContactMap.get(con.Id).Picture_URL__c);
				//cn.Picture_Decoded_URL__c = EncodingUtil.urldecode(newContactMap.get(con.Id).Picture_URL__c, 'utf-8');
				//update cn;
			//}
		}
	}
}