public class chinabankReferenceUtil {

    public static String generateReferenceNumber() {

        // Format today's date as yyyyMMdd using Datetime NOT Date
        String todayStr = Datetime.now().format('yyyyMMdd');

        // Query safely using a list (NO more List-Has-No-Rows error)
        List<API_Integration_Logs__c> latestList = [
            SELECT Requester_Reference_Number__c
            FROM API_Integration_Logs__c
            WHERE Requester_Reference_Number__c LIKE :('LEX' + todayStr + '%')
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        Long nextSeq = 1;

        // If a record exists for today, extract last 10 digits
        if (!latestList.isEmpty() && latestList[0].Requester_Reference_Number__c != null) {

            String full = latestList[0].Requester_Reference_Number__c;

            // Safety check to avoid substring errors
            if (full.length() >= 10) {
                String seqPart = full.substring(full.length() - 10);
                nextSeq = Long.valueOf(seqPart) + 1;
            }
        }

        // Pad sequence number to always be 10 digits
        String paddedSeq = String.valueOf(nextSeq).leftPad(10, '0');

        // Final reference number
        return 'LEX' + todayStr + paddedSeq;
    }
}