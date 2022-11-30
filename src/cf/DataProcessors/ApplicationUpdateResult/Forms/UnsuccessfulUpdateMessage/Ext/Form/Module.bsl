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
	
	// Preparing to open the form for data resynchronization before startup with two options, 
	// "Synchronize and continue" and "Continue".
	If ValueIsFilled(Parameters.DetailedErrorPresentation)
	   AND Common.SubsystemExists("StandardSubsystems.DataExchange")
	   AND Common.IsSubordinateDIBNode() Then
		ModuleDataExchangeServer = Common.CommonModule("DataExchangeServer");
		ModuleDataExchangeServer.EnableDataExchangeMessageImportRecurrenceBeforeStart();
	EndIf;
	
	If ValueIsFilled(Parameters.DetailedErrorPresentation) Then
		EventLogOperations.AddMessageForEventLog(InfobaseUpdate.EventLogEvent(), EventLogLevel.Error,
			, , Parameters.DetailedErrorPresentation);
	EndIf;
	
	ErrorMessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'При обновлении версии программы возникла ошибка:
		|
		|%1'; 
		|en = 'Application update error:
		|
		|%1'; 
		|pl = 'Przy aktualizacji wersji programu wystąpił błąd:
		|
		|%1';
		|de = 'Beim Aktualisieren der Softwareversion ist ein Fehler aufgetreten:
		|
		|%1';
		|ro = 'La actualizarea versiunii programului s-a produs eroarea:
		|
		|%1';
		|tr = 'Uygulama sürümü güncellendiğinde bir hata oluştu: 
		|
		|%1'; 
		|es_ES = 'Al actualizar la versión del programa se ha producido un error:
		|
		|%1'"),
		Parameters.BriefErrorPresentation);
	
	Items.ErrorMessageText.Title = ErrorMessageText;
	
	UpdateStartTime = Parameters.UpdateStartTime;
	UpdateEndTime = CurrentSessionDate();
	
	If Not Users.IsFullUser(, True) Then
		Items.FormOpenExternalDataProcessor.Visible = False;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
		UseSecurityProfiles = ModuleSafeModeManager.UseSecurityProfiles();
	Else
		UseSecurityProfiles = False;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.ConfigurationUpdate") Then
		ModuleSoftwareUpdate = Common.CommonModule("ConfigurationUpdate");
		ScriptDirectory = ModuleSoftwareUpdate.ScriptDirectory();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Not IsBlankString(ScriptDirectory) Then
		ModuleSoftwareUpdateClient = CommonClient.CommonModule("ConfigurationUpdateClient");
		ModuleSoftwareUpdateClient.WriteErrorLogFileAndExit(
			ScriptDirectory, 
			Parameters.DetailedErrorPresentation);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ShowUpdateResultInfoClick(Item)
	
	FormParameters = New Structure;
	FormParameters.Insert("StartDate", UpdateStartTime);
	FormParameters.Insert("EndDate", UpdateEndTime);
	FormParameters.Insert("RunNotInBackground", True);
	
	OpenForm("DataProcessor.EventLog.Form.EventLog", FormParameters,,,,,, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure ExitApplication(Command)
	Close(True);
EndProcedure

&AtClient
Procedure RestartApplication(Command)
	Close(False);
EndProcedure

&AtClient
Procedure OpenExternalDataProcessor(Command)
	
	ContinuationHandler = New NotifyDescription("OpenExternalDataProcessorAfterConfirmSafety", ThisObject);
	OpenForm("DataProcessor.ApplicationUpdateResult.Form.SecurityWarning",,,,,, ContinuationHandler);
	
EndProcedure

&AtClient
Procedure OpenExternalDataProcessorAfterConfirmSafety(Result, AdditionalParameters) Export
	If Result <> True Then
		Return;
	EndIf;
	
	If UseSecurityProfiles Then
		
		ModuleSafeModeManagerClient = CommonClient.CommonModule("SafeModeManagerClient");
		ModuleSafeModeManagerClient.OpenExternalDataProcessorOrReport(ThisObject);
		Return;
		
	EndIf;
	
	Notification = New NotifyDescription("OpenExternalDataProcessorCompletion", ThisObject);
	ImportParameters = FileSystemClient.FileImportParameters();
	ImportParameters.FormID = UUID;
	ImportParameters.Dialog.Filter = NStr("ru = 'Внешняя обработка'; en = 'External data processor'; pl = 'Zewnętrzne opracowanie';de = 'Externer Datenprozessor';ro = 'Prelucrare externă';tr = 'Dış veri işlemcisi'; es_ES = 'Procesador de datos externo'") + "(*.epf)|*.epf";
	ImportParameters.Dialog.Multiselect = False;
	ImportParameters.Dialog.Title = NStr("ru = 'Выберите внешнюю обработку'; en = 'Select external data processor'; pl = 'Wybierz zewnętrzne opracowanie';de = 'Wählen Sie einen externen Datenprozessor';ro = 'Selectați procesorul de date extern';tr = 'Dış veri işlemcisini seç'; es_ES = 'Seleccionar el procesador de datos externo'");
	FileSystemClient.ImportFile(Notification, ImportParameters);
EndProcedure

&AtClient
Procedure OpenExternalDataProcessorCompletion(Result, AdditionalParameters) Export
	
	If TypeOf(Result) = Type("Structure") Then
		ExternalDataProcessorName = AttachExternalDataProcessor(Result.Location);
		OpenForm(ExternalDataProcessorName + ".Form");
	EndIf;
	
EndProcedure

&AtServer
Function AttachExternalDataProcessor(AddressInTempStorage)
	
	If Not Users.IsFullUser(, True) Then
		Raise NStr("ru = 'Недостаточно прав доступа.'; en = 'Insufficient access rights.'; pl = 'Niewystarczające prawa dostępu.';de = 'Unzureichende Zugriffsrechte.';ro = 'Drepturi de acces insuficiente.';tr = 'Yetersiz erişim hakları.'; es_ES = 'Insuficientes derechos de acceso.'");
	EndIf;
	
	// CAC:552-off database repair script at update errors for full administrator.
	// CAC:556-disable
	Manager = ExternalDataProcessors;
	DataProcessorName = Manager.Connect(AddressInTempStorage, , False,
		Common.ProtectionWithoutWarningsDetails());
	Return Manager.Create(DataProcessorName, False).Metadata().FullName();
	// CAC:556-enable
	// CAC:552-enable
	
EndFunction

#EndRegion
