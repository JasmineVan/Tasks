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
	
	File = Parameters.File;
	FileData = Parameters.FileData;
	FileName = Parameters.FileName;
	OwnerID = Parameters.OwnerID;
	
	If Not ValueIsFilled(OwnerID) Then
		OwnerID = UUID;
	EndIf;
	
	If FileData.CurrentUserEditsFile Then
		EditMode = True;
	EndIf;
	
	If FileData.Version <> FileData.CurrentVersion Then
		EditMode = False;
	EndIf;
	
	Items.Text.ReadOnly                = Not EditMode;
	Items.ShowDifferences.Visible           = Common.IsWindowsClient();
	Items.ShowDifferences.Enabled         = EditMode;
	Items.Edit.Enabled           = Not EditMode;
	Items.EndEdit.Enabled = EditMode;
	Items.WriteAndClose.Enabled        = EditMode;
	Items.Write.Enabled                = EditMode;
	
	If FileData.Version <> FileData.CurrentVersion
		OR FileData.Internal Then
		Items.Edit.Enabled = False;
	EndIf;
	
	TitleRow = CommonClientServer.GetNameWithExtension(
		FileData.FullVersionDescription, FileData.Extension);
	
	If Not EditMode Then
		TitleRow = TitleRow + " " + NStr("ru='(только просмотр)'; en = '(read-only)'; pl = '(tylko podgląd)';de = '(nur Ansicht)';ro = '(doar vizualizare)';tr = '(salt okunur)'; es_ES = '(solo ver)'");
	EndIf;
	Title = TitleRow;
	
	If FileData.Property("Encoding") Then
		FileTextEncoding = FileData.Encoding;
	EndIf;
	
	If ValueIsFilled(FileTextEncoding) Then
		EncodingsList = FilesOperationsInternal.Encodings();
		ListItem = EncodingsList.FindByValue(FileTextEncoding);
		If ListItem = Undefined Then
			EncodingPresentation = FileTextEncoding;
		Else
			EncodingPresentation = ListItem.Presentation;
		EndIf;
	Else
		EncodingPresentation = NStr("ru='По умолчанию'; en = 'Default'; pl = 'Domyślny';de = 'Standard';ro = 'Implicit';tr = 'Varsayılan'; es_ES = 'Por defecto'");
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	Text.Read(FileName, TextEncodingForRead());
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_File"
	   AND Parameter.Property("Event")
	   AND Parameter.Event = "FileWasEdited"
	   AND Source = File Then
		
		EditMode = True;
		SetCommandsAvailability();
	EndIf;
	
	If EventName = "Write_File"
	   AND Parameter.Property("Event")
	   AND Parameter.Event = "FileDataChanged"
	   AND Source = File Then
		
		FileData = FilesOperationsInternalServerCall.FileData(File);
		
		EditMode = False;
		
		If FileData.CurrentUserEditsFile Then
			EditMode = True;
		EndIf;
		
		If FileData.Version <> FileData.CurrentVersion Then
			EditMode = False;
		EndIf;
		
		SetCommandsAvailability();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Not Modified Then
		Return;
	EndIf;
	
	Cancel = True;
	
	NameAndExtension = CommonClientServer.GetNameWithExtension(
		FileData.FullVersionDescription,
		FileData.Extension);
	
	If Exit Then
		WarningText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru ='Изменения в файле ""%1"" будут потеряны.'; en = 'The changes in file ""%1"" will be lost.'; pl = 'Zmiany w pliku ""%1"" zostaną utracone.';de = 'Änderungen an der Datei ""%1"" gehen verloren.';ro = 'Modificările în fișierul ""%1"" vor fi pierdute.';tr = '""%1"" dosyasındaki değişiklikler kaybedilecekler.'; es_ES = 'Los cambios en el archivo ""%1"" serán perdidos.'"), NameAndExtension);
		Return;
	EndIf;

	ResultHandler = New NotifyDescription("BeforeCloseAfterAnswerQuestionOnClosingTextEditor", ThisObject);
	ReminderText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru ='Файл ""%1"" был изменен.
			|Сохранить изменения?'; 
			|en = 'File ""%1"" was changed.
			|Do you want to save the changes?'; 
			|pl = 'Plik ""%1"" został zmieniony.
			|Zapisać zmiany?';
			|de = 'Die Datei ""%1"" wurde geändert.
			|Änderungen speichern?';
			|ro = 'Fișierul ""%1"" a fost modificat.
			|Salvați modificările?';
			|tr = 'Dosya ""%1"" değiştirilmiştir. 
			| Değişiklikler kaydedilsin mi?'; 
			|es_ES = 'El archivo ""%1"" ha sido cambiado.
			|¿Guardar los cambios?'"), 
		NameAndExtension);
	Buttons = New ValueList;
	Buttons.Add("Save", NStr("ru = 'Сохранить'; en = 'Save'; pl = 'Zapisz';de = 'Speichern';ro = 'Salvare';tr = 'Kaydet'; es_ES = 'Guardar'"));
	Buttons.Add("DoNotSave", NStr("ru = 'Не сохранять'; en = 'Do not save'; pl = 'Nie zapisuj';de = 'Nicht speichern';ro = 'Nu salva';tr = 'Kaydetme'; es_ES = 'No guardar'"));
	Buttons.Add("Cancel",  NStr("ru = 'Отмена'; en = 'Cancel'; pl = 'Anuluj';de = 'Abbrechen';ro = 'Revocare';tr = 'İptal'; es_ES = 'Cancelar'"));
	ReminderParameters = New Structure;
	ReminderParameters.Insert("Picture", PictureLib.Information32);
	ReminderParameters.Insert("Title", NStr("ru = 'Внимание'; en = 'Warning'; pl = 'Uwaga';de = 'Warnung';ro = 'Atenție';tr = 'Dikkat'; es_ES = 'Atención'"));
	ReminderParameters.Insert("SuggestDontAskAgain", False);
	StandardSubsystemsClient.ShowQuestionToUser(
			ResultHandler, ReminderText, Buttons, ReminderParameters);
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure SaveAs(Command)
	
	// Selecting a full path to the file on the hard drive.
	SelectFile = New FileDialog(FileDialogMode.Save);
	SelectFile.Multiselect = False;
	
	NameWithExtension = CommonClientServer.GetNameWithExtension(
		FileData.FullVersionDescription, FileData.Extension);
	
	SelectFile.FullFileName = NameWithExtension;
	Filter = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Все файлы (*.%1)|*.%1'; en = 'All files  (*.%1)|*.%1'; pl = 'Wszystkie pliki (*.%1)|*.%1';de = 'Alle Dateien (*.%1)| *.%1';ro = 'Toate fișierele (*.%1)|*.%1';tr = 'Tüm dosyalar (*.%1)|*.%1'; es_ES = 'Todos archivos (*.%1)|*.%1'"), FileData.Extension);
	SelectFile.Filter = Filter;
	
	If SelectFile.Choose() Then
		
		SelectedFullFileName = SelectFile.FullFileName;
		WriteTextToFile(SelectedFullFileName);
		
		ShowUserNotification(NStr("ru = 'Файл успешно сохранен'; en = 'File saved'; pl = 'Zapis pliku zakończony pomyślnie';de = 'Die Datei wurde erfolgreich gespeichert';ro = 'Fișier salvat cu succes';tr = 'Dosya başarıyla kaydedildi'; es_ES = 'Archivo se ha guardado con éxito'"), , SelectedFullFileName);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenCard(Command)
	
	ShowValue(, File);
	
EndProcedure

&AtClient
Procedure ExternalEditor(Command)
	
	WriteText();
	FileSystemClient.OpenFile(FileName);
	Close();
	
EndProcedure

&AtClient
Procedure Edit(Command)
	
	FilesOperationsInternalClient.EditWithNotification(Undefined, File, OwnerID);
	
EndProcedure

&AtClient
Procedure Write(Command)
	
	WriteText();
	
	Handler = New NotifyDescription("EndEditingCompletion", ThisObject);
	FileUpdateParameters = FilesOperationsInternalClient.FileUpdateParameters(Handler, File, OwnerID);
	FileUpdateParameters.Encoding = FileTextEncoding;
	FilesOperationsInternalClient.SaveFileChangesWithNotification(Handler, File, OwnerID);
		
EndProcedure

&AtClient
Procedure EndEdit(Command)
	
	WriteText();
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("Scenario", "EndEdit");
	Handler = New NotifyDescription("EndEditingCompletion", ThisObject, HandlerParameters);
	
	FileUpdateParameters = FilesOperationsInternalClient.FileUpdateParameters(Handler, File, OwnerID);
	FileUpdateParameters.Encoding = FileTextEncoding;
	FilesOperationsInternalClient.EndEditAndNotify(FileUpdateParameters);
	
EndProcedure

&AtClient
Procedure ShowDifferences(Command)
	
#If WebClient Then
	ShowMessageBox(, NStr("ru = 'Сравнение версий файлов в веб-клиенте недоступно.'; en = 'The web client does not support file version comparison.'; pl = 'Porównanie wersji plików w kliencie Web jest niedostępne.';de = 'Der Vergleich von Dateiversionen im Webclient ist nicht möglich.';ro = 'Salvarea versiunilor de fișiere nu este accesibilă în web-client.';tr = 'Web istemcide dosya sürümleri karşılaştırılamaz.'; es_ES = 'No está disponible comparar las versiones de archivos en el cliente web.'"));
	Return;
#ElsIf MobileClient Then
	ShowMessageBox(, NStr("ru = 'Сравнение версий файлов в мобильном клиенте недоступно.'; en = 'The mobile client does not support file version comparison.'; pl = 'Porównanie wersji plików w mobilnej aplikacji jest niedostępne.';de = 'Der Vergleich von Dateiversionen im mobilen Client ist nicht möglich.';ro = 'Salvarea versiunilor de fișiere nu este accesibilă în clientul mobil.';tr = 'Mobil istemciden dosya sürümleri karşılaştırılamaz.'; es_ES = 'No está disponible comparar las versiones de archivos en el cliente móvil.'"));
	Return;
#Else
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("CurrentStep", 1);
	ExecutionParameters.Insert("FileVersionsComparisonMethod", Undefined);
	ExecutionParameters.Insert("FullFileNameLeft", GetTempFileName(FileData.Extension));
	ExecuteCompareFiles(-1, ExecutionParameters);
#EndIf
	
EndProcedure

&AtClient
Procedure WriteAndClose(Command)
	
	WriteText();
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("Scenario", "WriteAndClose");
	Handler = New NotifyDescription("EndEditingCompletion", ThisObject, HandlerParameters);
	
	FileUpdateParameters = FilesOperationsInternalClient.FileUpdateParameters(Handler, File, OwnerID);
	FileUpdateParameters.Encoding = FileTextEncoding;
	FilesOperationsInternalClient.EndEditAndNotify(FileUpdateParameters);
	
EndProcedure

&AtClient
Procedure SelectEncoding(Command)
	FormParameters = New Structure;
	FormParameters.Insert("CurrentEncoding", FileTextEncoding);
	Handler = New NotifyDescription("SelectEncodingCompletion", ThisObject);
	OpenForm("DataProcessor.FilesOperations.Form.SelectEncoding", FormParameters, ThisObject, , , , Handler);
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure BeforeCloseAfterAnswerQuestionOnClosingTextEditor(Result, ExecutionParameters) Export
	
	If Result.Value = "Save" Then
		
		WriteText();
		HandlerParameters = New Structure;
		HandlerParameters.Insert("Scenario", "Close");
		Handler = New NotifyDescription("EndEditingCompletion", ThisObject, HandlerParameters);
		FileUpdateParameters = FilesOperationsInternalClient.FileUpdateParameters(Handler, File, OwnerID);
		FileUpdateParameters.Encoding = FileTextEncoding;
		FilesOperationsInternalClient.EndEditAndNotify(FileUpdateParameters);
		
	ElsIf Result.Value = "DoNotSave" Then
		
		Modified = False;
		Close();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectEncodingCompletion(Result, ExecutionParameters) Export
	
	If TypeOf(Result) <> Type("Structure") Then
		Return;
	EndIf;
	
	FileTextEncoding   = Result.Value;
	EncodingPresentation = Result.Presentation;
	
	If EditMode Then
		Modified = True;
	EndIf;
	
	ReadText();
	
EndProcedure

&AtClient
Procedure EndEditingCompletion(Result, ExecutionParameters) Export
	If Result <> True Then
		Return;
	EndIf;
	
	If ExecutionParameters.Scenario = "EndEdit" Then
		EditMode = False;
		SetCommandsAvailability();
	ElsIf ExecutionParameters.Scenario = "WriteAndClose" Then
		EditMode = False;
		SetCommandsAvailability();
		Close();
	ElsIf ExecutionParameters.Scenario = "Close" Then
		Modified = False;
		Close();
	EndIf;
EndProcedure

&AtClient
Procedure WriteText()
	
	If Not Modified Then
		Return;
	EndIf;
	
	WriteTextToFile(FileName);
	Modified = False;
	
EndProcedure

&AtClient
Procedure WriteTextToFile(FileName)
	
	FileText = CommonClientServer.ReplaceProhibitedXMLChars(Text.GetText());
	Text.SetText(FileText);
	
	If FileTextEncoding = "utf-8_WithoutBOM" Then
		
		BinaryData = GetBinaryDataFromString(Text.GetText(), "utf-8", False);
		BinaryData.Write(FileName);
		
	Else
		
		Text.Write(FileName,
			?(ValueIsFilled(FileTextEncoding), FileTextEncoding, Undefined));
		
	EndIf;
	
	FilesOperationsInternalServerCall.WriteFileVersionEncodingAndExtractedText(
		FileData.Version, FileTextEncoding, Text.GetText());
	
EndProcedure

&AtClient
Procedure SetCommandsAvailability()
	
	Items.Text.ReadOnly                = Not EditMode;
	Items.ShowDifferences.Enabled         = EditMode;
	Items.Edit.Enabled           = Not EditMode;
	Items.EndEdit.Enabled = EditMode;
	Items.WriteAndClose.Enabled        = EditMode;
	Items.Write.Enabled                = EditMode;
	Items.FormSelectEncoding.Enabled   = EditMode;
	
	TitleRow = CommonClientServer.GetNameWithExtension(
		FileData.FullVersionDescription, FileData.Extension);
	
	If Not EditMode Then
		TitleRow = TitleRow + " " + NStr("ru='(только просмотр)'; en = '(read-only)'; pl = '(tylko podgląd)';de = '(nur Ansicht)';ro = '(doar vizualizare)';tr = '(salt okunur)'; es_ES = '(solo ver)'");
	EndIf;
	Title = TitleRow;
	
EndProcedure

&AtClient
Procedure ReadText()
	
	Text.Read(FileName, TextEncodingForRead());
	
EndProcedure

&AtClient
Function TextEncodingForRead()
	
	TextEncodingForRead = ?(ValueIsFilled(FileTextEncoding), FileTextEncoding, Undefined);
	If TextEncodingForRead = "utf-8_WithoutBOM" Then
		TextEncodingForRead = "utf-8";
	EndIf;
	
	Return TextEncodingForRead;
	
EndFunction

&AtClient
Procedure ExecuteCompareFiles(Result, ExecutionParameters) Export
	If ExecutionParameters.CurrentStep = 1 Then
		PersonalSettings = FilesOperationsInternalClient.PersonalFilesOperationsSettings();
		ExecutionParameters.FileVersionsComparisonMethod = PersonalSettings.FileVersionsComparisonMethod;
		// First call means that setting has not been initialized yet.
		If ExecutionParameters.FileVersionsComparisonMethod = Undefined Then
			Handler = New NotifyDescription("ExecuteCompareFiles", ThisObject, ExecutionParameters);
			OpenForm("DataProcessor.FilesOperations.Form.SelectVersionCompareMethod", , ThisObject, , , , Handler);
			ExecutionParameters.CurrentStep = 1.1;
			Return;
		EndIf;
		ExecutionParameters.CurrentStep = 2;
	ElsIf ExecutionParameters.CurrentStep = 1.1 Then
		If Result <> DialogReturnCode.OK Then
			Return;
		EndIf;
		PersonalSettings = FilesOperationsInternalClient.PersonalFilesOperationsSettings();
		ExecutionParameters.FileVersionsComparisonMethod = PersonalSettings.FileVersionsComparisonMethod;
		If ExecutionParameters.FileVersionsComparisonMethod = Undefined Then
			Return;
		EndIf;
		ExecutionParameters.CurrentStep = 2;
	EndIf;
	
	If ExecutionParameters.CurrentStep = 2 Then
		// Saving file for the right part.
		WriteText(); // Full name is placed to the FileToOpenName attribute.
		
		// Saving file for the left part.
		If FileData.CurrentVersion = FileData.Version Then
			LeftFileData = FilesOperationsInternalServerCall.FileDataToSave(File, , OwnerID);
			LeftFileAddress = LeftFileData.CurrentVersionURL;
		Else
			LeftFileAddress = FilesOperationsInternalServerCall.GetURLToOpen(
				FileData.Version,
				OwnerID);
		EndIf;
		FilesToTransfer = New Array;
		FilesToTransfer.Add(New TransferableFileDescription(ExecutionParameters.FullFileNameLeft, LeftFileAddress));
		If Not GetFiles(FilesToTransfer,, ExecutionParameters.FullFileNameLeft, False) Then
			Return;
		EndIf;
		
		// Comparison.
		FilesOperationsInternalClient.ExecuteCompareFiles(
			ExecutionParameters.FullFileNameLeft,
			FileName,
			ExecutionParameters.FileVersionsComparisonMethod);
	EndIf;
EndProcedure

#EndRegion
