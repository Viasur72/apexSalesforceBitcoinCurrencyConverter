/*********************************************************************************************************
    Apex Class Name : ConverterSupportClass
    Created By  : Carlos Naranjo (carlos.naranjo@ccloudonline.nl)
    Description : HTTP Request to Get Code values. It completes Currency Converter Visualforce Page
*********************************************************************************************************/
public without sharing class  ConverterSupportClass {

    public List<SelectOption> CurrencyOptionsOne {get;set;}
    public List<SelectOption> CurrencyOptionsTwo {get;set;}
    public String defaultCurrency {get; set;}
    public String secundaryCurrency {get; set;}
    public Decimal entryValueOne {get;set;}
    public Decimal entryValueTwo {get;set;}
    public Rate_Code__c rate {get;set;}
    public Rate_Code__c soqlEntryCurrencyOne {get;set;}
    public Rate_Code__c soqlEntryCurrencyTwo {get;set;}
    
    public Decimal bitcoinValue = 1;
    public Decimal noBitcoinValue; 
    public Decimal CalculationEntryValueTwo; 
    public String bitcoinBTC = 'Bitcoin (BTC)';
    
    
    /*
     * Sending request to end point to get currency values
    */
    public static void init()
    {
        String endpoint ='https://bitpay.com/api/rates/';    
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
        }
	     else{
        /* 
         * Parsing code values from JSON string.
        */
        List<Codes> restCode = (List<Codes>) JSON.deserialize(responseBody, List<Codes>.class); 
        List<Rate_Code__c> inSystemCodesList = [SELECT code__c, rate__c FROM Rate_Code__c]; 
        Map<String, Decimal> inSystemCodesMap = new Map<String, Decimal>();  
        Map<String, Decimal> incomingCodesMap = new Map<String, Decimal>(); 
                     
        // Use these collections to insert new Rate_Code__c records based on new restCode Codes that are not in the system.
        Set<String> theIncomingKeysToInsert = new Set<String>();  
        List<Rate_Code__c> codesList = new List<Rate_Code__c>(); 
         
         /*
	     * Adding code__c and rate__c values from SFDC to a map
	     */
         for(integer c=0; c<inSystemCodesList.size(); c++)
         {
             inSystemCodesMap.put(inSystemCodesList[c].code__c, inSystemCodesList[c].rate__c); 
         } 
            
         /*
	      * Adding code and rate values from JSON to a map
	     */
         for(integer i=0; i<restCode.size(); i++)
         {
             incomingCodesMap.put(restCode[i].code, restCode[i].rate); 
         }
            
         /*
		  * Iterate through codes that are already in the system
	     */
         for(String k: inSystemCodesMap.Keyset())
         {

         /*  If incoming Codes from GET response does not macth with those in system, 
          *  send to collection for later proccesing
         */
	        if(!incomingCodesMap.keyset().contains(k))
                  theIncomingKeysToInsert.add(k); 
               
         }
         
        /*
         * Inserting new Code/Rate/Currency if there is a new Code (Name, Rate, and Code) coming from the http response
        */   
        for(integer i=0; i<restCode.size(); i++){

            Rate_Code__c codeItem = new Rate_Code__c();

                 codeItem = new Rate_Code__c(name       = restCode[i].name,
                                            name__c     = restCode[i].name,
                                            rate__c     = restCode[i].rate,
                                            code__c     = restCode[i].code,
                                            currency__c = restCode[i].name +' '+'('+ restCode[i].code +')'
                                            );
                 
                codesList.add(codeItem); 
        }

        // This list will containg only new Codes
        List<Rate_Code__c> newRateCodesToInsert = new List<Rate_Code__c>(); 

        for(Rate_Code__c rcs: codesList)
        {
          for(String str: theIncomingKeysToInsert)
          {
                if(rcs.code__c == str)
                {
                   newRateCodesToInsert.add(rcs); 
                }
          }
        }

        /*
         * Inserting new Codes if any
        */
        try {
                if(!newRateCodesToInsert.isEmpty() && (newRateCodesToInsert.size()>0))

                    insert newRateCodesToInsert;

             } catch(DmlException e) { 
                System.debug('The following exception has occurred when insert Rate Code records: ' + e.getMessage());
              
             }
        /*
         * Getting Rate_Code__c records from system and update them with the new rate from incomingCodesMap. 
        */
        List<Rate_Code__c> rc = [SELECT id, rate__c, code__c, name__c
                                 FROM Rate_Code__c WHERE code__c IN :incomingCodesMap.keySet()]; 

         if((!rc.isEmpty()) && (rc.size()> 0))
         {
          for(Rate_Code__c r: rc)
          {
             if(r.code__c != null && incomingCodesMap.containsKey(r.code__c))
             {
                r.rate__c = incomingCodesMap.get(r.code__c);
             }
          }
        }	

         /*
          * Executing DML operation to update rate__c for Rate_Code__c with news values from incomingCodesMap
         */
         try {
    
               update rc;

             } catch(DmlException e) { 
                System.debug('The following exception has occurred when updating Rate Code records: ' + e.getMessage());
                
             }
       }

    } 
    
    /*
     * Standard Controller
    */
    public ConverterSupportClass(ApexPages.StandardController controller)
    {
        
        /*
         * Setting up default values for currency picklists
        */ 
        defaultCurrency   =  bitcoinBTC;
        secundaryCurrency = 'US Dollar (USD)'; 
        
        /*
         * Querying Rate_Code__c object to obtain secundaryCurrency value and   
         * setting it up as default value for the entryValueTwo field
        */ 
        rate =[SELECT rate__c, currency__c 
               FROM Rate_Code__c WHERE currency__c =:secundaryCurrency LIMIT 1]; 
        
        entryValueOne = 1;
        entryValueTwo = rate.rate__c;
                
        // Getting all values from currency picklist on Rate_Code__c
        CurrencyOptionsOne = new List<SelectOption>();
        CurrencyOptionsTwo = new List<SelectOption>(); 
        // Use DescribeFieldResult object to retrieve currency field.
        Schema.DescribeFieldResult statusFieldDescription =  Rate_Code__c.Currency__c.getDescribe();
        
        /* 
         * For each picklist value, create a new select option
        */
        for (Schema.Picklistentry  picklistEntry: statusFieldDescription.getPicklistValues())
        {
            CurrencyOptionsOne.add(new SelectOption(pickListEntry.getValue(),pickListEntry.getLabel()));
            CurrencyOptionsTwo.add(new SelectOption(pickListEntry.getValue(),pickListEntry.getLabel()));
         }  
         
       }
    
       /*
        * Method for event actions on 'dropdown field one' id dropdownOne
       */
       public PageReference defaultCurrencyEntry()
       {
       /*
        * If one currencie is equal zero or null.
       */
        if((entryValueOne == 0) || (entryValueOne == null))
            {
                entryValueOne = 0;
                entryValueTwo = 0;
            }

        else if((defaultCurrency == bitcoinBTC) &&
                 (secundaryCurrency != bitcoinBTC) &&
                    ((entryValueOne != 0) || (entryValueOne != null)))
            {
            bitcoinValue = entryValueOne; 
            soqlEntryCurrencyOne =[SELECT rate__c, currency__c 
                                  FROM Rate_Code__c WHERE currency__c =:secundaryCurrency]; 
            
            CalculationEntryValueTwo = soqlEntryCurrencyOne.rate__c.setscale(8);
            entryValueTwo = bitcoinValue * CalculationEntryValueTwo.setscale(3); 
            
            }

        /*
         * Actions for non Bitcoin currencies on defaultCurrency
        */ 
        else if((defaultCurrency != bitcoinBTC) && 
                 (secundaryCurrency != defaultCurrency) &&
                    ((entryValueOne != 0) || (entryValueOne != null)))
             {
               soqlEntryCurrencyOne =[SELECT RateVsBitcoin__c, currency__c 
                                     FROM Rate_Code__c WHERE currency__c =:defaultCurrency];
                           
               soqlEntryCurrencyTwo =[SELECT rate__c, currency__c 
                                     FROM Rate_Code__c WHERE currency__c =:secundaryCurrency];
              
               noBitcoinValue = entryValueOne * soqlEntryCurrencyOne.RateVsBitcoin__c;
               entryValueTwo  = noBitcoinValue * soqlEntryCurrencyTwo.rate__c.setscale(3); 
             }
               
        /*
         * If both currencies entries are equal, set both to same values
	    */
        else if((defaultCurrency == secundaryCurrency) && 
                    (secundaryCurrency == defaultCurrency) &&
                        ((entryValueOne != 0) || (entryValueOne != null)))
             {
               entryValueOne = entryValueOne.setscale(3);
               entryValueTwo = entryValueOne.setscale(3); 
             }


           return null;
       }
    
       /*
        * Method for event actions on 'dropdown field one' id dropdownTwo
       */
       public PageReference secundaryCurrencyEntry()
       {
        /*
         * If one currencies entrie is zero, set both to zero
        */
        if((entryValueTwo == 0) || (entryValueTwo == null))
            {
                 entryValueOne = 0;
                 entryValueTwo = 0;
            }

        else if((secundaryCurrency == bitcoinBTC) && 
                (defaultCurrency != bitcoinBTC) && 
                    ((entryValueTwo != 0) || (entryValueTwo != null)))
        {
            bitcoinValue = entryValueTwo; 
            soqlEntryCurrencyTwo =[SELECT rate__c, currency__c 
                                  FROM Rate_Code__c WHERE currency__c =:defaultCurrency]; 
            
            CalculationEntryValueTwo = soqlEntryCurrencyTwo.rate__c.setscale(8); 
            entryValueOne = bitcoinValue * CalculationEntryValueTwo.setscale(3);
                     
        }
        /*
         * Actions for non Bitcoin currencies on secundaryCurrency
        */ 
        else if((secundaryCurrency != bitcoinBTC) &&   
                    (secundaryCurrency != defaultCurrency) && 
                        ((entryValueTwo != 0) || (entryValueTwo != null)))
        {	
             noBitcoinValue = 0; 
             soqlEntryCurrencyTwo =[SELECT RateVsBitcoin__c, currency__c 
                                    FROM Rate_Code__c WHERE currency__c =:secundaryCurrency];
             soqlEntryCurrencyOne =[SELECT rate__c, currency__c 
                                    FROM Rate_Code__c WHERE currency__c =:defaultCurrency];
             
             noBitcoinValue = entryValueTwo * soqlEntryCurrencyTwo.RateVsBitcoin__c;
             entryValueOne  = noBitcoinValue * soqlEntryCurrencyOne.rate__c.setscale(3); 
        }
          
        /*
         * If both currencies entries are equal, set both to same values
	    */
         else if((secundaryCurrency == defaultCurrency ) && (defaultCurrency == secundaryCurrency ))
            {
                 entryValueTwo = entryValueTwo;
                 entryValueOne = entryValueTwo;
            }

        
             return null;
    }
            
}