public class ChinabankResultPayloadBuilder {

    /**
     * Builds JSON payload for GET RESULT API
     * @param clientId – provided by Chinabank in metadata
     * @param requesterRef – unique per API call
     * @param applicationRef – comes from push API response & stored on Contact
     */
    public static String buildResultPayload(
        String clientId,
        String requesterRef,
        String applicationRef
    ) {
        Map<String, Object> root = new Map<String, Object>();

        Map<String, Object> header = new Map<String, Object>();
        Map<String, Object> requestContext = new Map<String, Object>();

        requestContext.put('clientId', clientId);
        requestContext.put('requesterReferenceNumber', requesterRef);
        requestContext.put('applicationReferenceNo', applicationRef);

        header.put('RequestHeader', new Map<String, Object>{
            'requestContext' => requestContext
        });

        return JSON.serialize(header);
    }
}