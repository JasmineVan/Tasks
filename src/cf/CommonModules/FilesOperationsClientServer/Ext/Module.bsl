///////////////////////////////////////////////////////////////////////////////////////////////////////
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

// Initializes parameter structure to get file data. See FilesOperations.FileData. 
//
// Returns:
//  Structure - with the following properties:
//    * FormID             - UUID - a form UUID. The method puts the file to the temporary storage 
//                                     of this form and returns the address in the RefToBinaryFileData property.
//                                     Default value is Undefined.
//    * GetRefToBinaryData - Boolean - if False, reference to the binary data in the 
//                                     RefToBinaryFileData is not received thus significantly speeding up execution for large binary data.
//                                     Default value is True.
//    * ForEditing              - Boolean - if you specify True, a file will be locked for editing.
//                                     Default value is False.
//    * RaiseException             - Boolean - if you specify True, the function will not raise 
//                                     exceptions in exceptional situations and will return Undefined. Default value is True.
//
Function FileDataParameters() Export
	
	DataParameters = New Structure;
	DataParameters.Insert("ForEditing",              False);
	DataParameters.Insert("FormID",             Undefined);
	DataParameters.Insert("RaiseException",             True);
	DataParameters.Insert("GetBinaryDataRef", True);
	Return DataParameters;
	
EndFunction

#Region ObsoleteProceduresAndFunctions
////////////////////////////////////////////////////////////////////////////////
// Event subscription handlers.

// Obsolete. Use FilesOperations.DefiineAttachedFileForm.
// Handler of the subscription to FormGetProcessing event for overriding file form.
//
// Parameters:
//  Source                 - CatalogManager - the *AttachedFiles catalog manager.
//  FormKind                 - String - a standard form name.
//  Parameters                - Structure - structure parameters.
//  SelectedForm           - String - name or metadata object of opened form.
//  AdditionalInformation - Structure - an additional information of the form opening.
//  StandardProcessing     - Boolean - a flag of standard (system) event processing execution.
//
Procedure DetermineAttachedFileForm(Source,
                                                      FormKind,
                                                      Parameters,
                                                      SelectedForm,
                                                      AdditionalInformation,
                                                      StandardProcessing) Export
	
	FilesOperationsInternalServerCall.DetermineAttachedFileForm(
		Source,
		FormKind,
		Parameters,
		SelectedForm,
		AdditionalInformation,
		StandardProcessing);
		
EndProcedure

#EndRegion

#EndRegion

#Region Internal

// Initializes the structure with file data.
//
// Parameters:
//   Mode        - String - File or FileWithVersion.
//   SourceFile - FIle   - the file on whose basis the structure properties are filled.
//
// Returns:
//   Structure - with the following properties:
//    * BaseName             - String - file name without extension.
//    * ExtensionWithPoint           - String - a file extension.
//    * ModificationTime               - Date - date and time of file modification.
//    * ModificationTimeUniversal  - Date   - UTC date and time of file modificaion.
//    * Size                       - Number  - file size in bytes.
//    * FileTemporaryStorageAddress  - String, ValueStorage - address in temporary storage with 
//                                       binary data of the file or file binary data itself.
//    * TextTemporaryStorageAddress - String, ValueStorage - address in temporary storage with 
//                                       extracted texts for FTS or directly the data with text itself.
//    * IsWebClient                 - Boolean - True if a call comes from the web client.
//    * Author                        - CatalogRef.Users - a file author. If Undefined, a current 
//                                                                     user.
//    * Comment                  - String - a comment to the file.
//    * WriteToHistory             - Boolean - write to user work history.
//    * StoreVersions                - Boolean - allow storing file versions in the infobase.
//                                              when creating a new version, create a new version, 
//                                              or modify an existing one (False).
//    * Encrypted                   - Boolean - file is encrypted.
//
Function FileInfo(Val Mode, Val SourceFile = Undefined) Export
	
	Result = New Structure;
	Result.Insert("BaseName");
	Result.Insert("Comment", "");
	Result.Insert("TempTextStorageAddress");
	Result.Insert("Author");
	Result.Insert("FilesStorageCatalogName", "Files");
	Result.Insert("TempFileStorageAddress");
	Result.Insert("ExtensionWithoutPoint");
	Result.Insert("Modified", Date('00010101'));
	Result.Insert("ModificationTimeUniversal", Date('00010101'));
	Result.Insert("Size", 0);
	Result.Insert("Encrypted");
	Result.Insert("WriteToHistory", False);
	Result.Insert("Encoding");
	Result.Insert("NewTextExtractionStatus");
	If Mode = "FileWithVersion" Then
		Result.Insert("StoreVersions", True);
		Result.Insert("RefToVersionSource");
		Result.Insert("NewVersionCreationDate");
		Result.Insert("NewVersionAuthor");
		Result.Insert("NewVersionComment");
		Result.Insert("NewVersionVersionNumber");
	Else
		Result.Insert("StoreVersions", False);
	EndIf;
	
	If SourceFile <> Undefined Then
		Result.BaseName            = SourceFile.BaseName;
		Result.ExtensionWithoutPoint          = CommonClientServer.ExtensionWithoutPoint(SourceFile.Extension);
		Result.Modified              = SourceFile.GetModificationTime();
		Result.ModificationTimeUniversal = SourceFile.GetModificationUniversalTime();
		Result.Size                      = SourceFile.Size();
	EndIf;
	Return Result;
	
EndFunction

#EndRegion

#Region Private

// Determine whether the file can be locked and if not, generate the error text.
//
// Parameters:
//  FileData  - Structure - a structure with file data.
//  ErrorRow - String - (return value) - if the file cannot be locked, then it contains an error 
//                 description.
//
// Returns:
//  Boolean - if True, then the current user may lock the file or the file is already locked by the 
//           current user.
//
Function WhetherPossibleLockFile(FileData, ErrorRow = "") Export
	
	If FileData.DeletionMark = True Then
		ErrorRow = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Нельзя занять файл ""%1"",
			           |т.к. он помечен на удаление.'; 
			           |en = 'Cannot lock file ""%1""
			           |as it is marked for deletion.'; 
			           |pl = 'Nie można zająć
			           |pliku ""%1"", ponieważ jest on zaznaczony do usunięcia.';
			           |de = 'Unmöglich, Datei zu 
			           |besetzen ""%1"", so. Es ist zum Löschen markiert.';
			           |ro = 'Imposibil de ocupat fișierul ""%1"",
			           |deoarece el este marcat pentru ștergere.';
			           |tr = '"
" dosyası silinmek üzere işaretlendiği için %1 işgal edilemez. '; 
			           |es_ES = 'Imposible
			           |ocupar el archivo ""%1"", porque está marcado para borrar.'"),
			String(FileData.Ref));
		Return False;
	EndIf;
	
	Result = Not ValueIsFilled(FileData.BeingEditedBy) Or FileData.CurrentUserEditsFile;  
	
	If Not Result Then
		
		LoanDate = ?(ValueIsFilled(FileData.LoanDate), 
			" " + NStr("ru='с'; en = 'on'; pl = 'z dnia';de = 'von';ro = 'de la';tr = 'itibaren'; es_ES = 'desde'") + " " + Format(FileData.LoanDate, "DLF=DT"), "");
		
		ErrorRow = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Файл ""%1""
			           |уже занят для редактирования пользователем
			           |""%2""%3.'; 
			           |en = 'The ""%1"" file
			           |is already locked for editing by user
			           |""%2""%3.'; 
			           |pl = 'Plik ""%1""
			           |jest już zajęty do edycji przez użytkownika
			           |""%2""%3.';
			           |de = 'Die Datei ""%1""
			           |ist bereits für die Bearbeitung durch den Benutzer 
			           |""%2""%3 belegt.';
			           |ro = 'Fișierul ""%1""
			           |este deja blocat pentru editare de către utilizator
			           |""%2""%3.';
			           |tr = '"
" dosyası %1 düzenleme için "
" kullanıcı tarafından %3 zaten kilitlendi%2. '; 
			           |es_ES = 'El archivo ""%1""
			           |está ocupado ya para editar por usuario
			           |""%2""%3.'"),
			String(FileData.Ref), String(FileData.BeingEditedBy), LoanDate);
			
	EndIf;
		
	Return Result;
	
EndFunction

#EndRegion