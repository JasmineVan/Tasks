﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
// "Stored files" subsystem.
//
////////////////////////////////////////////////////////////////////////////////

#Region Public

////////////////////////////////////////////////////////////////////////////////
// File operation commands

// Opens a file for viewing or editing.
// If the file is opened for viewing, the procedure searches for the file in the user working 
// directory and suggest to open it or to get the file from the server.
// When the file is opened for editing, the procedure opens it in the working directory (if it 
// exist) or retrieves the file from the server.
//
// Parameters:
//  FileData       - Structure - the file data. See the description at FilesOperations.FileData. 
//  ForEditing - Boolean - True to open the file for editing, False otherwise.
//
Procedure OpenFile(Val FileData, Val ForEditing = False) Export
	
	If ForEditing Then
		FilesOperationsInternalClient.EditFile(Undefined, FileData);
	Else
		FilesOperationsInternalClient.OpenFileWithNotification(Undefined, FileData, , ForEditing); 
	EndIf;
	
EndProcedure

// Opens the directory on the computer where the specified file is located in the standard viewer 
// (explorer).
//
// Parameters:
//  FileData - Structure - the file data. See the description at FilesOperations.FileData. 
//
Procedure OpenFileDirectory(FileData) Export
	
	FilesOperationsInternalClient.FileDirectory(Undefined, FileData);
	
EndProcedure

// Opens a file selection dialog box for storing one or more files to the application.
// This checks the necessary conditions:
// - file does not exceed the maximum allowed size,
// - file has a valid extension,
// - volume has enough space (when storing files in volumes),
// - other conditions.
//
// Parameters:
//  FileOwner      - DefinedType.AttachedFilesOwner - a file folder or an object, to which you need 
//                       to attach the file.
//  FormID - UUID - a form UUID, whose temporary storage the file will be placed to.
//                       
//  Filter             - String - filter of a file being selected, for example, pictures for products.
//  FilesGroup       - DefinedType.AttachedFile - a catalog group with files, where a new file will 
//                       be added.
//  ResultHandler - NotifyDescription - contains description of the procedure that will be called 
//                       after adding a file with the following parameters:
//      * Result - Array - references to added files. If files were not added, a blank array.
//      * AdditionalParameters - Arbitrary - a value specified when creating notification details.
//
Procedure AddFiles(Val FileOwner, Val FormID, Val Filter = "", GroupOfFiles = Undefined,
	ResultHandler = Undefined) Export
	
	If Not ValueIsFilled(FileOwner) Then
		Raise NStr("ru = 'Не задано значение параметра ВладелецФайла в РаботаСФайламиКлиент.ДобавитьФайлы.'; en = 'The FileOwner parameter is not set in FilesOperationsClient.AddFiles.'; pl = 'Wartość parametru nie jest określona ВладелецФайла w РаботаСФайламиКлиент.ДобавитьФайлы.';de = 'Der Wert des Parameters DateiBesitzer in ArbeitenMitClientDateien.DateienHinzufügen ist nicht angegeben.';ro = 'Nu este specificată valoarea parametrului ВладелецФайла în РаботаСФайламиКлиент.ДобавитьФайлы.';tr = 'JobsFilesClient.AddFiles içinde Dosya Sahibi parametresinin değerini ayarmadınız.'; es_ES = 'No se ha establecido el valor del parámetro ВладелецФайлов en РаботаСФайламиКлиент.ДобавитьФайлы.'");
	EndIf;
	
	Parameters = New Structure;
	Parameters.Insert("FileOwner",        FileOwner);
	Parameters.Insert("FormID",   FormID);
	Parameters.Insert("Filter",               Filter);
	Parameters.Insert("GroupOfFiles",         GroupOfFiles);
	Parameters.Insert("ResultHandler", ResultHandler);
	
	NotifyDescription = New NotifyDescription("AddFilesAddInSuggested", FilesOperationsInternalClient, Parameters);
	FilesOperationsInternalClient.ShowFileSystemExtensionInstallationQuestion(NotifyDescription);
	
EndProcedure

// Opens a file selection dialog box for storing a single file to the application.
//
// Parameters:
//   ResultHandler - NotifyDescription - contains description of the procedure that will be called 
//                        after adding a file with the following parameters:
//                    * Result - Structure containing fields:
//                       ** FileRef - DefinedType.AttachedFile - a reference to the catalog item 
//                                     with the file if it was added, Undefined otherwise.
//                       ** FileAdded - Boolean - True if file is added.
//                       ** ErrorText  - String - an error text if the file was not added.
//                    * AdditionalParameters - a value specified when creating a notification object.
//
//   FileOwner      - DefinedType.AttachedFilesOwner - a file folder or an object, to which you need 
//                 to attach the file.
//   FormOwner - ManagedForm - a form, from which the file creation was called.
//   CreationMode - Undefined, Number - file creation mode:
//       - Undefined - show the dialog box for selecting file creation mode.
//       - Number - create file using the specified method:
//           * 1 - from a template (by copying other file).
//           * 2 - from the hard disk (from the client file system).
//           * 3 - from scanner.
//
//   AddingOptions - Structure - additional parameters of adding files.
//     * MaxSize  - Number - a size restriction of a file (in megabytes) that is imported from file system.
//                           If the value is 0, size is not checked. The property is ignored if its 
//                           value is bigger than it is specified in the MaxFileSize constant.
//     * SelectionDialogFilter - String - a filter that is set to choice dialog when adding a file.
//                           The format see in the Filter property of the FileSelectionDialog object in syntax assistant.
//     * DontOpenCard - Boolean - an action after file creation. If it is True, a file card will not 
//                           open after creation, otherwise, it will open.
//
Procedure AppendFile(ResultHandler, FileOwner, OwnerForm, CreateMode = Undefined, 
	AddingOptions = Undefined) Export
	
	If Not ValueIsFilled(FileOwner) Then
		Raise NStr("ru = 'Не задано значение параметра ВладелецФайла в РаботаСФайламиКлиент.ДобавитьФайл.'; en = 'The FileOwner parameter is not set in FilesOperationsClient.AddFile.'; pl = 'Wartość parametru nie jest określona ВладелецФайла w РаботаСФайламиКлиент.ДобавитьФайл.';de = 'Der Wert des Parameters DateiBesitzer in ArbeitenMitClientDateien.DateiHinzufügen ist nicht angegeben.';ro = 'Nu este specificată valoarea parametrului ВладелецФайла în РаботаСФайламиКлиент.ДобавитьФайл.';tr = 'JobsFilesClient.AddFile içindeki OwnerFile parametresinin değeri belirtilmedi.'; es_ES = 'No se ha establecido el valor del parámetro ВладелецФайлов en РаботаСФайламиКлиент.ДобавитьФайл.'");
	EndIf;
	
	ExecutionParameters = New Structure;
	If AddingOptions = Undefined
		Or TypeOf(AddingOptions) = Type("Boolean") Then
		
		ExecutionParameters.Insert("MaxSize" , 0);
		ExecutionParameters.Insert("DontOpenCard", ?(AddingOptions = Undefined, False, AddingOptions));
		ExecutionParameters.Insert("SelectionDialogFilter",  NStr("ru = 'Все файлы(*.*)|*.*'; en = 'All files (*.*)|*.*'; pl = 'Wszystkie pliki(*.*)|*.*';de = 'Alle Dateien (*.*)| *.*';ro = 'Toate fișierele(*.*)|*.*';tr = 'Tüm dosyalar(*.*)|*.*'; es_ES = 'Todos archivos(*.*)|*.*'"));
		
	Else
		ExecutionParameters.Insert("MaxSize" , AddingOptions.MaxSize);
		ExecutionParameters.Insert("DontOpenCard", AddingOptions.DontOpenCard);
		ExecutionParameters.Insert("SelectionDialogFilter", AddingOptions.SelectionDialogFilter);
	EndIf;
	
	If CreateMode = Undefined Then
		FilesOperationsInternalClient.AppendFile(ResultHandler, FileOwner, OwnerForm, , ExecutionParameters);
	Else
		ExecutionParameters.Insert("ResultHandler", ResultHandler);
		ExecutionParameters.Insert("FileOwner", FileOwner);
		ExecutionParameters.Insert("OwnerForm", OwnerForm);
		ExecutionParameters.Insert("OneFileOnly", True);
		FilesOperationsInternalClient.AddAfterCreationModeChoice(CreateMode, ExecutionParameters);
	EndIf;
	
EndProcedure

// Opens the form for setting the parameters of the working directory from the application user personal settings.
// A working directory is a folder on the user personal computer where files received from a viewer 
// or editor are temporarily stored.
//
Procedure OpenWorkingDirectorySettingsForm() Export
	
	OpenForm("CommonForm.WorkingDirectorySettings");
	
EndProcedure

// Show a warning before closing the object form if the user still has captured files attached to 
// this object.
// Called from the BeforeClose event of forms with files.
//
// If the captured files remain, then the Cancel parameter is set to True, and the user is asked a 
// question. If the user answers yes, the form closes.
//
// Parameters:
//   Form            - ManagedForm - a form, where the file is edited.
//   Cancel            - Boolean - BeforeClose event parameter.
//   Exit - Boolean - indicates that the form closes on exit the application.
//   FilesOwner   - DefinedType.AttachedFilesOwner - a file folder or an object, to which files are 
//                    attached.
//   AttributeName     - String - name of the Boolean type attribute, which stores the flag showing 
//                    that the question has already been displayed.
//
// Example:
//
//	&AtClient
//	Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
//		FilesOperationsClient.ShowConfirmationOfCloseFormWithFiles(ThisObject, Cancel, WorkCompletion, Object.Ref);
//	EndProcedure
//
Procedure ShowConfirmationForClosingFormWithFiles(Form, Cancel, WorkCompletion, FilesOwner,
	AttributeName = "CanCloseFormWithFiles") Export
	
	ProcedureName = "FilesOperationsClient.ShowConfirmationForClosingFormWithFiles";
	CommonClientServer.CheckParameter(ProcedureName, "Form", Form, Type("ManagedForm"));
	CommonClientServer.CheckParameter(ProcedureName, "Cancel", Cancel, Type("Boolean"));
	CommonClientServer.CheckParameter(ProcedureName, "WorkCompletion", WorkCompletion, Type("Boolean"));
	CommonClientServer.CheckParameter(ProcedureName, "AttributeName", AttributeName, Type("String"));
		
	If Form[AttributeName] Then
		Return;
	EndIf;
	
	If WorkCompletion Then
		Return;
	EndIf;
	
	Count = FilesOperationsInternalServerCall.FilesLockedByCurrentUserCount(FilesOwner);
	If Count = 0 Then
		Return;
	EndIf;
	
	Cancel = True;
	
	QuestionText = NStr("ru = 'Один или несколько файлов заняты для редактирования.
	                          |
	                          |Продолжить?'; 
	                          |en = 'One or several files are locked for editing.
	                          |
	                          |Do you want to continue?'; 
	                          |pl = 'Jeden lub kilka plików są zajęte dla edycji.
	                          |
	                          |Kontynuować?';
	                          |de = 'Eine oder mehrere Dateien sind für die Bearbeitung belegt.
	                          |
	                          |Fortfahren?';
	                          |ro = 'Unul sau mai multe fișiere sunt ocupate pentru editare. 
	                          |
	                          |Continuați?';
	                          |tr = 'Bir veya birkaç dosya düzenlemek için kilitlendi. 
	                          |
	                          | Devam etmek istiyor musunuz?'; 
	                          |es_ES = 'Uno o varios archivos están ocupados para editar.
	                          |
	                          |¿Continuar?'");
	CommonClient.ShowArbitraryFormClosingConfirmation(Form, Cancel, WorkCompletion, QuestionText, AttributeName);
	
EndProcedure

// Opens a new file form with a copy of the specified file.
//
// Parameters:
//  FileOwner - DefinedType.AttachedFilesOwner - a file folder or an object, to which a file is attached.
//  FileBase - DefinedType.AttachedFile - a file being copied.
//  AdditionalParameters - Structure - form opening parameters:
//    * FileStorageCatalogName - String - defines a catalog to store a file copy.
//  OnCloseNotifyDescription - NotifyDescription - description of the procedure to be called once 
//                                the form is closed. Contains the following parameters:
//                                <ClosingResult> - a value passed when calling Close() of the form being opened,
//                                <AdditionalParameters> - a value, specified when creating
//                                OnCloseNotifyDescription.
//                                If the parameter is not specified, no procedure will be called on close.
//
Procedure CopyFile(FileOwner, BasisFile, AdditionalParameters = Undefined,
	OnCloseNotifyDescription = Undefined) Export
	
	If Not ValueIsFilled(FileOwner) Then
		Raise NStr("ru = 'Не задано значение параметра ВладелецФайла в РаботаСФайламиКлиент.СкопироватьФайл.'; en = 'The FileOwner parameter is not set in FilesOperationsClient.CopyFile.'; pl = 'Wartość parametru nie jest określona ВладелецФайла w РаботаСФайламиКлиент.СкопироватьФайл.';de = 'Der Wert des Parameters DateiBesitzer in ArbeitenMitClientDateien.DateienKopieren ist nicht angegeben.';ro = 'Nu este specificată valoarea parametrului ВладелецФайла în РаботаСФайламиКлиент.СкопироватьФайл.';tr = 'JobsFilesClient.CopyFile içinde Dosya Sahibi parametresinin değerini ayarmadınız.'; es_ES = 'No se ha establecido el valor del parámetro ВладелецФайлов en РаботаСФайламиКлиент.СкопироватьФайл.'");
	EndIf;
	
	AreFiles = TypeOf(BasisFile) = Type("CatalogRef.Files");
	
	FormParameters = New Structure;
	If TypeOf(AdditionalParameters) = Type("Structure") Then
		FormParameters = CommonClient.CopyRecursive(AdditionalParameters);
		FilesStorageCatalogName = Undefined;
		If AdditionalParameters.Property("FilesStorageCatalogName", FilesStorageCatalogName) Then
			AreFiles = (FilesStorageCatalogName = "Files");
		EndIf;
	EndIf;
	
	FormParameters.Insert("CopyingValue", BasisFile);
	FormParameters.Insert("FileOwner", FileOwner);
	If AreFiles Then
		OpenForm("Catalog.Files.ObjectForm", FormParameters,,,,, OnCloseNotifyDescription);
	Else
		OpenForm("DataProcessor.FilesOperations.Form.AttachedFile", FormParameters,,,,, OnCloseNotifyDescription);
	EndIf;
	
EndProcedure

// Opens a list of file digital signatures and prompts to choose signatures to save with the file by 
// the user-selected path.
// The file signature name is generated from the file name and the signature author with the "p7s" extension.
//
// If there is no Digital signature subsystem in the configuration, the file will not be saved.
//
// Parameters:
//  AttachedFile - DefinedType.AttachedFile - a reference to the catalog item with the file.
//  FormID - UUID  - a form UUID that is used to lock the file.
//
Procedure SaveWithDigitalSignature(Val AttachedFile, Val FormID) Export
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return;
	EndIf;
	
	FileData = FilesOperationsInternalServerCall.FileDataToSave(AttachedFile);
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("AttachedFile", AttachedFile);
	ExecutionParameters.Insert("FileData",        FileData);
	ExecutionParameters.Insert("FormID", FormID);
	
	DataDetails = New Structure;
	DataDetails.Insert("DataTitle",     NStr("ru = 'Файл'; en = 'File'; pl = 'Plik';de = 'Datei';ro = 'Fișier';tr = 'Dosya'; es_ES = 'Archivo'"));
	DataDetails.Insert("ShowComment", True);
	DataDetails.Insert("Presentation",       ExecutionParameters.FileData.Ref);
	DataDetails.Insert("Object",              AttachedFile);
	
	DataDetails.Insert("Data",
		New NotifyDescription("OnSaveFileData", FilesOperationsInternalClient, ExecutionParameters));
	
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	ModuleDigitalSignatureClient.SaveDataWithSignature(DataDetails);
	
EndProcedure

// Opens a save file dialog box where the user can define a path and a name to save the file.
//
// Parameters:
//  FileData - Structure - the file data. See the description at FilesOperations.FileData. 
//
Procedure SaveFileAs(Val FileData) Export
	
	FilesOperationsInternalClient.SaveAs(Undefined, FileData, Undefined);
	
EndProcedure

// Opens the file selection form.
// Used in selection handler for overriding the default behavior.
//
// Parameters:
//  FilesOwner - DefinedType.AttachedFilesOwner - a file folder or an object, to which files to 
//                   select are attached.
//  FormItem   - FormTable, FormField - a form item that will receive a selection notification.
//                   
//  StandardProcessing - Boolean - (return value) always set to False.
//  ChoiceNotificationDetails - NotifyDescription - description of the procedure to be called once 
//                                the form is closed. Contains the following parameters:
//    * ChoiceValue - DefinedType.AttachedFile, Undefined - if a choice was performed, choice value 
//                       will be returned. Else Undefined.
//    * AdditionalParameters - Arbitrary - a value specified when creating OnCloseNotifyDescription.
//
Procedure OpenFileChoiceForm(Val FilesOwner, Val FormItem, StandardProcessing = False,
	ChoiceNotificationDetails = Undefined) Export
	
	StandardProcessing = False;
	
	If FilesOwner.IsEmpty() Then
		OnCloseNotifyHandler = New NotifyDescription("PromptForWriteRequiredAfterCompletion", ThisObject);
		ShowQueryBox(OnCloseNotifyHandler,
			NStr("ru = 'Данные еще не записаны. 
				|Переход к ""Присоединенные файлы"" возможен только после записи данных.'; 
				|en = 'You have unsaved data.
				|You can open ""Attached files"" after saving the data.'; 
				|pl = 'Dane nie są jeszcze zapisane. 
				|Przejście do ""Dołączone pliki"" możliwy jest tylko po zapisaniu danych.';
				|de = 'Die Daten wurden noch nicht erfasst. 
				|Der Zugriff auf ""Angehängte Dateien"" ist erst nach dem Schreiben der Daten möglich.';
				|ro = 'Datele încă nu sunt înregistrate. 
				|Puteți trece la ""Fișiere atașate"" numai după înregistrarea datelor.';
				|tr = 'Veriler henüz kaydedilmedi. 
				|""Ekli dosyalara"" geçiş yalnızca veri kaydından sonra mümkündür.'; 
				|es_ES = 'Los datos todavía no se han guardado. 
				|El paso a ""Archivos adjuntos"" es posible solo al guardar los datos.'"),
				QuestionDialogMode.OK);
	Else
		FormParameters = New Structure;
		FormParameters.Insert("ChoiceMode", True);
		FormParameters.Insert("FileOwner", FilesOwner);
		OpenForm("DataProcessor.FilesOperations.Form.AttachedFiles", FormParameters, FormItem,,,,
						?(ChoiceNotificationDetails <> Undefined, ChoiceNotificationDetails, Undefined));
	EndIf;
	
EndProcedure

// Opens the file form.
// Can be used as a file opening handler.
//
// Parameters:
//  AttachedFile      - DefinedType.AttachedFile - a reference to the catalog item with the file.
//  StandardProcessing - Boolean - (return value) it is always set to False.
//  AdditionalParameters - Structure - form opening parameters:
//  OnCloseNotifyDescription - NotifyDescription - a description of the procedure to be called once 
//                                the form is closed. Contains the following parameters:
//                                <ClosingResult> - a value passed when calling Close() of the form being opened,
//                                <AdditionalParameters> - a value, specified when creating
//                                OnCloseNotifyDescription.
//                                If the parameter is not specified, no procedure will be called upon close.
//
Procedure OpenFileForm(Val AttachedFile, StandardProcessing = False, AdditionalParameters = Undefined, 
	OnCloseNotifyDescription = Undefined) Export
	
	StandardProcessing = False;
	
	If Not ValueIsFilled(AttachedFile) Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	If TypeOf(AdditionalParameters) = Type("Structure") Then
		FormParameters = CommonClient.CopyRecursive(AdditionalParameters);
	EndIf;	
	If TypeOf(AttachedFile) = Type("CatalogRef.Files") Then
		FormParameters.Insert("Key", AttachedFile);
		OpenForm("Catalog.Files.ObjectForm", FormParameters,,,,, OnCloseNotifyDescription);
	Else	
		FormParameters.Insert("AttachedFile", AttachedFile);
		OpenForm("DataProcessor.FilesOperations.Form.AttachedFile", FormParameters,, AttachedFile,,, OnCloseNotifyDescription);
	EndIf;
	
EndProcedure

// Prints files.
//
// Parameters:
//  Files              - DefinedType.AttachedFile, Array - a reference or an array of references to file objects.
//  FormID - UUID - a form UUID, whose temporary storage the file will be placed to.
//                       
//
Procedure PrintFiles(Val Files, FormID = Undefined) Export
	
	If TypeOf(Files) <> Type("Array") Then
		Files = CommonClientServer.ValueInArray(Files);
	EndIf;
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("FileNumber",   0);
	ExecutionParameters.Insert("FilesData", Files);
	ExecutionParameters.Insert("FileData",  Files);
	ExecutionParameters.Insert("UUID", FormID);
	PrintFilesExecution(Undefined, ExecutionParameters);
	
EndProcedure

// Signs a file with a digital signature.
// If the Digital signature subsystem is missing, a warning about the impossibility of adding a 
// digital signature will be displayed.
//
// Parameters:
//  AttachedFile      - DefinedType.AttachedFile - a reference to the catalog item with the file.
//  FormID      - UUID - a form UUID that is used to lock the file.
//                            
//  AdditionalParameters - Undefined - the standard behavior (see below).
//                          - Structure - with the following properties:
//       * FileData            - Structure - file data. If the property is not filled, it is filled automatically in the procedure.
//       * ResultProcessing    - NotifyDescription - when calling, a value of the Boolean type is 
//                                  passed. If True, the file is successfully signed, otherwise, it 
//                                  is not signed. If there is no property, a notification will not be called.
//
Procedure SignFile(AttachedFile, FormID, AdditionalParameters = Undefined) Export
	
	If Not ValueIsFilled(AttachedFile) Then
		ShowMessageBox(, NStr("ru = 'Не выбран файл, который нужно подписать.'; en = 'Please select a file to sign.'; pl = 'Plik do podpisu nie jest zaznaczony.';de = 'Zu signierende Datei ist nicht ausgewählt.';ro = 'Fișierul care urmează să fie semnat nu este selectat.';tr = 'İmzalanacak dosya seçilmemiş.'; es_ES = 'Archivo para firmar no está seleccionado.'"));
		Return;
	EndIf;
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		ShowMessageBox(, NStr("ru = 'Добавление электронных подписей не поддерживается.'; en = 'Adding digital signatures is not supported.'; pl = 'Dodawanie podpisów cyfrowych nie jest obsługiwane.';de = 'Das Hinzufügen digitaler Signaturen wird nicht unterstützt.';ro = 'Adăugarea de semnături digitale nu este acceptată.';tr = 'Dijital imzayı ekleme işlemi desteklenmiyor.'; es_ES = 'No se admite añadir las firmas digitales.'"));
		Return;
	EndIf;
	
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	
	If Not ModuleDigitalSignatureClient.UseDigitalSignature() Then
		ShowMessageBox(,
			NStr("ru = 'Чтобы добавить электронную подпись, включите
			           |в настройках программы использование электронных подписей.'; 
			           |en = 'To add a digital signature, enable the use of digital signatures
			           |in the application settings.'; 
			           |pl = 'Aby dodać podpis elektroniczny, włącz
			           |w ustawieniach programu wykorzystanie podpisów elektronicznych.';
			           |de = 'Um eine digitale Signatur hinzuzufügen, aktivieren
			           |Sie die Verwendung von digitalen Signaturen in den Programmeinstellungen.';
			           |ro = 'Pentru a adăuga semnătura electronică activați
			           |opțiunea de utilizare a semnăturilor electronice în setările aplicației.';
			           |tr = 'Dijital
			           | imza eklemek için uygulama ayarlarında dijital imza kullanma seçeneğini etkinleştirin.'; 
			           |es_ES = 'Para añadir la firma electrónica active
			           |en los ajustes del programa el uso de las firmas electrónicas.'"));
		Return;
	EndIf;
	
	If AdditionalParameters = Undefined Then
		AdditionalParameters = New Structure;
	EndIf;
	
	If Not AdditionalParameters.Property("FileData") Then
		AdditionalParameters.Insert("FileData", FilesOperationsInternalServerCall.FileData(
			AttachedFile,, FormID));
	EndIf;
	
	ResultProcessing = Undefined;
	AdditionalParameters.Property("ResultProcessing", ResultProcessing);
	
	FilesOperationsInternalClient.SignFile(AttachedFile,
		AdditionalParameters.FileData, FormID, ResultProcessing);
	
EndProcedure

// See FilesOperations.FileData. 
// Returns the structured file information. It is used in variety of file operation commands and as 
// FileData parameter value in other procedures and functions.
//
Function FileData(Val FileRef,
                    Val FormID = Undefined,
                    Val GetBinaryDataRef = True,
                    Val ForEditing = False) Export
	
	Return FilesOperationsInternalServerCall.GetFileData(
		FileRef,
		FormID,
		GetBinaryDataRef,
		ForEditing);

EndFunction

// Receives a file from the file storage to the user working directory.
// This is the analog of the View or Edit interactive actions without opening the received file.
// The ReadOnly property of the received file will be set if the file is locked for editing or not.
//  If it is not locked, the read only mode is set.
// If there is an existing file in the working directory, it will be deleted and replaced by the 
// file, received from the file storage
//
// Parameters:
//  Notification - NotifyDescription - a notification that runs after the file is received in the 
//   user working directory. As a result a structure with the following properties is returned:
//     * FullFileName - String - a full file name with a path.
//     * ErrorDescription - String - an error text if the file is not received.
//
//  AttachedFile - DefinedType.AttachedFile - a reference to the catalog item with the file.
//  FormID - UUID - a form UUID, whose temporary storage the file will be placed to.
//                       
//
//  AdditionalParameters - Undefined - use the default values.
//     - Structure - with optional properties:
//         * ForEditing - Boolean    - the initial value is False. If True, the file will be locked 
//                                           for editing.
//         * FileData       - Structure - file properties that can be passed for acceleration if 
//                                           they were previously received by the client from the server.
//
Procedure GetAttachedFile(Notification, AttachedFile, FormID, AdditionalParameters = Undefined) Export
	
	FilesOperationsInternalClient.GetAttachedFile(Notification, AttachedFile, FormID, AdditionalParameters);
	
EndProcedure

// Places the file from the user working directory into the file storage.
// It is the analogue of the Finish Editing interactive action.
//
// Parameters:
//  Notification - NotificationDescription - a method to be called after putting a file to a file 
//   storage. As a result a structure with the following properties is returned:
//     * ErrorDescription - String - an error text if the file is not put.
//
//  AttachedFile - DefinedType.AttachedFile - a reference to the catalog item with the file.
//  FormID - UUID - a form UUID. The method puts data to the temporary storage of this form and 
//          returns the new address.
//
//  AdditionalParameters - Undefined - use the default values.
//     - Structure - with optional properties:
//         * FullFileName - String - if filled, the specified file will be placed in the user 
//                                     working directory, and then in the file storage.
//         * FileData    - Structure - file properties that can be passed for acceleration if they 
//                                        were previously received by the client from the server.
//
Procedure PutAttachedFile(Notification, AttachedFile, FormID, AdditionalParameters = Undefined) Export
	
	FilesOperationsInternalClient.PutAttachedFile(Notification, AttachedFile, FormID, AdditionalParameters);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Operations with scanner.

// Opens the scan settings form from user settings.
//
Procedure OpenScanSettingForm() Export
	
	If Not FilesOperationsInternalClient.ScanAvailable() Then
		MessageText = NStr("ru = 'Для сканирования необходимо использовать 32-битную версию программы  для ОС Windows.'; en = 'To scan an image, use the 32-bit application version for Windows.'; pl = 'Do skanowania należy użyć 32-bitową wersję programu dla SO Windows.';de = 'Um zu scannen, müssen Sie eine 32-Bit-Version des Programms für Windows verwenden.';ro = 'Pentru scanare trebuie să utilizați versiunea programului de 32 biți pentru SO Windows.';tr = 'Tarama için, Windows programının 32-bit sürümünü kullanılmalıdır.'; es_ES = 'Para escanear es necesario usar la versión de 32 bit del programa para OS Windows.'");
		ShowMessageBox(, MessageText);
		Return;
	EndIf;
	
	AddInInstalled = FilesOperationsInternalClient.InitAddIn();
	
	If Not AddInInstalled Then
		QuestionText = 
			NStr("ru = 'Для продолжения работы необходимо установить компоненту сканирования. 
			           |Установить компоненту?'; 
			           |en = 'To proceed, install the scanner add-in.
			           |Do you want to install the add-in?'; 
			           |pl = 'Aby kontynuować pracę, należy zainstalować komponent skanowania.
			           |Zainstalować komponent?';
			           |de = 'Um fortzufahren, müssen Sie die Scan-Komponente installieren. 
			           |Die Komponente installieren?';
			           |ro = 'Pentru continuarea lucrului trebuie să instalați componenta de scanare. 
			           |Instalați componenta?';
			           |tr = 'Çalışmaya devam etmek için tarama bileşenini yüklemeniz gerekir. 
			           |Bileşeni yüklemek istiyor musunuz?'; 
			           |es_ES = 'Para continuar el trabajo es necesario instalar el componente de escaneo. 
			           |¿Instalar el componente?'");
		Handler = New NotifyDescription("ShowInstallScanningAddInQuestion", 
			ThisObject, AddInInstalled);
		ShowQueryBox(Handler, QuestionText, QuestionDialogMode.YesNo);
		Return;
	EndIf;
	
	OpenScanningSettingsFormCompletion(AddInInstalled, Undefined);
	
EndProcedure

#Region AttachedFilesManagement

// OnOpen event handler of the file owner managed form.
//
// Parameters:
//  Form - ManagedForm - a file owner form.
//  Cancel - Boolean  - standard parameter of OnOpen managed form event.
//
Procedure OnOpen(Form, Cancel) Export
	
	ScannerExistence = FilesOperationsInternalClientCached.ScanCommandAvailable();
	If Not ScannerExistence Then
		ChangeAdditionalCommandsVisibility(Form);
	EndIf;
	
EndProcedure

// NotificationProcessing event handler of the file owner managed form.
//
// Parameters:
//  Form      - ManagedForm - a file owner form.
//  EventName - String - a standard parameter of the NotificationProcessing managed form event.
//
Procedure NotificationProcessing(Form, EventName) Export
	
	If EventName <> "Write_File" Then
		Return;
	EndIf;
		
	For ItemNumber = 0 To Form.FilesOperationsParameters.UBound() Do
		
		DisplayCount = Form.FilesOperationsParameters[ItemNumber].DisplayCount;
		If Not DisplayCount Then
			Continue;
		EndIf;
		
		AttachedFilesOwner = AttachedFileParameterValue(Form, ItemNumber, "PathToOwnerData");
		AttachedFilesCount = FilesOperationsInternalServerCall.AttachedFilesCount(AttachedFilesOwner);
		AttachedFilesCountAsString = Format(AttachedFilesCount, "NG=");
		
		Hyperlink = Form.Items.Find("AttachedFilesManagementOpenList" + ItemNumber);
		If Hyperlink = Undefined Then
			Continue;
		EndIf;
			
		CountPositionInTitle = StrFind(Hyperlink.Title, "(");
		If CountPositionInTitle = 0 Then
			Hyperlink.Title = Hyperlink.Title 
						+ ?(AttachedFilesCount = 0, "",
						" (" + AttachedFilesCountAsString + ")");
		Else
			Hyperlink.Title = Left(Hyperlink.Title, CountPositionInTitle - 1)
						+ ?(AttachedFilesCount = 0, "",
						"(" + AttachedFilesCountAsString + ")");
		EndIf;
		
	EndDo;
	
EndProcedure

// Execution handler of additional commands for attached file management.
//
// Parameters:
//  Form   - ManagedForm - a file owner form.
//  Command - FormCommand - a running command.
//
Procedure AttachmentsControlCommand(Form, Command) Export
	
	CommandNameParts = StrSplit(Command.Name, "_");
	If CommandNameParts.Count() <= 1 Then
		Return;
	EndIf;
	
	ItemNumber = Number(CommandNameParts[1]);
	AttachedFilesOwner = AttachedFileParameterValue(Form, ItemNumber, "PathToOwnerData");
	If Not ValueIsFilled(AttachedFilesOwner) Then
		
		HandlerParameters = New Structure;
		HandlerParameters.Insert("Action", "CommandExecution");
		HandlerParameters.Insert("Form", Form);
		HandlerParameters.Insert("Command", Command);
		HandlerParameters.Insert("ItemNumber", ItemNumber);
		
		AskQuestionAboutOwnerRecord(HandlerParameters);
		
	Else
		AttachedFilesManagementCommandCompletion(Form, Command, AttachedFilesOwner);
	EndIf;
	
EndProcedure

// Handler of clicking preview field.
//
// Parameters:
//  Form                - ManagedForm - a file owner form.
//  Item              - FormField - a preview field.
//  StandardProcessing - Boolean - a standard parameter of the Click form field event.
//  View             - Boolean - if the parameter value is True, it opens file for viewing.
//                        Else imports file from the hard drive.
//                       Default value is False.
//
Procedure PreviewFieldClick(Form, Item, StandardProcessing, View = False) Export
	
	StandardProcessing = False;
	
	ItemNumber = Number(StrReplace(Item.Name, "AttachedFilePictureField", ""));
	OneFileOnly = Form.FilesOperationsParameters[ItemNumber].OneFileOnly;
	AttachedFilesOwner = AttachedFileParameterValue(Form, Number(ItemNumber), "PathToOwnerData");
	
	If Not ValueIsFilled(AttachedFilesOwner) Then
		
		HandlerParameters = New Structure;
		HandlerParameters.Insert("Action", "PreviewClick");
		HandlerParameters.Insert("Form", Form);
		HandlerParameters.Insert("Item", Item);
		HandlerParameters.Insert("View", View);
		HandlerParameters.Insert("ItemNumber", ItemNumber);
		HandlerParameters.Insert("OneFileOnly", OneFileOnly);
		
		AskQuestionAboutOwnerRecord(HandlerParameters);
		
	Else
		PreviewFieldClickCompletion(Form, AttachedFilesOwner, Item, StandardProcessing,
			View, OneFileOnly);
	EndIf;
	
EndProcedure

// Handler of dragging to preview field.
//
// Parameters:
//  Form                   - ManagedForm - a file owner form.
//  Item                 - FormField - a preview field.
//  DragParameters - DragParameters - a standard parameter of the Drag form field event.
//                          
//  StandardProcessing - Boolean - a standard parameter of the Drag form field event.
//
Procedure PreviewFieldDrag(Form, Item, DragParameters, StandardProcessing) Export
	
	ItemNumber = Number(StrReplace(Item.Name, "AttachedFilePictureField", ""));
	OneFileOnly = Form.FilesOperationsParameters[ItemNumber].OneFileOnly;
	AttachedFilesOwner = AttachedFileParameterValue(Form, Number(ItemNumber), "PathToOwnerData");
	
	StandardProcessing = False;
	If Not ValueIsFilled(AttachedFilesOwner) Then
		
		HandlerParameters = New Structure;
		HandlerParameters.Insert("Action", "Drag");
		HandlerParameters.Insert("Form", Form);
		HandlerParameters.Insert("Item", Item);
		HandlerParameters.Insert("ItemNumber", ItemNumber);
		HandlerParameters.Insert("OneFileOnly", OneFileOnly);
		HandlerParameters.Insert("DragParameters", DragParameters);
		
		AskQuestionAboutOwnerRecord(HandlerParameters);
		
	Else
		PreviewFieldDragCompletion(Form, AttachedFilesOwner, Item, DragParameters,
			StandardProcessing, OneFileOnly);
	EndIf;
	
EndProcedure

// Handler of checking drag to preview field.
//
// Parameters:
//  Form                   - ManagedForm - a file owner form.
//  Item                 - FormField - a preview field.
//  DragParameters - DragParameters - a standard parameter of the Drag check form field event.
//                          
//  StandardProcessing    - Boolean - a standard parameter of the Drag check form field event.
//
Procedure PreviewFieldCheckDragging(Form, Item, DragParameters, StandardProcessing) Export
	
	StandardProcessing = False;
	
EndProcedure

#EndRegion

#Region ObsoleteProceduresAndFunctions

// Obsolete. Use FilesOperationsClient.OpenFileForm
// Opens the file form from the file catalog item form. Closes the item form.
// 
// Parameters:
//  Form     - ManagedForm - the form of attached file catalog.
//
Procedure GoToFileForm(Val Form) Export
	
	AttachedFile = Form.Key;
	
	Form.Close();
	
	For Each Window In GetWindows() Do
		
		Content = Window.GetContent();
		
		If Content = Undefined Then
			Continue;
		EndIf;
		
		If Content.FormName = "DataProcessor.FilesOperations.Form.AttachedFile" Then
			If Content.Parameters.Property("AttachedFile")
				AND Content.Parameters.AttachedFile = AttachedFile Then
				Window.Activate();
				Return;
			EndIf;
		EndIf;
		
	EndDo;
	
	OpenFileForm(AttachedFile);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

// The procedure is designed to print the file by the appropriate application.
//
// Parameters
//  FileData          - Structure - a file data. See the description at FilesOperations.FileData. 
//  FileToOpenName - String - file full name.
//
Procedure PrintFileByApplication(FileData, FileNameToOpen)
	
#If MobileClient Then
	ShowMessageBox(, NStr("ru='Печать файлов данного типа не поддерживается в мобильном клиенте.'; en = 'The mobile client does not support printing files of this type.'; pl = 'Drukowanie tego rodzaju pliku nie jest obsługiwane w kliencie mobilnym.';de = 'Dateien dieses Typs werden im mobilen Client nicht unterstützt.';ro = 'Imprimarea fișierelor de acest tip nu este susținută în clientul mobil.';tr = 'Bu tür bir dosyayı yazdırmak mobil istemcide desteklenmiyor.'; es_ES = 'No se admite impresión de archivos de este tipo el cliente móvil.'"));
	Return;
#Else
	
	ExtensionsExceptions = 
	" m3u, m4a, mid, midi, mp2, mp3, mpa, rmi, wav, wma, 
	| 3g2, 3gp, 3gp2, 3gpp, asf, asx, avi, m1v, m2t, m2ts, m2v, m4v, mkv, mov, mp2v, mp4, mp4v, mpe, mpeg, mts, vob, wm, wmv, wmx, wvx,
	| 7z, zip, rar, arc, arh, arj, ark, p7m, pak, package, 
	| app, com, exe, jar, dll, res, iso, isz, mdf, mds,
	| cf, dt, epf, erf";
	
	Extension = Lower(FileData.Extension);
	
	If StrFind(ExtensionsExceptions, " " + Extension + ",") > 0 Then
		ShowMessageBox(, NStr("ru='Печать файлов данного типа не поддерживается.'; en = 'Cannot print files of this type.'; pl = 'Drukowanie plików tego typu nie jest obsługiwane.';de = 'Das Drucken von Dateien dieses Typs wird nicht unterstützt.';ro = 'Imprimarea fișierelor de acest tip nu este susținută.';tr = 'Bu tür dosyalar yazdırılamıyor.'; es_ES = 'No se admite imprimir archivos de este tipo.'"));
		Return;
	ElsIf Extension = "grs" Then
		Schema = New GraphicalSchema;
		Schema.Read(FileNameToOpen);
		Schema.Print();
	Else
		
		Try
			
			If CommonClient.IsWindowsClient() Then
				FileNameToOpen = StrReplace(FileNameToOpen, "/", "\");
			EndIf;
			
			PrintFromApplicationByFileName(FileNameToOpen);
			
		Except
			
			Info = ErrorInfo();
			ShowMessageBox(,StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Описание=""%1""'; en = 'Details=""%1""'; pl = 'Opis=""%1""';de = 'Beschreibung=""%1""';ro = 'Descriere=""%1""';tr = 'Açıklama = ""%1""'; es_ES = 'Descripción=""%1""'"),
				BriefErrorDescription(Info))); 
			
		EndTry;
		
	EndIf;
	
#EndIf

EndProcedure

// File printing procedure
//
// Parameters:
//  ResultHandler - NotifyDescription for further call.
//  ExecutionParameters  - Structure - with the following properties:
//        * FileNumber               - Number - current file number,
//        * FileData              - Structure - the file data,
//        * UUID  - UUID.
//
Procedure PrintFilesExecution(ResultHandler, ExecutionParameters) Export
	
	UserInterruptProcessing();
	
	If ExecutionParameters.FileNumber >= ExecutionParameters.FilesData.Count() Then
		Return;
	EndIf;
	ExecutionParameters.FileData = 
		FilesOperationsInternalServerCall.FileDataToPrint(ExecutionParameters.FilesData[ExecutionParameters.FileNumber],
		ExecutionParameters.UUID);
		
#If WebClient Then
	If ExecutionParameters.FileData.Extension <> "mxl" Then
		Text = NStr("ru = 'Необходимо сохранить файл на компьютер, после чего выполнить
			|печать при помощи приложения, предназначенного
			|для работы с данным файлом.'; 
			|en = 'Please save the file to your computer, and then
			|print it from an application that 
			|can open this file.'; 
			|pl = 'Należy zapisać plik na komputerze, po czym wykonać
			|drukowanie za pomocą aplikacji, przeznaczonej
			|do pracy z tym plikiem.';
			|de = 'Sie müssen die Datei auf Ihrem Computer speichern und dann mit der
			|Hilfe der Anwendung drucken, die
			|für die Arbeit mit dieser Datei entwickelt wurde.';
			|ro = 'Trebuie să salvați fișierul pe computer, după care să executați
			|imprimarea cu ajutorul aplicației destinate
			|pentru lucrul cu acest fișier.';
			|tr = 'Dosya bilgisayara kaydedilmeli ve ardından bu dosyayla çalışmak üzere 
			|tasarlanmış bir uygulama 
			|kullanarak yazdırılmalıdır. '; 
			|es_ES = 'Es necesario guardar el archivo en el ordenador después
			|imprimir con ayuda de la aplicación destinado
			|para usar con este archivo.'");
		ShowMessageBox(, Text);
		Return;
	EndIf;
#EndIf
	
	If ExecutionParameters.FileData.Property("SpreadsheetDocument") Then
		ExecutionParameters.FileData.SpreadsheetDocument.Print();
		// proceeding to print the next file.
		ExecutionParameters.FileNumber = ExecutionParameters.FileNumber + 1;
		Handler = New NotifyDescription("PrintFilesExecution", ThisObject, ExecutionParameters);
		ExecuteNotifyProcessing(Handler);
		Return
	EndIf;
	
	If FilesOperationsInternalClient.FileSystemExtensionAttached() Then
		Handler = New NotifyDescription("PrintFileAfterReceiveVersionInWorkingDirectory", ThisObject, ExecutionParameters);
		FilesOperationsInternalClient.GetVersionFileToWorkingDirectory(
			Handler,
			ExecutionParameters.FileData,
			"",
			ExecutionParameters.UUID);
	Else
		ExecutionParameters.FileData = FilesOperationsInternalServerCall.FileDataToOpen(ExecutionParameters.FilesData[ExecutionParameters.FileNumber], Undefined);
		OpenFile(ExecutionParameters.FileData, False);
	EndIf;
EndProcedure

// The procedure of printing the File after receiving it to hard drive
//
// Parameters:
//  ExecutionParameters  - Structure - with the following properties:
//        * FileNumber               - Number - current file number,
//        * FileData              - Structure - the file data,
//        * UUID  - UUID.
//
Procedure PrintFileAfterReceiveVersionInWorkingDirectory(Result, ExecutionParameters) Export

	If Result.FileReceived Then
		
		If ExecutionParameters.FileNumber >= ExecutionParameters.FilesData.Count() Then
			Return;
		EndIf;
	
		PrintFileByApplication(ExecutionParameters.FileData, Result.FullFileName);
		
	EndIf;

	// proceeding to print the next file.
	ExecutionParameters.FileNumber = ExecutionParameters.FileNumber + 1;
	Handler = New NotifyDescription("PrintFilesExecution", ThisObject, ExecutionParameters);
	ExecuteNotifyProcessing(Handler);
	
EndProcedure

// Prints file by an external application.
//
// Parameters
//  FileToOpenName - String - file full name.
//
Procedure PrintFromApplicationByFileName(FileNameToOpen)
	
#If Not MobileClient Then
	If Not ValueIsFilled(FileNameToOpen) Then
		Return;
	EndIf;
	
	If CommonClient.IsWindowsClient() Then
		Shell = New COMObject("Shell.Application");
		Shell.ShellExecute(FileNameToOpen, "", "", "print", 1);
	EndIf;
#EndIf

EndProcedure

Procedure ShowInstallScanningAddInQuestion(Result, AddInInstalled) Export
	
	If Result = DialogReturnCode.Yes Then
		Handler = New NotifyDescription("OpenScanningSettingsFormCompletion", ThisObject);
		FilesOperationsInternalClient.InstallAddInSSL(Handler);
	EndIf;
	
EndProcedure

Procedure OpenScanningSettingsFormCompletion(AddInInstalled, ExecutionParameters) Export
	
	If Not AddInInstalled Then
		Return;
	EndIf;
	
	SystemInfo = New SystemInfo();
	ClientID = SystemInfo.ClientID;
	
	FormParameters = New Structure;
	FormParameters.Insert("AddInInstalled", AddInInstalled);
	FormParameters.Insert("ClientID",  ClientID);
	
	OpenForm("DataProcessor.Scanning.Form.ScanningSettings", FormParameters);
	
EndProcedure

Procedure PromptForWriteRequiredAfterCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.OK Then
		Return;
	EndIf;
	
EndProcedure

#Region AttachedFilesManagement

Function ManagementCommandParameters(Form)
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("Form",              Form);
	ExecutionParameters.Insert("Action",           "ImportFile");
	ExecutionParameters.Insert("ItemNumber",      "");
	ExecutionParameters.Insert("FormID", Form.UUID);
	Return ExecutionParameters;
	
EndFunction

Function AttachedFileParameterValue(Form, Val ItemNumber, ParameterName)
	
	If TypeOf(ItemNumber) = Type("String") Then
		ItemNumber = Number(ItemNumber);
	EndIf;
	
	DataPath = Form.FilesOperationsParameters[ItemNumber][ParameterName];
	DataPathParts = StringFunctionsClientServer.SplitStringIntoSubstringsArray(DataPath, ".", True, True);
	If DataPathParts.Count() > 0 Then
		
		ParameterValue = Form[DataPathParts[0]];
		For Index = 1 To DataPathParts.UBound() Do
			ParameterValue = ParameterValue[DataPathParts[Index]];
		EndDo;
		
		Return ParameterValue;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

Procedure AskQuestionAboutOwnerRecord(CompletionHandlerParameters)
	
	QuestionText = NStr("ru = 'Данные еще не записаны.
		|Переход к присоединенным файлам возможен только после записи данных.
		|Данные будут записаны.'; 
		|en = 'You have unsaved data.
		|You can open the attached files after saving the data.
		|Do you want to save the data?'; 
		|pl = 'Dane nie są jeszcze zapisane.
		|Przejście do dołączonych plików możliwe jest tylko po zapisaniu danych.
		|Dane zostaną zapisane.';
		|de = 'Die Daten wurden noch nicht erfasst.
		|Auf die angehängten Dateien kann erst nach dem Schreiben der Daten zugegriffen werden.
		|Die Daten werden geschrieben.';
		|ro = 'Datele încă nu sunt înregistrate. 
		|Puteți trece la fișierele atașate numai după înregistrarea datelor.
		|Datele vor fi înregistrate.';
		|tr = 'Veriler henüz kaydedilmedi 
		|Ekli dosyalara geçiş ancak veriler kaydedildikten sonra mümkündür. 
		|Veriler kaydedilir.'; 
		|es_ES = 'Los datos todavía no se han guardado.
		|El paso a archivos adjuntos es posible solo al guardar los datos.
		|Los datos serán guardados.'");
	NotificationHandler = New NotifyDescription("ShowNewOwnerRecordQuestion", ThisObject, CompletionHandlerParameters);
	
	ShowQueryBox(NotificationHandler, QuestionText, QuestionDialogMode.OKCancel);
	
EndProcedure

Procedure ShowNewOwnerRecordQuestion(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.OK Then
		
		Form = AdditionalParameters.Form;
		If Not Form.Write() Then
			Return;
		EndIf;
		
		StandardProcessing = False;
		AttachedFilesOwner = AttachedFileParameterValue(Form, 
			AdditionalParameters.ItemNumber, "PathToOwnerData");
		
		If Not ValueIsFilled(AttachedFilesOwner) Then
			Return;
		EndIf;
		
		If AdditionalParameters.Action = "CommandExecution" Then
			AttachedFilesManagementCommandCompletion(Form, AdditionalParameters.Command, AttachedFilesOwner);
		ElsIf AdditionalParameters.Action = "PreviewClick" Then
			PreviewFieldClickCompletion(Form, AttachedFilesOwner,
				AdditionalParameters.Item, StandardProcessing,
				AdditionalParameters.View, AdditionalParameters.OneFileOnly);
		ElsIf AdditionalParameters.Action = "Drag" Then
			PreviewFieldDragCompletion(Form, AttachedFilesOwner,
				AdditionalParameters.Item, AdditionalParameters.DragParameters,
				StandardProcessing, AdditionalParameters.OneFileOnly);
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure AttachedFilesManagementCommandCompletion(Form, Command, AttachedFilesOwner)
	
	CommandNameParts = StrSplit(Command.Name, "_");
	CommandName        = StrReplace(CommandNameParts[0], "AttachedFilesManagement", "");
	
	ExecutionParameters = ManagementCommandParameters(Form);
	ExecutionParameters.ItemNumber = CommandNameParts[1];
	
	CompletionHandler = New NotifyDescription("CommandWithNotificationExecutionCompletion",
		ThisObject, ExecutionParameters);
		
	NumberType = New TypeDescription("Number");
	ItemNumber = NumberType.AdjustValue(ExecutionParameters.ItemNumber);
	FileAddingOptions = New Structure;
	FileAddingOptions.Insert("MaxSize",
		Form.FilesOperationsParameters[ItemNumber].MaxSize);
	FileAddingOptions.Insert("SelectionDialogFilter",
		Form.FilesOperationsParameters[ItemNumber].SelectionDialogFilter);
	FileAddingOptions.Insert("DontOpenCard", True);
	
	If StrStartsWith(CommandName, "OpenList") Then
		
		FormParameters = New Structure();
		FormParameters.Insert("FileOwner", AttachedFilesOwner);
		FormParameters.Insert("HideOwner", True);
		FormParameters.Insert("CurrentRow", Form.UUID);
		OpenForm("DataProcessor.FilesOperations.Form.AttachedFiles", FormParameters);
		
	ElsIf StrStartsWith(CommandName, "ImportFile") Then
		
		CommandName = StrReplace(CommandName, "ImportFile", "");
		OwnerFiles = FilesOperationsInternalServerCall.AttachedFilesCount(AttachedFilesOwner, True);
		If StrStartsWith(CommandName, "OneFileOnly")
			AND OwnerFiles.Count > 0 Then
			
			FileData = OwnerFiles.FileData;
			
			ExecutionParameters.Action = "ReplaceFile";
			ExecutionParameters.Insert("PicturesFile", FileData.Ref);
			
			FilesOperationsInternalClient.UpdateFromFileOnHardDriveWithNotification(CompletionHandler,
				FileData, Form.UUID, FileAddingOptions);
			
		Else
			AppendFile(CompletionHandler, AttachedFilesOwner, Form, 2, FileAddingOptions);
		EndIf;
		
	ElsIf StrStartsWith(CommandName, "AttachedFileTitle") Then
		
		Placement = AttachedFileParameterValue(Form, ExecutionParameters.ItemNumber, "PathToPlacementAttribute");
		If Not ValueIsFilled(Placement) Then
			AppendFile(CompletionHandler, AttachedFilesOwner, Form, 2, FileAddingOptions);
		Else
			ExecutionParameters.Action = "ViewFile";
			ExecuteActionWithFile(ExecutionParameters, CompletionHandler);
		EndIf;
		
	ElsIf StrStartsWith(CommandName, "CreateByTemplate") Then
		AppendFile(CompletionHandler, AttachedFilesOwner, Form, 1, FileAddingOptions);
	ElsIf StrStartsWith(CommandName, "Scan") Then
		AppendFile(CompletionHandler, AttachedFilesOwner, Form, 3, FileAddingOptions);
	ElsIf StrStartsWith(CommandName, "SelectFile") Then
		ExecutionParameters.Action = "SelectFile";
		OpenFileChoiceForm(AttachedFilesOwner, Undefined, False, CompletionHandler);
	ElsIf StrStartsWith(CommandName, "ViewFile") Then
		ExecutionParameters.Action = "ViewFile";
		ExecuteActionWithFile(ExecutionParameters, CompletionHandler);
	ElsIf StrStartsWith(CommandName, "Clear") Then
		UpdateAttachedFileStorageAttribute(Form, ExecutionParameters.ItemNumber, Undefined);
	ElsIf StrStartsWith(CommandName, "OpenForm") Then
		ExecutionParameters.Action = "OpenForm";
		ExecuteActionWithFile(ExecutionParameters, CompletionHandler);
	ElsIf StrStartsWith(CommandName, "EditFile") Then
		ExecutionParameters.Action = "EditFile";
		ExecuteActionWithFile(ExecutionParameters, CompletionHandler);
	ElsIf StrStartsWith(CommandName, "PutFile") Then
		ExecutionParameters.Action = "PutFile";
		ExecuteActionWithFile(ExecutionParameters, CompletionHandler);
	ElsIf StrStartsWith(CommandName, "CancelEdit") Then
		ExecutionParameters.Action = "CancelEdit";
		ExecuteActionWithFile(ExecutionParameters, CompletionHandler);
	EndIf;
	
EndProcedure

Procedure PreviewFieldClickCompletion(Form, AttachedFilesOwner, Item, StandardProcessing,
	View = False, OneFileOnly = False)
	
	StandardProcessing = False;
	ItemNumber = StrReplace(Item.Name, "AttachedFilePictureField", "");
	ExecutionParameters = ManagementCommandParameters(Form);
	ExecutionParameters.ItemNumber = ItemNumber;
	
	NumberType = New TypeDescription("Number");
	ItemNumber = NumberType.AdjustValue(ExecutionParameters.ItemNumber);
	FileAddingOptions = New Structure;
	FileAddingOptions.Insert("MaxSize",
		Form.FilesOperationsParameters[ItemNumber].MaxSize);
	FileAddingOptions.Insert("SelectionDialogFilter",
		Form.FilesOperationsParameters[ItemNumber].SelectionDialogFilter);
	FileAddingOptions.Insert("DontOpenCard", True);
	
	ImageAddingOptions = FilesOperationsInternalServerCall.ImageAddingOptions(AttachedFilesOwner);
	If View
		Or Not ImageAddingOptions.InsertRight Then
		
		ExecutionParameters.Action = "ViewFile";
		ExecuteActionWithFile(ExecutionParameters, Undefined);
		
	Else
		
		CompletionHandler = New NotifyDescription("CommandWithNotificationExecutionCompletion",
			ThisObject, ExecutionParameters);
		
		If OneFileOnly Then
			
			OwnerFiles = ImageAddingOptions.OwnerFiles;
			If OwnerFiles.FilesCount > 0 Then
				
				FileData = OwnerFiles.FileData;
				ExecutionParameters.Action = "ReplaceFile";
				ExecutionParameters.Insert("PicturesFile", FileData.Ref);
				
				FilesOperationsInternalClient.UpdateFromFileOnHardDriveWithNotification(CompletionHandler, FileData,
					Form.UUID, FileAddingOptions);
				
			Else
				AppendFile(CompletionHandler, AttachedFilesOwner, Form, 2, FileAddingOptions);
			EndIf;
			
		Else
			AppendFile(CompletionHandler, AttachedFilesOwner, Form, 2, FileAddingOptions);
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure PreviewFieldDragCompletion(Form, AttachedFilesOwner, Item, DragParameters,
	StandardProcessing, OneFileOnly = False)
	
	StandardProcessing = False;
	ExecutionParameters = ManagementCommandParameters(Form);
	ExecutionParameters.ItemNumber = StrReplace(Item.Name, "AttachedFilePictureField", "");
	
	NumberType = New TypeDescription("Number");
	ItemNumber = NumberType.AdjustValue(ExecutionParameters.ItemNumber);
	If TypeOf(DragParameters.Value) = Type("File")
		AND FilesOperationsInternalServerCall.HasAccessRight("Insert", AttachedFilesOwner) Then
		
		ExecutionParameters.Action = "CompleteDragging";
		CompletionHandler = New NotifyDescription("CommandWithNotificationExecutionCompletion",
			ThisObject, ExecutionParameters);
		
		AddingOptions = New Structure;
		AddingOptions.Insert("ResultHandler", CompletionHandler);
		AddingOptions.Insert("FullFileName", DragParameters.Value.FullName);
		AddingOptions.Insert("FileOwner", AttachedFilesOwner);
		AddingOptions.Insert("OwnerForm", Form);
		AddingOptions.Insert("DontOpenCardAfterCreateFromFIle", True);
		AddingOptions.Insert("NameOfFileToCreate", DragParameters.Value.BaseName);
		AddingOptions.Insert("MaxSize",
			Form.FilesOperationsParameters[ItemNumber].MaxSize);
		AddingOptions.Insert("SelectionDialogFilter",
			Form.FilesOperationsParameters[ItemNumber].SelectionDialogFilter);
			
		FilesOperationsInternalClient.AddFormFileSystemWithExtension(AddingOptions);
		
	EndIf;
	
EndProcedure

Procedure UpdateAttachedFileStorageAttribute(Form, Val ItemNumber, File)
	
	If TypeOf(ItemNumber) = Type("String") Then
		ItemNumber = Number(ItemNumber);
	EndIf;
	
	DataPath = Form.FilesOperationsParameters[ItemNumber].PathToPlacementAttribute;
	DataPathParts = StringFunctionsClientServer.SplitStringIntoSubstringsArray(DataPath, ".", True, True);
	
	If DataPathParts.Count() > 0 Then
		
		AttributeLocationLevel = DataPathParts.Count();
		If AttributeLocationLevel = 1 Then
			Form[DataPathParts[0]] = File;
		ElsIf AttributeLocationLevel = 2 Then
			Form[DataPathParts[0]][DataPathParts[1]] = File;
		Else
			Return;
		EndIf;
		
		UpdatePreviewArea(Form, ItemNumber, File);
		
		Form.Modified = True;
		
	EndIf;
	
EndProcedure

Procedure UpdatePreviewArea(Form, ItemNumber, File)
	
	AttributeName = Form.FilesOperationsParameters[ItemNumber].PathToPictureData;
	PictureItem = Form.Items.Find("AttachedFilePictureField" + ItemNumber);
	TitleItem = Form.Items.Find("AttachedFileTitle" + ItemNumber);
	
	DataParameters = FilesOperationsClientServer.FileDataParameters();
	DataParameters.RaiseException = False;
	DataParameters.FormID = Form.UUID;
	
	UpdateData = FilesOperationsInternalServerCall.ImageFieldUpdateData(
		File, DataParameters);
		
	FileData = UpdateData.FileData;
	If PictureItem <> Undefined Then
		
		NonSelectedPictureText = Form.FilesOperationsParameters[ItemNumber].NonselectedPictureText;
		If FileData = Undefined Then
			Form[AttributeName] = Undefined;
			PictureItem.NonselectedPictureText = NonSelectedPictureText;
		ElsIf UpdateData.FileCorrupt Then
			Form[AttributeName] = Undefined;
			PictureItem.NonselectedPictureText = NStr("ru = 'Изображение отсутствует'; en = 'No image'; pl = 'Brak obrazku';de = 'Kein Bild';ro = 'Imaginea lipsește';tr = 'Görüntü yok'; es_ES = 'No hay imagen'");
		Else
			Form[AttributeName] = FileData.BinaryFileDataRef;
			PictureItem.NonselectedPictureText = NonSelectedPictureText;
		EndIf;
		
		PictureItem.TextColor = UpdateData.TextColor;
		
	EndIf;
	
	If TitleItem <> Undefined Then
		
		If FileData = Undefined Then
			TitleItem.Title = NStr("ru = 'загрузить'; en = 'upload'; pl = 'pobierz';de = 'import';ro = 'import';tr = 'ındirme'; es_ES = 'descargar'");
			TitleItem.ToolTipRepresentation = ToolTipRepresentation.None;
		Else
			TitleItem.Title = FileData.FileName;
			TitleItem.ToolTipRepresentation = ToolTipRepresentation.Auto;
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure ExecuteActionWithFile(ExecutionParameters, CompletionHandler)
	
	Form = ExecutionParameters.Form;
	Placement = AttachedFileParameterValue(Form, Number(ExecutionParameters.ItemNumber), "PathToPlacementAttribute");
	If ValueIsFilled(Placement) Then
		
		If ExecutionParameters.Action = "ViewFile" Then
			FileData = FilesOperationsInternalServerCall.FileDataToOpen(Placement, Undefined, Form.UUID);
			OpenFile(FileData);
		ElsIf ExecutionParameters.Action = "OpenForm" Then
			OpenFileForm(Placement);
		ElsIf ExecutionParameters.Action = "EditFile" Then
			FilesOperationsInternalClient.EditWithNotification(CompletionHandler, Placement);
		ElsIf ExecutionParameters.Action = "PutFile" Then
			
			FileUpdateParameters = FilesOperationsInternalClient.FileUpdateParameters(CompletionHandler,
				Placement, Form.UUID);
			FileUpdateParameters.Insert("CreateNewVersion", False);
			FilesOperationsInternalClient.EndEditAndNotify(FileUpdateParameters);
			
		ElsIf ExecutionParameters.Action = "CancelEdit" Then
			
			FilesArray = New Array;
			FilesArray.Add(Placement);
			
			FilesOperationsInternalServerCall.UnlockFiles(FilesArray);
			CommandWithNotificationExecutionCompletion(Undefined, ExecutionParameters);
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure CommandWithNotificationExecutionCompletion(Result, AdditionalParameters) Export
	
	If AdditionalParameters.Action = "ReplaceFile" Then
		
		UpdatePreviewArea(AdditionalParameters.Form, AdditionalParameters.ItemNumber,
			AdditionalParameters.PicturesFile);
		
	ElsIf (AdditionalParameters.Action = "ImportFile"
		OR AdditionalParameters.Action = "CompleteDragging")
		AND Result <> Undefined
		AND Result.FileAdded Then
		
		UpdateAttachedFileStorageAttribute(AdditionalParameters.Form, AdditionalParameters.ItemNumber,
			Result.FileRef);
		
	ElsIf AdditionalParameters.Action = "SelectFile"
		AND Result <> Undefined Then
		
		UpdateAttachedFileStorageAttribute(AdditionalParameters.Form, AdditionalParameters.ItemNumber,
			Result);
		
	ElsIf AdditionalParameters.Action = "EditFile" Then
		ChangeButtonsAvailability(AdditionalParameters.Form, AdditionalParameters.ItemNumber, True);
	ElsIf AdditionalParameters.Action = "PutFile"
		Or AdditionalParameters.Action = "CancelEdit" Then
		ChangeButtonsAvailability(AdditionalParameters.Form, AdditionalParameters.ItemNumber, False);
	EndIf;
	
EndProcedure

Procedure ChangeButtonsAvailability(Form, ItemNumber, EditStart)
	
	Buttons = New ValueList;
	Buttons.Add("AttachedFilesManagementPlaceFile" + ItemNumber, , EditStart);
	Buttons.Add("AttachedFilesManagementCancelEditing" + ItemNumber, , EditStart);
	Buttons.Add("AttachedFilesManagementEditFile" + ItemNumber, , Not EditStart);
	Buttons.Add("PutFileFromContextMenu" + ItemNumber, , EditStart);
	Buttons.Add("CancelEditFromContextMenu" + ItemNumber, , EditStart);
	Buttons.Add("EditFileFromContextMenu" + ItemNumber, , Not EditStart);
	
	Items = Form.Items;
	For Each Button In Buttons Do
		
		FormButton = Items.Find(Button.Value);
		If FormButton <> Undefined Then
			FormButton.Enabled = Button.Check;
		EndIf;
		
	EndDo;
		
EndProcedure

Procedure ChangeAdditionalCommandsVisibility(Form)
	
	For ItemIndex = 0 To Form.FilesOperationsParameters.UBound() Do
		
		CommandsSubmenu                 = Form.Items.Find("AddingFileSubmenu" + ItemIndex);
		CommandSelectButton          = Form.Items.Find("AttachedFilesManagementSelectFile" + ItemIndex);
		CommandLoadButton        = Form.Items.Find("AttachedFilesManagementImportFile" + ItemIndex);
		CommandScanButton      = Form.Items.Find("AttachedFilesManagementScan" + ItemIndex);
		CommandCreateFromTemplateButton = Form.Items.Find("AttachedFilesManagementCreateByTemplate" + ItemIndex);
		
		If CommandScanButton <> Undefined Then
			CommandScanButton.Visible = False;
			ContextMenuItem = Form.Items["AttachedFilesManagementScanFromContextMenu" 
				+ ItemIndex];
			
			ContextMenuItem.Visible = False;
		EndIf;
		
		If CommandCreateFromTemplateButton <> Undefined Then
			CommandCreateFromTemplateButton.Visible = False;
			ContextMenuItem = Form.Items["AttachedFilesManagementCreateByTemplateFromContextMenu" 
				+ ItemIndex];
			
			ContextMenuItem.Visible = False;
		EndIf;
		
		SubmenuVisibility = False;
		If CommandsSubmenu <> Undefined Then
			SubmenuVisibility = CommandSelectButton <> Undefined;
			CommandsSubmenu.Visible = SubmenuVisibility;
		EndIf;
		
		If CommandLoadButton <> Undefined Then
			CommandLoadButton.Visible = Not SubmenuVisibility;
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion
