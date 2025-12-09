global with sharing class clientBulkPostSalesPaymentKPBatch implements Database.Batchable<sObject>,Database.stateful {  
	List<Client_Sales_Invoice_Header__c> clientSalesInvoiceHeaderList = new List<Client_Sales_Invoice_Header__c>();
    public Date paymentDate { get; set; }
    public String fromBankAccount { get; set; }
    public String toBankAccount { get; set; }
    public String paymentDescription { get; set; }
    public Boolean isPaymentByPass { get; set; } 
    
    Organization org = [SELECT Id,Name FROM Organization where id=:UserInfo.getOrganizationId() limit 1];
    
    String orgName = org.Name;
    String orgId  = org.Id; 
    
    global  clientBulkPostSalesPaymentKPBatch(List<Client_Sales_Invoice_Header__c> csihList, Date selectedDate,String selectedFromBankAccount, String selectedToBankAccount,String selectedPaymentDescription, Boolean isPaymentDirectly) {
        clientSalesInvoiceHeaderList = csihList;
        paymentDate = selectedDate; 
        if (isPaymentDirectly == null) {
            isPaymentByPass = false;
        } else {
            isPaymentByPass = isPaymentDirectly;
        } 
        fromBankAccount = selectedFromBankAccount;
        toBankAccount = selectedToBankAccount;
        paymentDescription = selectedPaymentDescription;
        initialize();
    }
    
    global void initialize(){
        
    }
   
    global Database.QueryLocator start(Database.BatchableContext BC) {
      String query = 'Select id,Name,CL_Amount_Due__c,CL_Customer_Reference__c from Client_Sales_Invoice_Header__c Where ID IN:clientSalesInvoiceHeaderList ';   
      return Database.getQueryLocator(query);  
    }
    
    global void execute(Database.BatchableContext BC, List<Client_Sales_Invoice_Header__c> csihList) {	
        clientSalesPaymentKPBulkPosting KPClass = new clientSalesPaymentKPBulkPosting();
        KPClass.spBulkPosting(csihList,paymentDate,fromBankAccount,toBankAccount,paymentDescription, isPaymentByPass);
    }
    
    global void finish(Database.BatchableContext BC) {
     
    }
}