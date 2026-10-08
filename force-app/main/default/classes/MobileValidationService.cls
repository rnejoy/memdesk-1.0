@RestResource(urlMapping='/validateMobile/*')
global with sharing class MobileValidationService {

    @HttpPost
    global static void validateMobile(String MobilePhone) {
        try {
            System.debug('Received MobilePhone: ' + MobilePhone);

            
            if (String.isEmpty(MobilePhone) || !isValidMobileNumber(MobilePhone)) {
                setErrorResponse(400, '400', 'Invalid mobile number format');
                return;
            }

            
            List<Contact> matchingContacts = [
                SELECT Id, MobilePhone 
                FROM Contact 
                WHERE MobilePhone = :MobilePhone 
                LIMIT 1
            ];

            
            if (matchingContacts.isEmpty()) {
                setErrorResponse(404, '404', 'Mobile number not found');
                return;
            }

            
            sendSuccessResponse();
        } catch (QueryException e) {
            System.debug('QueryException: ' + e.getMessage());
            setErrorResponse(500, '500', 'Internal server error');
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
            setErrorResponse(500, '500', 'Internal server error');
        }
    }

    private static Boolean isValidMobileNumber(String MobilePhone) {
        return MobilePhone != null && MobilePhone.length() >= 10 && MobilePhone.length() <= 15 && MobilePhone.isNumeric();
    }

    private static void sendSuccessResponse() {
        RestResponse res = RestContext.response;
        res.statusCode = 200;
        res.addHeader('Content-Type', 'application/json');
        Map<String, Object> successResponse = new Map<String, Object>{
            'status' => 'Success'
        };
        res.responseBody = Blob.valueOf(JSON.serialize(successResponse));
    }

    private static void setErrorResponse(Integer statusCode, String errorCode, String errorDescription) {
        RestResponse res = RestContext.response;
        res.statusCode = statusCode;
        res.addHeader('Content-Type', 'application/json');
        Map<String, Object> errorResponse = new Map<String, Object>{
            'error' => new Map<String, Object>{
                'code' => errorCode,
                'description' => errorDescription
            }
        };
        res.responseBody = Blob.valueOf(JSON.serialize(errorResponse));
    }
}