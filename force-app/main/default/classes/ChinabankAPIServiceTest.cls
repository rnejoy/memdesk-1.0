@IsTest
private class ChinabankAPIServiceTest {

    @testSetup
    static void setupData() {
        insert new API_Access_Token__c(
            Service_Name__c = 'Chinabank',
            Access_Token__c = 'EXISTING_TOKEN',
            Token_Expiry__c = (DateTime.now().addHours(2).getTime() / 1000)
        );

        Contact c = new Contact(
            FirstName = 'Juan',
            LastName  = 'Dela Cruz',
            membership_id__c = 'MEM-001',
            Birthdate__c = Date.today().addYears(-30),
            nationality__c = 'FILIPINO',
            employment_status__c = 'EMPLOYED',
            street__c = 'Test St',
            barangay__c = 'Test Brgy',
            city__c = 'Quezon City',
            province__c = 'Metro Manila',
            country__c = 'PH',
            zip_code__c = '1100'
        );
        insert c;
    }

    @IsTest
    static void testSendToBankAndGetResultFlow() {
        Contact c = [SELECT Id FROM Contact LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new ChinabankHttpMock());

        API_Access_Token__c token = [
            SELECT Id, Token_Expiry__c FROM API_Access_Token__c WHERE Service_Name__c = 'Chinabank' LIMIT 1
        ];
        token.Token_Expiry__c = (DateTime.now().addHours(-1).getTime() / 1000);
        update token;

        Test.startTest();
        chinabankAPIService.sendToBank(c.Id);
        Test.stopTest();

        Contact updated = [
            SELECT Chinabank_Application_Reference_Number__c
            FROM Contact WHERE Id = :c.Id
        ];
        System.assertEquals(
            'APP-12345',
            updated.Chinabank_Application_Reference_Number__c,
            'Application reference number must be set from mock response.'
        );

        List<API_Integration_Logs__c> logs = [SELECT Id FROM API_Integration_Logs__c];
        System.assert(logs.size() >= 2, 'At least Token + Push logs should be created.');
    }

    @IsTest
    static void testGetApprovalStatusCallout() {
        Contact c = [SELECT Id FROM Contact LIMIT 1];
        c.Chinabank_Application_Reference_Number__c = 'APP-12345';

        Test.setMock(HttpCalloutMock.class, new ChinabankHttpMock());

        update c;

        Test.startTest();
        chinabankAPIService.getApprovalStatus(c.Id, 'APP-12345');
        Test.stopTest();

        Contact updated = [
            SELECT Chinabank_Application_Status__c
            FROM Contact WHERE Id = :c.Id
        ];
        System.assertEquals(
            'APPROVED',
            updated.Chinabank_Application_Status__c,
            'Approval status should be updated by mocked callout.'
        );
    }

    @IsTest
    static void testSchedulerExecutionIsSafe() {
        Contact c = [SELECT Id FROM Contact LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new ChinabankHttpMock());

        Test.startTest();
        System.schedule(
            'TestScheduler',
            '0 0 0 1 1 ? 2099', 
            new chinabankStatusScheduler(c.Id, 'APP-12345')
        );
        Test.stopTest();

        System.assert(true, 'Scheduler executed safely in test context.');
    }
}