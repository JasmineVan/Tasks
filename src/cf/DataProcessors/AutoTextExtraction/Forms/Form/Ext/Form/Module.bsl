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
	
	If Common.IsWebClient() Or Not Common.IsWindowsClient() Then
		Return; // Cancel is set in OnOpen().
	EndIf;
	
	TextExtractionEnabled = False;
	
	ExecutionTimeInterval = Common.CommonSettingsStorageLoad("AutoTextExtraction", "ExecutionTimeInterval");
	If ExecutionTimeInterval = 0 Then
		ExecutionTimeInterval = 60;
		Common.CommonSettingsStorageSave("AutoTextExtraction", "ExecutionTimeInterval",  ExecutionTimeInterval);
	EndIf;
	
	FileCountInBlock = Common.CommonSettingsStorageLoad("AutoTextExtraction", "FileCountInBlock");
	If FileCountInBlock = 0 Then
		FileCountInBlock = 100;
		Common.CommonSettingsStorageSave("AutoTextExtraction", "FileCountInBlock",  FileCountInBlock);
	EndIf;
	
	Items.UnextractedTextFilesCountInfo.Title = StatusTextCalculation();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Not TextsExtractionAvailable() Then
		Cancel = True;
		MessageText = NStr("ru = 'Извлечение текстов поддерживается только в клиенте под управлением ОС Windows.'; en = 'Text extraction is only available in the Windows client.'; pl = 'Ekstrakcja tekstu jest obsługiwana tylko na kliencie SO Windows.';de = 'Die Textextraktion wird nur in dem Client unter Windows unterstützt.';ro = 'Extragerea textelor este susținută numai pe clientul gestionat de SO Windows.';tr = 'Metin çıkarma yalnızca Windows tabanlı bir istemcide desteklenir.'; es_ES = 'Se admite la extracción de texto solo en el cliente bajo OS Windows.'");
		ShowMessageBox(, MessageText);
		Return;
	EndIf;
	
	UpdateInformationOnFilesWithNonExtractedTextCount();
	
EndProcedure

&AtClient
Procedure ExecutionTimeIntervalOnChange(Item)
	
	CommonServerCall.CommonSettingsStorageSave("AutoTextExtraction", "ExecutionTimeInterval",  ExecutionTimeInterval);
	
	If TextExtractionEnabled Then
		DetachIdleHandler("TextExtractionClientHandler");
		ExpectedExtractionStartTime = CommonClient.SessionDate() + ExecutionTimeInterval;
		AttachIdleHandler("TextExtractionClientHandler", ExecutionTimeInterval);
		CountdownUpdate();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FileCountInBlockOnChange(Item)
	CommonServerCall.CommonSettingsStorageSave("AutoTextExtraction", "FileCountInBlock",  FileCountInBlock);
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Start(Command)
	
	TextExtractionEnabled = True; 
	
	ExpectedExtractionStartTime = CommonClient.SessionDate();
	AttachIdleHandler("TextExtractionClientHandler", ExecutionTimeInterval);
	
#If NOT WebClient AND NOT MobileClient Then
	TextExtractionClientHandler();
#EndIf
	
	AttachIdleHandler("CountdownUpdate", 1);
	CountdownUpdate();
	
EndProcedure

&AtClient
Procedure Stop(Command)
	ExecuteStop();
EndProcedure

&AtClient
Procedure ExtractAll(Command)
	
	#If NOT WebClient AND NOT MobileClient Then
		UnextractedTextFileCountBeforeOperation = UnextractedTextFileCount;
		Status = "";
		BatchSize = 0; // extract all
		TextExtractionClient(BatchSize);
		
		ShowMessageBox(, StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru='Завершено извлечение текста из
			         |всех файлов с неизвлеченным текстом.
			         |
			         |Обработано файлов: %1.'; 
			         |en = 'Extracting text from all files
			         |with extraction pending is completed.
			         |
			         | Files processed: %1.'; 
			         |pl = 'Wyodrębnianie tekstu
			         |ze wszystkich plików bez tekstu wyodrębnionego zostało zakończone. 
			         |
			         |Liczba przetworzonych plików: %1.';
			         |de = 'Die Textextraktion aus
			         |allen Dateien, die keinen Text extrahieren, ist abgeschlossen.
			         |
			         |Anzahl der verarbeiteten Dateien: %1.';
			         |ro = 'Extragerea textului din
			         |toate fișierele fără text extras este completă.
			         |
			         |Număr de fișiere prelucrate: %1.';
			         |tr = 'Metin ayıklamayan tüm dosyalardan
			         | metin çıkarımı tamamlandı.
			         |
			         | İşlenen dosyaların sayısı:%1.'; 
			         |es_ES = 'Extracción de texto desde
			         |todos los archivos con el no extraer el texto se ha finalizado.
			         |
			         |Número de los archivos procesados: %1.'"),
			UnextractedTextFileCountBeforeOperation));
	#EndIf
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Function TextsExtractionAvailable()
	
#If WebClient Or MobileClient Then
	Return False;
#Else
	Return CommonClient.IsWindowsClient();
#EndIf
	
EndFunction

&AtClientAtServerNoContext
Function StatusTextCalculation()
	Return NStr("ru = 'Поиск файлов с неизвлеченным текстом...'; en = 'Searching for files with text extraction pending...'; pl = 'Wyszukiwanie plików z niepobranym tekstem...';de = 'Suchen nach Dateien mit nicht extrahiertem Text...';ro = 'Căutarea fișierelor cu text ne extras...';tr = 'Çıkarılmamış metne sahip dosyalar aranıyor...'; es_ES = 'Búsqueda de archivo con texto no extraído...'");
EndFunction

&AtClient
Procedure UpdateInformationOnFilesWithNonExtractedTextCount()
	
	DetachIdleHandler("StartUpdateInformationOnFileCountWithUnextractedText");
	If CurrentBackgroundJob = "Calculation" AND ValueIsFilled(BackgroundJobID) Then
		CancelBackgroundJob();
	EndIf;
	AttachIdleHandler("StartUpdateInformationOnFileCountWithUnextractedText", 2, True);
	
EndProcedure

&AtClient
Procedure CheckBackgroundJobExecution()
	If ValueIsFilled(BackgroundJobID) AND Not JobCompleted(BackgroundJobID) Then
		AttachIdleHandler("CheckBackgroundJobExecution", 5, True);
	Else
		BackgroundJobID = "";
		If CurrentBackgroundJob = "Calculation" Then
			OutputInformationOnNonExtractedTextFilesCount();
			Return;
		EndIf;
		CurrentBackgroundJob = "";
		UpdateInformationOnFilesWithNonExtractedTextCount();
	EndIf;
EndProcedure

&AtClient
Procedure CancelBackgroundJob()
	CancelJobExecution(BackgroundJobID);
	DetachIdleHandler("CheckBackgroundJobExecution");
	CurrentBackgroundJob = "";
	BackgroundJobID = "";
EndProcedure

&AtServerNoContext
Function JobCompleted(BackgroundJobID)
	Return TimeConsumingOperations.JobCompleted(BackgroundJobID);
EndFunction

&AtServerNoContext
Procedure CancelJobExecution(BackgroundJobID)
	If ValueIsFilled(BackgroundJobID) Then 
		TimeConsumingOperations.CancelJobExecution(BackgroundJobID);
	EndIf;
EndProcedure

&AtClient
Procedure StartUpdateInformationOnFileCountWithUnextractedText()
	
	If ValueIsFilled(BackgroundJobID) Then
		Items.UnextractedTextFilesCountInfo.Title = StatusTextCalculation();
		Return;
	EndIf;
	
	Items.UnextractedTextFilesCountInfo.Title = StatusTextCalculation();
	TimeConsumingOperation = ExecuteSearchOfFilesWIthNonExtractedText();
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow = False;
	
	NotifyDescription = New NotifyDescription("OnCompleteUpdateUnextractedTextFilesCountInformation", ThisObject);
	TimeConsumingOperationsClient.WaitForCompletion(TimeConsumingOperation, NotifyDescription, IdleParameters);
	
EndProcedure

&AtClient
Procedure OnCompleteUpdateUnextractedTextFilesCountInformation(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		EventLogClient.AddMessageForEventLog(NStr("ru = 'Поиск файлов с неизвлеченным текстом'; en = 'Search of files with text extraction pending'; pl = 'Wyszukiwanie plików z niepobranym tekstem';de = 'Suchen nach Dateien mit nicht extrahiertem Text';ro = 'Căutarea fișierelor cu text ne extras';tr = 'Çıkarılmamış metne sahip dosyalar aranıyor'; es_ES = 'Búsqueda de archivo con texto no extraído'", CommonClient.DefaultLanguageCode()),
			"Error", Result.DetailedErrorPresentation, , True);
		Raise Result.BriefErrorPresentation;
	EndIf;

	BackgroundJobID = "";
	OutputInformationOnNonExtractedTextFilesCount();
	
EndProcedure

&AtClient
Procedure OutputInformationOnNonExtractedTextFilesCount()
	
	UnextractedTextFilesCountInfo = GetFromTempStorage(ResultAddress);
	If UnextractedTextFilesCountInfo = Undefined Then
		Return;
	EndIf;
	
	UnextractedTextFileCount = UnextractedTextFilesCountInfo;
	
	If UnextractedTextFileCount > 0 Then
		Items.UnextractedTextFilesCountInfo.Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Количество файлов с неизвлеченным текстом: %1'; en = 'Files with text extraction pending: %1'; pl = 'Ilość plików z nieodzyskanym tekstem: %1';de = 'Anzahl der Dateien mit nicht extrahiertem Text: %1';ro = 'Numărul de fișiere cu text ne extras: %1';tr = 'Çıkarılmamış metne sahip dosya sayısı: %1'; es_ES = 'Cantidad de archivos con texto no extraído: %1'"),
			UnextractedTextFileCount);
	Else
		Items.UnextractedTextFilesCountInfo.Title = NStr("ru = 'Количество файлов с неизвлеченным текстом: нет'; en = 'Files with text extraction pending: None'; pl = 'Ilość plików z nieodzyskanym tekstem: Nie';de = 'Anzahl der Dateien mit nicht extrahiertem Text: keine';ro = 'Numărul de fișiere cu text ne extras: lipsesc';tr = 'Çıkarılmamış metne sahip dosya sayısı: yok'; es_ES = 'Cantidad de archivos con texto no extraído: no hay'");
	EndIf;
	
EndProcedure

&AtServer
Function ExecuteSearchOfFilesWIthNonExtractedText()
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("ru = 'Поиск файлов с неизвлеченным текстом.'; en = 'Search for files with text extraction pending.'; pl = 'Wyszukaj pliki z nieodzyskanym tekstem.';de = 'Suchen nach Dateien mit nicht extrahiertem Text.';ro = 'Căutarea fișierelor cu text ne extras.';tr = 'Çıkarılmamış metne sahip dosyalar aranıyor.'; es_ES = 'Búsqueda de archivo con texto no extraído.'");
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground("FilesOperationsInternal.GetUnextractedTextVersionCount", New Structure, ExecutionParameters);
	CurrentBackgroundJob = "Calculation";
	BackgroundJobID = TimeConsumingOperation.JobID;
	ResultAddress = TimeConsumingOperation.ResultAddress;
	
	Return TimeConsumingOperation;
	
EndFunction

&AtServerNoContext
Procedure EventLogRecordServer(MessageText)
	
	WriteLogEvent(
		NStr("ru = 'Файлы.Извлечение текста'; en = 'Files.Extract text'; pl = 'Pliki. Ekstrakcja tekstu';de = 'Dateien. Text extrahieren';ro = 'Fișiere.Extragerea textului';tr = 'Dosyalar. Metin özütleme'; es_ES = 'Archivos.Extracción del texto'",
		     Common.DefaultLanguageCode()),
		EventLogLevel.Error,
		,
		,
		MessageText);
	
EndProcedure

&AtClient
Procedure CountdownUpdate()
	
	Left = ExpectedExtractionStartTime - CommonClient.SessionDate();
	
	MessageText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'До начала извлечения текстов осталось %1 сек'; en = 'Text extraction starts in %1 sec'; pl = 'Do początku wyciągania tekstów pozostało %1 sek';de = '%1 Sekunden vor Beginn der Textextraktion';ro = '%1 sec înainte de începerea extracției textului';tr = '%1 metin çıkarımı başlamadan önce '; es_ES = '%1 segundos antes del inicio de la extracción de texto'"),
		Left);
	
	If Left <= 1 Then
		MessageText = "";
	EndIf;
	
	ExecutionTimeInterval = Items.ExecutionTimeInterval.EditText;
	Status = MessageText;
	
EndProcedure

&AtClient
Procedure TextExtractionClientHandler()
	
#If NOT WebClient AND NOT MobileClient Then
	TextExtractionClient();
#EndIf

EndProcedure

#If Not WebClient AND Not MobileClient Then
	
	// Extracts text from files on the hard drive on the client.
&AtClient
Procedure TextExtractionClient(BatchSize = Undefined)
	
	ExpectedExtractionStartTime = CommonClient.SessionDate() + ExecutionTimeInterval;
	
	Try
		
		PortionSizeCurrent = FileCountInBlock;
		If BatchSize <> Undefined Then
			PortionSizeCurrent = BatchSize;
		EndIf;
		FilesArray = GetFilesForTextExtraction(PortionSizeCurrent);
		
		If FilesArray.Count() = 0 Then
			ShowUserNotification(NStr("ru = 'Извлечение текстов'; en = 'Extract text'; pl = 'Pobieranie tekstu';de = 'Text extraktion';ro = 'Extragerea de text';tr = 'Metin çıkarma'; es_ES = 'Extracción de texto'"),, NStr("ru = 'Нет файлов для извлечения текста'; en = 'No files for text extraction.'; pl = 'Nie ma plików dla wyciągania tekstu';de = 'Es gibt keine Dateien, um den Text zu extrahieren';ro = 'Nu există fișiere pentru extragerea textului';tr = 'Metni çıkarılacak dosya yok'; es_ES = 'No hay archivos para extraer el texto'"));
			Return;
		EndIf;
		
		For Index = 0 To FilesArray.Count() - 1 Do
			
			Extension = FilesArray[Index].Extension;
			FileDescription = FilesArray[Index].Description;
			FileOrFileVersion = FilesArray[Index].Ref;
			Encoding = FilesArray[Index].Encoding;
			
			Try
				FileAddress = GetFileURL(
					FileOrFileVersion, UUID);
				
				NameWithExtension = CommonClientServer.GetNameWithExtension(
					FileDescription, Extension);
				
				Progress = Index * 100 / FilesArray.Count();
				Status(NStr("ru = 'Идет извлечение текста файла'; en = 'Extracting text from files'; pl = 'Idzie wyciąganie tekstu plika';de = 'Extrahieren von Dateitext';ro = 'Extragerea textului fișierului';tr = 'Dosya metnini çıkarma'; es_ES = 'Extrayendo el texto del archivo'"), Progress, NameWithExtension);
				
				FilesOperationsInternalClient.ExtractVersionText(
					FileOrFileVersion, FileAddress, Extension, UUID, Encoding);
			
			Except
				
				ErrorDescriptionInfo = BriefErrorDescription(ErrorInfo());
				
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Во время извлечения текста из файла ""%1""
					           |произошла неизвестная ошибка.'; 
					           |en = 'An unknown error occurred while
					           |extracting text from file ""%1"".'; 
					           |pl = 'Wystąpił nieznany błąd podczas wyodrębniania tekstu z pliku ""%1""
					           |wystąpił nieznany błąd.';
					           |de = 'Beim Extrahieren von Text aus der Datei ""%1""
					           |ist ein unbekannter Fehler aufgetreten.';
					           |ro = 'A apărut o eroare necunoscută în timpul extragerii textului din fișierul ""%1""
					           |.';
					           |tr = '"" %1 "" 
					           |adlı dosyadan metin çıkarılırken bilinmeyen bir hata oluştu.'; 
					           |es_ES = 'Ha ocurrido un error desconocido al extraer el texto desde el archivo ""%1""
					           |.'"),
					String(FileOrFileVersion));
				
				MessageText = MessageText + String(ErrorDescriptionInfo);
				
				Status(MessageText);
				
				ExtractionResult = "FailedExtraction";
				ExtractionErrorRecord(FileOrFileVersion, ExtractionResult, MessageText);
				
			EndTry;
			
		EndDo;
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Извлечение текста завершено.
			           |Обработано файлов: %1'; 
			           |en = 'Text extraction completed.
			           |Files processed: %1'; 
			           |pl = 'Wyodrębnianie tekstu zostało zakończone.
			           |Liczba przetworzonych plików: %1';
			           |de = 'Die Textextraktion ist abgeschlossen.
			           |Anzahl der verarbeiteten Dateien: %1';
			           |ro = 'Extragerea textului este finalizată.
			           |Număr de fișiere procesate: %1';
			           |tr = 'Metin çıkarımı tamamlandı. 
			           |İşlenen dosya sayısı:%1'; 
			           |es_ES = 'Extracción del texto se ha finalizado.
			           |Número de archivos procesados: %1'"),
			FilesArray.Count());
		
		ShowUserNotification(NStr("ru = 'Извлечение текстов'; en = 'Extract text'; pl = 'Pobieranie tekstu';de = 'Text extraktion';ro = 'Extragerea de text';tr = 'Metin çıkarma'; es_ES = 'Extracción de texto'"),, MessageText);
		
	Except
		
		ErrorDescriptionInfo = BriefErrorDescription(ErrorInfo());
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Во время извлечения текста из файла ""%1""
			           |произошла неизвестная ошибка.'; 
			           |en = 'An unknown error occurred while
			           |extracting text from file ""%1"".'; 
			           |pl = 'Wystąpił nieznany błąd podczas wyodrębniania tekstu z pliku ""%1""
			           |wystąpił nieznany błąd.';
			           |de = 'Beim Extrahieren von Text aus der Datei ""%1""
			           |ist ein unbekannter Fehler aufgetreten.';
			           |ro = 'A apărut o eroare necunoscută în timpul extragerii textului din fișierul ""%1""
			           |.';
			           |tr = '"" %1 "" 
			           |adlı dosyadan metin çıkarılırken bilinmeyen bir hata oluştu.'; 
			           |es_ES = 'Ha ocurrido un error desconocido al extraer el texto desde el archivo ""%1""
			           |.'"),
			String(FileOrFileVersion));
		
		MessageText = MessageText + String(ErrorDescriptionInfo);
		
		ShowUserNotification(NStr("ru = 'Извлечение текстов'; en = 'Extract text'; pl = 'Pobieranie tekstu';de = 'Text extraktion';ro = 'Extragerea de text';tr = 'Metin çıkarma'; es_ES = 'Extracción de texto'"),, MessageText);
		
		EventLogRecordServer(MessageText);
		
	EndTry;
	
	UpdateInformationOnFilesWithNonExtractedTextCount();
	
EndProcedure

#EndIf

&AtServerNoContext
Procedure ExtractionErrorRecord(FileOrFileVersion, ExtractionResult, MessageText)
	
	SetPrivilegedMode(True);
	
	FilesOperationsInternal.RecordTextExtractionResult(FileOrFileVersion, ExtractionResult, "");
	
	// Record to the event log.
	EventLogRecordServer(MessageText);
	
EndProcedure

&AtServerNoContext
Function GetFilesForTextExtraction(FileCountInBlock)
	
	Result = New Array;
	
	Query = New Query;
	GetAllFiles = (FileCountInBlock = 0);
	
	Query = New Query;
	Query.Text = FilesOperationsInternal.QueryTextToExtractText(GetAllFiles, True);
	
	DataExported = Query.Execute().Unload();
	
	For Each Row In DataExported Do
		
		StringStructure = New Structure;
		StringStructure.Insert("Ref",       Row.Ref);
		StringStructure.Insert("Extension",   Row.Extension);
		StringStructure.Insert("Description", Row.Description);
		StringStructure.Insert("Encoding",    Row.Encoding);
		
		Result.Add(StringStructure);
		
	EndDo;
	
	Return Result;
	
EndFunction

&AtServerNoContext
Function GetFileURL(Val FileOrFileVersion, Val UUID)
	
	Return FilesOperationsInternal.FileURL(FileOrFileVersion,
		UUID);
	
EndFunction

&AtClient
Procedure ExecuteStop()
	DetachIdleHandler("TextExtractionClientHandler");
	DetachIdleHandler("CountdownUpdate");
	Status = "";
	TextExtractionEnabled = False;
EndProcedure

#EndRegion
