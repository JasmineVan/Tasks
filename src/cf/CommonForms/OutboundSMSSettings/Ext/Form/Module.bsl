///////////////////////////////////////////////////////////////////////////////////////////////////////
// ;Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetPrivilegedMode(True);
	SMSMessageSendingSettings = SendSMSMessage.SMSMessageSendingSettings();
	SetPrivilegedMode(False);
	
	ProviderSettings = SendSMSMessage.ProviderSettings(SMSMessageSendingSettings.Provider);
	FillAuthorizationMethods(ThisObject);
	
	If SMSMessageSendingSettings.Property("AuthorizationMethod")
		AND ValueIsFilled(SMSMessageSendingSettings.AuthorizationMethod)
		AND Items.AuthorizationMethod.ChoiceList.FindByValue(SMSMessageSendingSettings.AuthorizationMethod) <> Undefined Then
		
		AuthorizationMethod = SMSMessageSendingSettings.AuthorizationMethod;
	EndIf;
	
	SetAuthorizationFields(ThisObject);
	
	SMSMessageSenderUsername = SMSMessageSendingSettings.Username;
	SenderName = SMSMessageSendingSettings.SenderName;
	SMSMessageSenderPassword = SMSMessageSendingSettings.Password;
	
	If Items.Password.PasswordMode Then
		SMSMessageSenderPassword = ?(ValueIsFilled(SMSMessageSendingSettings.Password), ThisObject.UUID, "");
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	RefreshReusableValues();
	Notify("Write_SMSSendingSettings", WriteParameters, ThisObject);
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	SetPrivilegedMode(True);
	Owner = Common.MetadataObjectID("Constant.SMSProvider");
	If SMSMessageSenderPassword <> String(ThisObject.UUID) Then
		Common.WriteDataToSecureStorage(Owner, SMSMessageSenderPassword);
	EndIf;
	Common.WriteDataToSecureStorage(Owner, SMSMessageSenderUsername, "Username");
	Common.WriteDataToSecureStorage(Owner, SenderName, "SenderName");
	Common.WriteDataToSecureStorage(Owner, AuthorizationMethod, "AuthorizationMethod");
	SetPrivilegedMode(False);
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SMSMessageProviderOnChange(Item)
	
	ProviderSettings = ProviderSettings(ConstantsSet.SMSProvider);
	
	FillAuthorizationMethods(ThisObject);
	SetAuthorizationFields(ThisObject);
	
	SMSMessageSenderUsername = "";
	SMSMessageSenderPassword = "";
	SenderName = "";
	
EndProcedure

&AtClient
Procedure AuthorizationMethodOnChange(Item)
	
	SMSMessageSenderUsername = "";
	SMSMessageSenderPassword = "";
	
	SetAuthorizationFields(ThisObject);
	
EndProcedure

&AtClient
Procedure ServiceDetailsClick(Item)
	InternetAddress = ProviderSettings.ServiceDetailsInternetAddress;
	SendSMSMessagesClientOverridable.OnGetProviderInternetAddress(ConstantsSet.SMSProvider, InternetAddress);
	If Not IsBlankString(InternetAddress) Then
		FileSystemClient.OpenURL(InternetAddress);
	EndIf;
EndProcedure

&AtServerNoContext
Function ProviderSettings(Provider)
	
	Return SendSMSMessage.ProviderSettings(Provider);
	
EndFunction

&AtClientAtServerNoContext
Procedure SetAuthorizationFields(Form)
	
	AuthorizationFields = Form.ProviderSettings.AuthorizationMethods[Form.AuthorizationMethod];
	
	For Each FieldName In StrSplit("Username,Password", ",") Do
		Field = AuthorizationFields.FindByValue(FieldName);
		If Field <> Undefined Then
			Form.Items[FieldName].Title = Field.Presentation;
		EndIf;
		
		Form.Items[FieldName].Visible = Field <> Undefined;
		
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillAuthorizationMethods(Form)
	
	Form.Items.AuthorizationMethod.ChoiceList.Clear();
	
	DefaultAuthorizationMethods = New ValueList;
	DefaultAuthorizationMethods.Add("ByKey", NStr("ru = 'По ключу (рекомендуется)'; en = 'By key (recommended)'; pl = 'Wg klucza (zalecane)';de = 'Per Schlüssel (empfohlen)';ro = 'După cheie (recomandat)';tr = 'Anahtar (önerilen)'; es_ES = 'Por clave (se recomienda)'"));
	DefaultAuthorizationMethods.Add("ByUsernameAndPassword", NStr("ru = 'По логину и паролю'; en = 'By username and password'; pl = 'Wg logina i hasła';de = 'Mit Login und Passwort';ro = 'După login și parolă';tr = 'Giriş ve şifre ile'; es_ES = 'Por nombre y contraseña'"));
	
	For Each Item In DefaultAuthorizationMethods Do
		If Form.ProviderSettings.AuthorizationMethods.Property(Item.Value) Then
			Form.Items.AuthorizationMethod.ChoiceList.Add(Item.Value, Item.Presentation);
		EndIf;
	EndDo;
	
	Form.AuthorizationMethod = Form.Items.AuthorizationMethod.ChoiceList[0].Value;
	Form.Items.AuthorizationMethod.Visible = Form.Items.AuthorizationMethod.ChoiceList.Count() > 1;
	
EndProcedure

#EndRegion
