import { LightningElement, api } from 'lwc';
import LOGO from '@salesforce/resourceUrl/bpiLandersLogo';
// import HERO_IMG from '@salesforce/resourceUrl/heroImage';
import CARD_IMAGE from '@salesforce/resourceUrl/bpiLandingImage';

export default class bpiLandingPage extends LightningElement {
    logoUrl = LOGO; 
    heroImageUrl = '';
    cardImageUrl = CARD_IMAGE;
    showLogo = false;

    applyUrl = '/executivemicrosite/apply-membership';
    renewUrl = '/s/renew';
    termsUrl = '/executivemicrosite/terms-and-conditions';

    connectedCallback() {
        this.showLogo = !!this.logoUrl;
    }

    handleLogoError() {
        this.showLogo = false;
    }

    get imageStyle() {
        return this.heroImageUrl
            ? `background-image: url('${this.heroImageUrl}')`
            : '';
    }

    // Reads ?store=1010 from the QR link. Only a 4-digit code is accepted.
    readStoreFromUrl() {
        try {
            const code = new URLSearchParams(window.location.search).get('store');
            return /^\d{4}$/.test(code || '') ? code : '';
        } catch (e) {
            return '';
        }
    }

    // Carries the store code over to the application form so it is not lost
    // when the visitor clicks APPLY NOW.
    handleApply() {
        const store = this.readStoreFromUrl();
        const target = store
            ? `${this.applyUrl}?store=${encodeURIComponent(store)}`
            : this.applyUrl;
        window.location.assign(target);
    }
 
    handleRenew() {
        window.location.assign(this.renewUrl);
    }

    get hasCardImage() {
        return !!this.cardImageUrl;
    }
}