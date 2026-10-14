import { LightningElement, wire } from 'lwc';
import getProvinces from '@salesforce/apex/BpiApplicationController.getProvinces';
import getCities from '@salesforce/apex/BpiApplicationController.getCities';
import getBarangays from '@salesforce/apex/BpiApplicationController.getBarangays';
import getStores from '@salesforce/apex/BpiApplicationController.getStores';
import submitApplication from '@salesforce/apex/BpiApplicationController.submitApplication';
import LOGO from '@salesforce/resourceUrl/bpiLandersLogo';
import CARD_IMAGE from '@salesforce/resourceUrl/bpiLandingImage';

const GENDERS = ['Male', 'Female'];
const MARITAL_STATUSES = ['Single', 'Married', 'Widowed', 'Separated', 'Divorced', 'Living Together'];
// Filipino is intentionally first. Replace the rest with your official list if needed.
const NATIONALITIES = [
    'Filipino', 'Afghan', 'American', 'Australian', 'Bangladeshi', 'Belgian', 'Brazilian', 'British',
    'Bruneian', 'Burmese', 'Cambodian', 'Canadian', 'Chilean', 'Chinese', 'Colombian', 'Cuban', 'Czech',
    'Danish', 'Dutch', 'Egyptian', 'Emirati', 'Finnish', 'French', 'German', 'Greek', 'Hungarian',
    'Indian', 'Indonesian', 'Iranian', 'Iraqi', 'Irish', 'Israeli', 'Italian', 'Japanese', 'Jordanian',
    'Kenyan', 'Korean', 'Kuwaiti', 'Laotian', 'Lebanese', 'Malaysian', 'Mexican', 'Nepalese',
    'New Zealander', 'Nigerian', 'Norwegian', 'Pakistani', 'Peruvian', 'Polish', 'Portuguese', 'Qatari',
    'Romanian', 'Russian', 'Saudi', 'Singaporean', 'South African', 'Spanish', 'Sri Lankan', 'Swedish',
    'Swiss', 'Taiwanese', 'Thai', 'Turkish', 'Ukrainian', 'Vietnamese'
];

const OCCUPATIONS = [
    'ACADEMIC PERSONNEL', 'ACCOUNTANT', 'ACTUARIAN', 'ADMINISTRATIVE OFFICER', 'ADMINISTRATIVE STAFF',
    'AGRICULTURIST', 'ANALYST', 'ARCHITECT', 'ARTIST', 'ATHLETE', 'AUDITOR',
    'AVIATION OFFICER', 'AVIATION STAFF', 'BANK EMPLOYEE', 'BLUE COLLARED WORKER',
    'BUSINESSMAN', 'CLERGY OR MINISTER', 'CONSTRUCTION WORKER', 'CULINARY PERSONNEL',
    'DOCTOR', 'ECONOMIST', 'ENGINEER', 'FACTORY WORKER', 'GOVERNMENT WORKER',
    'HOUSEHOLD WORKER', 'HOUSEWIFE', 'IT OFFICER', 'IT STAFF', 'JEWELLER',
    'LAWYER', 'LESSOR', 'MARINE OFFICER', 'MARINE STAFF', 'MARKET VENDOR',
    'MEDIA PERSONNEL', 'MEDICAL STAFF', 'MERCHANDISING STAFF', 'MILITARY OFFICER',
    'MILITARY STAFF', 'MONEY CHANGER', 'MONEY LENDER', 'OFFICE STAFF', 'PAWNBROKER',
    'PILOT', 'PUBLIC OFFICIAL', 'REAL ESTATE BROKER OR REALTOR', 'RELIGIOUS PERSONNEL',
    'SALES OR MARKETING PERSONNEL', 'SANITARY PERSONNEL', 'SCIENTIST', 'SEAFARER',
    'SECURITY PERSONNEL', 'SOCIOLOGIST', 'SPORTS PERSONNEL', 'STATISTICIAN',
    'STUDENT', 'SUPERVISOR', 'TRANSPORT PERSONNEL', 'UNEMPLOYED', 'VETERINARIAN',
    'VETERINARY STAFF'
];

const toOptions = (values) => values.map((v) => ({ label: v, value: v }));
const GENDER_OPTIONS = toOptions(GENDERS);
const MARITAL_OPTIONS = toOptions(MARITAL_STATUSES);
const NATIONALITY_OPTIONS = toOptions(NATIONALITIES);
const OCCUPATION_OPTIONS = toOptions(OCCUPATIONS);

const RECAPTCHA_SITE_KEY = '6LeBTu4tAAAAAGM-H8baP-U-tgKKkMCmGdTEOFcW';
// The api.js script is loaded by the site's Head Markup, not by this component.
// Must match the action string checked in Apex: bpiRecaptcha.verify(token, 'submit_application')
const RECAPTCHA_ACTION = 'submit_application';

const REQUIRED_FIELDS = {
    firstName: 'First name',
    lastName: 'Last name',
    gender: 'Gender',
    birthdate: 'Date of Birth',
    maritalStatus: 'Marital status',
    nationality: 'Nationality',
    occupation: 'Occupation',
    mobile: 'Mobile number',
    email: 'Email address',
    province: 'State / Province',
    city: 'City / District',
    barangay: 'Barangay',
    street: 'Street address',
    store: 'Preferred shopping branch'
};

const EMAIL_PATTERN = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;
const MOBILE_PATTERN = /^9\d{9}$/;

const EMPTY_FORM = {
    firstName: '',
    middleName: '',
    lastName: '',
    gender: '',
    birthdate: '',
    maritalStatus: '',
    nationality: '',
    occupation: '',
    mobile: '',
    email: '',
    province: '',
    city: '',
    barangay: '',
    street: '',
    store: ''
};

const toTenDigitMobile = (raw) => {
    let digits = String(raw || '').replace(/\D/g, '');
    if (digits.startsWith('63') && digits.length > 10) {
        digits = digits.slice(2);
    }
    if (digits.startsWith('0')) {
        digits = digits.slice(1);
    }
    return digits.slice(0, 10);
};

const CODE39 = {
    '0': 'nnnwwnwnn', '1': 'wnnwnnnnw', '2': 'nnwwnnnnw', '3': 'wnwwnnnnn', '4': 'nnnwwnnnw',
    '5': 'wnnwwnnnn', '6': 'nnwwwnnnn', '7': 'nnnwnnwnw', '8': 'wnnwnnwnn', '9': 'nnwwnnwnn',
    A: 'wnnnnwnnw', B: 'nnwnnwnnw', C: 'wnwnnwnnn', D: 'nnnnwwnnw', E: 'wnnnwwnnn',
    F: 'nnwnwwnnn', G: 'nnnnnwwnw', H: 'wnnnnwwnn', I: 'nnwnnwwnn', J: 'nnnnwwwnn',
    K: 'wnnnnnnww', L: 'nnwnnnnww', M: 'wnwnnnnwn', N: 'nnnnwnnww', O: 'wnnnwnnwn',
    P: 'nnwnwnnwn', Q: 'nnnnnnwww', R: 'wnnnnnwwn', S: 'nnwnnnwwn', T: 'nnnnwnwwn',
    U: 'wwnnnnnnw', V: 'nwwnnnnnw', W: 'wwwnnnnnn', X: 'nwnnwnnnw', Y: 'wwnnwnnnn',
    Z: 'nwwnwnnnn', '*': 'nwnnwnwnn'
};
const BAR_NARROW = 2;
const BAR_WIDE = 5;
const BAR_QUIET = 20;

export default class BpiApplicationForm extends LightningElement {
    logoUrl = LOGO;
    cardImageUrl = CARD_IMAGE;
    showLogo = false;

    form = { ...EMPTY_FORM };
    errors = {};
    formError = '';

    provinces = [];
    cities = [];
    barangays = [];
    stores = [];

    // Store the applicant signed up at, taken from the QR link (?store=1040)
    signupStoreCode = '';
    storesLoaded = false;
    loadFailed = false;

    isLoadingCities = false;
    isLoadingBarangays = false;
    isSubmitting = false;
    isSubmitted = false;

    // Response from submitApplication (reference number, full name, amount, etc.)
    result = null;

    isAgreed = false;

    handleCheckboxChange(event) {
        this.isAgreed = event.target.checked;
        if (this.isAgreed) {
            this.clearError('agreeTerms');
        }
    }

    connectedCallback() {
        this.showLogo = !!this.logoUrl;
        this.signupStoreCode = this.readStoreFromUrl();
    }

    // Asks Google for a fresh v3 token. Tokens expire after ~2 minutes and are
    // single-use, so call this right before submitting, never earlier.
    // api.js comes from the site Head Markup; wait briefly in case it is still loading.
    async getRecaptchaToken() {
        for (let i = 0; i < 50 && !(window.grecaptcha && window.grecaptcha.ready); i++) {
            // eslint-disable-next-line no-await-in-loop
            await new Promise((r) => setTimeout(r, 100));
        }
        const g = window.grecaptcha;
        if (!g || !g.ready) {
            throw new Error('reCAPTCHA is not loaded (check the site Head Markup)');
        }
        return new Promise((resolve, reject) => {
            g.ready(() => {
                g.execute(RECAPTCHA_SITE_KEY, { action: RECAPTCHA_ACTION })
                    .then(resolve)
                    .catch((err) => {
                        reject(new Error(String((err && err.message) || err)));
                    });
            });
        });
    }

    readStoreFromUrl() {
        try {
            const code = new URLSearchParams(window.location.search).get('store');
            return /^\d{4}$/.test(code || '') ? code : '';
        } catch (e) {
            return '';
        }
    }

    handleLogoError() {
        this.showLogo = false;
    }

    get hasCardImage() {
        return !!this.cardImageUrl;
    }

    get formattedAmount() {
        if (!this.result || this.result.amountToPay == null) {
            return '';
        }
        return new Intl.NumberFormat('en-PH', {
            style: 'currency',
            currency: 'PHP'
        }).format(this.result.amountToPay);
    }

    // ---------- page state: form vs. invalid-link notice ----------
    get hasValidSignupStore() {
        return this.stores.some((s) => s.value === this.signupStoreCode);
    }
    get showForm() {
        return this.storesLoaded && this.hasValidSignupStore;
    }
    get showNotice() {
        return this.loadFailed || (this.storesLoaded && !this.hasValidSignupStore);
    }
    get noticeTitle() {
        return this.loadFailed ? 'Something went wrong' : "This link isn't valid";
    }
    get noticeText() {
        return this.loadFailed
            ? 'We could not load the application page. Please refresh and try again.'
            : 'To apply for a Landers Executive Membership, please scan the QR code at the Membership Counter of your Landers store.';
    }

    @wire(getProvinces)
    wiredProvinces({ data, error }) {
        if (data) {
            this.provinces = data;
        } else if (error) {
            this.formError = 'We could not load the province list. Please refresh the page.';
        }
    }

    @wire(getStores)
    wiredStores({ data, error }) {
        if (data) {
            this.stores = data;
            this.storesLoaded = true;
        } else if (error) {
            this.loadFailed = true;
        }
    }

    get genderOptions() {
        return GENDER_OPTIONS;
    }
    get maritalOptions() {
        return MARITAL_OPTIONS;
    }
    get nationalityOptions() {
        return NATIONALITY_OPTIONS;
    }
    get occupationOptions() {
        return OCCUPATION_OPTIONS;
    }
    get provinceOptions() {
        return this.provinces;
    }
    get cityOptions() {
        return this.cities;
    }
    get barangayOptions() {
        return this.barangays;
    }
    get storeOptions() {
        return this.stores;
    }
    get cityPlaceholder() {
        return this.isLoadingCities ? 'Loading..' : 'Please select..';
    }
    get barangayPlaceholder() {
        return this.isLoadingBarangays ? 'Loading..' : 'Please select..';
    }

    get isCityDisabled() {
        return !this.form.province || this.isLoadingCities;
    }
    get isBarangayDisabled() {
        return !this.form.city || this.isLoadingBarangays;
    }
    get submitLabel() {
        return this.isSubmitting ? 'Submitting...' : 'Submit';
    }

    get barcodeBars() {
        const ref = this.result && this.result.referenceNumber;
        if (!ref) {
            return [];
        }
        const text = `*${String(ref).toUpperCase()}*`; // * = start/stop character
        const bars = [];
        let x = BAR_QUIET;
        for (let c = 0; c < text.length; c++) {
            const pattern = CODE39[text[c]];
            if (!pattern) {
                return [];
            }
            for (let i = 0; i < 9; i++) {
                const w = pattern[i] === 'w' ? BAR_WIDE : BAR_NARROW;
                if (i % 2 === 0) {
                    bars.push({ key: `${c}-${i}`, x, width: w });
                }
                x += w;
            }
            x += BAR_NARROW; // gap between characters
        }
        return bars;
    }

    get hasBarcode() {
        return this.barcodeBars.length > 0;
    }

    setField(name, value) {
        this.form = { ...this.form, [name]: value };
        this.clearError(name);
    }

    clearError(name) {
        if (this.errors[name]) {
            const rest = { ...this.errors };
            delete rest[name];
            this.errors = rest;
        }
        const el = this.template.querySelector(`[data-field="${name}"]`);
        if (el) {
            el.classList.remove('is-invalid');
        }
    }

    handleChange(event) {
        this.setField(event.target.name, event.target.value);
    }

    handleComboChange(event) {
        this.setField(event.target.name, event.detail.value);
    }

    handleMobileInput(event) {
        const digits = toTenDigitMobile(event.target.value);
        event.target.value = digits;
        this.setField('mobile', digits);
    }

    async handleProvinceChange(event) {
        const code = event.detail.value;
        this.form = { ...this.form, province: code, city: '', barangay: '' };
        this.clearError('province');
        this.cities = [];
        this.barangays = [];
        if (!code) {
            return;
        }
        this.isLoadingCities = true;
        try {
            const result = await getCities({ provinceCode: Number(code) });
            if (this.form.province === code) {
                this.cities = result;
            }
        } catch (e) {
            this.formError = 'We could not load the cities. Please try again.';
        } finally {
            this.isLoadingCities = false;
        }
    }

    async handleCityChange(event) {
        const code = event.detail.value;
        this.form = { ...this.form, city: code, barangay: '' };
        this.clearError('city');
        this.barangays = [];
        if (!code) {
            return;
        }
        this.isLoadingBarangays = true;
        try {
            const result = await getBarangays({ cityCode: Number(code) });
            if (this.form.city === code) {
                this.barangays = result;
            }
        } catch (e) {
            this.formError = 'We could not load the barangays. Please try again.';
        } finally {
            this.isLoadingBarangays = false;
        }
    }

    // Copies what is actually typed in the text inputs into the form state.
    // Covers browser autofill and any case where an input event was missed.
    syncTextInputs() {
        const next = { ...this.form };
        this.template.querySelectorAll('input[name]').forEach((el) => {
            if (!(el.name in EMPTY_FORM)) {
                return;
            }
            next[el.name] = el.name === 'mobile' ? toTenDigitMobile(el.value) : el.value;
        });
        this.form = next;
    }

    validate() {
        const errors = {};
        Object.keys(REQUIRED_FIELDS).forEach((name) => {
            if (!String(this.form[name]).trim()) {
                errors[name] = `${REQUIRED_FIELDS[name]} is required.`;
            }
        });

        if (!errors.birthdate) {
            const dob = new Date(this.form.birthdate);
            const today = new Date();
            let age = today.getFullYear() - dob.getFullYear();
            const monthDiff = today.getMonth() - dob.getMonth();
            if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < dob.getDate())) {
                age--;
            }

            if (isNaN(age) || age < 18) {
                errors.birthdate = 'You must be at least 18 years old to apply.';
            }
        }

        if (!errors.email && !EMAIL_PATTERN.test(this.form.email.trim())) {
            errors.email = 'Please enter a valid email address.';
        }
        if (!errors.mobile && !MOBILE_PATTERN.test(this.form.mobile)) {
            errors.mobile = 'Enter a 10-digit mobile number starting with 9.';
        }

        if (!this.isAgreed) {
            errors.agreeTerms = 'You must agree to the Terms and Conditions and Privacy Policy to continue.';
        }

        this.errors = errors;

        this.template.querySelectorAll('[data-field]').forEach((el) => {
            el.classList.toggle('is-invalid', !!errors[el.dataset.field]);
        });

        const firstInvalid = this.template.querySelector('.is-invalid');
        if (firstInvalid) {
            firstInvalid.scrollIntoView({ behavior: 'smooth', block: 'center' });
            const focusTarget = firstInvalid.matches('input, select, c-bpi-dropdown')
                ? firstInvalid
                : firstInvalid.querySelector('input');
            if (focusTarget) {
                focusTarget.focus({ preventScroll: true });
            }
        }
        return Object.keys(errors).length === 0;
    }

    async handleSubmit(event) {
        event.preventDefault();
        if (this.isSubmitting) {
            return;
        }
        this.formError = '';
        this.syncTextInputs();
        if (!this.validate()) {
            return;
        }

        const f = this.form;
        this.isSubmitting = true;
        try {
            // Fetch the token last, right before the Apex call (expires in ~2 min).
            let recaptchaToken;
            try {
                recaptchaToken = await this.getRecaptchaToken();
            } catch (captchaError) {
                const detail = String((captchaError && captchaError.message) || captchaError);
                console.error('reCAPTCHA error:', detail); // eslint-disable-line no-console
                console.error('grecaptcha present?', typeof window.grecaptcha, // eslint-disable-line no-console
                    window.grecaptcha && typeof window.grecaptcha.execute);
                // TEMP DEBUG: shows the real reason on the form. Remove the "(detail)" part once fixed.
                this.formError =
                    'We could not verify that you are not a robot. Please refresh the page and try again. (' +
                    detail + ')';
                return;
            }

            const response = await submitApplication({
                requestJson: JSON.stringify({
                    firstName: f.firstName ? f.firstName.trim() : '',
                    middleName: f.middleName ? f.middleName.trim() : '',
                    lastName: f.lastName ? f.lastName.trim() : '',
                    gender: f.gender,
                    birthdate: f.birthdate,
                    maritalStatus: f.maritalStatus,
                    nationality: f.nationality,
                    occupation: f.occupation,
                    mobileNumber: f.mobile,
                    email: f.email ? f.email.trim() : '',
                    provinceCode: Number(f.province) || null,
                    cityCode: Number(f.city) || null,
                    barangayCode: Number(f.barangay) || null,
                    street: f.street ? f.street.trim() : '',
                    storeCode: f.store,
                    signupStoreCode: this.signupStoreCode,
                    agreedToTerms: this.isAgreed,
                    recaptchaToken
                })
            });
            this.result = response;
            this.isSubmitted = true;
            window.scrollTo({ top: 0, behavior: 'smooth' });
        } catch (e) {
            this.formError =
                (e && e.body && e.body.message) || 'Something went wrong. Please try again.';
        } finally {
            this.isSubmitting = false;
        }
    }

    // Back to a blank form for the next applicant. The store code from the QR link is kept.
    handleSubmitAnother() {
        this.form = { ...EMPTY_FORM };
        this.errors = {};
        this.formError = '';
        this.cities = [];
        this.barangays = [];
        this.result = null;
        this.isSubmitted = false;
        this.isAgreed = false;
        window.scrollTo({ top: 0, behavior: 'smooth' });
    }
}