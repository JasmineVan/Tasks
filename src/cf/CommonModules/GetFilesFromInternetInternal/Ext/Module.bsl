///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

////////////////////////////////////////////////////////////////////////////////
// Configuration subsystems event handlers.

// See InfobaseUpdateSSL.OnAddUpdateHandlers. 
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Version    = "1.2.1.4";
	Handler.Procedure = "GetFilesFromInternetInternal.RefreshStoredProxySettings";
	
EndProcedure

// See CommonOverridable.OnAddClientParameters. 
Procedure OnAddClientParameters(Parameters) Export
	
	Parameters.Insert("ProxyServerSettings", GetFilesFromInternet.ProxySettingsAtClient());
	
EndProcedure

// See SafeModeManagerOverridable.OnEnableSecurityProfiles. 
Procedure OnEnableSecurityProfiles() Export
	
	// Reset proxy settings to default condition.
	SaveServerProxySettings(Undefined);
	
	WriteLogEvent(EventLogEvent(),
		EventLogLevel.Warning, Metadata.Constants.ProxyServerSetting,,
		NStr("ru = 'При включении профилей безопасности настройки прокси-сервера сброшены на системные.'; en = 'Since a security profile is enabled, the proxy server settings are reverted to the default ones.'; pl = 'Przy włączeniu profili bezpieczeństwa, ustawienia serwera pośredniczącego zostały zresetowane do ustawień domyślnych.';de = 'Beim Aktivieren von Sicherheitsprofilen wurden die Proxy-Server-Einstellungen auf die Standardwerte zurückgesetzt.';ro = 'La activarea profilelor de securitate setările serverului proxy sunt resetate cu cele de sistem.';tr = 'Güvenlik profillerini etkinleştirirken, proxy sunucu ayarları varsayılan değerlere sıfırlandı.'; es_ES = 'Al activar los perfiles de seguridad, las configuraciones del servidor proxy se han restablecido para los valores por defecto.'"));
	
EndProcedure

#EndRegion

#Region Private

#Region Proxy

// Saves proxy server setting parameters on the 1C:Enterprise server side.
//
Procedure SaveServerProxySettings(Val Settings) Export
	
	If NOT Users.IsFullUser(, True) Then
		Raise(NStr("ru = 'Недостаточно прав для выполнения операции'; en = 'Insufficient rights to perform the operation.'; pl = 'Nie masz wystarczających uprawnień do wykonania operacji';de = 'Unzureichende Rechte zum Ausführen der Operation';ro = 'Insufficient rights to perform the operation';tr = 'İşlemi gerçekleştirmek için yetersiz haklar'; es_ES = 'Insuficientes derechos para realizar la operación'"));
	EndIf;
	
	SetPrivilegedMode(True);
	Constants.ProxyServerSetting.Set(New ValueStorage(Settings));
	
EndProcedure

#EndRegion

#Region InfobaseUpdate

// Initializes new proxy server settings: "UseProxy"
// and "UseSystemSettings".
//
Procedure RefreshStoredProxySettings() Export
	
	IBUsersArray = InfoBaseUsers.GetUsers();
	
	For Each InfobaseUser In IBUsersArray Do
		
		ProxyServerSetting = Common.CommonSettingsStorageLoad(
			"ProxyServerSetting", "", , , InfobaseUser.Name);
		
		If TypeOf(ProxyServerSetting) = Type("Map") Then
			
			SaveUserSettings = False;
			If ProxyServerSetting.Get("UseProxy") = Undefined Then
				ProxyServerSetting.Insert("UseProxy", False);
				SaveUserSettings = True;
			EndIf;
			If ProxyServerSetting.Get("UseSystemSettings") = Undefined Then
				ProxyServerSetting.Insert("UseSystemSettings", False);
				SaveUserSettings = True;
			EndIf;
			If SaveUserSettings Then
				Common.CommonSettingsStorageSave(
					"ProxyServerSetting", "", ProxyServerSetting, , InfobaseUser.Name);
			EndIf;
			
		EndIf;
		
	EndDo;
	
	ProxyServerSetting = GetFilesFromInternet.ProxySettingsAtServer();
	
	If TypeOf(ProxyServerSetting) = Type("Map") Then
		
		SaveServerSettings = False;
		If ProxyServerSetting.Get("UseProxy") = Undefined Then
			ProxyServerSetting.Insert("UseProxy", False);
			SaveServerSettings = True;
		EndIf;
		If ProxyServerSetting.Get("UseSystemSettings") = Undefined Then
			ProxyServerSetting.Insert("UseSystemSettings", False);
			SaveServerSettings = True;
		EndIf;
		If SaveServerSettings Then
			SaveServerProxySettings(ProxyServerSetting);
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region DownloadFile

#If Not WebClient Then

// function meant for getting files from the Internet
//
// Parameters:
//   URL - String - file URL in the following format:
//   ReceivingSettings - Structure with properties.
//    * PathForSaving - String - path on the server (including file name) for saving the downloaded file.
//    * User - String - user that established the connection.
//    * Password - String - password of the user that established the connection.
//    * Port - Number - port used for connecting to the server.
//    * Timeout - Number - file getting timeout in seconds.
//    * SecureConnection - Boolean - in case of http download the flag shows that the connection 
//                                             must be established via https.
//    * PassiveConnection - Boolean - in case of ftp download the flag shows that the connection 
//                                             must be passive (or active).
//    * Headers - Map - see the details of the Headers parameter of the HTTPRequest object.
//    * UseOSAuthentication - Boolean - see the details of the UseOSAuthentication parameter of the HTTPConnection object.
//
// SavingSetting - Map - contains parameters to save the downloaded file keys:
//                 
//                 Storage - String - may contain
//                        "Server" - server,
//                        "TemporaryStorage" - temporary storage.
//                 Path - String (optional parameter) - path to folder at client or at server or 
//                        temporary storage address will be generated if not specified.
//                        
//
// Returns:
//   structure success - Boolean - success or failure of the operation string - String - in case of 
//   success either a string that contains file saving path or an address in the temporary storage; 
//   in case of failure an error message.
//                   
//                   
//
Function DownloadFile(Val URL, Val ReceivingParameters, Val SavingSetting, Val WriteError = True) Export
	
	ReceivingSettings = GetFilesFromInternetClientServer.FileGettingParameters();
	If ReceivingParameters <> Undefined Then
		FillPropertyValues(ReceivingSettings, ReceivingParameters);
	EndIf;
	
	If SavingSetting.Get("StorageLocation") <> "TemporaryStorage" Then
		SavingSetting.Insert("Path", ReceivingSettings.PathForSaving);
	EndIf;
	
	ProxyServerSetting = GetFilesFromInternet.ProxySettingsAtServer();
	
	Redirections = New Array;
	
	Return GetFileFromInternet(URL, SavingSetting, ReceivingSettings,
		ProxyServerSetting, WriteError, Redirections);
	
EndFunction

// function meant for getting files from the Internet
//
// Parameters:
//   URL - String - file URL in the following format: [Protocol://]<Server>/<Path to the file on the server>.
//
// ConnectionSetting - Map -
//		SecureConnection* - Boolean - the connection is secure.
//		PassiveConnection* - Boolean - the connection is secure.
//		User - String - user that established the connection.
//		Password - String - password of the user that established the connection.
//		Port - Number - port used for connecting to the server.
//		* - mutually exclusive keys.
//
// ProxySettings - Map:
//		UseProxy - indicates whether to use proxy server.
//		BypassProxyOnLocal - indicates whether to use proxy server for local addresses.
//		UseSystemSettings - indicates whether to use proxy server system settings.
//		Server - proxy server address.
//		Port - proxy server port.
//		User - username for authorization on proxy server.
//		Password - user password.
//		UseOSAuthentication - Boolean - a flag that indicates the use of authentication by means of the operating system.
//
// SavingSetting - Map - contains parameters to save the downloaded file.
//		Storage - String - may contain
//			"Server" - server,
//			"TemporaryStorage" - temporary storage.
//		Path - String (optional parameter) - path to folder at client or at server or temporary storage 
//			address will be generated if not specified.
//
// Returns:
//   structure success - Boolean - success or failure of the operation string - String - in case of 
//   success either a string that contains file saving path or an address in the temporary storage; 
//   in case of failure an error message.
//                   
//                   
//
Function GetFileFromInternet(Val URL, Val SavingSetting, Val ConnectionSetting,
	Val ProxySettings, Val WriteError, Redirections = Undefined)
	
	URIStructure = CommonClientServer.URIStructure(URL);
	
	Server        = URIStructure.Host;
	PathAtServer = URIStructure.PathAtServer;
	Protocol      = URIStructure.Schema;
	
	If IsBlankString(Protocol) Then 
		Protocol = "http";
	EndIf;
	
	SecureConnection = ConnectionSetting.SecureConnection;
	Username      = ConnectionSetting.User;
	UserPassword   = ConnectionSetting.Password;
	Port                 = ConnectionSetting.Port;
	Timeout              = ConnectionSetting.Timeout;
	
	If (Protocol = "https" Or Protocol = "ftps") AND SecureConnection = Undefined Then
		SecureConnection = True;
	EndIf;
	
	If SecureConnection = True Then
		SecureConnection = CommonClientServer.NewSecureConnection();
	ElsIf SecureConnection = False Then
		SecureConnection = Undefined;
		// Otherwise the SecureConnection parameter was specified explicitly.
	EndIf;
	
	If Port = Undefined Then
		Port = URIStructure.Port;
	EndIf;
	
	If ProxySettings = Undefined Then 
		Proxy = Undefined;
	Else 
		Proxy = NewInternetProxy(ProxySettings, Protocol);
	EndIf;
	
	If SavingSetting["Path"] <> Undefined Then
		PathForSaving = SavingSetting["Path"];
	Else
		PathForSaving = GetTempFileName(); // APK:441 Temporary file must be deleted by the calling code.
	EndIf;
	
	If Timeout = Undefined Then 
		Timeout = GetFilesFromInternetClientServer.AutomaticTimeoutDetermination();
	EndIf;
	
	FTPProtocolISUsed = (Protocol = "ftp" Or Protocol = "ftps");
	
	If FTPProtocolISUsed Then
		
		PassiveConnection                       = ConnectionSetting.PassiveConnection;
		SecureConnectionUsageLevel = ConnectionSetting.SecureConnectionUsageLevel;
		
		Try
			
			If Timeout = GetFilesFromInternetClientServer.AutomaticTimeoutDetermination() Then
				
				Connection = New FTPConnection(
					Server, 
					Port, 
					Username, 
					UserPassword,
					Proxy, 
					PassiveConnection, 
					7, 
					SecureConnection, 
					SecureConnectionUsageLevel);
				
				FileSize = FTPFileSize(Connection, PathAtServer);
				Timeout = TimeoutByFileSize(FileSize);
				
			EndIf;
			
			Connection = New FTPConnection(
				Server, 
				Port, 
				Username, 
				UserPassword,
				Proxy, 
				PassiveConnection, 
				Timeout, 
				SecureConnection, 
				SecureConnectionUsageLevel);
			
			Server = Connection.Host;
			Port   = Connection.Port;
			
			Connection.Get(PathAtServer, PathForSaving);
			
		Except
			
			DiagnosticsResult = GetFilesFromInternet.ConnectionDiagnostics(URL);
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось получить файл %1 с сервера %2:%3
				           |по причине:
				           |%4
				           |Результат диагностики:
				           |%5'; 
				           |en = 'Cannot get file %1 from server %2:%3.
				           |Reason:
				           |%4
				           |Diagnostics result:
				           |%5'; 
				           |pl = 'Nie można pobrać plik %1 z serwera %2:%3
				           | w wyniku:
				           |%4
				           |Wynik diagnostyki:
				           |%5';
				           |de = 'Die Datei konnte nicht %1 vom Server heruntergeladen werden %2:%3
				           |wegen:
				           |%4
				           |Diagnoseergebnis:
				           |%5';
				           |ro = 'Eșec la obținerea fișierului %1 de pe serverul %2:%3
				           |din motivul:
				           |%4
				           |Rezultatul diagnosticului:
				           |%5';
				           |tr = 'Dosyayı %1 sunucudan %2: %3
				           |aşağıdaki nedenle alınamadı:
				           |%4
				           |Tanılama sonuçları:
				           |%5'; 
				           |es_ES = 'No se ha podido recibir el archivo %1 del servidor %2: %3
				           |a causa de:
				           |%4
				           |Resultado de diagnóstico:
				           |%5'"),
				URL, Server, Format(Port, "NG="),
				BriefErrorDescription(ErrorInfo()),
				DiagnosticsResult.ErrorDescription);
				
			If WriteError Then
				ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = '%1
					           |
					           |Трассировка:
					           |ЗащищенноеСоединение: %2
					           |Таймаут: %3'; 
					           |en = '%1
					           |
					           |Trace parameters:
					           |Secure connection: %2
					           |Timeout: %3'; 
					           |pl = '%1
					           |
					           |Śledzenie:
					           |BezpiecznePołączenie: %2
					           |Limit Czasu: %3';
					           |de = '%1
					           |
					           |Ablaufverfolgung:
					           |GeschützteVerbindung: %2
					           |Timeout: %3';
					           |ro = '%1
					           |
					           |Trasare:
					           |ConexiuneSecurizată: %2
					           |Timeout: %3';
					           |tr = '%1
					           |
					           |İzleme:
					           |KorunmuşBağlantı: %2
					           |Timeout: %3'; 
					           |es_ES = '%1
					           |
					           |Trazabilidad:
					           |SecureConnection: %2
					           |Tiempo muerto: %3'"),
					ErrorText,
					Format(Connection.IsSecure, NStr("ru = 'БЛ=Нет; БИ=Да'; en = 'BF=No; BT=Yes'; pl = 'BL=Nie; BI=Tak';de = 'BL=Nein; BI=Ja';ro = 'BF=Nu; BT=Da';tr = 'BF=Hayır; BT=Evet'; es_ES = 'BF=No; BT=Sí'")),
					Format(Connection.Timeout, "NG=0"));
					
				WriteErrorToEventLog(ErrorMessage);
			EndIf;
			
			Return FileGetResult(False, ErrorText);
			
		EndTry;
		
	Else // HTTP protocol is used.
		
		Headers                    = ConnectionSetting.Headers;
		UseOSAuthentication = ConnectionSetting.UseOSAuthentication;
		
		Try
			
			If Timeout = GetFilesFromInternetClientServer.AutomaticTimeoutDetermination() Then
				
				Connection = New HTTPConnection(
					Server, 
					Port, 
					Username, 
					UserPassword,
					Proxy, 
					7, 
					SecureConnection, 
					UseOSAuthentication);
				
				FileSize = HTTPFileSize(Connection, PathAtServer, Headers);
				Timeout = TimeoutByFileSize(FileSize);
				
			EndIf;
			
			Connection = New HTTPConnection(
				Server, 
				Port, 
				Username, 
				UserPassword,
				Proxy, 
				Timeout, 
				SecureConnection, 
				UseOSAuthentication);
			
			Server = Connection.Host;
			Port   = Connection.Port;
			
			HTTPRequest = New HTTPRequest(PathAtServer, Headers);
			HTTPRequest.Headers.Insert("Accept-Charset", "UTF-8");
			HTTPRequest.Headers.Insert("X-1C-Request-UID", String(New UUID));
			HTTPResponse = Connection.Get(HTTPRequest, PathForSaving);
			
		Except
			
			DiagnosticsResult = GetFilesFromInternet.ConnectionDiagnostics(URL);
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось установить HTTP-соединение с сервером %1:%2
				           |по причине:
				           |%3
				           |
				           |Результат диагностики:
				           |%4'; 
				           |en = 'Cannot establish HTTP connection to server %1:%2.
				           |Reason:
				           |%3
				           |
				           |Diagnostics result:
				           |%4'; 
				           |pl = 'Nie udało się powiązać połączenie HTTP z serwerem %1:%2
				           |z powodu:
				           |%3
				           |
				           |Rezultat diagnostyki:
				           |%4';
				           |de = 'Es konnte keine HTTP-Verbindung zum Server aufgebaut werden %1:%2
				           |aufgrund von:
				           |%3
				           |
				           |Diagnoseergebnis:
				           |%4';
				           |ro = 'Eșec la instalarea conexiunii HTTP cu serverul %1:%2
				           |din motivul:
				           |%3
				           |
				           |Rezultatul diagnosticului:
				           |%4';
				           |tr = 'Sunucu ile HTTP-bağlantı yapılamadı %1:%2
				           |nedenle:
				           |%3
				           |
				           |Tanılama sonuçları:
				           |%4'; 
				           |es_ES = 'No se ha podido instalar la conexión HTTP con el servidor %1:%2
				           |a causa de:
				           |%3
				           |
				           |Resultado de diagnóstico:
				           |%4'"),
				Server, Format(Port, "NG="),
				BriefErrorDescription(ErrorInfo()),
				DiagnosticsResult.ErrorDescription);
			
			AddRedirectionsPresentation(Redirections, ErrorText);
			
			If WriteError Then
				WriteErrorToEventLog(ErrorText);
			EndIf;
				
			Return FileGetResult(False, ErrorText);
			
		EndTry;
		
		Try
			
			If HTTPResponse.StatusCode = 301 // 301 Moved Permanently
				Or HTTPResponse.StatusCode = 302 // 302 Found, 302 Moved Temporarily
				Or HTTPResponse.StatusCode = 303 // 303 See Other by GET
				Or HTTPResponse.StatusCode = 307 // 307 Temporary Redirect
				Or HTTPResponse.StatusCode = 308 Then // 308 Permanent Redirect
				
				If Redirections.Count() > 7 Then
					Raise 
						NStr("ru = 'Превышено количество перенаправлений.'; en = 'Redirections limit exceeded.'; pl = 'Przekroczono liczbę przekierowań.';de = 'Anzahl der Umleitungen überschritten.';ro = 'Este depășit numărul de redirecționări.';tr = 'Tekrar yönlendirme sayısı arttı.'; es_ES = 'Se ha superado la cantidad de desviación.'");
				Else 
					
					NewURL = HTTPResponse.Headers["Location"];
					
					If NewURL = Undefined Then 
						Raise 
							NStr("ru = 'Некорректное перенаправление, отсутствует HTTP-заголовок ответа ""Location"".'; en = 'Invalid redirection: no ""Location"" header in the HTTP response.'; pl = 'Niepoprawne przekierowanie, brak nagłówka odpowiedzi HTTP ""Location"".';de = 'Falsche Umleitung, kein ""Location"" HTTP-Antwort-Header.';ro = 'Redirecționare incorectă, lipsește titlul HTTP al răspunsului ""Location"".';tr = 'Yanlış yönlendirme, ""Konum"" yanıtının HTTP üstbilgisi eksik.'; es_ES = 'Desviación incorrecta no hay título HTTP de la respuesta ""Location"".'");
					EndIf;
					
					NewURL = TrimAll(NewURL);
					
					If IsBlankString(NewURL) Then
						Raise 
							NStr("ru = 'Некорректное перенаправление, пустой HTTP-заголовок ответа ""Location"".'; en = 'Invalid redirection: blank ""Location"" header in the HTTP response.'; pl = 'Niepoprawne przekierowanie, pusty nagłówek odpowiedzi HTTP ""Location"".';de = 'Falsche Umleitung, leerer ""Location"" HTTP-Antwort-Header.';ro = 'Redirecționare incorectă, titlul HTTP gol al răspunsului ""Location"".';tr = 'Yanlış yönlendirme, ""Konum"" yanıtının HTTP üstbilgisi boş.'; es_ES = 'Desviación incorrecta título HTTP vacío de la respuesta ""Location"".'");
					EndIf;
					
					If Redirections.Find(NewURL) <> Undefined Then
						Raise StringFunctionsClientServer.SubstituteParametersToString(
							NStr("ru = 'Циклическое перенаправление.
							           |Попытка перейти на %1 уже выполнялась ранее.'; 
							           |en = 'Circular redirect.
							           |Redirect to %1 was attempted earlier.'; 
							           |pl = 'Cykliczne przekierowanie.
							           |Próba przejścia na %1 już uruchomione wcześniej.';
							           |de = 'Zyklische Umleitung.
							           |Ein Versuch, auf %1umzusteigen, wurde bereits unternommen.';
							           |ro = 'Redirecționare ciclică.
							           |Tentativa de trecere la %1 s-a executat deja anterior.';
							           |tr = 'Döngüsel yönlendirme. 
							           |Daha önce zaten devam etmeye %1çalışıyor.'; 
							           |es_ES = 'Desviación cíclica.
							           |Prueba de pasar a %1 se ha realizado anteriormente.'"),
							NewURL);
					EndIf;
					
					Redirections.Add(URL);
					
					If Not StrStartsWith(NewURL, "http") Then
						// <scheme>://<host>:<port>/<path>
						NewURL = StringFunctionsClientServer.SubstituteParametersToString(
							"%1://%2:%3/%4", Protocol, Server, Format(Port, "NG="), NewURL);
					EndIf;
					
					Return GetFileFromInternet(NewURL, SavingSetting, ConnectionSetting,
						ProxySettings, WriteError, Redirections);
					
				EndIf;
				
			EndIf;
			
			If HTTPResponse.StatusCode < 200 Or HTTPResponse.StatusCode >= 300 Then
				
				If HTTPResponse.StatusCode = 304 Then
					
					If (HTTPRequest.Headers["If-Modified-Since"] <> Undefined
						Or HTTPRequest.Headers["If-None-Match"] <> Undefined) Then
						WriteError = False;
					EndIf;
					
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Сервер убежден, что с вашего последнего запроса его ответ не изменился:
						           |%1'; 
						           |en = 'The server response has not changed since your last request:
						           |%1'; 
						           |pl = 'Serwer odpowiedział, że jego odpowiedź nie zmieniła się od czasu ostatniego żądania:
						           |%1';
						           |de = 'Der Server hat geantwortet, dass sich seine Antwort seit Ihrer letzten Anfrage nicht geändert hat:
						           |%1';
						           |ro = 'Server-ul a transmis că răspunsul nu s-a schimbat de la ultima solicitare:
						           |%1';
						           |tr = 'Sunucu, son sorgunuzdan cevabının değişmediğine düşünüyor: 
						           |%1'; 
						           |es_ES = 'El servidor está seguro de que desde su última consulta de usted su respuesta no se ha cambiado:
						           |%1'"),
						HTTPConnectionCodeDecryption(HTTPResponse.StatusCode));
					
					AddServerResponseBody(PathForSaving, ErrorText);
					
					Raise ErrorText;
					
				ElsIf HTTPResponse.StatusCode < 200
					Or HTTPResponse.StatusCode >= 300 AND HTTPResponse.StatusCode < 400 Then
					
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Неподдерживаемый ответ сервера:
						           |%1'; 
						           |en = 'Unsupported server response:
						           |%1'; 
						           |pl = 'Nieobsługiwana odpowiedź serwera:
						           |%1';
						           |de = 'Nicht unterstützte Serverantwort:
						           |%1';
						           |ro = 'Răspuns nesusținut al serverului:
						           |%1';
						           |tr = 'Sunucunun desteklenmeyen cevabı:
						           |%1'; 
						           |es_ES = 'Respuesta del servidor no admitida:
						           |%1'"),
						HTTPConnectionCodeDecryption(HTTPResponse.StatusCode));
					
					AddServerResponseBody(PathForSaving, ErrorText);
					
					Raise ErrorText;
					
				ElsIf HTTPResponse.StatusCode >= 400 AND HTTPResponse.StatusCode < 500 Then 
					
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Ошибка при выполнении запроса:
						           |%1'; 
						           |en = 'Request error:
						           |%1'; 
						           |pl = 'Błąd podczas wykonywania kwerendy:
						           |%1';
						           |de = 'Fehler beim Ausführen der Anfrage:
						           |%1';
						           |ro = 'Eroare la executarea interogării:
						           |%1';
						           |tr = 'Sorgu yürütülürken hata oluştu:
						           |%1'; 
						           |es_ES = 'Error al realizar la consulta:
						           |%1'"),
						HTTPConnectionCodeDecryption(HTTPResponse.StatusCode));
					
					AddServerResponseBody(PathForSaving, ErrorText);
					
					Raise ErrorText;
					
				Else 
					
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Ошибка сервера при обработке запроса к ресурсу:
						           |%1'; 
						           |en = 'A server error occurred while processing a request:
						           |%1'; 
						           |pl = 'Błąd serwera podczas przetwarzania żądania zasobu: 
						           |%1';
						           |de = 'Serverfehler bei der Verarbeitung von Ressourcenanfragen:
						           |%1';
						           |ro = 'Eroarea serverului la procesarea interogării la resursa:
						           |%1';
						           |tr = 'Kaynak isteği işlenirken sunucu hatası:
						           |%1'; 
						           |es_ES = 'Error del servidor al procesar la consulta del recurso: 
						           |%1'"),
						HTTPConnectionCodeDecryption(HTTPResponse.StatusCode));
					
					AddServerResponseBody(PathForSaving, ErrorText);
					
					Raise ErrorText;
					
				EndIf;
				
			EndIf;
			
		Except
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось получить файл %1 с сервера %2:%3
				           |по причине:
				           |%4'; 
				           |en = 'Cannot get file %1 from server %2.%3
				           |Reason:
				           |%4'; 
				           |pl = 'Nie udało się pobrać pliku %1 z serwera %2:%3
				           | z powodu:
				           |%4';
				           |de = 'Die Datei %1 konnte aus dem Server nicht abgerufen werden %2:%3
				           |Aus folgendem Grund:
				           |%4';
				           |ro = 'Eșec la obținerea fișierului %1 de pe serverul %2:%3
				           |din motivul:
				           |%4';
				           |tr = 'Dosyayı %1 sunucudan %2: %3
				           |aşağıdaki nedenle alınamadı:
				           |%4'; 
				           |es_ES = 'No se ha podido recibir el archivo %1 del servidor %2: %3
				           |a causa de:
				           |%4'"),
				URL, Server, Format(Port, "NG="),
				BriefErrorDescription(ErrorInfo()));
			
			AddRedirectionsPresentation(Redirections, ErrorText);
			
			If WriteError Then
				ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = '%1
					           |
					           |Трассировка:
					           |ЗащищенноеСоединение: %2
					           |Таймаут: %3
					           |ИспользоватьАутентификациюОС: %4'; 
					           |en = '%1
					           |
					           |Trace parameters:
					           |Secure connection: %2
					           |Timeout: %3
					           |OS authentication: %4'; 
					           |pl = '%1
					           |
					           |Śledzenie:
					           | ZabezpieczonePołączenie: %2
					           |Limit czasu: %3
					           |UżyjUwierzytelnianiaOS: %4';
					           |de = '%1
					           |
					           |Ablaufverfolgung:
					           |GeschützteVerbindung: %2
					           |Timeout: %3
					           |AuthentifizierungBetriebssystemVerwenden: %4';
					           |ro = '%1
					           |
					           |Trasare:
					           |ConexiuneSecurizată: %2
					           |Timeout: %3
					           |UtilizareAutentificareaSO: %4';
					           |tr = '%1
					           |
					           |İzleme:
					           |KorunmuşBağlantı: %2
					           |Timeout: %3OSDoğrulamayıKullan: 
					           |%4'; 
					           |es_ES = '%1
					           |
					           |Trazabilidad:
					           |SecureConnection: %2
					           |Tiempo muerto: %3 
					           |UseOSAuthentication: %4'"),
					ErrorText,
					Format(Connection.IsSecure, NStr("ru = 'БЛ=Нет; БИ=Да'; en = 'BF=No; BT=Yes'; pl = 'BL=Nie; BI=Tak';de = 'BL=Nein; BI=Ja';ro = 'BF=Nu; BT=Da';tr = 'BF=Hayır; BT=Evet'; es_ES = 'BF=No; BT=Sí'")),
					Format(Connection.Timeout, "NG=0"),
					Format(Connection.UseOSAuthentication, NStr("ru = 'БЛ=Нет; БИ=Да'; en = 'BF=No; BT=Yes'; pl = 'BL=Nie; BI=Tak';de = 'BL=Nein; BI=Ja';ro = 'BF=Nu; BT=Da';tr = 'BF=Hayır; BT=Evet'; es_ES = 'BF=No; BT=Sí'")));
				
				AddHTTPHeaders(HTTPRequest, ErrorMessage);
				AddHTTPHeaders(HTTPResponse, ErrorMessage);
				
				WriteErrorToEventLog(ErrorMessage);
			EndIf;
			
			Return FileGetResult(False, ErrorText, HTTPResponse);
			
		EndTry;
		
	EndIf;
	
	// If the file is saved in accordance with the setting.
	If SavingSetting["StorageLocation"] = "TemporaryStorage" Then
		UniqueKey = New UUID;
		Address = PutToTempStorage (New BinaryData(PathForSaving), UniqueKey);
		Return FileGetResult(True, Address, HTTPResponse);
	ElsIf SavingSetting["StorageLocation"] = "Server" Then
		Return FileGetResult(True, PathForSaving, HTTPResponse);
	Else
		Raise NStr("ru = 'Не указано место для сохранения файла.'; en = 'The file storage location is not specified.'; pl = 'Brak miejsca do zapisania pliku.';de = 'Es gibt keinen Platz, um die Datei zu speichern.';ro = 'Locul pentru salvarea fișierului nu este indicat.';tr = 'Dosyanın kaydedileceği yer belirtilmedi.'; es_ES = 'No se ha indicado el lugar para guardar el archivo.'");
	EndIf;
	
EndFunction

// function meant for completing the structure according to parameters
//
// Parameters:
//   OperationSuccess - Boolean - success or failure of the operation.
//   MessagePath - String -
//
// Returns - structure:
//          field success - Boolean field path - String.
//          
//
Function FileGetResult(Val Status, Val MessagePath, HTTPResponse = Undefined)
	
	Result = New Structure("Status", Status);
	
	If Status Then
		Result.Insert("Path", MessagePath);
	Else
		Result.Insert("ErrorMessage", MessagePath);
		Result.Insert("StatusCode", 1);
	EndIf;
	
	If HTTPResponse <> Undefined Then
		ResponseHeadings = HTTPResponse.Headers;
		If ResponseHeadings <> Undefined Then
			Result.Insert("Headers", ResponseHeadings);
		EndIf;
		
		Result.Insert("StatusCode", HTTPResponse.StatusCode);
		
	EndIf;
	
	Return Result;
	
EndFunction

Function HTTPFileSize(HTTPConnection, Val PathAtServer, Val Headers = Undefined)
	
	HTTPRequest = New HTTPRequest(PathAtServer, Headers);
	Try
		ReceivedHeaders = HTTPConnection.Head(HTTPRequest);// HEAD
	Except
		Return 0;
	EndTry;
	SizeInString = ReceivedHeaders.Headers["Content-Length"];
	
	NumberType = New TypeDescription("Number");
	FileSize = NumberType.AdjustValue(SizeInString);
	
	Return FileSize;
	
EndFunction

Function FTPFileSize(FTPConnection, Val PathAtServer)
	
	FileSize = 0;
	
	Try
		FilesFound = FTPConnection.FindFiles(PathAtServer);
		If FilesFound.Count() > 0 Then
			FileSize = FilesFound[0].Size();
		EndIf;
	Except
		FileSize = 0;
	EndTry;
	
	Return FileSize;
	
EndFunction

Function TimeoutByFileSize(Size)
	
	BytesInMegabyte = 1048576;
	
	If Size > BytesInMegabyte Then
		SecondsCount = Round(Size / BytesInMegabyte * 128);
		Return ?(SecondsCount > 43200, 43200, SecondsCount);
	EndIf;
	
	Return 128;
	
EndFunction

Function HTTPConnectionCodeDecryption(StatusCode)
	
	If StatusCode = 304 Then // Not Modified
		Details = NStr("ru = 'Нет необходимости повторно передавать запрошенные ресурсы.'; en = 'There is no need to retransmit the requested resources.'; pl = 'Nie trzeba ponownie przesyłać żądanych zasobów.';de = 'Es ist nicht erforderlich, die angeforderten Ressourcen erneut einzureichen.';ro = 'Necesitatea de transmitere repetată a resurselor interogate lipsește.';tr = 'Talep edilen kaynaklar tekrar aktarılmaz.'; es_ES = 'No hay necesidad de volver a transmitir los recursos solicitados.'");
	ElsIf StatusCode = 400 Then // Bad Request
		Details = NStr("ru = 'Запрос не может быть исполнен.'; en = 'Cannot process the request.'; pl = 'Żądanie nie może zostać wykonane.';de = 'Die Anforderung kann nicht ausgeführt werden.';ro = 'Interogarea nu poate fi executată.';tr = 'Talep yerine getirilemez.'; es_ES = 'La consulta no ha sido realizada.'");
	ElsIf StatusCode = 401 Then // Unauthorized
		Details = NStr("ru = 'Попытка авторизации на сервере была отклонена.'; en = 'The server denied authorization.'; pl = 'Próba autoryzacji na serwerze została odrzucona.';de = 'Der Versuch, sich auf dem Server zu autorisieren, wurde abgelehnt.';ro = 'Tentativa de autorizare pe server a fost respinsă.';tr = 'Sunucudaki doğrulama girişimi reddedildi.'; es_ES = 'Prueba de autorizar en el servidor ha sido declinada.'");
	ElsIf StatusCode = 402 Then // Payment Required
		Details = NStr("ru = 'Требуется оплата.'; en = 'Payment is required.'; pl = 'Wymagana płatność.';de = 'Zahlung erforderlich.';ro = 'Este necesară achitarea.';tr = 'Ödeme gerekli.'; es_ES = 'Se requiere pagar.'");
	ElsIf StatusCode = 403 Then // Forbidden
		Details = NStr("ru = 'К запрашиваемому ресурсу нет доступа.'; en = 'No access to the requested resource.'; pl = 'Nie ma dostępu do żądanego zasobu.';de = 'Es besteht kein Zugriff auf die angeforderte Ressource.';ro = 'Lipsește accesul la resursa interogată.';tr = 'Sorgulanan kaynak erişilemez.'; es_ES = 'No hay acceso al recurso solicitado.'");
	ElsIf StatusCode = 404 Then // Not Found
		Details = NStr("ru = 'Запрашиваемый ресурс не найден на сервере.'; en = 'The resource is not found on the server.'; pl = 'Żądany zasób nie został znaleziony na serwerze.';de = 'Die angeforderte Ressource wird auf dem Server nicht gefunden.';ro = 'Resursa interogată nu a fost găsită pe server.';tr = 'Sorgulanan kaynak sunucuda bulunamadı.'; es_ES = 'El recurso solicitado no se ha encontrado en el servidor.'");
	ElsIf StatusCode = 405 Then // Method Not Allowed
		Details = NStr("ru = 'Метод запроса не поддерживается сервером.'; en = 'The server does not support the request method.'; pl = 'Metoda żądania nie jest obsługiwana przez serwer.';de = 'Die Anforderungsmethode wird vom Server nicht unterstützt.';ro = 'Metoda de interogare nu este susținută de server.';tr = 'Sorgu yöntemi sunucu tarafından desteklenmez.'; es_ES = 'E método de la consulta no se admite por el servidor.'");
	ElsIf StatusCode = 406 Then // Not Acceptable
		Details = NStr("ru = 'Запрошенный формат данных не поддерживается сервером.'; en = 'The server does not support the requested data format.'; pl = 'Żądany format danych nie jest obsługiwany przez serwer.';de = 'Запрошенный формат данных не поддерживается сервером.';ro = 'Formatul de date interogat nu este susținut de server.';tr = 'Sorgulanan veri formatı sunucu tarafından desteklenmez.'; es_ES = 'El formato solicitado de datos no se admite por el servidor.'");
	ElsIf StatusCode = 407 Then // Proxy Authentication Required
		Details = NStr("ru = 'Ошибка аутентификации на прокси-сервере'; en = 'Proxy server authentication error.'; pl = 'Błąd uwierzytelniania na serwerze proxy';de = 'Authentifizierungsfehler auf dem Proxy-Server';ro = 'Eroare de autentificare pe proxy server';tr = 'Proxy sunucu doğrulama hatası'; es_ES = 'Error de autenticación en el servidor proxy'");
	ElsIf StatusCode = 408 Then // Request Timeout
		Details = NStr("ru = 'Время ожидания сервером передачи от клиента истекло.'; en = 'Request timeout.'; pl = 'Limit czasu transferu serwera z klienta wygasł.';de = 'Serverübertragungszeitlimit vom Client abgelaufen.';ro = 'A expirat timpul de așteptare de către server a trimiterii de la client.';tr = 'İstemciden aktarım sunucusu zaman aşımına uğradı.'; es_ES = 'El tiempo de espera del servidor de la transmisión se ha expirado.'");
	ElsIf StatusCode = 409 Then // Conflict
		Details = NStr("ru = 'Запрос не может быть выполнен из-за конфликтного обращения к ресурсу.'; en = 'Cannot execute the request due to an access conflict.'; pl = 'Żądanie nie mogło zostać wykonane z powodu sprzecznego wywołania zasobu.';de = 'Die Anforderung konnte aufgrund eines widersprüchlichen Aufrufs der Ressource nicht ausgeführt werden.';ro = 'Interogarea nu poate fi executată din cauza adresării de conflict la resursă.';tr = 'Sorgu, kaynak çakışması nedeniyle gerçekleştirilemez.'; es_ES = 'La consulta no puede ser realizada a causa de la llamada de conflicto al recurso.'");
	ElsIf StatusCode = 410 Then // Gone
		Details = NStr("ru = 'Ресурс на сервере был перемешен.'; en = 'The resource was moved.'; pl = 'Zasób na serwerze został przeniesiony.';de = 'Die Ressource auf dem Server wurde vertauscht.';ro = 'Resursa pe server a fost transferată.';tr = 'Sunucudaki kaynak taşındı.'; es_ES = 'El recurso en el servidor ha sido trasladado.'");
	ElsIf StatusCode = 411 Then // Length Required
		Details = NStr("ru = 'Сервер требует указание ""Content-length."" в заголовке запроса.'; en = 'The ""Content-length"" request header is not specified.'; pl = 'Serwer wymaga wskazania ""Content-length."" w nagłówku żądania.';de = 'Der Server benötigt die Angabe ""Content-length."" im Anforderungs-Header.';ro = 'Serverul cere indicarea ""Content-length."" în titlul interogării.';tr = 'Sunucu, sorgu başlığında ""İçerik uzunluğu"" belirtilmesini gerektirir.'; es_ES = 'El servidor requiere indicar ""Content-length."" en el título de la consulta.'");
	ElsIf StatusCode = 412 Then // Precondition Failed
		Details = NStr("ru = 'Запрос не применим к ресурсу'; en = 'The request is not applicable to the resource.'; pl = 'Żądanie nie dotyczy zasobu';de = 'Die Anforderung gilt nicht für die Ressource';ro = 'Interogarea nu poate fi aplicată față de resursă';tr = 'Sorgu kaynağa uygulanmaz'; es_ES = 'La consulta no se aplica al recurso'");
	ElsIf StatusCode = 413 Then // Request Entity Too Large
		Details = NStr("ru = 'Сервер отказывается обработать, слишком большой объем передаваемых данных.'; en = 'The server cannot process the request because the data volume is too large.'; pl = 'Serwer odmawia przetwarzania zbyt dużej ilości danych.';de = 'Der Server verweigert die Serviceleistung der Anfrage, weil das übergebene Datenvolumen zu groß ist.';ro = 'Serverul refuză să proceseze volumul prea mare a datelor transmise.';tr = 'Sunucu işlemeyi reddediyor, aktarılan verilerin hacmi fazladır.'; es_ES = 'El servidor rechaza procesar el tamaño demasiado grande de los datos trasmitidos.'");
	ElsIf StatusCode = 414 Then // Request-URL Too Long
		Details = NStr("ru = 'Сервер отказывается обработать, слишком длинный URL.'; en = 'The cannot process the request because the URL is too long.'; pl = 'Serwer odmawia przetworzenia, adres URL jest za długi.';de = 'Der Server verweigert die Verarbeitung, die URL ist zu lang.';ro = 'Serverul refuză să proceseze, URL prea lung.';tr = 'Sunucu işlemeyi reddediyor, URL aşırı uzun.'; es_ES = 'El servidor rechaza procesar URL demasiado largo.'");
	ElsIf StatusCode = 415 Then // Unsupported Media-Type
		Details = NStr("ru = 'Сервер заметил, что часть запроса была сделана в неподдерживаемом формат'; en = 'A part of the request has unsupported format.'; pl = 'Serwer zauważył, że część żądania została wykonana w nieobsługiwanym formacie';de = 'Der Server hat festgestellt, dass ein Teil der Anforderung in einem nicht unterstützten Format erfolgt ist';ro = 'Serverul a observat că o parte a interogării este făcută în format nesusținut';tr = 'Sunucu, sorgunun bir kısmının desteklenmeyen bir biçimde yapıldığını fark etti'; es_ES = 'El servidor ha notado que la parte de la consulta ha sido realizada en el formato no admitido'");
	ElsIf StatusCode = 416 Then // Requested Range Not Satisfiable
		Details = NStr("ru = 'Часть запрашиваемого ресурса не может быть предоставлена'; en = 'A part of the requested resource cannot be provided.'; pl = 'Nie można dostarczyć części żądanego zasobu';de = 'Ein Teil der angeforderten Ressource kann nicht bereitgestellt werden';ro = 'O parte a resursei interogate nu poate fi oferită';tr = 'İstenen kaynağın bir kısmı sağlanamaz'; es_ES = 'Una parte del recurso solicitado no puede ser presentada'");
	ElsIf StatusCode = 417 Then // Expectation Failed
		Details = NStr("ru = 'Сервер не может предоставить ответ на указанный запрос.'; en = 'The server cannot provide a response to the specified request.'; pl = 'Serwer nie może dostarczyć odpowiedzi na określone żądanie.';de = 'Der Server kann auf diese Anforderung keine Antwort geben.';ro = 'Serverul nu poate oferi răspuns la interogarea indicată.';tr = 'Sunucu, belirtilen sorgu yanıtını sağlayamaz.'; es_ES = 'El servidor no puede presentar la respuesta de la consulta indicada.'");
	ElsIf StatusCode = 429 Then // Too Many Requests
		Details = NStr("ru = 'Слишком много запросов за короткое время.'; en = 'Too many requests in a short amount of time.'; pl = 'Zbyt wiele próśb w krótkim czasie.';de = 'Zu viele Anforderungen in kurzer Zeit.';ro = 'Prea multe interogări într-unt timp scurt.';tr = 'Kısa sürede çok fazla sorgu.'; es_ES = 'Demasiadas consultas en poco tiempo.'");
	ElsIf StatusCode = 500 Then // Internal Server Error
		Details = NStr("ru = 'Внутренняя ошибка сервера.'; en = 'Internal server error.'; pl = 'Wewnętrzny błąd serwera.';de = 'Interner Serverfehler.';ro = 'Eroare internă a serverului.';tr = 'Sunucu dahili hatası.'; es_ES = 'Error interno del servidor.'");
	ElsIf StatusCode = 501 Then // Not Implemented
		Details = NStr("ru = 'Сервер не поддерживает метод запроса.'; en = 'The server does not support the request method.'; pl = 'Serwer nie obsługuje metody żądania.';de = 'Der Server unterstützt die Anforderungsmethode nicht.';ro = 'Serverul nu susține metoda de interogare.';tr = 'Sunucu sorgu yöntemini desteklemiyor.'; es_ES = 'El servidor no admite el método de la consulta.'");
	ElsIf StatusCode = 502 Then // Bad Gateway
		Details = NStr("ru = 'Сервер, выступая в роли шлюза или прокси-сервера, 
		                         |получил недействительное ответное сообщение от вышестоящего сервера.'; 
		                         |en = 'The server received an invalid response from the upstream server
		                         |while acting as a gateway or proxy server.'; 
		                         |pl = 'Serwer, działający jako brama lub serwer proxy, 
		                         |odebrał komunikat o nieprawidłowej odpowiedzi z serwera nadrzędnego.';
		                         |de = 'Der Server, der als Gateway- oder Proxy-Server fungiert, 
		                         |erhielt eine ungültige Antwortnachricht von einem übergeordneten Server.';
		                         |ro = 'Serverul în rol portal sau server proxy,
		                         |a primit un mesaj de răspuns nevalid de la serverul din amonte.';
		                         |tr = 'Ağ geçidi veya proxy rolü konuşan sunucu, 
		                         |üst düzey bir sunucudan geçersiz bir yanıt iletisi aldı.'; 
		                         |es_ES = 'El servidor que es puerta o servidor proxy 
		                         |ha recibido el mensaje de respuesta no válido del servidor superior.'");
	ElsIf StatusCode = 503 Then // Server Unavailable
		Details = NStr("ru = 'Сервер временно не доступен.'; en = 'The server is temporarily unavailable.'; pl = 'Serwer jest chwilowo niedostępny.';de = 'Der Server ist vorübergehend nicht verfügbar.';ro = 'Serverul temporar este inaccesibil.';tr = 'Sunucu geçici olarak kullanım dışında.'; es_ES = 'El servidor no está disponible temporalmente.'");
	ElsIf StatusCode = 504 Then // Gateway Timeout
		Details = NStr("ru = 'Сервер в роли шлюза или прокси-сервера 
		                         |не дождался ответа от вышестоящего сервера для завершения текущего запроса.'; 
		                         |en = 'The server did not receive a timely response from the upstream server
		                         |while acting as a gateway or proxy server.'; 
		                         |pl = 'Serwer bramki lub serwer proxy 
		                         |nie czekał na odpowiedź z serwera nadrzędnego, aby ukończyć bieżące żądanie.';
		                         |de = 'Der Server als Gateway- oder Proxy-Server 
		                         |hat nicht auf eine Antwort eines übergeordneten Servers gewartet, um die aktuelle Anfrage abzuschließen.';
		                         |ro = 'Serverul în rol portal sau server proxy 
		                         |nu a primit un mesaj de răspuns de la serverul din amonte pentru finalizarea interogării curente.';
		                         |tr = 'Ağ geçidi veya proxy rolündeki sunucu, 
		                         |geçerli sorguyu tamamlamak için bir üst sunucudan yanıt beklemedi.'; 
		                         |es_ES = 'El servidor es puerta o servidor proxy 
		                         |no ha esperado la respuesta del servidor superior para terminar la consulta actual.'");
	ElsIf StatusCode = 505 Then // HTTP Version Not Supported
		Details = NStr("ru = 'Сервер не поддерживает указанную в запросе версию протокола HTTP'; en = 'The server does not support HTTP version specified in the request.'; pl = 'Serwer nie obsługuje wersji protokołu HTTP określonej w żądaniu.';de = 'Der Server unterstützt nicht die in der Anforderung angegebene Version des HTTP-Protokolls';ro = 'Serverul nu susține versiunea protocolului HTTP indicată în interogare';tr = 'Sunucu HTTP protokolünün sorguda belirtilen sürümünü desteklemiyor'; es_ES = 'El servidor no admite la versión de protocolo HTTP indicada en la consulta'");
	ElsIf StatusCode = 506 Then // Variant Also Negotiates
		Details = NStr("ru = 'Сервер настроен некорректно, и не способен обработать запрос.'; en = 'The server cannot process a request because it is configured incorrectly.'; pl = 'Serwer jest skonfigurowany niepoprawnie i nie może przetworzyć żądania.';de = 'Der Server ist nicht korrekt konfiguriert und kann die Anforderung nicht bearbeiten.';ro = 'Serverul este configurat incorect și nu poate procesa interogarea.';tr = 'Sunucu düzgün yapılandırılmamış ve isteği işleyemiyor.'; es_ES = 'El servidor está ajustado incorrectamente y no es capaz de procesar la consulta.'");
	ElsIf StatusCode = 507 Then // Insufficient Storage
		Details = NStr("ru = 'На сервере недостаточно места для выполнения запроса.'; en = 'Not enough space on the server to run the request.'; pl = 'Na serwerze brakuje miejsca, aby spełnić żądanie.';de = 'Es ist nicht genügend Platz auf dem Server vorhanden, um die Anforderung auszuführen.';ro = 'Loc insuficient pe server pentru executarea interogării.';tr = 'Sunucu isteği gerçekleştirmek için yeterli alan yok.'; es_ES = 'En el servidor no hay suficiente espacio para realizar la consulta.'");
	ElsIf StatusCode = 509 Then // Bandwidth Limit Exceeded
		Details = NStr("ru = 'Сервер превысил отведенное ограничение на потребление трафика.'; en = 'The server exceeded the bandwidth limit.'; pl = 'Serwer przekroczył przydzielony limit na zużycie ruchu.';de = 'Der Server hat die Grenze für den Traffic-Verbrauch überschritten.';ro = 'Serverul a depășit restricția existentă pentru consumul de trafic.';tr = 'Sunucu, ayrılan trafik tüketim kısıtlamasını aştı.'; es_ES = 'El servidor ha superado la restricción concedida del consumo de tráfico.'");
	ElsIf StatusCode = 510 Then // Not Extended
		Details = NStr("ru = 'Сервер требует больше информации о совершаемом запросе.'; en = 'The server requires additional request details.'; pl = 'Serwer wymaga więcej informacji o żądaniu.';de = 'Der Server benötigt weitere Informationen über die gestellte Anforderung.';ro = 'Serverul solicit mai multe informații despre interogarea efectuată.';tr = 'Sunucu, işlenen sorgu hakkında daha fazla bilgi gerektirir.'; es_ES = 'El servidor requiere más información de la consulta realizada.'");
	ElsIf StatusCode = 511 Then // Network Authentication Required
		Details = NStr("ru = 'Требуется авторизация на сервере.'; en = 'Authorization on the server is required.'; pl = 'Wymagana autoryzacja na serwerze.';de = 'Erfordert Autorisierung auf dem Server.';ro = 'Este necesară autorizarea pe server.';tr = 'Sunucuda yetkilendirme gereklidir.'; es_ES = 'Se requiere autorización en el servidor.'");
	Else 
		Details = NStr("ru = '<Неизвестный код состояния>.'; en = 'Unknown status code.'; pl = '<Nieznany kod statusu>.';de = '<Unbekannter Statuscode>.';ro = '<Cod necunoscut al statutului>.';tr = '<Bilinmeyen durum kodu>.'; es_ES = '<Código desconocido del estado>.'");
	EndIf;
	
	Return StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = '[%1] %2'; en = '[%1] %2'; pl = '[%1] %2';de = '[%1] %2';ro = '[%1] %2';tr = '[%1] %2'; es_ES = '[%1] %2'"), 
		StatusCode, 
		Details);
	
EndFunction

Procedure AddRedirectionsPresentation(Redirections, ErrorText)
	
	If Redirections.Count() > 0 Then 
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = '%1
			           |
			           |Выполненные перенаправления (%2):
			           |%3'; 
			           |en = '%1
			           |
			           |Redirections (%2):
			           |%3'; 
			           |pl = '%1
			           |
			           |Przekierowania zakończone (%2):
			           |%3';
			           |de = '%1
			           |
			           |Umleitungen durchgeführt (%2):
			           |%3';
			           |ro = '%1
			           |
			           |Redirecționările executate (%2):
			           |%3';
			           |tr = '%1
			           |
			           |Yapılan yönlendirmeler (%2):
			           |%3'; 
			           |es_ES = '%1
			           |
			           |Redirecciones realizadas (%2):
			           |%3'"),
			ErrorText,
			Redirections.Count(),
			StrConcat(Redirections, Chars.LF));
	EndIf;
	
EndProcedure

Procedure AddServerResponseBody(FilePath, ErrorText)
	
	ServerResponseBody = TextFromHTMLFromFile(FilePath);
	
	If Not IsBlankString(ServerResponseBody) Then 
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = '%1
			           |
			           |Сообщение, полученное от сервера:
			           |%2'; 
			           |en = '%1
			           |
			           |Message from the server:
			           |%2'; 
			           |pl = '%1
			           |
			           |Wiadomość odebrana z serwera: 
			           |%2';
			           |de = '%1
			           |
			           |Nachricht, vom Server erhalten:
			           |%2';
			           |ro = '%1
			           |
			           |Mesajul primit de la server:
			           |%2';
			           |tr = '%1
			           |
			           |Sunucudan gelen mesaj:
			           |%2'; 
			           |es_ES = '%1
			           |
			           |Mensaje recibido del servidor:
			           |%2'"),
			ErrorText,
			ServerResponseBody);
	EndIf;
	
EndProcedure

Function TextFromHTMLFromFile(FilePath)
	
	ResponseFile = New TextReader(FilePath, TextEncoding.UTF8);
	SourceText = ResponseFile.Read(1024 * 15);
	ErrorText = StringFunctionsClientServer.ExtractTextFromHTML(SourceText);
	ResponseFile.Close();
	
	Return ErrorText;
	
EndFunction

Procedure AddHTTPHeaders(Object, ErrorText)
	
	If TypeOf(Object) = Type("HTTPRequest") Then 
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = '%1
			           |
			           |HTTP запрос:
			           |Адрес ресурса: %2
			           |Заголовки: %3'; 
			           |en = '%1
			           |
			           |HTTP request:
			           |Resource address: %2
			           |Headers: %3'; 
			           |pl = '%1
			           |
			           |Żądanie HTTP:
			           |Adres zasobu: %2
			           |Nagłówki: %3';
			           |de = '%1
			           |
			           |HTTP-Anforderung:
			           |Ressourcenadresse: %2
			           |Header: %3';
			           |ro = '%1
			           |
			           |Interogare HTTP:
			           |Adresa resursei: %2
			           |Titluri: %3';
			           |tr = '%1
			           |
			           |HTTP sorgu:
			           |Kaynağın adresi: %2
			           |Başlıklar: %3'; 
			           |es_ES = '%1
			           |
			           |Consulta HTTP:
			           |Dirección del recurso: %2
			           |Títulos: %3'"),
			ErrorText,
			Object.ResourceAddress,
			HTTPHeadersPresentation(Object.Headers));
	ElsIf TypeOf(Object) = Type("HTTPResponse") Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = '%1
			           |
			           |HTTP ответ:
			           |Код ответа: %2
			           |Заголовки: %3'; 
			           |en = '%1
			           |
			           |HTTP response:
			           |Response code: %2
			           |Headers: %3'; 
			           |pl = '%1
			           |
			           |Żądanie HTTP:
			           |Kod odpowiedzi: %2
			           |Nagłówki: %3';
			           |de = '%1
			           |
			           |HTTP-Antwort
			           |Antwortcode: %2
			           |Header: %3';
			           |ro = '%1
			           |
			           |Răspuns HTTP:
			           |Codul răspunsului: %2
			           |Titluri: %3';
			           |tr = '%1
			           |
			           |HTTP cevap:
			           |Cevap kodu: %2
			           |Başlıklar: %3'; 
			           |es_ES = '%1
			           |
			           |Respuesta HTTP:
			           |Código de la respuesta: %2
			           |Títulos: %3'"),
			ErrorText,
			Object.StatusCode,
			HTTPHeadersPresentation(Object.Headers));
	EndIf;
	
EndProcedure

Function HTTPHeadersPresentation(Headers)
	
	HeadersPresentation = "";
	
	For each Title In Headers Do 
		HeadersPresentation = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = '%1
			           |%2: %3'; 
			           |en = '%1
			           |%2: %3'; 
			           |pl = '%1
			           |%2: %3';
			           |de = '%1
			           |%2: %3';
			           |ro = '%1
			           |%2: %3';
			           |tr = '%1
			           |%2: %3'; 
			           |es_ES = '%1
			           |%2: %3'"), 
			HeadersPresentation,
			Title.Key, Title.Value);
	EndDo;
		
	Return HeadersPresentation;
	
EndFunction

Function InternetProxyPresentation(Proxy)
	
	Log = New Array;
	Log.Add(StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Адрес:  %1:%2
		           |HTTP:   %3:%4
		           |Secure: %5:%6
		           |FTP:    %7:%8'; 
		           |en = 'Address: %1:%2
		           |HTTP:    %3:%4
		           |HTTPS:   %5:%6
		           |FTP:     %7:%8'; 
		           |pl = 'Adres:  %1:%2
		           |HTTP:   %3:%4
		           |Secure: %5:%6
		           |FTP:    %7:%8';
		           |de = 'Adresse  :%1:%2
		           |HTTP:   %3:%4
		           |Secure: %5:%6
		           |FTP:   %7:%8';
		           |ro = 'Adresa:  %1:%2
		           |HTTP:   %3:%4
		           |Secure: %5:%6
		           |FTP:    %7:%8';
		           |tr = 'Adres:  %1:%2
		           |HTTP:   %3:%4
		           |Secure: %5:%6
		           |FTP:    %7:%8'; 
		           |es_ES = 'Dirección:  %1:%2
		           |HTTP:   %3:%4
		           |Secure: %5:%6
		           |FTP:    %7:%8'"),
		Proxy.Server(),        Format(Proxy.Port(),        "NG="),
		Proxy.Server("http"),  Format(Proxy.Port("http"),  "NG="),
		Proxy.Server("https"), Format(Proxy.Port("https"), "NG="),
		Proxy.Server("ftp"),   Format(Proxy.Port("ftp"),   "NG=")));
	
	If Proxy.UseOSAuthentication("") Then 
		Log.Add(NStr("ru = 'Используется аутентификация операционной системы'; en = 'OS authentication.'; pl = 'Używanie uwierzytelniania systemu operacyjnego';de = 'Die Authentifizierung des Betriebssystems wird verwendet';ro = 'Se utilizează autentificarea sistemului de operare';tr = 'İşletim sistemi kimlik doğrulaması kullanılır'; es_ES = 'Se usa autenticación del sistema operativo'"));
	Else 
		User = Proxy.User("");
		Password = Proxy.Password("");
		PasswordState = ?(IsBlankString(Password), NStr("ru = '<не указан>'; en = '<not specified>'; pl = '<nieokreślony>';de = '<nicht angegeben>';ro = '<Nespecificat>';tr = '<belirtilmedi>'; es_ES = '<no especificado>'"), NStr("ru = '********'; en = '********'; pl = '********';de = '********';ro = '********';tr = '********'; es_ES = '********'"));
		
		Log.Add(NStr("ru = 'Используется аутентификация по имени пользователя и паролю'; en = 'Authentication with username and password.'; pl = 'Wykorzystywane jest uwierzytelnianie według nazwy użytkownika i hasła';de = 'Die Authentifizierung von Benutzername und Passwort wird verwendet.';ro = 'Se utilizează autentificarea după numele utilizatorului și parolă';tr = 'Kullanıcı adı ve şifre kimlik doğrulaması kullanılır'; es_ES = 'Se usa la autenticación por el nombre de usuario y la contraseña'"));
		Log.Add(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Пользователь: %1
			           |Пароль: %2'; 
			           |en = 'User: %1
			           |Password: %2'; 
			           |pl = 'Użytkownik: %1
			           |Hasło: %2';
			           |de = 'Benutzer: %1
			           |Passwort: %2';
			           |ro = 'Utilizator: %1
			           |Parola: %2';
			           |tr = 'Kullanıcı: %1
			           |Şifre: %2'; 
			           |es_ES = 'Usuario: %1
			           |Contraseña: %2'"),
			User,
			PasswordState));
	EndIf;
	
	If Proxy.BypassProxyOnLocal Then 
		Log.Add(NStr("ru = 'Не использовать прокси для локальных адресов'; en = 'Bypass proxy for local addresses.'; pl = 'Nie używać proxy dla lokalnych adresów';de = 'Proxyserver für lokale URLs';ro = 'Bypass proxy pentru adresele URL locale';tr = 'Yerel URL''ler için baypas proxy''si'; es_ES = 'Proxy de bypass para URLs locales'"));
	EndIf;
	
	If Proxy.BypassProxyOnAddresses.Count() > 0 Then 
		Log.Add(NStr("ru = 'Не использовать для следующих адресов:'; en = 'Bypass proxy for the following addresses:'; pl = 'Nie używaj dla następujących adresów:';de = 'Nicht für die folgenden Adressen verwenden:';ro = 'Nu utiliza pentru următoarele adrese:';tr = 'Aşağıdaki adresler için kullanma:'; es_ES = 'No usar para las siguientes direcciones:'"));
		For Each AddressToExclude In Proxy.BypassProxyOnAddresses Do
			Log.Add(AddressToExclude);
		EndDo;
	EndIf;
	
	Return StrConcat(Log, Chars.LF);
	
EndFunction

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
Function NewInternetProxy(ProxyServerSetting, Protocol) Export
	
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

// Writes error messages to the event log Event name
// "Getting files from the Internet".
// Parameters:
//   ErrorMessage - String - error message.
// 
Procedure WriteErrorToEventLog(Val ErrorMessage)
	
	WriteLogEvent(
		EventLogEvent(),
		EventLogLevel.Error, , ,
		ErrorMessage);
	
EndProcedure

Function EventLogEvent()
	
	Return NStr("ru = 'Получение файлов из Интернета'; en = 'Network download'; pl = 'Pobieranie plików z internetu';de = 'Empfangen von Dateien aus dem Internet';ro = 'Primirea fișierelor din Internet';tr = 'İnternet''ten dosya alma'; es_ES = 'Recepción de los archivos de Internet'", Common.DefaultLanguageCode());
	
EndFunction

#EndIf

#EndRegion

#Region ConnectionDiagnostics

// Service information that displays current settings and proxy states to perform diagnostics.
//
// Returns:
//  Structure - with the following properties:
//     * ProxyConnection - Boolean - flag that indicates that proxy connection should be used.
//     * Presentation - String - presentation of the current set up proxy.
//
Function ProxySettingsState() Export
	
	Proxy = GetFilesFromInternet.GetProxy("http");
	ProxySettings = GetFilesFromInternet.ProxySettingsAtServer();
	
	Log = New Array;
	
	If ProxySettings = Undefined Then 
		Log.Add(NStr("ru = 'Параметры прокси-сервера в ИБ не указаны (используются системные настройки прокси).'; en = 'The proxy server parameters are not specified in the infobase. System proxy server are used instead.'; pl = 'Ustawienia serwera proxy w IB nie są określone (używane są ustawienia proxy systemu).';de = 'Proxy-Server-Parameter werden in der IB nicht angegeben (es werden System-Proxy-Einstellungen verwendet).';ro = 'Parametrii serverului proxy nu sunt indicați în BI (se utilizează setările de sistem ale proxy).';tr = 'Proxy sunucunun ayarları IB''de belirtilmemiştir (sistem proxy ayarları kullanılır).'; es_ES = 'Parámetros del servidor proxy en la BI no están indicados (se usan los ajustes proxy de sistema).'"));
	ElsIf Not ProxySettings.Get("UseProxy") Then
		Log.Add(NStr("ru = 'Параметры прокси-сервера в ИБ: Не использовать прокси-сервер.'; en = 'Proxy server parameters in the infobase: Do not use proxy server.'; pl = 'Ustawienia serwera proxy w IB: Nie używaj serwera proxy.';de = 'Proxy-Server-Parameter in der IB: Verwenden Sie keinen Proxy-Server.';ro = 'Parametrii serverului proxy în BI: Nu utiliza serverul proxy.';tr = 'Proxy sunucunun IB''deki ayarları: Proxy sunucusu kullanılamaz.'; es_ES = 'Parámetros del servidor proxy en la BI: No usar el servidor proxy.'"));
	ElsIf ProxySettings.Get("UseSystemSettings") Then
		Log.Add(NStr("ru = 'Параметры прокси-сервера в ИБ: Использовать системные настройки прокси-сервера.'; en = 'Proxy server parameters in the infobase: Use system proxy server settings.'; pl = 'Ustawienia serwera proxy w IB: Użyj ustawień systemu serwera proxy.';de = 'Proxy-Server-Parameter in der IB: Verwenden Sie die Systemeinstellungen des Proxy-Servers.';ro = 'Parametrii serverului proxy în BI: Utilizați setările de sistem ale serverului proxy.';tr = 'Proxy sunucunun IB''deki ayarları: Proxy sunucunun sistem ayarlarını kullan.'; es_ES = 'Parámetros del servidor proxy en la BI: Usar los ajustes del sistema del servidor proxy.'"));
	Else
		Log.Add(NStr("ru = 'Параметры прокси-сервера в ИБ: Использовать другие настройки прокси-сервера.'; en = 'Proxy server parameters in the infobase: Use other proxy server settings.'; pl = 'Ustawienia proxy w IB: Użyj innych ustawień serwera proxy.';de = 'Proxy-Server-Parameter in der IB: Verwenden Sie andere Proxy-Server-Einstellungen.';ro = 'Parametrii serverului proxy în BI: Utilizați alte setări ale serverului proxy.';tr = 'Proxy sunucunun IB''deki ayarları: Proxy sunucunun sistem diğer ayarlarını kullan.'; es_ES = 'Parámetros del servidor proxy en la BI: Usar otros ajustes del servidor proxy.'"));
	EndIf;
	
	If Proxy = Undefined Then 
		Proxy = New InternetProxy(True);
	EndIf;
	
	AllAddressesProxySpecified = Not IsBlankString(Proxy.Server());
	HTTPProxySpecified = Not IsBlankString(Proxy.Server("http"));
	HTTPSProxySpecified = Not IsBlankString(Proxy.Server("https"));
	
	ProxyConnection = AllAddressesProxySpecified Or HTTPProxySpecified Or HTTPSProxySpecified;
	
	If ProxyConnection Then 
		Log.Add(NStr("ru = 'Соединение выполняется через прокси-сервер:'; en = 'Connecting via proxy server:'; pl = 'Połączenie jest nawiązywane za pośrednictwem serwera proxy:';de = 'Die Verbindung erfolgt über einen Proxy-Server:';ro = 'Conexiunea se face prin serverul proxy:';tr = 'Bağlantı proxy sunucusu üzerinden yapılıyor:'; es_ES = 'La conexión se realiza a través del servidor proxy:'"));
		Log.Add(InternetProxyPresentation(Proxy));
	Else
		Log.Add(NStr("ru = 'Соединение выполняется без использования прокси-сервера.'; en = 'Connecting without a proxy server.'; pl = 'Połączenie jest wykonywane bez użycia serwera proxy.';de = 'Die Verbindung wird ohne Verwendung eines Proxy-Servers durchgeführt.';ro = 'Conexiunea se face fără utilizarea serverului proxy.';tr = 'Bağlantı proxy sunucu kullanılmadan yapılıyor.'; es_ES = 'La conexión se realiza sin usar el servidor proxy.'"));
	EndIf;
	
	Result = New Structure;
	Result.Insert("ProxyConnection", ProxyConnection);
	Result.Insert("Presentation", StrConcat(Log, Chars.LF));
	Return Result;
	
EndFunction

Function DiagnosticsLocationPresentation() Export
	
	If Common.DataSeparationEnabled() Then
		Return NStr("ru = 'Подключение проводится на сервере 1С:Предприятия в интернете.'; en = 'Connecting from a remote 1C:Enterprise server.'; pl = 'Podłączenie jest wykonywane na serwerze 1С:Предприятия в интернете.';de = 'Die Verbindung erfolgt auf dem Server 1C:Enterprises im Internet.';ro = 'Conectarea se face pe serverul 1C:Enterprise în internet.';tr = 'Bağlantı, 1C:İşletme sunucusunda İnternet''te yapılıyor.'; es_ES = 'La conexión se realiza en el servidor 1C:Enterprise en internet.'");
	Else 
		If Common.FileInfobase() Then
			If Common.ClientConnectedOverWebServer() Then 
				Return StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Подключение проводится из файловой базы на веб-сервере <%1>.'; en = 'Connecting from a file infobase on web server <%1>.'; pl = 'Podłączenie jest wykonywane z bazy plikowej w serwisie internetowym <%1>.';de = 'Die Verbindung wird von der Dateibasis auf dem Webserver <%1> hergestellt.';ro = 'Conectarea se face din baza de tip fișier pe web-server <%1>.';tr = 'Bağlantı, web-sunucusundaki dosya tabanından yapılıyor <%1>.'; es_ES = 'La conexión se realiza de la base de archivos en el servidor web <%1>.'"), ComputerName());
			Else 
				Return StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Подключение проводится из файловой базы на компьютере <%1>.'; en = 'Connecting from a file infobase on computer <%1>.'; pl = 'Podłączenie jest wykonywane z bazy plikowej na komputerze <%1>.';de = 'Die Verbindung wird von der Dateibasis auf dem Computer <%1> hergestellt.';ro = 'Conectarea se face din baza de tip fișier pe computer <%1>.';tr = 'Bağlantı, bilgisayardaki dosya tabanından yapılıyor <%1>.'; es_ES = 'La conexión se realiza de la base de archivos en el ordenador <%1>.'"), ComputerName());
			EndIf;
		Else
			Return StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Подключение проводится на сервере 1С:Предприятие <%1>.'; en = 'Connecting from 1C:Enterprise server <%1>.'; pl = 'Podłączenie jest wykonywane na serwerze 1C:Enterprise <%1>.';de = 'Die Verbindung wird auf dem Server 1C:Enterprise <%1> durchgeführt.';ro = 'Conectarea se face pe serverul 1C:Enterprise <%1>.';tr = 'Bağlantı, 1C:İşletme sunucusunda <%1> yapılıyor.'; es_ES = 'La conexión se realiza en el servidor 1C:Enterprise <%1>.'"), ComputerName());
		EndIf;
	EndIf;
	
EndFunction

Function CheckServerAvailability(ServerAddress) Export
	
	ApplicationStartupParameters = FileSystem.ApplicationStartupParameters();
	ApplicationStartupParameters.WaitForCompletion = True;
	ApplicationStartupParameters.GetOutputStream = True;
	ApplicationStartupParameters.GetErrorStream = True;
	ApplicationStartupParameters.ExecutionEncoding = "OEM";
	
	If Common.IsWindowsServer() Then
		CommandPattern = "ping %1 -n 2 -w 500";
	Else
		CommandPattern = "ping -c 2 -w 500 %1";
	EndIf;
	
	CommandRow = StringFunctionsClientServer.SubstituteParametersToString(CommandPattern, ServerAddress);
	
	Result = FileSystem.StartApplication(CommandRow, ApplicationStartupParameters);
	
	// Different operating systems can output errors in different threads:
	// - Windows always displays errors in the output thread.
	// - Debian or RHEL displays errors in the error thread.
	AvailabilityLog = Result.OutputStream + Result.ErrorStream;
	
	If Common.IsWindowsServer() Then
		UnavailabilityFact = (StrFind(AvailabilityLog, "Destination host unreachable") > 0); // Do not localize.
		NoLosses = (StrFind(AvailabilityLog, "(0% loss)") > 0); // Do not localize.
	Else 
		UnavailabilityFact = (StrFind(AvailabilityLog, "Destination Host Unreachable") > 0); // Do not localize.
		NoLosses = (StrFind(AvailabilityLog, "0% packet loss") > 0) // do not localize.
	EndIf;
	
	Available = Not UnavailabilityFact AND NoLosses;
	AvailabilityState = ?(Available, NStr("ru = 'доступен'; en = 'is available'; pl = 'dostępny';de = 'verfügbar';ro = 'accesibil';tr = 'mevcut'; es_ES = 'está disponible'"), NStr("ru = 'не доступен'; en = 'is unavailable'; pl = 'nie jest dostępny';de = 'nicht verfügbar';ro = 'inaccesibil';tr = 'mevcut değil'; es_ES = 'no está disponible'"));
	
	Log = New Array;
	Log.Add(StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Удаленный сервер %1 %2:'; en = 'Remote server %1 %2:'; pl = 'Usunięty serwer %1 %2:';de = 'Remote-Server %1 %2:';ro = 'Serverul la distanță %1 %2:';tr = 'Uzak sunucu %1%2:'; es_ES = 'Servidor remoto %1%2:'"), 
		ServerAddress, 
		AvailabilityState));
	
	Log.Add("> " + CommandRow);
	Log.Add(AvailabilityLog);
	
	Return New Structure("Available, DiagnosticsLog", Available, StrConcat(Log, Chars.LF));
	
EndFunction

Function ServerRouteTraceLog(ServerAddress) Export
	
	ApplicationStartupParameters = FileSystem.ApplicationStartupParameters();
	ApplicationStartupParameters.WaitForCompletion = True;
	ApplicationStartupParameters.GetOutputStream = True;
	ApplicationStartupParameters.GetErrorStream = True;
	ApplicationStartupParameters.ExecutionEncoding = "OEM";
	
	If Common.IsWindowsServer() Then
		CommandPattern = "tracert -w 100 -h 15 %1";
	Else 
		// If the traceroute package is not installed, an error will occur in the output tread.
		// As the result will not be parsed, you can ignore the output thread.
		// According to it the administrator will understand what to do.
		CommandPattern = "traceroute -w 100 -m 100 %1";
	EndIf;
	
	CommandRow = StringFunctionsClientServer.SubstituteParametersToString(CommandPattern, ServerAddress);
	
	Result = FileSystem.StartApplication(CommandRow, ApplicationStartupParameters);
	
	Log = New Array;
	Log.Add(StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Трассировка маршрута к удаленному серверу %1:'; en = 'Tracing route to remote server %1:'; pl = 'Trasowanie trasy do do usuniętego serwera %1:';de = 'Verfolgung der Route zum Remote-Server %1:';ro = 'Trasarea traseului către serverul la distanță %1:';tr = '%1Uzak sunucuya rota izleme: '; es_ES = 'Trazabilidad de la ruta al servidor remoto %1:'"), ServerAddress));
	
	Log.Add("> " + CommandRow);
	Log.Add(Result.OutputStream);
	Log.Add(Result.ErrorStream);
	
	Return StrConcat(Log, Chars.LF);
	
EndFunction

#EndRegion

#EndRegion
