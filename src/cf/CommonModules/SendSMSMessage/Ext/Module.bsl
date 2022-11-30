///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// It sends a text message via a configured service provider and returns message ID. 
//
// Parameters:
//  RecipientsNumbers - Array - an array of strings containing recipient numbers in format +7ХХХХХХХХХХ.
//  Text - String - a message text, the maximum length varies depending on operators.
//  SenderName     - String - a sender name that recipients will see instead of a number.
//  Transliterate - Boolean - True if the message text is to be transliterated before sending.
//
// Returns:
//  Structure - a sending result:
//    * SentMessages - Array - an array of structures:
//      ** RecipientNumber - String - a number of text message recipient.
//      ** MessageID - String - a text message ID assigned by a provider to track delivery.
//    * ErrorDescription - String - a user presentation of an error. If the string is empty, there is no error.
//
Function SendSMSMessage(RecipientsNumbers, Val Text, SenderName = Undefined, Transliterate = False) Export
	
	CheckRights();
	
	Result = New Structure("SentMessages,ErrorDescription", New Array, "");
	
	If Transliterate Then
		Text = StringFunctionsClientServer.LatinString(Text);
	EndIf;
	
	If Not SMSMessageSendingSetupCompleted() Then
		Result.ErrorDescription = NStr("ru = 'Неверно заданы настройки провайдера для отправки SMS.'; en = 'Invalid SMS provider settings.'; pl = 'Nieprawidłowe ustawienia dostawcy do wysyłania SMS.';de = 'Falsche Einstellungen des Providers für SMS-Versand.';ro = 'Setările incorecte ale furnizorului pentru trimiterea prin SMS.';tr = 'Sağlayıcının SMS gönderimi için hatalı ayarları.'; es_ES = 'Configuraciones incorrectas del proveedor para el envío de SMS.'");
		Return Result;
	EndIf;
	
	SetPrivilegedMode(True);
	SMSMessageSendingSettings = SMSMessageSendingSettings();
	SetPrivilegedMode(False);
	
	If SenderName = Undefined Then
		SenderName = SMSMessageSendingSettings.SenderName;
	EndIf;
	
	ModuleSMSMessageSendingViaProvider = ModuleSMSMessageSendingViaProvider(SMSMessageSendingSettings.Provider);
	If ModuleSMSMessageSendingViaProvider <> Undefined Then
		Username = "";
		Password = "";
		If SMSMessageSendingSettings.AuthorizationMethod <> "ByKey" Then
			Username = SMSMessageSendingSettings.Username;
			Password = SMSMessageSendingSettings.Password;
		EndIf;
		Result = ModuleSMSMessageSendingViaProvider.SendSMSMessage(RecipientsNumbers, Text, SenderName, Username, Password);
	Else
		SendOptions = New Structure;
		SendOptions.Insert("RecipientsNumbers", RecipientsNumbers);
		SendOptions.Insert("Text", Text);
		SendOptions.Insert("SenderName", SenderName);
		SendOptions.Insert("Username", SMSMessageSendingSettings.Username);
		SendOptions.Insert("Password", SMSMessageSendingSettings.Password);
		SendOptions.Insert("Provider", SMSMessageSendingSettings.Provider);
		
		SMSOverridable.SendSMSMessage(SendOptions, Result);
		
		CommonClientServer.CheckParameter("SMSOverridable.SendSMSMessage", "Result", Result,
			Type("Structure"), New Structure("SentMessages,ErrorDescription", Type("Array"), Type("String")));
			
		If Not ValueIsFilled(Result.ErrorDescription) AND Not ValueIsFilled(Result.SentMessages) Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Ошибка при выходе из процедуры ОтправкаSMSПереопределяемый.ОтправитьSMS:
					|Не заполнены выходные параметры ОписаниеОшибки и ОтправленныеСообщения (провайдер: %1).
					|Ожидается заполнение по меньшей мере одного из этих параметров.'; 
					|en = 'An error occurred while completing procedure SMSOverridable.SendSMSMessage:
					|The ErrorDescription and SentMessages output parameters (provider: %1) are blank.
					|At least one of these parameters is required.'; 
					|pl = 'Błąd podczas wyjścia z procedury ОтправкаSMSПереопределяемый.ОтправитьSMS:
					|Nie są wypełnione parametry wyjściowe ОписаниеОшибки i ОтправленныеСообщения (operatora Internetu: %1).
					|Oczekiwane jest wypełnienie co najmniej jednego z tych parametrów.';
					|de = 'Fehler beim Beenden der Prozedur SendenSMSNeudefinierbar.SendenSMS:
					| Ausgabeparameter sind nicht ausgefüllt FehlerBeschreibung und GesendeteNachrichten (Provider: %1).
					|Es wird erwartet, dass mindestens einer dieser Parameter ausgefüllt wird.';
					|ro = 'Eroare la ieșire din procedura ОтправкаSMSПереопределяемый.ОтправитьSMS:
					|Nu sunt completați parametrii de ieșire ОписаниеОшибки și ОтправленныеСообщения (provider: %1).
					|Se așteaptă completarea a cel puțin unuia din parametri.';
					|tr = 'SMSGönderimiYenidenBelirlenen.SMSGönder prosedürden çıkarken hata oluştu: 
					|Giriş parametreleri doldurulmadı HataAçıklaması ve GönderilenMesajlar (sağlayıcı: %1). 
					|Bu parametrelerin en az birinin doldurulması bekleniyor.'; 
					|es_ES = 'Error al salir del procedimiento ОтправкаSMSПереопределяемый.ОтправитьSMS:
					|No están rellenados los parámetros de salida ОписаниеОшибки y ОтправленныеСообщения (proveedor:%1).
					|Se espera el relleno de como mínimo uno de estos parámetros.'", Common.DefaultLanguageCode()),
					SMSMessageSendingSettings.Provider);
		EndIf;
		
		If Result.SentMessages.Count() > 0 Then
			CommonClientServer.Validate(
				TypeOf(Result.SentMessages[0]) = Type("Structure"),
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Неверный тип значения в коллекции Результат.ОтправленныеСообщения:
						|ожидается тип ""Структура"", передан тип ""%1""'; 
						|en = 'Invalid value type in Result.SentMessages collection.
						|Actual type: %1. Expected type: Structure.'; 
						|pl = 'Błędny typ wartości w kolekcji Result.SentMessages collection:
						|jest oczekiwany typ ""Structure"", został przekazany typ ""%1""';
						|de = 'Falsche Wertart in der Sammlung Result.SentMessages: der Strukturtyp wird 
						|erwartet, der Typ ""%1"" wird übertragen';
						|ro = 'Tip de valoare incorectă în colecția Result.SentMessages: este de așteptat 
						|tipul de structură, tipul ""%1"" este transferat';
						|tr = 'Result.SentMessages koleksiyonundaki değerin türü yanlıştır: 
						|""Yapı"" türü bekleniyor, ""%1"" türü aktarıldı'; 
						|es_ES = 'Tipo incorrecto del valor en la colección Result.SentMessages:
						|se espera el tipo ""Estructura"", ha enviado el tipo ""%1""'"),
						TypeOf(Result.SentMessages[0])),
				"SMSOverridable.SendSMSMessage");
			For Index = 0 To Result.SentMessages.Count() - 1 Do
				CommonClientServer.CheckParameter(
					"SMSOverridable.SendSMSMessage",
					StringFunctionsClientServer.SubstituteParametersToString("Result.SentMessages[%1]", Format(Index, "NZ=; NG=0")),
					Result.SentMessages[Index],
					Type("Structure"),
					New Structure("RecipientNumber,MessageID", Type("String"), Type("String")));
			EndDo;
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

// The function requests for a message delivery status from service provider.
//
// Parameters:
//  MessageID - String - ID assigned to a text message upon sending.
//
// Returns:
//  String - a message delivery status returned from service provider:
//           Pending - the message is not processed by the service provider yet (in queue).
//           BeingSent - the message is in the sending queue at the provider.
//           Sent - the message is sent, a delivery confirmation is awaited.
//           NotSent - the message is not sent (insufficient account balance or operator network congestion).
//           Delivered - the message is delivered to the addressee.
//           NotDelivered - cannot deliver the message (the subscriber is not available or delivery 
//                              confirmation from the subscriber is timed out).
//           Error - cannot get a status from service provider (unknown status).
//
Function DeliveryStatus(Val MessageID) Export
	
	CheckRights();
	
	If IsBlankString(MessageID) Then
		Return "Pending";
	EndIf;
	
	Result = SendSMSMessagesCached.DeliveryStatus(MessageID);
	
	Return Result;
	
EndFunction

// This function checks whether saved text message sending settings are correct.
//
// Returns:
//  Boolean - True if text message sending is set up.
Function SMSMessageSendingSetupCompleted() Export
	
	SetPrivilegedMode(True);
	SMSMessageSendingSettings = SMSMessageSendingSettings();
	SetPrivilegedMode(False);
	
	If ValueIsFilled(SMSMessageSendingSettings.Provider) Then
		ProviderSettings = ProviderSettings(SMSMessageSendingSettings.Provider);
		
		AuthorizationFields = DefaultProviderAuthorizationMethods().ByUsernameAndPassword;
		If SMSMessageSendingSettings.Property("AuthorizationMethod") AND ValueIsFilled(SMSMessageSendingSettings.AuthorizationMethod)
			AND ProviderSettings.AuthorizationMethods.Property(SMSMessageSendingSettings.AuthorizationMethod) Then
			
			AuthorizationFields = ProviderSettings.AuthorizationMethods[SMSMessageSendingSettings.AuthorizationMethod];
		EndIf;
		
		Cancel = False;
		For Each Field In AuthorizationFields Do
			If Not ValueIsFilled(SMSMessageSendingSettings[Field.Value]) Then
				Cancel = True;
			EndIf;
		EndDo;
		
		SMSOverridable.OnCheckSMSMessageSendingSettings(SMSMessageSendingSettings, Cancel);
		Return Not Cancel;
	EndIf;
	
	Return False;
	
EndFunction

// This function checks whether the current user can send text messages.
// 
// Returns:
//  Boolean - True if text message sending is set up and the current user has sufficient rights to send text messages.
//
Function CanSendSMSMessage() Export
	Return AccessRight("View", Metadata.CommonForms.SendSMSMessage) AND SMSMessageSendingSetupCompleted() Or Users.IsFullUser();
EndFunction

#EndRegion

#Region Internal

////////////////////////////////////////////////////////////////////////////////
// Update the infobase.

// Intended for moving passwords to a secure storage.
// This procedure is used in the infobase update handler.
Procedure MovePasswordsToSecureStorage() Export
	SMSMessageSenderUsername = Constants.DeleteSMSMessageSenderUsername.Get();
	SMSMessageSenderPassword = Constants.DeleteSMSMessageSenderPassword.Get();
	Owner = Common.MetadataObjectID("Constant.SMSProvider");
	SetPrivilegedMode(True);
	Common.WriteDataToSecureStorage(Owner, SMSMessageSenderPassword);
	Common.WriteDataToSecureStorage(Owner, SMSMessageSenderUsername, "Username");
	SetPrivilegedMode(False);
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Configuration subsystems event handlers.

// See CommonOverridable.OnAddClientParameters. 
Procedure OnAddClientParameters(Parameters) Export
	Parameters.Insert("CanSendSMSMessage", CanSendSMSMessage());
EndProcedure

// See SafeModeManagerOverridable.OnFillPermissionsToAccessExternalResources. 
Procedure OnFillPermissionsToAccessExternalResources(PermissionRequests) Export
	
	ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
	
	For Each ModuleProvider In ProvidersModules() Do
		ModuleSMSMessageSendingViaProvider = ModuleProvider.Value;
		PermissionRequests.Add(
			ModuleSafeModeManager.RequestToUseExternalResources(ModuleSMSMessageSendingViaProvider.Permissions()));
	EndDo;
	
	PermissionRequests.Add(
		ModuleSafeModeManager.RequestToUseExternalResources(AdditionalPermissions()));
	
EndProcedure

#EndRegion

#Region Private

Function AdditionalPermissions()
	Permissions = New Array;
	SMSOverridable.OnGetPermissions(Permissions);
	
	Return Permissions;
EndFunction

Procedure CheckRights() Export
	If Not AccessRight("View", Metadata.CommonForms.SendSMSMessage) Then
		Raise NStr("ru = 'Недостаточно прав для выполнения операции.'; en = 'Insufficient rights to perform the operation.'; pl = 'Niewystarczające uprawnienia do wykonania operacji.';de = 'Unzureichende Rechte zum Ausführen der Operation.';ro = 'Drepturi suficiente pentru a efectua operațiunea.';tr = 'İşlemi gerçekleştirmek için yetersiz haklar'; es_ES = 'Insuficientes derechos para realizar la operación.'");
	EndIf;
EndProcedure

Function ModuleSMSMessageSendingViaProvider(Provider) Export
	Return ProvidersModules()[Provider];
EndFunction

Function ProvidersModules()
	Result = New Map;
	
	For Each MetadataObject In Metadata.Enums.SMSProviders.EnumValues Do
		ModuleName = "SendSMSThrough" + MetadataObject.Name;
		If Metadata.CommonModules.Find(ModuleName) <> Undefined Then
			Result.Insert(Enums.SMSProviders[MetadataObject.Name], Common.CommonModule(ModuleName));
		EndIf;
	EndDo;
	
	Return Result;
EndFunction

Function PrepareHTTPRequest(ResourceAddress, QueryParameters, PutParametersInQueryBody = True) Export
	
	Headers = New Map;
	
	If PutParametersInQueryBody Then
		Headers.Insert("Content-Type", "application/x-www-form-urlencoded");
	EndIf;
	
	SMSMessageSendingSettings = SMSMessageSendingSettings();
	If SMSMessageSendingSettings.AuthorizationMethod = "ByKey" Then
		Headers.Insert("Authorization", "Bearer" + " " + SMSMessageSendingSettings.Password);
	EndIf;
	
	If TypeOf(QueryParameters) = Type("String") Then
		ParametersString = QueryParameters;
	Else
		ParametersList = New Array;
		For Each Parameter In QueryParameters Do
			Values = Parameter.Value;
			If TypeOf(Parameter.Value) <> Type("Array") Then
				Values = CommonClientServer.ValueInArray(Parameter.Value);
			EndIf;
			
			For Each Value In Values Do
				ParametersList.Add(Parameter.Key + "=" + EncodeString(Value, StringEncodingMethod.URLEncoding));
			EndDo;
		EndDo;
		ParametersString = StrConcat(ParametersList, "&");
	EndIf;
	
	If Not PutParametersInQueryBody Then
		ResourceAddress = ResourceAddress + "?" + ParametersString;
	EndIf;

	HTTPRequest = New HTTPRequest(ResourceAddress, Headers);
	
	If PutParametersInQueryBody Then
		HTTPRequest.SetBodyFromString(ParametersString);
	EndIf;
	
	Return HTTPRequest;

EndFunction

Function DefaultProviderAuthorizationMethods()
	
	AuthorizationMethods = New Structure;
	
	AuthorizationFields = New ValueList;
	AuthorizationFields.Add("Username", NStr("ru = 'Логин'; en = 'Username'; pl = 'Login';de = 'Login';ro = 'Login';tr = 'Kullanıcı kodu'; es_ES = 'Nombre de usuario'"));
	AuthorizationFields.Add("Password", NStr("ru = 'Пароль'; en = 'Password'; pl = 'Hasło';de = 'Passwort';ro = 'Parola';tr = 'Şifre'; es_ES = 'Contraseña'"), True);
	
	AuthorizationMethods.Insert("ByUsernameAndPassword", AuthorizationFields);
	
	Return AuthorizationMethods;
	
EndFunction

Function SMSMessageSendingSettings() Export
	
	Result = New Structure("Username,Password,Provider,SenderName,AuthorizationMethod");
	
	If Common.SeparatedDataUsageAvailable() Then
		Owner = Common.MetadataObjectID("Constant.SMSProvider");
		ProviderSettings = Common.ReadDataFromSecureStorage(Owner, "Password,Username,SenderName,AuthorizationMethod");
		FillPropertyValues(Result, ProviderSettings);
		Result.Provider = Constants.SMSProvider.Get();
	EndIf;
	
	Return Result;
	
EndFunction

Function DefaultProviderSettings()
	
	Result = New Structure;
	Result.Insert("OnDefineAuthorizationMethods", False);
	Result.Insert("ServiceDetailsInternetAddress", "");
	Result.Insert("AuthorizationMethods", DefaultProviderAuthorizationMethods());
	
	Return Result;
	
EndFunction

Function ProviderSettings(Provider) Export
	
	ProviderSettings = DefaultProviderSettings();
	ModuleSMSMessageSendingViaProvider = ModuleSMSMessageSendingViaProvider(Provider);
	
	If ModuleSMSMessageSendingViaProvider <> Undefined Then
		ModuleSMSMessageSendingViaProvider.OnDefineSettings(ProviderSettings);
		If ProviderSettings.OnDefineAuthorizationMethods Then
			ModuleSMSMessageSendingViaProvider.OnDefineAuthorizationMethods(ProviderSettings.AuthorizationMethods);
		EndIf;
	EndIf;
	
	Return ProviderSettings;
	
EndFunction

#EndRegion
