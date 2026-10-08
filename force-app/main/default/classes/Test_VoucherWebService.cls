@isTest
public class Test_VoucherWebService {
	@isTest 
    public static void VoucherWebService_CodeCoverage(){
        Contact newContact = new Contact(LastName = 'SomeonesContact', 
                                         Membership_ID__c = 'memberid');
        insert newContact;
        
        List<Voucher__c> listVoucher = new List<Voucher__c>();
        Voucher__c newVoucher = new Voucher__c(Claimed__c = false, 
                                               Membership_ID__c = 'memberid', 
                                               Start_Date__c = Date.today().addDays(-7), 
                                               End_Date__c = Date.today().addDays(7),
                                               Voucher_Code__c = 'validcode');
        listVoucher.add(newVoucher);
        newVoucher = new Voucher__c(Claimed__c = true, 
                                    Membership_ID__c = 'memberid', 
                                    Start_Date__c = Date.today().addDays(-7), 
                                    End_Date__c = Date.today().addDays(7),
                                    Voucher_Code__c = 'claimedcode');
        listVoucher.add(newVoucher);
        newVoucher = new Voucher__c(Claimed__c = false, 
                                    Membership_ID__c = 'memberid', 
                                    Start_Date__c = Date.today().addDays(-14), 
                                    End_Date__c = Date.today().addDays(-7),
                                    Voucher_Code__c = 'lapsecode');
        listVoucher.add(newVoucher);
        newVoucher = new Voucher__c(Claimed__c = false, 
                                    Membership_ID__c = null, 
                                    Start_Date__c = Date.today().addDays(-7), 
                                    End_Date__c = Date.today().addDays(7),
                                    Voucher_Code__c = 'nomembercode');
        listVoucher.add(newVoucher);
        newVoucher = new Voucher__c(Claimed__c = false, 
                                    Membership_ID__c = null, 
                                    Start_Date__c = null, 
                                    End_Date__c = null,
                                    Voucher_Code__c = 'errorcode');
        listVoucher.add(newVoucher);
        insert listVoucher;
        Test.startTest();
        VoucherWebService.checkVoucher('lapsecode');
        VoucherWebService.checkVoucher('invalidcode');
        VoucherWebService.checkVoucher('validcode');
        VoucherWebService.checkVoucher('nomembercode');
        VoucherWebService.checkVoucher('claimedcode');
        VoucherWebService.checkVoucher('errorcode');
        VoucherWebService.setVoucher('validcode');
        VoucherWebService.setVoucher('invalidcode');
        Test.stopTest();
    }
}