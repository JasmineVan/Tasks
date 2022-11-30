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
	
	If TypeOf(Parameters.RefsArray) <> Type("Array") 
		Or Parameters.RefsArray.Count() = 0 Then 
		
		Raise NStr("ru = 'Должна быть хоть одна ссылка указана.'; en = 'At least one reference is required.'; pl = 'At least one reference is required.';de = 'At least one reference is required.';ro = 'At least one reference is required.';tr = 'At least one reference is required.'; es_ES = 'At least one reference is required.'");
	EndIf;
	
	PortalAuthenticationDataSaved = PortalAuthenticationDataSaved();
	CanImportFromPortal = AddInsInternal.ImportFromPortalIsAvailable();
	
	NoteText = "";
	PromptToUpdate = False;
	For Each Ref In Parameters.RefsArray Do 
		Attributes = Common.ObjectAttributesValues(Ref, "ID, Version, UpdateFrom1CITSPortal");
		NoteText = NoteText
			+ AddInsInternal.AddInPresentation(Attributes.ID, Attributes. Version)
			+ ?(Attributes.UpdateFrom1CITSPortal, "", " - " + NStr("ru = 'обновление отключено'; en = 'Update disabled'; pl = 'Update disabled';de = 'Update disabled';ro = 'Update disabled';tr = 'Update disabled'; es_ES = 'Update disabled'") + ".")
			+ Chars.LF;
		
		PromptToUpdate = PromptToUpdate Or Attributes.UpdateFrom1CITSPortal;
		If Attributes.UpdateFrom1CITSPortal Then 
			RefsArray.Add(Ref);
		EndIf;
	EndDo;
	
	If PromptToUpdate Then 
		
		Items.NoteDecoration.Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = '%1
			           |Проверить обновление компоненты?'; 
			           |en = '%1
			           |Check the add-in update?'; 
			           |pl = '%1
			           |Check the add-in update?';
			           |de = '%1
			           |Check the add-in update?';
			           |ro = '%1
			           |Check the add-in update?';
			           |tr = '%1
			           |Check the add-in update?'; 
			           |es_ES = '%1
			           |Check the add-in update?'"),
			NoteText);
			
		Items.EnableOnlineSupport.Visible = Not PortalAuthenticationDataSaved;
		Items.Close.Visible = False;
		
	Else 
		Items.NoteDecoration.Title = NoteText;
		Items.EnableOnlineSupport.Visible = False;
		Items.Load.Visible = False;
		Items.Cancel.Visible = False;
		Items.Close.Visible = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Not CanImportFromPortal Then
		Cancel = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure EnableOnlineSupport(Command = Undefined)
	
	If CommonClient.SubsystemExists("OnlineUserSupport") Then
		ModuleOnlineUserSupportClient = CommonClient.CommonModule("OnlineUserSupportClient");
		Notification = New NotifyDescription("AfterEnableOnlineSupport", ThisObject);
		ModuleOnlineUserSupportClient.ConnectOnlineUserSupport(Notification, ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure Import(Command)
	
	If Not PortalAuthenticationDataSaved Then 
		EnableOnlineSupport();
		Return;
	EndIf;
	
	Items.Load.Enabled = False;
	Items.Pages.CurrentPage = Items.TimeConsumingOperation;
	
	TimeConsumingOperation = StartUpdatingTheComponentsFromThePortal();
	
	If TimeConsumingOperation = Undefined Then 
		BriefErrorPresentation = NStr("ru = 'Не удалось создать фоновое задание обновления компоненты.'; en = 'Cannot create a background job for add-in update.'; pl = 'Cannot create a background job for add-in update.';de = 'Cannot create a background job for add-in update.';ro = 'Cannot create a background job for add-in update.';tr = 'Cannot create a background job for add-in update.'; es_ES = 'Cannot create a background job for add-in update.'");
		Items.Pages.CurrentPage = Items.Error;
	EndIf;
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OwnerForm = ThisObject;
	IdleParameters.OutputIdleWindow = False;
	
	Notification = New NotifyDescription("AfterUpdateAddInsFromPortal", ThisObject);
	TimeConsumingOperationsClient.WaitForCompletion(TimeConsumingOperation, Notification, IdleParameters);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure AfterEnableOnlineSupport(Result, Parameter) Export
	
	If TypeOf(Result) = Type("Structure") Then
		Items.EnableOnlineSupport.Visible = False;
		PortalAuthenticationDataSaved = True;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function PortalAuthenticationDataSaved()
	
	If Common.SubsystemExists("OnlineUserSupport") Then
		ModuleOnlineUserSupport = Common.CommonModule("OnlineUserSupport");
		Return ModuleOnlineUserSupport.AuthenticationDataOfOnlineSupportUserFilled();
	EndIf;
	
	Return False;
	
EndFunction

&AtServer
Function StartUpdatingTheComponentsFromThePortal()
	
	If Not AddInsInternal.ImportFromPortalIsAvailable() Then
		Return Undefined;
	EndIf;
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("RefsArray", RefsArray.UnloadValues());
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("ru = 'Обновление внешней компоненты.'; en = 'Updating add-in.'; pl = 'Updating add-in.';de = 'Updating add-in.';ro = 'Updating add-in.';tr = 'Updating add-in.'; es_ES = 'Updating add-in.'");
	
	Return TimeConsumingOperations.ExecuteInBackground("AddInsInternal.UpdateAddInsFromPortal",
		ProcedureParameters, ExecutionParameters);
	
EndFunction

&AtClient
Procedure AfterUpdateAddInsFromPortal(Result, AdditionalParameters) Export
	
	// Answer:
	// - Structure - Completed - result in the structure.
	// - Undefined - canceled by user.
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		BriefErrorPresentation = Result.BriefErrorPresentation;
		Items.Pages.CurrentPage = Items.Error;
	EndIf;
	
	If Result.Status = "Completed" Then 
		ExecutionResult = GetFromTempStorage(Result.ResultAddress);
		Items.Pages.CurrentPage = Items.Completed;
		Items.Load.Visible = False;
		Items.Cancel.Visible = False;
		Items.Close.Visible = True;
	EndIf;
	
EndProcedure

#EndRegion