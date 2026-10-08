@isTest
public class MultiselectController_Test {
    @isTest public static void MultiselectController_CodeCoverage(){
        MultiselectController msc = new MultiselectController();
        SelectOption[] leftOption = new SelectOption[]{null,null};
        Test.startTest();
        msc.leftOptions = leftOption;
        msc.rightOptions = leftOption;
        msc.leftOptionsHidden = 'Hidden & Option';
        msc.rightOptionsHidden = 'Hidden & Option';
        Test.stopTest();
    }
}