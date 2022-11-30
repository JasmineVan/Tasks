///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Returns the parameter structure for getting a file from the Internet.
//
// Returns:
//  Structure - with the following properties:
//     * PathForSaving - String - path on the server (including file name) for saving the downloaded file.
//                                                     Not filled in if a file is saved to the temporary storage.
//     * User - String - user that established the connection.
//     * Password - String - password of the user that established the connection.
//     * Port - Number - port used for connecting to the server.
//     * Timeout - Number - file getting timeout in seconds.
//     * SecureConnection - Boolean - indicates the use of secure ftps or https connection.
//                                    - SecureConnection - see details of the SecureConnection 
//                                                             property of the FTPConnection and HTTPConnection objects in Syntax Assistant.
//                                    - Undefined - in case the secure connection is not used.
//
//    Parameters only for http (https) connection:
//     * Headers                    - Map - see details of the Headers parameter of the HTTPRequest object in Syntax Assistant.
//     * UseOSAuthentication - Boolean -       see details of the
//                                                     UseOSAuthentication of the HTTPConnection object.
//
//    Parameters only for ftp (ftps) connection:
//     * PassiveConnection - Boolean - a flag that indicates that the connection should be passive (or active).
//     * SecureConnectionUsageLevel - SecureFTPConnectionUsageLevel - see details of the property 
//         with the same name in the platform Syntax Assistant. Default value is Auto.
//
Function FileGettingParameters() Export
	
	ReceivingParameters = New Structure;
	ReceivingParameters.Insert("PathForSaving", Undefined);
	ReceivingParameters.Insert("User", Undefined);
	ReceivingParameters.Insert("Password", Undefined);
	ReceivingParameters.Insert("Port", Undefined);
	ReceivingParameters.Insert("Timeout", AutomaticTimeoutDetermination());
	ReceivingParameters.Insert("SecureConnection", Undefined);
	ReceivingParameters.Insert("PassiveConnection", Undefined);
	ReceivingParameters.Insert("Headers", New Map);
	ReceivingParameters.Insert("UseOSAuthentication", False);
	ReceivingParameters.Insert("SecureConnectionUsageLevel", Undefined);
	
	Return ReceivingParameters;
	
EndFunction

#Region ObsoleteProceduresAndFunctions

// Obsolete. Use NetworkDownload.GetProxy instead.
// Returns InternetProxy object for Internet access.
// The following protocols are acceptable for creating InternetProxy: http, https, ftp, and ftps.
//
// Parameters:
//    URLOrProtocol - String - url in the following format: [Protocol://]<Server>/<Path to file on 
//                              server>, or protocol ID (http, ftp, ...).
//
// Returns:
//    InternetProxy - describes proxy server parameters for various protocols.
//                     If the network protocol scheme cannot be recognized, the proxy will be 
//                     created based on the HTTP protocol.
//
Function GetProxy(Val URLOrProtocol) Export
	
#If WebClient Then
	Raise NStr("ru='Прокси не доступен в веб-клиенте.'; en = 'Proxy is not available in the web client.'; pl = 'Serwer proxy nie jest dostępny w kliencie Web.';de = 'Der Proxy ist im Webclient nicht verfügbar.';ro = 'Proxy nu este disponibil în web-client.';tr = 'Proxy web istemcide kullanılamaz.'; es_ES = 'Proxy no disponible en el cliente web.'");
#Else
	
	AcceptableProtocols = New Map();
	AcceptableProtocols.Insert("HTTP",  True);
	AcceptableProtocols.Insert("HTTPS", True);
	AcceptableProtocols.Insert("FTP",   True);
	AcceptableProtocols.Insert("FTPS",  True);
	
	ProxyServerSetting = ProxyServerSetting();
	
	If StrFind(URLOrProtocol, "://") > 0 Then
		Protocol = SplitURL(URLOrProtocol).Protocol;
	Else
		Protocol = Lower(URLOrProtocol);
	EndIf;
	
	If AcceptableProtocols[Upper(Protocol)] = Undefined Then
		Protocol = "HTTP";
	EndIf;
	
	Return NewInternetProxy(ProxyServerSetting, Protocol);
	
#EndIf
	
EndFunction

// Obsolete. Use CommonUseClientServer.URIStructure.
// Splits URL: protocol, server, path to resource
//
// Parameters:
//    URL - String - link to a web resource.
//
// Returns:
//    Structure - a structure containing fields:
//        * Protocol - String - protocol of access to the resource.
//        * ServerName - String - server the resource is located on.
//        * PathToFileAtServer - String - path to the resource on the server.
//
Function SplitURL(Val URL) Export
	
	URLStructure = CommonClientServer.URIStructure(URL);
	
	Result = New Structure;
	Result.Insert("Protocol", ?(IsBlankString(URLStructure.Schema), "http", URLStructure.Schema));
	Result.Insert("ServerName", URLStructure.ServerName);
	Result.Insert("PathToFileAtServer", URLStructure.PathAtServer);
	
	Return Result;
	
EndFunction

// Obsolete. Use CommonUseClientServer.URIStructure.
// Splits the URI string and returns it as a structure.
// The following normalizations are described based on RFC 3986.
//
// Parameters:
//     URIString - String - link to the resource in the following format:
//                          <schema>://<username>:<password>@<domain>:<port>/<path>?<query_string>#<fragment_id.
//
// Returns:
//    Structure - composite parts of the URI according to the format:
//        * Scheme - String - URI scheme.
//        * Username - String - user name.
//        * Password - String - user password.
//        * ServerName - String - part <host>:<port> of the input parameter.
//        * Host - String - server name.
//        * Port - String - server port.
//        * PathAtServer - String - part <path>?<parameters>#<anchor> of the input parameter.
//
Function URIStructure(Val URIString) Export
	
	Return CommonClientServer.URIStructure(URIString);
	
EndFunction

#EndRegion

#EndRegion

#Region Internal

#Region ObsoleteProceduresAndFunctions

// Service information that displays current settings and proxy states to perform diagnostics.
//
// Returns:
//  Structure - with the following properties:
//     * ProxyConnection - Boolean - flag that indicates that proxy connection should be used.
//     * Presentation - String - presentation of the current set up proxy.
//
Function ProxySettingsStatus() Export
	
#If WebClient Then
	
	Result = New Structure;
	Result.Insert("ProxyConnection", False);
	Result.Insert("Presentation", NStr("ru = 'Прокси не доступен в веб-клиенте.'; en = 'Proxy is not available in the web client.'; pl = 'Serwer proxy nie jest dostępny w kliencie Web.';de = 'Der Proxy ist im Webclient nicht verfügbar.';ro = 'Proxy nu este disponibil în web-client.';tr = 'Proxy web istemcide kullanılamaz.'; es_ES = 'Proxy no disponible en el cliente web.'"));
	Return Result;
	
#Else
	
	Return NetworkDownloadInternalServerCall.ProxySettingsState();
	
#EndIf
	
EndFunction

#EndRegion

#EndRegion

#Region Private

Function AutomaticTimeoutDetermination() Export
	
	Return -1;
	
EndFunction

#Region ObsoleteProceduresAndFunctions

#If Not WebClient Then

// Returns proxy according to settings ProxyServerSetting for the specified Protocol protocol.
//
// Parameters:
//   ProxyServerSetting - Map:
//		UseProxy - indicates whether to use proxy server.
//		BypassProxyOnLocal - indicates whether to use proxy server for local addresses.
//		UseSystemSettings - indicates whether to use proxy server system settings.
//		Server - proxy server address.
//		Port - proxy server port.
//		User - username for authorization on proxy server.
//		Password - user password.
//		UseOSAuthentication - Boolean - a flag that indicates the use of authentication by means of the operating system.
//   Protocol - String - protocol for which proxy server parameters are set, for example "http", "https",
//                       "ftp".
// 
// Returns:
//   InternetProxy
// 
Function NewInternetProxy(ProxyServerSetting, Protocol)
	
	If ProxyServerSetting = Undefined Then
		// Proxy server system settings.
		Return Undefined;
	EndIf;
	
	UseProxy = ProxyServerSetting.Get("UseProxy");
	If Not UseProxy Then
		// Do not use a proxy server.
		Return New InternetProxy(False);
	EndIf;
	
	UseSystemSettings = ProxyServerSetting.Get("UseSystemSettings");
	If UseSystemSettings Then
		// Proxy server system settings.
		Return New InternetProxy(True);
	EndIf;
	
	// Manually configured proxy settings.
	Proxy = New InternetProxy;
	
	// Detecting a proxy server address and port.
	AdditionalSettings = ProxyServerSetting.Get("AdditionalProxySettings");
	ProxyByProtocol = Undefined;
	If TypeOf(AdditionalSettings) = Type("Map") Then
		ProxyByProtocol = AdditionalSettings.Get(Protocol);
	EndIf;
	
	UseOSAuthentication = ProxyServerSetting.Get("UseOSAuthentication");
	UseOSAuthentication = ?(UseOSAuthentication = True, True, False);
	
	If TypeOf(ProxyByProtocol) = Type("Structure") Then
		Proxy.Set(Protocol, ProxyByProtocol.Address, ProxyByProtocol.Port,
			ProxyServerSetting["User"], ProxyServerSetting["Password"], UseOSAuthentication);
	Else
		Proxy.Set(Protocol, ProxyServerSetting["Server"], ProxyServerSetting["Port"], 
			ProxyServerSetting["User"], ProxyServerSetting["Password"], UseOSAuthentication);
	EndIf;
	
	Proxy.BypassProxyOnLocal = ProxyServerSetting["BypassProxyOnLocal"];
	
	ExceptionsAddresses = ProxyServerSetting.Get("BypassProxyOnAddresses");
	If TypeOf(ExceptionsAddresses) = Type("Array") Then
		For each ExceptionAddress In ExceptionsAddresses Do
			Proxy.BypassProxyOnAddresses.Add(ExceptionAddress);
		EndDo;
	EndIf;
	
	Return Proxy;
	
EndFunction

#EndIf

Function ProxyServerSetting()
	
	// ACC:547-disable, the code is saved for backward compatibility. It is used in the obsolete interface.
	
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	ProxyServerSetting = GetFilesFromInternet.ProxySettingsAtServer();
#Else
	ProxyServerSetting = StandardSubsystemsClient.ClientRunParameters().ProxyServerSettings;
#EndIf
	
	// ACC:547-enable
	
	Return ProxyServerSetting;
	
EndFunction

#EndRegion

#EndRegion