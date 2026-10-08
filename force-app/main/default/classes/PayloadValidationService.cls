@RestResource(urlMapping='/validatePayload/*')
global with sharing class PayloadValidationService {

    @HttpPost
    global static void validatePayload(String membershipId, String lastName, String dobString) {
        try {
            System.debug('Received payload: membershipId=' + membershipId + ', lastName=' + lastName + ', dobString=' + dobString);

           
            if (!isValidDate(dobString)) {
                setErrorResponse(400, '405', 'Invalid date format');
                return;
            }

            
            if (membershipId == null || !isValidMembershipIdFormat(membershipId)) {
                setErrorResponse(400, '403', 'Invalid membership ID');
                return;
            }

            String normalizedLastName = normalizeLastName(lastName);
            System.debug('Normalized lastName: ' + normalizedLastName);

          
            Date dob = Date.valueOf(dobString);
            System.debug('Converted dob: ' + dob);

          
            List<Contact> matchingContacts = [
                SELECT Id, LastName, Birthdate__c, Membership_id__c, Maya_Validated__c 
                FROM Contact 
                WHERE Membership_id__c = :membershipId AND 	Landers_Credit_Card_Applied__c = TRUE
                LIMIT 1
            ];

         
            if (matchingContacts.isEmpty()) {
                setErrorResponse(404, '404', 'Record not found');
                return;
            }

            Contact matchedContact = matchingContacts[0];
            Boolean lastNameMatch = normalizeLastName(matchedContact.LastName) == normalizedLastName;
            Boolean dobMatch = matchedContact.Birthdate__c == dob;

            
            if (!lastNameMatch && !dobMatch) {
                setErrorResponse(400, '402', 'Incorrect last name and date of birth');
                return;
            } else if (!lastNameMatch) {
                setErrorResponse(400, '401', 'Incorrect last name');
                return;
            } else if (!dobMatch) {
                setErrorResponse(400, '406', 'Incorrect date of birth');
                return;
            }

            
            matchedContact.Maya_Validated__c = true;
            update matchedContact; 

            
            sendSuccessResponse();
        } catch (QueryException e) {
            
            System.debug('QueryException: ' + e.getMessage());
            setErrorResponse(404, '404', 'Record not found');
        } catch (Exception e) {
           
            System.debug('Exception: ' + e.getMessage());
            setErrorResponse(500, '500', 'Internal server error');
        }
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

  private static String normalizeLastName(String input) {
    if (input == null) {
        return '';
    }
      
    
    String normalized = input.toLowerCase().trim();
      
    normalized = normalized.replaceAll('ñ', 'n').replaceAll('Ñ', 'n');

      
   
       normalized = normalized.replaceAll('[^a-z\'@ ]', ''); 
     
        normalized = normalized.replaceAll('\\s+', ''); 
      System.debug('After removing special characters: ' + normalized);
        normalized = normalized.replaceAll('\'', ''); 
      
        return normalized;
      
       
}

    private static Boolean isValidDate(String dateString) {
        try {
            Date.valueOf(dateString);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    private static Boolean isValidMembershipIdFormat(String membershipId) {
        return membershipId != null && membershipId.length() == 14 && membershipId.isNumeric();
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