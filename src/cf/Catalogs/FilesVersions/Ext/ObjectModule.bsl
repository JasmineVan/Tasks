///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If AdditionalProperties.Property("FileConversion") Then
		Return;
	EndIf;
	
	If AdditionalProperties.Property("FilePlacementInVolumes") Then
		Return;
	EndIf;
	
	If IsNew() Then
		ParentVersion = Owner.CurrentVersion;
	EndIf;
	
	// Setting an icon index upon object write.
	PictureIndex = FilesOperationsInternalClientServer.GetFileIconIndex(Extension);
	
	If TextExtractionStatus.IsEmpty() Then
		TextExtractionStatus = Enums.FileTextExtractionStatuses.NotExtracted;
	EndIf;
	
	If TypeOf(Owner) = Type("CatalogRef.Files") Then
		Description = TrimAll(FullDescr);
	EndIf;
	
	If Owner.CurrentVersion = Ref Then
		If DeletionMark = True AND Owner.DeletionMark <> True Then
			Raise NStr("ru = 'Активную версию нельзя удалить.'; en = 'Cannot delete the active version.'; pl = 'Nie można usunąć aktywnej wersji.';de = 'Aktive Version kann nicht gelöscht werden.';ro = 'Versiunea activă nu poate fi ștearsă.';tr = 'Aktif sürüm silinemez.'; es_ES = 'Versión del archivo no puede borrarse.'");
		EndIf;
	ElsIf ParentVersion.IsEmpty() Then
		If DeletionMark = True AND Owner.DeletionMark <> True Then
			Raise NStr("ru = 'Первую версию нельзя удалить.'; en = 'Cannot delete the first version.'; pl = 'Pierwsza wersja nie może zostać usunięta.';de = 'Die erste Version kann nicht gelöscht werden.';ro = 'Prima versiune nu poate fi ștearsă.';tr = 'İlk sürüm silinemez.'; es_ES = 'La primera versión no puede borrarse.'");
		EndIf;
	ElsIf DeletionMark = True AND Owner.DeletionMark <> True Then
		// Clearing a reference to a parent version for versions that are child to the marked one, 
		// specifying parent version of the version to be deleted.
		Query = New Query;
		Query.Text = 
			"SELECT
			|	FilesVersions.Ref AS Ref
			|FROM
			|	Catalog." + Metadata.FindByType(TypeOf(Ref)).Name + " AS FilesVersions
			|WHERE
			|	FilesVersions.ParentVersion = &ParentVersion";
		
		Query.SetParameter("ParentVersion", Ref);
		
		Result = Query.Execute();
		BeginTransaction();
		Try
			If Not Result.IsEmpty() Then
				Selection = Result.Select();
				Selection.Next();
				
				DataLock = New DataLock;
				DataLockItem = DataLock.Add(Metadata.FindByType(TypeOf(Selection.Ref)).FullName());
				DataLockItem.SetValue("Ref", Selection.Ref);
				DataLock.Lock();
				
				Object = Selection.Ref.GetObject();
				
				LockDataForEdit(Object.Ref);
				Object.ParentVersion = ParentVersion;
				Object.Write();
			EndIf;
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	EndIf;
	
EndProcedure

Procedure BeforeDelete(Cancel)
	
	If FileStorageType = Enums.FileStorageTypes.InVolumesOnHardDrive Then
		If NOT Volume.IsEmpty() AND Common.RefExists(Volume) Then
			FullPath = FilesOperationsInternal.FullVolumePath(Volume) + PathToFile; 
			Try
				File = New File(FullPath);
				File.SetReadOnly(False);
				DeleteFiles(FullPath);
				
				PathWithSubdirectory = File.Path;
				FilesArrayInDirectory = FindFiles(PathWithSubdirectory, GetAllFilesMask());
				If FilesArrayInDirectory.Count() = 0 Then
					DeleteFiles(PathWithSubdirectory);
				EndIf;
				
			Except
				
				WriteLogEvent(NStr("ru = 'Файлы.Ошибка удаления файла.'; en = 'Files.File deletion error.'; pl = 'Pliki.Błąd usuwania pliku.';de = 'Dateien.Fehler beim Löschen von Dateien.';ro = 'Fișiere.Eroare de ștergere a fișierului.';tr = 'Dosyalar. Dosya silme hatası.'; es_ES = 'Archivos.Error de eliminar el archivo'", 
					Common.DefaultLanguageCode()),
					EventLogLevel.Error,,
					File, ErrorDescription());
				
			EndTry;
		EndIf;
	EndIf;
	
	// Check DataExchange.Import starting from this row.
	// Firstly physically delete the file, and then delete information on it in the infobase.
	// Otherwise, file location information will be unavailable.
	If DataExchange.Load Then
		Return;
	EndIf;
	
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Niedozwolone wezwanie obiektu na kliencie.';de = 'Unzulässiger Objektaufruf auf dem Client.';ro = 'Apel inadmisibil al obiectului pe client.';tr = 'İstemcide kabul edilmeyen nesne çağrısı.'; es_ES = 'Llamada no disponible del objeto en el cliente.'");
#EndIf