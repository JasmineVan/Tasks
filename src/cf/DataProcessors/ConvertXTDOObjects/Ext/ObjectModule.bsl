///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var DataImportDataProcessorField;

#EndRegion

#Region Public

#Region ExportProperties

// Function for retrieving property: the result of data exchange.
//  Returns:
//      EnumRef.ExchangeExecutionResults - the result of data exchange execution.
//
Function ExchangeExecutionResult() Export
	
	If ExchangeComponents = Undefined Then
		Return Enums.ExchangeExecutionResults.Canceled;
	EndIf;
	
	ExchangeExecutionResult = ExchangeComponents.DataExchangeState.ExchangeExecutionResult;
	If ExchangeExecutionResult = Undefined Then
		Return Enums.ExchangeExecutionResults.Completed;
	EndIf;
	
	Return ExchangeExecutionResult;
	
EndFunction

// Function for retrieving property: the result of data exchange.
//
//  Returns:
//      String - data exchange execution result.
//
Function ExchangeExecutionResultString() Export
	
	Return Common.EnumValueName(ExchangeExecutionResult());
	
EndFunction


// Function for retrieving property: the number of imported objects.
//
//  Returns:
//      Number - number of imported objects.
//
Function ImportedObjectCounter() Export
	
	If ExchangeComponents = Undefined Then
		Return 0;
	EndIf;
	
	Return ExchangeComponents.ImportedObjectCounter;
	
EndFunction

// Function for retrieving property: the amount of exported objects.
//
//  Returns:
//      Number - number of exported objects.
//
Function ExportedObjectCounter() Export
	
	If ExchangeComponents = Undefined Then
		Return 0;
	EndIf;
	
	Return ExchangeComponents.ExportedObjectCounter;
	
EndFunction

// Function for retrieving properties: a data exchange error message string.
//
//  Returns:
//      String - a data exchange error message string.
//
Function ErrorMessageString() Export
	
	Return ExchangeComponents.ErrorMessageString;
	
EndFunction

// Function for retrieving property: a flag that shows a data exchange execution error.
//
//  Returns:
//     Boolean - a flag that shows a data exchange execution error.
//
Function ErrorFlag() Export
	
	Return ExchangeComponents.ErrorFlag;
	
EndFunction

// Function for retrieving property: a number of data exchange message.
//
//  Returns:
//      Number - a number of the data exchange message.
//
Function MessageNo() Export
	
	Return ExchangeComponents.IncomingMessageNumber;
	
EndFunction

// Function for retrieving properties: a value table with incoming exchange message statistics and extra information.
//
//  Returns:
//      ValueTable - contains statistics and extra information on the incoming exchange message.
//
Function PackageHeaderDataTable() Export
	
	If ExchangeComponents = Undefined Then
		Return DataExchangeXDTOServer.NewDataBatchTitleTable();
	Else
		Return ExchangeComponents.PackageHeaderDataTable;
	EndIf;
	
EndFunction

// Function for retrieving properties: map with data tables of the received data exchange message.
//
//  Returns:
//      Map - contains data tables of the received data exchange message.
//
Function DataTablesExchangeMessages() Export
	
	If ExchangeComponents = Undefined Then
		Return New Map;
	Else
		Return ExchangeComponents.DataTablesExchangeMessages;
	EndIf;
	
EndFunction

#EndRegion

#Region DataExport

// Run data export.
// -- All objects are exported to one file.
//
// Parameters:
//      DataProcessorForDataImport - DataProcessorObject.ConvertXTDOObjects - a data processor for import in COM connection.
Procedure RunDataExport(DataProcessorForDataImport = Undefined) Export
	
	DataImportDataProcessorField = DataProcessorForDataImport;
	
	ExchangeComponents = DataExchangeXDTOServer.InitializeExchangeComponents("Send");
	
	#Region SettingExchangeComponentsForNodeOperations
	ExchangeComponents.CorrespondentNode = NodeForExchange;
	
	ExchangeComponents.XDTOSettingsOnly = Not DataExchangeServer.SynchronizationSetupCompleted(
		ExchangeComponents.CorrespondentNode);
	If Not ExchangeComponents.XDTOSettingsOnly Then
		ExchangeComponents.ExchangeFormatVersion = Common.ObjectAttributeValue(
			ExchangeComponents.CorrespondentNode, "ExchangeFormatVersion");
	EndIf;
		
	ExchangePlanName = DataExchangeCached.GetExchangePlanName(ExchangeComponents.CorrespondentNode);
	ExchangeComponents.XMLSchema = DataExchangeXDTOServer.ExchangeFormat(ExchangePlanName, ExchangeComponents.ExchangeFormatVersion);
	
	If Not ExchangeComponents.XDTOSettingsOnly Then
		
		ExchangeComponents.ExchangeManager = DataExchangeXDTOServer.FormatVersionExchangeManager(
			ExchangeComponents.ExchangeFormatVersion, ExchangeComponents.CorrespondentNode);
		
		ExchangeComponents.ObjectsRegistrationRulesTable = DataExchangeXDTOServer.ObjectsRegistrationRules(
			ExchangeComponents.CorrespondentNode);
		ExchangeComponents.ExchangePlanNodeProperties = DataExchangeXDTOServer.ExchangePlanNodeProperties(
			ExchangeComponents.CorrespondentNode);
			
		DataExchangeXDTOServer.InitializeExchangeRulesTables(ExchangeComponents);
		DataExchangeXDTOServer.FillXDTOSettingsStructure(ExchangeComponents);
		DataExchangeXDTOServer.FillSupportedXDTODataObjects(ExchangeComponents);
		
		ExchangeComponents.SkipObjectsWithSchemaCheckErrors = DataExchangeXDTOServer.SkipObjectsWithSchemaCheckErrors(
			ExchangeComponents.CorrespondentNode);
		
	Else
		
		DataExchangeXDTOServer.FillXDTOSettingsStructure(ExchangeComponents);
		
	EndIf;
	#EndRegion
	
	If Not ExchangeComponents.XDTOSettingsOnly Then
		ExchangeComponents.KeepDataProtocol.OutputInfoMessagesToProtocol = OutputInfoMessagesToProtocol;
		ExchangeComponents.EventLogMessageKey = EventLogMessageKey;
		
		DataExchangeXDTOServer.InitializeKeepExchangeProtocol(ExchangeComponents, ExchangeProtocolFileName);
	EndIf;
	
	// Opening the exchange file.
	DataExchangeXDTOServer.OpenExportFile(ExchangeComponents, ExchangeFileName);
	
	Cancel = False;
	Try
		AfterOpenExportFile(Cancel);
		// EXPORTING DATA.
		If Not Cancel Then
			DataExchangeXDTOServer.ExecuteDataExport(ExchangeComponents);
		EndIf;
	Except
		Info = ErrorInfo();
		ErrorCode = New Structure("BriefErrorPresentation, DetailedErrorPresentation",
			BriefErrorDescription(Info), DetailErrorDescription(Info));
		
		DataExchangeXDTOServer.WriteToExecutionProtocol(ExchangeComponents, ErrorCode);
		DataExchangeXDTOServer.FinishKeepExchangeProtocol(ExchangeComponents);
		
		ExchangeComponents.ExchangeFile = Undefined;
		Cancel = True;
	EndTry;
	
	If ExchangeComponents.IsExchangeViaExchangePlan Then
		UnlockDataForEdit(ExchangeComponents.CorrespondentNode);
	EndIf;
	
	If Cancel Then
		Return;
	EndIf;
	
	XMLExportData = ExchangeComponents.ExchangeFile.Close();
	
	DataExchangeXDTOServer.FinishKeepExchangeProtocol(ExchangeComponents);
	
	If IsExchangeOverExternalConnection() Then
		If DataProcessorForDataImport().DataImportMode = "ImportMessageForDataMapping" Then
			If Not ExchangeComponents.ErrorFlag Then
				DataProcessorForDataImport().PutMessageForDataMapping(XMLExportData);
			Else
				DataProcessorForDataImport().PutMessageForDataMapping(Undefined);
			EndIf;
		Else
			If Not ExchangeComponents.ErrorFlag Then
				TempFileName = GetTempFileName("xml");
				
				TextDocument = New TextDocument;
				TextDocument.AddLine(XMLExportData);
				TextDocument.Write(TempFileName,,Chars.LF);
				
				DataProcessorForDataImport().ExchangeFileName = TempFileName;
				DataProcessorForDataImport().RunDataImport();
				
				DeleteFiles(TempFileName);
			Else
				DataProcessorForDataImport().ExchangeFileName = "";
				DataProcessorForDataImport().RunDataImport();
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region DataImport

// Imports data from the exchange message file.
// Data is imported to the infobase.
//
// Parameters:
//  ImportParameters - Structure, Undefined - a service parameter. Not intended for use.
//
Procedure RunDataImport(ImportParameters = Undefined) Export
	
	If ImportParameters = Undefined Then
		ImportParameters = New Structure;
	EndIf;
	
	ExchangeComponents = DataExchangeXDTOServer.InitializeExchangeComponents("Get");
	
	ExchangeComponents.CorrespondentNode = ExchangeNodeDataImport;
	
	DataExchangeWithExternalSystem = Undefined;
	If ImportParameters.Property("DataExchangeWithExternalSystem", DataExchangeWithExternalSystem) Then
		ExchangeComponents.DataExchangeWithExternalSystem = DataExchangeWithExternalSystem;
	EndIf;
	
	DataImportMode = "ImportToInfobase";
	
	ExchangeComponents.EventLogMessageKey = EventLogMessageKey;
	ExchangeComponents.KeepDataProtocol.OutputInfoMessagesToProtocol = OutputInfoMessagesToProtocol;
	ExchangeComponents.DataExchangeState.StartDate = CurrentSessionDate();
	
	DataExchangeXDTOServer.InitializeKeepExchangeProtocol(ExchangeComponents, ExchangeProtocolFileName);
	
	If IsBlankString(ExchangeFileName) Then
		DataExchangeXDTOServer.WriteToExecutionProtocol(ExchangeComponents, 15);
		DataExchangeXDTOServer.FinishKeepExchangeProtocol(ExchangeComponents);
		Return;
	EndIf;
	
	If ContinueOnError Then
		UseTransactions = False;
		ExchangeComponents.UseTransactions = False;
	EndIf;
	
	DataExchangeXDTOServer.OpenImportFile(ExchangeComponents, ExchangeFileName);
	
	Cancel = False;
	AfterOpenImportFile(Cancel);
	
	If Cancel Then
		Return;
	EndIf;
	
	DataAnalysisResultToExport = DataExchangeServer.DataAnalysisResultToExport(ExchangeFileName, True);
	DataAnalysisResultToExport.Insert("CorrespondentSupportsDataExchangeID",
											ExchangeComponents.CorrespondentSupportsDataExchangeID);
	ExchangeComponents.Insert("ExchangeMessageFileSize", DataAnalysisResultToExport.ExchangeMessageFileSize);
	ExchangeComponents.Insert("ObjectsToImportCount", DataAnalysisResultToExport.ObjectsToImportCount);
	
	DataExchangeInternal.DisableAccessKeysUpdate(True);
	Try
		DataExchangeXDTOServer.ReadData(ExchangeComponents);
		DataExchangeInternal.DisableAccessKeysUpdate(False);
	Except
		DataExchangeInternal.DisableAccessKeysUpdate(False);
		Information = ErrorInfo();
		MessageString = NStr("ru = 'Ошибка при загрузке данных: %1'; en = 'Cannot import data: %1'; pl = 'Wystąpił błąd podczas importu danych: %1';de = 'Beim Importieren von Daten ist ein Fehler aufgetreten: %1';ro = 'Eroare la importul datelor: %1';tr = 'Veri içe aktarılırken bir hata oluştu:  %1'; es_ES = 'Ha ocurrido un error al importar los datos: %1'");
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(
			MessageString, DetailErrorDescription(Information));
		DataExchangeXDTOServer.WriteToExecutionProtocol(ExchangeComponents, MessageString, , , , , True);
		ExchangeComponents.ErrorFlag = True;
	EndTry;
	
	DataExchangeInternal.DisableAccessKeysUpdate(True);
	Try
		DataExchangeXDTOServer.DeleteTemporaryObjectsCreatedByRefs(ExchangeComponents);
		DataExchangeInternal.DisableAccessKeysUpdate(False);
	Except
		DataExchangeInternal.DisableAccessKeysUpdate(False);
		Information = ErrorInfo();
		MessageString = NStr("ru = 'Ошибка при удалении временных объектов, созданных по ссылкам: %1'; en = 'Cannot delete temporary objects created by references: %1'; pl = 'Błąd podczas usuwania tymczasowych obiektów, utworzonych wg linków: %1';de = 'Fehler beim Löschen von temporären Objekten, die durch Links erstellt wurden: %1';ro = 'Eroare la ștergerea obiectelor temporare create conform referințelor: %1';tr = 'Referanslara göre oluşturulan geçici nesneler kaldırılırken bir hata oluştu: %1'; es_ES = 'Error al eliminar los objetos temporales creados por enlaces: %1'");
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(
			MessageString, DetailErrorDescription(Information));
		DataExchangeXDTOServer.WriteToExecutionProtocol(ExchangeComponents, MessageString, , , , , True);
		ExchangeComponents.ErrorFlag = True;
	EndTry;
	
	ExchangeComponents.ExchangeFile.Close();
	
	If Not ExchangeComponents.ErrorFlag Then
		// Checking data From / NewFrom.
		DataExchangeServer.CheckNodesCodes(DataAnalysisResultToExport, ExchangeComponents.CorrespondentNode);
		
		// Writing information on the incoming message number.
		NodeObject = ExchangeNodeDataImport.GetObject();
		NodeObject.ReceivedNo = ExchangeComponents.IncomingMessageNumber;
		NodeObject.AdditionalProperties.Insert("GettingExchangeMessage");
		NodeObject.Write();
		
	EndIf;
	
	DataExchangeXDTOServer.FinishKeepExchangeProtocol(ExchangeComponents);
	
EndProcedure

// Imports data from an exchange message file to an infobase of the specified object types only.
//
// Parameters:
//  TablesToImport - Array - array of types to be imported from the exchange message; array element - String
//        For example, to import from the exchange message the Counterparties catalog items only:
//             TablesToImport = New Array;
//             TablesToImport.Add("CatalogRef.Counterparties");
// 
//       You can receive the list of all types that are contained in the current exchange message by 
//       calling the ExecuteExchangeMessageAnalysis() procedure.
// 
Procedure ExecuteDataImportForInfobase(TablesToImport) Export
	
	ExchangeComponents = DataExchangeXDTOServer.InitializeExchangeComponents("Get");
	ExchangeComponents.EventLogMessageKey = EventLogMessageKey;
	ExchangeComponents.KeepDataProtocol.OutputInfoMessagesToProtocol = OutputInfoMessagesToProtocol;
	ExchangeComponents.CorrespondentNode = ExchangeNodeDataImport;
	
	DataImportMode = "ImportToInfobase";
	
	ExchangeComponents.DataExchangeState.StartDate = CurrentSessionDate();
	
	DataExchangeXDTOServer.OpenImportFile(ExchangeComponents, ExchangeFileName);
	
	Cancel = False;
	AfterOpenImportFile(Cancel);
	
	If Cancel Then
		Return;
	EndIf;
	
	// Record in the event log.
	MessageString = NStr("ru = 'Начало процесса обмена данными для узла: %1'; en = 'Data exchange for node %1 started.'; pl = 'Początek procesu wymiany danych dla węzła: %1';de = 'Datenaustauschprozess für den Knoten starten: %1';ro = 'Începutul procesului de schimb de date pentru nod: %1';tr = 'Ünite için veri değişimi süreci başlatılıyor: %1'; es_ES = 'Inicio del proceso del intercambio de datos para el nodo: %1'", Common.DefaultLanguageCode());
	MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, String(ExchangeNodeDataImport));
	DataExchangeXDTOServer.WriteEventLogDataExchange(MessageString, ExchangeComponents, EventLogLevel.Information);
	
	DataExchangeInternal.DisableAccessKeysUpdate(True);
	Try
		DataExchangeXDTOServer.ReadData(ExchangeComponents, TablesToImport);
	Except
		Information = ErrorInfo();
		MessageString = NStr("ru = 'Ошибка при загрузке данных: %1'; en = 'Cannot import data: %1'; pl = 'Wystąpił błąd podczas importu danych: %1';de = 'Beim Importieren von Daten ist ein Fehler aufgetreten: %1';ro = 'Eroare la importul datelor: %1';tr = 'Veri içe aktarılırken bir hata oluştu:  %1'; es_ES = 'Ha ocurrido un error al importar los datos: %1'");
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(
			MessageString, DetailErrorDescription(Information));
		DataExchangeXDTOServer.WriteEventLogDataExchange(MessageString, ExchangeComponents, EventLogLevel.Error);
	EndTry;
	
	Try
		DataExchangeXDTOServer.DeleteTemporaryObjectsCreatedByRefs(ExchangeComponents);
	Except
		Information = ErrorInfo();
		MessageString = NStr("ru = 'Ошибка при удалении временных объектов, созданных по ссылкам: %1'; en = 'Cannot delete temporary objects created by references: %1'; pl = 'Błąd podczas usuwania tymczasowych obiektów, utworzonych wg linków: %1';de = 'Fehler beim Löschen von temporären Objekten, die durch Links erstellt wurden: %1';ro = 'Eroare la ștergerea obiectelor temporare create conform referințelor: %1';tr = 'Referanslara göre oluşturulan geçici nesneler kaldırılırken bir hata oluştu: %1'; es_ES = 'Error al eliminar los objetos temporales creados por enlaces: %1'");
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(
			MessageString, DetailErrorDescription(Information));
		DataExchangeXDTOServer.WriteEventLogDataExchange(MessageString, ExchangeComponents, EventLogLevel.Error);
	EndTry;
	DataExchangeInternal.DisableAccessKeysUpdate(False);
	
	// Record in the event log.
	MessageString = NStr("ru = '%1, %2; Обработано %3 объектов'; en = '%1, %2, %3 objects processed.'; pl = '%1, %2; %3 obiekty są przetwarzane';de = '%1, %2; %3 Eigenschaften werden verarbeitet';ro = '%1, %2; %3 obiectele sunt procesate';tr = '%1, %2; %3 nesneler işleniyor'; es_ES = '%1, %2; %3 objetos se han procesado'", Common.DefaultLanguageCode());
	MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString,
					ExchangeComponents.DataExchangeState.ExchangeExecutionResult,
					Enums.ActionsOnExchange.DataImport,
					Format(ExchangeComponents.ImportedObjectCounter, "NG=0"));
	
	DataExchangeXDTOServer.WriteEventLogDataExchange(MessageString, ExchangeComponents, EventLogLevel.Information);
	ExchangeComponents.ExchangeFile.Close();
	
EndProcedure

// Performs sequential reading of the exchange message file while:
//  - registration of changes by the number of the incoming receipt is deleted
//  - exchange rules are imported
//  - information on data types is imported
//  - data mapping information is read and recorded to the infobase
//  - information on objects types and their amount is collected.
//
// Parameters:
//      AnalysisParameters - Structure - not used, left for the compatibility purposes.
// 
Procedure ExecuteExchangeMessageAnalysis(AnalysisParameters = Undefined) Export
	
	DataImportMode = "ImportToValueTable";
	UseTransactions = False;
	
	ExchangeComponents = DataExchangeXDTOServer.InitializeExchangeComponents("Get");
	ExchangeComponents.KeepDataProtocol.OutputInfoMessagesToProtocol = OutputInfoMessagesToProtocol;
	ExchangeComponents.EventLogMessageKey = EventLogMessageKey;
	ExchangeComponents.CorrespondentNode = ExchangeNodeDataImport;
	ExchangeComponents.DataImportToInfobaseMode = False;
	
	DataExchangeXDTOServer.InitializeKeepExchangeProtocol(ExchangeComponents, ExchangeProtocolFileName);
	
	If IsBlankString(ExchangeFileName) Then
		DataExchangeXDTOServer.WriteToExecutionProtocol(ExchangeComponents, 15);
		DataExchangeXDTOServer.FinishKeepExchangeProtocol(ExchangeComponents);
		Return;
	EndIf;
	
	// Analysis start date
	ExchangeComponents.DataExchangeState.StartDate = CurrentSessionDate();
	
	DataExchangeXDTOServer.OpenImportFile(ExchangeComponents, ExchangeFileName);
	
	Cancel = False;
	AfterOpenImportFile(Cancel);
	
	If Cancel Then
		Return;
	EndIf;
	
	Try
		
		// Reading data from the exchange message.
		DataExchangeXDTOServer.ReadDataInAnalysisMode(ExchangeComponents, AnalysisParameters);
		
		// Generate a temporary data table.
		TemporaryPackageHeaderDataTable = ExchangeComponents.PackageHeaderDataTable.Copy(, "SourceTypeString, DestinationTypeString, SearchFields, TableFields");
		TemporaryPackageHeaderDataTable.GroupBy("SourceTypeString, DestinationTypeString, SearchFields, TableFields");
		
		// Grouping the data table of a data batch title.
		ExchangeComponents.PackageHeaderDataTable.GroupBy(
			"ObjectTypeString, SourceTypeString, DestinationTypeString, SynchronizeByID, IsClassifier, IsObjectDeletion, UsePreview",
			"ObjectCountInSource");
		
		ExchangeComponents.PackageHeaderDataTable.Columns.Add("SearchFields",  New TypeDescription("String"));
		ExchangeComponents.PackageHeaderDataTable.Columns.Add("TableFields", New TypeDescription("String"));
		
		For Each TableRow In ExchangeComponents.PackageHeaderDataTable Do
			
			Filter = New Structure;
			Filter.Insert("SourceTypeString", TableRow.SourceTypeString);
			Filter.Insert("DestinationTypeString", TableRow.DestinationTypeString);
			
			TemporaryTableRows = TemporaryPackageHeaderDataTable.FindRows(Filter);
			
			TableRow.SearchFields  = TemporaryTableRows[0].SearchFields;
			TableRow.TableFields = TemporaryTableRows[0].TableFields;
			
		EndDo;
		
	Except
		MessageString = NStr("ru = 'Ошибка при анализе данных: %1'; en = 'Data analysis error: %1'; pl = 'W czasie analizy danych wystąpił błąd: %1';de = 'Beim Analysieren der Daten ist ein Fehler aufgetreten: %1';ro = 'A apărut o eroare la analizarea datelor: %1';tr = 'Veri analiz edilirken bir hata oluştu: %1'; es_ES = 'Ha ocurrido un error al analizar los datos: %1'");
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, ErrorDescription());
		DataExchangeXDTOServer.WriteToExecutionProtocol(ExchangeComponents, MessageString,,,,,True);
	EndTry;
	
	ExchangeComponents.ExchangeFile.Close();
	
	DataExchangeXDTOServer.FinishKeepExchangeProtocol(ExchangeComponents);
	
EndProcedure

// imports data from the exchange message file to values table of specified objects types.
//
// Parameters:
//  TablesToImport - Array - array of types to be imported from the exchange message; array element - String
//          For example, to import from the exchange message the Counterparties catalog items only:
//             TablesToImport = New Array;
//             TablesToImport.Add("CatalogRef.Counterparties");
// 
//          You can receive the list of all types that are contained in the current exchange message 
//          by calling the ExecuteExchangeMessageAnalysis() procedure.
// 
Procedure ExecuteDataImportIntoValueTable(TablesToImport) Export
	
	DataImportMode = "ImportToValueTable";
	UseTransactions = False;
	
	InitializeRulesTables = (ExchangeComponents = Undefined);
	
	If ExchangeComponents = Undefined Then
		ExchangeComponents = DataExchangeXDTOServer.InitializeExchangeComponents("Get");
		ExchangeComponents.EventLogMessageKey = EventLogMessageKey;
		ExchangeComponents.KeepDataProtocol.OutputInfoMessagesToProtocol = OutputInfoMessagesToProtocol;
		ExchangeComponents.CorrespondentNode = ExchangeNodeDataImport;
	EndIf;
	
	DataExchangeXDTOServer.OpenImportFile(ExchangeComponents, ExchangeFileName);
	
	Cancel = False;
	AfterOpenImportFile(Cancel, InitializeRulesTables);
	
	If Cancel Then
		Return;
	EndIf;
	
	ExchangeComponents.DataExchangeState.StartDate = CurrentSessionDate();
	ExchangeComponents.DataImportToInfobaseMode = False;
	
	// Initialize data tables of the data exchange message.
	For Each DataTableKey In TablesToImport Do
		
		SubstringsArray = StrSplit(DataTableKey, "#");
		
		ObjectType = SubstringsArray[1];
		
		ExchangeComponents.DataTablesExchangeMessages.Insert(DataTableKey, InitExchangeMessageDataTable(Type(ObjectType)));
		
	EndDo;
	
	DataExchangeXDTOServer.ReadData(ExchangeComponents, TablesToImport);
	ExchangeComponents.ExchangeFile.Close();
	
EndProcedure

#EndRegion

#EndRegion

#Region Internal

// Stores an exchange file to a file storage service for subsequent mapping.
// Data is not imported.
//
Procedure PutMessageForDataMapping(XMLExportData) Export
	
	ExchangeComponents = DataExchangeXDTOServer.InitializeExchangeComponents("Get");
	
	ExchangeComponents.CorrespondentNode = ExchangeNodeDataImport;
	
	ExchangeComponents.EventLogMessageKey = EventLogMessageKey;
	ExchangeComponents.KeepDataProtocol.OutputInfoMessagesToProtocol = OutputInfoMessagesToProtocol;
	ExchangeComponents.DataExchangeState.StartDate = CurrentSessionDate();
	
	DataExchangeXDTOServer.InitializeKeepExchangeProtocol(ExchangeComponents, ExchangeProtocolFileName);
	
	If Not ValueIsFilled(XMLExportData) Then
		DataExchangeXDTOServer.WriteToExecutionProtocol(ExchangeComponents, 15);
		DataExchangeXDTOServer.FinishKeepExchangeProtocol(ExchangeComponents);
		
		FileID = "";
	Else
		DumpDirectory = DataExchangeServer.TempFilesStorageDirectory();
		TempFileName = DataExchangeServer.UniqueExchangeMessageFileName();
		
		TempFileFullName = CommonClientServer.GetFullFileName(
			DumpDirectory, TempFileName);
			
		TextDocument = New TextDocument;
		TextDocument.AddLine(XMLExportData);
		TextDocument.Write(TempFileFullName, , Chars.LF);
		
		FileID = DataExchangeServer.PutFileInStorage(TempFileFullName);
	EndIf;
	
	DataExchangeInternal.PutMessageForDataMapping(ExchangeNodeDataImport, FileID);
	
EndProcedure

#EndRegion

#Region Private

#Region OtherProceduresAndFunctions

Function InitExchangeMessageDataTable(ObjectType)
	
	ExchangeMessageDataTable = New ValueTable;
	
	Columns = ExchangeMessageDataTable.Columns;
	
	// required fields
	Columns.Add("UUID", New TypeDescription("String",, New StringQualifiers(36)));
	Columns.Add("TypeString",              New TypeDescription("String",, New StringQualifiers(255)));
	
	MetadataObject = Metadata.FindByType(ObjectType);
	
	// Getting a description of all metadata object fields from the configuration.
	ObjectPropertiesDescriptionTable = Common.ObjectPropertiesDetails(MetadataObject, "Name, Type");
	
	For Each PropertyDetails In ObjectPropertiesDescriptionTable Do
		
		Columns.Add(PropertyDetails.Name, PropertyDetails.Type);
		
	EndDo;
	
	ExchangeMessageDataTable.Indexes.Add("UUID");
	
	Return ExchangeMessageDataTable;
	
EndFunction

Function DataProcessorForDataImport()
	
	Return DataImportDataProcessorField;
	
EndFunction

Function IsExchangeOverExternalConnection()
	
	Return DataProcessorForDataImport() <> Undefined;
	
EndFunction

Procedure AfterOpenImportFile(Cancel = False, InitializeRulesTables = True)
	
	If ExchangeComponents.ErrorFlag Then
		DataExchangeXDTOServer.FinishKeepExchangeProtocol(ExchangeComponents);
		If ExchangeComponents.Property("ExchangeFile") Then
			ExchangeComponents.ExchangeFile.Close();
		EndIf;
		Cancel = True;
		Return;
	EndIf;
	
	If ExchangeComponents.IsExchangeViaExchangePlan Then
		
		If ExchangeComponents.DataExchangeWithExternalSystem Then
			CorrespondentNodeCode = TrimAll(Common.ObjectAttributeValue(ExchangeComponents.CorrespondentNode, "Code"));
			If ValueIsFilled(ExchangeComponents.CorrespondentID)
				AND Not CorrespondentNodeCode = ExchangeComponents.CorrespondentID Then
				CorrespondentNodeObject = ExchangeComponents.CorrespondentNode.GetObject();
				CorrespondentNodeObject.Code = ExchangeComponents.CorrespondentID;
				CorrespondentNodeObject.DataExchange.Load = True;
				CorrespondentNodeObject.Write();
				
				DataExchangeXDTOServer.WriteToExecutionProtocol(ExchangeComponents, 
					NStr("ru = 'Изменен идентификатор узла корреспондента.'; en = 'The peer node ID is changed.'; pl = 'Zmieniony identyfikator węzła korespondenta.';de = 'Die ID des entsprechenden Knotens wurde geändert.';ro = 'Identificatorul nodului corespondentului este modificat.';tr = 'Muhabir ünitesinin tanımlayıcısı değiştirildi.'; es_ES = 'Se ha modificado el identificador del nodo del correspondiente.'"), , False, , , True);
			EndIf;
		EndIf;
		
		DataExchangeXDTOServer.UpdateCorrespondentXDTOSettings(ExchangeComponents);
		DataExchangeXDTOServer.RefreshCorrespondentPrefix(ExchangeComponents);
		
		If Not ExchangeComponents.XDTOSettingsOnly
			AND InitializeRulesTables Then
			DataExchangeXDTOServer.InitializeExchangeRulesTables(ExchangeComponents);
			DataExchangeXDTOServer.FillXDTOSettingsStructure(ExchangeComponents);
			DataExchangeXDTOServer.FillSupportedXDTODataObjects(ExchangeComponents);
		EndIf;
	EndIf;
	
	If ExchangeComponents.XDTOSettingsOnly Then
		If ExchangeComponents.Property("ExchangeFile") Then
			ExchangeComponents.ExchangeFile.Close();
		EndIf;
		Cancel = True;
		Return;
	EndIf;
	
	If ExchangeComponents.IsExchangeViaExchangePlan Then
		ExchangePlanName = DataExchangeCached.GetExchangePlanName(ExchangeComponents.CorrespondentNode);
		
		If DataExchangeServer.HasExchangePlanManagerAlgorithm("DefaultValuesCheckHandler", ExchangePlanName) Then
			
			ErrorMessage = "";
			
			HandlerParameters = New Structure;
			HandlerParameters.Insert("Correspondent", ExchangeComponents.CorrespondentNode);
			HandlerParameters.Insert("SupportedXDTODataObjects", ExchangeComponents.SupportedXDTODataObjects);
			
			ExchangePlans[ExchangePlanName].DefaultValuesCheckHandler(Cancel, HandlerParameters, ErrorMessage);
			
			If Cancel Then
				DataExchangeXDTOServer.WriteToExecutionProtocol(ExchangeComponents, ErrorMessage);
				DataExchangeXDTOServer.FinishKeepExchangeProtocol(ExchangeComponents);
				Return;
			EndIf;
			
		EndIf;
	EndIf;
	
EndProcedure

Procedure AfterOpenExportFile(Cancel = False)
	
	If ExchangeComponents.ErrorFlag Then
		ExchangeComponents.ExchangeFile = Undefined;
		DataExchangeXDTOServer.FinishKeepExchangeProtocol(ExchangeComponents);
		Cancel = True;
		Return;
	EndIf;
	
	If ExchangeComponents.XDTOSettingsOnly Then
		// XDTO settings are sent only for file communication channels.
		ExchangeComponents.ExchangeFile.WriteEndElement(); // Message
		ExchangeComponents.ExchangeFile.Close();
		Cancel = True;
		Return;
	EndIf;
	
	ExchangePlanName = "";
	If ExchangeComponents.IsExchangeViaExchangePlan Then
		ExchangePlanName = DataExchangeCached.GetExchangePlanName(ExchangeComponents.CorrespondentNode);
	EndIf;
	
	If ExchangeComponents.IsExchangeViaExchangePlan
		AND DataExchangeServer.HasExchangePlanManagerAlgorithm("DataTransferLimitsCheckHandler", ExchangePlanName) Then
		
		ErrorMessage = "";
		
		HandlerParameters = New Structure;
		HandlerParameters.Insert("Correspondent", ExchangeComponents.CorrespondentNode);
		HandlerParameters.Insert("SupportedXDTODataObjects", ExchangeComponents.SupportedXDTODataObjects);
		
		ExchangePlans[ExchangePlanName].DataTransferLimitsCheckHandler(Cancel, HandlerParameters, ErrorMessage);
		
		If Cancel Then
			DataExchangeXDTOServer.WriteToExecutionProtocol(ExchangeComponents, ErrorMessage);
			DataExchangeXDTOServer.FinishKeepExchangeProtocol(ExchangeComponents);
			Return;
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Initializing

Parameters = New Structure;

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Niedozwolone wezwanie obiektu na kliencie.';de = 'Unzulässiger Objektaufruf auf dem Client.';ro = 'Apel inadmisibil al obiectului pe client.';tr = 'İstemcide kabul edilmeyen nesne çağrısı.'; es_ES = 'Llamada no disponible del objeto en el cliente.'");
#EndIf