public with sharing class MemdeskSearchController {

    public class SearchResultWrapper {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String membershipId { get; set; }
        @AuraEnabled public String firstName { get; set; }
        @AuraEnabled public String middleName { get; set; }
        @AuraEnabled public String lastName { get; set; }
        @AuraEnabled public String type { get; set; } // 'Member' or 'Lead'
    }

    @AuraEnabled(cacheable=true)
    public static List<SearchResultWrapper> searchRecords(
        String searchType, 
        String searchText, 
        String firstName, 
        String middleName, 
        String lastName
    ) {
        List<SearchResultWrapper> results = new List<SearchResultWrapper>();

        try {
            if (searchType == 'Lead') {
                results = searchLeads(searchText, firstName, middleName, lastName);
            } else if (searchType == 'Member') {
                results = searchMembers(searchText, firstName, middleName, lastName);
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error executing search: ' + e.getMessage());
        }

        return results;
    }

    private static List<SearchResultWrapper> searchLeads(String searchText, String firstName, String middleName, String lastName) {
        List<SearchResultWrapper> results = new List<SearchResultWrapper>();
        String query = 'SELECT Id, FirstName, MiddleName, LastName FROM Lead WHERE IsConverted = false';

        String lastNameLike = String.isNotBlank(lastName) ? '%' + String.escapeSingleQuotes(lastName.trim()) + '%' : null;
        String firstNameLike = String.isNotBlank(firstName) ? '%' + String.escapeSingleQuotes(firstName.trim()) + '%' : null;
        String middleNameLike = String.isNotBlank(middleName) ? '%' + String.escapeSingleQuotes(middleName.trim()) + '%' : null;

        if (String.isNotBlank(lastName)) {
            query += ' AND LastName LIKE :lastNameLike';
            if (String.isNotBlank(firstName)) query += ' AND FirstName LIKE :firstNameLike';
            if (String.isNotBlank(middleName)) query += ' AND MiddleName LIKE :middleNameLike';
        } else if (String.isNotBlank(searchText)) {
            List<String> terms = searchText.trim().split('\\s+');
            for (Integer i = 0; i < terms.size(); i++) {
                String term = '%' + String.escapeSingleQuotes(terms[i]) + '%';
                query += ' AND (FirstName LIKE \'' + term + '\' OR MiddleName LIKE \'' + term + '\' OR LastName LIKE \'' + term + '\')';
            }
        }

        query += ' ORDER BY LastName, FirstName LIMIT 100';

        for (Lead l : Database.query(query)) {
            SearchResultWrapper wrapper = new SearchResultWrapper();
            wrapper.id = l.Id;
            wrapper.membershipId = l.Id; // Fallback to Id for leads
            wrapper.firstName = l.FirstName != null ? l.FirstName : '';
            wrapper.middleName = l.MiddleName != null ? l.MiddleName : '';
            wrapper.lastName = l.LastName != null ? l.LastName : '';
            wrapper.type = 'Lead';
            results.add(wrapper);
        }

        return results;
    }

    private static List<SearchResultWrapper> searchMembers(String searchText, String firstName, String middleName, String lastName) {
        List<SearchResultWrapper> results = new List<SearchResultWrapper>();
        String query = 'SELECT Id, Membership_ID__c, FirstName, MiddleName, LastName FROM Contact WHERE Id != null';

        String lastNameLike = String.isNotBlank(lastName) ? '%' + String.escapeSingleQuotes(lastName.trim()) + '%' : null;
        String firstNameLike = String.isNotBlank(firstName) ? '%' + String.escapeSingleQuotes(firstName.trim()) + '%' : null;
        String middleNameLike = String.isNotBlank(middleName) ? '%' + String.escapeSingleQuotes(middleName.trim()) + '%' : null;

        if (String.isNotBlank(lastName)) {
            query += ' AND LastName LIKE :lastNameLike';
            if (String.isNotBlank(firstName)) query += ' AND FirstName LIKE :firstNameLike';
            if (String.isNotBlank(middleName)) query += ' AND MiddleName LIKE :middleNameLike';
        } else if (String.isNotBlank(searchText)) {
            List<String> terms = searchText.trim().split('\\s+');
            for (Integer i = 0; i < terms.size(); i++) {
                String term = '%' + String.escapeSingleQuotes(terms[i]) + '%';
                query += ' AND (FirstName LIKE \'' + term + '\' OR MiddleName LIKE \'' + term + '\' OR LastName LIKE \'' + term + '\' OR Membership_ID__c LIKE \'' + term + '\')';
            }
        }

        query += ' ORDER BY LastName, FirstName LIMIT 100';

        for (Contact c : Database.query(query)) {
            SearchResultWrapper wrapper = new SearchResultWrapper();
            wrapper.id = c.Id;
            wrapper.membershipId = c.Membership_ID__c != null ? c.Membership_ID__c : c.Id;
            wrapper.firstName = c.FirstName != null ? c.FirstName : '';
            wrapper.middleName = c.MiddleName != null ? c.MiddleName : '';
            wrapper.lastName = c.LastName != null ? c.LastName : '';
            wrapper.type = 'Member';
            results.add(wrapper);
        }

        return results;
    }

    @AuraEnabled
    public static SearchResultWrapper getMemberByBarcode(String barcode) {
        if (String.isBlank(barcode)) {
            return null;
        }

        String cleanCode = String.escapeSingleQuotes(barcode.trim());
        
        List<Contact> members = [
            SELECT Id, Membership_ID__c, FirstName, MiddleName, LastName 
            FROM Contact 
            WHERE Membership_ID__c = :cleanCode OR Id = :cleanCode 
            LIMIT 1
        ];

        if (!members.isEmpty()) {
            Contact c = members[0];
            SearchResultWrapper wrapper = new SearchResultWrapper();
            wrapper.id = c.Id;
            wrapper.membershipId = c.Membership_ID__c != null ? c.Membership_ID__c : c.Id;
            wrapper.firstName = c.FirstName != null ? c.FirstName : '';
            wrapper.middleName = c.MiddleName != null ? c.MiddleName : '';
            wrapper.lastName = c.LastName != null ? c.LastName : '';
            wrapper.type = 'Member';
            return wrapper;
        }

        return null;
    }
}