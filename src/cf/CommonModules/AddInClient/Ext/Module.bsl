///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Parameter structure for see the AttachAddInSSL procedure.
//
// Returns:
//  Structure - a collection of the following parameters:
//      *       * Cached           - Boolean - use component caching on the client (the default value is True).
//      * SuggestInstall - Boolean - (default value is True) prompt to install and update an add-in.
//      * NoteText - String - purpose of an add-in and what applications do not operate without it.
//      * ObjectsCreationIDs - Array - string array of object module instance. Use it only for 
//                add-ins with several object creation IDs. On specify, the ID parameter is used 
//                only to determine add-in.
//
// Example:
//
//  AttachmentParameters = AddInClient.AttachmentParameters();
//  AttachmentParameters.NoteText =
//      NStr("en = 'To use a barcode scanner, install the file system extension
//                 |the 1C:Barcode scanners (NativeApi) add-in.'");
//
Function AttachmentParameters() Export
	
	Parameters = New Structure;
	Parameters.Insert("Cached", True);
	Parameters.Insert("SuggestInstall", True);
	Parameters.Insert("NoteText", "");
	Parameters.Insert("ObjectsCreationIDs", New Array);
	
	Return Parameters;
	
EndFunction

// Attaches an add-in based on Native API and COM technology in an asynchronous mode.
// Web client can display dialog with installation tips.
// Checking whether the add-in can be executed on the current user client.
//
// Parameters:
//  Notification - NotifyDescription - attachment notification details with the following parameters:
//      * Result - Structure - add-in attachment result:
//          ** Connected - Boolean - attachment flag.
//          ** AttachableModule - AddIn - an instance of the add-in;
//                     - FixedMap - an instance of the add-in,
//                     specified in AttachmentParameters.ObjectsCreationIDs,
//                     Key - ID, Value - object instance.
//          ** ErrorDescription - String - a brief error description. Empty string on cancel by user.
//      * AdditionalParameters - Structure - a value that was specified when creating the NotifyDescription object.
//   ID - String - the add-in ID.
//  Version - String - (optional) component version.
//  AttachmentParameters - Structure - (optional) see the AttachmentParameters function.
//
// Example:
//
//  Notification = New NotifyDescription("AttachAddInSSLCompletion", ThisObject);
//
//  AttachmentParameters = AddInClient.AttachmentParameters();
//  AttachmentParameters.NoteText =
//      NStr("en = 'To use a barcode scanner, install the file system extension
//                 |the 1C:Barcode scanners (NativeApi) add-in.'");
//
//  AddInClient.AttachAddInSSL(Notification,"InputDevice",, AttachmentParameters);
//
//  &AtClient
//  Procedure AttachAddInSSLCompletion(Result, AdditionalParameters) Export
//
//      AttachableModule = Undefined;
//
//      If Result.Attached Then
//          AttachableModule = Result.AttachableModule;
//      Else
//          If Not IsBlankString(Result.ErrorDescription) Then
//              ShowMessageBox (, Result.ErrorDescription);
//          EndIf.
//      EndIf.
//
//      If AttachableModule <> Undefined Then
//          // AttachableModule contains the instance of the attached add-in.
//      EndIf.
//
//      AttachableModule = Undefined;
//
//  EndProcedure
//
Procedure AttachAddInSSL(Notification, ID, Version = Undefined,
	AttachmentParameters = Undefined) Export
	
	If AttachmentParameters = Undefined Then
		AttachmentParameters = AttachmentParameters();
	EndIf;
	
	Context = New Structure;
	Context.Insert("Notification", Notification);
	Context.Insert("ID", ID);
	Context.Insert("Version", Version);
	Context.Insert("Cached", AttachmentParameters.Cached);
	Context.Insert("SuggestInstall", AttachmentParameters.SuggestInstall);
	Context.Insert("SuggestToImport", AttachmentParameters.SuggestInstall);
	Context.Insert("NoteText", AttachmentParameters.NoteText);
	Context.Insert("ObjectsCreationIDs", AttachmentParameters.ObjectsCreationIDs);
	
	AddInsInternalClient.AttachAddInSSL(Context);
	
EndProcedure

// Attaches an add-in based on COM technology from Windows registry in asynchronous mode.
// (not recommended for backward compatibility with )
//
// Parameters:
//  Notification - NotifyDescription - attachment notification details with the following parameters:
//      * Result - Structure - add-in attachment result:
//          ** Connected - Boolean - attachment flag.
//          ** AttachableModule - AddIn - an instance of the add-in.
//          ** ErrorDescription - String - a brief error description.
//      * AdditionalParameters - Structure - a value that was specified when creating the NotifyDescription object.
//   ID - String - the add-in ID.
//  ObjectCreationID - String - (optional) object creation ID of object module instance (only for 
//          add-ins with object creation ID different from ProgID).
//
// Example:
//
//  Notification = New NotifyDescription("AttachAddInSSLCompletion", ThisObject);
//
//  AddInClient.AttachAddInFromWindowsRegistry(Notification, "SBRFCOMObject", "SBRFCOMExtension");
//
//  &AtClient
//  Procedure AttachAddInSSLCompletion(Result, AdditionalParameters) Export
//
//      AttachableModule = Undefined;
//
//      If Result.Attached Then
//          AttachableModule = Result.AttachableModule;
//      Else
//          ShowMessageBox (, Result.ErrorDescription);
//      EndIf.
//
//      If AttachableModule <> Undefined Then
//          // AttachableModule contains the instance of the attached add-in.
//      EndIf.
//
//      AttachableModule = Undefined;
//
//  EndProcedure
//
Procedure AttachAddInFromWindowsRegistry(Notification, ID,
	ObjectCreationID = Undefined) Export 
	
	Context = New Structure;
	Context.Insert("Notification"                  , Notification);
	Context.Insert("ID"               , ID);
	Context.Insert("ObjectCreationID", ObjectCreationID);
	
	AddInsInternalClient.AttachAddInFromWindowsRegistry(Context);
	
EndProcedure

// Parameter structure for see the InstallAddIn procedure.
//
// Returns:
//  Structure - a collection of the following parameters:
//      * NoteText - String - purpose of an add-in and what applications do not operate without it.
//
// Example:
//
//  InstallationParameters = AddInClient.InstallationParameters();
//  InstallationParameters.NoteText
//      NStr("en = 'To use a barcode scanner, install the file system extension
//                 |the 1C:Barcode scanners (NativeApi) add-in.'");
//
Function InstallationParameters() Export
	
	Parameters = New Structure;
	Parameters.Insert("NoteText", "");
	
	Return Parameters;
	
EndFunction

// Connects an add-in based on Native API and COM technology in an asynchronous mode.
// Checking whether the add-in can be executed on the current user client.
//
// Parameters:
//  Notification - NotifyDescription - notification details of add-in installation:
//      * Structure - Completed - install component result:
//          ** Installed - Boolean - installation flag.
//          ** ErrorDescription - String - a brief error description. Empty string on cancel by user.
//      * AdditionalParameters - Structure - a value that was specified when creating the NotifyDescription object.
//   ID - String - the add-in ID.
//  Version - String - (optional) component version.
//  InstallationParameters - Structure - (optional) see the InstallationParameters function.
//
// Example:
//
//  Notification = New NotifyDescription("SetCompletionComponent", ThisObject);
//
//  InstallationParameters = AddInClient.InstallationParameters();
//  InstallationParameters.NoteText
//      NStr("en = 'To use a barcode scanner, install the file system extension
//                 |the 1C:Barcode scanners (NativeApi) add-in.'");
//
//  AddInClient.InstallAddIn(Notification,"InputDevice",, InstallationParameters);
//
//  &AtClient
//  Procedure InstallAddInEnd(Result, AdditionalParameters) Export
//
//      If Not Result.Installed and Not EmptyString(Result.ErrorDescription) Then
//          ShowMessageBox (, Result.ErrorDescription);
//      EndIf.
//
//  EndProcedure
//
Procedure InstallAddInSSL(Notification, ID, Version = Undefined, 
	InstallationParameters = Undefined) Export
	
	If InstallationParameters = Undefined Then
		InstallationParameters = InstallationParameters();
	EndIf;
	
	Context = New Structure;
	Context.Insert("Notification", Notification);
	Context.Insert("ID", ID);
	Context.Insert("Version", Version);
	Context.Insert("SuggestToImport", True);
	Context.Insert("NoteText", InstallationParameters.NoteText);
	
	AddInsInternalClient.InstallAddInSSL(Context);
	
EndProcedure

// Returns parameter structure to describe search rules of additional information within an add-in 
// see the ImportAddInFromFile.
//
// Returns:
//  Structure - a collection of the following parameters:
//      * XMLFileName - String - (optional) file name within an add-in from which information is extracted. 
//      * XPathExpression - String - (optional) XPath path to information in the file.
//
// Example:
//
//  ImportParameters = AddInClient.AdditionalInformationSearchParameters();
//  ImportParameters.XMLFileName = "INFO.XML";
//  ImportParameters.XPathExpression = "//drivers/component/@type";
//
Function AdditionalInformationSearchParameters() Export
	
	Parameters = New Structure;
	Parameters.Insert("XMLFileName", "");
	Parameters.Insert("XPathExpression", "");
	
	Return Parameters;
	
EndFunction

// Parameter structure for see the AttachAddInSSL procedure.ImportComponentFromFile.
//
// Returns:
//  Structure - a collection of the following parameters:
//      * ID - String - (optional) add-in object ID.
//      * Version - String - (optional) component version.
//      * AdditionalInformationSearchParameters - Map - (optional) parameters.
//          ** Key - String - Requested additional information ID.
//          ** Value - String - see the AdditionalInformationSearchParameters function.
// Example:
//
//  ImportParameters = AddInClient.ImportParameters();
//  ImportParameters.ID = "InputDevice";
//  ImportParameters.Version = "8.1.7.10";
//
Function ImportParameters() Export
	
	Parameters = New Structure;
	Parameters.Insert("ID", Undefined);
	Parameters.Insert("Version", Undefined);
	Parameters.Insert("AdditionalInformationSearchParameters", New Map);
	
	Return Parameters;
	
EndFunction

// Imports add-in file to the add-ins catalog in asynchronous mode.
//
// Parameters:
//  Notification - NotifyDescription - notification details of add-in installation:
//      * Result - Structure - import add-in result:
//          ** Imported - Boolean - imported flag.
//          **   ID - String - the add-in identification code.
//          ** Version - String - version of the imported add-in.
//          ** Descripption - String - version of the imported add-in.
//          ** AdditionalInformation - Map - additional Information on add-in.
//                     if not requested - blank map.
//               *** Key - String - additional see the AdditionalInformationSearchParameters function.
//               *** Value - String - see the AdditionalInformationSearchParameters function.
//      * AdditionalParameters - Structure - a value that was specified when creating the NotifyDescription object.
//  ImportParameters - Structure - (optional) see the ImportParameters function.
//
// Example:
//
//  ImportParameters = AddInClient.ImportParameters();
//  ImportParameters.ID = "InputDevice";
//  ImportParameters.Version = "8.1.7.10";
//
//  Notification = New NotifyDescription("LoadAddInFromFileAfterAddInImport", ThisObject);
//
//  AddInClient.ImportAddInsFromFile(Notification, ImportParameters);
//
//  &AtClient
//  Procedure LoadAddInFromFileAfterAddInImport(Result, AdditionalParameters) Export
//
//      If Result.Imported Then
//          ID = Result.ID;
//          Version = Result.Version;
//      EndIf.
//
//  EndProcedure
//
Procedure ImportAddInFromFile(Notification, ImportParameters = Undefined) Export
	
	If ImportParameters = Undefined Then 
		ImportParameters = ImportParameters();
	EndIf;
	
	Context = New Structure;
	Context.Insert("Notification", Notification);
	Context.Insert("ID", ImportParameters.ID);
	Context.Insert("Version", ImportParameters.Version);
	Context.Insert("AdditionalInformationSearchParameters", 
		ImportParameters.AdditionalInformationSearchParameters);
	
	AddInsInternalClient.ImportAddInFromFile(Context);
	
EndProcedure

#EndRegion