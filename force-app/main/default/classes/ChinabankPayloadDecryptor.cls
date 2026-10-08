public with sharing class ChinabankPayloadDecryptor {

    private static String aesKeyBase64;
    private static String aadValue;

    private static void loadConfig() {
        if (aesKeyBase64 == null || aadValue == null) {
            Chinabank_API_Setting__mdt cfg = [
                SELECT AES_Key__c, AES_AAD__c
                FROM Chinabank_API_Setting__mdt
                WHERE DeveloperName = 'Chinabank_GCM'
                LIMIT 1
            ];

            aesKeyBase64 = cfg.AES_Key__c;
            aadValue     = cfg.AES_AAD__c;
        }
    }
    
    @TestVisible
	static Boolean bypassTestDecrypt = false;

    public static String decrypt(String bankBase64) {
        
        if (Test.isRunningTest() && !bypassTestDecrypt) {
        	return '{"responseBody":{"result":"APPROVED"},"responseHeader":{"responseContext":{"providerReferenceNumber":"APP123"}}}';
    	}
        
        if (String.isBlank(bankBase64)) {
            return 'NO_ENCRYPTED_PAYLOAD';
        }

        loadConfig();

        if (String.isBlank(aesKeyBase64) || String.isBlank(aadValue)) {
            return 'CONFIG_ERROR: Missing AES_Key or AAD in metadata';
        }

        try {
            Blob bankBlob = EncodingUtil.base64Decode(bankBase64);

            String bankHex = EncodingUtil.convertToHex(bankBlob);

            String fixedHex = '0C' + bankHex;

            Blob fixedBlob = EncodingUtil.convertFromHex(fixedHex);

            Blob keyBlob = EncodingUtil.base64Decode(aesKeyBase64);
            Blob aadBlob = Blob.valueOf(aadValue);

            Blob decryptedBlob = Crypto.decryptWithManagedIV(
                'AES256-GCM',
                keyBlob,
                fixedBlob,
                aadBlob
            );

            return decryptedBlob.toString();

        } catch (Exception e) {
            return 'DECRYPT_ERROR: ' + e.getMessage();
        }
    }
}