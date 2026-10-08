import { LightningElement } from 'lwc';

export default class Footer extends LightningElement {
    showModal = false;

    openPrivacyModal() {
        this.showModal = true;
    }

    closePrivacyModal() {
        this.showModal = false;
    }
}