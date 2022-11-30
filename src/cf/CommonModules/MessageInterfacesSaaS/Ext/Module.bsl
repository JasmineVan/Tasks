///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Returns message interface versions supported by the current infobase.
//  
//
// Parameters:
//  InterfaceName - String - application message interface name.
//
// Returns:
//  Array (items - strings), numbers of supported versions in the RR.{S|SS}.ZZ.CC format.
//
Function CurrentIBInterfaceVersions(Val InterfaceName) Export
	
	Result = Undefined;
	
	SenderInterfaces = New Structure;
	RecordOutgoingMessageVersions(SenderInterfaces);
	SenderInterfaces.Property(InterfaceName, Result);
	
	If Result = Undefined Or Result.Count() = 0 Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Текущая информационная база не поддерживает интерфейс %1.'; en = 'Current infobase does not support interface %1.'; pl = 'Bieżąca baza informacyjna nie obsługuje interfejs %1.';de = 'Die aktuelle Informationsbasis unterstützt die Schnittstelle %1 nicht.';ro = 'Baza de date curentă nu acceptă interfața %1.';tr = 'Mevcut veritabanı %1 arayüzü desteklemiyor.'; es_ES = 'La base de información actual no admite la interfaz %1.'"), InterfaceName);
	Else
		Return Result;
	EndIf;
	
EndFunction

// Returns message interface versions supported by the correspondent infobase.
//
// Parameters:
//  MessageInterface - String - application message interface name.
//  ConnectionParameters - Structure - parameters for connecting to the correspondent infobase.
//  RecipientPresentation - String - infobase correspondent presentation.
//  CurrentIBInterface - String - application interface name for the current infobase (used for the 
//    purposes of backward compatibility with earlier SSL versions).
//
// Returns:
//  String - the latest interface version supported both by the correspondent infobase and the current infobase.
//
Function CorrespondentInterfaceVersion(Val MessageInterface, Val ConnectionParameters, Val RecipientPresentation, Val CurrentIBInterface = "") Export
	
	CorrespondentVersions = Common.GetInterfaceVersions(ConnectionParameters, MessageInterface);
	If CurrentIBInterface = "" Then
		CorrespondentVersion = CorrespondentVersionSelection(MessageInterface, CorrespondentVersions);
	Else
		CorrespondentVersion = CorrespondentVersionSelection(CurrentIBInterface, CorrespondentVersions);
	EndIf;
	
	SaaSIntegration.OnDefineCorrespondentInterfaceVersion(
			MessageInterface,
			ConnectionParameters,
			RecipientPresentation,
			CorrespondentVersion);
	
	MessagesInterfacesSaaSOverridable.OnDefineCorrespondentInterfaceVersion(
		MessageInterface,
		ConnectionParameters,
		RecipientPresentation,
		CorrespondentVersion);
	
	Return CorrespondentVersion;
	
EndFunction

// Returns the message channel names used in a specified package.
//
// Parameters:
//  PackageURL - String - URL of XDTO package whose message types to be received.
//   
//  BaseType - XDTOType - base type.
//
// Returns:
//  FixedArray(String) - channel names in the package.
//
Function GetPackageChannels(Val PackageURL, Val BaseType) Export
	
	Result = New Array;
	
	PackageMessageTypes = 
		GetPackageMessageTypes(PackageURL, BaseType);
	
	For each MessageType In PackageMessageTypes Do
		Result.Add(MessagesSaaS.ChannelNameByMessageType(MessageType));
	EndDo;
	
	Return New FixedArray(Result);
	
EndFunction

// Returns types of XDTO objects in the package that match the remote administration message types.
// 
//
// Parameters:
//  PackageURL - String - URL of XDTO package whose message types to be received.
//   
//  BaseType - XDTOType - base type.
//
// Returns:
//  Array(XDTOObjectType) - message types in the package.
//
Function GetPackageMessageTypes(Val PackageURL, Val BaseType) Export
	
	Result = New Array;
	
	PackageModels = XDTOFactory.ExportXDTOModel(PackageURL);
	
	For Each PackageModel In PackageModels.package Do
		For Each ObjectTypeModel In PackageModel.objectType Do
			ObjectType = XDTOFactory.Type(PackageURL, ObjectTypeModel.name);
			If NOT ObjectType.Abstract
				AND BaseType.IsDescendant(ObjectType) Then
				
				Result.Add(ObjectType);
			EndIf;
		EndDo;
	EndDo;
	
	Return Result;
	
EndFunction

// Returns a fixed array containing the common modules used as outgoing message interface handlers.
//  
//
// Returns:
//  FixedArray - array elements are common modules.
//
Function GetOutgoingMessageInterfaceHandlers() Export
	
	HandlersArray = New Array();
	
	SSLSubsystemsIntegration.RecordingOutgoingMessageInterfaces(HandlersArray);
	MessagesInterfacesSaaSOverridable.FillOutgoingMessageHandlers(
		HandlersArray);
	
	Return New FixedArray(HandlersArray);
	
EndFunction

// Returns a fixed array containing the common modules used as incoming message interface handlers.
//  
//
// Returns:
//  FixedArray - array elements are common modules.
//
Function GetIncomingMessageInterfaceHandlers() Export
	
	HandlersArray = New Array();
	
	SSLSubsystemsIntegration.RecordingIncomingMessageInterfaces(HandlersArray);
	MessagesInterfacesSaaSOverridable.FillIncomingMessageHandlers(
		HandlersArray);
	
	Return New FixedArray(HandlersArray);
	
EndFunction

// Returns mapping between application message interface names and their handlers.
//
// Returns:
//  FixedMap: Key - string, name of the application interface, Value - CommonModule.
//
Function GetOutgoingMessageInterfaces() Export
	
	Result = New Map();
	HandlersArray = GetOutgoingMessageInterfaceHandlers();
	For Each Handler In HandlersArray Do
		Result.Insert(Handler.Package(), Handler.Public());
	EndDo;
	
	Return New FixedMap(Result);
	
EndFunction

// Returns mapping between application interface names and their current versions (those with 
//  messages generated in the caller script.
//
// Returns:
//  FixedMap: Key - string, name of the application interface, Value - string, version number.
//
Function GetOutgoingMessageVersions() Export
	
	Result = New Map();
	HandlersArray = GetOutgoingMessageInterfaceHandlers();
	For Each Handler In HandlersArray Do
		Result.Insert(Handler.Public(), Handler.Version());
	EndDo;
	
	Return New FixedMap(Result);
	
EndFunction

// Returns an array of message SaaS translation handlers.
//
// Returns:
//  Array contains common modules with message translation handlers.
//
Function GetMessageTranslationHandlers() Export
	
	Result = New Array();
	
	InterfaceHandlers = GetOutgoingMessageInterfaceHandlers();
	
	For Each InterfaceHandler In InterfaceHandlers Do
		
		TranslationHandlers = New Array();
		InterfaceHandler.MessagesTranslationHandlers(TranslationHandlers);
		CommonClientServer.SupplementArray(Result, TranslationHandlers);
		
	EndDo;
	
	Return New FixedArray(Result);
	
EndFunction

#EndRegion

#Region Internal

////////////////////////////////////////////////////////////////////////////////
// Configuration subsystems event handlers.

// See MessagesExchangeOverridable.GetMessagesChannelsHandlers. 
Procedure MessageChannelHandlersOnDefine(Handlers) Export
	
	InterfaceHandlers = GetIncomingMessageInterfaceHandlers();
	
	For Each InterfaceHandler In InterfaceHandlers Do
		
		InterfaceChannelHandlers  = New Array();
		InterfaceHandler.MessagesChannelsHandlers(InterfaceChannelHandlers);
		
		For Each InterfaceChannelHandler In InterfaceChannelHandlers Do
			
			Package = InterfaceChannelHandler.Package();
			BaseType = InterfaceChannelHandler.BaseType();
			
			ChannelNames = GetPackageChannels(Package, BaseType);
			
			For Each ChannelName In ChannelNames Do
				Handler = Handlers.Add();
				Handler.Canal = ChannelName;
				Handler.Handler = MessagesSaaSMessageHandler;
			EndDo;
			
		EndDo;
		
	EndDo;
	
EndProcedure

// See CommonOverridable.OnDefineSupportedAPIVersions. 
Procedure OnDefineSupportedInterfaceVersions(Val SupportedVersionsStructure) Export
	
	RecordIncomingMessageVersions(SupportedVersionsStructure);
	
EndProcedure

#EndRegion

#Region Private

// Fills the passed structure with the supported versions of incoming messages.
//  
//
// Parameters:
//  SupportedVersionsStructure - Structure:
//    Key - subsystem names,
//    Value - arrays of the supported versions names.
//
Procedure RecordIncomingMessageVersions(SupportedVersionsStructure)
	
	InterfaceHandlers = GetIncomingMessageInterfaceHandlers();
	
	For Each InterfaceHandler In InterfaceHandlers Do
		
		ChannelHandlers = New Array();
		InterfaceHandler.MessagesChannelsHandlers(ChannelHandlers);
		
		SupportedVersions = New Array();
		
		For Each VersionHandler In ChannelHandlers Do
			
			SupportedVersions.Add(VersionHandler.Version());
			
		EndDo;
		
		SupportedVersionsStructure.Insert(
			InterfaceHandler.Public(),
			SupportedVersions);
		
	EndDo;
	
EndProcedure

// Fills the passed structure with the supported versions of outgoing messages.
//  
//
// Parameters:
//  SupportedVersionsStructure - Structure:
//    Key - subsystem names,
//    Value - arrays of the supported versions names.
//
Procedure RecordOutgoingMessageVersions(SupportedVersionsStructure)
	
	InterfaceHandlers = GetOutgoingMessageInterfaceHandlers();
	
	For Each InterfaceHandler In InterfaceHandlers Do
		
		TranslationHandlers = New Array();
		InterfaceHandler.MessagesTranslationHandlers(TranslationHandlers);
		
		SupportedVersions = New Array();
		
		For Each VersionHandler In TranslationHandlers Do
			
			SupportedVersions.Add(VersionHandler.ResultingVersion());
			
		EndDo;
		
		SupportedVersions.Add(InterfaceHandler.Version());
		
		SupportedVersionsStructure.Insert(
			InterfaceHandler.Public(),
			SupportedVersions);
		
	EndDo;
	
EndProcedure

// Selects an interface version supported both by the current infobase and the correspondent 
// infobase.
//
// Parameters:
//  Interface - String, message interface name,
//  CorrespondentVersions - Array(String) message interface versions supported by the correspondent 
//    infobase.
//
Function CorrespondentVersionSelection(Val Interface, Val CorrespondentVersions)
	
	SenderVersions = CurrentIBInterfaceVersions(Interface);
	
	SelectedVersion = Undefined;
	
	For Each CorrespondentVersion In CorrespondentVersions Do
		
		If SenderVersions.Find(CorrespondentVersion) <> Undefined Then
			
			If SelectedVersion = Undefined Then
				SelectedVersion = CorrespondentVersion;
			Else
				SelectedVersion = ?(CommonClientServer.CompareVersions(
						CorrespondentVersion, SelectedVersion) > 0, CorrespondentVersion,
						SelectedVersion);
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Return SelectedVersion;
	
EndFunction

#EndRegion
