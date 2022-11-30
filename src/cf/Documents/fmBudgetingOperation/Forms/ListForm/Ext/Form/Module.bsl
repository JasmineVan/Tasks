
&AtClient
Var mParametersStructure;

#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	fmCommonUseServer.SetFilterByMainBalanceUnit(ThisForm);
	
	// en script
	//CanEdit = AccessRight("Edit", Metadata.Documents.fmBudgetingOperation);
	//Items.ListContextMenuChangeSelected.Visible = CanEdit;
	// en script
	
EndProcedure

#EndRegion

#Region EventHandlersOfFormTableItemsList

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Group, Parameter)
	
	Cancel = True;
	ParametersStructure = GetFormParametersStructure("Manually");
	If Copy Then
		ParametersStructure.Insert("CopyingValue", Items.List.CurrentData.Ref);
	EndIf;
	OpenForm("Document.fmBudgetingOperation.ObjectForm", ParametersStructure, ThisForm);

EndProcedure

&AtClient
Procedure ListDragCheck(Item, DragParameters, StandardProcessing, String, Field)
	
	StandardProcessing = False;
	
EndProcedure

#EndRegion

#Region ServiceProceduresAdFunctions

&AtClient
Function GetFormParametersStructure(FillingMethod = "")
	
	ParametersStructure = New Structure;
	
	FillingValues = fmCommonUseServerCall.FillingValuesOfDynamicList(List.SettingsComposer);
		
	Return ParametersStructure;
	
EndFunction


#EndRegion
