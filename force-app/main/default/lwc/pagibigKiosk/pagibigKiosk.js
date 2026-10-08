import { LightningElement, api, track } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import JSBARCODE from '@salesforce/resourceUrl/landersjsBarcode';
import checkPagIbigId from '@salesforce/apex/DayPassController.checkPagIbigId';
import issueDayPass from '@salesforce/apex/DayPassController.issueDayPass';

const STEP = { SCAN: 'scan', DETAILS: 'details', PASS: 'pass' };
const ID_LENGTH = 12;
// 11 digits starting 09 — the standard Philippine mobile format.
const MOBILE_RE = /^09\d{9}$/;

export default class PagibigKiosk extends LightningElement {
    /** Seconds on the pass screen before the kiosk resets itself. 0 disables. */
    @api autoResetSeconds = 90;

    /** Set by a parent when the kiosk runs inside a modal: drops the header
     *  and the full-viewport background so it sits in the dialog cleanly. */
    @api embedded = false;

    /**
     * The shared Landers membership the day pass runs under. Every visitor's
     * printed pass carries THIS number — it is what the POS and entrance
     * scanners recognise. The per-registration reference (pass.passNumber)
     * is internal tracking only and is never scanned.
     * Configurable because sandbox and Production may differ.
     */
    @api membershipId = '20208800006500';
    @api membershipName = 'PAG IBIG LANDERS ALL STORE DAYPASS';

    step = STEP.SCAN;
    scanBuffer = '';
    scanError = '';
    errorMessage = '';
    manualEntry = false;
    blockedMessage = '';
    checking = false;
    busy = false;
    secondsLeft = 0;

    @track form = this.blankForm();
    @track touched = {};
    @track pass = {};

    _barcodeReady = false;
    _barcodeDrawn = false;
    _refocusTimer = null;
    _countdownTimer = null;
    _scanTimer = null;

    // ---------------------------------------------------------------- wiring

    connectedCallback() {
        if (typeof JsBarcode !== 'undefined') {
            this._barcodeReady = true;
            return;
        }
        loadScript(this, JSBARCODE)
            .then(() => {
                this._barcodeReady = true;
                // eslint-disable-next-line @lwc/lwc/no-async-operation
                Promise.resolve().then(() => this.drawBarcode());
            })
            .catch(() => { this._barcodeReady = false; });
    }

    renderedCallback() {
        if (this.step === STEP.SCAN) {
            this.focusScanner();
        }
        this.drawBarcode();
    }

    /*
     * Landers cards print the membership as 4-8-2, e.g. 1000-00942287-00.
     * The barcode itself carries the bare 14 digits — that is what the
     * scanner returns.
     */
    get today() {
        return new Date().toISOString().slice(0, 10);
    }

    get displayMembershipId() {
        const d = this.digits(this.membershipId);
        return d.length === 14
            ? `${d.slice(0, 4)}-${d.slice(4, 12)}-${d.slice(12)}`
            : this.membershipId;
    }

    get kioskClass() {
        return this.embedded ? 'kiosk kiosk--embedded' : 'kiosk';
    }

    /** Lets a parent modal reset the flow when it reopens. */
    @api
    reset() {
        this.restart();
    }

    get isScanStep()    { return this.step === STEP.SCAN; }
    get isDetailsStep() { return this.step === STEP.DETAILS; }
    get isPassStep()    { return this.step === STEP.PASS; }

    get step1Class() { return this.stepClass(STEP.SCAN); }
    get step2Class() { return this.stepClass(STEP.DETAILS); }
    get step3Class() { return this.stepClass(STEP.PASS); }

    stepClass(which) {
        const order = [STEP.SCAN, STEP.DETAILS, STEP.PASS];
        const here = order.indexOf(this.step);
        const mine = order.indexOf(which);
        if (mine < here) return 'done';
        if (mine === here) return 'current';
        return '';
    }

    get scanFrameClass() {
        if (this.blockedMessage) return 'scan-frame is-blocked';
        return this.scanError ? 'scan-frame is-error' : 'scan-frame';
    }

    /*
     * Android pops the on-screen keyboard whenever a text input holds focus.
     * The scan input must stay focused to catch the wedge, so it declares
     * inputmode="none" — the keyboard stays down, HID input still lands.
     * Tapping "Type it instead" switches it to a numeric keypad.
     */
    get scanInputMode() {
        return this.manualEntry ? 'numeric' : 'none';
    }

    get scanPlaceholder() {
        return this.manualEntry ? 'Enter 12 digits' : 'Waiting for scan…';
    }

    enableManual() {
        this.manualEntry = true;
        this.focusScanner();
    }

    get scanHint() {
        if (this.checking) return 'Checking…';
        const n = this.digits(this.scanBuffer).length;
        if (n === 0) return 'Waiting for card…';
        return `${n} of ${ID_LENGTH} digits`;
    }

    get displayId() {
        return this.formatId(this.form.pagIbigId);
    }

    get submitDisabled() {
        return this.busy || !this.isFormValid;
    }

    get isFormValid() {
        const f = this.form;
        return (
            this.digits(f.pagIbigId).length === ID_LENGTH &&
            !this.validate('firstName') &&
            !this.validate('lastName') &&
            !this.validate('mobile') &&
            !this.validate('birthdate') &&
            f.consent
        );
    }

    /*
     * One place that decides whether a field is wrong, and what to say.
     * Returns an empty string when valid so callers can treat it as falsy.
     */
    validate(field) {
        const v = (this.form[field] || '').trim();
        switch (field) {
            case 'firstName':
                return v ? '' : 'First name is required.';
            case 'lastName':
                return v ? '' : 'Last name is required.';
            case 'mobile':
                if (!v) return 'Mobile number is required.';
                return MOBILE_RE.test(v)
                    ? ''
                    : 'Enter 11 digits starting with 09.';
            case 'birthdate': {
                if (!v) return 'Birthdate is required.';
                const d = new Date(v);
                if (isNaN(d.getTime())) return 'Enter a valid date.';
                const now = new Date();
                if (d > now) return 'Birthdate cannot be in the future.';
                // sanity bound: no one over 120
                const min = new Date();
                min.setFullYear(min.getFullYear() - 120);
                if (d < min) return 'Enter a valid birthdate.';
                return '';
            }
            default:
                return '';
        }
    }

    /** Errors only surface once the member has left the field. */
    shownError(field) {
        return this.touched[field] ? this.validate(field) : '';
    }

    fieldClass(field) {
        return this.shownError(field) ? 'has-error' : '';
    }

    get firstNameError() { return this.shownError('firstName'); }
    get lastNameError()  { return this.shownError('lastName'); }
    get mobileError()    { return this.shownError('mobile'); }
    get birthdateError() { return this.shownError('birthdate'); }

    get firstNameClass() { return this.fieldClass('firstName'); }
    get lastNameClass()  { return this.fieldClass('lastName'); }
    get mobileClass()    { return this.fieldClass('mobile'); }
    get birthdateClass() { return this.fieldClass('birthdate'); }

    handleBlur(event) {
        const field = event.target.dataset.field;
        this.touched = { ...this.touched, [field]: true };
    }

    get showCountdown() {
        return this.autoResetSeconds > 0 && this.secondsLeft > 0;
    }

    // ---------------------------------------------------------------- step 1

    focusScanner() {
        const el = this.template.querySelector('.manual__input');
        if (el && this.template.activeElement !== el) {
            el.focus();
        }
    }

    /** Kiosks lose focus on stray taps; take it back so the scanner still lands. */
    refocusSoon() {
        clearTimeout(this._refocusTimer);
        this._refocusTimer = setTimeout(() => this.focusScanner(), 120);
    }

    handleScanInput(event) {
        this.scanBuffer = event.target.value;
        this.scanError = '';

        // Hardware scanners fire a burst of keystrokes. If a full-length ID
        // arrives and no Enter follows, advance anyway after a short pause.
        clearTimeout(this._scanTimer);
        if (this.digits(this.scanBuffer).length >= ID_LENGTH) {
            this._scanTimer = setTimeout(() => this.commitScan(), 150);
        }
    }

    handleScanKey(event) {
        if (event.key === 'Enter') {
            event.preventDefault();
            clearTimeout(this._scanTimer);
            this.commitScan();
        }
    }

    commitScan() {
        if (this.checking) return;
        const id = this.digits(this.scanBuffer);
        if (id.length !== ID_LENGTH) {
            this.scanError = `That reads as ${id.length} digits. A Pag-IBIG ID has ${ID_LENGTH}.`;
            this.scanBuffer = '';
            this.refocusSoon();
            return;
        }

        // Check before the member fills anything in — making someone type
        // nine fields only to be told the pass is used would be rough.
        this.scanError = '';
        this.checking = true;

        checkPagIbigId({ pagIbigId: id })
            .then((res) => {
                if (res.available) {
                    this.form = this.blankForm();
                    this.touched = {};
                    this.form.pagIbigId = id;
                    this.errorMessage = '';
                    this.step = STEP.DETAILS;
                } else {
                    this.blockedMessage = res.message;
                    this.scanBuffer = '';
                }
            })
            .catch(() => {
                this.scanError =
                    'Could not check that card just now. Please try again.';
                this.scanBuffer = '';
                this.refocusSoon();
            })
            .finally(() => {
                this.checking = false;
            });
    }

    /** Clears the "already used" state so the next member can scan. */
    clearBlocked() {
        this.blockedMessage = '';
        this.scanBuffer = '';
        this.scanError = '';
        this.refocusSoon();
    }

    get isBlocked() {
        return !!this.blockedMessage;
    }

    get scanBusy() {
        return this.checking;
    }

    // ---------------------------------------------------------------- step 2

    handleField(event) {
        const field = event.target.dataset.field;
        let value =
            event.target.type === 'checkbox' ? event.target.checked : event.target.value;

        // Scanners, keypads and paste all deliver stray characters; keep the
        // mobile field to bare digits so the 11-digit rule means something.
        if (field === 'mobile') {
            value = this.digits(value).slice(0, 11);
        }

        this.form = { ...this.form, [field]: value };
        this.errorMessage = '';
    }

    submitForm() {
        if (!this.isFormValid || this.busy) return;
        this.busy = true;
        this.errorMessage = '';

        issueDayPass({
            pagIbigId: this.digits(this.form.pagIbigId),
            firstName: this.form.firstName.trim(),
            middleName: this.form.middleName.trim(),
            lastName: this.form.lastName.trim(),
            mobile: this.form.mobile,
            birthdate: this.form.birthdate
        })
            .then((result) => {
                this.pass = result;
                this._barcodeDrawn = false;
                this.step = STEP.PASS;
                this.startCountdown();
            })
            .catch((err) => {
                this.errorMessage =
                    err?.body?.message ||
                    'Something went wrong issuing the pass. Please ask a staff member.';
            })
            .finally(() => {
                this.busy = false;
            });
    }

    // ---------------------------------------------------------------- step 3

    drawBarcode() {
        if (this.step !== STEP.PASS || this._barcodeDrawn || !this._barcodeReady) return;
        const svg = this.template.querySelector('svg[data-barcode]');
        if (!svg || !this.membershipId) return;
        try {
            /*
             * CODE128 matches the physical Landers cards — subset C pairs the
             * digits, so 14 digits stay compact enough to fit the pass with
             * proper quiet zones. width:3 is the narrow-bar size in px; at
             * this print scale that lands well above the ~0.19mm minimum
             * scanners need. Lower it only if the barcode stops fitting.
             */
            // eslint-disable-next-line no-undef
            JsBarcode(svg, this.digits(this.membershipId), {
                format: 'CODE128',
                displayValue: false,
                margin: 10,
                height: 70,
                width: 3
            });
            this._barcodeDrawn = true;
            this.rasterise(svg);
        } catch (e) {
            this._barcodeDrawn = true;
        }
    }

    /*
     * Chrome drops scripted inline SVG when printing, so convert the drawn
     * barcode to a PNG and print that instead. 4x scale keeps the bar edges
     * crisp on thermal paper — soft edges are a common scan failure.
     */
    rasterise(svg) {
        try {
            const xml = new XMLSerializer().serializeToString(svg);
            const svg64 = 'data:image/svg+xml;base64,' + btoa(unescape(encodeURIComponent(xml)));
            const img = new Image();
            img.onload = () => {
                const scale = 4;
                const canvas = document.createElement('canvas');
                canvas.width = (svg.width.baseVal.value || 300) * scale;
                canvas.height = (svg.height.baseVal.value || 70) * scale;
                const ctx = canvas.getContext('2d');
                ctx.imageSmoothingEnabled = false;
                ctx.fillStyle = '#fff';
                ctx.fillRect(0, 0, canvas.width, canvas.height);
                ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
                const out = this.template.querySelector('img[data-barcode-img]');
                if (out) out.src = canvas.toDataURL('image/png');
            };
            img.src = svg64;
        } catch (e) {
            /* on-screen svg still renders; only the printout would be blank */
        }
    }

    printPass() {
        this.pauseCountdown();
        window.print();
    }

    startCountdown() {
        if (this.autoResetSeconds <= 0) return;
        this.secondsLeft = this.autoResetSeconds;
        this._countdownTimer = setInterval(() => {
            this.secondsLeft -= 1;
            if (this.secondsLeft <= 0) {
                this.restart();
            }
        }, 1000);
    }

    pauseCountdown() {
        clearInterval(this._countdownTimer);
        this.secondsLeft = 0;
    }

    restart() {
        this.clearTimers();
        this.form = this.blankForm();
        this.touched = {};
        this.pass = {};
        this.scanBuffer = '';
        this.scanError = '';
        this.errorMessage = '';
        this.manualEntry = false;
        this.blockedMessage = '';
        this.checking = false;
        this.busy = false;
        this._barcodeDrawn = false;
        this.step = STEP.SCAN;
    }

    clearTimers() {
        clearInterval(this._countdownTimer);
        clearTimeout(this._refocusTimer);
        clearTimeout(this._scanTimer);
        this.secondsLeft = 0;
    }

    // ---------------------------------------------------------------- helpers

    blankForm() {
        return {
            pagIbigId: '',
            firstName: '',
            middleName: '',
            lastName: '',
            mobile: '',
            birthdate: '',
            consent: false
        };
    }

    digits(v) {
        return (v || '').replace(/[^0-9]/g, '');
    }

    formatId(v) {
        const d = this.digits(v);
        if (d.length !== ID_LENGTH) return d;
        return `${d.slice(0, 4)}-${d.slice(4, 8)}-${d.slice(8, 12)}`;
    }

}