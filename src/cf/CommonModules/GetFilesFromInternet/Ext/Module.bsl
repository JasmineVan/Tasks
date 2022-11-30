///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Gets the file from the Internet via http(s) protocol or ftp protocol and saves it at the specified path on server.
//
// Parameters:
//   URL - String - file URL in the following format: [Protocol://]<Server>/<Path to the file on the server>.
//   ReceivingParameters - Structure - see GetFilesFromInternetClientServer.FileReceivingParameters. 
//   WriteError - Boolean - indicates the need to write errors to event log while getting the file.
//
// Returns:
//   Structure - structure with the following properties:
//      * Status - Boolean - file getting result.
//      * Path - String - path to the file on the server. This key is used only if Status is True.
//      * ErrorMessage - String - error message if Status is False.
//      * Headers         - Map - see details of the Headers parameter of the HTTPResponse object in Syntax Assistant.
//      * StatusCode - Number - adds in case of an error.
//                                    See details of the StatusCode parameter of the HTTPResponse object in Syntax Assistant.
//
Function DownloadFileAtServer(Val URL, ReceivingParameters = Undefined, Val WriteError = True) Export
	
	SavingSetting = New Map;
	SavingSetting.Insert("StorageLocation", "Server");
	
	Return GetFilesFromInternetInternal.DownloadFile(URL,
		ReceivingParameters, SavingSetting, WriteError);
	
EndFunction

// Gets a file from the internet over HTTP(S) or FTP and saves it to a temporary storage.
// Note: After getting the file, clear the temporary storage by using the DeleteFromTempStorage 
// method. If you do not do it, the file will remain in the server memory until the session is over.
// 
//
// Parameters:
//   URL - String - file URL in the following format: [Protocol://]<Server>/<Path to the file on the server>.
//   ReceivingParameters - Structure - see GetFilesFromInternetClientServer.FileReceivingParameters. 
//   WriteError - Boolean - indicates the need to write errors to event log while getting the file.
//
// Returns:
//   Structure - structure with the following properties:
//      * Status - Boolean - file getting result.
//      * Path - String - temporary storage address with the file binary data, the key is used only 
//                            if Status is True.
//      * ErrorMessage - String - error message if Status is False.
//      * Headers         - Map - see details of the Headers parameter of the HTTPResponse object in Syntax Assistant.
//      * StatusCode - Number - adds in case of an error.
//                                    See details of the StatusCode parameter of the HTTPResponse object in Syntax Assistant.
//
Function DownloadFileToTempStorage(Val URL, ReceivingParameters = Undefined, Val WriteError = True) Export
	
	SavingSetting = New Map;
	SavingSetting.Insert("StorageLocation", "TemporaryStorage");
	
	Return GetFilesFromInternetInternal.DownloadFile(URL,
		ReceivingParameters, SavingSetting, WriteError);
	
EndFunction

// Returns proxy settings of Internet access on the client side of the currnet user.
// 
//
// Returns:
//   Map - properties:
//		UseProxy - indicates whether to use proxy server.
//		BypassProxyOnLocal - indicates whether to use proxy server for local addresses.
//		UseSystemSettings - indicates whether to use proxy server system settings.
//		Server - proxy server address.
//		Port - proxy server port.
//		User - username for authorization on proxy server.
//		Password - user password.
//
Function ProxySettingsAtClient() Export
	
	Username = Undefined;
	
	If Common.FileInfobase() Then
		
		// In file mode, scheduled jobs are executed on the same computer where the user is working.
		// 
		
		CurrentInfobaseSession = GetCurrentInfoBaseSession();
		BackgroundJob = CurrentInfobaseSession.GetBackgroundJob();
		IsScheduledJobSession = BackgroundJob <> Undefined AND BackgroundJob.ScheduledJob <> Undefined;
		
		If IsScheduledJobSession Then
			
			If Not ValueIsFilled(BackgroundJob.ScheduledJob.UserName) Then 
				
				// If a scheduled job is executed on behalf of a user by default, proxy server settings are to be 
				// taken from the saved settings of the user, on whose computer the current scheduled job session is 
				// running.
				
				Sessions = GetInfoBaseSessions();
				For Each Session In Sessions Do 
					If Session.ComputerName = CurrentInfobaseSession.ComputerName Then 
						Username = Session.User.Name;
						Break;
					EndIf;
				EndDo;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return Common.CommonSettingsStorageLoad("ProxyServerSetting", "",,, Username);
	
EndFunction

// Returns proxy setting parameters on the 1C:Enterprise server side.
//
// Returns:
//   Map - properties:
//		UseProxy - indicates whether to use proxy server.
//		BypassProxyOnLocal - indicates whether to use proxy server for local addresses.
//		UseSystemSettings - indicates whether to use proxy server system settings.
//		Server - proxy server address.
//		Port - proxy server port.
//		User - username for authorization on proxy server.
//		Password - user password.
//
Function ProxySettingsAtServer() Export
	
	If Common.FileInfobase() Then
		Return ProxySettingsAtClient();
	Else
		SetPrivilegedMode(True);
		ProxySettingsAtServer = Constants.ProxyServerSetting.Get().Get();
		Return ?(TypeOf(ProxySettingsAtServer) = Type("Map"),
			ProxySettingsAtServer,
			Undefined);
	EndIf;
	
EndFunction

// Returns the InternetProxy object for the Internet access.
// The following protocols are acceptable for creating InternetProxy: http, https, ftp, and ftps.
//
// Parameters:
//    URLOrProtocol - String - url in the following format: [Protocol://]<Server>/<Path to file on 
//                              server>, or protocol identifier (http, ftp, ...).
//
// Returns:
//    InternetProxy - describes proxy server parameters for various protocols.
//                     If the network protocol scheme cannot be recognized, the proxy will be 
//                     created based on the HTTP protocol.
//
Function GetProxy(Val URLOrProtocol) Export
	
	AcceptableProtocols = New Map();
	AcceptableProtocols.Insert("HTTP",  True);
	AcceptableProtocols.Insert("HTTPS", True);
	AcceptableProtocols.Insert("FTP",   True);
	AcceptableProtocols.Insert("FTPS",  True);
	
	ProxyServerSetting = ProxySettingsAtServer();
	
	If StrFind(URLOrProtocol, "://") > 0 Then
		URLStructure = CommonClientServer.URIStructure(URLOrProtocol);
		Protocol = ?(IsBlankString(URLStructure.Schema), "http", URLStructure.Schema);
	Else
		Protocol = Lower(URLOrProtocol);
	EndIf;
	
	If AcceptableProtocols[Upper(Protocol)] = Undefined Then
		Protocol = "HTTP";
	EndIf;
	
	Return GetFilesFromInternetInternal.NewInternetProxy(ProxyServerSetting, Protocol);
	
EndFunction

// Runs the network resource diagnostics.
// In SaaS mode, returns only an error description.
//
// Parameters:
//  URL - String - URL resource address to be diagnosed.
//
// Returns:
//  Structure - a diagnostics result:
//    *  ErrorDescription    - String - a brief error description.
//    *  DiagnosticsLog - String - a detailed log of diagnostcs with texchnical details.
//
// Example:
//	// Diagnostics of address classifier web service.
//	Result = CommonUseClientServer. ConnectionDiagnostics ("https://api.orgaddress.1c.ru/orgaddress/v1?wsdl").
//	
//	ErrorDescription    = Result.ErrorDescription;
//	DiagnosticsLog = Result.DiagnosticsLog.
//
Function ConnectionDiagnostics(URL) Export
	
	Details = New Array;
	Details.Add(StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'При обращении по URL: %1'; en = 'Accessing URL: %1.'; pl = 'Podczas odwołania do URL: %1';de = 'Beim Zugriff auf die URL: %1';ro = 'La adresare prin URL: %1';tr = 'URL''ye erişirken: %1'; es_ES = 'Al llamar por URL: %1'"), 
		URL));
	Details.Add(GetFilesFromInternetInternal.DiagnosticsLocationPresentation());
	
	If Common.DataSeparationEnabled() Then
		Details.Add(
			NStr("ru = 'Обратитесь к администратору.'; en = 'Please contact the administrator.'; pl = 'Skontaktuj się z administratorem.';de = 'Kontaktieren Sie den Administrator.';ro = 'Contactați administratorul.';tr = 'Yöneticiye başvurun.'; es_ES = 'Contactar el administrador.'"));
		
		ErrorDescription = StrConcat(Details, Chars.LF);
		
		Result = New Structure;
		Result.Insert("ErrorDescription", ErrorDescription);
		Result.Insert("DiagnosticsLog", "");
		
		Return Result;
	EndIf;
	
	Log = New Array;
	Log.Add(
		NStr("ru = 'Журнал диагностики:
		           |Выполняется проверка доступности сервера.
		           |Описание диагностируемой ошибки см. в следующем сообщении журнала.'; 
		           |en = 'Diagnostics log:
		           |Checking server availability.
		           |See the error description in the next log record.'; 
		           |pl = 'Dziennik diagnostyki:
		           |Jest wykonywana weryfikacja dostępności serwera.
		           |Opis wykrywanego błędu zob. w następnej wiadomości dziennika.';
		           |de = 'Diagnoseprotokoll:
		           |Die Verfügbarkeit des Servers wird überprüft.
		           |Die Beschreibung des zu diagnostizierenden Fehlers finden Sie in der folgenden Protokollnachricht.';
		           |ro = 'Registrul diagnostic:
		           |Se execută verificarea accesibilității serverului.
		           |Descrierea erorii diagnosticate vezi în mesajul următor al registrului.';
		           |tr = 'Tanılama günlüğü: 
		           |sunucu kullanılabilirliğini denetler. 
		           |Teşhis edilen hatanın açıklaması için aşağıdaki günlük iletisine bakın.'; 
		           |es_ES = 'El registro de diagnóstica:
		           |Se está realizando la prueba de disponibilidad del servidor.
		           |La descripción del error diagnosticado véase en el siguiente mensaje del registro.'"));
	Log.Add();
	
	ProxySettingsState = GetFilesFromInternetInternal.ProxySettingsState();
	ProxyConnection = ProxySettingsState.ProxyConnection;
	Log.Add(ProxySettingsState.Presentation);
	
	If ProxyConnection Then 
		
		Details.Add(
			NStr("ru = 'Диагностика соединения не выполнена, т.к. настроен прокси-сервер.
			           |Обратитесь к администратору.'; 
			           |en = 'Connection diagnostics are not performed because a proxy server is configured.
			           |Please contact the administrator.'; 
			           |pl = 'Diagnostyka połączenia nie jest wykonana, ponieważ jest ustawiony serwer proxy.
			           |Zwróć się do administratora.';
			           |de = 'Die Diagnose der Verbindung wird nicht durchgeführt, da der Proxy-Server konfiguriert ist.
			           |Wenden Sie sich an den Administrator.';
			           |ro = 'Diagnosticul conexiunii nu este executat, deoarece este setat serverul proxy.
			           |Adresați-vă administratorului.';
			           |tr = 'Proxy sunucusu yapılandırıldığından bağlantı tanılama başarısız oldu. 
			           |Lütfen sistem yöneticinize başvurun.'; 
			           |es_ES = 'La diagnóstica de la conexión no se ha realizado porque está ajustado el servidor proxy.
			           |Diríjase al administrador.'"));
		
	Else 
		
		RefStructure = CommonClientServer.URIStructure(URL);
		ResourceServerAddress = RefStructure.Host;
		VerificationServerAddress = "1c.com";
		
		ResourceAvailabilityResult = GetFilesFromInternetInternal.CheckServerAvailability(ResourceServerAddress);
		
		Log.Add();
		Log.Add("1) " + ResourceAvailabilityResult.DiagnosticsLog);
		
		If ResourceAvailabilityResult.Available Then 
			
			Details.Add(StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Выполнено обращение к несуществующему ресурсу на сервере %1
				           |или возникли неполадки на удаленном сервере.'; 
				           |en = 'Attempted to access a resource that does not exist on server %1,
				           |or some issues occurred on the remote server.'; 
				           |pl = 'Zostało wykonane odwołanie do nie istniejącego zasobu na serwerze %1
				           |lub wystąpiły problemy na usuniętym serwerze.';
				           |de = 'Der Verweis auf eine nicht vorhandene Ressource auf einem Server wird ausgeführt oder %1
				           |es gab Störungen auf einem entfernten Server.';
				           |ro = 'Adresare la resursa inexistentă pe server %1
				           |sau au apărut defecțiuni pe serverul la distanță.';
				           |tr = 'Sunucudaki mevcut olmayan kaynağa erişildi%1
				           |veya uzak sunucuda sorun yaşandı.'; 
				           |es_ES = 'Se ha realizado la llamada al recurso no existente en el servidor%1
				           |o han aparecido los fallos en el servidor remoto.'"),
				ResourceServerAddress));
			
		Else 
			
			VerificationResult = GetFilesFromInternetInternal.CheckServerAvailability(VerificationServerAddress);
			Log.Add("2) " + VerificationResult.DiagnosticsLog);
			
			If Not VerificationResult.Available Then
				
				Details.Add(
					NStr("ru = 'Отсутствует доступ в сеть интернет по причине:
					           |- компьютер не подключен к интернету;
					           |- неполадки у интернет-провайдера;
					           |- подключение к интернету блокирует межсетевой экран, 
					           |  антивирусная программа или другое программное обеспечение.'; 
					           |en = 'No internet access. Possible reasons:
					           |- The computer is not connected to the internet.
					           | - Internet service provider issues.
					           |- A firewall, antivirus, or another software
					           |  is blocking the connection.'; 
					           |pl = 'Brakuje dostęp do sieci Internet z powodu:
					           |- komputer nie jest podłączony do Internetu;
					           |- problemy u operatora Internetu;
					           |- podłączenie do Internetu blokuje zapora sieciowa, 
					           |  program antiwirusowy lub inne oprogramowanie.';
					           |de = 'Fehlender Zugang zum Internet aufgrund von:
					           |- der Computer ist nicht mit dem Internet verbunden;
					           |- Störungen beim Internet-Service-Provider;
					           |- Verbindung zum Internet blockiert die Firewall, 
					           |das Antivirenprogramm oder andere Software.';
					           |ro = 'Lipsește accesul în rețeaua internet din motivul:
					           |- computerul nu este conectat la internet;
					           |- defecțiuni la providerul de internet;
					           |- conectarea la internet este blocată de firewall, 
					           |  programul antivirus sau alt soft.';
					           |tr = 'Aşağıdakilerden dolayı İnternet erişimi yoktur: - 
					           |bilgisayar İnternete bağlı değildir - 
					           | İnternet sağlayıcısıyla ilgili sorunlar - 
					           |
					           | İnternet bağlantısı, güvenlik duvarı, antivirüs programı veya diğer yazılımlar tarafından engellendi.'; 
					           |es_ES = 'No hay acceso en Internet a causa de:
					           |- el ordenador no está conectado a Internet;
					           |- los fallos del proveedor Internet;
					           |- la conexión a Internet bloqueo la pantalla entre red, 
					           |  el programa antivirus u otro software.'"));
				
			Else 
				
				Details.Add(StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Сервер %1 не доступен по причине:
					           |- неполадки у интернет-провайдера;
					           |- подключение к серверу блокирует межсетевой экран, 
					           |  антивирусная программа или другое программное обеспечение;
					           |- сервер отключен или на техническом обслуживании.'; 
					           |en = 'Server %1 is unavailable. Possible reasons: 
					           |-  Internet service provider issues.
					           |- A firewall, antivirus, or another software
					           |  is blocking the connection.
					           |- The server is turned off or under maintenance.'; 
					           |pl = 'Serwer %1 nie jest dostępny z powodu:
					           |- problemy u operatora Internetu;
					           |- podłączenie do serwisu blokuje zapora sieciowa, 
					           |  program antiwirusowy lub inne oprogramowanie;
					           |- serwer odłączony lub jest na konserwacji.';
					           |de = 'Der Server%1 ist nicht verfügbar, weil:
					           |- eine Fehlfunktion des Internet-Service-Providers;
					           |- die Verbindung zum Server die Firewall, 
					           | das Antivirenprogramm oder andere Software blockiert;
					           |- der Server deaktiviert ist oder sich in der Wartung befindet.';
					           |ro = 'Serverul %1 este inaccesibil din motivul:
					           |- defecțiuni la providerul de internet;
					           |- conectarea la internet este blocată de firewall, 
					           |  programul antivirus sau alt soft;
					           |- serverul este dezactivat sau se află la deservire tehnică.';
					           |tr = 'Sunucuya%1 şu nedenlerden dolayı erişilemiyor: 
					           |- İnternet sağlayıcısıyla ilgili bir sorun; 
					           |- Sunucuyla bağlantı, güvenlik duvarı, 
					           |antivirüs veya diğer yazılımlar tarafından engellendi; 
					           |- Sunucunun bağlantısı kesildi veya bakım halinde.'; 
					           |es_ES = 'El servidor %1 no está disponible a causa de:
					           |- los fallos del proveedor Internet;
					           |- la conexión a Internet bloqueo la pantalla entre red, 
					           |  el programa antivirus u otro software;
					           |- el servidor está desactivado o en el servicio técnico.'"),
					ResourceServerAddress));
				
				TraceLog = GetFilesFromInternetInternal.ServerRouteTraceLog(ResourceServerAddress);
				Log.Add("3) " + TraceLog);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	ErrorDescription = StrConcat(Details, Chars.LF);
	
	Log.Insert(0);
	Log.Insert(0, ErrorDescription);
	
	DiagnosticsLog = StrConcat(Log, Chars.LF);
	
	WriteLogEvent(
		NStr("ru = 'Диагностика соединения'; en = 'Connection diagnostics'; pl = 'Diagnostyka połączenia';de = 'Verbindungsdiagnose';ro = 'Diagnosticul conexiunii';tr = 'Bağlantı tanısı'; es_ES = 'Diagnóstica de conexión'", Common.DefaultLanguageCode()),
		EventLogLevel.Error,,, DiagnosticsLog);
	
	Result = New Structure;
	Result.Insert("ErrorDescription", ErrorDescription);
	Result.Insert("DiagnosticsLog", DiagnosticsLog);
	
	Return Result;
	
EndFunction

#EndRegion
