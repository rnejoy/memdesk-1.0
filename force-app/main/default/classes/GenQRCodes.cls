public class GenQRCodes {
	//public variables
		public Boolean showPromptCampaign  {get; set;}
		public Boolean showPromptStores    {get; set;}
		public Boolean showPromptCanvassa  {get; set;}
		public Boolean showPromptCanvassb  {get; set;}
		public Boolean showGenerateQRCodes {get; set;}
		public Boolean showCannotGenCodes  {get; set;}
		public Boolean showFinalScreen     {get; set;}

		public String CampaignId {get; set;}
		public String StoreCode  {get; set;}
		public String StoreName  {get; set;}

		public SelectOption[] allStores      	 {get; set;}
		public SelectOption[] selectedStores 	 {get; set;}
		public SelectOption[] allCanvassers      {get; set;}
		public SelectOption[] selectedCanvassers {get; set;}
		public String qrbandcolor {get; set;}
		public Id UserId {get; set;}

		public Boolean firstDone = false;
		public Boolean secndDone = false;
		public Boolean thirdDone = false;

		public String CampaignName;
		public Map<String, String> mapStore;

	public GenQRCodes() {
		//get the Id of the user using the utility
		UserId = UserInfo.getUserId();
		showPromptCampaign = true;
		//showGenerateQRCodes = true;
	}

	public List<SelectOption> getCampaignOpts() {
		List<SelectOption> options = new List<SelectOption>();
		List<Campaign> camps = [SELECT Id, Name FROM Campaign
				WHERE Type = 'Registration' ORDER BY Name];
		options.add(new SelectOption('', '--None--'));
		for(Campaign cmp : camps) {
			options.add(new SelectOption(cmp.Id, cmp.Name));
		}

		firstDone = true;
		return options;
	}

    public List<selectoption> getStoreOpts() {
		mapStore = new Map<String, String>();
        List<selectoption> options= new List<selectoption>();
        List<Store__c> stores = [SELECT Code__c, Name__c from Store__c ORDER BY Name__c];
        options.add(new selectOption('', 'Choose a Store...'));
        for(Store__c st : stores){
            options.add(new selectOption(st.Code__c, st.Name__c));
			mapStore.put(st.Code__c, st.Name__c);
        }

        return options;
    }

	public void goNext1() {
		System.Debug('we are in goNext1');

		CampaignId = CampaignId == null ? '' : CampaignId;
		if (CampaignId != '') {
			Campaign camp = [SELECT Name FROM Campaign WHERE Id =: CampaignId];
			CampaignName = camp.Name;
		}
		else
			CampaignName = '';

		if (secndDone == false) {
			selectedStores = new List<SelectOption>();
			List<Store__c> stores = [SELECT Id, Name__c FROM Store__c
				WHERE IsActive__c = true ORDER BY Name__c];
			allStores = new List<SelectOption>();
			for (Store__c s : stores) {
				allStores.add(new SelectOption(s.Id, s.Name__c));
			}
		}

		showPromptCampaign = false;
		showPromptStores   = true;
		secndDone = true;
	}

	public void goPrev1() {
		showPromptStores   = false;
		showPromptCampaign = true;
	}

	public void goNext2a() {
		System.Debug('we are in goNext2a');

		showPromptStores   = false;
		showPromptCanvassa = true;
		thirdDone = false;
	}

	public void goPrev2a() {
		showPromptCanvassa = false;
		showPromptStores = true;
	}

	public void goNext2b() {
		System.Debug('we are in goNext2b');
		System.Debug('StoreCode :>> ' + StoreCode);
		StoreCode = StoreCode == null ? '' : StoreCode;
		if (thirdDone == false) {
			showPromptCanvassa = false;
			selectedCanvassers = new List<SelectOption>();
			if (StoreCode != '') {
				StoreName = mapStore.get(StoreCode);
				List<Canvasser__c> canvass = [SELECT Id, Name__c FROM Canvasser__c
					WHERE IsActive__c = true AND Store_Assignment_Code__c =: StoreCode ORDER BY Name__c];
				allCanvassers = new List<SelectOption>();
				for (Canvasser__c c : canvass) {
					allCanvassers.add(new SelectOption(c.Id, c.Name__c));
				}

				showPromptCanvassb = true;
			}
			else {
				goNext3();
			}

			thirdDone = true;
		}
	}

	// public void filterCanvassers() {
	// 	System.Debug('we are in filterCanvassers');

	// 	StoreCode = StoreCode == null ? '' : StoreCode;

	// 	List<Canvasser__c> canvass = new List<Canvasser__c>();
	// 	String filter;
	// 	if (StoreCode == '')
	// 		filter = '';
	// 	else
	// 		filter = ' AND Store_Assignment_Code__c =: StoreCode ';

	// 	String query = 'SELECT Id, Name__c FROM Canvasser__c ' +
	// 					'WHERE IsActive__c = true ' + filter + ' ORDER BY Name__c';
	// 	canvass = Database.query(query);
	// 	allCanvassers = new List<SelectOption>();
	// 	for (Canvasser__c c : canvass) {
	// 		allCanvassers.add(new SelectOption(c.Id, c.Name__c));
	// 	}
	// }

	public void goPrev2b() {
		showPromptCanvassb = false;
		showPromptCanvassa = true;
		thirdDone = false;
	}

	public void goNext3() {
		System.Debug('we are in goNext3');

		showPromptCanvassb = false;

		if (selectedStores.size() > 0 || (StoreCode != '' && selectedCanvassers.size() > 0))
			showGenerateQRCodes = true;
		else
			showCannotGenCodes  = true;
	}

	public void goPrev3() {
		showGenerateQRCodes = false;
		showCannotGenCodes  = false;
		showPromptCanvassa  = true;
		thirdDone = false;
	}

	public void jumpStart() {
		showCannotGenCodes = false;
		showPromptCampaign = true;
	}

	public void generateQRCodes() {
		System.Debug('qrbandcolor :>> ' + qrbandcolor);
		String Community_URL = Label.Community_URL.replace(':', '%3A').replace('/', '%2F');
		System.Debug('Community_URL :>> ' + Community_URL);
		//campaignId URL string for both Stores and Canvassers
			String campaignIdURL = '';
			if (campaignId != '') {
				campaignIdURL = '%26campaignId=' + CampaignId;
			}
			System.Debug('campaignIdURL :>> ' + campaignIdURL);
		//for both Stores and Canvassers
			String leadSourceURL;
			String qrcVersionURL  = '%3FqrcVersion=';
			String canvasserIdURL = '%26canvasserId=';
			Integer qrcversion;

		//****** PROCESSING FOR STORES ********/
		if (selectedStores.size() > 0) {
			List<Store__c> stores = new List<Store__c>();
			leadSourceURL = '%26leadSource=Store';

			for (SelectOption so : selectedStores) {
				System.Debug('so.getLabel() :>> ' + so.getLabel());
				System.Debug('so.getValue() :>> ' + so.getValue());

				Store__c store = [SELECT Id,
						Code__c,
						QR_Code_Version__c,
						Email__c
					FROM Store__c
					WHERE Id =: so.getValue()];

				qrcversion = Integer.valueOf(store.QR_Code_Version__c);
				qrcversion++;

				String wholeURL = Community_URL +
									qrcVersionURL +
									String.valueOf(qrcversion) +
									leadSourceURL +
									canvasserIdURl +
									so.getValue() +
									campaignIdURL;
				System.Debug('wholeURL :>> ' + wholeURL);
				store.QR_Code_Version__c = qrcversion;
				store.QR_Code_URL__c = wholeURL;

				stores.add(store);
			}
			update stores;
		}

		//****** PROCESSING FOR CANVASSERS ********/
		if (selectedCanvassers.size() > 0) {
			List<Canvasser__c> canvas = new List<Canvasser__c>();
			Messaging.SingleEmailMessage[] mails = new List<Messaging.SingleEmailMessage>();
			leadSourceURL = '%26leadSource=Canvasser';

			for (SelectOption ca : selectedCanvassers) {
				System.Debug('ca.getLabel() :>> ' + ca.getLabel());
				System.Debug('ca.getValue() :>> ' + ca.getValue());

				Canvasser__c canva = [SELECT Id,
						C_Code__c,
						Name__c,
						QR_Code_Version__c,
						Email__c,
						Send_Email__c,
						Store_Assignment_Code__c,
						Store_Assignment__c
					FROM Canvasser__c
					WHERE Id =: ca.getValue()];

				qrcversion = Integer.valueOf(canva.QR_Code_Version__c);
				qrcversion++;

				String wholeURL = Community_URL +
									qrcVersionURL +
									String.valueOf(qrcversion) +
									leadSourceURL +
									canvasserIdURl +
									ca.getValue() +
									campaignIdURL;
				System.Debug('wholeURL :>> ' + wholeURL);
				canva.QR_Code_Version__c = qrcversion;
				canva.QR_Code_URL__c = wholeURL;

				System.Debug('canva.Email__c :>> ' + canva.Email__c);
				if (canva.Send_Email__c == true) {
					System.Debug('we are allowed to send an email');
					EmailTemplate temp = [SELECT Subject, HTMLValue FROM EmailTemplate WHERE DeveloperName = 'New_QR_Code_Gen_C'];
					String html = temp.HTMLValue;
						html = html.replace('{!FullName}', canva.Name__c);
						html = html.replace('{!CanvasserCode}', canva.C_Code__c);
						html = html.replace('{!EffectivityDate}', 'tomorrow');
						html = html.replace('{!QRCodeURL}', wholeURL);
						html = html.replace('{!QRBandColor}', qrbandcolor);
						html = html.replace('{!StoreAssignmentName}', canva.Store_Assignment__c);
						html = html.replace('{!StoreAssignmentCode}', canva.Store_Assignment_Code__c);
						html = html.replace('{!CampaignName}', CampaignName);

					Messaging.SingleEmailMessage mail = getEmail();
					OrgWideEmailAddress owea = [select Id from OrgWideEmailAddress where DisplayName = 'no-reply'];
					mail.setOrgWideEmailAddressId(owea.Id);
					mail.toAddresses = new String[] {canva.Email__c};
					mail.subject  = temp.Subject;
					mail.htmlbody = html;
					mails.add(mail);
				}
				canvas.add(canva);
			}

			if (mails.size() > 0) {
				Messaging.SendEmailResult[] results = Messaging.sendEmail(mails);
				if (results[0].success)
					System.debug('The email was sent successfully.');
				else
					System.debug('The email failed to send: ' + results[0].errors[0].message);
			}
			update canvas;
		}

		showGenerateQRCodes = false;
		showFinalScreen     = true;
	}

	public static Messaging.SingleEmailMessage getEmail() {
		Messaging.SingleEmailMessage mailMessage = new Messaging.SingleEmailMessage();
		mailMessage.setSaveAsActivity(false);
		return mailMessage;
	}
}