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
	
	Topic            = Parameters.Topic;
	MessageKind       = Parameters.MessageKind;
	ChoiceMode        = Parameters.ChoiceMode;
	TemplateOwner    = Parameters.TemplateOwner;
	MessageParameters = Parameters.MessageParameters;
	PrepareTemplate  = Parameters.PrepareTemplate;
	
	If ValueIsFilled(Topic) AND TypeOf(Topic) <> Type("String") Then
		FullBasisTypeName = Topic.Metadata().FullName();
	EndIf;
	
	If MessageKind = "SMSMessage" Then
		ForSMSMessages = True;
		ForEmails = False;
		Title = NStr("ru = 'Шаблоны сообщений SMS'; en = 'SMS templates'; pl = 'SMS templates';de = 'SMS templates';ro = 'SMS templates';tr = 'SMS templates'; es_ES = 'SMS templates'");
	Else
		ForSMSMessages = False;
		ForEmails = True;
	EndIf;
	
	If NOT AccessRight("Update", Metadata.Catalogs.MessageTemplates) Then
		HasUpdateRight = False;
		Items.FormChange.Visible = False;
		Items.FormCreate.Visible  = False;
	Else
		HasUpdateRight = True;
	EndIf;
	
	If ChoiceMode Then
		Items.FormGenerateAndSend.Visible = False;
		Items.FormGenerate.Title = NStr("ru='Выбрать'; en = 'Select'; pl = 'Select';de = 'Select';ro = 'Select';tr = 'Select'; es_ES = 'Select'");
	ElsIf PrepareTemplate Then
		Items.FormGenerateAndSend.Visible = False;
	EndIf;
	
	FillAvailableTemplatesList();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If EventName = "Write_MessagesTemplates" Then
		SelectedItemRef = Undefined;
		If Items.Templates.CurrentData <> Undefined Then
			SelectedItemRef = Items.Templates.CurrentData.Ref;
		EndIf;
		FillAvailableTemplatesList();
		FoundRows = Templates.FindRows(New Structure("Ref", SelectedItemRef));
		If FoundRows.Count() > 0 Then
			Items.Templates.CurrentRow = FoundRows[0].GetID();
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If NOT ShowTemplatesChoiceForm Then
		SendOptions = SendOptionsConstructor();
		SendOptions.AdditionalParameters.ConvertHTMLForFormattedDocument = False;
		GenerateMessageToSend(SendOptions);
	EndIf;
	
EndProcedure

#EndRegion

#Region TemplatesFormTableItemsEventHandlers

&AtClient
Procedure TemplatesBeforeAddRow(Item, Cancel, Clone, Parent, Folder, Parameter)
	Cancel = True;
	If Clone AND NOT Folder Then
		CreateNewTemplate(Item.CurrentData.Ref);
	Else
		CreateNewTemplate();
	EndIf;
EndProcedure

&AtClient
Procedure TemplatesBeforeDeleteRow(Item, Cancel)
	Cancel = True;
EndProcedure

&AtClient
Procedure TemplatesOnActivateRow(Item)
	If Item.CurrentData <> Undefined Then
		Items.FormGenerateAndSend.Enabled = (Item.CurrentData.Name <> "<NoTemplate>");
		If Item.CurrentData.MailTextType = PredefinedValue("Enum.EmailEditingMethods.HTML") Then
			Items.PreviewPages.CurrentPage = Items.FormattedDocumentPage;
			AttachIdleHandler("UpdatePreviewData", 0.2, True);
		Else
			Items.PreviewPages.CurrentPage = Items.PlainTextPage;
			PreviewPlainText.SetText(Item.CurrentData.TemplateText);
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure TemplatesBeforeChangeStart(Item, Cancel)
	Cancel = True;
	If Item.CurrentData <> Undefined Then
		FormParameters = New Structure("Key", Item.CurrentData.Ref);
		OpenForm("Catalog.MessageTemplates.ObjectForm", FormParameters);
	EndIf;
EndProcedure

&AtClient
Procedure TemplatesChoice(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	GenerateMessageFromSelectedTemplate();
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Generate(Command)
	
	GenerateMessageFromSelectedTemplate();
	
EndProcedure

&AtClient
Procedure GenerateAndSend(Command)
	
	CurrentData = Templates.FindByID(Items.Templates.CurrentRow);
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	SendOptions = SendOptionsConstructor(CurrentData.Ref);
	SendOptions.AdditionalParameters.SendImmediately = True;
	If CurrentData.HasArbitraryParameters Then
		ParametersInput(CurrentData.Ref, SendOptions, True);
	Else
		SendMessage(SendOptions);
	EndIf;
	
EndProcedure

&AtClient
Procedure Create(Command)
	CreateNewTemplate();
EndProcedure

&AtClient
Procedure ParametersInput(Template, SendOptions, SendImmediately)
	
	ParametersToFill = New Structure("Template, Topic", Template, Topic);
	
	Notification = New NotifyDescription("AfterParametersInput", ThisObject, SendOptions);
	OpenForm("Catalog.MessageTemplates.Form.FillArbitraryParameters", ParametersToFill,,,,, Notification);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure GenerateMessageFromSelectedTemplate()
	
	CurrentData = Templates.FindByID(Items.Templates.CurrentRow);
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If ChoiceMode Then
		Close(CurrentData.Ref);
		Return;
	EndIf;
	
	SendOptions = SendOptionsConstructor(CurrentData.Ref);
	SendOptions.AdditionalParameters.ConvertHTMLForFormattedDocument = True;
	
	If CurrentData.HasArbitraryParameters Then
		ParametersInput(CurrentData.Ref, SendOptions, False);
	Else
		GenerateMessageToSend(SendOptions);
	EndIf;
	
EndProcedure

&AtClient
Procedure GenerateMessageToSend(SendOptions)
	
	TempStorageAddress = Undefined;
	TempStorageAddress = PutToTempStorage(Undefined, UUID);
	
	ResultAddress = GenerateMessageAtServer(TempStorageAddress, SendOptions, MessageKind);
	
	Result = GetFromTempStorage(ResultAddress);
	
	Result.Insert("Topic", Topic);
	Result.Insert("Template",  SendOptions.Template);
	If SendOptions.AdditionalParameters.Property("MessageParameters")
		AND TypeOf(SendOptions.AdditionalParameters.MessageParameters) = Type("Structure") Then
		CommonClientServer.SupplementStructure(Result, MessageParameters, False);
	EndIf;
	
	If SendOptions.AdditionalParameters.SendImmediately Then
		AfterGenerateAndSendMessage(Result, SendOptions);
	Else
		If PrepareTemplate Then
			Close(Result);
		Else
			Close();
			ShowMessageForm(Result);
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Function GenerateMessageAtServer(TempStorageAddress, SendOptions, MessageKind)
	
	ServerCallParameters = New Structure();
	ServerCallParameters.Insert("SendOptions", SendOptions);
	ServerCallParameters.Insert("MessageKind",      MessageKind);
	If Common.SubsystemExists("StandardSubsystems.Interactions") Then
		ModuleInteractions = Common.CommonModule("Interactions");
		SendOptions.AdditionalParameters.Insert("ExtendedRecipientsList", ModuleInteractions.OtherInteractionsUsed());
	EndIf;
	
	MessageTemplatesInternal.GenerateMessageInBackground(ServerCallParameters, TempStorageAddress);
	
	Return TempStorageAddress;
	
EndFunction

&AtClient
Procedure AfterParametersInput(Result, SendOptions) Export
	
	If Result <> Undefined AND Result <> DialogReturnCode.Cancel Then
		SendOptions.AdditionalParameters.ArbitraryParameters = Result;
		GenerateMessageToSend(SendOptions);
	EndIf;
	
EndProcedure

&AtClient
Procedure SendMessage(Val MessageSendOptions)
	
	If MessageKind = "Email" Then
		If CommonClient.SubsystemExists("StandardSubsystems.EmailOperations") Then
			NotifyDescription = New NotifyDescription("SendMessageAccountCheckCompleted", ThisObject, MessageSendOptions);
			ModuleEmailOperationsClient = CommonClient.CommonModule("EmailOperationsClient");
			ModuleEmailOperationsClient.CheckAccountForSendingEmailExists(NotifyDescription);
		EndIf;
	Else
		GenerateMessageToSend(MessageSendOptions);
	EndIf;
	
EndProcedure

&AtClient
Procedure SendMessageAccountCheckCompleted(AccountSetUp, SendOptions) Export
	
	If AccountSetUp = True Then
		GenerateMessageToSend(SendOptions);
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterGenerateAndSendMessage(Result, SendOptions)
	
	If Result.Sent Then;
		Close();
	Else
		Notification = New NotifyDescription("AfterQuestionOnOpenMessageForm", ThisObject, SendOptions);
		ErrorDescription = Result.ErrorDescription + Chars.LF + NStr("ru = 'Открыть форму отправки сообщения?'; en = 'Open message sending form?'; pl = 'Open message sending form?';de = 'Open message sending form?';ro = 'Open message sending form?';tr = 'Open message sending form?'; es_ES = 'Open message sending form?'");
		ShowQueryBox(Notification, ErrorDescription, QuestionDialogMode.YesNo);
	EndIf;

EndProcedure

&AtClient
Procedure ShowMessageForm(Message)
	
	If MessageKind = "SMSMessage" Then
		If CommonClient.SubsystemExists("StandardSubsystems.SendSMSMessage") Then 
			ModuleSMSClient= CommonClient.CommonModule("SMSClient");
			
			AdditionalParameters = New Structure("Transliterate");
			
			If Message.AdditionalParameters <> Undefined Then
				FillPropertyValues(AdditionalParameters, Message.AdditionalParameters);
			EndIf;
			
			AdditionalParameters.Transliterate = ?(Message.AdditionalParameters.Property("Transliterate"),
				Message.AdditionalParameters.Transliterate, False);
			AdditionalParameters.Insert("Topic", Topic);
			Text      = ?(Message.Property("Text"), Message.Text, "");
			
			Recipient = New Array;
			IsValueList = (TypeOf(Message.Recipient) = Type("ValueList"));
			
			For each RecipientInfo In Message.Recipient Do
				If IsValueList Then
					Phone                      = RecipientInfo.Value;
					ContactInformationSource = "";
				Else 
					Phone                      = RecipientInfo.PhoneNumber;
					ContactInformationSource = RecipientInfo.ContactInformationSource ;
				EndIf;
				
				RecipientData = New Structure();
				RecipientData.Insert("Presentation",                RecipientInfo.Presentation);
				RecipientData.Insert("Phone",                      Phone);
				RecipientData.Insert("ContactInformationSource", ContactInformationSource);
				Recipient.Add(RecipientData);
				
			EndDo;
			
			ModuleSMSClient.SendSMSMessage(Recipient, Text, AdditionalParameters);
		EndIf;
	Else
		If CommonClient.SubsystemExists("StandardSubsystems.EmailOperations") Then
			ModuleEmailOperationsClient = CommonClient.CommonModule("EmailOperationsClient");
			ModuleEmailOperationsClient.CreateNewEmailMessage(Message);
		EndIf;
	EndIf;
	
	If Message.Property("UserMessages")
		AND Message.UserMessages <> Undefined
		AND Message.UserMessages.Count() > 0 Then
			For each UserMessages In Message.UserMessages Do
				CommonClient.MessageToUser(UserMessages.Text,
					UserMessages.DataKey, UserMessages.Field, UserMessages.DataPath);
			EndDo;
	EndIf;
	
EndProcedure

&AtClient
Function SendOptionsConstructor(Template = Undefined)
	
	SendOptions = MessageTemplatesClientServer.SendOptionsConstructor(Template, Topic, UUID);
	SendOptions.AdditionalParameters.MessageKind       = MessageKind;
	SendOptions.AdditionalParameters.MessageParameters = MessageParameters;
	
	Return SendOptions;
	
EndFunction

&AtClient
Procedure AfterQuestionOnOpenMessageForm(Result, SendOptions) Export
	If Result = DialogReturnCode.Yes Then
		SendOptions.AdditionalParameters.SendImmediately                                  = False;
		SendOptions.AdditionalParameters.ConvertHTMLForFormattedDocument = True;
		GenerateMessageToSend(SendOptions);
	EndIf;
EndProcedure

&AtClient
Procedure CreateNewTemplate(CopyingValue = Undefined)
	
	FormParameters = New Structure();
	FormParameters.Insert("MessageKind"          , MessageKind);
	FormParameters.Insert("FullBasisTypeName",
		?(ValueIsFilled(FullBasisTypeName), FullBasisTypeName, Topic));
	FormParameters.Insert("AvailableToAuthorOnly",        True);
	FormParameters.Insert("TemplateOwner",        TemplateOwner);
	FormParameters.Insert("CopyingValue",    CopyingValue);
	FormParameters.Insert("New",                  True);
	
	OpenForm("Catalog.MessageTemplates.ObjectForm", FormParameters, ThisObject);
	
EndProcedure

&AtServer
Procedure FillAvailableTemplatesList()
	
	Templates.Clear();
	TemplateType = ?(ForSMSMessages, "SMS", "Email");
	Query = MessageTemplatesInternal.PrepareQueryToGetTemplatesList(TemplateType, Topic, TemplateOwner);
	
	QueryResult = Query.Execute().Select();
		
	While QueryResult.Next() Do
		NewRow = Templates.Add();
		FillPropertyValues(NewRow, QueryResult);
		
		If QueryResult.TemplateByExternalDataProcessor
			AND Common.SubsystemExists("StandardSubsystems.AdditionalReportsAndDataProcessors") Then
				ModuleAdditionalReportsAndDataProcessors = Common.CommonModule("AdditionalReportsAndDataProcessors");
				ExternalObject = ModuleAdditionalReportsAndDataProcessors.ExternalDataProcessorObject(QueryResult.ExternalDataProcessor);
				TemplateParameters = ExternalObject.TemplateParameters();
				
				If TemplateParameters.Count() > 1 Then
					HasArbitraryParameters = True;
				Else
					HasArbitraryParameters = False;
				EndIf;
		Else
			ArbitraryParameters = QueryResult.HasArbitraryParameters.Unload();
			HasArbitraryParameters = ArbitraryParameters.Count() > 0;
		EndIf;
		
		NewRow.HasArbitraryParameters = HasArbitraryParameters;
	EndDo;
	
	If Templates.Count() = 0 Then
		MessagesTemplatesSettings = MessagesTemplatesInternalCachedModules.OnDefineSettings();
		ShowTemplatesChoiceForm = MessagesTemplatesSettings.AlwaysShowTemplatesChoiceForm;
	Else
		ShowTemplatesChoiceForm = True;
	EndIf;
	
	Templates.Sort("Presentation");
	
	If NOT ChoiceMode AND NOT PrepareTemplate Then
		FirstRow = Templates.Insert(0);
		FirstRow.Name = "<NoTemplate>";
		FirstRow.Presentation = NStr("ru = '<Без шаблона>'; en = '<No template>'; pl = '<No template>';de = '<No template>';ro = '<No template>';tr = '<No template>'; es_ES = '<No template>'");
	EndIf;
	
	If Templates.Count() = 0 Then
		Items.FormCreate.OnlyInAllActions = False;
		Items.FormCreate.Representation = ButtonRepresentation.PictureAndText;
		Items.FormGenerate.Enabled           = False;
		Items.FormGenerateAndSend.Enabled = False;
	Else
		Items.FormGenerate.Enabled           = True;
		Items.FormGenerateAndSend.Enabled = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdatePreviewData()
	CurrentData = Items.Templates.CurrentData;
	If CurrentData <> Undefined Then
		SetHTMLInFormattedDocument(CurrentData.TemplateText, CurrentData.Ref);
	EndIf;
EndProcedure

&AtServer
Procedure SetHTMLInFormattedDocument(HTMLEmailTemplateText, CurrentObjectRef);
	
	TemplateParameter = New Structure("Template, UUID");
	TemplateParameter.Template = CurrentObjectRef;
	TemplateParameter.UUID = UUID;
	Message = MessageTemplatesInternal.MessageConstructor();
	Message.Text = HTMLEmailTemplateText;
	MessageTemplatesInternal.ProcessHTMLForFormattedDocument(TemplateParameter, Message, True);
	AttachmentsStructure = New Structure();
	For each HTMLAttachment In Message.Attachments Do
		Picture = New Picture(GetFromTempStorage(HTMLAttachment.AddressInTempStorage));
		AttachmentsStructure.Insert(HTMLAttachment.Presentation, Picture);
	EndDo;
	PreviewFormattedDocument.SetHTML(Message.Text, AttachmentsStructure);
	
EndProcedure

#EndRegion