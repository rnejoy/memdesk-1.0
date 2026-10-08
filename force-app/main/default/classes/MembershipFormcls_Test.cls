@isTest
public class MembershipFormcls_Test {
	@isTest 
    public static void ExtensionFormcls_CodeCoverage () {
        Store__c insertStore = new Store__c();
        insertStore.Code__c = '1234';
        insert insertStore;
        
        Canvasser__c insertCanvasser = new Canvasser__c();
        insertCanvasser.Name__c = 'Canvasser Name';
        insert insertCanvasser;
        
        Barangay__c insertBrgy = new Barangay__c();
        insertBrgy.Code__c = 1234;
        insertBrgy.City__c = 1234;
        insert insertBrgy;
        
        Province__c insertProvince = new Province__c();
        insertProvince.Code__c = 12; 
        insertProvince.Name__c = 'CDO';
        insert insertProvince;
        
        City__c insertCity = new City__c();
        insertCity.Code__c = 1234; 
        insertCity.Name__c = 'CDO City';
        insertCity.Province__c = 12;
        insert insertCity;
        
        Lead insertLead = new Lead();
        insertLead.LastName = 'Sample';
        insertLead.Company = 'Sample Company';
        
        Test.startTest();
        MembershipFormcls.fetchQRSVersion(insertStore.Id);
        MembershipFormcls.fetchQRCVersion(insertCanvasser.Id);
        MembershipFormcls.fetchNationals();
        MembershipFormcls.fetchStores();
        MembershipFormcls.fetchProvinces();
        MembershipFormcls.fetchCities(1234);
        MembershipFormcls.fetchBarangs(1234);
        MembershipFormcls.createLeadRecord(insertLead);
        Test.stopTest();
    }
}