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
	
	If Common.FileInfobase() Then
		Items.WindowsArchivePath.Title = NStr("ru = 'Для сервера 1С:Предприятия под управлением Microsoft Windows'; en = 'For 1C:Enterprise server on Microsoft Windows'; pl = 'Dla serwera 1C:Enterprise w systemie Microsoft Windows';de = 'Für den 1C:Enterprise Server unter Microsoft Windows';ro = 'Pentru server-ul 1C:Enterprise în Microsoft Windows';tr = 'Microsoft Windows sisteminde 1C:Enterprise sunucusu için'; es_ES = 'Para el servidor de la 1C:Empresa bajo Microsoft Windows'"); 
	Else
		Items.WindowsArchivePath.ChoiceButton = False; 
	EndIf;
	
	If Common.IsMobileClient() Then
		CommandBarLocation = FormCommandBarLabelLocation.Auto;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ArchivePathWindowsStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	If Not FilesOperationsInternalClient.FileSystemExtensionAttached() Then
		FilesOperationsInternalClient.ShowFileSystemExtensionRequiredMessageBox(Undefined);
		Return;
	EndIf;
	
	Dialog = New FileDialog(FileDialogMode.Open);
	
	Dialog.Title                    = NStr("ru = 'Выберите файл'; en = 'Select file'; pl = 'Wybierz plik';de = 'Datei auswählen';ro = 'Selectați fișierul';tr = 'Dosya seç'; es_ES = 'Seleccionar un archivo'");
	Dialog.FullFileName               = ?(ThisObject.WindowsArchivePath = "", "files.zip", ThisObject.WindowsArchivePath);
	Dialog.Multiselect           = False;
	Dialog.Preview      = False;
	Dialog.CheckFileExist  = True;
	Dialog.Filter                       = NStr("ru = 'Архивы zip(*.zip)|*.zip'; en = 'ZIP archives (*.zip)|*.zip'; pl = 'Archiwa ZIP (*.zip)|*.zip';de = 'Zip-Archive(*.zip)|*.zip';ro = 'Arhiva zip (*.zip)|*.zip';tr = 'Zip arşivleri(*.zip)|*.zip'; es_ES = 'Archivos zip(*.zip)|*.zip'");
	
	If Dialog.Choose() Then
		
		ThisObject.WindowsArchivePath = Dialog.FullFileName;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Assign(Command)
	
	ClearMessages();
	
	If IsBlankString(WindowsArchivePath) AND IsBlankString(PathToArchiveLinux) Then
		Text = NStr("ru = 'Укажите полное имя архива с
		                   |файлами начального образа (файл *.zip)'; 
		                   |en = 'Please specify the full name of the archive 
		                   |with initial image files (a *.zip file).'; 
		                   |pl = 'Wskaż pełną nazwę archiwum z
		                   |plikami obrazu początkowego (plik *.zip)';
		                   |de = 'Geben Sie den vollständigen Namen des Archivs mit
		                   |den ursprünglichen Bilddateien (*.zip-Datei) an.';
		                   |ro = 'Specificați numele complet al arhivei cu
		                   |fișierele imaginii inițiale (fișier *.zip)';
		                   |tr = 'Arşivin tam adını 
		                   |ilk görüntü dosyaları (dosya*.zip) ile belirtin'; 
		                   |es_ES = 'Especifique el nombre completo del archivo
		                   |con los archivos de la imagen inicial (archivo *.zip)'");
		CommonClient.MessageToUser(Text, , "WindowsArchivePath");
		Return;
	EndIf;
	
	If Not CommonClient.FileInfobase() Then
	
		If Not IsBlankString(WindowsArchivePath) AND (Left(WindowsArchivePath, 2) <> "\\" OR StrFind(WindowsArchivePath, ":") <> 0) Then
			ErrorText = NStr("ru = 'Путь к архиву с файлами начального образа
			                         |должен быть в формате UNC (\\servername\resource).'; 
			                         |en = 'The path to the archive with initial image files
			                         |must have UNC format (\\server_name\resource).'; 
			                         |pl = 'Ścieżka do archiwum z plikami obrazu początkowego
			                         |musi być w formacie UNC (\\servername\resource).';
			                         |de = 'Der Pfad zum ursprünglichen Bilddateiarchiv 
			                         |muss im UNC-Format (\\servername\resource) vorliegen.';
			                         |ro = 'Calea spre arhiva cu fișierele imaginii inițiale
			                         |trebuie să fie în format UNC (\\servername\resource).';
			                         |tr = 'İlk görüntü dosya arşivinin 
			                         |kısayolu UNC biçiminde olmalı (\\servername\resource).'; 
			                         |es_ES = 'La ruta al archivo con las imágenes iniciales
			                         |debe ser en el formato UNC (\\servername\resource).'");
			CommonClient.MessageToUser(ErrorText, , "WindowsArchivePath");
			Return;
		EndIf;
	
	EndIf;
	
	AddFilesToVolumes();
	
	NotificationText = NStr("ru = 'Размещение файлов из архива с файлами
		|начального образа успешно завершено.'; 
		|en = 'Files from the initial image archive
		|are stored to volumes.'; 
		|pl = 'Umieszczanie plików z archiwum
		|z plikami początkowych obrazów zostało pomyślnie zakończone.';
		|de = 'Der Speicherort der Dateien aus dem Archiv 
		|mit den Dateien des ursprünglichen Bildes wurde erfolgreich abgeschlossen.';
		|ro = 'Plasarea fișierelor din arhiva cu fișierele
		|imaginii inițiale este finalizată cu succes.';
		|tr = 'İlk görüntü dosyaları ile 
		|arşivden dosya yerleştirme başarıyla tamamlandı.'; 
		|es_ES = 'Colocación del archivo del archivo
		|con los archivos de la imagen inicial se ha finalizado con éxito.'");
	ShowUserNotification(NStr("ru = 'Размещение файлов'; en = 'Store files'; pl = 'Umieszczenie pliku';de = 'Ablegen der Datei';ro = 'Plasare fișiere';tr = 'Dosya yerleştirme'; es_ES = 'Ubicación del archivo'"),, NotificationText);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure AddFilesToVolumes()
	
	FilesOperationsInternal.AddFilesToVolumes(WindowsArchivePath, PathToArchiveLinux);
	
EndProcedure

#EndRegion
