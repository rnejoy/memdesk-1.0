/**
 * Test class for RecaptchaController.
 *
 * IMPORTANT: Recaptcha_Setting__mdt is Custom Metadata. Records can't be
 * inserted via DML in a test — they must already be deployed to the org.
 * Tests here check for a 'Default' record and skip the callout-dependent
 * assertions if it isn't present, so the class still compiles/runs cleanly
 * in orgs without it configured. For full coverage, deploy a record like:
 *
 *   DeveloperName: Default
 *   Site_Key__c:   any non-blank string (e.g. "test-site-key")
 *   Secret_Key__c: any non-blank string (e.g. "test-secret-key")
 *   Score_Threshold__c: 0.5
 */
@isTest
private class RecaptchaController_Test {

    // ── Configurable mock for the reCAPTCHA siteverify endpoint ────────────
    private class RecaptchaHttpMock implements HttpCalloutMock {
        Integer statusCode;
        String body;

        RecaptchaHttpMock(Integer statusCode, String body) {
            this.statusCode = statusCode;
            this.body = body;
        }

        public HTTPResponse respond(HTTPRequest req) {
            System.assertEquals('POST', req.getMethod());
            System.assert(
                req.getEndpoint().contains('recaptcha/api/siteverify'),
                'Unexpected endpoint: ' + req.getEndpoint()
            );
            System.assert(
                req.getBody().contains('response=') && req.getBody().contains('secret='),
                'Expected secret and response params in request body'
            );

            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setBody(body);
            return res;
        }
    }

    // Mock that simulates a network-level failure (timeout, DNS, etc.)
    private class ThrowingHttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            throw new CalloutException('Simulated network failure');
        }
    }

    private static Boolean isConfigured() {
        return ![SELECT Id FROM Recaptcha_Setting__mdt WHERE DeveloperName = 'Default' LIMIT 1].isEmpty();
    }

    // ───────────────────────── getSiteKey ──────────────────────────────────

    @isTest
    static void testGetSiteKey_returnsSiteKeyWhenConfigured() {
        if (!isConfigured()) return;

        Test.startTest();
        String key = RecaptchaController.getSiteKey();
        Test.stopTest();

        System.assertNotEquals(null, key, 'Expected a site key to be returned');
    }

    @isTest
    static void testGetSiteKey_throwsWhenNotConfigured() {
        if (isConfigured()) return;

        Boolean threw = false;
        try {
            RecaptchaController.getSiteKey();
        } catch (AuraHandledException e) {
            threw = true;
        }
        System.assert(threw, 'Expected AuraHandledException when reCAPTCHA is not configured');
    }

    // ───────────────────────── verify / verifyCaptcha ──────────────────────

    @isTest
    static void testVerify_missingToken() {
        // Fails before any callout or metadata lookup dependency, so this
        // runs regardless of whether the Default metadata record exists.
        Boolean threw = false;
        try {
            RecaptchaController.verify(null, 'login');
        } catch (AuraHandledException e) {
            threw = true;
        }
        System.assert(threw, 'Expected failure for blank token');

        threw = false;
        try {
            RecaptchaController.verify('', 'login');
        } catch (AuraHandledException e) {
            threw = true;
        }
        System.assert(threw, 'Expected failure for empty token');
    }

    @isTest
    static void testVerify_notConfigured() {
        if (isConfigured()) return;

        Boolean threw = false;
        try {
            RecaptchaController.verify('some-token', 'login');
        } catch (AuraHandledException e) {
            threw = true;
        }
        System.assert(threw, 'Expected failure when reCAPTCHA is not configured');
    }

    @isTest
    static void testVerify_success_v3WithScoreAndMatchingAction() {
        if (!isConfigured()) return;

        Test.setMock(HttpCalloutMock.class,
            new RecaptchaHttpMock(200, '{"success":true,"score":0.9,"action":"login"}'));

        Test.startTest();
        Boolean result = RecaptchaController.verifyCaptcha('good-token', 'login');
        Test.stopTest();

        System.assertEquals(true, result);
    }

    @isTest
    static void testVerify_success_v2NoScoreNoAction() {
        if (!isConfigured()) return;

        Test.setMock(HttpCalloutMock.class,
            new RecaptchaHttpMock(200, '{"success":true}'));

        Test.startTest();
        Boolean result = RecaptchaController.verifyCaptcha('good-token', null);
        Test.stopTest();

        System.assertEquals(true, result);
    }

    @isTest
    static void testVerify_googleReportsFailure() {
        if (!isConfigured()) return;

        Test.setMock(HttpCalloutMock.class,
            new RecaptchaHttpMock(200, '{"success":false,"error-codes":["invalid-input-response"]}'));

        Boolean threw = false;
        Test.startTest();
        try {
            RecaptchaController.verify('bad-token', 'login');
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();
        System.assert(threw, 'Expected failure when Google reports success=false');
    }

    @isTest
    static void testVerify_scoreBelowThreshold() {
        if (!isConfigured()) return;

        Test.setMock(HttpCalloutMock.class,
            new RecaptchaHttpMock(200, '{"success":true,"score":0.1,"action":"login"}'));

        Boolean threw = false;
        Test.startTest();
        try {
            RecaptchaController.verify('low-score-token', 'login');
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();
        System.assert(threw, 'Expected failure due to score below threshold');
    }

    @isTest
    static void testVerify_actionMismatch() {
        if (!isConfigured()) return;

        Test.setMock(HttpCalloutMock.class,
            new RecaptchaHttpMock(200, '{"success":true,"score":0.9,"action":"signup"}'));

        Boolean threw = false;
        Test.startTest();
        try {
            RecaptchaController.verify('token', 'login');
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();
        System.assert(threw, 'Expected failure due to action mismatch');
    }

    @isTest
    static void testVerify_serviceReturnsNon200() {
        if (!isConfigured()) return;

        Test.setMock(HttpCalloutMock.class,
            new RecaptchaHttpMock(503, 'Service Unavailable'));

        Boolean threw = false;
        Test.startTest();
        try {
            RecaptchaController.verify('token', 'login');
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();
        System.assert(threw, 'Expected failure on non-200 response');
    }

    @isTest
    static void testVerify_calloutException() {
        if (!isConfigured()) return;

        Test.setMock(HttpCalloutMock.class, new ThrowingHttpMock());

        Boolean threw = false;
        Test.startTest();
        try {
            RecaptchaController.verify('token', 'login');
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();
        System.assert(threw, 'Expected failure when the callout itself throws');
    }
}