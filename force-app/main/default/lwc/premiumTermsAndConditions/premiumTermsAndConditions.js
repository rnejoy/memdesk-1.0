import { LightningElement } from 'lwc';
import LOGO from '@salesforce/resourceUrl/bpiLandersLogo';

export default class BpiTermsAndConditions extends LightningElement {
    logoUrl = LOGO;

    connectedCallback() {
        this.showLogo = !!this.logoUrl;
        this.signupStoreCode = this.readStoreFromUrl();
    }

    handleLogoError() {
        this.showLogo = false;
    }


}