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
	
	AvailableTypes = FormAttributeToValue("Object").Metadata().Attributes.RespondentsType.Type.Types();
	
	For each AvailableType In AvailableTypes Do
		
		TypesArray = New Array;
		TypesArray.Add(AvailableType);
		Items.RespondentsType.ChoiceList.Add(New TypeDescription(TypesArray),String(AvailableType));
		
	EndDo;
	
	UseExternalUsers = GetFunctionalOption("UseExternalUsers");
	If Object.Ref.IsEmpty() AND Not UseExternalUsers Then
		Object.RespondentsType = New ("CatalogRef.Users");
	EndIf; 
	Items.RespondentsType.Visible = UseExternalUsers;
	
	If Object.RespondentsType = Undefined Then
		If AvailableTypes.Count() > 0 Then
			 Object.RespondentsType = New(AvailableTypes[0]);
			 RespondentsType = Items.RespondentsType.ChoiceList[0].Value;
		 EndIf;
	 Else
		TypesArray = New Array;
		TypesArray.Add(TypeOf(Object.RespondentsType));
		RespondentsType = New TypeDescription(TypesArray);
	EndIf;
	
	If Object.Ref.IsEmpty() Then
		OnCreatReadAtServer();
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	If Common.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommands = Common.CommonModule("AttachableCommands");
		ModuleAttachableCommands.OnCreateAtServer(ThisObject);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	ProcessRespondentTypeChange();
	AvailabilityControl();
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.StartCommandUpdate(ThisObject);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If (Object.StartDate > Object.EndDate) AND (Object.EndDate <> Date(1,1,1)) Then
	
		CommonClient.MessageToUser(NStr("ru = 'Дата начала не может быть больше чем дата окончания.'; en = 'The start date cannot be greater than end date.'; pl = 'The start date cannot be greater than end date.';de = 'The start date cannot be greater than end date.';ro = 'The start date cannot be greater than end date.';tr = 'The start date cannot be greater than end date.'; es_ES = 'The start date cannot be greater than end date.'"),,"Object.StartDate");
		Cancel = True;
	
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "SelectRespondents" Then
		
		For each ArrayElement In Parameter.SelectedRespondents Do
			
			If Object.Respondents.FindRows(New Structure("Respondent", ArrayElement)).Count() = 0 Then
				
				NewRow = Object.Respondents.Add();
				NewRow.Respondent = ArrayElement;
				
			EndIf;
			
		EndDo;
		Modified = True;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	Items.CommentPage.Picture = CommonClientServer.CommentPicture(Object.Comment);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	OnCreatReadAtServer();
	
	// StandardSubsystems.AttachableCommands
	If Common.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClientServer = Common.CommonModule("AttachableCommandsClientServer");
		ModuleAttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure RespondentsTypeOnChange(Item)
	
	ProcessRespondentTypeChange();
	AvailabilityControl();
	
EndProcedure

&AtClient
Procedure FreeFormSurveyOnChange(Item)
	
	AvailabilityControl();
	If Object.Respondents.Count() > 0 Then
		Object.Respondents.Clear();
	EndIf;
	
EndProcedure

#EndRegion

#Region RespondentsFormTableItemsEventHandlers

&AtClient
Procedure RespondentsRespondentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CurrentData = Items.Respondents.CurrentData;
	
	Value                 = CurrentData.Respondent;
	CurrentData.Respondent = RespondentsType.AdjustValue(Value);
	Item.ChooseType      = False;
	
EndProcedure

&AtClient
Procedure RespondentsOnStartEditing(Item, NewRow, Clone)
	
	CurrentData = Items.Respondents.CurrentData;
	
	Value                  = CurrentData.Respondent;
	CurrentData.Respondent  = RespondentsType.AdjustValue(Value);
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

// Opens the respondents pick form.
&AtClient
Procedure PickRespondents(Command)
	
	FilterStructure = New Structure;
	FilterStructure.Insert("RespondentType",Object.RespondentsType);
	FilterStructure.Insert("Respondents",Object.Respondents);
	
	OpenForm("Document.PollPurpose.Form.FormSelectRespondents",FilterStructure,ThisObject);
	
EndProcedure

#EndRegion

#Region Private

// Processes respondent type change.
&AtClient
Procedure ProcessRespondentTypeChange()
	
	Items.RespondentsRespondent.TypeRestriction  = RespondentsType;
	Items.RespondentsRespondent.AvailableTypes	= RespondentsType;
	
	If Object.RespondentsType <> Undefined Then
		Object.RespondentsType = New(RespondentsType.Types()[0]);
	EndIf;
	
	For each RespondentsRow In Object.Respondents Do
		
		If Not RespondentsType.ContainsType(TypeOf(RespondentsRow.Respondent)) Then
			Object.Respondents.Clear();
			Items.Respondents.Refresh();
		EndIf;
		
		Break;
		
	EndDo;
	
EndProcedure

// Controls form items availability.
&AtClient
Procedure AvailabilityControl()

	Items.Respondents.ReadOnly           = Object.FreeSurvey;
	Items.RespondentsSelect.Enabled = NOT Object.FreeSurvey;

EndProcedure

&AtServer
Procedure OnCreatReadAtServer()

	Items.CommentPage.Picture = CommonClientServer.CommentPicture(Object.Comment);

EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
	ModuleAttachableCommandsClient.ExecuteCommand(ThisObject, Command, Object);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result)
	ModuleAttachableCommands = Common.CommonModule("AttachableCommands");
	ModuleAttachableCommands.ExecuteCommand(ThisObject, Context, Object, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	ModuleAttachableCommandsClientServer = CommonClient.CommonModule("AttachableCommandsClientServer");
	ModuleAttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion
