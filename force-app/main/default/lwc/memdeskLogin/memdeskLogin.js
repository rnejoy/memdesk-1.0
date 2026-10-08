import { LightningElement, api } from 'lwc';
import MEMDESK_LOGIN_BG from '@salesforce/resourceUrl/memdeskLoginBg';
import MEMDESK_LOGIN_CENTER_IMG from '@salesforce/resourceUrl/memdeskLoginPhoto';
import MEMDESK_LOGIN_LOGO from '@salesforce/resourceUrl/memdeskLoginLogo';
import userExists from '@salesforce/apex/LoginAuthController.userExists';

export default class MemdeskLogin extends LightningElement {
    memdeskLoginBg = MEMDESK_LOGIN_BG;
    memdeskLoginCenterImage = MEMDESK_LOGIN_CENTER_IMG;
    memdeskLoginLogo = MEMDESK_LOGIN_LOGO;

    // View state
    isLoggedIn = false;
    loggedInUser = '';
    loggedInStore = 'Alabang'; 

    email = '';
    password = '';
    errorMessage = '';
    successMessage = '';

    emailInvalid = false;
    passwordInvalid = false;
    isLoading = false;

    showForgotModal = false;
    focusModal = false;

    currentDateTime = '';
    timerId;

    connectedCallback() {
        this.updateDateTime();
        this.timerId = setInterval(() => this.updateDateTime(), 1000);
    }

    disconnectedCallback() {
        clearInterval(this.timerId);
    }

    updateDateTime() {
        const now = new Date();

        const date = now.toLocaleDateString('en-US', {
            weekday: 'short',
            month: 'short',
            day: 'numeric',
            year: 'numeric',
            timeZone: 'Asia/Manila'
        });

        const time = now.toLocaleTimeString('en-US', {
            hour: 'numeric',
            minute: '2-digit',
            hour12: true,
            timeZone: 'Asia/Manila'
        });

        this.currentDateTime = `${date} · ${time}`;
    }

    renderedCallback() {
        this.template.host.style.setProperty('--memdesk-login-bg', `url(${this.memdeskLoginBg})`);

        if (this.focusModal) {
            const closeBtn = this.template.querySelector('.modal-close');
            if (closeBtn) {
                closeBtn.focus();
            }
            this.focusModal = false;
        }
    }

    handleEmailChange(event) {
        this.email = event.target.value;
        this.clearErrors();
    }

    handlePasswordChange(event) {
        this.password = event.target.value;
        this.clearErrors();
    }

    clearErrors() {
        this.errorMessage = '';
        this.successMessage = '';
        this.emailInvalid = false;
        this.passwordInvalid = false;
    }

    // Forgot password 
    openForgotModal() {
        this.showForgotModal = true;
        this.focusModal = true;
    }

    closeForgotModal() {
        this.showForgotModal = false;
    }

    handleBackdropClick(event) {
        if (event.target === event.currentTarget) {
            this.closeForgotModal();
        }
    }

    handleModalKeydown(event) {
        if (event.key === 'Escape') {
            this.closeForgotModal();
        }
    }

    // Validation
    validateForm() {
        const email = this.email.trim();
        const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

        if (!email && !this.password) {
            this.emailInvalid = true;
            this.passwordInvalid = true;
            this.errorMessage = 'Please enter your email and password.';
            return false;
        }

        if (!email) {
            this.emailInvalid = true;
            this.errorMessage = 'Please enter your email.';
            return false;
        }

        if (!emailPattern.test(email)) {
            this.emailInvalid = true;
            this.errorMessage = 'Please enter a valid email address.';
            return false;
        }

        if (!this.password) {
            this.passwordInvalid = true;
            this.errorMessage = 'Please enter your password.';
            return false;
        }

        return true;
    }

    async handleSubmit() {
        if (this.isLoading) {
            return;
        }

        this.clearErrors();

        if (!this.validateForm()) {
            return;
        }

        this.isLoading = true;

        try {
            const exists = await userExists({
                email: this.email.trim()
            });

            if (!exists) {
                this.emailInvalid = true;
                this.passwordInvalid = true;
                this.errorMessage = 'Incorrect email or password. Please try again.';
                return;
            }

            // ACCOUNT EXISTS -> Switch to landing page view
            this.loggedInUser = this.email.trim().split('@')[0];
            this.isLoggedIn = true;
        } catch (error) {
            console.error('Account verification error:', JSON.stringify(error));
            this.errorMessage =
                error?.body?.message ||
                'Unable to verify the account. Please try again.';
        } finally {
            this.isLoading = false;
        }
    }

    handleLogout() {
        this.isLoggedIn = false;
        this.email = '';
        this.password = '';
        this.clearErrors();
    }

    get emailClass() {
        return this.emailInvalid ? 'form-field field-error' : 'form-field';
    }

    get passwordClass() {
        return this.passwordInvalid ? 'form-field field-error' : 'form-field';
    }

    get submitLabel() {
        return this.isLoading ? 'Verifying...' : 'Submit';
    }
}