@IsTest
private class ChinabankSignatureServiceTest {

    @IsTest
    static void testGenerateSignature() {

        String signature = chinabankSignatureService.generateSignature(
            'Bearer TEST_TOKEN',
            'PARTNER123',
            'SESSION123',
            '12/15/2025 10:00 AM',
            '{"requestData":"TEST"}',
            'HASHKEY123'
        );

        System.assertNotEquals(null, signature);
        System.assert(signature.length() > 0);
    }
}