@RestResource(urlMapping='/shell/membership/*')
global with sharing class ShellMembershipService {

    @HttpGet
    global static void getMembershipDetails() {

        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        String membershipId = req.requestURI.substring(
            req.requestURI.lastIndexOf('/') + 1
        );

        if (String.isBlank(membershipId)) {
            res.statusCode = 400;
            res.responseBody = Blob.valueOf('{"error":"Missing Membership ID"}');
            return;
        }

        List<Contact> results = [
            SELECT Is_Active__c, Live__c, Expired__c,
                   FirstName, Membership_Expiry_Date__c
            FROM Contact
            WHERE Membership_ID__c = :membershipId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        if (results.isEmpty()) {
            res.statusCode = 404;
            res.responseBody = Blob.valueOf('{"error":"Membership not found"}');
            return;
        }

        Contact c = results[0];

        String status;
        if (c.Is_Active__c == true) {
            if (c.Live__c == true) {
                status = 'Live';
            } else if (c.Expired__c == true) {
                status = 'Expired';
            } else {
                status = 'Active'; 
            }
        } else {
            status = 'Deactivated';
        }

        Map<String, Object> payload = new Map<String, Object>{
            'status' => status,
            'firstName' => c.FirstName,
            'membershipExpiry' => c.Membership_Expiry_Date__c
        };

        res.statusCode = 200;
        res.responseBody = Blob.valueOf(JSON.serialize(payload));
    }

}