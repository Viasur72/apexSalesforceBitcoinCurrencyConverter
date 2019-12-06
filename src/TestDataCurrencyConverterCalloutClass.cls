/*********************************************************************************************************
    Apex Class Name : TestDataCurrencyConverterCalloutClass
    Created By  : Carlos Naranjo (carlos.naranjo@ccloudonline.nl)
    Description : Test Data Factory class for CurrencyConverterCalloutClassTest
*********************************************************************************************************/
@IsTest
public class TestDataCurrencyConverterCalloutClass {
    // Rate__Code__c records already inserted
    public static List<Rate_Code__c> TestRateCodeRecordsInserted() {
        // Because we are not receiving a big amount of records
        // we inserted a small number of Rate Code records for our test
        List<Rate_Code__c> rcList = new List<Rate_Code__c>();

        Rate_Code__c afghan = new Rate_Code__c(Name = 'Afghan Afghani',
                Name__c = 'Afghan Afghani',
                Rate__c = 494.79893,
                Code__c = 'AFN',
                Currency__c = 'Afghan Afghani (AFN)');
        rcList.add(afghan);

        Rate_Code__c bitcoin = new Rate_Code__c(Name = 'Bitcoin',
                Name__c = 'Bitcoin',
                Rate__c = 1,
                Code__c = 'BTC',
                Currency__c = 'Bitcoin (BTC)');
        rcList.add(bitcoin);

        Rate_Code__c usDollar = new Rate_Code__c(Name = 'US Dollar',
                Name__c = 'US Dollar',
                Rate__c = 6.528,
                Code__c = 'USD',
                Currency__c = 'US Dollar (USD)');
        rcList.add(usDollar);

        Rate_Code__c dong = new Rate_Code__c(Name = 'Vietnamese Dong',
                Name__c = 'Vietnamese Dong',
                Rate__c = 151.737028,
                Code__c = 'VND',
                Currency__c = 'Vietnamese Dong (VND)');
        rcList.add(dong);


        insert rcList;

        return rcList;
    }
}