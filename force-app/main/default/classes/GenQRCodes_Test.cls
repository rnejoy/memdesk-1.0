@isTest
public class GenQRCodes_Test {
	@isTest
    public static void GenQRCodes_CodeCoverage(){
        Campaign insertCampaign = new Campaign();
        insertCampaign.Name = 'Campaign';
        insertCampaign.Type = 'Registration';
        insertCampaign.Campaign_Code__c = 123123123;
        insert insertCampaign;

        Store__c insertStore = new Store__c();
		insertStore.Code__c = '1040';
        insertStore.Name__c = 'Store';
        insertStore.IsActive__c = true;
        insert insertStore;

        Canvasser__c insertCanvasser = new Canvasser__c();
        insertCanvasser.Name__c = 'Canvasser';
        insertCanvasser.IsActive__c = true;
        insertCanvasser.Type__c = 'In-store';
		insertCanvasser.Store_Assignment_Code__c = '1040';
        insertCanvasser.Store_Assignment__c = 'Store Assignment';
        insertCanvasser.Email__c = 'test@testemailnotworking.com';
        insert insertCanvasser;

        // insertCanvasser = new Canvasser__c();
        // insertCanvasser.Name__c = 'Canvasser';
        // insertCanvasser.IsActive__c = true;
        // insertCanvasser.Type__c = 'Roaming';
		// insertCanvasser.Store_Assignment_Code__c = '1040';
        // insertCanvasser.Store_Assignment__c = 'Store Assignment';
        // insertCanvasser.Email__c = 'test@testemailnotworking.com';
        // insert insertCanvasser;

        List<SelectOption> optionListStore = new List<SelectOption>();
        SelectOption optionStore = new SelectOption(insertStore.Id, 'Store');
        optionListStore.add(optionStore);

        List<SelectOption> optionListCanvasser = new List<SelectOption>();
        SelectOption optionCanvasser = new SelectOption(insertCanvasser.Id, 'Canvasser');
        optionListCanvasser.add(optionCanvasser);

        Test.startTest();
        GenQRCodes gqrc = new GenQRCodes();

        List<SelectOption> getCampaignOptionReturn = gqrc.getCampaignOpts();
        List<SelectOption> getStoreOptionReturn = gqrc.getStoreOpts();
        gqrc.goNext1();
        gqrc.goPrev1();
        gqrc.goNext2a();
        gqrc.goPrev2a();
        gqrc.goNext2b();
        gqrc.goPrev2b();
        gqrc.goNext3();
        gqrc.goPrev3();
        //gqrc.goNext4();
        gqrc.selectedStores = optionListStore;
        // gqrc.goNext4();
        // gqrc.goPrev4();
        gqrc.jumpStart();
        gqrc.CampaignId = insertCampaign.Id;
        gqrc.qrbandcolor = 'red';
        gqrc.selectedStores = optionListStore;
        //gqrc.selectedICanvassers = optionListCanvasser;
        gqrc.selectedCanvassers = optionListCanvasser;
        gqrc.generateQRCodes();
        Test.stopTest();
        System.assert(getCampaignOptionReturn.size() > 1, 'getCampaignOpts: Number of options are not correct.');
    }
}