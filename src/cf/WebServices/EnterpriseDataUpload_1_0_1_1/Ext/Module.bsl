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

Function ConnectionTest(ErrorMessage)
	
	ErrorMessage = "";
	
	// Checking that the infobase is not the file one.
	If Common.FileInfobase() Then
		ErrorMessage = NStr("ru = 'Подключаемая информационная база является файловой,
			|в связи с чем не поддерживает работу методов веб-сервиса.'; 
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
	
	Return True;
	
EndFunction

Function GetDataImportResult(BackgroundJobID, ErrorMessage)
	
	Return DataExchangeInternal.GetDataReceiptExecutionStatus(BackgroundJobID, ErrorMessage);
	
EndFunction

// PutFilePart
//
Function ImportFilePart(FileID, FilePartToImportNumber, FilePartToImport, ErrorMessage)
	
	Return DataExchangeInternal.ImportFilePart(FileID, FilePartToImportNumber, FilePartToImport, ErrorMessage);
	
EndFunction

// PutData
//
Function ImportDataToInfobase(FileID, BackgroundJobID, ErrorMessage)
	
	ErrorMessage = "";
	
	ParametersStructure = DataExchangeInternal.InitializeWebServiceParameters();
	ParametersStructure.TempStorageFileID = DataExchangeInternal.PrepareFileForImport(FileID, ErrorMessage);
	ParametersStructure.WEBServiceName                          = "EnterpriseDataUpload_1_0_1_1";
	
	// Importing to the infobase.
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("WebServiceParameters", ParametersStructure);
	ProcedureParameters.Insert("ErrorMessage",   ErrorMessage);

	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(New UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("ru = 'Загрузка данных в информационную базу через web-сервис ""Enterprise Data Upload""'; en = 'Import data into the infobase through web service ""Enterprise Data Upload""'; pl = 'Wczytywanie danych do bazy informacyjnej za pośrednictwem web-serwisu ""Enterprise Data Upload""';de = 'Import von Daten in die Datenbank über den Webservice ""Enterprise Data Upload""';ro = 'Încărcarea datelor în baza de informații prin intermediul serviciului web ""Enterprise Data Upload""';tr = 'Verilerin """"Enterprise Data Upload"" web hizmeti üzerinden veritabanına içe aktarımı'; es_ES = 'Descarga de datos en la base de información a través del servicio web ""Enterprise Data Upload""'");
	ExecutionParameters.BackgroundJobKey = String(New UUID);
	
	ExecutionParameters.RunInBackground = True;

	BackgroundJob = TimeConsumingOperations.ExecuteInBackground(
		"DataExchangeInternal.ImportXDTODateToInfobase",
		ProcedureParameters,
		ExecutionParameters);
	BackgroundJobID = String(BackgroundJob.JobID);
	
	Return "";
	
EndFunction

#EndRegion