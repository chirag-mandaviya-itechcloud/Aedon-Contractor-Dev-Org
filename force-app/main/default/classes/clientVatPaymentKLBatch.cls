global with sharing class clientVatPaymentKLBatch implements Database.Batchable<sObject>,Database.stateful {

    List<aedCn5__VAT_Payment__c> siList = new List<aedCn5__VAT_Payment__c>();
    public Date paymentDate { get; set; }
    public String bankAccount { get; set; }
    public String journalDescription { get; set; }

    Organization org = [SELECT Id,Name FROM Organization where id=:UserInfo.getOrganizationId() limit 1];

    String orgName = org.Name;
    String orgId  = org.Id;

     global  clientVatPaymentKLBatch(List<aedCn5__VAT_Payment__c> csihList, Date selectedDate, String selectedPicklistValue, String selectedJournalDescription) {
        siList = csihList;
        paymentDate = selectedDate;
        bankAccount = selectedPicklistValue;
        journalDescription = selectedJournalDescription;
        initialize();
    }

    global void initialize(){

    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
      String query = 'Select id,Name from aedCn5__VAT_Payment__c Where ID IN:siList ';
      return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<aedCn5__VAT_Payment__c> clientSIList) {

        clientVatPaymentKLBulkPosting KPClass = new clientVatPaymentKLBulkPosting();
        KPClass.klBulkPosting(clientSIList,paymentDate, bankAccount, journalDescription);
    }

    global void finish(Database.BatchableContext BC) {

    }
}
