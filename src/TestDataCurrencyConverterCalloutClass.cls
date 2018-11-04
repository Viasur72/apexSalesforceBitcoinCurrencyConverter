/*********************************************************************************************************
    Apex Class Name : TestDataCurrencyConverterCalloutClass
    Created By  : Carlos Naranjo (carlos.naranjo@ccloudonline.nl)
    Description : Test Data Factory class for CurrencyConverteCalloutClassTest
*********************************************************************************************************/
@isTest
public class TestDataCurrencyConverterCalloutClass
{
    // Rate__Code__c records allready inserted 
    public static List<Rate_Code__c> TestRateCodeRecordsInserted()
    {
       // Becasue we are not receiving a big ammount of records
       // we inserted a small number of Rate Code records for our test
       List<Rate_Code__c> rcList = new List<Rate_Code__c>();  
       
       Rate_Code__c afghan = new Rate_Code__c(name ='Afghan Afghani',
                                               name__c     = 'Afghan Afghani',
                                               rate__c     = 494.79893,
                                               code__c     = 'AFN',
                                               currency__c = 'Afghan Afghani (AFN)');
       rcList.add(afghan); 
        
       Rate_Code__c bitcoin = new Rate_Code__c(name ='Bitcoin',
                                                name__c     = 'Bitcoin',
                                                rate__c     =  1,
                                                code__c     = 'BTC',
                                                currency__c = 'Bitcoin (BTC)');
       rcList.add(bitcoin); 
      
       Rate_Code__c usDollar = new Rate_Code__c(name ='US Dollar',
                                                name__c     = 'US Dollar',
                                                rate__c     =  6.528,
                                                code__c     = 'USD',
                                                currency__c = 'US Dollar (USD)');
       rcList.add(usDollar); 
        
       
       Rate_Code__c dong = new Rate_Code__c(name ='Vietnamese Dong',
                                             name__c     = 'Vietnamese Dong',
                                             rate__c     =  151.737028,
                                             code__c     = 'VND',
                                             currency__c = 'Vietnamese Dong (VND)');
       rcList.add(dong);
                
        
       insert rcList;  
        
       return rcList;
    }
}