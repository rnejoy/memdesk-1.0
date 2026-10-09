import { LightningElement, api } from 'lwc';
import MEMDESK_LOGIN_LOGO from '@salesforce/resourceUrl/memdeskLoginLogo';
import MIMI_PHOTO from '@salesforce/resourceUrl/mimi';
import searchRecords from '@salesforce/apex/MemdeskSearchController.searchRecords';
import getMemberByBarcode from '@salesforce/apex/MemdeskSearchController.getMemberByBarcode';
import getMemberDetails from '@salesforce/apex/MemdeskMemberController.getMemberDetails';
import verifyOverride from '@salesforce/apex/MemdeskEditController.verifyOverride';
import saveMember from '@salesforce/apex/MemdeskEditController.saveMember';
import savePreferences from '@salesforce/apex/MemdeskEditController.savePreferences';
import getProvinces from '@salesforce/apex/MemdeskLookupController.getProvinces';
import getCities from '@salesforce/apex/MemdeskLookupController.getCities';
import getBarangays from '@salesforce/apex/MemdeskLookupController.getBarangays';
import getPicklist from '@salesforce/apex/MemdeskLookupController.getPicklist';

const EMPTY = '—';
const PH_MOBILE = /^(09|\+639)\d{9}$/;
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

const REACH_LABELS = ['Email', 'Mail Service', 'Mobilephone', 'Home Phone'];
const SOURCE_LABELS = ['Walk In', 'Sales Team', 'Ads', 'Referral', 'Website'];

const show = (value) =>
    value === null || value === undefined || value === '' ? EMPTY : String(value);

// "2025-07-10" or "2025-07-10T08:00:00Z" -> "Jul 10, 2025"
const formatDate = (value) => {
    if (!value) {
        return EMPTY;
    }
    const match = /^(\d{4})-(\d{2})-(\d{2})/.exec(String(value));
    if (!match) {
        return String(value);
    }
    return new Date(Number(match[1]), Number(match[2]) - 1, Number(match[3])).toLocaleDateString('en-US', {
        month: 'short',
        day: 'numeric',
        year: 'numeric'
    });
};

const toIsoDate = (value) => {
    const match = /^(\d{4}-\d{2}-\d{2})/.exec(String(value || ''));
    return match ? match[1] : '';
};

const formatMonths = (value) => {
    if (value === null || value === undefined || value === '') {
        return EMPTY;
    }
    if (/^\d+(\.\d+)?$/.test(String(value))) {
        return `${value} ${Number(value) === 1 ? 'month' : 'months'}`;
    }
    return String(value);
};

const isTrue = (value) => value === true || value === 'true';

export default class MemdeskLandingPage extends LightningElement {
    memdeskLoginLogo = MEMDESK_LOGIN_LOGO;

    @api storeName = 'Alabang';
    @api userName = 'Override User';

    showUserMenu = false;

    // ----- Detail view -----
    showDetailView = false;
    selectedMemberData = null;
    isLoadingDetails = false;
    isRefreshing = false;
    detailKey = '';
    detailRecordType = 'Member';
    detailError = '';

    voucherCode = '';
    voucherError = '';
    notice = '';
    noticeTimer;

    // ----- Edit mode -----
    isEditing = false;
    isSaving = false;
    isDirty = false;
    discardWarned = false;
    overrideBarcode = '';
    edit = {};
    errors = {};
    lookupsReady = false;
    provinceOptions = [];
    cityOptions = [];
    barangayOptions = [];
    nationalityOptions = [];
    maritalOptions = [];
    genderOptions = [];

    // ----- Override modal -----
    showOverrideModal = false;
    overrideError = '';
    overrideChecking = false;
    overrideFocused = false;
    focusOverrideInput = false;

    // ----- Reach / hear-about checkboxes -----
    prefs = { reach: {}, source: {} };
    prefTimer;
    prefPending = false;

    // ----- Scan -----
    isScanning = false;
    focusScanInput = false;
    scanMessage = '';

    // ----- Search -----
    searchType = 'Member';
    searchText = '';
    showNameFields = false;
    firstName = '';
    middleName = '';
    lastName = '';
    searchError = '';
    lastNameError = '';

    // ----- Results -----
    hasSearched = false;
    lastQuery = null;
    allResults = [];
    pageNumber = 1;
    pageSize = 4;
    selectedId = '';

    showPrintModal = false;

    renderedCallback() {
        if (this.focusScanInput) {
            const input = this.template.querySelector('.scan-input');
            if (input) {
                input.focus();
                this.focusScanInput = false;
            }
        }
        if (this.focusOverrideInput) {
            const input = this.template.querySelector('.override-input');
            if (input) {
                input.focus();
                this.focusOverrideInput = false;
            }
        }
    }

    disconnectedCallback() {
        clearTimeout(this.noticeTimer);
        clearTimeout(this.prefTimer);
    }

    get isSearchMode() {
        return !this.showDetailView;
    }

    // Photo from the record, otherwise the default image
    get detailPhotoUrl() {
        if (this.selectedMemberData && this.selectedMemberData.photoUrl) {
            return this.selectedMemberData.photoUrl;
        }
        return MIMI_PHOTO;
    }

    async openDetailView(recordId, recordType) {
        this.resetEditState();
        this.detailKey = recordId;
        this.detailRecordType = recordType;
        this.selectedId = recordId;
        this.searchError = '';
        this.detailError = '';
        this.selectedMemberData = null;
        this.showDetailView = true;
        await this.loadDetails();
    }

    async loadDetails(silent = false) {
        if (!silent) {
            this.isLoadingDetails = true;
        }
        try {
            const result = await getMemberDetails({
                memberKey: this.detailKey,
                recordType: this.detailRecordType
            });
            if (!result) {
                throw new Error('No details were returned.');
            }
            this.selectedMemberData = result;
            this.initPrefs(result);
        } catch (error) {
            console.error('Error fetching details:', error);
            if (!silent) {
                this.selectedMemberData = null;
            }
            this.detailError = error?.body?.message || 'We could not load this record. Please go back and try again.';
        } finally {
            this.isLoadingDetails = false;
        }
    }

    async handleRefresh() {
        if (this.isRefreshing || this.isEditing) {
            return;
        }
        this.isRefreshing = true;
        await this.loadDetails(true);
        this.isRefreshing = false;
        this.showNotice('Details refreshed.');
    }

    handleBackToSearch() {
        if (this.isEditing && this.isDirty && !this.discardWarned) {
            this.discardWarned = true;
            this.showNotice('You have unsaved changes. Press Back again to discard them.');
            return;
        }
        this.flushPrefs();
        this.resetEditState();
        this.showDetailView = false;
        this.selectedMemberData = null;
        this.detailError = '';
    }

    resetEditState() {
        this.isEditing = false;
        this.isSaving = false;
        this.isDirty = false;
        this.discardWarned = false;
        this.overrideBarcode = '';
        this.edit = {};
        this.errors = {};
        this.showOverrideModal = false;
        this.overrideError = '';
    }

    showNotice(message) {
        this.notice = message;
        clearTimeout(this.noticeTimer);
        this.noticeTimer = setTimeout(() => {
            this.notice = '';
        }, 3500);
    }

    handlePlaceholderAction(event) {
        const name = event.currentTarget.dataset.name;
        this.showNotice(`${name} is not connected yet.`);
    }

    async handleCopyId() {
        const id = this.selectedMemberData?.membershipId;
        if (!id) {
            return;
        }
        try {
            await navigator.clipboard.writeText(String(id));
            this.showNotice('Membership ID copied.');
        } catch (error) {
            this.showNotice('Could not copy. Select the ID and press Ctrl+C.');
        }
    }

    handleVoucherInput(event) {
        this.voucherCode = event.target.value;
        this.voucherError = '';
    }

    handleVoucherKeydown(event) {
        if (event.key === 'Enter') {
            event.preventDefault();
            this.handleVoucherSubmit();
        }
    }

    handleVoucherSubmit() {
        if (!this.voucherCode.trim()) {
            this.voucherError = 'Enter a voucher code.';
            return;
        }
        this.showNotice('Voucher validation is not connected yet.');
    }

    initPrefs(m) {
        this.prefs = {
            reach: {
                Email: isTrue(m.reachEmail),
                'Mail Service': isTrue(m.reachMail),
                Mobilephone: isTrue(m.reachMobile),
                'Home Phone': isTrue(m.reachHomePhone)
            },
            source: {
                'Walk In': isTrue(m.sourceWalkIn),
                'Sales Team': isTrue(m.sourceSalesTeam),
                Ads: isTrue(m.sourceAds),
                Referral: isTrue(m.sourceReferral),
                Website: isTrue(m.sourceWebsite)
            }
        };
    }

    prefItems(group, labels) {
        return labels.map((label) => {
            const checked = Boolean(this.prefs[group][label]);
            return {
                label,
                group,
                ariaChecked: checked ? 'true' : 'false',
                boxClass: checked ? 'check-box is-checked' : 'check-box'
            };
        });
    }

    openPrintModal() {
        if (this.isLead) {
            this.showNotice('Printing is available for members only.');
            return;
        }
        this.showPrintModal = true;
    }

    closePrintModal() {
        this.showPrintModal = false;
    }

    handlePrintComplete() {
        this.showPrintModal = false;
        this.showNotice('Card printing completed.');
    }

    get pageClass() {
        return this.showPrintModal ? 'page is-printing-card' : 'page';
    }

    get reachItems() {
        return this.prefItems('reach', REACH_LABELS);
    }

    get sourceItems() {
        return this.prefItems('source', SOURCE_LABELS);
    }

    get prefsLocked() {
        return this.isLead;
    }

    handlePrefToggle(event) {
        if (this.isLead) {
            return;
        }
        const { group, label } = event.currentTarget.dataset;
        const current = this.prefs[group];
        this.prefs = { ...this.prefs, [group]: { ...current, [label]: !current[label] } };

        this.prefPending = true;
        clearTimeout(this.prefTimer);
        this.prefTimer = setTimeout(() => this.persistPrefs(), 900);
    }

    flushPrefs() {
        if (this.prefPending) {
            clearTimeout(this.prefTimer);
            this.persistPrefs();
        }
    }

    async persistPrefs() {
        this.prefPending = false;
        const join = (group, labels) => labels.filter((label) => this.prefs[group][label]).join(', ');
        try {
            await savePreferences({
                memberKey: this.detailKey,
                reachText: join('reach', REACH_LABELS),
                sourceText: join('source', SOURCE_LABELS)
            });
            this.showNotice('Preferences saved.');
        } catch (error) {
            this.showNotice(error?.body?.message || 'Could not save the preferences.');
        }
    }

    handleEditSave() {
        if (this.isSaving) {
            return;
        }
        if (this.isEditing) {
            this.saveChanges();
        } else {
            this.requestEdit();
        }
    }

    requestEdit() {
        if (this.isLead || !this.selectedMemberData?.isEditable) {
            this.showNotice('Editing leads is not set up yet.');
            return;
        }
        this.overrideError = '';
        this.showOverrideModal = true;
        this.focusOverrideInput = true;
    }

    closeOverrideModal() {
        this.showOverrideModal = false;
        this.overrideError = '';
    }

    handleOverrideBackdrop(event) {
        if (event.target === event.currentTarget) {
            this.closeOverrideModal();
        }
    }

    handleOverrideEsc(event) {
        if (event.key === 'Escape') {
            this.closeOverrideModal();
        }
    }

    refocusOverride() {
        this.focusOverrideInput = true;
        const input = this.template.querySelector('.override-input');
        if (input) {
            input.focus();
        }
    }

    handleOverrideFocus() {
        this.overrideFocused = true;
    }

    handleOverrideBlur() {
        this.overrideFocused = false;
    }

    handleOverrideClick(event) {
        if (event.target.tagName === 'BUTTON') {
           return;
        }
        this.checkOverride('OVERRIDE');
    }

    get overrideIconClass() {
        return this.overrideFocused ? 'override-icon-wrap is-focused' : 'override-icon-wrap';
    }

    handleOverrideScan(event) {
        if (event.key !== 'Enter') {
            return;
        }
        event.preventDefault();
        const code = event.target.value.trim();
        event.target.value = '';
        if (code) {
            this.checkOverride(code);
        }
    }

    async checkOverride(code) {
        if (this.overrideChecking) {
            return;
        }
        this.overrideChecking = true;
        try {
            const ok = await verifyOverride({ barcode: code });
            if (ok) {
                this.overrideBarcode = code;
                this.showOverrideModal = false;
                this.overrideError = '';
                await this.startEditing();
            } else {
                this.overrideError = 'Incorrect barcode scanned. Try again.';
                this.focusOverrideInput = true;
            }
        } catch (error) {
            this.overrideError = 'Could not check the barcode. Try again.';
            this.focusOverrideInput = true;
        } finally {
            this.overrideChecking = false;
        }
    }

    async startEditing() {
        const m = this.selectedMemberData || {};
        this.edit = {
            firstName: m.firstName || '',
            middleName: m.middleName || '',
            lastName: m.lastName || '',
            street: m.street || '',
            provinceValue: '',
            cityValue: '',
            barangayValue: '',
            mobile: m.mobileNumber || '',
            altMobile: m.altMobileNumber || '',
            email: m.email || '',
            occupation: m.occupation || '',
            birthdate: toIsoDate(m.birthdate),
            nationality: m.nationality || '',
            maritalStatus: m.maritalStatus || '',
            gender: m.gender || '',
            remarks: m.remarks || ''
        
        };
        this.errors = {};
        this.isDirty = false;
        this.discardWarned = false;
        this.isEditing = true;
        await this.prepareLookups();
    }

    matchOption(options, code, text) {
        const wanted = String(text || '').trim().toLowerCase();
        return (
            options.find((option) => code && String(option.value) === String(code)) ||
            (wanted ? options.find((option) => String(option.label).trim().toLowerCase() === wanted) : null) ||
            null
        );
    }

    async prepareLookups() {
        const m = this.selectedMemberData || {};
        try {
            if (!this.lookupsReady) {
                const [provinces, nationalities, marital, genders] = await Promise.all([
                    getProvinces(),
                    getPicklist({ fieldApiName: 'Nationality__c' }),
                    getPicklist({ fieldApiName: 'Marital_Status__c' }),
                    getPicklist({ fieldApiName: 'Gender__c' })
                ]);
                this.provinceOptions = provinces || [];
                this.nationalityOptions = nationalities || [];
                this.maritalOptions = marital || [];
                this.genderOptions = genders || [];
            }

            const province = this.matchOption(this.provinceOptions, m.provinceCode, m.province);
            const cities = province ? (await getCities({ provinceCode: province.value })) || [] : [];
            const city = this.matchOption(cities, m.cityCode, m.city);
            const barangays = city ? (await getBarangays({ cityCode: city.value })) || [] : [];
            const barangay = this.matchOption(barangays, m.barangayCode, m.barangay);

            this.cityOptions = cities;
            this.barangayOptions = barangays;
            this.edit = {
                ...this.edit,
                provinceValue: province ? province.value : m.province ? `text:${m.province}` : '',
                cityValue: city ? city.value : m.city ? `text:${m.city}` : '',
                barangayValue: barangay ? barangay.value : m.barangay ? `text:${m.barangay}` : ''
            };
        } catch (error) {
            console.error('Lookup error:', error);
            this.showNotice('Some dropdown lists could not be loaded.');
        }
    }

    markDirty() {
        this.isDirty = true;
        this.discardWarned = false;
    }

    handleEditInput(event) {
        const field = event.target.dataset.field;
        this.edit = { ...this.edit, [field]: event.target.value };
        if (this.errors[field]) {
            this.errors = { ...this.errors, [field]: '' };
        }
        this.markDirty();
    }

    handleEditSelect(event) {
        const field = event.target.dataset.field;
        const value = event.target.value;
        this.markDirty();

        if (field === 'province') {
            this.changeProvince(value);
        } else if (field === 'city') {
            this.changeCity(value);
        } else if (field === 'barangay') {
            this.edit = { ...this.edit, barangayValue: value };
        } else {
            this.edit = { ...this.edit, [field]: value };
        }
    }

    async changeProvince(value) {
        this.edit = { ...this.edit, provinceValue: value, cityValue: '', barangayValue: '' };
        this.cityOptions = [];
        this.barangayOptions = [];
        if (value && !value.startsWith('text:')) {
            try {
                this.cityOptions = (await getCities({ provinceCode: value })) || [];
            } catch (error) {
                this.showNotice('The city list could not be loaded.');
            }
        }
    }

    async changeCity(value) {
        this.edit = { ...this.edit, cityValue: value, barangayValue: '' };
        this.barangayOptions = [];
        if (value && !value.startsWith('text:')) {
            try {
                this.barangayOptions = (await getBarangays({ cityCode: value })) || [];
            } catch (error) {
                this.showNotice('The barangay list could not be loaded.');
            }
        }
    }

    validateEdit() {
        const e = this.edit;
        const errors = {};
        if (!e.lastName.trim() && !this.selectedMemberData?.lastName) {
        }
        if (e.mobile.trim() && !PH_MOBILE.test(e.mobile.trim())) {
            errors.mobile = 'Use 09XXXXXXXXX or +639XXXXXXXXX.';
        }
        if (e.altMobile.trim() && !PH_MOBILE.test(e.altMobile.trim())) {
            errors.altMobile = 'Use 09XXXXXXXXX or +639XXXXXXXXX.';
        }
        if (e.email.trim() && !EMAIL_RE.test(e.email.trim())) {
            errors.email = 'Enter a valid email address.';
        }
        if (e.birthdate) {
            const date = new Date(`${e.birthdate}T00:00:00`);
            if (Number.isNaN(date.getTime()) || date > new Date()) {
                errors.birthdate = 'Enter a valid birthdate.';
            }
        }
        return errors;
    }

    buildPayload() {
        const e = this.edit;
        const labelOf = (options, value) => {
            if (!value) {
                return '';
            }
            if (value.startsWith('text:')) {
                return value.slice(5);
            }
            const option = options.find((item) => item.value === value);
            return option ? option.label : '';
        };
      
        const codeOf = (value) => {
            if (!value) {
                return '';
            }
            return value.startsWith('text:') ? null : value;
        };

        return {
            firstName: e.firstName.trim(),
            middleName: e.middleName.trim(),
            lastName: e.lastName.trim(),
            street: e.street.trim(),
            province: labelOf(this.provinceOptions, e.provinceValue),
            provinceCode: codeOf(e.provinceValue),
            city: labelOf(this.cityOptions, e.cityValue),
            cityCode: codeOf(e.cityValue),
            barangay: labelOf(this.barangayOptions, e.barangayValue),
            barangayCode: codeOf(e.barangayValue),
            mobile: e.mobile.trim(),
            altMobile: e.altMobile.trim(),
            email: e.email.trim(),
            occupation: e.occupation.trim(),
            birthdate: e.birthdate,
            nationality: e.nationality,
            maritalStatus: e.maritalStatus,
            gender: e.gender,
            remarks: e.remarks.trim()
        };
    }

    async saveChanges() {
        console.log('SAVE PAYLOAD', JSON.stringify(this.buildPayload()));
        this.errors = this.validateEdit();
        if (Object.keys(this.errors).some((key) => this.errors[key])) {
            this.showNotice('Please fix the highlighted fields.');
            return;
        }

        this.isSaving = true;
        try {
            const skipped = await saveMember({
                memberKey: this.detailKey,
                overrideBarcode: this.overrideBarcode,
                edit: this.buildPayload()
            });

            this.isEditing = false;
            this.isDirty = false;
            this.discardWarned = false;
            this.overrideBarcode = '';
            this.edit = {};
            this.errors = {};
            await this.loadDetails(true);

            this.showNotice(
                skipped && skipped.length ? `Saved. Not updated: ${skipped.join(', ')}` : 'Changes saved.'
            );
        } catch (error) {
            this.showNotice(error?.body?.message || 'Could not save. Please try again.');
        } finally {
            this.isSaving = false;
        }
    }

    get editButtonLabel() {
        if (this.isSaving) {
            return 'Saving...';
        }
        return this.isEditing ? 'Save' : 'Edit';
    }

    get editButtonClass() {
        return this.isEditing ? 'btn btn-lime' : 'btn';
    }

    get refreshDisabled() {
        return this.isRefreshing || this.isEditing;
    }

    get hasDetails() {
        return Boolean(this.selectedMemberData);
    }

    get isLead() {
        return this.detailRecordType === 'Lead';
    }

    get idLabel() {
        return this.isLead ? 'Lead' : 'Membership ID';
    }

    get idText() {
        if (this.isLead) {
            return 'Not a member yet';
        }
        const id = String(this.selectedMemberData?.membershipId || '');
        if (/^\d{14}$/.test(id)) {
            return `${id.slice(0, 4)}-${id.slice(4, 12)}-${id.slice(12)}`;
        }
        return id || EMPTY;
    }

    get idTextClass() {
        return this.isLead ? 'badge-number is-text' : 'badge-number';
    }

    get showCopyId() {
        return !this.isLead;
    }

    get isVatExempt() {
        return isTrue(this.selectedMemberData?.isVatExempt);
    }

    get statusClass() {
        const status = String(this.selectedMemberData?.status || '').toLowerCase();
        if (status === 'active') {
            return 'pill pill-active';
        }
        if (['expired', 'inactive', 'cancelled', 'canceled', 'suspended'].includes(status)) {
            return 'pill pill-danger';
        }
        return 'pill pill-neutral';
    }

    buildSelect(options, selected, placeholder) {
        const list = [{ value: '', label: placeholder }];
        if (selected && selected.startsWith('text:')) {
            list.push({ value: selected, label: selected.slice(5) });
        }
        options.forEach((option) => list.push({ value: option.value, label: option.label }));
        return list.map((option) => ({ ...option, selected: option.value === (selected || '') }));
    }

    buildPicklist(options, current) {
        const list = [{ value: '', label: 'Select' }];
        const known = options.some((option) => option.value === current);
        if (current && !known) {
            list.push({ value: current, label: current });
        }
        options.forEach((option) => list.push({ value: option.value, label: option.label }));
        return list.map((option) => ({ ...option, selected: option.value === (current || '') }));
    }

    staticField(key, label, display, full = true, extra = {}) {
        return {
            key,
            label,
            display,
            wrapClass: full ? 'field span-2' : 'field',
            showInput: false,
            valueClass: this.isEditing ? 'value is-locked' : 'value',
            ...extra
        };
    }

    headingField(key, label) {
        return { key, label, isHeading: true, wrapClass: 'field span-2 field-heading' };
    }

    editField(key, label, display, config = {}) {
        const {
            kind = 'text',
            inputType = 'text',
            full = true,
            maxlength = 100,
            required = false,
            options = [],
            disabled = false,
            actionHref = '',
            actionLabel = '',
            isSms = false
        } = config;
        const hasAction = !this.isEditing && Boolean(actionHref);
        const error = this.errors[key] || '';

        let valueClass = 'value';
        if (kind === 'textarea') {
            valueClass = 'value is-remarks';
        } else if (hasAction) {
            valueClass = 'value has-action';
        }

        return {
            key,
            label,
            display,
            required,
            value: this.edit[key] === undefined ? '' : this.edit[key],
            wrapClass: full ? 'field span-2' : 'field',
            showInput: this.isEditing,
            isSelect: kind === 'select',
            isTextarea: kind === 'textarea',
            inputType,
            maxlength,
            options,
            disabled,
            error,
            inputClass: error ? 'input has-error' : 'input',
            valueClass,
            hasAction,
            actionHref,
            actionLabel,
            isSms
        };
    }

    get cards() {
        return [
            { key: 'membership', fields: this.membershipFields },
            { key: 'personal', fields: this.personalFields },
            { key: 'contact', fields: this.contactFields }
        ];
    }

    get membershipFields() {
        const m = this.selectedMemberData || {};
        return [
            this.staticField('customerType', 'Customer Type', show(m.customerType)),
            this.staticField('membershipType', 'Membership Type', show(m.membershipType)),
            this.staticField('accountLevel', 'Account Level', show(m.accountLevel)),
            this.staticField('status', 'Status', show(m.status), true, { isPill: true, pillClass: this.statusClass }),
            this.staticField('monthsToGo', 'Months To Go', formatMonths(m.monthsToGo)),
            this.staticField('startDate', 'Start Date', formatDate(m.startDate), false),
            this.staticField('expiryDate', 'Expiry Date', formatDate(m.expiryDate), false),
            this.staticField('paidDate', 'Membership Paid Date', formatDate(m.membershipPaidDate)),
            this.staticField('cardPrintedDate', 'Card Printed Date', formatDate(m.cardPrintedDate))
        ];
    }

    get personalFields() {
        const m = this.selectedMemberData || {};
        const e = this.edit;
        return [
            this.editField('firstName', 'First Name', show(m.firstName), { maxlength: 40 }),
            this.editField('middleName', 'Middle Name', show(m.middleName), { maxlength: 40 }),
            this.editField('lastName', 'Last Name', show(m.lastName), { maxlength: 80, required: true }),
            this.staticField('suffix', 'Suffix', show(m.suffix), false),
            this.editField('gender', 'Gender', show(m.gender), {
                kind: this.genderOptions.length ? 'select' : 'text',
                full: false,
                maxlength: 30,
                options: this.buildPicklist(this.genderOptions, e.gender)
            }),
                        this.headingField('addressHeading', 'Address'),
            this.editField('street', 'Street', show(m.street), { maxlength: 100 }),
            this.editField('barangay', 'Barangay', show(m.barangay), {
                kind: 'select',
                disabled: !e.cityValue,
                options: this.buildSelect(this.barangayOptions, e.barangayValue, e.cityValue ? 'Select barangay' : 'Select city first')
            }),
            this.editField('city', 'City / Municipality', show(m.city), {
                kind: 'select',
                disabled: !e.provinceValue,
                options: this.buildSelect(this.cityOptions, e.cityValue, e.provinceValue ? 'Select city' : 'Select province first')
            }),
            this.editField('province', 'Province', show(m.province), {
                kind: 'select',
                options: this.buildSelect(this.provinceOptions, e.provinceValue, 'Select province')
            })
        ];
    }

    get contactFields() {
        const m = this.selectedMemberData || {};
        const e = this.edit;
        return [
            {
                key: 'vat',
                isVat: true,
                display: this.isVatExempt ? 'yes' : 'no',
                boxClass: this.isVatExempt ? 'check-box is-checked' : 'check-box',
                wrapClass: 'field span-2 vat-row'
            },
            this.editField('mobile', 'Mobile Number', show(m.mobileNumber), {
                inputType: 'tel',
                maxlength: 16,
                actionHref: m.mobileNumber ? `sms:${m.mobileNumber}` : '',
                actionLabel: 'Send a message',
                isSms: true
            }),
            this.editField('altMobile', 'Secondary / Alt. Mobile Number', show(m.altMobileNumber), {
                inputType: 'tel',
                maxlength: 16,
                actionHref: m.altMobileNumber ? `sms:${m.altMobileNumber}` : '',
                actionLabel: 'Send a message',
                isSms: true
            }),
            this.editField('email', 'Email', show(m.email), {
                inputType: 'email',
                maxlength: 80,
                actionHref: m.email ? `mailto:${m.email}` : '',
                actionLabel: 'Send an email'
            }),
            this.editField('occupation', 'Occupation', show(m.occupation), { maxlength: 100 }),
            this.editField('birthdate', 'Birthdate', formatDate(m.birthdate), { inputType: 'date', full: false, maxlength: 10 }),
            this.editField('nationality', 'Nationality', show(m.nationality), {
                kind: 'select',
                full: false,
                options: this.buildPicklist(this.nationalityOptions, e.nationality)
            }),
            this.editField('maritalStatus', 'Marital Status', show(m.maritalStatus), {
                kind: 'select',
                options: this.buildPicklist(this.maritalOptions, e.maritalStatus)
            }),
            this.editField('remarks', 'Remarks', show(m.remarks), { kind: 'textarea', maxlength: 300 })
        ];
    }

    toggleUserMenu() {
        this.showUserMenu = !this.showUserMenu;
    }

    closeUserMenu() {
        this.showUserMenu = false;
    }

    handleMenuKeydown(event) {
        if (event.key === 'Escape') {
            this.showUserMenu = false;
        }
    }

    handleMenuAction(event) {
        const action = event.currentTarget.dataset.action;
        this.showUserMenu = false;
        this.dispatchEvent(new CustomEvent(action === 'logout' ? 'logout' : 'menuaction', { detail: { action } }));
    }

    get menuExpanded() {
        return this.showUserMenu ? 'true' : 'false';
    }

    get userChevronClass() {
        return this.showUserMenu ? 'chevron is-open' : 'chevron';
    }

    get userInitials() {
        return this.userName
            .split(/\s+/)
            .filter(Boolean)
            .slice(0, 2)
            .map((word) => word.charAt(0).toUpperCase())
            .join('');
    }

    startScan() {
        this.isScanning = true;
        this.scanMessage = '';
        this.focusScanInput = true;
    }

    handleScanKeydown(event) {
        if (event.key === 'Escape') {
            event.target.value = '';
            this.isScanning = false;
            return;
        }
        if (event.key === 'Enter') {
            event.preventDefault();
            const code = event.target.value.trim();
            event.target.value = '';
            if (code) {
                this.handleBarcode(code);
            }
        }
    }

    handleScanBlur() {
        this.isScanning = false;
    }


    async handleBarcode(code) {
        try {
            const member = await getMemberByBarcode({ barcode: code });
            this.isScanning = false;

            if (member && (member.id || member.membershipId)) {
                await this.openDetailView(member.id || member.membershipId, 'Member');
            } else {
                this.scanMessage = `No member found for barcode: ${code}`;
            }
        } catch (error) {
            console.error('Barcode lookup error:', error);
            this.scanMessage = 'Error scanning barcode. Try again.';
            this.isScanning = false;
        }
    }

    get scanCardClass() {
        return this.isScanning ? 'scan-card is-scanning' : 'scan-card';
    }

    get scanTitle() {
        return this.isScanning ? 'Ready to scan' : 'Scan Barcode to Start';
    }

    get scanHint() {
        if (this.isScanning) {
            return 'Waiting for the scanner... press Esc to cancel';
        }
        return this.scanMessage || 'Click here, then scan a barcode';
    }

    handleTypeChange(event) {
        this.searchType = event.currentTarget.dataset.type;
        if (this.hasSearched) {
            this.performSearch();
        }
    }

    get leadToggleClass() {
        return this.searchType === 'Lead' ? 'toggle-btn is-active' : 'toggle-btn';
    }

    get memberToggleClass() {
        return this.searchType === 'Member' ? 'toggle-btn is-active' : 'toggle-btn';
    }

    get leadPressed() {
        return this.searchType === 'Lead' ? 'true' : 'false';
    }

    get memberPressed() {
        return this.searchType === 'Member' ? 'true' : 'false';
    }

    handleSearchInput(event) {
        this.searchText = event.target.value;
        this.searchError = '';
    }

    handleFirstChange(event) {
        this.firstName = event.target.value;
    }

    handleMiddleChange(event) {
        this.middleName = event.target.value;
    }

    handleLastChange(event) {
        this.lastName = event.target.value;
        this.lastNameError = '';
    }

    handleSearchKeydown(event) {
        if (event.key === 'Enter') {
            event.preventDefault();
            this.handleSearch();
        }
    }

    toggleNameFields() {
        this.searchError = '';

        if (!this.showNameFields) {
            const typed = this.searchText.trim();
            if (typed && typed !== this.composedName) {
                const parts = this.splitFullName(typed);
                this.firstName = parts.first;
                this.middleName = parts.middle;
                this.lastName = parts.last;
            }
            this.showNameFields = true;
        } else {
            if (this.composedName) {
                this.searchText = this.composedName;
            }
            this.lastNameError = '';
            this.showNameFields = false;
        }
    }

    splitFullName(text) {
        const parts = text.trim().split(/\s+/).filter(Boolean);
        if (parts.length === 0) return { first: '', middle: '', last: '' };
        if (parts.length === 1) return { first: '', middle: '', last: parts[0] };
        if (parts.length === 2) return { first: parts[0], middle: '', last: parts[1] };
        return {
            first: parts[0],
            middle: parts.slice(1, -1).join(' '),
            last: parts[parts.length - 1]
        };
    }

    get composedName() {
        return [this.firstName, this.middleName, this.lastName]
            .map((part) => part.trim())
            .filter(Boolean)
            .join(' ');
    }

    get searchInputValue() {
        return this.showNameFields ? this.composedName : this.searchText;
    }

    get searchInputReadOnly() {
        return this.showNameFields;
    }

    get nameFieldsExpanded() {
        return this.showNameFields ? 'true' : 'false';
    }

    get chevronClass() {
        return this.showNameFields ? 'chevron is-open' : 'chevron';
    }

    get lastNameClass() {
        return this.lastNameError ? 'name-input has-error' : 'name-input';
    }

    get lastNamePlaceholder() {
        return this.lastNameError || '';
    }

    handleSearch() {
        this.searchError = '';
        this.lastNameError = '';

        let query;
        if (this.showNameFields) {
            const last = this.lastName.trim();
            if (!last) {
                this.lastNameError = '*Please input Last Name';
                return;
            }
            query = { first: this.firstName.trim(), middle: this.middleName.trim(), last };
        } else {
            const text = this.searchText.trim();
            if (!text) {
                this.searchError = 'Please enter a name to search.';
                return;
            }
            query = { text };
        }

        this.lastQuery = query;
        this.hasSearched = true;
        this.performSearch();
    }

    async performSearch() {
        const q = this.lastQuery;
        try {
            const results = await searchRecords({
                searchType: this.searchType,
                searchText: q.text || '',
                firstName: q.first || '',
                middleName: q.middle || '',
                lastName: q.last || ''
            });
            this.allResults = results || [];
            this.pageNumber = 1;
            this.selectedId = '';
        } catch (error) {
            console.error('Search error:', error);
            this.searchError = 'Failed to fetch search results. Please try again.';
            this.allResults = [];
        }
    }

    async handleSelectResult(event) {
        const id = event.currentTarget.dataset.id;
        if (id) {
            await this.openDetailView(id, this.searchType);
        }
    }

    handlePrevPage() {
        if (this.pageNumber > 1) {
            this.pageNumber -= 1;
        }
    }

    handleNextPage() {
        if (this.pageNumber < this.totalPages) {
            this.pageNumber += 1;
        }
    }

    get totalResults() {
        return this.allResults.length;
    }

    get totalPages() {
        return Math.max(1, Math.ceil(this.allResults.length / this.pageSize));
    }

    get pagedResults() {
        const start = (this.pageNumber - 1) * this.pageSize;
        return this.allResults.slice(start, start + this.pageSize).map((record) => ({
            ...record,
            fullName: [record.firstName, record.middleName, record.lastName].filter(Boolean).join(' '),
            displayId: record.membershipId || record.id,
            rowClass: record.id === this.selectedId ? 'result-row is-selected' : 'result-row'
        }));
    }

    get hasResults() {
        return this.allResults.length > 0;
    }

    get noMatches() {
        return this.hasSearched && this.allResults.length === 0;
    }

    get noMatchesMessage() {
        return `No ${this.searchType.toLowerCase()} records found.`;
    }

    get resultsLabel() {
        if (!this.hasSearched) {
            return 'Results';
        }
        return `Results (${this.pagedResults.length} out of ${this.totalResults})`;
    }

    get prevDisabled() {
        return this.pageNumber <= 1;
    }

    get nextDisabled() {
        return this.pageNumber >= this.totalPages;
    }
}