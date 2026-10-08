public class MR_Statistics {
	//public variables
		public Map<String, Map<String, String>> liclist {get; set;}
		public Map<String, Map<String, String>> orglist {get; set;}
		//public Map<String, Map<String, String>> reclist {get; set;}

		public String orgnumber {get; set;}
		//public String orgrecord {get; set;}

	public MR_Statistics() {
		getStats();
	}

	public void getStats() {
		//Organization User License Information
			List<UserLicense> lics = [SELECT LicenseDefinitionKey, TotalLicenses, UsedLicenses
										FROM UserLicense
										WHERE Status = 'Active'];

			liclist = new Map<String, Map<String, String>>();
			Map<String, String> interMap;

			if (lics.size() > 0) {
				Integer row = 0;
				for (UserLicense obj : lics) {
					System.Debug('obj.LicenseDefinitionKey :>> ' + obj.LicenseDefinitionKey);
					interMap = new Map<String, String>();
					interMap.put('LicenseDefinitionKey', String.valueOf(obj.LicenseDefinitionKey));
					interMap.put('TotalLicenses', String.valueOf(obj.TotalLicenses));
					interMap.put('UsedLicenses',  String.valueOf(obj.UsedLicenses));
					Integer bal = Integer.valueOf(obj.TotalLicenses) - Integer.valueOf(obj.UsedLicenses);
					interMap.put('BalLicenses', String.valueOf(bal));
					System.Debug('interMap.size() :>> ' + interMap.size());
					liclist.put(String.valueOf(row), interMap);
					row++;
				}

				System.Debug('liclist.size() :>> ' + liclist.size());
			}

		//Organic User Distribution
			List<AggregateResult> result = [SELECT count(id), ProfileId
												FROM User
												WHERE IsActive = true
												GROUP BY ProfileId];

			orglist = new Map<String, Map<String, String>>();
			List<Profile> pro = new List<Profile>();
			String pId;
			String strname;
			String stcount;
			Integer row = 0;
			Integer incount = 0;
			for (AggregateResult ar : result)  {
				pId = String.valueOf(ar.get('ProfileId'));
				pro = [SELECT Name FROM Profile WHERE Id =: pId AND UserLicense.Name = 'Salesforce'];
				if (pro.size() > 0) {
					strname = pro[0].Name;
					stcount = String.valueOf(ar.get('expr0'));
					incount += Integer.valueOf(stcount);

					System.debug('Profile: ' + strname + ' Id: ' + pId);
					System.debug('count: '   + stcount);

					interMap = new Map<String, String>();
					interMap.put('Profile', strname);
					interMap.put('Count', stcount);

					orglist.put(String.valueOf(row), interMap);
					row++;
				}
			}

			orgnumber = String.valueOf(incount);

		//Distribution of Membership Records By Source
			// reclist = new Map<String, Map<String, String>>();
			// incount = 0;
			// //total number of member records
			// AggregateResult aggres = [SELECT Count(Id) FROM Contact];
			// orgrecord = String.valueOf(Integer.valueOf(aggres.get('expr0')).format());
			// //records uploaded as baseline -- data migration
			// aggres = [SELECT Count(Id) FROM Contact WHERE Local_Id__c != null];
			// interMap = new Map<String, String>();
			// interMap.put('Row_Header', 'Baseline (Migration)');
			// stcount = String.valueOf(Integer.valueOf(aggres.get('expr0')).format());
			// interMap.put('Count', stcount);
			// row = 0;
			// reclist.put(String.valueOf(row), interMap);
			// incount += Integer.valueOf(aggres.get('expr0'));
			// //records created via Membership Desk
			// aggres = [SELECT Count(Id) FROM Contact WHERE Local_Id__c = null AND Created_By_MDU__c != null];
			// interMap = new Map<String, String>();
			// interMap.put('Row_Header', 'Membership Desk');
			// stcount = String.valueOf(Integer.valueOf(aggres.get('expr0')).format());
			// interMap.put('Count', stcount);
			// row++;
			// reclist.put(String.valueOf(row), interMap);
			// incount += Integer.valueOf(aggres.get('expr0'));
			// //records uploaded as delta (created as members in ANSI)
			// aggres = [SELECT Count(Id) FROM Contact WHERE Delta_Upload__c = true];
			// interMap = new Map<String, String>();
			// interMap.put('Row_Header', 'Delta Upload');
			// stcount = String.valueOf(Integer.valueOf(aggres.get('expr0')).format());
			// interMap.put('Count', stcount);
			// row++;
			// reclist.put(String.valueOf(row), interMap);
			// incount += Integer.valueOf(aggres.get('expr0'));
			// //records created as members in Landers.ph and Central.ph
			// aggres = [SELECT Count(Id) FROM Contact WHERE Local_Id__c = null AND Created_By_MDU__c = null AND Delta_Upload__c = false];
			// interMap = new Map<String, String>();
			// interMap.put('Row_Header', 'Online (Landers.ph/Central.ph)');
			// stcount = String.valueOf(Integer.valueOf(aggres.get('expr0')).format());
			// interMap.put('Count', stcount);
			// row++;
			// reclist.put(String.valueOf(row), interMap);
			// incount += Integer.valueOf(aggres.get('expr0'));
			// //total to check against total above
			// interMap = new Map<String, String>();
			// interMap.put('Row_Header', 'Total');
			// interMap.put('Count', String.valueOf(incount.format()));
			// row++;
			// reclist.put(String.valueOf(row), interMap);
	}
}