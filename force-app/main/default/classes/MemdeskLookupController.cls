public without sharing class MemdeskLookupController {

    public class Option {
        @AuraEnabled public String value;
        @AuraEnabled public String label;
        public Option(String value, String label) {
            this.value = value;
            this.label = label;
        }
    }

    private static final Set<String> PICKLIST_FIELDS = new Set<String>{ 'Nationality__c', 'Marital_Status__c', 'Gender__c' };

    @AuraEnabled(cacheable=true)
    public static List<Option> getProvinces() {
        return loadLevel('Province', null);
    }

    @AuraEnabled(cacheable=true)
    public static List<Option> getCities(String provinceCode) {
        return loadLevel('City', provinceCode);
    }

    @AuraEnabled(cacheable=true)
    public static List<Option> getBarangays(String cityCode) {
        return loadLevel('Barangay', cityCode);
    }

    @AuraEnabled(cacheable=true)
    public static List<Option> getPicklist(String fieldApiName) {
        List<Option> result = new List<Option>();
        if (!PICKLIST_FIELDS.contains(fieldApiName)) {
            return result;
        }
        Schema.SObjectField field = Schema.SObjectType.Contact.fields.getMap().get(fieldApiName);
        if (field == null) {
            return result;
        }
        for (Schema.PicklistEntry entry : field.getDescribe().getPicklistValues()) {
            if (entry.isActive()) {
                result.add(new Option(entry.getValue(), entry.getLabel()));
            }
        }
        return result;
    }

    // Reads Address_Location__c. Uses the sample list until that object exists and has provinces.
    private static List<Option> loadLevel(String level, String parentCode) {
        if (parentCode != null && parentCode.startsWith('S-')) {
            return sampleFor(level, parentCode);
        }
        if (!tableAvailable()) {
            return sampleFor(level, parentCode);
        }

        List<Option> result = new List<Option>();
        String soql = 'SELECT Name, Code__c FROM Address_Location__c WHERE Level__c = :level';
        if (parentCode != null) {
            soql += ' AND Parent_Code__c = :parentCode';
        }
        soql += ' ORDER BY Name LIMIT 2000';

        for (SObject row : Database.query(soql)) {
            result.add(new Option(String.valueOf(row.get('Code__c')), String.valueOf(row.get('Name'))));
        }

        if (level == 'Province' && result.isEmpty()) {
            return sampleFor(level, parentCode);
        }
        return result;
    }

    private static Boolean tableAvailable() {
        try {
            Schema.describeSObjects(new List<String>{ 'Address_Location__c' });
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    // SAMPLE DATA ONLY: codes start with "S-" so they are never saved to the member record
    private static List<Option> sampleFor(String level, String parentCode) {
        List<Option> result = new List<Option>();
        if (level == 'Province') {
            result.add(new Option('S-P1', 'METRO MANILA-MANILA'));
            result.add(new Option('S-P2', 'METRO MANILA-QUEZON CITY'));
            result.add(new Option('S-P3', 'RIZAL'));
        } else if (level == 'City') {
            if (parentCode == 'S-P1') {
                result.add(new Option('S-C1', 'MANILA CITY'));
            } else if (parentCode == 'S-P2') {
                result.add(new Option('S-C2', 'QUEZON CITY'));
            } else if (parentCode == 'S-P3') {
                result.add(new Option('S-C3', 'ANTIPOLO CITY'));
                result.add(new Option('S-C4', 'CAINTA'));
            }
        } else if (level == 'Barangay') {
            if (parentCode == 'S-C1') {
                result.add(new Option('S-B1', 'ERMITA'));
                result.add(new Option('S-B2', 'SAMPALOC'));
            } else if (parentCode == 'S-C2') {
                result.add(new Option('S-B3', 'ANONAS'));
                result.add(new Option('S-B4', 'BAGUMBAYAN'));
            } else if (parentCode == 'S-C3') {
                result.add(new Option('S-B5', 'MAYAMOT'));
                result.add(new Option('S-B6', 'SAN ROQUE'));
            } else if (parentCode == 'S-C4') {
                result.add(new Option('S-B7', 'SAN ANDRES'));
                result.add(new Option('S-B8', 'STO. DOMINGO'));
            }
        }
        return result;
    }
}