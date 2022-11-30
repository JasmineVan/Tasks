

// Executes operations before the system start.
Procedure BeforeStart(Parameters) Export
	
	ClientParameters = StandardSubsystemsClientCached.ClientParametersOnStart();
	
	If ClientParameters.ProtectionSystemState.Error Then
		
		Parameters.InteractiveHandler = New NotifyDescription("InteractiveDataProcessorOfProtectionSystemSettings", ThisObject, ClientParameters.ProtectionSystemState);
		
	EndIf;
	
EndProcedure // BeforeStart()

Procedure OnExit() Export
	
	ErrorDescription = "";
	
	LicensingServer.LicensingSystemFinish(ErrorDescription);
	
EndProcedure // OnExit()


////////////////////////////////////////////////////////////////////////////////
// ПРОЦЕДУРЫ И ФУНКЦИИ ОБЩЕГО НАЗНАЧЕНИЯ

Procedure InteractiveDataProcessorOfProtectionSystemSettings(Parameters, ProtectionSystemState) Export
	
	FormParameters = New Structure("LaunchResults,ProgramFormOpening", ProtectionSystemState.LaunchResults, TRUE);
	
	NotifyDescription = New NotifyDescription("InteractiveDataProcessorOfProtectionSystemSettingsResultProcessing", ThisObject, Parameters);
	
	OpenForm("DataProcessor.LicensingManagement.Form.ProtectionSystemState", FormParameters,,,,, NotifyDescription, FormWindowOpeningMode.LockWholeInterface);
	
EndProcedure // ИнтерактивнаяОбработкаНастройкиСистемыЗащиты()

Procedure InteractiveDataProcessorOfProtectionSystemSettingsResultProcessing(ClosingResult, Parameters=Undefined) Export
	
	Parameters.Cancel = (ClosingResult=Undefined) OR ClosingResult;
	
	ExecuteNotifyProcessing(Parameters.ContinuationHandler, FALSE);
	
EndProcedure // ИнтерактивнаяОбработкаНастройкиСистемыЗащитыОбработкаРезультата()



