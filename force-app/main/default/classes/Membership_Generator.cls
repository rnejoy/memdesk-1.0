public class Membership_Generator {
	//global variables
		public Boolean showPromptMember {get; set;}
		public Boolean showFinalScreen  {get; set;}

		public List<String> storecodes {get; set;}
		public List<String> storenames {get; set;}
		public List<String> campaignids {get; set;}
		public List<String> campaignnms {get; set;}

		public String  StoreCode    {get; set;}
		public String  StoreName    {get; set;}
		public String  CompanyName  {get; set;}
		public Integer Number2Gen   {get; set;}
		public String  TempNumber   {get; set;}
		public String  MemberType   {get; set;}
		public String  MemStartDate {get; set;}
		public Integer ExtendExpiry {get; set;}
		public String  RefNumber    {get; set;}
		public String  CampaignId   {get; set;}
		public String  Remarks      {get; set;}

	public Membership_Generator() {
		//get the store code of the store where manager is assigned
		User usr = [SELECT Store_Assigned__c FROM user WHERE Id =: UserInfo.getUserId()];
		StoreCode = usr.Store_Assigned__c;
		//get the list of stores to pass on to vfpage select element
		List<Store__c> storelist = [SELECT Code__c, Name__c FROM Store__c WHERE IsActive__c = true ORDER BY Name__c];
		storecodes = new String[] {};
		storenames = new String[] {};
		if (storelist.size() > 0) {
			for (Store__c st : storelist) {
				storecodes.add(st.Code__c); storenames.add(st.Name__c);
			}
		}
		List<Campaign> cmpgnlist = [SELECT Id, Name FROM Campaign WHERE Type = 'Prepaid Batch' AND IsActive = true ORDER BY Name];
		campaignids = new String[] {};
		campaignnms = new String[] {};
		if (cmpgnlist.size() > 0) {
			for (Campaign cm : cmpgnlist) {
				campaignids.add(cm.Id);
				campaignnms.add(cm.Name);
			}
		}
		showPromptMember = true;
		showFinalScreen  = false;
	}

	public void generateLeads() {
		System.Debug('we are in generateLeads!');

		Integer TempNum = 999999999;
		if (TempNumber != '') {
			TempNum = Integer.valueOf(TempNumber.replace('-', ''));
			//we decrement because our temporary number is inclusive
			TempNum--;
		}

		//we create the Master Batch record first bec we will use the SF recordId as control for the Lead batch
		//	we also pre-calculate the expiry date of the would-be member record once converted
		Date sDate = Date.valueOf(MemStartDate);
		Date mDate = Date.newInstance(sDate.year(), sDate.month(), sDate.day());
		Date eDate = mDate.addYears(1);
		eDate = eDate.addDays(ExtendExpiry);
		Membership_Batch_Master__c mbatch = new Membership_Batch_Master__c ();
			mbatch.Company_Name__c 		  	 = CompanyName;
			mbatch.Number_Members__c 		 = Number2Gen;
			mbatch.Temporary_Number_Start__c = TempNumber;
			mbatch.Membership_Type__c 		 = MemberType;
			mbatch.Membership_Start_Date__c  = Date.valueOf(MemStartDate);
			mbatch.Extended_Expiry_Days__c   = ExtendExpiry;
			mbatch.Membership_Expiry_Date__c = eDate;
			mbatch.Store_Signup_Code__c	  	 = StoreCode;
			mbatch.Store_Signup_Name__c	  	 = StoreName;
			mbatch.Reference_Number__c		 = RefNumber;
			if (CampaignId != '')
				mbatch.Campaign_Id__c 		 = Id.valueOf(CampaignId);
			mbatch.Remarks__c 				 = Remarks;
		insert mbatch;

		Lead[] leads = new List<Lead>();
		for (Integer i=1; i<=Number2Gen; i++) {
			//we assemble incremented Temporary Number
				String NewStr = '';
				if (TempNum != 999999999) {
					TempNum++;
					String TempStr = ('000000000' + String.valueOf(TempNum)).Right(9);
					List<String> arrTemp = new String[] {};
					Integer h = 0;

					for (Integer j=0; j<TempStr.length(); j++) {
						h++;
						NewStr = NewStr + TempStr.substring(j, j+1);
						if (h == 3) {
							h = 0;
							arrTemp.add(NewStr);
							NewStr = '';
						}
					}
					NewStr = String.join(arrTemp, '-');
					System.Debug('NewStr :>> ' + NewStr);
				}

			Lead ld = new Lead ();
				ld.Is_Generated__c = true;
				ld.Batch_Reference_Number__c = RefNumber;
				ld.Batch_Master_Id__c = mbatch.Id;

				ld.Store_Signup__c		= StoreName;
				ld.Store_Signup_Code__c = StoreCode;
				ld.Membership_Type__c 	= MemberType;
				ld.Customer_Type__c 	= 'Premium';
				ld.Customer_Sub_Type__c = 'Primary';
				ld.LeadSource	 		= 'Batch Upload';

				ld.FirstName 		 = 'ToBeUpdated';
				ld.LastName  		 = 'ToBeUpdated';
				ld.Birthdate__c 	 = Date.valueOf('1900-01-01');
				ld.Gender__c		 = 'ToBeUpdated';
				ld.Marital_Status__c = 'ToBeUpdated';
				ld.Nationality__c 	 = 'ToBeUpdated';
				ld.MobilePhone 	  	 = '99999999999';
				ld.Email 			 = 'ToBeUpdated@tbu.ph';
				ld.Occupation__c	 = 'ToBeUpdated';
				ld.Street__c		 = 'ToBeUpdated';
				ld.Province_Code__c  = 888;
				ld.Province__c       = 'ToBeUpdated';
				ld.City_Code__c 	 = 8888;
				ld.City__c			 = 'ToBeUpdated';
				ld.Barangay_Code__c  = 88888;
				ld.Barangay__c       = 'ToBeUpdated';

				ld.Remarks__c = CompanyName;
				ld.Company    = CompanyName;
				ld.Campaign_Id__c = CampaignId;

				ld.Temporary_Number__c 	   = NewStr;
				ld.Expected_Start_Date__c  = Date.valueOf(MemStartDate);
				ld.Expected_Expiry_Date__c = eDate;

			leads.add(ld);
		}
		insert leads;

		showPromptMember = false;
		showFinalScreen  = true;
	}
}