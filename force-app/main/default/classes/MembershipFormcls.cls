public class MembershipFormcls {

	@auraenabled
	public static Store__c fetchQRSVersion(String recId) {
		System.Debug('we are in fetchQRSVersion');
		System.Debug('recId :>> ' + recId);

		Store__c store = new Store__c();
		store = [SELECT IsActive__c,
					QR_Code_Version__c,
					Code__c,
					Name__c
				FROM Store__c
				WHERE Id =: recId];
		return store;
	}

	@auraenabled
	public static Canvasser__c fetchQRCVersion(String recId) {
		System.Debug('we are in fetchQRCVersion');
		System.Debug('recId :>> ' + recId);

		Canvasser__c canva = new Canvasser__c();
		canva = [SELECT IsActive__c,
					QR_Code_Version__c,
					C_Code__c,
					Name__c,
					Store_Assignment__c,
					Store_Assignment_Code__c
				FROM Canvasser__c
				WHERE Id =: recId];
		return canva;
	}

	@auraenabled
	public static List<String> fetchNationals() {
		List<String> nationals = new List<String>();
		nationals = getPicklist('Lead', 'Nationality__c');
		return nationals;
	}

	@auraenabled
	public static List<Store__c> fetchStores() {
		List<Store__c> stores =
				[SELECT Code__c, Name__c FROM Store__c ORDER BY Name__c];
		return stores;
	}

	@auraenabled
	public static List<Province__c> fetchProvinces() {
		List<Province__c> provinces =
				[SELECT Code__c, Name__c FROM Province__c ORDER BY Name__c];
		return provinces;
	}

	@auraenabled
	public static List<City__c> fetchCities(Integer Pcode) {
		System.Debug('Pcode :>> ' + Pcode);
		List<City__c> cities =
				[SELECT Code__c, Name__c FROM City__c
					WHERE Province__c =: Pcode
					ORDER BY Name__c];
		return cities;
	}

	@auraenabled
	public static List<Barangay__c> fetchBarangs(Integer Ccode) {
		System.Debug('Ccode :>> ' + Ccode);
		List<Barangay__c> barangs =
				[SELECT Code__c, Name__c FROM Barangay__c
					WHERE City__c =: Ccode
					ORDER BY Name__c];
		return barangs;
	}

	@auraenabled
	public static Id createLeadRecord(Lead leadObj){
		System.Debug('leadObj :>> ' + leadObj);
		upsert leadObj;

		return leadObj.Id;
	}

	public static List<String> getPicklist(String zObjType, String zPicklist) {
		List<String> PickValues = new List<String>();

		SObjectType objType = Schema.getGlobalDescribe().get(zObjType);							//get Object
		Map<String, Schema.SObjectField> objFields = objType.getDescribe().fields.getMap();		//get the Fields
		SObjectField fieldName = objFields.get(zPickList);										//select the picklist
		Schema.DescribeFieldResult fieldResult = fieldName.getDescribe();						//get Describe
		fieldResult = fieldResult.getSObjectField().getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();						//get the values as a list
		//we are getting the labels instead of getValue() because the getValue() gets the API Name
		for (Schema.PicklistEntry pl : ple) {													//we iterate
			if (pl.isActive()) {																//and only get the active ones
				PickValues.add(pl.getLabel());
			}
		}

		return PickValues;
	}
}