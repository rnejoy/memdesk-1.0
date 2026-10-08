import { LightningElement, track } from 'lwc';
import findMember from '@salesforce/apex/MemberFeedbackLookupController.findMember';
import saveFeedback from '@salesforce/apex/MemberFeedbackController.saveFeedback';
import getActiveStores from '@salesforce/apex/MemberFeedbackController.getActiveStores';
import {
    SECTIONS,
    OTHER_OPTION,
    NONE_WALLET_OPTION,
    CUSTOM_CONDITIONS,
    getLowSatisfactionRows
} from './surveyQuestions';

const PHASE_LANDING = 'landing';
const PHASE_QUESTIONS = 'questions';
const PHASE_THANKYOU = 'thankyou';
const OTHER_OPTION_LABEL = OTHER_OPTION;

export default class FeedbackForm extends LightningElement {

    phase = PHASE_LANDING;
    membershipId = '';
    memberToken = null;
    firstName = 'Visitor';

    @track isVerified = false;
    @track selectedStore = '';
    @track storeOptions = [];
    errorMessage = '';

    // Single answer bag for the whole survey.
    // Shape: { Q1_TRIP: '...', Q4_SATISFACTION: { appearance: 4, ... }, ... }
    @track answers = {};

    // Free-text "Other, please specify" values, keyed by question id.
    @track otherText = {};

    // Index into the *currently visible* question list (recomputed every render).
    questionIndex = 0;

    consentGiven = false;
    showModal = false;

    get displayName() {
        return this.firstName ? this.firstName : 'Visitor';
    }

    get selectedStoreName() {
        const match = this.storeOptions.find((s) => s.value === this.selectedStore);
        return match ? match.label : 'Unknown Store';
    }

    get isLanding() { return this.phase === PHASE_LANDING; }
    get isQuestions() { return this.phase === PHASE_QUESTIONS; }
    get isThankYou() { return this.phase === PHASE_THANKYOU; }

    connectedCallback() {
        this.loadStores();
        try {
            const savedStore = window.localStorage.getItem('landersStoreCode');
            if (savedStore) {
                this.selectedStore = savedStore;
                this.isVerified = true;
            }
        } catch (err) {
            console.error('Storage reading error:', err);
        }
    }

    loadStores() {
        getActiveStores()
            .then((result) => {
                this.storeOptions = result.map((s) => ({ label: s.name, value: s.code }));
            })
            .catch((err) => {
                console.error('Failed to load stores:', err);
                this.showError('Unable to load store list.');
            });
    }

    handleStoreChange(event) {
        this.selectedStore = event.detail.value;
        this.isVerified = !!this.selectedStore;
        try {
            window.localStorage.setItem('landersStoreCode', this.selectedStore);
        } catch (e) {
            console.error('Storage locking failed:', e);
        }
    }

    handleInputChange(event) {
        this.membershipId = event.target.value.trim();
    }

    handleMembershipKey(event) {
        if (event.key === 'Enter') {
            this.lookupMember();
        }
    }

    lookupMember() {
        if (!this.membershipId) return;

        findMember({ membershipId: this.membershipId })
            .then((result) => {
                if (result) {
                    this.memberToken = result.token;
                    this.firstName = result.firstName;
                    this.errorMessage = '';
                    this.phase = PHASE_QUESTIONS;
                    this.questionIndex = 0;
                } else {
                    this.memberToken = null;
                    this.firstName = '';
                    this.showError('Membership ID not found.');
                }
            })
            .catch((err) => {
                console.error(err);
                this.memberToken = null;
                this.firstName = '';
                this.showError('Unable to validate Membership ID.');
            });
    }

    // ---------------------------------------------------------------
    // Schema engine
    // ---------------------------------------------------------------

    /**
     * Flattens all sections into one ordered question list, filtered by
     * showIf against the answers collected so far.
     */
    get visibleQuestions() {
        return SECTIONS.flatMap((s) => s.questions).filter((q) => this.evaluateShowIf(q.showIf));
    }

    evaluateShowIf(condition) {
        if (!condition) return true;

        // Conditions that depend on more than one prior answer live in
        // CUSTOM_CONDITIONS (surveyQuestions.js) and are referenced by name.
        if (condition.custom) {
            const fn = CUSTOM_CONDITIONS[condition.custom];
            return fn ? fn(this.answers) : true;
        }

        const answer = this.answers[condition.question];

        if (condition.answered !== undefined) {
            const hasAnswer = Array.isArray(answer) ? answer.length > 0 : !!answer;
            return condition.answered ? hasAnswer : !hasAnswer;
        }
        if (condition.equals !== undefined) return answer === condition.equals;
        if (condition.notEquals !== undefined) return answer !== condition.notEquals && answer !== undefined && answer !== null;
        if (condition.in !== undefined) return condition.in.includes(answer);
        if (condition.scoreBetween) {
            const [min, max] = condition.scoreBetween;
            return typeof answer === 'number' && answer >= min && answer <= max;
        }
        return true;
    }

    /** Single source of truth for "what question am I on" - clamps if a branch collapsed the list. */
    get currentQuestion() {
        const list = this.visibleQuestions;
        if (this.questionIndex >= list.length) {
            this.questionIndex = Math.max(0, list.length - 1);
        }
        return list[this.questionIndex];
    }

    /**
     * The literal category text from the xlsx "Category" column for the
     * current question (e.g. "Satisfaction", "Trip Mission"). Deliberately
     * NOT the SECTIONS.title grouping - that label ("How we are doing",
     * "Your visit today", etc.) doesn't exist in the source sheet.
     */
    get currentSectionTitle() {
        const q = this.currentQuestion;
        return q && q.category ? q.category : '';
    }

    /**
     * Ordered list of distinct categories (per the xlsx "Category" column)
     * among the *currently visible* questions - i.e. only categories the
     * respondent will actually pass through given their answers so far.
     * Mutually-exclusive branches (e.g. NPS Promoters/Passives/Detractors,
     * Renewal - likely/at risk) only ever contribute one entry each, since
     * showIf already filters out the ones that don't apply.
     */
    get categoryList() {
        const list = [];
        this.visibleQuestions.forEach((q) => {
            if (q.category && !list.includes(q.category)) {
                list.push(q.category);
            }
        });
        return list;
    }

    /** 1-based position of the current question's category within categoryList. */
    get currentCategoryIndex() {
        const q = this.currentQuestion;
        if (!q || !q.category) return 1;
        const idx = this.categoryList.indexOf(q.category);
        return idx >= 0 ? idx + 1 : 1;
    }

    get totalCategories() {
        return this.categoryList.length;
    }

    get progressLabel() {
        return `Category ${this.currentCategoryIndex} of ${this.totalCategories}`;
    }

    get isFirstQuestion() { return this.questionIndex === 0; }
    get isLastQuestion() { return this.questionIndex === this.visibleQuestions.length - 1; }
    get nextLabel() { return this.isLastQuestion ? 'Submit' : 'Next'; }

    // Type-check getters used by the template to switch renderers
    get isTypeSingleSelect() {
        const t = this.currentQuestion?.type;
        return t === 'single-select' || t === 'single-select-dynamic';
    }
    get isTypeMultiSelect() { return this.currentQuestion?.type === 'multi-select'; }
    get isTypeOpenText() { return this.currentQuestion?.type === 'open-text'; }
    get isTypeOpenTextMulti() { return this.currentQuestion?.type === 'open-text-multi'; }
    get isTypeStarMatrix() { return this.currentQuestion?.type === 'star-matrix'; }
    get isTypeSatisfactionFollowup() { return this.currentQuestion?.type === 'satisfaction-followup'; }
    get isTypeNPS() { return this.currentQuestion?.type === 'nps-scale'; }
    get isTypeYesNo() { return this.currentQuestion?.type === 'yes-no'; }
    get isTypeCheckbox() { return this.currentQuestion?.type === 'checkbox'; }

    get currentOptions() {
        const q = this.currentQuestion;
        if (!q) return [];
        const selected = this.answers[q.id];

        let optionList = q.options || [];
        if (q.optionsSource) {
            const sourceAnswer = this.answers[q.optionsSource] || [];
            const dynamic = sourceAnswer.filter((v) => v !== NONE_WALLET_OPTION);
            optionList = [...new Set([...(q.alwaysInclude || []), ...dynamic])];
        }

        return optionList.map((label) => ({
            label,
            value: label,
            selected: Array.isArray(selected) ? selected.includes(label) : selected === label
        }));
    }

    /** True when the current question allows "Other" and the person has selected it. */
    get showOtherTextInput() {
        const q = this.currentQuestion;
        if (!q || !q.allowOther) return false;
        const selected = this.answers[q.id];
        return Array.isArray(selected)
            ? selected.includes(OTHER_OPTION_LABEL)
            : selected === OTHER_OPTION_LABEL;
    }

    get currentOtherText() {
        return this.otherText[this.currentQuestion?.id] || '';
    }

    /** Inline optional free-text note attached to the current question (e.g. Q12_PRIORITY's "Tell us more"). */
    get currentOptionalComment() {
        return this.currentQuestion?.optionalComment || null;
    }

    get currentOptionalCommentValue() {
        const comment = this.currentOptionalComment;
        return comment ? this.answers[comment.id] || '' : '';
    }

    handleOptionalCommentChange(event) {
        const comment = this.currentOptionalComment;
        if (!comment) return;
        this.answers = { ...this.answers, [comment.id]: event.target.value };
    }

    get currentNpsStars() {
        const q = this.currentQuestion;
        const score = (q && this.answers[q.id]) || 0;
        return this.createStars(score, 10);
    }

    get currentStarRows() {
        const q = this.currentQuestion;
        if (!q || !q.rows) return [];
        const answer = this.answers[q.id] || {};
        return q.rows.map((r) => ({
            key: r.key,
            label: r.label,
            stars: this.createStars(answer[r.key] || 0, 5)
        }));
    }

    get currentSatisfactionFollowUps() {
        const rows = getLowSatisfactionRows(this.answers);
        const stored = this.answers.Q4_FOLLOWUP || {};
        return rows.map((r) => ({
            key: r.key,
            label: r.label,
            score: r.score,
            prompt: `You gave "${r.label}" a ${r.score}. What would make it a 5 for you?`,
            value: stored[r.key] || ''
        }));
    }

    get currentCheckboxChecked() {
        return this.answers[this.currentQuestion?.id] === true;
    }

    /** Drives the selected/green styling on the Yes/No buttons (mirrors opt.selected for single/multi-select). */
    get isYesSelected() {
        return this.currentQuestion && this.answers[this.currentQuestion.id] === 'Yes';
    }
    get isNoSelected() {
        return this.currentQuestion && this.answers[this.currentQuestion.id] === 'No';
    }

    get currentQuestionMaxItemsArray() {
        return this.currentQuestion?.maxItemsArray || [];
    }

    createStars(value, total = 5) {
        return Array.from({ length: total }, (_, i) => ({
            index: i + 1,
            className: i + 1 <= value ? 'star filled' : 'star'
        }));
    }

    // ---------------------------------------------------------------
    // Answer handlers
    // ---------------------------------------------------------------

    handleSingleSelect(event) {
        const value = event.currentTarget.dataset.value;
        this.answers = { ...this.answers, [this.currentQuestion.id]: value };
        this.errorMessage = '';
    }

    handleMultiSelect(event) {
        const value = event.currentTarget.dataset.value;
        const qId = this.currentQuestion.id;
        const current = this.answers[qId] || [];
        const maxItems = this.currentQuestion.maxItems;

        let updated;
        if (current.includes(value)) {
            updated = current.filter((v) => v !== value);
        } else {
            if (maxItems && current.length >= maxItems) {
                this.showError(`Please choose up to ${maxItems}.`);
                return;
            }
            updated = [...current, value];
        }
        this.answers = { ...this.answers, [qId]: updated };
        this.errorMessage = '';
    }

    handleOpenTextChange(event) {
        this.answers = { ...this.answers, [this.currentQuestion.id]: event.target.value };
    }

    handleOpenTextMultiItemChange(event) {
        const idx = parseInt(event.currentTarget.dataset.index, 10);
        const qId = this.currentQuestion.id;
        const current = [...(this.answers[qId] || [])];
        current[idx] = event.target.value;
        this.answers = { ...this.answers, [qId]: current };
    }

    handleOtherTextChange(event) {
        this.otherText = { ...this.otherText, [this.currentQuestion.id]: event.target.value };
    }

    handleNpsClick(event) {
        const index = parseInt(event.currentTarget.dataset.index, 10);
        this.answers = { ...this.answers, [this.currentQuestion.id]: index };
    }

    handleStarClick(event) {
        const rowKey = event.currentTarget.dataset.rowKey;
        const index = parseInt(event.currentTarget.dataset.index, 10);
        const qId = this.currentQuestion.id;
        const current = { ...(this.answers[qId] || {}) };
        current[rowKey] = index;
        this.answers = { ...this.answers, [qId]: current };
    }

    handleSatisfactionFollowUpChange(event) {
        const key = event.currentTarget.dataset.key;
        const qId = this.currentQuestion.id;
        const current = { ...(this.answers[qId] || {}) };
        current[key] = event.target.value;
        this.answers = { ...this.answers, [qId]: current };
    }

    handleYesNo(event) {
        const value = event.currentTarget.dataset.value;
        this.answers = { ...this.answers, [this.currentQuestion.id]: value };
        this.errorMessage = '';
    }

    handleCheckboxToggle(event) {
        this.answers = { ...this.answers, [this.currentQuestion.id]: event.target.checked };
    }

    handleKeyDown(event) {
        if (event.key === 'Enter' && event.repeat) {
            event.preventDefault();
        }
    }

    // ---------------------------------------------------------------
    // Navigation / validation
    // ---------------------------------------------------------------

    nextStep() {
        if (!this.validateCurrent()) return;
        this.errorMessage = '';

        if (this.isLastQuestion) {
            this.handleSubmit();
        } else {
            this.questionIndex++;
        }
    }

    prevStep() {
        if (this.questionIndex > 0) {
            this.questionIndex--;
            this.errorMessage = '';
        }
    }

    validateCurrent() {
        const q = this.currentQuestion;
        if (!q) return true;
        const isRequired = q.required !== false; // default true unless explicitly optional
        if (!isRequired) return true;

        let isEmpty;
        if (q.type === 'star-matrix') {
            const ans = this.answers[q.id] || {};
            isEmpty = q.rows.some((r) => !ans[r.key]);
        } else if (q.type === 'satisfaction-followup') {
            // Optional by nature - never blocks navigation.
            isEmpty = false;
        } else if (q.type === 'open-text-multi') {
            const ans = this.answers[q.id] || [];
            isEmpty = !ans.some((v) => v && v.trim());
        } else {
            const answer = this.answers[q.id];
            isEmpty =
                answer === undefined ||
                answer === null ||
                answer === '' ||
                (Array.isArray(answer) && answer.length === 0);
        }

        if (isEmpty) {
            return this.showError('Please answer this question before continuing.');
        }
        return true;
    }

    showError(message) {
        this.errorMessage = message;
        return false;
    }

    handleReset() {
        this.phase = PHASE_LANDING;
        this.questionIndex = 0;
        this.answers = {};
        this.otherText = {};
        this.membershipId = '';
        this.memberToken = null;
        this.firstName = 'Visitor';
        this.errorMessage = '';
        this.consentGiven = false;
    }

    // ---------------------------------------------------------------
    // Consent + submit
    // ---------------------------------------------------------------

    handleConsentChange(event) {
        this.consentGiven = event.target.checked;
    }

    openPrivacyModal(event) {
        event.stopPropagation();
        this.showModal = true;
    }

    closePrivacyModal() {
        this.showModal = false;
    }

    get isNextDisabled() {
        return this.isLastQuestion && !this.consentGiven;
    }

    /** Apex expects List<String>, never undefined/null - normalize single values into a list too. */
    toList(value) {
        if (Array.isArray(value)) return value;
        if (value === undefined || value === null || value === '') return [];
        return [value];
    }

    /** Star-matrix answers[key] -> Integer, or null if unanswered. */
    starScore(rowKey) {
        const ans = this.answers.Q4_SATISFACTION || {};
        return typeof ans[rowKey] === 'number' ? ans[rowKey] : null;
    }

    /** Builds the combined text for Satisfaction_Follow_Up__c from the two per-row answers. */
    buildSatisfactionFollowUpText() {
        const rows = getLowSatisfactionRows(this.answers);
        const stored = this.answers.Q4_FOLLOWUP || {};
        const parts = rows
            .filter((r) => stored[r.key] && stored[r.key].trim())
            .map((r) => `${r.label} (${r.score}/5): ${stored[r.key].trim()}`);
        return parts.length ? parts.join(' | ') : null;
    }

    handleSubmit() {
        saveFeedback({
            input: {
                membershipId: this.membershipId,
                memberToken: this.memberToken,
                storeCode: this.selectedStore,

                tripMission: this.answers.Q1_TRIP || null,

                availability: this.answers.Q2_AVAILABILITY || null,
                availabilityItems: this.toList(this.answers.Q2A_AVAILABILITY_ITEMS).filter((v) => v && v.trim()),
                availabilityFollowUp: this.toList(this.answers.Q2B_AVAILABILITY_FOLLOWUP),
                availabilityFollowUpOther: this.otherText.Q2B_AVAILABILITY_FOLLOWUP || null,

                checkout: this.answers.Q3_CHECKOUT || null,

                rateStoreAppearance: this.starScore('appearance'),
                rateFreshItems: this.starScore('fresh'),
                rateProductAvailability: this.starScore('availability'),
                rateValueForMoney: this.starScore('value'),
                rateCheckoutExperience: this.starScore('checkout'),
                rateFoodChoices: this.starScore('food'),
                satisfactionFollowUp: this.buildSatisfactionFollowUpText(),

                freshSection: this.answers.Q5_FRESH || null,
                freshSectionFollowUp: this.toList(this.answers.Q5A_FRESH_FOLLOWUP),
                freshSectionFollowUpOther: this.otherText.Q5A_FRESH_FOLLOWUP || null,

                shareOfWallet: this.toList(this.answers.Q6_WALLET),
                shareOfWalletTop: this.answers.Q6A_WALLET_TOP || null,
                shareOfWalletBetter: this.toList(this.answers.Q6B_WALLET_BETTER),
                shareOfWalletBetterOther: this.otherText.Q6B_WALLET_BETTER || null,

                leakage: this.answers.Q7_LEAKAGE || null,
                leakageFollowUp: this.answers.Q7A_LEAKAGE_FOLLOWUP || null,
                leakageFollowUpOther: this.otherText.Q7A_LEAKAGE_FOLLOWUP || null,

                pricing: this.toList(this.answers.Q8_PRICING),
                pricingOther: this.otherText.Q8_PRICING || null,

                recommendScore: this.answers.Q9_NPS,
                promoterReasons: this.toList(this.answers.Q9A_PROMOTERS),
                promoterOther: this.otherText.Q9A_PROMOTERS || null,
                passiveComment: this.answers.Q9B_PASSIVE || null,
                detractorReasons: this.toList(this.answers.Q9C_DETRACTORS),
                detractorOther: this.otherText.Q9C_DETRACTORS || null,
                serviceRecoveryConsent: this.answers.Q9C_CONSENT === true,
                serviceRecoveryPhone: this.answers.Q9C_PHONE || null,

                renewalIntent: this.answers.Q10_RENEWAL || null,
                renewalReasonsLikely: this.toList(this.answers.Q10A_LIKELY),
                renewalReasonsAtRisk: this.toList(this.answers.Q10B_ATRISK),
                renewalReasonsAtRiskOther: this.otherText.Q10B_ATRISK || null,
                renewalClosing: this.answers.Q10B_CLOSING || null,

                campaignChannels: this.toList(this.answers.Q11_CAMPAIGN),

                storePriority: this.answers.Q12_PRIORITY || null,
                storePriorityComment: this.answers.Q12_COMMENT || null,

                openFeedback: this.answers.Q13_OPEN || null
            }
        })
            .then(() => {
                this.phase = PHASE_THANKYOU;
            })
            .catch((err) => {
                console.error(err);
                this.errorMessage = 'Error saving feedback';
            });
    }
}