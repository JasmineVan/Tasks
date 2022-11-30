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
	
	FileVersionsInInfobaseCount = FileVersionsInInfobaseCount();
	VolumeStorageType = Enums.FileStorageTypes.InVolumesOnHardDrive;
	
	VersionsSizeInBaseInBytes = FileVersionsSizeInInfobase();
	FileVersionsSizeInInfobase = VersionsSizeInBaseInBytes / 1048576;
	
	AdditionalParameters = New Structure;
	
	AdditionalParameters.Insert(
		"OnOpenStoreFilesInVolumesOnHardDrive",
		FilesOperationsInternal.StoreFilesInVolumesOnHardDrive());
	
	AdditionalParameters.Insert(
		"OnOpenHasFilesStorageVolumes",
		FilesOperations.HasFileStorageVolumes());
		
	If Common.IsMobileClient() Then
		Items.IconDecoration.Visible = False;
		CommandBarLocation = FormCommandBarLabelLocation.Auto;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If NOT AdditionalParameters.OnOpenStoreFilesInVolumesOnHardDrive Then
		ShowMessageBox(, NStr("ru = 'Не установлен тип хранения файлов ""В томах на диске""'; en = 'The ""Store files in volumes on a hard drive"" option is turned off.'; pl = 'Typ przechowywania plików ""W woluminach na dysku twardym"" nie jest ustawiony';de = 'Der Dateispeichertyp ""In Volumen auf der Festplatte"" ist nicht festgelegt';ro = 'Tipul de stocare a fișierelor ""În volume pe hard disk"" nu este setat';tr = ' ""Sabit diskteki birimlerde"" dosya depolama türü ayarlanmadı'; es_ES = 'Tipo de almacenamiento de archivos ""En volúmenes en el disco duro"" no está establecido'"));
		Cancel = True;
		Return;
	EndIf;
	
	If NOT AdditionalParameters.OnOpenHasFilesStorageVolumes Then 
		ShowMessageBox(, NStr("ru = 'Нет ни одного тома для размещения файлов'; en = 'There are no file storage volumes available.'; pl = 'Brak woluminów do umieszczania plików w';de = 'Es gibt keine Volumen zum Einreihen von Dateien';ro = 'Nu există volume pentru plasarea fișierelor';tr = 'Dosyaların yerleştirileceği birimler yok'; es_ES = 'No hay volúmenes para colocar archivos en ellos'"));
		Cancel = True;
		Return;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure ExecuteMoveFilesToVolumes(Command)
	
	FilesStorageProperties = FilesStorageProperties();
	
	If FilesStorageProperties.FilesStorageTyoe <> VolumeStorageType Then
		ShowMessageBox(, NStr("ru = 'Не установлен тип хранения файлов ""В томах на диске""'; en = 'The ""Store files in volumes on a hard drive"" option is turned off.'; pl = 'Typ przechowywania plików ""W woluminach na dysku twardym"" nie jest ustawiony';de = 'Der Dateispeichertyp ""In Volumen auf der Festplatte"" ist nicht festgelegt';ro = 'Tipul de stocare a fișierelor ""În volume pe hard disk"" nu este setat';tr = ' ""Sabit diskteki birimlerde"" dosya depolama türü ayarlanmadı'; es_ES = 'Tipo de almacenamiento de archivos ""En volúmenes en el disco duro"" no está establecido'"));
		Return;
	EndIf;
	
	If NOT FilesStorageProperties.HasFilesStorageVolumes Then
		ShowMessageBox(, NStr("ru = 'Нет ни одного тома для размещения файлов'; en = 'There are no file storage volumes available.'; pl = 'Brak woluminów do umieszczania plików w';de = 'Es gibt keine Volumen zum Einreihen von Dateien';ro = 'Nu există volume pentru plasarea fișierelor';tr = 'Dosyaların yerleştirileceği birimler yok'; es_ES = 'No hay volúmenes para colocar archivos en ellos'"));
		Return;
	EndIf;
	
	If FileVersionsInInfobaseCount = 0 Then
		ShowMessageBox(, NStr("ru = 'Нет ни одного файла в информационной базе'; en = 'There are no files in the infobase.'; pl = 'Brak plików w bazie informacyjnej';de = 'In der Infobase befinden sich keine Dateien';ro = 'Nu există fișiere în baza de date';tr = 'Veritabanında dosya yok'; es_ES = 'No hay archivos en la infobase'"));
		Return;
	EndIf;
	
	QuestionText = NStr("ru = 'Выполнить перенос файлов в информационной базе в тома хранения файлов?
		|
		|Эта операция может занять продолжительное время.'; 
		|en = 'Do you want to move the files from the infobase to the file storage volumes?
		|
		|This might take a long time.'; 
		|pl = 'Wykonać transfer plików w bazie informacyjnej do woluminów przechowywania plików?
		|
		|Ta operacja może potrwać dłuższy czas.';
		|de = 'Dateiübertragung in der Informationsdatenbank auf Dateispeicher-Volumes durchführen?
		|
		|Dieser Vorgang kann lange dauern.';
		|ro = 'Transferați fișierele în baza de informații în volumele de stocare a fișierelor?
		|
		|Această operație poate fi de lungă durată.';
		|tr = 'Veritabanı dosyalarında depolama birimlerine dosya aktarımı yapmak ister misiniz? 
		|
		|Bu işlem uzun zaman alabilir.'; 
		|es_ES = '¿Quiere realizar el traslado de archivos en la infobase a los volúmenes de guarda de archivos?
		|
		|Esta operación puede llevar mucho tiempo.'");
	Handler = New NotifyDescription("MoveFilesToVolumesCompletion", ThisObject);
	ShowQueryBox(Handler, QuestionText, QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure MoveFilesToVolumesCompletion(Response, ExecutionParameters) Export
	If Response <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	VersionsArray = VersionsInBase();
	LoopNumber = 1;
	MovedFilesCount = 0;
	
	VersionsInPackageCount = 10;
	VersionsPackage = New Array;
	
	FilesArrayWithErrors = New Array;
	ProcessingAborted = False;
	
	For Each VersionStructure In VersionsArray Do
		
		VersionsPackage.Add(VersionStructure);
		
		If VersionsPackage.Count() >= VersionsInPackageCount Then
			MovedItemsInPackageCount = MoveVersionsArrayToVolume(VersionsPackage, FilesArrayWithErrors);
			
			If MovedItemsInPackageCount = 0 AND VersionsPackage.Count() = VersionsInPackageCount Then
				ProcessingAborted = True; // If you cannot move the whole batch, stop the operation.
				Break;
			EndIf;
			
			MovedFilesCount = MovedFilesCount + MovedItemsInPackageCount;
			VersionsPackage.Clear();
			
		EndIf;
		
		LoopNumber = LoopNumber + 1;
	EndDo;
	
	If VersionsPackage.Count() <> 0 Then
		MovedItemsInPackageCount = MoveVersionsArrayToVolume(VersionsPackage, FilesArrayWithErrors);
		
		If MovedItemsInPackageCount = 0 Then
			ProcessingAborted = True; // If you cannot move the whole batch, stop the operation.
		EndIf;
		
		MovedFilesCount = MovedFilesCount + MovedItemsInPackageCount;
		VersionsPackage.Clear();
	EndIf;
	
	FileVersionsInInfobaseCount = FileVersionsInInfobaseCount();
	VersionsSizeInBaseInBytes = FileVersionsSizeInInfobase();
	FileVersionsSizeInInfobase = VersionsSizeInBaseInBytes / 1048576;
	
	If MovedFilesCount <> 0 Then
		WarningText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Завершен перенос файлов в тома.
			           |Перенесено файлов: %1'; 
			           |en = 'The files are moved to volumes.
			           |Total files moved: %1.'; 
			           |pl = 'Przeniesienie plików do woluminów zostało zakończone.
			           |Przeniesione pliki: %1';
			           |de = 'Die Dateiübertragung auf die Volumen ist abgeschlossen. 
			           |Übertragene Dateien: %1';
			           |ro = 'Transferul de fișiere în volume este finalizat.
			           |Fișiere transferate: %1';
			           |tr = 'Birimlere dosya aktarımı tamamlandı. 
			           |Aktarılan dosyalar:%1'; 
			           |es_ES = 'Traslado de archivos para los volúmenes se ha finalizado.
			           |Archivos trasladados: %1'"),
			MovedFilesCount);
		ShowMessageBox(, WarningText);
	EndIf;
	
	If FilesArrayWithErrors.Count() <> 0 Then
		
		Note = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Количество ошибок при переносе: %1'; en = 'Total errors: %1.'; pl = 'Liczba błędów w czasie przeniesienia: %1';de = 'Anzahl der Fehler bei der Übertragung: %1';ro = 'Numărul de erori la transfer: %1';tr = 'Transfer hataların sayısı: %1'; es_ES = 'Número de errores durante el traslado: %1'"),
			FilesArrayWithErrors.Count());
			
		If ProcessingAborted Then
			Note = NStr("ru = 'Не удалось перенести ни одного файла из пакета.
			                       |Перенос прерван.'; 
			                       |en = 'Cannot move the file batch.
			                       |Canceled moving the files.'; 
			                       |pl = 'Nie udało się przenieść żadnego pliku z paczki.
			                       |Przerwano przeniesienie.';
			                       |de = 'Fehler beim Übertragen einer Datei aus dem Paket. 
			                       |Übertragung abgebrochen.';
			                       |ro = 'Din pachet nu a fost transferat nici un fișier.
			                       |Transfer întrerupt.';
			                       |tr = 'Hiçbir dosya paketten aktarılamadı. 
			                       |Aktarım iptal edildi.'; 
			                       |es_ES = 'Ni un archivo del paquete se ha podido trasladar.
			                       |Traslado anulado.'");
		EndIf;
		
		FormParameters = New Structure;
		FormParameters.Insert("Explanation", Note);
		FormParameters.Insert("FilesArrayWithErrors", FilesArrayWithErrors);
		
		OpenForm("DataProcessor.MoveFilesToVolumes.Form.ReportForm", FormParameters);
		
	EndIf;
	
	Close();
	
EndProcedure

&AtServer
Function FileVersionsSizeInInfobase()
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ISNULL(SUM(FilesVersions.Size), 0) AS Size
	|FROM
	|	Catalog.FilesVersions AS FilesVersions
	|WHERE
	|	FilesVersions.FileStorageType = Value(Enum.FileStorageTypes.InInfobase)";
	
	For Each CatalogType In Metadata.DefinedTypes.AttachedFile.Type.Types() Do
		FullCatalogName = Metadata.FindByType(CatalogType).FullName();
		If FullCatalogName <> "Catalog.Files" AND FullCatalogName <> "Catalog.FilesVersions" Then
			Query.Text = Query.Text + 
			"
			|UNION ALL
			|
			|SELECT
			|	ISNULL(SUM(FilesVersions.Size), 0) AS Size
			|FROM
			|	" + FullCatalogName + " AS FilesVersions
			|WHERE
			|	FilesVersions.FileStorageType = VALUE(Enum.FileStorageTypes.InInfobase)";
		EndIf;
	EndDo;
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return 0;
	EndIf;
	
	Selection = Result.Select();
	Selection.Next();
	Return Selection.Size;
	
EndFunction

&AtServer
Function FileVersionsInInfobaseCount()
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	COUNT(*) AS Count
		|FROM
		|	InformationRegister.BinaryFilesData AS BinaryFilesData";
	Query.SetParameter("FileStorageType", Enums.FileStorageTypes.InInfobase);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return 0;
	EndIf;
	
	Selection = Result.Select();
	Selection.Next();
	Return Selection.Count;
	
EndFunction

&AtServer
Function VersionsInBase()
	
	VersionsArray = New Array;
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	FilesVersions.Ref AS Ref,
		|	FilesVersions.Description AS FullDescr,
		|	FilesVersions.Size AS Size
		|FROM
		|	Catalog.FilesVersions AS FilesVersions
		|WHERE
		|	FilesVersions.FileStorageType = VALUE(Enum.FileStorageTypes.InInfobase)
		|";
	
	For Each CatalogType In Metadata.DefinedTypes.AttachedFile.Type.Types() Do
		FullCatalogName = Metadata.FindByType(CatalogType).FullName();
		If FullCatalogName <> "Catalog.Files" AND FullCatalogName <> "Catalog.FilesVersions" Then
			Query.Text = Query.Text + 
			"
			|UNION ALL
			|
			|SELECT
			|	FilesVersions.Ref AS Ref,
			|	FilesVersions.Description AS FullDescr,
			|	FilesVersions.Size AS Size
			|FROM
			|	" + FullCatalogName + " AS FilesVersions
			|WHERE
			|	FilesVersions.FileStorageType = VALUE(Enum.FileStorageTypes.InInfobase)";
		EndIf;
	EndDo;
	
	Result = Query.Execute();
	ExportedTable = Result.Unload();
	
	For Each Row In ExportedTable Do
		VersionStructure = New Structure("Ref, Text, Size", 
			Row.Ref, Row.FullDescr, Row.Size);
		VersionsArray.Add(VersionStructure);
	EndDo;
	
	Return VersionsArray;
	
EndFunction

&AtServerNoContext
Function FilesStorageProperties()
	
	FilesStorageProperties = New Structure;
	
	FilesStorageProperties.Insert(
		"FilesStorageTyoe", FilesOperationsInternal.FilesStorageTyoe());
	
	FilesStorageProperties.Insert(
		"HasFilesStorageVolumes", FilesOperations.HasFileStorageVolumes());
	
	Return FilesStorageProperties;
	
EndFunction

&AtServer
Function MoveVersionsArrayToVolume(VersionsPackage, FilesArrayWithErrors)
	
	SetPrivilegedMode(True);
	
	NumberOfProcessedItems = 0;
	MaxFileSize = FilesOperations.MaxFileSize();
	
	For Each VersionStructure In VersionsPackage Do
		
		If MoveVersionToVolume(VersionStructure, MaxFileSize, FilesArrayWithErrors) Then
			NumberOfProcessedItems = NumberOfProcessedItems + 1;
		EndIf;
		
	EndDo;
	
	Return NumberOfProcessedItems;
	
EndFunction

&AtServer
Function MoveVersionToVolume(VersionStructure, MaxFileSize, FilesArrayWithErrors)
	
	ReturnCode = True;
	
	VersionRef = VersionStructure.Ref;
	If TypeOf(VersionRef) = Type("CatalogRef.FilesVersions") Then
		FileRef = VersionRef.Owner;
	Else
		FileRef = VersionRef;
	EndIf;
	Size = VersionStructure.Size;
	NameForLog = "";
	
	If Size > MaxFileSize Then
		
		NameForLog = VersionStructure.Text;
		WriteLogEvent(NStr("ru = 'Файлы.Ошибка переноса файла в том'; en = 'Files.Cannot move file to volume'; pl = 'Pliki.Nie można przenieść pliku do woluminu';de = 'Dateien. Die Datei kann nicht auf das Volumen übertragen werden';ro = 'Fișiere.Nu puteți transfera fișierul în volum';tr = 'Dosyalar. Dosya birime aktarılamıyor'; es_ES = 'Archivos.No se puede trasladar el archivo al volumen'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,, FileRef,
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'При переносе в том файла
				           |""%1""
				           |возникла ошибка:
				           |""Размер превышает максимальный"".'; 
				           |en = 'Cannot move file
				           |""%1""
				           |to the volume because
				           |its size exceeds the limit.'; 
				           |pl = 'Podczas przeniesienia do woluminu pliku
				           |""%1""
				           |wystąpił błąd:
				           |""Rozmiar przekracza wartość maksymalną"".';
				           |de = 'Bei der Übertragung auf das Datei-Volumen 
				           |""%1""
				           |ist ein Fehler aufgetreten:
				           |""Größe überschreitet das Maximum"".';
				           |ro = 'La transferarea în volum a fișierului
				           |""%1""
				           |s-a produs eroarea:
				           |""Dimensiunea depășește cea maximă"".';
				           |tr = '
				           |""%1""
				           | dosya birimine aktarılırken bir hata oluştu: 
				           |""Boyut maksimum değerini aşıyor"".'; 
				           |es_ES = 'Trasladando al volumen de archivos
				           |""%1""
				           |,ha ocurrido un error:
				           |""Tamaño excede el máximo"".'"),
				NameForLog));
		
		Return False; // do not report anything
	EndIf;
	
	NameForLog = VersionStructure.Text;
	WriteLogEvent(NStr("ru = 'Файлы.Начат перенос файла в том'; en = 'Files.Moving file to volume started'; pl = 'Pliki.Rozpoczęło się przeniesienie plików do woluminu';de = 'Dateien. Die Dateiübertragung auf das Volumen wurde gestartet';ro = 'Fișiere.Transferul fițierului în volum este complet';tr = 'Dosyalar. Birime dosya aktarımı başladı'; es_ES = 'Archivos.Traslado de archivos al volumen se ha iniciado'", Common.DefaultLanguageCode()),
		EventLogLevel.Information,, FileRef,
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Начат перенос в том файла
			           |""%1"".'; 
			           |en = 'Moving file
			           |""%1"" to volume started.'; 
			           |pl = 'Rozpoczęto transfer do woluminu pliku
			           |""%1"".';
			           |de = 'Übertragung in Volume der Datei
			           |""%1""gestartet.';
			           |ro = 'Transferul în volum a fișierului
			           |""%1"" este început.';
			           |tr = 'Dosya birimine aktarma işlemi başladı 
			           |""%1"".'; 
			           |es_ES = 'Traslado al volumen de archivos se ha empezado
			           |""%1"".'"),
			NameForLog));
	
	Try
		LockDataForEdit(FileRef);
	Except
		Return False; // do not report anything
	EndTry;
	
	Try
		LockDataForEdit(VersionRef);
	Except
		UnlockDataForEdit(FileRef);
		Return False; // do not report anything
	EndTry;
	
	FileStorageType = Common.ObjectAttributeValue(VersionRef, "FileStorageType");
	If FileStorageType <> Enums.FileStorageTypes.InInfobase Then // File is already in the volume.
		UnlockDataForEdit(FileRef);
		UnlockDataForEdit(VersionRef);
		Return False;
	EndIf;
	
	BeginTransaction();
	
	Try
		
		VersionLock = New DataLock;
		DataLockItem = VersionLock.Add(Metadata.FindByType(TypeOf(VersionRef)).FullName());
		DataLockItem.SetValue("Ref", VersionRef);
		VersionLock.Lock();
		
		VersionObject = VersionRef.GetObject();
		FileStorage = FilesOperations.FileFromInfobaseStorage(VersionRef);
		If TypeOf(VersionObject) = Type("CatalogObject.FilesVersions") Then
			FileInfo = FilesOperationsInternal.AddFileToVolume(FileStorage.Get(), VersionObject.UniversalModificationDate, 
				VersionObject.FullDescr, VersionObject.Extension, VersionObject.VersionNumber, FileRef.Encrypted, 
				// To prevent files from getting into one folder for today, inserting the date of file creation.
				VersionObject.UniversalModificationDate);
		Else
			FileInfo = FilesOperationsInternal.AddFileToVolume(FileStorage.Get(), VersionObject.UniversalModificationDate, 
				VersionObject.Description, VersionObject.Extension, , FileRef.Encrypted, 
				// To prevent files from getting into one folder for today, inserting the date of file creation.
				VersionObject.UniversalModificationDate);
		EndIf;
			
		VersionObject.Volume = FileInfo.Volume;
		VersionObject.PathToFile = FileInfo.PathToFile;
		VersionObject.FileStorageType = Enums.FileStorageTypes.InVolumesOnHardDrive;
		VersionObject.FileStorage = New ValueStorage("");
		// To write a previously signed object.
		VersionObject.AdditionalProperties.Insert("WriteSignedObject", True);
		VersionObject.Write();
		
		ObjectLock = New DataLock;
		DataLockItem = ObjectLock.Add(Metadata.FindByType(TypeOf(FileRef)).FullName());
		DataLockItem.SetValue("Ref", FileRef);
		ObjectLock.Lock();
		
		FileObject = FileRef.GetObject();
		// To write a previously signed object.
		FileObject.AdditionalProperties.Insert("WriteSignedObject", True);
		FileObject.Write(); // To move version fields to file.
		
		FilesOperationsInternal.DeleteRecordFromBinaryFilesDataRegister(VersionRef);
		
		WriteLogEvent(
			NStr("ru = 'Файлы.Завершен перенос файла в том'; en = 'Files.Moving file to volume completed'; pl = 'Pliki.Rozpoczęło się plików do woluminu zostało zakończone';de = 'Dateien. Die Dateiübertragung auf das Volumen ist abgeschlossen';ro = 'Fișiere.Transferul fițierului în volum este complet';tr = 'Dosyalar. Birime dosya aktarımı tamamlandı'; es_ES = 'Archivos.Traslado de archivos al volumen se ha finalizado'", Common.DefaultLanguageCode()),
			EventLogLevel.Information,, FileRef,
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Завершен перенос в том файла
				           |""%1"".'; 
				           |en = 'Moving file
				           |""%1"" to volume completed.'; 
				           |pl = 'Przeniesienie do woluminu pliku zostało zakończone
				           |""%1"".';
				           |de = 'Die Übertragung zum Dateivolumen ist abgeschlossen 
				           |""%1"".';
				           |ro = 'Transferul în volum a fișierului
				           |""%1"" este finalizat.';
				           |tr = 'Dosya birimine aktarma işlemi tamamlandı 
				           |""%1"".'; 
				           |es_ES = 'Traslado al tomo de archivos se ha finalizado
				           |""%1"".'"), NameForLog));
		
		CommitTransaction();
	Except
		RollbackTransaction();
		ErrorInformation = ErrorInfo();
		
		ErrorStructure = New Structure;
		ErrorStructure.Insert("FileName", NameForLog);
		ErrorStructure.Insert("Error",   BriefErrorDescription(ErrorInformation));
		ErrorStructure.Insert("Version",   VersionRef);
		
		FilesArrayWithErrors.Add(ErrorStructure);
		
		WriteLogEvent(NStr("ru = 'Файлы.Ошибка переноса файла в том'; en = 'Files.Cannot move file to volume'; pl = 'Pliki.Nie można przenieść pliku do woluminu';de = 'Dateien. Die Datei kann nicht auf das Volumen übertragen werden';ro = 'Fișiere.Nu puteți transfera fișierul în volum';tr = 'Dosyalar. Dosya birime aktarılamıyor'; es_ES = 'Archivos.No se puede trasladar el archivo al volumen'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,, FileRef,
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'При переносе в том файла
				           |""%1""
				           |возникла ошибка:
				           |""%2"".'; 
				           |en = 'Cannot move file
				           |""%1""
				           |to volume. Reason:
				           |%2'; 
				           |pl = 'Podczas transferu do woluminu pliku
				           |""%1""
				           |wystąpił błąd:
				           |""%2"".';
				           |de = 'Beim Verschieben in das Volume dieser Datei
				           |""%1""
				           | ist ein Fehler aufgetreten:
				           |""%2"".';
				           |ro = 'La transferarea în volum a fișierului
				           |""%1""
				           |s-a produs eroarea:
				           |""%2"".';
				           |tr = '
				           |""%1""
				           | dosya birimine aktarılırken bir hata oluştu: 
				           |""%2"".'; 
				           |es_ES = 'Al trasladar los archivos en el tomo
				           |""%1""
				           |se ha producido un error:
				           |""%2"".'"),
				NameForLog,
				DetailErrorDescription(ErrorInformation)));
				
		ReturnCode = False;
		
	EndTry;
	
	UnlockDataForEdit(FileRef);
	UnlockDataForEdit(VersionRef);
	
	Return ReturnCode;
	
EndFunction

#EndRegion
