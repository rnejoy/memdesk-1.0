import { LightningElement, api } from 'lwc';
import MEMDESK_LOGIN_LOGO from '@salesforce/resourceUrl/memdeskLoginLogo';
import getPhoto from '@salesforce/apex/MemdeskPhotoController.getPhoto';

const CODE39 = {
    '0': 'nnnwwnwnn', '1': 'wnnwnnnnw', '2': 'nnwwnnnnw', '3': 'wnwwnnnnn', '4': 'nnnwwnnnw',
    '5': 'wnnwwnnnn', '6': 'nnwwwnnnn', '7': 'nnnwnnwnw', '8': 'wnnwnnwnn', '9': 'nnwwnnwnn',
    '*': 'nwnnwnwnn'
};

const cardDate = (value) => {
    const match = /^(\d{4})-(\d{2})-(\d{2})/.exec(String(value || ''));
    return match ? `${match[2]}/${match[3]}/${match[1]}` : '';
};

export default class memdeskPrintCardModal extends LightningElement {
    @api member;
    @api recordKey = '';
    @api idText = '';
    @api fallbackPhotoUrl = '';

    logoUrl = MEMDESK_LOGIN_LOGO;
    savedPhotoUrl = '';
    focusModal = true;
    printTab = 'preview';
    cardTextSize = 10;
    cardTextOffset = 0;
    printedSteps = [];

    connectedCallback() {
        this.loadPhoto();
    }

    renderedCallback() {
        if (this.focusModal) {
            const modal = this.template.querySelector('.pc-modal');
            if (modal) {
                modal.focus();
                this.focusModal = false;
            }
        }
    }

    async loadPhoto() {
        if (!this.recordKey) {
            return;
        }
        try {
            const url = await getPhoto({ recordKey: this.recordKey, recordType: 'Member' });
            if (url) {
                this.savedPhotoUrl = url;
            }
        } catch (error) {
            this.savedPhotoUrl = '';
        }
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('closemodal'));
    }

    handleBackdropClick(event) {
        if (event.target === event.currentTarget) {
            this.handleClose();
        }
    }

    handleKeydown(event) {
        if (event.key === 'Escape') {
            this.handleClose();
        }
    }

    handleTab(event) {
        this.printTab = event.currentTarget.dataset.tab;
    }

    handleTextSize(event) {
        const next = this.cardTextSize + Number(event.currentTarget.dataset.delta);
        this.cardTextSize = Math.min(16, Math.max(6, next));
    }

    handleTextPos(event) {
        const next = this.cardTextOffset + Number(event.currentTarget.dataset.delta) * 2;
        this.cardTextOffset = Math.min(20, Math.max(-20, next));
    }

    handlePrintStep(event) {
        const id = event.currentTarget.dataset.id;
        const step = this.printSteps.find((item) => item.id === id);
        if (!step || !step.ready) {
            return;
        }
        window.print();
        this.printedSteps = [...this.printedSteps, id];
    }

    handleComplete() {
        this.dispatchEvent(new CustomEvent('printcomplete'));
    }

    get isExecutive() {
        return /executive/i.test(this.member?.customerType || '');
    }

    get printSteps() {
        const defs = this.isExecutive
            ? [{ id: 'underlay', label: 'White underlay' }, { id: 'color', label: 'Full Color' }]
            : [{ id: 'color', label: 'Full Color' }];
        return defs.map((def, index) => {
            const printed = this.printedSteps.includes(def.id);
            const ready = !printed && defs.slice(0, index).every((prev) => this.printedSteps.includes(prev.id));
            return {
                id: def.id,
                number: index + 1,
                label: def.label,
                printed,
                ready,
                status: printed ? 'Printed' : ready ? 'Ready to print' : '',
                btnLabel: printed ? 'Printed' : `Print Step ${index + 1}`,
                btnDisabled: !ready
            };
        });
    }

    get allPrinted() {
        return this.printSteps.every((step) => step.printed);
    }

    get adjustDisabled() {
        return this.printTab === 'ready';
    }

    get previewTabClass() {
        return this.printTab === 'preview' ? 'pc-tab is-active' : 'pc-tab';
    }

    get readyTabClass() {
        return this.printTab === 'ready' ? 'pc-tab is-active' : 'pc-tab';
    }

    get cardClass() {
        return this.isExecutive ? 'pc-card is-executive' : 'pc-card is-premium';
    }

    get cardName() {
        const m = this.member || {};
        return [m.firstName, m.lastName].filter(Boolean).join(' ').toUpperCase();
    }

    get cardSince() {
        return cardDate(this.member?.startDate);
    }

    get cardThru() {
        return cardDate(this.member?.expiryDate);
    }

    get cardPhoto() {
        return this.savedPhotoUrl || this.fallbackPhotoUrl;
    }

    get nameStyle() {
        return `font-size:${this.cardTextSize}px;`;
    }

    get idStyle() {
        return `font-size:${Math.max(6, this.cardTextSize - 1)}px;`;
    }

    get textBlockStyle() {
        return `transform:translateY(${this.cardTextOffset}px);`;
    }

    get barcodeSrc() {
        const id = String(this.member?.membershipId || '');
        let x = 0;
        let bars = '';
        for (const ch of `*${id}*`) {
            const pattern = CODE39[ch];
            if (!pattern) {
                continue;
            }
            for (let i = 0; i < 9; i++) {
                const w = pattern[i] === 'w' ? 3 : 1;
                if (i % 2 === 0) {
                    bars += `<rect x="${x}" width="${w}" height="1"/>`;
                }
                x += w;
            }
            x += 1;
        }
        if (!bars) {
            return '';
        }
        const fill = this.isExecutive ? '#ffffff' : '#000000';
        const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${x} 1" preserveAspectRatio="none" shape-rendering="crispEdges" fill="${fill}">${bars}</svg>`;
        return `data:image/svg+xml;charset=utf-8,${encodeURIComponent(svg)}`;
    }
}