public without sharing class MemberFeedbackController {

    private static final Integer MIN_NPS_SCORE = 0;
    private static final Integer MAX_NPS_SCORE = 10;
    private static final Integer MIN_STAR_SCORE = 1;
    private static final Integer MAX_STAR_SCORE = 5;
    private static final Integer MAX_COMMENT_LENGTH = 1000;
    private static final String OTHER_LABEL = 'Other (please specify)';

    //private static final String CACHE_PARTITION = 'local.feedbackLimiter';
    private static final Integer MAX_SUBMISSIONS_PER_MEMBER = 3;
    private static final Integer SUBMIT_WINDOW_SECONDS = 60;

    /**
     * Wire wrapper for saveFeedback. The survey grew to ~29 answer fields
     * with the revised questionnaire, so individual @AuraEnabled method
     * params were replaced with a single input object - the LWC builds a
     * plain JS object literal and passes it straight through.
     */
    public class FeedbackInput {
        @AuraEnabled public String membershipId { get; set; }
        @AuraEnabled public String memberToken { get; set; }
        @AuraEnabled public String storeCode { get; set; }

        // Section A - Your visit today
        @AuraEnabled public String tripMission { get; set; }
        @AuraEnabled public String availability { get; set; }
        @AuraEnabled public List<String> availabilityItems { get; set; }
        @AuraEnabled public List<String> availabilityFollowUp { get; set; }
        @AuraEnabled public String availabilityFollowUpOther { get; set; }
        @AuraEnabled public String checkout { get; set; }

        // Section B - Satisfaction star matrix
        @AuraEnabled public Integer rateStoreAppearance { get; set; }
        @AuraEnabled public Integer rateFreshItems { get; set; }
        @AuraEnabled public Integer rateProductAvailability { get; set; }
        @AuraEnabled public Integer rateValueForMoney { get; set; }
        @AuraEnabled public Integer rateCheckoutExperience { get; set; }
        @AuraEnabled public Integer rateFoodChoices { get; set; }
        @AuraEnabled public String satisfactionFollowUp { get; set; }

        // Section C - Fresh / competitive / leakage
        @AuraEnabled public String freshSection { get; set; }
        @AuraEnabled public List<String> freshSectionFollowUp { get; set; }
        @AuraEnabled public String freshSectionFollowUpOther { get; set; }
        @AuraEnabled public List<String> shareOfWallet { get; set; }
        @AuraEnabled public String shareOfWalletTop { get; set; }
        @AuraEnabled public List<String> shareOfWalletBetter { get; set; }
        @AuraEnabled public String shareOfWalletBetterOther { get; set; }
        @AuraEnabled public String leakage { get; set; }
        @AuraEnabled public String leakageFollowUp { get; set; }
        @AuraEnabled public String leakageFollowUpOther { get; set; }

        // Section D - Value, NPS, renewal
        @AuraEnabled public List<String> pricing { get; set; }
        @AuraEnabled public String pricingOther { get; set; }
        @AuraEnabled public Integer recommendScore { get; set; }
        @AuraEnabled public List<String> promoterReasons { get; set; }
        @AuraEnabled public String promoterOther { get; set; }
        @AuraEnabled public String passiveComment { get; set; }
        @AuraEnabled public List<String> detractorReasons { get; set; }
        @AuraEnabled public String detractorOther { get; set; }
        @AuraEnabled public Boolean serviceRecoveryConsent { get; set; }
        @AuraEnabled public String serviceRecoveryPhone { get; set; }
        @AuraEnabled public String renewalIntent { get; set; }
        @AuraEnabled public List<String> renewalReasonsLikely { get; set; }
        @AuraEnabled public List<String> renewalReasonsAtRisk { get; set; }
        @AuraEnabled public String renewalReasonsAtRiskOther { get; set; }
        @AuraEnabled public String renewalClosing { get; set; }

        // Section E - Keeping in touch
        @AuraEnabled public List<String> campaignChannels { get; set; }

        // Section F - Closing
        @AuraEnabled public String storePriority { get; set; }
        @AuraEnabled public String storePriorityComment { get; set; }
        @AuraEnabled public String openFeedback { get; set; }
    }

    @AuraEnabled
    public static void saveFeedback(FeedbackInput input) {
        try {
            if (input == null) {
                throw new AuraHandledException('Missing feedback payload.');
            }

            validateInput(input);
            //enforceSubmissionRateLimit(input.membershipId);

            Id contactId = MemberFeedbackLookupController.resolveMemberToken(input.memberToken, input.membershipId);

            List<Contact> matches = [
                SELECT Id
                FROM Contact
                WHERE Id = :contactId
                AND Membership_ID__c = :input.membershipId
                LIMIT 1
            ];

            if (matches.isEmpty()) {
                throw new AuraHandledException('Unable to verify member.');
            }

            Member_Feedback__c record = new Member_Feedback__c();
            record.Contact_ID__c = contactId;
            record.Store_Code__c = input.storeCode;

            // Section A
            record.Trip_Mission__c = input.tripMission;
            record.Availability__c = input.availability;
            record.Availability_Open_Text__c = joinList(input.availabilityItems);
            record.Availability_Follow_Up__c = joinListWithOther(input.availabilityFollowUp, input.availabilityFollowUpOther);
            record.Checkout__c = input.checkout;

            // Section B
            record.Rate_Store_Appearance__c = clampStar(input.rateStoreAppearance);
            record.Rate_Fresh_Items__c = clampStar(input.rateFreshItems);
            record.Rate_Product_Availability__c = clampStar(input.rateProductAvailability);
            record.Rate_Value_For_Money__c = clampStar(input.rateValueForMoney);
            record.Rate_Checkout_Experience__c = clampStar(input.rateCheckoutExperience);
            record.Rate_Food_Choices__c = clampStar(input.rateFoodChoices);
            record.Satisfaction_Follow_Up__c = truncate(input.satisfactionFollowUp, MAX_COMMENT_LENGTH);

            // Section C
            record.Fresh_Section__c = input.freshSection;
            record.Fresh_Section_Follow_Up__c = joinListWithOther(input.freshSectionFollowUp, input.freshSectionFollowUpOther);
            record.Share_Of_Wallet__c = joinList(input.shareOfWallet);
            record.Share_Of_Wallet_a__c = input.shareOfWalletTop;
            record.Share_Of_Wallet_b__c = joinListWithOther(input.shareOfWalletBetter, input.shareOfWalletBetterOther);
            record.Leakage__c = input.leakage;
            record.Leakage_Follow_Up__c = resolveSingleWithOther(input.leakageFollowUp, input.leakageFollowUpOther);

            // Section D
            record.Pricing__c = joinListWithOther(input.pricing, input.pricingOther);
            record.Rate_Recommendation__c = input.recommendScore;
            record.Rate_Recommendation_Promoters__c = joinListWithOther(input.promoterReasons, input.promoterOther);
            record.Rate_Recommendation_Passive__c = truncate(input.passiveComment, MAX_COMMENT_LENGTH);
            record.Rate_Recommendation_Detractors__c = joinListWithOther(input.detractorReasons, input.detractorOther);
            record.Service_Recovery_Consent__c = input.serviceRecoveryConsent == true;
            record.Service_Recovery_Phone__c = truncate(input.serviceRecoveryPhone, 40);
            record.Renewal__c = input.renewalIntent;
            record.Renewal_Comments_1__c = joinList(input.renewalReasonsLikely);
            record.Renewal_Comments_2__c = joinListWithOther(input.renewalReasonsAtRisk, input.renewalReasonsAtRiskOther);
            record.Renewal_Comments_2_Closing__c = input.renewalClosing;

            // Section E
            record.Campaign_Reach__c = joinList(input.campaignChannels);

            // Section F
            record.Store_Experience__c = input.storePriority;
            record.Store_Experience_Comments__c = truncate(input.storePriorityComment, MAX_COMMENT_LENGTH);
            record.Open_Feedback__c = truncate(input.openFeedback, MAX_COMMENT_LENGTH);

            SObjectAccessDecision decision = Security.stripInaccessible(
                AccessType.CREATABLE,
                new List<Member_Feedback__c>{ record }
            );
            insert decision.getRecords();

        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (MemberFeedbackLookupController.SecurityException se) {
            throw new AuraHandledException('We could not verify your request. Please try again.');
        } catch (DmlException de) {
            System.debug(LoggingLevel.ERROR, 'Feedback DML error: ' + de.getMessage());
            throw new AuraHandledException('We could not save your feedback. Please try again later.');
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Unexpected feedback error: ' + e.getTypeName() + ' - ' + e.getMessage() + ' at line ' + e.getLineNumber());
            throw new AuraHandledException('Something went wrong. Please try again later.');
        }
    }

    // --- internal helpers ---

    private static void validateInput(FeedbackInput input) {
        if (String.isBlank(input.membershipId)) {
            throw new AuraHandledException('Membership ID is required.');
        }
        if (String.isBlank(input.storeCode) || !isValidStoreCode(input.storeCode)) {
            throw new AuraHandledException('Please select a valid store.');
        }
        if (input.recommendScore == null || input.recommendScore < MIN_NPS_SCORE || input.recommendScore > MAX_NPS_SCORE) {
            throw new AuraHandledException('Recommendation score is invalid.');
        }
    }

    private static Boolean isValidStoreCode(String storeCode) {
        for (Store_Setting__mdt s : Store_Setting__mdt.getAll().values()) {
            if (s.Is_Active__c && s.Store_Code__c == storeCode) {
                return true;
            }
        }
        return false;
    }

    /** Clamps a star-matrix rating to the 1-5 range, or returns null if unanswered. */
    private static Integer clampStar(Integer value) {
        if (value == null) {
            return null;
        }
        if (value < MIN_STAR_SCORE) {
            return MIN_STAR_SCORE;
        }
        if (value > MAX_STAR_SCORE) {
            return MAX_STAR_SCORE;
        }
        return value;
    }

    private static String joinList(List<String> values) {
        if (values == null || values.isEmpty()) {
            return null;
        }
        return truncate(String.join(values, '; '), MAX_COMMENT_LENGTH);
    }

    /**
     * Joins a multi-select answer into a single text field, substituting the
     * literal "Other (please specify)" choice with the free-text the member
     * typed (e.g. "Other: left my discount card at home").
     */
    private static String joinListWithOther(List<String> values, String otherText) {
        if (values == null || values.isEmpty()) {
            return null;
        }
        List<String> resolved = new List<String>();
        for (String v : values) {
            if (v == OTHER_LABEL) {
                if (String.isNotBlank(otherText)) {
                    resolved.add('Other: ' + otherText);
                }
            } else if (String.isNotBlank(v)) {
                resolved.add(v);
            }
        }
        if (resolved.isEmpty()) {
            return null;
        }
        return truncate(String.join(resolved, '; '), MAX_COMMENT_LENGTH);
    }

    /** Same substitution as joinListWithOther but for a single-select answer. */
    private static String resolveSingleWithOther(String value, String otherText) {
        if (String.isBlank(value)) {
            return null;
        }
        if (value == OTHER_LABEL) {
            return String.isNotBlank(otherText) ? truncate('Other: ' + otherText, MAX_COMMENT_LENGTH) : null;
        }
        return truncate(value, MAX_COMMENT_LENGTH);
    }

    private static String truncate(String s, Integer maxLen) {
        if (String.isBlank(s)) {
            return s;
        }
        return s.length() > maxLen ? s.substring(0, maxLen) : s;
    }

    // private static void enforceSubmissionRateLimit(String membershipId) {
    //     if (String.isBlank(membershipId)) {
    //         // Should never happen if validateInput() runs first, but guards
    //         // against a raw NullPointerException from Blob.valueOf(null)
    //         // if this method is ever called before validation again.
    //         throw new AuraHandledException('Membership ID is required.');
    //     }
    //     try {
    //         Cache.Partition part = Cache.Org.getPartition(CACHE_PARTITION);
    //         Blob hash = Crypto.generateDigest('SHA-256', Blob.valueOf(membershipId));
    //         String key = 'submit' + EncodingUtil.convertToHex(hash).substring(0, 40);

    //         Integer attempts = (Integer) part.get(key);
    //         attempts = attempts == null ? 0 : attempts;

    //         if (attempts >= MAX_SUBMISSIONS_PER_MEMBER) {
    //             throw new AuraHandledException('You have already submitted feedback recently. Thank you!');
    //         }
    //         part.put(key, attempts + 1, SUBMIT_WINDOW_SECONDS);
    //     } catch (Cache.Org.OrgCacheException ce) {
    //         System.debug(LoggingLevel.ERROR, 'Rate limit cache unavailable: ' + ce.getMessage());
    //         throw new AuraHandledException('Service temporarily unavailable. Please try again shortly.');
    //     }
    // }

    public class StoreOption {
        @AuraEnabled public String code;
        @AuraEnabled public String name;
    }

    @AuraEnabled(cacheable=true)
    public static List<StoreOption> getActiveStores() {
        List<StoreOption> options = new List<StoreOption>();
        for (Store_Setting__mdt s : Store_Setting__mdt.getAll().values()) {
            if (s.Is_Active__c) {
                StoreOption opt = new StoreOption();
                opt.code = s.Store_Code__c;
                opt.name = String.isNotBlank(s.Store_Name__c) ? s.Store_Name__c : s.Store_Code__c;
                options.add(opt);
            }
        }
        return options;
    }
}