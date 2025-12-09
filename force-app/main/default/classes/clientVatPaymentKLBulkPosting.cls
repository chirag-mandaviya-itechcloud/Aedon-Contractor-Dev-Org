global with sharing class clientVatPaymentKLBulkPosting {
	global static Boolean isErrorReturn{get;set;}
    global static String errorMessageReturn{get;set;}
    global Date paymentDate { get; set; }
    global String fromBankAccount { get; set; }
    global String toBankAccount { get; set; }
    global String paymentDescription { get; set; }
    global String journalDescription { get; set; }

    global string klBulkPosting(List<aedCn5__VAT_Payment__c> vpList, Date selectedDate, String selectedFromBankAccount, String selectedToBankAccount, String selectedPaymentDescription){
        paymentDate = selectedDate; 
        fromBankAccount = selectedFromBankAccount;
        toBankAccount = selectedToBankAccount;
        paymentDescription = selectedPaymentDescription;
        
    	if(vpList.size() > 0){ 
            
            VAT_Payment_Transactions__c vpt = [Select id, Name, Credit__c,aedCn5__VAT_Payment__r.Name, Analysis_1__c, Analysis_2__c, Account__c, aedCn5__CL_Account__c, End_User__c
                                               from VAT_Payment_Transactions__c where aedCn5__VAT_Payment__c =: vpList[0].Id and aedCn5__CL_Nominal_Code__r.aed0n7__Nominal_Account_UID__c =: '9830' WITH SECURITY_ENFORCED LIMIT 1];
            
            
            String userId;
            if(!Test.isRunningTest()) {
                userId = String.valueOf(UserInfo.getUserId()); 
            } else {
                User u = [select Id,Name,Email from User where Email='testuser@gmail.com' WITH SECURITY_ENFORCED];
                userId = u.Id;
            }
            
            aed0n7__User_Company__c userCompany=[Select Id,aed0n7__Current_Logged_In_Company__c,aed0n7__User__c from aed0n7__User_Company__c where aed0n7__User__c=:userId WITH SECURITY_ENFORCED limit 1];
            String compnayId = userCompany.aed0n7__Current_Logged_In_Company__c;
            
        	//KP -> ID --> KI --> all details
        
            aed0n7__Chart_Of_Accounts__c chartAccountDebit1 = [Select Id,Name,aed0n7__Nominal_Account__c,aed0n7__Ledger_Balance__c,aed0n7__Credit__c,aed0n7__Nominal_Code__c from aed0n7__Chart_Of_Accounts__c where aed0n7__Nominal_Account_UID__c='8110' AND aed0n7__Company__c =:userCompany.aed0n7__Current_Logged_In_Company__c WITH SECURITY_ENFORCED limit 1];
            aed0n7__Chart_Of_Accounts__c chartAccountCredit1 = [Select Id,Name,aed0n7__Nominal_Account__c,aed0n7__Ledger_Balance__c,aed0n7__Debit__c,aed0n7__Nominal_Code__c from aed0n7__Chart_Of_Accounts__c where Id=: toBankAccount AND aed0n7__Company__c =:userCompany.aed0n7__Current_Logged_In_Company__c WITH SECURITY_ENFORCED limit 1];
            aed0n7__Chart_Of_Accounts__c chartAccountDebit2 = [Select Id,Name,aed0n7__Nominal_Account__c,aed0n7__Ledger_Balance__c,aed0n7__Credit__c,aed0n7__Nominal_Code__c from aed0n7__Chart_Of_Accounts__c where aed0n7__Nominal_Account_UID__c='9830' AND aed0n7__Company__c =:userCompany.aed0n7__Current_Logged_In_Company__c WITH SECURITY_ENFORCED limit 1];
            aed0n7__Chart_Of_Accounts__c chartAccountCredit2 = [Select Id,Name,aed0n7__Nominal_Account__c,aed0n7__Ledger_Balance__c,aed0n7__Debit__c,aed0n7__Nominal_Code__c from aed0n7__Chart_Of_Accounts__c where aed0n7__Nominal_Account_UID__c='9800' AND aed0n7__Company__c =:userCompany.aed0n7__Current_Logged_In_Company__c WITH SECURITY_ENFORCED limit 1];
            
            if(vpList.size() > 0){ 
                
                aedCn5__Payment_of_the_VAT_Liability__c mjh = new aedCn5__Payment_of_the_VAT_Liability__c();
                mjh.CL_Date__c = paymentDate;
                mjh.Journal_Description__c = vpt.aedCn5__VAT_Payment__r.Name;
                mjh.aedCn5__VAT_Payment__c = vpList[0].Id;
                List<aedCn5__Payment_of_the_VAT_Liability__c> headerKMUpdateList = new List<aedCn5__Payment_of_the_VAT_Liability__c>{mjh};
                mjh = (aedCn5__Payment_of_the_VAT_Liability__c)aed0n7.aedonAppExUtils.aedonInsert(headerKMUpdateList)[0];
                
                List<aedCn5__Payment_of_the_VAT_Liability_Transaction__c> mjList = new List<aedCn5__Payment_of_the_VAT_Liability_Transaction__c>();
                
                aedCn5__Payment_of_the_VAT_Liability_Transaction__c mjtDebit1 = new aedCn5__Payment_of_the_VAT_Liability_Transaction__c();
                mjtDebit1.aedCn5__Payment_of_the_VAT_Liability__c = mjh.Id;
                mjtDebit1.CL_Nominal_Code__c = chartAccountDebit1.Id;
                mjtDebit1.Debit__c = vpt.Credit__c;
                mjtDebit1.Analysis_1__c = vpt.Analysis_1__c;
                mjtDebit1.Analysis_2__c = vpt.Analysis_2__c;
                mjtDebit1.Account__c = vpt.Account__c;
                mjtDebit1.CL_Account__c = vpt.aedCn5__CL_Account__c;
                mjtDebit1.End_User__c = vpt.End_User__c;
                mjtDebit1.aedCn5__From_Bank_Account__c = fromBankAccount;
                mjList.add(mjtDebit1);
                
                aedCn5__Payment_of_the_VAT_Liability_Transaction__c mjtCredit1 = new aedCn5__Payment_of_the_VAT_Liability_Transaction__c();
                mjtCredit1.aedCn5__Payment_of_the_VAT_Liability__c = mjh.Id;
                mjtCredit1.CL_Nominal_Code__c = chartAccountCredit1.Id;
                mjtCredit1.Credit__c = vpt.Credit__c;
                mjtCredit1.Analysis_1__c = vpt.Analysis_1__c;
                mjtCredit1.Analysis_2__c = vpt.Analysis_2__c;
                mjtCredit1.Account__c = vpt.Account__c;
                mjtCredit1.CL_Account__c = vpt.aedCn5__CL_Account__c;
                mjtCredit1.End_User__c = vpt.End_User__c;
                mjtCredit1.aedCn5__From_Bank_Account__c = fromBankAccount;
                mjList.add(mjtCredit1);
                
                aedCn5__Payment_of_the_VAT_Liability_Transaction__c mjtDebit2 = new aedCn5__Payment_of_the_VAT_Liability_Transaction__c();
                mjtDebit2.aedCn5__Payment_of_the_VAT_Liability__c = mjh.Id;
                mjtDebit2.CL_Nominal_Code__c = chartAccountDebit2.Id;
                mjtDebit2.Debit__c = vpt.Credit__c;
                mjtDebit2.Analysis_1__c = vpt.Analysis_1__c;
                mjtDebit2.Analysis_2__c = vpt.Analysis_2__c;
                mjtDebit2.Account__c = vpt.Account__c;
                mjtDebit2.CL_Account__c = vpt.aedCn5__CL_Account__c;
                mjtDebit2.End_User__c = vpt.End_User__c;
                mjtDebit2.aedCn5__From_Bank_Account__c = fromBankAccount;
                mjList.add(mjtDebit2);
                
                aedCn5__Payment_of_the_VAT_Liability_Transaction__c mjtCredit2 = new aedCn5__Payment_of_the_VAT_Liability_Transaction__c();
                mjtCredit2.aedCn5__Payment_of_the_VAT_Liability__c = mjh.Id;
                mjtCredit2.CL_Nominal_Code__c = chartAccountCredit2.Id;	
                mjtCredit2.Credit__c = vpt.Credit__c;
                mjtCredit2.Analysis_1__c = vpt.Analysis_1__c;
                mjtCredit2.Analysis_2__c = vpt.Analysis_2__c;
                mjtCredit2.Account__c = vpt.Account__c;
                mjtCredit2.CL_Account__c = vpt.aedCn5__CL_Account__c;
                mjtCredit2.End_User__c = vpt.End_User__c;
                mjtCredit2.aedCn5__From_Bank_Account__c = fromBankAccount;
                mjList.add(mjtCredit2);
                
                mjList = aed0n7.aedonAppExUtils.aedonInsert(mjList); 
            }  
        }
        return errorMessageReturn;
    }
}