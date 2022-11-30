///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not AccessRight("CollaborationSystemInfoBaseRegistration", Metadata) Then 
		Cancel = True;
		Return;
	EndIf;
	
	StatesContainer = New Structure;
	StatesContainer.Insert("CollaborationServer", "wss://1cdialog.com:443");
	StatesContainer.Insert("InfobaseName", Metadata.BriefInformation);
	StatesContainer.Insert("RegistrationState", CurrentRegistrationState());
	// Possible values:
	// "CreateAdministratorRequired"
	// "NotRegistered"
	// "Registered"
	// "WaitForConfirmationCodeInput"
	// "WaitForCollaborationServerResponse"
	
	OnChangeFormState(StatesContainer, ThisObject);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CreateAdministratorRequiredNoteURLProcessing(Item, 
	FormattedStringURL, StandardProcessing)
	
	Close();
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Register(Command)
	
	RegistrationState = StatesContainer.RegistrationState;
	
	If RegistrationState = "UnlockRequired" Then 
		OnUnlock();
	ElsIf RegistrationState = "NotRegistered" Then 
		OnReceiveRegistrationCode();
	ElsIf RegistrationState = "WaitForConfirmationCodeInput" Then 
		OnRegister();
	EndIf;
	
EndProcedure

&AtClient
Procedure Back(Command)
	
	RegistrationState = StatesContainer.RegistrationState;
	
	If RegistrationState = "WaitForConfirmationCodeInput" Then 
		OnRejectConfirmationCodeInput();
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

#Region PrivateEventHandlers

&AtClient
Procedure OnUnlock()
	
	ConversationsServiceServerCall.Unlock();
	
	StatesContainer.RegistrationState = "Registered";
	OnChangeFormState(StatesContainer, ThisObject);
	
	Notify("ConversationsEnabled", True);
	
	RefreshInterface();
	
EndProcedure

&AtClient
Procedure OnReceiveRegistrationCode()
	
	If IsBlankString(EmailAddress) Then 
		ShowMessageBox(, NStr("ru = 'Адрес электронной почты не заполнен'; en = 'Email address is not filled in'; pl = 'Email address is not filled in';de = 'Email address is not filled in';ro = 'Email address is not filled in';tr = 'Email address is not filled in'; es_ES = 'Email address is not filled in'"));
		Return;
	EndIf;
	
	If Not CommonClientServer.EmailAddressMeetsRequirements(EmailAddress) Then 
		ShowMessageBox(, NStr("ru = 'Адрес электронной почты содержит ошибки'; en = 'The email address contains errors.'; pl = 'The email address contains errors.';de = 'The email address contains errors.';ro = 'The email address contains errors.';tr = 'The email address contains errors.'; es_ES = 'The email address contains errors.'"));
		Return;
	EndIf;
	
	CollaborationServer = StatesContainer.CollaborationServer;
	
	RegistrationParameters = New CollaborationSystemInfoBaseRegistrationParameters;
	RegistrationParameters.ServerAddress = CollaborationServer;
	RegistrationParameters.Email = EmailAddress;
	
	Notification = New NotifyDescription("AfterReceiveRegistrationCodeSuccessfully", ThisObject,,
		"OnProcessGetRegistrationCodeError", ThisObject);
	CollaborationSystem.BeginInfoBaseRegistration(Notification, RegistrationParameters);
	
	StatesContainer.RegistrationState = "WaitForCollaborationServerResponse";
	OnChangeFormState(StatesContainer, ThisObject);
	
EndProcedure

&AtClient
Procedure AfterReceiveRegistrationCodeSuccessfully(RegistrationCompleted, MessageText, Context) Export
	
	ShowMessageBox(, MessageText);
	
	StatesContainer.RegistrationState = "WaitForConfirmationCodeInput";
	OnChangeFormState(StatesContainer, ThisObject);
	
EndProcedure

&AtClient
Procedure OnProcessGetRegistrationCodeError(ErrorInformation, StandardProcessing, Context) Export 
	
	StandardProcessing = False;
	ShowErrorInfo(ErrorInformation);
	
	StatesContainer.RegistrationState = "NotRegistered";
	OnChangeFormState(StatesContainer, ThisObject);
	
EndProcedure

&AtClient
Procedure OnRegister()
	
	If IsBlankString(RegistrationCode) Then 
		ShowMessageBox(, NStr("ru = 'Код регистрации не заполнен'; en = 'Registration code is required'; pl = 'Registration code is required';de = 'Registration code is required';ro = 'Registration code is required';tr = 'Registration code is required'; es_ES = 'Registration code is required'"));
		Return;
	EndIf;
	
	CollaborationServer  = StatesContainer.CollaborationServer;
	InfoBaseName = StatesContainer.InfobaseName;
	
	RegistrationParameters = New CollaborationSystemInfoBaseRegistrationParameters;
	RegistrationParameters.ServerAddress = CollaborationServer;
	RegistrationParameters.Email = EmailAddress;
	RegistrationParameters.InfoBaseName = InfoBaseName;
	RegistrationParameters.ActivationCode = TrimAll(RegistrationCode);
	
	Notification = New NotifyDescription("AfterRegisterSuccessfully", ThisObject,,
		"OnProcessRegistrationError", ThisObject);
	
	CollaborationSystem.BeginInfoBaseRegistration(Notification, RegistrationParameters);
	
	StatesContainer.RegistrationState = "WaitForCollaborationServerResponse";
	OnChangeFormState(StatesContainer, ThisObject);
	
EndProcedure

&AtClient
Procedure AfterRegisterSuccessfully(RegistrationCompleted, MessageText, Context) Export
	
	If RegistrationCompleted Then 
		Notify("ConversationsEnabled", True);
		StatesContainer.RegistrationState = "Registered";
	Else 
		ShowMessageBox(, MessageText);
		StatesContainer.RegistrationState = "WaitForConfirmationCodeInput";
	EndIf;
	
	OnChangeFormState(StatesContainer, ThisObject);
	
EndProcedure

&AtClient
Procedure OnProcessRegistrationError(ErrorInformation, StandardProcessing, Context) Export 
	
	StandardProcessing = False;
	ShowErrorInfo(ErrorInformation);
	
	StatesContainer.RegistrationState = "WaitForConfirmationCodeInput";
	OnChangeFormState(StatesContainer, ThisObject);
	
EndProcedure

&AtClient
Procedure OnRejectConfirmationCodeInput()
	
	Notification = New NotifyDescription("AfterConfirmRefuseToEnterConfirmationCode", ThisObject);
	ShowQueryBox(Notification, 
		NStr("ru = 'При отказе от ввода высланный на электронную почту код станет недействительным.
		           |Продолжение будет возможно только с запросом нового кода.'; 
		           |en = 'If not entered, the code sent to your email will be invalid.
		           |You can continue only after a new code is requested.'; 
		           |pl = 'If not entered, the code sent to your email will be invalid.
		           |You can continue only after a new code is requested.';
		           |de = 'If not entered, the code sent to your email will be invalid.
		           |You can continue only after a new code is requested.';
		           |ro = 'If not entered, the code sent to your email will be invalid.
		           |You can continue only after a new code is requested.';
		           |tr = 'If not entered, the code sent to your email will be invalid.
		           |You can continue only after a new code is requested.'; 
		           |es_ES = 'If not entered, the code sent to your email will be invalid.
		           |You can continue only after a new code is requested.'"), 
		QuestionDialogMode.OKCancel,, DialogReturnCode.Cancel);
	
EndProcedure

&AtClient
Procedure AfterConfirmRefuseToEnterConfirmationCode(QuestionResult, Context) Export 
	
	If QuestionResult = DialogReturnCode.OK Then 
		StatesContainer.RegistrationState = "NotRegistered";
		OnChangeFormState(StatesContainer, ThisObject);
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure OnChangeFormState(StatesContainer, ThisObject) 
	
	RegistrationState = StatesContainer.RegistrationState;
	
	If RegistrationState = "WaitForConfirmationCodeInput" Then
		ThisObject.RegistrationCode = "";
	EndIf;
	
	SetPage(StatesContainer, ThisObject);
	
	Items = ThisObject.Items;
	
	RefreshCommandBarButtonsVisibility(StatesContainer, 
		Items.Register, Items.Close, Items.Back);
	
EndProcedure

#EndRegion

#Region PresentationModel

&AtServerNoContext
Function CurrentRegistrationState()
	
	CurrentUser = InfoBaseUsers.CurrentUser();
	
	If IsBlankString(CurrentUser.Name) Then 
		Return "CreateAdministratorRequired";
	EndIf;
	
	If ConversationsService.Locked() Then 
		Return "UnlockRequired";
	EndIf;
	
	Return ?(CollaborationSystem.InfoBaseRegistered(),
		"Registered", "NotRegistered");
	
EndFunction

#EndRegion

#Region Presentations

&AtClientAtServerNoContext
Procedure SetPage(StatesContainer, ThisObject)
	
	RegistrationState = StatesContainer.RegistrationState;
	Items = ThisObject.Items;
	
	If RegistrationState = "CreateAdministratorRequired" Then 
		Items.Pages.CurrentPage = Items.CreateAdministratorRequired;
	ElsIf RegistrationState = "UnlockRequired" Then 
		Items.Pages.CurrentPage = Items.UnlockRequired;
	ElsIf RegistrationState = "NotRegistered" Then 
		Items.Pages.CurrentPage = Items.OfferRegistration;
	ElsIf RegistrationState = "WaitForConfirmationCodeInput" Then 
		Items.Pages.CurrentPage = Items.EnterRegistrationCode;
	ElsIf RegistrationState = "WaitForCollaborationServerResponse" Then
		Items.Pages.CurrentPage = Items.TimeConsumingOperation;
	ElsIf RegistrationState = "Registered" Then
		Items.Pages.CurrentPage = Items.RegistrationComplete;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure RefreshCommandBarButtonsVisibility(StatesContainer,
	Register, Close, Back)
	
	RegistrationState = StatesContainer.RegistrationState;
	
	If RegistrationState = "CreateAdministratorRequired" Then 
		Register.Visible = False;
		Back.Visible = False;
	ElsIf RegistrationState = "UnlockRequired" Then 
		Register.Visible = True;
		Register.Title = NStr("ru = 'Восстановить подключение'; en = 'Enable conversations'; pl = 'Enable conversations';de = 'Enable conversations';ro = 'Enable conversations';tr = 'Enable conversations'; es_ES = 'Enable conversations'");
		Back.Visible = False;
	ElsIf RegistrationState = "NotRegistered" Then 
		Register.Visible = True;
		Back.Visible = False;
	ElsIf RegistrationState = "WaitForConfirmationCodeInput" Then 
		Register.Visible = True;
		Back.Visible = True;
	ElsIf RegistrationState = "WaitForCollaborationServerResponse" Then 
		Register.Visible = False;
		Back.Visible = False;
	ElsIf RegistrationState = "Registered" Then 
		Register.Visible = False;
		Back.Visible = False;
		Close.DefaultButton = True;
		Close.Title = NStr("ru = 'Готово'; en = 'Finish'; pl = 'Finish';de = 'Finish';ro = 'Finish';tr = 'Finish'; es_ES = 'Finish'");
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion