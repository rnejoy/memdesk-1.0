@isTest
public class Test_EmailWeb2Service {
	@isTest 
    public static void EmailWeb2Service_CodeCoverage(){
        Test.startTest();
        EmailWeb2Service.sendEmail('ST', 'test.email@test.com', 'mrecord');
        EmailWeb2Service.sendEmail('MT', 'test.email@test.com', 'mrecord');
        EmailWeb2Service.sendEmail('not MT/ST', 'test.email@test.com', 'mrecord');
        Test.stopTest();
    }
}