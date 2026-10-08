import { LightningElement, api, wire } from 'lwc';
import getLatestPushLog from '@salesforce/apex/ChinabankResponseController.getLatestPushLog';

export default class LatestPushLog extends LightningElement {
    @api recordId;
    log;

    @wire(getLatestPushLog, { contactId: '$recordId' })
    wiredLog({ error, data }) {
        if (data) {
            this.log = data;
        } else if (error) {
            this.log = null;
            console.error(error);
        }
    }
}