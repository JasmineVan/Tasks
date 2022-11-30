///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	For Each Record In ThisObject Do
		
		If Record.DebugMode Then
			
			ExchangePlanID = Common.MetadataObjectID(Metadata.ExchangePlans[Record.ExchangePlanName]);
			ModuleSafeModeManagerInternal = Common.CommonModule("SafeModeManagerInternal");
			SecurityProfileName = ModuleSafeModeManagerInternal.ExternalModuleAttachmentMode(ExchangePlanID);
			
			If SecurityProfileName <> Undefined Then
				SetSafeMode(SecurityProfileName);
			EndIf;
			
			IsFileInfobase = Common.FileInfobase();
			
			If Record.ExportDebugMode Then
				
				CheckExternalDataProcessorFileExistence(Record.ExportDebuggingDataProcessorFileName, IsFileInfobase, Cancel);
				
			EndIf;
			
			If Record.ImportDebugMode Then
				
				CheckExternalDataProcessorFileExistence(Record.ImportDebuggingDataProcessorFileName, IsFileInfobase, Cancel);
				
			EndIf;
			
			If Record.DataExchangeLoggingMode Then
				
				CheckExchangeProtocolFileAvailability(Record.ExchangeProtocolFileName, Cancel);
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

Procedure CheckExternalDataProcessorFileExistence(FileToCheckName, IsFileInfobase, Cancel)
	
	FileNameStructure = CommonClientServer.ParseFullFileName(FileToCheckName);
	CheckDirectoryName	 = FileNameStructure.Path;
	CheckDirectory = New File(CheckDirectoryName);
	FileOnHardDrive = New File(FileToCheckName);
	DirectoryLocation = ? (IsFileInfobase, NStr("ru = 'на клиенте'; en = 'on client'; pl = 'na kliencie';de = 'auf Kunde';ro = 'pe client';tr = 'istemcide'; es_ES = 'en el cliente'"), NStr("ru = 'на сервере'; en = 'on the server'; pl = 'na serwerze';de = 'auf dem server';ro = 'pe server';tr = 'sunucuda'; es_ES = 'en servidor'"));
	
	If Not CheckDirectory.Exist() Then
		
		MessageString = NStr("ru = 'Каталог ""%1"" не найден %2.'; en = 'Directory %1 not found %2.'; pl = 'Nie znaleziono %2 katalogu %1.';de = 'Das Verzeichnis ""%1"" wurde nicht gefunden %2.';ro = 'Directorul ""%1"" nu a fost găsit %2.';tr = '""%1"" dizini bulunamadı%2.'; es_ES = 'El  directorio ""%1"" no se ha encontrado %2.'");
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, CheckDirectoryName, DirectoryLocation);
		Cancel = True;
		
	ElsIf Not FileOnHardDrive.Exist() Then 
		
		MessageString = NStr("ru = 'Файл внешней обработки ""%1"" не найден %2.'; en = 'File of external data processor %1 not found %2.'; pl = 'Nie znaleziono %2 pliku ""%1"" zewnętrznego przetwarzania danych.';de = 'Externe Datenprozessordatei ""%1"" wurde nicht gefunden %2.';ro = 'Fișierul procesării externe ""%1"" nu a fost găsit %2.';tr = 'Harici veri işlemci dosyası ""%1"" bulunamadı%2.'; es_ES = 'Archivo del procesador de datos externo ""%1"" no se ha encontrado %2.'");
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, FileToCheckName, DirectoryLocation);
		Cancel = True;
		
	Else
		
		Return;
		
	EndIf;
	
	Common.MessageToUser(MessageString,,,, Cancel);
	
EndProcedure

Procedure CheckExchangeProtocolFileAvailability(ExchangeProtocolFileName, Cancel)
	
	FileNameStructure = CommonClientServer.ParseFullFileName(ExchangeProtocolFileName);
	CheckDirectoryName = FileNameStructure.Path;
	CheckDirectory = New File(CheckDirectoryName);
	CheckFileName = "test.tmp";
	
	If Not CheckDirectory.Exist() Then
		
		MessageString = NStr("ru = 'Каталог файла протокола обмена ""%1"" не найден.'; en = 'Exchange protocol file directory %1 not found.'; pl = 'Nie znaleziono katalogu pliku protokołu wymiany ""%1"".';de = 'Das ""%1"" Austauschprotokoll Dateiverzeichnis wird nicht gefunden.';ro = 'Directorul fișierului protocolului de schimb ""%1"" nu a fost găsit.';tr = '""%1"" alışveriş protokolü dosya dizini bulunamadı.'; es_ES = 'El directorio de archivos del protocolo de intercambio ""%1"" no se ha encontrado.'");
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, CheckDirectoryName);
		Cancel = True;
		
	ElsIf Not CreateCheckFile(CheckDirectoryName, CheckFileName) Then
		
		MessageString = NStr("ru = 'Не удалось создать файл в папке протокола обмена: ""%1"".'; en = 'Cannot create a file in the exchange protocol folder: ""%1"".'; pl = 'Nie można utworzyć pliku w katalogu protokołu wymiany: ""%1"".';de = 'Kann eine Datei nicht im Austausch-Protokollordner erstellen: ""%1"".';ro = 'Nu se poate crea un fișier în dosarul protocolului de schimb: ""%1"".';tr = 'Değişim protokolü klasöründe bir dosya oluşturulamıyor: ""%1"".'; es_ES = 'No se puede crear un archivo en la carpeta del protocolo de intercambio: ""%1"".'");
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, CheckDirectoryName);
		Cancel = True;
		
	ElsIf Not DeleteCheckFile(CheckDirectoryName, CheckFileName) Then
		
		MessageString = NStr("ru = 'Не удалось удалить файл в папке протокола обмена: ""%1"".'; en = 'Cannot delete file from the exchange protocol folder: ""%1"".'; pl = 'Nie można usunąć pliku z katalogu protokołu wymiany: ""%1"".';de = 'Datei kann nicht aus dem Austausch-Protokollordner gelöscht werden: ""%1"".';ro = 'Nu se poate șterge fișierul din dosarul protocolului de schimb: ""%1"".';tr = 'Değişim protokolü klasöründen dosya silinemiyor: ""%1"".'; es_ES = 'No se puede borrar el archivo de la carpeta del protocolo de intercambio: ""%1"".'");
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, CheckDirectoryName);
		Cancel = True;
		
	Else
		
		Return;
		
	EndIf;
	
	Common.MessageToUser(MessageString,,,, Cancel);
	
EndProcedure

Function CreateCheckFile(CheckDirectoryName, CheckFileName)
	
	TextDocument = New TextDocument;
	TextDocument.AddLine(NStr("ru = 'Временный файл проверки'; en = 'Temporary file for checking access to directory'; pl = 'Tymczasowy plik sprawdzenia';de = 'Temporäre Prüfdatei';ro = 'Fișierul temporar de verificare';tr = 'Geçici kontrol dosyası'; es_ES = 'Archivo de revisión temporal'"));
	
	Try
		TextDocument.Write(CheckDirectoryName + "/" + CheckFileName);
	Except
		Return False;
	EndTry;
	
	Return True;
	
EndFunction

Function DeleteCheckFile(CheckDirectoryName, CheckFileName)
	
	Try
		DeleteFiles(CheckDirectoryName, CheckFileName);
	Except
		Return False;
	EndTry;
	
	Return True;
	
EndFunction

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Niedozwolone wezwanie obiektu na kliencie.';de = 'Unzulässiger Objektaufruf auf dem Client.';ro = 'Apel inadmisibil al obiectului pe client.';tr = 'İstemcide kabul edilmeyen nesne çağrısı.'; es_ES = 'Llamada no disponible del objeto en el cliente.'");
#EndIf