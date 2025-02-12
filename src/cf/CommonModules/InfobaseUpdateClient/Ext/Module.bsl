﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// Opens the form of deferred handlers.
//
Procedure ShowDeferredHandlers() Export
	OpenForm("DataProcessor.ApplicationUpdateResult.Form.DeferredHandlers");
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Configuration subsystems event handlers.

// See CommonClientOverridable.BeforeStart. 
Procedure BeforeStart(Parameters) Export
	
	ClientParameters = StandardSubsystemsClient.ClientParametersOnStart();
	If Not ClientParameters.DataSeparationEnabled Or Not ClientParameters.SeparatedDataUsageAvailable Then
		InfobaseUpdateClientOverridable.OnDetermineUpdateAvailability(ClientParameters.MainConfigurationDataVersion);
	EndIf;
	
	If ClientParameters.Property("InfobaseLockedForUpdate") Then
		Buttons = New ValueList();
		Buttons.Add("Restart", NStr("ru = 'Перезапустить'; en = 'Restart'; pl = 'Zrestartuj';de = 'Neustart';ro = 'Relansare';tr = 'Yeniden başlat'; es_ES = 'Reiniciar'"));
		Buttons.Add("ExitApplication",     NStr("ru = 'Завершить работу'; en = 'Exit'; pl = 'Sfinalizować';de = 'Finalisieren';ro = 'Finalizare lucrul';tr = 'Sonlandır'; es_ES = 'Finalizar'"));
		
		QuestionParameters = New Structure;
		QuestionParameters.Insert("DefaultButton", "Restart");
		QuestionParameters.Insert("TimeoutButton",    "Restart");
		QuestionParameters.Insert("Timeout",           60);
		
		WarningDetails = New Structure;
		WarningDetails.Insert("Buttons",           Buttons);
		WarningDetails.Insert("QuestionParameters", QuestionParameters);
		WarningDetails.Insert("WarningText",
			ClientParameters.InfobaseLockedForUpdate);
		
		Parameters.Cancel = True;
		Parameters.InteractiveHandler = New NotifyDescription(
			"ShowMessageBoxAndContinue",
			StandardSubsystemsClient,
			WarningDetails);
	EndIf;
	
EndProcedure

// See CommonClientOverridable.BeforeStart. 
Procedure BeforeStart2(Parameters) Export
	
	ClientParameters = StandardSubsystemsClient.ClientParametersOnStart();
	If ClientParameters.Property("MustRunDeferredUpdateHandlers") Then
		Parameters.InteractiveHandler = New NotifyDescription(
			"DeferredUpdateStatusCheckInteractiveHandler",
			ThisObject);
	EndIf;
	
EndProcedure

// See CommonClientOverridable.BeforeStart. 
Procedure BeforeStart3(Parameters) Export
	
	ClientParameters = StandardSubsystemsClient.ClientParametersOnStart();
	If ClientParameters.Property("ApplicationParametersUpdateRequired") Then
		Parameters.InteractiveHandler = New NotifyDescription(
			"ImportUpdateApplicationParameters", InfobaseUpdateClient);
	EndIf;
	
EndProcedure

// See CommonClientOverridable.BeforeStart. 
Procedure BeforeStart4(Parameters) Export
	
	ClientRunParameters = StandardSubsystemsClient.ClientParametersOnStart();
	If NOT ClientRunParameters.SeparatedDataUsageAvailable Then
		CloseUpdateProgressIndicationFormIfOpen(Parameters);
		Return;
	EndIf;
	
	If ClientRunParameters.Property("InfobaseUpdateRequired") Then
		Parameters.InteractiveHandler = New NotifyDescription(
			"StartInfobaseUpdate", ThisObject);
	Else
		If ClientRunParameters.Property("LoadDataExchangeMessage") Then
			Restart = False;
			InfobaseUpdateInternalServerCall.UpdateInfobase(True, Restart);
			If Restart Then
				Parameters.Cancel = True;
				Parameters.Restart = True;
			EndIf;
		EndIf;
		CloseUpdateProgressIndicationFormIfOpen(Parameters);
	EndIf;
	
EndProcedure

// See CommonClientOverridable.BeforeStart. 
Procedure BeforeStart5(Parameters) Export
	
	If CommonClient.FileInfobase()
	   AND StrFind(LaunchParameter, "UpdateAndExit") > 0 Then
		
		Terminate();
		
	EndIf;
	
EndProcedure

// See CommonClientOverridable.OnStart. 
Procedure OnStart(Parameters) Export
	
	ClientRunParameters = StandardSubsystemsClient.ClientParametersOnStart();
	If NOT ClientRunParameters.SeparatedDataUsageAvailable Then
		Return;
	EndIf;
	
	ShowChangeHistory();
	
EndProcedure

// See CommonClientOverridable.AfterStart. 
Procedure AfterStart() Export
	
	ClientParameters = StandardSubsystemsClient.ClientParametersOnStart();
	
	If ClientParameters.Property("ShowInvalidHandlersMessage")
		Or ClientParameters.Property("ShowUncompletedHandlersNotification") Then
		AttachIdleHandler("CheckDeferredUpdateStatus", 2, True);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// This method is required by UpdateInfobase procedure.
Procedure CloseUpdateProgressIndicationFormIfOpen(Parameters)
	
	ParameterName = "StandardSubsystems.IBVersionUpdate.IBUpdateProgressIndicatorForm";
	Form = ApplicationParameters.Get(ParameterName);
	If Form = Undefined Then
		Return;
	EndIf;
	If Form.IsOpen() Then
		Form.BeginClose();
	EndIf;
	ApplicationParameters.Delete(ParameterName);
	
EndProcedure

// For internal use only. Continues the execution of InfobaseUpdate procedure.
Procedure StartInfobaseUpdate(Parameters, ContinuationHandler) Export
	
	ParameterName = "StandardSubsystems.IBVersionUpdate.IBUpdateProgressIndicatorForm";
	Form = ApplicationParameters.Get(ParameterName);
	
	If Form = Undefined Then
		FormName = "DataProcessor.ApplicationUpdateResult.Form.IBUpdateProgressIndicator";
		Form = OpenForm(FormName,,,,,, New NotifyDescription(
			"AfterCloseIBUpdateProgressIndicatorForm", ThisObject, Parameters));
		ApplicationParameters.Insert(ParameterName, Form);
	EndIf;
	
	Form.UpdateInfobase();
	
EndProcedure

// For internal use only. Continues the execution of BeforeApplicationStart procedure.
Procedure ImportUpdateApplicationParameters(Parameters, Context) Export
	
	FormName = "DataProcessor.ApplicationUpdateResult.Form.IBUpdateProgressIndicator";
	Form = OpenForm(FormName,,,,,, New NotifyDescription(
		"AfterCloseIBUpdateProgressIndicatorForm", ThisObject, Parameters));
	ApplicationParameters.Insert("StandardSubsystems.IBVersionUpdate.IBUpdateProgressIndicatorForm", Form);
	Form.ImportUpdateApplicationParameters(Parameters);
	
EndProcedure

// For internal use only. Continues the execution of InfobaseUpdate procedure.
Procedure AfterCloseIBUpdateProgressIndicatorForm(Result, Parameters) Export
	
	If TypeOf(Result) <> Type("Structure") Then
		Result = New Structure("Cancel, Restart", True, False);
	EndIf;
	
	If Result.Cancel Then
		Parameters.Cancel = True;
		If Result.Restart Then
			Parameters.Restart = True;
		EndIf;
	EndIf;
	
	ExecuteNotifyProcessing(Parameters.ContinuationHandler);
	
EndProcedure

// For internal use only. Continue the CheckDeferredUpdateHandlersStatus procedure.
Procedure DeferredUpdateStatusCheckInteractiveHandler(Parameters, Context) Export
	
	OpenForm("DataProcessor.ApplicationUpdateResult.Form.DeferredUpdateNotCompleted", , , , , ,
		New NotifyDescription("AfterDeferredUpdateStatusCheckFormClose",
			ThisObject, Parameters));
	
EndProcedure

// For internal use only. Continue the CheckDeferredUpdateHandlersStatus procedure.
Procedure AfterDeferredUpdateStatusCheckFormClose(Result, Parameters) Export
	
	If Result <> True Then
		Parameters.Cancel = True;
	EndIf;
	
	ExecuteNotifyProcessing(Parameters.ContinuationHandler);
	
EndProcedure

// If there is hidden description of changes and settings allow a user to view such information, 
// open the ApplicationChangeHistory form. 
//
Procedure ShowChangeHistory()
	
	ClientRunParameters = StandardSubsystemsClient.ClientParametersOnStart();
	If ClientRunParameters.ShowChangeHistory Then
		
		FormParameters = New Structure;
		FormParameters.Insert("ShowOnlyChanges", True);
		
		OpenForm("CommonForm.ApplicationReleaseNotes", FormParameters);
	EndIf;
	
EndProcedure

// Notifies the user that the deferred data processing is not executed.
// 
//
Procedure NotifyDeferredHandlersNotExecuted() Export
	
	If UsersClient.IsExternalUserSession() Then
		Return;
	EndIf;
	
	ShowUserNotification(
		NStr("ru = 'Работа в программе временно ограничена'; en = 'The application functionality is temporarily limited.'; pl = 'Operacje aplikacji są tymczasowo ograniczone';de = 'Anwendungsvorgänge sind vorübergehend eingeschränkt';ro = 'Lucrul în program este limitat temporar';tr = 'Başvuru işlemleri geçici olarak kısıtlanmıştır'; es_ES = 'Operaciones de la aplicación temporalmente están restringidas'"),
		DataProcessorURL(),
		NStr("ru = 'Не завершен переход на новую версию'; en = 'Upgrade to the new version is still in progress.'; pl = 'Aktualizacja do nowej wersji jest niekompletna';de = 'Das Update auf eine neue Version ist unvollständig';ro = 'Migrarea la versiunea nouă nu este finalizată';tr = 'Yeni sürüme güncelleme tamamlanmamış'; es_ES = 'Actualización para una nueva versión está incompleta'"),
		PictureLib.Warning32);
	
EndProcedure

// Returns the URL of InfobaseUpdate data processor
//
Function DataProcessorURL()
	Return "e1cib/app/DataProcessor.ApplicationUpdateResult";
EndFunction

#EndRegion
