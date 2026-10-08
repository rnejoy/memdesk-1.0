@isTest
public class S3Csv_Test {
    @testSetup static void setup() {
        Test.setMock(HttpCalloutMock.class, new Send_Contact_To_stores_Mock()); 
        Contact testMember = new Contact(LastName='LastName',
                                         Membership_ID__c = '00000000000');
        insert testMember;
        Transaction__c testTransaction = new Transaction__c(Membership_ID__c = '00000000000',
                                                             Name = '00000000000',
                                                             Member__c = testMember.Id);
        insert testTransaction;
    }
    @isTest
    public static void S3CsvScheduler_Instore(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        SchedulableContext sc = null;
        S3CsvScheduler_Instore tsc = new S3CsvScheduler_Instore();
        tsc.execute(sc);
        Test.stopTest();
    }
    @isTest
    public static void S3CsvScheduler_FB(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        SchedulableContext sc = null;
        S3CsvScheduler_FB tsc = new S3CsvScheduler_FB();
        tsc.execute(sc);
        Test.stopTest();
    }
    @isTest
    public static void S3CsvScheduler_CapCare(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        SchedulableContext sc = null;
        S3CsvScheduler_CapCare tsc = new S3CsvScheduler_CapCare();
        tsc.execute(sc);
        Test.stopTest();
    }
    @isTest
    public static void S3CsvScheduler_TransactionDetails(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        SchedulableContext sc = null;
        S3CsvScheduler_TransactionDetails tsc = new S3CsvScheduler_TransactionDetails();
        tsc.execute(sc);
        Test.stopTest();
    }
    @isTest
    public static void S3CsvtoSalesforce_Transaction(){
        Test.startTest();
        S3CsvToSalesforceHelper.CSVtoSFObject_Method('transactions', 'branch,cashiercode,creditmemoexpirationdate,dateandtimereturned,member,transactiondate,transactionno,transactiontype,foodservicecode,caltexcode,mode,type,remarks,status,void,creditmemonumber,managercode,billinginformation,deliveryaddress,deliverydate,deliveryfee,deliverytime,shipto,vouchercode,managername,creditmemoreasons,personalshopperfee,paymentmethod,sourceofpurchase\n1030,4110,2023-01-11 00:00:00.0,2023-01-11 00:00:00.0,00000000000,2023-01-11,103006142813,A,1030,1030,S,P,þþþþþþþþþ12þ5601312606437þþþþþþþþþþLANDERSPHüC,Successful,,,,,,,,,,,,,,,In-Store\n1030,4110,2023-01-11 00:00:00.0,2023-01-11 00:00:00.0,00000000000,2023-01-11 00:00:00.0,103006142813,A,1030,1030,S,P,þþþþþþþþþ12þ4800056012035þþþþþþþþþþLANDERSPHüC,Successful,,,,,,,,,,,,,,,In-Store');
    	Test.stopTest();
    }
    @isTest
    public static void S3CsvtoSalesforce_TransactionDetails(){
        Test.startTest();
        S3CsvToSalesforceHelper.CSVtoSFObject_Method('transaction details', 'article,price,quantity,remarks,subtotal,transaction,itemdescriptionposnumber,member,articledescription,class,dept,regsrp,subclass,subdept,promosrp,promotype,promocode,discountcode,netsales,btgi,manualdiscount,grossafterpromo,promodiscount,tax,gross,onsale\n106151,39.95,1.0,þþþþþþþþþ12þ4800047840012þþþþþþþþþþLANDERSPHüC,39.95,00000000000,8,00000000000,Zonrox Bleach Original 1L,BLEACH,SUNDRIES,39.95,LIQUID,LAUNDRY,,,,,35.6696,,0.0,39.95,0.0,4.28,39.95,ONSALE\n804937,50.69,0.26,þ194.95þþþþVþþþþ0þ28049370000260þþþþþþþþþþLANDERSPHüC,50.69,00000000000,8,00000000000,OrgOp Tomato Native /kg,VEGETABLES,FRESH,204.95,VEGETABLE ORGANIC,PRODUCE,,,,,50.69,,0.0,50.69,0.0,0.0,50.69,ONSALE');
    	Test.stopTest();
    }
}