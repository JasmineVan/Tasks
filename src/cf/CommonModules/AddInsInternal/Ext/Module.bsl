///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// Add-in presentation for the event log
//
Function AddInPresentation(ID, Version) Export
	
	If ValueIsFilled(Version) Then 
		AddInPresentation = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = '%1 (версии %2)'; en = '%1(version %2)'; pl = '%1(version %2)';de = '%1(version %2)';ro = '%1(version %2)';tr = '%1(version %2)'; es_ES = '%1(version %2)'"), 
			ID, 
			Version);
	Else 
		AddInPresentation = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = '%1 (последней версии)'; en = '%1 (latest version)'; pl = '%1 (latest version)';de = '%1 (latest version)';ro = '%1 (latest version)';tr = '%1 (latest version)'; es_ES = '%1 (latest version)'"), 
			ID, 
			Version);
	EndIf;
	
	Return AddInPresentation;
	
EndFunction

// Checks whether the add-ins import from the portal is allowed.
//
// Returns:
//  Boolean - flag of availability.
//
Function ImportFromPortalIsAvailable() Export 
	
	If Common.SubsystemExists("OnlineUserSupport.GetAddIns") Then 
		ModuleGetAddIns = Common.CommonModule("GetAddIns");
		Return ModuleGetAddIns.AddInsImportAvailable();
	EndIf;
	
	Return False;
	
EndFunction

// Parse an add-in file to receive service data on add-in
//
// Parameters:
//  FileStorageAddress - String - address of storage with add-in file binary data.
//  ParseInfoFile - Boolean - (optional) whether INFO.XML file data is required to analise 
//          additionally.
//  AdditionalInformationSearchParameters - Map - (optional)
//          See AddInClient.ImportParameters. 
//
// Returns:
//  Disassembled - content of information.
//      * Disassembled - Boolean - shows whether the component is disassembled successfully.
//      * Attributes - Structure - disassembled component attributes.
//          ** Windows_x86 - Boolean
//          ** Windows_x86_64 - Boolean
//          ** Linux_x86 - Boolean
//          ** Linux_x86_64 - Boolean
//          ** Windows_x86_Firefox - Boolean
//          ** Linux_x86_Firefox - Boolean
//          ** Linux_x86_64_Firefox - Boolean
//          ** Windows_x86_MSIE - Boolean
//          ** Windows_x86_64_MSIE - Boolean
//          ** Windows_x86_Chrome - Boolean
//          ** Linux_x86_Chrome - Boolean
//          ** Linux_x86_64_Chrome - Boolean
//          ** MacOS_x86_64_Safari - Boolean
//          ** ID - String
//          ** Description - String.
//          ** Version - String
//          ** VersionDate - Date
//          ** FileName - String.
//      * BinaryData - BinaryData - add-in file export.
//      * AdditionalInformation - Map - information received by passed search parameters.
//      * ErrorDescription - String - an error text if parsing failed.
//
Function InformationOnAddInFromFile(FileStorageAddress, ParseInfoFile = True, 
	Val AdditionalInformationSearchParameters = Undefined) Export
	
	If AdditionalInformationSearchParameters = Undefined Then 
		AdditionalInformationSearchParameters = New Map;
	EndIf;
	
	// Values are default.
	Attributes = AddInAttributes();
	
	// Additional requested information.
	AdditionalInformation = New Map;
	
	// Add-in binary data receipt and import.
	BinaryData = GetFromTempStorage(FileStorageAddress);
	
	// Clear allocated file in the storage
	DeleteFromTempStorage(FileStorageAddress);
	
	// Add-in map comtrol.
	ManifestIsFound = False;
	
	// Data parsing of component archive.
	Try
		Thread = BinaryData.OpenStreamForRead();
		ReadingArchive = New ZipFileReader(Thread);
	Except
		ErrorText = NStr("ru = 'В файле отсутствует информация о компоненте.'; en = 'Add-in information is missing in the file.'; pl = 'Add-in information is missing in the file.';de = 'Add-in information is missing in the file.';ro = 'Add-in information is missing in the file.';tr = 'Add-in information is missing in the file.'; es_ES = 'Add-in information is missing in the file.'");
		
		Result = AddInParsingResult();
		Result.ErrorDescription = ErrorText;
		
		Return Result;
	EndTry;
	
	TempDirectory = FileSystem.CreateTemporaryDirectory("ExtComp");
	
	For Each ArchiveItem In ReadingArchive.Items Do
		
		If ArchiveItem.Encrypted Then
			
			// Clear temporary files and memory.
			FileSystem.DeleteTemporaryDirectory(TempDirectory);
			ReadingArchive.Close();
			Thread.Close();
			
			ErrorText = NStr("ru = 'ZIP-архив не должен быть зашифрован.'; en = 'ZIP archive must not be encrypted.'; pl = 'ZIP archive must not be encrypted.';de = 'ZIP archive must not be encrypted.';ro = 'ZIP archive must not be encrypted.';tr = 'ZIP archive must not be encrypted.'; es_ES = 'ZIP archive must not be encrypted.'");
			
			Result = AddInParsingResult();
			Result.ErrorDescription = ErrorText;
			
			Return Result;
			
		EndIf;
		
		Try
			
			// Manifest search and parsing.
			If Lower(ArchiveItem.OriginalFullName) = "manifest.xml" Then
				
				Attributes.VersionDate = ArchiveItem.Modified;
				
				ReadingArchive.Extract(ArchiveItem, TempDirectory);
				TemporaryXMLfile = TempDirectory + GetPathSeparator() + ArchiveItem.FullName;
				ParseAddInManifest(TemporaryXMLfile, Attributes);
				
				ManifestIsFound = True;
				
			EndIf;
			
			If Lower(ArchiveItem.OriginalFullName) = "info.xml" AND ParseInfoFile Then
				
				ReadingArchive.Extract(ArchiveItem, TempDirectory);
				TemporaryXMLfile = TempDirectory + GetPathSeparator() + ArchiveItem.FullName;
				ParseAddInInfo(TemporaryXMLfile, Attributes);
				
			EndIf;
			
			For Each SearchParameter In AdditionalInformationSearchParameters Do 
				
				XMLFileName = SearchParameter.Value.XMLFileName;
				
				If ArchiveItem.OriginalFullName = XMLFileName Then 
					
					AdditionalInformationKey = SearchParameter.Key;
					XPathExpression = SearchParameter.Value.XPathExpression;
					
					ReadingArchive.Extract(ArchiveItem, TempDirectory);
					TemporaryXMLfile = TempDirectory + GetPathSeparator() + ArchiveItem.FullName;
					
					DocumentDOM = DocumentDOM(TemporaryXMLfile);
					XPathValue = EvaluateXPathExpression(XPathExpression, DocumentDOM);
					
					AdditionalInformation.Insert(AdditionalInformationKey, XPathValue);
					
				EndIf;
				
			EndDo;
			
		Except
			Result = AddInParsingResult();
			Result.ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Ошибка при разборе файла %1
				           |%2'; 
				           |en = 'An error occurred while parsing file %1
				           |%2'; 
				           |pl = 'An error occurred while parsing file %1
				           |%2';
				           |de = 'An error occurred while parsing file %1
				           |%2';
				           |ro = 'An error occurred while parsing file %1
				           |%2';
				           |tr = 'An error occurred while parsing file %1
				           |%2'; 
				           |es_ES = 'An error occurred while parsing file %1
				           |%2'"),
				ArchiveItem.OriginalFullName,
				BriefErrorDescription(ErrorInfo()));
				
			Return Result;
		EndTry;
	EndDo;
	
	// Clear temporary files and memory.
	FileSystem.DeleteTemporaryDirectory(TempDirectory);
	ReadingArchive.Close();
	Thread.Close();
	
	// Add-in map comtrol.
	If Not ManifestIsFound Then 
		ErrorText = NStr("ru = 'В архиве компоненты отсутствует обязательный файл MANIFEST.XML.'; en = 'MANIFEST.XML mandatory file is missing in the add-in archive.'; pl = 'MANIFEST.XML mandatory file is missing in the add-in archive.';de = 'MANIFEST.XML mandatory file is missing in the add-in archive.';ro = 'MANIFEST.XML mandatory file is missing in the add-in archive.';tr = 'MANIFEST.XML mandatory file is missing in the add-in archive.'; es_ES = 'MANIFEST.XML mandatory file is missing in the add-in archive.'");
		
		Result = AddInParsingResult();
		Result.ErrorDescription = ErrorText;
		
		Return Result;
	EndIf;
	
	Result = AddInParsingResult();
	Result.Disassembled = True;
	Result.Attributes = Attributes;
	Result.BinaryData = BinaryData;
	Result.AdditionalInformation = AdditionalInformation;
	
	Return Result;
	
EndFunction

#Region ConfigurationSubsystemsEventHandlers

// See BatchObjectModificationOverridable.OnDetermineObjectsWithEditableAttributes. 
Procedure OnDefineObjectsWithEditableAttributes(Objects) Export
	
	Objects.Insert(Metadata.Catalogs.AddIns.FullName(), "AttributesToEditInBatchProcessing");
	
EndProcedure

// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport. 
Procedure OnFillTypesExcludedFromExportImport(Types) Export
	
	Types.Add(Metadata.Catalogs.AddIns);
	
EndProcedure

// See StandardSubsystemsServer.OnSendDataToMaster. 
Procedure OnSendDataToMaster(DataItem, ItemSending, Recipient) Export
	
	If TypeOf(DataItem) = Type("CatalogObject.AddIns") Then
		ItemSending = DataItemSend.Ignore;
	EndIf;
	
EndProcedure

// See StandardSubsystemsServer.OnSendDataToSlave. 
Procedure OnSendDataToSlave(DataItem, ItemSending, InitialImageCreation, Recipient) Export
	
	If TypeOf(DataItem) = Type("CatalogObject.AddIns") Then
		ItemSending = DataItemSend.Ignore;
	EndIf;
	
EndProcedure

// See StandardSubsystemsServer.OnReceiveDataFromMaster. 
Procedure OnReceiveDataFromMaster(DataItem, GetItem, SendBack, Sender) Export
	
	If TypeOf(DataItem) = Type("CatalogObject.AddIns") Then
		GetItem = DataItemReceive.Ignore;
	EndIf;
	
EndProcedure

// See StandardSubsystemsServer.OnReceiveDataFromSlave. 
Procedure OnReceiveDataFromSlave(DataItem, GetItem, SendBack, Sender) Export
	
	If TypeOf(DataItem) = Type("CatalogObject.AddIns") Then
		GetItem = DataItemReceive.Ignore;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region SavedAddInInformation

Function ImportFromFileIsAvailable()
	
	Return Users.IsFullUser(,, False);
	
EndFunction

// Parameters:
//  Parameters - Structure - preparation parameters.
//      * ID - String ID of external component object.
//      * Version - String, Undefined -  component version.
//
// Returns:
//  Structure - SavedAddInInformationResult()
//
Function SavedAddInInformation(ID, Version = Undefined) Export
	
	Result = InformationOnSavedAddInResult();
	
	// Component search step.
	
	ReferenceFromStorage = Catalogs.AddIns.FindByID(ID, Version);
	
	If Common.DataSeparationEnabled() 
		AND Common.SubsystemExists("StandardSubsystems.SaaS.AddInsSaaS") Then
		
		ModuleCatalogsAddInsShare = Common.CommonModule("Catalogs.CommonAddIns");
		ReferenceFromSharedStorage = ModuleCatalogsAddInsShare.FindByID(ID, Version);
		
		If ReferenceFromStorage.IsEmpty() Then
			If ReferenceFromSharedStorage.IsEmpty() Then
				Result.State = "NotFound";
			Else 
				Result.State = "FoundInSharedStorage";
				Result.Ref = ReferenceFromSharedStorage;
			EndIf;
		Else 
			If ReferenceFromSharedStorage.IsEmpty() Then
				Result.State = "FoundInStorage";
				Result.Ref = ReferenceFromStorage;
			Else 
				If ValueIsFilled(Version) Then
					// Special case: there is a component in shared and area storage,
					// They are of the same version. Priority to the area add-in.
					Result.State = "FoundInStorage";
					Result.Ref = ReferenceFromStorage;
				Else 
					StorageVersion = Common.ObjectAttributeValue(ReferenceFromStorage, "VersionDate");
					SharedStorageVersion = Common.ObjectAttributeValue(ReferenceFromSharedStorage, "VersionDate");
					
					If SharedStorageVersion > StorageVersion Then 
						Result.State = "FoundInSharedStorage";
						Result.Ref = ReferenceFromSharedStorage;
					Else 
						// Special case: there is a component in shared and area storage,
						// If they are of the same version. Priority to the area add-in.
						Result.State = "FoundInStorage";
						Result.Ref = ReferenceFromStorage;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		
	Else 
		
		If ReferenceFromStorage.IsEmpty() Then
			Result.State = "NotFound";
		Else
			Result.State = "FoundInStorage";
			Result.Ref = ReferenceFromStorage;
		EndIf
		
	EndIf;
	
	// Used add-in analysis step
	
	If Result.State = "NotFound" Then 
		Return Result;
	EndIf;
	
	Attributes = AddInAttributes();
	If Result.State = "FoundInStorage" Then 
		Attributes.Insert("Use"); 
		// Required to define status.
		// Only area add-ins have the flag.
	EndIf;
	If Result.State = "FoundInSharedStorage" Then 
		Attributes.Delete("FileName");
		// Shared add-ins do not have it.
	EndIf;
	
	ObjectAttributes = Common.ObjectAttributesValues(Result.Ref, Attributes);
	
	FillPropertyValues(Result.Attributes, ObjectAttributes);
	Result.Location = GetURL(Result.Ref, "AddInStorage");
	
	If Result.State = "FoundInStorage" Then 
		If ObjectAttributes.Use <> Enums.AddInUsageOptions.Used Then 
			Result.State = "DisabledByAdministrator";
		EndIf;
	EndIf;
	
	Return Result
	
EndFunction

Function InformationOnSavedAddInResult()
	
	Result = New Structure;
	Result.Insert("Ref");
	Result.Insert("Attributes", AddInAttributes());
	Result.Insert("Location");
	Result.Insert("State");
	// Options:
	// * NotFound
	// * FoundInStorage
	// * FoundInSharedStorage
	// * DisabledByAdministrator
	
	Result.Insert("ImportFromFileIsAvailable", ImportFromFileIsAvailable());
	Result.Insert("CanImportFromPortal", ImportFromPortalIsAvailable());
	
	Return Result;
	
EndFunction

Function AddInAttributes()
	
	Attributes = New Structure;
	Attributes.Insert("Windows_x86");
	Attributes.Insert("Windows_x86_64");
	Attributes.Insert("Linux_x86");
	Attributes.Insert("Linux_x86_64");
	Attributes.Insert("Windows_x86_Firefox");
	Attributes.Insert("Linux_x86_Firefox");
	Attributes.Insert("Linux_x86_64_Firefox");
	Attributes.Insert("Windows_x86_MSIE");
	Attributes.Insert("Windows_x86_64_MSIE");
	Attributes.Insert("Windows_x86_Chrome");
	Attributes.Insert("Linux_x86_Chrome");
	Attributes.Insert("Linux_x86_64_Chrome");
	Attributes.Insert("MacOS_x86_64_Safari");
	Attributes.Insert("ID");
	Attributes.Insert("Description");
	Attributes.Insert("Version");
	Attributes.Insert("VersionDate");
	Attributes.Insert("FileName");
	
	Return Attributes;
	
EndFunction

#EndRegion

#Region ParsingAddInFromFile

Function AddInParsingResult()
	
	Result = New Structure;
	Result.Insert("Disassembled", False);
	Result.Insert("Attributes", New Structure);
	Result.Insert("BinaryData", Undefined);
	Result.Insert("AdditionalInformation", New Map);
	Result.Insert("ErrorDescription", "");
	
	Return Result;
	
EndFunction

Procedure ParseAddInManifest(XMLFile, Attributes)
	
	XMLReader = New XMLReader;
	XMLReader.OpenFile(XMLFile);
	
	XMLReader.MoveToContent();
	If XMLReader.Name = "bundle" AND XMLReader.NodeType = XMLNodeType.StartElement Then
		While XMLReader.Read() Do 
			If XMLReader.Name = "component" AND XMLReader.NodeType = XMLNodeType.StartElement Then
				
				OperatingSystem  = Lower(XMLReader.AttributeValue("os"));
				ComponentType        = Lower(XMLReader.AttributeValue("type"));
				PlatformArchitecture = Lower(XMLReader.AttributeValue("arch"));
				Viewer   = Lower(XMLReader.AttributeValue("client"));
				
				If OperatingSystem = "windows" AND PlatformArchitecture = "i386"
					AND (ComponentType = "native" Or ComponentType = "com") Then 
					
					Attributes.Windows_x86 = True;
					Continue;
				EndIf;
				
				If OperatingSystem = "windows" AND PlatformArchitecture = "x86_64"
					AND (ComponentType = "native" Or ComponentType = "com") Then 
					
					Attributes.Windows_x86_64 = True;
					Continue;
				EndIf;
				
				If OperatingSystem = "linux" AND PlatformArchitecture = "i386"
					AND ComponentType = "native" Then 
					
					Attributes.Linux_x86 = True;
					Continue;
				EndIf;
				
				If OperatingSystem = "linux" AND PlatformArchitecture = "x86_64"
					AND ComponentType = "native" Then 
					
					Attributes.Linux_x86_64 = True;
					Continue;
				EndIf;
				
				If OperatingSystem = "windows" AND PlatformArchitecture = "i386"
					AND ComponentType = "plugin" AND Viewer = "firefox" Then
					
					Attributes.Windows_x86_Firefox = True;
					Continue;
				EndIf;
				
				If OperatingSystem = "linux" AND PlatformArchitecture = "i386" 
					AND ComponentType = "plugin" AND Viewer = "firefox" Then
					
					Attributes.Linux_x86_Firefox = True;
					Continue;
				EndIf;
				
				If OperatingSystem = "linux" AND PlatformArchitecture = "x86_64"
					AND ComponentType = "plugin" AND Viewer = "firefox" Then
					
					Attributes.Linux_x86_64_Firefox = True;
					Continue;
				EndIf;
				
				If OperatingSystem = "windows" AND PlatformArchitecture = "i386"
					AND ComponentType = "plugin" AND Viewer = "msie" Then
					
					Attributes.Windows_x86_MSIE = True;
					Continue;
				EndIf;
				
				If OperatingSystem = "windows" AND PlatformArchitecture = "x86_64"
					AND ComponentType = "plugin" AND Viewer = "msie" Then
					
					Attributes.Windows_x86_64_MSIE = True;
					Continue;
				EndIf;
				
				If OperatingSystem = "windows" AND PlatformArchitecture = "i386"
					AND ComponentType = "plugin" AND Viewer = "chrome" Then
					
					Attributes.Windows_x86_Chrome = True;
					Continue;
				EndIf;
				
				If OperatingSystem = "linux" AND PlatformArchitecture = "i386"
					AND ComponentType = "plugin" AND Viewer = "chrome" Then
					
					Attributes.Linux_x86_Chrome = True;
					Continue;
				EndIf;
				
				If OperatingSystem = "linux" AND PlatformArchitecture = "x86_64"
					AND ComponentType = "plugin" AND Viewer = "chrome" Then
					
					Attributes.Linux_x86_64_Chrome = True;
					Continue;
				EndIf;
				
				If OperatingSystem = "macos" 
					AND (PlatformArchitecture = "x86_64" Or PlatformArchitecture = "universal")
					AND ComponentType = "plugin" AND Viewer = "safari" Then 
					
					Attributes.MacOS_x86_64_Safari = True;
					Continue;
				EndIf;
				
			EndIf;
		EndDo;  
	EndIf;
	XMLReader.Close();
	
EndProcedure

Procedure ParseAddInInfo(XMLFile, Attributes)
	
	InfoParsed = False;
	
	// TryingToParseByPLFormat
	XMLReader = New XMLReader;
	XMLReader.OpenFile(XMLFile);
	
	XMLReader.MoveToContent();
	If XMLReader.Name = "drivers" AND XMLReader.NodeType = XMLNodeType.StartElement Then
		While XMLReader.Read() Do
			If XMLReader.Name = "component" AND XMLReader.NodeType = XMLNodeType.StartElement Then
				
				ID = XMLReader.AttributeValue("progid");
				
				Attributes.ID = Mid(ID, StrFind(ID, ".") + 1);
				Attributes.Description  = XMLReader.AttributeValue("name");
				Attributes.Version        = XMLReader.AttributeValue("version");
				
				InfoParsed = True;
				
			EndIf;
		EndDo;
	EndIf;
	XMLReader.Close();
	
	If Not InfoParsed Then
		
		// Trying to parse by EDL format.
		XMLReader = New XMLReader;
		XMLReader.OpenFile(XMLFile);
	
		info = XDTOFactory.ReadXML(XMLReader);
		Attributes.ID = info.progid;
		Attributes.Description = info.name;
		Attributes.Version = info.version;
		
		XMLReader.Close();
	
	EndIf;
	
EndProcedure

Function EvaluateXPathExpression(Expression, DocumentDOM)
	
	XPathValue = Undefined;
	
	Dereferencer = DocumentDOM.CreateNSResolver();
	XPathResult = DocumentDOM.EvaluateXPathExpression(Expression, DocumentDOM, Dereferencer);
	
	ResultNode = XPathResult.IterateNext();
	If TypeOf(ResultNode) = Type("DOMAttribute") Then 
		XPathValue = ResultNode.Value;
	EndIf;
	
	Return XPathValue
	
EndFunction

Function DocumentDOM(PathToFile)
	
	XMLReader = New XMLReader;
	XMLReader.OpenFile(PathToFile);
	DOMBuilder = New DOMBuilder;
	DocumentDOM = DOMBuilder.Read(XMLReader);
	XMLReader.Close();
	
	Return DocumentDOM;
	
EndFunction

#EndRegion

#Region ImportFromPortal

Procedure CheckImportFromPortalAvailability()
	
	If Not ImportFromPortalIsAvailable() Then
		Raise 
			NStr("ru = 'Обновление внешних компонент не доступно.
			           |Требуется подсистема обновления внешних компонент библиотеки интернет поддержки.'; 
			           |en = 'Cannot update add-ins.
			           |Add-in update subsystem of online support library is required.'; 
			           |pl = 'Cannot update add-ins.
			           |Add-in update subsystem of online support library is required.';
			           |de = 'Cannot update add-ins.
			           |Add-in update subsystem of online support library is required.';
			           |ro = 'Cannot update add-ins.
			           |Add-in update subsystem of online support library is required.';
			           |tr = 'Cannot update add-ins.
			           |Add-in update subsystem of online support library is required.'; 
			           |es_ES = 'Cannot update add-ins.
			           |Add-in update subsystem of online support library is required.'");
	EndIf;
	
EndProcedure

Procedure NewAddInsFromPortal(ProcedureParameters, ResultAddress) Export
	
	If Common.SubsystemExists("OnlineUserSupport.GetAddIns") Then
		
		ID = ProcedureParameters.ID;
		Version = ProcedureParameters.Version;
		
		CheckImportFromPortalAvailability();
		
		ModuleGetAddIns = Common.CommonModule("GetAddIns");
		
		AddInsDetails  = ModuleGetAddIns.AddInsDetails();
		AddInDetails = AddInsDetails.Add();
		AddInDetails.ID = ID;
		AddInDetails.Version        = Version;
		
		If Not ValueIsFilled(Version) Then
			OperationResult = ModuleGetAddIns.RelevantAddInsVersions(AddInsDetails);
		Else
			OperationResult = ModuleGetAddIns.AddInsVersions(AddInsDetails);
		EndIf;
		
		If ValueIsFilled(OperationResult.ErrorCode) Then
			ExceptionText = ?(Users.IsFullUser(),
				OperationResult.ErrorInfo,
				OperationResult.ErrorMessage);
			Raise ExceptionText;
		EndIf;
		
		If OperationResult.AddInsData.Count() = 0 Then
			ExceptionText = NStr("ru = 'На Портале 1С:ИТС внешняя компонента не обнаружена.'; en = 'Add-in is not found on 1C:ITS Portal.'; pl = 'Add-in is not found on 1C:ITS Portal.';de = 'Add-in is not found on 1C:ITS Portal.';ro = 'Add-in is not found on 1C:ITS Portal.';tr = 'Add-in is not found on 1C:ITS Portal.'; es_ES = 'Add-in is not found on 1C:ITS Portal.'");
			WriteLogEvent(NStr("ru = 'Обновление внешних компонент'; en = 'Updating add-ins'; pl = 'Updating add-ins';de = 'Updating add-ins';ro = 'Updating add-ins';tr = 'Updating add-ins'; es_ES = 'Updating add-ins'",
					Common.DefaultLanguageCode()),
				EventLogLevel.Error,,, ExceptionText);
			Raise ExceptionText;
		EndIf;
		
		ResultString = OperationResult.AddInsData[0]; // Focus on the first search result.
		
		ErrorCode = ResultString.ErrorCode;
		
		If ValueIsFilled(ErrorCode) Then
			
			ErrorInformation = "";
			If ErrorCode = "ComponentNotFound" Then 
				ErrorInformation = NStr("ru = 'В сервисе внешних компонент не обнаружена внешняя компонента'; en = 'Add-in is not found in the add-in service'; pl = 'Add-in is not found in the add-in service';de = 'Add-in is not found in the add-in service';ro = 'Add-in is not found in the add-in service';tr = 'Add-in is not found in the add-in service'; es_ES = 'Add-in is not found in the add-in service'");
			ElsIf ErrorCode = "VersionNotFound" Then
				ErrorInformation = NStr("ru = 'В сервисе внешних компонент не обнаружена требуемая версия внешней компоненты'; en = 'Required add-in version is not found in the add-in service'; pl = 'Required add-in version is not found in the add-in service';de = 'Required add-in version is not found in the add-in service';ro = 'Required add-in version is not found in the add-in service';tr = 'Required add-in version is not found in the add-in service'; es_ES = 'Required add-in version is not found in the add-in service'");
			ElsIf ErrorCode = "FileNotImported" Then 
				ErrorInformation = NStr("ru = 'При попытке загрузить файл внешней компоненты из сервиса, возникла ошибка'; en = 'An error occurred while trying to import add-in file from service'; pl = 'An error occurred while trying to import add-in file from service';de = 'An error occurred while trying to import add-in file from service';ro = 'An error occurred while trying to import add-in file from service';tr = 'An error occurred while trying to import add-in file from service'; es_ES = 'An error occurred while trying to import add-in file from service'");
			ElsIf ErrorCode = "LatestVersion" Then
				ErrorInformation = 
					NStr("ru = 'Скорее всего произошла ошибка сервера при загрузке компоненты.
					           |Получен код ошибки: АктуальнаяВерсия, однако в ИБ компоненты не обнаружено.'; 
					           |en = 'A server error might have occurred while loading the add-in.
					           |Error code received: LatestVersion but the add-in is not found in the infobase.'; 
					           |pl = 'A server error might have occurred while loading the add-in.
					           |Error code received: LatestVersion but the add-in is not found in the infobase.';
					           |de = 'A server error might have occurred while loading the add-in.
					           |Error code received: LatestVersion but the add-in is not found in the infobase.';
					           |ro = 'A server error might have occurred while loading the add-in.
					           |Error code received: LatestVersion but the add-in is not found in the infobase.';
					           |tr = 'A server error might have occurred while loading the add-in.
					           |Error code received: LatestVersion but the add-in is not found in the infobase.'; 
					           |es_ES = 'A server error might have occurred while loading the add-in.
					           |Error code received: LatestVersion but the add-in is not found in the infobase.'");
			EndIf;
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'При загрузке внешней компоненты %1 возникала ошибка:
				           |%2'; 
				           |en = 'An error occurred while importing add-in %1:
				           |%2'; 
				           |pl = 'An error occurred while importing add-in %1:
				           |%2';
				           |de = 'An error occurred while importing add-in %1:
				           |%2';
				           |ro = 'An error occurred while importing add-in %1:
				           |%2';
				           |tr = 'An error occurred while importing add-in %1:
				           |%2'; 
				           |es_ES = 'An error occurred while importing add-in %1:
				           |%2'"),
				AddInPresentation(ID, Version),
				ErrorInformation);
			
			WriteLogEvent(NStr("ru = 'Обновление внешних компонент'; en = 'Updating add-ins'; pl = 'Updating add-ins';de = 'Updating add-ins';ro = 'Updating add-ins';tr = 'Updating add-ins'; es_ES = 'Updating add-ins'",
				Common.DefaultLanguageCode()),
				EventLogLevel.Error,,,
				ErrorText);
			
			Raise ErrorText;
		EndIf;
		
		Information = InformationOnAddInFromFile(ResultString.FileAddress, False);
		
		If Not Information.Disassembled Then 
			WriteLogEvent(NStr("ru = 'Обновление внешних компонент'; en = 'Updating add-ins'; pl = 'Updating add-ins';de = 'Updating add-ins';ro = 'Updating add-ins';tr = 'Updating add-ins'; es_ES = 'Updating add-ins'",
				Common.DefaultLanguageCode()),
			EventLogLevel.Error, , , Information.ErrorDescription);
			Raise Information.ErrorDescription;
		EndIf;
		
		SetPrivilegedMode(True);
		
		BeginTransaction();
		Try
			// Creating add-in instance
			Object = Catalogs.AddIns.CreateItem();
			Object.Fill(Undefined); // Default constructor
			
			FillPropertyValues(Object, Information.Attributes); // By manifest data.
			FillPropertyValues(Object, ResultString);     // By data from the website.
			
			Object.ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Загружена с Портала 1С:ИТС. %1.'; en = 'Imported from 1C:ITS Portal. %1.'; pl = 'Imported from 1C:ITS Portal. %1.';de = 'Imported from 1C:ITS Portal. %1.';ro = 'Imported from 1C:ITS Portal. %1.';tr = 'Imported from 1C:ITS Portal. %1.'; es_ES = 'Imported from 1C:ITS Portal. %1.'"),
				CurrentSessionDate());
			
			Object.AdditionalProperties.Insert("ComponentBinaryData", Information.BinaryData);
			
			If Not ValueIsFilled(Version) Then // If the specific version is requested, then skip.
				Object.UpdateFrom1CITSPortal = Object.ThisIsTheLatestVersionComponent();
			EndIf;
			
			Object.Write();
			CommitTransaction();
		Except
			RollbackTransaction();
			WriteLogEvent(NStr("ru = 'Обновление внешних компонент'; en = 'Updating add-ins'; pl = 'Updating add-ins';de = 'Updating add-ins';ro = 'Updating add-ins';tr = 'Updating add-ins'; es_ES = 'Updating add-ins'",
				Common.DefaultLanguageCode()),
				EventLogLevel.Error,,, 
				DetailErrorDescription(ErrorInfo()));
			Raise;
		EndTry;
		
	Else
		Raise 
			NStr("ru = 'Ожидается существование подсистемы ""ИнтернетПоддержкаПользователей.ПолучениеВнешнихКомпонент""'; en = 'OnlineUserSupport.GetAddIns subsystem is expected to exist'; pl = 'OnlineUserSupport.GetAddIns subsystem is expected to exist';de = 'OnlineUserSupport.GetAddIns subsystem is expected to exist';ro = 'OnlineUserSupport.GetAddIns subsystem is expected to exist';tr = 'OnlineUserSupport.GetAddIns subsystem is expected to exist'; es_ES = 'OnlineUserSupport.GetAddIns subsystem is expected to exist'");
	EndIf;
	
EndProcedure

Procedure UpdateAddInsFromPortal(ProcedureParameters, ResultAddress) Export
	
	If Common.SubsystemExists("OnlineUserSupport.GetAddIns") Then
		
		RefsArray = ProcedureParameters.RefsArray;
		
		CheckImportFromPortalAvailability();
		
		ModuleGetAddIns = Common.CommonModule("GetAddIns");
		AddInsDetails = ModuleGetAddIns.AddInsDetails();
		
		For Each Ref In RefsArray Do 
			Attributes = Common.ObjectAttributesValues(Ref, "ID, Version");
			ComponentDetails = AddInsDetails.Add();
			ComponentDetails.ID = Attributes.ID;
			ComponentDetails.Version = Attributes.Version;
		EndDo;
		
		OperationResult = ModuleGetAddIns.RelevantAddInsVersions(AddInsDetails);
		
		If ValueIsFilled(OperationResult.ErrorCode) Then
			ExceptionText = ?(Users.IsFullUser(),
				OperationResult.ErrorInfo,
				OperationResult.ErrorMessage);
			Raise ExceptionText;
		EndIf;
		
		AddInsServer.UpdateAddIns(OperationResult.AddInsData, ResultAddress);
		
	Else
		Raise 
			NStr("ru = 'Ожидается существование подсистемы ""ИнтернетПоддержкаПользователей.ПолучениеВнешнихКомпонент""'; en = 'OnlineUserSupport.GetAddIns subsystem is expected to exist'; pl = 'OnlineUserSupport.GetAddIns subsystem is expected to exist';de = 'OnlineUserSupport.GetAddIns subsystem is expected to exist';ro = 'OnlineUserSupport.GetAddIns subsystem is expected to exist';tr = 'OnlineUserSupport.GetAddIns subsystem is expected to exist'; es_ES = 'OnlineUserSupport.GetAddIns subsystem is expected to exist'");
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

