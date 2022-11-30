///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Schedule data import correspondent to the descriptor.
//
// Parameters:
//   Descriptor - XDTODataObject - Descriptor.
//
Procedure ScheduleDataImport(Val Descriptor) Export
	Var XMLDescriptor, MethodParameters;
	
	If Descriptor.RecommendedUpdateDate = Undefined Then
		Descriptor.RecommendedUpdateDate = CurrentUniversalDate();
	EndIf;
	
	XMLDescriptor = SerializeXDTO(Descriptor);
	
	MethodParameters = New Array;
	MethodParameters.Add(XMLDescriptor);

	JobParameters = New Structure;
	JobParameters.Insert("MethodName"    , "SuppliedDataMessagesMessageHandler.ImportData");
	JobParameters.Insert("Parameters"    , MethodParameters);
	JobParameters.Insert("DataArea", -1);
	JobParameters.Insert("ScheduledStartTime", Descriptor.RecommendedUpdateDate);
	JobParameters.Insert("RestartCountOnFailure", 3);
	
	SetPrivilegedMode(True);
	JobQueue.AddJob(JobParameters);

EndProcedure

#EndRegion

#Region Private

// Generates a list of handlers of messages that are processed by the current subsystem.
// 
// Parameters:
//  Handlers - ValueTable - see the field composition in MessagesExchange.NewMessagesHandlersTable.
// 
Procedure GetMessagesChannelsHandlers(Val Handlers) Export
	
	AddMessageChannelHandler("SuppliedData\Update", SuppliedDataMessagesMessageHandler, Handlers);
	
EndProcedure

// Processes a message body from the channel according to the algorithm of the current message channel.
//
// Parameters:
//  MessageChannel - String - an ID of a message channel used to receive the message.
//  MessageBody - Arbitrary - the body of the message received from the channel to be processed.
//  Sender - ExchangePlanRef.MessagesExchange - an endpoint that is the message sender.
//
Procedure ProcessMessage(Val MessagesChannel, Val MessageBody, Val Sender) Export
	
	Try
		Descriptor = DeserializeXDTO(MessageBody);
		
		If MessagesChannel = "SuppliedData\Update" Then
			
			HandleNewDescriptor(Descriptor);
			
		EndIf;
	Except
		WriteLogEvent(NStr("ru = 'Поставляемые данные.Ошибка обработки сообщения'; en = 'Supplied data.Message processing error'; pl = 'Dostarczone dane.Błąd przetwarzania komunikatów';de = 'Gelieferte Daten. Nachrichtenverarbeitungsfehler';ro = 'Eroare de procesare a mesajelor furnizate';tr = 'Sağlanan veri. Mesaj işleme hatası'; es_ES = 'Datos proporcionado.Error de procesamiento de mensajes'", 
			Common.DefaultLanguageCode()), 
			EventLogLevel.Error, ,
			, SuppliedData.GetDataDescription(Descriptor) + Chars.LF + DetailErrorDescription(ErrorInfo()));
		Raise;
	EndTry;
	
EndProcedure

// Processes new data. Is called from ProcessMessage and from SuppliedData.ImportAndProcessData.
//
// Parameters:
//  Descriptor - XDTODataObject Descriptor.
Procedure HandleNewDescriptor(Val Descriptor) Export
	
	Import = False;
	RecordSet = InformationRegisters.SuppliedDataRequiringProcessing.CreateRecordSet();
	RecordSet.Filter.FileID.Set(Descriptor.FileGUID);
	
	For each Handler In GetHandlers(Descriptor.DataType) Do
		
		ImportHandler = False;
		
		Handler.Handler.NewDataAvailable(Descriptor, ImportHandler);
		
		If ImportHandler Then
			RawData = RecordSet.Add();
			RawData.FileID = Descriptor.FileGUID;
			RawData.HandlerCode = Handler.HandlerCode;
			Import = True;
		EndIf;
		
	EndDo; 
	
	If Import Then
		SetPrivilegedMode(True);
		RecordSet.Write();
		SetPrivilegedMode(False);
		
		ScheduleDataImport(Descriptor);
	EndIf;
	
	WriteLogEvent(NStr("ru = 'Поставляемые данные.Доступны новые данные'; en = 'Supplied data.New data is available'; pl = 'Dostarczone dane. Dostępne są nowe dane';de = 'Gelieferte Daten. Neue Daten sind verfügbar';ro = 'Datele furnizate. Nu sunt disponibile date noi';tr = 'Sağlanan veri. Yeni veri mevcut'; es_ES = 'Datos proporcionado.Nuevos datos están disponibles'", 
		Common.DefaultLanguageCode()), 
		EventLogLevel.Information, ,
		, ?(Import, NStr("ru = 'В очередь добавлено задание на загрузку.'; en = 'Import job is added to the queue.'; pl = 'Do kolejki dodano zadanie importu.';de = 'Der Importjob wurde zur Warteschlange hinzugefügt.';ro = 'Lucrarea de import a fost adăugată la sfârșit.';tr = 'İçe aktarma işi kuyruğa eklendi.'; es_ES = 'Tarea de importación se ha añadido a la cola.'"), NStr("ru = 'Загрузка данных не требуется.'; en = 'Data import is not required.'; pl = 'Import danych nie jest wymagany.';de = 'Der Datenimport ist nicht erforderlich.';ro = 'Importul de date nu este necesar.';tr = 'Veri içe aktarımı gerekmez.'; es_ES = 'Importación de datos no está requerida.'"))
		+ Chars.LF + SuppliedData.GetDataDescription(Descriptor));

EndProcedure

// Import data correspondent to the descriptor .
//
// Parameters:
//   Descriptor - XDTODataObject Descriptor.
//
// Import data correspondent to the descriptor .
//
// Parameters:
//   Descriptor - XDTODataObject Descriptor.
//
Procedure ImportData(Val XMLDescriptor) Export
	Var Descriptor, ExportFileName;
	
	Try
		Descriptor = DeserializeXDTO(XMLDescriptor);
	Except
		WriteLogEvent(NStr("ru = 'Поставляемые данные.Ошибка работы с XML'; en = 'Supplied data.Work with XML error'; pl = 'Dostarczone dane. Podczas pracy z XML wystąpił błąd';de = 'Gelieferte Daten. Beim Arbeiten mit XML ist ein Fehler aufgetreten';ro = 'Datele furnizate. O eroare a avut loc la lucrul cu XML';tr = 'Sağlanan veri. XML ile çalışırken bir hata oluştu'; es_ES = 'Datos proporcionados.Ha ocurrido un error al trabajar con XML'", 
			Common.DefaultLanguageCode()), 
			EventLogLevel.Error, ,
			, DetailErrorDescription(ErrorInfo())
			+ XMLDescriptor);
		Return;
	EndTry;

	WriteLogEvent(NStr("ru = 'Поставляемые данные.Загрузка данных'; en = 'Supplied data.Data import'; pl = 'Dostarczone dane. Import danych';de = 'Gelieferte Daten. Daten importieren';ro = 'Datele furnizate. Import de date';tr = 'Sağlanan veri. Veri içe aktarma'; es_ES = 'Datos proporcionado. Importación de datos'", 
		Common.DefaultLanguageCode()), 
		EventLogLevel.Information, ,
		, NStr("ru = 'Загрузка начата'; en = 'Import started'; pl = 'Import został rozpoczęty';de = 'Der Import wird gestartet';ro = 'Importul este pornit';tr = 'Içe aktarma başladı'; es_ES = 'Se ha iniciado la importación'") + Chars.LF + SuppliedData.GetDataDescription(Descriptor));

	If ValueIsFilled(Descriptor.FileGUID) Then
		ExportFileName = GetFileFromStorage(Descriptor);
	
		If ExportFileName = Undefined Then
			WriteLogEvent(NStr("ru = 'Поставляемые данные.Загрузка данных'; en = 'Supplied data.Data import'; pl = 'Dostarczone dane. Import danych';de = 'Gelieferte Daten. Daten importieren';ro = 'Datele furnizate. Import de date';tr = 'Sağlanan veri. Veri içe aktarma'; es_ES = 'Datos proporcionado. Importación de datos'", 
				Common.DefaultLanguageCode()), 
				EventLogLevel.Information, ,
				, NStr("ru = 'Файл не может быть загружен'; en = 'The file can not be imported'; pl = 'Plik nie może zostać zaimportowany';de = 'Die Datei kann nicht importiert werden';ro = 'Fișierul nu poate fi importat';tr = 'Dosya içe aktarılamıyor'; es_ES = 'El archivo no puede importarse'") + Chars.LF 
				+ SuppliedData.GetDataDescription(Descriptor));
			Return;
		EndIf;
	EndIf;
	
	WriteLogEvent(NStr("ru = 'Поставляемые данные.Загрузка данных'; en = 'Supplied data.Data import'; pl = 'Dostarczone dane. Import danych';de = 'Gelieferte Daten. Daten importieren';ro = 'Datele furnizate. Import de date';tr = 'Sağlanan veri. Veri içe aktarma'; es_ES = 'Datos proporcionado. Importación de datos'", 
		Common.DefaultLanguageCode()), 
		EventLogLevel.Note, ,
		, NStr("ru = 'Загрузка успешно выполнена'; en = 'Data import successful'; pl = 'Import zakończony pomyślnie';de = 'Der Import wurde erfolgreich abgeschlossen';ro = 'Importul este finalizat cu succes';tr = 'Içe aktarma başarı ile tamamlandı'; es_ES = 'Importación se ha finalizado con éxito'") + Chars.LF + SuppliedData.GetDataDescription(Descriptor));

	// InformationRegister.RequireProcessingSuppliedData is used in that case if the loop was 
	// interrupted by rebooting the server.
	// In this case the only way to keep information about emission handlers (if there are more than 1) 
	// quickly record them in the specified register.
	RawDataSet = InformationRegisters.SuppliedDataRequiringProcessing.CreateRecordSet();
	RawDataSet.Filter.FileID.Set(Descriptor.FileGUID);
	RawDataSet.Read();
	HadErrors = False;
	
	For each Handler In GetHandlers(Descriptor.DataType) Do
		RecordFound = False;
		For each RawDataRecord In RawDataSet Do
			If RawDataRecord.HandlerCode = Handler.HandlerCode Then
				RecordFound = True;
				Break;
			EndIf;
		EndDo; 
		
		If Not RecordFound Then 
			Continue;
		EndIf;
			
		Try
			Handler.Handler.ProcessNewData(Descriptor, ExportFileName);
			RawDataSet.Delete(RawDataRecord);
			RawDataSet.Write();			
		Except
			WriteLogEvent(NStr("ru = 'Поставляемые данные.Ошибка обработки'; en = 'Supplied data.Processing error'; pl = 'Dostarczone dane. Błąd przetwarzania';de = 'Gelieferte Daten. Datenverarbeitungsfehler';ro = 'Datele furnizate. Eroare procesor de date';tr = 'Sağlanan veri. Veri işlemcisi hatası'; es_ES = 'Datos proporcionados. Error del procesador de datos'", 
				Common.DefaultLanguageCode()), 
				EventLogLevel.Error, ,
				, DetailErrorDescription(ErrorInfo())
				+ Chars.LF + SuppliedData.GetDataDescription(Descriptor)
				+ Chars.LF + StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Код обработчика: %1'; en = 'Handler code: %1'; pl = 'Kod obsługi: %1';de = 'Anwender-Code: %1';ro = 'Cod Procesor: %1';tr = 'Işleyici kodu: %1'; es_ES = 'Código del manipulador: %1'"), Handler.HandlerCode));
				
			RawDataRecord.AttemptCount = RawDataRecord.AttemptCount + 1;
			If RawDataRecord.AttemptCount > 3 Then
				NotifyAboutProcessingCancellation(Handler, Descriptor);
				RawDataSet.Delete(RawDataRecord);
			Else
				HadErrors = True;
			EndIf;
			RawDataSet.Write();			
			
		EndTry;
	EndDo; 
	
	If ExportFileName <> Undefined Then
		
		TempFile = New File(ExportFileName);
		
		If TempFile.Exist() Then
			
			Try
				
				TempFile.SetReadOnly(False);
				DeleteFiles(ExportFileName);
				
			Except
				
				WriteLogEvent(NStr("ru = 'Поставляемые данные.Загрузка данных'; en = 'Supplied data.Data import'; pl = 'Dostarczone dane. Import danych';de = 'Gelieferte Daten. Daten importieren';ro = 'Datele furnizate. Import de date';tr = 'Sağlanan veri. Veri içe aktarma'; es_ES = 'Datos proporcionado. Importación de datos'", Common.DefaultLanguageCode()), 
					EventLogLevel.Error, , , DetailErrorDescription(ErrorInfo()));
					
			EndTry;
			
		EndIf;
		
	EndIf;
	
	If TransactionActive() Then
			
		While TransactionActive() Do
				
			RollbackTransaction();
				
		EndDo;
			
		WriteLogEvent(NStr("ru = 'Поставляемые данные.Ошибка обработки'; en = 'Supplied data.Processing error'; pl = 'Dostarczone dane. Błąd przetwarzania';de = 'Gelieferte Daten. Datenverarbeitungsfehler';ro = 'Datele furnizate. Eroare procesor de date';tr = 'Sağlanan veri. Veri işlemcisi hatası'; es_ES = 'Datos proporcionados. Error del procesador de datos'", 
			Common.DefaultLanguageCode()),
			EventLogLevel.Error, 
			,
			, 
			NStr("ru = 'По завершении выполнения обработчика не была закрыта транзакция'; en = 'Upon completion of handler execution Transaction was not closed when the handler finished'; pl = 'Po zakończeniu wykonywania obsługi transakcji, Transakcja nie została zamknięta';de = 'Nach Abschluss der Ausführung des Anwenders wurde die Transaktion beim Beenden des Anwenders nicht beendet';ro = 'La finalizarea executării manualului Tranzacția nu a fost închisă când utilizatorul a terminat';tr = 'İşleyici yürütmesinin tamamlanması üzerine İşleyici işlendiğinde İşlem kapatılmadı'; es_ES = 'Al finalizar la ejecución del manipulador Transacción no se ha cerrado cuando se ha finalizado el manipulador'")
				 + Chars.LF + SuppliedData.GetDataDescription(Descriptor));
			
	EndIf;
	
	If HadErrors Then
		// Download delayed for 5 minutes.
		Descriptor.RecommendedUpdateDate = CurrentUniversalDate() + 5 * 60;
		ScheduleDataImport(Descriptor);
		WriteLogEvent(NStr("ru = 'Поставляемые данные.Ошибка обработки'; en = 'Supplied data.Processing error'; pl = 'Dostarczone dane. Błąd przetwarzania';de = 'Gelieferte Daten. Datenverarbeitungsfehler';ro = 'Datele furnizate. Eroare procesor de date';tr = 'Sağlanan veri. Veri işlemcisi hatası'; es_ES = 'Datos proporcionados. Error del procesador de datos'", 
			Common.DefaultLanguageCode()), 
			EventLogLevel.Information, , ,
			NStr("ru = 'Обработка данных будет запущена повторно из-за ошибки обработчика.'; en = 'Data processor will be run due to an error handler.'; pl = 'Przetwarzanie danych zostanie uruchomione ponownie z powodu błędu obsługi.';de = 'Die Datenverarbeitung wird aufgrund eines Anwender-Fehlers neu gestartet.';ro = 'Prelucrarea datelor va fi reluată din cauza erorii de manipulare.';tr = 'Veri işleme, işleyici hatası nedeniyle yeniden başlatılacak.'; es_ES = 'Procesamiento de datos se reiniciará debido al error del manipulador.'")
			 + Chars.LF + SuppliedData.GetDataDescription(Descriptor));
	Else
		RawDataSet.Clear();
		RawDataSet.Write();
		
		WriteLogEvent(NStr("ru = 'Поставляемые данные.Загрузка данных'; en = 'Supplied data.Data import'; pl = 'Dostarczone dane. Import danych';de = 'Gelieferte Daten. Daten importieren';ro = 'Datele furnizate. Import de date';tr = 'Sağlanan veri. Veri içe aktarma'; es_ES = 'Datos proporcionado. Importación de datos'", 
			Common.DefaultLanguageCode()), 
			EventLogLevel.Information, ,
			, NStr("ru = 'Новые данные обработаны'; en = 'New data is processed'; pl = 'Przetwarzanie nowych danych';de = 'Neue Daten werden verarbeitet';ro = 'Noi date sunt prelucrate';tr = 'Yeni veri işlendi'; es_ES = 'Nuevos datos se ha procesado'") + Chars.LF + SuppliedData.GetDataDescription(Descriptor));

	EndIf;
	
EndProcedure

Procedure DeleteUnprocessedDataInfo(Val Descriptor)
	
	RawDataSet = InformationRegisters.SuppliedDataRequiringProcessing.CreateRecordSet();
	RawDataSet.Filter.FileID.Set(Descriptor.FileGUID);
	RawDataSet.Read();
	
	For each Handler In GetHandlers(Descriptor.DataType) Do
		RecordFound = False;
		
		For each RawDataRecord In RawDataSet Do
			If RawDataRecord.HandlerCode = Handler.HandlerCode Then
				RecordFound = True;
				Break;
			EndIf;
		EndDo; 
		
		If Not RecordFound Then 
			Continue;
		EndIf;
			
		NotifyAboutProcessingCancellation(Handler, Descriptor);
		
	EndDo; 
	RawDataSet.Clear();
	RawDataSet.Write();
	
EndProcedure

Procedure NotifyAboutProcessingCancellation(Val Handler, Val Descriptor)
	
	Try
		Handler.Handler.DataProcessingCanceled(Descriptor);
		WriteLogEvent(NStr("ru = 'Поставляемые данные.Отмена обработки'; en = 'Supplied data.Processing cancel'; pl = 'Dostarczone dane. Anuluj przetwarzanie';de = 'Gelieferte Daten. Prozessor abbrechen';ro = 'Datele furnizate. Anulați procesorul';tr = 'Sağlanan veri. İşlem iptali'; es_ES = 'Datos proporcionados. Cancelar el procesador'", 
			Common.DefaultLanguageCode()), 
			EventLogLevel.Information, ,
			, SuppliedData.GetDataDescription(Descriptor)
			+ Chars.LF + StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Код обработчика: %1'; en = 'Handler code: %1'; pl = 'Kod obsługi: %1';de = 'Anwender-Code: %1';ro = 'Cod Procesor: %1';tr = 'Işleyici kodu: %1'; es_ES = 'Código del manipulador: %1'"), Handler.HandlerCode));
	
	Except
		WriteLogEvent(NStr("ru = 'Поставляемые данные.Отмена обработки'; en = 'Supplied data.Processing cancel'; pl = 'Dostarczone dane. Anuluj przetwarzanie';de = 'Gelieferte Daten. Prozessor abbrechen';ro = 'Datele furnizate. Anulați procesorul';tr = 'Sağlanan veri. İşlem iptali'; es_ES = 'Datos proporcionados. Cancelar el procesador'", 
			Common.DefaultLanguageCode()), 
			EventLogLevel.Error, ,
			, DetailErrorDescription(ErrorInfo())
			+ Chars.LF + SuppliedData.GetDataDescription(Descriptor)
			+ Chars.LF + StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Код обработчика: %1'; en = 'Handler code: %1'; pl = 'Kod obsługi: %1';de = 'Anwender-Code: %1';ro = 'Cod Procesor: %1';tr = 'Işleyici kodu: %1'; es_ES = 'Código del manipulador: %1'"), Handler.HandlerCode));
	EndTry;

EndProcedure

Function GetFileFromStorage(Val Descriptor)
	
	Try
		ExportFileName = SaaS.GetFileFromServiceManagerStorage(Descriptor.FileGUID);
	Except
		WriteLogEvent(NStr("ru = 'Поставляемые данные.Ошибка хранилища'; en = 'Supplied data.Storage error'; pl = 'Dostarczone dane. Błąd pamięci';de = 'Gelieferte Daten. Speicherfehler';ro = 'Datele furnizate. Erori de stocare';tr = 'Sağlanan veri. Depolama alanı hatası'; es_ES = 'Datos proporcionados. Error de almacenamiento'", 
			Common.DefaultLanguageCode()), 
			EventLogLevel.Error, ,
			, DetailErrorDescription(ErrorInfo())
			+ Chars.LF + SuppliedData.GetDataDescription(Descriptor));
				
		// Import is deferred for one hour.
		Descriptor.RecommendedUpdateDate = Descriptor.RecommendedUpdateDate + 60 * 60;
		ScheduleDataImport(Descriptor);
		Return Undefined;
	EndTry;
	
	// If the file was replaced or deleted between function restarts, delete the old update plan.
	// 
	If ExportFileName = Undefined Then
		DeleteUnprocessedDataInfo(Descriptor);
	EndIf;
	
	Return ExportFileName;

EndFunction

Function GetHandlers(Val DataKind)
	
	Handlers = New ValueTable;
	Handlers.Columns.Add("DataKind");
	Handlers.Columns.Add("Handler");
	Handlers.Columns.Add("HandlerCode");
	
	SSLSubsystemsIntegration.OnDefineSuppliedDataHandlers(Handlers);
	SuppliedDataOverridable.GetSuppliedDataHandlers(Handlers);
	
	Return Handlers.Copy(New Structure("DataKind", DataKind), "Handler, HandlerCode");
	
EndFunction	

Function SerializeXDTO(Val XDTOObject)
	Record = New XMLWriter;
	Record.SetString();
	XDTOFactory.WriteXML(Record, XDTOObject, , , , XMLTypeAssignment.Explicit);
	Return Record.Close();
EndFunction

Function DeserializeXDTO(Val XMLString)
	Read = New XMLReader;
	Read.SetString(XMLString);
	XDTOObject = XDTOFactory.ReadXML(Read);
	Read.Close();
	Return XDTOObject;
EndFunction

// AUXILIARY PROCEDURES AND FUNCTIONS

Procedure AddMessageChannelHandler(Val Canal, Val ChannelHandler, Val Handlers)
	
	Handler = Handlers.Add();
	Handler.Canal = Canal;
	Handler.Handler = ChannelHandler;
	
EndProcedure

#EndRegion