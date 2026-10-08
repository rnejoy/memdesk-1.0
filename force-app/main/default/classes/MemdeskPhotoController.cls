public without sharing class MemdeskPhotoController {

    private static final String PHOTO_TITLE = 'Member Photo';
    private static final Integer MAX_BYTES = 1500000;    // after the browser resizes it

    // Returns the saved photo as a data URL, or null when there isn't one
    @AuraEnabled
    public static String getPhoto(String recordKey, String recordType) {
        Id parentId = resolveParentId(recordKey, recordType);
        if (parentId == null) {
            return null;
        }

        Id documentId = findPhotoDocumentId(parentId);
        if (documentId == null) {
            return null;
        }

        List<ContentVersion> versions = [
            SELECT VersionData
            FROM ContentVersion
            WHERE ContentDocumentId = :documentId
            AND IsLatest = true
            LIMIT 1
        ];

        if (versions.isEmpty()) {
            return null;
        }
        return 'data:image/jpeg;base64,' + EncodingUtil.base64Encode(versions[0].VersionData);
    }

    // Saves the photo. If the record already has one, it becomes a new version of the same file.
    @AuraEnabled
    public static Boolean savePhoto(String recordKey, String recordType, String dataUrl) {
        Id parentId = resolveParentId(recordKey, recordType);
        if (parentId == null) {
            throw buildError('That record could not be found.');
        }
        if (String.isBlank(dataUrl) || !dataUrl.startsWith('data:image/') || !dataUrl.contains(',')) {
            throw buildError('That is not a valid image.');
        }

        Blob body = EncodingUtil.base64Decode(dataUrl.substringAfter(','));
        if (body.size() > MAX_BYTES) {
            throw buildError('That image is too large. Please choose a smaller one.');
        }

        ContentVersion version = new ContentVersion(
            Title = PHOTO_TITLE,
            PathOnClient = 'member-photo.jpg',
            VersionData = body
        );

        Id existingDocumentId = findPhotoDocumentId(parentId);
        if (existingDocumentId == null) {
            version.FirstPublishLocationId = parentId;
        } else {
            version.ContentDocumentId = existingDocumentId;
        }
        insert version;
        return true;
    }

    private static Id findPhotoDocumentId(Id parentId) {
        for (ContentDocumentLink link : [
            SELECT ContentDocumentId, ContentDocument.Title
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :parentId
        ]) {
            if (link.ContentDocument.Title == PHOTO_TITLE) {
                return link.ContentDocumentId;
            }
        }
        return null;
    }

    // Accepts a Membership ID or a Contact Id for members, and a Lead Id for leads
    private static Id resolveParentId(String recordKey, String recordType) {
        if (String.isBlank(recordKey)) {
            return null;
        }
        String key = recordKey.trim();

        if (recordType == 'Lead') {
            return Pattern.matches('00Q[a-zA-Z0-9]{12}([a-zA-Z0-9]{3})?', key) ? (Id) key : null;
        }
        if (Pattern.matches('003[a-zA-Z0-9]{12}([a-zA-Z0-9]{3})?', key)) {
            return (Id) key;
        }
        List<Contact> rows = [SELECT Id FROM Contact WHERE Membership_ID__c = :key LIMIT 1];
        return rows.isEmpty() ? null : rows[0].Id;
    }

    private static AuraHandledException buildError(String msg) {
        AuraHandledException ex = new AuraHandledException(msg);
        ex.setMessage(msg);
        return ex;
    }
}