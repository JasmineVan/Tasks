///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

&AtClient
Var ChoiceContext;

#EndRegion

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Prohibiting creation of new ones.
	If Not ValueIsFilled(Object.Ref) Then
		Cancel = True;
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	Interactions.SetEmailFormHeader(ThisObject);
	RestrictedExtensions = FilesOperationsInternal.DeniedExtensionsList();
	
	// Filling a selection list for the ReviewAfter field.
	Interactions.FillChoiceListForReviewAfter(Items.ReviewAfter.ChoiceList);
	If Reviewed Then
		Items.ReviewAfter.Enabled = False;
	EndIf;
	
	// StandardSubsystems.Properties
	If Common.SubsystemExists("StandardSubsystems.Properties") Then
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("ItemForPlacementName", "AdditionalAttributesPage");
		AdditionalParameters.Insert("DeferredInitialization", True);
		ModulePropertyManager = Common.CommonModule("PropertyManager");
		ModulePropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	EndIf;
	// End StandardSubsystems.Properties
	
	If Object.Ref.IsEmpty() Then
		Items.CommentPage.Picture = CommonClientServer.CommentPicture(Object.Comment);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	If CommonClient.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManagerClient = CommonClient.CommonModule("PropertyManagerClient");
		ModulePropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	EnableUnsafeContent = False;
	
	Interactions.SetInteractionFormAttributesByRegisterData(ThisObject);
	
	Attachments.Clear();
	AttachmentTable = EmailManagement.GetEmailAttachments(Object.Ref, True);
	
	If AttachmentTable.Count() > 0 Then
		
		FoundRows = AttachmentTable.FindRows(New Structure("EmailFileID", ""));
		CommonClientServer.SupplementTable(FoundRows, Attachments);
		
	EndIf;
	
	For Each DeletedAttachment In CurrentObject.PendingAttachments Do
		
		NewAttachment = Attachments.Add();
		NewAttachment.FileName = DeletedAttachment.NameAttachment;
		NewAttachment.PictureIndex = FilesOperationsInternalClientServer.GetFileIconIndex(".msg") + 1;
		
	EndDo;
	
	If Attachments.Count() = 0 Then
		
		Items.Attachments.Visible = False;
		
	EndIf;
	
	// Setting a text and its kind.
	If Object.TextType = Enums.EmailTextTypes.HTML Then
		ReadHTMLEmailText();
		Items.EmailText.Type = FormFieldType.HTMLDocumentField;
		Items.EmailText.ReadOnly = False;
	Else
		EmailText = Object.Text;
		Items.EmailText.Type = FormFieldType.TextDocumentField;
	EndIf;
	
	// Generating a sender presentation.
	SenderPresentation = InteractionsClientServer.GetAddresseePresentation(
		Object.SenderPresentation, Object.SenderAddress,"");
	
	// Generating the To and CC presentation.
	RecipientsPresentation =
		InteractionsClientServer.GetAddressesListPresentation(Object.EmailRecipients, False);
	CopiesRecipientsPresentation =
		InteractionsClientServer.GetAddressesListPresentation(Object.CCRecipients, False);
	ReplyRecipientsPresentation = 
		InteractionsClientServer.GetAddressesListPresentation(Object.ReplyRecipients, False);
		
	If IsBlankString(CopiesRecipientsPresentation) Then
		Items.CopiesRecipientsPresentation.Visible = False;
	EndIf;

	FillAdditionalInformation();
	
	ProcessReadReceiptNecessity();
	
	InteractionsClientServer.CheckContactsFilling(Object, ThisObject, "IncomingEmail");
	Items.CommentPage.Picture = CommonClientServer.CommentPicture(Object.Comment);
	
	// StandardSubsystems.Properties
	If Common.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManager = Common.CommonModule("PropertyManager");
		ModulePropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.AccessManagement

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// StandardSubsystems.Properties
	If CommonClient.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManagerClient = CommonClient.CommonModule("PropertyManagerClient");
		If ModulePropertyManagerClient.ProcessNofifications(ThisObject, EventName, Parameter) Then
			UpdateAdditionalAttributesItems();
			ModulePropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
		EndIf;
	EndIf;
	// End StandardSubsystems.Properties
	
	InteractionsClient.ProcessNotification(ThisObject, EventName, Parameter, Source);
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectedValue, ChoiceSource)
	
	If Upper(ChoiceSource.FormName) = Upper("CommonForm.ContactsClarification") Then
		
		If TypeOf(SelectedValue) <> Type("Array") Then
			Return;
		EndIf;
		
		FillClarifiedContacts(SelectedValue);
		ContactsChanged = True;
		Modified = True;
		
	Else
		
		InteractionsClient.ChoiceProcessingForm(ThisObject, SelectedValue, ChoiceSource, ChoiceContext);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteMode, PostingMode)
	
	Interactions.BeforeWriteInteractionFromForm(ThisObject, CurrentObject, ContactsChanged);
	
	If Reviewed AND ReceiptSendingFlagRequired Then
		SetNotificationSendingFlag(Object.Ref, True);
	EndIf;
	
	// StandardSubsystems.Properties
	If Common.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManager = Common.CommonModule("PropertyManager");
		ModulePropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	Interactions.OnWriteInteractionFromForm(CurrentObject, ThisObject);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	EndIf;
	// End StandardSubsystems.AccessManagement
	
	Items.CommentPage.Picture = CommonClientServer.CommentPicture(Object.Comment);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	If Common.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManager = Common.CommonModule("PropertyManager");
		ModulePropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PagesDetailsAdditionallyOnChangePage(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	If CommonClient.SubsystemExists("StandardSubsystems.Properties")
		AND CurrentPage.Name = "AdditionalAttributesPage"
		AND Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		ModulePropertyManagerClient = CommonClient.CommonModule("PropertyManagerClient");
		ModulePropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure ReviewAfterProcessSelection(Item, ValueSelected, StandardProcessing)
	
	InteractionsClient.ProcessSelectionInReviewAfterField(ReviewAfter,
	                                                          ValueSelected,
	                                                          StandardProcessing,
	                                                          Modified);
	
EndProcedure

&AtClient
Procedure ReviewedOnChange(Item)
	
	Items.ReviewAfter.Enabled = NOT Reviewed;
	If Reviewed AND ReadReceiptRequestRequired Then
		
		OnCloseNotifyHandler = New NotifyDescription("PromptForSendingReadReceiptAfterCompletion", ThisObject);
		ShowQueryBox(OnCloseNotifyHandler,
		       NStr("ru='Отправитель запросил уведомление о прочтении. Отправить?'; en = 'Sender requested read receipt. Send?'; pl = 'Sender requested read receipt. Send?';de = 'Sender requested read receipt. Send?';ro = 'Sender requested read receipt. Send?';tr = 'Sender requested read receipt. Send?'; es_ES = 'Sender requested read receipt. Send?'"),
		       QuestionDialogMode.YesNo,
		       ,
		       DialogReturnCode.Yes,
		       NStr("ru='Запрос уведомления'; en = 'Notification query'; pl = 'Notification query';de = 'Notification query';ro = 'Notification query';tr = 'Notification query'; es_ES = 'Notification query'"));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure EditRecipients()
	
	// Getting an addressee list
	SendersArray = New Array;
	SendersArray.Add(New Structure("Address,Presentation,Contact",
		Object.SenderAddress,
		Object.SenderPresentation, 
		Object.SenderContact));
	
	RecipientsList = New ValueList;
	RecipientsList.Add(SendersArray, "From");
	RecipientsList.Add(
		EmailManagementClient.ContactsTableToArray(Object.EmailRecipients), "To");
	RecipientsList.Add(
		EmailManagementClient.ContactsTableToArray(Object.CCRecipients),  "Cc");
	RecipientsList.Add(
		EmailManagementClient.ContactsTableToArray(Object.ReplyRecipients), "Response");
	
	FormParameters = New Structure;
	FormParameters.Insert("Account", Object.Account);
	FormParameters.Insert("SelectedItemsList", RecipientsList);
	FormParameters.Insert("Topic", Topic);
	FormParameters.Insert("Email", Object.Ref);
	
	// Opening a form to edit an addressee list.
	OpenForm("CommonForm.ContactsClarification", FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure FillClarifiedContacts(Result)
	
	Object.CCRecipients.Clear();
	Object.ReplyRecipients.Clear();
	Object.EmailRecipients.Clear();
	
	For each ArrayElement In Result Do
	
		If ArrayElement.Group = "To" Then
			RecipientsTable = Object.EmailRecipients;
		ElsIf ArrayElement.Group = "Cc" Then
			RecipientsTable = Object.CCRecipients;
		ElsIf ArrayElement.Group = "Response" Then
			RecipientsTable = Object.ReplyRecipients;
		ElsIf ArrayElement.Group = "From" Then
			Object.SenderAddress = ArrayElement.Address;
			Object.SenderContact = ArrayElement.Contact;
			Continue;
		Else
			Continue;
		EndIf;
		
		RowRecipients = RecipientsTable.Add();
		FillPropertyValues(RowRecipients,ArrayElement);
	
	EndDo;
	
	// Generating a sender presentation.
	SenderPresentation = InteractionsClientServer.GetAddresseePresentation(
		Object.SenderPresentation, Object.SenderAddress, "");
	
	// Generating the To and CC presentation.
	RecipientsPresentation       =
		InteractionsClientServer.GetAddressesListPresentation(Object.EmailRecipients, False);
	CopiesRecipientsPresentation  =
		InteractionsClientServer.GetAddressesListPresentation(Object.CCRecipients, False);
	ReplyRecipientsPresentation = 
		InteractionsClientServer.GetAddressesListPresentation(Object.ReplyRecipients, False);
	
	InteractionsClientServer.CheckContactsFilling(Object, ThisObject, "IncomingEmail");

EndProcedure

&AtClient
Procedure SenderPresentationOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	If ValueIsFilled(Object.SenderContact) Then
		ShowValue(, Object.SenderContact);
	Else
		EditRecipients();
	EndIf;
	
EndProcedure

&AtClient
Procedure EmailTextOnClick(Item, EventData, StandardProcessing)
	
	InteractionsClient.HTMLFieldOnClick(Item, EventData, StandardProcessing);
	
EndProcedure

&AtClient
Procedure SubjectStartChoice(Item, ChoiceData, StandardProcessing)
	
	InteractionsClient.SubjectStartChoice(ThisObject, Item, ChoiceData, StandardProcessing);
	
EndProcedure

&AtClient
Procedure WarningAboutUnsafeContentURLProcessing(Item, FormattedStringURL, StandardProcessing)
	If FormattedStringURL = "EnableUnsafeContent" Then
		StandardProcessing = False;
		EnableUnsafeContent = True;
		ReadHTMLEmailText();
	EndIf;
EndProcedure

#EndRegion

#Region AttachmentsFormTableItemsEventHandlers

&AtClient
Procedure AttachmentsChoice(Item, RowSelected, Field, StandardProcessing)
	
	OpenAttachment();
	
EndProcedure

&AtClient
Procedure AttachmentsOnActivateRow(Item)
	
	CurrentData = Items.Attachments.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	AttachmentExists = ValueIsFilled(CurrentData.Ref);
	Items.AttachmentsContextMenuAttachmentProperties.Enabled = AttachmentExists;
	Items.OpenAttachment.Enabled = AttachmentExists;
	Items.SaveAttachment.Enabled = AttachmentExists;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure OpenAttachmentExecute()
	
	OpenAttachment();
	
EndProcedure

&AtClient
Procedure SaveAttachmentExecute()
	
	CurrentData = Items.Attachments.CurrentData;
	
	If CurrentData <> Undefined Then
		
		If NOT ValueIsFilled(CurrentData.Ref) Then
			Return;
		EndIf;
		
		FileData = FilesOperationsClient.FileData(
			CurrentData.Ref, UUID);
		
		FilesOperationsClient.SaveFileAs(FileData);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SpecifyContacts(Command)
	
	EditRecipients();
	
EndProcedure

&AtClient
Procedure EmailParameters(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("Created",             Object.Date);
	FormParameters.Insert("ReceivedEmails",            Object.DateReceived);
	FormParameters.Insert("RequestDeliveryReceipt",  Object.RequestDeliveryReceipt);
	FormParameters.Insert("RequestReadReceipt", Object.RequestReadReceipt);
	FormParameters.Insert("InternetTitles",  Object.InternalTitle);
	FormParameters.Insert("Email",              Object.Ref);
	FormParameters.Insert("EmailType",           "IncomingEmail");
	FormParameters.Insert("Encoding",           Object.Encoding);
	FormParameters.Insert("InternalNumber",     Object.Number);
	FormParameters.Insert("Account",       Object.Account);
	
	OpenForm("DocumentJournal.Interactions.Form.EmailMessageParameters", FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure LinkedInteractionsExecute()
	
	FormParameters = New Structure;
	FormParameters.Insert("FilterObject", Object.Topic);
	
	OpenForm("DocumentJournal.Interactions.ListForm", FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure ChangeEncoding(Command)
	
	EncodingsList = EncodingsList();
	OnCloseNotifyHandler = New NotifyDescription("SelectEncodingAfterCompletion", ThisObject);
	EncodingsList.ShowChooseItem(OnCloseNotifyHandler,
		NStr("ru = 'Выберите кодировку'; en = 'Select encoding'; pl = 'Select encoding';de = 'Select encoding';ro = 'Select encoding';tr = 'Select encoding'; es_ES = 'Select encoding'"), EncodingsList.FindByValue(Lower(Object.Encoding)));
	
EndProcedure 

&AtClient
Procedure AttachmentProperties(Command)
	
	CurrentData = Items.Attachments.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If NOT ValueIsFilled(CurrentData.Ref) Then
		Return;
	EndIf;
	
	FormParameters = New Structure("AttachedFile, ReadOnly", CurrentData.Ref,True);
	OpenForm("DataProcessor.FilesOperations.Form.AttachedFile", FormParameters,, CurrentData.Ref);
	
EndProcedure

// StandardSubsystems.Properties

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	
	If CommonClient.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManagerClient = CommonClient.CommonModule("PropertyManagerClient");
		ModulePropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, URL = Undefined, StandardProcessing = Undefined)
	
	If CommonClient.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManagerClient = CommonClient.CommonModule("PropertyManagerClient");
		ModulePropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
	EndIf;
	
EndProcedure

// End StandardSubsystems.Properties

#EndRegion

#Region Private

&AtClient
Procedure OpenAttachment()
	
	CurrentData = Items.Attachments.CurrentData;
	
	If CurrentData <> Undefined Then
		
		If NOT ValueIsFilled(CurrentData.Ref) Then
			Return;
		EndIf;
		
		If InteractionsClientServer.IsFileEmail(CurrentData.FileName) Then
			
			AttachmentParameters = InteractionsClient.EmptyStructureOfAttachmentEmailParameters();
			AttachmentParameters.BaseEmailDate = Object.DateReceived;
			AttachmentParameters.EmailBasis     = Object.Ref;
			AttachmentParameters.BaseEmailSubject = Object.Subject;

			InteractionsClient.OpenAttachmentEmail(CurrentData.Ref, AttachmentParameters, ThisObject);
			
		Else
			
			EmailManagementClient.OpenAttachment(CurrentData.Ref, ThisObject);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure TransformEmailEncoding(SelectedEncoding)
	
	TempFileName = GetTempFileName();
	TextWriter = New TextWriter(TempFileName, Object.Encoding);
	TextWriter.Write(
		?(Object.TextType = Enums.EmailTextTypes.HTML, Object.HTMLText, Object.Text));
	TextWriter.Close();
	
	TextReader = New TextReader(TempFileName, SelectedEncoding);
	If Object.TextType = Enums.EmailTextTypes.HTML Then
		Object.HTMLText = TextReader.Read();
		EmailText = Object.HTMLText;
		Interactions.FilterHTMLTextContent(EmailText, SelectedEncoding, Not EnableUnsafeContent, HasUnsafeContent);
	Else
		Object.Text = TextReader.Read();
		EmailText = Object.Text;
	EndIf;
	TextReader.Close();
	DeleteFiles(TempFileName);
	
	TempFileName = GetTempFileName();
	TextWriter = New TextWriter(TempFileName, Object.Encoding);
	TextWriter.WriteLine(SenderPresentation);
	TextWriter.WriteLine(CopiesRecipientsPresentation);
	TextWriter.WriteLine(ReplyRecipientsPresentation);
	TextWriter.WriteLine(RecipientsPresentation);
	TextWriter.WriteLine(Object.Subject);
	TextWriter.Close();
	
	TextReader = New TextReader(TempFileName, SelectedEncoding);
	SenderPresentation = TextReader.ReadLine();
	CopiesRecipientsPresentation = TextReader.ReadLine();
	ReplyRecipientsPresentation = TextReader.ReadLine();
	RecipientsPresentation = TextReader.ReadLine();
	Object.Subject = TextReader.ReadLine();
	TextReader.Close();
	DeleteFiles(TempFileName);
	
	Object.Encoding = SelectedEncoding;
	
EndProcedure

&AtServer
Procedure FillAdditionalInformation()
	
	AdditionalInformationAboutEmail = NStr("ru = 'Создано:'; en = 'Created:'; pl = 'Created:';de = 'Created:';ro = 'Created:';tr = 'Created:'; es_ES = 'Created:'") + "   " + Object.Date 
	+ Chars.LF + NStr("ru = 'Получено'; en = 'ReceivedEmails'; pl = 'ReceivedEmails';de = 'ReceivedEmails';ro = 'ReceivedEmails';tr = 'ReceivedEmails'; es_ES = 'ReceivedEmails'") + ":  " + Object.DateReceived 
	+ Chars.LF + NStr("ru = 'Важность'; en = 'Importance'; pl = 'Importance';de = 'Importance';ro = 'Importance';tr = 'Importance'; es_ES = 'Importance'") + ":  " + Object.Importance
	+ Chars.LF + NStr("ru = 'Кодировка'; en = 'Encoding'; pl = 'Encoding';de = 'Encoding';ro = 'Encoding';tr = 'Encoding'; es_ES = 'Encoding'") + ": " + Object.Encoding;
	
EndProcedure

&AtServer
Procedure ProcessReadReceiptNecessity()
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ReadReceipts.Email
	|FROM
	|	InformationRegister.ReadReceipts AS ReadReceipts
	|WHERE
	|	ReadReceipts.Email = &Email
	|	AND (NOT ReadReceipts.SendingRequired)";
	
	Query.SetParameter("Email",Object.Ref);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	NecessaryAction = Interactions.GetUserParametersForIncomingEmail();
	
	If NecessaryAction = Enums.ReplyToReadReceiptPolicies.AlwaysSendReadReceipt Then
		
		ReceiptSendingFlagRequired = True;
		
	ElsIf NecessaryAction = 
		Enums.ReplyToReadReceiptPolicies.NeverSendReadReceipt Then
		
		EmailManagement.SetNotificationSendingFlag(Object.Ref,False);
		
	ElsIf NecessaryAction = 
		Enums.ReplyToReadReceiptPolicies.AskBeforeSendReadReceipt Then
		
		ReadReceiptRequestRequired = True;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure SetNotificationSendingFlag(Ref, Flag)

	EmailManagement.SetNotificationSendingFlag(Ref, Flag)

EndProcedure

&AtClient
Procedure PromptForSendingReadReceiptAfterCompletion(QuestionResult, AdditionalParameters) Export

	If QuestionResult = DialogReturnCode.Yes Then
		SetNotificationSendingFlag(Object.Ref, True);
	ElsIf QuestionResult = DialogReturnCode.No Then
		SetNotificationSendingFlag(Object.Ref, False);
	EndIf;
	ReadReceiptRequestRequired = False;
	
EndProcedure

&AtClient
Procedure SelectEncodingAfterCompletion(SelectedItem, AdditionalParameters) Export

	If SelectedItem <> Undefined Then
		TransformEmailEncoding(SelectedItem.Value);
	EndIf;

EndProcedure

// StandardSubsystems.Properties

&AtServer
Procedure PropertiesExecuteDeferredInitialization()
	
	If Common.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManager = Common.CommonModule("PropertyManager");
		ModulePropertyManager.FillAdditionalAttributesInForm(ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	
	If CommonClient.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManagerClient = CommonClient.CommonModule("PropertyManagerClient");
		ModulePropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	If Common.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManager = Common.CommonModule("PropertyManager");
		ModulePropertyManager.UpdateAdditionalAttributesItems(ThisObject);
	EndIf;
	
EndProcedure

// End StandardSubsystems.Properties

&AtClient
Function EncodingsList()
	
	EncodingsList = New ValueList;
	
	EncodingsList.Add("ibm852",       NStr("ru = 'ibm852 (Центральноевропейская DOS)'; en = 'ibm852 (Central European DOS)'; pl = 'ibm852 (Central European DOS)';de = 'ibm852 (Central European DOS)';ro = 'ibm852 (Central European DOS)';tr = 'ibm852 (Central European DOS)'; es_ES = 'ibm852 (Central European DOS)'"));
	EncodingsList.Add("ibm866",       NStr("ru = 'ibm866 (Кириллица DOS)'; en = 'ibm866 (Cyrillic DOS)'; pl = 'ibm866 (Cyrillic DOS)';de = 'ibm866 (Cyrillic DOS)';ro = 'ibm866 (Cyrillic DOS)';tr = 'ibm866 (Cyrillic DOS)'; es_ES = 'ibm866 (Cyrillic DOS)'"));
	EncodingsList.Add("iso-8859-1",   NStr("ru = 'iso-8859-1 (Западноевропейская ISO)'; en = 'iso-8859-1 (Western European ISO)'; pl = 'iso-8859-1 (Western European ISO)';de = 'iso-8859-1 (Western European ISO)';ro = 'iso-8859-1 (Western European ISO)';tr = 'iso-8859-1 (Western European ISO)'; es_ES = 'iso-8859-1 (Western European ISO)'"));
	EncodingsList.Add("iso-8859-2",   NStr("ru = 'iso-8859-2 (Центральноевропейская ISO)'; en = 'iso-8859-2 (Central European ISO)'; pl = 'iso-8859-2 (Central European ISO)';de = 'iso-8859-2 (Central European ISO)';ro = 'iso-8859-2 (Central European ISO)';tr = 'iso-8859-2 (Central European ISO)'; es_ES = 'iso-8859-2 (Central European ISO)'"));
	EncodingsList.Add("iso-8859-3",   NStr("ru = 'iso-8859-3 (Латиница 3 ISO)'; en = 'iso-8859-3 (Latin 3 ISO)'; pl = 'iso-8859-3 (Latin 3 ISO)';de = 'iso-8859-3 (Latin 3 ISO)';ro = 'iso-8859-3 (Latin 3 ISO)';tr = 'iso-8859-3 (Latin 3 ISO)'; es_ES = 'iso-8859-3 (Latin 3 ISO)'"));
	EncodingsList.Add("iso-8859-4",   NStr("ru = 'iso-8859-4 (Балтийская ISO)'; en = 'iso-8859-4 (Baltic ISO)'; pl = 'iso-8859-4 (Baltic ISO)';de = 'iso-8859-4 (Baltic ISO)';ro = 'iso-8859-4 (Baltic ISO)';tr = 'iso-8859-4 (Baltic ISO)'; es_ES = 'iso-8859-4 (Baltic ISO)'"));
	EncodingsList.Add("iso-8859-5",   NStr("ru = 'iso-8859-5 (Кириллица ISO)'; en = 'iso-8859-5 (Cyrillic ISO)'; pl = 'iso-8859-5 (Cyrillic ISO)';de = 'iso-8859-5 (Cyrillic ISO)';ro = 'iso-8859-5 (Cyrillic ISO)';tr = 'iso-8859-5 (Cyrillic ISO)'; es_ES = 'iso-8859-5 (Cyrillic ISO)'"));
	EncodingsList.Add("iso-8859-7",   NStr("ru = 'iso-8859-7 (Греческая ISO)'; en = 'iso-8859-7 (Greek ISO)'; pl = 'iso-8859-7 (Greek ISO)';de = 'iso-8859-7 (Greek ISO)';ro = 'iso-8859-7 (Greek ISO)';tr = 'iso-8859-7 (Greek ISO)'; es_ES = 'iso-8859-7 (Greek ISO)'"));
	EncodingsList.Add("iso-8859-9",   NStr("ru = 'iso-8859-9 (Турецкая ISO)'; en = 'iso-8859-9 (Turkish ISO)'; pl = 'iso-8859-9 (Turkish ISO)';de = 'iso-8859-9 (Turkish ISO)';ro = 'iso-8859-9 (Turkish ISO)';tr = 'iso-8859-9 (Turkish ISO)'; es_ES = 'iso-8859-9 (Turkish ISO)'"));
	EncodingsList.Add("iso-8859-15",  NStr("ru = 'iso-8859-15 (Латиница 9 ISO)'; en = 'iso-8859-15 (Latin 9 ISO)'; pl = 'iso-8859-15 (Latin 9 ISO)';de = 'iso-8859-15 (Latin 9 ISO)';ro = 'iso-8859-15 (Latin 9 ISO)';tr = 'iso-8859-15 (Latin 9 ISO)'; es_ES = 'iso-8859-15 (Latin 9 ISO)'"));
	EncodingsList.Add("koi8-r",       NStr("ru = 'koi8-r (Кириллица KOI8-R)'; en = 'koi8-r (Cyrillic KOI8-R)'; pl = 'koi8-r (Cyrillic KOI8-R)';de = 'koi8-r (Cyrillic KOI8-R)';ro = 'koi8-r (Cyrillic KOI8-R)';tr = 'koi8-r (Cyrillic KOI8-R)'; es_ES = 'koi8-r (Cyrillic KOI8-R)'"));
	EncodingsList.Add("koi8-u",       NStr("ru = 'koi8-u (Кириллица KOI8-U)'; en = 'koi8-u (Cyrillic KOI8-U)'; pl = 'koi8-u (Cyrillic KOI8-U)';de = 'koi8-u (Cyrillic KOI8-U)';ro = 'koi8-u (Cyrillic KOI8-U)';tr = 'koi8-u (Cyrillic KOI8-U)'; es_ES = 'koi8-u (Cyrillic KOI8-U)'"));
	EncodingsList.Add("us-ascii",     NStr("ru = 'us-ascii США'; en = 'us-ascii USA'; pl = 'us-ascii USA';de = 'us-ascii USA';ro = 'us-ascii USA';tr = 'us-ascii USA'; es_ES = 'us-ascii USA'"));
	EncodingsList.Add("utf-8",        NStr("ru = 'utf-8 (Юникод UTF-8)'; en = 'utf-8 (Unicode UTF-8)'; pl = 'utf-8 (Unicode UTF-8)';de = 'utf-8 (Unicode UTF-8)';ro = 'utf-8 (Unicode UTF-8)';tr = 'utf-8 (Unicode UTF-8)'; es_ES = 'utf-8 (Unicode UTF-8)'"));
	EncodingsList.Add("windows-1250", NStr("ru = 'windows-1250 (Центральноевропейская Windows)'; en = 'windows-1250 (Central European Windows)'; pl = 'windows-1250 (Central European Windows)';de = 'windows-1250 (Central European Windows)';ro = 'windows-1250 (Central European Windows)';tr = 'windows-1250 (Central European Windows)'; es_ES = 'windows-1250 (Central European Windows)'"));
	EncodingsList.Add("windows-1251", NStr("ru = 'windows-1251 (Кириллица Windows)'; en = 'windows-1251 (Cyrillic Windows)'; pl = 'windows-1251 (Cyrillic Windows)';de = 'windows-1251 (Cyrillic Windows)';ro = 'windows-1251 (Cyrillic Windows)';tr = 'windows-1251 (Cyrillic Windows)'; es_ES = 'windows-1251 (Cyrillic Windows)'"));
	EncodingsList.Add("windows-1252", NStr("ru = 'windows-1252 (Западноевропейская Windows)'; en = 'windows-1252 (Western European Windows)'; pl = 'windows-1252 (Western European Windows)';de = 'windows-1252 (Western European Windows)';ro = 'windows-1252 (Western European Windows)';tr = 'windows-1252 (Western European Windows)'; es_ES = 'windows-1252 (Western European Windows)'"));
	EncodingsList.Add("windows-1253", NStr("ru = 'windows-1253 (Греческая Windows)'; en = 'windows-1253 (Greek Windows)'; pl = 'windows-1253 (Greek Windows)';de = 'windows-1253 (Greek Windows)';ro = 'windows-1253 (Greek Windows)';tr = 'windows-1253 (Greek Windows)'; es_ES = 'windows-1253 (Greek Windows)'"));
	EncodingsList.Add("windows-1254", NStr("ru = 'windows-1254 (Турецкая Windows)'; en = 'windows-1254 (Turkish Windows)'; pl = 'windows-1254 (Turkish Windows)';de = 'windows-1254 (Turkish Windows)';ro = 'windows-1254 (Turkish Windows)';tr = 'windows-1254 (Turkish Windows)'; es_ES = 'windows-1254 (Turkish Windows)'"));
	EncodingsList.Add("windows-1257", NStr("ru = 'windows-1257 (Балтийская Windows)'; en = 'windows-1257 (Baltic Windows)'; pl = 'windows-1257 (Baltic Windows)';de = 'windows-1257 (Baltic Windows)';ro = 'windows-1257 (Baltic Windows)';tr = 'windows-1257 (Baltic Windows)'; es_ES = 'windows-1257 (Baltic Windows)'"));
	
	Return EncodingsList;

EndFunction

&AtServer
Procedure SetSecurityWarningVisiblity()
	UnsafeContentDisplayInEmailsProhibited = Interactions.UnsafeContentDisplayInEmailsProhibited();
	Items.SecurityWarning.Visible = Not UnsafeContentDisplayInEmailsProhibited
		AND HasUnsafeContent AND Not EnableUnsafeContent;
EndProcedure

&AtServer
Procedure ReadHTMLEmailText()
	EmailText = Interactions.ProcessHTMLText(Object.Ref, Not EnableUnsafeContent, HasUnsafeContent);
	SetSecurityWarningVisiblity();
EndProcedure

#EndRegion
