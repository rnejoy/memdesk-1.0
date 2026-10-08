public with sharing class RecaptchaController {

    private static final String  VERIFY_ENDPOINT         = 'https://www.google.com/recaptcha/api/siteverify';
    private static final Decimal DEFAULT_SCORE_THRESHOLD = 0.5;

    // ── Public site key, safe to expose to the client ───────────────────────
    @AuraEnabled(cacheable=true)
    public static String getSiteKey() {
        Recaptcha_Setting__mdt setting = getSetting();
        if (setting == null || String.isBlank(setting.Site_Key__c)) {
            throw new AuraHandledException('reCAPTCHA is not configured for this org.');
        }
        return setting.Site_Key__c;
    }

    // ── Server-side verification. The secret key never leaves Apex. ────────
    @AuraEnabled
    public static Boolean verifyCaptcha(String token, String action) {
        verify(token, action);
        return true;
    }

    // Plain Apex entry point (no @AuraEnabled boundary) so other server-side
    // code — like RegistrationController.createRegistration — can verify the
    // captcha as part of its own transaction, rather than relying on the
    // client having called verifyCaptcha first. Throws on any failure.
    public static void verify(String token, String action) {
        if (String.isBlank(token)) {
            throw new AuraHandledException('Missing captcha token.');
        }

        Recaptcha_Setting__mdt setting = getSetting();
        if (setting == null || String.isBlank(setting.Secret_Key__c)) {
            throw new AuraHandledException('reCAPTCHA is not configured for this org.');
        }

        HttpResponse res = sendVerifyRequest(setting.Secret_Key__c, token);

        if (res.getStatusCode() != 200) {
            throw new AuraHandledException('Captcha verification service is unavailable. Please try again.');
        }

        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

        Boolean success = result.get('success') == true;
        if (!success) {
            throw new AuraHandledException('Captcha verification failed. Please try again.');
        }

        // v3 responses include a score (0–1) and the action name; v2 checkbox/image
        // challenge responses include neither. Only enforce these when present, so
        // this method works correctly against either captcha type without changes.
        if (result.get('score') != null) {
            Decimal score    = (Decimal) result.get('score');
            Decimal minScore = setting.Score_Threshold__c != null ? setting.Score_Threshold__c : DEFAULT_SCORE_THRESHOLD;
            if (score < minScore) {
                throw new AuraHandledException('Captcha verification failed. Please try again.');
            }
        }

        Object returnedAction = result.get('action');
        if (String.isNotBlank(action) && returnedAction != null && action != (String) returnedAction) {
            throw new AuraHandledException('Captcha verification failed. Please try again.');
        }
    }

    private static HttpResponse sendVerifyRequest(String secretKey, String token) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(VERIFY_ENDPOINT);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setBody(
            'secret='    + EncodingUtil.urlEncode(secretKey, 'UTF-8') +
            '&response=' + EncodingUtil.urlEncode(token, 'UTF-8')
        );

        try {
            return new Http().send(req);
        } catch (Exception e) {
            throw new AuraHandledException('Unable to reach the captcha verification service. Please try again.');
        }
    }

    private static Recaptcha_Setting__mdt getSetting() {
        List<Recaptcha_Setting__mdt> settings = [
            SELECT Site_Key__c, Secret_Key__c, Score_Threshold__c
            FROM Recaptcha_Setting__mdt
            WHERE DeveloperName = 'Default'
            LIMIT 1
        ];
        return settings.isEmpty() ? null : settings[0];
    }
}