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
	
	CurrentFolder = Common.ObjectAttributesValues(Ref,
		"Description, Parent, DeletionMark");
	
	If IsNew() Or CurrentFolder.Parent <> Parent Then
		// Check rights to a source folder.
		If NOT FilesOperationsInternal.HasRight("FoldersModification", CurrentFolder.Parent) Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Недостаточно прав для перемещения из папки файлов ""%1"".'; en = 'Insufficient rights to move files from the ""%1"" folder.'; pl = 'Niewystarczające uprawnienia do przemieszczenia z folderu plików ""%1"".';de = 'Nicht genügend Rechte, um aus dem Dateiordner ""%1"" zu wechseln.';ro = 'Drepturi insuficiente pentru transferare din folderul de fișiere ""%1"".';tr = '""%1"" dosya klasörünü taşımak için haklar yetersiz.'; es_ES = 'Insuficientes derechos para mover de la carpeta de archivos ""%1"".'"),
				String(?(ValueIsFilled(CurrentFolder.Parent), CurrentFolder.Parent, NStr("ru = 'Папки'; en = 'Folders'; pl = 'Foldery';de = 'Ordner';ro = 'Dosare';tr = 'Klasörler'; es_ES = 'Carpetas'"))));
		EndIf;
		// Check rights to a destination folder.
		If NOT FilesOperationsInternal.HasRight("FoldersModification", Parent) Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Недостаточно прав для добавления подпапок в папку файлов ""%1"".'; en = 'Insufficient rights to add subfolders to the ""%1"" folder.'; pl = 'Niewystarczające uprawnienia do dodawania podfolderów do folderu plików ""%1"".';de = 'Unzureichende Rechte zum Hinzufügen von Unterordnern zum Dateiordner ""%1"".';ro = 'Drepturi insuficiente pentru a adăuga subdirectoare în dosarul ""%1"".';tr = '""%1"" dosya klasörüne alt klasörleri eklemek için haklar yetersiz'; es_ES = 'Insuficientes derechos para añadir subcarpetas a la carpeta de archivos ""%1"".'"),
				String(?(ValueIsFilled(Parent), Parent, NStr("ru = 'Папки'; en = 'Folders'; pl = 'Foldery';de = 'Ordner';ro = 'Dosare';tr = 'Klasörler'; es_ES = 'Carpetas'"))));
		EndIf;
	EndIf;
	
	If DeletionMark AND CurrentFolder.DeletionMark <> True Then
		
		// Checking the "Deletion mark" right.
		If NOT FilesOperationsInternal.HasRight("FoldersModification", Ref) Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Недостаточно прав для изменения папки файлов ""%1"".'; en = 'Insufficient rights to change the ""%1"" file folder.'; pl = 'Niewystarczające uprawnienia do zmiany folderu ""%1"".';de = 'Unzureichende Rechte zum Ändern des Dateiordners ""%1"".';ro = 'Drepturi insuficiente pentru a schimba directorul de fișiere ""%1"".';tr = '""%1"" dosya klasörünü değiştirmek için haklar yetersiz.'; es_ES = 'Insuficientes derechos para cambiar la carpeta de archivos ""%1"".'"),
				String(Ref));
		EndIf;
	EndIf;
	
	If DeletionMark <> CurrentFolder.DeletionMark AND Not Ref.IsEmpty() Then
		// Filtering files and trying to mark them for deletion.
		Query = New Query;
		Query.Text = 
			"SELECT
			|	Files.Ref,
			|	Files.BeingEditedBy
			|FROM
			|	Catalog.Files AS Files
			|WHERE
			|	Files.FileOwner = &Ref";
		
		Query.SetParameter("Ref", Ref);
		
		Result = Query.Execute();
		Selection = Result.Select();
		While Selection.Next() Do
			If ValueIsFilled(Selection.BeingEditedBy) Then
				Raise StringFunctionsClientServer.SubstituteParametersToString(
				                     NStr("ru = 'Папку %1 нельзя удалить, т.к. она содержит файл ""%2"", занятый для редактирования.'; en = 'Cannot delete the %1 folder as it contains the ""%2"" file that is locked for editing.'; pl = 'Folderu %1 nie można usunąć, ponieważ zawiera on plik ""%2"" zajęty dla redagowania.';de = 'Der Ordner %1 kann nicht gelöscht werden, da er die Datei ""%2"" enthält, die für die Bearbeitung gesperrt ist.';ro = 'Folderul %1 nu poate fi șters deoarece conține fișierul ""%2"" care este blocat pentru editare.';tr = 'Klasör %1, düzenleme için kilitli olan ""%2"" dosyasını içerdiğinden silinemez.'; es_ES = 'La carpeta %1 no puede borrarse, porque contiene el archivo ""%2"" que está bloqueado para editar.'"),
				                     String(Ref),
				                     String(Selection.Ref));
			EndIf;

			FileObject = Selection.Ref.GetObject();
			FileObject.Lock();
			FileObject.SetDeletionMark(DeletionMark);
		EndDo;
	EndIf;
	
	AdditionalProperties.Insert("PreviousIsNew", IsNew());
	
	If NOT IsNew() Then
		
		If Description <> CurrentFolder.Description Then // folder is renamed
			FolderWorkingDirectory         = FilesOperationsInternalServerCall.FolderWorkingDirectory(Ref);
			FolerParentWorkingDirectory = FilesOperationsInternalServerCall.FolderWorkingDirectory(CurrentFolder.Parent);
			If FolerParentWorkingDirectory <> "" Then
				
				// Adding a slash mark at the end if it is not there.
				FolerParentWorkingDirectory = CommonClientServer.AddLastPathSeparator(
					FolerParentWorkingDirectory);
				
				InheritedFolerWorkingDirectoryPrevious = FolerParentWorkingDirectory
					+ CurrentFolder.Description + GetPathSeparator();
					
				If InheritedFolerWorkingDirectoryPrevious = FolderWorkingDirectory Then
					
					NewFolderWorkingDirectory = FolerParentWorkingDirectory
						+ Description + GetPathSeparator();
					
					FilesOperationsInternalServerCall.SaveFolderWorkingDirectory(Ref, NewFolderWorkingDirectory);
				EndIf;
			EndIf;
		EndIf;
		
		If Parent <> CurrentFolder.Parent Then // Folder is moved to another folder.
			FolderWorkingDirectory               = FilesOperationsInternalServerCall.FolderWorkingDirectory(Ref);
			FolerParentWorkingDirectory       = FilesOperationsInternalServerCall.FolderWorkingDirectory(CurrentFolder.Parent);
			NewFolderParentWorkingDirectory = FilesOperationsInternalServerCall.FolderWorkingDirectory(Parent);
			
			If FolerParentWorkingDirectory <> "" OR NewFolderParentWorkingDirectory <> "" Then
				
				InheritedFolerWorkingDirectoryPrevious = FolerParentWorkingDirectory;
				
				If FolerParentWorkingDirectory <> "" Then
					InheritedFolerWorkingDirectoryPrevious = FolerParentWorkingDirectory
						+ CurrentFolder.Description + GetPathSeparator();
				EndIf;
				
				// Working directory is created automatically from a parent.
				If InheritedFolerWorkingDirectoryPrevious = FolderWorkingDirectory Then
					If NewFolderParentWorkingDirectory <> "" Then
						
						NewFolderWorkingDirectory = NewFolderParentWorkingDirectory
							+ Description + GetPathSeparator();
						
						FilesOperationsInternalServerCall.SaveFolderWorkingDirectory(Ref, NewFolderWorkingDirectory);
					Else
						FilesOperationsInternalServerCall.CleanUpWorkingDirectory(Ref);
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If AdditionalProperties.PreviousIsNew Then
		FolderWorkingDirectory = FilesOperationsInternalServerCall.FolderWorkingDirectory(Parent);
		If FolderWorkingDirectory <> "" Then
			
			// Adding a slash mark at the end if it is not there.
			FolderWorkingDirectory = CommonClientServer.AddLastPathSeparator(
				FolderWorkingDirectory);
			
			FolderWorkingDirectory = FolderWorkingDirectory
				+ Description + GetPathSeparator();
			
			FilesOperationsInternalServerCall.SaveFolderWorkingDirectory(Ref, FolderWorkingDirectory);
		EndIf;
	EndIf;
	
EndProcedure

Procedure Filling(FillingData, FillingText, StandardProcessing)
	CreationDate = CurrentSessionDate();
	EmployeeResponsible = Users.AuthorizedUser();
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	FoundProhibitedCharsArray = CommonClientServer.FindProhibitedCharsInFileName(Description);
	If FoundProhibitedCharsArray.Count() <> 0 Then
		Cancel = True;
		
		Text = NStr("ru = 'Наименование папки содержит запрещенные символы ( \ / : * ? "" < > | .. )'; en = 'The folder name contains characters that are not allowed ( \ / : * ? "" < > | .. )'; pl = 'Nazwa folderu zawiera niedozwolone znaki (\ /: *? "" < > | ..)';de = 'Ordnername enthält verbotene Zeichen (\ /: *? "" < > | ..)';ro = 'Numele folderului conține caractere interzise ( \  / : * ? "" < > | ..)';tr = 'Klasör adı yasaklanmış karakterler içeriyor (\ /: *? ""< >| ..)'; es_ES = 'Nombre de la carpeta contiene los símbolos prohibidos ( \ / : * ? "" < > | .. )'");
		Common.MessageToUser(Text, ThisObject, "Description");
	EndIf;
	
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Niedozwolone wezwanie obiektu na kliencie.';de = 'Unzulässiger Objektaufruf auf dem Client.';ro = 'Apel inadmisibil al obiectului pe client.';tr = 'İstemcide kabul edilmeyen nesne çağrısı.'; es_ES = 'Llamada no disponible del objeto en el cliente.'");
#EndIf