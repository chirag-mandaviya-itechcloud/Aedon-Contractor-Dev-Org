public with sharing class clientSalesPaymentKPBulkPost {
    
    public List<Client_Sales_Invoice_Header__c> csihList { get; set; }
    public Boolean isErrorReturn {get;set;}
    public static String errorMessageReturn{get;set;}
    public static integer paymentsCount {get;set;}
    public ApexPages.StandardSetController stdCtrl;
    
    public Date selectedDate { get; set; }
    public String selectedPicklistValue { get; set; }
    public String selectedPaymentDescription { get; set; }
    public Decimal totalAmountDue { get; set; }
    public Boolean isPaymentDirectly { get; set; }
    
    public List<SelectOption> getItems() {
        List<SelectOption> options = new List<SelectOption>();
        
        // Fetch the default bank account based on the UID field
        aed0n7__Chart_Of_Accounts__c defaultBankAccount = [
            SELECT Id, Name 
            FROM aed0n7__Chart_Of_Accounts__c 
            WHERE aed0n7__Nominal_Account_UID__c = '7600' 
            LIMIT 1
        ];
        
        // Query all available bank accounts
        List<aed0n7__Chart_Of_Accounts__c> bankAccounts = [
            SELECT Id, Name 
            FROM aed0n7__Chart_Of_Accounts__c 
            WHERE aed0n7__Reporting_Class__c = 'Cash & Bank' 
            WITH SECURITY_ENFORCED
        ];
        
        // Populate the options and set the default value
        for (aed0n7__Chart_Of_Accounts__c c : bankAccounts) {
            options.add(new SelectOption(c.Id, c.Name));
            
            // If this is the default record, assign it to selectedPicklistValue
            if (defaultBankAccount != null && c.Id == defaultBankAccount.Id) {
                selectedPicklistValue = c.Id;
            }
        }
        
        return options;
    }
    
    
    public clientSalesPaymentKPBulkPost(ApexPages.StandardSetController stdSetController) {
        stdCtrl = stdSetController;
        String filterID = stdSetController.getfilterId();
        csihList = (List<Client_Sales_Invoice_Header__c>) stdSetController.getSelected();
        paymentsCount = csihList.size();
        isErrorReturn = false;
        
        totalAmountDue = 0.0;
        
        List<Client_Sales_Invoice_Header__c> csihObjList = [Select id,Name,Client_Account_Lookup__c,Client_Account_Lookup__r.Name, CL_Account__c,CL_Account__r.Name,CL_Account__r.aed0n7__Display_Label_UI1__c,CL_Company__c,CL_Customer_Reference__c,CL_Due_On__c,
                                                            CL_Invoice_Date__c,CL_Currency__c,CL_VAT_Treatment__c,CL_Currency__r.aed0n7__IsBaseCurrency__c,CL_On_Hold_Reason__c,CreatedDate,
                                                            CL_Currency_Exchange_Rate__c,CL_Currency__r.Name,CL_Posting_Status__c,CL_Payment_Status__c,CL_Amount_Due__c,
                                                            CL_Total_Tax_Payable__c,CL_Paid_Amount__c,CL_VAT_Only__c,CL_Email_Sent_Text__c,CL_Source__c,CL_Payment_Method__c,CL_On_Hold__c,CL_Planned_Pay_Date__c,CL_Address__c,
                                                            CL_Account_Code__c,CL_Reason__c from Client_Sales_Invoice_Header__c where Id IN: csihList WITH SECURITY_ENFORCED];
        
        for(Client_Sales_Invoice_Header__c csihObj : csihObjList){
            totalAmountDue += csihObj.CL_Amount_Due__c;
            
            if(csihObj.CL_Posting_Status__c == 'Draft'){
                isErrorReturn = true;
                errorMessageReturn = 'Please choose posted invoices.';
            }
            if(csihObj.CL_Amount_Due__c == 0){
                isErrorReturn = true;
                errorMessageReturn = 'Balance outstanding should be greater than 0.';
            }
        }
    } 
    
    public string bulkPostKP(){
        String errorMessage='';
        
        if(!isErrorReturn){
            List<Client_Sales_Invoice_Header__c> csihObjList = [Select id,Name,Client_Account_Lookup__c,Client_Account_Lookup__r.Name, CL_Account__c,CL_Account__r.Name,CL_Account__r.aed0n7__Display_Label_UI1__c,CL_Company__c,CL_Customer_Reference__c,CL_Due_On__c,
                                                                CL_Invoice_Date__c,CL_Currency__c,CL_VAT_Treatment__c,CL_Currency__r.aed0n7__IsBaseCurrency__c,CL_On_Hold_Reason__c,CreatedDate,
                                                                CL_Currency_Exchange_Rate__c,CL_Currency__r.Name,CL_Posting_Status__c,CL_Payment_Status__c,
                                                                CL_Total_Tax_Payable__c,CL_Paid_Amount__c,CL_VAT_Only__c,CL_Email_Sent_Text__c,CL_Source__c,CL_Payment_Method__c,CL_On_Hold__c,CL_Planned_Pay_Date__c,CL_Address__c,
                                                                CL_Account_Code__c,CL_Reason__c from Client_Sales_Invoice_Header__c where Id IN: csihList and CL_Posting_Status__c = 'Posted' and CL_Amount_Due__c != 0 WITH SECURITY_ENFORCED];
            
            
            
            if(csihObjList.size() > 0){
                clientBulkPostSalesPaymentKPBatch batchObj1 = new clientBulkPostSalesPaymentKPBatch(csihObjList,selectedDate,selectedPicklistValue,selectedPaymentDescription, isPaymentDirectly);
                Id jobId1 = Database.executeBatch(batchObj1, 1);
            }
        }
        return errorMessageReturn;
    }
}