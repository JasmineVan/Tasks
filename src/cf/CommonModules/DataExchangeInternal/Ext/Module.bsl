///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// Returns an error flag at start:
// 1) Exchange message import error:
//    - Metadata object ID import error.
//    - Object ID verification error.
//    - Error of importing exchange message before infobase update.
//    - Error of importing exchange message before infobase update when infobase version is not changed.
// 2) Database update error after successful exchange message import.
//
Function RetryDataExchangeMessageImportBeforeStart() Export
	
	SetPrivilegedMode(True);
	
	Return Constants.RetryDataExchangeMessageImportBeforeStart.Get();
	
EndFunction

// See CommonOverridable.OnAddSessionParametersSettingHandlers. 
Procedure SessionParametersSetting(ParameterName, SpecifiedParameters) Export
	
	// Session parameters must be initialized without using application parameters.
	
	If ParameterName = "DataExchangeMessageImportModeBeforeStart" Then
		SessionParameters.DataExchangeMessageImportModeBeforeStart = New FixedStructure(New Structure);
		SpecifiedParameters.Add("DataExchangeMessageImportModeBeforeStart");
		Return;
	EndIf;
	
	If Common.SeparatedDataUsageAvailable() Then
		
		// Procedure for updating cached values and session parameters.
		UpdateObjectsRegistrationMechanismCache();
		
		// Registering parameter names set on
		// execution of DataExchangeServerCall.UpdateObjectsRecordMechanismCache.
		SpecifiedParameters.Add("SelectiveObjectsRegistrationRules");
		SpecifiedParameters.Add("ObjectsRegistrationRules");
		SpecifiedParameters.Add("ORMCachedValuesRefreshDate");
		
		SessionParameters.DataSynchronizationPasswords = New FixedMap(New Map);
		SpecifiedParameters.Add("DataSynchronizationPasswords");
		
		SessionParameters.PriorityExchangeData = New FixedArray(New Array);
		SpecifiedParameters.Add("PriorityExchangeData");
		
		SessionParameters.DataSynchronizationSessionParameters = New ValueStorage(New Map);
		SpecifiedParameters.Add("DataSynchronizationSessionParameters");
		
		CheckStructure =New Structure;
		CheckStructure.Insert("CheckVersionDifference", False);
		CheckStructure.Insert("HasError", False);
		CheckStructure.Insert("ErrorText", "");
		
		SessionParameters.VersionMismatchErrorOnGetData = New FixedStructure(CheckStructure);
		SpecifiedParameters.Add("VersionMismatchErrorOnGetData");
		
	Else
		
		SessionParameters.DataSynchronizationPasswords = New FixedMap(New Map);
		SpecifiedParameters.Add("DataSynchronizationPasswords");
		
		SessionParameters.DataSynchronizationSessionParameters = New ValueStorage(New Map);
		SpecifiedParameters.Add("DataSynchronizationSessionParameters");
	EndIf;
	
EndProcedure

// Checks whether object registration cache is up-to-date.
// If the cached data is obsolete, cache gets initialized with new values.
//
// Parameters:
//  No.
// 
Procedure CheckObjectsRegistrationMechanismCache() Export
	
	SetPrivilegedMode(True);
	
	If Common.SeparatedDataUsageAvailable() Then
		
		ActualDate = GetFunctionalOption("ORMCachedValuesLatestUpdate");
		
		If SessionParameters.ORMCachedValuesRefreshDate <> ActualDate Then
			
			UpdateObjectsRegistrationMechanismCache();
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Updates or sets cached values and session parameters for data exchange subsystem.
//
// The following session parameters are set:
//   ObjectsRegistrationRules - ValueStorage - contains an object registration rule value table in 
//                                                    binary format.
//   SelectiveObjectsRegistrationRules -
//   ORMCachedValueRefreshDate - Date (Date and time) - contains the date of the last relevant cache 
//                                                                         for the data exchange subsystem.
//
// Parameters:
//  No.
// 
Procedure UpdateObjectsRegistrationMechanismCache() Export
	
	SetPrivilegedMode(True);
	
	RefreshReusableValues();
	
	If DataExchangeCached.ExchangePlansInUse().Count() > 0 Then
		
		SessionParameters.ObjectsRegistrationRules = New ValueStorage(DataExchangeServer.GetObjectsRegistrationRules());
		
		SessionParameters.SelectiveObjectsRegistrationRules = New ValueStorage(DataExchangeServer.GetSelectiveObjectsRegistrationRules());
		
	Else
		
		SessionParameters.ObjectsRegistrationRules = New ValueStorage(DataExchangeServer.ObjectsRegistrationRulesTableInitialization());
		
		SessionParameters.SelectiveObjectsRegistrationRules = New ValueStorage(DataExchangeServer.SelectiveObjectsRegistrationRulesTableInitialization());
		
	EndIf;
	
	// Getting date value for checking whether cached data is up-to-date.
	SessionParameters.ORMCachedValuesRefreshDate = GetFunctionalOption("ORMCachedValuesLatestUpdate");
	
EndProcedure

// See DataExchangeServerCall.ResetObjectsRegistrationMechanismCache. 
Procedure ResetObjectsRegistrationMechanismCache() Export
	
	If Common.SeparatedDataUsageAvailable() Then
		
		SetPrivilegedMode(True);
		// Recording universal date and time of the server computer - CurrentUniversalDate(). Do not use the 
		// CurrentSessionDate() method.
		// The current universal server date is used as a unique key for the object registration mechanism 
		// cache.
		Constants.ORMCachedValuesRefreshDate.Set(CurrentUniversalDate());
		
	EndIf;
	
EndProcedure

// Returns the list of priority exchange data items.
//
// Returns:
//	Array - a collection of references to priority exchange data items.
//
Function PriorityExchangeData() Export
	
	SetPrivilegedMode(True);
	
	Result = New Array;
	
	For Each Item In SessionParameters.PriorityExchangeData Do
		
		Result.Add(Item);
		
	EndDo;
	
	Return Result;
EndFunction

// Clears the list of priority exchange data items.
//
Procedure ClearPriorityExchangeData() Export
	
	SetPrivilegedMode(True);
	
	SessionParameters.PriorityExchangeData = New FixedArray(New Array);
	
EndProcedure

// Adds the passed value to the list of priority exchange data items.
//
Procedure SupplementPriorityExchangeData(Val Data) Export
	
	Result = PriorityExchangeData();
	
	Result.Add(Data);
	
	SetPrivilegedMode(True);
	
	SessionParameters.PriorityExchangeData = New FixedArray(Result);
	
EndProcedure

// Returns the flag that shows whether application parameters are imported into the infobase from the exchange message.
// This function is used in DIB data exchange when data is imported to a subordinate node.
//
Function DataExchangeMessageImportModeBeforeStart(Property) Export
	
	SetPrivilegedMode(True);
	
	Return SessionParameters.DataExchangeMessageImportModeBeforeStart.Property(Property);
	
EndFunction

// Returns a flag that shows whether an exchange plan is used in data exchange.
// If an exchange plan contains at least one node apart from the predefined one, it is considered 
// being used in data exchange.
//
// Parameters:
//	ExchangePlanName - String - an exchange plan name as it is set in Designer.
//
// Returns:
//	Boolean - True if the exchange plan is being used, False if it is not being used.
//
Function DataExchangeEnabled(Val ExchangePlanName, Val Sender) Export
	
	SetPrivilegedMode(True);
	
	Return DataExchangeCached.DataExchangeEnabled(ExchangePlanName, Sender);
EndFunction

// Returns the value of session parameter ObjectsRegistrationRules obtained in privileged mode.
//
// Returns:
//	ValueStorage - the value of the ObjectsRegistrationRules session parameter.
//
Function SessionParametersObjectsRegistrationRules() Export
	
	SetPrivilegedMode(True);
	
	Return SessionParameters.ObjectsRegistrationRules;
	
EndFunction

// Returns the flag that indicates whether data changes are registered for the specified recipient.
//
Function ChangesRegistered(Val Recipient) Export
	
	QueryText =
	"SELECT TOP 1 1
	|FROM
	|	[Table].Changes AS ChangesTable
	|WHERE
	|	ChangesTable.Node = &Node";
	
	Query = New Query;
	Query.SetParameter("Node", Recipient);
	
	SetPrivilegedMode(True);
	
	ExchangePlanComposition = Metadata.ExchangePlans[DataExchangeCached.GetExchangePlanName(Recipient)].Content;
	
	For Each CompositionItem In ExchangePlanComposition Do
		
		Query.Text = StrReplace(QueryText, "[Table]", CompositionItem.Metadata.FullName());
		
		QueryResult = Query.Execute();
		
		If Not QueryResult.IsEmpty() Then
			Return True;
		EndIf;
		
	EndDo;
	
	Return False;
EndFunction

Function ImportFilePart(FileID, FilePartToImportNumber, FilePartToImport, ErrorMessage) Export
	
	ErrorMessage = "";
	
	If Not ValueIsFilled(FileID) Then
		ErrorMessage = NStr("ru = 'Не указан идентификатор загружаемого файла. Дальнейшее выполнение метода невозможно.
				|Необходимо для загружаемого файла назначить уникальный идентификатор.'; 
				|en = 'Cannot execute the method. The ID of the file to be imported is not specified.
				|Please specify a UUID for the file.'; 
				|pl = 'Nie jest wskazany identyfikator pobieranego pliku. Dalsze wykonanie metody jest niemożliwe.
				|Należy dla pobieranego pliku wyznaczyć unikalny identyfikator.';
				|de = 'Die Kennung der heruntergeladenen Datei wird nicht angegeben. Eine weitere Ausführung der Methode ist nicht möglich.
				|Es ist notwendig, der heruntergeladenen Datei eine eindeutige Kennung zuzuweisen.';
				|ro = 'Nu este indicat identificatorul fișierului încărcat. Executarea ulterioară a metodei este imposibilă.
				| Atribuiți identificatorul unic pentru fișierul încărcat.';
				|tr = 'İndirilen dosyanın kimliği belirtilmedi. Bir yöntemin daha fazla yürütülmesi mümkün değildir. 
				|İndirilen dosyanın benzersiz bir tanımlayıcı atamanız gerekir.'; 
				|es_ES = 'No se ha indicado el identificador del archivo descargado. La siguiente ejecución del método es imposible.
				|Es necesario indicar el identificador único para el archivo descargado.'");
		Raise(ErrorMessage);
	EndIf;
	
	If Not ValueIsFilled(FilePartToImport)
		AND TypeOf(FilePartToImport) <> Type("BinaryData") Then
		ErrorMessage = NStr("ru = 'Метод не может быть выполнен, т.к. переданные данные не соответствуют типу для получения данных.'; en = 'Cannot execute the method as the passed data type does not match the expected type.'; pl = 'Metoda nie może być wykonana, ponieważ przekazane dane nie odpowiadają typowi do otrzymania danych.';de = 'Die Methode kann nicht ausgeführt werden, da die übertragenen Daten nicht dem Typ des Datenempfangs entsprechen.';ro = 'Metoda nu poate fi executată, deoarece datele transmise nu corespund tipului pentru primirea datelor.';tr = 'Yöntem yürütülemez, çünkü aktarılan veriler veri almak için türe uygun değildir.'; es_ES = 'El método no puede ser realizado porque los datos pasados no corresponden al tipo para recibir los datos.'");
		Raise(ErrorMessage);
	EndIf;
	
	If Not ValueIsFilled(FilePartToImportNumber) 
		Or FilePartToImportNumber = 0 Then
		FilePartToImportNumber = 1;
	EndIf;
	
	TempFilesDirectory = TemporaryExportDirectory(FileID);
	
	Directory = New File(TempFilesDirectory);
	If Not Directory.Exist() Then
		CreateDirectory(TempFilesDirectory);
	EndIf;
	
	FileName = CommonClientServer.GetFullFileName(TempFilesDirectory, GetFilePartName(FilePartToImportNumber));
	FilePartToImport.Write(FileName);
	
	Return "";
	
EndFunction

Function ExportFilePart(FileID, FilePartToExportNumber, ErrorMessage) Export
	
	ErrorMessage      = "";
	FilePartName          = "";
	TempFilesDirectory = TemporaryExportDirectory(FileID);
	
	For DigitsCount = StrLen(Format(FilePartToExportNumber, "NFD=0; NG=0")) To 5 Do
		
		FormatString = StringFunctionsClientServer.SubstituteParametersToString("ND=%1; NLZ=; NG=0", String(DigitsCount));
		
		FileName = StringFunctionsClientServer.SubstituteParametersToString("%1.zip.%2", FileID, Format(FilePartToExportNumber, FormatString));
		
		FileNames = FindFiles(TempFilesDirectory, FileName);
		
		If FileNames.Count() > 0 Then
			
			FilePartName = CommonClientServer.GetFullFileName(TempFilesDirectory, FileName);
			Break;
			
		EndIf;
		
	EndDo;
	
	FilePart = New File(FilePartName);
	
	If FilePart.Exist() Then
		Return New BinaryData(FilePartName);
	Else
		ErrorMessage = NStr("ru = 'Часть файла с указанным номером не найдена.'; en = 'The file part with the specified number is not found.'; pl = 'Część pliku ze wskazanym numerem nie jest wyszukana.';de = 'Der Teil der Datei mit der angegebenen Nummer wurde nicht gefunden.';ro = 'Partea de fișier cu numărul indicat nu a fost găsită.';tr = 'Belirtilen numaraya sahip dosyanın bir kısmı bulunamadı.'; es_ES = 'La parte de archivo con el número indicado no se ha encontrado.'");
	EndIf;
	
EndFunction

Function PrepareFileForImport(FileID, ErrorMessage) Export
	
	SetPrivilegedMode(True);
	
	TempStorageFileID = "";
	
	TempFilesDirectory = TemporaryExportDirectory(FileID);
	ArchiveName              = CommonClientServer.GetFullFileName(TempFilesDirectory, "datafile.zip");
	
	ReceivedFilesArray = FindFiles(TempFilesDirectory,"data.zip.*");
	
	If ReceivedFilesArray.Count() > 0 Then
		
		FilesToMerge = New Array();
		FilePartName = CommonClientServer.GetFullFileName(TempFilesDirectory, "data.zip.%1");
		
		For PartNumber = 1 To ReceivedFilesArray.Count() Do
			FilesToMerge.Add(StringFunctionsClientServer.SubstituteParametersToString(FilePartName, PartNumber));
		EndDo;
		
	Else
		MessageTemplate = NStr("ru = 'Не найден ни один фрагмент сессии передачи с идентификатором %1.
				|Необходимо убедиться, что в настройках программы заданы параметры
				|""Каталог временных файлов для Linux"" и ""Каталог временных файлов для Windows"".'; 
				|en = 'No fragments of the transfer session with ID %1 are found.
				|Ensure that ""Windows temporary files directory"" and
				|""Linux temporary files directory"" are specified in the application settings.'; 
				|pl = 'Nie znaleziono żadnego fragmentu sesji przekazania z identyfikatorem %1.
				|Należy upewnić się, że w ustawieniach programu są określone parametry
				|""Каталог временных файлов для Linux"" и ""Каталог временных файлов для Windows"".';
				|de = 'Es wurden keine Fragmente einer Übertragungssitzung mit dem Bezeichner gefunden %1.
				| Es ist darauf zu achten, dass die Programmeinstellungen die Parameter 
				|""Temporäres Dateiverzeichnis für Linux"" und ""Temporäres Dateiverzeichnis für Windows"" enthalten.';
				|ro = 'Nici un fragment al sesiunii de transfer cu ID%1nu este găsit.
				|Este necesar să vă asigurați că în parametrii setărilor aplicației sunt specificați parametrii
				|""Directorul fișierelor temporare pentru Linux"" și ""Directorul fișierelor temporare pentru Windows"".';
				|tr = '%1Kimlik ile transfer oturumu parçası bulunamadı. 
				|Uygulama ayarlarında ""Linux için geçici dosya dizini"" ve ""Windows için geçici dosya dizini"" 
				|belirtildiğinden emin olmak gerekir.'; 
				|es_ES = 'No se ha encontrado ningún fragmento de la sesión de traspaso con el identificador %1.
				|Es necesario asegurarse que en los ajustes del programa se han establecido los parámetros
				|""Catálogo de los archivos temporales para Linux"" y ""Catálogo de los archivos temporales para Windows"".'");
		ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, String(FileID));
		Raise(ErrorMessage);
	EndIf;
	
	Try 
		MergeFiles(FilesToMerge, ArchiveName);
	Except
		ErrorMessage = BriefErrorDescription(ErrorInfo());
		Raise(ErrorMessage);
	EndTry;
	
	// Unpack.
	Dearchiver = New ZipFileReader(ArchiveName);
	
	If Dearchiver.Items.Count() = 0 Then
		
		Try
			DeleteFiles(TempFilesDirectory);
		Except
			ErrorMessage = DetailErrorDescription(ErrorInfo());
			WriteLogEvent(DataExchangeServer.TempFileDeletionEventLogMessageText(),
				EventLogLevel.Error,,, ErrorMessage);
			Raise(ErrorMessage);
		EndTry;
		
		ErrorMessage = NStr("ru = 'Файл архива не содержит данных.'; en = 'The archive file does not contain data.'; pl = 'Plik archiwum nie zawiera danych.';de = 'Die Archivdatei enthält keine Daten.';ro = 'Fișierul arhivei nu conține date.';tr = 'Arşiv dosyası veri içermemektedir.'; es_ES = 'Documento del archivo no contiene datos.'");
		Raise(ErrorMessage);
		
	EndIf;
	
	FileName = CommonClientServer.GetFullFileName(TempFilesDirectory, Dearchiver.Items[0].Name);
	Dearchiver.Extract(Dearchiver.Items[0], TempFilesDirectory);
	Dearchiver.Close();
	
	// Placing the file to the file temporary storage directory.
	ImportDirectory          = DataExchangeServer.TempFilesStorageDirectory();
	NameOfFIleWithData         = CommonClientServer.GetNameWithExtension(FileID, CommonClientServer.GetFileNameExtension(FileName));
	FileNameInImportDirectory = CommonClientServer.GetFullFileName(ImportDirectory, NameOfFIleWithData);
	
	Try
		MoveFile(FileName, FileNameInImportDirectory);
	Except
		ErrorMessage = DetailErrorDescription(ErrorInfo());
		WriteLogEvent(DataExchangeServer.TempFileDeletionEventLogMessageText(),
			EventLogLevel.Error,,, ErrorMessage);
		Raise(ErrorMessage);
	EndTry;
	
	TempStorageFileID = DataExchangeServer.PutFileInStorage(FileNameInImportDirectory);
	
	// Deleting temporary files.
	Try
		DeleteFiles(TempFilesDirectory);
	Except
		ErrorMessage = DetailErrorDescription(ErrorInfo());
		WriteLogEvent(DataExchangeServer.TempFileDeletionEventLogMessageText(),
			EventLogLevel.Error,,, ErrorMessage);
		Raise(ErrorMessage);
	EndTry;
	
	Return TempStorageFileID;
	
EndFunction

Procedure PrepareDataForExportFromInfobase(ProcedureParameters, StorageAddress) Export
	
	WebServiceParameters = ProcedureParameters["WebServiceParameters"];
	ErrorMessage   = ProcedureParameters["ErrorMessage"];
	
	SetPrivilegedMode(True);
	
	ExchangeComponents = ExchangeComponents("Send", WebServiceParameters);
	FileName         = String(New UUID()) + ".xml";
	
	TempFilesDirectory = DataExchangeServer.TempFilesStorageDirectory();
	FullFileName         = CommonClientServer.GetFullFileName(
		TempFilesDirectory, FileName);
		
	// Opening the exchange file.
	DataExchangeXDTOServer.OpenExportFile(ExchangeComponents, FullFileName);
	
	If ExchangeComponents.ErrorFlag Then
		ExchangeComponents.ExchangeFile = Undefined;
		
		DataExchangeXDTOServer.FinishKeepExchangeProtocol(ExchangeComponents);
		
		Raise ExchangeComponents.ErrorMessageString;
	EndIf;
	
	ExchangeSettingsStructure = ExchangeSettingsStructure(ExchangeComponents, Enums.ActionsOnExchange.DataExport);
	
	// Exporting data.
	Try
		DataExchangeXDTOServer.ExecuteDataExport(ExchangeComponents);
	Except
		
		If ExchangeComponents.IsExchangeViaExchangePlan Then
			UnlockDataForEdit(ExchangeComponents.CorrespondentNode);
		EndIf;
		
		Info = ErrorInfo();
		ErrorCode = New Structure("BriefErrorPresentation, DetailedErrorPresentation",
			BriefErrorDescription(Info), DetailErrorDescription(Info));
		
		DataExchangeXDTOServer.WriteToExecutionProtocol(ExchangeComponents, ErrorCode);
		DataExchangeXDTOServer.FinishKeepExchangeProtocol(ExchangeComponents);
		
		ExchangeComponents.ExchangeFile = Undefined;
		
		Raise ErrorCode.BriefErrorPresentation;
	EndTry;
	
	ExchangeComponents.ExchangeFile.Close();
	
	AddExchangeFinishEventLogMessage(ExchangeSettingsStructure, ExchangeComponents);
	
	If ExchangeComponents.ErrorFlag Then
		
		ErrorMessage = ExchangeComponents.ErrorMessageString;
		Raise ErrorMessage;
		
	Else
		
		// Put file in temporary storage.
		TempStorageFileID = String(DataExchangeServer.PutFileInStorage(FullFileName));
		
		// Creating the temporary directory for storing data file parts.
		TempDirectory                     = TemporaryExportDirectory(
			TempStorageFileID);
		SharedFileName               = CommonClientServer.GetFullFileName(
			TempDirectory, TempStorageFileID + ?(WebServiceParameters.FilePartSize > 0, ".zip", ".zip.1"));
		SourceFileNameInTemporaryDirectory = CommonClientServer.GetFullFileName(
			TempDirectory, "data.xml");
		
		CreateDirectory(TempDirectory);
		FileCopy(FullFileName, SourceFileNameInTemporaryDirectory);
		
		// Archiving the file.
		Archiver = New ZipFileWriter(SharedFileName);
		Archiver.Add(SourceFileNameInTemporaryDirectory);
		Archiver.Write();
		
		If WebServiceParameters.FilePartSize > 0 Then
			// Splitting a file into parts.
			FileNames = SplitFile(SharedFileName, WebServiceParameters.FilePartSize * 1024);
		Else
			FileNames = New Array();
			FileNames.Add(SharedFileName);
		EndIf;
		
		ReturnValue = "{WEBService}$%1$%2";
		ReturnValue = StringFunctionsClientServer.SubstituteParametersToString(ReturnValue, FileNames.Count(), TempStorageFileID);
		
		Message = New UserMessage();
		Message.Text = ReturnValue;
		Message.Message();
		
	EndIf;
	
EndProcedure

Procedure ImportXDTODateToInfobase(ProcedureParameters, StorageAddress) Export
	
	WebServiceParameters = ProcedureParameters["WebServiceParameters"];
	ErrorMessage   = ProcedureParameters["ErrorMessage"];
	
	SetPrivilegedMode(True);
	
	ExchangeComponents = ExchangeComponents("Get", WebServiceParameters);
	
	If ExchangeComponents.ErrorFlag Then
		ErrorMessage = ExchangeComponents.ErrorMessageString;
		Raise ErrorMessage;
	EndIf;
	
	ExchangeSettingsStructure = ExchangeSettingsStructure(ExchangeComponents, Enums.ActionsOnExchange.DataImport);
	
	DisableAccessKeysUpdate(True);
	Try
		DataExchangeXDTOServer.ReadData(ExchangeComponents);
	Except
		Information = ErrorInfo();
		ErrorMessage = NStr("ru = 'Ошибка при загрузке данных: %1'; en = 'Cannot import data: %1'; pl = 'Wystąpił błąd podczas importu danych: %1';de = 'Beim Importieren von Daten ist ein Fehler aufgetreten: %1';ro = 'Eroare la importul datelor: %1';tr = 'Veri içe aktarılırken bir hata oluştu:  %1'; es_ES = 'Ha ocurrido un error al importar los datos: %1'");
		ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorMessage,
			DetailErrorDescription(Information));
		DataExchangeXDTOServer.WriteToExecutionProtocol(ExchangeComponents, ErrorMessage, , , , , True);
		ExchangeComponents.ErrorFlag = True;
	EndTry;
	
	Try
		DataExchangeXDTOServer.DeleteTemporaryObjectsCreatedByRefs(ExchangeComponents);
	Except
		Information = ErrorInfo();
		ErrorMessage = NStr("ru = 'Ошибка при удалении временных объектов, созданных по ссылкам: %1'; en = 'Cannot delete temporary objects created by references: %1'; pl = 'Błąd podczas usuwania tymczasowych obiektów, utworzonych wg linków: %1';de = 'Fehler beim Löschen von temporären Objekten, die durch Links erstellt wurden: %1';ro = 'Eroare la ștergerea obiectelor temporare create conform referințelor: %1';tr = 'Referanslara göre oluşturulan geçici nesneler kaldırılırken bir hata oluştu: %1'; es_ES = 'Error al eliminar los objetos temporales creados por enlaces: %1'");
		ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorMessage,
			DetailErrorDescription(Information));
		DataExchangeXDTOServer.WriteToExecutionProtocol(ExchangeComponents, ErrorMessage, , , , , True);
		ExchangeComponents.ErrorFlag = True;
	EndTry;
	DisableAccessKeysUpdate(False);
	
	ExchangeComponents.ExchangeFile.Close();
	
	AddExchangeFinishEventLogMessage(ExchangeSettingsStructure, ExchangeComponents);
	
	If ExchangeComponents.ErrorFlag Then
		Raise ExchangeComponents.ErrorMessageString;
	EndIf;
	
	If Not ExchangeComponents.ErrorFlag 
		AND ExchangeComponents.IsExchangeViaExchangePlan
		AND ExchangeComponents.UseAcknowledgement Then
		
		// Writing information on the incoming message number.
		NodeObject = ExchangeComponents.CorrespondentNode.GetObject();
		NodeObject.ReceivedNo = ExchangeComponents.IncomingMessageNumber;
		NodeObject.AdditionalProperties.Insert("GettingExchangeMessage");
		NodeObject.Write();
		
	EndIf;
	
EndProcedure

Function TemporaryExportDirectory(Val SessionID) Export
	
	SetPrivilegedMode(True);
	
	TempDirectory = "{SessionID}";
	TempDirectory = StrReplace(TempDirectory, "SessionID", String(SessionID));
	
	Result = CommonClientServer.GetFullFileName(DataExchangeServer.TempFilesStorageDirectory(), TempDirectory);
	
	Return Result;
	
EndFunction

Procedure CheckCanSynchronizeData() Export
	
	If Not AccessRight("View", Metadata.CommonCommands.Synchronize) Then
		
		Raise NStr("ru = 'Недостаточно прав для синхронизации данных.'; en = 'Insufficient rights to synchronize data.'; pl = 'Niewystarczające uprawnienia do synchronizacji danych.';de = 'Unzureichende Rechte für die Datensynchronisierung.';ro = 'Drepturi insuficiente pentru sincronizarea datelor.';tr = 'Veri senkronizasyonu için yetersiz haklar.'; es_ES = 'Insuficientes derechos para sincronizar los datos.'");
		
	ElsIf InfobaseUpdate.InfobaseUpdateRequired()
		AND Not DataExchangeMessageImportModeBeforeStart("ImportPermitted") Then
		
		Raise NStr("ru = 'Информационная база находится в состоянии обновления.'; en = 'Infobase update is pending.'; pl = 'Baza informacyjna została zaktualizowana.';de = 'Infobase wird aktualisiert.';ro = 'Baza de informații este în curs de actualizare.';tr = 'Veritabanı güncelleniyor.'; es_ES = 'Infobase se está actualizando.'");
		
	EndIf;
	
EndProcedure

Procedure CheckInfobaseLockForUpdate() Export
	
	If ValueIsFilled(InfobaseUpdateInternal.InfobaseLockedForUpdate()) Then
		
		Raise NStr("ru = 'Синхронизация данных временно недоступна в связи с обновлением приложения.'; en = 'Data synchronization is temporarily unavailable due to the application update.'; pl = 'Synchronizacja danych tymczasowo jest niedostępna w związku z aktualizacją aplikacji.';de = 'Die Datensynchronisation ist aufgrund von Anwendungsaktualisierungen vorübergehend nicht möglich.';ro = 'Sincronizarea datelor nu este temporar disponibilă din cauza actualizării aplicației.';tr = 'Çevrimiçi uygulama güncellemesi nedeniyle veri senkronizasyonu geçici olarak kullanılamıyor.'; es_ES = 'La sincronización de datos no está disponible temporalmente debido a la actualización de la aplicación.'");
		
	EndIf;
	
EndProcedure

Function GetDataReceiptExecutionStatus(TimeConsumingOperationID, ErrorMessage) Export
	
	ErrorMessage = "";
	
	SetPrivilegedMode(True);
	BackgroundJob = BackgroundJobs.FindByUUID(New UUID(TimeConsumingOperationID));
	
	BackgroundJobStates = BackgroundJobsStatuses();
	If BackgroundJob = Undefined Then
		CurrentBackgroundJobStatus = BackgroundJobStates.Get(BackgroundJobState.Canceled);
	Else
		
		If BackgroundJob.ErrorInfo <> Undefined Then
			ErrorMessage = DetailErrorDescription(BackgroundJob.ErrorInfo);
		EndIf;
		CurrentBackgroundJobStatus = BackgroundJobStates.Get(BackgroundJob.State)
		
	EndIf;
	
	Return CurrentBackgroundJobStatus;
	
EndFunction

Function GetExecutionStatusOfPreparingDataForSending(BackgroundJobID, ErrorMessage) Export
	
	ErrorMessage = "";
	
	SetPrivilegedMode(True);
	
	ReturnedStructure = XDTOFactory.Create(
		XDTOFactory.Type("http://v8.1c.ru/SSL/Exchange/EnterpriseDataExchange", "PrepareDataOperationResult"));
	
	BackgroundJob = BackgroundJobs.FindByUUID(New UUID(BackgroundJobID));
	
	If BackgroundJob = Undefined Then
		CurrentBackgroundJobStatus = BackgroundJobsStatuses().Get(BackgroundJobState.Canceled);
	Else
	
		ErrorMessage        = "";
		FilePartsCount    = 0;
		FileID       = "";
		CurrentBackgroundJobStatus = BackgroundJobsStatuses().Get(BackgroundJob.State);
		
		If BackgroundJob.ErrorInfo <> Undefined Then
			ErrorMessage = DetailErrorDescription(BackgroundJob.ErrorInfo);
		Else
			If BackgroundJob.State = BackgroundJobState.Completed Then
				MessagesArray  = BackgroundJob.GetUserMessages(True);
				For Each BackgroundJobMessage In MessagesArray Do
					If StrFind(BackgroundJobMessage.Text, "{WEBService}") > 0 Then
						ResultArray = StrSplit(BackgroundJobMessage.Text, "$", True);
						FilePartsCount = ResultArray[1];
						FileID    = ResultArray[2];
						Break;
					Else
						Continue;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
	
	ReturnedStructure.ErrorMessage = ErrorMessage;
	ReturnedStructure.FileID       = FileID;
	ReturnedStructure.PartCount    = FilePartsCount;
	ReturnedStructure.Status       = CurrentBackgroundJobStatus;
	
	Return ReturnedStructure;
	
EndFunction

Function InitializeWebServiceParameters() Export
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("ExchangePlanName");
	ParametersStructure.Insert("ExchangePlanNodeCode");
	ParametersStructure.Insert("TempStorageFileID");
	ParametersStructure.Insert("FilePartSize");
	ParametersStructure.Insert("WEBServiceName");

	Return ParametersStructure;
	
EndFunction

Procedure DisableAccessKeysUpdate(Disable, ScheduleUpdate = True) Export
	
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.DisableAccessKeysUpdate(Disable, ScheduleUpdate);
	EndIf;
	
EndProcedure

Procedure PutMessageForDataMapping(ExchangeNode, MessageID) Export
	
	// Deleting the previous message for data mapping.
	Filter = New Structure("InfobaseNode", ExchangeNode);
	CommonSettings = InformationRegisters.CommonInfobasesNodesSettings.Get(Filter);
	
	If ValueIsFilled(CommonSettings.MessageForDataMapping) Then
		TempFileName = DataExchangeServer.GetFileFromStorage(CommonSettings.MessageForDataMapping);
		File = New File(TempFileName);
		If File.Exist() AND File.IsFile() Then
			Try
				DeleteFiles(TempFileName);
			Except
				// Returning file information to the temporary storage for further deletion via the scheduled job.
				// 
				DataExchangeServer.PutFileInStorage(TempFileName, CommonSettings.MessageForDataMapping);
			EndTry;
		EndIf;
	EndIf;
	
	InformationRegisters.CommonInfobasesNodesSettings.PutMessageForDataMapping(
		ExchangeNode, MessageID);
	
EndProcedure

#Region SerializationMethodsExchangeExecution

Function PredefinedDataTable() Export
	
	PredefinedItemsTable = New ValueTable;
	PredefinedItemsTable.Columns.Add("TableName");
	PredefinedItemsTable.Columns.Add("XMLTypeName");
	PredefinedItemsTable.Columns.Add("Ref");
	PredefinedItemsTable.Columns.Add("PredefinedDataName");
	
	MetadataKinds = New Array;
	MetadataKinds.Add(Metadata.Catalogs);
	MetadataKinds.Add(Metadata.ChartsOfCalculationTypes);
	MetadataKinds.Add(Metadata.ChartsOfCharacteristicTypes);
	MetadataKinds.Add(Metadata.ChartsOfAccounts);
	
	QueriesPackage = New Array;
	TablesCounter = 0;
	QueryText  = "";
	
	For Each MetadataKind In MetadataKinds Do
		
		For Each CurrentMetadata In MetadataKind Do
			
			If TablesCounter = 256 Then
				QueriesPackage.Add(New Query(QueryText));
				
				TablesCounter = 0;
				QueryText  = "";
			EndIf;
			
			TablesCounter = TablesCounter + 1;
			
			If TablesCounter > 1 Then
				QueryText = QueryText + "				
				|UNION ALL";
			EndIf;
			
			QueryText = QueryText + StrReplace("
				|SELECT
				|	""#TableName"" AS TableName,
				|	T.Ref AS Ref,
				|	T.PredefinedDataName AS PredefinedDataName
				|FROM
				|	#TableName AS T
				|WHERE
				|	T.PredefinedDataName <> """"",
				"#TableName",
				CurrentMetadata.FullName());
				
		EndDo;
			
	EndDo;
	
	If TablesCounter > 1 Then
		QueriesPackage.Add(New Query(QueryText));
	EndIf;
	
	For Each CurrentQuery In QueriesPackage Do
		
		Selection = CurrentQuery.Execute().Select();
		While Selection.Next() Do
			PredefinedItemsRow = PredefinedItemsTable.Add();
			FillPropertyValues(PredefinedItemsRow, Selection);
			PredefinedItemsRow.XMLTypeName = XMLTypeOf(PredefinedItemsRow.Ref).TypeName;
		EndDo;
		Selection = Undefined;
		
	EndDo;
	
	Return PredefinedItemsTable;
	
EndFunction

Procedure MarkRefsToPredefinedData(Data, PredefinedItemsTable) Export
	
	If Data = Undefined
		Or TypeOf(Data) = Type("ObjectDeletion") Then
		Return;
	Else
		ObjectMetadata = Data.Metadata();
		
		If Common.IsConstant(ObjectMetadata) Then
			
			CheckMarkPredefineditemsRef(Data.Value, PredefinedItemsTable);
			
		ElsIf Common.IsRefTypeObject(ObjectMetadata) Then
			
			CollectionsArray = New Array;
			CollectionsArray.Add(ObjectMetadata.Attributes);
			CollectionsArray.Add(ObjectMetadata.StandardAttributes);
			
			If Common.IsTask(ObjectMetadata) Then
				CollectionsArray.Add(ObjectMetadata.AddressingAttributes);
			EndIf;
			
			CheckMarkPredefinedItemsRefInObjectAttributesCollection(Data, CollectionsArray, PredefinedItemsTable);
			
			For Each TabularSection In ObjectMetadata.TabularSections Do
				CheckMarkPredefinedItemsRefInDataTable(Data[TabularSection.Name].Unload(), PredefinedItemsTable);
			EndDo;
			
			If Common.IsChartOfAccounts(ObjectMetadata)
				Or Common.IsChartOfCalculationTypes(ObjectMetadata) Then
				For Each TabularSection In ObjectMetadata.StandardTabularSections Do
					CheckMarkPredefinedItemsRefInDataTable(Data[TabularSection.Name].Unload(), PredefinedItemsTable);
				EndDo;
			EndIf;
			
		ElsIf Common.IsRegister(ObjectMetadata) Then
			
			CheckMarkPredefinedItemsRefInDataTable(Data.Unload(), PredefinedItemsTable);
			
		EndIf;
	EndIf;
	
EndProcedure

Procedure ReplaceRefsToPredefinedItems(Data, PredefinedItemsTable) Export
	
	If Data = Undefined
		Or TypeOf(Data) = Type("ObjectDeletion") Then
		Return;
	Else
		ObjectMetadata = Data.Metadata();
		
		If Common.IsConstant(ObjectMetadata) Then
			
			CheckReplacePredefinedItemRefInObjectAttribute(Data, "Value", PredefinedItemsTable);
			
		ElsIf Common.IsRefTypeObject(ObjectMetadata) Then
			
			ProcessPredefinedItemImport(Data, PredefinedItemsTable);
			
			CollectionsArray = New Array;
			CollectionsArray.Add(ObjectMetadata.Attributes);
			CollectionsArray.Add(ObjectMetadata.StandardAttributes);
			
			If Common.IsTask(ObjectMetadata) Then
				CollectionsArray.Add(ObjectMetadata.AddressingAttributes);
			EndIf;
			
			CheckReplacePredefinedItemsRefInObjectAttributesCollection(Data, CollectionsArray, PredefinedItemsTable);
			
			For Each TabularSection In ObjectMetadata.TabularSections Do
				CheckReplacePredefinedItemsRefInDataTable(Data[TabularSection.Name], PredefinedItemsTable);
			EndDo;
			
			If Common.IsChartOfAccounts(ObjectMetadata)
				Or Common.IsChartOfCalculationTypes(ObjectMetadata) Then
				For Each TabularSection In ObjectMetadata.StandardTabularSections Do
					CheckReplacePredefinedItemsRefInDataTable(Data[TabularSection.Name], PredefinedItemsTable);
				EndDo;
			EndIf;
			
		ElsIf Common.IsRegister(ObjectMetadata) Then
			
			CheckReplacePredefinedItemsRefInDataTable(Data, PredefinedItemsTable);
			
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

Function ExchangeComponents(ExchangeDirection, WebServiceParameters)
	
	ExchangeComponents = DataExchangeXDTOServer.InitializeExchangeComponents(ExchangeDirection);
	
	If ValueIsFilled(WebServiceParameters.ExchangePlanName) AND ValueIsFilled(WebServiceParameters.ExchangePlanNodeCode) Then
		ExchangeComponents.CorrespondentNode = ExchangePlans[WebServiceParameters.ExchangePlanName].FindByCode(WebServiceParameters.ExchangePlanNodeCode);
	Else
		ExchangeComponents.IsExchangeViaExchangePlan = False;
	EndIf;
	
	ExchangeComponents.KeepDataProtocol.OutputInfoMessagesToProtocol = False;
	ExchangeComponents.DataExchangeState.StartDate = CurrentSessionDate();
	ExchangeComponents.UseTransactions = False;

	If ExchangeDirection = "Get" Then
		
		ExchangeComponents.EventLogMessageKey = GenerateEventLogMessageKey(ExchangeDirection, WebServiceParameters);
		
		FileName = DataExchangeServer.GetFileFromStorage(WebServiceParameters.TempStorageFileID);
		DataExchangeXDTOServer.OpenImportFile(ExchangeComponents, FileName);
		
	Else
		
		ExchangeComponents.EventLogMessageKey   = GenerateEventLogMessageKey(ExchangeDirection, WebServiceParameters);
		ExchangeComponents.ExchangeFormatVersion               = DataExchangeXDTOServer.ExchangeFormatVersionOnImport(
			ExchangeComponents.CorrespondentNode);
		ExchangeComponents.XMLSchema                          = DataExchangeXDTOServer.ExchangeFormat(
			WebServiceParameters.ExchangePlanName, ExchangeComponents.ExchangeFormatVersion);
		ExchangeComponents.ExchangeManager                    = DataExchangeXDTOServer.FormatVersionExchangeManager(
			ExchangeComponents.ExchangeFormatVersion, ExchangeComponents.CorrespondentNode);
		ExchangeComponents.ObjectsRegistrationRulesTable = DataExchangeXDTOServer.ObjectsRegistrationRules(
			ExchangeComponents.CorrespondentNode);
		ExchangeComponents.ExchangePlanNodeProperties           = DataExchangeXDTOServer.ExchangePlanNodeProperties(
			ExchangeComponents.CorrespondentNode);
		
	EndIf;
	
	If ExchangeComponents.ErrorFlag Then
		Return ExchangeComponents;
	EndIf;
	
	DataExchangeXDTOServer.InitializeExchangeRulesTables(ExchangeComponents);
	
	If ExchangeComponents.IsExchangeViaExchangePlan Then
		DataExchangeXDTOServer.FillXDTOSettingsStructure(ExchangeComponents);
		DataExchangeXDTOServer.FillSupportedXDTODataObjects(ExchangeComponents);
	EndIf;
	
	Return ExchangeComponents;
	
EndFunction

Function GetFilePartName(FilePartNumber, ArchiveName = "")
	
	If Not ValueIsFilled(ArchiveName) Then
		ArchiveName = "data";
	EndIf;
	
	Result = StringFunctionsClientServer.SubstituteParametersToString("%1.zip.%2", ArchiveName, Format(FilePartNumber, "NG=0"));
	
	Return Result;
	
EndFunction

Function BackgroundJobsStatuses()
	
	BackgroundJobStates = New Map;
	BackgroundJobStates.Insert(BackgroundJobState.Active,           "Active");
	BackgroundJobStates.Insert(BackgroundJobState.Completed,         "Completed");
	BackgroundJobStates.Insert(BackgroundJobState.Failed, "Failed");
	BackgroundJobStates.Insert(BackgroundJobState.Canceled,          "Canceled");
	
	Return BackgroundJobStates;
	
EndFunction

Function GenerateEventLogMessageKey(ExchangeDirection, WebServiceParameters)
	
	If ExchangeDirection = "Get" Then
		MessageKeyTemplate = NStr("ru = 'Загрузка данных через Web-сервис %1'; en = 'Import data over web service %1'; pl = 'Pobieranie danych poprzez Web-serwis %1';de = 'Daten-Import über den Webservice %1';ro = 'Încărcarea datelor prin Web-service %1';tr = 'Verilerin Web-hizmet üzerinden içe aktarılması%1'; es_ES = 'Descarga de datos a través el servidor Web %1'", Common.DefaultLanguageCode());
	Else
		MessageKeyTemplate = NStr("ru = 'Выгрузка данных через Web-сервис %1'; en = 'Export data over web service %1'; pl = 'Pobieranie danych poprzez Web-serwis %1';de = 'Daten-Export über den Webservice %1';ro = 'Descărcarea datelor prin Web-service %1';tr = 'Verilerin Web-hizmet üzerinden dışa aktarılması%1'; es_ES = 'Subida de datos a través el servidor Web %1'", Common.DefaultLanguageCode());
	EndIf;
	
	Return StringFunctionsClientServer.SubstituteParametersToString(MessageKeyTemplate, WebServiceParameters.WEBServiceName);
	
EndFunction

Function ExchangeSettingsStructure(ExchangeComponents, DataExchangeAction)
	
	If Not ExchangeComponents.IsExchangeViaExchangePlan Then
		Return Undefined;
	EndIf;
	
	ExchangeSettingsStructure = DataExchangeServer.ExchangeSettingsForInfobaseNode(
		ExchangeComponents.CorrespondentNode, DataExchangeAction, Undefined, False);
		
	If ExchangeSettingsStructure.Cancel Then
		ErrorMessageString = NStr("ru = 'Ошибка при инициализации процесса обмена данными.'; en = 'Cannot initialize data exchange.'; pl = 'Podczas inicjowania procesu wymiany danych wystąpił błąd.';de = 'Bei der Initialisierung des Datenaustauschprozesses ist ein Fehler aufgetreten.';ro = 'Eroare la inițializarea procesului schimbului de date.';tr = 'Veri alışverişi sürecini başlatırken bir hata oluştu.'; es_ES = 'Ha ocurrido un error al iniciar el proceso de intercambio de datos.'");
		DataExchangeServer.AddExchangeCompletionEventLogMessage(ExchangeSettingsStructure);
		Raise ErrorMessageString;
	EndIf;
	
	ExchangeSettingsStructure.ExchangeExecutionResult = Undefined;
	ExchangeSettingsStructure.StartDate = CurrentSessionDate();
	
	MessageString = NStr("ru = 'Начало процесса обмена данными для узла %1'; en = 'Data exchange for node %1 started.'; pl = 'Początek procesu wymiany danych dla węzła %1';de = 'Datenaustausch beginnt für Knoten %1';ro = 'Începutul procesului schimbului de date pentru nodul %1';tr = '%1Ünite için veri değişimi süreci başlatılıyor'; es_ES = 'Inicio de proceso de intercambio de datos para el nodo %1'", Common.DefaultLanguageCode());
	MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, ExchangeSettingsStructure.InfobaseNodeDescription);
	
	WriteLogEvent(ExchangeSettingsStructure.EventLogMessageKey, 
		EventLogLevel.Information,
		ExchangeSettingsStructure.InfobaseNode.Metadata(),
		ExchangeSettingsStructure.InfobaseNode,
		MessageString);
		
	Return ExchangeSettingsStructure;
	
EndFunction

Procedure AddExchangeFinishEventLogMessage(ExchangeSettingsStructure, ExchangeComponents)
	
	If Not ExchangeComponents.IsExchangeViaExchangePlan Then
		Return;
	EndIf;
	
	ExchangeSettingsStructure.ExchangeExecutionResult    = ExchangeComponents.DataExchangeState.ExchangeExecutionResult;
	
	If ExchangeSettingsStructure.ActionOnExchange = Enums.ActionsOnExchange.DataExport Then
		ExchangeSettingsStructure.ProcessedObjectsCount = ExchangeComponents.ExportedObjectCounter;
		ExchangeSettingsStructure.MessageOnExchange           = ExchangeSettingsStructure.DataExchangeDataProcessor.CommentOnDataExport;
	ElsIf ExchangeSettingsStructure.ActionOnExchange = Enums.ActionsOnExchange.DataImport Then
		ExchangeSettingsStructure.ProcessedObjectsCount = ExchangeComponents.ImportedObjectCounter;
		ExchangeSettingsStructure.MessageOnExchange           = ExchangeSettingsStructure.DataExchangeDataProcessor.CommentOnDataImport;
	EndIf;
	
	ExchangeSettingsStructure.ErrorMessageString      = ExchangeComponents.ErrorMessageString;
	
	DataExchangeServer.AddExchangeCompletionEventLogMessage(ExchangeSettingsStructure);
	
EndProcedure

#Region SerializationMethodsExchangeExecution

Procedure CheckMarkPredefineditemsRef(Value, PredefinedItemsTable)
	
	If Not Common.IsReference(TypeOf(Value)) Then
		Return;
	EndIf;
	
	PredefinedItemsRow = PredefinedItemsTable.Find(Value, "Ref");
	If PredefinedItemsRow = Undefined Then
		// Value is not a predeifined item.
		Return;
	EndIf;
	
	If Not PredefinedItemsRow.ExportData Then
		PredefinedItemsRow.ExportData = True;
	EndIf;
	
EndProcedure

Procedure CheckMarkPredefinedItemsRefInObjectAttributesCollection(Data, CollectionsArray, PredefinedItemsTable)
	
	For Each AttributesCollection In CollectionsArray Do
		For Each Attribute In AttributesCollection Do
			CheckMarkPredefineditemsRef(Data[Attribute.Name], PredefinedItemsTable);
		EndDo;
	EndDo;
	
EndProcedure

Procedure CheckMarkPredefinedItemsRefInDataTable(TableData, PredefinedItemsTable)
	
	For Each TableRow In TableData Do
		For Each Column In TableData.Columns Do
			CheckMarkPredefineditemsRef(TableRow[Column.Name], PredefinedItemsTable);
		EndDo;
	EndDo;
	
EndProcedure

Procedure ProcessPredefinedItemImport(Data, PredefinedItemsTable)
	
	OriginalDataRef = Data.Ref;
	If Data.IsNew() Then
		OriginalDataRef = Data.GetNewObjectRef();
	EndIf;
	
	RowPredefined = PredefinedItemsTable.Find(OriginalDataRef, "SourceRef");
	If RowPredefined = Undefined Then
		Return;
	EndIf;
	
	DataForImport = RowPredefined.Ref.GetObject();
	ObjectMetadata = DataForImport.Metadata();
	
	CollectionsArray = New Array;
	CollectionsArray.Add(ObjectMetadata.Attributes);
	CollectionsArray.Add(ObjectMetadata.StandardAttributes);
	
	If Common.IsTask(ObjectMetadata) Then
		CollectionsArray.Add(ObjectMetadata.AddressingAttributes);
	EndIf;
	
	TransferAttributesCollectionValuesBetweenObjects(Data, DataForImport, CollectionsArray);
	
	For Each TabularSection In ObjectMetadata.TabularSections Do
		If Data[TabularSection.Name].Count() > 0
			Or DataForImport[TabularSection.Name].Count() > 0 Then
			DataForImport[TabularSection.Name].Load(Data[TabularSection.Name].Unload());
		EndIf;
	EndDo;
	
	If Common.IsChartOfAccounts(ObjectMetadata)
		Or Common.IsChartOfCalculationTypes(ObjectMetadata) Then
		For Each TabularSection In ObjectMetadata.StandardTabularSections Do
			If Data[TabularSection.Name].Count() > 0
				Or DataForImport[TabularSection.Name].Count() > 0 Then
				DataForImport[TabularSection.Name].Load(Data[TabularSection.Name].Unload());
			EndIf;
		EndDo;
	EndIf;
			
	Data = DataForImport;
	
EndProcedure

Procedure TransferAttributesCollectionValuesBetweenObjects(Source, Target, CollectionsArray)
	
	For Each AttributesCollection In CollectionsArray Do
		For Each Attribute In AttributesCollection Do
			If Target[Attribute.Name] = Target.Ref Then
				Continue;
			EndIf;
			If Target[Attribute.Name] = Source[Attribute.Name] Then
				Continue;
			EndIf;
			Target[Attribute.Name] = Source[Attribute.Name];
		EndDo;
	EndDo;
	
EndProcedure

Procedure CheckReplacePredefinedItemRefInObjectAttribute(Data, AttributeName, PredefinedItemsTable)
	
	Value = Data[AttributeName];
	
	If Not Common.IsReference(TypeOf(Value)) Then
		Return;
	EndIf;
	
	RowPredefined = PredefinedItemsTable.Find(Value, "SourceRef");
	If Not RowPredefined = Undefined Then
		Data[AttributeName] = RowPredefined.Ref;
	EndIf;
	
EndProcedure

Procedure CheckReplacePredefinedItemsRefInObjectAttributesCollection(Data, CollectionsArray, PredefinedItemsTable)
	
	For Each AttributesCollection In CollectionsArray Do
		For Each Attribute In AttributesCollection Do
			CheckReplacePredefinedItemRefInObjectAttribute(Data, Attribute.Name, PredefinedItemsTable);
		EndDo;
	EndDo;
	
EndProcedure

Procedure CheckReplacePredefinedItemsRefInDataTable(TableData, PredefinedItemsTable)
	
	If TableData.Count() = 0 Then
		Return;
	EndIf;
	
	TableTS = TableData.Unload();
	
	For Each TSDataTable In TableData Do
		For Each Column In TableTS.Columns Do
			If Not CommonClientServer.HasAttributeOrObjectProperty(TSDataTable, Column.Name) Then
				Continue;
			EndIf;
			CheckReplacePredefinedItemRefInObjectAttribute(TSDataTable, Column.Name, PredefinedItemsTable);
		EndDo;
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion