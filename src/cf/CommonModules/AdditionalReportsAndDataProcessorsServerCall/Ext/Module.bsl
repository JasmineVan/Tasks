///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Attaches an external report or data processor.
// For more information, see AdditionalReportsAndDataProcessors.AttachExternalDataProcessor(). 
//
// Parameters:
//   Ref - CatalogRef.AdditionalReportsAndDataProcessors - a data processor to attach.
//
// Returns:
//   String       - a name of the attached report or data processor.
//   Undefined - if an invalid reference is passed.
//
Function AttachExternalDataProcessor(Ref) Export
	
	Return AdditionalReportsAndDataProcessors.AttachExternalDataProcessor(Ref);
	
EndFunction

// Creates and returns an instance of an external data processor (report).
// For more information, see AdditionalReportsAndDataProcessors.ExternalDataProcessorObject(). 
//
// Parameters:
//   Ref - CatalogRef.AdditionalReportsAndDataProcessors - a report or a data processor to attach.
//
// Returns:
//   ExternalDataProcessorObject - an object of the attached data processor.
//   ExternalReportObject     - an attached report object.
//   Undefined           - if an invalid reference is passed.
//
Function ExternalDataProcessorObject(Ref) Export
	
	Return AdditionalReportsAndDataProcessors.ExternalDataProcessorObject(Ref);
	
EndFunction

#Region ObsoleteProceduresAndFunctions

// Obsolete. Use AdditionalReportsAndDataProcessors.ExternalDataProcessorObject().
//
// Parameters:
//   Ref - CatalogRef.AdditionalReportsAndDataProcessors - a report or a data processor to attach.
//
// Returns:
//   ExternalDataProcessorObject - an object of the attached data processor.
//   ExternalReportObject     - an attached report object.
//   Undefined           - if an invalid reference is passed.
//
Function GetExternalDataProcessorsObject(Ref) Export
	
	Return AdditionalReportsAndDataProcessors.ExternalDataProcessorObject(Ref);
	
EndFunction

#EndRegion

#EndRegion

#Region Private

// Executes a data processor command and puts the result in a temporary storage.
//   For more information, see AdditionalReportsAndDataProcessors.ExecuteCommand(). 
//
Function ExecuteCommand(CommandParameters, ResultAddress = Undefined) Export
	
	Return AdditionalReportsAndDataProcessors.ExecuteCommand(CommandParameters, ResultAddress);
	
EndFunction

// Puts binary data of an additional report or data processor in a temporary storage.
Function PutInStorage(Ref, FormID) Export
	If TypeOf(Ref) <> Type("CatalogRef.AdditionalReportsAndDataProcessors") 
		Or Ref = Catalogs.AdditionalReportsAndDataProcessors.EmptyRef() Then
		Return Undefined;
	EndIf;
	If NOT AdditionalReportsAndDataProcessors.CanExportDataProcessorToFile(Ref) Then
		Raise NStr("ru = 'Недостаточно прав для выгрузки файлов дополнительных отчетов и обработок'; en = 'Insufficient rights to export additional report or data processor files'; pl = 'Niewystarczające uprawnienia do eksportowania plików dodatkowych sprawozdań i procedur przetwarzania danych';de = 'Unzureichende Rechte zum Exportieren von Dateien zusätzlicher Berichte und Datenprozessoren';ro = 'Drepturi insuficiente pentru importul fișierelor de rapoarte și procesări suplimentare';tr = 'Ek raporların ve veri işlemcilerinin dosyalarını dışa aktarmak için yetersiz haklar'; es_ES = 'Insuficientes derechos para exportar los archivos de informes adicionales y procesadores de datos'");
	EndIf;
	
	DataProcessorStorage = Common.ObjectAttributeValue(Ref, "DataProcessorStorage");
	
	Return PutToTempStorage(DataProcessorStorage.Get(), FormID);
EndFunction

// Starts a time-consuming operation.
Function StartTimeConsumingOperation(Val UUID, Val CommandParameters) Export
	MethodName = "AdditionalReportsAndDataProcessors.ExecuteCommand";
	
	StartSettings = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	StartSettings.WaitForCompletion = 0;
	StartSettings.BackgroundJobDescription = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Выполнение дополнительного отчета или обработки ""%1"", имя команды ""%2""'; en = 'Running %1 additional report or data processor, command name: %2.'; pl = 'Uruchamianie dodatkowego sprawozdania lub przetwarzania danych ""%1"", nazwa polecenia ""%2""';de = 'Ausführen eines zusätzlichen Berichts oder Datenprozessors ""%1"", Befehlsname ""%2""';ro = 'Executarea raportului sau procesării suplimentare ""%1"", numele comenzii ""%2""';tr = 'Ek rapor veya veri işlemcisi çalıştırılıyor ""%1"", komut adı ""%2""'; es_ES = 'Lanzando el informe adicional o el procesador de datos ""%1"", nombre del comando ""%2""'"),
		String(CommandParameters.AdditionalDataProcessorRef),
		CommandParameters.CommandID);
	
	Return TimeConsumingOperations.ExecuteInBackground(MethodName, CommandParameters, StartSettings);
EndFunction

#EndRegion
