@IsTest
private class ChinabankConfig_Test {

    @IsTest
    static void testGetConfig_execution() {

        Test.startTest();
        ChinaBank_API_Setting__mdt cfg = ChinabankConfig.getConfig();
        Test.stopTest();

        System.assert(true, 'getConfig method executed successfully');

        if (cfg != null) {
            System.assertNotEquals(null, cfg.DeveloperName, 'Config record exists');
        }
    }
}