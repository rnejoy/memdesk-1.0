public with sharing class chinabankSignatureService {

    public static String generateSignature(
        String authorization,
        String partnerId,
        String sessionId,
        String requestDT,
        String fullRequestJson,
        String hashKey
    ) {
        String canonical = 
            authorization +
            partnerId +
            sessionId +
            requestDT +
            fullRequestJson;

        Blob dataBlob = Blob.valueOf(canonical);
        Blob secretBlob = Blob.valueOf(hashKey + sessionId);
        Blob mac = Crypto.generateMac('HmacSHA256', dataBlob, secretBlob);

        return EncodingUtil.base64Encode(mac);
    }
}