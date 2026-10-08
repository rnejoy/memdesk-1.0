import { LightningElement } from 'lwc';

const MAX_BYTES = 5 * 1024 * 1024;
const ALLOWED_TYPES = ['image/png', 'image/jpeg', 'image/webp'];

const REACTIONS = [
    { value: 'frustrated', label: 'Frustrated', emoji: '😠', tone: 'tone1' },
    { value: 'unhappy', label: 'Unhappy', emoji: '🙁', tone: 'tone2' },
    { value: 'neutral', label: 'Neutral', emoji: '😐', tone: 'tone3' },
    { value: 'happy', label: 'Happy', emoji: '🙂', tone: 'tone4' },
    { value: 'love', label: 'Love it', emoji: '😍', tone: 'tone5' }
];

const TOPICS = [
    'Fresh produce',
    'Checkout lanes',
    'Membership perks',
    'Bulk deals',
    'Store cleanliness',
    'Staff service'
];

export default class landersfeedbackForm extends LightningElement {
    // Sample data
    reaction = 'happy';
    selectedTopics = ['Fresh produce', 'Checkout lanes'];
    comment = 'The bulk snacks aisle was easy to find, but the checkout lines got long on Saturday afternoon.';
    fileName = '';
    fileError = '';
    submitted = false;

    get reactionItems() {
        return REACTIONS.map((r) => {
            const on = r.value === this.reaction;
            return {
                ...r,
                checked: String(on),
                cls: on ? 'reaction is-on' : 'reaction',
                faceCls: `face ${r.tone}`
            };
        });
    }

    get topicItems() {
        return TOPICS.map((name) => {
            const on = this.selectedTopics.includes(name);
            return {
                name,
                pressed: String(on),
                cls: on ? 'chip is-on' : 'chip',
                mark: on ? '✓' : '+'
            };
        });
    }

    get attachLabel() {
        return this.fileName || 'Attach a photo';
    }

    get selectedReactionLabel() {
        const found = REACTIONS.find((r) => r.value === this.reaction);
        return found ? found.label : 'no reaction';
    }

    get topicCount() {
        return this.selectedTopics.length;
    }

    get topicWord() {
        return this.selectedTopics.length === 1 ? 'topic' : 'topics';
    }

    handleReaction(event) {
        this.reaction = event.currentTarget.dataset.value;
    }

    handleTopic(event) {
        const name = event.currentTarget.dataset.name;
        this.selectedTopics = this.selectedTopics.includes(name)
            ? this.selectedTopics.filter((t) => t !== name)
            : [...this.selectedTopics, name];
    }

    handleComment(event) {
        this.comment = event.target.value;
    }

    handleAttach() {
        this.template.querySelector('input[type="file"]').click();
    }

    handleFile(event) {
        const file = event.target.files[0];
        this.fileError = '';
        this.fileName = '';
        if (!file) {
            return;
        }
        if (!ALLOWED_TYPES.includes(file.type)) {
            this.fileError = 'Choose a PNG, JPG or WebP image.';
            return;
        }
        if (file.size > MAX_BYTES) {
            this.fileError = 'That image is over 5 MB. Choose a smaller one.';
            return;
        }
        this.fileName = file.name;
    }

    handleSend() {
        this.submitted = true;
    }

    handleReset() {
        this.reaction = '';
        this.selectedTopics = [];
        this.comment = '';
        this.fileName = '';
        this.fileError = '';
        this.submitted = false;
    }
}