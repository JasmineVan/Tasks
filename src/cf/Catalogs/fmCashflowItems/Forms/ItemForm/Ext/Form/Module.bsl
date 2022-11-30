
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	//fm rarus begin
	TemporaryModule.OnCreateAtServer(ThisForm);
	fmBudgeting.OnCreateAtServerProcessTemplateEntriesTable(Object, TSAttributes);
	//fm rarus end
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, RecordParameters)
	
	// fm rarus begin
	fmBudgeting.BeforeWriteAtServerProcessTemplateEntriesTable(Object, CurrentObject);
	// fm rarus end
	
EndProcedure

#EndRegion

&AtClient
Procedure EntriesTemplateChooseFromListStart(Item)
	fmBudgetingClientServer.RepresentList(ThisForm, Item);
EndProcedure

&AtClient
Procedure EntriesTemplatesExtDimensionDrOnChange(Item)
	CurrentData = Items.EntriesTemplates.CurrentData;
	AccountExtDimensions = fmBudgeting.GetAccountExtDimension(CurrentData.AccountDr);
	fmBudgetingClientServer.CheckTypesMap(Object,"ExtDimensionDr", AccountExtDimensions, CurrentData, Item.Name);
EndProcedure

&AtClient
Procedure EntriesTemplatesExtDimensionCrOnChange(Item)
	CurrentData = Items.EntriesTemplates.CurrentData;
	AccountExtDimensions = fmBudgeting.GetAccountExtDimension(CurrentData.AccountCr);
	fmBudgetingClientServer.CheckTypesMap(Object,"ExtDimensionCr", AccountExtDimensions, CurrentData, Item.Name);
EndProcedure

&AtClient
Procedure EntriesTemplatesAccountDrOnChange(Item)
	CurRow = Items.EntriesTemplates.CurrentData;
	AnalyticsTypes = fmBudgeting.GetAccountExtDimension(CurRow.AccountDr);
	Index = 1;
	For Each It1 In AnalyticsTypes Do
		If TypeOf(It1.Value) <> Type("Boolean") Then
			CurRow["fmAnalyticsTypeDr"+Index] = It1.Value;
			CurRow["ExtDimensionDr"+Index] = Undefined;
			Index = Index+1;
		EndIf;
	EndDo;
EndProcedure

&AtClient
Procedure EntriesTemplatesAccountCrOnChange(Item)
	CurRow = Items.EntriesTemplates.CurrentData;
	AnalyticsTypes = fmBudgeting.GetAccountExtDimension(CurRow.AccountCr);
	Index = 1;
	For Each It1 In AnalyticsTypes Do
		If TypeOf(It1.Value) <> Type("Boolean") Then
			CurRow["fmAnalyticsTypeCr"+Index] = It1.Value;
			CurRow["ExtDimensionCr"+Index] = Undefined;
			Index = Index+1;
		EndIf;
	EndDo;
EndProcedure

&AtClient
Procedure TypeItemStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure EntriesTemplatesOnStartEdit(Item, NewLine, Copy)
	If NewLine AND NOT Copy Then
		Item.CurrentData.AmountCalculationRatio = 1;
	EndIf;
EndProcedure

&AtClient
Procedure OnActivateCellEntriesTemplates(Item)
	fmBudgetingClientServer.RepresentList(ThisForm, Item);
EndProcedure



