/*********************************************************************************************************
    Apex Class Name : CurrencyConverterCalloutClassTest
    Created By  : Carlos Naranjo (carlos.naranjo@ccloudonline.nl)
    Description : Test class for extension class ConverterSupportClass and CurrencyConverter.vf page

    Methods: 
    * For HTTP calls:                              runTestCalloutWithStaticResources(), 
    * Negative update record done on this method:  runTestCalloutToUpdateAndInsertNewCodes()
    * 
    * Bitcoin vs No Bitcoin executions:      runTestBtcVsNoBtc()
    * No Bitcoin vs No Bitcoin executions:   runTestNoBtcVsNoBtc()
    * Both currency selections equal values: runTestBothCurrenciesEquals()
    * No Bitcoin vs Bitcoin executions:      runTestNoBtcVsBtc()
    * Both currency selections equal zero:   runTestOnEntryValuesZeroInput
    * Testing with a different user:         runTestWithOtherUserProfile()
    * Negative input from JSON for insert:   runTestCalloutNegativeInsertJSON()
*********************************************************************************************************/
@IsTest
private class CurrencyConverterCalloutClassTest {

    // Testing HTTP Get call out
    @IsTest static void runTestCalloutWithStaticResources() {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('converterMockResponse1');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        ConverterSupportClass.init();
        Integer callouts = Limits.getCallouts();
        Test.stopTest();

        System.assertEquals(1, callouts, 'The method should make a callout');

    }

    /*
     * A HTTP Get method callout is done every time we access the vf page Currency Converter
     * On every call we check for new Codes and changes on Rates values for existing Rate_Code__c 
    */
    @IsTest static void runTestCalloutToUpdateAndInsertNewCodes() {
        List<Rate_Code__c> rcList = TestDataCurrencyConverterCalloutClass.TestRateCodeRecordsInserted();
        System.assertEquals(4, rcList.size());

        StaticResourceCalloutMock mock2 = new StaticResourceCalloutMock();

        // The converterMockResponse2 contains six new code records. Four are already saved in database
        mock2.setStaticResource('converterMockResponse2');
        mock2.setStatusCode(200);
        mock2.setHeader('Content-Type', 'application/json');

        Test.setMock(HttpCalloutMock.class, mock2);

        Test.startTest();
        ConverterSupportClass.init();

        List<Rate_Code__c> inSystemRateCodes = [SELECT Id FROM Rate_Code__c];
        System.debug(inSystemRateCodes.size());

        String responseBody = '[{"code":"BTC","name":"Bitcoin","rate":1},{"code":"VND","name":"Vietnamese Dong","rate":164.776528},{"code":"AFN","name":"Afghan Afghani","rate":496.79773},{"code":"BCH","name":"Bitcoin Cash","rate":12.763562},{"code":"USD","name":"US Dollar","rate":6531.37},{"code":"EUR","name":"Eurozone Euro","rate":5690.07}]';
        List<Codes> restCode = (List<Codes>) JSON.deserialize(responseBody, List<Codes>.class);
        System.debug(restCode.size());

        // We had four rate_Code__c records inserted in database, checking if we have six after second HTTP call
        System.assertEquals(6, restCode.size());
        System.debug(restCode);

        // Updating rate_Code__c record with negative input. Code__c is mandatory
        List<Rate_Code__c> rcListToUpdate = new List<Rate_Code__c>();
        Rate_Code__c rcToUpdate = rcList[3];
        System.debug('Rate Code code on rcList: ' + rcList[3].Code__c);

        rcToUpdate.Code__c = null;
        rcListToUpdate.add(rcToUpdate);

        System.debug('rcListToUpdate size: -------------->' + rcListToUpdate.size());

        try {
            if ((!rcListToUpdate.isEmpty()) && (rcListToUpdate.size() > 0)) {
                update rcListToUpdate;
            }

        } catch (DmlException e) {
            System.debug('The following exception has occurred when insert Rate Code records: ' + e.getMessage());
            System.assert(e.getMessage().contains('Required fields are missing'), 'Update did not fire');

        }

        Test.stopTest();

    }

    /*
    * A HTTP Get method callout is done every time we access the vf page Currency Converter
    * This method test negative inputs coming from the JSON response
   */
    @IsTest static void runTestCalloutNegativeInsertJSON() {
        List<Rate_Code__c> rcList = TestDataCurrencyConverterCalloutClass.TestRateCodeRecordsInserted();
        System.assertEquals(4, rcList.size());

        StaticResourceCalloutMock mock3 = new StaticResourceCalloutMock();

        // The converterMockResponse2 contains six new code records. Four are already saved in database
        mock3.setStaticResource('converterMockResponse2');
        mock3.setStatusCode(200);
        mock3.setHeader('Content-Type', 'application/json');

        Test.setMock(HttpCalloutMock.class, mock3);

        Test.startTest();
        ConverterSupportClass.init();

        List<Rate_Code__c> inSystemRateCodes = [SELECT Id FROM Rate_Code__c];
        System.debug(inSystemRateCodes.size());

        // Passing a JSON response with a code with no value. Code__c is a mandatory field
        // this should fire the catch error before inserting. 

        String responseBody = '[{"code":"","name":"New Zealand Dollar","rate":10159.894353}]';
        List<Codes> restCode = (List<Codes>) JSON.deserialize(responseBody, List<Codes>.class);
        System.debug(restCode.size());

        // We had four rate_Code__c records inserted in database, checking if it is the same after second HTTP call
        // with negative value entry on JOSN response
        System.assertEquals(1, restCode.size());
        System.debug(restCode);
        System.debug('This value should be four: (Negative Input Coming from JSON) :' + inSystemRateCodes.size());

        // Trying to insert a new Rate_Code__c record with missing Code__c
        List<Rate_Code__c> codesList = new List<Rate_Code__c>();
        Set<String> theIncomingKeysToInsert = new Set<String>();

        for (Integer i = 0; i < restCode.size(); i++) {
            theIncomingKeysToInsert.add(restCode[i].code);
        }

        for (Integer i = 0; i < restCode.size(); i++) {

            Rate_Code__c codeItem = new Rate_Code__c();

            codeItem = new Rate_Code__c(Name = restCode[i].name,
                    Name__c = restCode[i].name,
                    Rate__c = restCode[i].rate,
                    Code__c = restCode[i].code,
                    Currency__c = restCode[i].name + ' ' + '(' + restCode[i].code + ')'
            );

            codesList.add(codeItem);
        }

        // This list will contain only new Codes
        List<Rate_Code__c> newRateCodesToInsert = new List<Rate_Code__c>();

        for (Rate_Code__c rcs : codesList) {
            for (String str : theIncomingKeysToInsert) {
                if (rcs.Code__c == str) {
                    newRateCodesToInsert.add(rcs);
                }
            }
        }

        try {
            if (!newRateCodesToInsert.isEmpty() && (newRateCodesToInsert.size() > 0)) {
                insert newRateCodesToInsert;
            }
        } catch (DmlException e) {
            System.debug('The following exception has occurred when inserting Rate Code records: ' + e.getMessage());

            // Assert that the error has been fired
            System.assert(e.getMessage().contains('Insert failed.'), 'Insert did not fire');

        }

        // Initially we had four records coming from the rcList and it should remain the same amount
        System.debug('It should remain four records after trying to insert missing data from JSON: ' + rcList.size() + 'records in database');
        System.assertEquals(4, rcList.size());

        Test.stopTest();

    }

    // This method test statement defaultCurrency = 'Bitcoin (BTC)' AND secondaryCurrency != 'Bitcoin (BTC)'; 
    @IsTest static void runTestBtcVsNoBtc() {
        /* Getting records from Test Data Factory "TestDataCurrencyConverterCallotuClass"
         *
         *  rcList contains four records: 
         *  rcList.get(0) is equal to Afghan Afghani, (1) to Bitcoin, (2) to US Dollar, and (3) to Vietnamese Dong
         *  This is used on System.asserts for all some of the methods in this class.
         */
        List<Rate_Code__c> rcList = TestDataCurrencyConverterCalloutClass.TestRateCodeRecordsInserted();

        Test.startTest();

        // Instantiate the standard controller
        Rate_Code__c rc = new Rate_Code__c();
        ApexPages.StandardController sc = new ApexPages.StandardController(rc);

        // Instantiate the extension
        ConverterSupportClass ext = new ConverterSupportClass(sc);

        // Test Properties
        ext.CurrencyOptionsOne.get(0);
        ext.CurrencyOptionsTwo.get(0);
        ext.defaultCurrency = 'Bitcoin (BTC)';
        ext.secondaryCurrency = 'US Dollar (USD)';
        ext.rate = [SELECT Rate__c, Currency__c FROM Rate_Code__c WHERE Currency__c = :ext.secondaryCurrency];
        ext.entryValueOne = 1.0;
        ext.entryValueTwo = ext.rate.Rate__c;
        ext.soqlEntryCurrencyOne = [SELECT Rate__c, RateVsBitcoin__c,Currency__c FROM Rate_Code__c WHERE Currency__c = :ext.secondaryCurrency];
        ext.soqlEntryCurrencyTwo = [SELECT Rate__c, RateVsBitcoin__c, Currency__c FROM Rate_Code__c WHERE Currency__c = :ext.secondaryCurrency];
        ext.soqlEntryCurrencyOne = [SELECT Rate__c, RateVsBitcoin__c, Currency__c FROM Rate_Code__c WHERE Currency__c = :ext.defaultCurrency];
        ext.soqlEntryCurrencyTwo = [SELECT Rate__c, RateVsBitcoin__c, Currency__c FROM Rate_Code__c WHERE Currency__c = :ext.defaultCurrency];
        ext.bitcoinValue = 1;
        ext.noBitcoinValue = ext.entryValueOne * ext.soqlEntryCurrencyOne.RateVsBitcoin__c;
        ext.CalculationEntryValueTwo = ext.soqlEntryCurrencyOne.Rate__c;
        ext.bitcoinBTC = 'Bitcoin (BTC)';

        // Asserts
        System.assertEquals(ext.CurrencyOptionsTwo, ext.CurrencyOptionsOne);
        System.assertEquals('Bitcoin (BTC)', ext.defaultCurrency);
        System.assertEquals('US Dollar (USD)', ext.secondaryCurrency);
        System.assertEquals(rcList.get(2).Rate__c, ext.rate.Rate__c);
        System.assertEquals(rcList.get(1).Currency__c, ext.soqlEntryCurrencyOne.Currency__c);
        System.assertEquals(rcList.get(1).Currency__c, ext.soqlEntryCurrencyTwo.Currency__c);
        System.assertEquals(1, ext.entryValueOne);
        System.assertEquals('Bitcoin (BTC)', ext.bitcoinBTC);

        // Set test page passing initial parameters.
        PageReference ccPage = Page.CurrencyConverter;

        // Parameters
        ccPage.getParameters().put(ext.defaultCurrency, 'Bitcoin (BTC)');
        ccPage.getParameters().put(ext.secondaryCurrency, 'US Dollar (USD)');
        ccPage.getParameters().put(String.valueOf(ext.entryValueOne), String.valueOf(1.0));
        ccPage.getParameters().put(String.valueOf(ext.entryValueTwo), String.valueOf(ext.rate.Rate__c));

        // Asserts
        System.assertEquals('Bitcoin (BTC)', ext.defaultCurrency);
        System.assertEquals('US Dollar (USD)', ext.secondaryCurrency);
        System.assertEquals(1.0, ext.entryValueOne);
        System.assertEquals(ext.rate.Rate__c, ext.entryValueTwo);

        ext.defaultCurrencyEntry();
        ext.secondaryCurrencyEntry();

        Test.setCurrentPage(ccPage);

        Test.stopTest();

    }

    // This method test statement defaultCurrency != 'Bitcoin (BTC)' AND secondaryCurrency != 'Bitcoin (BTC)';      
    @IsTest static void runTestNoBtcVsNoBtc() {
        /* Getting records from Test Data Factory "TestDataCurrencyConverterCallotuClass"
         *
         *  rcList contains four records:
         *  rcList.get(0) is equal to Afghan Afghani, (1) to Bitcoin, (2) to US Dollar, and (3) to Vietnamese Dong
         *  This is used on System.asserts for all some of the methods in this class.
         */
        List<Rate_Code__c> rcList = TestDataCurrencyConverterCalloutClass.TestRateCodeRecordsInserted();

        Test.startTest();

        // Instantiate the standard controller
        Rate_Code__c rc = new Rate_Code__c();
        ApexPages.StandardController sc = new ApexPages.StandardController(rc);

        // Instantiate the extension
        ConverterSupportClass ext = new ConverterSupportClass(sc);

        // Test Properties
        ext.CurrencyOptionsOne.get(0);
        ext.CurrencyOptionsTwo.get(0);
        ext.defaultCurrency = 'Bitcoin (BTC)';
        ext.secondaryCurrency = 'US Dollar (USD)';
        ext.rate = [SELECT Rate__c, Currency__c FROM Rate_Code__c WHERE Currency__c = :ext.secondaryCurrency];
        ext.entryValueOne = 1.0;
        ext.entryValueTwo = ext.rate.Rate__c;
        ext.soqlEntryCurrencyOne = [SELECT Rate__c, RateVsBitcoin__c,Currency__c FROM Rate_Code__c WHERE Currency__c = :ext.secondaryCurrency];
        ext.soqlEntryCurrencyTwo = [SELECT Rate__c, RateVsBitcoin__c, Currency__c FROM Rate_Code__c WHERE Currency__c = :ext.secondaryCurrency];
        ext.soqlEntryCurrencyOne = [SELECT Rate__c, RateVsBitcoin__c, Currency__c FROM Rate_Code__c WHERE Currency__c = :ext.defaultCurrency];
        ext.soqlEntryCurrencyTwo = [SELECT Rate__c, RateVsBitcoin__c, Currency__c FROM Rate_Code__c WHERE Currency__c = :ext.defaultCurrency];
        ext.bitcoinValue = 1;
        ext.noBitcoinValue = ext.entryValueOne * ext.soqlEntryCurrencyOne.RateVsBitcoin__c;
        ext.CalculationEntryValueTwo = ext.soqlEntryCurrencyOne.Rate__c;
        ext.bitcoinBTC = 'Bitcoin (BTC)';

        // Asserts
        System.assertEquals(ext.CurrencyOptionsTwo, ext.CurrencyOptionsOne);
        System.assertEquals('Bitcoin (BTC)', ext.defaultCurrency);
        System.assertEquals('US Dollar (USD)', ext.secondaryCurrency);
        System.assertEquals(rcList.get(2).Rate__c, ext.rate.Rate__c);
        System.assertEquals(rcList.get(1).Currency__c, ext.soqlEntryCurrencyOne.Currency__c);
        System.assertEquals(rcList.get(1).Currency__c, ext.soqlEntryCurrencyTwo.Currency__c);
        System.assertEquals(1, ext.entryValueOne);
        System.assertEquals('Bitcoin (BTC)', ext.bitcoinBTC);

        // Set test page passing initial parameters.
        PageReference ccPage = Page.CurrencyConverter;

        // Parameters
        ccPage.getParameters().put(ext.defaultCurrency, 'Bitcoin (BTC)');
        ccPage.getParameters().put(ext.secondaryCurrency, 'US Dollar (USD)');
        ccPage.getParameters().put(String.valueOf(ext.entryValueOne), String.valueOf(1.0));
        ccPage.getParameters().put(String.valueOf(ext.entryValueTwo), String.valueOf(ext.rate.Rate__c));

        // Asserts
        System.assertEquals('Bitcoin (BTC)', ext.defaultCurrency);
        System.assertEquals('US Dollar (USD)', ext.secondaryCurrency);
        System.assertEquals(1.0, ext.entryValueOne);
        System.assertEquals(ext.rate.Rate__c, ext.entryValueTwo);

        // This should be giving Bitcoin RateVsBitcoin__c value
        System.debug(ext.soqlEntryCurrencyOne.RateVsBitcoin__c);

        // Setting up new values for defaultCurrency and secondaryCurrency 
        ext.defaultCurrency = 'Vietnamese Dong (VND)';
        ext.secondaryCurrency = 'Afghan Afghani (AFN)';
        System.assertEquals('Vietnamese Dong (VND)', ext.defaultCurrency);
        System.assertEquals('Afghan Afghani (AFN)', ext.secondaryCurrency);

        // Debugging changes to defaultCurrency and secondaryCurrency
        System.debug(ext.defaultCurrency);
        System.debug(ext.secondaryCurrency);

        ext.soqlEntryCurrencyOne = [SELECT Rate__c, RateVsBitcoin__c, Currency__c FROM Rate_Code__c WHERE Currency__c = :ext.defaultCurrency];
        ext.soqlEntryCurrencyTwo = [SELECT Rate__c, Currency__c FROM Rate_Code__c WHERE Currency__c = :ext.secondaryCurrency];
        System.assertEquals('Vietnamese Dong (VND)', ext.soqlEntryCurrencyOne.Currency__c);
        System.assertEquals('Afghan Afghani (AFN)', ext.soqlEntryCurrencyTwo.Currency__c);

        System.debug(ext.soqlEntryCurrencyOne);
        System.debug(ext.soqlEntryCurrencyTwo);

        ext.defaultCurrencyEntry();
        ext.secondaryCurrencyEntry();

        Test.setCurrentPage(ccPage);

        Test.stopTest();

    }

    // This method test statement defaultCurrency == secondaryCurrency  
    @IsTest static void runTestBothCurrenciesEquals() {
        /* Getting records from Test Data Factory "TestDataCurrencyConverterCallotuClass"
         *
         *  rcList contains four records: 
         *  rcList.get(0) is equal to Afghan Afghani, (1) to Bitcoin, (2) to US Dollar, and (3) to Vietnamese Dong
         *  This is used on System.asserts for all some of the methods in this class.
         */
        List<Rate_Code__c> rcList = TestDataCurrencyConverterCalloutClass.TestRateCodeRecordsInserted();

        Test.startTest();

        // Instantiate the standard controller
        Rate_Code__c rc = new Rate_Code__c();
        ApexPages.StandardController sc = new ApexPages.StandardController(rc);

        // Instantiate the extension
        ConverterSupportClass ext = new ConverterSupportClass(sc);

        // Test Properties
        ext.CurrencyOptionsOne.get(0);
        ext.CurrencyOptionsTwo.get(0);
        ext.defaultCurrency = 'Bitcoin (BTC)';
        ext.secondaryCurrency = 'US Dollar (USD)';
        ext.rate = [SELECT Rate__c, Currency__c FROM Rate_Code__c WHERE Currency__c = :ext.secondaryCurrency];
        ext.entryValueOne = 1.0;
        ext.entryValueTwo = ext.rate.Rate__c;
        ext.soqlEntryCurrencyOne = [SELECT Rate__c, RateVsBitcoin__c,Currency__c FROM Rate_Code__c WHERE Currency__c = :ext.secondaryCurrency];
        ext.soqlEntryCurrencyTwo = [SELECT Rate__c, RateVsBitcoin__c, Currency__c FROM Rate_Code__c WHERE Currency__c = :ext.secondaryCurrency];
        ext.soqlEntryCurrencyOne = [SELECT Rate__c, RateVsBitcoin__c, Currency__c FROM Rate_Code__c WHERE Currency__c = :ext.defaultCurrency];
        ext.soqlEntryCurrencyTwo = [SELECT Rate__c, RateVsBitcoin__c, Currency__c FROM Rate_Code__c WHERE Currency__c = :ext.defaultCurrency];
        ext.bitcoinValue = 1;
        ext.noBitcoinValue = ext.entryValueOne * ext.soqlEntryCurrencyOne.RateVsBitcoin__c;
        ext.CalculationEntryValueTwo = ext.soqlEntryCurrencyOne.Rate__c;
        ext.bitcoinBTC = 'Bitcoin (BTC)';

        // Asserts
        System.assertEquals(ext.CurrencyOptionsTwo, ext.CurrencyOptionsOne);
        System.assertEquals('Bitcoin (BTC)', ext.defaultCurrency);
        System.assertEquals('US Dollar (USD)', ext.secondaryCurrency);
        System.assertEquals(rcList.get(2).Rate__c, ext.rate.Rate__c);
        System.assertEquals(rcList.get(1).Currency__c, ext.soqlEntryCurrencyOne.Currency__c);
        System.assertEquals(rcList.get(1).Currency__c, ext.soqlEntryCurrencyTwo.Currency__c);
        System.assertEquals(1, ext.entryValueOne);
        System.assertEquals('Bitcoin (BTC)', ext.bitcoinBTC);

        // Set test page passing initial parameters.
        PageReference ccPage = Page.CurrencyConverter;

        // Parameters
        ccPage.getParameters().put(ext.defaultCurrency, 'Bitcoin (BTC)');
        ccPage.getParameters().put(ext.secondaryCurrency, 'US Dollar (USD)');
        ccPage.getParameters().put(String.valueOf(ext.entryValueOne), String.valueOf(1.0));
        ccPage.getParameters().put(String.valueOf(ext.entryValueTwo), String.valueOf(ext.rate.Rate__c));

        // Asserts
        System.assertEquals('Bitcoin (BTC)', ext.defaultCurrency);
        System.assertEquals('US Dollar (USD)', ext.secondaryCurrency);
        System.assertEquals(1.0, ext.entryValueOne);
        System.assertEquals(ext.rate.Rate__c, ext.entryValueTwo);

        // This should be givin Bitcoin RateVsBitcoin__c value
        System.debug(ext.soqlEntryCurrencyOne.RateVsBitcoin__c);

        // Setting up new values for defaultCurrency and secondaryCurrency 
        ext.defaultCurrency = 'Vietnamese Dong (VND)';
        ext.secondaryCurrency = 'Vietnamese Dong (VND)';
        System.assertEquals('Vietnamese Dong (VND)', ext.defaultCurrency);
        System.assertEquals('Vietnamese Dong (VND)', ext.secondaryCurrency);

        // Debugging changes to defaultCurrency and secondaryCurrency
        System.debug(ext.defaultCurrency);
        System.debug(ext.secondaryCurrency);

        ext.soqlEntryCurrencyOne = [SELECT Rate__c, RateVsBitcoin__c, Currency__c FROM Rate_Code__c WHERE Currency__c = :ext.defaultCurrency];
        ext.soqlEntryCurrencyTwo = [SELECT Rate__c, Currency__c FROM Rate_Code__c WHERE Currency__c = :ext.secondaryCurrency];
        System.assertEquals('Vietnamese Dong (VND)', ext.soqlEntryCurrencyOne.Currency__c);
        System.assertEquals('Vietnamese Dong (VND)', ext.soqlEntryCurrencyTwo.Currency__c);

        System.debug(ext.soqlEntryCurrencyOne);
        System.debug(ext.soqlEntryCurrencyTwo);

        ext.defaultCurrencyEntry();
        ext.secondaryCurrencyEntry();

        Test.setCurrentPage(ccPage);

        Test.stopTest();

    }

    // This method test statement defaultCurrency != 'Bitcoin (BTC)' AND secondaryCurrency == 'Bitcoin (BTC)'; 
    @IsTest static void runTestNoBtcVsBtc() {
        /* Getting records from Test Data Factory "TestDataCurrencyConverterCalloutClass"
        *
        *  rcList contains four records: 
        *  rcList.get(0) is equal to Afghan Afghani, (1) to Bitcoin, (2) to US Dollar, and (3) to Vietnamese Dong
        *  This is used on System.asserts for all some of the methods in this class.
        */
        List<Rate_Code__c> rcList = TestDataCurrencyConverterCalloutClass.TestRateCodeRecordsInserted();

        Test.startTest();

        // Instantiate the standard controller
        Rate_Code__c rc = new Rate_Code__c();
        ApexPages.StandardController sc = new ApexPages.StandardController(rc);

        // Instantiate the extension
        ConverterSupportClass ext = new ConverterSupportClass(sc);

        // Test Properties
        ext.CurrencyOptionsOne.get(0);
        ext.CurrencyOptionsTwo.get(0);
        ext.defaultCurrency = 'Bitcoin (BTC)';
        ext.secondaryCurrency = 'US Dollar (USD)';
        ext.rate = [SELECT Rate__c, Currency__c FROM Rate_Code__c WHERE Currency__c = :ext.secondaryCurrency];
        ext.entryValueOne = 1.0;
        ext.entryValueTwo = ext.rate.Rate__c;
        ext.soqlEntryCurrencyOne = [SELECT Rate__c, RateVsBitcoin__c,Currency__c FROM Rate_Code__c WHERE Currency__c = :ext.secondaryCurrency];
        ext.soqlEntryCurrencyTwo = [SELECT Rate__c, RateVsBitcoin__c, Currency__c FROM Rate_Code__c WHERE Currency__c = :ext.secondaryCurrency];
        ext.soqlEntryCurrencyOne = [SELECT Rate__c, RateVsBitcoin__c, Currency__c FROM Rate_Code__c WHERE Currency__c = :ext.defaultCurrency];
        ext.soqlEntryCurrencyTwo = [SELECT Rate__c, RateVsBitcoin__c, Currency__c FROM Rate_Code__c WHERE Currency__c = :ext.defaultCurrency];
        ext.bitcoinValue = 1;
        ext.noBitcoinValue = ext.entryValueOne * ext.soqlEntryCurrencyOne.RateVsBitcoin__c;
        ext.CalculationEntryValueTwo = ext.soqlEntryCurrencyOne.Rate__c;
        ext.bitcoinBTC = 'Bitcoin (BTC)';

        // Asserts
        System.assertEquals(ext.CurrencyOptionsTwo, ext.CurrencyOptionsOne);
        System.assertEquals('Bitcoin (BTC)', ext.defaultCurrency);
        System.assertEquals('US Dollar (USD)', ext.secondaryCurrency);
        System.assertEquals(rcList.get(2).Rate__c, ext.rate.Rate__c);
        System.assertEquals(rcList.get(1).Currency__c, ext.soqlEntryCurrencyOne.Currency__c);
        System.assertEquals(rcList.get(1).Currency__c, ext.soqlEntryCurrencyTwo.Currency__c);
        System.assertEquals(1, ext.entryValueOne);
        System.assertEquals('Bitcoin (BTC)', ext.bitcoinBTC);

        // Set test page passing initial parameters.
        PageReference ccPage = Page.CurrencyConverter;

        // Parameters
        ccPage.getParameters().put(ext.defaultCurrency, 'Bitcoin (BTC)');
        ccPage.getParameters().put(ext.secondaryCurrency, 'US Dollar (USD)');
        ccPage.getParameters().put(String.valueOf(ext.entryValueOne), String.valueOf(1.0));
        ccPage.getParameters().put(String.valueOf(ext.entryValueTwo), String.valueOf(ext.rate.Rate__c));

        // Asserts
        System.assertEquals('Bitcoin (BTC)', ext.defaultCurrency);
        System.assertEquals('US Dollar (USD)', ext.secondaryCurrency);
        System.assertEquals(1.0, ext.entryValueOne);
        System.assertEquals(ext.rate.Rate__c, ext.entryValueTwo);

        // This should be giving Bitcoin RateVsBitcoin__c value
        System.debug(ext.soqlEntryCurrencyOne.RateVsBitcoin__c);

        // Setting up new values for defaultCurrency and secondaryCurrency 
        ext.defaultCurrency = 'Vietnamese Dong (VND)';
        ext.secondaryCurrency = 'Bitcoin (BTC)';
        System.assertEquals('Vietnamese Dong (VND)', ext.defaultCurrency);
        System.assertEquals('Bitcoin (BTC)', ext.secondaryCurrency);

        // Debugging changes to defaultCurrency and secondaryCurrency
        System.debug(ext.defaultCurrency);
        System.debug(ext.secondaryCurrency);

        ext.soqlEntryCurrencyOne = [SELECT Rate__c, RateVsBitcoin__c, Currency__c FROM Rate_Code__c WHERE Currency__c = :ext.defaultCurrency];
        ext.soqlEntryCurrencyTwo = [SELECT Rate__c, Currency__c FROM Rate_Code__c WHERE Currency__c = :ext.secondaryCurrency];
        System.assertEquals('Vietnamese Dong (VND)', ext.soqlEntryCurrencyOne.Currency__c);
        System.assertEquals('Bitcoin (BTC)', ext.soqlEntryCurrencyTwo.Currency__c);

        System.debug(ext.soqlEntryCurrencyOne);
        System.debug(ext.soqlEntryCurrencyTwo);

        ext.defaultCurrencyEntry();
        ext.secondaryCurrencyEntry();

        Test.setCurrentPage(ccPage);

        Test.stopTest();

    }

    // This method test if entry values one and two are behaving as expected with zero inputs
    @IsTest static void runTestOnEntryValuesZeroInput() {
        /* Getting records from Test Data Factory "TestDataCurrencyConverterCalloutClass"
         *
         *  rcList contains four records: 
         *  rcList.get(0) is equal to Afghan Afghani, (1) to Bitcoin, (2) to US Dollar, and (3) to Vietnamese Dong
         *  This is used on System.asserts for all some of the methods in this class.
         */
        List<Rate_Code__c> rcList = TestDataCurrencyConverterCalloutClass.TestRateCodeRecordsInserted();

        Test.startTest();

        // Instantiate the standard controller
        Rate_Code__c rc = new Rate_Code__c();
        ApexPages.StandardController sc = new ApexPages.StandardController(rc);

        // Instantiate the extension
        ConverterSupportClass ext = new ConverterSupportClass(sc);

        // Test Properties
        ext.CurrencyOptionsOne.get(0);
        ext.CurrencyOptionsTwo.get(0);
        ext.defaultCurrency = 'Bitcoin (BTC)';
        ext.secondaryCurrency = 'US Dollar (USD)';
        ext.rate = [SELECT Rate__c, Currency__c FROM Rate_Code__c WHERE Currency__c = :ext.secondaryCurrency];
        ext.entryValueOne = 1.0;
        ext.entryValueTwo = ext.rate.Rate__c;
        ext.soqlEntryCurrencyOne = [SELECT Rate__c, RateVsBitcoin__c,Currency__c FROM Rate_Code__c WHERE Currency__c = :ext.secondaryCurrency];
        ext.soqlEntryCurrencyTwo = [SELECT Rate__c, RateVsBitcoin__c, Currency__c FROM Rate_Code__c WHERE Currency__c = :ext.secondaryCurrency];
        ext.soqlEntryCurrencyOne = [SELECT Rate__c, RateVsBitcoin__c, Currency__c FROM Rate_Code__c WHERE Currency__c = :ext.defaultCurrency];
        ext.soqlEntryCurrencyTwo = [SELECT Rate__c, RateVsBitcoin__c, Currency__c FROM Rate_Code__c WHERE Currency__c = :ext.defaultCurrency];
        ext.bitcoinValue = 1;
        ext.noBitcoinValue = ext.entryValueOne * ext.soqlEntryCurrencyOne.RateVsBitcoin__c;
        ext.CalculationEntryValueTwo = ext.soqlEntryCurrencyOne.Rate__c;
        ext.bitcoinBTC = 'Bitcoin (BTC)';

        // Asserts
        System.assertEquals(ext.CurrencyOptionsTwo, ext.CurrencyOptionsOne);
        System.assertEquals('Bitcoin (BTC)', ext.defaultCurrency);
        System.assertEquals('US Dollar (USD)', ext.secondaryCurrency);
        System.assertEquals(rcList.get(2).Rate__c, ext.rate.Rate__c);
        System.assertEquals(rcList.get(1).Currency__c, ext.soqlEntryCurrencyOne.Currency__c);
        System.assertEquals(rcList.get(1).Currency__c, ext.soqlEntryCurrencyTwo.Currency__c);
        System.assertEquals(1, ext.entryValueOne);
        System.assertEquals('Bitcoin (BTC)', ext.bitcoinBTC);

        // Set test page passing initial parameters.
        PageReference ccPage = Page.CurrencyConverter;

        // Parameters
        ccPage.getParameters().put(ext.defaultCurrency, 'Bitcoin (BTC)');
        ccPage.getParameters().put(ext.secondaryCurrency, 'US Dollar (USD)');
        ccPage.getParameters().put(String.valueOf(ext.entryValueOne), String.valueOf(1.0));
        ccPage.getParameters().put(String.valueOf(ext.entryValueTwo), String.valueOf(ext.rate.Rate__c));

        // Asserts
        System.assertEquals('Bitcoin (BTC)', ext.defaultCurrency);
        System.assertEquals('US Dollar (USD)', ext.secondaryCurrency);
        System.assertEquals(1.0, ext.entryValueOne);
        System.assertEquals(ext.rate.Rate__c, ext.entryValueTwo);

        // This should be giving Bitcoin RatevsBitcoin__c value
        System.debug(ext.soqlEntryCurrencyOne.RateVsBitcoin__c);

        // Setting up new values for defaultCurrency and secondaryCurrency 
        ext.defaultCurrency = 'Vietnamese Dong (VND)';
        ext.secondaryCurrency = 'Bitcoin (BTC)';
        System.assertEquals('Vietnamese Dong (VND)', ext.defaultCurrency);
        System.assertEquals('Bitcoin (BTC)', ext.secondaryCurrency);

        // Debugging changes to defaultCurrency and secondaryCurrency
        System.debug(ext.defaultCurrency);
        System.debug(ext.secondaryCurrency);

        ext.soqlEntryCurrencyOne = [SELECT Rate__c, RateVsBitcoin__c, Currency__c FROM Rate_Code__c WHERE Currency__c = :ext.defaultCurrency];
        ext.soqlEntryCurrencyTwo = [SELECT Rate__c, Currency__c FROM Rate_Code__c WHERE Currency__c = :ext.secondaryCurrency];
        System.assertEquals('Vietnamese Dong (VND)', ext.soqlEntryCurrencyOne.Currency__c);
        System.assertEquals('Bitcoin (BTC)', ext.soqlEntryCurrencyTwo.Currency__c);
        System.debug(ext.soqlEntryCurrencyOne);
        System.debug(ext.soqlEntryCurrencyTwo);

        ext.entryValueOne = 0;
        ext.entryValueTwo = 0;

        ext.defaultCurrencyEntry();
        ext.secondaryCurrencyEntry();

        Test.setCurrentPage(ccPage);

        Test.stopTest();

    }

    @IsTest static void runTestWithOtherUserProfile() {
        /* Getting records from Test Data Factory "TestDataCurrencyConverterCallotuClass"
        *
        *  rcList contains four records: 
        *  rcList.get(0) is equal to Afghan Afghani, (1) to Bitcoin, (2) to US Dollar, and (3) to Vietnamese Dong
        *  This is used on System.asserts for some of the methods in this class.
        */
        List<Rate_Code__c> rcList = TestDataCurrencyConverterCalloutClass.TestRateCodeRecordsInserted();


        // Creating new user for our test
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
        User u = new User(Alias = 'standt', Email = 'standardTestCurrencyuser@testorg.com',
                EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = p.Id,
                TimeZoneSidKey = 'America/Los_Angeles', Username = 'standardTestCurrencyuser@testorg.com');

        // Instantiate the standard controller
        Rate_Code__c rc = new Rate_Code__c();
        ApexPages.StandardController sc = new ApexPages.StandardController(rc);

        // Instantiate the extension
        ConverterSupportClass ext = new ConverterSupportClass(sc);

        Test.startTest();

        System.runAs(u) {

            // The following code runs as user 'u' 
            System.debug('Current User: ' + UserInfo.getUserName());
            System.debug('Current Profile: ' + UserInfo.getProfileId());


            // Test Properties
            ext.CurrencyOptionsOne.get(0);
            ext.CurrencyOptionsTwo.get(0);
            ext.defaultCurrency = 'Bitcoin (BTC)';
            ext.secondaryCurrency = 'US Dollar (USD)';
            ext.rate = [SELECT Rate__c, Currency__c FROM Rate_Code__c WHERE Currency__c = :ext.secondaryCurrency];
            ext.entryValueOne = 1.0;
            ext.entryValueTwo = ext.rate.Rate__c;
            ext.soqlEntryCurrencyOne = [SELECT Rate__c, RateVsBitcoin__c,Currency__c FROM Rate_Code__c WHERE Currency__c = :ext.secondaryCurrency];
            ext.soqlEntryCurrencyTwo = [SELECT Rate__c, RateVsBitcoin__c, Currency__c FROM Rate_Code__c WHERE Currency__c = :ext.secondaryCurrency];
            ext.soqlEntryCurrencyOne = [SELECT Rate__c, RateVsBitcoin__c, Currency__c FROM Rate_Code__c WHERE Currency__c = :ext.defaultCurrency];
            ext.soqlEntryCurrencyTwo = [SELECT Rate__c, RateVsBitcoin__c, Currency__c FROM Rate_Code__c WHERE Currency__c = :ext.defaultCurrency];
            ext.bitcoinValue = 1;
            ext.noBitcoinValue = ext.entryValueOne * ext.soqlEntryCurrencyOne.RateVsBitcoin__c;
            ext.CalculationEntryValueTwo = ext.soqlEntryCurrencyOne.Rate__c;
            ext.bitcoinBTC = 'Bitcoin (BTC)';

            // Asserts
            System.assertEquals(ext.CurrencyOptionsTwo, ext.CurrencyOptionsOne);
            System.assertEquals('Bitcoin (BTC)', ext.defaultCurrency);
            System.assertEquals('US Dollar (USD)', ext.secondaryCurrency);
            System.assertEquals(rcList.get(2).Rate__c, ext.rate.Rate__c);
            System.assertEquals(rcList.get(1).Currency__c, ext.soqlEntryCurrencyOne.Currency__c);
            System.assertEquals(rcList.get(1).Currency__c, ext.soqlEntryCurrencyTwo.Currency__c);
            System.assertEquals(1, ext.entryValueOne);
            System.assertEquals('Bitcoin (BTC)', ext.bitcoinBTC);

            // Set test page passing initial parameters.
            PageReference ccPage = Page.CurrencyConverter;

            // Parameters
            ccPage.getParameters().put(ext.defaultCurrency, 'Bitcoin (BTC)');
            ccPage.getParameters().put(ext.secondaryCurrency, 'US Dollar (USD)');
            ccPage.getParameters().put(String.valueOf(ext.entryValueOne), String.valueOf(1.0));
            ccPage.getParameters().put(String.valueOf(ext.entryValueTwo), String.valueOf(ext.rate.Rate__c));

            // Asserts
            System.assertEquals('Bitcoin (BTC)', ext.defaultCurrency);
            System.assertEquals('US Dollar (USD)', ext.secondaryCurrency);
            System.assertEquals(1.0, ext.entryValueOne);
            System.assertEquals(ext.rate.Rate__c, ext.entryValueTwo);

            // This should be giving Bitcoin RateVsBitcoin__c value
            System.debug(ext.soqlEntryCurrencyOne.RateVsBitcoin__c);

            // Setting up new values for defaultCurrency and secondaryCurrency 
            ext.defaultCurrency = 'Vietnamese Dong (VND)';
            ext.secondaryCurrency = 'Bitcoin (BTC)';
            System.assertEquals('Vietnamese Dong (VND)', ext.defaultCurrency);
            System.assertEquals('Bitcoin (BTC)', ext.secondaryCurrency);

            // Debugging changes to defaultCurrency and secondaryCurrency
            System.debug(ext.defaultCurrency);
            System.debug(ext.secondaryCurrency);

            ext.soqlEntryCurrencyOne = [SELECT Rate__c, RateVsBitcoin__c, Currency__c FROM Rate_Code__c WHERE Currency__c = :ext.defaultCurrency];
            ext.soqlEntryCurrencyTwo = [SELECT Rate__c, Currency__c FROM Rate_Code__c WHERE Currency__c = :ext.secondaryCurrency];
            System.assertEquals('Vietnamese Dong (VND)', ext.soqlEntryCurrencyOne.Currency__c);
            System.assertEquals('Bitcoin (BTC)', ext.soqlEntryCurrencyTwo.Currency__c);
            System.debug(ext.soqlEntryCurrencyOne);
            System.debug(ext.soqlEntryCurrencyTwo);

            ext.entryValueOne = 0;
            ext.entryValueTwo = 0;

            ext.defaultCurrencyEntry();
            ext.secondaryCurrencyEntry();

            Test.setCurrentPage(ccPage);

            Test.stopTest();
        }
    }
}