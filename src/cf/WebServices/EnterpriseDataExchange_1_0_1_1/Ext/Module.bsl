///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private
////////////////////////////////////////////////////////////////////////////////
// Web service operation handlers

Function Ping()
	Return "";
EndFunction

Function ConnectionTest(ExchangePlanName, ExchangePlanNodeCode, ErrorMessage)
	
	ErrorMessage = "";
	
	// Checking that the infobase is not the file one.
	If Common.FileInfobase() Then
		ErrorMessage = NStr("ru = 'Подключаемая информационная база является файловой,
			|в связи с чем не поддерживает работу методов web-сервиса.'; 
			|en = 'The infobase is the file base,
			|so web service methods are not supported.'; 
			|pl = 'Podłączana baza informacyjna jest system plików,
			|w związku z czym nie obsługuje metody web-serwisu.';
			|de = 'Die verbundene Informationsbasis ist eine Dateibasis
			|und unterstützt daher nicht die Arbeit von Webservice-Methoden.';
			|ro = 'Baza de informații conectată este de tip fișier,
			|de aceea nu susține lucrul metodelor serviciului web.';
			|tr = 'Bağlı veri tabanı bir dosya veri tabanı olmasından dolayı, 
			|web hizmeti tekniklerinin çalışmasını desteklemiyor.'; 
			|es_ES = 'La base de información conectada es de archivo
			|por eso no se admite el uso de métodos del servicio web.'");
		Return False;
	EndIf;
	
	// Checking whether a user has rights to perform the data exchange.
	Try
		DataExchangeInternal.CheckCanSynchronizeData();
	Except
		ErrorMessage = BriefErrorDescription(ErrorInfo());
		Return False;
	EndTry;
	
	// Checking whether the infobase is locked for update.
	Try
		DataExchangeInternal.CheckInfobaseLockForUpdate();
	Except
		ErrorMessage = BriefErrorDescription(ErrorInfo());
		Return False;
	EndTry;
	
	SetPrivilegedMode(True);
	
	// Checking whether the exchange plan node exists (it might be deleted).
	If ExchangePlans[ExchangePlanName].FindByCode(ExchangePlanNodeCode).IsEmpty() Then
		ErrorMessage = NStr("ru = 'Заданный узел плана обмена не найден. Обратитесь к администратору приложения.'; en = 'Presetting not foung. Please contact with application administrator'; pl = 'Określony węzeł planu wymiany nie został znaleziony. Skontaktuj się z administratorem aplikacji.';de = 'Der angegebene Knoten des Austauschplans wurde nicht gefunden. Wenden Sie sich an den Administrator der Anwendung.';ro = 'Nodul planului de schimb specificat nu a fost găsit. Adresați-vă la administratorul aplicației.';tr = 'Belirlenen alışveriş planı ünitesi bulunamadı.  Uygulama yöneticisine başvurun.'; es_ES = 'El nodo establecido del plan de cambio no se ha encontrado. Diríjase al administrador de la aplicación.'");
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

// ConfirmGettingFile
//
Function ConfirmDataExported(FileID, ConfirmFileReceipt, ErrorMessage)
	
	ErrorMessage = "";
	
	Try
		DeleteFiles(DataExchangeInternal.TemporaryExportDirectory(FileID));
	Except
		
		ErrorMessage = BriefErrorDescription(ErrorInfo());
		WriteLogEvent(DataExchangeServer.TempFileDeletionEventLogMessageText(),
			EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
			
	EndTry;
		
	Return "";	
		
EndFunction

Function GetDataImportResult(BackgroundJobID, ErrorMessage)
	
	Return DataExchangeInternal.GetDataReceiptExecutionStatus(BackgroundJobID, ErrorMessage);
	
EndFunction

Function GetPrepareDataToExportResult(BackgroundJobID, ErrorMessage)
	
	Return DataExchangeInternal.GetExecutionStatusOfPreparingDataForSending(BackgroundJobID, ErrorMessage);
	
EndFunction

// PutFilePart
//
Function ImportFilePart(FileID, FilePartToImportNumber, FilePartToImport, ErrorMessage)
	
	Return DataExchangeInternal.ImportFilePart(FileID, FilePartToImportNumber, FilePartToImport, ErrorMessage);
	
EndFunction

Function ExportFilePart(FileID, FilePartToExportNumber, ErrorMessage)
	
	Return DataExchangeInternal.ExportFilePart(FileID, FilePartToExportNumber, ErrorMessage);
	
EndFunction

// PutData
//
Function ImportDataToInfobase(ExchangePlanName, ExchangePlanNodeCode, FileID, BackgroundJobID, ErrorMessage)
	
	ErrorMessage = "";
	
	ParametersStructure = DataExchangeInternal.InitializeWebServiceParameters();
	ParametersStructure.ExchangePlanName                         = ExchangePlanName;
	ParametersStructure.ExchangePlanNodeCode                     = ExchangePlanNodeCode;
	ParametersStructure.TempStorageFileID = DataExchangeInternal.PrepareFileForImport(FileID, ErrorMessage);
	ParametersStructure.WEBServiceName                          = "EnterpriseDataExchange_1_0_1_1";
	
	// Importing data to the infobase.
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("WebServiceParameters", ParametersStructure);
	ProcedureParameters.Insert("ErrorMessage",   ErrorMessage);

	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(New UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("ru = 'Загрузка данных в информационную базу через web-сервис ""Enterprise Data Exchange""'; en = 'Import data into the infobase through web service ""Enterprise Data Exchange""'; pl = 'Wczytywanie danych do bazy informacyjnej za pośrednictwem web-serwisu ""Enterprise Data Exchange""';de = 'Importieren von Daten in die Datenbank über den ""Enterprise Data Exchange"" Webservice';ro = 'Încărcarea datelor în baza de informații prin intermediul serviciului web ""Enterprise Data Exchange""';tr = 'Verilerin """"Enterprise Data Exchange"" web hizmeti üzerinden veritabanına içe aktarımı'; es_ES = 'Descarga de datos en la base de información a través del servicio web ""Enterprise Data Exchange""'");
	ExecutionParameters.BackgroundJobKey = String(New UUID);
	
	ExecutionParameters.RunInBackground = True;

	BackgroundJob = TimeConsumingOperations.ExecuteInBackground(
		"DataExchangeInternal.ImportXDTODateToInfobase",
		ProcedureParameters,
		ExecutionParameters);
	BackgroundJobID = String(BackgroundJob.JobID);
	
	Return "";
	
EndFunction

// PrepareDataForGetting
//
Function PrepareDataToImport(ExchangePlanName, ExchangePlanNodeCode, FilePartSize, BackgroundJobID, ErrorMessage)
	
	ErrorMessage = "";
	
	ParametersStructure = DataExchangeInternal.InitializeWebServiceParameters();
	ParametersStructure.ExchangePlanName                         = ExchangePlanName;
	ParametersStructure.ExchangePlanNodeCode                     = ExchangePlanNodeCode;
	ParametersStructure.FilePartSize                       = FilePartSize;
	ParametersStructure.TempStorageFileID = New UUID();
	ParametersStructure.WEBServiceName                          = "EnterpriseDataExchange_1_0_1_1";
	
	// Preparing data to export from the infobase.
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("WebServiceParameters", ParametersStructure);
	ProcedureParameters.Insert("ErrorMessage",   ErrorMessage);

	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(New UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("ru = 'Подготовка к выгрузке данных из информационной базы через web-сервис ""Enterprise Data Exchange""'; en = 'Preparing data export from infobase via web service ""Enterprise Data Exchange""'; pl = 'Przygotowanie do wyeksportowania danych z bazy informacyjnej za pośrednictwem web-serwisu ""Enterprise Data Exchange""';de = 'Vorbereitung zum Export von Daten aus der Informationsdatenbank über den Webservice ""Enterprise Data Exchange"".';ro = 'Pregătirea pentru descărcarea datelor din baza de informații prin intermediul serviciului web ""Enterprise Data Exchange""';tr = 'Verilerin """"Enterprise Data Exchange"" web hizmeti üzerinden veritabanına dışa aktarmaya hazırlık'; es_ES = 'Preparación a la subida de datos de la base de información a través del servicio web ""Enterprise Data Exchange""'");
	ExecutionParameters.BackgroundJobKey = String(New UUID);
	
	ExecutionParameters.RunInBackground = True;

	BackgroundJob = TimeConsumingOperations.ExecuteInBackground(
		"DataExchangeInternal.PrepareDataForExportFromInfobase",
		ProcedureParameters,
		ExecutionParameters);
	BackgroundJobID = String(BackgroundJob.JobID);
	
	Return "";
	
EndFunction

#EndRegion