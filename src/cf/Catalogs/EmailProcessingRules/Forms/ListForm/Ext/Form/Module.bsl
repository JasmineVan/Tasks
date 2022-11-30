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
	
	If Parameters.Filter.Property("Owner") Then
		
		If NOT Interactions.UserIsResponsibleForMaintainingFolders(Parameters.Filter.Owner) Then
			
			ReadOnly = True;
			
			Items.FormCommandBar.ChildItems.FormApplyRules.Visible               = False;
			Items.ItemOrderSetup.Visible = False;
			
		EndIf;
		
	Else
		
		Cancel = True;
		
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure ApplyRules(Command)
	
	ClearMessages();
	
	FormParameters = New Structure;
	
	FilterItemsArray = CommonClientServer.FindFilterItemsAndGroups(InteractionsClientServer.DynamicListFilter(List), "Owner");
	If FilterItemsArray.Count() > 0 AND FilterItemsArray[0].Use
		AND ValueIsFilled(FilterItemsArray[0].RightValue) Then
		FormParameters.Insert("Account",FilterItemsArray[0].RightValue);
	Else
		CommonClient.MessageToUser(NStr("ru = 'Не установлен отбор по владельцу(учетной записи) правил.'; en = 'Filter by the owner (of account) of rules is not set.'; pl = 'Filter by the owner (of account) of rules is not set.';de = 'Filter by the owner (of account) of rules is not set.';ro = 'Filter by the owner (of account) of rules is not set.';tr = 'Filter by the owner (of account) of rules is not set.'; es_ES = 'Filter by the owner (of account) of rules is not set.'"));
		Return;
	EndIf;
	
	OpenForm("Catalog.EmailProcessingRules.Form.RulesApplication", FormParameters, ThisObject);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.List);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result)
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.List, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion
