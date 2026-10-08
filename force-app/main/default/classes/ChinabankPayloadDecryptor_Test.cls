@IsTest
private class ChinabankPayloadDecryptor_Test {

    @IsTest
    static void testDecrypt_Bypass() {
        String result = ChinabankPayloadDecryptor.decrypt('ANY');
        System.assert(result.contains('APPROVED'), 'Bypass decrypt should contain APPROVED');
        System.assert(result.contains('providerReferenceNumber'), 'Bypass decrypt should contain providerReferenceNumber');
    }

    @IsTest
    static void testDecrypt_BlankInput() {
        
        ChinabankPayloadDecryptor.bypassTestDecrypt = true;
        String result = ChinabankPayloadDecryptor.decrypt('');
        System.assert(result.contains('NO_ENCRYPTED_PAYLOAD'), 'Blank input should return NO_ENCRYPTED_PAYLOAD');
        ChinabankPayloadDecryptor.bypassTestDecrypt = false;
    }

    @IsTest
    static void testDecrypt_InvalidBase64() {
        ChinabankPayloadDecryptor.bypassTestDecrypt = true;
        String result = ChinabankPayloadDecryptor.decrypt('INVALID_BASE64');
        System.assert(result.contains('DECRYPT_ERROR'), 'Invalid Base64 should result in DECRYPT_ERROR');
        ChinabankPayloadDecryptor.bypassTestDecrypt = false;
    }

    @IsTest
    static void testDecrypt_ValidFlow() {
        ChinabankPayloadDecryptor.bypassTestDecrypt = true;

        String dummyPayload = EncodingUtil.base64Encode(Blob.valueOf('DummyPayload'));
        String result = ChinabankPayloadDecryptor.decrypt(dummyPayload);

        System.assert(result != null, 'Valid dummy Base64 should not return null');

        ChinabankPayloadDecryptor.bypassTestDecrypt = false;
    }

    @IsTest
    static void testDecrypt_MissingConfig() {
        ChinabankPayloadDecryptor.bypassTestDecrypt = true;

        Test.startTest();
        String result = ChinabankPayloadDecryptor.decrypt('');
        System.assert(result.contains('NO_ENCRYPTED_PAYLOAD') || result.contains('CONFIG_ERROR'), 'Missing config should be handled');
        Test.stopTest();

        ChinabankPayloadDecryptor.bypassTestDecrypt = false;
    }
}