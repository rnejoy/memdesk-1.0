import { LightningElement } from 'lwc';
import LOGO from '@salesforce/resourceUrl/bpiLandersLogo';
import CARD_IMAGE from '@salesforce/resourceUrl/bpiLandingImage';

export default class PremiumTermsAndConditions extends LightningElement {
    logoUrl = LOGO;
    cardImageUrl = CARD_IMAGE;
    showLogo = false;

    connectedCallback() {
        this.showLogo = !!this.logoUrl;
    }

    handleLogoError() {
        this.showLogo = false;
    }

    get hasCardImage() {
        return !!this.cardImageUrl;
    }
}