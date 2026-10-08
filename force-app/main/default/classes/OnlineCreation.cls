public class OnlineCreation {
    public class MembershipAccount {
        public String cs_email;
        public String cs_code;
        public String cs_expdate;
        public String cs_name;
        public String cs_fname;
        public String cs_mname;
        public String cs_lname;
    }

    public class Payload {
        public MembershipAccount membershipAccount;
    }

    @future(callout=true)
    public static void sendPayload(String contactId) {
        Contact newContact = [SELECT Id, Email, FirstName, MiddleName, LastName, membership_id__c, Membership_Expiry_Date__c FROM Contact WHERE Id = :contactId LIMIT 1];

        MembershipAccount membershipAccount = new MembershipAccount();
        membershipAccount.cs_email = newContact.Email;
        membershipAccount.cs_code = newContact.membership_id__c;
        membershipAccount.cs_expdate = newContact.Membership_Expiry_Date__c != null ? DateTime.newInstance(newContact.Membership_Expiry_Date__c.year(), newContact.Membership_Expiry_Date__c.month(), newContact.Membership_Expiry_Date__c.day()).format('yyyy-MM-dd') : null;
        membershipAccount.cs_name = newContact.FirstName + ' ' + newContact.LastName;
        membershipAccount.cs_fname = newContact.FirstName;
        membershipAccount.cs_mname = newContact.MiddleName;
        membershipAccount.cs_lname = newContact.LastName;

        Payload payload = new Payload();
        payload.membershipAccount = membershipAccount;

        String payloadJson = JSON.serialize(payload);

        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://api.snapmart.ph/v1/membership'); 
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHBpcmVkQXQiOiIyMDI2LTA3LTE0VDEzOjIwOjE1LjQwNTYwNzk4OSswODowMCIsImlzTG9uZ0xpdmUiOnRydWUsInRva2VuSUQiOiIxMzU5YWM0NC02ZmQxLTQwN2UtYWY3My0zNjFhZTVkNTVkMDIiLCJ1c2VySUQiOiJmYTMxZmU5NC01OWUzLTQwYzUtYjI3ZS00ODkyMmFhNzQ1N2YifQ.Pe7EfgslR0sfz2o63zimMian398ci6TXkKDmd3woldQ'); 

        request.setBody(payloadJson);

        HttpResponse response = new Http().send(request);

        // Process the response if needed
        // Example: System.debug('API Response: ' + response.getBody());
        System.debug('API Response: ' + response.getBody());
    }
}