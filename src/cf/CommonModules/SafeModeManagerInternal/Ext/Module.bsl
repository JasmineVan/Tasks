///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// Checks whether the security profiles can be set up for the current infobase.
//
// Returns:
//   Boolean - True if the setting is available.
//
Function CanSetUpSecurityProfiles() Export
	
	If SecurityProfilesUsageAvailable() Then
		
		Cancel = False;
		
		SaaSIntegration.CanSetupSecurityProfilesOnCheck(Cancel);
		If Not Cancel Then
			SafeModeManagerOverride.CanSetUpSecurityProfilesOnCheck(Cancel);
		EndIf;
		
		Return Not Cancel;
		
	Else
		
		Return False;
		
	EndIf;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// External modules
//

// Returns external module attachment mode.
//
// Parameters:
//  ExternalModule - AnyRef - a reference to an external module.
//    
//
// Returns: String - a name of the security profile to be used for attaching the external module.
//   If the attachment mode is not registered for the external module, Undefined is returned.
//
Function ExternalModuleAttachmentMode(Val ExternalModule) Export
	
	Return InformationRegisters.ExternalModulesAttachmentModes.ExternalModuleAttachmentMode(ExternalModule);
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Using security profiles.
//

// Returns a namespace URI of an XDTO package used to describe permissions in security profiles.
// 
//
// Returns: String, a namespace URI of an XDTO package.
//
Function Package() Export
	
	Return Metadata.XDTOPackages.ApplicationPermissions_1_0_0_2.Namespace;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Creating permission requests.
//

// Creates requests to use external resources for the external module.
//
// Parameters:
//  ExternalModule - AnyRef - a reference that matches the external module for which permissions are being requested,
//  NewPermissions - Array(XDTODataObject) - an array of XDTODataObjects that match internal details 
//    of external resource access permissions to be requested. It is assumed that all 
//    XDTODataObjects passed as parameters are generated using the SafeModeManager.Permission*() functions.
//    When requesting permissions for external modules, permissions are added in replacement mode.
//
// Returns - Array(UUID) - IDs of the created requests.
//
Function PermissionsRequestForExternalModule(Val ProgramModule, Val NewPermissions = Undefined) Export
	
	Result = New Array();
	
	If NewPermissions = Undefined Then
		NewPermissions = New Array();
	EndIf;
	
	If NewPermissions.Count() > 0 Then
		
		// If there is no security profile, create it.
		If ExternalModuleAttachmentMode(ProgramModule) = Undefined Then
			Result.Add(RequestForSecurityProfileCreation(ProgramModule));
		EndIf;
		
		Result.Add(
			PermissionChangeRequest(
				ProgramModule, True, NewPermissions, Undefined, ProgramModule));
		
	Else
		
		// If there is a security profile, delete it.
		If ExternalModuleAttachmentMode(ProgramModule) <> Undefined Then
			Result.Add(RequestToDeleteSecurityProfile(ProgramModule));
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Using security profiles.
//

////////////////////////////////////////////////////////////////////////////////
// Converting references to Type+ID for storing in the permission registers.
// 
//
// References are stored in an unusual way because permission registers do not require referential 
// integrity, and records that belong to objects can be kept when the object is deleted.
// 
//

// Generates parameters for storing references in permission registers.
//
// Parameters:
//  Ref - AnyRef.
//
// Returns - Structure:
//                        * Type - CatalogRef.MetadataObjectsIDs,
//                        * ID - UUID - a reference UUID.
//                           
//
Function PropertiesForPermissionRegister(Val Ref) Export
	
	Result = New Structure("Type,ID");
	
	If Ref = Catalogs.MetadataObjectIDs.EmptyRef() Then
		
		Result.Type = Catalogs.MetadataObjectIDs.EmptyRef();
		Result.ID = CommonClientServer.BlankUUID();
		
	Else
		
		Result.Type = Common.MetadataObjectID(Ref.Metadata());
		Result.ID = Ref.UUID();
		
	EndIf;
	
	Return Result;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Applying the requests for permissions to use external resources.
//

// Generates a presentation of permissions to use external resources by permission tables.
//
// Parameters:
//  Tables - Structure - permission tables, for which a presentation is being generated (see
//     PermissionsTables()).
//
// Returns: SpreadsheetDocument - a presentation of permissions to use external resources.
//
Function PermissionsToUseExternalResourcesPresentation(Val ModuleType, Val ModuleID, Val OwnerType, Val OwnerID, Val Permissions) Export
	
	// CAC:326-off Transaction is used to apply the PermissionRequests information register as an 
	// intermediate cache for calculating requests for using external resources.
	// canceling of the transaction is used as a calculation cache cleanup alarm.
	
	BeginTransaction();
	Try
		Manager = DataProcessors.ExternalResourcePermissionSetup.Create();
		
		Manager.AddRequestForPermissionsToUseExternalResources(
			ModuleType,
			ModuleID,
			OwnerType,
			OwnerID,
			True,
			Permissions,
			New Array());
		
		Manager.CalculateRequestsApplication();
		
		RollbackTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	// CAC:326-off
	
	Return Manager.Presentation(True);
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Configuration subsystems event handlers.

// See CommonOverridable.OnAddClientParametersOnStart. 
Procedure OnAddClientParametersOnStart(Parameters, BeforeUpdateApplicationRunParameters = False) Export
	
	If BeforeUpdateApplicationRunParameters Then
		Parameters.Insert("DisplayPermissionSetupAssistant", False);
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	Parameters.Insert("DisplayPermissionSetupAssistant", InteractivePermissionRequestModeUsed());
	If Not Parameters.DisplayPermissionSetupAssistant Then
		Return;
	EndIf;	
	
	If Not Users.IsFullUser() Then
		Return;
	EndIf;	
			
	CheckSSL = PermissionsToUseExternalResourcesSetupServerCall.CheckApplyPermissionsToUseExternalResources();
	If CheckSSL.CheckResult Then
		Parameters.Insert("CheckExternalResourceUsagePermissionsApplication", False);
	Else
		Parameters.Insert("CheckExternalResourceUsagePermissionsApplication", True);
		Parameters.Insert("PermissionsToUseExternalResourcesApplicabilityCheck", CheckSSL);
	EndIf;
	
EndProcedure

// See ReportsOptionsOverridable.CustomizeReportsOptions. 
Procedure OnSetUpReportsOptions(Settings) Export
	ModuleReportsOptions = Common.CommonModule("ReportsOptions");
	ModuleReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.ExternalResourcesInUse);
EndProcedure

#EndRegion

#Region Private

// Creates a request to create a security profile for the external module.
// For internal use only.
//
// Parameters:
//  ExternalModule - AnyRef - a reference that matches the external module for which permissions are 
//    being requested (Undefined if permissions are requested for configurations, not for external modules).
//
// Returns - UUID - an ID of the created request.
//
Function RequestForSecurityProfileCreation(Val ProgramModule)
	
	StandardProcessing = True;
	Result = Undefined;
	Operation = Enums.SecurityProfileAdministrativeOperations.Creating;
	
	SaaSIntegration.OnRequestToCreateSecurityProfile(
		ProgramModule, StandardProcessing, Result);
	
	If StandardProcessing Then
		SafeModeManagerOverride.OnRequestToCreateSecurityProfile(
			ProgramModule, StandardProcessing, Result);
	EndIf;
	
	If StandardProcessing Then
		
		Result = InformationRegisters.RequestsForPermissionsToUseExternalResources.PermissionAdministrationRequest(
			ProgramModule, Operation);
		
	EndIf;
	
	Return Result;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Using security profiles.
//

// Checks whether the security profiles can be used for the current infobase.
//
// Returns: Boolean.
//
Function SecurityProfilesUsageAvailable() Export
	
	If Common.FileInfobase(InfoBaseConnectionString()) Then
		Return False;
	EndIf;
	
	Cancel = False;
	
	SafeModeManagerOverride.OnCheckSecurityProfilesUsageAvailability(Cancel);
	
	Return Not Cancel;
	
EndFunction

// Returns checksums of add-in files from the bundle provided in the configuration template.
//
// Parameters:
//  TemplateName - String - a configuration template name.
//
// Returns - FixedMap:
//                         * Key - String - a file name,
//                         * Value - String - a checksum.
//
Function AddInBundleFilesChecksum(Val TemplateName) Export
	
	Result = New Map();
	
	NameStructure = StrSplit(TemplateName, ".");
	
	If NameStructure.Count() = 2 Then
		
		// This is a common template
		Template = GetCommonTemplate(NameStructure[1]);
		
	ElsIf NameStructure.Count() = 4 Then
		
		// This is a metadata object template.
		ObjectManager = Common.ObjectManagerByFullName(NameStructure[0] + "." + NameStructure[1]);
		Template = ObjectManager.GetTemplate(NameStructure[3]);
		
	Else
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось сформировать разрешение на использование внешней компоненты:
				  |некорректное имя макета %1.'; 
				  |en = 'Cannot generate a permission to use the external component:
				  |incorrect name of the %1 template.'; 
				  |pl = 'Cannot generate a permission to use the external component:
				  |incorrect name of the %1 template.';
				  |de = 'Cannot generate a permission to use the external component:
				  |incorrect name of the %1 template.';
				  |ro = 'Cannot generate a permission to use the external component:
				  |incorrect name of the %1 template.';
				  |tr = 'Cannot generate a permission to use the external component:
				  |incorrect name of the %1 template.'; 
				  |es_ES = 'Cannot generate a permission to use the external component:
				  |incorrect name of the %1 template.'"), TemplateName);
	EndIf;
	
	If Template = Undefined Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось сформировать разрешение на использование внешней компоненты,
				  |поставляемой в макете %1: макет %1 не обнаружен в составе конфигурации.'; 
				  |en = 'Cannot create a permission to use the add-in supplied in the template %1:
				  | Template %1 is not found in the configuration.'; 
				  |pl = 'Cannot create a permission to use the add-in supplied in the template %1:
				  | Template %1 is not found in the configuration.';
				  |de = 'Cannot create a permission to use the add-in supplied in the template %1:
				  | Template %1 is not found in the configuration.';
				  |ro = 'Cannot create a permission to use the add-in supplied in the template %1:
				  | Template %1 is not found in the configuration.';
				  |tr = 'Cannot create a permission to use the add-in supplied in the template %1:
				  | Template %1 is not found in the configuration.'; 
				  |es_ES = 'Cannot create a permission to use the add-in supplied in the template %1:
				  | Template %1 is not found in the configuration.'"), TemplateName);
	EndIf;
	
	TemplateType = Metadata.FindByFullName(TemplateName).TemplateType;
	If TemplateType <> Metadata.ObjectProperties.TemplateType.BinaryData AND TemplateType <> Metadata.ObjectProperties.TemplateType.AddIn Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось сформировать разрешение на использование внешней компоненты:
				  |макет %1 не содержит двоичных данных.'; 
				  |en = 'Cannot generate a permission to use the external component:
				  |the %1 template does not contain binary data.'; 
				  |pl = 'Cannot generate a permission to use the external component:
				  |the %1 template does not contain binary data.';
				  |de = 'Cannot generate a permission to use the external component:
				  |the %1 template does not contain binary data.';
				  |ro = 'Cannot generate a permission to use the external component:
				  |the %1 template does not contain binary data.';
				  |tr = 'Cannot generate a permission to use the external component:
				  |the %1 template does not contain binary data.'; 
				  |es_ES = 'Cannot generate a permission to use the external component:
				  |the %1 template does not contain binary data.'"), TemplateName);
	EndIf;
	
	TempFile = GetTempFileName("zip");
	Template.Write(TempFile);
	
	Archiver = New ZipFileReader(TempFile);
	UnpackDirectory = GetTempFileName() + "\";
	CreateDirectory(UnpackDirectory);
	
	ManifestFile = "";
	For Each ArchiveItem In Archiver.Items Do
		If Upper(ArchiveItem.Name) = "MANIFEST.XML" Then
			ManifestFile = UnpackDirectory + ArchiveItem.Name;
			Archiver.Extract(ArchiveItem, UnpackDirectory);
		EndIf;
	EndDo;
	
	If IsBlankString(ManifestFile) Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось сформировать разрешение на использование внешней компоненты,
				  |поставляемой в макете %1: в архиве не обнаружен файл MANIFEST.XML.'; 
				  |en = 'Cannot create a permission to use the add-in supplied in the template %1: 
				  |The archive does not contain the MANIFEST.XML file.'; 
				  |pl = 'Cannot create a permission to use the add-in supplied in the template %1: 
				  |The archive does not contain the MANIFEST.XML file.';
				  |de = 'Cannot create a permission to use the add-in supplied in the template %1: 
				  |The archive does not contain the MANIFEST.XML file.';
				  |ro = 'Cannot create a permission to use the add-in supplied in the template %1: 
				  |The archive does not contain the MANIFEST.XML file.';
				  |tr = 'Cannot create a permission to use the add-in supplied in the template %1: 
				  |The archive does not contain the MANIFEST.XML file.'; 
				  |es_ES = 'Cannot create a permission to use the add-in supplied in the template %1: 
				  |The archive does not contain the MANIFEST.XML file.'"), TemplateName);
	EndIf;
	
	ReaderStream = New XMLReader();
	ReaderStream.OpenFile(ManifestFile);
	BundleDetails = XDTOFactory.ReadXML(ReaderStream, XDTOFactory.Type("http://v8.1c.ru/8.2/addin/bundle", "bundle"));
	For Each ComponentDetails In BundleDetails.component Do
		
		If ComponentDetails.type = "native" OR ComponentDetails.type = "com" Then
			
			ComponentFile = UnpackDirectory + ComponentDetails.path;
			
			Archiver.Extract(Archiver.Items.Find(ComponentDetails.path), UnpackDirectory);
			
			Hashing = New DataHashing(HashFunction.SHA1);
			Hashing.AppendFile(ComponentFile);
			
			HashSum = Hashing.HashSum;
			HashSumAsBase64String = Base64String(HashSum);
			
			Result.Insert(ComponentDetails.path, HashSumAsBase64String);
			
		EndIf;
		
	EndDo;
	
	ReaderStream.Close();
	Archiver.Close();
	
	Try
		DeleteFiles(UnpackDirectory);
	Except
		WriteLogEvent(NStr("ru = 'Работа в безопасном режиме.Не удалось удалить временный файл'; en = 'Safe mode.Cannot create temporary file'; pl = 'Safe mode.Cannot create temporary file';de = 'Safe mode.Cannot create temporary file';ro = 'Safe mode.Cannot create temporary file';tr = 'Safe mode.Cannot create temporary file'; es_ES = 'Safe mode.Cannot create temporary file'", Common.DefaultLanguageCode()), 
			EventLogLevel.Error, , , DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Try
		DeleteFiles(TempFile);
	Except
		WriteLogEvent(NStr("ru = 'Работа в безопасном режиме.Не удалось удалить временный файл'; en = 'Safe mode.Cannot create temporary file'; pl = 'Safe mode.Cannot create temporary file';de = 'Safe mode.Cannot create temporary file';ro = 'Safe mode.Cannot create temporary file';tr = 'Safe mode.Cannot create temporary file'; es_ES = 'Safe mode.Cannot create temporary file'", Common.DefaultLanguageCode()), 
			EventLogLevel.Error, , , DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Return New FixedMap(Result);
	
EndFunction

// Generates a reference by data from the permission registers.
//
// Parameters:
//  Type - CatalogRef.MetadataObjectID,
//  ID - UUID - a reference UUID.
//
// Returns: AnyRef.
//
Function ReferenceFormPermissionRegister(Val Type, Val ID) Export
	
	If Type = Catalogs.MetadataObjectIDs.EmptyRef() Then
		Return Type;
	EndIf;
		
	MetadataObject = Common.MetadataObjectByID(Type);
	Manager = Common.ObjectManagerByFullName(MetadataObject.FullName());
	
	If IsBlankString(ID) Then
		Return Manager.EmptyRef();
	Else
		Return Manager.GetRef(ID);
	EndIf;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Creating permission requests.
//

// Creates a request for changing permissions to use external resources.
// For internal use only.
//
// Parameters:
//  Owner - AnyRef - an owner of permissions to use external resources.
//    (Undefined when requesting permissions for the configuration, not for configuration objects),
//  ReplacementMode - Boolean - replacement mode of permissions provided earlier for the permission owner,
//  PermissionsToAdd - Array(XDTODataObject) - an array of XDTODataObjects that match internal 
//    details of permissions to access external resources being requested. It is assumed that all 
//    XDTO objects passed as parameters are generated using the SafeModeManager.Permission*() functions,
//  PermissionsToDelete - Array(XDTODataObject) - an array of XDTODataObjects that match internal 
//    details of permissions to access external resources being canceled. It is assumed that all 
//    XDTO objects passed as parameters are generated using the SafeModeManager.Permission*() functions,
//  ExternalModule - AnyRef - a reference that matches the external module for which permissions are 
//    being requested (Undefined if permissions are requested for configurations, not for external modules).
//
// Returns - UUID - an ID of the created request.
//
Function PermissionChangeRequest(Val Owner, Val ReplacementMode, Val PermissionsToAdd = Undefined, Val PermissionsToDelete = Undefined, Val ProgramModule = Undefined) Export
	
	StandardProcessing = True;
	Result = Undefined;
	
	SaaSIntegration.OnRequestPermissionsToUseExternalResources(
			ProgramModule, Owner, ReplacementMode, PermissionsToAdd, PermissionsToDelete, StandardProcessing, Result);
	
	If StandardProcessing Then
		
		SafeModeManagerOverride.OnRequestPermissionsToUseExternalResources(
			ProgramModule, Owner, ReplacementMode, PermissionsToAdd, PermissionsToDelete, StandardProcessing, Result);
		
	EndIf;
	
	If StandardProcessing Then
		
		Result = InformationRegisters.RequestsForPermissionsToUseExternalResources.RequestToUsePermissions(
			ProgramModule, Owner, ReplacementMode, PermissionsToAdd, PermissionsToDelete);
		
	EndIf;
	
	Return Result;
	
EndFunction

// Creates a request to delete a security profile for the external module.
// For internal use only.
//
// Parameters:
//  ExternalModule - AnyRef - a reference that matches the external module for which permissions are 
//    being requested (Undefined if permissions are requested for configurations, not for external modules).
//
// Returns - UUID - an ID of the created request.
//
Function RequestToDeleteSecurityProfile(Val ProgramModule) Export
	
	StandardProcessing = True;
	Result = Undefined;
	Operation = Enums.SecurityProfileAdministrativeOperations.Delete;
	
	SaaSIntegration.OnRequestToDeleteSecurityProfile(
			ProgramModule, StandardProcessing, Result);
	
	If StandardProcessing Then
		SafeModeManagerOverride.OnRequestToDeleteSecurityProfile(
			ProgramModule, StandardProcessing, Result);
	EndIf;
	
	If StandardProcessing Then
		
		Result = InformationRegisters.RequestsForPermissionsToUseExternalResources.PermissionAdministrationRequest(
			ProgramModule, Operation);
		
	EndIf;
	
	Return Result;
	
EndFunction

// Creates requests for application permission update.
//
// Parameters:
//  IIncludingIBProfileCreationRequest - Boolean - include a request to create a security profile 
//    for the current infobase to the result.
//
// Returns:
//   Array From UUID - request IDs for updating the configuration permissions to the currently 
//                                       required ones.
//
Function RequestsToUpdateApplicationPermissions(Val IncludingIBProfileCreationRequest = True) Export
	
	Result = New Array();
	
	BeginTransaction();
	Try
		If IncludingIBProfileCreationRequest Then
			Result.Add(RequestForSecurityProfileCreation(Catalogs.MetadataObjectIDs.EmptyRef()));
		EndIf;
		
		FillPermissionsToUpdatesProtectionCenter(Result);
		SSLSubsystemsIntegration.OnFillPermissionsToAccessExternalResources(Result);
		SafeModeManagerOverride.OnFillPermissionsToAccessExternalResources(Result);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Return Result;
	
EndFunction

Procedure FillPermissionsToUpdatesProtectionCenter(PermissionRequests)
	
	Permission = SafeModeManager.PermissionToUseInternetResource("HTTPS", "1cv8update.com",, 
		NStr("ru = 'Сайт ""Центр защиты обновлений"" (ЦЗО) для проверки правомерности использования и обновления программного продукта.'; en = 'The ""Update protection center"" (UPC) site for checking legitimacy of the software usage and updating.'; pl = 'The ""Update protection center"" (UPC) site for checking legitimacy of the software usage and updating.';de = 'The ""Update protection center"" (UPC) site for checking legitimacy of the software usage and updating.';ro = 'The ""Update protection center"" (UPC) site for checking legitimacy of the software usage and updating.';tr = 'The ""Update protection center"" (UPC) site for checking legitimacy of the software usage and updating.'; es_ES = 'The ""Update protection center"" (UPC) site for checking legitimacy of the software usage and updating.'"));
	Permissions = New Array;
	Permissions.Add(Permission);
	PermissionRequests.Add(SafeModeManager.RequestToUseExternalResources(Permissions));

EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Other.
//

// Returns the module that is the external module manager.
//
//  ExternalModule - AnyRef - a reference that matches the external module for which the manager is 
//    being requested.
//
// Returns: CommonModule.
//
Function ExternalModuleManager(Val ExternalModule) Export
	
	Managers = ExternalModulesManagers();
	For Each Manager In Managers Do
		ManagerContainers = Manager.ExternalModuleContainers();
		
		If TypeOf(ExternalModule) = Type("CatalogRef.MetadataObjectIDs") Then
			MetadataObject = Common.MetadataObjectByID(ExternalModule);
		Else
			MetadataObject = ExternalModule.Metadata();
		EndIf;
		
		If ManagerContainers.Find(MetadataObject) <> Undefined Then
			Return Manager;
		EndIf;
	EndDo;
	
	Return Undefined;
	
EndFunction

// Must be called when recording any internal data that cannot be changed in the safe mode.
// 
//
Procedure InternalDataOnWrite(Object) Export
	
	If SafeModeManager.SafeModeSet() Then
		
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Запись объекта %1 недоступна: установлен безопасный режим: %2.'; en = 'Cannot write the %1 object: safe mode is used: %2.'; pl = 'Cannot write the %1 object: safe mode is used: %2.';de = 'Cannot write the %1 object: safe mode is used: %2.';ro = 'Cannot write the %1 object: safe mode is used: %2.';tr = 'Cannot write the %1 object: safe mode is used: %2.'; es_ES = 'Cannot write the %1 object: safe mode is used: %2.'"),
			Object.Metadata().FullName(),
			SafeMode());
		
	EndIf;
	
EndProcedure

// Checks whether the interactive permission request mode is required.
//
// Returns: Boolean.
//
Function InteractivePermissionRequestModeUsed()
	
	If SecurityProfilesUsageAvailable() Then
		
		Return GetFunctionalOption("UseSecurityProfiles") AND Constants.AutomaticallyConfigurePermissionsInSecurityProfiles.Get();
		
	Else
		
		Return False;
		
	EndIf;
	
EndFunction

// Returns an array of the catalog managers that are external module containers.
//
// Returns: Array(CatalogManager).
//
Function ExternalModulesManagers()
	
	Managers = New Array;
	
	SSLSubsystemsIntegration.OnRegisterExternalModulesManagers(Managers);
	
	Return Managers;
	
EndFunction

#EndRegion
