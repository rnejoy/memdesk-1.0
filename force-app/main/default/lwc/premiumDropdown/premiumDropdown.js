import { LightningElement, api } from 'lwc';

const TYPEAHEAD_RESET_MS = 600;

export default class BpiDropdown extends LightningElement {
    @api label = '';
    @api name = '';
    @api placeholder = 'Please select..';
    @api options = [];
    @api value = '';
    @api disabled = false;
    @api error = '';

    isOpen = false;
    activeIndex = -1;

    _scrollPending = false;
    _typed = '';
    _typedTimer;

    @api
    focus() {
        const el = this.template.querySelector('[role="combobox"]');
        if (el) {
            el.focus();
        }
    }

    disconnectedCallback() {
        clearTimeout(this._typedTimer);
    }

    renderedCallback() {
        if (this._scrollPending && this.isOpen) {
            this._scrollPending = false;
            const el = this.template.querySelector(`[data-index="${this.activeIndex}"]`);
            if (el) {
                el.scrollIntoView({ block: 'nearest' });
            }
        }
    }

    // ---------- derived state ----------
    get list() {
        return this.options || [];
    }

    get items() {
        return this.list.map((o, i) => ({
            key: o.value,
            label: o.label,
            index: i,
            className:
                'dd__option' +
                (i === this.activeIndex ? ' is-active' : '') +
                (o.value === this.value ? ' is-selected' : ''),
            selected: o.value === this.value ? 'true' : 'false'
        }));
    }

    get hasItems() {
        return this.list.length > 0;
    }

    get selectedLabel() {
        const match = this.list.find((o) => o.value === this.value);
        return match ? match.label : '';
    }

    get displayText() {
        return this.selectedLabel || this.placeholder;
    }

    get triggerClass() {
        let c = 'dd__trigger';
        if (this.isOpen) {
            c += ' is-open';
        }
        if (this.error) {
            c += ' has-error';
        }
        if (!this.selectedLabel) {
            c += ' is-placeholder';
        }
        return c;
    }

    get chevronClass() {
        return 'dd__chevron' + (this.isOpen ? ' is-open' : '');
    }

    get ariaExpanded() {
        return this.isOpen ? 'true' : 'false';
    }

    get ariaDisabled() {
        return this.disabled ? 'true' : 'false';
    }

    get tabIndexValue() {
        return this.disabled ? '-1' : '0';
    }

    // ---------- open / close / select ----------
    openList() {
        if (this.disabled) {
            return;
        }
        const selectedIndex = this.list.findIndex((o) => o.value === this.value);
        this.activeIndex = selectedIndex >= 0 ? selectedIndex : this.list.length ? 0 : -1;
        this.isOpen = true;
        this._scrollPending = true;
    }

    closeList() {
        this.isOpen = false;
        this.activeIndex = -1;
    }

    selectIndex(index) {
        const option = this.list[index];
        if (option && option.value !== this.value) {
            this.dispatchEvent(
                new CustomEvent('change', { detail: { value: option.value, name: this.name } })
            );
        }
        this.closeList();
    }

    moveActive(delta) {
        const n = this.list.length;
        if (!n) {
            return;
        }
        const next = this.activeIndex < 0 && delta > 0 ? 0 : this.activeIndex + delta;
        this.activeIndex = Math.min(n - 1, Math.max(0, next));
        this._scrollPending = true;
    }

    // ---------- event handlers ----------
    handleTriggerClick() {
        if (this.disabled) {
            return;
        }
        if (this.isOpen) {
            this.closeList();
        } else {
            this.openList();
        }
    }

    handleOptionClick(event) {
        this.selectIndex(Number(event.currentTarget.dataset.index));
    }

    handleOptionHover(event) {
        this.activeIndex = Number(event.currentTarget.dataset.index);
    }

    // Keeps focus on the trigger while the user clicks inside the list,
    // so the blur handler below doesn't close the list before the click lands.
    handleListMouseDown(event) {
        event.preventDefault();
    }

    handleBlur() {
        if (this.isOpen) {
            this.closeList();
        }
    }

    handleKeyDown(event) {
        if (this.disabled) {
            return;
        }
        switch (event.key) {
            case 'ArrowDown':
                event.preventDefault();
                if (this.isOpen) {
                    this.moveActive(1);
                } else {
                    this.openList();
                }
                break;
            case 'ArrowUp':
                event.preventDefault();
                if (this.isOpen) {
                    this.moveActive(-1);
                } else {
                    this.openList();
                }
                break;
            case 'Home':
                if (this.isOpen) {
                    event.preventDefault();
                    this.activeIndex = 0;
                    this._scrollPending = true;
                }
                break;
            case 'End':
                if (this.isOpen) {
                    event.preventDefault();
                    this.activeIndex = this.list.length - 1;
                    this._scrollPending = true;
                }
                break;
            case 'Enter':
            case ' ':
                event.preventDefault();
                if (!this.isOpen) {
                    this.openList();
                } else if (this.activeIndex >= 0) {
                    this.selectIndex(this.activeIndex);
                } else {
                    this.closeList();
                }
                break;
            case 'Escape':
                if (this.isOpen) {
                    event.preventDefault();
                    this.closeList();
                }
                break;
            case 'Tab':
                this.closeList();
                break;
            default:
                if (event.key.length === 1 && !event.ctrlKey && !event.metaKey && !event.altKey) {
                    this.handleTypeahead(event.key);
                }
        }
    }

    // Typing letters jumps to the first matching option (handy for long lists).
    handleTypeahead(char) {
        clearTimeout(this._typedTimer);
        this._typed += char.toLowerCase();
        this._typedTimer = setTimeout(() => {
            this._typed = '';
        }, TYPEAHEAD_RESET_MS);

        const found = this.list.findIndex((o) => String(o.label).toLowerCase().startsWith(this._typed));
        if (found >= 0) {
            if (!this.isOpen) {
                this.openList();
            }
            this.activeIndex = found;
            this._scrollPending = true;
        }
    }
}