import { LightningElement, api } from 'lwc';
import LANDERS_ASSETS from '@salesforce/resourceUrl/landersPagibig';

/**
 * Benefit tiles are the marketing artwork itself — the headline copy is
 * baked into each image, so the component must not overlay its own text.
 * Order here matches the approved layout in Landers_X_PagIbig.pdf.
 */
const BENEFIT_FILES = [
    { key: 'shop', file: 'mb_3.jpg', alt: 'Shop on-the-go: same day delivery and curbside pickup using the Landers app' },
    { key: 'meds', file: 'mb_6.jpg', alt: 'Landers lowest-priced medicine at Capital Care Pharmacy' },
    { key: 'hair', file: 'mb_7.jpg', alt: 'Free haircut and blowdry services at Federal Barbers' },
    { key: 'prod', file: 'mb_1.jpg', alt: 'Access to a wide selection of premium global and local products' },
    { key: 'food', file: 'mb_5.jpg', alt: 'Excellent food and drinks choices from Landers Central, Doppio, Dough & Co.' },
    { key: 'sale', file: 'mb_2.jpg', alt: 'Participation in Super Crazy Sale, Piso Sale and other promotional activities' },
    { key: 'lpg', file: 'mb_4.jpg', alt: 'One hundred fifty pesos off on Solane refills' },
    { key: 'more', file: 'mb_9.jpg', alt: 'And more Landers member benefits' }
];

export default class Pagibiglndpartnership extends LightningElement {
    /**
     * Destinations wired in Experience Builder (see targetConfig in the meta).
     * Default to '#' so the component still renders before they're set.
     */
    @api registerUrl = '#';
    @api applyUrl = '#';

    /** Passed through to the embedded kiosk. */
    @api autoResetSeconds = 90;
    @api membershipId = '20208800006500';
    @api membershipName = 'PAG IBIG LANDERS ALL STORE DAYPASS';

    kioskOpen = false;
    _scrollY = 0;

    get cardImg() {
        return `${LANDERS_ASSETS}/goldcard.png`;
    }

    get benefits() {
        return BENEFIT_FILES.map((b) => ({
            key: b.key,
            alt: b.alt,
            src: `${LANDERS_ASSETS}/${b.file}`
        }));
    }

    openKiosk() {
        this.kioskOpen = true;
        this.lockScroll(true);
    }

    closeKiosk() {
        this.kioskOpen = false;
        this.lockScroll(false);
    }

    handleModalKey(event) {
        if (event.key === 'Escape') {
            this.closeKiosk();
        }
    }

    /* The page behind a modal shouldn't scroll under it. document.body is
       reachable from LWC, but guard it — LWS may restrict it in some contexts. */
    lockScroll(on) {
        try {
            document.body.style.overflow = on ? 'hidden' : '';
        } catch (e) {
            /* non-fatal: the modal still works, the page just scrolls behind it */
        }
    }

    handleViewBenefits(event) {
        event.preventDefault();
        const section = this.template.querySelector('.benefits');
        if (section) {
            section.scrollIntoView({ behavior: 'smooth', block: 'start' });
        }
    }

    handleHome(event) {
        event.preventDefault();
        this.template.querySelector('.page').scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
}