///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// For internal use.
Function GenerateMailingRecipientsList(Val Parameters) Export
	LogParameters = New Structure("EventName, Metadata, Data, ErrorArray, HadErrors");
	LogParameters.EventName   = NStr("ru = 'Рассылка отчетов. Формирование списка получателей'; en = 'Report bulk email. Generate recipient list'; pl = 'Report bulk email. Generate recipient list';de = 'Report bulk email. Generate recipient list';ro = 'Report bulk email. Generate recipient list';tr = 'Report bulk email. Generate recipient list'; es_ES = 'Report bulk email. Generate recipient list'", Common.DefaultLanguageCode());
	LogParameters.ErrorArray = New Array;
	LogParameters.HadErrors   = False;
	LogParameters.Data       = Parameters.Ref;
	LogParameters.Metadata   = Metadata.Catalogs.ReportMailings;
	
	ExecutionResult = New Structure("Recipients, HadCriticalErrors, Text, More");
	ExecutionResult.Recipients = ReportMailing.GenerateMailingRecipientsList(LogParameters, Parameters);
	ExecutionResult.HadCriticalErrors = ExecutionResult.Recipients.Count() = 0;
	
	If ExecutionResult.HadCriticalErrors Then
		ExecutionResult.Text = NStr("ru = 'Не удалось сформировать список получателей'; en = 'Cannot generate a recipient list'; pl = 'Cannot generate a recipient list';de = 'Cannot generate a recipient list';ro = 'Cannot generate a recipient list';tr = 'Cannot generate a recipient list'; es_ES = 'Cannot generate a recipient list'");
		ExecutionResult.More = ReportMailing.MessagesToUserString(LogParameters.ErrorArray, False);
	EndIf;
	
	Return ExecutionResult;
EndFunction

// Runs background job.
Function RunBackgroundJob(Val MethodParameters, Val UUID) Export
	MethodName = "ReportMailing.SendBulkEmailsInBackgroundJob";
	
	StartSettings = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	StartSettings.BackgroundJobDescription = NStr("ru = 'Рассылки отчетов: Выполнение рассылок в фоне'; en = 'Report bulk emails: Running in the background'; pl = 'Report bulk emails: Running in the background';de = 'Report bulk emails: Running in the background';ro = 'Report bulk emails: Running in the background';tr = 'Report bulk emails: Running in the background'; es_ES = 'Report bulk emails: Running in the background'");
	
	Return TimeConsumingOperations.ExecuteInBackground(MethodName, MethodParameters, StartSettings);
EndFunction

#EndRegion
