import { LightningElement, track } from 'lwc';
import LANDERS_LOGO from '@salesforce/resourceUrl/landerslogo';
import KIA_CAR      from '@salesforce/resourceUrl/kiamotors';
import KIA_SORENTO_IMG  from '@salesforce/resourceUrl/KIASorento';
import KIA_CARNIVAL_IMG from '@salesforce/resourceUrl/KIACarnival';
import ANNIV_ICON   from '@salesforce/resourceUrl/landers10thIcon';
import AMOUNT_400K   from '@salesforce/resourceUrl/kia400kOff';
import BEBAS_KAI_FONT from '@salesforce/resourceUrl/BebasKai';
import createRegistration        from '@salesforce/apex/RegistrationController.createRegistration';
import validateMemberId          from '@salesforce/apex/RegistrationController.validateMemberId';
import checkExistingRegistration from '@salesforce/apex/RegistrationController.checkExistingRegistration';
import getRecaptchaSiteKey from '@salesforce/apex/RecaptchaController.getSiteKey';
import RECAPTCHA_WIDGET    from '@salesforce/resourceUrl/recaptchaWidget';

// reCAPTCHA (the checkbox + "select all images with..." challenge) has to run
// inside the static-resource iframe below, not as a script injected directly
// into this component's own JS — Lightning Web Security blocks the DOM writes
// Google's script needs (it tries to prepend a <meta> tag to <head>) when run
// inside an LWC's locked context. The iframe is a separate document, so it's
// unaffected; we just listen for postMessage events coming back from it.

// ── Top-level model cards (what the user taps) ──────────────────────────────
// Sorento is now a single trim (EX 4x2 Turbo Hybrid) — no more variant picker.
const CAR_MODELS = [
    {
        label:         'Sorento',
        value:         'Sorento EX 4x2 Turbo Hybrid',
        badge:         'Limited Offer',
        originalPrice: '₱2,188,000',
        price:         '₱1,988,000'
    },
    {
        label:         'Carnival',
        value:         'Carnival SX Diesel AT',
        badge:         'Limited Offer',
        originalPrice: '₱3,368,000',
        price:         '₱2,968,000'
    }
];

const RELATIONSHIPS  = ['Father', 'Mother', 'Wife', 'Husband', 'Son', 'Daughter', 'Brother', 'Sister'];

// ── Specs/photo data for the "View Specs" popup — sourced directly from the
// official Kia Philippines spec sheets (Main-SorentoTH2026-EXAT.pdf,
// Main-Carnival2026_EXAT.pdf, dated February 2026). Kept short/summary-style
// for the modal — the full sheet is one tap away via the link below it. ──
const CAR_SPECS = {
    'Sorento EX 4x2 Turbo Hybrid': {
        image:   KIA_SORENTO_IMG,
        link:    'https://kiaphilippines.com/vehicles/sorento',
        summary: '1.6L Turbo Hybrid (Gamma II) • 235 ps / 367 Nm • Smartstream 6-Speed AT • All-Wheel Drive',
        colors:  'Snow White Pearl, Aurora Black Pearl',
        features: [
            'Turbo Hybrid Powertrain',
            '12.3" Infotainment System with Wireless Connectivity',
            'Shift-By-Wire',
            'Rear Camera with Dynamic Guide',
            'Dual-Zone Climate Control with Switchable Controller',
            'Comfort and Space for 7'
        ]
    },
    'Carnival SX Diesel AT': {
        image:   KIA_CARNIVAL_IMG,
        link:    'https://kiaphilippines.com/vehicles/carnival',
        summary: '2.2L Smartstream Diesel CRDI VGT • 202 ps / 440 Nm • Smartstream 8-Speed AT • Front-Wheel Drive',
        colors:  'Snow White Pearl, Aurora Black Pearl',
        features: [
            'Powerful Diesel Engine',
            'Dual 12.3" Instrument Cluster and Infotainment System with Wireless Connectivity',
            'Captain Seats',
            '360-Degree Surround View Monitor',
            'Comfort and Space for 7'
        ]
    }
};

// ── Partnership constant for this LWC ──────────────────────────────────────
const PARTNERSHIP = 'KIA';

const EMPTY_FORM = () => ({
    memberId:     '',
    firstName:    '',
    middleName:   '',
    lastName:     '',
    email:        '',
    phone:        '',
    carModel:     '',
    relationship: ''
});

export default class KiaxlndApplication extends LightningElement {

    landersLogo = LANDERS_LOGO;
    kiaCar      = KIA_CAR;
    anniversaryIcon = ANNIV_ICON;
    amount400k      = AMOUNT_400K;

    /* ── Component State ── */
    @track isForm      = true;
    @track currentStep = 1;
    @track isReview    = false;
    @track isDone      = false;

    @track form = EMPTY_FORM();

    @track errorMessage   = '';
    @track emailError     = '';
    @track phoneError     = '';
    @track memberIdStatus = '';

    @track applyingForOthers = false;
    @track recaptchaSiteKey  = '';
    @track recaptchaReady    = false;
    @track showRecaptchaFrame = false;
    @track captchaToken      = '';
    @track captchaBusy       = false;

    // tracks which TOP-LEVEL model card is selected ('Sorento EX 4x2 Turbo Hybrid' | 'Carnival SX Diesel AT' | '')
    @track _selectedModel = '';

    // specs/photo popup state
    @track specsModalOpen = false;
    @track specsModalData = null;

    // data privacy consent
    @track consentChecked   = false;
    @track consentModalOpen = false;

    _contactFirstName  = '';
    _contactMiddleName = '';
    _contactLastName   = '';

    relationshipOptions = RELATIONSHIPS.map(r => ({ label: r, value: r }));

    /* ── Step Visibility ── */
    get isStepDetails()    { return this.isForm && this.currentStep === 1; }
    get isStepPreference() { return this.isForm && this.currentStep === 2; }

    /* ── Step Progress CSS ── */
    get activeStep1() { return this.currentStep === 1 ? 'step-circle active' : 'step-circle done'; }
    get activeName1() { return this.currentStep === 1 ? 'step-name active' : 'step-name'; }
    get activeStep2() { return this.currentStep === 2 ? 'step-circle active' : 'step-circle'; }
    get activeName2() { return this.currentStep === 2 ? 'step-name active' : 'step-name'; }

    /* ── Member ID Status ── */
    get memberIdChecking()  { return this.memberIdStatus === 'checking'; }
    get memberIdValid()     { return this.memberIdStatus === 'valid'; }
    get memberIdInvalid()   { return this.memberIdStatus === 'invalid'; }
    get memberIdDuplicate() { return this.memberIdStatus === 'duplicate'; }

    get verifyButtonLabel()    { return this.memberIdChecking ? 'Verifying…' : 'Verify'; }
    get verifyButtonDisabled() { return !this.form.memberId || this.memberIdChecking; }

    /* ── Name Field Controls ── */
    get nameFieldsDisabled() { return !this.applyingForOthers; }
    get showRelationship()   { return this.applyingForOthers === true; }
    get nameFieldClass()     { return this.applyingForOthers ? '' : 'name-field name-field-locked'; }

    /* ── Masked name display (privacy) ──
       Each word is masked independently and rejoined with a real space —
       treating the whole string as one sequence (including the space) was
       masking the space itself, garbling multi-word names like "Angelica
       Jovelle" into one unreadable blob.
       Fixed positions per word so the mask doesn't shuffle on every re-render:
       - 2-4 letter words: show the first letter only.
       - 5+ letter words: show the first, the 4th, and the last letter. */
    maskWord(word) {
        const len = word.length;
        if (len <= 1) return word;

        const chars = word.split('');
        const visible = new Set();
        visible.add(0); // first letter, always shown

        if (len > 4) {
            visible.add(3);       // 4th letter
            visible.add(len - 1); // last letter
        }

        for (let i = 0; i < len; i++) {
            if (!visible.has(i)) chars[i] = '*';
        }
        return chars.join('');
    }

    maskName(value) {
        if (!value) return '';
        return value.trim().split(/\s+/).map(word => this.maskWord(word)).join(' ');
    }

    get maskedFirstName()  { return this.nameFieldsDisabled ? this.maskName(this.form.firstName)  : this.form.firstName;  }
    get maskedMiddleName() { return this.nameFieldsDisabled ? this.maskName(this.form.middleName) : this.form.middleName; }
    get maskedLastName()   { return this.nameFieldsDisabled ? this.maskName(this.form.lastName)   : this.form.lastName;   }

    // Only invite input with the "Optional" placeholder when the member is
    // actually typing it in. When the field is locked (showing the member's
    // own record) a blank middle name should just stay blank.
    get middleNamePlaceholder() { return this.nameFieldsDisabled ? '' : 'Optional'; }

    /* ── Car Model Cards ── */
    get carCards() {
        return CAR_MODELS.map(c => ({
            ...c,
            cardClass: 'car-card' + (this._selectedModel === c.value ? ' car-card-selected' : '')
        }));
    }

    /* ── Derived display values ── */
    get fullName() {
        return [this.form.firstName, this.form.middleName, this.form.lastName].filter(Boolean).join(' ');
    }

    get carLabel() {
        return this.form.carModel || '—';
    }

    get submitLabel() {
        return this.captchaBusy ? 'Submitting…' : 'Submit';
    }

    get recaptchaIframeUrl() {
        return this.recaptchaSiteKey
            ? `${RECAPTCHA_WIDGET}?key=${encodeURIComponent(this.recaptchaSiteKey)}`
            : '';
    }

    get submitDisabled() {
        return this.captchaBusy || !this.captchaToken || !this.consentChecked;
    }

    /* ── Handlers ── */
    handleApplyingForOthersChange(event) {
        this.applyingForOthers = event.target.checked;
        if (!this.applyingForOthers) {
            this.form = { ...this.form, firstName: this._contactFirstName, middleName: this._contactMiddleName, lastName: this._contactLastName, relationship: '' };
        } else {
            this.form = { ...this.form, firstName: '', middleName: '', lastName: '' };
        }
    }

    handleCarSelect(event) {
        const selected = event.currentTarget.dataset.value;
        this._selectedModel = selected;
        this.form = { ...this.form, carModel: selected };
    }

    // Separate from selection — tapping "View Specs & Photo" previews a model
    // without committing to it. stopPropagation keeps it from also bubbling
    // up to the card's own onclick (which would select it).
    handleViewSpecs(event) {
        event.stopPropagation();
        const value = event.currentTarget.dataset.value;
        this.openSpecsModalFor(value);
    }

    // Looks up a model's summary spec/photo and opens the popup.
    openSpecsModalFor(value) {
        const car   = CAR_MODELS.find(c => c.value === value);
        const specs = CAR_SPECS[value];
        if (!car || !specs) return;

        this.specsModalData = {
            label:         value, // full model name (e.g. "Sorento EX 4x2 Turbo Hybrid")
            price:         car.price,
            originalPrice: car.originalPrice,
            image:         specs.image,
            link:          specs.link,
            summary:       specs.summary,
            colors:        specs.colors,
            features:      specs.features.map((text, i) => ({ id: value + '-feature-' + i, text }))
        };
        this.specsModalOpen = true;
    }

    handleCloseSpecsModal() {
        this.specsModalOpen = false;
    }

    // Opens the official Kia page for the currently-shown model. A real
    // <button> rather than an <a> — same destination, just not styled/marked
    // up as a hyperlink.
    handleOpenFullSpecs() {
        if (this.specsModalData?.link) {
            window.open(this.specsModalData.link, '_blank', 'noopener,noreferrer');
        }
    }

    handleConsentChange(event) {
        this.consentChecked = event.target.checked;
    }

    handleOpenConsentModal(event) {
        if (event) event.preventDefault();
        this.consentModalOpen = true;
    }

    handleCloseConsentModal() {
        this.consentModalOpen = false;
    }

    // Prevents a click inside the modal card from bubbling up to the backdrop (which closes the modal).
    stopModalClose(event) {
        event.stopPropagation();
    }

    handleChange(event) {
        const field = event.target.dataset.field;
        const value = event.detail?.value ?? event.target.value;
        if (!field) return;

        this.form = { ...this.form, [field]: value };

        if (field === 'memberId') {
            this.memberIdStatus     = '';
            this.errorMessage       = '';
            this._contactFirstName  = '';
            this._contactMiddleName = '';
            this._contactLastName   = '';
            this.applyingForOthers  = false;
            this.form = { ...this.form, memberId: value, firstName: '', middleName: '', lastName: '' };
        }

        if (field === 'email') {
            const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
            this.emailError = value && !emailPattern.test(value) ? 'Please enter a valid email address.' : '';
        }

        if (field === 'phone') {
            let phone = value.replace(/\D/g, '');
            if (phone.length > 11) phone = phone.substring(0, 11);
            this.form.phone = phone;
            event.target.value = phone;
            this.phoneError = phone.length > 0 && phone.length < 11 ? 'Phone number must be 11 digits.' : '';
        }
    }

    handleVerifyMemberId() {
        const id = this.form.memberId;
        if (!id) { this.memberIdStatus = ''; return; }
        this.memberIdStatus = 'checking';

        validateMemberId({ memberId: id })
            .then(result => {
                if (!result) {
                    this.memberIdStatus = 'invalid';
                    this.form = { ...this.form, firstName: '', middleName: '', lastName: '' };
                    return;
                }
                return checkExistingRegistration({ memberId: id, partnership: PARTNERSHIP })
                    .then(alreadyRegistered => {
                        if (alreadyRegistered) {
                            this.memberIdStatus = 'duplicate';
                            this.form = { ...this.form, firstName: '', middleName: '', lastName: '' };
                            return;
                        }
                        this.memberIdStatus     = 'valid';
                        this.errorMessage       = '';
                        this._contactFirstName  = result.firstName  || '';
                        this._contactMiddleName = result.middleName || '';
                        this._contactLastName   = result.lastName   || '';

                        if (!this.applyingForOthers) {
                            this.form = { ...this.form, firstName: this._contactFirstName, middleName: this._contactMiddleName, lastName: this._contactLastName };
                        }
                    });
            })
            .catch(error => {
                console.error('Validation error:', error);
                this.memberIdStatus = 'invalid';
                this.errorMessage   = 'Error validating membership ID. Please try again.';
            });
    }

    /* ── Step 1 ── */
    handleNextDetails() {
        const f = this.form;
        this.errorMessage = '';

        if (this.memberIdStatus === 'duplicate') {
            this.errorMessage = 'This Membership ID has already been registered for this promo.';
            return;
        }

        const missingRelationship = this.applyingForOthers && !f.relationship;
        if (!f.memberId || !f.firstName || !f.lastName || !f.phone || !f.email || missingRelationship) {
            this.errorMessage = 'Please complete all required fields on this step before continuing.';
            return;
        }

        const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailPattern.test(f.email)) {
            this.errorMessage = 'Please enter a valid email address.';
            return;
        }

        if (f.phone.length !== 11) {
            this.errorMessage = 'Phone number must be exactly 11 digits.';
            return;
        }

        if (this.memberIdStatus !== 'valid') {
            this.memberIdStatus = 'checking';
            validateMemberId({ memberId: f.memberId })
                .then(result => {
                    if (!result) {
                        this.memberIdStatus = 'invalid';
                        this.errorMessage   = 'Invalid Membership ID. Please try again.';
                        return;
                    }
                    return checkExistingRegistration({ memberId: f.memberId, partnership: PARTNERSHIP })
                        .then(alreadyRegistered => {
                            if (alreadyRegistered) {
                                this.memberIdStatus = 'duplicate';
                                this.errorMessage   = 'This Membership ID has already been registered for this promo.';
                                return;
                            }
                            this.memberIdStatus = 'valid';
                            this.currentStep = 2;
                        });
                })
                .catch(() => {
                    this.memberIdStatus = 'invalid';
                    this.errorMessage = 'Error validating membership ID.';
                });
            return;
        }

        this.currentStep = 2;
    }

    handleBackPreference() {
        this.errorMessage = '';
        this.currentStep  = 1;
    }

    /* ── Step 2 ── */
    handleNextPreference() {
        const f = this.form;
        this.errorMessage = '';

        if (!f.carModel) {
            this.errorMessage = 'Please select a car model before continuing.';
            return;
        }

        // Reveal the captcha iframe now, right before the user reaches
        // Review/Submit — not on initial component mount. The iframe itself
        // is what triggers Google's script to load (inside its own isolated
        // document), so simply opening or previewing the page in Experience
        // Builder no longer touches reCAPTCHA at all until this point.
        this.showRecaptchaFrame = true;

        this.isForm   = false;
        this.isReview = true;
    }

    handleBackReview() {
        this.errorMessage = '';
        this.isReview = false;
        this.isForm   = true;
        this.currentStep = 2;
    }

    /* ── Submit ── */
    async handleSubmit() {
        this.errorMessage = '';

        if (!this.consentChecked) {
            this.errorMessage = 'Please read and agree to the Data Privacy Notice before submitting.';
            return;
        }

        if (!this.captchaToken) {
            this.errorMessage = 'Please complete the captcha above before submitting.';
            return;
        }

        this.captchaBusy = true;
        try {
            await createRegistration({
                memberId:       this.form.memberId,
                firstName:      this.form.firstName,
                middleName:     this.form.middleName,
                lastName:       this.form.lastName,
                email:          this.form.email,
                phoneNumber:    this.form.phone,
                model:          this.form.carModel,
                relationship:   this.form.relationship,
                partnership:    PARTNERSHIP,
                recaptchaToken: this.captchaToken
            });

            this.errorMessage = '';
            this.isReview = false;
            this.isForm   = false;
            this.isDone   = true;
        } catch (error) {
            console.error('SUBMIT ERROR:', error);
            this.errorMessage = error?.body?.message || 'Submission failed. Please try again.';
            // A captcha token is single-use — if verification failed, the same
            // token can't be retried. Clear it so the checkbox/challenge resets
            // and the person can complete it again rather than hitting a wall.
            this.captchaToken = '';
        } finally {
            this.captchaBusy = false;
        }
    }

    handleReset() {
        this.form               = EMPTY_FORM();
        this.errorMessage       = '';
        this.emailError         = '';
        this.phoneError         = '';
        this.memberIdStatus     = '';
        this.applyingForOthers  = false;
        this._contactFirstName  = '';
        this._contactMiddleName = '';
        this._contactLastName   = '';
        this.isDone             = false;
        this.isForm             = true;
        this.isReview           = false;
        this._selectedModel     = '';
        this.specsModalOpen     = false;
        this.specsModalData     = null;
        this.currentStep        = 1;
        this.captchaToken       = '';
        this.showRecaptchaFrame = false;
        this.consentChecked     = false;
        this.consentModalOpen   = false;
    }

    // Only fetches the site key here — does NOT show the captcha iframe yet.
    // The iframe is revealed later in handleNextPreference(), right before
    // Review, so merely mounting this component (including every time
    // Experience Builder renders its preview canvas) never touches Google's
    // script at all.
    connectedCallback() {
        this._handleRecaptchaMessage = this._handleRecaptchaMessage.bind(this);
        window.addEventListener('message', this._handleRecaptchaMessage);

        this.loadCustomFont();

        getRecaptchaSiteKey()
            .then((siteKey) => {
                this.recaptchaSiteKey = siteKey;
            })
            .catch((error) => {
                console.error('Unable to load captcha configuration:', error);
                this.errorMessage = 'Captcha is unavailable right now. Please try again later.';
            });
    }

    // Custom fonts can't be loaded via a plain @font-face in the static .css
    // file because the resource URL is only known at runtime (it includes a
    // content hash). The first attempt injected a <style> tag into a
    // manually-owned slot in this component's own template — that produced
    // zero network requests for the font at all, meaning the injection
    // itself was failing silently with no error to debug from. The CSS Font
    // Loading API below doesn't touch the DOM tree in any way — it just
    // registers a font resource directly with the browser — and, critically,
    // gives us a real catchable error if something does block it.
    loadCustomFont() {
        if (this._fontLoadAttempted) return;
        this._fontLoadAttempted = true;

        try {
            const fontFace = new FontFace('BebasKai', `url(${BEBAS_KAI_FONT})`);
            fontFace.load()
                .then((loadedFace) => {
                    document.fonts.add(loadedFace);
                })
                .catch((error) => {
                    console.error('BebasKai font failed to load:', error);
                });
        } catch (error) {
            console.error('BebasKai FontFace could not be created:', error);
        }
    }

    disconnectedCallback() {
        if (this._handleRecaptchaMessage) {
            window.removeEventListener('message', this._handleRecaptchaMessage);
        }
    }

    // Routes messages coming back from the static-resource iframe: readiness
    // signal, a completed checkbox/challenge token, an expiry, or an error.
    _handleRecaptchaMessage(event) {
        const data = event.data;
        if (!data || !data.type) return;

        if (data.type === 'recaptcha-ready') {
            this.recaptchaReady = true;
        } else if (data.type === 'recaptcha-token') {
            this.captchaToken = data.token;
            this.errorMessage = '';
        } else if (data.type === 'recaptcha-expired') {
            this.captchaToken = '';
            this.errorMessage = 'Captcha expired — please verify again.';
        } else if (data.type === 'recaptcha-error') {
            this.captchaToken = '';
            this.errorMessage = data.message || 'Captcha failed to load. Please refresh and try again.';
        }
    }
}