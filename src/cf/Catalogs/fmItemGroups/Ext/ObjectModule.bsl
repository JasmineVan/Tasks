
#If Server OR ThickClientOrdinaryApplication OR ExternalConnection Then

Procedure Filling(FillingData, FillingText, StandardProcessing)
	ThisObject.ItemType = Enums.fmBudgetOperationTypes.IncomesAndExpenses;
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckingAttributes)
	
	Query = New Query;
	Query.Text = "SELECT
	               |	fmIncomesAndExpensesItems.{fm}AnalyticsType1 AS AnalyticsType1,
	               |	fmIncomesAndExpensesItems.{fm}AnalyticsType2 AS AnalyticsType2,
	               |	fmIncomesAndExpensesItems.{fm}AnalyticsType3 AS AnalyticsType3
	               |FROM
	               |	Catalog.fmIncomesAndExpensesItems AS fmIncomesAndExpensesItems
	               |WHERE
	               |	fmIncomesAndExpensesItems.Ref IN (&ItemsList)
	               |GROUP BY
	               |	fmIncomesAndExpensesItems.{fm}AnalyticsType1,
	               |	fmIncomesAndExpensesItems.{fm}AnalyticsType2,
	               |	fmIncomesAndExpensesItems.{fm}AnalyticsType3";
	If ItemType = Enums.fmBudgetOperationTypes.Cashflows Then
		Query.Text = StrReplace(Query.Text,"{fm}","fm");
		Query.Text = StrReplace(Query.Text,"fmIncomesAndExpensesItems","fmCashflowItems");
	ElsIf ItemType = Enums.fmBudgetOperationTypes.IncomesAndExpenses Then
		Query.Text = StrReplace(Query.Text,"{fm}","");
	EndIf;
	Query.SetParameter("ItemsList", Items.UnloadColumn("Item"));
	Result = Query.Execute().Unload();
	If Result.Count()>1 Then
		CommonClientServer.MessageToUser(NStr("en='Group items have different dimensions';ru='В статьях группы есть различные аналитики'"),,,,Cancel);
	EndIf;
	
EndProcedure

#EndIf
