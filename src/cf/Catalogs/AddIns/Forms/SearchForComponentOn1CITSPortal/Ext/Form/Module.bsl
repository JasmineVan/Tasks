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
	
	If IsBlankString(Parameters.NoteText) Then
		NoteText = AddInsInternal.AddInPresentation(Parameters.ID, Parameters.Version);
	Else 
		NoteText = Parameters.NoteText;
	EndIf;
	
	Items.NoteDecoration.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = '%1
		           |
		           |Компонента не загружена в программу.
		           |Загрузить?'; 
		           |en = '%1
		           |
		           |The  add-in is not imported to the application.
		           |Do you want to import it?'; 
		           |pl = '%1
		           |
		           |The  add-in is not imported to the application.
		           |Do you want to import it?';
		           |de = '%1
		           |
		           |The  add-in is not imported to the application.
		           |Do you want to import it?';
		           |ro = '%1
		           |
		           |The  add-in is not imported to the application.
		           |Do you want to import it?';
		           |tr = '%1
		           |
		           |The  add-in is not imported to the application.
		           |Do you want to import it?'; 
		           |es_ES = '%1
		           |
		           |The  add-in is not imported to the application.
		           |Do you want to import it?'"),
		NoteText);
	
	PortalAuthenticationDataSaved = PortalAuthenticationDataSaved();
	CanImportFromPortal = AddInsInternal.ImportFromPortalIsAvailable();
	
	Items.EnableOnlineSupport.Visible = Not PortalAuthenticationDataSaved;
	
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
	
	TimeConsumingOperation = StartGettingAddInFromPortal(Parameters.ID, Parameters.Version);
	
	If TimeConsumingOperation = Undefined Then 
		BriefErrorPresentation = NStr("ru = 'Не удалось создать фоновое задание обновления компоненты.'; en = 'Cannot create a background job for add-in update.'; pl = 'Cannot create a background job for add-in update.';de = 'Cannot create a background job for add-in update.';ro = 'Cannot create a background job for add-in update.';tr = 'Cannot create a background job for add-in update.'; es_ES = 'Cannot create a background job for add-in update.'");
		Items.Pages.CurrentPage = Items.Error;
	EndIf;
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OwnerForm = ThisObject;
	IdleParameters.OutputIdleWindow = False;
	
	Notification = New NotifyDescription("AfterGetAddInFromPortal", ThisObject);
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
Function StartGettingAddInFromPortal(ID, Version)
	
	If Not AddInsInternal.ImportFromPortalIsAvailable() Then
		Return Undefined;
	EndIf;
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("ID", ID);
	ProcedureParameters.Insert("Version", Version);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("ru = 'Получение внешней компоненты.'; en = 'Getting add-in.'; pl = 'Getting add-in.';de = 'Getting add-in.';ro = 'Getting add-in.';tr = 'Getting add-in.'; es_ES = 'Getting add-in.'");
	
	Return TimeConsumingOperations.ExecuteInBackground("AddInsInternal.NewAddInsFromPortal",
		ProcedureParameters, ExecutionParameters);
	
EndFunction

&AtClient
Procedure AfterGetAddInFromPortal(Result, AdditionalParameters) Export
	
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
		Close(True);
	EndIf;
	
EndProcedure

#EndRegion