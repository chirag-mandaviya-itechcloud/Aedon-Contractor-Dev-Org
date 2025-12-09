public class clientVATPaymentFromKIBulkCreate {
	
    public static List<Client_Sales_Invoice_Header__c> csihList { get; set; }
    public static Boolean isErrorReturn{get;set;}
    public static String errorMessageReturn{get;set;}
    public static integer siCount {get;set;}
    
    public clientVATPaymentFromKIBulkCreate(ApexPages.StandardSetController stdSetController) {
        csihList = (List<Client_Sales_Invoice_Header__c>) stdSetController.getSelected();
        siCount = csihList.size();
    }
     
    public string generateKV(){
       List<Client_Sales_Invoice_Header__c> kiObjList = [Select id,Name from Client_Sales_Invoice_Header__c where Id IN: csihList AND CL_Posting_Status__c =: 'Posted' AND Exclude_from_VAT_Crystallisation__c = false WITH SECURITY_ENFORCED];
       
       
       if(kiObjList.size() > 0){
            clientVATPaymentFromKIBatch batchObj1 = new clientVATPaymentFromKIBatch(kiObjList);
            Id jobId1 = Database.executeBatch(batchObj1, 1);
       }
       return errorMessageReturn;
    }
}