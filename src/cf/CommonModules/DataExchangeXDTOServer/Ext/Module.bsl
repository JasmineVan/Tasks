﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

#Region ExchangeInitialization
// Adds a row to the conversion rule table and initializes the value in the Properties column.
// It is used in the exchange manager module upon filling the table of object conversion rules.
//
// Parameters:
//  ConversionRules - ValueTable - a table containing object conversion rules.
//
// Returns:
//  ValueTableRow - a value table row of conversion rules.
//
Function InitializeObjectConversionRule(ConversionRules) Export
	
	ConversionRule = ConversionRules.Add();
	ConversionRule.Properties = InitializePropertiesTableForConversionRule();
	Return ConversionRule;
	
EndFunction

// Initializes exchange components.
//
// Parameters:
//  ExchangeDirection - String - Sending or Receiving.
//
// Returns:
//  Structure - contains exchange components: exchange rules and exchange parameters.
//
Function InitializeExchangeComponents(ExchangeDirection) Export
	
	ExchangeComponents = New Structure;
	ExchangeComponents.Insert("ExchangeFormatVersion");
	ExchangeComponents.Insert("XMLSchema");
	ExchangeComponents.Insert("ExchangeManager");
	ExchangeComponents.Insert("CorrespondentNode");
	ExchangeComponents.Insert("CorrespondentNodeObject");
	ExchangeComponents.Insert("ExchangeManagerFormatVersion");
		
	ExchangeComponents.Insert("ExchangeDirection", ExchangeDirection);
	ExchangeComponents.Insert("IsExchangeViaExchangePlan", True);
	ExchangeComponents.Insert("ErrorFlag", False);
	ExchangeComponents.Insert("ErrorMessageString", "");
	ExchangeComponents.Insert("EventLogMessageKey", DataExchangeServer.EventLogMessageTextDataExchange());
	ExchangeComponents.Insert("UseAcknowledgement", True);
	
	ExchangeComponents.Insert("DataExchangeWithExternalSystem", False);
	ExchangeComponents.Insert("CorrespondentID",  "");
	
	ExchangeComponents.Insert("XDTOSettingsOnly", False);
	// The list of supported objects of the format for the current exchange session.
	// Contains a set of supported objects of this base and correspondent base within the specific 
	// exchange action (sending/receiving).
	// For more information, see DataExchangeXDTOServer.FillSupportedXDTODataObjects 
	ExchangeComponents.Insert("SupportedXDTODataObjects", New Array);
	
	DataExchangeState = New Structure;
	DataExchangeState.Insert("InfobaseNode");
	DataExchangeState.Insert("ActionOnExchange");
	DataExchangeState.Insert("StartDate");
	DataExchangeState.Insert("EndDate");
	DataExchangeState.Insert("ExchangeExecutionResult");
	ExchangeComponents.Insert("DataExchangeState", DataExchangeState);
	
	KeepDataProtocol = New Structure;
	KeepDataProtocol.Insert("DataProtocolFile", Undefined);
	KeepDataProtocol.Insert("OutputInfoMessagesToProtocol", False);
	KeepDataProtocol.Insert("AppendDataToExchangeLog", True);
	
	ExchangeComponents.Insert("KeepDataProtocol", KeepDataProtocol);
	
	ExchangeComponents.Insert("UseTransactions", True);
	
	// Structure of XDTO settings of this infobase.
	// Generates a supported object list (see SupportedXDTOObjects)
	// When sending, it is used to generate the header of the exchange message. In this case, it 
	// contains a list of all available format objects with detailed version information.
	ExchangeComponents.Insert("XDTOSettings", New Structure);
	ExchangeComponents.XDTOSettings.Insert("Format",                "");
	ExchangeComponents.XDTOSettings.Insert("SupportedObjects", New ValueTable);
	ExchangeComponents.XDTOSettings.Insert("SupportedVersions",  New Array);
	
	InitializeSupportedFormatObjectsTable(
		ExchangeComponents.XDTOSettings.SupportedObjects, "SendGet");
	
	If ExchangeDirection = "Send" Then
		
		ExchangeComponents.Insert("ExportedObjects", New Array);
		ExchangeComponents.Insert("ObjectsToExportCount", 0);
		ExchangeComponents.Insert("ExportedObjectCounter", 0);
		ExchangeComponents.Insert("MapRegistrationOnRequest", New Map);
		ExchangeComponents.Insert("ExportedByRefObjects", New Array);
		
		ExchangeComponents.Insert("ExportScenario");
		
		ExchangeComponents.Insert("ObjectsRegistrationRulesTable");
		ExchangeComponents.Insert("ExchangePlanNodeProperties");
		
		ExchangeComponents.Insert("SkipObjectsWithSchemaCheckErrors", False);
		ExchangeComponents.Insert("NotExportedObjects", New Array);
		
	Else
		
		ExchangeComponents.Insert("IncomingMessageNumber");
		ExchangeComponents.Insert("MessageNumberReceivedByCorrespondent");
		
		ExchangeComponents.Insert("DataImportToInfobaseMode", True);
		ExchangeComponents.Insert("ImportedObjectCounter", 0);
		ExchangeComponents.Insert("ObjectsPerTransaction", 0);
		ExchangeComponents.Insert("ObjectsToImportCount", 0);
		ExchangeComponents.Insert("ExchangeMessageFileSize", 0);
		
		DocumentsForDeferredPosting = New ValueTable;
		DocumentsForDeferredPosting.Columns.Add("DocumentRef");
		DocumentsForDeferredPosting.Columns.Add("DocumentDate",           New TypeDescription("Date"));
		DocumentsForDeferredPosting.Columns.Add("DocumentPostedSuccessfully", New TypeDescription("Boolean"));
		DocumentsForDeferredPosting.Columns.Add("IsCollision", New TypeDescription("Number"));
		ExchangeComponents.Insert("DocumentsForDeferredPosting", DocumentsForDeferredPosting);
		
		ImportedObjects = New ValueTable;
		ImportedObjects.Columns.Add("HandlerName");
		ImportedObjects.Columns.Add("Object");
		ImportedObjects.Columns.Add("Parameters");
		ImportedObjects.Columns.Add("ObjectRef");
		ImportedObjects.Indexes.Add("ObjectRef");
		ExchangeComponents.Insert("ImportedObjects", ImportedObjects);
		
		ObjectsCreatedByRefsTable = New ValueTable();
		ObjectsCreatedByRefsTable.Columns.Add("ObjectRef");
		ObjectsCreatedByRefsTable.Columns.Add("DeleteObjectsCreatedByKeyProperties");
		ObjectsCreatedByRefsTable.Indexes.Add("ObjectRef");
		ExchangeComponents.Insert("ObjectsCreatedByRefsTable", ObjectsCreatedByRefsTable);
		
		ExchangeComponents.Insert("PackageHeaderDataTable", NewDataBatchTitleTable());
		ExchangeComponents.Insert("DataTablesExchangeMessages", New Map);
		
		ExchangeComponents.Insert("ObjectsForDeferredPosting", New Map);
		
		// Structure of XDTO correspondent settings read from the exchange message.
		ExchangeComponents.Insert("XDTOCorrespondentSettings", New Structure);
		ExchangeComponents.XDTOCorrespondentSettings.Insert("Format",                "");
		ExchangeComponents.XDTOCorrespondentSettings.Insert("SupportedObjects", New ValueTable);
		ExchangeComponents.XDTOCorrespondentSettings.Insert("SupportedVersions",  New Array);
		
		InitializeSupportedFormatObjectsTable(
			ExchangeComponents.XDTOCorrespondentSettings.SupportedObjects, "SendGet");
		
		ExchangeComponents.Insert("CorrespondentPrefix");
		
		ExchangeComponents.Insert("DeleteObjectsCreatedByKeyProperties", False);
		ExchangeComponents.Insert("ObjectsMarkedForDeletion",         New Array);
		
	EndIf;
	
	Return ExchangeComponents;
	
EndFunction

// Initializes value tables with exchange rules and puts them in ExchangeComponents.
//
// Parameters:
//  ExchangeComponents - Structure - contains all exchange rules and parameters.
//
Procedure InitializeExchangeRulesTables(ExchangeComponents) Export
	
	ExchangeDirection = ExchangeComponents.ExchangeDirection;
	XMLSchema = ExchangeComponents.XMLSchema;
	ExchangeManager = ExchangeComponents.ExchangeManager;
	
	// Calculating a version of exchange manager format. Rules generation depends on it.
	Try
		ExchangeComponents.Insert("ExchangeManagerFormatVersion", ExchangeManager.ExchangeManagerFormatVersion());
	Except
		ExchangeComponents.Insert("ExchangeManagerFormatVersion", "1");
	EndTry;
	
	// Initializing exchange rule tables.
	ExchangeComponents.Insert("DataProcessingRules", DataProcessingRulesTable(XMLSchema, ExchangeManager, ExchangeDirection));
	ExchangeComponents.Insert("ObjectConversionRules", ConversionRulesTable(
		XMLSchema, ExchangeManager, ExchangeDirection, ExchangeComponents.DataProcessingRules, ExchangeComponents.ExchangeManagerFormatVersion));
	
	ExchangeComponents.Insert("PredefinedDataConversionRules",
		PredefinedDataConversionRulesTable(XMLSchema, ExchangeManager, ExchangeDirection));
	
	ExchangeComponents.Insert("ConversionParameters", ConversionParametersStructure(ExchangeManager));
	
EndProcedure

// Initializes a value table to store object property conversion rules.
//
// Returns:
//  ValueTable - a table storing property conversion rules.
//
Function InitializePropertiesTableForConversionRule() Export
	
	PCRTable = New ValueTable;
	PCRTable.Columns.Add("ConfigurationProperty", New TypeDescription("String"));
	PCRTable.Columns.Add("FormatProperty", New TypeDescription("String"));
	PCRTable.Columns.Add("PropertyConversionRule", New TypeDescription("String",,New StringQualifiers(50)));
	PCRTable.Columns.Add("UsesConversionAlgorithm", New TypeDescription("Boolean"));
	PCRTable.Columns.Add("KeyPropertyProcessing", New TypeDescription("Boolean"));
	PCRTable.Columns.Add("SearchPropertyHandler", New TypeDescription("Boolean"));
	PCRTable.Columns.Add("TSName", New TypeDescription("String"));

	Return PCRTable;
	
EndFunction

// Fills in a column with the tabular section properties with a blank value table with the certain columns.
// Used in the current module and exchange manager module upon filling the object conversion rules table.
//
// Parameters:
//  ConversionRule - ValueTableRow - an object conversion rule.
//  ColumnName - Row - a name of a conversion rule table column being filled in.
Procedure InitializeTabularSectionsProperties(ConversionRule, ColumnName = "TabularSectionsProperties") Export
	TabularSectionsProperties = New ValueTable;
	TabularSectionsProperties.Columns.Add("ConfigurationTabularSection",          New TypeDescription("String"));
	TabularSectionsProperties.Columns.Add("FormatTS",               New TypeDescription("String"));
	TabularSectionsProperties.Columns.Add("Properties",                New TypeDescription("ValueTable"));
	TabularSectionsProperties.Columns.Add("UsesConversionAlgorithm", New TypeDescription("Boolean"));
	
	ConversionRule[ColumnName] = TabularSectionsProperties;
EndProcedure

#EndRegion

#Region KeepProtocol
// Creates an object to write an exchange protocol and puts it in ExchangeComponents.
//
// Parameters:
//  ExchangeComponents        - Structure - contains all exchange rules and parameters.
//  ExchangeProtocolFileName - String - contains a full protocol file name.
//
Procedure InitializeKeepExchangeProtocol(ExchangeComponents, ExchangeProtocolFileName) Export
	
	ExchangeComponents.KeepDataProtocol.DataProtocolFile = Undefined;
	If Not IsBlankString(ExchangeProtocolFileName) Then
		
		// Attempting to write to an exchange protocol file.
		Try
			ExchangeComponents.KeepDataProtocol.DataProtocolFile = New TextWriter(
				ExchangeProtocolFileName,
				TextEncoding.UTF8,
				,
				ExchangeComponents.KeepDataProtocol.AppendDataToExchangeLog);
		Except
			
			MessageString = NStr("ru = 'Ошибка при попытке записи в файл протокола данных: %1. Описание ошибки: %2'; en = 'Cannot write to the log file %1. Error description: %2'; pl = 'Wystąpił błąd podczas próby zapisu do pliku protokołu danych: %1. Opis błędu: %2';de = 'Beim Schreiben in die Datenprotokolldatei ist ein Fehler aufgetreten: %1. Fehlerbeschreibung: %2';ro = 'A apărut o eroare la încercarea de scriere în fișierul protocolului de date: %1. Descrierea erorii: %2';tr = 'Veri iletişim kuralı %1dosyasına yazılmaya çalışırken bir hata oluştu. Hata açıklaması:%2'; es_ES = 'Ha ocurrido un error al intentar grabar para el archivo del protocolo de datos: %1. Descripción del error: %2'",
				Common.DefaultLanguageCode());
			MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, ExchangeProtocolFileName, ErrorDescription());
			
			WriteEventLogDataExchange(MessageString, ExchangeComponents, EventLogLevel.Warning);
			
		EndTry;
		
	EndIf;
	
EndProcedure

// Finishing writing to the exchange protocol.
//
// Parameters:
//  ExchangeComponents - Structure - contains all exchange rules and parameters.
//
Procedure FinishKeepExchangeProtocol(ExchangeComponents) Export
	
	If ExchangeComponents.KeepDataProtocol.DataProtocolFile <> Undefined Then
		
		ExchangeComponents.KeepDataProtocol.DataProtocolFile.Close();
		ExchangeComponents.KeepDataProtocol.DataProtocolFile = Undefined;
		
	EndIf;
	
EndProcedure

// Writes to a protocol or displays messages of the specified structure.
//
// Parameters:
//  ExchangeComponents - Structure - contains all exchange rules and parameters.
//  ErrorCode        - Number, String, Structure - an error information.
//                       Number - an error code, see DataExchangeCached.ErrorMessages(). 
//                       String - an error description.
//                       Structure - a structure with brief and detailed error descriptions.
//                         * BriefErrorPresentation - an error description for end users.
//                         * DetailedErrorPresentation - an error description for the event log.
//                         * Level - EventLogLevel - an error importance level.
//  RecordStructure   - Structure - a protocol record structure.
//  SetErrorsFlag - Boolean - if true, then it is an error message. Setting ErrorFlag.
//  Level           - Number - a left indent, a number of tabs.
//  Align      - Number - an indent in the text to align the text displayed as Key - Value.
//  UnconditionalWriteToExchangeProtocol - Boolean - shows that the information is written to the protocol unconditionally.
//
// Returns:
//  String - an error text written to the log.
//
Function WriteToExecutionProtocol(ExchangeComponents,
		ErrorCode = "",
		RecordStructure = Undefined,
		SetErrorFlag = True,
		Level = 0,
		Align = 22,
		UnconditionalWriteToExchangeProtocol = False) Export
	
	DataProtocolFile = ExchangeComponents.KeepDataProtocol.DataProtocolFile;
	OutputInfoMessagesToProtocol = ExchangeComponents.KeepDataProtocol.OutputInfoMessagesToProtocol;
	
	Indent = "";
	For Cnt = 0 To Level - 1 Do
		Indent = Indent + Chars.Tab;
	EndDo; 
	
	BriefErrorPresentation   = "";
	DetailedErrorPresentation = "";
	
	If TypeOf(ErrorCode) = Type("Number") Then
		
		ErrorMessages = DataExchangeCached.ErrorMessages();
		
		BriefErrorPresentation   = ErrorMessages[ErrorCode];
		DetailedErrorPresentation = ErrorMessages[ErrorCode];
		
	ElsIf TypeOf(ErrorCode) = Type("Structure") Then
		
		ErrorCode.Property("BriefErrorPresentation",   BriefErrorPresentation);
		ErrorCode.Property("DetailedErrorPresentation", DetailedErrorPresentation);
		
	Else
		
		BriefErrorPresentation   = ErrorCode;
		DetailedErrorPresentation = ErrorCode;
		
	EndIf;

	BriefErrorPresentation   = Indent + String(BriefErrorPresentation);
	DetailedErrorPresentation = Indent + String(DetailedErrorPresentation);
	
	If RecordStructure <> Undefined Then
		
		For Each Field In RecordStructure Do
			
			Value = Field.Value;
			If Value = Undefined Then
				Continue;
			EndIf; 
			
			BriefErrorPresentation  = BriefErrorPresentation + Chars.LF + Indent + Chars.Tab
				+ StringFunctionsClientServer.SupplementString(Field.Key, Align, " ", "Right") + " =  " + String(Value);
			DetailedErrorPresentation  = DetailedErrorPresentation + Chars.LF + Indent + Chars.Tab
				+ StringFunctionsClientServer.SupplementString(Field.Key, Align, " ", "Right") + " =  " + String(Value);
			
		EndDo;
		
	EndIf;
	
	ExchangeComponents.ErrorMessageString = BriefErrorPresentation;
	
	If SetErrorFlag Then
		
		ExchangeComponents.ErrorFlag = True;
		If ExchangeComponents.DataExchangeState.ExchangeExecutionResult = Undefined Then
			ExchangeComponents.DataExchangeState.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Error;
		EndIf;
		
	EndIf;
	
	If DataProtocolFile <> Undefined Then
		
		If SetErrorFlag Then
			
			DataProtocolFile.WriteLine(Chars.LF + "Error.");
			
		EndIf;
		
		If SetErrorFlag
			Or UnconditionalWriteToExchangeProtocol
			Or OutputInfoMessagesToProtocol Then
			
			DataProtocolFile.WriteLine(Chars.LF + ExchangeComponents.ErrorMessageString);
		
		EndIf;
		
	EndIf;
	
	ELLevel = Undefined;
	If Not TypeOf(ErrorCode) = Type("Structure")
		Or Not ErrorCode.Property("Level", ELLevel)
		Or ELLevel = Undefined Then
		
		If ExchangeExecutionResultError(ExchangeComponents.DataExchangeState.ExchangeExecutionResult) Then
			ELLevel = EventLogLevel.Error;
		ElsIf ExchangeExecutionResultWarning(ExchangeComponents.DataExchangeState.ExchangeExecutionResult) Then
			ELLevel = EventLogLevel.Warning;
		Else
			ELLevel = EventLogLevel.Information;
		EndIf;
		
	EndIf;
	
	RefPosition = StrFind(DetailedErrorPresentation, "e1cib/data/");
	If RefPosition > 0 Then
		UIDPosition = StrFind(DetailedErrorPresentation, "?ref=");
		RefRow = Mid(DetailedErrorPresentation, RefPosition, UIDPosition - RefPosition + 37);
		FirstPoint = StrFind(RefRow, "e1cib/data/");
		SecondPoint = StrFind(RefRow, "?ref=");
		TypePresentation = Mid(RefRow, FirstPoint + 11, SecondPoint - FirstPoint - 11);
		ValueTemplate = ValueToStringInternal(PredefinedValue(TypePresentation + ".EmptyRef"));
		RefValue = StrReplace(ValueTemplate, "00000000000000000000000000000000", Mid(RefRow, SecondPoint + 5));
		ObjectRef = ValueFromStringInternal(RefValue);
	Else
		ObjectRef = Undefined;
	EndIf;
	
	// Registering an event in the event log.
	WriteEventLogDataExchange(
		DetailedErrorPresentation,
		ExchangeComponents,
		ELLevel,
		ObjectRef);
	
	Return ExchangeComponents.ErrorMessageString;
	
EndFunction

#EndRegion

#Region ExchangeRulesSearch
// Searches for an object conversion rule by name.
//
// Parameters:
//  ExchangeComponents - Structure - contains all exchange rules and parameters.
//  Name              - String - a rule name.
//
// Returns:
//  ValueTableRow - a conversion rules table row containing the searched rule.
//
Function OCRByName(ExchangeComponents, Name) Export
	
	ConversionRule = ExchangeComponents.ObjectConversionRules.Find(Name, "OCRName");
	
	If ConversionRule = Undefined Then
		
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Не найдено ПКО с именем %1'; en = 'Object conversion rule ""%1"" is not found.'; pl = 'Nie znaleziono przyjęcia kasowego o nazwie %1';de = 'Einzahlungsschein mit Namen %1 nicht gefunden';ro = 'Regula de conversie a datelor cu numele %1 nu a fost găsită';tr = '%1İsimli Nakit tahsilat fişi bulunamadı'; es_ES = 'Comprobante de crédito con el nombre %1 no encontrado'"), Name);
			
	Else
		Return ConversionRule;
	EndIf;

EndFunction

#EndRegion

#Region DataSending
// Exports data according to exchange rules and parameters.
//
// Parameters:
//  ExchangeComponents - Structure - contains all exchange rules and parameters.
//
Procedure ExecuteDataExport(ExchangeComponents) Export
	
	NodeForExchange = ExchangeComponents.CorrespondentNode;
	
	If ExchangeComponents.IsExchangeViaExchangePlan Then
		ClearErrorsListOnExportData(NodeForExchange);
	EndIf;
	
	Try
		ExchangeComponents.ExchangeManager.BeforeConvert(ExchangeComponents);
	Except
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Направление: %1.
			|Обработчик: ПередКонвертацией.
			|
			|Ошибка выполнения обработчика.
			|%2.'; 
			|en = 'Direction: %1.
			|Handler: BeforeConvert.
			|
			|Handler execution error.
			|%2.'; 
			|pl = 'Kierunek: %1.
			|Procedura przetwarzania: ПередКонвертацией.
			|
			|Błąd wykonania programu przetwarzania.
			|%2.';
			|de = 'Richtung: %1.
			|Handler: VorDerKonvertierung.
			|
			|Fehler bei der Ausführung des Handlers.
			|%2.';
			|ro = 'Direcția: %1.
			|Handlerul: ПередКонвертацией.
			|
			|Eroare de executare a handlerului.
			|%2.';
			|tr = 'Yön: %1. 
			| İşleyici: DönüştürmedenÖnce. 
			|
			| İşleyici yürütme hatası. 
			|%2.'; 
			|es_ES = 'Dirección: %1.
			|Procesador: ПередКонвертацией.
			|
			|Error de ejecutar el procesador.
			|%2.'"),
			ExchangeComponents.ExchangeDirection,
			DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	SentMessageNumber = 0;
	
	If ExchangeComponents.IsExchangeViaExchangePlan Then
	
		SentMessageNumber = Common.ObjectAttributeValue(NodeForExchange, "SentNo") + 1;
		
		ExecuteRegisteredDataExport(ExchangeComponents, SentMessageNumber);
		
	Else
		
		For Each Row In ExchangeComponents.ExportScenario Do
			ProcessingRule = DPRByName(ExchangeComponents, Row.DPRName);
			
			DataSelection = DataSelection(ExchangeComponents, ProcessingRule);
			For Each SelectionObject In DataSelection Do
				ExportSelectionObject(ExchangeComponents, SelectionObject, ProcessingRule);
			EndDo;
		EndDo;
		
	EndIf;
	
	If ExchangeComponents.ErrorFlag Then
		Raise NStr("ru = 'При формировании сообщения обмена данными произошли ошибки. Подробнее см. в журнале регистрации.'; en = 'Errors occurred while generating a data exchange message. For more information, see the event log.'; pl = 'Wystąpił błąd podczas generowania komunikatu wymiany danych. Szczegółowe informacje można znaleźć w dzienniku rejestracji.';de = 'Beim Erzeugen der Kommunikationsmeldung sind Fehler aufgetreten. Siehe das Logbuch für Details.';ro = 'Erori la generarea mesajului schimbului de date. Detalii vezi în registrul logare.';tr = 'Veri alışverişi mesajı oluşturulurken hatalar oluştu. Daha fazla bilgi için bkz. kayıt günlüğü.'; es_ES = 'Al generar el mensaje de intercambio de daros se han producido errores. Véase más en el registro de eventos.'");
	EndIf;
	
	Try
		ExchangeComponents.ExchangeManager.AfterConvert(ExchangeComponents);
	Except
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Событие: %1.
				|Обработчик: ПослеКонвертации.
				|
				|Ошибка выполнения обработчика.
				|%2.'; 
				|en = 'Event: %1.
				|Handler: AfterConvert.
				|
				|Handler execution error.
				|%2.'; 
				|pl = 'Zdarzenie: %1.
				|Procedura przetwarzania: ПослеКонвертации.
				|
				|Błąd wykonania programu przetwarzania.
				|%2.';
				|de = 'Veranstaltung: %1.
				|Handler: NachDerKonvertierung.
				|
				|Fehler bei der Ausführung des Handlers:
				|%2.';
				|ro = 'Evenimentul: %1.
				|Handlerul: ПослеКонвертации.
				|
				|Eroare de executare a handlerului.
				|%2.';
				|tr = 'Olay: %1. 
				| İşleyici: DönüştürmedenSonra. 
				|
				| İşleyici yürütme hatası. 
				|%2.'; 
				|es_ES = 'Evento: %1.
				|Procesador: ПослеКонвертации.
				|
				|Error de ejecutar el procesador.
				|%2.'"),
			ExchangeComponents.ExchangeDirection,
			DetailErrorDescription(ErrorInfo()));
		Raise ErrorText;
	EndTry;
	
	If ExchangeComponents.IsExchangeViaExchangePlan Then
		
		// Resetting the sent message number for non-exported objects.
		If ExchangeComponents.SkipObjectsWithSchemaCheckErrors Then
			For Each ObjectRef In ExchangeComponents.NotExportedObjects Do
				ExchangePlans.RecordChanges(NodeForExchange, ObjectRef);
			EndDo;
		EndIf;
		
		// Setting the number of sent message for objects exported by reference.
		If ExchangeComponents.ExportedByRefObjects.Count() > 0 Then
			// Registering the selected exported by reference objects on the current node.
			For Each Item In ExchangeComponents.ExportedByRefObjects Do
				ExchangePlans.RecordChanges(NodeForExchange, Item);
			EndDo;
			
			DataExchangeServer.SelectChanges(NodeForExchange, SentMessageNumber, ExchangeComponents.ExportedByRefObjects);
		EndIf;
		
		Recipient = NodeForExchange.GetObject();
		Recipient.SentNo = SentMessageNumber;
		Recipient.DataExchange.Load = True;
		Recipient.Write();
		
	EndIf;
	
	ExchangeComponents.ExchangeFile.WriteEndElement(); // Body
	ExchangeComponents.ExchangeFile.WriteEndElement(); // Message
	
	// Recording successful exchange completion.
	If ExchangeComponents.DataExchangeState.ExchangeExecutionResult = Undefined Then
		ExchangeComponents.DataExchangeState.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Completed;
	EndIf;
	
	If ExchangeComponents.DataExchangeState.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Completed
		AND (ExchangeComponents.SkipObjectsWithSchemaCheckErrors
			AND ExchangeComponents.NotExportedObjects.Count() > 0) Then
		ExchangeComponents.DataExchangeState.ExchangeExecutionResult = Enums.ExchangeExecutionResults.CompletedWithWarnings;
	EndIf;
	
EndProcedure

// Exports an infobase object.
//
// Parameters:
//  ExchangeComponents - Structure - contains all exchange rules and parameters.
//  Object           - AnyRef - a reference to an infobase object.
//  ProcessingRule - ValueTableRow - a row of the table of data processing rule values matching the 
//                     processing rule of the object type being exported.
//                     If ProcessingRule is not specified, it will be found by a metadata object of the object being exported.
//
Procedure ExportSelectionObject(ExchangeComponents, Object, ProcessingRule = Undefined) Export
	
	RefTypeObject = (TypeOf(Object) <> Type("Structure"))
		AND Common.IsRefTypeObject(Object.Metadata());
		
	If (TypeOf(Object) <> Type("Structure"))
		AND ProcessingRule = Undefined Then
		GetProcessingRuleForObject(ExchangeComponents, Object, ProcessingRule);
	EndIf;
	
	ExchangeComponents.ExportedObjects.Add(?(RefTypeObject, Object.Ref, Object));
	
	// DPR processing
	OCRUsage = New Structure;
	For Each CurrentOCR1 In ProcessingRule.CashReceiptsUsed Do
		OCRUsage.Insert(CurrentOCR1, True);
	EndDo;
	
	AbortProcessing = False;
	SetErrorFlag = False;
	
	OnProcessExchangePlan(
		ExchangeComponents,
		ProcessingRule,
		Object,
		OCRUsage,
		AbortProcessing);
	
	If AbortProcessing Then
		SetErrorFlag = True;
	EndIf;
	
	If Not AbortProcessing Then
		// OCR processing
		SeveralOCR = (OCRUsage.Count() > 1);
		HasDataClearingColumn = ExchangeComponents.DataProcessingRules.Columns.Find("DataClearing") <> Undefined;
		
		For Each CurrentOCR In OCRUsage Do
			ConversionRule = ExchangeComponents.ObjectConversionRules.Find(CurrentOCR.Key, "OCRName");
			If ConversionRule = Undefined Then
				// An OCR not intended for the current data format  version can be specified.
				Continue;
			EndIf;
			
			If Not FormatObjectPassesXDTOFilter(ExchangeComponents, ConversionRule.FormatObject) Then
				Continue;
			EndIf;
			
			If Not CurrentOCR.Value Then
				// If there are several conversion rules and some of them are not used, export the object deletion 
				// if it was exported according to these rules before.
				If SeveralOCR
					AND RefTypeObject 
					AND (Not HasDataClearingColumn
						Or ProcessingRule.DataClearing) Then
					ExportDeletion(ExchangeComponents, Object.Ref, ConversionRule);
				EndIf;
				Continue;
			EndIf;
			
			SkipProcessing = False;
			Try
				// 2. Converting data to Structure by conversion rules.
				XDTOData = XDTODataFromIBData(ExchangeComponents, Object, ConversionRule, Undefined);
				
				If XDTOData = Undefined Then
					Continue;
				EndIf;
				
				// 3. Convert Structure to XDTODataObject.
				RefsFromObject = New Array;
				XDTODataObject = XDTODataObjectFromXDTOData(ExchangeComponents, XDTOData, ConversionRule.XDTOType, , RefsFromObject);
			Except
				SkipProcessing = True;
				SetErrorFlag   = True;
				
				ErrorDescription = OCRErrorDescription(
					ExchangeComponents.ExchangeDirection,
					ProcessingRule.Name,
					ConversionRule.OCRName,
					ObjectPresentationForProtocol(Object),
					ErrorInfo());
					
				RecordIssueOnProcessObject(ExchangeComponents,
					Object,
					Enums.DataExchangeIssuesTypes.HandlersCodeExecutionErrorOnSendData,
					ErrorDescription.DetailedPresentation,
					ErrorDescription.BriefPresentation);
			EndTry;
				
			If Not SkipProcessing Then
				CheckBySchemaError = False;
				CheckBySchemaErrorDescription = Undefined;
				
				Context = New Structure;
				Context.Insert("ExchangeDirection",    ExchangeComponents.ExchangeDirection);
				Context.Insert("DPRName",               ProcessingRule.Name);
				Context.Insert("OCRName",               ConversionRule.OCRName);
				Context.Insert("ObjectPresentation", ObjectPresentationForProtocol(Object));
				
				CheckXDTOObjectBySchema(XDTODataObject, ConversionRule.XDTOType, Context, CheckBySchemaError, CheckBySchemaErrorDescription);
				
				If CheckBySchemaError Then
					SkipProcessing = True;
					
					RecordIssueOnProcessObject(ExchangeComponents,
						Object,
						Enums.DataExchangeIssuesTypes.ConvertedObjectValidationError,
						CheckBySchemaErrorDescription.DetailedPresentation,
						CheckBySchemaErrorDescription.BriefPresentation);
				EndIf;
			EndIf;
		
			If SkipProcessing Then
				AbortProcessing = True;
				Continue;
			EndIf;
			
			ExportObjectsByRef(ExchangeComponents, RefsFromObject);
			
			// 4. Write XDTODataObject to an XML file.
			XDTOFactory.WriteXML(ExchangeComponents.ExchangeFile, XDTODataObject);
		EndDo;
	EndIf;
	
	If AbortProcessing Then
		ExchangeComponents.NotExportedObjects.Add(?(RefTypeObject, Object.Ref, Object));
	EndIf;
	
	If SetErrorFlag Then
		ExchangeComponents.ErrorFlag = True;
		ExchangeComponents.DataExchangeState.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Error;
	EndIf;
	
EndProcedure

// Converts a structure with data to an XDTO object of the specified type according to the rules.
//
// Parameters:
//  ExchangeComponents - Structure - contains all exchange rules and parameters.
//  Source         - Structure - a source of data to convert into XDTO object.
//  XDTOType          - String - an object type or an XDTO value type, to which the data is to be converted.
//  Destination         - XDTODataObject - an object, to which the result is placed.
//  RefsFromObject  - Array - contains a general list of objects exported by references.
//  PropertiesAreFilled - Boolean - a parameter to define fullness of common composite properties.
//
// Returns:
//  XDTODataObject - a conversion result.
// 
Function XDTODataObjectFromXDTOData(
		ExchangeComponents,
		Val Source,
		Val XDTOType,
		Destination = Undefined,
		RefsFromObject = Undefined,
		PropertiesAreFilled = False) Export
	
	If RefsFromObject = Undefined Then
		RefsFromObject = New Array;
	EndIf;
	
	If Destination = Undefined Then
		Destination = XDTOFactory.Create(XDTOType);
	EndIf;
	
	For Each Property In XDTOType.Properties Do
		
		PropertyValue = Undefined;
		PropertyFound = False;
		
		If TypeOf(Source) = Type("Structure") Then
			PropertyFound = Source.Property(Property.Name, PropertyValue);
		ElsIf TypeOf(Source) = Type("ValueTableRow")
			AND Source.Owner().Columns.Find(Property.Name) <> Undefined Then
			PropertyFound = True;
			PropertyValue = Source[Property.Name];
		EndIf;
		
		PropertyType = Undefined;
		If TypeOf(Property.Type) = Type("XDTOValueType") Then
			PropertyType = "RegularProperty";
		ElsIf TypeOf(Property.Type) = Type("XDTOObjectType") Then
			
			If Property.Name = "AdditionalInfo" Then
				PropertyType = "AdditionalInfo";
			ElsIf IsObjectTable(Property) Then
				PropertyType = "Table";
			ElsIf Property.Name = "KeyProperties"
				Or StrFind(Property.Type.Name, "KeyProperties") > 0 Then
				PropertyType = "KeyProperties";
			Else
				If PropertyFound Then
					If TypeOf(PropertyValue) = Type("Structure") 
						AND (PropertyValue.Property("Value")
							Or StrFind(TrimAll(Property.Type), "CommonProperties") > 0) Then
						PropertyType = "CommonCompositeProperty";
					Else
						PropertyType = "CompositeTypeProperty";
					EndIf;
				Else
					PropertyType = "CommonCompositeProperty";
				EndIf;
			EndIf;
			
		Else
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Неизвестный тип свойства <%1>. Тип объекта: %2'; en = 'Unknown type of %1 property. Object type: %2'; pl = 'Nieznany typ właściwości <%1>. Rodzaj obiektu: %2';de = 'Unbekannter Eigenschaftstyp <%1>. Objekttyp: %2';ro = 'Tip de proprietate necunoscut <%1>. Tipul obiectului: %2';tr = 'Bilinmeyen özellik türü <%1>. Nesne türü:%2'; es_ES = 'Tipo de la propiedad desconocido <%1>. Tipo de objeto: %2'"),
				Property.Name,
				String(XDTOType));
		EndIf;
		
		Try
			If PropertyType = "CommonCompositeProperty" Then
				
				NestedPropertiesAreFilled = False;
				If TypeOf(Source) = Type("Structure") AND PropertyFound Then
					XDTOValue = XDTODataObjectFromXDTOData(ExchangeComponents, PropertyValue, 
						Property.Type,, RefsFromObject, NestedPropertiesAreFilled);
				Else
					XDTOValue = XDTODataObjectFromXDTOData(ExchangeComponents, Source, 
						Property.Type,, RefsFromObject, NestedPropertiesAreFilled);
				EndIf;
				
				If Not NestedPropertiesAreFilled Then
					Continue;
				EndIf;
				
			Else
				
				If Not PropertyFound Then
					Continue;
				EndIf;
				
				// Fullness check.
				If PropertyValue = Null
					Or Not ValueIsFilled(PropertyValue) Then
					
					If Property.Nillable Then
						Destination[Property.Name] = Undefined;
					EndIf;
					
					Continue;
					
				EndIf;
				
				XDTOValue = Undefined;
				If PropertyType = "KeyProperties" Then
					XDTOValue = XDTODataObjectFromXDTOData(ExchangeComponents, PropertyValue, Property.Type,,RefsFromObject);
				ElsIf PropertyType = "RegularProperty" Then
					
					If IsXDTORef(Property.Type) Then // Reference conversion
						
						XDTOValue = ConvertRefToXDTO(ExchangeComponents, PropertyValue, Property.Type);
						
						If RefsFromObject.Find(PropertyValue) = Undefined Then
							RefsFromObject.Add(PropertyValue);
						EndIf;
						
					ElsIf Property.Type.Facets <> Undefined
						AND Property.Type.Facets.Enumerations <> Undefined
						AND Property.Type.Facets.Enumerations.Count() > 0 Then // Enumeration conversion
						XDTOValue = ConvertEnumerationToXDTO(ExchangeComponents, PropertyValue, Property.Type);
					Else // Common value conversion.
						XDTOValue = XDTOFactory.Create(Property.Type, PropertyValue);
					EndIf;
				ElsIf PropertyType = "AdditionalInfo" Then
					XDTOValue = XDTOSerializer.WriteXDTO(PropertyValue);
					
				ElsIf PropertyType = "Table" Then
					
					XDTOValue = XDTOFactory.Create(Property.Type);
					
					TableType = Property.Type.Properties[0].Type;
					
					StringPropertyName = Property.Type.Properties[0].Name;
					
					For Each StringSource In PropertyValue Do
						
						DestinationRow = XDTODataObjectFromXDTOData(ExchangeComponents, StringSource, TableType,,RefsFromObject);
						
						XDTOValue[StringPropertyName].Add(DestinationRow);
						
					EndDo;
					
				ElsIf PropertyType = "CompositeTypeProperty" Then
					
					For Each CompositeTypeProperty In Property.Type.Properties Do
						
						XDTOCompositeValue = Undefined;
						If TypeOf(PropertyValue) = Type("Structure")
							AND PropertyValue.CompositePropertyType = CompositeTypeProperty.Type Then
							
							// Composite type property containing items only of the KeyProperties type.
							XDTOCompositeValue = XDTODataObjectFromXDTOData(ExchangeComponents, PropertyValue, CompositeTypeProperty.Type,,RefsFromObject);
						// Simple composite type property and simple value.
						ElsIf (TypeOf(PropertyValue) = Type("String")
							AND StrFind(CompositeTypeProperty.Type.Name,"string")>0)
							OR (TypeOf(PropertyValue) = Type("Number")
							AND StrFind(CompositeTypeProperty.Type.Name,"decimal")>0)
							OR (TypeOf(PropertyValue) = Type("Boolean")
							AND StrFind(CompositeTypeProperty.Type.Name,"boolean")>0)
							OR (TypeOf(PropertyValue) = Type("Date")
							AND StrFind(CompositeTypeProperty.Type.Name,"date")>0) Then
							XDTOCompositeValue = PropertyValue;

						ElsIf TypeOf(PropertyValue) = Type("String")
							AND TypeOf(CompositeTypeProperty.Type) = Type("XDTOValueType")
							AND CompositeTypeProperty.Type.Facets <> Undefined Then
							If CompositeTypeProperty.Type.Facets.Count() = 0 Then
								XDTOCompositeValue = PropertyValue;
							Else
								
								For Each Facet In CompositeTypeProperty.Type.Facets Do
									If Facet.Value = PropertyValue Then
										XDTOCompositeValue = PropertyValue;
										Break;
									EndIf;
								EndDo;
								
							EndIf;
						EndIf;
						
						If XDTOCompositeValue <> Undefined Then
							Break;
						EndIf;
						
					EndDo;
					
					// If a value of the type not supported in the format is passed, do not pass.
					If XDTOCompositeValue = Undefined Then
						Continue;
					EndIf;
					
					XDTOValue = XDTOFactory.Create(Property.Type);
					XDTOValue.Set(CompositeTypeProperty, XDTOCompositeValue);
				EndIf;
				
			EndIf;
		Except
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Ошибка формирования объекта XDTO: Тип свойства <%1>. Имя свойства: <%2>.
				|
				|%3'; 
				|en = 'XDTO object generation error. Property type: %1. Property name: %2.
				|
				|%3'; 
				|pl = 'Błąd tworzenia obiektu XDTO: Typ właściwości <%1>. Nazwa właściwości: <%2>.
				|
				|%3';
				|de = 'XDTO Objektbildungsfehler: Eigenschaftstyp <%1>. Eigenschaftsname: <%2>.
				|
				|%3';
				|ro = 'Eroare de generare a obiectului XDTO: Tipul proprietății <%1>. Numele proprietății: <%2>.
				|
				|%3';
				|tr = 'XDTO nesnesini oluşturma hatası: Özellik türü <%1>. Özellik adı: <%2>.
				|
				|%3'; 
				|es_ES = 'Error al generar el objeto XDTO: Tipo de propiedad <%1>. Nombre de propiedad: <%2>.
				|
				|%3'"),
				PropertyType,
				Property.Name,
				DetailErrorDescription(ErrorInfo()));
		EndTry;
		
		Destination[Property.Name] = XDTOValue;
		PropertiesAreFilled = True;
		
	EndDo;
	
	Return Destination;
EndFunction

// Converts infobase data into the structure with data according to rules.
//
// Parameters:
//  ExchangeComponents   - Structure - contains all exchange rules and parameters.
//  Source            - AnyRef - a reference to an infobase object being exported.
//  ConversionRule  - ValueTableRow - a row of table of object conversion rules according to which 
//                        the conversion is carried out.
//  ExportStack        - array - references to the objects being exported depending on nesting.
//
// Returns:
//  Structure - a conversion result.
//
Function XDTODataFromIBData(ExchangeComponents, Source, Val ConversionRule, ExportStack = Undefined) Export
	
	Destination = New Structure;
	
	If ExportStack = Undefined Then
		ExportStack = New Array;
	EndIf;
	
	If ConversionRule.IsReferenceType Then
		
		PositionInStack = ExportStack.Find(Source.Ref);
		
		// Checking whether the object is exported by reference to avoid looping.
		If PositionInStack <> Undefined Then
			
			If PositionInStack > 0 Then
				Return Undefined;
			ElsIf ExportStack.Count() > 1 Then
				// Iteration search is required.
				FirstIteration = True;
				For Each StackItem In ExportStack Do
					If FirstIteration Then
						FirstIteration = False;
						Continue;
					EndIf;
					If StackItem = Source.Ref Then
						Return Undefined;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
		
		ExportStack.Add(Source.Ref);
		
		If Not Common.RefExists(Source.Ref) Then
			Return Undefined;
		EndIf;
		
	Else
		ExportStack.Add(Source);
	EndIf;
	
	If ConversionRule.IsConstant Then
		
		If ConversionRule.XDTOType.Properties.Count() = 1 Then
			
			Destination.Insert(ConversionRule.XDTOType.Properties[0].Name, Source.Value);
			
		Else
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Ошибка XML-схемы. Для приемника должно быть задано одно свойство.
				|Тип источника: %1
				|Тип приемника: %2'; 
				|en = 'XML schema error. A single property must be set for the destination.
				|Source type: %1
				|Destination type: %2'; 
				|pl = 'Błąd XML-schematu. Dla odbiorcy musi być podana jedna właściwość.
				|Typ źródła: %1
				|Typ odbiornika: %2';
				|de = 'XML-Schema-Fehler. Für den Empfänger muss eine Eigenschaft angegeben werden.
				|Art der Quelle: %1
				|Typ des Empfängers: %2';
				|ro = 'Eroare în schema XML. Pentru receptor trebuie să fie setată o proprietate.
				|Tipul sursei:
				|%1Tipul receptorului: %2';
				|tr = 'XML Şeması hatası. Bir özellik alıcı için ayarlanmalıdır. 
				|Kaynak türü: 
				|%1Alıcı türü:%2'; 
				|es_ES = 'Error del esquema-XML. Una propiedad tiene que estar establecida para un receptor.
				|Tipo de fuente:%1
				|Tipo de receptor: %2'"),
				String(TypeOf(Source)),
				ConversionRule.XDTOType);
		EndIf;
		
	Else
		
		// PCR Execution, stage 1
		For Each PCR In ConversionRule.Properties Do
			
			If ConversionRule.DataObject <> Undefined
				AND PCR.ConfigurationProperty = ""
				AND PCR.UsesConversionAlgorithm Then
				Continue;
			EndIf;
			
			If ExportStack.Count() > 1 AND Not PCR.KeyPropertyProcessing Then
				Continue;
			EndIf;
			
			ExportProperty(
				ExchangeComponents,
				Source,
				Destination,
				PCR,
				ExportStack,
				1);
		EndDo;
		
		// PCR Execution for tabular sections (direct conversion).
		If ExportStack.Count() = 1 Then
			For Each TabularSectionsAndProperties In ConversionRule.TabularSectionsProperties Do
				If NOT (ValueIsFilled(TabularSectionsAndProperties.ConfigurationTabularSection) AND ValueIsFilled(TabularSectionsAndProperties.FormatTS)) Then
					Continue;
				EndIf;
				// Empty tabular section.
				If Source[TabularSectionsAndProperties.ConfigurationTabularSection].Count() = 0 Then
					Continue;
				EndIf;
				NewDestinationTS = CreateDestinationTSByPCR(TabularSectionsAndProperties.Properties);
				For Each ConfigurationTSRow In Source[TabularSectionsAndProperties.ConfigurationTabularSection] Do
					TSRowDestination = NewDestinationTS.Add();
					For Each PCR In TabularSectionsAndProperties.Properties Do
						If PCR.UsesConversionAlgorithm Then
							Continue;
						EndIf;
						ExportProperty(
							ExchangeComponents,
							ConfigurationTSRow,
							TSRowDestination,
							PCR,
							ExportStack,
							1);
					EndDo;
				EndDo;
				Destination.Insert(TabularSectionsAndProperties.FormatTS, NewDestinationTS);
			EndDo;
		EndIf;
		
		// {Handler: OnSendData} Start
		If ConversionRule.HasHandlerOnSendData Then
			
			If Not Destination.Property("KeyProperties") Then
				Destination.Insert("KeyProperties", New Structure);
			EndIf;
			
			OnSendData(Source, Destination, ConversionRule.OnSendData, ExchangeComponents, ExportStack);
			
			If Destination = Undefined Then
				Return Undefined;
			EndIf;
			
			If ExportStack.Count() > 1 Then
				For Each KeyProperty In Destination.KeyProperties Do
					Destination.Insert(KeyProperty.Key, KeyProperty.Value);
				EndDo;
				Destination.Delete("KeyProperties");
			EndIf;
			
			// PCR Execution, stage 2
			For Each PCR In ConversionRule.Properties Do
				If PCR.FormatProperty = "" 
					Or (ExportStack.Count() > 1 AND Not PCR.KeyPropertyProcessing) Then
					Continue;
				EndIf;
				
				// Carrying out conversion if an instruction is included in the property.
				PropertyValue = Undefined;
				If ExportStack.Count() = 1 AND PCR.KeyPropertyProcessing Then
					Destination.KeyProperties.Property(PCR.FormatProperty, PropertyValue);
				Else
					FormatProperty_Name = TrimAll(PCR.FormatProperty);
					NestedProperties = StrSplit(FormatProperty_Name,".",False);
					// A full property name is specified. The property is included in the common properties group.
					If NestedProperties.Count() > 1 Then
						GetNestedPropertiesValue(Destination, NestedProperties, PropertyValue);
					Else
						Destination.Property(FormatProperty_Name, PropertyValue);
					EndIf;
				EndIf;
				If PropertyValue = Undefined Then
					Continue;
				EndIf;
				
				If PCR.UsesConversionAlgorithm Then
					
					If TypeOf(PropertyValue) = Type("Structure")
						AND PropertyValue.Property("Value")
						AND PropertyValue.Property("OCRName")
						Or PCR.PropertyConversionRule <> ""
						AND TypeOf(PropertyValue) <> Type("Structure") Then
						
						ExportProperty(
							ExchangeComponents,
							Source,
							Destination,
							PCR,
							ExportStack,
							2);
							
					EndIf;
						
				EndIf;
			EndDo;
			
			// Carrying out PCR for a tabular section
			If ExportStack.Count() = 1 Then
				
				// Generating a structure of new tabular sections by PCR.
				DestinationTSProperties = New Structure;
				For Each TabularSectionsAndProperties In ConversionRule.TabularSectionsProperties Do
					
					DestinationTSName = TabularSectionsAndProperties.FormatTS;
					
					If IsBlankString(DestinationTSName) Then
						Continue;
					EndIf;
					
					If Not DestinationTSProperties.Property(DestinationTSName) Then
						PCRTable = New ValueTable;
						PCRTable.Columns.Add("FormatProperty", New TypeDescription("String"));
						
						DestinationTSProperties.Insert(DestinationTSName, PCRTable);
					EndIf;
					
					For Each PCR In TabularSectionsAndProperties.Properties Do
						RowProperty = DestinationTSProperties[DestinationTSName].Add();
						RowProperty.FormatProperty = PCR.FormatProperty;
					EndDo;
					
				EndDo;
				
				For Each TabularSectionsAndProperties In ConversionRule.TabularSectionsProperties Do
					
					If Not TabularSectionsAndProperties.UsesConversionAlgorithm Then
						Continue;
					EndIf;
					
					PCRForTS = TabularSectionsAndProperties.Properties;
					DestinationTSName = TabularSectionsAndProperties.FormatTS;
					
					DestinationTS = Undefined;
					If Not ValueIsFilled(DestinationTSName)
						Or Not Destination.Property(DestinationTSName, DestinationTS) Then
						Continue;
					EndIf;
					
					// Creating a new TV without type limitation for columns.
					NewDestinationTS = CreateDestinationTSByPCR(DestinationTSProperties[DestinationTSName]);
					
					// Removing excess columns that could be added to the destination.
					ColumnsToDelete = New Array;
					For Each Column In DestinationTS.Columns Do
						If NewDestinationTS.Columns.Find(Column.Name) = Undefined Then
							ColumnsToDelete.Add(Column);
						EndIf;
					EndDo;
					For Each Column In ColumnsToDelete Do
						DestinationTS.Columns.Delete(Column);
					EndDo;
					
					// Copying data to a new destination table.
					For Each DestinationTSRow In DestinationTS Do
						NewDestinationTSRow = NewDestinationTS.Add();
						FillPropertyValues(NewDestinationTSRow, DestinationTSRow);
					EndDo;
					Destination[DestinationTSName] = NewDestinationTS;
					
					For Each Row In NewDestinationTS Do
						
						For Each PCR In PCRForTS Do
							
							If NOT PCR.UsesConversionAlgorithm Then
								Continue;
							EndIf;
							
							ExportProperty(
								ExchangeComponents,
								Source,
								Row,
								PCR,
								ExportStack,
								2);
								
						EndDo;
						
					EndDo;
					
				EndDo;
				
			EndIf;
			
		EndIf;
		// {Handler: OnSendData} End
		
		If ExportStack.Count() > 1 Then
			Destination.Insert("CompositePropertyType", ConversionRule.KeyPropertiesTypeOfXDTODataObject);
		EndIf;
		
	EndIf;
	
	Return Destination;
	
EndFunction

// Exports an infobase object property according to the rules.
//
// Parameters:
//  ExchangeComponents   - Structure - contains all rules and exchange parameters.
//  IBData           - AnyRef - a reference to the infobase object being exported.
//  PropertyRecipient - Structure - a recipient of data of the Structure type, in which the exported property value is to be stored.
//  PCR                - ValueTableRow - a row of the table of property conversion rules according 
//                                               to which the conversion is carried out.
//  ExportStack       - Array - references to the objects being exported considering nesting.
//  ExportStage       - Number - contains information about the export stage.
//     1 - exporting before OnSendData algorithm execution.
//     2 - exporting before OnSendData algorithm execution.
//
Procedure ExportProperty(ExchangeComponents, IBData, PropertyRecipient, PCR, ExportStack, ExportStage = 1) Export
	// Format property is not specified. The current PCR is used only for export.
	If TrimAll(PCR.FormatProperty) = "" Then
		Return;
	EndIf;
	
	FormatProperty_Name = TrimAll(PCR.FormatProperty);
	NestedProperties = StrSplit(FormatProperty_Name,".",False);
	// A full property name is specified. The property is included in the common properties group.
	FullPropertyNameSpecified = False;
	If NestedProperties.Count() > 1 Then
		FullPropertyNameSpecified = True;
		FormatProperty_Name = NestedProperties[NestedProperties.Count()-1];
	EndIf;
	
	PropertyValue = Undefined;
	If ExportStage = 1 Then
		If ValueIsFilled(PCR.ConfigurationProperty) Then
			PropertyValue = IBData[PCR.ConfigurationProperty];
		ElsIf TypeOf(IBData) = Type("Structure") Then
			// This PCR from OCR with structure source.
			If FullPropertyNameSpecified Then
				GetNestedPropertiesValue(IBData, NestedProperties, PropertyValue);
			Else
				IBData.Property(FormatProperty_Name, PropertyValue);
			EndIf;
			If PropertyValue = Undefined Then
				Return;
			EndIf;
		EndIf;
	Else
		
		If TypeOf(PropertyRecipient) = Type("ValueTableRow") Then
			TSColumns = PropertyRecipient.Owner().Columns;
			MaxLevel = NestedProperties.Count() - 1;
			If FullPropertyNameSpecified Then
				For Level = 0 To MaxLevel Do
					ColumnName = NestedProperties[Level];
					If TSColumns.Find(ColumnName) = Undefined Then
						Continue;
					EndIf;
					ValueInColumn = PropertyRecipient[ColumnName];
					If Level = MaxLevel Then
						PropertyValue = ValueInColumn;
					ElsIf TypeOf(ValueInColumn) = Type("Structure") Then
						// Nested property value is packed to the structure, which can be multilevel.
						NestedPropertySource = ValueInColumn;
						NestedPropertyValue = Undefined;
						For SubordinateLevel = Level + 1 To MaxLevel Do
							NestedPropertyName = NestedProperties[SubordinateLevel];
							If NOT NestedPropertySource.Property(NestedPropertyName, NestedPropertyValue) Then
								Continue;
							EndIf;
							If SubordinateLevel = MaxLevel Then
								PropertyValue = NestedPropertyValue;
							ElsIf TypeOf(NestedPropertyValue) = Type("Structure") Then
								NestedPropertySource = NestedPropertyValue;
								NestedPropertyValue = Undefined;
							Else
								Break;
							EndIf;
						EndDo;
					EndIf;
				EndDo;
			Else
				If TSColumns.Find(FormatProperty_Name) = Undefined Then
					Return;
				Else
					PropertyValue = PropertyRecipient[FormatProperty_Name];
				EndIf;
			EndIf;
		Else
			If FullPropertyNameSpecified Then
				GetNestedPropertiesValue(IBData, NestedProperties, PropertyValue);
			Else
				PropertyRecipient.Property(FormatProperty_Name, PropertyValue);
			EndIf;
			If PropertyValue = Undefined
				AND Not (ExportStack.Count() = 1 AND PropertyRecipient.KeyProperties.Property(FormatProperty_Name, PropertyValue)) Then
				Return;
			EndIf;
		EndIf;
		
	EndIf;
		
	PropertyConversionRule = PCR.PropertyConversionRule;
	
	// The value can be in the instruction format.
	If TypeOf(PropertyValue) = Type("Structure") Then
		If PropertyValue.Property("OCRName") Then
			PropertyConversionRule = PropertyValue.OCRName;
		EndIf;
		If PropertyValue.Property("Value") Then
			PropertyValue = PropertyValue.Value;
		EndIf;
	EndIf;
	
	If ValueIsFilled(PropertyValue) Then
	
		If TrimAll(PropertyConversionRule) <> "" Then
			
			PDCR = ExchangeComponents.PredefinedDataConversionRules.Find(PropertyConversionRule, "PDCRName");
			If PDCR <> Undefined Then
				PropertyValue = PDCR.ConvertValuesOnSend.Get(PropertyValue);
			Else
			
				ConversionRule = OCRByName(ExchangeComponents, PropertyConversionRule);
				
				ExportStackBranch = New Array;
				For Each Item In ExportStack Do
					ExportStackBranch.Add(Item);
				EndDo;
				
				PropertyValue = XDTODataFromIBData(
					ExchangeComponents,
					PropertyValue,
					ConversionRule,
					ExportStackBranch);
					
			EndIf;
			
		EndIf;
		
	Else
		PropertyValue = Undefined;
	EndIf;
	
	If ExportStack.Count() = 1 AND PCR.KeyPropertyProcessing Then
		If Not PropertyRecipient.Property("KeyProperties") Then
			PropertyRecipient.Insert("KeyProperties", New Structure);
		EndIf;
		PropertyRecipient.KeyProperties.Insert(FormatProperty_Name, PropertyValue);
	Else
		If TypeOf(PropertyRecipient) = Type("ValueTableRow") Then
			If FullPropertyNameSpecified Then
				PutNestedPropertiesValue(PropertyRecipient, NestedProperties, PropertyValue, True);
			Else
				PropertyRecipient[FormatProperty_Name] = PropertyValue;
			EndIf;
		Else
			If FullPropertyNameSpecified Then
				PutNestedPropertiesValue(PropertyRecipient, NestedProperties, PropertyValue, False);
			Else
				PropertyRecipient.Insert(FormatProperty_Name, PropertyValue);
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

// Opens an export data file, writes a file header according to the exchange format.
//
// Parameters:
//  ExchangeComponents - Structure - contains all exchange rules and parameters.
//  ExchangeFileName - string - an exchange file name.
//
Procedure OpenExportFile(ExchangeComponents, ExchangeFileName = "") Export

	ExchangeFile = New XMLWriter;
	If ExchangeFileName <> "" Then
		ExchangeFile.OpenFile(ExchangeFileName);
	Else
		ExchangeFile.SetString();
	EndIf;
	ExchangeFile.WriteXMLDeclaration();
	
	WriteMessage = Undefined;
	
	If ExchangeComponents.IsExchangeViaExchangePlan Then

		WriteMessage = New Structure("ReceivedNo, MessageNo, Recipient");
		WriteMessage.Recipient = ExchangeComponents.CorrespondentNode;
		
		If TransactionActive() Then
			Raise NStr("ru = 'Блокировка на обмен данными не может быть установлена в активной транзакции.'; en = 'Cannot set a data exchange lock in an active transaction.'; pl = 'Blokada wymiany danych nie może być ustawiona w aktywnej transakcji.';de = 'Austausch-Datensperre kann nicht in einer aktiven Transaktion festgelegt werden.';ro = 'Schimbul de date Exchange nu poate fi setat într-o tranzacție activă.';tr = 'Değişim veri kilidi aktif bir işlemde ayarlanamaz.'; es_ES = 'Bloqueo de los datos de intercambio no puede establecerse en una transacción activa.'");
		EndIf;
		
		// Setting a lock to the recipient node.
		Try
			LockDataForEdit(WriteMessage.Recipient);
		Except
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Ошибка установки блокировки на обмен данными.
				|Возможно, обмен данными выполняется другим сеансом.
				|
				|Подробности:
				|%1'; 
				|en = 'Cannot set a data exchange lock.
				|Perhaps data exchange is running in another session.
				|
				|Details:
				|%1'; 
				|pl = 'Błąd ustawiania blokady wymiany danych.
				|Wymiana danych może być wykonana przez inną sesję.
				|
				|Szczegóły:
				|%1';
				|de = 'Sperren des Datenaustauschfehlers einstellen. 
				|Der Datenaustausch kann von einer anderen Sitzung durchgeführt werden. 
				|
				| Einzelheiten: 
				|%1';
				|ro = 'Eroare de instalare a blocării schimbului de date.
				|Posibil, schimbul de date a fost efectuat de altă sesiune.
				|
				|Detalii:
				|%1';
				|tr = 'Veri değişimi hatası ayarlanıyor. 
				|Veri değişimi başka bir oturum tarafından gerçekleştirilebilir. 
				|
				|Detaylar:
				|%1'; 
				|es_ES = 'Bloque de la configuración del error del intercambio de datos.
				|Intercambio de datos puede realizarse en otra sesión.
				|
				|Detalles:
				|%1'"),
				BriefErrorDescription(ErrorInfo()));
		EndTry;
		
		RecipientData = Common.ObjectAttributesValues(WriteMessage.Recipient, "SentNo, ReceivedNo, Code");
		
		WriteMessage.MessageNo = RecipientData.SentNo + 1;
		WriteMessage.ReceivedNo = RecipientData.ReceivedNo;
		
	EndIf;
	
	HeaderParameters = ExchangeMessageHeaderParameters();
	
	HeaderParameters.ExchangeFormat                 = ExchangeComponents.XMLSchema;
	HeaderParameters.IsExchangeViaExchangePlan      = ExchangeComponents.IsExchangeViaExchangePlan;
	HeaderParameters.DataExchangeWithExternalSystem = ExchangeComponents.DataExchangeWithExternalSystem;
	HeaderParameters.ExchangeFormatVersion          = ExchangeComponents.ExchangeFormatVersion;
	
	If ExchangeComponents.IsExchangeViaExchangePlan Then
		
		HeaderParameters.CorrespondentNode = ExchangeComponents.CorrespondentNode;
		HeaderParameters.SenderID = DataExchangeServer.NodeIDForExchange(ExchangeComponents.CorrespondentNode);
		
		If Not ExchangeComponents.XDTOSettingsOnly Then
			HeaderParameters.MessageNo = WriteMessage.MessageNo;
			HeaderParameters.ReceivedNo = WriteMessage.ReceivedNo;
		EndIf;
		
		HeaderParameters.SupportedVersions  = ExchangeComponents.XDTOSettings.SupportedVersions;
		HeaderParameters.SupportedObjects = ExchangeComponents.XDTOSettings.SupportedObjects;
		
		If Not ExchangeComponents.DataExchangeWithExternalSystem Then
			HeaderParameters.ExchangePlanName = DataExchangeCached.GetExchangePlanName(ExchangeComponents.CorrespondentNode);
			HeaderParameters.PredefinedNodeAlias = DataExchangeServer.PredefinedNodeAlias(ExchangeComponents.CorrespondentNode);
			
			HeaderParameters.RecipientID  = DataExchangeServer.CorrespondentNodeIDForExchange(ExchangeComponents.CorrespondentNode);
			
			HeaderParameters.Prefix = DataExchangeServer.InfobasePrefix();
		EndIf;
		
	EndIf;
	
	WriteExchangeMessageHeader(ExchangeFile, HeaderParameters);
	
	If Not ExchangeComponents.XDTOSettingsOnly Then
		// Writing the <Body> item
		ExchangeFile.WriteStartElement("Body");
		ExchangeFile.WriteNamespaceMapping("", ExchangeComponents.XMLSchema);
	EndIf;
	
	ExchangeComponents.Insert("ExchangeFile", ExchangeFile);
	
EndProcedure

#EndRegion

#Region GetData

// Returns an infobase object matching the received data.
// 
// Parameters:
//  ExchangeComponents - Structure - contains all exchange rules and parameters.
//  XDTOData       - Structure - a structure simulating XDTO object.
//
//  ConversionRule - ValueTableRow, Structure - the current conversion rule parameters.
//                       ValueTableRow - a row of object conversion rule tables.
//                       Structure - object conversion rule details.
//                         * ConversionRule - ValueTableRow - a row of object conversion rule tables.
//                                                Required property.
//                         * DeleteObjectsCreatedByKeyProperties - Boolean - indicates that you need 
//                                                                 to delete objects created ony by key property values.
//                                                                 Optional, the default value is False.
//
//  Action - String - defines a goal of infobase object receiving:
//           "GetRef" - an object identification.
//           "ConvertAndWrite" - a full object export.
//
// Returns:
//  - Object - an infobase object if the ConvertAndWrite action is passed, or if the GetRef is 
//             passed and the object is created while getting it.
//  - Ref - a reference to an infobase object or a blank reference of the specified type if the GetRef action is passed
//             and the object is not created while receiving it.
//
Function XDTOObjectStructureToIBData(ExchangeComponents, XDTOData, Val ConversionRule, Action = "ConvertAndWrite") Export
	
	DeleteObjectsCreatedByKeyProperties = ExchangeComponents.DeleteObjectsCreatedByKeyProperties;
	If TypeOf(ConversionRule) = Type("Structure") Then
		If ConversionRule.Property("DeleteObjectsCreatedByKeyProperties") Then
			DeleteObjectsCreatedByKeyProperties = ConversionRule.DeleteObjectsCreatedByKeyProperties;
		EndIf;
		ConversionRule = ConversionRule.ConversionRule;
	EndIf;
	
	IBData = Undefined;
	ReceivedData = InitializeReceivedData(ConversionRule);
	PropertiesContent = "All";
	ReceivedDataRef = Undefined;
	XDTODataContainRef = XDTOData.Property("Ref");
	If ConversionRule.IsReferenceType Then
		ReceivedDataRef = ReceivedData.Ref;
		IdentificationOption = TrimAll(ConversionRule.IdentificationOption);
		If XDTODataContainRef
			AND (IdentificationOption = "ByUUID"
				Or IdentificationOption = "FirstByUUIDThenBySearchFields") Then
			
			ReceivedDataRef = ObjectRefByXDTODataObjectUUID(
				XDTOData.Ref.Value,
				ConversionRule.DataType,
				ExchangeComponents);
				
			ReceivedData.SetNewObjectRef(ReceivedDataRef);
			
			IBData = ReceivedDataRef.GetObject();
			
			If Action = "GetRef" Then
				
				If IBData <> Undefined Then
					// Task: receiving a reference.
					// Identification: by UUID or UUID + search fields.
					// An object with the received reference (or with the same public ID) exists.
					WritePublicIDIfNecessary(
						IBData,
						ReceivedDataRef,
						XDTOData.Ref.Value,
						ExchangeComponents.CorrespondentNode,
						ConversionRule);
						
					Return IBData.Ref;
				ElsIf IdentificationOption = "ByUUID" Then
					// Task: receiving a reference.
					// Identification: by UUID.
					// An object with the received reference (or with the same public ID) is not found.
					WritePublicIDIfNecessary(
						IBData,
						ReceivedDataRef,
						XDTOData.Ref.Value,
						ExchangeComponents.CorrespondentNode,
						ConversionRule);
					
					Return ReceivedDataRef;
				EndIf;
				
			EndIf;
		Else
			ReceivedDataRef = ConversionRule.ObjectManager.GetRef(New UUID());
			ReceivedData.SetNewObjectRef(ReceivedDataRef);
		EndIf;
		// Define the properties to convert.
		PropertiesContent = ?(Action = "GetRef" AND DeleteObjectsCreatedByKeyProperties, "SearchProperties", "All");
	EndIf;
	
	// Converting properties not requiring the handler execution.
	ConversionOfXDTODataObjectStructureProperties(
		ExchangeComponents,
		XDTOData,
		ReceivedData,
		ConversionRule,
		1,
		PropertiesContent);
		
	If Action = "GetRef" Then
		XDTOData = New Structure("KeyProperties",
			Common.CopyRecursive(XDTOData));
	EndIf;
	
	OnConvertXDTOData(
		XDTOData,
		ReceivedData,
		ExchangeComponents,
		ConversionRule.OnConvertXDTOData);
		
	If Action = "GetRef" Then
		XDTOData = Common.CopyRecursive(XDTOData.KeyProperties);
	EndIf;
		
	ConversionOfXDTODataObjectStructureProperties(
		ExchangeComponents,
		XDTOData,
		ReceivedData,
		ConversionRule,
		2,
		PropertiesContent);
		
	// As a result of properties conversion, the object could be written if there is a circular reference.
	If ReceivedDataRef <> Undefined AND Common.RefExists(ReceivedDataRef) Then
		IBData = ReceivedDataRef.GetObject();
	EndIf;
	
	If IBData = Undefined Then
		If ConversionRule.IsRegister Then
			// Identification failed, a record set is filtered in rule algorithms.
			IBData = Undefined;
		ElsIf IdentificationOption = "BySearchFields"
			Or IdentificationOption = "FirstByUUIDThenBySearchFields" Then
			
			IBData = ObjectRefByXDTODataObjectProperties(
				ConversionRule,
				ReceivedData,
				XDTODataContainRef,
				ExchangeComponents.CorrespondentNode);
			If Not ValueIsFilled(IBData) Then
				IBData = Undefined;
			EndIf;
			
			If IBData <> Undefined AND ConversionRule.IsReferenceType Then
				If Action = "GetRef" Then
					// Task: receiving a reference.
					// Identification: by UUID + search fields.
					// The object is found by search fields.
					If XDTODataContainRef Then
						WritePublicIDIfNecessary(
							IBData.GetObject(),
							IBData,
							XDTOData.Ref.Value,
							ExchangeComponents.CorrespondentNode,
							ConversionRule);
					EndIf;
					
					Return IBData;
				Else
					IBData = IBData.GetObject();
				EndIf;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	WriteObjectToIB = ?(Action = "ConvertAndWrite", True, False);
	
	If ExchangeComponents.DataImportToInfobaseMode
		AND (IdentificationOption = "BySearchFields"
			Or IdentificationOption = "FirstByUUIDThenBySearchFields") Then
		// Objects identified using the search fields must be written to the infobase to get the same object 
		// reference for each search.
		WriteObjectToIB = True;
	EndIf;
	
	If WriteObjectToIB Then
		
		IsFullObjectImport = Action = "ConvertAndWrite"
			Or ConversionRule.AllowCreateObjectFromStructure
			Or (Action = "GetRef"
				AND Not DeleteObjectsCreatedByKeyProperties
				AND IBData = Undefined);
			
		If IsFullObjectImport
			AND ConversionRule.HasHandlerBeforeWriteReceivedData Then
			
			// Full object import, deleting a temporary object.
			If IBData <> Undefined Then
				ObjectString = ExchangeComponents.ObjectsCreatedByRefsTable.Find(IBData.Ref, "ObjectRef");
				If ObjectString <> Undefined Then
					DataExchangeServer.SetDataExchangeLoad(IBData, True, False, ExchangeComponents.CorrespondentNode);
					DeleteObject(IBData, True, ExchangeComponents);
					IBData = Undefined;
					ReceivedData.SetNewObjectRef(ObjectString.ObjectRef);
				EndIf;
			EndIf;
			
			BeforeWriteReceivedData(
				ReceivedData,
				IBData,
				ExchangeComponents,
				ConversionRule.BeforeWriteReceivedData,
				ConversionRule.Properties);
			
		EndIf;
		
		If IBData = Undefined Then
			DataToWriteToIB = ReceivedData;
		Else
			If ReceivedData <> Undefined Then
				FillIBDataByReceivedData(IBData, ReceivedData, ConversionRule);
			EndIf;
			DataToWriteToIB = IBData;
		EndIf;
		
		If DataToWriteToIB = Undefined Then
			Return Undefined;
		EndIf;
		
		If ExchangeComponents.IsExchangeViaExchangePlan
			AND ConversionRule.IsReferenceType
			AND XDTODataContainRef Then
			
			WritePublicIDIfNecessary(
				IBData,
				?(DataToWriteToIB.IsNew(), DataToWriteToIB.GetNewObjectRef(), DataToWriteToIB.Ref),
				XDTOData.Ref.Value,
				ExchangeComponents.CorrespondentNode,
				ConversionRule);
				
		EndIf;
		
		If ConversionRule.IsReferenceType AND IsFullObjectImport Then
			ExecuteNumberCodeGenerationIfNecessary(DataToWriteToIB);
		EndIf;
		
		If ExchangeComponents.IsExchangeViaExchangePlan AND Not ConversionRule.IsRegister Then
			GetItem = DataItemReceive.Auto;
			SendBack = False;
			StandardSubsystemsServer.OnReceiveDataFromMaster(
				DataToWriteToIB, GetItem, SendBack, ExchangeComponents.CorrespondentNodeObject);
			DataToWriteToIB.AdditionalProperties.Insert("DataItemReceive", GetItem);
			
			If GetItem = DataItemReceive.Ignore Then
				Return DataToWriteToIB;
			EndIf;
		EndIf;
		
		If ConversionRule.IsReferenceType AND DataToWriteToIB.DeletionMark Then
			DataToWriteToIB.DeletionMark = False;
		EndIf;
		
		If ConversionRule.IsDocument Then
			
			Try
				
				If ConversionRule.DocumentCanBePosted Then
				
					If DataToWriteToIB.Posted Then
						
						DataToWriteToIB.Posted = False;
						If Not DataToWriteToIB.IsNew()
							AND Common.ObjectAttributeValue(DataToWriteToIB.Ref, "Posted") Then
							// Writing a new document version with posting cancellation.
							Result = UndoObjectPostingInIB(DataToWriteToIB, ExchangeComponents.CorrespondentNode);
						Else
							// Writing a new document version.
							WriteObjectToIB(ExchangeComponents, DataToWriteToIB, ConversionRule.DataType);
							If DataToWriteToIB = Undefined Then
								Return Undefined;
							EndIf;
						EndIf;
						
						TableRow = ExchangeComponents.DocumentsForDeferredPosting.Add();
						TableRow.DocumentRef = DataToWriteToIB.Ref;
						TableRow.DocumentDate  = DataToWriteToIB.Date;
						
					Else
						If DataToWriteToIB.IsNew() Then
							WriteObjectToIB(ExchangeComponents, DataToWriteToIB, ConversionRule.DataType);
							If DataToWriteToIB = Undefined Then
								Return Undefined;
							EndIf;
						Else
							UndoObjectPostingInIB(DataToWriteToIB, ExchangeComponents.CorrespondentNode);
						EndIf;
					EndIf;
					
				Else
					WriteObjectToIB(ExchangeComponents, DataToWriteToIB, ConversionRule.DataType);
					If DataToWriteToIB = Undefined Then
						Return Undefined;
					EndIf;
				EndIf;
				
			Except
				WriteToExecutionProtocol(ExchangeComponents, DetailErrorDescription(ErrorInfo()));
			EndTry;
			
		Else
			
			WriteObjectToIB(ExchangeComponents, DataToWriteToIB, ConversionRule.DataType);
			If DataToWriteToIB = Undefined Then
				Return Undefined;
			EndIf;
			If ConversionRule.IsReferenceType Then
				ExchangeComponents.ObjectsForDeferredPosting.Insert(
					DataToWriteToIB.Ref, 
					DataToWriteToIB.AdditionalProperties);
			EndIf;
		EndIf;
		
		RememberObjectForDeferredFilling(DataToWriteToIB, ConversionRule, ExchangeComponents);
		
	Else
		
		DataToWriteToIB = ReceivedData;
		
	EndIf;
	
	If ConversionRule.IsReferenceType Then
		// Writing the objects being created by the link to the table in order to delete not fully loaded 
		// objects (temporary objects) after importing all data.
		// 
		// Upon importing the whole objects, delete the objects from the table changing their status from 
		// temporary to permanent.
		ObjectsCreatedByRefsTable = ExchangeComponents.ObjectsCreatedByRefsTable;
			
		If Action = "GetRef"
			AND WriteObjectToIB
			AND Not ConversionRule.AllowCreateObjectFromStructure Then
			
			ObjectString = ObjectsCreatedByRefsTable.Find(DataToWriteToIB.Ref, "ObjectRef");
			
			If ObjectString = Undefined Then
				NewRow = ObjectsCreatedByRefsTable.Add();
				NewRow.ObjectRef = DataToWriteToIB.Ref;
				NewRow.DeleteObjectsCreatedByKeyProperties = DeleteObjectsCreatedByKeyProperties;
			Else
				If Not DeleteObjectsCreatedByKeyProperties Then
					ObjectString.DeleteObjectsCreatedByKeyProperties = False;
				EndIf;
			EndIf;
			
		ElsIf Action = "ConvertAndWrite" Then
			
			ObjectString = ObjectsCreatedByRefsTable.Find(DataToWriteToIB.Ref, "ObjectRef");
			
			If ObjectString <> Undefined Then
				ObjectsCreatedByRefsTable.Delete(ObjectString);
			EndIf;
			
		EndIf;
	EndIf;
	
	Return DataToWriteToIB;
	
EndFunction

// Reads a data file upon import.
//
// Parameters:
//  ExchangeComponents - Structure - contains all exchange rules and parameters.
//  TablesToImport -  ValueTable - a table to import data to (upon interactive data mapping).
//
Procedure ReadData(ExchangeComponents, TablesToImport = Undefined) Export
	
	ExchangeComponents.ObjectsCreatedByRefsTable.Clear();
	
	If TypeOf(TablesToImport) = Type("ValueTable")
		AND TablesToImport.Count() = 0 Then
		Return;
	EndIf;
	
	If ExchangeComponents.IsExchangeViaExchangePlan
		AND ExchangeComponents.CorrespondentNodeObject = Undefined Then
		ExchangeComponents.CorrespondentNodeObject = ExchangeComponents.CorrespondentNode.GetObject();
	EndIf;
	
	If ExchangeComponents.IsExchangeViaExchangePlan Then
		ClearErrorsListOnImportData(ExchangeComponents.CorrespondentNode);
	EndIf;
	
	Results = Undefined;
	ReadExchangeMessage(ExchangeComponents, Results, TablesToImport);
	
	If Not ExchangeComponents.ErrorFlag
		AND ExchangeComponents.DataImportToInfobaseMode Then
		
		DataExchangeInternal.DisableAccessKeysUpdate(True);
		Try
			ApplyObjectsDeletion(ExchangeComponents, Results.ArrayOfObjectsToDelete, Results.ArrayOfImportedObjects);
			DeleteTemporaryObjectsCreatedByRefs(ExchangeComponents);
			DeferredObjectsFilling(ExchangeComponents);
		
			DataExchangeInternal.DisableAccessKeysUpdate(False);
		Except
			DataExchangeInternal.DisableAccessKeysUpdate(False);
			Raise;
		EndTry;
		
		ExchangeComponents.ObjectsMarkedForDeletion = Common.CopyRecursive(Results.ArrayOfObjectsToDelete);
		
		If Not ExchangeComponents.ErrorFlag Then
			Try
				ExchangeComponents.ExchangeManager.AfterConvert(ExchangeComponents);
			Except
				Raise StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Направление: %1.
					|Обработчик: ПослеКонвертации.
					|
					|Ошибка выполнения обработчика.
					|%2.'; 
					|en = 'Direction: %1.
					|Handler: AfterConvert.
					|
					|Handler execution error.
					|%2.'; 
					|pl = 'Kierunek: %1.
					|Procedura przetwarzania: ПослеКонвертации.
					|
					|Błąd wykonania programu przetwarzania.
					|%2.';
					|de = 'Richtung: %1.
					|Handler: Nach der Konvertierung.
					|
					|Handler-Fehler.
					|%2.';
					|ro = 'Direcția: %1.
					|Handlerul: ПослеКонвертации.
					|
					|Eroare de executare a handlerului.
					|%2.';
					|tr = 'Yön: %1. 
					| İşleyici: DönüştürmedenSonra. 
					|
					| İşleyici yürütme hatası. 
					|%2.'; 
					|es_ES = 'Dirección: %1.
					|Procesador: ПослеКонвертации.
					|
					|Error de ejecutar el procesador.
					|%2.'"),
					ExchangeComponents.ExchangeDirection,
					DetailErrorDescription(ErrorInfo()));
			EndTry;
				
			DataExchangeInternal.DisableAccessKeysUpdate(True);
			Try
				ExecuteDeferredDocumentsPosting(ExchangeComponents);
				ExecuteDeferredObjectsWrite(ExchangeComponents);
				
				DataExchangeInternal.DisableAccessKeysUpdate(False);	
			Except
				DataExchangeInternal.DisableAccessKeysUpdate(False);	
				Raise;
			EndTry;
				
		EndIf;
	EndIf;
	
	// Recording successful exchange completion.
	If ExchangeComponents.DataExchangeState.ExchangeExecutionResult = Undefined Then
		ExchangeComponents.DataExchangeState.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Completed;
	EndIf;
	
EndProcedure

// Reads a data file upon import in the analysis mode (upon interactive data synchronization).
//
// Parameters:
//  ExchangeComponents - Structure - contains all exchange rules and parameters.
//  AnalysisParameters - Structure - parameters of interactive data import.
//
Procedure ReadDataInAnalysisMode(ExchangeComponents, AnalysisParameters = Undefined) Export
	
	Results = Undefined;
	ReadExchangeMessage(ExchangeComponents, Results, , True);
	
	ApplyObjectsDeletion(ExchangeComponents, Results.ArrayOfObjectsToDelete, Results.ArrayOfImportedObjects);
	
EndProcedure

// Opens a data import file, writes a file header according to the exchange format.
//
// Parameters:
//  ExchangeComponents - Structure - contains all exchange rules and parameters.
//  ExchangeFileName - string - an exchange file name.
//
Procedure OpenImportFile(ExchangeComponents, ExchangeFileName) Export
	
	IsExchangeViaExchangePlan = ExchangeComponents.IsExchangeViaExchangePlan;
	
	XMLReader = New XMLReader;
	
	ExchangeComponents.ErrorFlag = True;
	
	StopCycle = False;
	While Not StopCycle Do
		StopCycle = True;
		
		Try
			XMLReader.OpenFile(ExchangeFileName);
			ExchangeComponents.Insert("ExchangeFile", XMLReader);
		Except
			ErrorMessageString = NStr("ru = 'Ошибка при загрузке данных: %1'; en = 'Data import error: %1'; pl = 'Wystąpił błąd podczas importu danych: %1';de = 'Beim Importieren von Daten ist ein Fehler aufgetreten: %1';ro = 'Eroare la importul datelor: %1';tr = 'Veri içe aktarılırken bir hata oluştu:  %1'; es_ES = 'Ha ocurrido un error al importar los datos: %1'");
			ErrorMessageString = StringFunctionsClientServer.SubstituteParametersToString(ErrorMessageString, ErrorDescription());
			WriteToExecutionProtocol(ExchangeComponents, ErrorMessageString);
			Break;
		EndTry;
		
		XMLReader.Read(); // Message
		If (XMLReader.NodeType <> XMLNodeType.StartElement
			Or XMLReader.LocalName <> "Message") Then
			If MessageFromNotUpdatedSetting(XMLReader) Then
				ErrorMessageString = NStr("ru = 'Получение данных от источника, в котором не выполнено
					|обновление настройки синхронизации данных. Необходимо:'; 
					|en = 'Receiving data from the source where
					|data synchronization settings are not updated. Please do one of the following:'; 
					|pl = 'Pobieranie danych od źródła, w którym nie jest wykonana
					|aktualizacja ustawienia synchronizacji danych. Należy:';
					|de = 'Empfängt Daten von einer Quelle, die die
					|Datensynchronisationseinstellung nicht aktualisiert hat. Es ist notwendig:';
					|ro = 'Primirea datelor de la sursa, în care nu este actualizată
					|setarea sincronizării datelor. Trebuie:';
					|tr = 'Veri eşleşme ayarlarının 
					|yapılamadığı bir kaynaktan veri alma. Yapılması gereken:'; 
					|es_ES = 'La recepción de datos de la fuente en la que no se ha realizado
					|la actualización del ajuste de sincronización de datos. Es necesario:'")
					+ Chars.LF + NStr("ru = '1) Выполнить повторную синхронизацию данных через некоторое время.'; en = '1) Repeat data synchronization later.'; pl = '1) Wykonuj ponowną synchronizację danych po pewnym czasie.';de = '1) Synchronisieren Sie die Daten nach einiger Zeit erneut.';ro = '1) Execută sincronizarea repetată a datelor mai târziu.';tr = '1) Daha sonra veri eşleşmesini yapın.'; es_ES = '1) Volver a sincronizar los datos a través de un tiempo.'")
					+ Chars.LF + NStr("ru = '2) Выполнить синхронизацию данных на стороне источника, после этого 
					|повторно выполнить синхронизацию данных в этой информационной базе.'; 
					|en = '2) Run data synchronization in the source infobase, then repeat 
					|data synchronization in this infobase.'; 
					|pl = '2) Wykonuj synchronizację danych na stronie źródła, po tym 
					|ponownie wykonaj synchronizację danych w tej bazie informacyjnej.';
					|de = '2) Führen Sie die Datensynchronisation auf der Quellenseite durch und danach 
					| synchronisieren Sie die Daten in dieser Informationsbasis erneut.';
					|ro = '2) Execută sincronizarea datelor pe partea sursei, după care 
					|repetă sincronizarea datelor în această bază de informații.';
					|tr = '2) Kaynak tarafında veri eşleşmesini yapın, 
					|daha sonra bu veri tabanında veri eşleşmesini tekrar yapın. '; 
					|es_ES = '2) Realizar la sincronización de datos al lado de la fuente, después 
					|volver a realizar la sincronización de datos en esta base de información.'")
					+ Chars.LF + NStr("ru = '(1 - для вида транспорта Через интернет, 2 - для вида транспорта Другое)'; en = '(1 for transport over internet, 2 for any other transport type.)'; pl = '(1 - dla rodzaju transportu Poprzez Internet, 2 - dla rodzaju transportu Inne)';de = '(1- für den Transportmodus über das Internet, 2- für den Transportmodus Sonstige)';ro = '(1 - pentru tipul de transport Prin internet, 2 - pentru tipul de transport Altele)';tr = '(1- araç türü için İnternet üzerinden, 2 - araç türü için Diğer)'; es_ES = '(1 - para el tipo de transporte A través de internet, 2 - para el tipo de transporte Otro)'");
				WriteToExecutionProtocol(ExchangeComponents, ErrorMessageString);
			Else
				WriteToExecutionProtocol(ExchangeComponents, 9);
			EndIf;
			Break;
		EndIf;
		
		XMLReader.Read(); // Header
		If XMLReader.NodeType <> XMLNodeType.StartElement
			Or XMLReader.LocalName <> "Header" Then
			WriteToExecutionProtocol(ExchangeComponents, 9);
			Break;
		EndIf;
		
		Header = XDTOFactory.ReadXML(XMLReader, XDTOFactory.Type(XMLBaseSchema(), "Header"));
		
		URIFormat = Header.Format;
		
		If IsExchangeViaExchangePlan Then
			
			If Not Header.IsSet("Confirmation") Then
				WriteToExecutionProtocol(ExchangeComponents, 9);
				Break;
			EndIf;
			
			Confirmation = Header.Confirmation;
			
			If ExchangeComponents.DataExchangeWithExternalSystem Then
				ExchangePlanName = DataExchangeCached.GetExchangePlanName(ExchangeComponents.CorrespondentNode);
			Else
				ExchangePlanName = Confirmation.ExchangePlan;
			
				If Metadata.ExchangePlans.Find(ExchangePlanName) = Undefined Then
					WriteToExecutionProtocol(ExchangeComponents, 177);
					Break;
				EndIf;
			EndIf;
			
			ExchangePlanFormat = DataExchangeServer.ExchangePlanSettingValue(ExchangePlanName, "ExchangeFormat");
			
			ExchangeComponents.XDTOSettingsOnly =
				Not DataExchangeServer.SynchronizationSetupCompleted(ExchangeComponents.CorrespondentNode)
					Or (URIFormat = ExchangePlanFormat);
			
			If Confirmation.MessageNo <> Undefined Then		
				ExchangeComponents.IncomingMessageNumber = Confirmation.MessageNo;
			Else
				ExchangeComponents.IncomingMessageNumber = 0;
			EndIf;
			If Confirmation.ReceivedNo <> Undefined Then
				ExchangeComponents.MessageNumberReceivedByCorrespondent = Confirmation.ReceivedNo;
			Else
				ExchangeComponents.MessageNumberReceivedByCorrespondent = 0;
			EndIf;
			
			FromWhomCode = Confirmation.From;
			ToWhomCode   = Confirmation.To;
			
			If Not ExchangeComponents.XDTOSettingsOnly Then
				ExchangeComponents.XMLSchema = URIFormat;
				
				ExchangeFormat = ParseExchangeFormat(ExchangeComponents.XMLSchema);
				
				// Checking the basic format.
				If ExchangePlanFormat <> ExchangeFormat.BasicFormat Then
					MessageString = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Формат сообщения обмена ""%1"" не соответствует формату плана обмена ""%2"".'; en = 'The exchange message format ""%1"" does not match the exchange plan format ""%2.""'; pl = 'Format komunikatu wymiany ""%1"" nie odpowiada formatowi planu wymiany ""%2"".';de = 'Das Format der Austauschnachricht ""%1"" entspricht nicht dem Format des Austauschplans ""%2"".';ro = 'Formatul mesajului de schimb ""%1"" nu corespunde formatului planului de schimb ""%2"".';tr = 'İleti biçimi biçimi ""%1"", veri alışveriş değişim planın biçimine ""%2"" uymuyor.'; es_ES = 'Formato del mensaje de intercambio ""%1"" no corresponde al formato del plan de cambio ""%2"".'"),
						ExchangeFormat.BasicFormat,
						ExchangePlanFormat);
					WriteToExecutionProtocol(ExchangeComponents, MessageString);
					Break;
				EndIf;
				
				// Checking a version of the exchange message format.
				If ExhangeFormatVersionsArray(ExchangeComponents.CorrespondentNode).Find(ExchangeFormat.Version) = Undefined Then
					MessageString = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Версия ""%1"" формата сообщения обмена ""%2"" не поддерживается.'; en = 'Version %1 of exchange message format ""%2"" is not supported.'; pl = 'Wersja ""%1"" formatu komunikatu wymiany ""%2"" nie jest obsługiwana.';de = 'Die Version ""%1"" des Austauschnachrichtenformats ""%2"" wird nicht unterstützt.';ro = 'Versiunea ""%1"" a formatului mesajului de schimb ""%2"" nu este susținută.';tr = 'Veri alışverişi mesajı ""%2"" biçiminin ""%1"" sürümü desteklenmiyor.'; es_ES = 'La versión ""%1"" del formato del mensaje de cambio ""%2"" no se admite.'"),
						ExchangeFormat.Version, ExchangeFormat.BasicFormat);
					WriteToExecutionProtocol(ExchangeComponents, MessageString);
					Break;
				EndIf;
				
				ExchangeComponents.ExchangeFormatVersion = ExchangeFormat.Version;
				ExchangeComponents.ExchangeManager      = FormatVersionExchangeManager(ExchangeComponents.ExchangeFormatVersion,
					ExchangeComponents.CorrespondentNode);
					
				If ExchangeComponents.IncomingMessageNumber <= 0 Then
					ExchangeComponents.UseAcknowledgement = False;
				EndIf;
					
				If Not ExchangeComponents.DataExchangeWithExternalSystem Then
					
					NewFromWhomCode = "";
					If Header.IsSet("NewFrom") Then
						NewFromWhomCode = Header.NewFrom;
					EndIf;
					
					RecipientFromMessage = DataExchangeServer.ExchangePlanNodeByCode(ExchangePlanName, ToWhomCode);
					If RecipientFromMessage <> ExchangePlans[ExchangePlanName].ThisNode() Then
						// Probably, the recipient virtual code is set.
						PredefinedNodeAlias = DataExchangeServer.PredefinedNodeAlias(ExchangeComponents.CorrespondentNode);
						If PredefinedNodeAlias <> ToWhomCode Then
							WriteToExecutionProtocol(ExchangeComponents, 178);
							Break;
						EndIf;
					EndIf;
					
					SenderFromMessage = DataExchangeServer.ExchangePlanNodeByCode(ExchangePlanName, FromWhomCode);
					If (SenderFromMessage = Undefined
							Or SenderFromMessage <> ExchangeComponents.CorrespondentNode)
						AND ValueIsFilled(NewFromWhomCode) Then
						SenderFromMessage = DataExchangeServer.ExchangePlanNodeByCode(ExchangePlanName, NewFromWhomCode);
					EndIf;
					
					If SenderFromMessage = Undefined
						Or SenderFromMessage <> ExchangeComponents.CorrespondentNode Then
						
						MessageString = NStr("ru = 'Не найден узел обмена для загрузки данных. План обмена: %1, Идентификатор: %2'; en = 'Exchange node for data import is not found. Exchange plan: %1, ID: %2'; pl = 'Nie jest znaleziony węzeł wymiany do wysłania danych. Plan wymiany: %1, Identyfikator: %2';de = 'Es wurde kein Austauschknoten für das Herunterladen von Daten gefunden. Austauschplan: %1, Kennung: %2';ro = 'Nodul de schimb pentru importul de date nu a fost găsit. Planul de schimb: %1, Identificatorul: %2';tr = 'Veri içe aktarma için veri alışverişi ünitesi bulunamadı. Veri alışverişi planı:%1, Tanımlayıcı:%2'; es_ES = 'No se ha encontrado un nodo de cambio para cargar los datos. Plan de cambio: %1, Identificador: %2'");
						MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, ExchangePlanName, FromWhomCode);
						WriteToExecutionProtocol(ExchangeComponents, MessageString);
						Break;
						
					EndIf;
				EndIf;
				
				If ExchangeComponents.UseAcknowledgement Then
					
					ReceivedMessageNumber = Common.ObjectAttributeValue(ExchangeComponents.CorrespondentNode, "ReceivedNo");
					
					If ReceivedMessageNumber >= ExchangeComponents.IncomingMessageNumber Then
						// The message number is less than or equal to the previously received one.
						ExchangeComponents.DataExchangeState.ExchangeExecutionResult =
							Enums.ExchangeExecutionResults.Warning_ExchangeMessageAlreadyAccepted;
							
						WriteToExecutionProtocol(ExchangeComponents, 174,,,,, True);
						ExchangeComponents.XDTOSettingsOnly = True;
					Else
						// Adding public IDs for reference objects whose receiving was reported by the correspondent node.
						AddExportedObjectsToPublicIDsRegister(ExchangeComponents);
						
						// Deleting registration of changes whose receiving was reported by the correspondent node.
						ExchangePlans.DeleteChangeRecords(ExchangeComponents.CorrespondentNode, ExchangeComponents.MessageNumberReceivedByCorrespondent);
						
						// Removing the initial data export flag.
						InformationRegisters.CommonInfobasesNodesSettings.ClearInitialDataExportFlag(
							ExchangeComponents.CorrespondentNode, ExchangeComponents.MessageNumberReceivedByCorrespondent);
					EndIf;
					
				EndIf;
					
			EndIf;
			
			If ExchangeComponents.DataExchangeWithExternalSystem Then
				ExchangeComponents.CorrespondentID = FromWhomCode;
			EndIf;
			
			FillCorrespondentXDTOSettingsStructure(ExchangeComponents.XDTOCorrespondentSettings,
				Header, Not (URIFormat = ExchangePlanFormat), ExchangeComponents.CorrespondentNode);
				
			If Header.IsSet("Prefix") Then
				ExchangeComponents.CorrespondentPrefix = Header.Prefix;
			EndIf;
			
			// Checking encoding support by UUID in the correspondent.
			ExchangeComponents.Insert("CorrespondentSupportsDataExchangeID",
				VersionSupported(ExchangeComponents.XDTOCorrespondentSettings.SupportedVersions, VersionNumberWithDataExchangeIDSupport()));
				
		Else
				
			ExchangeComponents.XMLSchema = URIFormat;
			
			ExchangeFormat = ParseExchangeFormat(ExchangeComponents.XMLSchema);
			
			ExchangeComponents.ExchangeFormatVersion = ExchangeFormat.Version;
			ExchangeComponents.ExchangeManager      = FormatVersionExchangeManager(ExchangeComponents.ExchangeFormatVersion);
			
		EndIf;
		
		If Not ExchangeComponents.XDTOSettingsOnly Then
			If XMLReader.NodeType <> XMLNodeType.StartElement
				Or XMLReader.LocalName <> "Body" Then
				WriteToExecutionProtocol(ExchangeComponents, 9);
				Break;
			EndIf;
			
			XMLReader.Read(); // Body
		EndIf;
		
		ExchangeComponents.ErrorFlag = False;
		
	EndDo;
	
	If ExchangeComponents.ErrorFlag Then
		XMLReader.Close();
	Else
		ExchangeComponents.Insert("ExchangeFile", XMLReader);
	EndIf;
	
EndProcedure

// Converts an XDTO object to the data structure.
//
// Parameters:
//  XDTODataObject - XDTODataObject - a value to be converted.
//
// Returns:
//  Structure - a structure simulating an XDTO object.
//    Structure keys match XDTO object properties.
//    Values match XDTO object properties.
//
Function XDTODataObjectToStructure(XDTODataObject) Export
	
	Destination = New Structure;
	
	For Each Property In XDTODataObject.Properties() Do
		
		ConvertXDTOPropertyToStructureItem(XDTODataObject, Property, Destination);
		
	EndDo;
	
	If Destination.Property("KeyProperties")
		AND Destination.KeyProperties.Property("Ref") Then
		Destination.Insert("Ref", Destination.KeyProperties.Ref);
	EndIf;
	
	Return Destination;
EndFunction

// Converts a string UUID presentation to a reference to the current infobase object.
// First, the UUID is searched in the public IDs register.
// If search is completed successfully, a reference from the register is returned. Otherwise, either 
// a reference with the initial UUID is returned (if it is not mapped yet), or a new reference with 
// a random UUID is generated.
// In both cases, a record is created in the public IDs register.
// 
// Parameters:
//  XDTODataObjectUUID       - String - a unique XDTO object ID that requires receiving a reference 
//                                  of the matching infobase object.
//
//  IBObjectValueType - Type - a type of the infobase object, to which the reference to be received 
//                               must match.
//
//  ExchangeComponents     - Structure - contains all necessary data initialized on the exchange 
//                                     start (such as OCR, PDCR, DPR).
//
// Returns:
//  CatalogRef, DocumentRef, etc. – a reference to the infobase object.
// 
Function ObjectRefByXDTODataObjectUUID(XDTODataObjectUUID, IBObjectValueType, ExchangeComponents) Export
	
	SetPrivilegedMode(True);
	
	// Defining a reference to the object using a public reference.
	PublicRef = FIndRefByPublicID(XDTODataObjectUUID, ExchangeComponents.CorrespondentNode, IBObjectValueType);
	If PublicRef <> Undefined Then
		// Public ID is found.
		Return PublicRef;
	EndIf;
	
	// Searching for a reference by the initial UUID.
	RefByUUID = RefByUUID(IBObjectValueType, XDTODataObjectUUID, ExchangeComponents.CorrespondentNode);
	
	// Reference is found by UUID or a new reference is created.
	Return RefByUUID;
	
EndFunction

// Writes an object to the infobase.
//
// Parameters:
//  ExchangeComponents - Structure - contains all necessary data initialized on exchange start (such 
//                as OCR, PDCR, DPR.)
//  Object - Arbitrary - CatalogObject, DocumentObject and another object to be written.
//  Type - String - an object type as a string.
//  WriteObject - Boolean - a variable takes the False value if the object is not written.
//  SendBack - Boolean - a service flag to set the object data exchange parameter.
//  UUIDString - String - a unique object ID as a string.
// 
Procedure WriteObjectToIB(ExchangeComponents, Object, Type, WriteObject = False, Val SendBack = False, UUIDAsString = "") Export
	
	If Not WriteObjectAllowed(Object, ExchangeComponents) Then
		ErrorMessageString = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Попытка изменения неразделенных данных (%1: %2) в разделенном режиме.'; en = 'Attempting to change shared data (%1: %2) in separated mode.'; pl = 'Próba zmiany niepodzielonych danych (%1: %2) w trybie rozdzielonym.';de = 'Versuch, ungeteilte Daten (%1: %2) im geteilten Modus zu ändern.';ro = 'Tentativa de modificare a datelor neseparate (%1: %2) în regim separat.';tr = 'Bölünmemiş verileri (%1:%2) bölünmüş modda değiştirme girişimi.'; es_ES = 'Prueba de cambiar los datos no distribuidos (%1: %2) en el modo no distribuido.'"),
			Object.Metadata().FullName(), String(Object));

		If ExchangeComponents.DataExchangeState.ExchangeExecutionResult = Undefined
			Or ExchangeComponents.DataExchangeState.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Completed Then
			ExchangeComponents.DataExchangeState.ExchangeExecutionResult = Enums.ExchangeExecutionResults.CompletedWithWarnings;
		EndIf;
		
		ErrorCode = New Structure;
		ErrorCode.Insert("BriefErrorPresentation",   ErrorMessageString);
		ErrorCode.Insert("DetailedErrorPresentation", ErrorMessageString);
		ErrorCode.Insert("Level",                      EventLogLevel.Warning);
		
		WriteToExecutionProtocol(ExchangeComponents, ErrorCode, , False);
		
		Object = Undefined;
		Return;
	EndIf;
	
	If ExchangeComponents.IsExchangeViaExchangePlan Then
		// Setting a data import mode for the object.
		DataExchangeServer.SetDataExchangeLoad(Object,, SendBack, ExchangeComponents.CorrespondentNode);
	Else
		DataExchangeServer.SetDataExchangeLoad(Object,, SendBack);
	EndIf;
	
	// Checking for a deletion mark of the predefined item.
	RemoveDeletionMarkFromPredefinedItem(Object, Type, ExchangeComponents);
	
	BeginTransaction();
	Try
		
		// Writing an object to the transaction.
		Object.Write();
		
		CommitTransaction();
		
	Except
		RollbackTransaction();
		
		WriteObject = False;
		
		WP         = ExchangeProtocolRecord(26, DetailErrorDescription(ErrorInfo()));
		WP.Object  = Object;
		
		If Type <> Undefined Then
			WP.ObjectType = Type;
		EndIf;
		
		WriteToExecutionProtocol(ExchangeComponents, 26, WP);
		
		Raise ExchangeComponents.ErrorMessageString;
		
	EndTry;
	
EndProcedure

// Executes deferred posting of imported documents after importing all data.
//
// Parameters:
//  ExchangeComponents - Structure - contains all exchange rules and parameters.
//
Procedure ExecuteDeferredDocumentsPosting(ExchangeComponents) Export
	
	DocumentsForDeferredPosting = ExchangeComponents.DocumentsForDeferredPosting;
	If DocumentsForDeferredPosting.Count() = 0 Then
		Return; // Queue is empty
	EndIf;
	
	// Collapsing the table by unique fields.
	DocumentsForDeferredPosting.GroupBy("DocumentRef, DocumentDate, DocumentPostedSuccessfully", "IsCollision");
	
	// Sorting the documents by dates ascending.
	ComparisonObject = New CompareValues;
	DocumentsForDeferredPosting.Sort("DocumentDate, DocumentRef", ComparisonObject);
	
	DataExchangeServer.SkipPeriodClosingCheck();
	
	For Each TableRow In DocumentsForDeferredPosting Do
		
		If TableRow.DocumentRef.IsEmpty() Then
			Continue;
		EndIf;
		
		Object = TableRow.DocumentRef.GetObject();
		
		If Object = Undefined Then
			Continue;
		EndIf;
		
		ExecuteDocumentPostingOnImport(ExchangeComponents, Object, True);
		
		TableRow.DocumentPostedSuccessfully = Object.Posted;
		
	EndDo;
	
	DataExchangeServer.SkipPeriodClosingCheck(False);
	
EndProcedure

// Posts a document upon its import to the infobase.
//
// Parameters:
//  ExchangeComponents - Structure - contains all exchange rules and parameters.
//  Object - DocumentObject - an imported document.
//  RecordIssuesInExchangeResults - Boolean - issues must be registered.
//
Procedure ExecuteDocumentPostingOnImport(
		ExchangeComponents,
		Object,
		RecordIssuesInExchangeResults = True) Export
	
	ErrorDescription = "";
	DocumentPostedSuccessfully = False;
	
	CorrespondentNode = ExchangeComponents.CorrespondentNode;
	
	// Determining a sender node to prevent object registration on the destination node. Posting is 
	// executed not in import mode.
	DataExchangeServer.SetDataExchangeLoad(Object, False, False, CorrespondentNode);
	
	Try
		
		Object.AdditionalProperties.Insert("DeferredPosting");
		
		If Object.CheckFilling() Then
			
			// Enabling the object registration rules on document posting as
			//  ORR were ignored during normal document writing in order to optimize data import speed.
			If Object.AdditionalProperties.Property("DisableObjectChangeRecordMechanism") Then
				Object.AdditionalProperties.Delete("DisableObjectChangeRecordMechanism");
			EndIf;
			
			Object.AdditionalProperties.Insert("SkipPeriodClosingCheck");
			
			// Trying to post a document.
			Object.Write(DocumentWriteMode.Posting);
			
			DocumentPostedSuccessfully = Object.Posted;
			
		EndIf;
		
	Except
		
		ErrorDescription = BriefErrorDescription(ErrorInfo());
		
	EndTry;
	
	If Not DocumentPostedSuccessfully Then
		
		DataExchangeServer.RecordDocumentPostingError(
			Object, CorrespondentNode, ErrorDescription, RecordIssuesInExchangeResults);
		
	EndIf;
	
EndProcedure

// Cancels an infobase object posting.
//
// Parameters:
//  Objects - DocumentObject - a document to cancel posting.
//  Sender - ExchangePlanRef - a reference to the exchange plan node, which is the data sender.
//
// Returns:
//   Boolean - a flag of successful posting cancellation.
Function UndoObjectPostingInIB(Object, Sender) Export
	
	InformationRegisters.DataExchangeResults.RecordIssueResolved(Object,
		Enums.DataExchangeIssuesTypes.UnpostedDocument);
	
	// Setting a data import mode for the object.
	DataExchangeServer.SetDataExchangeLoad(Object, True, False, Sender);
	
	// Checking for import restriction date conflicts.
	Object.AdditionalProperties.Insert("SkipPeriodClosingCheck");
	
	DocumentPostingCanceled = False;
	
	BeginTransaction();
	Try
		
		// Canceling a document posting.
		Object.Posted = False;
		Object.Write();
		
		DataExchangeServer.DeleteDocumentRegisterRecords(Object);
		DocumentPostingCanceled = True;
		CommitTransaction();
	Except
		RollbackTransaction();
	EndTry;
	
	Return DocumentPostingCanceled;
	
EndFunction

// The procedure fills in the object tabular section according to the previous tabular section version (before importing data).
//
// Parameters:
//  ObjectTabularSectionAfterProcessing - TabularSection - a tabular section containing changed data.
//  ObjectTabularSectionBeforeProcessing     - ValueTable - a value table, object tabular section 
//                                                          content before data import.
//  KeyFields                        - String - columns, by which search of rows in the tabular 
//                                        section is performed (a comma-separated string).
//  ColumnsToInclude                 - String - other columns (excluding the key ones) with the 
//                                        values to be changed (a comma-separated string).
//  ColumnsToExclude                - String - columns with values not to be changed (comma-separated string.)
//
Procedure FillObjectTabularSectionWithInitialData(
	ObjectTabularSectionAfterProcessing, 
	ObjectTabularSectionBeforeProcessing,
	Val KeyFields = "",
	ColumnsToInclude = "", 
	ColumnsToExclude = "") Export
	
	If TypeOf(KeyFields) = Type("String") Then
		If KeyFields = "" Then
			Return; // Cannot get mapping of new and old data without key fields.
		Else
			KeyFields = StrSplit(KeyFields, ",");
		EndIf;
	EndIf;
	
	MappingOldAndCurrentTSData = MappingOldAndCurrentTSData(
		ObjectTabularSectionAfterProcessing, 
		ObjectTabularSectionBeforeProcessing,
		KeyFields);
	
	For Each NewTSRow In ObjectTabularSectionAfterProcessing Do
		OldTSRow = MappingOldAndCurrentTSData.Get(NewTSRow);
		If OldTSRow <> Undefined Then
			FillPropertyValues(NewTSRow, OldTSRow, ColumnsToInclude, ColumnsToExclude);
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

// Returns a table of objects available for exchange of a format for the specified exchange plan.
// The list is generated according to exchange rules from the exchange manager modules by the matching versions.
//
// Parameters:
//  ExchangePlanName - String - an XDTO exchange plan name.
//  Mode          - String - presentation of requested information: "Sending" | "Receiving" | "SendingReceiving".
//                            Send - all objects, for which sending is supported, will be returned.
//                            Receive - all objects, for which receiving is supported, will be returned.
//                            SendReceive - all supported objects will be returned.
//                            SendReceive by default.
//  ExchangeNode - ExchangePlanRef, Undefined - an exchange plan node matching the correspondent.
//
// Returns:
//  ValueTable - content of supported objects of the format by versions.
//    * Version    - String - a format version. For example "1.5".
//    * Object    - String - a format object name. For example, "Catalog.Products".
//    * Send  - Boolean - shows whether sending of the current format object is supported.
//    * Receive - Boolean - shows whether receiving of the current format object is supported.
//
Function SupportedObjectsInFormat(ExchangePlanName, Mode = "SendGet", ExchangeNode = Undefined) Export
	
	ObjectsTable = New ValueTable;
	InitializeSupportedFormatObjectsTable(ObjectsTable, Mode);
	
	FormatVersions = DataExchangeServer.ExchangePlanSettingValue(ExchangePlanName, "ExchangeFormatVersions");
	
	For Each Version In FormatVersions Do
		
		If StrFind(Mode, "Send") Then
			ExchangeComponents = InitializeExchangeComponents("Send");
			
			ExchangeComponents.ExchangeFormatVersion = Version.Key;
			ExchangeComponents.ExchangeManager = Version.Value;
			
			ExchangeComponents.XMLSchema = ExchangeFormat(ExchangePlanName, ExchangeComponents.ExchangeFormatVersion);
			
			InitializeExchangeRulesTables(ExchangeComponents);
			
			FillSupportedFormatObjectsByExchangeComponents(ObjectsTable, ExchangeComponents);
		EndIf;
		
		If StrFind(Mode, "Get") Then
			ExchangeComponents = InitializeExchangeComponents("Get");
			
			ExchangeComponents.ExchangeFormatVersion = Version.Key;
			ExchangeComponents.ExchangeManager = Version.Value;
			
			ExchangeComponents.XMLSchema = ExchangeFormat(ExchangePlanName, ExchangeComponents.ExchangeFormatVersion);
			
			InitializeExchangeRulesTables(ExchangeComponents);
			
			FillSupportedFormatObjectsByExchangeComponents(ObjectsTable, ExchangeComponents);
		EndIf;
		
	EndDo;
	
	HasAlgorithm = DataExchangeServer.HasExchangePlanManagerAlgorithm(
		"OnDefineSupportedFormatObjects", ExchangePlanName);
	If HasAlgorithm Then
		ExchangePlans[ExchangePlanName].OnDefineSupportedFormatObjects(ObjectsTable, Mode, ExchangeNode);
	EndIf;
	
	Return ObjectsTable;
	
EndFunction

// Returns a table of format objects available for exchange for the specified correspondent.
//
// Parameters:
//  ExchangeNode - ExchangePlanRef - an XDTO exchange plan node of the specific correspondent.
//  Mode          - String - presentation of requested information: "Sending" | "Receiving" | "SendingReceiving".
//                            Send - all objects, for which sending is supported, will be returned.
//                            Receive - all objects, for which receiving is supported, will be returned.
//                            SendReceive - all supported objects will be returned.
//                            SendReceive by default.
//
// Returns:
//  ValueTable - content of supported objects of the format by versions.
//    * Version    - String - a format version. For example "1.5".
//    * Object    - String - a format object name. For example, "Catalog.Products".
//    * Send  - Boolean - shows whether sending of the current format object is supported by the correspondent.
//    * Receive - Boolean - shows whether receiving of the current format object is supported by the correspondent.
//
Function SupportedCorrespondentFormatObjects(ExchangeNode, Mode = "SendGet") Export
	
	ObjectsTable = New ValueTable;
	InitializeSupportedFormatObjectsTable(ObjectsTable, Mode);
	
	CorrespondentSettings = InformationRegisters.XDTODataExchangeSettings.CorrespondentSettingValue(ExchangeNode, "SupportedObjects");
	
	If Not CorrespondentSettings = Undefined Then
		
		For Each CorrespondentSettingsString In CorrespondentSettings Do
			
			If (StrFind(Mode, "Send") AND CorrespondentSettingsString.Send)
				Or (StrFind(Mode, "Get") AND CorrespondentSettingsString.Get) Then
				RowObjects = ObjectsTable.Add();
				FillPropertyValues(RowObjects, CorrespondentSettingsString);
			EndIf;
			
		EndDo;
		
	Else
		
		If Not DataExchangeServer.SynchronizationSetupCompleted(ExchangeNode) Then
			Return ObjectsTable;
		EndIf;
		
		ExchangePlanName = DataExchangeCached.GetExchangePlanName(ExchangeNode);
		
		DatabaseObjectsTable = SupportedObjectsInFormat(ExchangePlanName,
			"SendGet", ?(ExchangeNode.IsEmpty(), Undefined, ExchangeNode));
		
		For Each InfobaseObjectsString In DatabaseObjectsTable Do
			
			CorrespondentObjectsString = ObjectsTable.Add();
			FillPropertyValues(CorrespondentObjectsString, InfobaseObjectsString, "Version, Object");
			
			If StrFind(Mode, "Send") > 0 Then
				CorrespondentObjectsString.Send = InfobaseObjectsString.Get;
			EndIf;
			If StrFind(Mode, "Get") > 0 Then
				CorrespondentObjectsString.Get = InfobaseObjectsString.Send;
			EndIf;
			
		EndDo;		
	EndIf;
	
	ExchangePlanName = DataExchangeCached.GetExchangePlanName(ExchangeNode);
	HasAlgorithm = DataExchangeServer.HasExchangePlanManagerAlgorithm(
		"OnDefineFormatObjectsSupportedByCorrespondent", ExchangePlanName);
	If HasAlgorithm Then
		ExchangePlans[ExchangePlanName].OnDefineFormatObjectsSupportedByCorrespondent(ExchangeNode, ObjectsTable, Mode);
	EndIf;
	
	ObjectsTable.Indexes.Add("Object");
	
	Return ObjectsTable;
	
EndFunction

// Returns skipping mode flag when exporting format objects that have not passed check by schema.
// It can be used to set a new mode value.
//
// Parameters:
//   InfobaseNode - ExchangePlanRef - an exchange plan node matching the correspondent.
//   NewValue - Boolean, Undefined - a new mode value to set.
//                                          If Undefined, mode value is not changed.
//
// Returns:
//   Boolean - True if format objects need to be skipped when sending data.
//
Function SkipObjectsWithSchemaCheckErrors(InfobaseNode, NewValue = Undefined) Export
	
	Mode = False;
	
	SetPrivilegedMode(True);
	
	RecordManager = InformationRegisters.XDTODataExchangeSettings.CreateRecordManager();
	RecordManager.InfobaseNode = InfobaseNode;
	RecordManager.Read();
	
	If NewValue = Undefined Then
		If RecordManager.Selected() Then
			Mode = RecordManager.SkipObjectsWithSchemaCheckErrors;
		EndIf;
	Else
		RecordManager.SkipObjectsWithSchemaCheckErrors = NewValue;
		RecordManager.Write(True);
		
		Mode = NewValue;
	EndIf;
	
	Return Mode;
	
EndFunction

#EndRegion

#Region Internal

#Region ExchangeInitialization
// Creates a value table to store a data batch title.
//
// Returns:
//  Value table
//
Function NewDataBatchTitleTable() Export
	
	PackageHeaderDataTable = New ValueTable;
	Columns = PackageHeaderDataTable.Columns;
	
	Columns.Add("ObjectTypeString",            New TypeDescription("String"));
	Columns.Add("ObjectCountInSource", New TypeDescription("Number"));
	Columns.Add("SearchFields",                   New TypeDescription("String"));
	Columns.Add("TableFields",                  New TypeDescription("String"));
	
	Columns.Add("SourceTypeString", New TypeDescription("String"));
	Columns.Add("DestinationTypeString", New TypeDescription("String"));
	
	Columns.Add("SynchronizeByID", New TypeDescription("Boolean"));
	Columns.Add("IsObjectDeletion", New TypeDescription("Boolean"));
	Columns.Add("IsClassifier", New TypeDescription("Boolean"));
	Columns.Add("UsePreview", New TypeDescription("Boolean"));
	
	Return PackageHeaderDataTable;
	
EndFunction

// Gets object registration rules for the exchange plan.
//
// Returns:
//  Value table
//
Function ObjectsRegistrationRules(ExchangePlanNode) Export
	
	ObjectsRegistrationRules = DataExchangeEvents.ExchangePlanObjectsRegistrationRules(
		DataExchangeCached.GetExchangePlanName(ExchangePlanNode));
	ObjectsRegistrationRulesTable = ObjectsRegistrationRules.Copy(, "MetadataObjectName, FlagAttributeName");
	ObjectsRegistrationRulesTable.Indexes.Add("MetadataObjectName");
	
	Return ObjectsRegistrationRulesTable;
	
EndFunction

// Gets properties of an exchange plan node.
//
// Returns:
//  Structure (a key matches the attribute name and the value matches the attribute value).
Function ExchangePlanNodeProperties(Node) Export
	
	ExchangePlanNodeProperties = New Structure;
	
	// getting attribute names
	AttributesNames = Common.AttributeNamesByType(Node, Type("EnumRef.ExchangeObjectExportModes"));
	
	// Getting attribute values.
	If Not IsBlankString(AttributesNames) Then
		
		ExchangePlanNodeProperties = Common.ObjectAttributesValues(Node, AttributesNames);
		
	EndIf;
	
	Return ExchangePlanNodeProperties;
EndFunction

#EndRegion

#Region GetData

// The function checks whether the exchange message format matches EnterpriseData exchange format.
//
// Parameters:
//  ReadXML - ReadXML - an exchange message.
//
// Returns
//  True - the format matches the required format. False - the format does not match the required format.
Function CheckExchangeMessageFormat(XMLReader) Export
	
	If (XMLReader.NodeType <> XMLNodeType.StartElement
		Or XMLReader.LocalName <> "Message") Then
		Return False;
	EndIf;
		
	XMLReader.Read(); // Header
	If XMLReader.NodeType <> XMLNodeType.StartElement
		Or XMLReader.LocalName <> "Header" Then
		Return False;
	EndIf;
	
	Try
		Header = XDTOFactory.ReadXML(XMLReader, XDTOFactory.Type(XMLBaseSchema(), "Header"));
	Except
		Return False;
	EndTry;
	
	If XMLReader.NodeType <> XMLNodeType.StartElement
		Or XMLReader.LocalName <> "Body" Then
		Return False;
	EndIf;
	If Not Header.IsSet("Confirmation") Then
		Return False;
	EndIf;
	Confirmation = Header.Confirmation;
	
	ExchangePlanName = Confirmation.ExchangePlan;
	
	If Metadata.ExchangePlans.Find(ExchangePlanName) = Undefined Then
		Return False;
	EndIf;
	Return True;
EndFunction

#EndRegion

#Region ExchangeFormatVersioningProceduresAndFunctions
// Returns data exchange manager matching the specified exchange format version.
//
// Parameters:
//  FormatVersion - String.
//  InfobaseNode - ExchangePlanRef - an exchange plan node, for which you need to get the exchange manager.
//                                              If the exchange via the format is executed without using the exchange plan,
//                                              InfobaseNode is not passed.
//
Function FormatVersionExchangeManager(Val FormatVersion, Val InfobaseNode = Undefined) Export
	
	Result = ExchangeFormatVersions(InfobaseNode).Get(FormatVersion);
	
	If Result = Undefined Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не определен Менеджер конвертации для версии формата обмена <%1>.'; en = 'Conversion manager for exchange format version %1 is not specified.'; pl = 'Menedżer konwersji dla wersji formatu wymiany <%1> nie jest zdefiniowany.';de = 'Der Conversion-Manager für die Austausch-Formatversion <%1> ist nicht definiert.';ro = 'Managerul de conversii pentru versiunea formatului de schimb <%1> nu este definit.';tr = 'Değişim biçimi sürümü <%1> için Dönüşüm Yöneticisi tanımlanmadı.'; es_ES = 'Gestor de Conversión para la versión del formato de intercambio <%1> no está definido.'"),
			FormatVersion);
	EndIf;
	
	Return Result;
	
EndFunction

// Returns a string with the exchange format.
// Exchange format includes:
//  Basic format provided for the exchange plan.
//  Basic format version.
//
// Parameters:
//  ExchangePlanName - String.
//  FormatVersion - String.
//
Function ExchangeFormat(Val ExchangePlanName, Val FormatVersion) Export
	
	ExchangeFormat = DataExchangeServer.ExchangePlanSettingValue(ExchangePlanName, "ExchangeFormat");
	
	If Not IsBlankString(FormatVersion) Then
		ExchangeFormat = ExchangeFormat + "/" + FormatVersion;
	EndIf;
	
	Return ExchangeFormat;
	
EndFunction

// Returns a string with a number of the exchange format version supported by the data recipient.
//
// Parameters:
//  Recipient - a reference to the exchange plan node, to which data is exported.
//
Function ExchangeFormatVersionOnImport(Val Recipient) Export
	
	Result = Common.ObjectAttributeValue(Recipient, "ExchangeFormatVersion");
	If Not ValueIsFilled(Result) Then
		
		// If the exchange format version is not set, using the earliest version.
		Result = MinExchangeFormatVersion(Recipient);
		
	EndIf;
	
	Return TrimAll(Result);
EndFunction

// Returns a flag showing whether the node supports the format version, for which the node encoding 
//  with UUID usage is provided.
//
Function VersionWithDataExchangeIDSupported(Val InfobaseNode) Export
	
	ExchangePlanName = DataExchangeCached.GetExchangePlanName(InfobaseNode);
	
	If InfobaseNode = ExchangePlans[ExchangePlanName].ThisNode()
		Or Not ValueIsFilled(InfobaseNode) Then
		SupportedVersions = ExhangeFormatVersionsArray(InfobaseNode);
	Else
		SupportedVersions = New Array;
		SupportedVersions.Add(Common.ObjectAttributeValue(InfobaseNode, "ExchangeFormatVersion"));
	EndIf;
	
	Return VersionSupported(SupportedVersions, VersionNumberWithDataExchangeIDSupport());
	
EndFunction

#EndRegion

#Region OtherProceduresAndFunctions

// The procedure adds an infobase object to the allowed objects filter.
// Parameters:
//  Data - a reference to the infobase object to be added to the allowed objects filter.
//  Recipient - ExchangePlanRef - a reference to the exchange plan the object is being checked for.
//
Procedure AddObjectToAllowedObjectsFilter(Data, Recipient) Export
	
	InformationRegisters.ObjectsDataToRegisterInExchanges.AddObjectToAllowedObjectsFilter(Data, Recipient);
	
EndProcedure

// Returns the array of nodes the object was exported to earlier.
//
// Parameters:
//  Ref            - a reference to the infobase object to receive the node array for.
//  ExchangePlanName    - String - a name of the exchange plan as a metadata object used to determine nodes.
//  FlagAttributeName - String - a name of the exchange plan attribute used to set a node selection filter.
// Returns:
//  NodesArray - an array of exchange plan nodes with the "Export when needed" check box selected, 
//                empty by default.
//
Function NodesArrayToRegisterExportIfNecessary(Ref, ExchangePlanName, FlagAttributeName) Export
	
	QueryText = "
	|SELECT DISTINCT
	|	ExchangePlanHeader.Ref AS Node
	|FROM
	|	ExchangePlan.[ExchangePlanName] AS ExchangePlanHeader
	|LEFT JOIN
	|	InformationRegister.ObjectsDataToRegisterInExchanges AS ObjectsDataToRegisterInExchanges
	|ON
	|	ExchangePlanHeader.Ref = ObjectsDataToRegisterInExchanges.InfobaseNode
	|	AND ObjectsDataToRegisterInExchanges.Ref = &Object
	|WHERE
	|	     NOT ExchangePlanHeader.ThisNode
	|	AND    ExchangePlanHeader.[FlagAttributeName] = VALUE(Enum.ExchangeObjectExportModes.ExportIfNecessary)
	|	AND NOT ExchangePlanHeader.DeletionMark
	|	AND    ObjectsDataToRegisterInExchanges.Ref = &Object
	|";
	
	QueryText = StrReplace(QueryText, "[ExchangePlanName]",    ExchangePlanName);
	QueryText = StrReplace(QueryText, "[FlagAttributeName]", FlagAttributeName);
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Object",   Ref);
	
	NodesArray = Query.Execute().Unload().UnloadColumn("Node");
	
	Return NodesArray;
	
EndFunction

// Writes a message to the event log.
//
// Parameters:
//  Comment      - a string, comment to write to the event log.
//  Level          - an event log message level (Error by default.)
//  ExchangeComponents - Structure - contains all exchange rules and parameters.
//
Procedure WriteEventLogDataExchange(Comment, ExchangeComponents, Level = Undefined, ObjectRef = Undefined) Export
	
	CorrespondentNode = ExchangeComponents.CorrespondentNode;
	EventLogMessageKey = ExchangeComponents.EventLogMessageKey;
	
	If Level = Undefined Then
		Level = EventLogLevel.Error;
	EndIf;
	
	MetadataObject = Undefined;
	
	If     CorrespondentNode <> Undefined
		AND Not CorrespondentNode.IsEmpty() Then
		
		MetadataObject = CorrespondentNode.Metadata();
		
	EndIf;
	
	WriteLogEvent(EventLogMessageKey, Level, MetadataObject, ObjectRef, Comment);
	
EndProcedure

Procedure FillSupportedXDTODataObjects(ExchangeComponents) Export
	
	If Not ExchangeComponents.IsExchangeViaExchangePlan
		Or Not ValueIsFilled(ExchangeComponents.CorrespondentNode) Then
		Return;
	EndIf;
	
	If ExchangeComponents.ExchangeDirection = "Send" Then
		
		// The objects that can be sent from this infobase
		// and can be received in the correspondent base are supported for sending.
		// 
		
		CorrespondentDatabaseObjectsTable = SupportedCorrespondentFormatObjects(ExchangeComponents.CorrespondentNode, "Get");
		
	ElsIf ExchangeComponents.ExchangeDirection = "Get" Then
		
		// The objects that can be received in this infobase
		// and can be sent in the correspondent base are supported for receiving.
		// 
		
		CorrespondentDatabaseObjectsTable = SupportedCorrespondentFormatObjects(ExchangeComponents.CorrespondentNode, "Send");
		
	Else
		
		Return;
		
	EndIf;
	
	FilterByVersionAndDirection = New Structure("Version", ExchangeComponents.ExchangeFormatVersion);
	FilterByVersionAndDirection.Insert(ExchangeComponents.ExchangeDirection, True);
	
	DatabaseObjectTableByVersion = ExchangeComponents.XDTOSettings.SupportedObjects.Copy(FilterByVersionAndDirection);
	
	FilterByVersion = New Structure("Version", ExchangeComponents.ExchangeFormatVersion);
	
	CorrespondentDatabaseObjectsTableByVersion = CorrespondentDatabaseObjectsTable.Copy(FilterByVersion);
	
	For Each DatabaseObjectsByVersionString In DatabaseObjectTableByVersion Do
		If CorrespondentDatabaseObjectsTableByVersion.Find(DatabaseObjectsByVersionString.Object, "Object") = Undefined Then
			Continue;
		EndIf;
		
		ExchangeComponents.SupportedXDTODataObjects.Add(DatabaseObjectsByVersionString.Object);
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region ExchangeInitialization

Function DataProcessingRulesTable(XMLSchema, ExchangeManager , ExchangeDirection)
	
	// Initializing a table of data processing rules.
	DataProcessingRules = New ValueTable;
	DataProcessingRules.Columns.Add("Name");
	DataProcessingRules.Columns.Add("FilterObjectFormat");
	DataProcessingRules.Columns.Add("XDTORefType");
	DataProcessingRules.Columns.Add("SelectionObjectMetadata");
	DataProcessingRules.Columns.Add("DataSelection");
	DataProcessingRules.Columns.Add("TableNameForSelection");
	DataProcessingRules.Columns.Add("OnProcess",    New TypeDescription("String"));
	
	// UsedOCR - an array containing the names of OCR into which an object from this DPR can be sent.
	DataProcessingRules.Columns.Add("CashReceiptsUsed",    New TypeDescription("Array"));
	
	ExchangeManager.FillDataConversionRules(ExchangeDirection, DataProcessingRules);
	
	RowsCount = DataProcessingRules.Count();
	For IterationNumber = 1 To RowsCount Do
		
		RowIndex = RowsCount - IterationNumber;
		DPR = DataProcessingRules.Get(RowIndex);
		
		If ExchangeDirection = "Get" Then
			
			XDTOType = XDTOFactory.Type(XMLSchema, DPR.FilterObjectFormat);
			
			If XDTOType = Undefined Then
				DataProcessingRules.Delete(DPR);
				Continue;
			EndIf;
			
			KeyProperties = XDTOType.Properties.Get("KeyProperties");
			If KeyProperties <> Undefined Then
				
				KeyPropertiesTypeOfXDTODataObject = KeyProperties.Type;
				PropertyXDTORef = KeyPropertiesTypeOfXDTODataObject.Properties.Get("Ref");
				If PropertyXDTORef <> Undefined Then
					DPR.XDTORefType = PropertyXDTORef.Type;
				EndIf;
				
			EndIf;
			
		ElsIf DPR.SelectionObjectMetadata <> Undefined Then
			DPR.TableNameForSelection = DPR.SelectionObjectMetadata.FullName();
		EndIf;
		
	EndDo;
	
	If ExchangeDirection = "Send" Then
		DataProcessingRules.Indexes.Add("Name");
		DataProcessingRules.Indexes.Add("SelectionObjectMetadata");
	Else
		DataProcessingRules.Indexes.Add("FilterObjectFormat");
		DataProcessingRules.Indexes.Add("XDTORefType");
	EndIf;
	
	Return DataProcessingRules;
EndFunction

Function ConversionRulesTable(XMLSchema, ExchangeManager , ExchangeDirection, DataProcessingRules, ExchangeManagerFormatVersion)
	
	// Initializing the data conversion rules table.
	ConversionRules = New ValueTable;
	ConversionRules.Columns.Add("OCRName", New TypeDescription("String",,New StringQualifiers(50)));
	ConversionRules.Columns.Add("DataObject");
	ConversionRules.Columns.Add("FormatObject",                         New TypeDescription("String"));
	ConversionRules.Columns.Add("ReceivedDataTypeAsString",            New TypeDescription("String",,New StringQualifiers(300)));
	ConversionRules.Columns.Add("ReceivedDataTableName",            New TypeDescription("String",,New StringQualifiers(300)));
	ConversionRules.Columns.Add("ReceivedDataTypePresentation",     New TypeDescription("String",,New StringQualifiers(300)));
	ConversionRules.Columns.Add("Properties",                              New TypeDescription("ValueTable"));
	ConversionRules.Columns.Add("SearchFields",                            New TypeDescription("Array"));
	ConversionRules.Columns.Add("ObjectPresentationFields",              New TypeDescription("String",,New StringQualifiers(300)));
	ConversionRules.Columns.Add("ReceivedDataHeaderAttributes",        New TypeDescription("Array"));
	ConversionRules.Columns.Add("OnSendData",                     New TypeDescription("String"));
	ConversionRules.Columns.Add("OnConvertXDTOData",              New TypeDescription("String"));
	ConversionRules.Columns.Add("BeforeWriteReceivedData",          New TypeDescription("String"));
	ConversionRules.Columns.Add("AfterImportAllData",               New TypeDescription("String"));
	ConversionRules.Columns.Add("RuleForCatalogGroup",           New TypeDescription("Boolean"));
	ConversionRules.Columns.Add("IdentificationOption",                  New TypeDescription("String",,New StringQualifiers(60)));
	ConversionRules.Columns.Add("AllowCreateObjectFromStructure");
	
	If ExchangeManagerFormatVersion = "1" Then
		TSPropertiesTypesDetails = New TypeDescription("Structure");
		ConversionRules.Columns.Add("ProcessedTabularSectionsProperties", New TypeDescription("ValueTable"));
	Else
		TSPropertiesTypesDetails = New TypeDescription("ValueTable");
	EndIf;
	ConversionRules.Columns.Add("TabularSectionsProperties",               TSPropertiesTypesDetails);
	
	ExchangeManager.FillObjectsConversionRules(ExchangeDirection, ConversionRules);
	
	If ExchangeDirection = "Get" Then
		
		// Selecting conversion rule rows with empty AllowCreateObjectFromStructure attribute.
		FilterParameters = New Structure("AllowCreateObjectFromStructure", Undefined);
		RowsToProcess = ConversionRules.FindRows(FilterParameters);
		
		// The AllowCreateObjectFromStructure attribute is to be filled in for found rows.
		// The attribute is filled according to the following algorithm:
		// if the conversion rule of the format object is not specified in data processing rules for this 
		// format object, then the attribute is filled with the True value, since the data received for this 
		// OCR cannot be imported independently. Otherwise it is False.
		// 
		// 
		For Each ProcessingRow In RowsToProcess Do
			ProcessingRow.AllowCreateObjectFromStructure = True;
			DataProcessingRulesRow = DataProcessingRules.Find(ProcessingRow.FormatObject, "FilterObjectFormat");
			If DataProcessingRulesRow <> Undefined Then
				ArrayOfOCRBeingUsed = DataProcessingRulesRow.CashReceiptsUsed;
				ProcessingRow.AllowCreateObjectFromStructure = ArrayOfOCRBeingUsed.Find(ProcessingRow.OCRName) = Undefined;
			EndIf;
		EndDo;
		
	EndIf;
	
	// Adding service fields to the conversion rules table.
	ConversionRules.Columns.Add("XDTOType");
	ConversionRules.Columns.Add("XDTORefType");
	ConversionRules.Columns.Add("KeyPropertiesTypeOfXDTODataObject");
	ConversionRules.Columns.Add("DataType");
	
	ConversionRules.Columns.Add("ObjectManager");
	ConversionRules.Columns.Add("FullName");
	
	ConversionRules.Columns.Add("IsDocument",               New TypeDescription("Boolean"));
	ConversionRules.Columns.Add("IsRegister",                New TypeDescription("Boolean"));
	ConversionRules.Columns.Add("IsCatalog",             New TypeDescription("Boolean"));
	ConversionRules.Columns.Add("IsEnum",           New TypeDescription("Boolean"));
	ConversionRules.Columns.Add("IsChartOfCharacteristicTypes", New TypeDescription("Boolean"));
	ConversionRules.Columns.Add("IsBusinessProcess",          New TypeDescription("Boolean"));
	ConversionRules.Columns.Add("IsTask",                 New TypeDescription("Boolean"));
	ConversionRules.Columns.Add("IsChartOfAccounts",             New TypeDescription("Boolean"));
	ConversionRules.Columns.Add("IsChartOfCalculationTypes",       New TypeDescription("Boolean"));
	ConversionRules.Columns.Add("IsConstant",              New TypeDescription("Boolean"));
	
	ConversionRules.Columns.Add("DocumentCanBePosted", New TypeDescription("Boolean"));
	
	ConversionRules.Columns.Add("IsReferenceType", New TypeDescription("Boolean"));
	
	ConversionRules.Columns.Add("HasHandlerOnSendData",            New TypeDescription("Boolean"));
	ConversionRules.Columns.Add("HasHandlerOnConvertXDTOData",     New TypeDescription("Boolean"));
	ConversionRules.Columns.Add("HasHandlerBeforeWriteReceivedData", New TypeDescription("Boolean"));
	ConversionRules.Columns.Add("HasHandlerAfterImportAllData",      New TypeDescription("Boolean"));
	
	AllowDocumentPosting = Metadata.ObjectProperties.Posting.Allow;
	
	RowsCount = ConversionRules.Count();
	For IterationNumber = 1 To RowsCount Do
		
		RowIndex = RowsCount - IterationNumber;
		ConversionRule = ConversionRules.Get(RowIndex);
		
		If ValueIsFilled(ConversionRule.FormatObject) Then
			ConversionRule.XDTOType = XDTOFactory.Type(XMLSchema, ConversionRule.FormatObject);
			If ConversionRule.XDTOType = Undefined Then
				ConversionRules.Delete(ConversionRule);
				Continue;
			EndIf;
		EndIf;
		
		If ExchangeDirection = "Get" Then
			
			ObjectMetadata = ConversionRule.DataObject;
		
			ConversionRule.ReceivedDataTableName = ObjectMetadata.FullName();
			ConversionRule.ReceivedDataTypePresentation = ObjectMetadata.Presentation();
			ConversionRule.ReceivedDataTypeAsString = DataTypeNameByMetadataObject(ConversionRule.DataObject);
		
			ConversionRule.ObjectPresentationFields = ?(ConversionRule.SearchFields.Count() = 0, "", ConversionRule.SearchFields[0]);
			
			// Attributes of the object of data to be received.
			ArrayAttributes = New Array;
			For Each Attribute In ObjectMetadata.StandardAttributes Do
				If Attribute.Name = "Description"
					OR Attribute.Name = "Code"
					OR Attribute.Name = "IsFolder"
					OR Attribute.Name = "Parent"
					OR Attribute.Name = "Owner"
					OR Attribute.Name = "Date"
					OR Attribute.Name = "Number" Then
					ArrayAttributes.Add(Attribute.Name);
				EndIf;
			EndDo;
			For Each Attribute In ObjectMetadata.Attributes Do
				ArrayAttributes.Add(Attribute.Name);
			EndDo;

			ConversionRule.ReceivedDataHeaderAttributes = ArrayAttributes;
			
			ConversionRule.HasHandlerOnConvertXDTOData     = Not IsBlankString(ConversionRule.OnConvertXDTOData);
			ConversionRule.HasHandlerBeforeWriteReceivedData = Not IsBlankString(ConversionRule.BeforeWriteReceivedData);
			ConversionRule.HasHandlerAfterImportAllData      = Not IsBlankString(ConversionRule.AfterImportAllData);

		Else
			ConversionRule.HasHandlerOnSendData            = Not IsBlankString(ConversionRule.OnSendData);
		EndIf;
		
		If ConversionRule.DataObject <> Undefined Then
			
			ConversionRule.FullName                  = ConversionRule.DataObject.FullName();
			ConversionRule.ObjectManager            = Common.ObjectManagerByFullName(ConversionRule.FullName);
			
			ConversionRule.IsRegister                = Common.IsRegister(ConversionRule.DataObject);
			ConversionRule.IsDocument               = Common.IsDocument(ConversionRule.DataObject);
			ConversionRule.IsCatalog             = Common.IsCatalog(ConversionRule.DataObject);
			ConversionRule.IsEnum           = Common.IsEnum(ConversionRule.DataObject);
			ConversionRule.IsChartOfCharacteristicTypes = Common.IsChartOfCharacteristicTypes(ConversionRule.DataObject);
			ConversionRule.IsBusinessProcess          = Common.IsBusinessProcess(ConversionRule.DataObject);
			ConversionRule.IsTask                 = Common.IsTask(ConversionRule.DataObject);
			ConversionRule.IsChartOfAccounts             = Common.IsChartOfAccounts(ConversionRule.DataObject);
			ConversionRule.IsChartOfCalculationTypes       = Common.IsChartOfCalculationTypes(ConversionRule.DataObject);
			ConversionRule.IsConstant              = Common.IsConstant(ConversionRule.DataObject);
			
			ConversionRule.DataType = Type(DataTypeNameByMetadataObject(ConversionRule.DataObject));
			
			If ConversionRule.IsDocument Then
				ConversionRule.DocumentCanBePosted = ConversionRule.DataObject.Posting = AllowDocumentPosting;
			EndIf;
			
		EndIf;
		
		
		ConversionRule.IsReferenceType = ConversionRule.IsDocument
			Or ConversionRule.IsCatalog
			Or ConversionRule.IsChartOfCharacteristicTypes
			Or ConversionRule.IsBusinessProcess
			Or ConversionRule.IsTask
			Or ConversionRule.IsChartOfAccounts
			Or ConversionRule.IsChartOfCalculationTypes;
		
		If ValueIsFilled(ConversionRule.FormatObject) Then
			KeyProperties = ConversionRule.XDTOType.Properties.Get("KeyProperties");
			If KeyProperties <> Undefined Then
				
				KeyPropertiesTypeOfXDTODataObject = KeyProperties.Type;
				ConversionRule.KeyPropertiesTypeOfXDTODataObject = KeyPropertiesTypeOfXDTODataObject;
				
				KeyPropertiesProperties = New Array;
				FillXDTODataObjectPropertiesList(KeyPropertiesTypeOfXDTODataObject, KeyPropertiesProperties);
				
				PCRToAdd = New Array;
				
				PCRTable = ConversionRule.Properties;
				For Each PCR In PCRTable Do
					
					If KeyPropertiesProperties.Find(PCR.FormatProperty) <> Undefined Then
						PCR.KeyPropertyProcessing = True;
						
						If ConversionRule.XDTOType.Properties.Get(PCR.FormatProperty) <> Undefined Then
							PCRToAdd.Add(PCR);
						EndIf;
					EndIf;
					
				EndDo;
				
				For Each PCR In PCRToAdd Do
					NewPCR = PCRTable.Add();
					FillPropertyValues(NewPCR, PCR, , "KeyPropertyProcessing");
				EndDo;
				
				PropertyXDTORef = KeyPropertiesTypeOfXDTODataObject.Properties.Get("Ref");
				If PropertyXDTORef <> Undefined Then
					
					ConversionRule.XDTORefType = PropertyXDTORef.Type;
					
					If ConversionRule.IsReferenceType
						AND ExchangeDirection = "Send" Then
						PCRForRef = PCRTable.Add();
						PCRForRef.ConfigurationProperty = "Ref";
						PCRForRef.FormatProperty = "Ref";
						PCRForRef.KeyPropertyProcessing = True;
					EndIf;
					
				EndIf;
				
			EndIf;
		EndIf;
		
		If ConversionRule.IdentificationOption = "BySearchFields"
			Or ConversionRule.IdentificationOption = "FirstByUUIDThenBySearchFields" Then
			
			PCRTable = ConversionRule.Properties;
			For Each PCR In PCRTable Do
				
				If ValueIsFilled(ConversionRule.SearchFields) Then
					For Each SearchFieldsItem In ConversionRule.SearchFields Do
						SearchFieldsAsArray = StrSplit(SearchFieldsItem, ",");
						For Each SearchField In SearchFieldsAsArray Do
							SearchField = TrimAll(SearchField);
							If SearchField = PCR.ConfigurationProperty Then
								PCR.SearchPropertyHandler = True;
								Break;
							EndIf;
						EndDo;
					EndDo;
				EndIf;
				
			EndDo;
			
		EndIf;
		
		If ExchangeManagerFormatVersion = "1" Then
			InitializeTabularSectionsProperties(ConversionRule, "ProcessedTabularSectionsProperties");
			For Each TS In ConversionRule.TabularSectionsProperties Do
				TabularSectionsPropertiesRow = ConversionRule.ProcessedTabularSectionsProperties.Add();
				TabularSectionsPropertiesRow.UsesConversionAlgorithm = True;
				TabularSectionsPropertiesRow.Properties = TS.Value;
				If ExchangeDirection = "Get" Then
					TabularSectionsPropertiesRow.ConfigurationTabularSection = TS.Key;
				Else
					TabularSectionsPropertiesRow.FormatTS = TS.Key;
				EndIf;
			EndDo;
		Else
			// Filling in information on tabular sections properties conversion.
			For Each TSPCR In ConversionRule.TabularSectionsProperties Do
				For Each PCR In TSPCR.Properties Do
					If PCR.UsesConversionAlgorithm Then
						TSPCR.UsesConversionAlgorithm = True;
						Break;
					EndIf;
				EndDo;
			EndDo;
		EndIf;
	EndDo;
	
	If ExchangeManagerFormatVersion = "1" Then
		ConversionRules.Columns.Delete(ConversionRules.Columns.TabularSectionsProperties);
		ConversionRules.Columns.Add("TabularSectionsProperties", New TypeDescription("ValueTable"));
		For Each ConversionRule In ConversionRules Do
			InitializeTabularSectionsProperties(ConversionRule);
			For Each TSProperty In ConversionRule.ProcessedTabularSectionsProperties Do
				TabularSectionsPropertiesRow = ConversionRule.TabularSectionsProperties.Add();
				FillPropertyValues(TabularSectionsPropertiesRow, TSProperty);
				For Each PCR In TabularSectionsPropertiesRow.Properties Do
					If PCR.UsesConversionAlgorithm Then
						TabularSectionsPropertiesRow.UsesConversionAlgorithm = True;
						Break;
					EndIf;
				EndDo;
			EndDo;
		EndDo;
		ConversionRules.Columns.Delete(ConversionRules.Columns.ProcessedTabularSectionsProperties);
	EndIf;
	
	// Adding conversion rules table indexes.
	ConversionRules.Indexes.Add("OCRName");
	ConversionRules.Indexes.Add("DataType");
	ConversionRules.Indexes.Add("XDTOType");
	If ExchangeDirection = "Get" Then
		ConversionRules.Indexes.Add("XDTORefType");
	EndIf;
	
	Return ConversionRules;
EndFunction

Function PredefinedDataConversionRulesTable(XMLSchema, ExchangeManager , ExchangeDirection)
	
	// Initializing the data conversion rules table.
	ConversionRules = New ValueTable;
	ConversionRules.Columns.Add("DataType");
	ConversionRules.Columns.Add("XDTOType");
	ConversionRules.Columns.Add("ConvertValuesOnReceipt");
	ConversionRules.Columns.Add("ConvertValuesOnSend");
	
	ConversionRules.Columns.Add("PDCRName", New TypeDescription("String"));
	
	ExchangeManager.FillPredefinedDataConversionRules(ExchangeDirection, ConversionRules);
	
	For Each ConversionRule In ConversionRules Do
	
		ConversionRule.XDTOType = XDTOFactory.Type(XMLSchema, ConversionRule.XDTOType);
		ConversionRule.DataType = Type(DataTypeNameByMetadataObject(ConversionRule.DataType));
		
	EndDo;
	
	ConversionRules.Indexes.Add("PDCRName");
	ConversionRules.Indexes.Add("DataType");
	ConversionRules.Indexes.Add("DataType,XDTOType");
	
	Return ConversionRules;
	
EndFunction

Function ConversionParametersStructure(ExchangeManager)
	// Initializing a structure with conversion parameters.
	//	Probably, in the future you will need not a structure, but a table if you pass parameters from 
	//	one infobase to another.
	ConversionParameters = New Structure();
	ExchangeManager.FillConversionParameters(ConversionParameters);
	Return ConversionParameters;
EndFunction

#EndRegion

#Region DataSending

Procedure ExecuteRegisteredDataExport(ExchangeComponents, MessageNumber)
	
	NodeForExchange = ExchangeComponents.CorrespondentNode;
	
	InitialDataExport = DataExchangeServer.InitialDataExportFlagIsSet(NodeForExchange);
	
	// Getting changed data selection.
	ChangesSelection = ExchangePlans.SelectChanges(NodeForExchange, MessageNumber);
	
	ObjectsToExportCount = 0;
	While ChangesSelection.Next() Do
		ObjectsToExportCount = ObjectsToExportCount + 1;
	EndDo;
	ExchangeComponents.Insert("ObjectsToExportCount", ObjectsToExportCount);
	
	NodeForExchangeObject = NodeForExchange.GetObject();
	
	//  Algorithm of data export to an XML file:
	// 1. Get data from the infobase.
	// 2. Send information about deletion or export data.
	// 3. Convert Data to Structure using conversion rule.
	// 4. Convert Data to Structure using the OnSendData handler.
	// 5. Convert Structure to XDTODataObject.
	// 6. Write XDTODataObject to an XML file.
	ChangesSelection.Reset();
	While ChangesSelection.Next() Do
		Data = ChangesSelection.Get();
		
		Try
			If TypeOf(Data) = Type("ObjectDeletion") Then
				ExportDeletion(ExchangeComponents, Data.Ref);
			Else
				ItemSending = DataItemSend.Auto;
				DataExchangeEvents.OnSendDataToRecipient(Data, ItemSending, InitialDataExport, NodeForExchangeObject, False);
				
				// Sending an empty record set upon the register deletion.
				If ItemSending = DataItemSend.Delete
					AND Common.IsRegister(Data.Metadata()) Then
					ItemSending = DataItemSend.Auto;
				EndIf;
				
				If ItemSending = DataItemSend.Delete Then
					ExportDeletion(ExchangeComponents, Data.Ref);
				ElsIf ItemSending = DataItemSend.Ignore Then
					// The situation when the object does not match the filter conditions, but it is not to be sent as a deletion.
					// Occurs in case of initial data export.
					Continue;
				Else
					ExportSelectionObject(ExchangeComponents, Data);
				EndIf;
			EndIf;
			
			ExchangeComponents.ExportedObjectCounter = ExchangeComponents.ExportedObjectCounter + 1;
			DataExchangeServer.CalculateExportPercent(ExchangeComponents.ExportedObjectCounter, ExchangeComponents.ObjectsToExportCount);
			
		Except
			Info = ErrorInfo();
			DataPresentation = ObjectPresentationForProtocol(Data);
			
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Событие: %1.
				|Объект: %2.
				|
				|%3'; 
				|en = 'Event: %1.
				|Object: %2.
				|
				|%3'; 
				|pl = 'Zdarzenie: %1.
				|Obiekt: %2.
				|
				|%3';
				|de = 'Ereignis: %1.
				|Objekt: %2.
				|
				|%3';
				|ro = 'Evenimentul: %1.
				|Obiectul: %2.
				|
				|%3';
				|tr = 'Olay: %1. Nesne: 
				|. %2
				|
				|%3'; 
				|es_ES = 'Evento: %1.
				|Objeto: %2.
				|
				|%3'"),
				ExchangeComponents.ExchangeDirection,
				DataPresentation,
				DetailErrorDescription(Info));
		EndTry;
	EndDo;
	
EndProcedure

Procedure ExportObjectsByRef(ExchangeComponents, RefsFromObject)
	
	If Not ExchangeComponents.IsExchangeViaExchangePlan Then
		Return;
	EndIf;
			
	For Each RefValue In RefsFromObject Do
		
		If ExchangeComponents.ExportedObjects.Find(RefValue) = Undefined
			AND ExportObjectIfNecessary(ExchangeComponents, RefValue) Then
			
			If Not InformationRegisters.ObjectsDataToRegisterInExchanges.ObjectIsInRegister(
				RefValue, ExchangeComponents.CorrespondentNode) Then
				
				ObjectToExportByRef = Undefined;
				
				If Common.RefExists(RefValue) Then
					ObjectToExportByRef = RefValue.GetObject();
				EndIf;
				
				If ObjectToExportByRef <> Undefined Then
					
					ExportSelectionObject(ExchangeComponents, ObjectToExportByRef);
					ExchangeComponents.ExportedByRefObjects.Add(RefValue);
					InformationRegisters.ObjectsDataToRegisterInExchanges.AddObjectToAllowedObjectsFilter(
						RefValue, ExchangeComponents.CorrespondentNode);
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Function IsXDTORef(Val Type)
	
	Return XDTOFactory.Type(XMLBaseSchema(), "Ref").IsDescendant(Type);
	
EndFunction

Function ExportObjectIfNecessary(ExchangeComponents, Object)
	
	MetadataObject = Metadata.FindByType(TypeOf(Object));
	
	If MetadataObject = Undefined Then
		Return False;
	EndIf;
	
	// Receiving a setting from cache.
	RegisterIfNecessary = ExchangeComponents.MapRegistrationOnRequest.Get(MetadataObject);
	If RegisterIfNecessary <> Undefined Then
		Return RegisterIfNecessary;
	EndIf;
	
	RegisterIfNecessary = False;
	
	Filter = New Structure("MetadataObjectName", MetadataObject.FullName());
	RulesArray = ExchangeComponents.ObjectsRegistrationRulesTable.FindRows(Filter);
	
	For Each Rule In RulesArray Do
		
		If Not IsBlankString(Rule.FlagAttributeName) Then
			
			FlagAttributeValue = Undefined;
			ExchangeComponents.ExchangePlanNodeProperties.Property(Rule.FlagAttributeName, FlagAttributeValue);
			
			RegisterIfNecessary = (FlagAttributeValue = Enums.ExchangeObjectExportModes.ExportIfNecessary
				Or FlagAttributeValue = Enums.ExchangeObjectExportModes.EmptyRef());

			If RegisterIfNecessary Then
				Break;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	// Saving the received value to cache.
	ExchangeComponents.MapRegistrationOnRequest.Insert(MetadataObject, RegisterIfNecessary);
	Return RegisterIfNecessary;
	
EndFunction

Procedure WriteXDTODataObjectDeletion(ExchangeComponents, Ref, XDTORefType)
	
	XDTODataObjectUUID = InformationRegisters.SynchronizedObjectPublicIDs.PublicIDByObjectRef(
		ExchangeComponents.CorrespondentNode, Ref);
		
	If Not ValueIsFilled(XDTODataObjectUUID) Then
		Return;
	EndIf;
	
	XMLSchema = ExchangeComponents.XMLSchema;
	XDTOType  = XDTOFactory.Type(XMLSchema, "ObjectDeletion");
	
	For Each Property In XDTOType.Properties[0].Type.Properties[0].Type.Properties Do
		If Property.Type = XDTORefType Then
			
			AnyRefXDTOValue = XDTOFactory.Create(Property.Type, XDTODataObjectUUID);
			AnyRefObject = XDTOFactory.Create(XDTOType.Properties[0].Type);
			AnyRefObject.ObjectRef = XDTOFactory.Create(XDTOType.Properties[0].Type.Properties[0].Type);
			AnyRefObject.ObjectRef.Set(Property, AnyRefXDTOValue);
			
			XDTOData = XDTOFactory.Create(XDTOType);
			XDTOData.ObjectRef = XDTOFactory.Create(XDTOType.Properties[0].Type);
			XDTOData.Set(XDTOType.Properties[0], AnyRefObject);
			XDTOFactory.WriteXML(ExchangeComponents.ExchangeFile, XDTOData);
			Break;
			
		EndIf;
	EndDo;
	
EndProcedure

// Parameters:
//   ExchangeComponents - structure contains all key data for exchange (such as OCR, PDCR, DPR.)
//   Ref - a deleted object.
//   ConversionRule  - a row of a table of object conversion rules according to which the conversion is performed.
//
Procedure ExportDeletion(ExchangeComponents, Ref, ConversionRule = Undefined)
	
	If ConversionRule <> Undefined Then
		// OCR was passed explicitly (when calling deletion for a specific OCR).
		If Not FormatObjectPassesXDTOFilter(ExchangeComponents, ConversionRule.FormatObject) Then
			Return;
		EndIf;
		
		WriteXDTODataObjectDeletion(ExchangeComponents, Ref, ConversionRule.XDTORefType);
	Else
		
		// Searching for OCR
		OCRNamesArray = DPRByMetadataObject(ExchangeComponents, Ref.Metadata()).CashReceiptsUsed;
		
		// Array is used for collapsing OCR by XDTO types.
		ProcessedXDTORefsTypes = New Array;
		
		For Each ConversionRuleName In OCRNamesArray Do
			
			ConversionRule = ExchangeComponents.ObjectConversionRules.Find(ConversionRuleName, "OCRName");
			
			If ConversionRule = Undefined Then
				// An OCR not intended for the current data format  version can be specified.
				Continue;
			EndIf;
			
			If Not FormatObjectPassesXDTOFilter(ExchangeComponents, ConversionRule.FormatObject) Then
				Continue;
			EndIf;
			
			// Collapsing OCR by XDTO reference type.
			XDTORefType = ConversionRule.XDTORefType;
			If ProcessedXDTORefsTypes.Find(XDTORefType) = Undefined Then
				ProcessedXDTORefsTypes.Add(XDTORefType);
			Else
				Continue;
			EndIf;
			
			WriteXDTODataObjectDeletion(ExchangeComponents, Ref, XDTORefType);
			
		EndDo;
		
	EndIf;
EndProcedure

Function ConvertEnumerationToXDTO(ExchangeComponents, EnumValue, XDTOEnumerationType)
	If TypeOf(EnumValue) = Type("String") Then
	
		XDTOValue = XDTOFactory.Create(XDTOEnumerationType, EnumValue);
		
	Else
	
		PredefinedDataConversionRules = ExchangeComponents.PredefinedDataConversionRules;
		
		ConversionRule = FindConversionRuleForValue(
			PredefinedDataConversionRules, TypeOf(EnumValue), XDTOEnumerationType);
		
		XDTOValue = XDTOFactory.Create(XDTOEnumerationType,
			XDTOEnumerationValue(ConversionRule.ConvertValuesOnSend, EnumValue));
		
	EndIf;
	Return XDTOValue;
EndFunction

Function FindConversionRuleForValue(PredefinedDataConversionRules, Val Type, Val XDTOType = Undefined)
	
	If XDTOType = Undefined Then
		
		FoundRules = PredefinedDataConversionRules.FindRows(New Structure("DataType", Type));
		
		If FoundRules.Count() = 1 Then
			
			ConversionRule = FoundRules[0];
			
			Return ConversionRule;
			
		ElsIf FoundRules.Count() > 1 Then
			
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Ошибка правил конвертации предопределенных данных.
				|Задано более одного правила конвертации для типа источника <%1>.'; 
				|en = 'Predefined data conversion rule error.
				|Multiple conversion rules are specified for source type ""%1.""'; 
				|pl = 'Błąd zasady konwersji predefiniowanych danych.
				|Więcej niż jedna zasada konwersji dla typu źródła <%1> jest określona.';
				|de = 'Konvertierungsregeln Fehler der vordefinierten Daten. 
				|Es wurde mehr als eine Konvertierungsregel für den Quelltyp <%1> angegeben.';
				|ro = 'Eroare a regulilor de conversie a datelor predefinite.
				|Este specificată mai mult de o regulă de conversie pentru tipul de sursă <%1>.';
				|tr = 'Ön tanımlı verilerin dönüşüm kuralları hatası. %1<
				|> Kaynak türü için birden fazla dönüşüm kuralı belirtildi.'; 
				|es_ES = 'Error de las reglas de conversión de los datos predefinidos.
				|Más de una reglas de conversión para el tipo de fuente <%1> está especificada.'"),
				String(Type));
			
		EndIf;
		
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Ошибка правил конвертации предопределенных данных.
			|Правило конвертации не определено для типа источника <%1>.'; 
			|en = 'Predefined data conversion rule error.
			|The conversion rule is not specified for source type ""%1.""'; 
			|pl = 'Błąd reguły konwersji predefiniowanych danych.
			|Konwersja reguły jest niezdefiniowana dla typu źródła <%1>.';
			|de = 'Konvertierungsregeln Fehler der vordefinierten Daten. 
			|Die Regelkonvertierung ist für den Quellentyp <%1> nicht definiert.';
			|ro = 'Eroare a regulilor de conversie a datelor predefinite.
			|Nu este definită regula de conversie pentru tipul de sursă <%1>.';
			|tr = 'Ön tanımlı verilerin dönüşüm kuralları hatası. %1Kural dönüşümü <
			|> kaynak türü için tanımsız.'; 
			|es_ES = 'Error de las reglas de conversión de los datos predefinidos.
			|Conversión de la regla está sin definir para el tipo de fuente <%1>.'"),
			String(Type));
			
	Else
		
		FoundRules = PredefinedDataConversionRules.FindRows(New Structure("DataType, XDTOType", Type, XDTOType, False));
		
		If FoundRules.Count() = 1 Then
			
			ConversionRule = FoundRules[0];
			
			Return ConversionRule;
			
		ElsIf FoundRules.Count() > 1 Then
			
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Ошибка правил конвертации предопределенных данных.
				|Задано более одного правила конвертации для типа источника <%1> и типа приемника <%2>.'; 
				|en = 'Predefined data conversion rule error.
				|Multiple conversion rules are specified for source type ""%1"" and destination type ""%2.""'; 
				|pl = 'Błąd zasady konwersji predefiniowanych danych.
				|Określono więcej niż jedną zasadę konwersji dla typu źródła <%1> i typu odbiorcy <%2>.';
				|de = 'Beim Konvertieren der vordefinierten Daten ist ein Fehler aufgetreten. 
				|Für Quelltyp <%1> und Zieltyp <%2> sind mehrere Konvertierungsregeln angegeben.';
				|ro = 'A apărut o eroare la conversia datelor predefinite.
				|Mai mult de o regulă de conversie este specificată pentru tipul de sursă <%1> și tipul destinației <%2>.';
				|tr = 'Ön tanımlı verilerin dönüşüm kuralları hatası. 
				|<%1> Kaynak türü ve <%2> alıcı türü için birden fazla dönüşüm kuralı belirtildi.'; 
				|es_ES = 'Error de las reglas de conversión de los datos predefinidos.
				|Más de una reglas de la conversión para el tipo de fuente <%1> y el tipo de destinatario <%2> está especificada.'"),
				String(Type),
				String(XDTOType));
			
		EndIf;
		
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Ошибка правил конвертации предопределенных данных.
			|Правило конвертации не определено для типа источника <%1> и типа приемника <%2>.'; 
			|en = 'Predefined data conversion rule error.
			|The conversion rule is not specified for source type ""%1"" and destination type ""%2.""'; 
			|pl = 'Błąd reguły konwersji predefiniowanych danych.
			|Reguła konwersji nie jest zdefiniowana dla typu %1 źródła i %2 typu odbiorcy.';
			|de = 'Bei der Konvertierung der vordefinierten Daten ist ein Fehler aufgetreten. 
			|Für den Quelltyp <%1> und den Zieltyp <%2> ist die Konvertierungsregel nicht angegeben.';
			|ro = 'A apărut o eroare la conversia datelor predefinite.
			|Regula de conversie nu este specificată pentru tipul de sursă <%1> și tipul destinației <%2>.';
			|tr = 'Ön tanımlı verilerin dönüşüm kuralları hatası. 
			| %1 Kaynak türü ve %2 alıcı türü için birden fazla dönüşüm kuralı belirtilmedi.'; 
			|es_ES = 'Error de las reglas de conversión de los datos predefinidos.
			|Regla de la conversión no está definida para un tipo de fuente %1 y un tipo de destinatario %2.'"),
			String(Type),
			String(XDTOType));
		
	EndIf;
	
EndFunction

Function XDTOEnumerationValue(Val ValuesConversions, Val Value)
	
	XDTOValue = ValuesConversions.Get(Value);
	
	If XDTOValue = Undefined Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не найдено правило конвертации для значения предопределенных данных.
			|Тип значения источника: <%1>
			|Значение источника: <%2>'; 
			|en = 'A predefined data conversion rule is not found.
			|Source value type: ""%1.""
			|Source value: ""%2"".'; 
			|pl = 'Nie jest znaleziona reguła konwersji dla wartości określonych wcześniej danych.
			|Typ wartości źródła: <%1>
			|Wartość źródła: <%2>';
			|de = 'Für den Wert der vordefinierten Daten wurde keine Konvertierungsregel gefunden.
			|Quellwerttyp: <%1>
			| Quellwert: <%2>';
			|ro = 'Regula de conversie pentru valoarea datelor predefinite nu a fost găsită.
			|Tipul valorii sursei: <%1>
			| Valoarea sursă: <%2>';
			|tr = 'Ön tanımlı verilerin değeri için dönüşüm kuralı bulunamadı. %1Kaynak değer türü: <
			|> %2Kaynak değeri: <
			|>'; 
			|es_ES = 'No se ha encontrado una regla de conversión para valor de los datos predeterminados.
			|Tipo de valor de la fuente: <%1>
			|Valor de fuente: <%2>'"),
			TypeOf(Value),
			String(Value));
	EndIf;
	
	Return XDTOValue;
EndFunction

Function ConvertRefToXDTO(ExchangeComponents, RefValue, XDTORefType)
	
	If ExchangeComponents.IsExchangeViaExchangePlan Then
	
		XDTODataObjectUUID = InformationRegisters.SynchronizedObjectPublicIDs.PublicIDByObjectRef(
			ExchangeComponents.CorrespondentNode, RefValue);
		XDTOValue = XDTOFactory.Create(XDTORefType, XDTODataObjectUUID);
			
		Return XDTOValue;
		
	Else
		Return TrimAll(RefValue.UUID());
	EndIf;
	
EndFunction

Function IsObjectTable(Val XDTOProperty)
	
	If TypeOf(XDTOProperty.Type) = Type("XDTOObjectType")
		AND XDTOProperty.Type.Properties.Count() = 1 Then
		
		Return XDTOProperty.Type.Properties[0].UpperBound <> 1;
		
	EndIf;
	
	Return False;
EndFunction

Procedure GetNestedPropertiesValue(PropertySource, NestedProperties, PropertyValue)
	CurrentPropertySource = PropertySource;
	CurrentPropertyValue = Undefined;
	For Level = 0 To NestedProperties.Count()-1 Do
		If NOT CurrentPropertySource.Property(NestedProperties[Level], CurrentPropertyValue) Then
			Break;
		EndIf;
		If Level = NestedProperties.Count()-1 Then
			PropertyValue = CurrentPropertyValue;
		ElsIf TypeOf(CurrentPropertyValue) <> Type("Structure") Then
			Break;
		Else
			CurrentPropertySource = CurrentPropertyValue;
			CurrentPropertyValue = Undefined;
		EndIf;
	EndDo;
EndProcedure

Procedure PutNestedPropertiesValue(PropertyRecipient, NestedProperties, PropertyValue, IsTSRow)
	PropertyName = NestedProperties[0];
	NestedPropertiesValue = Undefined;
	If IsTSRow Then
		If PropertyRecipient.Owner().Columns.Find(PropertyName) = Undefined Then
			PropertyRecipient.Owner().Columns.Add(PropertyName);
		Else
			NestedPropertiesValue = PropertyRecipient[PropertyName];
		EndIf;
	Else
		If NOT PropertyRecipient.Property(PropertyName, NestedPropertiesValue) Then
			PropertyRecipient.Insert(PropertyName);
		EndIf;
	EndIf;
	If NestedPropertiesValue = Undefined Then
		NestedPropertiesValue = New Structure;
	EndIf;
	NestedPropertiesStucture = NestedPropertiesValue;
	MaxLevel = NestedProperties.Count() - 1;
	For Level = 1 To MaxLevel Do
		NestedPropertyName = NestedProperties[Level];
		If Level = MaxLevel Then
			NestedPropertiesStucture.Insert(NestedPropertyName, PropertyValue);
			Break;
		EndIf;
		NestedPropertyRecipient = Undefined;
		NestedPropertiesStucture.Property(NestedPropertyName, NestedPropertyRecipient);
		If NestedPropertyRecipient = Undefined Then
			NestedPropertyRecipient = New Structure;
		EndIf;
		NestedPropertyRecipient.Insert(NestedPropertyName, New Structure);
		NestedPropertiesStucture = NestedPropertyRecipient;
	EndDo;
	PropertyRecipient[PropertyName] = NestedPropertiesValue;
EndProcedure

Function CreateDestinationTSByPCR(PCRForTS)
	
	NewDestinationTS = New ValueTable;
	For Each PCR In PCRForTS Do
		ColumnName = TrimAll(PCR.FormatProperty);
		// Perhaps this is the PCR for nested properties.
		If StrFind(ColumnName, ".") > 0 Then
			NestedProperties = StrSplit(ColumnName,".",False);
			MaxIndex = NestedProperties.Count() - 1;
			For Index = 0 To MaxIndex Do
				NestedPropertyName = NestedProperties[Index];
				If NewDestinationTS.Columns.Find(NestedPropertyName) = Undefined Then
					NewDestinationTS.Columns.Add(NestedPropertyName);
				EndIf;
			EndDo;
		Else
			NewDestinationTS.Columns.Add(ColumnName);
		EndIf;
	EndDo;
	
	Return NewDestinationTS;
	
EndFunction

Procedure ExportSupportedFormatObjects(Header, SupportedObjects, CorrespondentNode)
	
	AllVersionsTable = New ValueTable;
	AllVersionsTable.Columns.Add("Version", New TypeDescription("String"));
	
	For Each AvailableVersion In Header.AvailableVersion Do
		AllVersionsTableRow = AllVersionsTable.Add();
		AllVersionsTableRow.Version = AvailableVersion;
	EndDo;
	
	AllVersionsTable.Sort("Version");
	
	AllVersionsString = StrConcat(AllVersionsTable.UnloadColumn("Version"), ",");
	
	SupportedObjectsTable = SupportedObjects.Copy();
	
	SupportedObjectsTable.Sort("Object, Version");
	
	AvailableObjectTypes = XDTOFactory.Create(XDTOFactory.Type(XMLBaseSchema(), "AvailableObjectTypes"));
	
	CurrentObject = Undefined;
	For Each SupportedObjectsString In SupportedObjectsTable Do
		If CurrentObject = Undefined Then
			CreateNewObject = True;
		ElsIf CurrentObject.Name <> SupportedObjectsString.Object Then
			
			If CurrentObject.Sending = AllVersionsString Then
				CurrentObject.Sending = "*";
			EndIf;
			
			If CurrentObject.Receiving = AllVersionsString Then
				CurrentObject.Receiving = "*";
			EndIf;
			
			AvailableObjectTypes.ObjectType.Add(CurrentObject);
			CreateNewObject = True;
		Else
			CreateNewObject = False;
		EndIf;
		
		If CreateNewObject Then
			CurrentObject = XDTOFactory.Create(XDTOFactory.Type(XMLBaseSchema(), "ObjectType"));
			CurrentObject.Name = SupportedObjectsString.Object;
			
			CurrentObject.Sending   = "";
			CurrentObject.Receiving = "";
		EndIf;
		
		If SupportedObjectsString.Send Then
			If IsBlankString(CurrentObject.Sending) Then
				CurrentObject.Sending = SupportedObjectsString.Version;
			Else
				CurrentObject.Sending = CurrentObject.Sending + "," + SupportedObjectsString.Version;
			EndIf;
		EndIf;
		
		If SupportedObjectsString.Get Then
			If IsBlankString(CurrentObject.Receiving) Then
				CurrentObject.Receiving = SupportedObjectsString.Version;
			Else
				CurrentObject.Receiving = CurrentObject.Receiving + "," + SupportedObjectsString.Version;
			EndIf;
		EndIf;
	EndDo;
	
	If CurrentObject <> Undefined Then
		If CurrentObject.Sending = AllVersionsString Then
			CurrentObject.Sending = "*";
		EndIf;
		
		If CurrentObject.Receiving = AllVersionsString Then
			CurrentObject.Receiving = "*";
		EndIf;
		
		AvailableObjectTypes.ObjectType.Add(CurrentObject);
	EndIf;
	
	If AvailableObjectTypes.ObjectType.Count() > 0 Then
		Header.AvailableObjectTypes = AvailableObjectTypes;
	Else
		Header.AvailableObjectTypes = Undefined;
	EndIf;
	
	InformationRegisters.XDTODataExchangeSettings.UpdateSettings(
		CorrespondentNode, "SupportedObjects", SupportedObjectsTable);
	
EndProcedure

Function ExchangeMessageHeaderParameters() Export
	
	HeaderParameters = New Structure;
	HeaderParameters.Insert("ExchangeFormat",            "");
	HeaderParameters.Insert("IsExchangeViaExchangePlan", False);
	HeaderParameters.Insert("DataExchangeWithExternalSystem", False);
	HeaderParameters.Insert("ExchangeFormatVersion",     "");
	
	HeaderParameters.Insert("ExchangePlanName",                 "");
	HeaderParameters.Insert("PredefinedNodeAlias", "");
	
	HeaderParameters.Insert("RecipientID", "");
	HeaderParameters.Insert("SenderID", "");
	
	HeaderParameters.Insert("MessageNo", 0);
	HeaderParameters.Insert("ReceivedNo", 0);
	
	HeaderParameters.Insert("SupportedVersions",  New Array);
	HeaderParameters.Insert("SupportedObjects", New ValueTable);
	
	HeaderParameters.Insert("Prefix", "");
	
	HeaderParameters.Insert("CorrespondentNode", Undefined);
	
	Return HeaderParameters;
	
EndFunction

Procedure WriteExchangeMessageHeader(ExchangeFile, HeaderParameters) Export
	
	// Writing item <Message> 
	ExchangeFile.WriteStartElement("Message");
	ExchangeFile.WriteNamespaceMapping("msg", "http://www.1c.ru/SSL/Exchange/Message");
	ExchangeFile.WriteNamespaceMapping("xs",  "http://www.w3.org/2001/XMLSchema");
	ExchangeFile.WriteNamespaceMapping("xsi", "http://www.w3.org/2001/XMLSchema-instance");
	
	// Item <Header>
	Header = XDTOFactory.Create(XDTOFactory.Type(XMLBaseSchema(), "Header"));
	
	Header.Format       = HeaderParameters.ExchangeFormat;
	Header.CreationDate = CurrentUniversalDate();
	
	If HeaderParameters.IsExchangeViaExchangePlan Then
		
		Confirmation = XDTOFactory.Create(XDTOFactory.Type(XMLBaseSchema(), "Confirmation"));
		
		If HeaderParameters.DataExchangeWithExternalSystem Then
			Confirmation.From = HeaderParameters.SenderID;
		
			Confirmation.MessageNo  = HeaderParameters.MessageNo;
			Confirmation.ReceivedNo = HeaderParameters.ReceivedNo;
			
			Header.Confirmation = Confirmation;
			
			For Each FormatVersion In HeaderParameters.SupportedVersions Do
				Header.AvailableVersion.Add(FormatVersion);
			EndDo;
			
			ExportSupportedFormatObjects(Header,
				HeaderParameters.SupportedObjects, HeaderParameters.CorrespondentNode);
		Else
			Confirmation.ExchangePlan = HeaderParameters.ExchangePlanName;
			Confirmation.To           = HeaderParameters.RecipientID;
			
			If ValueIsFilled(HeaderParameters.PredefinedNodeAlias) Then
				// A sender node code correction is required.
				Confirmation.From = HeaderParameters.PredefinedNodeAlias;
			Else
				Confirmation.From = HeaderParameters.SenderID;
			EndIf;
		
			Confirmation.MessageNo  = HeaderParameters.MessageNo;
			Confirmation.ReceivedNo = HeaderParameters.ReceivedNo;
			
			Header.Confirmation = Confirmation;
			
			For Each FormatVersion In HeaderParameters.SupportedVersions Do
				Header.AvailableVersion.Add(FormatVersion);
			EndDo;
			
			If ValueIsFilled(HeaderParameters.PredefinedNodeAlias) Then
				// The Header type is Ordered, that is why the order of property values assignment is important.
				// Otherwise, validation by the schema can fail.
				Header.NewFrom = HeaderParameters.SenderID;
			EndIf;
			
			ExportSupportedFormatObjects(Header,
				HeaderParameters.SupportedObjects, HeaderParameters.CorrespondentNode);
			
		    Header.Prefix = HeaderParameters.Prefix;
		EndIf;
		
	Else
		Header.AvailableVersion.Add(HeaderParameters.ExchangeFormatVersion);
	EndIf;
	
	XDTOFactory.WriteXML(ExchangeFile, Header);
	
EndProcedure

Procedure CheckXDTOObjectBySchema(XDTODataObject, XDTOType, Context, Cancel, ErrorDescription)
	
	DetailedPresentation        = "";
	UserPresentation = "";
	
	Try
		XDTODataObject.Validate();
	Except
		Cancel = True;
		DetailedPresentation = DetailErrorDescription(ErrorInfo());
	EndTry;
	
	If Cancel Then
		ErrorsStack = New Array;
		FillXDTODataObjectCheckErrors(XDTODataObject, XDTOType, ErrorsStack);
		
		If ErrorsStack.Count() > 0 Then
			UserPresentation = XDTOType.Name;
			For Each CurrentError In ErrorsStack Do
				UserPresentation = UserPresentation + Chars.LF + CurrentError;
			EndDo;
		EndIf;
	EndIf;
	
	ErrorDescription = New Structure("BriefPresentation, DetailedPresentation");
	
	UserErrorMessageTemplate =
	NStr("ru = 'Не удалось выполнить конвертацию в объект формата ""%1"": 
	|%2
	|
	|Дополнительная информация:
	|Направление: %3.
	|ПОД: %4.
	|ПКО: %5.
	|Объект: %6.
	|
	|Подробнее см. в журнале регистрации.'; 
	|en = 'Cannot convert to an object of ""%1"" format:
	|%2
	|
	|Details:
	|Direction: %3.
	|DER: %4.
	|OCR: %5.
	|Object: %6.
	|
	|For more information, see the event log.'; 
	|pl = 'Nie udało się wykonać przewalutowanie na obiekt formatu ""%1"": 
	|%2
	|
	|Dodatkowe informacje:
	|Kierunek: %3.
	|POG: %4.
	|PKO: %5.
	|Obiekt: %6.
	|
	|Szczegółowe informacje można znaleźć w dzienniku rejestracji.';
	|de = 'Konnte nicht in ein Objekt des Formats ""%1"" konvertiert werden: 
	|%2
	|
	|Zusätzliche Informationen:
	|Richtung: %3.
	|POD: %4.
	|PKO: %5.
	|Objekt: %6.
	|
	|Weitere Informationen finden Sie im Ereignisprotokoll. ';
	|ro = 'Eșec la conversie în obiectul de formatul ""%1"": 
	|%2
	|
	|Informații suplimentare:
	|Direcția: %3.
	|RSD: %4.
	|RCO: %5.
	|Obiectul: %6.
	|
	|Detalii vezi în registrul logare.';
	|tr = '""%1"" biçim nesnesine dönüştürülemedi: 
	|%2
	|
	|Ek bilgi: 
	| Yön: %3. 
	| POD: %4.
	| PKO: %5. 
	| Nesne: %6. 
	|
	| Daha fazla bilgi için bkz. kayıt günlüğü.'; 
	|es_ES = 'No se ha podido realizar la conversión al objeto del formato ""%1"": 
	|%2
	|
	| Información adicional:
	|Dirección:%3.
	|ПОД: %4.
	|ПКО: %5.
	| Objeto: %6.
	|
	|Véase más en el registro de eventos.'");
	
	EventLogErrorMessageTemplate = 
	NStr("ru = 'Направление: %1.
	|ПОД: %2.
	|ПКО: %3.
	|Объект: %4.
	|
	|%5'; 
	|en = 'Direction: %1.
	|DER: %2.
	|OCR: %3.
	|Object: %4.
	|
	|%5'; 
	|pl = 'Kierunek: %1.
	|POD: %2.
	|POG: %3.
	|Obiekt: %4.
	|
	|%5';
	|de = 'Richtung: %1.
	|POD: %2.
	|PKO: %3.
	|Objekt: %4.
	|
	|%5';
	|ro = 'Direcția: %1.
	|RSD: %2.
	|RCO: %3.
	|Obiectul: %4.
	|
	|%5';
	|tr = 'Yön: %1.
	|POD: %2.
	|PKО: %3.
	|Nesne: %4.
	|
	|%5'; 
	|es_ES = 'Dirección: %1.
	|ПОД: %2.
	|ПКО: %3.
	|Objeto: %4.
	|
	|%5'");
	
	ErrorDescription.BriefPresentation = StringFunctionsClientServer.SubstituteParametersToString(
		UserErrorMessageTemplate,
		XDTOType.Name,
		UserPresentation,
		Context.ExchangeDirection,
		Context.DPRName,
		Context.OCRName,
		Context.ObjectPresentation);
	ErrorDescription.DetailedPresentation = StringFunctionsClientServer.SubstituteParametersToString(
		EventLogErrorMessageTemplate,
		Context.ExchangeDirection,
		Context.DPRName,
		Context.OCRName,
		Context.ObjectPresentation,
		DetailedPresentation);
	
EndProcedure

Procedure FillXDTODataObjectCheckErrors(XDTODataObject, XDTODataObjectType, ErrorsStack, Val Level = 1)
	
	OutputError = (Level = 1);
	
	For Each Property In XDTODataObjectType.Properties Do
		If Not XDTODataObject.IsSet(Property) Then
			If Property.LowerBound = 1
				AND Not Property.Nillable Then
				ErrorMessage = StringFunctionsClientServer.GenerateCharacterString("  ", Level);
				ErrorMessage = ErrorMessage + "->" + Property.Name + " - " + NStr("ru = 'не заполнено обязательное поле.'; en = 'the required field is blank.'; pl = 'wymagane pole nie zostało wypełnione.';de = 'das Pflichtfeld ist nicht ausgefüllt.';ro = 'nu este completat câmpul obligatoriu.';tr = 'zorunlu alan doldurulmadı.'; es_ES = 'no se ha rellenado un campo obligatorio.'");
				ErrorsStack.Add(ErrorMessage);
			EndIf;
			Continue;
		Else
			XDTOPropertyValue = Undefined;
			IsXDTOList = False;
			If Property.UpperBound = 1 Then
				XDTOPropertyValue = XDTODataObject.GetXDTO(Property);
			Else
				XDTOPropertyValue = XDTODataObject.GetList(Property);
				IsXDTOList = True;
			EndIf;
			
			If XDTOPropertyValue = Undefined Then
				Continue;
			EndIf;
			
			If TypeOf(XDTOPropertyValue) = Type("XDTODataValue") Then
				Try
					Property.Type.Validate(XDTOPropertyValue.LexicalValue);
				Except
					ErrorMessage = StringFunctionsClientServer.GenerateCharacterString("  ", Level);
					ErrorMessage = ErrorMessage + "->" + Property.Name + " - " + NStr("ru = 'значение поля не соответствует заданным ограничениям.'; en = 'the field value does not match the specified restrictions.'; pl = 'wartość pola nie spełnia określonych ograniczeń.';de = 'der Wert des Feldes nicht den angegebenen Grenzen entspricht.';ro = 'valoarea câmpului nu corespunde cu restricțiile specificate.';tr = 'alan değeri belirlenen kısıtlamalara uygun değil.'; es_ES = 'el valor del campo no corresponde a las restricciones establecidas.'");
					ErrorsStack.Add(ErrorMessage);
				EndTry;
			ElsIf IsXDTOList Then
				Cnt = 0;
				For Each XDTOListItem In XDTOPropertyValue Do
					Cnt = Cnt + 1;
					NewErrorsStack = New Array;
					FillXDTODataObjectCheckErrors(XDTOListItem, Property.Type, NewErrorsStack, Level + 1);
					
					If NewErrorsStack.Count() > 0 Then
						ErrorMessage = StringFunctionsClientServer.GenerateCharacterString("  ", Level);
						ErrorMessage = ErrorMessage + "->" + Property.Name + "[" + XMLString(Cnt) + "]";
						ErrorsStack.Add(ErrorMessage);
						For Each NewError In NewErrorsStack Do
							ErrorsStack.Add(NewError);
						EndDo;
					EndIf;
				EndDo;
			Else
				NewErrorsStack = New Array;
				FillXDTODataObjectCheckErrors(XDTOPropertyValue, Property.Type, NewErrorsStack, Level + 1);
				
				If NewErrorsStack.Count() > 0 Then
					ErrorMessage = StringFunctionsClientServer.GenerateCharacterString("  ", Level);
					ErrorMessage = ErrorMessage + "->" + Property.Name;
					ErrorsStack.Add(ErrorMessage);
					For Each NewError In NewErrorsStack Do
						ErrorsStack.Add(NewError);
					EndDo;
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region GetData

#Region ObjectsConversion

#Region XDTOToStructureConversion

Procedure ConvertXDTOPropertyToStructureItem(Source, Property, Destination, NameForCompositeTypeProperty = "")
	
	If Not Source.IsSet(Property) Then
		Return;
	EndIf;
	
	PropertyName = ?(NameForCompositeTypeProperty = "", Property.Name, NameForCompositeTypeProperty);
	
	XDTOValue = Source.GetXDTO(Property);
	
	Try
		
		If TypeOf(XDTOValue) = Type("XDTODataValue") Then
			
			Value = ReadXDTOValue(XDTOValue);
			
			If TypeOf(Destination) = Type("Structure") Then
				Destination.Insert(PropertyName, Value);
			Else
				
				If TypeOf(Destination) = Type("ValueTableRow")
					AND Destination.Owner().Columns.Find(PropertyName) = Undefined Then
					Return;
				EndIf;
				
				Destination[PropertyName] = Value;
			EndIf;
			
		ElsIf TypeOf(XDTOValue) = Type("XDTODataObject") Then
			
			// The property can contain:
			// - additional information
			// - tabular section
			// - a set of key properties
			// - a set of common properties
			// - a property of composite type.
			
			If PropertyName = "AdditionalInfo" Then // Additional information
				
				Value = XDTOSerializer.ReadXDTO(XDTOValue);
				Destination.Insert(PropertyName, Value);
				
			ElsIf IsObjectTable(Property) Then
				
				// Initializing a value table displaying a tabular section of the object.
				Value = ObjectTableByType(Property.Type.Properties[0].Type);
				
				XDTOTabularSection = Source[PropertyName].Row;
				
				For Index = 0 To XDTOTabularSection.Count() - 1 Do
					
					TSRow = Value.Add();
					XDTORow = XDTOTabularSection.GetXDTO(Index);
					For Each TSRowProperty In XDTORow.Properties() Do
						
						ConvertXDTOPropertyToStructureItem(XDTORow, TSRowProperty, TSRow);
						
					EndDo;
					
				EndDo;
				
				Destination.Insert(PropertyName, Value);
				
			ElsIf StrFind(XDTOValue.Type().Name, "KeyProperties") > 0 Then
				
				Value = New Structure("IsKeyPropertiesSet");
				Value.Insert("ValueType", StrReplace(XDTOValue.Type().Name, "KeyProperties", ""));
				For Each KeyProperty In XDTOValue.Properties() Do
					ConvertXDTOPropertyToStructureItem(XDTOValue, KeyProperty, Value);
				EndDo;
				
				
				If TypeOf(Destination) = Type("Structure") Then
					Destination.Insert(PropertyName, Value);
				Else
					Destination[PropertyName] = Value;
				EndIf;
				
			ElsIf StrFind(XDTOValue.Type().Name, "CommonProperties") > 0 Then
				If TypeOf(Destination) = Type("Structure") Then 
					PropertiesGroupDestination = New Structure;
					For Each SubProperty In XDTOValue.Properties() Do
						
						ConvertXDTOPropertyToStructureItem(XDTOValue, SubProperty, PropertiesGroupDestination);
						
					EndDo;
					Destination.Insert(PropertyName, PropertiesGroupDestination);
					// If possible, duplicate properties from the property group in destination
					// for compatibility with existing rules and algorithms.
					HasKeyProperties = Destination.Property("KeyProperties");
					For Each GroupProperty In PropertiesGroupDestination Do
						SubpropertyName = GroupProperty.Key;
						If NOT Destination.Property(SubpropertyName)
							AND NOT (HasKeyProperties AND Destination.KeyProperties.Property(SubpropertyName)) Then
							Destination.Insert(SubpropertyName, GroupProperty.Value);
						EndIf;
					EndDo;
				Else
					
					For Each SubProperty In XDTOValue.Properties() Do
						
						ConvertXDTOPropertyToStructureItem(XDTOValue, SubProperty, Destination);
						
					EndDo;
					
				EndIf;
				
			Else
				
				// A property of composite type.
				Value = Undefined;
				For Each SubProperty In XDTOValue.Properties() Do
					
					If NOT XDTOValue.IsSet(SubProperty) Then
						Continue;
					EndIf;
					
					ConvertXDTOPropertyToStructureItem(XDTOValue, SubProperty, Destination, PropertyName);
					Break;
					
				EndDo;
				
			EndIf;
			
		EndIf;
	Except
		ErrorPresentation = DetailErrorDescription(ErrorInfo());
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Ошибка чтения объекта XDTO, имя свойства: <%1>.'; en = 'XDTO object reading error. Property name: %1.'; pl = 'Błąd odczytu obiektu XDTO, nazwa właściwości: <%1>.';de = 'XDTO-Objekt Lesefehler, Eigenschaftsname: <%1>.';ro = 'Eroare de citire a obiectului XDTO, numele proprietății: <%1>.';tr = 'XDTO nesnesini okuma hatası, özelliğin adı: <%1>.'; es_ES = 'Error de leer el objeto XDTO, nombre de propiedad: <%1>.'"), PropertyName)
			+ Chars.LF + Chars.LF + ErrorPresentation;
		Raise ErrorText;
	EndTry;
	
EndProcedure

Function ReadXDTOValue(XDTOValue)
	
	If XDTOValue = Undefined Then
		Return Undefined;
	EndIf;
	
	If IsXDTORef(XDTOValue.Type()) Then // Reference conversion
		Value = ReadComplexTypeXDTOValue(XDTOValue, "Ref");
	ElsIf XDTOValue.Type().Facets <> Undefined
		AND XDTOValue.Type().Facets.Enumerations <> Undefined
		AND XDTOValue.Type().Facets.Enumerations.Count() > 0 Then // Enumeration conversion
		
		Value = ReadComplexTypeXDTOValue(XDTOValue, "Enum");
	Else // Common value conversion.
		
		Value = XDTOValue.Value;
		
	EndIf;
	
	Return Value;
	
EndFunction

Function ReadComplexTypeXDTOValue(XDTOValue, ComplexType)
	
	XDTOStructure = New Structure;
	XDTOStructure.Insert("IsReference", ComplexType = "Ref");
	XDTOStructure.Insert("IsEnum", ComplexType = "Enum");
	XDTOStructure.Insert("XDTOValueType", XDTOValue.Type());
	XDTOStructure.Insert("Value", XDTOValue.Value);

	Return XDTOStructure;
	
EndFunction

Function ObjectTableByType(Val Type)
	
	Result = New ValueTable;
	
	For Each Column In Type.Properties Do
		
		If StrFind(Column.Type.Name, "CommonProperties") > 0 Then
			
			For Each SubColumn In Column.Type.Properties Do
				
				Result.Columns.Add(SubColumn.Name);
				
			EndDo;
			
		Else
			Result.Columns.Add(Column.Name);
		EndIf;
		
	EndDo;
	
	Return Result;
EndFunction

#EndRegion

#Region StructureConversionToIBData

Procedure ConversionOfXDTODataObjectStructureProperties(
		ExchangeComponents,
		XDTOData,
		ReceivedData,
		ConversionRule,
		StageNumber = 1,
		PropertiesContent = "All")
	
	Try
		For Each PCR In ConversionRule.Properties Do
			
			If PropertiesContent = "SearchProperties"
				AND Not PCR.SearchPropertyHandler Then
				Continue;
			EndIf;
			
			ConversionOfXDTODataObjectStructureProperty(
				ExchangeComponents,
				XDTOData,
				ReceivedData.AdditionalProperties,
				ReceivedData,
				PCR,
				StageNumber);
			
		EndDo;
			
		If PropertiesContent = "SearchProperties" Then
			Return;
		EndIf;
		
		// Conversion of tabular sections.
		For Each TS In ConversionRule.TabularSectionsProperties Do
			
			If StageNumber = 1 AND ValueIsFilled(TS.ConfigurationTabularSection) AND ValueIsFilled(TS.FormatTS) Then
				
				// Direct conversion of tabular sections.
				FormatTS = Undefined;
				If NOT XDTOData.Property(TS.FormatTS, FormatTS) Then
					Continue;
				ElsIf FormatTS.Count() = 0 Then
					Continue;
				EndIf;
				
				TSColumnsArray = New Array;
				For Each TSColumn In FormatTS.Columns Do
					TSColumnsArray.Add(TSColumn.Name);
				EndDo;
				
				ColumnsNamesAsString = StrConcat(TSColumnsArray, ",");
				For RowNumber = 1 To FormatTS.Count() Do
					
					XDTOStringData = FormatTS[RowNumber - 1];
					TSRow = ReceivedData[TS.ConfigurationTabularSection].Add();
					XDTOStringDataStructure = New Structure(ColumnsNamesAsString);
					FillPropertyValues(XDTOStringDataStructure, XDTOStringData);
					
					For Each PCR In TS.Properties Do
						If PCR.UsesConversionAlgorithm Then
							Continue;
						EndIf;
						ConversionOfXDTODataObjectStructureProperty(
							ExchangeComponents,
							XDTOStringDataStructure,
							ReceivedData.AdditionalProperties,
							TSRow,
							PCR,
							StageNumber);
					EndDo;
					
				EndDo;
				
			EndIf;
			
			If StageNumber = 2 AND TS.UsesConversionAlgorithm
				AND ValueIsFilled(TS.ConfigurationTabularSection)
				AND ReceivedData.AdditionalProperties.Property(TS.ConfigurationTabularSection) Then
 				ArrayOfStructuresWithStringsData = ReceivedData.AdditionalProperties[TS.ConfigurationTabularSection];
				ConfigurationTSRowsCount = ReceivedData[TS.ConfigurationTabularSection].Count();
				
				For RowNumber = 1 To ArrayOfStructuresWithStringsData.Count() Do
					
					// Maybe, the string was added on direct conversion.
					If RowNumber <= ConfigurationTSRowsCount Then
						TSRow = ReceivedData[TS.ConfigurationTabularSection][RowNumber - 1];
					Else
						TSRow = ReceivedData[TS.ConfigurationTabularSection].Add();
					EndIf;
					
					For Each PCR In TS.Properties Do
						
						If NOT PCR.UsesConversionAlgorithm Then
							Continue;
						EndIf;
						
						ConversionOfXDTODataObjectStructureProperty(
							ExchangeComponents,
							XDTOData,
							ReceivedData.AdditionalProperties,
							TSRow,
							PCR,
							StageNumber, 
							TS.ConfigurationTabularSection);
						
					EndDo;
					
				EndDo;
			EndIf;
			
		EndDo;
	Except
		ErrorText = Chars.LF + StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Событие: %1.
				|Объект: %2.
				|
				|Ошибка конвертации свойств.
				|%3.'; 
				|en = 'Event: %1.
				|Object: %2.
				|
				|Property conversion error.
				|%3.'; 
				|pl = 'Zdarzenie: %1.
				|Obiekt: %2.
				|
				|Błąd konwersji właściwości.
				|%3.';
				|de = 'Ereignis: %1.
				|Objekt: %2.
				|
				|Fehler bei der Konvertierung von Eigenschaften.
				|%3.';
				|ro = 'Evenimentul: %1.
				|Obiectul: %2.
				|
				|Eroare de conversie a proprietăților.
				|%3.';
				|tr = 'Olay: %1. 
				|Nesne: %2. 
				|
				|Özelliği dönüştürme hatası. 
				|%3.'; 
				|es_ES = 'Evento: %1.
				|Objeto: %2.
				|
				|Error de conversión de propiedades.
				|%3.'"),
			ExchangeComponents.ExchangeDirection,
			ObjectPresentationForProtocol(ReceivedData),
			DetailErrorDescription(ErrorInfo()));
		Raise ErrorText;
	EndTry;
	
EndProcedure

Procedure ConversionOfXDTODataObjectStructureProperty(
		ExchangeComponents,
		XDTOData,
		AdditionalProperties,
		DataDestination,
		PCR,
		StageNumber = 1,
		TSName = "")
	// PCR with only format property specified is being processed. It is used only on export.
	If TrimAll(PCR.ConfigurationProperty) = "" Then
		Return;
	EndIf;
	
	PropertyConversionRule = PCR.PropertyConversionRule;
	
	PropertyValue = "";
	Try
		If StageNumber = 1 Then
			
			If Not ValueIsFilled(PCR.FormatProperty) Then
				Return;
			EndIf;
			
			If PCR.KeyPropertyProcessing
				AND Not XDTOData.Property("IsKeyPropertiesSet") Then
				DataSource = XDTOData.KeyProperties;
			Else
				DataSource = XDTOData;
			EndIf;
			
			FormatProperty_Name = TrimAll(PCR.FormatProperty);
			PointPosition = StrFind(FormatProperty_Name, ".");
			// A full property name is specified. The property is included in the common properties group.
			If PointPosition > 0 Then
				NestedProperties = StrSplit(FormatProperty_Name,".",False);
				GetNestedPropertiesValue(DataSource, NestedProperties, PropertyValue);
			Else
				DataSource.Property(FormatProperty_Name, PropertyValue);
			EndIf;
			
		ElsIf StageNumber = 2 Then
			
			If StageNumber = 2 AND Not PCR.UsesConversionAlgorithm Then
				Return;
			EndIf;
			
			// At the second stage, property values are obtained from the additional properties of the received 
			// data object. They represent a structure containing conversion instruction or the XDTO value.
			// If a value destination is a tabular section row, the property value is located in 
			// AdditionalProperties[TabularSectionName][RowIndex].
			If ValueIsFilled(TSName) Then
				DataSource = AdditionalProperties[TSName][DataDestination.LineNumber - 1];
			Else
				DataSource = AdditionalProperties;
			EndIf;
			
			If DataSource.Property(PCR.ConfigurationProperty) Then
				PropertyValue = DataSource[PCR.ConfigurationProperty];
			EndIf;
			
		EndIf;
		
		If Not ValueIsFilled(PropertyValue) Then
			Return;
		EndIf;
		
		DeleteObjectsCreatedByKeyProperties = ExchangeComponents.DeleteObjectsCreatedByKeyProperties;
		If TypeOf(PropertyValue) = Type("Structure")
			AND PropertyValue.Property("OCRName")
			AND PropertyValue.Property("Value") Then
			
			// Instruction is the value.
			If PropertyValue.Property("DeleteObjectsCreatedByKeyProperties") Then
				DeleteObjectsCreatedByKeyProperties = PropertyValue.DeleteObjectsCreatedByKeyProperties;
			EndIf;
			
			PropertyConversionRule = PropertyValue.OCRName;
			PropertyValue           = PropertyValue.Value;
			
		EndIf;
		
		If TypeOf(PropertyValue) = Type("Structure") Then
			PDCR = ExchangeComponents.PredefinedDataConversionRules.Find(PropertyConversionRule, "PDCRName");
			If PDCR <> Undefined Then
				
				Value = PDCR.ConvertValuesOnReceipt.Get(PropertyValue.Value);
				DataDestination[PCR.ConfigurationProperty] = Value;
				Return;
				
			Else
				PropertyConversionRule = OCRByName(ExchangeComponents, PropertyConversionRule);
			EndIf;
		Else
			// Simple values are converted only at the first stage.
			DataDestination[PCR.ConfigurationProperty] = PropertyValue;
			Return;
		EndIf;
		
		ConversionRule = New Structure("ConversionRule, DeleteObjectsCreatedByKeyProperties",
			PropertyConversionRule, DeleteObjectsCreatedByKeyProperties);
		DataToWriteToIB = XDTOObjectStructureToIBData(ExchangeComponents, PropertyValue, ConversionRule, "GetRef");
		
		If DataToWriteToIB <> Undefined Then
			DataDestination[PCR.ConfigurationProperty] = DataToWriteToIB.Ref;
		EndIf;
		
	Except
		ErrorPresentation = DetailErrorDescription(ErrorInfo());
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Ошибка конвертации свойства объекта XDTO, имя свойства: <%1>.'; en = 'XDTO object property conversion error. Property name: %1.'; pl = 'Błąd podczas konwersji właściwości obiektu XDTO, nazwa właściwości: <%1>.';de = 'Fehler bei der Konvertierung von XDTO-Objekteigenschaften, Eigenschaftsname: <%1>.';ro = 'Eroare de conversie a proprietății obiectului XDTO, numele proprietății: <%1>.';tr = 'XDTO nesnesi özelliğinin dönüştürme hatası, özellik adı: <%1>.'; es_ES = 'Error de conversión de la propiedad del objeto XDTO, nombre de propiedad: <%1>.'"), PCR.ConfigurationProperty)
			+ Chars.LF + Chars.LF + ErrorPresentation;
		Raise ErrorText;
	EndTry;
	
EndProcedure

Function ObjectRefByXDTODataObjectProperties(ConversionRule, ReceivedData, XDTODataContainRef, ExchangeNode)
	
	Result = Undefined;
	// ConversionRule.ObjectSearchFields - an array, contains search options. Array items - a value 
	//	table with search fields.
	If ConversionRule.SearchFields = Undefined
		OR TypeOf(ConversionRule.SearchFields) <> Type("Array") Then
		Return Result;
	EndIf;
	
	For Each SearchAttempt In ConversionRule.SearchFields Do
		SearchFields = New Structure(SearchAttempt);
		FillPropertyValues(SearchFields, ReceivedData);
		
		// If at least one search field is not filled in, the search option is skipped.
		// (Except for catalogs and charts of characteristic types. For them, blank Parent search field is 
		// allowed.)
		// The search option is full if all the fields are filled.
		// Otherwise, another search option must work.
		HasBlankFields = False;
		For Each SearchField In SearchFields Do
			If Not ValueIsFilled(SearchField.Value) Then
				If (ConversionRule.IsCatalog Or ConversionRule.IsChartOfCharacteristicTypes)
					AND SearchField.Key = "Parent" Then
					Continue;
				EndIf;
				
				HasBlankFields = True;
				Break;
			EndIf;
		EndDo;
		If HasBlankFields Then
			// Go to the next search option.
			Continue;
		EndIf;
		
		IdentificationOption = TrimAll(ConversionRule.IdentificationOption);
		AnalyzePublicIDs = IdentificationOption = "FirstByUUIDThenBySearchFields"
			AND XDTODataContainRef
			AND ValueIsFilled(ExchangeNode);
			
		SearchByQuery = False;
		If AnalyzePublicIDs Then
			SearchByQuery = True;
		Else
			// Perhaps, the search can be executed by platform methods.
			If ConversionRule.IsDocument
				AND SearchFields.Count() = 2
				AND SearchFields.Property("Date")
				AND SearchFields.Property("Number") Then
				Result = ConversionRule.ObjectManager.FindByNumber(SearchFields.Number, SearchFields.Date);
				Result = ?(Result.IsEmpty(), Undefined, Result);
			ElsIf ConversionRule.IsCatalog
				AND SearchFields.Count() = 1
				AND SearchFields.Property("Description") Then
				Result = ConversionRule.ObjectManager.FindByDescription(SearchFields.Description, True);
			ElsIf ConversionRule.IsCatalog
				AND SearchFields.Count() = 1
				AND SearchFields.Property("Code") Then
				Result = ConversionRule.ObjectManager.FindByCode(SearchFields.Code);
			Else
				SearchByQuery = True;
			EndIf;
		EndIf;
		
		If SearchByQuery Then
			Query = New Query;
			
			QueryText =
			"SELECT
			|	Table.Ref AS Ref
			|FROM
			|	[FullName] AS Table
			|WHERE
			|	[FilterCriterion]";
			
			Filter = New Array;
			
			For Each SearchField In SearchFields Do
				
				If DataExchangeCached.IsStringAttributeOfUnlimitedLength(ConversionRule.FullName, SearchField.Key) Then
					
					FilterString = "CAST(Table.[Key] AS STRING([StringLength])) = &[Key]";
					FilterString = StrReplace(FilterString, "[Key]", SearchField.Key);
					FilterString = StrReplace(FilterString, "[StringLength]", Format(StrLen(SearchField.Value), "NG=0"));
					Filter.Add(FilterString);
					
				Else
					
					Filter.Add(StrReplace("Table.[Key] = &[Key]", "[Key]", SearchField.Key));
					
				EndIf;
				
				Query.SetParameter(SearchField.Key, SearchField.Value);
				
			EndDo;
			
			FilterCriterion = StrConcat(Filter, " AND ");
			
			If AnalyzePublicIDs Then
				// Excluding the objects mapped earlier from the search.
				JoinText = "	LEFT JOIN InformationRegister.SynchronizedObjectPublicIDs AS PublicIDs
					|	ON PublicIDs.Ref = Table.Ref AND PublicIDs.InfobaseNode = &ExchangeNode";
				FilterCriterion = FilterCriterion + Chars.LF + "	AND PublicIDs.Ref is null";
				QueryText = StrReplace(QueryText,  "WHERE", JoinText + Chars.LF + "	WHERE");
				Query.SetParameter("ExchangeNode", ExchangeNode);
			EndIf;
			
			QueryText = StrReplace(QueryText, "[FilterCriterion]", FilterCriterion);
			QueryText = StrReplace(QueryText, "[FullName]", ConversionRule.FullName);
			Query.Text = QueryText;
			
			QueryResult = Query.Execute();
			
			If Not QueryResult.IsEmpty() Then
				
				Selection = QueryResult.Select();
				Selection.Next();
				
				Result = Selection.Ref;
				
			EndIf;
			
		EndIf;
		If ValueIsFilled(Result) Then
			Break;
		EndIf;
	EndDo;
	Return Result;
EndFunction

Procedure FillIBDataByReceivedData(IBData, ReceivedData, ConversionRule)
	
	DataCopyFields = ConversionRule.Properties.UnloadColumn("ConfigurationProperty");
	If DataCopyFields.Count() > 0 Then
		
		For FieldNumber = 1 To DataCopyFields.Count() Do
			DataCopyFields[FieldNumber - 1] = TrimAll(DataCopyFields[FieldNumber - 1]);
		EndDo;
		
		DataCopyFields = StrConcat(DataCopyFields, ",");
		FillPropertyValues(IBData, ReceivedData, DataCopyFields);
	EndIf;
	
	For Each TSConversions In ConversionRule.TabularSectionsProperties Do
		
		TSName = TSConversions.ConfigurationTabularSection;
		
		If IsBlankString(TSName) Then
			Continue;
		EndIf;
		
		IBData[TSName].Clear();
		IBData[TSName].Load(ReceivedData[TSName].Unload());
		
	EndDo;
	
EndProcedure

Function InitializeReceivedData(ConversionRule)
	
	If ConversionRule.IsDocument Then
		ReceivedData = ConversionRule.ObjectManager.CreateDocument();
	ElsIf ConversionRule.IsCatalog
		Or ConversionRule.IsChartOfCharacteristicTypes Then
		If ConversionRule.RuleForCatalogGroup Then
			ReceivedData = ConversionRule.ObjectManager.CreateFolder();
		Else
			ReceivedData = ConversionRule.ObjectManager.CreateItem();
		EndIf;
	ElsIf ConversionRule.IsRegister Then
		ReceivedData = ConversionRule.ObjectManager.CreateRecordSet();
	EndIf;
	
	Return ReceivedData;
	
EndFunction

#EndRegion

#EndRegion

#Region ServiceProceduresAndFunctions

Procedure ExecuteNumberCodeGenerationIfNecessary(Object)
	
	ObjectTypeName = Common.ObjectKindByType(TypeOf(Object.Ref));
	
	// Using the document type, checking whether a code or a number is filled in.
	If ObjectTypeName = "Document"
		Or ObjectTypeName = "BusinessProcess"
		Or ObjectTypeName = "Task" Then
		
		If Not ValueIsFilled(Object.Number) Then
			
			Object.SetNewNumber();
			
		EndIf;
		
	ElsIf ObjectTypeName = "Catalog"
		Or ObjectTypeName = "ChartOfCharacteristicTypes" Then
		
		If Not ValueIsFilled(Object.Code)
			AND Object.Metadata().Autonumbering Then
			
			Object.SetNewCode();
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure RemoveDeletionMarkFromPredefinedItem(Object, ObjectType, ExchangeComponents)
	
	MarkPredefined = New Structure("DeletionMark, Predefined", False, False);
	FillPropertyValues(MarkPredefined, Object);
	
	If MarkPredefined.DeletionMark
		AND MarkPredefined.Predefined Then
			
		Object.DeletionMark = False;
		
		// Adding the event log entry.
		WP            = ExchangeProtocolRecord(80);
		WP.ObjectType = ObjectType;
		WP.Object     = String(Object);
		
		ExchangeComponents.DataExchangeState.ExchangeExecutionResult =
			Enums.ExchangeExecutionResults.CompletedWithWarnings;
		WriteToExecutionProtocol(ExchangeComponents, 80, WP, False);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region DeferredOperations
Procedure RememberObjectForDeferredFilling(DataToWriteToIB, ConversionRule, ExchangeComponents)
	
	If ConversionRule.HasHandlerAfterImportAllData Then
		
		// Add object data to the deferred processing table.
		NewRow = ExchangeComponents.ImportedObjects.Add();
		NewRow.HandlerName = ConversionRule.AfterImportAllData;
		NewRow.Object         = DataToWriteToIB;
		NewRow.ObjectRef = DataToWriteToIB.Ref;
		
	EndIf;
	
EndProcedure

Procedure DeleteTemporaryObjectsCreatedByRefs(ExchangeComponents) Export
	
	ObjectsCreatedByRefsTable = ExchangeComponents.ObjectsCreatedByRefsTable;
	
	RowsObjectsToDelete = ObjectsCreatedByRefsTable.FindRows(New Structure("DeleteObjectsCreatedByKeyProperties", True));
	
	For Each TableRow In RowsObjectsToDelete Do
		
		ObjectRef = TableRow.ObjectRef;
		
		// Deleting object reference from the deferred object filling table.
		DeferredFillingTableRow = ExchangeComponents.ImportedObjects.Find(ObjectRef, "ObjectRef");
		If DeferredFillingTableRow <> Undefined Then
			ExchangeComponents.ImportedObjects.Delete(DeferredFillingTableRow);
		EndIf;
		
		If ValueIsFilled(ObjectRef) Then
			
			ObjectCreatedByRef = ObjectRef.GetObject();
			DataExchangeServer.SetDataExchangeLoad(ObjectCreatedByRef, True, False, ExchangeComponents.CorrespondentNode);
			DeleteObject(ObjectCreatedByRef, True, ExchangeComponents);
			
		EndIf;
		
	EndDo;
	
	ObjectsCreatedByRefsTable.Clear();
	
EndProcedure

Procedure DeferredObjectsFilling(ExchangeComponents)
	
	ConversionParameters = ExchangeComponents.ConversionParameters;
	ImportedObjects   = ExchangeComponents.ImportedObjects;
	
	Try
		ExchangeComponents.ExchangeManager.BeforeDeferredFilling(ExchangeComponents);
	Except
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Направление: %1.
			|Обработчик: ПередОтложеннымЗаполнением.
			|
			|Ошибка выполнения обработчика.
			|%2.'; 
			|en = 'Direction: %1.
			|Handler: BeforeDeferredFilling.
			|
			|Handler execution error.
			|%2.'; 
			|pl = 'Kierunek: %1.
			|Procedura przetwarzania: ПередОтложеннымЗаполнением.
			|
			|Błąd wykonania programu przetwarzania.
			|%2.';
			|de = 'Ereignis: %1.
			|Handler: VorDerVerzögertenBefüllung.
			|
			|Fehler bei der Ausführung des Handlers.
			|%2';
			|ro = 'Direcția: %1.
			|Handlerul: ПередОтложеннымЗаполнением.
			|
			|Eroare de executare a handlerului.
			|%2.';
			|tr = 'Yön: %1. 
			| İşleyici: ErtelenmişDoldurulmadanÖnce. 
			|
			| İşleyici yürütme hatası. 
			|%2.'; 
			|es_ES = 'Dirección: %1.
			|Procesador: ПередОтложеннымЗаполнением.
			|
			|Error de ejecutar el procesador.
			|%2.'"),
			ExchangeComponents.ExchangeDirection,
			DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	For Each TableRow In ImportedObjects Do
		
		If TableRow.Object.IsNew() Then
			Continue;
		EndIf;
		
		Object = TableRow.Object.Ref.GetObject();
		
		// Transferring additional properties.
		For Each Property In TableRow.Object.AdditionalProperties Do
			Object.AdditionalProperties.Insert(Property.Key, Property.Value);
		EndDo;
		
		HandlerName = TableRow.HandlerName;
		
		ExchangeManager = ExchangeComponents.ExchangeManager;
		
		ParametersStructure = New Structure;
		ParametersStructure.Insert("Object",              Object);
		ParametersStructure.Insert("ExchangeComponents",    ExchangeComponents);
		ParametersStructure.Insert("ObjectIsModified", True);
		
		Try
			ExchangeManager.RunManagerModuleProcedure(HandlerName, ParametersStructure);
		Except
			ErrorText = Chars.LF + StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Событие: %1.
					|Обработчик: ОтложенноеЗаполнениеОбъектов.
					|Объект: %2.
					|
					|Ошибка выполнения обработчика.
					|%3.'; 
					|en = 'Event: %1.
					|Handler: DeferredObjectsFilling.
					|Object: %2.
					|
					|Handler execution error.
					|%3.'; 
					|pl = 'Zdarzenie: %1.
					|Procedura przetwarzania: ОтложенноеЗаполнениеОбъектов.
					|Obiekt: %2.
					|
					|Błąd wykonania programu przetwarzania.
					|%3.';
					|de = 'Ereignis: %1.
					|Handler: VorDerVerzögertenBefüllung.
					|Objekt: %2.
					|
					|Fehler bei der Ausführung des Handlers.
					|%3.';
					|ro = 'Evenimentul: %1.
					|Handlerul: ОтложенноеЗаполнениеОбъектов.
					|Obiectul:%2.
					|
					|Eroare de executare a handlerului.
					|%3.';
					|tr = 'Olay: %1. 
					|İşleyici: ErtelenmişNesneDoldurulması. 
					| Nesne: %2. 
					|
					| İşleyici yürütme hatası. 
					|%3.'; 
					|es_ES = 'Evento: %1.
					|Procesador: FillObjectsDeferred.
					|Objeto: %2.
					|
					|Error de realizar el procesador.
					|%3.'"),
				ExchangeComponents.ExchangeDirection,
				ObjectPresentationForProtocol(Object.Ref),
				DetailErrorDescription(ErrorInfo()));
			WriteToExecutionProtocol(ExchangeComponents, TrimAll(ErrorText),,,,, True);
			Return;
		EndTry;
		
		ObjectIsModified = ParametersStructure.ObjectIsModified;
		
		If ObjectIsModified Then
			DataExchangeServer.SetDataExchangeLoad(Object, True, False, ExchangeComponents.CorrespondentNode);
			Object.AdditionalProperties.Insert("SkipObjectVersionRecord");
			Object.Write();
		EndIf;
		
	EndDo;

EndProcedure

Procedure ExecuteDeferredObjectsWrite(ExchangeComponents)
	
	If ExchangeComponents.ObjectsForDeferredPosting.Count() = 0 Then
		Return // No objects in the queue.
	EndIf;
	
	For Each MapObject In ExchangeComponents.ObjectsForDeferredPosting Do
		
		If MapObject.Key.IsEmpty() Then
			Continue;
		EndIf;
		
		Object = MapObject.Key.GetObject();
		
		If Object = Undefined Then
			Continue;
		EndIf;
		
		// Determining a sender node to prevent object registration on the destination node. Posting is 
		// executed not in import mode.
		DataExchangeServer.SetDataExchangeLoad(Object, False, False, ExchangeComponents.CorrespondentNode);
		
		ErrorDescription = "";
		ObjectWrittenSuccessfully = False;
		
		Try
			
			AdditionalProperties = MapObject.Value;
			
			For Each Property In AdditionalProperties Do
				
				Object.AdditionalProperties.Insert(Property.Key, Property.Value);
				
			EndDo;
			
			Object.AdditionalProperties.Insert("DeferredWriting");
			
			If Object.CheckFilling() Then
				
				// Enabling the object registration rules on document posting as
				//  ORR were ignored during normal document writing in order to optimize data import speed.
				If Object.AdditionalProperties.Property("DisableObjectChangeRecordMechanism") Then
					Object.AdditionalProperties.Delete("DisableObjectChangeRecordMechanism");
				EndIf;
				
				DataExchangeServer.SkipPeriodClosingCheck();
				Object.AdditionalProperties.Insert("SkipPeriodClosingCheck");
				
				// Attempting to write the object.
				ObjectVersionInfo = Undefined;
				If Object.AdditionalProperties.Property("ObjectVersionInfo", ObjectVersionInfo) Then
					DataExchangeEvents.OnCreateObjectVersion(Object, ObjectVersionInfo, True, ExchangeComponents.CorrespondentNode);
				EndIf;
				Object.Write();
				
				ObjectWrittenSuccessfully = True;
				
			Else
				
				ObjectWrittenSuccessfully = False;
				
				ErrorDescription = NStr("ru = 'Ошибка проверки заполнения реквизитов'; en = 'Attribute filling check error.'; pl = 'Wystąpił błąd podczas sprawdzania wypełnienia atrybutów';de = 'Bei der Überprüfung der Attributpopulation ist ein Fehler aufgetreten';ro = 'Eroare la verificarea completării atributelor';tr = 'Doldurulmuş özellikleri doğrulanamadı'; es_ES = 'Ha ocurrido un error al revisar la población del atributo'");
				
			EndIf;
			
		Except
			
			ErrorDescription = BriefErrorDescription(ErrorInfo());
			
			ObjectWrittenSuccessfully = False;
			
		EndTry;
		
		DataExchangeServer.SkipPeriodClosingCheck(False);
		
		If Not ObjectWrittenSuccessfully Then
			
			DataExchangeServer.RecordObjectWriteError(Object, ExchangeComponents.CorrespondentNode, ErrorDescription);
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region OtherProceduresAndFunctions

Procedure ReadExchangeMessage(ExchangeComponents, Results, TablesToImport = Undefined, AnalysisMode = False)
	
	Try
		ExchangeComponents.ExchangeManager.BeforeConvert(ExchangeComponents);
	Except
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Направление: %1.
			|Обработчик: ПередКонвертацией.
			|
			|Ошибка выполнения обработчика.
			|%2.'; 
			|en = 'Direction: %1.
			|Handler: BeforeConvert.
			|
			|Handler execution error.
			|%2.'; 
			|pl = 'Kierunek: %1.
			|Procedura przetwarzania: ПередКонвертацией.
			|
			|Błąd wykonania programu przetwarzania.
			|%2.';
			|de = 'Richtung: %1.
			|Handler: VorDerKonvertierung.
			|
			|Fehler bei der Ausführung des Handlers.
			|%2.';
			|ro = 'Direcția: %1.
			|Handlerul: ПередКонвертацией.
			|
			|Eroare de executare a handlerului.
			|%2.';
			|tr = 'Yön: %1. 
			| İşleyici: DönüştürmedenÖnce. 
			|
			| İşleyici yürütme hatası. 
			|%2.'; 
			|es_ES = 'Dirección: %1.
			|Procesador: ПередКонвертацией.
			|
			|Error de ejecutar el procesador.
			|%2.'"),
			ExchangeComponents.ExchangeDirection,
			DetailErrorDescription(ErrorInfo()));
	EndTry;
		
	ArrayOfObjectsToDelete   = New Array;
	ArrayOfImportedObjects = New Array;
		
	Results = New Structure;	
	Results.Insert("ArrayOfObjectsToDelete",   ArrayOfObjectsToDelete);
	Results.Insert("ArrayOfImportedObjects", ArrayOfImportedObjects);
	
	SetErrorFlag = False;
		
	While ExchangeComponents.ExchangeFile.NodeType = XMLNodeType.StartElement Do
		UpdateImportedObjectsCounter(ExchangeComponents);
		
		// Receiving XDTODataObject from the file.
		XDTODataObjectType = XDTOFactory.Type(ExchangeComponents.ExchangeFile.NamespaceURI, ExchangeComponents.ExchangeFile.LocalName);
		XDTODataObject     = XDTOFactory.ReadXML(ExchangeComponents.ExchangeFile, XDTODataObjectType);
		
		If XDTODataObjectType.Name = "ObjectDeletion" Then
			// Importing a flag of object deletion - a specific logic.
			ReadDeletion(ExchangeComponents, XDTODataObject, ArrayOfObjectsToDelete, TablesToImport);
			Continue;
		EndIf;
		
		// DPR processing
		ProcessingRule = DPRByXDTODataObjectType(ExchangeComponents, XDTODataObjectType.Name, True);
		
		If Not ValueIsFilled(ProcessingRule) Then
			Continue;
		EndIf;
		
		// Converting XDTODataObject to Structure.
		XDTOData = XDTODataObjectToStructure(XDTODataObject);
		
		OCRUsage = New Structure;
		For Each OCRName In ProcessingRule.CashReceiptsUsed Do
			OCRUsage.Insert(OCRName, True);
		EndDo;
		
		AbortProcessing = False;
		
		OnProcessExchangePlan(
			ExchangeComponents,
			ProcessingRule,
			XDTOData,
			OCRUsage,
			AbortProcessing);
		
		If AbortProcessing Then
			SetErrorFlag = True;
			Continue;
		EndIf;
		
		For Each CurrentOCR In OCRUsage Do
			Try
				ConversionRule = OCRByName(ExchangeComponents, CurrentOCR.Key);
			Except
				SetErrorFlag   = True;
				
				ErrorDescription = DPRErrorDescription(
					ExchangeComponents.ExchangeDirection,
					ProcessingRule.Name,
					XDTODataObjectPresentationForProtocol(XDTODataObjectType),
					ErrorInfo());
					
				RecordIssueOnProcessObject(ExchangeComponents,
					XDTOData,
					Enums.DataExchangeIssuesTypes.HandlersCodeExecutionErrorOnGetData,
					ErrorDescription.DetailedPresentation,
					ErrorDescription.BriefPresentation);
					
				Continue;
			EndTry;
			
			If Not FormatObjectPassesXDTOFilter(ExchangeComponents, ConversionRule.FormatObject) Then
				Continue;
			EndIf;
			
			If Not ObjectPassesByTablesToImportFilter(
					TablesToImport, XDTODataObjectType.Name, ConversionRule.ReceivedDataTypeAsString) Then
				Continue;
			EndIf;
			
			SynchronizeByID = SearchByID(ConversionRule.IdentificationOption)
				AND XDTOData.Property("Ref");
				
			If Not CurrentOCR.Value Then
				If SynchronizeByID Then
					SupplementListOfObjectsForDeletion(ExchangeComponents,
						ConversionRule.DataType, XDTOData.Ref.Value, ArrayOfObjectsToDelete);
				EndIf;
				Continue;
			EndIf;
			
			If AnalysisMode Then
				AddObjectToPackageTitleDataTable(ExchangeComponents,
					ConversionRule, XDTODataObjectType.Name, SynchronizeByID);
				
				If SynchronizeByID Then
					ArrayOfImportedObjects.Add(
						ObjectRefByXDTODataObjectUUID(XDTOData.Ref.Value, ConversionRule.DataType, ExchangeComponents));
				EndIf;
			Else
				If ExchangeComponents.DataImportToInfobaseMode
					Or TablesToImport <> Undefined Then
					
					DataToWriteToIB = Undefined;
					Try
						DataToWriteToIB = XDTOObjectStructureToIBData(
							ExchangeComponents,
							XDTOData,
							ConversionRule,
							?(ExchangeComponents.DataImportToInfobaseMode, "ConvertAndWrite", "Convert"));
					Except
						SetErrorFlag  = True;
						
						ErrorDescription = OCRErrorDescription(
							ExchangeComponents.ExchangeDirection,
							ProcessingRule.Name,
							ConversionRule.OCRName,
							XDTODataObjectPresentationForProtocol(XDTODataObjectType),
							ErrorInfo());
							
						RecordIssueOnProcessObject(ExchangeComponents,
							XDTOData,
							Enums.DataExchangeIssuesTypes.HandlersCodeExecutionErrorOnGetData,
							ErrorDescription.DetailedPresentation,
							ErrorDescription.BriefPresentation);
							
						Continue;
					EndTry;
						
				EndIf;
				
				If DataToWriteToIB = Undefined Then
					Continue;
				EndIf;
				
				If ExchangeComponents.DataImportToInfobaseMode Then
					
					If SearchByID(ConversionRule.IdentificationOption) Then
						ArrayOfImportedObjects.Add(DataToWriteToIB.Ref);
					EndIf;
					
				ElsIf TablesToImport <> Undefined Then
					
					ExecuteNumberCodeGenerationIfNecessary(DataToWriteToIB);
					
					DataTableKey = DataExchangeServer.DataTableKey(
						XDTODataObjectType.Name, ConversionRule.ReceivedDataTypeAsString, False);
					ExchangeMessageDataTable = ExchangeComponents.DataTablesExchangeMessages.Get(DataTableKey);
					
					UUIDAsString = "";
					TableRow = Undefined;
					If XDTOData.Property("Ref") Then
						UUIDAsString = XDTOData.Ref.Value;
						TableRow = ExchangeMessageDataTable.Find(UUIDAsString, "UUID");
					EndIf;
					
					If TableRow = Undefined Then
						TableRow = ExchangeMessageDataTable.Add();
						
						TableRow.TypeString              = ConversionRule.ReceivedDataTypeAsString;
						TableRow.UUID = UUIDAsString;
					EndIf;
					
					// Filling in object property values.
					FillPropertyValues(TableRow, DataToWriteToIB);
					
					If SynchronizeByID Then
						TableRow.Ref = ObjectRefByXDTODataObjectUUID(XDTOData.Ref.Value,
							ConversionRule.DataType, ExchangeComponents);
					Else
						TableRow.Ref = Undefined;
					EndIf;
					
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	
	If SetErrorFlag Then
		ExchangeComponents.ErrorFlag = True;
		ExchangeComponents.DataExchangeState.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Error;
	EndIf;
	
EndProcedure

Procedure AddObjectToPackageTitleDataTable(ExchangeComponents,
		ConversionRule, XDTODataObjectType, SynchronizeByID)
	
	TableRow = ExchangeComponents.PackageHeaderDataTable.Add();
					
	TableRow.ObjectTypeString = ConversionRule.ReceivedDataTypeAsString;
	TableRow.ObjectCountInSource = 1;
	
	TableRow.DestinationTypeString = ConversionRule.ReceivedDataTypeAsString;
	TableRow.SourceTypeString = XDTODataObjectType;
	
	TableRow.SearchFields  = ConversionRule.ObjectPresentationFields;
	TableRow.TableFields = StrConcat(ConversionRule.ReceivedDataHeaderAttributes, ",");
	
	TableRow.SynchronizeByID = SynchronizeByID;
		
	TableRow.UsePreview = TableRow.SynchronizeByID;
	TableRow.IsClassifier                    = ConversionRule.IdentificationOption = "FirstByUUIDThenBySearchFields";
	TableRow.IsObjectDeletion = False;
	
EndProcedure

Function MappingOldAndCurrentTSData(ObjectTabularSectionAfterProcessing, ObjectTabularSectionBeforeProcessing, KeyFieldsArray)
	
	MappingNewAndOldTSRows = New Map;
	
	For Each NewTSRow In ObjectTabularSectionAfterProcessing Do
		
		FoundRowOfOldTS = Undefined;
		
		SearchStructure = New Structure;
		For Each KeyField In KeyFieldsArray Do
			SearchStructure.Insert(KeyField, NewTSRow[KeyField]);
		EndDo;
		
		FoundRowsOfNewTS = ObjectTabularSectionAfterProcessing.FindRows(SearchStructure);
		
		If FoundRowsOfNewTS.Count() = 1 Then
			
			FoundRowsOfOldTS = ObjectTabularSectionBeforeProcessing.FindRows(SearchStructure);
			
			If FoundRowsOfOldTS.Count() = 1 Then
				FoundRowOfOldTS = FoundRowsOfOldTS[0];
			EndIf;
			
		EndIf;
		
		MappingNewAndOldTSRows.Insert(NewTSRow, FoundRowOfOldTS);
		
	EndDo;
	
	Return MappingNewAndOldTSRows;
	
EndFunction

Function ParseExchangeFormat(Val ExchangeFormat)
	
	Result = New Structure("BasicFormat, Version");
	
	FormatItems = StrSplit(ExchangeFormat, "/");
	
	If FormatItems.Count() = 0 Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Неканоническое имя формата обмена <%1>'; en = 'Noncanonical exchange format name: ""%1"".'; pl = 'Niekanoniczna nazwa formatu wymiany <%1>';de = 'Nicht-kanonischer Name des Austauschformats <%1>';ro = 'Denumire neconformă a formatului de schimb <%1>';tr = 'Değişim biçiminin kurallara uygun olmayan adı <%1>'; es_ES = 'Nombre no canónico del formato de intercambio <%1>'"), ExchangeFormat);
	EndIf;
	
	Result.Version = FormatItems[FormatItems.UBound()];
	
	CheckVersion(Result.Version);
	
	FormatItems.Delete(FormatItems.UBound());
	
	Result.BasicFormat = StrConcat(FormatItems, "/");
	
	Return Result;
EndFunction

Function RefByUUID(IBObjectValueType, XDTODataObjectUUID, ExchangeNode)
	
	TypesArray = New Array;
	TypesArray.Add(IBObjectValueType);
	TypesDetails = New TypeDescription(TypesArray);
	EmptyRef = TypesDetails.AdjustValue();

	MetadataObjectManager = Common.ObjectManagerByRef(EmptyRef);
	
	FoundReference = MetadataObjectManager.GetRef(New UUID(XDTODataObjectUUID));
	If Not ValueIsFilled(ExchangeNode)
		Or FoundReference.IsEmpty()
		Or Not Common.RefExists(FoundReference) Then
		Return FoundReference;
	EndIf;
	RecordStructure = New Structure;
	RecordStructure.Insert("Ref", FoundReference);
	RecordStructure.Insert("InfobaseNode", ExchangeNode);
	
	If NOT InformationRegisters.SynchronizedObjectPublicIDs.RecordIsInRegister(RecordStructure) Then
		Return FoundReference;
	EndIf;
	// Another object is mapped with this UUID. Create a reference with another UUID.
	NewRef = MetadataObjectManager.GetRef();
	
	Return NewRef;
	
EndFunction

Function FIndRefByPublicID(XDTODataObjectUUID, CorrespondentNode, IBObjectValueType)
	
	If Not ValueIsFilled(CorrespondentNode) Then
		Return Undefined;
	EndIf;
	
	Query = New Query(
	"SELECT
	|	PIR.Ref AS Ref
	|FROM
	|	InformationRegister.SynchronizedObjectPublicIDs AS PIR
	|WHERE
	|	PIR.InfobaseNode = &InfobaseNode
	|	AND PIR.ID = &ID");
	Query.SetParameter("InfobaseNode", CorrespondentNode);
	Query.SetParameter("ID",          XDTODataObjectUUID);
	
	FoundReference    = Undefined;
	IncorrectRefs = New Array;
	DeleteAllRecords   = False;
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		If TypeOf(Selection.Ref) <> IBObjectValueType Then
			Continue;
		EndIf;
		
		If FoundReference = Undefined Then
			FoundReference = Selection.Ref;
		ElsIf Common.RefExists(Selection.Ref) Then
			If Common.RefExists(FoundReference) Then
				DeleteAllRecords = True;
				FoundReference  = Undefined;
				Break;
			Else
				// Deleting a dead reference.
				IncorrectRefs.Add(FoundReference);
				
				FoundReference = Selection.Ref;
			EndIf;
		Else
			// Deleting a dead reference.
			IncorrectRefs.Add(Selection.Ref);
		EndIf;
	EndDo;
	
	If FoundReference <> Undefined
		AND IncorrectRefs.Count() > 0
		AND Not Common.RefExists(FoundReference) Then
		DeleteAllRecords = True;
		FoundReference  = Undefined;
	EndIf;
	
	If DeleteAllRecords Then
		
		RecordStructure = New Structure;
		RecordStructure.Insert("ID",          XDTODataObjectUUID);
		RecordStructure.Insert("InfobaseNode", CorrespondentNode);
		
		InformationRegisters.SynchronizedObjectPublicIDs.DeleteRecord(RecordStructure, True);
		
	ElsIf IncorrectRefs.Count() > 0 Then
		
		RecordStructure = New Structure;
		RecordStructure.Insert("ID",          XDTODataObjectUUID);
		RecordStructure.Insert("InfobaseNode", CorrespondentNode);
		
		For Each Ref In IncorrectRefs Do
			RecordStructure.Insert("Ref", Ref);
			InformationRegisters.SynchronizedObjectPublicIDs.DeleteRecord(RecordStructure, True);
		EndDo;
		
	EndIf;
	
	Return FoundReference;
	
EndFunction

// Reading and processing data on object deletion.
//
// Parameters:
//  ExchangeComponents        - Structure - contains all exchange rules and parameters.
//  XDTOObject              - an object of ObjectDeletion XDTO package that contains information 
//                            about deleted infobase object.
//  ArrayOfObjectsToDelete - an array to store the reference to the object to delete.
//                            The actual deletion of objects happens after importing all data and 
//                            analyzing them. The references  imported as other
//                            XDTODataObjects are not deleted.
//
Procedure ReadDeletion(ExchangeComponents, XDTODataObject, ArrayOfObjectsToDelete, TablesToImport = Undefined)
	
	XDTORefType = Undefined;
	
	If Not XDTODataObject.IsSet("ObjectRef") Then
		Return;
	EndIf;
	
	For Each XDTOProperty In XDTODataObject.ObjectRef.ObjectRef.Properties() Do
		
		If Not XDTODataObject.ObjectRef.ObjectRef.IsSet(XDTOProperty) Then
			Continue;
		EndIf;
		
		XDTOPropertyValue = XDTODataObject.ObjectRef.ObjectRef.GetXDTO(XDTOProperty);
		XDTORefValue   = ReadComplexTypeXDTOValue(XDTOPropertyValue, "Ref");
		
		// Determining the reference type.
		XDTORefType = XDTORefValue.XDTOValueType;
		UUIDAsString = XDTORefValue.Value;
		Break;
		
	EndDo;
	
	If XDTORefType = Undefined Then
		Return;
	EndIf;
	
	// Searching for OCR
	DPR = DPRByXDTORefType(ExchangeComponents, XDTORefType, True);
	
	If Not ValueIsFilled(DPR) Then
		Return;
	EndIf;
		
	OCRNamesArray = DPR.CashReceiptsUsed;
	
	For Each ConversionRuleName In OCRNamesArray Do
		
		ConversionRule = OCRByName(ExchangeComponents, ConversionRuleName);
		
		If Not FormatObjectPassesXDTOFilter(ExchangeComponents, ConversionRule.FormatObject) Then
			Continue;
		EndIf;
		
		If ConversionRule.IdentificationOption = "FirstByUUIDThenBySearchFields"
			Or ConversionRule.IdentificationOption = "ByUUID" Then
			
			If Not ObjectPassesByTablesToImportFilter(
					TablesToImport, XDTODataObject.Type().Name, ConversionRule.ReceivedDataTypeAsString) Then
				Continue;
			EndIf;
			
			SupplementListOfObjectsForDeletion(ExchangeComponents,
				ConversionRule.DataType, UUIDAsString, ArrayOfObjectsToDelete);
			
		EndIf;
	EndDo;
	
EndProcedure

Procedure ApplyObjectsDeletion(ExchangeComponents, ArrayOfObjectsToDelete, ArrayOfImportedObjects)
	
	For Each ImportedObject In ArrayOfImportedObjects Do
		While ArrayOfObjectsToDelete.Find(ImportedObject) <> Undefined Do
			ArrayOfObjectsToDelete.Delete(ArrayOfObjectsToDelete.Find(ImportedObject));
		EndDo;
	EndDo;
	
	ProhibitDocumentPosting = Metadata.ObjectProperties.Posting.Deny;
	
	For Each ItemToDelete In ArrayOfObjectsToDelete Do
		
		// Actually deleting the reference.
		Object = ItemToDelete.GetObject();
		If Object = Undefined Then
			Continue;
		EndIf;
		
		If ExchangeComponents.DataImportToInfobaseMode Then
			If ExchangeComponents.IsExchangeViaExchangePlan
				AND DataExchangeEvents.ImportRestricted(Object, ExchangeComponents.CorrespondentNodeObject) Then
				Return;
			EndIf;
			ObjectMetadata = Object.Metadata();
			If Metadata.Documents.Contains(ObjectMetadata) Then
				If Object.Posted Then
					HasResult = UndoObjectPostingInIB(Object, ExchangeComponents.CorrespondentNode);
					If Not HasResult Then
						Continue;
					EndIf;
				ElsIf ObjectMetadata.Posting = ProhibitDocumentPosting Then
					MakeDocumentRegisterRecordsInactive(Object, ExchangeComponents.CorrespondentNode);
				EndIf;
			EndIf;
			DataExchangeServer.SetDataExchangeLoad(Object, True, False, ExchangeComponents.CorrespondentNode);
			DeleteObject(Object, False, ExchangeComponents);
		Else
			
			ReceivedDataTypeAsString = DataTypeNameByMetadataObject(Object.Metadata());
			
			TableRow = ExchangeComponents.PackageHeaderDataTable.Add();
			
			TableRow.ObjectTypeString = ReceivedDataTypeAsString;
			TableRow.ObjectCountInSource = 1;
			TableRow.DestinationTypeString = ReceivedDataTypeAsString;
			TableRow.IsObjectDeletion = True;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure DeleteObject(Object, DeleteDirectly, ExchangeComponents)
	
	If Not WriteObjectAllowed(Object, ExchangeComponents) Then
		ErrorMessageString = StringFunctionsClientServer.SubstituteParametersToString(
			?(DeleteDirectly,
				NStr("ru = 'Попытка удаления неразделенных данных (%1: %2) в разделенном режиме.'; en = 'Attempting to delete shared data (%1: %2) in separated mode.'; pl = 'Próba usunięcia niepodzielonych danych (%1: %2) w trybie rozdzielonym.';de = 'Versuch, ungeteilte Daten (%1: %2) im geteilten Modus zu ändern.';ro = 'Tentativa de ștergere a datelor neseparate (%1: %2) în regim separat.';tr = 'Bölünmemiş verileri (%1:%2) bölünmüş modda değiştirme girişimi.'; es_ES = 'Error de eliminar los datos no divididos (%1: %2) en el modo distribuido.'"),
				NStr("ru = 'Попытка пометки на удаление неразделенных данных (%1: %2) в разделенном режиме.'; en = 'Attempting to mark shared data (%1: %2) for deletion in separated mode.'; pl = 'Próba zaznaczenia do usunięcia niepodzielonych danych (%1: %2) w trybie rozdzielonym.';de = 'Versuch, das Löschen von nicht freigegebenen Daten (%1: %2) im geteilten Modus zu markieren.';ro = 'Tentativa de marcare la ștergere a datelor neseparate (%1: %2) în regim separat.';tr = 'Bölünmemiş verileri (%1:%2) bölünmüş modda silme girişimi.'; es_ES = 'Prueba de marcar para borrar los datos no divididos (%1: %2) en el modo no distribuido.'")),
			Object.Metadata().FullName(),
			String(Object));

		If ExchangeComponents.DataExchangeState.ExchangeExecutionResult = Undefined
			Or ExchangeComponents.DataExchangeState.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Completed Then
			ExchangeComponents.DataExchangeState.ExchangeExecutionResult = Enums.ExchangeExecutionResults.CompletedWithWarnings;
		EndIf;
		
		ErrorCode = New Structure;
		ErrorCode.Insert("BriefErrorPresentation",   ErrorMessageString);
		ErrorCode.Insert("DetailedErrorPresentation", ErrorMessageString);
		ErrorCode.Insert("Level",                      EventLogLevel.Warning);
		
		WriteToExecutionProtocol(ExchangeComponents, ErrorCode, , False);
		
		Return;
	EndIf;
	
	Predefined = False;
	If CommonClientServer.HasAttributeOrObjectProperty(Object, "Predefined") Then
		Predefined = Object.Predefined;
	EndIf;
	
	If Predefined Then
		Return;
	EndIf;
	
	If DeleteDirectly Then
		Object.Delete();
	Else
		SetObjectDeletionMark(Object);
	EndIf;
	
EndProcedure

// Sets deletion mark.
//
// Parameters:
//  Object          - an object to set deletion mark for.
//  DeletionMark - Boolean - deletion mark flag.
//  ObjectTypeName  - String - an object type as a string.
//
Procedure SetObjectDeletionMark(Object)
	
	If Object.AdditionalProperties.Property("DataImportRestrictionFound") Then
		Return;
	EndIf;
	ObjectMetadata = Object.Metadata();
	If Common.IsDocument(ObjectMetadata) Then
		DataExchangeServer.SetDataExchangeLoad(Object, False);
		InformationRegisters.DataExchangeResults.RecordIssueResolved(Object,
			Enums.DataExchangeIssuesTypes.UnpostedDocument);
	EndIf;
	
	DataExchangeServer.SetDataExchangeLoad(Object);
	
	// For hierarchical objects, deletion mark is set only for a particular object.
	If Common.IsCatalog(ObjectMetadata)
		Or Common.IsChartOfCharacteristicTypes(ObjectMetadata)
		Or Common.IsChartOfAccounts(ObjectMetadata) Then
		Object.SetDeletionMark(True, False);
	Else
		Object.SetDeletionMark(True);
	EndIf;
	
EndProcedure

Function MessageFromNotUpdatedSetting(XMLReader)
	If XMLReader.NodeType = XMLNodeType.StartElement
		AND XMLReader.LocalName = "ExchangeFile" Then
		While XMLReader.ReadAttribute() Do
			If XMLReader.LocalName = "FormatVersion" 
				OR XMLReader.LocalName = "SourceConfigurationVersion" Then
				Return True;
			EndIf;
		EndDo;
	EndIf;
	Return False;
EndFunction

// Removes the flag of document register records activity.
//
// Parameters:
//  Object      - DocumentObject - a document with register records to process.
//  Sender - ExchangePlanRef - a reference to the exchange plan node, which is the data sender.
//
// Returns:
//   Boolean - shows that the activity flag is removed from register records.
Function MakeDocumentRegisterRecordsInactive(Object, Sender)
	
	Try
		
		For Each RegisterRecord In Object.RegisterRecords Do
			
			RegisterRecord.Read();
			HasChanges = False;
			For Each Row In RegisterRecord Do
				
				If Row.Active = False Then
					Continue;
				EndIf;
				
				Row.Active   = False;
				HasChanges = True;
				
			EndDo;
			
			If HasChanges Then
				RegisterRecord.Write = True;
				DataExchangeServer.SetDataExchangeLoad(RegisterRecord, True, False, Sender);
				RegisterRecord.Write();
			EndIf;
			
		EndDo;
		
	Except
		Return False;
	EndTry;
	
	Return True;
	
EndFunction

Procedure RefreshCorrespondentPrefix(ExchangeComponents) Export
	
	If ValueIsFilled(ExchangeComponents.CorrespondentPrefix) Then
		Prefixes = InformationRegisters.CommonInfobasesNodesSettings.NodePrefixes(ExchangeComponents.CorrespondentNode);
		If Not ValueIsFilled(Prefixes.CorrespondentPrefix) Then
			InformationRegisters.CommonInfobasesNodesSettings.UpdatePrefixes(
				ExchangeComponents.CorrespondentNode, , ExchangeComponents.CorrespondentPrefix);
		EndIf;
	EndIf;
	
EndProcedure

Procedure UpdateCorrespondentXDTOSettings(ExchangeComponents) Export
	
	// Checking the possibility to upgrade correspondent to a later version.
	CorrespondentVersionNumber  = Common.ObjectAttributeValue(ExchangeComponents.CorrespondentNode, "ExchangeFormatVersion");
	MaxCommonVersion    = MaxCommonFormatVersion(
		DataExchangeCached.GetExchangePlanName(ExchangeComponents.CorrespondentNode),
		ExchangeComponents.XDTOCorrespondentSettings.SupportedVersions);
	
	If MaxCommonVersion <> CorrespondentVersionNumber Then
		CorrespondentNodeObject = ExchangeComponents.CorrespondentNode.GetObject();
		CorrespondentNodeObject.ExchangeFormatVersion = MaxCommonVersion;
		CorrespondentNodeObject.Write();
		WriteToExecutionProtocol(ExchangeComponents, 
			NStr("ru = 'Изменен номер версии формата обмена.'; en = 'Exchange format version number is changed.'; pl = 'Numer wersji formatu wymiany został zmieniony.';de = 'Die Versionsnummer des Austausch-Formats wurde geändert.';ro = 'Numărul versiunii formatului de schimb este modificat.';tr = 'Değişim formatı sürüm numarası değiştirildi.'; es_ES = 'Número de la versión del formato de intercambio se ha cambiado.'"), , False, , , True);
	EndIf;
	
	InformationRegisters.XDTODataExchangeSettings.UpdateCorrespondentSettings(ExchangeComponents.CorrespondentNode,
		"SupportedObjects",
		ExchangeComponents.XDTOCorrespondentSettings.SupportedObjects);
	
EndProcedure

Procedure FillXDTOSettingsStructure(ExchangeComponents) Export
	
	If Not ExchangeComponents.IsExchangeViaExchangePlan
		Or Not ValueIsFilled(ExchangeComponents.CorrespondentNode) Then
		Return;
	EndIf;
	
	ExchangePlanName = DataExchangeCached.GetExchangePlanName(ExchangeComponents.CorrespondentNode);
	
	ExchangeComponents.XDTOSettings.Format = ExchangeFormat(ExchangePlanName, "");
	
	If ExchangeComponents.ExchangeDirection = "Send" Then
		ExchangeComponents.XDTOSettings.SupportedObjects = SupportedObjectsInFormat(
			ExchangePlanName, "SendGet", ExchangeComponents.CorrespondentNode);
	Else
		ObjectsTable = New ValueTable;
		InitializeSupportedFormatObjectsTable(ObjectsTable, ExchangeComponents.ExchangeDirection);
		
		FillSupportedFormatObjectsByExchangeComponents(ObjectsTable, ExchangeComponents);
		
		HasAlgorithm = DataExchangeServer.HasExchangePlanManagerAlgorithm(
			"OnDefineSupportedFormatObjects", ExchangePlanName);
		If HasAlgorithm Then
			ExchangePlans[ExchangePlanName].OnDefineSupportedFormatObjects(
				ObjectsTable, ExchangeComponents.ExchangeDirection, ExchangeComponents.CorrespondentNode);
		EndIf;
		
		ExchangeComponents.XDTOSettings.SupportedObjects = ObjectsTable;
	EndIf;
	
	ExchangeComponents.XDTOSettings.SupportedVersions = ExhangeFormatVersionsArray(ExchangeComponents.CorrespondentNode);
	
EndProcedure

Procedure FillCorrespondentXDTOSettingsStructure(SettingsStructure,
		Header, FormatContainsVersion = True, ExchangeNode = Undefined) Export
	
	SettingsStructure.Insert("Format", "");
	SettingsStructure.Insert("SupportedVersions",  New Array);
	SettingsStructure.Insert("SupportedObjects", New ValueTable);
	
	InitializeSupportedFormatObjectsTable(
		SettingsStructure.SupportedObjects, "SendGet");
	
	If FormatContainsVersion Then
		ExchangeFormat = ParseExchangeFormat(Header.Format);
		SettingsStructure.Format = ExchangeFormat.BasicFormat;
	Else
		SettingsStructure.Format = Header.Format;
	EndIf;
	
	For Each AvailableVersion In Header.AvailableVersion Do
		SettingsStructure.SupportedVersions.Add(AvailableVersion);
	EndDo;
	
	If Not Header.IsSet("AvailableObjectTypes")
		AND Not ExchangeNode = Undefined
		AND FormatContainsVersion Then
		// Backward compatibility with 2.x.
		// Since there is no object support information from the correspondent and it cannot be obtained, 
		// suppose the correspondent can send all the objects that this infobase can receive, and it can 
		// receive all the objects that this infobase can send.
		// The maximum common version is taken as the format version.
		
		ExchangePlanName = DataExchangeCached.GetExchangePlanName(ExchangeNode);
		
		DatabaseObjectsTable = SupportedObjectsInFormat(ExchangePlanName,
			"SendGet", ?(ExchangeNode.IsEmpty(), Undefined, ExchangeNode));
		
		For Each Version In SettingsStructure.SupportedVersions Do
			FilterByVersion = New Structure("Version", Version);
			
			BaseObjectsStrings = DatabaseObjectsTable.FindRows(FilterByVersion);
			For Each InfobaseObjectsString In BaseObjectsStrings Do
				
				CorrespondentObjectsString = SettingsStructure.SupportedObjects.Add();
				FillPropertyValues(CorrespondentObjectsString, InfobaseObjectsString, "Version, Object");
				CorrespondentObjectsString.Send = InfobaseObjectsString.Get;
				CorrespondentObjectsString.Get = InfobaseObjectsString.Send;
				
			EndDo;
		EndDo;
		
		Return;
	EndIf;
	
	If Header.AvailableObjectTypes = Undefined Then
		Return;
	EndIf;
	
	For Each ObjectType In Header.AvailableObjectTypes.ObjectType Do
		
		Sending  = New Array;
		Receiving = New Array;
		
		If Not IsBlankString(ObjectType.Sending) Then
			
			If ObjectType.Sending = "*" Then
				For Each Version In SettingsStructure.SupportedVersions Do
					Sending.Add(TrimAll(Version));
				EndDo;
			Else
				For Each Version In StrSplit(ObjectType.Sending, ",", False) Do
					Sending.Add(TrimAll(Version));
				EndDo;
			EndIf;
			
		EndIf;
		
		If Not IsBlankString(ObjectType.Receiving) Then
			
			If ObjectType.Receiving = "*" Then
				For Each Version In SettingsStructure.SupportedVersions Do
					Receiving.Add(TrimAll(Version));
				EndDo;
			Else
				For Each Version In StrSplit(ObjectType.Receiving, ",", False) Do
					Receiving.Add(TrimAll(Version));
				EndDo;
			EndIf;
			
		EndIf;
		
		For Each Version In Sending Do
			
			StringObject = SettingsStructure.SupportedObjects.Add();
			StringObject.Object = ObjectType.Name;
			StringObject.Version = Version;
			StringObject.Send = True;
			
			Index = Receiving.Find(Version);
			If Not Index = Undefined Then
				StringObject.Get = True;
				Receiving.Delete(Index);
			EndIf;
			
		EndDo;
		
		For Each Version In Receiving Do
			
			StringObject = SettingsStructure.SupportedObjects.Add();
			StringObject.Object = ObjectType.Name;
			StringObject.Version = Version;
			StringObject.Get = True;
			
		EndDo;
		
	EndDo;
	
EndProcedure

Function WriteObjectAllowed(Object, ExchangeComponents)
	
	If Common.DataSeparationEnabled()
		AND Common.SeparatedDataUsageAvailable() Then
		
		If Common.SubsystemExists("StandardSubsystems.SaaS") Then
			ModuleSaaS = Common.CommonModule("SaaS");
			IsSeparatedMetadataObject = ModuleSaaS.IsSeparatedMetadataObject(Object.Metadata());
		Else
			IsSeparatedMetadataObject = False;
		EndIf;
		
		If Not IsSeparatedMetadataObject Then
		
			Return False;
			
		EndIf;
		
	EndIf;
	
	Return True;
	
EndFunction

#EndRegion

#Region ExchangeRulesSearch

Function DPRByXDTORefType(ExchangeComponents, XDTORefType, ReturnEmptyValue = False)
	
	ProcessingRule = ExchangeComponents.DataProcessingRules.Find(XDTORefType, "XDTORefType");
	If ProcessingRule = Undefined Then
		
		If ReturnEmptyValue Then
			Return ProcessingRule;
		Else
			
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не найдено ПОД для типа ссылки XDTO.
					|Тип ссылки XDTO: %1
					|Описание ошибки: %2'; 
					|en = 'Cannot find a DER for an XDTO reference type.
					|XDTO reference type: %1
					|Error description: %2'; 
					|pl = 'Nie znaleziono ПОД dla typu linku XDTO.
					|Typ linku XDTO: %1
					|Opis błędu: %2';
					|de = 'Es wurde kein POD für den XDTO-Referenztyp gefunden.
					|Referenztyp XDTO: %1
					|Beschreibung des Fehlers: %2';
					|ro = 'Regula schimbului de date pentru tipul de referință XDTO nu a fost găsită.
					|Tipul de referință XDTO:
					|%1 Descrierea erorii: %2';
					|tr = 'XDTO referans tipi için DER bulunamadı. 
					|XDTO referans tipi: 
					|%1Hata açıklaması:%2'; 
					|es_ES = 'No se ha encontrado DER para el tipo de enlace XDTO.
					|Tipo de enlace XDTO: %1
					|Descripción de error: %2'"),
				String(XDTORefType),
				DetailErrorDescription(ErrorInfo()));
				
		EndIf;
		
	Else
		Return ProcessingRule;
	EndIf;
	
EndFunction

Function DPRByXDTODataObjectType(ExchangeComponents, XDTODataObjectType, ReturnEmptyValue = False)
	
	ProcessingRule = ExchangeComponents.DataProcessingRules.Find(XDTODataObjectType, "FilterObjectFormat");
	If ProcessingRule = Undefined Then
		
		If ReturnEmptyValue Then
			Return ProcessingRule;
		Else
			
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не найдено ПОД для типа объекта XDTO.
					|Тип объекта XDTO: %1
					|Описание ошибки: %2'; 
					|en = 'Cannot find a DER for an XDTO object type.
					|XDTO object type: %1
					|Error description: %2'; 
					|pl = 'Nie znaleziono ПОД dla typu obiektu XDTO.
					|Typ obiektu XDTO: %1
					|Opis błędu: %2';
					|de = 'Es wurde kein ODP für den XDTO-Objekttyp gefunden.
					|Objekttyp XDTO: %1
					|Beschreibung des Fehlers: %2';
					|ro = 'Regula schimbului de date pentru tipul de obiect XDTO nu a fost găsită.
					|Tipul de obiect XDTO:%1
					|Descrierea erorii: %2';
					|tr = 'XDTO nesne türü için DER bulunamadı. 
					|XDTO referans tipi: 
					|%1Hata açıklaması:%2'; 
					|es_ES = 'No se ha encontrado DER para el tipo de objeto XDTO.
					|Tipo de objeto XDTO: %1
					|Descripción de error: %2'"),
				String(XDTODataObjectType),
				DetailErrorDescription(ErrorInfo()));
				
		EndIf;
		
	Else
		Return ProcessingRule;
	EndIf;
	
EndFunction

Function DPRByMetadataObject(ExchangeComponents, MetadataObject)
	
	ProcessingRule = ExchangeComponents.DataProcessingRules.Find(MetadataObject, "SelectionObjectMetadata");
	
	If ProcessingRule = Undefined Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не найдено ПОД для объекта метаданных.
			|Объект метаданных: %3.'; 
			|en = 'Cannot find a DER for a metadata object.
			|Metadata object: %3.'; 
			|pl = 'Nie znaleziono ПОД dla obiektu metadanych.
			|Obiekt metadanych: %3.';
			|de = 'Es wurde kein POD für das Metadatenobjekt gefunden.
			|Metadaten-Objekt: %3.';
			|ro = 'Regula schimbului de date pentru obiectul de metadate nu a fost găsit.
			|Obiectul de metadate: %3.';
			|tr = 'Meta veri nesneleri için DER bulunamadı. 
			|Meta veri nesnesi:%3.'; 
			|es_ES = 'No se ha encontrado DER para el objeto de metadatos.
			|Objeto de metadatos: %3.'"),
			String(MetadataObject));
	EndIf;
	
	Return ProcessingRule;

EndFunction

Function DPRByName(ExchangeComponents, Name)
	
	ProcessingRule = ExchangeComponents.DataProcessingRules.Find(Name, "Name");
	
	If ProcessingRule = Undefined Then
		
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Не найдено ПОД с именем %1'; en = 'Cannot find a DER with name %1.'; pl = 'DER z nazwą %1 nie został znaleziony';de = 'DER mit Name %1 wird nicht gefunden';ro = 'DER cu numele %1 nu a fost găsit';tr = 'Adında %1 isimli DER bulunamadı'; es_ES = 'DER con el nombre %1 no encontrado'"), Name);
			
	Else
		Return ProcessingRule;
	EndIf;

EndFunction

Procedure GetProcessingRuleForObject(ExchangeComponents, Object, ProcessingRule)
	
	Try
		ProcessingRule = DPRByMetadataObject(ExchangeComponents, Object.Metadata());
	Except
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Событие: %1.
			|Объект: %2.
			|
			|%3.'; 
			|en = 'Event: %1.
			|Object: %2.
			|
			|%3.'; 
			|pl = 'Zdarzenie: %1.
			|Obiekt: %2.
			|
			|%3.';
			|de = 'Ereignis: %1.
			|Objekt: %2.
			|
			|%3.';
			|ro = 'Evenimentul: %1.
			|Obiectul: %2.
			|
			|%3.';
			|tr = 'Olay: %1. Nesne: 
			|. %2
			|
			|%3'; 
			|es_ES = 'Evento: %1.
			|Objeto: %2.
			|
			|%3.'"),
			ExchangeComponents.ExchangeDirection,
			ObjectPresentationForProtocol(Object),
			BriefErrorDescription(ErrorInfo()));
	EndTry;
	
EndProcedure

#EndRegion

#Region DataProcessingRulesEventHandlers
// Wrapper procedure for DPR OnProcess handler call.
//
// Parameters:
//  ExchangeComponents - Structure - contains all exchange rules and parameters.
//  ProcessingRule - a row of the data processing rules table that corresponds the DPR to process.
//  ObjectToProcess - a reference to the object to be processed, or a structure that maps an XDTO 
//                     object (on import), or a reference to an infobase object (on export).
//                     
//  OCRUsage - a structure that determines which OCR are used to export the object. Keys correspond 
//                     the OCR names, values are flags of whether an OCR is used for a specific 
//                     processing object.
//
Procedure OnProcessExchangePlan(ExchangeComponents, ProcessingRule, Val DataProcessorObject, OCRUsage, Cancel = False)
	
	If Not ValueIsFilled(ProcessingRule.OnProcess) Then
		Return;
	EndIf;
	
	ExchangeManager = ExchangeComponents.ExchangeManager;
	ParametersStructure = New Structure();
	ParametersStructure.Insert("DataProcessorObject",  DataProcessorObject);
	ParametersStructure.Insert("OCRUsage", OCRUsage);
	ParametersStructure.Insert("ExchangeComponents", ExchangeComponents);

	Try
		ExchangeManager.RunManagerModuleProcedure(ProcessingRule.OnProcess, ParametersStructure);
	Except
		Cancel = True;
		
		ErrorDescription = DPRErrorDescription(
			ExchangeComponents.ExchangeDirection,
			ProcessingRule.Name,
			ObjectPresentationForProtocol(DataProcessorObject),
			ErrorInfo());
		
		RecordIssueOnProcessObject(ExchangeComponents,
			DataProcessorObject,
			?(ExchangeComponents.ExchangeDirection = "Send",
				Enums.DataExchangeIssuesTypes.HandlersCodeExecutionErrorOnSendData,
				Enums.DataExchangeIssuesTypes.HandlersCodeExecutionErrorOnGetData),
			ErrorDescription.DetailedPresentation,
			ErrorDescription.BriefPresentation);
	EndTry;
	
	DataProcessorObject  = ParametersStructure.DataProcessorObject;
	OCRUsage = ParametersStructure.OCRUsage;
	ExchangeComponents = ParametersStructure.ExchangeComponents;
	
EndProcedure

// Wrapper procedure for DPR DataSelection handler call.
//
// Parameters:
//  ExchangeComponents - Structure - contains all exchange rules and parameters.
//  ProcessingRule - a row of the data processing rules table that corresponds the DPR to process.
//
// Return value - DataSelection handler return value (for example, query result selection).
//
Function DataSelection(ExchangeComponents, ProcessingRule)
	
	SelectionAlgorithm = ProcessingRule.DataSelection;
	If ValueIsFilled(SelectionAlgorithm) Then
		
		ExchangeManager = ExchangeComponents.ExchangeManager;
		ParametersStructure = New Structure();
		ParametersStructure.Insert("ExchangeComponents", ExchangeComponents);
		
		Try
			DataSelection = ExchangeManager.ExecuteManagerModuleFunction(ProcessingRule.DataSelection, ParametersStructure);
		Except
			ErrorText = Chars.LF + StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Событие: %1.
					|Обработчик: ВыборкаДанных.
					|ПОД: %2.
					|
					|Ошибка выполнения обработчика.
					|%3.'; 
					|en = 'Event: %1.
					|Handler: DataSelection.
					|Exchange plan: %2.
					|
					|Handler execution error.
					|%3.'; 
					|pl = 'Zdarzenie: %1.
					|Procedura przetwarzania: DataSelection.
					|: %2.
					|
					|Błąd wykonania programu przetwarzania.
					|%3.';
					|de = 'Ereignis: %1.
					|Handler: DataSelection.
					|Austauschplan:%2.
					|
					| Fehler beim Ausführen des Handlers.
					|%3.';
					|ro = 'Eveniment: %1.
					|Handler: DataSelection.
					|Planul de schimb: %2.
					|
					|Eroare la rulare handler.
					|%3.';
					|tr = 'Olay: %1. 
					|İşleyici: DataSelection. 
					| DER: %2. 
					|
					| İşleyici yürütme hatası. 
					|%3.'; 
					|es_ES = 'Evento: %1.
					|Procesador: DataSelection.
					|Plan de intercambio: %2.
					|
					|Error al realizar el procesador.
					|%3.'"),
				ExchangeComponents.ExchangeDirection,
				ProcessingRule.Name,
				DetailErrorDescription(ErrorInfo()));
			Raise ErrorText;
		EndTry;
		
	Else
		Query = New Query;
		Query.Text = 
		"SELECT
		|	Ref
		|FROM
		|	" + ProcessingRule.TableNameForSelection;
		
		DataSelection = Query.Execute().Unload().UnloadColumn("Ref");
	EndIf;
	
	Return DataSelection;
	
EndFunction

#EndRegion

#Region ConversionRulesEventsHandlers
// Wrapper function for calling OCR handler OnSendData.
//
// Parameters:
//  IBData         - a reference to the infobase object to export.
//                     If a reference is being exported, not the object, the value can be a key properties structure.
//  XDTOData       - a structure data is exported to. Its content is identical to XDTO object content.
//  HandlerName   - String, a handler procedure name in the manager module.
//  ExchangeComponents - Structure - contains all exchange rules and parameters.
//  ExportStack     - an array, contains references to objects being exported considering nesting.
//
Procedure OnSendData(IBData, XDTOData, Val HandlerName, ExchangeComponents, ExportStack)
	
	ExchangeManager = ExchangeComponents.ExchangeManager;
	ParametersStructure = New Structure();
	ParametersStructure.Insert("IBData", IBData);
	ParametersStructure.Insert("XDTOData", XDTOData);
	ParametersStructure.Insert("ExchangeComponents", ExchangeComponents);
	ParametersStructure.Insert("ExportStack", ExportStack);

	Try
		ExchangeManager.RunManagerModuleProcedure(HandlerName, ParametersStructure);
	Except
		ErrorText = Chars.LF + StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Событие: %1.
				|Обработчик: ПриОтправкеДанных.
				|Объект: %2.
				|
				|Ошибка выполнения обработчика.
				|%3.'; 
				|en = 'Event: %1.
				|Handler: OnSendData.
				|Object: %2.
				|
				|Handler execution error.
				|%3.'; 
				|pl = 'Zdarzenie: %1.
				|Procedura przetwarzania: ПриОтправкеДанных.
				|Obiekt: %2.
				|
				|Błąd wykonania programu przetwarzania.
				|%3.';
				|de = 'Ereignis: %1.
				|Handler: BeimSendenDerDaten.
				|POD: %2.
				|
				|Fehler bei der Ausführung des Handlers.
				|%3.';
				|ro = 'Evenimentul: %1.
				|Handlerul: ПриОтправкеДанных.
				|Obiectul:%2.
				|
				|Eroare de executare a handlerului.
				|%3.';
				|tr = 'Olay: %1. 
				|İşleyici: VeriGönderilirken. 
				| Nesne: %2. 
				|
				| İşleyici yürütme hatası. 
				|%3.'; 
				|es_ES = 'Evento: %1.
				|Procesador: OnSendData.
				|Objeto: %2.
				|
				|Error al realizar el procesador.
				|%3.'"),
			ExchangeComponents.ExchangeDirection,
			ObjectPresentationForProtocol(IBData),
			DetailErrorDescription(ErrorInfo()));
		Raise ErrorText;
	EndTry;
	
	XDTOData       = ParametersStructure.XDTOData;
	ExchangeComponents = ParametersStructure.ExchangeComponents;
	ExportStack     = ParametersStructure.ExportStack;
	
EndProcedure

// Wrapper function for calling OCR handler OnConvertXDTOData.
//
// Parameters:
//  ReceivedData - an infobase object the data is imported into.
//  XDTOData       - a structure data is imported from. Its content is identical to content of the XDTO object being imported.
//  ExchangeComponents - Structure - contains all exchange rules and parameters.
//  HandlerName   - String, a handler procedure name in the manager module.
//
Procedure OnConvertXDTOData(XDTOData, ReceivedData, ExchangeComponents, Val HandlerName)
	
	ExchangeManager = ExchangeComponents.ExchangeManager;
	ParametersStructure = New Structure();
	ParametersStructure.Insert("XDTOData", XDTOData);
	ParametersStructure.Insert("ReceivedData", ReceivedData);
	ParametersStructure.Insert("ExchangeComponents", ExchangeComponents);
	
	Try
		ExchangeManager.RunManagerModuleProcedure(HandlerName, ParametersStructure);
	Except
		ErrorText = Chars.LF + StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Событие: %1.
				|Обработчик: ПриКонвертацииДанныхXDTO.
				|Объект: %2.
				|
				|Ошибка выполнения обработчика.
				|%3.'; 
				|en = 'Event: %1.
				|Handler: OnConvertXDTOData.
				|Object: %2.
				|
				|Handler execution error.
				|%3.'; 
				|pl = 'Zdarzenie: %1.
				|Procedura przetwarzania: ПриКонвертацииДанныхXDTO.
				|Obiekt: %2.
				|
				|Błąd wykonania programu przetwarzania.
				|%3.';
				|de = 'Ereignis: %1.
				|Handler: BeiXDTO DatenKonvertierung.
				|POD: %2.
				|
				|Fehler bei der Ausführung des Handlers.
				|%3.';
				|ro = 'Evenimentul: %1.
				|Handlerul: ПриКонвертацииДанныхXDTO.
				|Obiectul:%2.
				|
				|Eroare de executare a handlerului.
				|%3.';
				|tr = 'Olay: %1. 
				|İşleyici: XDTOVeriDönüştürmeEsnasında
				| Nesne: %2. 
				|
				| İşleyici yürütme hatası. 
				|%3.'; 
				|es_ES = 'Evento: %1.
				|Procesador: OnConvertXDTOData.
				|Objeto: %2.
				|
				|Error al realizar el procesador.
				|%3.'"),
			ExchangeComponents.ExchangeDirection,
			ObjectPresentationForProtocol(ReceivedData),
			DetailErrorDescription(ErrorInfo()));
		Raise ErrorText;
	EndTry;
	
	XDTOData               = ParametersStructure.XDTOData;
	ReceivedData         = ParametersStructure.ReceivedData;
	ExchangeComponents         = ParametersStructure.ExchangeComponents;
	
EndProcedure

// Wrapper function for calling OCR handler BeforeWriteReceivedData.
//
// Parameters:
//  ReceivedData   - an infobase object data is imported into.
//  IBData           - an infobase object found when identifying the data being imported.
//                       If the object mapping the imported one is not found, IBData = Undefined.
//  ExchangeComponents   - Structure - contains all rules and exchange parameters.
//  HandlerName     - String, a handler procedure name in the manager module.
//  PropertiesConversion  - a value table, the object property conversion rules.
//                       It is used to determine the composition of properties that are to be transferred from ReceivedData to
//                       IBData.
//
Procedure BeforeWriteReceivedData(ReceivedData, IBData, ExchangeComponents, HandlerName, PropertiesConversion)
	
	ExchangeManager = ExchangeComponents.ExchangeManager;
	ParametersStructure = New Structure();
	ParametersStructure.Insert("IBData", IBData);
	ParametersStructure.Insert("ReceivedData", ReceivedData);
	ParametersStructure.Insert("ExchangeComponents", ExchangeComponents);
	ParametersStructure.Insert("PropertiesConversion", PropertiesConversion);

	Try
		ExchangeManager.RunManagerModuleProcedure(HandlerName, ParametersStructure);
	Except
		ErrorText = Chars.LF + StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Событие: %1.
				|Обработчик: ПередЗаписьюПолученныхДанных.
				|Объект: %2.
				|
				|Ошибка выполнения обработчика.
				|%3.'; 
				|en = 'Event: %1.
				|Handler: BeforeWriteReceivedData.
				|Object: %2.
				|
				|Handler execution error.
				|%3.'; 
				|pl = 'Zdarzenie: %1.
				|Procedura przetwarzania: ПередЗаписьюПолученныхДанных.
				|Obiekt: %2.
				|
				|Błąd wykonania programu przetwarzania.
				|%3.';
				|de = 'Ereignis: %1.
				|Handler: VorAufzeichnungDerEmpfangenenDaten.
				|POD: %2.
				|
				|Fehler bei der Ausführung des Handlers.
				|%3.';
				|ro = 'Evenimentul: %1.
				|Handlerul: ПередЗаписьюПолученныхДанных.
				|Obiectul:%2.
				|
				|Eroare de executare a handlerului.
				|%3.';
				|tr = 'Olay: %1. 
				|İşleyici: AlınmışVeriKaydetmedenÖnce. 
				| Nesne: %2. 
				|
				| İşleyici yürütme hatası. 
				|%3.'; 
				|es_ES = 'Evento: %1.
				|Procesador: BeforeWriteReceivedData.
				|Objeto: %2.
				|
				|Error al realizar el procesador.
				|%3.'"),
			ExchangeComponents.ExchangeDirection,
			ObjectPresentationForProtocol(?(IBData <> Undefined, IBData, ReceivedData)),
			DetailErrorDescription(ErrorInfo()));
		Raise ErrorText;
	EndTry;
	
	IBData                 = ParametersStructure.IBData;
	ReceivedData         = ParametersStructure.ReceivedData;
	ExchangeComponents         = ParametersStructure.ExchangeComponents;
	PropertiesConversion       = ParametersStructure.PropertiesConversion;
	
EndProcedure

#EndRegion

#EndRegion

#Region KeepProtocol

// Returns a Structure type object containing all possible fields of the execution protocol record 
// (such as error messages and others).
//
// Parameters:
//  ErrorMessageCode - String, contains an error code.
//  ErrorLine        - String, contains a module line where an error occurred.
//
// Returns:
//  Object of the Structure type.
// 
Function ExchangeProtocolRecord(ErrorMessageCode = "", Val ErrorRow = "")

	ErrorStructure = New Structure();
	ErrorStructure.Insert("ObjectType");
	ErrorStructure.Insert("Object");
	ErrorStructure.Insert("ErrorDescription");
	ErrorStructure.Insert("ModulePosition");
	ErrorStructure.Insert("ErrorMessageCode");
	
	ModuleLine              = SplitWithSeparator(ErrorRow, "{");
	ErrorDescription            = SplitWithSeparator(ModuleLine, "}: ");
	
	If ErrorDescription <> "" Then
		
		ErrorStructure.ErrorDescription         = ErrorDescription;
		ErrorStructure.ModulePosition          = ModuleLine;
		
	EndIf;
	
	If ErrorStructure.ErrorMessageCode <> "" Then
		
		ErrorStructure.ErrorMessageCode           = ErrorMessageCode;
		
	EndIf;
	
	Return ErrorStructure;
	
EndFunction

Function ExchangeExecutionResultError(ExchangeExecutionResult)
	
	Return ExchangeExecutionResult = Enums.ExchangeExecutionResults.Error
		Or ExchangeExecutionResult = Enums.ExchangeExecutionResults.Error_MessageTransport;
	
EndFunction

Function ExchangeExecutionResultWarning(ExchangeExecutionResult)
	
	Return ExchangeExecutionResult = Enums.ExchangeExecutionResults.CompletedWithWarnings
		Or ExchangeExecutionResult = Enums.ExchangeExecutionResults.Warning_ExchangeMessageAlreadyAccepted;
	
EndFunction

// The function generates the object presentation to be written to the exchange protocol.
//
// Parameters:
//   Object - Ref - a reference to any MO.
//          - Object - a MO.
//          - XDTODataObject - an XDTO object.
//          - Structure.
//
// Returns:
//   String - a string presentation of the object.
//
Function ObjectPresentationForProtocol(Object)
	
	ObjectType = TypeOf(Object);
	ObjectMetadata = Metadata.FindByType(ObjectType);
	ObjectPresentation = String(Object);
	URL = "";
	If ObjectMetadata <> Undefined
		AND Common.IsRefTypeObject(ObjectMetadata)
		AND ValueIsFilled(Object.Ref) Then
		URL = GetURL(Object);
	Else
		If ObjectType = Type("XDTODataObject") Then
			PropertiesCollection = Object.Properties();
			ObjectPresentation = "";
			ObjectType = Object.Type().Name;
			If PropertiesCollection.Count() > 0 AND PropertiesCollection.Get("KeyProperties") <> Undefined Then
				KeyProperties = Object.Get("KeyProperties");
				PropertiesCollection = KeyProperties.Properties();
				Description = "";
				Number = "";
				Date = "";
				Code = "";
				If PropertiesCollection.Get("Description") <> Undefined Then
					Description = TrimAll(KeyProperties.Get("Description"));
				EndIf;
				If PropertiesCollection.Get("Number") <> Undefined Then
					Number = TrimAll(KeyProperties.Get("Number"));
				EndIf;
				If PropertiesCollection.Get("Date") <> Undefined Then
					Date = KeyProperties.Get("Date");
				EndIf;
				If PropertiesCollection.Get("Code") <> Undefined Then
					Code = TrimAll(KeyProperties.Get("Code"));
				ElsIf PropertiesCollection.Get("CodeInApp") <> Undefined Then
					Code = TrimAll(KeyProperties.Get("CodeInApp"));
				EndIf;
				If ValueIsFilled(Number) Then
					ObjectPresentation = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = '%1 №%2 от %3'; en = '%1 #%2, %3'; pl = '%1 #%2 z dn. %3';de = '%1 #%2 datiert %3';ro = '%1 Nr.%2 din %3';tr = '%1 sayılı %2 tarihli %3'; es_ES = '%1 #%2 fechado %3'"), Description, Number, Date);
				ElsIf ValueIsFilled(Code) Then
					ObjectPresentation = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = '%1, %2'; en = '%1, %2'; pl = '%1, %2';de = '%1, %2';ro = '%1, %2';tr = '%1, %2'; es_ES = '%1, %2'"), Description, Code);
				EndIf;
			EndIf;
		ElsIf ObjectType = Type("Structure") Then
			If Object.Property("Ref") Then
				ObjectType = TypeOf(Object.Ref);
				ObjectPresentation = String(Object.Ref);
				URL = GetURL(Object.Ref);
			EndIf;
		EndIf;
	EndIf;
	
	PresentationTemplate = NStr("ru = '%1, %2 (%3)'; en = '%1, %2 (%3)'; pl = '%1, %2 (%3)';de = '%1, %2 (%3)';ro = '%1, %2 (%3)';tr = '%1, %2 (%3)'; es_ES = '%1, %2 (%3)'");
	ObjectPresentation = StringFunctionsClientServer.SubstituteParametersToString(PresentationTemplate, ObjectType, ObjectPresentation, URL);
	
	Return ObjectPresentation;
	
EndFunction

Function XDTODataObjectPresentationForProtocol(XDTODataObjectType)
	
	Return XDTODataObjectType.Name;
	
EndFunction

#EndRegion

#Region DataExchangeResults

Function DPRErrorDescription(ExchangeDirection, DPRName, ObjectPresentation, Information)
	
	Result = New Structure("BriefPresentation, DetailedPresentation");
	
	ErrorDescriptionTemplate = NStr("ru = 'Событие: %1.
	|Обработчик: ПриОбработкеПОД.
	|ПОД: %2.
	|Объект: %3.
	|
	|Ошибка выполнения обработчика.
	|%4.'; 
	|en = 'Event: %1.
	|Handler: OnProcessExchangePlan.
	|Exchange plan: %2.
	|Object: %3.
	|
	|Handler execution error.
	|%4.'; 
	|pl = 'Zdarzenie: %1.
	|Procedura przetwarzania: ПриОбработкеПОД.
	|ПОД: %2.
	|Obiekt: %3.
	|
	|Błąd wykonania programu przetwarzania.
	|%4.';
	|de = 'Ereignis: %1.
	|Handler: BeiBearbeitungVonPOD.
	|POD: %2.
	|Objekt: %3.
	|
	|Fehler bei der Ausführung des Handlers.
	|%4.';
	|ro = 'Evenimentul: %1.
	|Handlerul: ПриОбработкеПОД.
	|RPD: %2.
	|Obiectul: %3.
	|
	|Eroare de executare a handlerului.
	|%4.';
	|tr = 'Olay: %1.
	|İşleyici: DERİşlemesiEsnasında.
	|DER: %2.
	|Nesne: %3.
	|
	|İşleyici yürütme hatası.
	|%4.'; 
	|es_ES = 'Evento: %1.
	|Procesador: ПриОбработкеПОД.
	|ПОД: %2.
	|Objeto: %3.
	|
	|Error al realizar el procesador.
	|%4.'");
	
	Result.BriefPresentation = StringFunctionsClientServer.SubstituteParametersToString(
		ErrorDescriptionTemplate,
		ExchangeDirection,
		DPRName,
		ObjectPresentation,
		BriefErrorDescription(Information));
	Result.DetailedPresentation = StringFunctionsClientServer.SubstituteParametersToString(
		ErrorDescriptionTemplate,
		ExchangeDirection,
		DPRName,
		ObjectPresentation,
		DetailErrorDescription(Information));
	
	Return Result;
	
EndFunction

Function OCRErrorDescription(ExchangeDirection, DPRName, OCRName, ObjectPresentation, Information)
	
	Result = New Structure("BriefPresentation, DetailedPresentation");
	
	ErrorDescriptionTemplate = NStr("ru = 'Направление: %1.
	|ПОД: %2.
	|ПКО: %3.
	|Объект: %4.
	|
	|%5'; 
	|en = 'Direction: %1.
	|DER: %2.
	|OCR: %3.
	|Object: %4.
	|
	|%5'; 
	|pl = 'Kierunek: %1.
	|POD: %2.
	|POG: %3.
	|Obiekt: %4.
	|
	|%5';
	|de = 'Richtung: %1.
	|POD: %2.
	|PKO: %3.
	|Objekt: %4.
	|
	|%5';
	|ro = 'Direcția: %1.
	|RSD: %2.
	|RCO: %3.
	|Obiectul: %4.
	|
	|%5';
	|tr = 'Yön: %1.
	|POD: %2.
	|PKО: %3.
	|Nesne: %4.
	|
	|%5'; 
	|es_ES = 'Dirección: %1.
	|ПОД: %2.
	|ПКО: %3.
	|Objeto: %4.
	|
	|%5'");
	
	Result.BriefPresentation = StringFunctionsClientServer.SubstituteParametersToString(
		ErrorDescriptionTemplate,
		ExchangeDirection,
		DPRName,
		OCRName,
		ObjectPresentation,
		BriefErrorDescription(Information));
	Result.DetailedPresentation = StringFunctionsClientServer.SubstituteParametersToString(
		ErrorDescriptionTemplate,
		ExchangeDirection,
		DPRName,
		OCRName,
		ObjectPresentation,
		DetailErrorDescription(Information));
		
	Return Result;
	
EndFunction

Procedure RecordIssueOnProcessObject(ExchangeComponents,
		DataProcessorObject, IssueType, DetailedPresentation, BriefPresentation = "")
	
	ErrorCode = New Structure("Level", ErrorLevelByErrorType(ExchangeComponents, IssueType));
	ErrorCode.Insert("DetailedErrorPresentation", DetailedPresentation);
	ErrorCode.Insert("BriefErrorPresentation",
		?(IsBlankString(BriefPresentation), DetailedPresentation, BriefPresentation));
	
	If ExchangeComponents.IsExchangeViaExchangePlan Then
		If ExchangeComponents.ExchangeDirection = "Send" Then
			WriteToExecutionProtocol(ExchangeComponents, ErrorCode, , Not ExchangeComponents.SkipObjectsWithSchemaCheckErrors);
			WriteObjectProcessingErrorOnSend(
				DataProcessorObject,
				ExchangeComponents.CorrespondentNode,
				ErrorCode.BriefErrorPresentation,
				IssueType);
		Else
			WriteToExecutionProtocol(ExchangeComponents, ErrorCode);
		EndIf;
	Else
		WriteToExecutionProtocol(ExchangeComponents, ErrorCode);
	EndIf;
	
EndProcedure

Procedure WriteObjectProcessingErrorOnSend(DataProcessorObject, InfobaseNode, Reason, IssueType)
	
	If TypeOf(DataProcessorObject) = Type("Structure") Then
		Return;
	EndIf;
	
	If Common.IsRefTypeObject(DataProcessorObject.Metadata()) Then
		InformationRegisters.DataExchangeResults.RecordDocumentCheckError(
			DataProcessorObject.Ref,
			InfobaseNode,
			Reason,
			IssueType);
	Else
		InformationRegisters.DataExchangeResults.RecordDocumentCheckError(
			DataProcessorObject,
			InfobaseNode,
			Reason,
			IssueType);
	EndIf;

EndProcedure

Procedure ClearErrorsListOnExportData(InfobaseNode)
	
	InformationRegisters.DataExchangeResults.ClearIssuesOnSend(InfobaseNode);
	
EndProcedure

Procedure ClearErrorsListOnImportData(InfobaseNode)
	
	InformationRegisters.DataExchangeResults.ClearIssuesOnGet(InfobaseNode);
	
EndProcedure

Function ErrorLevelByErrorType(ExchangeComponents, IssueType)
	
	If IssueType = Enums.DataExchangeIssuesTypes.ConvertedObjectValidationError Then
		Return ?(ExchangeComponents.IsExchangeViaExchangePlan
				AND ExchangeComponents.SkipObjectsWithSchemaCheckErrors,
			EventLogLevel.Warning, EventLogLevel.Error);
	ElsIf IssueType = Enums.DataExchangeIssuesTypes.HandlersCodeExecutionErrorOnSendData
		Or IssueType = Enums.DataExchangeIssuesTypes.HandlersCodeExecutionErrorOnGetData Then
		Return EventLogLevel.Error;
	ElsIf IssueType = Enums.DataExchangeIssuesTypes.BlankAttributes
		Or IssueType = Enums.DataExchangeIssuesTypes.UnpostedDocument Then
		Return EventLogLevel.Warning;
	EndIf;
	
	Return Undefined;
	
EndFunction

#EndRegion

#Region ExchangeFormatVersioningProceduresAndFunctions

Function MaxCommonFormatVersion(ExchangePlanName, CorrespondentFormatVersions) Export
	
	MaxCommonVersion = "0.0";
	
	FormatVersions = ExhangeFormatVersionsArray(ExchangePlans[ExchangePlanName].ThisNode());
	
	For Each CorrespondentVersion In CorrespondentFormatVersions Do
		CorrespondentVersion = TrimAll(CorrespondentVersion);
		
		If FormatVersions.Find(CorrespondentVersion) = Undefined Then
			Continue;
		EndIf;
		
		If CompareVersions(CorrespondentVersion, MaxCommonVersion) >= 0 Then
			MaxCommonVersion = CorrespondentVersion;
		EndIf;
	EndDo;
	
	Return MaxCommonVersion;
	
EndFunction

Function ExchangeFormatVersions(Val InfobaseNode)
	
	ExchangeFormatVersions = New Map;
	ExchangePlanName = "";
	
	If ValueIsFilled(InfobaseNode) Then
		ExchangePlanName = DataExchangeCached.GetExchangePlanName(InfobaseNode);
		ExchangeFormatVersions = DataExchangeServer.ExchangePlanSettingValue(ExchangePlanName, "ExchangeFormatVersions");
	Else
		DataExchangeOverridable.OnGetAvailableFormatVersions(ExchangeFormatVersions);
	EndIf;
	
	If ExchangeFormatVersions.Count() = 0 Then
		If ValueIsFilled(InfobaseNode) Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не заданы версии формата обмена.
				|Имя плана обмена: %1
				|Процедура: ПолучитьВерсииФорматаОбмена(<ВерсииФорматаОбмена>)'; 
				|en = 'Exchange format versions are not specified.
				|Exchange plan name: %1
				|Procedure: GetExchangeFormatVersions(<ExchangeFormatVersions>).'; 
				|pl = 'Nie są określone wersje formatu wymiany.
				|Nazwa planu wymiany: %1
				|Procedura: ПолучитьВерсииФорматаОбмена(<ВерсииФорматаОбмена>)';
				|de = 'Es wird keine Version des Austauschformats angegeben.
				|Name des Austausch-Plans: %1
				|Vorgehensweise: AustauschFormatVersionenErhalten(<AustauschFormatVersionen>)';
				|ro = 'Versiunile formatului de schimb nu sunt specificate.
				|Numele planului de schimb: %1
				|Procedura: GetExchangeFormatVersions (<ExchangeFormatVersions>)';
				|tr = 'Alışveriş formatının sürümleri belirtilmemiş. 
				|Veri alışverişi planının adı:%1 
				|Prosedür: DeğişimFormatıSürümleriniAlın (<DeğişimFormatıSürümleri>)'; 
				|es_ES = 'No se han establecido las versiones del formato del objeto.
				|Nombre del plan de cambio: %1
				|Procedimiento: GetExchangeFormatVersions(<ExchangeFormatVersions>)'"),
				ExchangePlanName);
		Else
			Raise NStr("ru = 'Не заданы версии формата обмена.
				|Процедура: ОбменДаннымиПереопределяемый.ПриПолученииДоступныхВерсийФормата(<ВерсииФорматаОбмена>)'; 
				|en = 'Exchange format versions are not specified.
				|Procedure: DataExchangeOverridable.OnGetAvailableFormatVersions(<ExchangeFormatVersions>).'; 
				|pl = 'Nie są określone wersje formatu wymiany.
				|Procedura: ОбменДаннымиПереопределяемый.ПриПолученииДоступныхВерсийФормата(<ВерсииФорматаОбмена>)';
				|de = 'Es wird keine Version des Austauschformats angegeben.
				|Vorgehensweise: DatenaustauschNeuDefinierbar.BeimEmpfangVerfügbarerFormatVersionen(<AustauschFormatVersionen>)';
				|ro = 'Nu sunt specificate versiunile formatului de schimb.
				|Procedura: ОбменДаннымиПереопределяемый.ПриПолученииДоступныхВерсийФормата(<ВерсииФорматаОбмена>)';
				|tr = 'Veri alışveriş biçimi sürümleri belirlenmemiş. 
				| İşlem: YenidenBelirlenenVeriAlışverişi.ErişilebilirBiçimSürümleriniAlırken (<AlışverişBiçimiSürümleri>)'; 
				|es_ES = 'No se han establecido las versiones del formato del objeto.
				|Procedimiento: DataExchangeOverridable.OnGetAvailableFormatVersions(<ExchangeFormatVersions>).'");
		EndIf;
	EndIf;
	
	Result = New Map;
	
	For Each Version In ExchangeFormatVersions Do
		
		Result.Insert(TrimAll(Version.Key), Version.Value);
		
	EndDo;
	
	Return Result;
	
EndFunction

Function SortFormatVersions(Val FormatVersions)
	
	Result = New ValueTable;
	Result.Columns.Add("Version");
	
	For Each Version In FormatVersions Do
		
		Result.Add().Version = Version.Key;
		
	EndDo;
	
	Result.Sort("Version Desc");
	
	Return Result.UnloadColumn("Version");
EndFunction

Procedure CheckVersion(Val Version)
	
	Versions = StrSplit(Version, ".");
	
	If Versions.Count() = 0 Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Неканоническое представление версии формата обмена: <%1>.'; en = 'Noncanonical presentation of the exchange format version: %1.'; pl = 'Niekanoniczna prezentacja wersji formatu wymiany <%1>';de = 'Nicht-kanonische Darstellung der Austausch-Formatversion: <%1>.';ro = 'Prezentarea neconformă a versiunii formatului de schimb: <%1>.';tr = 'Değişim biçimi sürümünün kanonik olmayan sunumu: <%1>.'; es_ES = 'Presentación no canónica de la versión del formato de intercambio: <%1>.'"), Version);
	EndIf;
	
EndProcedure

Function MinExchangeFormatVersion(Val InfobaseNode)
	
	Result = Undefined;
	
	FormatVersions = ExchangeFormatVersions(InfobaseNode);
	
	For Each FormatVersion In FormatVersions Do
		
		If Result = Undefined Then
			Result = FormatVersion.Key;
			Continue;
		EndIf;
		If CompareVersions(TrimAll(Result), TrimAll(FormatVersion.Key)) > 0 Then
			Result = FormatVersion.Key;
		EndIf;
		
	EndDo;
	
	Return Result;
EndFunction

// Receives an array of exchange format versions sorted in descending order.
// Parameters:
//  InfobaseNode - a reference to the correspondent node.
//
Function ExhangeFormatVersionsArray(Val InfobaseNode) Export
	
	Return SortFormatVersions(ExchangeFormatVersions(InfobaseNode));
	
EndFunction

// Compares two versions in the String format.
//
// Parameters:
//  VersionString1  - String - a number of version in either 0.0.0 or 0.0 format.
//  VersionString2  - String - the second version.
//
// Returns:
//   Number - if VersionString1 > VersionString2, it is a positive number. If they are equal, it is 0.
//             Less than 0 if VersionString1 < VersionString2.
Function CompareVersions(Val VersionString1, Val VersionString2)
	
	String1 = ?(IsBlankString(VersionString1), "0.0", VersionString1);
	String2 = ?(IsBlankString(VersionString2), "0.0", VersionString2);
	Version1 = StrSplit(String1, ".");
	If Version1.Count() < 2 OR Version1.Count() > 3 Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Неправильный формат параметра СтрокаВерсии1: %1'; en = 'Invalid format of VersionString1 parameter: %1.'; pl = 'Niepoprawny format dla parametru VersionRow1: %1';de = 'Ungültiges Format für Parameter Version Reihe1: %1';ro = 'Format incorect pentru parametrul VersionRow1: %1';tr = 'SürümSatırı1 parametresi için geçersiz biçim: %1'; es_ES = 'Formato inválido para el parámetro VersiónFila1:%1'"), VersionString1);
	EndIf;
	Version2 = StrSplit(String2, ".");
	If Version2.Count() < 2 OR Version2.Count() > 3 Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Неправильный формат параметра СтрокаВерсии2: %1'; en = 'Invalid format of VersionString2 parameter: %1.'; pl = 'Niepoprawny format dla parametru VersionRow2: %1';de = 'Ungültiges Format für Parameter Version Reihe2: %1';ro = 'Format incorect pentru parametrul VersionRow2: %1';tr = 'SürümSatırı2 parametresi için geçersiz biçim:%1'; es_ES = 'Formato inválido para el parámetro VersiónFila2:%1'"), VersionString2);
	EndIf;
	
	Result = 0;
	If TrimAll(VersionString1) = TrimAll(VersionString2) Then
		Return 0;
	EndIf;
	
	// The last digit can be beta which is the minimal version incompatible with any other version.
	If Version1.Count() = 3 AND TrimAll(Version1[2]) = "beta" Then
		Return -1;
	ElsIf Version2.Count() = 3 AND TrimAll(Version2[2]) = "beta" Then
		Return 1;
	EndIf;
	// When comparing, the first two digits are considered (always number).
	For Digit = 0 To 1 Do
		Result = Number(Version1[Digit]) - Number(Version2[Digit]);
		If Result <> 0 Then
			Return Result;
		EndIf;
	EndDo;
	Return Result;
	
EndFunction

Function VersionSupported(SupportedVersions, VersionToCheck)
	
	Result = False;
	
	For Each SupportedVersion In SupportedVersions Do
		If CompareVersions(SupportedVersion, VersionToCheck) >= 0 Then
			Result = True;
			Break;
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Miscellaneous

// Splits a string into two parts: before the separator substring and after it.
//
// Parameters:
//  Str          - a string to split.
//  Separator  - separator substring:
//  Mode        - 0 - separator is not included in the returned substrings.
//                 1 - separator is included in the left substring.
//                 2 - separator is included in the right substring.
//
// Returns:
//  The right part of the string - before the separator character.
// 
Function SplitWithSeparator(Page, Val Separator, Mode=0)

	RightPart         = "";
	SeparatorPos      = StrFind(Page, Separator);
	SeparatorLength    = StrLen(Separator);
	If SeparatorPos > 0 Then
		RightPart	 = Mid(Page, SeparatorPos + ?(Mode=2, 0, SeparatorLength));
		Page          = TrimAll(Left(Page, SeparatorPos - ?(Mode=1, -SeparatorLength + 1, 1)));
	EndIf;

	Return(RightPart);

EndFunction // SplitWithSeparator()

// Returns a string presentation of the type which is expected for the data corresponding to the 
// passed metadata object.
// It can be used as a value of the Type() embedded function parameter.
//
// Parameters:
//  MetadataObject - a metadata object to use for identifying the type name.
//
// Returns:
//  String - for example, "CatalogRef.Products".
//
Function DataTypeNameByMetadataObject(Val MetadataObject)
	
	LiteralsOfType = StrSplit(MetadataObject.FullName(), ".");
	TableType = LiteralsOfType[0];
	
	If TableType = "Constant" Then
		
		TypeNameTemplate = "[TableType]ValueManager.[TableName]";
		
	ElsIf TableType = "InformationRegister"
		Or TableType = "AccumulationRegister"
		Or TableType = "AccountingRegister"
		Or TableType = "CalculationRegister" Then
		
		TypeNameTemplate = "[TableType]RecordSet.[TableName]";
		
	Else
		TypeNameTemplate = "[TableType]Ref.[TableName]";
	EndIf;
	
	TypeNameTemplate = StrReplace(TypeNameTemplate, "[TableType]", LiteralsOfType[0]);
	Result = StrReplace(TypeNameTemplate, "[TableName]", LiteralsOfType[1]);
	Return Result;
	
EndFunction

Procedure WritePublicIDIfNecessary(
		DataToWriteToIB,
		ReceivedDataRef,
		UUIDAsString,
		ExchangeNode,
		ConversionRule)
	
	IdentificationOption = TrimAll(ConversionRule.IdentificationOption);
	If Not (IdentificationOption = "FirstByUUIDThenBySearchFields"
		Or IdentificationOption = "ByUUID")
		Or Not ValueIsFilled(ExchangeNode) Then
		Return;
	EndIf;
	
	RecordStructure = New Structure;
	RecordStructure.Insert("InfobaseNode", ExchangeNode);
	RecordStructure.Insert("Ref", ?(DataToWriteToIB = Undefined, ReceivedDataRef, DataToWriteToIB.Ref));
	
	If DataToWriteToIB <> Undefined
		AND InformationRegisters.SynchronizedObjectPublicIDs.RecordIsInRegister(RecordStructure) Then
		Return;
	EndIf;
	
	PublicID = ?(ValueIsFilled(UUIDAsString), UUIDAsString, ReceivedDataRef.UUID());
	RecordStructure.Insert("ID", PublicID);
	
	InformationRegisters.SynchronizedObjectPublicIDs.AddRecord(RecordStructure, True);
	
EndProcedure

Procedure AddExportedObjectsToPublicIDsRegister(ExchangeComponents)
	NodeForExchange = ExchangeComponents.CorrespondentNode;
	ExchangePlanComposition = NodeForExchange.Metadata().Content;
	QueryText = "SELECT 
	|	ChangesTable.Ref
	|FROM 
	|	#FullName#.Changes AS ChangesTable
	|LEFT JOIN 
	|	InformationRegister.SynchronizedObjectPublicIDs AS PublicIDs
	|ON PublicIDs.InfobaseNode = &Node AND PublicIDs.Ref = ChangesTable.Ref
	|WHERE ChangesTable.Node = &Node AND ChangesTable.MessageNo <= &MessageNo
	|	AND PublicIDs.ID IS NULL";
	For Each CompositionItem In ExchangePlanComposition Do
		If NOT Common.IsRefTypeObject(CompositionItem.Metadata) Then
			Continue;
		EndIf;
		FullObjectName = CompositionItem.Metadata.FullName();
		Query = New Query;
		Query.Text = StrReplace(QueryText, "#FullName#", FullObjectName);
		Query.SetParameter("Node", NodeForExchange);
		Query.SetParameter("MessageNo", ExchangeComponents.MessageNumberReceivedByCorrespondent);
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			RecordStructure = New Structure;
			RecordStructure.Insert("Ref", Selection.Ref);
			RecordStructure.Insert("InfobaseNode", ExchangeComponents.CorrespondentNode);
			RecordStructure.Insert("ID", Selection.Ref.UUID());
			InformationRegisters.SynchronizedObjectPublicIDs.AddRecord(RecordStructure, True);
		EndDo;
	EndDo;
EndProcedure

Function XMLBaseSchema()
	
	Return "http://www.1c.ru/SSL/Exchange/Message";
	
EndFunction

Function VersionNumberWithDataExchangeIDSupport()
	Return "1.5";
EndFunction

Procedure InitializeSupportedFormatObjectsTable(ObjectsTable, Mode)
	
	ObjectsTable.Columns.Add("Version", New TypeDescription("String"));
	ObjectsTable.Columns.Add("Object", New TypeDescription("String"));
	
	If StrFind(Mode, "Send") Then
		ObjectsTable.Columns.Add("Send", New TypeDescription("Boolean"));
	EndIf;
	
	If StrFind(Mode, "Get") Then
		ObjectsTable.Columns.Add("Get", New TypeDescription("Boolean"));
	EndIf;
	
	ObjectsTable.Indexes.Add("Version, Object");
	
EndProcedure

Procedure FillSupportedFormatObjectsByExchangeComponents(ObjectsTable, ExchangeComponents)
	
	If ExchangeComponents.ExchangeDirection = "Send" Then
		
		For Each ConversionRule In ExchangeComponents.ObjectConversionRules Do
			
			Filter = New Structure;
			Filter.Insert("Version", ExchangeComponents.ExchangeFormatVersion);
			Filter.Insert("Object", ConversionRule.XDTOType.Name);
			
			RowsObjects = ObjectsTable.FindRows(Filter);
			If RowsObjects.Count() = 0 Then
				RowObjects = ObjectsTable.Add();
				FillPropertyValues(RowObjects, Filter);
			Else
				RowObjects = RowsObjects[0];
			EndIf;
			
			RowObjects.Send = True;
			
		EndDo;
		
	ElsIf ExchangeComponents.ExchangeDirection = "Get" Then
		
		For Each ProcessingRule In ExchangeComponents.DataProcessingRules Do
			
			Filter = New Structure;
			Filter.Insert("Version", ExchangeComponents.ExchangeFormatVersion);
			Filter.Insert("Object", ProcessingRule.FilterObjectFormat);
			
			RowsObjects = ObjectsTable.FindRows(Filter);
			If RowsObjects.Count() = 0 Then
				RowObjects = ObjectsTable.Add();
				FillPropertyValues(RowObjects, Filter);
			Else
				RowObjects = RowsObjects[0];
			EndIf;
			
			RowObjects.Get = True;
			
		EndDo;
		
	EndIf;
	
EndProcedure

Function FormatObjectPassesXDTOFilter(ExchangeComponents, FormatObject)
	
	Return Not ExchangeComponents.IsExchangeViaExchangePlan
		Or ExchangeComponents.SupportedXDTODataObjects.Find(FormatObject) <> Undefined;
	
EndFunction
	
Function ObjectPassesByTablesToImportFilter(TablesToImport, DataTypeOnSend, DataTypeOnGet)
	
	If TablesToImport = Undefined Then
		Return True;
	EndIf;
	
	DataTableKey = DataExchangeServer.DataTableKey(DataTypeOnSend, DataTypeOnGet, False);
	
	Return TablesToImport.Find(DataTableKey) <> Undefined;
	
EndFunction

Function SearchByID(Val IdentificationOption)
	
	IdentificationOption = TrimAll(IdentificationOption);
	
	Return (IdentificationOption = "FirstByUUIDThenBySearchFields")
		Or (IdentificationOption = "ByUUID");
									
EndFunction
	
Procedure SupplementListOfObjectsForDeletion(ExchangeComponents, DataType, UUID, ArrayOfObjectsToDelete)
	
	RefForDeletion = ObjectRefByXDTODataObjectUUID(UUID,
		DataType, ExchangeComponents);
	If ArrayOfObjectsToDelete.Find(RefForDeletion) = Undefined Then
		ArrayOfObjectsToDelete.Add(RefForDeletion);
	EndIf;
	
EndProcedure

Procedure UpdateImportedObjectsCounter(ExchangeComponents)
	
	ExchangeComponents.ImportedObjectCounter = ExchangeComponents.ImportedObjectCounter + 1;
	DataExchangeServer.CalculateImportPercent(ExchangeComponents.ImportedObjectCounter,
		ExchangeComponents.ObjectsToImportCount, ExchangeComponents.ExchangeMessageFileSize);
	
EndProcedure

Procedure FillXDTODataObjectPropertiesList(XDTODataObjectType, Properties)
	
	For Each ChildProperty In XDTODataObjectType.Properties Do
		If TypeOf(ChildProperty.Type) = Type("XDTOObjectType")
			AND StrStartsWith(ChildProperty.Type.Name, "CommonProperties") Then
			FillXDTODataObjectPropertiesList(ChildProperty.Type, Properties);
		Else
			Properties.Add(ChildProperty.Name);
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion
