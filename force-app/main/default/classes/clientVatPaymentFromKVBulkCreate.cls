public class clientVatPaymentFromKVBulkCreate {
    
    public class RowWrapper {
        public aedCn5__VAT_Payment__c record { get; set; }
        public Decimal userAmount { get; set; }
        public Decimal amountHeldOnAccount { get; set; } 
        
        public RowWrapper(aedCn5__VAT_Payment__c rec) {
            record = rec;
            userAmount = 0;
            amountHeldOnAccount = 0;
        }
    }
    
    public List<RowWrapper> wrapperList { get; set; }
    
    public List<aedCn5__VAT_Payment__c> siList { get; set; }
    public Boolean isErrorReturn { get; set; }
    public String errorMessageReturn { get; set; }
    public integer siCount { get; set; }
    public ApexPages.StandardSetController stdCtrl;
    
    public Date selectedDate { get; set; }
    public String selectedFromBankAccount { get; set; }		// new from bank account
    public String selectedToBankAccount { get; set; }		// new to bank account
    public String selectedJournalDescription { get; set; }
    public Map<Id, aed0n7__Chart_Of_Accounts__c> bankAccountMap { get; set; }
    
    public List<SelectOption> getItems() {
        List<SelectOption> options = new List<SelectOption>();
        bankAccountMap = new Map<Id, aed0n7__Chart_Of_Accounts__c>();
        
        // Fetch the default bank account based on the UID field
        aed0n7__Chart_Of_Accounts__c defaultBankAccount = [
            SELECT Id, Name 
            FROM aed0n7__Chart_Of_Accounts__c 
            WHERE aed0n7__Nominal_Account_UID__c = '7601' 
            LIMIT 1
        ];
        
        // Query all available bank accounts
        List<aed0n7__Chart_Of_Accounts__c> bankAccounts = [
            SELECT Id, Name, aed0n7__Category__c, aedCn5__Client_Ledger__c, aedCn5__Client_Ledger__r.aed0n7__Category__c 
            FROM aed0n7__Chart_Of_Accounts__c 
            WHERE aed0n7__Reporting_Class__c = 'Cash & Bank' 
            WITH SECURITY_ENFORCED
        ];
        
        // Populate the options and set the default value
        for (aed0n7__Chart_Of_Accounts__c c : bankAccounts) {
            options.add(new SelectOption(c.Id, c.Name));
            bankAccountMap.put(c.Id, c);
            
            // If this is the default record, assign it to 
            if (defaultBankAccount != null && c.Id == defaultBankAccount.Id) {
                selectedToBankAccount = c.Id; // default selected to bank acocunt
                selectedFromBankAccount = c.Id;
            }
        }
        
        return options;
    }
    
    public clientVatPaymentFromKVBulkCreate(ApexPages.StandardSetController stdSetController) {
        stdCtrl = stdSetController;
        // String filterID = stdSetController.getfilterId();
        siList = (List<aedCn5__VAT_Payment__c>) stdCtrl.getSelected();
        siCount = siList.size();
        isErrorReturn = false;
        wrapperList = new List<RowWrapper>();
        
        // query vat payments
        List<aedCn5__VAT_Payment__c> vatList = [Select Id, Name, aedCn5__Client_Sales_Invoices__c from aedCn5__VAT_Payment__c where Id IN: siList WITH SECURITY_ENFORCED];       
        System.debug('vatList: '+ vatList);
        
        // collect invoiceIds
        Set<Id> invoiceIds = new Set<Id>();
        for (aedCn5__VAT_Payment__c vat : vatList) {
            if (vat.aedCn5__Client_Sales_Invoices__c != null) {
                invoiceIds.add(vat.aedCn5__Client_Sales_Invoices__c); 
            }
            wrapperList.add(new RowWrapper(vat));
        }
        System.debug('invoiceIds: '+ invoiceIds);
        
        // query sales invoice and get account Ids
        Map<Id, aedCn5__Client_Sales_Invoice_Header__c> invoiceMap = new Map<Id, aedCn5__Client_Sales_Invoice_Header__c>();
        List<aedCn5__Client_Sales_Invoice_Header__c> invoiceList = [SELECT Id, aedCn5__CL_Account__c FROM aedCn5__Client_Sales_Invoice_Header__c WHERE Id IN :invoiceIds WITH SECURITY_ENFORCED];
        
        for (aedCn5__Client_Sales_Invoice_Header__c sih : invoiceList) {
            if (sih.aedCn5__CL_Account__c != null) {
                invoiceMap.put(sih.Id, sih);
            }
        }
        System.debug('Invoice Map: ' + invoiceMap);
        
        // collect account IDs
        Set<Id> accIds = new Set<Id>();
        for (RowWrapper wrap : wrapperList) {
            Id invId = wrap.record.aedCn5__Client_Sales_Invoices__c;
            
            if (invoiceMap.containsKey(invId)) {
                Id accId = invoiceMap.get(invId).aedCn5__CL_Account__c;
                if (accId != null) {
                    accIds.add(accId);
                }
            }
        }
        System.debug('Account Ids: ' + accIds);
        
        // getting ledger entries and calculate the amount
        List<aed0n7__Ledger_Entry__c> leList = [
            SELECT Id, aed0n7__Debit__c, aed0n7__Credit__c, 
            aedCn5__Client_Account__c, aed0n7__Nominal_Code_Name__c
            FROM aed0n7__Ledger_Entry__c
            WHERE aedCn5__Client_Account__c IN :accIds
            AND aed0n7__Nominal_Code_Name__c LIKE '%Company%'
            WITH SECURITY_ENFORCED
        ];
        
        System.debug('leList: '+ leList);
        
        Map<Id, Decimal> accountHeldAmountMap = new Map<Id, Decimal>();
        
        for (aed0n7__Ledger_Entry__c le : leList) {
            Id accId = le.aedCn5__Client_Account__c;
            Decimal current = accountHeldAmountMap.get(accId);
            Decimal debit = (le.aed0n7__Debit__c == null ? 0 : le.aed0n7__Debit__c);
            Decimal credit = (le.aed0n7__Credit__c == null ? 0 : le.aed0n7__Credit__c);
            accountHeldAmountMap.put(accId, current + (debit - credit));
        }
        
        System.debug('Account Held Amount Map: ' + accountHeldAmountMap);
        
        // Assign each wrapper its calculated amount
        for (RowWrapper wrap : wrapperList) {
            Id invId = wrap.record.aedCn5__Client_Sales_Invoices__c;
            
            if (invoiceMap.containsKey(invId)) {
                Id accId = invoiceMap.get(invId).aedCn5__CL_Account__c;
                wrap.amountHeldOnAccount = accountHeldAmountMap.containsKey(accId) ? accountHeldAmountMap.get(accId) : 0;
            }
        }
        
        siCount = wrapperList.size();
        
        System.debug('wrapperList size: '+ wrapperList.size());
        System.debug('wrapperList: '+ wrapperList);
    }
    
    public void generateKT(){
        isErrorReturn = false;
        errorMessageReturn = null;
        
        // condition for amount exceed or not.
        for (RowWrapper wrap : wrapperList) {
            Decimal ua = (wrap.userAmount == null) ? 0 : wrap.userAmount;
            if (ua > wrap.amountHeldOnAccount) {
                isErrorReturn = true;
                errorMessageReturn = 'Entered amount (' + String.valueOf(ua) + ') cannot exceed available amount (' + String.valueOf(wrap.amountHeldOnAccount) + ')';
                return;
            }
        }
        
        // Validation for from account selection condition
        aed0n7__Chart_Of_Accounts__c fromAcc = bankAccountMap.get(selectedFromBankAccount);
        if (fromAcc != null) {
            Boolean isChildClient  = (fromAcc.aed0n7__Category__c == 'Client');
            Boolean isParentClient = false;
            if (fromAcc.aedCn5__Client_Ledger__c != null) {
                aed0n7__Chart_Of_Accounts__c parentAcc = bankAccountMap.get(fromAcc.aedCn5__Client_Ledger__c);
                if (parentAcc != null && parentAcc.aed0n7__Category__c == 'Client') {
                    isParentClient = true;
                }
            }
            if (isChildClient && isParentClient) {
                isErrorReturn = true;
                errorMessageReturn = 'Selected From Account cannot be Client when its parent account is also Client.';
                return;
            }
        }
        
        // main logic
        List<aedCn5__VAT_Payment__c> kiObjList = [Select id,Name from aedCn5__VAT_Payment__c where Id IN: siList AND CL_Posting_Status__c =: 'Posted'  WITH SECURITY_ENFORCED];
        if(kiObjList.size() > 0){
            clientVatPaymentKLBatch batchObj1 = new clientVatPaymentKLBatch(kiObjList,selectedDate,selectedFromBankAccount,selectedToBankAccount,selectedJournalDescription);
            Id jobId1 = Database.executeBatch(batchObj1, 1);
        }
        return;
    }
}