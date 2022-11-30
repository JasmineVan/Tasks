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
	
	If Not SaaS.SessionSeparatorUsage() Then 
		Raise(NStr("ru = 'Не установлено значение разделителя'; en = 'The separator value is not specified.'; pl = 'Nie ustawiono wartości separatora';de = 'Trennzeichenwert ist nicht festgelegt';ro = 'Valoarea separatorului nu este setată';tr = 'Ayırıcı değeri ayarlanmadı'; es_ES = 'Valor del separador no está establecido'"));
	EndIf;
	
	SwitchPage(ThisObject);
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure CreateAreaCopy(Command)
	
	TimeConsumingOperation = CreateAreaCopyAtServer();
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);

	CompletionNotification = New NotifyDescription("CreateAreaCopyCompletion", ThisObject);
	TimeConsumingOperationsClient.WaitForCompletion(TimeConsumingOperation, CompletionNotification, IdleParameters);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure CreateAreaCopyCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then 
		
		Return;
		
	EndIf;
	
	ProcessJobExecutionResult(Result);
	
EndProcedure 

&AtClient
Procedure ProcessJobExecutionResult(Result)
	
	DisableExclusiveMode();
	
	If Result.Status = "Error" Then
		
		WriteExceptionsAtServer(Result.DetailedErrorPresentation);
		Raise Result.BriefErrorPresentation;
	
	ElsIf NOT IsBlankString(Result.ResultAddress) Then
		
		DeleteFromTempStorage(Result.ResultAddress);
		Result.ResultAddress = "";
		// Navigating to the result page.
		SwitchPage(ThisObject, "PageAfterExportSuccess");
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SwitchPage(Form, Val PageName = "PageBeforeExport")
	
	Form.Items.PagesGroup.CurrentPage = Form.Items[PageName];
	
	If PageName = "PageBeforeExport" Then
		Form.Items.FormCreateAreaCopy.Enabled = True;
	Else
		Form.Items.FormCreateAreaCopy.Enabled = False;
	EndIf;

EndProcedure

&AtServer
Procedure WriteExceptionsAtServer(Val ErrorPresentation)
	
	DisableExclusiveMode();
	
	Event = DataAreaBackup.BackgroundBackupDescription();
	WriteLogEvent(Event, EventLogLevel.Error, , , ErrorPresentation);
	
EndProcedure

&AtServer
Function CreateAreaCopyAtServer()
	
	DataArea = SaaS.SessionSeparatorValue();
	SetExclusiveMode(True);
	
	JobParameters = DataAreaBackup.CreateEmptyExportParameters();
	JobParameters.DataArea = DataArea;
	JobParameters.BackupID = New UUID;
	JobParameters.Forcibly = True;
	JobParameters.OnDemand = True;
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(ThisObject.UUID);
	ExecutionParameters.BackgroundJobDescription = DataAreaBackup.BackgroundBackupDescription();
	ExecutionParameters.RunInBackground = True;
	
	Try
		
		Result = TimeConsumingOperations.ExecuteInBackground(
			DataAreaBackup.BackgroundBackupMethodName(),
			JobParameters,
			ExecutionParameters);
		
	Except
		
		ErrorPresentation = DetailErrorDescription(ErrorInfo());
		WriteExceptionsAtServer(ErrorPresentation);
		Raise;
		
	EndTry;
	
	StorageAddress = Result.ResultAddress;
	JobID = Result.JobID;
	
	Return Result;
	
EndFunction

&AtServerNoContext
Procedure DisableExclusiveMode()
	
	SetExclusiveMode(False);
	
EndProcedure

#EndRegion
