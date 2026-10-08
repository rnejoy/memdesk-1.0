/**
 * Backs the Pag-IBIG one-day pass kiosk.
 *
 * The day pass is a single shared Landers membership
 * (PAG IBIG LANDERS ALL STORE DAYPASS, ID 20208800006500). Nothing unique
 * is minted per visitor — the kiosk exists to capture the registration and
 * to enforce one pass per Pag-IBIG member.
 *
 * REQUIRED ON LEAD — create this before deploying:
 *   Pag_IBIG_ID__c   Text(12), External Id, **Unique**
 *
 * Standard fields used: FirstName, MiddleName, LastName, Company,
 * MobilePhone, Birthdate__c.
 *
 * Company is a required standard field on Lead — an insert without it
 * fails with REQUIRED_FIELD_MISSING — so it is set to a constant.
 *
 * Kiosk registrations are identified by Pag_IBIG_ID__c being non-null.
 * LeadSource is not set, so reports and campaign filters must use that
 * field rather than a source value.
 *
 * The Unique flag is what actually prevents a second pass. The pre-check
 * is for a clean message; the constraint is for correctness, since two
 * kiosks can scan the same card in the same second.
 *
 * `without sharing` is deliberate: the duplicate check must see Leads
 * created at *every* branch. Under `with sharing` a card used in Cebu
 * would look unused in Aseana and the rule would silently stop working.
 * The class returns no Lead data to the browser — checkPagIbigId answers
 * with a boolean and a message only.
 */
public without sharing class DayPassController {

    private static final String LEAD_COMPANY = 'PAG-IBIG Member';
    @TestVisible
    private static final String USED_MESSAGE =
        'Daypass already been used for this Pag-IBIG member.';

    // 11 digits, must start 09. Matches what the kiosk accepts.
    private static final String MOBILE_PATTERN = '^09[0-9]{9}$';

    public class CheckResult {
        @AuraEnabled public Boolean available;
        @AuraEnabled public String message;
    }

    public class PassResult {
        @AuraEnabled public String pagIbigId;
        @AuraEnabled public String validOn;
    }

    /**
     * Called the moment a card is scanned, before the member fills anything
     * in. Returns only a boolean and a message — never Lead data — so the
     * endpoint cannot be used to read records by guessing IDs.
     */
    @AuraEnabled(cacheable=false)
    public static CheckResult checkPagIbigId(String pagIbigId) {
        String id12 = digitsOnly(pagIbigId);
        CheckResult r = new CheckResult();

        if (id12.length() != 12) {
            r.available = false;
            r.message = 'That does not look like a 12-digit Pag-IBIG ID.';
            return r;
        }

        // Converted leads still count — the pass was used.
        Integer used = [SELECT COUNT() FROM Lead WHERE Pag_IBIG_ID__c = :id12];

        r.available = (used == 0);
        r.message = r.available ? null : USED_MESSAGE;
        return r;
    }

    @AuraEnabled
    public static PassResult issueDayPass(
        String pagIbigId,
        String firstName,
        String middleName,
        String lastName,
        String mobile,
        String birthdate
    ) {
        String id12 = digitsOnly(pagIbigId);
        String mobileNo = digitsOnly(mobile);

        // A browser-facing endpoint must never trust the client, logged in
        // or not, so everything the kiosk validates is validated again here.
        if (id12.length() != 12) {
            throw new AuraHandledException('Pag-IBIG ID must be 12 digits.');
        }
        if (String.isBlank(firstName) || String.isBlank(lastName)) {
            throw new AuraHandledException('First and last name are required.');
        }
        if (!Pattern.matches(MOBILE_PATTERN, mobileNo)) {
            throw new AuraHandledException(
                'Mobile number must be 11 digits starting with 09.');
        }
        Date bd;
        if (String.isBlank(birthdate)) {
            throw new AuraHandledException('Birthdate is required.');
        }
        try {
            // Kiosk sends an ISO yyyy-MM-dd string from the <input type=date>.
            // Parse the parts explicitly — Date.valueOf expects a datetime and
            // is locale-sensitive, so it is unreliable for a bare date string.
            List<String> p = birthdate.split('-');
            bd = Date.newInstance(
                Integer.valueOf(p[0]),
                Integer.valueOf(p[1]),
                Integer.valueOf(p[2])
            );
        } catch (Exception e) {
            throw new AuraHandledException('Birthdate is not a valid date.');
        }
        if (bd > Date.today()) {
            throw new AuraHandledException('Birthdate cannot be in the future.');
        }
        if (bd < Date.today().addYears(-120)) {
            throw new AuraHandledException('Birthdate is not valid.');
        }

        if ([SELECT COUNT() FROM Lead WHERE Pag_IBIG_ID__c = :id12] > 0) {
            throw new AuraHandledException(USED_MESSAGE);
        }

        Lead l = new Lead(
            FirstName        = truncate(firstName, 40),
            MiddleName       = String.isBlank(middleName) ? null : truncate(middleName, 40),
            LastName         = truncate(lastName, 80),
            Company          = LEAD_COMPANY,
            MobilePhone      = mobileNo,
            Pag_IBIG_ID__c   = id12,
            Birthdate__c     = bd,
            ReferenceNumber__c = nextReference()
        );

        // Standard Lead duplicate rules match on name and would
        // block a registration for someone already in the database for
        // unrelated reasons. Pag-IBIG uniqueness is the rule that governs.
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.DuplicateRuleHeader.AllowSave = true;
        dmo.optAllOrNone = true;

        try {
            Database.insert(l, dmo);
        } catch (DmlException e) {
            // Two kiosks scanning the same card at once land here; the
            // unique constraint on Pag_IBIG_ID__c is what catches it.
            if (e.getMessage().contains('DUPLICATE_VALUE')) {
                throw new AuraHandledException(USED_MESSAGE);
            }
            throw new AuraHandledException(
                'Could not complete the registration: ' + e.getDmlMessage(0));
        }

        PassResult r = new PassResult();
        r.pagIbigId = formatId(id12);
        r.validOn   = Date.today().format();
        return r;
    }

    /*
     * Mints the next reference: 'PBG' + a 9-digit zero-padded running number
     * = exactly 12 chars, e.g. PBG000000001. Backend only, no helper object.
     *
     * SOQL forbids ORDER BY with FOR UPDATE (locking implies Id order), so we
     * find the current maximum with an aggregate MAX() instead of an ordered
     * top-1. MAX on the zero-padded PBG strings is correct because equal-length
     * strings compare lexically the same as numerically.
     *
     * CONCURRENCY: this is a read-then-write, so two registrations in the same
     * instant could compute the same number. For a staff-assisted kiosk
     * handling one member at a time that window is effectively nil. It is not
     * the absolute guarantee an auto-number gives; if a duplicate ever appears
     * under heavy simultaneous load, that is the signal to move the sequence
     * onto an auto-number field/object.
     */
    private static String nextReference() {
        Integer nextNum = 1;
        AggregateResult ar = [
            SELECT MAX(ReferenceNumber__c) maxRef
            FROM Lead
            WHERE ReferenceNumber__c LIKE 'PBG%'
        ];
        String maxRef = (String) ar.get('maxRef');
        if (String.isNotBlank(maxRef)) {
            String digits = maxRef.replaceAll('[^0-9]', '');
            if (String.isNotBlank(digits)) {
                nextNum = Integer.valueOf(digits) + 1;
            }
        }
        String padded = String.valueOf(nextNum);
        while (padded.length() < 9) {
            padded = '0' + padded;
        }
        return 'PBG' + padded;
    }

    /** Field lengths are FirstName 40, MiddleName 40, LastName 80. */
    private static String truncate(String v, Integer max) {
        String t = v == null ? '' : v.trim();
        return t.length() > max ? t.substring(0, max) : t;
    }

    /** Stores 1234-5678-9012 and 123456789012 identically. */
    private static String digitsOnly(String raw) {
        return String.isBlank(raw) ? '' : raw.replaceAll('[^0-9]', '');
    }

    private static String formatId(String digits) {
        if (String.isBlank(digits) || digits.length() != 12) return digits;
        return digits.substring(0, 4) + '-' + digits.substring(4, 8) + '-' + digits.substring(8, 12);
    }
}