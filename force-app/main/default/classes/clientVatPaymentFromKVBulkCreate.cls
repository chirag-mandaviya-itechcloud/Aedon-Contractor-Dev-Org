public class clientVatPaymentFromKVBulkCreate {

    public List<aedCn5__VAT_Payment__c> siList { get; set; }
    public Boolean isErrorReturn {get;set;}
    public static String errorMessageReturn{get;set;}
    public static integer siCount {get;set;}
    public ApexPages.StandardSetController stdCtrl;

    public Date selectedDate { get; set; }
    public String selectedPicklistValue { get; set; }
 	public String selectedJournalDescription { get; set; }


    public List<SelectOption> getItems() {
        List<SelectOption> options = new List<SelectOption>();

        // Fetch the default bank account based on the UID field
        aed0n7__Chart_Of_Accounts__c defaultBankAccount = [
            SELECT Id, Name
            FROM aed0n7__Chart_Of_Accounts__c
            WHERE aed0n7__Nominal_Account_UID__c = '7601'
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

    public clientVatPaymentFromKVBulkCreate(ApexPages.StandardSetController stdSetController) {
        stdCtrl = stdSetController;
        String filterID = stdSetController.getfilterId();
        siList = (List<aedCn5__VAT_Payment__c>) stdSetController.getSelected();
        siCount = siList.size();
        isErrorReturn = false;

        List<aedCn5__VAT_Payment__c> paysheetObjList = [Select id,Name from aedCn5__VAT_Payment__c where Id IN: siList WITH SECURITY_ENFORCED];

    }

    public string generateKT(){
       List<aedCn5__VAT_Payment__c> kiObjList = [Select id,Name from aedCn5__VAT_Payment__c where Id IN: siList AND CL_Posting_Status__c =: 'Posted'  WITH SECURITY_ENFORCED];


       if(kiObjList.size() > 0){
            clientVatPaymentKLBatch batchObj1 = new clientVatPaymentKLBatch(kiObjList,selectedDate,selectedPicklistValue,selectedJournalDescription);
            Id jobId1 = Database.executeBatch(batchObj1, 1);
       }
       return errorMessageReturn;
    }
}
