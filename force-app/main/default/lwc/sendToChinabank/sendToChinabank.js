import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions'; 
import sendContactToBank from '@salesforce/apex/chinabankAPIService.sendToBank';

import CUSTOMER_TYPE from '@salesforce/schema/Contact.Customer_Type__c';
import CHINABANK_APPLIED from '@salesforce/schema/Contact.Chinabank_Credit_Card_Applied__c';

export default class ChinabankAction extends LightningElement {
    @api recordId;
    @track isLoading = false;

    @wire(getRecord, { recordId: '$recordId', fields: [CUSTOMER_TYPE, CHINABANK_APPLIED] })
    contact;

    async connectedCallback() {
        this.isLoading = true;
    }

    @wire(getRecord, { recordId: '$recordId', fields: [CUSTOMER_TYPE, CHINABANK_APPLIED] })
    wiredRecord({ error, data }) {
        if (data && this.isLoading) {
            this.processAction(data);
        } else if (error) {
            this.showToast('Error', 'Failed to load record.', 'error');
            this.closeAction();
        }
    }

    async processAction(data) {
        const customerType = getFieldValue(data, CUSTOMER_TYPE);
        const applied = getFieldValue(data, CHINABANK_APPLIED);

        if (customerType !== 'Executive' && customerType !== 'Business') {
            this.showToast('Error', 'Cannot send: Contact is not an Executive member.', 'error');
            this.closeAction();
            return;
        }

        if (!applied) {
            this.showToast('Error', 'Cannot send: Chinabank credit card not applied.', 'error');
            this.closeAction();
            return;
        }

        try {
            await sendContactToBank({ contactId: this.recordId });
            this.showToast('Success', 'Contact successfully sent to Chinabank.', 'success');
        } catch (error) {
            this.showToast('Error', error.body?.message || 'Error sending data.', 'error');
        } finally {
            this.closeAction();
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    closeAction() {
        this.isLoading = false;
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}