/*********************************************************************************************************
    Apex Class Name : ConverterSupportClass
    Created By  : Carlos Naranjo (carlos.naranjo@ccloudonline.nl)
    Description : HTTP Request to Get Code values. It completes Currency Converter Visualforce Page
*********************************************************************************************************/
public without sharing class ConverterSupportClass {

    public List<SelectOption> CurrencyOptionsOne { get; set; }
    public List<SelectOption> CurrencyOptionsTwo { get; set; }
    public String defaultCurrency { get; set; }
    public String secondaryCurrency { get; set; }
    public Decimal entryValueOne { get; set; }
    public Decimal entryValueTwo { get; set; }
    public Rate_Code__c rate { get; set; }
    public Rate_Code__c soqlEntryCurrencyOne { get; set; }
    public Rate_Code__c soqlEntryCurrencyTwo { get; set; }

    public Decimal bitcoinValue = 1;
    public Decimal noBitcoinValue;
    public Decimal CalculationEntryValueTwo;
    public String bitcoinBTC = 'Bitcoin (BTC)';

    /*
     * Sending request to end point to get currency values
    */
    public static void init() {
        String endpoint = 'https://bitpay.com/api/rates/';
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');
        Http http = new Http();
        HttpResponse res = http.send(req);
        String responseBody = res.getBody();

        if (res.getStatusCode() != 200) {
            System.debug('The status code returned was not expected: '
                    + res.getStatusCode() + ' ' + res.getStatus());
        } else {
            /* 
             * Parsing code values from JSON string.
            */
            List<Codes> restCode = (List<Codes>) JSON.deserialize(responseBody, List<Codes>.class);
            List<Rate_Code__c> inSystemCodesList = [SELECT Code__c, Rate__c FROM Rate_Code__c];
            Map<String, Decimal> inSystemCodesMap = new Map<String, Decimal>();
            Map<String, Decimal> incomingCodesMap = new Map<String, Decimal>();

            // Use these collections to insert new Rate_Code__c records based on new restCode Codes that are not in the system.
            Set<String> theIncomingKeysToInsert = new Set<String>();
            List<Rate_Code__c> codesList = new List<Rate_Code__c>();

            /*
            * Adding Code__c and Rate__c values from SFDC to a map
            */
            for (Integer c = 0; c < inSystemCodesList.size(); c++) {
                inSystemCodesMap.put(inSystemCodesList[c].Code__c, inSystemCodesList[c].Rate__c);
            }

            /*
             * Adding code and rate values from JSON to a map
            */
            for (Integer i = 0; i < restCode.size(); i++) {
                incomingCodesMap.put(restCode[i].code, restCode[i].rate);
            }

            /*
             * Iterate through codes that are already in the system
            */
            for (String k : inSystemCodesMap.keySet()) {

                /*  If incoming Codes from GET response does not match with those in system, 
                 *  send to collection for later processing
                */
                if (!incomingCodesMap.keySet().contains(k)) {
                    theIncomingKeysToInsert.add(k);
                }
            }

            /*
             * Inserting new Code/Rate/Currency if there is a new Code (Name, Rate, and Code) coming from the http response
            */
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

            /*
             * Inserting new Codes if any
            */
            try {
                if (!newRateCodesToInsert.isEmpty() && (newRateCodesToInsert.size() > 0)) {
                    insert newRateCodesToInsert;
                }

            } catch (DmlException e) {
                System.debug('The following exception has occurred when insert Rate Code records: ' + e.getMessage());

            }
            /*
             * Getting Rate_Code__c records from system and update them with the new rate from incomingCodesMap. 
            */
            List<Rate_Code__c> rc = [
                    SELECT Id, Rate__c, Code__c, Name__c
                    FROM Rate_Code__c
                    WHERE Code__c IN :incomingCodesMap.keySet()
            ];

            if ((!rc.isEmpty()) && (rc.size() > 0)) {
                for (Rate_Code__c r : rc) {
                    if (r.Code__c != null && incomingCodesMap.containsKey(r.Code__c)) {
                        r.Rate__c = incomingCodesMap.get(r.Code__c);
                    }
                }
            }

            /*
             * Executing DML operation to update Rate__c for Rate_Code__c with news values from incomingCodesMap
            */
            try {

                update rc;

            } catch (DmlException e) {
                System.debug('The following exception has occurred when updating Rate Code records: ' + e.getMessage());

            }
        }
    }

    /*
     * Standard Controller
    */
    public ConverterSupportClass(ApexPages.StandardController controller) {

        /*
         * Setting up default values for currency picklists
        */
        defaultCurrency = bitcoinBTC;
        secondaryCurrency = 'US Dollar (USD)';

        /*
         * Querying Rate_Code__c object to obtain secondaryCurrency value and   
         * setting it up as default value for the entryValueTwo field
        */
        rate = [
                SELECT Rate__c, Currency__c
                FROM Rate_Code__c
                WHERE Currency__c = :secondaryCurrency
                LIMIT 1
        ];

        entryValueOne = 1;
        entryValueTwo = rate.Rate__c;

        // Getting all values from currency picklist on Rate_Code__c
        CurrencyOptionsOne = new List<SelectOption>();
        CurrencyOptionsTwo = new List<SelectOption>();
        // Use DescribeFieldResult object to retrieve currency field.
        Schema.DescribeFieldResult statusFieldDescription = Rate_Code__c.Currency__c.getDescribe();

        /* 
         * For each picklist value, create a new select option
        */
        for (Schema.PicklistEntry picklistEntry : statusFieldDescription.getPicklistValues()) {
            CurrencyOptionsOne.add(new SelectOption(picklistEntry.getValue(), picklistEntry.getLabel()));
            CurrencyOptionsTwo.add(new SelectOption(picklistEntry.getValue(), picklistEntry.getLabel()));
        }
    }

    // Method for event actions on 'dropdown field one' Id dropdownOne
    public PageReference defaultCurrencyEntry() {
        if ((entryValueOne == 0) || (entryValueOne == null)) {
            entryValueOne = 0;
            entryValueTwo = 0;
        }

        else if ((defaultCurrency == bitcoinBTC) &&
                (secondaryCurrency != bitcoinBTC) &&
                ((entryValueOne != 0) || (entryValueOne != null))) {
            bitcoinValue = entryValueOne;

            soqlEntryCurrencyOne = [
                    SELECT Rate__c, Currency__c
                    FROM Rate_Code__c
                    WHERE Currency__c = :secondaryCurrency
            ];

            CalculationEntryValueTwo = soqlEntryCurrencyOne.Rate__c.setScale(8);
            entryValueTwo = bitcoinValue * CalculationEntryValueTwo.setScale(3);

            // Actions for non Bitcoin currencies on defaultCurrency
        } else if ((defaultCurrency != bitcoinBTC) &&
                (secondaryCurrency != defaultCurrency) &&
                ((entryValueOne != 0) || (entryValueOne != null))) {

            soqlEntryCurrencyOne = [
                    SELECT RateVsBitcoin__c, Currency__c
                    FROM Rate_Code__c
                    WHERE Currency__c = :defaultCurrency
            ];

            soqlEntryCurrencyTwo = [
                    SELECT Rate__c, Currency__c
                    FROM Rate_Code__c
                    WHERE Currency__c = :secondaryCurrency
            ];

            noBitcoinValue = entryValueOne * soqlEntryCurrencyOne.RateVsBitcoin__c;
            entryValueTwo = noBitcoinValue * soqlEntryCurrencyTwo.Rate__c.setScale(3);

            // If both currencies entries are equal, set both to same values
        } else if ((defaultCurrency == secondaryCurrency) &&
                (secondaryCurrency == defaultCurrency) &&
                ((entryValueOne != 0) || (entryValueOne != null))) {
            entryValueOne = entryValueOne.setScale(3);
            entryValueTwo = entryValueOne.setScale(3);
        }

        return null;
    }

    /*
     * Method for event actions on 'dropdown field one' Id dropdownTwo
    */
    public PageReference secondaryCurrencyEntry() {
        /*
         * If one currency entry is equal zero, set both to zero
        */
        if ((entryValueTwo == 0) || (entryValueTwo == null)) {
            entryValueOne = 0;
            entryValueTwo = 0;
        }

        else if ((secondaryCurrency == bitcoinBTC) &&
                (defaultCurrency != bitcoinBTC) &&
                ((entryValueTwo != 0) || (entryValueTwo != null))) {
            bitcoinValue = entryValueTwo;

            soqlEntryCurrencyTwo = [
                    SELECT Rate__c, Currency__c
                    FROM Rate_Code__c
                    WHERE Currency__c = :defaultCurrency
            ];

            CalculationEntryValueTwo = soqlEntryCurrencyTwo.Rate__c.setScale(8);
            entryValueOne = bitcoinValue * CalculationEntryValueTwo.setScale(3);

            // Actions for non Bitcoin currencies on secondaryCurrency
        } else if ((secondaryCurrency != bitcoinBTC) &&
                (secondaryCurrency != defaultCurrency) &&
                ((entryValueTwo != 0) || (entryValueTwo != null))) {
            noBitcoinValue = 0;
            soqlEntryCurrencyTwo = [
                    SELECT RateVsBitcoin__c, Currency__c
                    FROM Rate_Code__c
                    WHERE Currency__c = :secondaryCurrency
            ];
            soqlEntryCurrencyOne = [
                    SELECT Rate__c, Currency__c
                    FROM Rate_Code__c
                    WHERE Currency__c = :defaultCurrency
            ];

            noBitcoinValue = entryValueTwo * soqlEntryCurrencyTwo.RateVsBitcoin__c;
            entryValueOne = noBitcoinValue * soqlEntryCurrencyOne.Rate__c.setScale(3);

            // If both currencies entries are equal, set both to same values
        } else if ((secondaryCurrency == defaultCurrency) && (defaultCurrency == secondaryCurrency)) {
            entryValueTwo = entryValueTwo;
            entryValueOne = entryValueTwo;
        }

        return null;
    }

}