///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Parameters.Property("ChangeInTransaction",    ChangeInTransaction);
	Parameters.Property("ProcessRecursively", ProcessRecursively);
	Parameters.Property("BatchSetting",        BatchSetting);
	Parameters.Property("ObjectsPercentageInBatch", ObjectsPercentageInBatch);
	Parameters.Property("ObjectCountInBatch",   ObjectCountInBatch);
	Parameters.Property("DeveloperMode",     DeveloperMode);
	Parameters.Property("DisableSelectionParameterConnections",     DisableSelectionParameterConnections);
	Parameters.Property("InterruptOnError",     InterruptOnError);
	
	HasDataAdministrationRight = AccessRight("DataAdministration", Metadata);
	WindowOptionsKey = ?(HasDataAdministrationRight, "HasDataAdministrationRight", "NoDataAdministrationRight");
	
	CanShowInternalAttributes = Not Parameters.ContextCall AND HasDataAdministrationRight;
	Items.ShowInternalAttributesGroup.Visible = CanShowInternalAttributes;
	Items.DeveloperMode.Visible = CanShowInternalAttributes;
	Items.DisableSelectionParameterConnections.Visible = CanShowInternalAttributes;
	
	If CanShowInternalAttributes Then
		Parameters.Property("ShowInternalAttributes", ShowInternalAttributes);
	EndIf;
	
	Items.ProcessRecursivelyGroup.Visible = Parameters.ContextCall AND Parameters.IncludeSubordinateItems;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	SetFormItems();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ChangeInTransactionOnChange(Item)
	
	SetFormItems();
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure OK(Command)
	
	SelectionResult = New Structure;
	SelectionResult.Insert("ChangeInTransaction",    ChangeInTransaction);
	SelectionResult.Insert("ProcessRecursively", ProcessRecursively);
	SelectionResult.Insert("BatchSetting",        BatchSetting);
	SelectionResult.Insert("ObjectsPercentageInBatch", ObjectsPercentageInBatch);
	SelectionResult.Insert("ObjectCountInBatch",   ObjectCountInBatch);
	SelectionResult.Insert("InterruptOnError",     ChangeInTransaction Or InterruptOnError);
	SelectionResult.Insert("ShowInternalAttributes", ShowInternalAttributes);
	SelectionResult.Insert("DeveloperMode", DeveloperMode);
	SelectionResult.Insert("DisableSelectionParameterConnections", DisableSelectionParameterConnections);
	
	NotifyChoice(SelectionResult);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SetFormItems()
	
	If ChangeInTransaction Then
		Items.AbortOnErrorGroup.Enabled = False;
	Else
		Items.AbortOnErrorGroup.Enabled = True;
	EndIf;
	
EndProcedure

#EndRegion
