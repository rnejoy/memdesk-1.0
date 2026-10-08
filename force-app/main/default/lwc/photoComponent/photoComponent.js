import { LightningElement, api } from 'lwc';
import MIMI_PHOTO from '@salesforce/resourceUrl/mimi';
import getPhoto from '@salesforce/apex/MemdeskPhotoController.getPhoto';
import savePhoto from '@salesforce/apex/MemdeskPhotoController.savePhoto';

const MAX_SIDE = 640;                       // longest side after resizing, in pixels
const MAX_FILE_BYTES = 10 * 1024 * 1024;    // 10 MB before resizing
const DEFAULT_CAMERA = [{ value: '', label: 'Integrated Camera', selected: true }];

export default class PhotoComponent extends LightningElement {
    @api recordKey = '';          // Contact Id / Membership ID / Lead Id
    @api recordType = 'Member';   // 'Member' or 'Lead'
    @api initialPhotoUrl = '';    // photo from the record's URL field

    savedPhotoUrl = '';
    previewUrl = '';
    fallbackOnly = false;
    isSaving = false;
    statusMessage = '';
    statusIsError = false;
    statusTimer;

    // Camera modal
    isModalOpen = false;
    focusModal = false;
    startCameraOnOpen = false;
    cameraOn = false;
    isStarting = false;
    cameraMessage = '';
    modalError = '';
    capturedUrl = '';
    cameraOptions = DEFAULT_CAMERA;
    selectedDeviceId = '';
    stream = null;

    connectedCallback() {
        this.loadSavedPhoto();
    }

    disconnectedCallback() {
        clearTimeout(this.statusTimer);
        this.stopCamera();
    }

    renderedCallback() {
        if (this.isModalOpen) {
            if (this.focusModal) {
                const card = this.template.querySelector('.modal-card');
                if (card) {
                    card.focus();
                    this.focusModal = false;
                }
            }
            if (this.startCameraOnOpen) {
                this.startCameraOnOpen = false;
                this.startCamera('');
            }
        }
    }

    async loadSavedPhoto() {
        if (!this.recordKey) {
            return;
        }
        try {
            const url = await getPhoto({ recordKey: this.recordKey, recordType: this.recordType });
            if (url) {
                this.savedPhotoUrl = url;
                this.fallbackOnly = false;
            }
        } catch (error) {
            console.warn('Could not load the saved photo:', error);
        }
    }

    // Saved photo -> photo from the record -> default image
    get displayUrl() {
        if (this.fallbackOnly) {
            return MIMI_PHOTO;
        }
        return this.previewUrl || this.savedPhotoUrl || this.initialPhotoUrl || MIMI_PHOTO;
    }

    handleImageError() {
        this.fallbackOnly = true;
    }

    // ---------- Upload from a file ----------
    async handleFileSelected(event) {
        const input = event.target;
        const file = input.files && input.files[0];
        if (!file) {
            return;
        }

        if (!file.type || !file.type.startsWith('image/')) {
            this.showStatus('Please choose an image file.', true);
            input.value = '';
            return;
        }
        if (file.size > MAX_FILE_BYTES) {
            this.showStatus('That image is too large (10 MB max).', true);
            input.value = '';
            return;
        }
        if (!this.recordKey) {
            this.showStatus('No record is selected.', true);
            input.value = '';
            return;
        }

        this.isSaving = true;
        this.statusMessage = '';

        try {
            const dataUrl = await this.resizeImage(file);
            this.previewUrl = dataUrl;
            this.fallbackOnly = false;

            await savePhoto({ recordKey: this.recordKey, recordType: this.recordType, dataUrl });

            this.savedPhotoUrl = dataUrl;
            this.previewUrl = '';
            this.showStatus('Photo updated.', false);
            this.dispatchEvent(new CustomEvent('photochange', { detail: { photoUrl: dataUrl } }));
        } catch (error) {
            this.previewUrl = '';
            this.showStatus(
                error?.body?.message || error?.message || 'Could not save the photo. Please try again.',
                true
            );
        } finally {
            this.isSaving = false;
            input.value = '';
        }
    }

    // Shrinks the photo and converts it to JPEG so it saves quickly
    resizeImage(file) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onerror = () => reject(new Error('Could not read that file.'));
            reader.onload = () => {
                const img = new Image();
                img.onerror = () => reject(new Error('That image could not be opened.'));
                img.onload = () => {
                    const scale = Math.min(1, MAX_SIDE / Math.max(img.width, img.height));
                    const width = Math.max(1, Math.round(img.width * scale));
                    const height = Math.max(1, Math.round(img.height * scale));

                    const canvas = document.createElement('canvas');
                    canvas.width = width;
                    canvas.height = height;
                    const ctx = canvas.getContext('2d');
                    ctx.fillStyle = '#ffffff';
                    ctx.fillRect(0, 0, width, height);
                    ctx.drawImage(img, 0, 0, width, height);

                    resolve(canvas.toDataURL('image/jpeg', 0.85));
                };
                img.src = reader.result;
            };
            reader.readAsDataURL(file);
        });
    }

    // ---------- Take a Picture modal ----------
    openCameraModal() {
        if (!this.recordKey) {
            this.showStatus('No record is selected.', true);
            return;
        }
        this.capturedUrl = '';
        this.modalError = '';
        this.cameraMessage = '';
        this.cameraOptions = DEFAULT_CAMERA;
        this.selectedDeviceId = '';
        this.isModalOpen = true;
        this.focusModal = true;
        this.startCameraOnOpen = true;
    }

    closeCameraModal() {
        this.stopCamera();
        this.isModalOpen = false;
        this.capturedUrl = '';
        this.modalError = '';
        this.cameraMessage = '';
    }

    handleBackdropClick(event) {
        if (event.target === event.currentTarget) {
            this.closeCameraModal();
        }
    }

    handleModalKeydown(event) {
        if (event.key === 'Escape') {
            this.closeCameraModal();
        }
    }

    async startCamera(deviceId) {
        this.stopCamera();
        this.modalError = '';
        this.isStarting = true;
        this.cameraMessage = 'Starting camera...';

        try {
            if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
                throw new Error('unsupported');
            }
            const constraints = { audio: false, video: deviceId ? { deviceId: { exact: deviceId } } : true };
            const stream = await navigator.mediaDevices.getUserMedia(constraints);

            // The window may have been closed while the browser asked for permission
            if (!this.isModalOpen) {
                stream.getTracks().forEach((track) => track.stop());
                return;
            }

            this.stream = stream;
            const video = this.template.querySelector('.camera-video');
            video.muted = true;
            video.playsInline = true;
            video.srcObject = stream;
            await video.play();

            this.cameraOn = true;
            this.cameraMessage = '';
            await this.loadCameras();
        } catch (error) {
            this.stopCamera();
            this.cameraMessage = this.cameraErrorText(error);
        } finally {
            this.isStarting = false;
        }
    }

    stopCamera() {
        if (this.stream) {
            this.stream.getTracks().forEach((track) => track.stop());
            this.stream = null;
        }
        const video = this.template.querySelector('.camera-video');
        if (video) {
            video.srcObject = null;
        }
        this.cameraOn = false;
    }

    async loadCameras() {
        try {
            const devices = await navigator.mediaDevices.enumerateDevices();
            const cameras = devices.filter((device) => device.kind === 'videoinput');
            const track = this.stream && this.stream.getVideoTracks()[0];
            const activeId = track && track.getSettings ? track.getSettings().deviceId : '';

            this.selectedDeviceId = activeId || (cameras[0] ? cameras[0].deviceId : '');
            if (cameras.length) {
                this.cameraOptions = cameras.map((device, index) => ({
                    value: device.deviceId,
                    label: device.label || `Camera ${index + 1}`,
                    selected: device.deviceId === this.selectedDeviceId
                }));
            }
        } catch (error) {
            // keep the default list
        }
    }

    handleCameraChange(event) {
        this.selectedDeviceId = event.target.value;
        this.cameraOptions = this.cameraOptions.map((option) => ({
            ...option,
            selected: option.value === this.selectedDeviceId
        }));
        this.startCamera(this.selectedDeviceId);
    }

    cameraErrorText(error) {
        const name = error && error.name;
        if (name === 'NotAllowedError' || name === 'SecurityError') {
            return 'Camera access was blocked. Allow the camera in your browser, then reopen this window.';
        }
        if (name === 'NotFoundError' || name === 'OverconstrainedError') {
            return 'No camera was found on this computer.';
        }
        if (name === 'NotReadableError') {
            return 'The camera is being used by another app.';
        }
        if (error && error.message === 'unsupported') {
            return 'The camera is not available in this browser.';
        }
        return 'The camera could not be started.';
    }

    // First click captures. After capturing, the same button becomes "Retake".
    handleCapture() {
        if (!this.cameraOn) {
            this.capturedUrl = '';
            this.startCamera(this.selectedDeviceId);
            return;
        }

        const video = this.template.querySelector('.camera-video');
        if (!video || !video.videoWidth) {
            return;
        }

        // Center square, so the saved picture matches the preview
        const side = Math.min(video.videoWidth, video.videoHeight);
        const sx = (video.videoWidth - side) / 2;
        const sy = (video.videoHeight - side) / 2;
        const size = Math.min(side, MAX_SIDE);

        const canvas = document.createElement('canvas');
        canvas.width = size;
        canvas.height = size;
        canvas.getContext('2d').drawImage(video, sx, sy, side, side, 0, 0, size, size);

        this.capturedUrl = canvas.toDataURL('image/jpeg', 0.85);
        this.stopCamera();
    }

    async handleUploadCaptured() {
        if (!this.capturedUrl || this.isSaving) {
            return;
        }
        this.isSaving = true;
        this.modalError = '';
        const dataUrl = this.capturedUrl;

        try {
            await savePhoto({ recordKey: this.recordKey, recordType: this.recordType, dataUrl });
            this.savedPhotoUrl = dataUrl;
            this.fallbackOnly = false;
            this.closeCameraModal();
            this.showStatus('Photo updated.', false);
            this.dispatchEvent(new CustomEvent('photochange', { detail: { photoUrl: dataUrl } }));
        } catch (error) {
            this.modalError = error?.body?.message || 'Could not save the photo. Please try again.';
        } finally {
            this.isSaving = false;
        }
    }

    get videoClass() {
        return this.cameraOn ? 'camera-video' : 'camera-video is-hidden';
    }

    get captureLabel() {
        return this.capturedUrl && !this.cameraOn ? 'Retake' : 'Capture';
    }

    get captureDisabled() {
        return this.isSaving || this.isStarting || (!this.cameraOn && !this.capturedUrl);
    }

    get uploadLabel() {
        return this.isSaving ? 'Uploading...' : 'Upload';
    }

    get uploadDisabled() {
        return !this.capturedUrl || this.isSaving;
    }

    // ---------- Messages and events ----------
    showStatus(message, isError) {
        this.statusMessage = message;
        this.statusIsError = isError;
        clearTimeout(this.statusTimer);
        this.statusTimer = setTimeout(() => {
            this.statusMessage = '';
        }, 4000);
    }

    get statusClass() {
        return this.statusIsError ? 'status is-error' : 'status is-ok';
    }

    handleSendMessage() {
        this.dispatchEvent(new CustomEvent('sendmessage', { detail: { recordKey: this.recordKey } }));
    }
}