@RestResource(urlMapping='/voucher/membership/*')
global with sharing class VoucherMembershipService {

    @HttpGet
    global static void getMembershipDetails() {

        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        String membershipId = req.requestURI.substring(
            req.requestURI.lastIndexOf('/') + 1
        );

        if (String.isBlank(membershipId)){
            res.statusCode = 400;
            res.responseBody = Blob.valueOf('{"error":"Missing Membership ID"}');
            return;
        }

        List<Contact> results = [
            SELECT membership_id__c, name, firstname, membership_expiry_date__c
            FROM Contact
            WHERE Membership_ID__c = :membershipId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        if (results.isEmpty()){
            res.statusCode = 404;
            res.responseBody = Blob.valueof('{"error":"Membership not found"}');
            return;
        }

        Contact c = results[0];
        Map<String, Object> payload = new Map<String, Object>{
            'membershipId' => c.Membership_ID__c,
            'fullName' => c.Name,
            'firstName' => c.FirstName,
            'membershipExpiry' => c.Membership_Expiry_Date__c
        };
        res.statusCode = 200;
        res.responseBody = Blob.valueOf(JSON.serialize(payload));
    }
    
}