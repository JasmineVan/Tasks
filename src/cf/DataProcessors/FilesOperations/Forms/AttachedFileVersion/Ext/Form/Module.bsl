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
		
	ObjectValue = Parameters.Key.GetObject();
	ObjectValue.Fill(Undefined);
	
	ErrorTitle = NStr("ru = 'Ошибка при настройке формы элемента присоединенных файлов.'; en = 'An error occurred when configuring the item form of attached files.'; pl = 'Błąd podczas konfiguracji formularzu elementu dołączonych plików.';de = 'Fehler beim Einrichten des Formulars des angehängten Dateielements.';ro = 'Eroare la setarea formei elementului fișierelor atașate.';tr = 'Ekli dosyaların unsur biçimi yapılandırırken bir hata oluştu.'; es_ES = 'Error al ajustar el formulario del elemento de los archivos adjuntos.'");
	ErrorEnd = NStr("ru = 'В этом случае настройка формы элемента невозможна.'; en = 'Cannot configure the item form.'; pl = 'W tym przypadku konfiguracja formularzu elementu nie jest możliwe.';de = 'In diesem Fall ist die Einstellung der Elementform nicht möglich.';ro = 'În acest caz, configurarea formei elementului este imposibilă.';tr = 'Bu durumda, unsur biçimi yapılandırılamaz.'; es_ES = 'En este caso es imposible ajustar el formulario del elemento.'");
	
	SetUpFormObject(ObjectValue);
	
	If TypeOf(ThisObject.Object.Owner) = Type("CatalogRef.Files") Then
		Items.FullDescr.ReadOnly = True;
	EndIf;
	
	If Users.IsFullUser() Then
		Items.Author0.ReadOnly = False;
		Items.CreationDate0.ReadOnly = False;
	Else
		Items.LocationGroup.Visible = False;
	EndIf;
	
	VolumeFullPath = FilesOperationsInternal.FullVolumePath(ThisObject.Object.Volume);
	
	CommonSettings = FilesOperationsInternalCached.FilesOperationSettings().CommonSettings;
	
	FileExtensionInList = FilesOperationsInternalClientServer.FileExtensionInList(
		CommonSettings.TestFilesExtensionsList, ThisObject.Object.Extension);
	
	If FileExtensionInList Then
		If ValueIsFilled(ThisObject.Object.Ref) Then
			
			EncodingValue = FilesOperationsInternal.GetFileVersionEncoding(ThisObject.Object.Ref);
			
			EncodingsList = FilesOperationsInternal.Encodings();
			ListItem = EncodingsList.FindByValue(EncodingValue);
			If ListItem = Undefined Then
				Encoding = EncodingValue;
			Else	
				Encoding = ListItem.Presentation;
			EndIf;
			
		EndIf;
		
		If Not ValueIsFilled(Encoding) Then
			Encoding = NStr("ru='По умолчанию'; en = 'Default'; pl = 'Domyślny';de = 'Standard';ro = 'Implicit';tr = 'Varsayılan'; es_ES = 'Por defecto'");
		EndIf;
	Else
		Items.Encoding.Visible = False;
	EndIf;
	
	If Common.IsMobileClient() Then
		
		CommonClientServer.SetFormItemProperty(Items, "StandardWriteAndClose", "Representation", ButtonRepresentation.Picture);
		
		If Items.Find("Comment") <> Undefined Then
			
			CommonClientServer.SetFormItemProperty(Items, "Comment", "MaxHeight", 2);
			CommonClientServer.SetFormItemProperty(Items, "Comment", "AutoMaxHeight", False);
			CommonClientServer.SetFormItemProperty(Items, "Comment", "VerticalStretch", False);
			
		EndIf;
		
		If Items.Find("Comment0") <> Undefined Then
			
			CommonClientServer.SetFormItemProperty(Items, "Comment0", "MaxHeight", 2);
			CommonClientServer.SetFormItemProperty(Items, "Comment0", "AutoMaxHeight", False);
			CommonClientServer.SetFormItemProperty(Items, "Comment0", "VerticalStretch", False);
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OpenExecute()
	
	VersionRef = ThisObject.Object.Ref;
	FileData = FilesOperationsInternalServerCall.FileDataToOpen(ThisObject.Object.Owner, VersionRef, UUID);
	FilesOperationsInternalClient.OpenFileVersion(Undefined, FileData, UUID);
	
EndProcedure

&AtClient
Procedure FullDescriptionOnChange(Item)
	ThisObject.Object.Description = ThisObject.Object.FullDescr;
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure SaveAs(Command)
	
	VersionRef = ThisObject.Object.Ref;
	FileData = FilesOperationsInternalServerCall.FileDataToSave(ThisObject.Object.Owner, VersionRef, UUID);
	FilesOperationsInternalClient.SaveAs(Undefined, FileData, UUID);
	
EndProcedure

&AtClient
Procedure StandardWrite(Command)
	ProcessWriteFileVersionCommand();
EndProcedure

&AtClient
Procedure StandardWriteAndClose(Command)
	
	If ProcessWriteFileVersionCommand() Then
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure StandardReread(Command)
	
	If IsNew() Then
		Return;
	EndIf;
	
	If NOT Modified Then
		RereadDataFromServer();
		Return;
	EndIf;
	
	QuestionText = NStr("ru = 'Данные изменены. Перечитать данные?'; en = 'The data was changed. Do you want to refresh the data?'; pl = 'Dane są zmieniane. Odczytać ponownie?';de = 'Die Daten wurden geändert. Die Daten wieder lesen?';ro = 'Datele sunt schimbate. Reluați?';tr = 'Veri değişti. Tekrar okunsun mu?'; es_ES = 'Datos se han cambiado. ¿Volver a leer?'");
	
	NotifyDescription = New NotifyDescription("StandardRereadAnswerReceived", ThisObject);
	ShowQueryBox(NotifyDescription, QuestionText, QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetUpFormObject(Val NewObject)
	
	NewObjectType = New Array;
	NewObjectType.Add(TypeOf(NewObject));
	NewAttribute = New FormAttribute("Object", New TypeDescription(NewObjectType));
	NewAttribute.StoredData = True;
	
	AttributesToAdd = New Array;
	AttributesToAdd.Add(NewAttribute);
	
	ChangeAttributes(AttributesToAdd);
	ValueToFormAttribute(NewObject, "Object");
	For each Item In Items Do
		If TypeOf(Item) = Type("FormField")
			AND StrStartsWith(Item.DataPath, "PrototypeObject[0].")
			AND StrEndsWith(Item.Name, "0") Then
			
			ItemName = Left(Item.Name, StrLen(Item.Name) -1);
			
			If Items.Find(ItemName) <> Undefined  Then
				Continue;
			EndIf;
			
			NewItem = Items.Insert(ItemName, TypeOf(Item), Item.Parent, Item);
			NewItem.DataPath = "Object." + Mid(Item.DataPath, StrLen("PrototypeObject[0].") + 1);
			
			If Item.Type = FormFieldType.CheckBoxField Or Item.Type = FormFieldType.PictureField Then
				PropertiesToExclude = "Name, DataPath";
			Else
				PropertiesToExclude = "Name, DataPath, SelectedText, TypeLink";
			EndIf;
			FillPropertyValues(NewItem, Item, , PropertiesToExclude);
			Item.Visible = False;
		EndIf;
	EndDo;
	
	If Not NewObject.IsNew() Then
		ThisObject.URL = GetURL(NewObject);
	EndIf;

EndProcedure

&AtClient
Function ProcessWriteFileVersionCommand()
	
	If IsBlankString(ThisObject.Object.FullDescr) Then
		CommonClient.MessageToUser(
			NStr("ru = 'Для продолжения укажите имя версии файла.'; en = 'Please specify the name of the file version.'; pl = 'Aby kontynuować, wprowadź nazwę wersji pliku.';de = 'Um fortzufahren, geben Sie den Namen der Dateiversion an.';ro = 'Pentru continuare specificați numele versiunii fișierului.';tr = 'Devam etmek için dosya sürümün adını belirtin.'; es_ES = 'Para continuar especifique el nombre de la versión del archivo.'"), , "Description", "Object");
		Return False;
	EndIf;
	
	Try
		FilesOperationsInternalClient.CorrectFileName(ThisObject.Object.FullDescr);
	Except
		CommonClient.MessageToUser(
			BriefErrorDescription(ErrorInfo()), ,"Description", "Object");
		Return False;
	EndTry;
	
	If NOT WriteFileVersion() Then
		Return False;
	EndIf;
	
	Modified = False;
	RepresentDataChange(ThisObject.Object.Ref, DataChangeType.Update);
	NotifyChanged(ThisObject.Object.Ref);
	Notify("Write_File", New Structure("Event", "VersionSaved"), ThisObject.Object.Owner);
	Notify("Write_FileVersion",
	           New Structure("IsNew", False),
	           ThisObject.Object.Ref);
	
	Return True;
	
EndFunction

&AtServer
Function WriteFileVersion(Val ParameterObject = Undefined)
	
	If ParameterObject = Undefined Then
		ObjectToWrite = FormAttributeToValue("Object");
	Else
		ObjectToWrite = ParameterObject;
	EndIf;
	
	BeginTransaction();
	Try
		
		ObjectToWrite.Write();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		WriteLogEvent(NStr("ru = 'Файлы.Ошибка записи версии присоединенного файла'; en = 'Files.Cannot write attached file version'; pl = 'Plik.Błąd zapisu wersji załączonego pliku';de = 'Dateien.Fehler beim Schreiben der Version der angehängten Datei';ro = 'Fișiere.Eroare la înregistrarea versiunii fișierului atașat';tr = 'Dosyalar. Ekli dosya kaydedilirken bir hata oluştu.'; es_ES = 'Archivos.Error de guardar la versión del archivo adjunto'", Common.DefaultLanguageCode()),
			EventLogLevel.Error, , , DetailErrorDescription(ErrorInfo()));
		Raise;
	EndTry;
	
	If ParameterObject = Undefined Then
		ValueToFormAttribute(ObjectToWrite, "Object");
	EndIf;
	
	Return True;
	
EndFunction

&AtServer
Procedure RereadDataFromServer()
	
	FileObject = ThisObject.Object.Ref.GetObject();
	ValueToFormAttribute(FileObject, "Object");
	
EndProcedure

&AtClient
Procedure StandardRereadAnswerReceived(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		RereadDataFromServer();
		Modified = False;
	EndIf;
	
EndProcedure

&AtClient
Function IsNew()
	
	Return ThisObject.Object.Ref.IsEmpty();
	
EndFunction

#EndRegion