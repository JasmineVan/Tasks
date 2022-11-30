
#Region Rarus
// Функция обработчик "ПолучитьСвойстваСчета" 
//
Function GetAccountProperties(Account) Export

	AccountData = New Structure;

	If TypeOf(Account) = Type("ChartOfAccountsRef.fmBudgeting") Then
		AccountData.Insert("Ref"                         , Account.Ref);
		AccountData.Insert("Description"                   , Account.Description);
		AccountData.Insert("Code"                            , Account.Code);
		AccountData.Insert("Parent"                       , Account.Parent);
		AccountData.Insert("EnglishDescription"         , Account.EnglishDescription);
		AccountData.Insert("Type"                            , Account.Type);
		AccountData.Insert("OffBalance"                   , Account.OffBalance);
		AccountData.Insert("DenyUsingInEntries", Account.DenyUsingInEntries);
		AccountData.Insert("Currency"                       , Account.Currency);
		AccountData.Insert("FinancialResults"            , Account.FinancialResults);
		AccountData.Insert("AccountingByProjects"                 , Account.AccountingByProjects);
		AccountData.Insert("ExtDimensionCount"             , Account.ExtDimensionTypes.Count());

		MaxExtDimensionCount = GetMaxExtDimensionCount();
		For Index = 1 To MaxExtDimensionCount Do
			If Index <= Account.ExtDimensionTypes.Count() Then
				AccountData.Insert("ExtDimensionType" + Index,                   Account.ExtDimensionTypes[Index - 1].ExtDimensionType);
				AccountData.Insert("ExtDimensionType" + Index + "Description",  String(Account.ExtDimensionTypes[Index - 1].ExtDimensionType));
				AccountData.Insert("ExtDimensionType" + Index + "ValueType",   Account.ExtDimensionTypes[Index - 1].ExtDimensionType.ValueType);
				AccountData.Insert("ExtDimensionType" + Index + "Sum",      Account.ExtDimensionTypes[Index - 1].Sum);
				AccountData.Insert("ExtDimensionType" + Index + "TurnoversOnly", Account.ExtDimensionTypes[Index - 1].TurnoversOnly);
			Else
				AccountData.Insert("ExtDimensionType" + Index,                   Undefined);
				AccountData.Insert("ExtDimensionType" + Index + "Description",  Undefined);
				AccountData.Insert("ExtDimensionType" + Index + "ValueType",   Undefined);
				AccountData.Insert("ExtDimensionType" + Index + "Sum",      False);
				AccountData.Insert("ExtDimensionType" + Index + "TurnoversOnly", False);
			EndIf;
		EndDo;
	Else
		AccountData.Insert("Ref"                         , ChartsOfAccounts.fmBudgeting.EmptyRef());
		AccountData.Insert("Description"                   , "");
		AccountData.Insert("Code"                            , "");
		AccountData.Insert("Parent"                       , ChartsOfAccounts.fmBudgeting.EmptyRef());
		AccountData.Insert("Description"                   , "");
		AccountData.Insert("Type"                            , Undefined);
		AccountData.Insert("OffBalance"                   , False);
		AccountData.Insert("DenyUsingInEntries", True);
		AccountData.Insert("Currency"                       , True);
		AccountData.Insert("AccountingByProjects"                 , False);
		AccountData.Insert("FinancialResults"           , False);
		AccountData.Insert("ExtDimensionCount"             , 0);
	EndIf;

	Return AccountData;

EndFunction

// Функция обработчик "ПолучитьМаксКоличествоСубконто" 
//
Function GetMaxExtDimensionCount() Export

	Return Metadata.ChartsOfAccounts.fmBudgeting.MaxExtDimensionCount;

EndFunction

Function AccountsInHierarchy(AccountGroup) Export	
	If NOT ValueIsFilled(AccountGroup) Then
		Return New FixedArray(New Array);
	EndIf;
	
	Query = New Query;
	Query.SetParameter("AccountGroup", AccountGroup);
	Query.Text =
	"SELECT
	|	fmBudgeting.Ref AS Account
	|FROM
	|	ChartOfAccounts.fmBudgeting AS fmBudgeting
	|WHERE
	|	fmBudgeting.Ref IN HIERARCHY(&AccountGroup)";
	Subaccounts = Query.Execute().Unload().UnloadColumn("Account");
	
	Return New FixedArray(Subaccounts);

EndFunction
#EndRegion

