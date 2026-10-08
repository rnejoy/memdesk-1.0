public without sharing class MemberFeedbackLookupController {

    public class MemberResult {
        @AuraEnabled public String token;   // opaque, not the raw Contact Id
        @AuraEnabled public String firstName;
    }

    public class SecurityException extends Exception {}

    @AuraEnabled
    public static MemberResult findMember(String membershipId) {
        if (String.isBlank(membershipId)) {
            return null;
        }

        String cleanId = membershipId.trim();
        List<Contact> contacts;
        try {
            contacts = [
                SELECT Id, FirstName
                FROM Contact
                WHERE Membership_ID__c = :cleanId
                LIMIT 1
            ];
        } catch (System.QueryException qe) {
            return null;
        }

        if (contacts.isEmpty()) {
            return null;
        }

        Contact matchedContact = contacts[0];
        MemberResult result = new MemberResult();
        result.token = generateMemberToken(matchedContact.Id, cleanId);
        result.firstName = String.isNotBlank(matchedContact.FirstName)
            ? matchedContact.FirstName
            : 'Member';
        return result;
    }

    // --- internal helpers ---

    private static String generateMemberToken(Id contactId, String membershipId) {
        Long expiry = Datetime.now().getTime() + (10 * 60 * 1000);
        String payload = 'MEMBER:' + contactId + ':' + membershipId + ':' + expiry;
        Blob mac = Crypto.generateMac('HmacSHA256', Blob.valueOf(payload), getSigningKey());
        return EncodingUtil.base64Encode(Blob.valueOf(payload)) + '.' + EncodingUtil.base64Encode(mac);
    }

    public static Id resolveMemberToken(String token, String expectedMembershipId) {
        if (String.isBlank(token) || !token.contains('.')) {
            throw new SecurityException('Invalid token.');
        }

        List<String> parts = token.split('\\.', 2);
        Blob payloadBlob = EncodingUtil.base64Decode(parts[0]);
        Blob providedMac = EncodingUtil.base64Decode(parts[1]);
        Blob expectedMac = Crypto.generateMac('HmacSHA256', payloadBlob, getSigningKey());

        if (EncodingUtil.convertToHex(expectedMac) != EncodingUtil.convertToHex(providedMac)) {
            throw new SecurityException('Token verification failed.');
        }

        String payload = payloadBlob.toString();
        List<String> segments = payload.split(':');
        if (segments.size() != 4 || segments[0] != 'MEMBER') {
            throw new SecurityException('Malformed token.');
        }

        Id contactId = (Id) segments[1];
        String membershipId = segments[2];
        Long expiry = Long.valueOf(segments[3]);

        if (Datetime.now().getTime() > expiry) {
            throw new SecurityException('Token has expired. Please look up the member again.');
        }
        if (membershipId != expectedMembershipId) {
            throw new SecurityException('Token does not match the provided membership ID.');
        }

        return contactId;
    }

    private static Blob getSigningKey() {
        Feedback_Security_Setting__mdt setting = Feedback_Security_Setting__mdt.getInstance('Default');
        return Blob.valueOf(setting.Signing_Key__c);
    }
}