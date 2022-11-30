///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// Gets a unique file name for using it in the working directory.
//  If there are matches, the name will look like "A1\Order.doc".
//
Function GetUniqueNameWithPath(DirectoryName, FileName) Export
	
	FinalPath = "";
	
	Counter = 0;
	DoNumber = 0;
	Success = False;
	CodeLetterA = CharCode("A", 1);
	
	RandomValueGenerator = Undefined;
	
#If Not WebClient Then
	RandomValueGenerator = New RandomNumberGenerator(CurrentUniversalDateInMilliseconds());
#EndIf

	RandomOptionsCount = 26;
	
	While NOT Success AND DoNumber < 100 Do
		DirectoryNumber = 0;
		
#If Not WebClient Then
		DirectoryNumber = RandomValueGenerator.RandomNumber(0, RandomOptionsCount - 1);
#Else
		DirectoryNumber = CurrentUniversalDateInMilliseconds() % RandomOptionsCount;
#EndIf

		If Counter > 1 AND RandomOptionsCount < 26 * 26 * 26 * 26 * 26 Then
			RandomOptionsCount = RandomOptionsCount * 26;
		EndIf;
		
		DirectoryLetters = "";
		CodeLetterA = CharCode("A", 1);
		
		While True Do
			LetterNumber = DirectoryNumber % 26;
			DirectoryNumber = Int(DirectoryNumber / 26);
			
			DirectoryCode = CodeLetterA + LetterNumber;
			
			DirectoryLetters = DirectoryLetters + Char(DirectoryCode);
			If DirectoryNumber = 0 Then
				Break;
			EndIf;
		EndDo;
		
		SubDirectory = ""; // Partial path.
		
		// Use the root directory by default. If it is impossible, add A, B, ...
		//  Z, .. ZZZZZ, .. AAAAA, .. AAAAAZ and so on.
		If  Counter = 0 Then
			SubDirectory = "";
		Else
			SubDirectory = DirectoryLetters;
			DoNumber = Round(Counter / 26);
			
			If DoNumber <> 0 Then
				DoNumberString = String(DoNumber);
				SubDirectory = SubDirectory + DoNumberString;
			EndIf;
			
			If IsReservedDirectoryName(SubDirectory) Then
				Continue;
			EndIf;
			
			SubDirectory = CommonClientServer.AddLastPathSeparator(SubDirectory);
		EndIf;
		
		FullSubdirectory = DirectoryName + SubDirectory;
		
		// Creating a directory for files.
		DirectoryOnHardDrive = New File(FullSubdirectory);
		If NOT DirectoryOnHardDrive.Exist() Then
			Try
				CreateDirectory(FullSubdirectory);
			Except
				Raise StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Ошибка при создании каталога ""%1"":
					           |""%2"".'; 
					           |en = 'Cannot create directory ""%1"". Reason:
					           |%2'; 
					           |pl = 'Błąd przy utworzeniu katalogu ""%1"":
					           |""%2"".';
					           |de = 'Fehler beim Erstellen des Verzeichnisses ""%1"":
					           |""%2"".';
					           |ro = 'Eroare la crearea directorului ""%1"":
					           |""%2"".';
					           |tr = '""%1"" dizin oluşturulurken bir hata oluştu: 
					           |""%2"".'; 
					           |es_ES = 'Error al crear el catálogo ""%1"":
					           |""%2"".'"),
					FullSubdirectory,
					BriefErrorDescription(ErrorInfo()) );
			EndTry;
		EndIf;
		
		AttemptFile = FullSubdirectory + FileName;
		Counter = Counter + 1;
		
		// Checking whether the file name is unique
		FileOnHardDrive = New File(AttemptFile);
		If NOT FileOnHardDrive.Exist() Then  // There is no such file.
			FinalPath = SubDirectory + FileName;
			Success = True;
		EndIf;
	EndDo;
	
	Return FinalPath;
	
EndFunction

// Returns True if the file with such extension is in the list of extensions.
Function FileExtensionInList(ExtensionList, FileExtention) Export
	
	FileExtentionWithoutDot = CommonClientServer.ExtensionWithoutPoint(FileExtention);
	
	ExtensionArray = StrSplit(
		Lower(ExtensionList), " ", False);
	
	If ExtensionArray.Find(FileExtentionWithoutDot) <> Undefined Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// For user interface.

// Returns the row of the message that it is forbidden to sign a locked file.
//
Function FileUsedByAnotherProcessCannotBeSignedMessageString(FileRef = Undefined) Export
	
	If FileRef = Undefined Then
		Return NStr("ru = 'Нельзя подписать занятый файл.'; en = 'Cannot sign the file because it is locked.'; pl = 'Nie można podpisać zajętego pliku.';de = 'Gesperrte Datei kann nicht signiert werden.';ro = 'Nu se poate semna un fișier blocat.';tr = 'Kilitli dosya imzalanamıyor'; es_ES = 'No se puede firmar el archivo bloqueado.'");
	Else
		Return StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Нельзя подписать занятый файл: %1.'; en = 'Cannot sign the file %1 because it is locked.'; pl = 'Nie można podpisać zajętego pliku: %1.';de = 'Gesperrte Datei kann nicht signiert werden: %1.';ro = 'Nu se poate semna un fișier blocat: %1.';tr = 'Kilitli dosya imzalanamıyor: %1.'; es_ES = 'No se puede firmar el archivo bloqueado: %1.'"),
			String(FileRef) );
	EndIf;
	
EndFunction

// Returns the row of the message that it is forbidden to sign an encrypted file.
//
Function EncryptedFileCannotBeSignedMessageString(FileRef = Undefined) Export
	
	If FileRef = Undefined Then
		Return NStr("ru = 'Нельзя подписать зашифрованный файл.'; en = 'Cannot sign the file because it is encrypted.'; pl = 'Nie można podpisać zaszyfrowanego pliku.';de = 'Verschlüsselte Datei kann nicht signiert werden.';ro = 'Nu se poate semna fișierul criptat.';tr = 'Şifrelenmiş dosya imzalanamıyor.'; es_ES = 'No se puede firmar el archivo codificado.'");
	Else
		Return StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Нельзя подписать зашифрованный файл: %1.'; en = 'Cannot sign the file %1 because it is encrypted.'; pl = 'Nie można podpisać zaszyfrowanego pliku: %1.';de = 'Verschlüsselte Datei kann nicht signiert werden: %1.';ro = 'Nu se poate semna fișierul criptat: %1.';tr = 'Şifrelenmiş dosya imzalanamıyor: %1.'; es_ES = 'No se puede firmar el archivo codificado: %1.'"),
						String(FileRef) );
	EndIf;
	
EndFunction

// Receive a row representing the file size, for example, to display in the Status when the file is transferred.
Function GetStringWithFileSize(Val SizeInMB) Export
	
	If SizeInMB < 0.1 Then
		SizeInMB = 0.1;
	EndIf;	
	
	SizeString = ?(SizeInMB >= 1, Format(SizeInMB, "NFD=0"), Format(SizeInMB, "NFD=1; NZ=0"));
	Return SizeString;
	
EndFunction	

// The index of the file icon is being received. It is the index in the FilesIconsCollection picture.
Function GetFileIconIndex(Val FileExtention) Export
	
	If TypeOf(FileExtention) <> Type("String")
		OR IsBlankString(FileExtention) Then
		Return 0;
	EndIf;
	
	FileExtention = CommonClientServer.ExtensionWithoutPoint(FileExtention);
	
	Extension = "." + Lower(FileExtention) + ";";
	
	If StrFind(".dt;.1cd;.cf;.cfu;", Extension) <> 0 Then
		Return 6; // 1C files.
		
	ElsIf Extension = ".mxl;" Then
		Return 8; // Spreadsheet File.
		
	ElsIf StrFind(".txt;.log;.ini;", Extension) <> 0 Then
		Return 10; // Text File.
		
	ElsIf Extension = ".epf;" Then
		Return 12; // External data processors.
		
	ElsIf StrFind(".ico;.wmf;.emf;",Extension) <> 0 Then
		Return 14; // Pictures.
		
	ElsIf StrFind(".htm;.html;.url;.mht;.mhtml;",Extension) <> 0 Then
		Return 16; // HTML.
		
	ElsIf StrFind(".doc;.dot;.rtf;",Extension) <> 0 Then
		Return 18; // Microsoft Word file.
		
	ElsIf StrFind(".xls;.xlw;",Extension) <> 0 Then
		Return 20; // Microsoft Excel file.
		
	ElsIf StrFind(".ppt;.pps;",Extension) <> 0 Then
		Return 22; // Microsoft PowerPoint file.
		
	ElsIf StrFind(".vsd;",Extension) <> 0 Then
		Return 24; // Microsoft Visio file.
		
	ElsIf StrFind(".mpp;",Extension) <> 0 Then
		Return 26; // Microsoft Visio file.
		
	ElsIf StrFind(".mdb;.adp;.mda;.mde;.ade;",Extension) <> 0 Then
		Return 28; // Microsoft Access database.
		
	ElsIf StrFind(".xml;",Extension) <> 0 Then
		Return 30; // xml.
		
	ElsIf StrFind(".msg;.eml;",Extension) <> 0 Then
		Return 32; // Email.
		
	ElsIf StrFind(".zip;.rar;.arj;.cab;.lzh;.ace;",Extension) <> 0 Then
		Return 34; // Archives.
		
	ElsIf StrFind(".exe;.com;.bat;.cmd;",Extension) <> 0 Then
		Return 36; // Files being executed.
		
	ElsIf StrFind(".grs;",Extension) <> 0 Then
		Return 38; // Graphical schema.
		
	ElsIf StrFind(".geo;",Extension) <> 0 Then
		Return 40; // Geographical schema.
		
	ElsIf StrFind(".jpg;.jpeg;.jp2;.jpe;",Extension) <> 0 Then
		Return 42; // jpg.
		
	ElsIf StrFind(".bmp;.dib;",Extension) <> 0 Then
		Return 44; // bmp.
		
	ElsIf StrFind(".tif;.tiff;",Extension) <> 0 Then
		Return 46; // tif.
		
	ElsIf StrFind(".gif;",Extension) <> 0 Then
		Return 48; // gif.
		
	ElsIf StrFind(".png;",Extension) <> 0 Then
		Return 50; // png.
		
	ElsIf StrFind(".pdf;",Extension) <> 0 Then
		Return 52; // pdf.
		
	ElsIf StrFind(".odt;",Extension) <> 0 Then
		Return 54; // Open Office writer.
		
	ElsIf StrFind(".odf;",Extension) <> 0 Then
		Return 56; // Open Office math.
		
	ElsIf StrFind(".odp;",Extension) <> 0 Then
		Return 58; // Open Office Impress.
		
	ElsIf StrFind(".odg;",Extension) <> 0 Then
		Return 60; // Open Office draw.
		
	ElsIf StrFind(".ods;",Extension) <> 0 Then
		Return 62; // Open Office calc.
		
	ElsIf StrFind(".mp3;",Extension) <> 0 Then
		Return 64;
		
	ElsIf StrFind(".erf;",Extension) <> 0 Then
		Return 66; // External reports.
		
	ElsIf StrFind(".docx;",Extension) <> 0 Then
		Return 68; // Microsoft Word docx file.
		
	ElsIf StrFind(".xlsx;",Extension) <> 0 Then
		Return 70; // Microsoft Excel xlsx file.
		
	ElsIf StrFind(".pptx;",Extension) <> 0 Then
		Return 72; // Microsoft PowerPoint pptx file.
		
	ElsIf StrFind(".p7s;",Extension) <> 0 Then
		Return 74; // Signature file
		
	ElsIf StrFind(".p7m;",Extension) <> 0 Then
		Return 76; // encrypted message.
	Else
		Return 4;
	EndIf;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Other

// For internal use only.
Procedure FillSignatureStatus(SignatureRow) Export
	
	If Not ValueIsFilled(SignatureRow.SignatureValidationDate) Then
		SignatureRow.Status = "";
		Return;
	EndIf;
	
	If SignatureRow.SignatureCorrect Then
		SignatureRow.Status = NStr("ru = 'Верна'; en = 'Valid'; pl = 'Napraw';de = 'Korrigieren';ro = 'Corect';tr = 'Düzelt'; es_ES = 'Correcto'");
	Else
		SignatureRow.Status = NStr("ru = 'Неверна'; en = 'Invalid'; pl = 'Błędna';de = 'Falsche';ro = 'Incorect';tr = 'Yanlış'; es_ES = 'Incorrecto'");
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// File synchronization

Function AddressInCloudService(Service, Href) Export
	
	ObjectAddress = Href;
	
	If Not IsBlankString(Service) Then
		If Service = "https://webdav.yandex.ru" Then
			ObjectAddress = StrReplace(Href, "https://webdav.yandex.ru", "https://disk.yandex.ru/client/disk");
		ElsIf Service = "https://webdav.4shared.com" Then
			ObjectAddress = "http://www.4shared.com/folder";
		ElsIf Service = "https://dav.box.com/dav" Then
			ObjectAddress = "https://app.box.com/files/0/";
		ElsIf Service = "https://dav.dropdav.com" Then
			ObjectAddress = "https://www.dropbox.com/home/";
		EndIf;
	EndIf;
	
	Return ObjectAddress;
	
EndFunction

#Region TextExtraction

// Extracts text in the specified encoding.
// If encoding is not specified, it calculates the encoding itself.
//
Function ExtractTextFromTextFile(FullFileName, Encoding, Cancel) Export
	
	ExtractedText = "";
	
#If Not WebClient Then
	
	// Determining encoding.
	If Not ValueIsFilled(Encoding) Then
		Encoding = Undefined;
	EndIf;
	
	Try
		EncodingForRead = ?(Encoding = "utf-8_WithoutBOM", "utf-8", Encoding);
		TextReader = New TextReader(FullFileName, EncodingForRead);
		ExtractedText = TextReader.Read();
	Except
		Cancel = True;
		ExtractedText = "";
	EndTry;
	
#EndIf
	
	Return ExtractedText;
	
EndFunction

// Extracts text from an OpenDocument file and returns it as a string.
//
Function ExtractOpenDocumentText(PathToFile, Cancel) Export
	
	ExtractedText = "";
	
#If Not WebClient AND NOT MobileClient Then
	
	TemporaryFolderForUnzipping = GetTempFileName("");
	TemporaryZIPFile = GetTempFileName("zip"); 
	
	FileCopy(PathToFile, TemporaryZIPFile);
	File = New File(TemporaryZIPFile);
	File.SetReadOnly(False);

	Try
		Archive = New ZipFileReader();
		Archive.Open(TemporaryZIPFile);
		Archive.ExtractAll(TemporaryFolderForUnzipping, ZIPRestoreFilePathsMode.Restore);
		Archive.Close();
		XMLReader = New XMLReader();
		
		XMLReader.OpenFile(TemporaryFolderForUnzipping + "/content.xml");
		ExtractedText = ExtractTextFromXMLContent(XMLReader);
		XMLReader.Close();
	Except
		// This is not an error because the OTF extension, for example, is related both to OpenDocument format and OpenType font format.
		Archive     = Undefined;
		XMLReader = Undefined;
		Cancel = True;
		ExtractedText = "";
	EndTry;
	
	DeleteFiles(TemporaryFolderForUnzipping);
	DeleteFiles(TemporaryZIPFile);
	
#EndIf
	
	Return ExtractedText;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

// Extract text from the XMLReader object (that was read from an OpenDocument file).
Function ExtractTextFromXMLContent(XMLReader)
	
	ExtractedText = "";
	LastTagName = "";
	
#If Not WebClient Then
	
	While XMLReader.Read() Do
		
		If XMLReader.NodeType = XMLNodeType.StartElement Then
			
			LastTagName = XMLReader.Name;
			
			If XMLReader.Name = "text:p" Then
				If NOT IsBlankString(ExtractedText) Then
					ExtractedText = ExtractedText + Chars.LF;
				EndIf;
			EndIf;
			
			If XMLReader.Name = "text:line-break" Then
				If NOT IsBlankString(ExtractedText) Then
					ExtractedText = ExtractedText + Chars.LF;
				EndIf;
			EndIf;
			
			If XMLReader.Name = "text:tab" Then
				If NOT IsBlankString(ExtractedText) Then
					ExtractedText = ExtractedText + Chars.Tab;
				EndIf;
			EndIf;
			
			If XMLReader.Name = "text:s" Then
				
				AdditionString = " "; // space
				
				If XMLReader.AttributeCount() > 0 Then
					While XMLReader.ReadAttribute() Do
						If XMLReader.Name = "text:c"  Then
							SpaceCount = Number(XMLReader.Value);
							AdditionString = "";
							For Index = 0 To SpaceCount - 1 Do
								AdditionString = AdditionString + " "; // space
							EndDo;
						EndIf;
					EndDo
				EndIf;
				
				If NOT IsBlankString(ExtractedText) Then
					ExtractedText = ExtractedText + AdditionString;
				EndIf;
			EndIf;
			
		EndIf;
		
		If XMLReader.NodeType = XMLNodeType.Text Then
			
			If StrFind(LastTagName, "text:") <> 0 Then
				ExtractedText = ExtractedText + XMLReader.Value;
			EndIf;
			
		EndIf;
		
	EndDo;
	
#EndIf

	Return ExtractedText;
	
EndFunction

// Receive scanned file name of the type DM-00000012, where DM is base prefix.
//
// Parameters:
//  FileNumber  - Number - an integer, for example, 12.
//  BasePrefix - String - a base prefix, for example, DM.
//
// Returns:
//  String - the scanned file name, for example, "DM-00000012".
//
Function ScannedFileName(FileNumber, BasePrefix) Export
	
	FileName = "";
	If NOT IsBlankString(BasePrefix) Then
		FileName = BasePrefix + "-";
	EndIf;
	
	FileName = FileName + Format(FileNumber, "ND=9; NLZ=; NG=0");
	Return FileName;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Auxiliary procedures and functions.

Function IsReservedDirectoryName(SubDirectoryName)
	
	NamesList = New Map();
	NamesList.Insert("CON", True);
	NamesList.Insert("PRN", True);
	NamesList.Insert("AUX", True);
	NamesList.Insert("NUL", True);
	
	Return NamesList[SubDirectoryName] <> Undefined;
	
EndFunction

#EndRegion