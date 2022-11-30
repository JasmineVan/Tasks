///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

////////////////////////////////////////////////////////////////////////////////
// Permission constructors.
//

// Returns the internal description of the permission to use the file system directory.
//
// Parameters:
//  Address - String - a file system resource address,
//  DataReader - Boolean - indicates that it is required to grant permissions to read data from this 
//    file system directory,
//  DataWriter - Boolean - indicates that it is required to grant permissions to write data to the 
//    specified file system directory,
//  Details - String - details on the reason to grant the permission.
//
// Returns:
//  XDTODataObject - internal details of the permission being requested.
//  Intended only for passing as a parameter to functions.
//  SafeModeManager.RequestToUseExternalResources(),
//  SafeModeManager.RequestToCancelPermissionsToUseExternalResources() and
//  SafeModeManager.RequestToClearPermissionsToUseExternalResources().
//
Function PermissionToUseFileSystemDirectory(Val Address, Val DataReading = False, Val DataWriter = False, Val Details = "") Export
	
	Package = SafeModeManagerInternal.Package();
	Result = XDTOFactory.Create(XDTOFactory.Type(Package, "FileSystemAccess"));
	Result.Description = Details;
	
	If StrEndsWith(Address, "\") Or StrEndsWith(Address, "/") Then
		Address = Left(Address, StrLen(Address) - 1);
	EndIf;
	
	Result.Path = Address;
	Result.AllowedRead = DataReading;
	Result.AllowedWrite = DataWriter;
	
	Return Result;
	
EndFunction

// Returns the internal description of the permission to use the temporary file directory.
//
// Parameters:
//  DataReader - Boolean - indicates that it is required to grant a permission to read data from the 
//    temporary file directory,
//  DataWriter - Boolean - indicates that it is required to grant a permission to write data to the 
//    temporary file directory,
//  Details - String - details on the reason to grant the permission.
//
// Returns:
//  XDTODataObject - internal details of the permission being requested.
//  Intended only for passing as a parameter to functions.
//  SafeModeManager.RequestToUseExternalResources(),
//  SafeModeManager.RequestToCancelPermissionsToUseExternalResources() and
//  SafeModeManager.RequestToClearPermissionsToUseExternalResources().
//
Function PermissionToUseTempDirectory(Val DataReading = False, Val DataWriter = False, Val Details = "") Export
	
	Return PermissionToUseFileSystemDirectory(TempDirectoryAlias(), DataReading, DataWriter);
	
EndFunction

// Returns the internal description of the permission to use the application directory.
//
// Parameters:
//  DataReader - Boolean - indicates that it is required to grant a permission to read data from the 
//    application directory,
//  DataWriter - Boolean - indicates that it is required to grant a permission to write data to the 
//    application directory,
//  Details - String - details on the reason to grant the permission.
//
// Returns:
//  XDTODataObject - internal details of the permission being requested.
//  Intended only for passing as a parameter to functions.
//  SafeModeManager.RequestToUseExternalResources(),
//  SafeModeManager.RequestToCancelPermissionsToUseExternalResources() and
//  SafeModeManager.RequestToClearPermissionsToUseExternalResources().
//
Function PermissionToUseApplicationDirectory(Val DataReading = False, Val DataWriter = False, Val Details = "") Export
	
	Return PermissionToUseFileSystemDirectory(ApplicationDirectoryAlias(), DataReading, DataWriter);
	
EndFunction

// Returns the internal description of the permission to use the COM class.
//
// Parameters:
//  ProgID - String - ProgID of COM class, with which it is registered in the application.
//    For example, "Excel.Application".
//  CLSID - String - a CLSID of a COM class, with which it is registered in the application.
//  ComputerName - String - a name of the computer where the specified object must be created.
//    If the parameter is skipped, an object will be created on the computer where the current 
//    working process is running,
//  Details - String - details on the reason to grant the permission.
//
// Returns:
//  XDTODataObject - internal details of the permission being requested.
//  Intended only for passing as a parameter to functions.
//  SafeModeManager.RequestToUseExternalResources(),
//  SafeModeManager.RequestToCancelPermissionsToUseExternalResources() and
//  SafeModeManager.RequestToClearPermissionsToUseExternalResources().
//
Function PermissionToCreateCOMClass(Val ProgID, Val CLSID, Val ComputerName = "", Val Details = "") Export
	
	Package = SafeModeManagerInternal.Package();
	Result = XDTOFactory.Create(XDTOFactory.Type(Package, "CreateComObject"));
	Result.Description = Details;
	
	Result.ProgId = ProgID;
	Result.CLSID = String(CLSID);
	Result.ComputerName = ComputerName;
	
	Return Result;
	
EndFunction

// Returns the internal description of the permission to use the add-in distributed in the common 
//  configuration template.
//
// Parameters:
//  TemplateName - String - a name of the common template in the configuration that stores the 
//    add-in,
//  Details - String - details on the reason to grant the permission.
//
// Returns:
//  XDTODataObject - internal details of the permission being requested.
//  Intended only for passing as a parameter to functions.
//  SafeModeManagerRequestToUseExternalResources(),
//  SafeModeManager.RequestToCancelPermissionsToUseExternalResources() and
//  SafeModeManager.RequestToClearPermissionsToUseExternalResources().
//
Function PermissionToUseAddIn(Val TemplateName, Val Details = "") Export
	
	Package = SafeModeManagerInternal.Package();
	Result = XDTOFactory.Create(XDTOFactory.Type(Package, "AttachAddin"));
	Result.Description = Details;
	
	Result.TemplateName = TemplateName;
	
	Return Result;
	
EndFunction

// Returns the internal description of the permission to use the application extension.
//
// Parameters:
//  Name - String - a configuration extension name,
//  Checksum - String - a configuration extension checksum,
//  Details - String - details on the reason to grant the permission.
//
// Returns:
//  XDTODataObject - internal details of the permission being requested.
//  Intended only for passing as a parameter to functions.
//  SafeModeManager.RequestToUseExternalResources(),
//  SafeModeManager.RequestToCancelPermissionsToUseExternalResources() and
//  SafeModeManager.RequestToClearPermissionsToUseExternalResources().
Function PermissionToUseExternalModule(Val Name, Val Checksum, Val Details = "") Export
	
	Package = SafeModeManagerInternal.Package();
	Result = XDTOFactory.Create(XDTOFactory.Type(Package, "ExternalModule"));
	Result.Description = Details;
	
	Result.Name = Name;
	Result.Hash = Checksum;
	
	Return Result;
	
EndFunction

// Returns the internal description of the permission to use the operating system application.
//
// Parameters:
//  CommandLinePattern - String - a template of an application command line.
//                                 For more information, see the platform documentation.
//  Details - String - details on the reason to grant the permission.
//
// Returns:
//  XDTODataObject - internal details of the permission being requested.
//  Intended only for passing as a parameter to functions.
//  SafeModeManager.RequestToUseExternalResources(),
//  SafeModeManager.RequestToCancelPermissionsToUseExternalResources() and
//  SafeModeManager.RequestToClearPermissionsToUseExternalResources().
//
Function PermissionToUseOperatingSystemApplications(Val CommandLinePattern, Val Details = "") Export
	
	Package = SafeModeManagerInternal.Package();
	Result = XDTOFactory.Create(XDTOFactory.Type(Package, "RunApplication"));
	Result.Description = Details;
	
	Result.CommandMask = CommandLinePattern;
	
	Return Result;
	
EndFunction

// Returns the internal description of the permissions to use the Internet resource.
//
// Parameters:
//  Protocol - String - a protocol used to interact with the resource. The following values are available:
//      IMAP,
//      POP3,
//      SMTP,
//      HTTP,
//      HTTPS,
//      FTP,
//      FTPS,
//  Address - String - a resource address without a specified protocol,
//  Port - Number - a number of the port that is used to interact with the resource,
//  Details - String - details on the reason to grant the permission.
//
// Returns:
//  XDTODataObject - internal details of the permission being requested.
//  Intended only for passing as a parameter to functions.
//  SafeModeManager.RequestToUseExternalResources(),
//  SafeModeManager.RequestToCancelPermissionsToUseExternalResources() and
//  SafeModeManager.RequestToClearPermissionsToUseExternalResources().
//
Function PermissionToUseInternetResource(Val Protocol, Val Address, Val Port = Undefined, Val Details = "") Export
	
	If Port = Undefined Then
		StandardPorts = StandardInternetProtocolPorts();
		If StandardPorts.Property(Upper(Protocol)) <> Undefined Then
			Port = StandardPorts[Upper(Protocol)];
		EndIf;
	EndIf;
	
	Package = SafeModeManagerInternal.Package();
	Result = XDTOFactory.Create(XDTOFactory.Type(Package, "InternetResourceAccess"));
	Result.Description = Details;
	
	Result.Protocol = Protocol;
	Result.Host = Address;
	Result.Port = Port;
	
	Return Result;
	
EndFunction

// Returns the internal description of the permissions for extended data processing (including the 
// privileged mode) for external modules.
//
// Parameters:
//  Details - String - details on the reason to grant the permission.
//
// Returns:
//  XDTODataObject - internal details of the permission being requested.
//  Intended only for passing as a parameter to functions.
//  SafeModeManager.RequestToUseExternalResources(),
//  SafeModeManager.RequestToCancelPermissionsToUseExternalResources() and
//  SafeModeManager.RequestToClearPermissionsToUseExternalResources().
//
Function PermissionToUsePrivilegedMode(Val Details = "") Export
	
	Package = SafeModeManagerInternal.Package();
	Result = XDTOFactory.Create(XDTOFactory.Type(Package, "ExternalModulePrivilegedModeAllowed"));
	Result.Description = Details;
	
	Return Result;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Functions creating requests for permissions to use external resources.
//

// Creates a request to use external resources.
//
// Parameters:
//  NewPermissions - Array - an array of XDTODataObjects that match internal details of external 
//    resource access permissions to be requested. It is assumed that all XDTODataObjects passed as 
//    parameters are generated using the SafeModeManager.Permission*() functions.
//  Owner - AnyRef - a reference to the infobase object the permissions being requested are 
//    logically connected with. For example, all permissions to access file storage volume 
//    directories are logically associated with relevant FilesStorageVolumes catalog items, all 
//    permissions to access data exchange directories (or other resources according to the used 
//    exchange transport) are logically associated with relevant exchange plan nodes, and so on. If  
//    a permission is logically isolated (for example, if granting of a permission is controlled by 
//    the constant value with the Boolean type), it is recommended that you use a reference to the MetadataObjectsIDs catalog item,
//  ReplacementMode - Boolean - defines the replacement mode of permissions previously granted for this owner. 
//    If the value is True, in addition to granting the requested permissions, clearing all 
//    permissions that were previously requested for the owner are added to the request.
//
// Returns:
//  UUID -  a reference to the permission request written to the infobase. When all requests for 
//  permission changes are created, the changes must be applied by calling the procedure.
//  SafeModeManagerClient.ApplyExternalResourcesRequests().
//
Function RequestToUseExternalResources(Val NewPermissions, Val Owner = Undefined, Val ReplacementMode = True) Export
	
	Return SafeModeManagerInternal.PermissionChangeRequest(
		Owner,
		ReplacementMode,
		NewPermissions);
	
EndFunction

// Creates a request for canceling permissions to use external resources.
//
// Parameters:
//  Owner - AnyRef - a reference to the infobase object the permissions being canceled are logically 
//    connected with. For example, all permissions to access file storage volume directories are 
//    logically associated with relevant FilesStorageVolumes catalog items, all permissions to 
//    access data exchange directories (or other resources according to the used exchange transport) 
//    are logically associated with relevant exchange plan nodes, and so on. If a permission is  
//    logically isolated (for example, if permissions being canceled are controlled by the constant 
//    value with the Boolean type), it is recommended that you use a reference to the MetadataObjectsIDs catalog item,
//  PermissionsToCancel - Array - an array of XDTODataObjects that match internal details of 
//    external resource access permissions to be canceled. It is assumed that all XDTODataObjects 
//    passed as parameters are generated using the SafeModeManager.Permission*() functions.
//
// Returns:
//  UUID - a reference to the permission request written to the infobase. When all requests for 
//  permission changes are created, the changes must be applied by calling the procedure.
//  SafeModeManagerClient.ApplyExternalResourcesRequests().
//
Function RequestToCancelPermissionsToUseExternalResources(Val Owner, Val PermissionsToCancel) Export
	
	Return SafeModeManagerInternal.PermissionChangeRequest(
		Owner,
		False,
		,
		PermissionsToCancel);
	
EndFunction

// Creates a request for canceling all owner's permissions to use external resources.
//
// Parameters:
//  Owner - AnyRef - a reference to the infobase object the permissions being canceled are logically 
//    connected with. For example, all permissions to access file storage volume directories are 
//    logically associated with relevant FilesStorageVolumes catalog items, all permissions to 
//    access data exchange directories (or other resources according to the used exchange transport) 
//    are logically associated with relevant exchange plan nodes, and so on. If a permission is  
//    logically isolated (for example, if permissions being canceled are controlled by the constant 
//    value with the Boolean type), it is recommended that you use a reference to the MetadataObjectsIDs catalog item.
//
// Returns:
//  UUID - a reference to the permission request written to the infobase. When all requests for 
//  permission changes are created, the changes must be applied by calling the procedure.
//  SafeModeManagerClient.ApplyExternalResourcesRequests().
//
Function RequestToClearPermissionsToUseExternalResources(Val Owner) Export
	
	Return SafeModeManagerInternal.PermissionChangeRequest(
		Owner,
		True);
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Supporting security profiles in a configuration where attaching external modules with the 
// disabled safe mode is not allowed.
//

// Checks whether the safe mode is enabled ignoring the security profile safe mode that is used as a 
//  security profile with the configuration privilege level.
//
// Returns:
//   Boolean - True if the safe mode is enabled.
//
Function SafeModeSet() Export
	
	CurrentSafeMode = SafeMode();
	
	If TypeOf(CurrentSafeMode) = Type("String") Then
		
		If Not SwichingToPrivilegedModeAvailable() Then
			Return True; // If the safe mode is not enabled, switching to the privileged mode is always available.
		EndIf;
		
		Try
			InfobaseProfile = InfobaseSecurityProfile();
		Except
			Return True;
		EndTry;
		
		Return (CurrentSafeMode <> InfobaseProfile);
		
	ElsIf TypeOf(CurrentSafeMode) = Type("Boolean") Then
		
		Return CurrentSafeMode;
		
	EndIf;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Other procedures and functions
//

// Creates requests for application permission update.
//
// Parameters:
//  IIncludingIBProfileCreationRequest - Boolean - include a request to create a security profile 
//    for the current infobase to the result.
//
// Returns:
//  Array - request IDs for updating the configuration permissions to the currently required ones.
//           
//
Function RequestsToUpdateApplicationPermissions(Val IncludingIBProfileCreationRequest = True) Export
	
	Return SafeModeManagerInternal.RequestsToUpdateApplicationPermissions(IncludingIBProfileCreationRequest);
	
EndFunction

// Returns checksums of add-in files from the bundle provided in the configuration template.
//
// Parameters:
//   TemplateName - String - a configuration template name.
//
// Returns:
//   FixedMap - file checksums:
//                         * Key - String - a file name,
//                         * Value - String - a checksum.
//
Function AddInBundleFilesChecksum(Val TemplateName) Export
	
	Return SafeModeManagerInternal.AddInBundleFilesChecksum(TemplateName);
	
EndFunction

#Region ObsoleteProceduresAndFunctions

// Obsolete. Use Common.ExecuteConfigurationMethod instead.
//
// Parameters:
//  MethodName - String - a name of the export procedure as
//                       <object name>.<procedure name>, where <object name> is a common module or 
//                       an object manager module.
//  Parameters - Array - parameters are passed to <ExportProcedureName>
//                       according to the array element order.
//
Procedure ExecuteConfigurationMethod(Val MethodName, Val Parameters = Undefined) Export
	Common.ExecuteConfigurationMethod(MethodName, Parameters);
EndProcedure

// Obsolete. Use Common.ExecuteObjectMethod instead.
//
// Parameters:
//   Object - Arbitrary - 1C:Enterprise language object that contains the methods (for example, DataProcessorObject),
//   MethodName - String - a name of export procedure of the data processor object module.
//   Parameters - Array - parameters are passed to <ProcedureName> according to the array element order.
//
Procedure ExecuteObjectMethod(Val Object, Val MethodName, Val Parameters = Undefined) Export
	Common.ExecuteObjectMethod(Object, MethodName, Parameters);
EndProcedure

// Obsolete. Use Common.ExecuteInSafeMode instead.
//
// Parameters:
//  Algorithm - String - contains an arbitrary algorithm in the 1C:Enterprise language.
//  Parameters - Arbitrary - any value as might be required for the algorithm. The algorithm code 
//    must refer to this value as the Parameters variable.
//    
//
Procedure ExecuteInSafeMode(Val Algorithm, Val Parameters = Undefined) Export
	Common.ExecuteInSafeMode(Algorithm, Parameters);
EndProcedure

// Obsolete. Use Common.CalculateInSafeMode instead.
//
// Parameters:
//  Expression - String - an expression to be calculated. For example, "MyModule.MyFunction(Parameters)".
//  Parameters - Arbitrary - any value as might be required for evaluating the expression. The 
//    expression must refer to  this value as the Parameters variable.
//    
//
// Returns:
//   Arbitrary - the result of the expression calculation.
//
Function CalculateInSafeMode(Val Expression, Val Parameters = Undefined) Export
	Return Common.CalculateInSafeMode(Expression, Parameters);
EndFunction

#EndRegion

#EndRegion

#Region Internal

Function UseSecurityProfiles() Export
	Return GetFunctionalOption("UseSecurityProfiles");
EndFunction

// Returns the name of the security profile that provides privileges for configuration code.
//
// Returns: String - a security profile name.
//
Function InfobaseSecurityProfile(CheckForUsage = False) Export
	
	If CheckForUsage AND Not GetFunctionalOption("UseSecurityProfiles") Then
		Return "";
	EndIf;
	
	SetPrivilegedMode(True);
	
	Return Constants.InfobaseSecurityProfile.Get();
	
EndFunction

#EndRegion

#Region Private

// Checks whether the privileged mode can be set from the current safe mode.
//
// Returns: Boolean.
//
Function SwichingToPrivilegedModeAvailable()
	
	SetPrivilegedMode(True);
	Return PrivilegedMode();
	
EndFunction

// Returns the predefined alias of the application directory.
//
// Returns: String.
//
Function ApplicationDirectoryAlias()
	
	Return "/bin";
	
EndFunction

// Returns the predefined alias of the temporary file directory.
//
Function TempDirectoryAlias()
	
	Return "/temp";
	
EndFunction

// Returns the standard ports of the Internet protocols that can be processed using the 1C:
//  Enterprise language. Is used to determine the port if the applied code requests the permission 
//  but does not define the port.
//
// Returns: FixedStructure:
//                          * Key - String - an Internet protocol name,
//                          * Value - Number - a port number.
//
Function StandardInternetProtocolPorts()
	
	Result = New Structure();
	
	Result.Insert("IMAP",  143);
	Result.Insert("POP3",  110);
	Result.Insert("SMTP",  25);
	Result.Insert("HTTP",  80);
	Result.Insert("HTTPS", 443);
	Result.Insert("FTP",   21);
	Result.Insert("FTPS",  21);
	
	Return New FixedStructure(Result);
	
EndFunction

#EndRegion

