///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

#Region ObsoleteProceduresAndFunctions

// Obsolete. It will be removed in the next library version.
// Returns a namespace of the current (used by the calling code) message interface version.
//
// Returns:
//   String - a namespace of the current message interface version.
//
Function Package() Export
	
	Return "http://www.1c.ru/1cFresh/ApplicationExtensions/Permissions/" + Version();
	
EndFunction

// Obsolete. It will be removed in the next library version.
// Returns the current (used by the calling code) message interface version.
//
// Returns:
//   String - a version.
//
Function Version() Export
	
	Return "1.0.0.1";
	
EndFunction

// Obsolete. It will be removed in the next library version.
// Returns the name of the application message interface.
//
// Returns:
//   String - an application interface ID.
//
Function Public() Export
	
	Return "ApplicationExtensionsPermissions";
	
EndFunction

// Obsolete. It will be removed in the next library version.
// Registers supported versions of message interface.
//
// Parameters:
//  SupportedVersionsStructure - Structure - an application interface name is passed as a key, while 
//    an array of supported versions is passed as a value.
//
Procedure RegisterInterface(Val SupportedVersionsStructure) Export
	
	VersionsArray = New Array;
	VersionsArray.Add("1.0.0.1");
	SupportedVersionsStructure.Insert(Public(), VersionsArray);
	
EndProcedure

// Obsolete. It will be removed in the next library version.
// Registers message handlers as message exchange channel handlers.
//
// Parameters:
//  HandlerArray - Array - an array of handlers.
//
Procedure MessageChannelHandlers(Val HandlersArray) Export
	
EndProcedure

// Obsolete. It will be removed in the next library version.
// Returns the action kind ID of the configuration method call.
//
// Returns:
//   String - an action kind ID.
//
Function ConfigurationMethodCallActionKind() Export
	
	Return "ConfigurationMethod"; // Do not localize.
	
EndFunction

// Obsolete. It will be removed in the next library version.
// Returns the action kind ID of the data processor method call.
//
// Returns:
//   String - an action kind ID.
//
Function DataProcessorMethodCallActionKind() Export
	
	Return "DataProcessorMethod"; // Do not localize.
	
EndFunction

// Obsolete. It will be removed in the next library version.
// Returns the parameter kind ID of the startup key.
//
// Returns:
//   String - a parameter kind.
//
Function SessionKeyParameterKind() Export
	
	Return "SessionKey"; // Do not localize.
	
EndFunction

// Obsolete. It will be removed in the next library version.
// Returns the parameter kind ID of the fixed value.
//
// Returns:
//   String - a parameter kind ID.
//
Function ValuePropertyKind() Export
	
	Return "FixedValue"; // Do not localize.
	
EndFunction

// Obsolete. It will be removed in the next library version.
// Returns the parameter kind ID of the value to be saved.
//
// Returns:
//   String - an action kind ID.
//
Function ValueToSaveParameterKind() Export
	
	Return "ValueToSave"; // Do not localize.
	
EndFunction

// Obsolete. It will be removed in the next library version.
// Returns the parameter kind ID of the collection of values to be saved.
//
// Returns:
//   String - an action kind ID.
//
Function ValueToSaveCollectionParameterKind() Export
	
	Return "ValueToSaveCollection"; // Do not localize.
	
EndFunction

// Obsolete. It will be removed in the next library version.
// Returns the parameter kind ID of the command execution parameter.
//
// Returns:
//   String - an action kind ID.
//
Function CommandRunParameterParameterKind() Export
	
	Return "CommandRunParameter"; // Do not localize.
	
EndFunction

// Obsolete. It will be removed in the next library version.
// Returns the parameter kind ID of the collection of related objects.
//
// Returns:
//   String - an action kind ID.
//
Function ParameterKindRelatedObjects() Export
	
	Return "RelatedObjects"; // Do not localize.
	
EndFunction

// Obsolete. It will be removed in the next library version.
// Constructor of a blank value table that is used as details of a safe mode scenario.
// 
//
// Returns:
//   ValueTable - a table with columns:
//     * ActionKind - String - an action kind ID.
//     * MethodName - String - a method name ID.
//     * Parameters - ValueTable - a table of parameters.
//     * ResultSaving - String - saving the result.
//
Function NewScenario() Export
	
	Result = New ValueTable();
	Result.Columns.Add("ActionKind", New TypeDescription("String"));
	Result.Columns.Add("MethodName", New TypeDescription("String"));
	Result.Columns.Add("Parameters", New TypeDescription("ValueTable"));
	Result.Columns.Add("ResultSaving", New TypeDescription("String"));
	
	Return Result;
	
EndFunction

// Obsolete. It will be removed in the next library version.
// Adds a stage of configuration method execution to data processor execution scenario in safe mode.
// 
//
// Parameters:
//  Scenario - ValueTable - see NewScenario. 
//  MethodName - String - a name of the configuration method meant to be called when executing a 
//    scenario stage.
//  ResultSaving - String - a name of the scenario value to be saved. It will store the result of 
//    the method passed in the MethodName parameter.
//
// Returns:
//   ValueTableRow - see NewScenario. 
//
Function AddConfigurationMethod(Scenario, Val MethodName, Val ResultSaving = "") Export
	
	Return AddStage(Scenario, ConfigurationMethodCallActionKind(), MethodName, ResultSaving);
	
EndFunction

// Obsolete. It will be removed in the next library version.
// Adds a stage that includes execution of a data processor method to data processor execution 
// scenario in safe mode.
//
// Parameters:
//  Scenario - ValueTable - see NewScenario. 
//  MethodName - String - a name of the configuration method meant to be called when executing a 
//    scenario stage.
//  ResultSaving - String - a name of the scenario value to be saved. It will store the result of 
//    the method passed in the MethodName parameter.
//
// Returns:
//   ValueTableRow - see NewScenario. 
//
Function AddDataProcessorMethod(Scenario, Val MethodName, Val ResultSaving = "") Export
	
	Return AddStage(Scenario, DataProcessorMethodCallActionKind(), MethodName, ResultSaving);
	
EndFunction

// Obsolete. It will be removed in the next library version.
// Constructor of a blank value table that is used as details of safe mode scenario item parameters.
// 
//
// Returns:
//   ValueTable - a table with columns:
//     * Kind - String - a parameter kind.
//     * Value - Arbitrary - a parameter value.
//
Function NewParameterTable() Export
	
	Result = New ValueTable();
	Result.Columns.Add("Kind", New TypeDescription("String"));
	Result.Columns.Add("Value");
	
	Return Result;
	
EndFunction

// Obsolete. It will be removed in the next library version.
// Adds a startup key of the current data processor to a parameter table.
//
// Parameters:
//  Stage - ValueTableRow - see AddConfigurationMethod or AddDataProcessorMethod. 
//
Procedure AddSessionKey(Stage) Export
	
	AddParameter(Stage, SessionKeyParameterKind());
	
EndProcedure

// Obsolete. It will be removed in the next library version.
// Adds a fixed value to a parameter table.
//
// Parameters:
//  Stage - ValueTableRow - see AddConfigurationMethod or AddDataProcessorMethod.  
//  Value - Arbitrary - a fixed value.
//
Procedure AddValue(Stage, Val Value) Export
	
	AddParameter(Stage, ValuePropertyKind(), Value);
	
EndProcedure

// Obsolete. It will be removed in the next library version.
// Adds a fixed value to a parameter table.
//
// Parameters:
//  Stage - ValueTableRow - see AddConfigurationMethod or AddDataProcessorMethod.  
//  ValueToSave - String - a name of the variable to store the value inside the scenario.
//
Procedure AddValueToSave(Stage, Val ValueToSave) Export
	
	AddParameter(Stage, ValueToSaveParameterKind(), ValueToSave);
	
EndProcedure

// Obsolete. It will be removed in the next library version.
// Adds a collection of values to be saved to the parameter table.
//
// Parameters:
//  Stage - ValueTableRow - see AddConfigurationMethod or AddDataProcessorMethod.  
//
Procedure AddCollectionOfValuesToSave(Stage) Export
	
	AddParameter(Stage, ValueToSaveCollectionParameterKind());
	
EndProcedure

// Obsolete. It will be removed in the next library version.
// Adds a command execution parameter to the parameter table.
//
// Parameters:
//  Stage - ValueTableRow - see AddConfigurationMethod or AddDataProcessorMethod.  
//  ParameterName - String - a name of the command execution parameter.
//
Procedure AddCommandRunParameter(Stage, Val ParameterName) Export
	
	AddParameter(Stage, CommandRunParameterParameterKind(), ParameterName);
	
EndProcedure

// Obsolete. It will be removed in the next library version.
// Adds a collection of related objects to the parameter table.
//
// Parameters:
//  Stage - ValueTableRow - see AddConfigurationMethod or AddDataProcessorMethod.  
//
Procedure AddRelatedObjects(Stage) Export
	
	AddParameter(Stage, ParameterKindRelatedObjects());
	
EndProcedure

// Obsolete. It will be removed in the next library version.
// Returns type {http://www.1c.ru/1cFresh/ApplicationExtensions/Core/a.b.c.d}CreateComObject
//
// Parameters:
//  PackageUsed - String - a namespace of the message interface version for which the message type 
//    is being received.
//
// Returns:
//  XDTOType - a message type.
//
Function COMObjectCreationType(Val PackageUsed = Undefined) Export
	
	Return GenerateMessageType(PackageUsed, "CreateComObject");
	
EndFunction

// Obsolete. It will be removed in the next library version.
// Returns object {http://www.1c.ru/1cFresh/ApplicationExtensions/Core/a.b.c.d}CreateComObject.
//
// Parameters:
//  ProgID - String - ProgID of COM class, with which it is registered in the application.
//    For example, "Excel.Application".
//  PackageUsed - String - a namespace of the message interface version for which the message type 
//    is being received.
//
// Returns:
//  XDTODataObject - a permission.
//
Function PermissionToCreateCOMObject(Val ProgId, Val PackageUsed = Undefined) Export
	
	Type = COMObjectCreationType(PackageUsed);
	Permission = XDTOFactory.Create(Type);
	Permission.ProgId = ProgId;
	
	Return Permission;
	
EndFunction

// Obsolete. It will be removed in the next library version.
// Returns type {http://www.1c.ru/1cFresh/ApplicationExtensions/Core/a.b.c.d}AttachAddin.
//
// Parameters:
//  PackageUsed - String - a namespace of the message interface version for which the message type 
//    is being received.
//
// Returns:
//  XDTOType - a message type.
//
Function AddInAttachmentType(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "AttachAddin");
	
EndFunction

// Obsolete. It will be removed in the next library version.
// Returns object {http://www.1c.ru/1cFresh/ApplicationExtensions/Core/a.b.c.d}AttachAddin.
//
// Parameters:
//  CommonTemplateName - String - a name of the common template.
//  PackageUsed - String - a namespace of the message interface version for which the message type 
//    is being received.
//
// Returns:
//  XDTODataObject - a permission.
//
Function AttachAddInFromCommonConfigurationTemplatePermission(Val CommonTemplateName, Val PackageToUse = Undefined) Export
	
	Type = AddInAttachmentType(PackageToUse);
	Permission = XDTOFactory.Create(Type);
	Permission.TemplateName = "CommonTemplate." + CommonTemplateName;
	
	Return Permission;
	
EndFunction

// Obsolete. It will be removed in the next library version.
// Returns object {http://www.1c.ru/1cFresh/ApplicationExtensions/Core/a.b.c.d}AttachAddin.
//
// Parameters:
//  MetadataObject - MetadataObject - a metadata object.
//  TemplateName - String - a template name.
//  PackageUsed - String - a namespace of the message interface version for which the message type 
//    is being received.
//
// Returns:
//  XDTODataObject - a permission.
//
Function AttachAddInFromConfigurationTemplatePermission(Val MetadataObject, Val TemplateName, Val PackageToUse = Undefined) Export
	
	Type = AddInAttachmentType(PackageToUse);
	Permission = XDTOFactory.Create(Type);
	Permission.TemplateName = MetadataObject.FullName() + ".Template" + TemplateName;
	
	Return Permission;
	
EndFunction

// Obsolete. It will be removed in the next library version.
// Returns type {http://www.1c.ru/1cFresh/ApplicationExtensions/Core/a.b.c.d}GetFileFromExternalSoftware.
//
// Parameters:
//  PackageUsed - String - a namespace of the message interface version for which the message type 
//    is being received.
//
// Returns:
//  XDTOType - a message type.
//
Function FileReceivingFromExternalObjectType(Val PackageUsed = Undefined) Export
	
	Return GenerateMessageType(PackageUsed, "GetFileFromExternalSoftware");
	
EndFunction

// Obsolete. It will be removed in the next library version.
// Returns object {http://www.1c.ru/1cFresh/ApplicationExtensions/Core/a.b.c.d}GetFileFromExternalSoftware.
//
// Parameters:
//  PackageUsed - String - a namespace of the message interface version for which the message type 
//    is being received.
//
// Returns:
//  XDTODataObject - a permission.
//
Function PermissionToGetFileFromExternalObject(Val PackageUsed = Undefined) Export
	
	Type = FileReceivingFromExternalObjectType(PackageUsed);
	Permission = XDTOFactory.Create(Type);
	
	Return Permission;
	
EndFunction

// Obsolete. It will be removed in the next library version.
// Returns type {http://www.1c.ru/1cFresh/ApplicationExtensions/Core/a.b.c.d}SendFileToExternalSoftware.
//
// Parameters:
//  PackageUsed - String - a namespace of the message interface version for which the message type 
//    is being received.
//
// Returns:
//  XDTOType - a message type.
//
Function TypeTransferFileToExternalObject(Val PackageUsed = Undefined) Export
	
	Return GenerateMessageType(PackageUsed, "SendFileToExternalSoftware");
	
EndFunction

// Obsolete. It will be removed in the next library version.
// Returns object {http://www.1c.ru/1cFresh/ApplicationExtensions/Core/a.b.c.d}SendFileToExternalSoftware.
//
// Parameters:
//  PackageUsed - String - a namespace of the message interface version for which the message type 
//    is being received.
//
// Returns:
//  XDTODataObject - a permission.
//
Function PermissionToSendFileToExternalObject(Val PackageUsed = Undefined) Export
	
	Type = TypeTransferFileToExternalObject(PackageUsed);
	Permission = XDTOFactory.Create(Type);
	
	Return Permission;
	
EndFunction

// Obsolete. It will be removed in the next library version.
// Returns type {http://www.1c.ru/1cFresh/ApplicationExtensions/Core/a.b.c.d}GetFileFromInternet.
//
// Parameters:
//  PackageUsed - String - a namespace of the message interface version for which the message type 
//    is being received.
//
// Returns:
//  XDTOType - a message type.
//
Function DataReceivingFromInternetType(Val PackageUsed = Undefined) Export
	
	Return GenerateMessageType(PackageUsed, "GetFileFromInternet");
	
EndFunction

// Obsolete. It will be removed in the next library version.
// Returns object {http://www.1c.ru/1cFresh/ApplicationExtensions/Core/a.b.c.d}GetFileFromInternet.
//
// Parameters:
//  Protocol - String - a protocol.
//  Server - String - a server.
//  Port - String - a port.
//  PackageUsed - String - a namespace of the message interface version for which the message type 
//    is being received.
//
// Returns:
//  XDTODataObject - a permission.
//
Function PermissionToGetDataFromInternet(Val Protocol, Val Server, Val Port, Val PackageUsed = Undefined) Export
	
	Type = DataReceivingFromInternetType(PackageUsed);
	Permission = XDTOFactory.Create(Type);
	Permission.Protocol = Upper(Protocol);
	Permission.Host = Server;
	Permission.Port = Port;
	
	Return Permission;
	
EndFunction

// Obsolete. It will be removed in the next library version.
// Returns type {http://www.1c.ru/1cFresh/ApplicationExtensions/Core/a.b.c.d}SendFileToInternet.
//
// Parameters:
//  PackageUsed - String - a namespace of the message interface version for which the message type 
//    is being received.
//
// Returns:
//  XDTOType - a message type.
//
Function DataSendingToInternetType(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "SendFileToInternet");
	
EndFunction

// Obsolete. It will be removed in the next library version.
// Returns object {http://www.1c.ru/1cFresh/ApplicationExtensions/Core/a.b.c.d}SendFileToInternet.
//
// Parameters:
//  Protocol - String - a data transfer protocol being used.
//  Server - String - a server.
//  Port - String - a port.
//  PackageUsed - String - a namespace of the message interface version for which the message type 
//    is being received.
//
// Returns:
//  XDTODataObject - a permission.
//
Function SendDataToInternetPermission(Val Protocol, Val Server, Val Port, Val PackageToUse = Undefined) Export
	
	Type = DataSendingToInternetType(PackageToUse);
	Permission = XDTOFactory.Create(Type);
	Permission.Protocol = Upper(Protocol);
	Permission.Host = Server;
	Permission.Port = Port;
	
	Return Permission;
	
EndFunction

// Obsolete. It will be removed in the next library version.
// Returns type {http://www.1c.ru/1cFresh/ApplicationExtensions/Core/a.b.c.d}SoapConnect.
//
// Parameters:
//  PackageUsed - String - a namespace of the message interface version for which the message type 
//    is being received.
//
// Returns:
//  XDTOType - a message type.
//
Function WSConnectionType(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "SoapConnect");
	
EndFunction

// Obsolete. It will be removed in the next library version.
// Returns object {http://www.1c.ru/1cFresh/ApplicationExtensions/Core/a.b.c.d}SoapConnect.
//
// Parameters:
//  WSDLAddress - String - a WDSL publication address.
//  PackageUsed - String - a namespace of the message interface version for which the message type 
//    is being received.
//
// Returns:
//  XDTODataObject - a permission.
//
Function WSConnectionPermission(Val WSDLAddress, Val PackageToUse = Undefined) Export
	
	Type = WSConnectionType(PackageToUse);
	Permission = XDTOFactory.Create(Type);
	Permission.WsdlDestination = WSDLAddress;
	
	Return Permission;
	
EndFunction

// Obsolete. It will be removed in the next library version.
// Returns type {http://www.1c.ru/1cFresh/ApplicationExtensions/Core/a.b.c.d}DocumentPosting.
//
// Parameters:
//  PackageUsed - String - a namespace of the message interface version for which the message type 
//    is being received.
//
// Returns:
//  XDTOType - a message type.
//
Function DocumentPostingType(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "DocumentPosting");
	
EndFunction

// Obsolete. It will be removed in the next library version.
// Returns object {http://www.1c.ru/1cFresh/ApplicationExtensions/Core/a.b.c.d}DocumentPosting.
//
// Parameters:
//  MetadataObject - MetadataObject - a metadata object.
//  WriteMode - DocumentWriteMode - a document write mode.
//  PackageUsed - String - a namespace of the message interface version for which the message type 
//    is being received.
//
// Returns:
//  XDTODataObject - a permission.
//
Function DocumentPostingPermission(Val MetadataObject, Val WriteMode, Val PackageUsed = Undefined) Export
	
	Type = DocumentPostingType(PackageUsed);
	Permission = XDTOFactory.Create(Type);
	Permission.DocumentType = MetadataObject.FullName();
	If WriteMode = DocumentWriteMode.Posting Then
		Permission.Action = "Posting";
	Else
		Permission.Action = "UndoPosting";
	EndIf;
	
	Return Permission;
	
EndFunction

// Obsolete. It will be removed in the next library version.
// Returns type {http://www.1c.ru/1cFresh/ApplicationExtensions/Core/a.b.c.d}InternalFileHandler.
//
// Parameters:
//  PackageUsed - String - a namespace of the message interface version for which the message type 
//    is being received.
//
// Returns:
//  XDTOType - a message type.
//
Function ParameterPassedFile(Val PackageUsed = Undefined) Export
	
	Return GenerateMessageType(PackageUsed, "InternalFileHandler");
	
EndFunction

// Obsolete. It will be removed in the next library version.
// Returns the value that matches "any restriction" value (*) during the registration of permissions 
// that are requested by the additional data processor.
//
// Returns:
//  Undefined - any value.
//
Function AnyValue() Export
	
	Return Undefined;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

// Obsolete.
Function GenerateMessageType(Val PackageToUse, Val Type)
		
	If PackageToUse = Undefined Then
		PackageToUse = Package();
	EndIf;
	
	Return XDTOFactory.Type(PackageToUse, Type);
	
EndFunction

// Obsolete.
Function AddStage(Scenario, Val StageKind, Val MethodName, Val ResultSaving = "")
	
	Stage = Scenario.Add();
	Stage.ActionKind = StageKind;
	Stage.MethodName = MethodName;
	Stage.Parameters = NewParameterTable();
	If Not IsBlankString(ResultSaving) Then
		Stage.ResultSaving = ResultSaving;
	EndIf;
	
	Return Stage;
	
EndFunction

// Obsolete.
Procedure AddParameter(Stage, Val ParameterKind, Val Value = Undefined)
	
	Parameter = Stage.Parameters.Add();
	Parameter.Kind = ParameterKind;
	If Value <> Undefined Then
		Parameter.Value = Value;
	EndIf;
	
EndProcedure

// Obsolete.
// Converts permissions from version 2.1.3 format to version 2.2.2 format.
//
Function ConvertVersion_2_1_3_PermissionsTo_2_2_2_VersionPermissions(Val AdditionalReportOrDataProcessor, Val Permissions) Export
	
	Result = New Array();
	
	// If the data processor has commands that are scenarios, adding rights to work with the temporary 
	// file directory.
	
	ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
	
	ScenariosFilter = New Structure("StartupOption", Enums.AdditionalDataProcessorsCallMethods.ScenarioInSafeMode);
	HasScenarios = AdditionalReportOrDataProcessor.Commands.FindRows(ScenariosFilter).Count() > 0;
	If HasScenarios Then
		Result.Add(ModuleSafeModeManager.PermissionToUseTempDirectory(True, True));
	EndIf;
	
	// Converting permissions to safe mode "expansion" notations.
	For Each Permission In Permissions Do
		
		If Permission.Type() = DataReceivingFromInternetType(Package()) Then
			
			Result.Add(
				ModuleSafeModeManager.PermissionToUseInternetResource(
					Permission.Protocol,
					Permission.Host,
					Permission.Port));
			
		ElsIf Permission.Type() = DataSendingToInternetType(Package()) Then
			
			Result.Add(
				ModuleSafeModeManager.PermissionToUseInternetResource(
					Permission.Protocol,
					Permission.Host,
					Permission.Port));
			
		ElsIf Permission.Type() = WSConnectionType(Package()) Then
			
			URIStructure = CommonClientServer.URIStructure(Permission.WsdlDestination);
			
			Result.Add(
				ModuleSafeModeManager.PermissionToUseInternetResource(
					URIStructure.Schema,
					URIStructure.ServerName,
					URIStructure.Port));
			
		ElsIf Permission.Type() = COMObjectCreationType(Package()) Then
			
			Result.Add(
				ModuleSafeModeManager.PermissionToCreateCOMClass(
					Permission.ProgId,
					COMClassIDInBackwardCompatibilityMode(Permission.ProgId)));
			
		ElsIf Permission.Type() = AddInAttachmentType(Package()) Then
			
			Result.Add(
				ModuleSafeModeManager.PermissionToUseAddIn(
					Permission.TemplateName));
			
		ElsIf Permission.Type() = FileReceivingFromExternalObjectType(Package()) Then
			
			Result.Add(
				ModuleSafeModeManager.PermissionToUseTempDirectory(True, True));
			
		ElsIf Permission.Type() = TypeTransferFileToExternalObject(Package()) Then
			
			Result.Add(
				ModuleSafeModeManager.PermissionToUseTempDirectory(True, True));
			
		ElsIf Permission.Type() = DocumentPostingType(Package()) Then
			
			Result.Add(ModuleSafeModeManager.PermissionToUsePrivilegedMode());
			
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

// Obsolete.
Function COMClassIDInBackwardCompatibilityMode(Val ProgId)
	
	SupportedIDs = COMClassesIDsInBackwardCompatibilityMode();
	CLSID = SupportedIDs.Get(ProgId);
	
	If CLSID = Undefined Then
		
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Разрешение на использование COM-класса ""%1"" не может быть предоставлено дополнительной обработке,
				|работающей в режиме обратной совместимости с механизмом разрешений, реализованным в версии БСП 2.1.3.
				|Для использования COM-класса требуется переработать дополнительную обработку для работы без режима обратной совместимости.'; 
				|en = 'Additional data processors in backward compatibility mode for permission mechanism (implemented in SSL 2.1.3)
				|cannot use COM class %1. To allow using the COM class,
				|modify the data processor so it will not require backward compatibility mode.'; 
				|pl = 'Uprawnienie do korzystania z klasy COM ""%1"" nie może być nadano przetwarzaniu dodatkowemu,
				|pracującemu w trybie kompatybilności odwrotnej z mechanizmem zezwoleń, realizowanym w wersji БСП 2.1.3.
				|W celu użycia klasy COM należy przetworzyć przetwarzanie dodatkowe do pracy bez trybu kompatybilności odwrotnej.';
				|de = 'Die Berechtigung zur Verwendung der COM-Klasse ""%1"" kann für die weitere Verarbeitung im Abwärtskompatibilitätsmodus mit dem in der BSP-Version 2.1.3 implementierten
				|Berechtigungsmechanismus nicht erteilt werden.
				|Für die Verwendung der COM-Klasse ist es notwendig, die zusätzliche Verarbeitung zu überarbeiten, um ohne Abwärtskompatibilitätsmodus zu arbeiten.';
				|ro = 'Permisiunea de utilizare a clasei COM ""%1"" nu poate fi oferită procesării suplimentare
				|care lucrează în modul de compatibilitate inversă cu mecanismul permisiunilor implementat în versiunea SSL 2.1.3.
				|Pentru a utiliza clasa COM este necesară transformarea procesării suplimentare pentru funcționare fără modul de compatibilitate inversă.';
				|tr = 'COM  sınıfını kullanma izni, %1SSL 2.1.3 sürümünde uygulanan izin  mekanizmasıyla geriye dönük uyumluluk modunda çalışan ek veri  işlemcisine verilemez. 
				|COM sınıfını kullanmak için, 
				|geriye dönük uyumluluk modu olmadan çalışmak için ek veri işlemcisini işlemek gerekir.'; 
				|es_ES = 'Permiso para utilizar la clase COM ""%1"" puede no otorgarse al procesador de datos adicional
				|que lanza en el modo de compatibilidad reversa con el mecanismo de permisos implementado en la versión SSL 2.1.3.
				|Para utilizar la clase COM, se requiere procesar el procesador de datos adicionales para trabajar sin el modo de compatibilidad reversa.'"),
			ProgId);
		
	Else
		
		Return CLSID;
		
	EndIf;
	
EndFunction

// Obsolete.
Function COMClassesIDsInBackwardCompatibilityMode()
	
	Result = New Map();
	
	// V83.ComConnector
	Result.Insert(CommonClientServer.COMConnectorName(), Common.COMConnectorID(CommonClientServer.COMConnectorName()));
	// Word.Application
	Result.Insert("Word.Application", "000209FF-0000-0000-C000-000000000046");
	// Excel.Application
	Result.Insert("Excel.Application", "00024500-0000-0000-C000-000000000046");
	
	Return Result;
	
EndFunction

#EndRegion
