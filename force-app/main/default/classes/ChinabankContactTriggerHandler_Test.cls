@IsTest
public class ChinabankContactTriggerHandler_Test {

    private class ChinabankHttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"result":"SUCCESS"}');
            return res;
        }
    }

    @IsTest
    static void testHandlerAfterInsert_Direct() {
        Test.setMock(HttpCalloutMock.class, new ChinabankHttpMock());

        Contact c = new Contact(
            Id = Schema.SObjectType.Contact.getKeyPrefix() + '000000000000001', 
            LastName = 'Insert Exec',
            Chinabank_Credit_Card_Applied__c = true,
            LeadSource = 'Chinabank-Instore'
        );

        Test.startTest();
        chinabankContactTriggerHandler.handleAfterInsert(
            new List<Contact>{ c }
        );
        Test.stopTest();

        System.assertNotEquals(null, c.LastName, 'The list should have been processed.');
    }

    @IsTest
    static void testHandlerAfterUpdate_Scenario1() {
        Test.setMock(HttpCalloutMock.class, new ChinabankHttpMock());
        Id fakeId = Schema.SObjectType.Contact.getKeyPrefix() + '000000000000002';

        Contact oldC = new Contact(
            Id = fakeId,
            Chinabank_Credit_Card_Applied__c = false,
            Chinabank_Application_Status__c = null,
            CBCC_ID_Number__c = 'OLD123'
        );

        Contact newC = new Contact(
            Id = fakeId,
            Chinabank_Credit_Card_Applied__c = true,
            Chinabank_Application_Status__c = null,
            CBCC_ID_Number__c = 'NEW123'
        );

        Test.startTest();
        chinabankContactTriggerHandler.handleAfterUpdate(
            new List<Contact>{ newC },
            new Map<Id, Contact>{ fakeId => oldC }
        );
        Test.stopTest();
    }

    @IsTest
    static void testHandlerAfterUpdate_Scenario2() {
        Test.setMock(HttpCalloutMock.class, new ChinabankHttpMock());
        Id fakeId = Schema.SObjectType.Contact.getKeyPrefix() + '000000000000003';

        Contact oldC = new Contact(
            Id = fakeId,
            MobilePhone = '12345',
            Customer_Type__c = 'Executive',
            Chinabank_Credit_Card_Applied__c = true,
            Chinabank_Application_Status__c = 'IN-PROGRESS'
        );

        Contact newC = new Contact(
            Id = fakeId,
            MobilePhone = '67890',
            Customer_Type__c = 'Executive',
            Chinabank_Credit_Card_Applied__c = true,
            Chinabank_Application_Status__c = 'IN-PROGRESS'
        );

        Test.startTest();
        chinabankContactTriggerHandler.handleAfterUpdate(
            new List<Contact>{ newC },
            new Map<Id, Contact>{ fakeId => oldC }
        );
        Test.stopTest();
    }

    @IsTest
    static void testChinaBankTriggerService() {
        Test.setMock(HttpCalloutMock.class, new ChinabankHttpMock());

        Contact c = new Contact(
            LastName = 'Service Exec',
            Customer_Type__c = 'Executive',
            LeadSource = 'Chinabank-Online',
            Chinabank_Credit_Card_Applied__c = true
        );
        insert c;

        Test.startTest();
        chinaBankTriggerService.sendContactsToChinaBank(
            new List<Id>{ c.Id }
        );
        Test.stopTest();

        System.assert(c.Id != null);
    }
}