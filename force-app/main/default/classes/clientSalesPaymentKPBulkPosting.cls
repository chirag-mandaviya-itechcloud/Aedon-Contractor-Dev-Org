global with sharing class clientSalesPaymentKPBulkPosting {
	global static Boolean isErrorReturn{get;set;}
    global static String errorMessageReturn{get;set;}
    global Date paymentDate { get; set; }
    global String bankAccount { get; set; }
    global String paymentDescription { get; set; }
     global Boolean isPaymentByPass { get; set; }
    
    global string spBulkPosting(List<Client_Sales_Invoice_Header__c> csihList, Date selectedDate, String selectedPicklistValue,String selectedPaymentDescription, Boolean isPaymentDirectly){
        paymentDate = selectedDate; 
        bankAccount = selectedPicklistValue;
        paymentDescription = selectedPaymentDescription;
        isPaymentByPass = isPaymentDirectly;
        System.debug('isPaymentByPass@@'+isPaymentByPass);
    	if(csihList.size() > 0){ 
            
            Client_Sales_Payment_Header__c sph = new Client_Sales_Payment_Header__c();
            sph.Client_Sales_Invoice_Header__c = csihList[0].Id;
            sph.CL_Amount__c =csihList[0].CL_Amount_Due__c;
            sph.CL_Payment_Date__c = paymentDate;
            sph.CL_Payment_Reference__c = paymentDescription;
            sph.CL_Nominal_Code__c = bankAccount;
            sph.Bypass_Client_Ledger__c = isPaymentByPass;
            List<Client_Sales_Payment_Header__c> headerPaymentStatusUpdateList = new List<Client_Sales_Payment_Header__c>{sph};
            sph = (Client_Sales_Payment_Header__c)aed0n7.aedonAppExUtils.aedonInsert(headerPaymentStatusUpdateList)[0];
            System.debug('sph@@'+sph);
        	errorMessageReturn = clientSalesPaymentController.postClientSalesPayment(csihList[0].Id);
        }  
    return errorMessageReturn;       
    }
}