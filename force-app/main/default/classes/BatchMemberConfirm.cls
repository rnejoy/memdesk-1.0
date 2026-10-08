public class BatchMemberConfirm {
	public String mbId;

	public Boolean showPrompt {get; set;}
	public Boolean showFinal  {get; set;}
	public Boolean IsHeadOffice {get; set;}

	public String Status {get; set;}
	public String NumMem {get; set;}
	public String NumMax {get; set;}

	public BatchMemberConfirm() {
		User usr = [SELECT IsHeadOffice__c from User WHERE Id =: UserInfo.getUserId()];
		IsHeadOffice = usr.IsHeadOffice__c;
		mbId = ApexPages.currentPage().getParameters().get('id');
		System.Debug('mbId :>> ' + mbId);
		if (!Test.isRunningTest()) {
			System_Settings__c sys = [SELECT Value__c FROM System_Settings__c WHERE Parameter__c = 'MAXIMUM_CONVERT_NOW'];
			NumMax = sys.Value__c;
			Membership_Batch_Master__c mbatch = [SELECT Id, Status__c, Number_Members__c FROM Membership_Batch_Master__c WHERE Id =: mbId];
			Status = mbatch.Status__c;
			NumMem = String.valueOf(mbatch.Number_Members__c);
		}
		else {
			Status = 'Testing';
			NumMem = '0';
			NumMax = '3';
		}
		showPrompt = true;
		showFinal  = false;
	}

	public void confirmBatch() {
		System.Debug('we are in confirmBatch');
		System.Debug('mbId :>> ' + mbId);

		List<Lead> leads = [SELECT Id FROM Lead WHERE Batch_Master_Id__c =: mbId];
		System.Debug('leads.size() :>> ' + leads.size());
		if (leads.size() > 0) {
			Membership_Batch_Master__c mbatch = [SELECT Id, Store_Signup_Code__c FROM Membership_Batch_Master__c WHERE Id =: mbId];
			String StoreCode = mbatch.Store_Signup_Code__c;

			//we get our machine number and the starting sequence number from the store record
			Store__c stor = [SELECT Machine_Number__c, Sequence_Number__c FROM Store__c WHERE Code__c =: StoreCode];
			String MachineStr   = stor.Machine_Number__c;
			Integer SequenceNum = Integer.valueOf(stor.Sequence_Number__c);

			for (Lead ld : leads) {
				//we assemble Membership ID
					SequenceNum++;
					String SequenceStr = ('000000' + String.valueOf(SequenceNum)).right(6);
					ld.Membership_ID__c = StoreCode + MachineStr + SequenceStr + '00';
					ld.Is_Confirmed__c  = true;
			}
			update leads;

			mbatch.Confirmed_By__c   = UserInfo.getName();
			mbatch.Confirmed_Date__c = System.now();
			mbatch.Status__c 		 = 'Confirmed';
			update mbatch;

			stor.Sequence_Number__c = SequenceNum;
			update stor;

			if (1 == 1) {																//this "if" statement will enable the alternative way of creating Member records
				//get all the Lead records in this batch 								//	if enabled, Batchable Job must not be scheduled
				List<Lead> lds = [SELECT 												//				creation of members will be through direct upload to SF via dataloader (maybe .io)
									Batch_Reference_Number__c, 							//				linked to Account records that are created in this process
									Batch_Master_Id__c, 								//			    -- This process will create a CSV file that will be seen as an attachment of
									Is_Generated__c,									//				   the affected Membership Batch Master object
																						//				-- The attachment will be downloaded and subsequently uploaded via dataloader
									Membership_ID__c, 									//					the column headers are such that they automatically match with the object field
									Expected_Start_Date__c, 							//					labels
									Expected_Expiry_Date__c,

									Store_Signup_Code__c,
									Store_Signup__c,
									Membership_Type__c,
									Customer_Type__c,
									Customer_Sub_Type__c,
									LeadSource,
									FirstName,
									LastName,
									Birthdate__c,
									Gender__c,
									Marital_Status__c,
									Nationality__c,
									MobilePhone,
									Email,
									Occupation__c,
									Street__c,
									Province_Code__c,
									Province__c,
									City_Code__c,
									City__c,
									Barangay_Code__c,
									Barangay__c,
									Remarks__c,
									Company,
									Temporary_Number__c
								FROM Lead
								WHERE Batch_Master_Id__c =: mbId
								ORDER BY Membership_ID__c ASC];

				Integer ldsSize = lds.size();
				Integer rec = 0;
				String IsBatchUploadLast = 'false';

				List<Account> accountlist = new List<Account>();
				for (Lead ld : lds) {
					//create account via List to save on DML Statement count
						Account acc = new Account();
						acc.Name = ld.Company;
						acc.Batch_Reference_Number__c = ld.Batch_Reference_Number__c;
						acc.Batch_Master_Id__c 		  = ld.Batch_Master_Id__c;
						acc.Membership_ID__c = ld.Membership_ID__c;
						acc.Customer_Type__c = ld.Customer_Type__c;
						accountlist.add(acc);
				}
				//insert the whole List in one DML statement -- MADAMOT SI SALESFORCE SA DML HAHAHAHA
				insert accountlist;
				//AND THEN READ THE NEW BATCH OF ACCOUNTS TO GET THEIR INDIVIDUAL Ids
				accountlist = [SELECT Id FROM Account WHERE Batch_Master_Id__c =: mbId ORDER BY Membership_ID__c ASC];
				List<String> csvRowValues = new List<String>();
				for (Lead ld : lds) {
					//equate object fields to string variables
						String AccountId 			= String.valueOf(accountlist[rec].Id);
						String BatchReferenceNumber = ld.Batch_Reference_Number__c;
						String BatchMasterId 		= String.valueOf(ld.Batch_Master_Id__c);
						String IsGenerated 			= String.valueOf(ld.Is_Generated__c);

						String MembershipID 		= ld.Membership_ID__c;
						String MembershipStartDate 	= String.valueOf(ld.Expected_Start_Date__c.month())  + '/' + String.valueOf(ld.Expected_Start_Date__c.day())  + '/' + String.valueOf(ld.Expected_Start_Date__c.year());
						String MembershipExpiryDate = String.valueOf(ld.Expected_Expiry_Date__c.month()) + '/' + String.valueOf(ld.Expected_Expiry_Date__c.day()) + '/' + String.valueOf(ld.Expected_Expiry_Date__c.year());

						String StoreSignupCode = ld.Store_Signup_Code__c;
						String StoreSignup 	   = ld.Store_Signup__c;
						String MembershipType  = ld.Membership_Type__c;
						String CustomerType    = ld.Customer_Type__c;
						String CustomerSubType = ld.Customer_Sub_Type__c;
						String LeadSource 	   = ld.LeadSource;
						String FirstName 	   = ld.FirstName;
						String LastName 	   = ld.LastName;
						String Birthdate 	   = String.valueOf(ld.Birthdate__c.month()) + '/' + String.valueOf(ld.Birthdate__c.day()) + '/' + String.valueOf(ld.Birthdate__c.year());
						String Gender 		   = ld.Gender__c;
						String MaritalStatus   = ld.Marital_Status__c;
						String Nationality 	   = ld.Nationality__c;
						String MobilePhone 	   = String.valueOf(ld.MobilePhone);
						String Email 		   = String.valueOf(ld.Email);
						String Occupation 	   = ld.Occupation__c;
						String Street 		   = ld.Street__c;
						String ProvinceCode    = String.valueOf(ld.Province_Code__c);
						String Province 	   = ld.Province__c;
						String CityCode 	   = String.valueOf(ld.City_Code__c);
						String City 		   = ld.City__c;
						String BarangayCode    = String.valueOf(ld.Barangay_Code__c);
						String Barangay 	   = ld.Barangay__c;
						String Remarks 	   	   = ld.Remarks__c;
						String TemporaryNumber = ld.Temporary_Number__c;
						rec++;
						if (rec == ldsSize)
							IsBatchUploadLast = 'true';
					//then assemble the CSV row by concatenating the string variables
					String csvRowVal =  AccountId + ',' +
										BatchReferenceNumber + ',' +
										BatchMasterId + ',' +
										IsGenerated + ',' +

										MembershipID + ',' +
										MembershipStartDate + ',' +
										MembershipExpiryDate + ',' +

										StoreSignupCode + ',' +
										StoreSignup + ',' +
										MembershipType + ',' +
										CustomerType + ',' +
										CustomerSubType + ',' +
										LeadSource + ',' +
										FirstName + ',' +
										LastName + ',' +
										Birthdate + ',' +
										Gender + ',' +
										MaritalStatus + ',' +
										Nationality + ',' +
										MobilePhone + ',' +
										Email + ',' +
										Occupation + ',' +
										Street + ',' +
										ProvinceCode + ',' +
										Province + ',' +
										CityCode + ',' +
										City + ',' +
										BarangayCode + ',' +
										Barangay + ',' +
										Remarks + ',' +
										TemporaryNumber + ',' +
										IsBatchUploadLast;
					csvRowValues.add(csvRowVal);
				}

				//assemble the CSV Header Row:
				String csvColumnHeader;
				csvColumnHeader = 	'Account ID,' +
									'Batch Reference Number,' +
									'Batch Master Id,' +
									'Is_Generated,' +

									'Membership ID,' +
									'Membership Start Date,' +
									'Membership Expiry Date,' +

									'Store Signup Code,' +
									'Store Signup,' +
									'Membership Type,' +
									'Customer Type,' +
									'Customer Sub Type,' +
									'LeadSource,' +
									'FirstName,' +
									'LastName,' +
									'Birthdate__c,' +
									'Gender,' +
									'Marital Status,' +
									'Nationality,' +
									'Mobile Phone,' +
									'Email,' +
									'Occupation,' +
									'Street,' +
									'Province Code,' +
									'Province,' +
									'City Code,' +
									'City,' +
									'Barangay Code,' +
									'Barangay,' +
									'Remarks,' +
									'Temporary Number,' +
									'Is Batch Upload Last' +
									'\n';
				//then concatenate our Header and List of comma-delimited rows as one big string
				String csvFile = csvColumnHeader + String.join(csvRowValues,'\n');

				Attachment attachment = new Attachment();
				attachment.Body = Blob.valueOf(csvFile);
				attachment.Name = 'BatchUploadFile.csv';
				attachment.ParentId = mbId;
				insert attachment;
			}
		}
	}

	public void cancelBatch() {
		System.Debug('we are in cancelBatch!');
		System.Debug('mbId :>> ' + mbId);

		Membership_Batch_Master__c mbatch = [SELECT Id FROM Membership_Batch_Master__c WHERE Id =: mbId];
		Lead[] leads = [SELECT Id FROM Lead WHERE Is_Generated__c = true AND Batch_Master_Id__c =: mbId];
		delete leads;

		mbatch.Cancelled_By__c   = UserInfo.getName();
		mbatch.Cancelled_Date__c = System.now();
		mbatch.Status__c 		 = 'Cancelled';
		update mbatch;

		showPrompt = false;
		showFinal  = true;
	}

	/*public void convertNow() {
		BatchableUploadConvertNow batchjob = new BatchableUploadConvertNow(mbId);
		Database.executeBatch(batchjob, 5);

		showPrompt = false;
		showFinal  = true;
	}*/
    
    public void convertNow() {
        List<Contact> contacts = getContacts();
        
        system.debug('Contact size:' + contacts.size());        
        
        if(contacts.size() > 0) {
            insert contacts;
        }
        
        showprompt = false;
        showFinal = true;
    }
    
    private List<Contact> getContacts() {
        Contact con;
        List<Contact> contacts = new List<Contact>();
        
        for(Attachment att : [Select Id, Body from Attachment  WHERE ParentId = :mbId]) {
            for(string csvContent : getCSVContents(att.Body.toString())) {
         		contacts.addAll(convertCSVToContacts(csvContent));
            }        
        }
        
        return contacts;
    }
    
    private List<string> getCSVContents(string csvBody) {
        List<string> contents = new List<string>();
        
        string[] lines = csvBody.split('\n');
        for(string line : lines) {
            contents.add(line.replace('\\', '\\\\').replace('"', '\\"'));
        }        
        
        return contents;
    }
    
    private List<Contact> convertCSVToContacts(string csvContent) {
        List<Contact> contacts = new List<Contact>();
        List<String> lines = csvContent.split('\n');
        
        for (String line : lines) {
            if(line.contains('Account ID,') != true) {
                List<String> fields = line.split(',');
                contacts.add(mapFieldsToContact(fields));                
            }
        }
                
        return contacts;
    }
    
    private Contact mapFieldsToContact(List<string> fields) {
        Contact con = new Contact();

        con.AccountId = Id.valueOf(fields[0]);
		con.Batch_Reference_Number__c = fields[1];
        con.Batch_Master_Id__c = Id.valueOf(fields[2]);
        con.Is_Generated__c = Boolean.valueOf(fields[3]);
       	con.Membership_ID__c = fields[4];
        con.Membership_Start_Date__c = Date.Parse(fields[5]);
        con.Membership_Expiry_Date__c = Date.Parse(fields[6]);
        con.Store_Signup_Code__c = fields[7];
        con.Store_Signup__c = fields[8];
        con.Membership_Type__c = fields[9];
        con.Customer_Type__c = fields[10];
        con.Customer_Sub_Type__c = fields[11];
        con.LeadSource = fields[12];
        con.FirstName = fields[13];
        con.LastName = fields[14];
        con.Birthdate = Date.Parse(fields[15]);
        con.Gender__c = fields[16];
        con.Marital_Status__c = fields[17];
        con.Nationality__c = fields[18];
        con.MobilePhone = fields[19];
        con.Email = fields[20];
        con.Occupation__c = fields[21];
        con.Street__c = fields[22];
        con.Province_Code__c = double.valueOf(fields[23]);
		con.Province__c = fields[24];
        con.City_Code__c = double.valueOf(fields[25]);
        con.City__c = fields[26];
		con.Barangay_Code__c = double.valueOf(fields[27]);
        con.Barangay__c = fields[28];
        con.Remarks__c = fields[29];
        con.Temporary_Number__c = fields[30];
        con.Is_Batch_Upload_Last__c = Boolean.valueOf(fields[31]);
        
        return con;
    }
    
}