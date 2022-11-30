
#Region ProceduresAndFunctionsOfCommonUse

&AtServer
Procedure RestrictionByTypes() 
	If Object.ItemType = Enums.fmBudgetOperationTypes.Cashflows Then
		TypesArray = New Array;
		TypesArray.Add(Type("CatalogRef.fmCashflowItems"));
		Items.ItemsClosingItems.TypeRestriction = New TypeDescription(TypesArray);
	ElsIf Object.ItemType = Enums.fmBudgetOperationTypes.IncomesAndExpenses Then
		TypesArray = New Array;
		TypesArray.Add(Type("CatalogRef.fmIncomesAndExpensesItems"));
		Items.ItemsClosingItems.TypeRestriction = New TypeDescription(TypesArray);
	EndIf
EndProcedure

#EndRegion

#Region FormItemsEventsHandlers

&AtClient
Procedure BudgetOnChange(Item)
	Object.Items.Clear();
	RestrictionByTypes();
EndProcedure

#EndRegion

#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	RestrictionByTypes();
EndProcedure

#EndRegion
