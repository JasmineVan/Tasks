///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// The procedure is called from document filling data handlers - interactions and filling objects.
// Fills in attributes with default values.
//
// Parameters:
//  Object - DocumentObject - a document to be filled.
//  FillingData - Arbitrary - a value used as a filling base.
//
Procedure FillDefaultAttributes(Object, FillingData) Export
	
	IsInteraction = InteractionsClientServer.IsInteraction(Object.Ref);
	
	// The current user is the author and the person responsible for the interaction being created.
	If IsInteraction Then
		Object.Author = Users.CurrentUser();
		Object.EmployeeResponsible = Object.Author;
	EndIf;
	
	If FillingData = Undefined Then
		Return;
	EndIf;
	
	Contacts = Undefined;
	
	If IsContact(FillingData) AND Not FillingData.IsFolder Then
		// Based on contact
		Contacts = New Array;
		Contacts.Add(FillingData);
		
	ElsIf InteractionsClientServer.IsSubject(FillingData) Then
		// Based on subject
		ObjectManager = Common.ObjectManagerByRef(FillingData);
		Contacts = ObjectManager.GetContacts(FillingData);
		
	ElsIf InteractionsClientServer.IsInteraction(FillingData) Then
		// Based on interaction.
		ObjectManager = Common.ObjectManagerByRef(FillingData);
		Contacts = ObjectManager.GetContacts(FillingData);
		
	ElsIf TypeOf(FillingData) = Type("Structure") Then
		// Filling in a contact
		If FillingData.Property("Contact") AND ValueIsFilled(FillingData.Contact) Then
			Contacts = New Array;
			Contacts.Add(FillingData.Contact);
		EndIf;
		If FillingData.Property("Topic") AND ValueIsFilled(FillingData.Topic) Then
			ObjectManager = Common.ObjectManagerByRef(FillingData.Topic);
			If NOT (FillingData.Property("Contact") AND ValueIsFilled(FillingData.Contact)) Then
				Contacts = ObjectManager.GetContacts(FillingData.Topic);
			EndIf;
		EndIf;
		
	EndIf;
	
	// Filling in participants
	If ValueIsFilled(Contacts) AND (Contacts.Count() > 0) Then
		
		If TypeOf(Object) = Type("DocumentObject.PhoneCall")
			Or TypeOf(Object) = Type("DocumentObject.SMSMessage") Then
			
			ClearAddressRequired = False;
			
			If (TypeOf(FillingData) = Type("DocumentRef.IncomingEmail")
				Or TypeOf(FillingData) = Type("DocumentRef.OutgoingEmail")) Then
				
				ClearAddressRequired = True;
				
			EndIf;
			
			If TypeOf(FillingData) = Type("Structure")
				AND FillingData.Property("Topic")
				AND (TypeOf(FillingData.Topic) = Type("DocumentRef.IncomingEmail")
					Or TypeOf(FillingData.Topic) = Type("DocumentRef.OutgoingEmail")) Then
					
				ClearAddressRequired = True;
				
			EndIf;
			
			If ClearAddressRequired Then
			
				For Each RowContact In Contacts Do
					
					If TypeOf(RowContact) = Type("Structure") Then
						
						If Not ValueIsFilled(RowContact.Contact) Then
							RowContact.Address = "";
						EndIf;
						
					EndIf;
					
				EndDo;
			
			EndIf;
			
		EndIf;
		
		Object.FillContacts(Contacts);
		
	EndIf;
	
EndProcedure

// Sets the created object as a subject in the interaction chain.
// Parameters:
//  Subject - ObjectRef - a created interaction subject.
//  Interaction - DocumentRef - an interaction the subject is created by.
//  Cancel - Boolean - an operation cancellation flag.
//
Procedure OnWriteSubjectFromForm(Topic, Interaction, Cancel) Export
	
	If Not ValueIsFilled(Interaction)
		Or Not InteractionsClientServer.IsInteraction(Interaction) Then
		Return;
	EndIf;
	
	OldSubject = GetSubjectValue(Interaction);
	If Topic = OldSubject Then
		// The subject has already been set
		Return;
	EndIf;
	
	// Getting the list of interactions whose subject requires changing.
	If ValueIsFilled(OldSubject)
		AND InteractionsClientServer.IsInteraction(OldSubject) Then
		ArrayReplace = InteractionsFromChain(OldSubject, Interaction);
	Else
		ArrayReplace = New Array;
	EndIf;
	ArrayReplace.Insert(0, Interaction);
	
	// Replacing a subject in all interactions.
	
	For Each Item In ArrayReplace Do
		Try
			SetSubject(Item, Topic);
		Except
			ErrorPresentation = BriefErrorDescription(ErrorInfo());
			Common.MessageToUser(StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Ошибка при замене предмета у %1: %2'; en = 'An error occurred when replacing subject from %1: %2'; pl = 'An error occurred when replacing subject from %1: %2';de = 'An error occurred when replacing subject from %1: %2';ro = 'An error occurred when replacing subject from %1: %2';tr = 'An error occurred when replacing subject from %1: %2'; es_ES = 'An error occurred when replacing subject from %1: %2'"), Item, ErrorPresentation), , , , Cancel);
			Cancel = True;
			Return;
		EndTry;
	EndDo;
	
EndProcedure

// Prepares a notification when creating an interaction document on the server.
// Parameters:
//  Form - ManagedForm - a form the notification will be sent from.
//  Parameters - Structure - parameters of creating an interaction document form.
//  UseInteractionBase - Boolean - indicates whether a base document is to be considered.
//
Procedure PrepareNotifications(Form, Parameters, UseInteractionBase = True) Export
	
	If Parameters.Property("Base") AND Parameters.Basis <> Undefined Then
		
		If InteractionsClientServer.IsInteraction(Parameters.Basis) Then
			
			Form.NotificationRequired = True;
			If UseInteractionBase  Then
				Form.InteractionBasis = Parameters.Basis;
			Else
				Form.BasisObject = Parameters.Basis;
			EndIf;
			
		ElsIf TypeOf(Parameters.Basis) = Type("Structure") 
			AND Parameters.Basis.Property("Object") 
			AND InteractionsClientServer.IsInteraction(Parameters.Basis.Object) Then
			
			Form.NotificationRequired = True;
			If UseInteractionBase  Then
				Form.InteractionBasis = Parameters.Basis.Object;
			Else
				Form.BasisObject = Parameters.Basis.Object;
			EndIf;
			
		ElsIf TypeOf(Parameters.Basis) = Type("Structure") 
			AND (Parameters.Basis.Property("Base") 
			AND InteractionsClientServer.IsInteraction(Parameters.Basis.Base)) Then

			Form.NotificationRequired = True;
			If UseInteractionBase  Then
				Form.InteractionBasis = Parameters.Basis.Base;
			Else
				Form.BasisObject = Parameters.Basis.Base;
			EndIf;
			
		EndIf;
		
	ElsIf Parameters.Property("FillingValues") AND Parameters.FillingValues.Property("Topic") Then
		Form.NotificationRequired = True;
	EndIf;
	
EndProcedure

// Sets an active subject flag.
//
// Parameters:
//  Subject - DocumentRef, CatalogRef - a subject to be recorded.
//  Active - Boolean - indicates that the subject is active.
//
Procedure SetActiveFlag(Topic, Active) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	InteractionsSubjectsStates.NotReviewedInteractionsCount,
	|	InteractionsSubjectsStates.LastInteractionDate,
	|	InteractionsSubjectsStates.IsActive
	|FROM
	|	InformationRegister.InteractionsSubjectsStates AS InteractionsSubjectsStates
	|WHERE
	|	InteractionsSubjectsStates.Topic = &Topic";
	
	Query.SetParameter("Topic",Topic);
	
	RecordManager = InformationRegisters.InteractionsSubjectsStates.CreateRecordManager();
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		
		If Active = False Then
			Return;
		EndIf;
		
		RecordManager.LastInteractionDate = Date(1,1,1);
		RecordManager.NotReviewedInteractionsCount      = 0;
		
	Else
		
		Selection = Result.Select();
		Selection.Next();
		
		If Selection.IsActive = Active Then
			Return;
		EndIf;
		
		RecordManager.LastInteractionDate = Selection.LastInteractionDate;
		RecordManager.NotReviewedInteractionsCount      = Selection.NotReviewedInteractionsCount;
		
	EndIf;
	
	RecordManager.IsActive = Active;
	RecordManager.Topic = Topic;
	
	RecordManager.Write();

EndProcedure

#EndRegion

#Region Internal

// Recalculates states of folders, contacts, and subjects.
//
Procedure PerformCompleteStatesRecalculation() Export
	
	CalculateReviewedByFolders(Undefined);
	CalculateReviewedByContacts(Undefined);
	CalculateReviewedBySubjects(Undefined);
	
EndProcedure

Function EmailClientUsed() Export
	Return GetFunctionalOption("UseEmailClient");
EndFunction

Function OtherInteractionsUsed() Export
	Return GetFunctionalOption("UseOtherInteractions");
EndFunction

Function SendEmailsInHTMLFormat() Export
	Return GetFunctionalOption("SendEmailsInHTMLFormat");
EndFunction

// Returns a contact list to the subject by the specified contact information type.
//
Function GetContactsBySubject(Topic, ContactInformationTypes) Export
	
	EmailRecipients = New Array;
	If InteractionsClientServer.IsSubject(Topic)
		OR InteractionsClientServer.IsInteraction(Topic) Then
		
		ObjectManager = Common.ObjectManagerByRef(Topic);
		Contacts = ObjectManager.GetContacts(Topic);
		
		If Contacts <> Undefined Then
			For each TableRow In Contacts Do
				
				Recipient = New Structure("Contact, Presentation, Address");
				Recipient.Contact = ?(TypeOf(TableRow) = Type("Structure"), TableRow.Contact, TableRow);
				
				FinishFillingContactsFields(Recipient.Contact, Recipient.Presentation,
					Recipient.Address, ContactInformationTypes);
				
				EmailRecipients.Add(Recipient);
				
			EndDo;
		EndIf;
		
	EndIf;
	
	Return EmailRecipients;
	
EndFunction

Procedure RegisterEmailAccountsToProcessingToMigrateToNewVersion(Parameters) Export
	
	QueryText =
	"SELECT
	|	EmailAccounts.Ref
	|FROM
	|	InformationRegister.EmailAccountSettings AS EmailAccountSettings
	|		LEFT JOIN Catalog.EmailAccounts AS EmailAccounts
	|		ON EmailAccountSettings.EmailAccount = EmailAccounts.Ref
	|WHERE
	|	EmailAccountSettings.DeletePersonalAccount
	|	AND EmailAccounts.AccountOwner = VALUE(Catalog.Users.EmptyRef)";
	
	Query = New Query(QueryText);
	
	Result = Query.Execute().Unload();
	RefsArray = Result.UnloadColumn("Ref");
	
	InfobaseUpdate.MarkForProcessing(Parameters, RefsArray);
	
EndProcedure

Function EmailAccountsOwners(Accounts) Export
	
	Result = New Map;
	
	QueryText =
	"SELECT
	|	EmailAccounts.Ref AS Ref,
	|	EmailAccountSettings.EmployeeResponsibleForProcessingEmails AS AccountOwner
	|FROM
	|	InformationRegister.EmailAccountSettings AS EmailAccountSettings
	|		LEFT JOIN Catalog.EmailAccounts AS EmailAccounts
	|		ON EmailAccountSettings.EmailAccount = EmailAccounts.Ref
	|WHERE
	|	EmailAccounts.Ref IN(&Accounts)";
	
	Query = New Query(QueryText);
	Query.SetParameter("Accounts", Accounts);
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Result.Insert(Selection.Ref, Selection.AccountOwner);
	EndDo;
	
	Return Result;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Message templates.

Function CreateEmail(Message, Account) Export
	
	EmailSendingResult = New Structure("Sent, ErrorDescription", False);
	
	HTMLEmail = (Message.AdditionalParameters.EmailFormat = Enums.EmailEditingMethods.HTML);
	
	BeginTransaction();
	Try
		
		Email = Documents.OutgoingEmail.CreateDocument();
		
		Email.Author                    = Users.CurrentUser();
		Email.EmployeeResponsible            = Users.CurrentUser();
		Email.Date                     = CurrentSessionDate();
		Email.Importance                 = Enums.InteractionImportanceOptions.Normal;
		Email.Encoding                = TextEncoding.UTF8;
		Email.SenderPresentation = String(Account);
		
		If HTMLEmail Then
			
			Email.HTMLText = Message.Text;
			Email.Text     = GetPlainTextFromHTML(Message.Text);
			
		Else
			
			Email.Text = Message.Text;
			
		EndIf;
		
		Email.Subject = Message.Subject;
		Email.TextType = ?(HTMLEmail, Enums.EmailTextTypes.HTML, Enums.EmailTextTypes.PlainText);
		Email.Account = Account;
		Email.InteractionBasis = Undefined;
		
		// Filling in the IncludeSourceEmailBody, DisplaySourceEmailBody, RequestDeliveryReceipt, and RequestReadReceipt attributes.
		UserSettings = GetUserParametersForOutgoingEmail(
		                           Account, Message.AdditionalParameters.EmailFormat, True);
		FillPropertyValues(Email, UserSettings);
		
		Email.DeleteAfterSend = False;
		Email.Comment = CommentByTemplateDescription(Message.AdditionalParameters.Description);
		
		RecipientsListAsValueList =( TypeOf(Message.Recipient) = Type("ValueList"));
		For Each EmailRecipient In Message.Recipient Do
			
			NewRow = Email["EmailRecipients"].Add();
			
			If RecipientsListAsValueList Then
				NewRow.Address         = EmailRecipient.Value;
				NewRow.Presentation = EmailRecipient.Presentation;
			Else
				NewRow.Address         = EmailRecipient.Address;
				NewRow.Presentation = EmailRecipient.Presentation;
				NewRow.Contact       = EmailRecipient.ContactInformationSource;
			EndIf;
			
		EndDo;
		
		Email.EmailRecipientsList    = InteractionsClientServer.GetAddressesListPresentation(Email.EmailRecipients, False);
		Email.EmailStatus = ?(Common.FileInfobase(),
			Enums.OutgoingEmailStatuses.Draft,
			Enums.OutgoingEmailStatuses.Outgoing);
		
		Email.HasAttachments = (Message.Attachments.Count() > 0);
		AttachmentsSize  = 0;
		AttachmentsSizes = New Map;
		For Each Attachment In Message.Attachments Do
			
			Size = GetFromTempStorage(Attachment.AddressInTempStorage).Size() * 1.5;
			AttachmentsSize = AttachmentsSize + Size;
			AttachmentsSizes.Insert(Attachment.AddressInTempStorage, Size);
			
			// If ID characters are not English, the email may be processed incorrectly.
			If ValueIsFilled(Attachment.ID) Then
				ID = StringFunctionsClientServer.LatinString(Attachment.ID);
				Email.HTMLText = StrReplace(Email.HTMLText, "cid:" + Attachment.ID, "cid:" + ID);
				Attachment.ID = ID;
			EndIf;
			
		EndDo;
		
		Email.Size = AttachmentsSize + StrLen(Email.Subject) * 2
			+ ?(HTMLEmail, StrLen(Email.HTMLText), StrLen(Email.Text)) * 2;
		Email.EmailStatus = Enums.OutgoingEmailStatuses.Outgoing;
		
		Email.Write();
		
		// Adding attachments
		For Each Attachment In Message.Attachments Do
			
			ModuleEmailManager = Common.CommonModule("EmailManagement");
			If IsBlankString(Attachment.ID) Then
				
				ModuleEmailManager.WriteEmailAttachmentFromTempStorage(Email.Ref,
					Attachment.AddressInTempStorage, Attachment.Presentation, AttachmentsSizes[Attachment.AddressInTempStorage]);
					
			ElsIf HTMLEmail Then
				
				AttachedFile = ModuleEmailManager.WriteEmailAttachmentFromTempStorage(Email.Ref,
					Attachment.AddressInTempStorage, Attachment.Presentation, AttachmentsSizes[Attachment.AddressInTempStorage]);
				
				If AttachedFile <> Undefined Then
					AttachedFileObject = AttachedFile.GetObject();
					AttachedFileObject.EmailFileID = Attachment.ID;
					AttachedFileObject.Write();
				EndIf;
				
			EndIf;
			
		EndDo;
		
		If Message.AdditionalParameters.Property("Topic") AND ValueIsFilled(Message.AdditionalParameters.Topic) Then
			Topic = Message.AdditionalParameters.Topic;
		Else
			Topic = Email.Ref;
		EndIf;
	
		Attributes       = InteractionAttributesStructureForWrite(Topic, True);
		Attributes.Folder = DefineFolderForEmail(Email.Ref);
		
		InformationRegisters.InteractionsFolderSubjects.WriteInteractionFolderSubjects(Email.Ref, Attributes);
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		ErrorInformation = ErrorInfo();
		MessageTextTemplate = NStr("ru = 'Не удалось сформировать письмо по причине:
		|%1'; 
		|en = 'Cannot generate an email due to:
		|%1'; 
		|pl = 'Cannot generate an email due to:
		|%1';
		|de = 'Cannot generate an email due to:
		|%1';
		|ro = 'Cannot generate an email due to:
		|%1';
		|tr = 'Cannot generate an email due to:
		|%1'; 
		|es_ES = 'Cannot generate an email due to:
		|%1'");
		
		WriteLogEvent(InfobaseUpdate.EventLogEvent(),
			EventLogLevel.Error,, Email,
			StringFunctionsClientServer.SubstituteParametersToString(MessageTextTemplate, DetailErrorDescription(ErrorInformation)));
			
		EmailSendingResult.ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(MessageTextTemplate, BriefErrorDescription(ErrorInformation));
		Return EmailSendingResult;
		
	EndTry;
		
	Try
		EmailID = ExecuteEmailSending(Email);
	Except
		
		ErrorInformation = ErrorInfo();
		MessageTextTemplate = NStr("ru = 'Не удалось отправить письмо по причине:
				|%1'; 
				|en = 'Cannot send an email due to:
				|%1'; 
				|pl = 'Cannot send an email due to:
				|%1';
				|de = 'Cannot send an email due to:
				|%1';
				|ro = 'Cannot send an email due to:
				|%1';
				|tr = 'Cannot send an email due to:
				|%1'; 
				|es_ES = 'Cannot send an email due to:
				|%1'");
				
		WriteLogEvent(InfobaseUpdate.EventLogEvent(),
			EventLogLevel.Error,, Email,
			StringFunctionsClientServer.SubstituteParametersToString(MessageTextTemplate, DetailErrorDescription(ErrorInformation)));
		
		EmailSendingResult.ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(MessageTextTemplate, BriefErrorDescription(ErrorInformation));
		Return EmailSendingResult;
		
	EndTry;
	
	If NOT Email.DeleteAfterSend Then
		
		Try
			Email.MessageID = EmailID;
			Email.EmailStatus           = Enums.OutgoingEmailStatuses.Sent;
			Email.PostingDate        = CurrentSessionDate();
			Email.Write(DocumentWriteMode.Write);
			
			InteractionsServerCall.SetEmailFolder(
				Email.Ref, DefineFolderForEmail(Email.Ref));
		Except
				
			ErrorInformation = ErrorInfo();
			MessageTextTemplate = NStr("ru = 'Не удалось сохранить письмо в программе после успешной отправки по причине:
				|%1'; 
				|en = 'Cannot save the email in the application after successful sending due to:
				|%1'; 
				|pl = 'Cannot save the email in the application after successful sending due to:
				|%1';
				|de = 'Cannot save the email in the application after successful sending due to:
				|%1';
				|ro = 'Cannot save the email in the application after successful sending due to:
				|%1';
				|tr = 'Cannot save the email in the application after successful sending due to:
				|%1'; 
				|es_ES = 'Cannot save the email in the application after successful sending due to:
				|%1'");
				
			WriteLogEvent(InfobaseUpdate.EventLogEvent(),
				EventLogLevel.Error,, Email,
				StringFunctionsClientServer.SubstituteParametersToString(MessageTextTemplate, DetailErrorDescription(ErrorInformation)));
				
			EmailSendingResult.Sent     = True;
			EmailSendingResult.ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(MessageTextTemplate, BriefErrorDescription(ErrorInformation));
			Return EmailSendingResult;

		EndTry;
		
	Else
		
		Email.Read();
		Email.Delete();
		
	EndIf;
	
	EmailSendingResult.Sent = True;
	Return EmailSendingResult;
	
EndFunction

Procedure CreateAndSendSMSMessage(Message) Export

	SMSMessage = Documents.SMSMessage.CreateDocument();
	
	SMSMessage.Date                    = CurrentSessionDate();
	SMSMessage.Author                   = Users.CurrentUser();

	SMSMessage.EmployeeResponsible           = Users.CurrentUser();
	SMSMessage.Importance                = Enums.InteractionImportanceOptions.Normal;

	SMSMessage.InteractionBasis = Undefined;
	SMSMessage.MessageText          = Message.Text;
	SMSMessage.Subject                    = SubjectByMessageText(Message.Text);
	SMSMessage.SendInTransliteration    = Message.AdditionalParameters.Transliterate;
	SMSMessage.Comment             = CommentByTemplateDescription(Message.AdditionalParameters.Description);
	
	For each SMSMessageAddressee In Message.Recipient Do
		
		NewRow = SMSMessage.Recipients.Add();
		If TypeOf(SMSMessageAddressee) = Type("Structure") Then
			NewRow.Contact                = SMSMessageAddressee.ContactInformationSource;
			NewRow.ContactPresentation  = SMSMessageAddressee.Presentation;
			NewRow.HowToContact           = SMSMessageAddressee.PhoneNumber;
			NewRow.SendingNumber       = SMSMessageAddressee.PhoneNumber;
		Else
			NewRow.Contact                = "";
			NewRow.ContactPresentation  = SMSMessageAddressee.Presentation;
			NewRow.HowToContact           = SMSMessageAddressee.Value;
			NewRow.SendingNumber       = SMSMessageAddressee.Value;
		EndIf;
		NewRow.MessageID = "";
		NewRow.ErrorText            = "";
		NewRow.MessageState = Enums.SMSMessagesState.Draft;
	
	EndDo;
	
	If Common.FileInfobase() Then
		SendSMSMessageByDocument(SMSMessage);
	Else
		InteractionsClientServer.SetStateOutgoingDocumentSMSMessage(SMSMessage);
	EndIf;
	
	SMSMessage.Write();
	
	If Message.AdditionalParameters.Property("Topic") AND ValueIsFilled(Message.AdditionalParameters.Topic) Then
		Topic = Message.AdditionalParameters.Topic;
	Else
		Topic = SMSMessage.Ref;
	EndIf;
	Attributes = InteractionAttributesStructureForWrite(Topic, True);
	InformationRegisters.InteractionsFolderSubjects.WriteInteractionFolderSubjects(SMSMessage.Ref, Attributes);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Configuration subsystems event handlers.

// See ImportDataFromFileOverridable.OnDefineCatalogsForDataImport. 
Procedure OnDefineCatalogsForDataImport(CatalogsToImport) Export
	
	// Cannot import to the StringInteractionsContacts catalog.
	TableRow = CatalogsToImport.Find(Metadata.Catalogs.StringContactInteractions.FullName(), "FullName");
	If TableRow <> Undefined Then 
		CatalogsToImport.Delete(TableRow);
	EndIf;
	
EndProcedure

// See BatchObjectModificationOverridable.OnDetermineObjectsWithEditableAttributes. 
Procedure OnDefineObjectsWithEditableAttributes(Objects) Export
	Objects.Insert(Metadata.Documents.Meeting.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Documents.PhoneCall.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Documents.PlannedInteraction.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Documents.IncomingEmail.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Documents.OutgoingEmail.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Documents.SMSMessage.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.MeetingAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.InteractionsTabs.FullName(), "AttributesToSkipInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.PlannedInteractionAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.EmailMessageFolders.FullName(), "AttributesToSkipInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.EmailProcessingRules.FullName(), "AttributesToSkipInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.SMSMessageAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.StringContactInteractions.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.PhoneCallAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.IncomingEmailAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.OutgoingEmailAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
EndProcedure

// Called after the marked objects are deleted.
//
// Parameters:
//   ExecutionParameters - Structure - a context of marked object deletion.
//       * Deleted - Array - references of deleted objects.
//       * NotDeletedItems - Array - references to the objects that cannot be deleted.
//
Procedure AfterDeleteMarkedObjects(ExecutionParameters) Export
	
	StatesRecalculationRequired = False;
	
	For Each RemovedRef In ExecutionParameters.DeletedItems Do
		
		If InteractionsClientServer.IsInteraction(RemovedRef) Then
			StatesRecalculationRequired = True;
			Break;
		EndIf;
		
	EndDo;
	
	If StatesRecalculationRequired Then
		
		PerformCompleteStatesRecalculation();
		
	EndIf;
	
EndProcedure

// See ScheduledJobsOverridable.OnDefineScheduledJobsSettings. 
Procedure OnDefineScheduledJobSettings(Dependencies) Export
	
	Dependence = Dependencies.Add();
	Dependence.ScheduledJob = Metadata.ScheduledJobs.SMSDeliveryStatusUpdate;
	Dependence.FunctionalOption = Metadata.FunctionalOptions.UseEmailClient;
	Dependence.UseExternalResources = True;
	
	Dependence = Dependencies.Add();
	Dependence.ScheduledJob = Metadata.ScheduledJobs.SendSMSMessage;
	Dependence.FunctionalOption = Metadata.FunctionalOptions.UseEmailClient;
	Dependence.UseExternalResources = True;
	
	Dependence = Dependencies.Add();
	Dependence.ScheduledJob = Metadata.ScheduledJobs.SendReceiveEmails;
	Dependence.FunctionalOption = Metadata.FunctionalOptions.UseEmailClient;
	Dependence.UseExternalResources = True;

EndProcedure

// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport. 
Procedure OnFillTypesExcludedFromExportImport(Types) Export
	
	Types.Add(Metadata.InformationRegisters.AccountsLockedForReceipt);
	Types.Add(Metadata.InformationRegisters.Delete_ActiveInteractionObjects);
	
EndProcedure

// See CommonOverridable.OnAddClientParameters. 
Procedure OnAddClientParameters(Parameters) Export
	
	UseEmailClient = GetFunctionalOption("UseEmailClient");
	HasRightToCreateOutgoingEmails = AccessRight("Insert", Metadata.Documents.OutgoingEmail);
	
	Parameters.Insert("UseEmailClient", UseEmailClient);
	Parameters.Insert("UseOtherInteractions", GetFunctionalOption("UseOtherInteractions"));
	Parameters.Insert("OutgoingEmailsCreationAvailable", UseEmailClient AND HasRightToCreateOutgoingEmails);
	
EndProcedure

// See AccessManagementOverridable.OnFillListsWithAccessRestriction. 
Procedure OnFillListsWithAccessRestriction(Lists) Export
	
	Lists.Insert(Metadata.Catalogs.MeetingAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.PlannedInteractionAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.EmailMessageFolders, True);
	Lists.Insert(Metadata.Catalogs.EmailProcessingRules, True);
	Lists.Insert(Metadata.Catalogs.SMSMessageAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.PhoneCallAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.IncomingEmailAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.OutgoingEmailAttachedFiles, True);
	Lists.Insert(Metadata.Documents.Meeting, True);
	Lists.Insert(Metadata.Documents.PlannedInteraction, True);
	Lists.Insert(Metadata.Documents.SMSMessage, True);
	Lists.Insert(Metadata.Documents.PhoneCall, True);
	Lists.Insert(Metadata.Documents.IncomingEmail, True);
	Lists.Insert(Metadata.Documents.OutgoingEmail, True);
	Lists.Insert(Metadata.DocumentJournals.Interactions, True);
	Lists.Insert(Metadata.InformationRegisters.EmailAccountSettings, True);
	Lists.Insert(Metadata.InformationRegisters.InteractionsFolderSubjects, True);
	
EndProcedure

// See AccessManagementOverridable.OnFillMetadataObjectsAccessRestrictionsKinds. 
Procedure OnFillMetadataObjectsAccessRestrictionKinds(Details) Export
	
	If NOT Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		Return;
	EndIf;
	
	ModuleAccessManagementInternal = Common.CommonModule("AccessManagementInternal");
	
	If ModuleAccessManagementInternal.AccessKindExists("EmailAccounts") Then
		
		Details = Details + "
		|Catalog.EmailMessageFolders.Read.EmailAccounts
		|Catalog.EmailMessageFolders.Update.EmailAccounts
		|Catalog.EmailProcessingRules.Read.EmailAccounts
		|Catalog.EmailProcessingRules.Update.EmailAccounts
		|InformationRegister.EmailAccountSettings.Read.EmailAccounts
		|";
		
	EndIf;
	
	Details = Details + "
	|Document.Meeting.Read.Object.Document.Meeting
	|Document.Meeting.Update.Object.Document.Meeting
	|Document.PlannedInteraction.Read.Object.Document.PlannedInteraction
	|Document.PlannedInteraction.Update.Object.Document.PlannedInteraction
	|Document.SMSMessage.Read.Object.Document.SMSMessage
	|Document.SMSMessage.Update.Object.Document.SMSMessage
	|Document.PhoneCall.Read.Object.Document.PhoneCall
	|Document.PhoneCall.Update.Object.Document.PhoneCall
	|Document.IncomingEmail.Read.Object.Document.IncomingEmail
	|Document.IncomingEmail.Update.Object.Document.IncomingEmail
	|Document.OutgoingEmail.Read.Object.Document.OutgoingEmail
	|Document.OutgoingEmail.Update.Object.Document.OutgoingEmail
	|DocumentJournal.Interactions.Read.Object.Document.Meeting
	|DocumentJournal.Interactions.Read.Object.Document.PlannedInteraction
	|DocumentJournal.Interactions.Read.Object.Document.SMSMessage
	|DocumentJournal.Interactions.Read.Object.Document.PhoneCall
	|DocumentJournal.Interactions.Read.Object.Document.IncomingEmail
	|DocumentJournal.Interactions.Read.Object.Document.OutgoingEmail
	|InformationRegister.EmailAccountSettings.Read.Users
	|InformationRegister.InteractionsFolderSubjects.Update.Object.Document.Meeting
	|InformationRegister.InteractionsFolderSubjects.Update.Object.Document.PlannedInteraction
	|InformationRegister.InteractionsFolderSubjects.Update.Object.Document.SMSMessage
	|InformationRegister.InteractionsFolderSubjects.Update.Object.Document.PhoneCall
	|InformationRegister.InteractionsFolderSubjects.Update.Object.Document.IncomingEmail
	|InformationRegister.InteractionsFolderSubjects.Update.Object.Document.OutgoingEmail
	|Catalog.EmailMessageFolders.Read.Users
	|Catalog.EmailMessageFolders.Update.Users
	|Catalog.EmailProcessingRules.Read.Users
	|Catalog.EmailProcessingRules.Update.Users
	|";
	
	If Common.SubsystemExists("StandardSubsystems.FilesOperations") Then
		Details = Details + "
		|Catalog.MeetingAttachedFiles.Read.Object.Document.Meeting
		|Catalog.MeetingAttachedFiles.Update.Object.Document.Meeting
		|Catalog.PlannedInteractionAttachedFiles.Read.Object.Document.PlannedInteraction
		|Catalog.PlannedInteractionAttachedFiles.Update.Object.Document.PlannedInteraction
		|Catalog.SMSMessageAttachedFiles.Read.Object.Document.SMSMessage
		|Catalog.SMSMessageAttachedFiles.Update.Object.Document.SMSMessage
		|Catalog.PhoneCallAttachedFiles.Read.Object.Document.PhoneCall
		|Catalog.PhoneCallAttachedFiles.Update.Object.Document.PhoneCall
		|Catalog.IncomingEmailAttachedFiles.Read.Object.Document.IncomingEmail
		|Catalog.IncomingEmailAttachedFiles.Update.Object.Document.IncomingEmail
		|Catalog.OutgoingEmailAttachedFiles.Read.Object.Document.OutgoingEmail
		|Catalog.OutgoingEmailAttachedFiles.Update.Object.Document.OutgoingEmail
		|";
		
	EndIf;
	
EndProcedure

// See JobsQueueOverridable.OnGetTemplatesList. 
Procedure OnGetTemplateList(JobTemplates) Export
	
	JobTemplates.Add("SMSDeliveryStatusUpdate");
	JobTemplates.Add("SendSMSMessage");
	JobTemplates.Add("SendReceiveEmails");
	
EndProcedure

// See ToDoListOverridable.OnDetermineToDoListHandlers 
Procedure OnFillToDoList(ToDoList) Export
	
	ModuleToDoListServer = Common.CommonModule("ToDoListServer");
	If (Not Users.IsFullUser()
		AND Not (AccessRight("Read", Metadata.DocumentJournals.Interactions) 
		AND AccessRight("Read", Metadata.Catalogs.EmailAccounts)))
		Or ModuleToDoListServer.UserTaskDisabled("InteractionsMail") Then
		Return;
	EndIf;
	
	NewEmailsByAccounts = NewEmailsByAccounts();
	
	// This procedure is only called when To-do list subsystem is available. Therefore, the subsystem 
	// availability check is redundant.
	Sections = ModuleToDoListServer.SectionsForObject(Metadata.DocumentJournals.Interactions.FullName());
	
	For Each Section In Sections Do
		
		InteractionID = "Interactions" + StrReplace(Section.FullName(), ".", "");
		UserTaskParent = ToDoList.Add();
		UserTaskParent.ID  = InteractionID;
		UserTaskParent.Presentation  = NStr("ru = 'Почта'; en = 'Mail'; pl = 'Mail';de = 'Mail';ro = 'Mail';tr = 'Mail'; es_ES = 'Mail'");
		UserTaskParent.Form          = "DocumentJournal.Interactions.Form.ListForm";
		UserTaskParent.Owner       = Section;
		
		Index = 1;
		EmailsCount = 0;
		For Each NewEmailsByAccount In NewEmailsByAccounts Do
		
			EmailsIDByAccount = InteractionID + "Account" + Index;
			ToDoItem = ToDoList.Add();
			ToDoItem.ID  = EmailsIDByAccount;
			ToDoItem.HasToDoItems       = NewEmailsByAccount.EmailsCount > 0;
			ToDoItem.Count     = NewEmailsByAccount.EmailsCount;
			ToDoItem.Presentation  = NewEmailsByAccount.Account;
			ToDoItem.Owner       = InteractionID;
			
			Index = Index + 1;
			EmailsCount = EmailsCount + NewEmailsByAccount.EmailsCount;
		EndDo;
		
		UserTaskParent.Count = EmailsCount;
		UserTaskParent.HasToDoItems   = EmailsCount > 0;
	EndDo;
	
EndProcedure

// See InfobaseUpdateSSL.OnAddUpdateHandlers. 
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.InitialFilling = True;
	Handler.Procedure = "Interactions.DisableSubsystemSaaS";
	
	Handler = Handlers.Add();
	Handler.Version = "1.1.2.4";
	Handler.Procedure = "Interactions.UpdateSubjectStorage_1_2_1_4";
	
	Handler = Handlers.Add();
	Handler.Version = "1.1.2.4";
	Handler.Procedure = "Interactions.UpdateStorageEmployeeResponsibleAccount_1_2_1_4";
	
	Handler = Handlers.Add();
	Handler.Version = "1.1.2.4";
	Handler.Procedure = "Interactions.CreateEmailFolders_1_2_1_4";
	
	Handler = Handlers.Add();
	Handler.Version = "1.1.2.4";
	Handler.Procedure = "Interactions.MoveMessagesToPredefinedFolders_1_2_3_4";
	
	Handler = Handlers.Add();
	Handler.Version = "1.1.2.4";
	Handler.Procedure = "Interactions.ConvertDescriptionToSubject_1_2_1_4";
	
	Handler = Handlers.Add();
	Handler.Version = "1.1.2.4";
	Handler.Procedure = "Interactions.FillSizeForOutgoingEmails_1_2_1_4";
	
	Handler = Handlers.Add();
	Handler.Version = "2.0.1.2";
	Handler.Procedure = "Interactions.ChangeEmailFoldersEncoding_2_0_1_2";
	
	Handler = Handlers.Add();
	Handler.Version = "2.1.3.22";
	Handler.Procedure = "Interactions.UpdateStorageIncludeUsernameInPresentation_2_1_3_22";
	
	Handler = Handlers.Add();
	Handler.Version = "2.2.1.12";
	Handler.Procedure = "InformationRegisters.InteractionsFolderSubjects.UpdateStoragereviewedReviewAfter_2_2_0_0";
	Handler.ExecutionMode = "Deferred";
	Handler.ID = New UUID("c12dc82c-2358-4abd-9622-656a6a188062");
	Handler.Comment = NStr("ru = 'Переносится хранение реквизитов ""Рассмотрено"" и ""РассмотретьПосле"" в регистр сведений ""ПредметыПапкиВзаимодействий"". Без выполнения обработчика значения данных реквизитов будут отображаться некорректно.'; en = 'Moves the Reviewed and ReviewAfter attributes to the InteractionsFolderSubjects information register. If this handler is not executed, attribute data values will be displayed incorrectly.'; pl = 'Moves the Reviewed and ReviewAfter attributes to the InteractionsFolderSubjects information register. If this handler is not executed, attribute data values will be displayed incorrectly.';de = 'Moves the Reviewed and ReviewAfter attributes to the InteractionsFolderSubjects information register. If this handler is not executed, attribute data values will be displayed incorrectly.';ro = 'Moves the Reviewed and ReviewAfter attributes to the InteractionsFolderSubjects information register. If this handler is not executed, attribute data values will be displayed incorrectly.';tr = 'Moves the Reviewed and ReviewAfter attributes to the InteractionsFolderSubjects information register. If this handler is not executed, attribute data values will be displayed incorrectly.'; es_ES = 'Moves the Reviewed and ReviewAfter attributes to the InteractionsFolderSubjects information register. If this handler is not executed, attribute data values will be displayed incorrectly.'");
	
	Handler = Handlers.Add();
	Handler.Version = "2.2.1.12";
	Handler.Procedure = "InformationRegisters.InteractionsContacts.FillInteractionsContacts_2_2_0_0";
	Handler.ExecutionMode = "Deferred";
	Handler.ID = New UUID("bfe0bff5-6d5c-4359-a994-6e76bf824454");
	Handler.Comment = NStr("ru = 'Заполняется вспомогательный регистр сведений ""КонтактыВзаимодействий"". Без выполнения обработчика не будут корректно работать отборы по контактам взаимодействий.'; en = 'Fills the auxiliary information register InteractionsContacts.  If this handler is not executed, filters by interactions contacts will not function correctly.'; pl = 'Fills the auxiliary information register InteractionsContacts.  If this handler is not executed, filters by interactions contacts will not function correctly.';de = 'Fills the auxiliary information register InteractionsContacts.  If this handler is not executed, filters by interactions contacts will not function correctly.';ro = 'Fills the auxiliary information register InteractionsContacts.  If this handler is not executed, filters by interactions contacts will not function correctly.';tr = 'Fills the auxiliary information register InteractionsContacts.  If this handler is not executed, filters by interactions contacts will not function correctly.'; es_ES = 'Fills the auxiliary information register InteractionsContacts.  If this handler is not executed, filters by interactions contacts will not function correctly.'");
	
	Handler = Handlers.Add();
	Handler.Version = "2.2.1.12";
	Handler.Procedure = "InformationRegisters.EmailFolderStates.CalculateEmailFolderStatuses_2_2_0_0";
		Handler.ExecutionMode = "Deferred";
		Handler.ID = New UUID("48cc6281-e934-45d6-b673-819c68016d11");
	Handler.Comment = NStr("ru = 'Выполняется первоначальный расчет количества нерассмотренных писем по папкам. Без выполнения обработчика не будет корректно выводится информация о количестве нерассмотренных писем по папкам.'; en = 'Initial calculation of the number of not reviewed emails by folders is in progress. Information on the number of not reviewed emails by folders will not be displayed correctly without the handler execution.'; pl = 'Initial calculation of the number of not reviewed emails by folders is in progress. Information on the number of not reviewed emails by folders will not be displayed correctly without the handler execution.';de = 'Initial calculation of the number of not reviewed emails by folders is in progress. Information on the number of not reviewed emails by folders will not be displayed correctly without the handler execution.';ro = 'Initial calculation of the number of not reviewed emails by folders is in progress. Information on the number of not reviewed emails by folders will not be displayed correctly without the handler execution.';tr = 'Initial calculation of the number of not reviewed emails by folders is in progress. Information on the number of not reviewed emails by folders will not be displayed correctly without the handler execution.'; es_ES = 'Initial calculation of the number of not reviewed emails by folders is in progress. Information on the number of not reviewed emails by folders will not be displayed correctly without the handler execution.'");
	
	Handler = Handlers.Add();
	Handler.Version = "2.2.1.12";
	Handler.Procedure = "InformationRegisters.InteractionsSubjectsStates.CalculateInteractionSubjectStatuses_2_2_0_0";
	Handler.ExecutionMode = "Deferred";
	Handler.ID = New UUID("0eec6511-cb6c-443b-b27b-6b888aad99ef");
	Handler.Comment = NStr("ru = 'Выполняется первоначальный расчет количества состояний предметов взаимодействий. Без выполнения обработчика не будет корректно выводится информация в панель навигации журнала взаимодействий по предметам.'; en = 'Initial calculation of the number of subject states is in progress. The information will not be displayed correctly in the navigation panel of the interaction log by subjects without the handler execution.'; pl = 'Initial calculation of the number of subject states is in progress. The information will not be displayed correctly in the navigation panel of the interaction log by subjects without the handler execution.';de = 'Initial calculation of the number of subject states is in progress. The information will not be displayed correctly in the navigation panel of the interaction log by subjects without the handler execution.';ro = 'Initial calculation of the number of subject states is in progress. The information will not be displayed correctly in the navigation panel of the interaction log by subjects without the handler execution.';tr = 'Initial calculation of the number of subject states is in progress. The information will not be displayed correctly in the navigation panel of the interaction log by subjects without the handler execution.'; es_ES = 'Initial calculation of the number of subject states is in progress. The information will not be displayed correctly in the navigation panel of the interaction log by subjects without the handler execution.'");
	
	Handler = Handlers.Add();
	Handler.Version = "2.2.1.12";
	Handler.Procedure = "InformationRegisters.InteractionsContactStates.CalculateInteractionContactStatuses_2_2_0_0";
	Handler.ExecutionMode = "Deferred";
	Handler.ID = New UUID("4ec55cf6-e322-49f2-b977-77b718a4e7ca");
	Handler.Comment = NStr("ru = 'Выполняется первоначальный расчет количества состояний контактов взаимодействий. Без выполнения обработчика не будет корректно выводится информация в панель навигации журнала взаимодействий по контактам.'; en = 'Initial calculation of the number of interaction contact states is in progress. The information will not be displayed correctly in the navigation panel of the interaction log by contacts without the handler execution.'; pl = 'Initial calculation of the number of interaction contact states is in progress. The information will not be displayed correctly in the navigation panel of the interaction log by contacts without the handler execution.';de = 'Initial calculation of the number of interaction contact states is in progress. The information will not be displayed correctly in the navigation panel of the interaction log by contacts without the handler execution.';ro = 'Initial calculation of the number of interaction contact states is in progress. The information will not be displayed correctly in the navigation panel of the interaction log by contacts without the handler execution.';tr = 'Initial calculation of the number of interaction contact states is in progress. The information will not be displayed correctly in the navigation panel of the interaction log by contacts without the handler execution.'; es_ES = 'Initial calculation of the number of interaction contact states is in progress. The information will not be displayed correctly in the navigation panel of the interaction log by contacts without the handler execution.'");
	
	Handler = Handlers.Add();
	Handler.Version = "2.2.1.29";
	Handler.Procedure = "Interactions.DisableSubsystemSaaS";
	
	Handler = Handlers.Add();
	Handler.Version = "2.3.3.28";
	Handler.ExecutionMode = "Deferred";
	Handler.ID = New UUID("301d4867-5fb2-45ff-9d32-dc3e5da008df");
	Handler.Procedure = "Documents.IncomingEmail.FillBasisInteractionsForDependentEmails";
	Handler.UpdateDataFillingProcedure = "Documents.IncomingEmail.FillBasisInteractionsForDependentEmailsToProcess";
	Handler.CheckProcedure    = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.DeferredProcessingQueue = 1;
	Handler.ObjectsToBeRead      = "Document.IncomingEmail, Document.OutgoingEmail";
	Handler.ObjectsToChange    = "Document.IncomingEmail";
	Handler.ObjectsToLock   = "Document.IncomingEmail";
	Handler.ExecutionPriorities = InfobaseUpdate.HandlerExecutionPriorities();
	Priority = Handler.ExecutionPriorities.Add();
	Priority.Procedure = "Documents.OutgoingEmail.ProcessDataForMigrationToNewVersion";
	Priority.Order = "Any";
	Handler.Comment = NStr("ru = 'Выполняет дозаполнение реквизита ВзаимодействиеОснование для входящих писем, у которых письмо основание в ИБ есть, но оно не указано.'; en = 'Fills the InteractionBasis attribute for incoming emails with basis emails existing but not specified.'; pl = 'Fills the InteractionBasis attribute for incoming emails with basis emails existing but not specified.';de = 'Fills the InteractionBasis attribute for incoming emails with basis emails existing but not specified.';ro = 'Fills the InteractionBasis attribute for incoming emails with basis emails existing but not specified.';tr = 'Fills the InteractionBasis attribute for incoming emails with basis emails existing but not specified.'; es_ES = 'Fills the InteractionBasis attribute for incoming emails with basis emails existing but not specified.'");
	
	Handler = Handlers.Add();
	Handler.Version = "2.3.6.76";
	Handler.ID = New UUID("35e85660-7125-4079-b5df-5a71dbb43a48");
	Handler.Procedure = "Documents.OutgoingEmail.ProcessDataForMigrationToNewVersion";
	Handler.Comment =
		NStr("ru = 'Технологический перенос данных идентификаторов сообщения IMAP (реквизит ИдентификаторСообщенияОтправкаIMAP) для предотвращения потери данных
		           |при переходе на последующие релизы программы.
		           |Выполняет дозаполнение реквизита ВзаимодействиеОснование для исходящих писем, у которых письмо основание в ИБ есть, но оно не указано'; 
		           |en = 'Performs technological transfer of IMAP message IDs data (MessageIDSendingIMAP attribute) to prevent data loss
		           |during migration to next application releases.
		           |Fills the InteractionBasis attribute for outgoing emails with basis emails existing but not specified.'; 
		           |pl = 'Performs technological transfer of IMAP message IDs data (MessageIDSendingIMAP attribute) to prevent data loss
		           |during migration to next application releases.
		           |Fills the InteractionBasis attribute for outgoing emails with basis emails existing but not specified.';
		           |de = 'Performs technological transfer of IMAP message IDs data (MessageIDSendingIMAP attribute) to prevent data loss
		           |during migration to next application releases.
		           |Fills the InteractionBasis attribute for outgoing emails with basis emails existing but not specified.';
		           |ro = 'Performs technological transfer of IMAP message IDs data (MessageIDSendingIMAP attribute) to prevent data loss
		           |during migration to next application releases.
		           |Fills the InteractionBasis attribute for outgoing emails with basis emails existing but not specified.';
		           |tr = 'Performs technological transfer of IMAP message IDs data (MessageIDSendingIMAP attribute) to prevent data loss
		           |during migration to next application releases.
		           |Fills the InteractionBasis attribute for outgoing emails with basis emails existing but not specified.'; 
		           |es_ES = 'Performs technological transfer of IMAP message IDs data (MessageIDSendingIMAP attribute) to prevent data loss
		           |during migration to next application releases.
		           |Fills the InteractionBasis attribute for outgoing emails with basis emails existing but not specified.'");
	Handler.ExecutionMode = "Deferred";
	Handler.DeferredProcessingQueue = 3;
	Handler.UpdateDataFillingProcedure = "Documents.OutgoingEmail.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure    = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.ObjectsToBeRead      = "Document.OutgoingEmail";
	Handler.ObjectsToChange    = "Document.OutgoingEmail";
	Handler.ObjectsToLock   = "Document.OutgoingEmail";
	Handler.ExecutionPriorities = InfobaseUpdate.HandlerExecutionPriorities();
	Priority = Handler.ExecutionPriorities.Add();
	Priority.Procedure = "Documents.IncomingEmail.FillBasisInteractionsForDependentEmails";
	Priority.Order = "Any";
	Handler.CheckProcedure    = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	
EndProcedure

// See FilesOperationsInternal.OnDetermineFilesSynchronizationExceptionObjects. 
Procedure OnDefineFilesSynchronizationExceptionObjects(Objects) Export
	
	Objects.Add(Metadata.Documents.SMSMessage);
	Objects.Add(Metadata.Documents.IncomingEmail);
	Objects.Add(Metadata.Documents.OutgoingEmail);
	
EndProcedure

Procedure OnReceiveObjectsToReadOfEmailAccountsUpdateHandler(ObjectsToRead) Export
	ObjectsToRead.Add("InformationRegister.EmailAccountSettings");
EndProcedure

Procedure BeforeSetLockInEmailAccountsUpdateHandler(Lock) Export
	Lock.Add("InformationRegister.EmailAccountSettings");
EndProcedure

Function HasAbilityToFilterHTMLContent() Export
	
	SystemInformation = New SystemInfo;
	CurrentPlatformVersion = SystemInformation.AppVersion;
	RequiredPlatformVersion = "8.3.13.0";
	
	Return CommonClientServer.CompareVersions(RequiredPlatformVersion, CurrentPlatformVersion) <= 0;
	
EndFunction

// See PropertyManagerOverridable.OnGetPredefinedPropertiesSets. 
Procedure OnGetPredefinedPropertiesSets(Sets) Export
	Set = Sets.Rows.Add();
	Set.Name = "Document_Meeting";
	Set.ID = New UUID("26c5b310-f6a7-47b0-b85a-6052216965e2");
	
	Set = Sets.Rows.Add();
	Set.Name = "Document_PlannedInteraction";
	Set.ID = New UUID("70425541-23e3-4e5a-8bd3-9587cc949dfa");
	
	Set = Sets.Rows.Add();
	Set.Name = "Document_SMSMessage";
	Set.ID = New UUID("e9c48775-2727-46e1-bdb8-e9a0a68358a1");
	
	Set = Sets.Rows.Add();
	Set.Name = "Document_PhoneCall";
	Set.ID = New UUID("da617a73-992a-42b9-8d20-e65e043c46bc");
	
	Set = Sets.Rows.Add();
	Set.Name = "Document_IncomingEmail";
	Set.ID = New UUID("0467d0fe-1bf6-480d-ae0d-f2e36449d1df");
	
	Set = Sets.Rows.Add();
	Set.Name = "Document_OutgoingEmail";
	Set.ID = New UUID("123329af-4b94-4f47-9d39-e503190487bd");
EndProcedure

#EndRegion

#Region Private

// Returns fields for getting an owner description (if the owner exists).
//
// Parameters:
//  TableName - String - a name of the main table, for which the query is generated.
//
// Returns:
//  String - string that will be inserted into the query.
//
Function FieldNameForOwnerDescription(TableName) Export
	
	ContactsDetailsArray = InteractionsClientServer.ContactsDetails();
	
	For each ArrayDetailsItem In ContactsDetailsArray Do
		If ArrayDetailsItem.Name = TableName AND ArrayDetailsItem.HasOwner Then
			Return "CatalogContact.Owner.Description";
		EndIf;
	EndDo;
	
	Return """""";
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Auxiliary procedures and functions of contact search.

// Returns a list of available kinds of contact search.
//
// Parameters:
//  FTSEnabled         - Boolean - indicates whether a full-text search is available.
//  Parameters - Structure - parameters containing contact Presentation and Address.
//  FormItems - FormItems
//  ForAddressBook - Boolean - true if the list is generated for an address book.
//
// Returns:
//   Structure        - a structure that contains search kinds and search values in them.
//
Function AvailableSearchesList(FTSEnabled, Parameters, FormItems, ForAddressBook) Export
	
	AllSearchLists = New Structure;
	
	If ForAddressBook Then
		Address = "";
		DomainAddress = "";
		SearchByStringOptions = "";
		Presentation = "";
	Else
		Address = Parameters.Address;
		DomainAddress = GetDomainAddressForSearch(Parameters.Address);
		SearchByStringOptions = GetSearchOptionsByString(Parameters.Presentation, Parameters.Address);
		Presentation = Parameters.Presentation;
	EndIf;
	
	AddSearchOption(AllSearchLists, FormItems, "ByEmail", NStr("ru = 'По email'; en = 'By email'; pl = 'By email';de = 'By email';ro = 'By email';tr = 'By email'; es_ES = 'By email'"), Address);
	AddSearchOption(AllSearchLists, FormItems, "ByDomain", NStr("ru = 'По доменному имени'; en = 'By domain name'; pl = 'By domain name';de = 'By domain name';ro = 'By domain name';tr = 'By domain name'; es_ES = 'By domain name'"), DomainAddress);
	
	If Not ForAddressBook
		AND (Parameters.Property("EmailOnly") 
		   AND Not Parameters.EmailOnly) Then
		AddSearchOption(AllSearchLists, FormItems, "ByPhone", NStr("ru = 'По телефону'; en = 'By phone number'; pl = 'By phone number';de = 'By phone number';ro = 'By phone number';tr = 'By phone number'; es_ES = 'By phone number'"), Address);
	EndIf;
	
	If NOT FullTextSearch.GetFullTextSearchMode() = FullTextSearchMode.Disable Then
		FTSEnabled = True;
	EndIf;
	
	If FTSEnabled Then
		AddSearchOption(AllSearchLists, FormItems, "ByLine",
			NStr("ru = 'По строке'; en = 'By line'; pl = 'By line';de = 'By line';ro = 'By line';tr = 'By line'; es_ES = 'By line'"), SearchByStringOptions);
	EndIf;
	
	AddSearchOption(AllSearchLists, FormItems, "BeginsWith", NStr("ru = 'Начинается с'; en = 'Begins with'; pl = 'Begins with';de = 'Begins with';ro = 'Begins with';tr = 'Begins with'; es_ES = 'Begins with'"), Presentation);
	
	Return AllSearchLists;
	
EndFunction

// Adds a search option to an available search list.
//
// Parameters:
//  AllSearchLists - Structure - a search option and this option values are added to it.
//  FormItems - FormItems
//  OptionName - String - a search option name.
//  Presentation - String - a search option presentation.
//  Value        - String - a value for searching this search option.
//
Procedure AddSearchOption(AllSearchLists, FormItems, OptionName, Presentation, Value)
	
	FormItems.SearchOptions.ChoiceList.Add(OptionName, Presentation);
	AllSearchLists.Insert(OptionName, Value);
	
EndProcedure

// Sets a contact as the current one in the "Address book" and "Select contact" forms.
//
// Parameters:
//  Contact - CatalogRef - a contact to be positioned on in the form.
//  Form - ManagedForm - a form, for which the actions are performed.
//
Procedure SetContactAsCurrent(Contact, Form) Export
	
	If TypeOf(Contact) = Type("CatalogRef.Users") Then
		
		Form.Items.PagesLists.CurrentPage = Form.Items.UsersPage;
		Form.Items.UsersList.CurrentRow = Contact;
		
	Else
		
		ContactsDetailsArray = InteractionsClientServer.ContactsDetails();
		ContactMetadataName = Contact.Metadata().Name;
		
		For each DetailsArrayElement In ContactsDetailsArray Do
			If DetailsArrayElement.Name = ContactMetadataName Then
				Form.Items.PagesLists.CurrentPage = 
					Form.Items["Page_" + ?(DetailsArrayElement.HasOwner,
					                               DetailsArrayElement.OwnerName,
					                               DetailsArrayElement.Name)];
				Form.Items["Table_" + DetailsArrayElement.Name].CurrentRow = Contact;
				If DetailsArrayElement.HasOwner Then
					Form.Items["Table_" + DetailsArrayElement.OwnerName].CurrentRow = Contact.Owner;
					CommonClientServer.SetDynamicListFilterItem(
						Form["List_" + DetailsArrayElement.Name],"Owner",Contact.Owner,,,True);
				EndIf;
			ElsIf DetailsArrayElement.OwnerName = ContactMetadataName Then
				Form.Items.PagesLists.CurrentPage = 
					Form.Items["Page_" + DetailsArrayElement.OwnerName];
				CommonClientServer.SetDynamicListFilterItem(
					Form["List_" + DetailsArrayElement.Name],"Owner",Contact,,,True);
			EndIf;
		EndDo;
		
	EndIf;
	
EndProcedure

// Receives a domain address from the email address.
//
// Parameters:
//  Address - String - contains an email address, from which a domain address is retrieved.
//
// Returns:
//   String   - a received domain address.
//
Function GetDomainAddressForSearch(Address)
	
	Row = Address;
	Position = StrFind(Row, "@");
	Return ?(Position = 0, "", Mid(Row, Position+1));
	
EndFunction

// Generates search options by the string.
//
// Parameters:
//  Presentation - String - a contact presentation.
//  Address - String - a contact address.
//
// Returns:
//   ValueList
//
Function GetSearchOptionsByString(Presentation, Address)
	
	If IsBlankString(Presentation) Then
		Return Address;
	ElsIf  IsBlankString(Address) Then
		Return Presentation;
	ElsIf TrimAll(Presentation) = TrimAll(Address) Then
		Return Address;
	EndIf;
	
	SearchOptions = New ValueList;
	Presentation = AddQuotationMarksToString(Presentation);
	Address         = AddQuotationMarksToString(Address);
	SearchOptions.Add(Presentation + " AND " + Address);
	SearchOptions.Add(Presentation + " OR " + Address);
	
	Return SearchOptions;
	
EndFunction

Function AddQuotationMarksToString(SourceString)
	
	
	StringToReturn = TrimAll(SourceString);
	
	If CharCode(Left(TrimAll(StringToReturn), 1)) <> 34 Then
		StringToReturn = """" + StringToReturn;
	EndIf;
	
	If CharCode(Right(TrimAll(StringToReturn), 1)) <> 34 Then
		StringToReturn = StringToReturn + """";
	EndIf;
	
	Return StringToReturn;
	
EndFunction

// Returns an array that contains structures with information about interaction contacts or 
// interaction subject participants.
//
// Parameters:
//  ContactsTable - Document.TabularSection - contains descriptions and references to interaction 
//                     contacts or interaction subject participants.
//
Function ConvertContactsTableToArray(ContactsTable) Export
	
	Result = New Array;
	For Each ArrayElement In ContactsTable Do
		Contact = ?(TypeOf(ArrayElement.Contact) = Type("String"), Undefined, ArrayElement.Contact);
		Record = New Structure(
		"Address, Presentation, Contact", ArrayElement.Address, ArrayElement.Presentation, Contact);
		Result.Add(Record);
	EndDo;
	
	Return Result;
	
EndFunction

// Fills in the "Found contacts" value table of the "Address book" and "Select contact" common forms
// based on the passed value table.
//
// Parameters:
//  ContactsTable - ValueTable - a source value table.
//  FoundContacts - ValueTable - a destination value table.
//
Procedure FillFoundContacts(ContactsTable,FoundContacts) Export
	
	For Each Page In ContactsTable Do
		NewRow = FoundContacts.Add();
		NewRow.Ref               = Page.Contact;
		NewRow.Presentation        = Page.Presentation;
		NewRow.ContactDescription = Page.Description + ?(IsBlankString(Page.OwnerDescription), "", " (" + Page.OwnerDescription + ")");
		NewRow.CatalogName       = Page.Contact.Metadata().Name;
	EndDo;
	
EndProcedure

// Generates an array of metadata of possible contact types.
//
// Returns:
//   Array - an array of metadata of possible contact types.
//
Function MetadataArrayContacts()
	
	ContactsDetailsArray = InteractionsClientServer.ContactsDetails();
	MetadataArray = New Array;
	For each DetailsArrayElement In ContactsDetailsArray Do
	
		MetadataArray.Add(Metadata.Catalogs[DetailsArrayElement.Name]);
	
	EndDo;
	
	Return MetadataArray;
	
EndFunction 

////////////////////////////////////////////////////////////////////////////////
//  Main procedures and functions of contact search.

// Returns a table of all contacts related to the interaction subject.
// Parameters:
//   Subject - an interaction subject.
//   IncludeEmail - return email addresses even if the contact is not defined.
//
// Returns:
//   ValueTable - a value table that contains information about contacts.
//
Function ContactsBySubjectOrChain(Topic, IncludeEmail)
	
	If Not ValueIsFilled(Topic) Then
		Return Undefined;
	EndIf;
	
	QueryText = SearchForContactsByInteractionsChainQueryText(True);
	If Not InteractionsClientServer.IsInteraction(Topic) Then
		ContactsTableName = Topic.Metadata().FullName();
		
		SearchQueryText = "";
		InteractionsOverridable.OnSearchForContacts(ContactsTableName, SearchQueryText);
		
		If IsBlankString(SearchQueryText) Then
			// CAC:223-off For backward compatibility.
			SearchQueryText = InteractionsOverridable.QueryTextContactsSearchBySubject(False, 
				ContactsTableName, True);
			// ACC:223-enable
		EndIf;
		
		QueryText = QueryText + SearchQueryText;
	EndIf;
	
	QueryText = QueryText + QueryTextToGetContactsInformation(IncludeEmail);
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Topic", Topic);
	ContactsTable = Query.Execute().Unload();
	
	ContactsTable.Columns.Add("DescriptionPresentation");
	
	For Each TableRow In ContactsTable Do
		TableRow.DescriptionPresentation = TableRow.Description 
		    + ?(IsBlankString(TableRow.OwnerDescription),
		        "",
		        " (" + TableRow.OwnerDescription + ")");
	EndDo;
	
	Return ContactsTable;
	
EndFunction

// Returns a query text that filters all contacts by an interaction chain.
// Parameters:
//  PutInTempTable - shows whether intermediate results are stored to a temporary table.
//
Function SearchForContactsByInteractionsChainQueryText(PutInTempTable)
	
	SearchList = New ValueList;
	SearchList.Add("Meeting.Members",                                 "Contact");
	SearchList.Add("PlannedInteraction.Members",           "Contact");
	SearchList.Add("PhoneCall",                                  "SubscriberContact");
	SearchList.Add("IncomingEmail",                         "SenderContact");
	SearchList.Add("IncomingEmail.EmailRecipients",        "Contact");
	SearchList.Add("IncomingEmail.CCRecipients",         "Contact");
	SearchList.Add("IncomingEmail.ReplyRecipients",        "Contact");
	SearchList.Add("OutgoingEmail.EmailRecipients",       "Contact");
	SearchList.Add("OutgoingEmail.CCRecipients",        "Contact");
	SearchList.Add("OutgoingEmail.ReplyRecipients",       "Contact");
	SearchList.Add("OutgoingEmail.BccRecipients", "Contact");
	
	QueryText = "";
	TextOnAllowedItems = " ALLOWED";
	TextTempTable = ?(
	PutInTempTable,
	"INTO ContactsTable
	|",
	"");
	TextUnion = "";
	RefsConditionTemplate = ConditionTemplateForRefsToContactsForQuery();
	
	For Each ListItem In SearchList Do
		TableName = ListItem.Value;
		FieldName    = ListItem.Presentation;
		RefsCondition = StrReplace(RefsConditionTemplate, "%FieldName%", FieldName);
		
		QueryText = QueryText + (TextUnion 
		+ "SELECT" + TextOnAllowedItems + " DISTINCT
		|	InteractionContacts." + FieldName + "
		|" + TextTempTable + "FROM
		|	Document." + TableName + " AS InteractionContacts
		|	INNER JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsSubjects
		|	ON InteractionContacts.Ref = InteractionsSubjects.Interaction
		|	WHERE
		|		InteractionsSubjects.Topic = &Topic
		|	AND (" + RefsCondition + ")");
		
		TextOnAllowedItems = "";
		TextTempTable = "";
		TextUnion = "
		|
		|UNION ALL
		|
		|";
		
	EndDo;
	
	Return QueryText;
	
EndFunction

// Returns a table of all contacts related to email.
//
// Parameters:
//  Address - String - an email address to search.
//
// Returns:
//  ValueTable - a value table that contains information about contacts.
//
Function ContactsByEmail(Address)
	
	If IsBlankString(Address) Then
		Return Undefined;
	EndIf;
	
	Query = New Query;
	Query.Text = GenerateQueryTextForSearchByEmail(False);
	
	Query.SetParameter("Address", Address);
	Return Query.Execute().Unload();
	
EndFunction

// Returns a table of all contacts related to the Email list.
//
// Parameters:
//  Address - String - an email address to search.
//
// Returns:
//  QueryResultSelection - query result selection that contains information about contacts.
//
Function GetAllContactsByEmailList(AddressesList) Export
	
	If AddressesList.Count() = 0 Then
		Return Undefined;
	EndIf;
	
	QueryText = GenerateQueryTextForSearchByEmail(True,True);
	
	Query = New Query;
	Query.Text = QueryText;
	
	Query.SetParameter("Address", AddressesList);
	Return Query.Execute().Unload(QueryResultIteration.ByGroups);
	
EndFunction

// Generates a connection string for a query to get information about the contact.
//
// Parameters:
//  IncludeEmail - Boolean - indicates whether email information is included in the query result.
//  CatalogName - String - a name of the catalog, for which the query is being generated.
//
// Returns:
//  String - a query addition.
//
Function ConnectionStringForContactsInformationQuery(IncludeEmail,CatalogName)
	
	If (Not IncludeEmail) OR (NOT CatalogHasTabularSection(CatalogName,"ContactInformation")) Then
		
		Return "";
		
	Else
		
		Return "
		|			LEFT JOIN Catalog."  + CatalogName + ".ContactInformation AS ContactInformationTable
		|			ON CatalogContact.Ref = ContactInformationTable.Ref
		|				AND (ContactInformationTable.Type = VALUE(Enum.ContactInformationTypes.EmailAddress))";
		
	EndIf;
	
EndFunction

// Generates a field selection row to receive in the email address query.
//
// Parameters:
//  IncludeEmail - Boolean - indicates whether it is necessary to get an email address in this query.
//                            
//  CatalogName - Boolean - a name of the catalog, for which the query is being executed.
//  NameField - Boolean - indicates that the query field must be named.
//
// Returns:
//  String - a string complementing a query.
//
Function GetStringWithAddressForContactsInformationQuery(IncludeEmail,CatalogName,NameField = False)
	
	If Not IncludeEmail Then
		
		Return "";
		
	Else
		
		If CatalogHasTabularSection(CatalogName,"ContactInformation")Then
			Return ",
			|	ContactInformationTable.EMAddress";
		Else
			
			Return ",
			|	""""" + ?(NameField," AS EMAddress","");
			
		EndIf;
		
	EndIf;
	
EndFunction

// Generates a text of a query to get information about contacts.
//
// Parameters:
//  IncludeEmail - Boolean - indicates whether it is necessary to get information about email.
//
// Returns:
//   String - a query text.
//
Function QueryTextToGetContactsInformation(IncludeEmail)
	
	ContactsTypesDetailsArray = InteractionsClientServer.ContactsDetails();
	
	QueryText =";
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT ALLOWED
	|	CatalogContact.Ref       AS Ref,
	|	CatalogContact.Description AS Description,
	|	"""" AS OwnerDescription " + GetStringWithAddressForContactsInformationQuery(IncludeEmail,"Users") + "
	|FROM
	|	ContactsTable AS ContactsTable
	|		INNER JOIN Catalog.Users AS CatalogContact" + ConnectionStringForContactsInformationQuery(IncludeEmail,"Users") + "
	|		ON ContactsTable.Contact = CatalogContact.Ref
	|WHERE
	|	(NOT CatalogContact.DeletionMark)
	|";
		
	For each DetailsArrayElement In ContactsTypesDetailsArray Do
		
		If DetailsArrayElement.Name = "Users" Then
			Continue;
		Else
			
			QueryText = QueryText + "
			|UNION
			|
			|SELECT
			|	CatalogContact.Ref,
			|	CatalogContact.Description,
			|	""""" + GetStringWithAddressForContactsInformationQuery(IncludeEmail,DetailsArrayElement.Name) + "
			|FROM
			|	ContactsTable AS ContactsTable
			|		INNER JOIN Catalog." + DetailsArrayElement.Name + " AS CatalogContact"  + ConnectionStringForContactsInformationQuery(IncludeEmail,DetailsArrayElement.Name) + "
			|		ON ContactsTable.Contact = CatalogContact.Ref
			|WHERE
			|	(NOT CatalogContact.DeletionMark)
			|	"+?(DetailsArrayElement.Hierarchical," AND (NOT CatalogContact.Ref.IsFolder)","");
			
		EndIf;
		
	EndDo;
	
	TextOrderBy = "
	|
	|ORDER BY
	|	Description";
	
	QueryText = QueryText + TextOrderBy;
	
	Return QueryText;
	
EndFunction

// Generates a query text for contact search by email.
//
// Parameters:
//  SearchByList - Boolean - indicates that a value array is passed as a parameter.
//
// Returns:
//  String - a query text.
//
Function GenerateQueryTextForSearchByEmail(SearchByList, TotalsByEmail = False)
	
	ContactsTypesDetailsArray = InteractionsClientServer.ContactsDetails();
	
	QueryText =
	"SELECT ALLOWED
	|	ContactInformationTable.Ref AS Contact,
	|	ContactInformationTable.Presentation,
	|	"""" AS OwnerDescription,
	|	ContactInformationTable.Ref.Description AS Description
	|FROM
	|	Catalog.Users.ContactInformation AS ContactInformationTable
	|WHERE
	|	ContactInformationTable.EMAddress = &Address
	|	AND (NOT ContactInformationTable.Ref.DeletionMark)
	|	AND ContactInformationTable.Type = VALUE(Enum.ContactInformationTypes.EmailAddress)";
	
	For each DetailsArrayElement In ContactsTypesDetailsArray Do
		
		If DetailsArrayElement.Name = "Users" Then
			Continue;
		Else
			
			QueryText = QueryText + "
			|UNION ALL
			|
			|SELECT
			|	ContactInformationTable.Ref,
			|	ContactInformationTable.Presentation,
			|	" + ?(DetailsArrayElement.HasOwner," ContactInformationTable.Ref.Owner.Description","""""") + ",
			|	ContactInformationTable.Ref." + DetailsArrayElement.ContactPresentationAttributeName + " AS Description
			|FROM
			|	Catalog." + DetailsArrayElement.Name + ".ContactInformation AS ContactInformationTable
			|WHERE
			|	ContactInformationTable.EMAddress = &Address
			|  AND (NOT ContactInformationTable.Ref.DeletionMark)
			|	AND ContactInformationTable.Type = VALUE(Enum.ContactInformationTypes.EmailAddress)
			|  "+?(DetailsArrayElement.Hierarchical," AND (NOT ContactInformationTable.Ref.IsFolder)","");
			
		EndIf;
		
	EndDo;
	
	QueryText = QueryText + "
	|
	|ORDER BY
	|	Description";
	
	If TotalsByEmail Then
		QueryText = QueryText + "
		|
		|TOTALS BY
		|	Presentation";
	EndIf;
	
	If SearchByList Then
		QueryText = StrReplace(QueryText, "= &Address", "IN (&Address)");
	EndIf;
	
	Return QueryText;
	
EndFunction

// Generates a query text for contact search by phone number and executes it.
//
// Parameters:
//  Phone - String - a string that contains a phone number.
//  Form - ManagedForm - a form, for which the operation is being executed.
//
// Returns:
//  Boolean - True if at least one contact is found.
//
Function GetAllContactsByPhone(Phone,Form) Export
	
	ContactsTypesDetailsArray = InteractionsClientServer.ContactsDetails();
	
	QueryText =
	"SELECT
	|	ContactInformationTable.Ref AS Contact,
	|	SUBSTRING(ContactInformationTable.Presentation, 1, 1000)AS Presentation,
	|	ContactInformationTable.Ref.Description AS Description,
	|	"""" AS OwnerDescription
	|FROM
	|	Catalog.Users.ContactInformation AS ContactInformationTable
	|WHERE
	|	SUBSTRING(ContactInformationTable.Presentation, 1, 100) = &Phone
	|	AND (ContactInformationTable.Type = VALUE(Enum.ContactInformationTypes.Phone)
	|			OR ContactInformationTable.Type = VALUE(Enum.ContactInformationTypes.Fax))
	|  AND (NOT ContactInformationTable.Ref.DeletionMark)
	|";
	
	For each DetailsArrayElement In ContactsTypesDetailsArray Do
		
		If DetailsArrayElement.Name = "Users" Then
			Continue;
		Else
			
			QueryText =QueryText +  "
			|UNION ALL
			|
			|SELECT
			|	ContactInformationTable.Ref,
			|	SUBSTRING(ContactInformationTable.Presentation, 1, 1000),
			|	ContactInformationTable.Ref." + DetailsArrayElement.ContactPresentationAttributeName + " AS Description,
			|	" + ?(DetailsArrayElement.HasOwner," ContactInformationTable.Ref.Owner.Description","""""") + "
			|FROM
			|	Catalog." + DetailsArrayElement.Name + ".ContactInformation AS ContactInformationTable
			|WHERE
			|	SUBSTRING(ContactInformationTable.Presentation, 1, 100) = &Phone
			|	AND (ContactInformationTable.Type = VALUE(Enum.ContactInformationTypes.Phone)
			|			OR ContactInformationTable.Type = VALUE(Enum.ContactInformationTypes.Fax))
			|  AND (NOT ContactInformationTable.Ref.DeletionMark)
			|  "+?(DetailsArrayElement.Hierarchical," AND (NOT ContactInformationTable.Ref.IsFolder)","");
		EndIf;
		
	EndDo;
	
	QueryText = QueryText + "
	|ORDER BY
	|	Description";
	
	Query = New Query;
	Query.Text = QueryText;
	
	Query.SetParameter("Phone", Phone);
	ContactsTable = Query.Execute().Unload();
	
	If ContactsTable = Undefined OR ContactsTable.Count() = 0 Then
		Return False;
	EndIf;
	
	FillFoundContacts(ContactsTable,Form.FoundContacts);
	
	Return True;
	
EndFunction

// Generates a query text to search for contacts by description beginning and runs the query.
//
// Parameters:
//  Description - String - a string that contains the beginning of the contact description.
//
// Returns:
//  ValueTable - an executed query result exported to the value table.
//
Function AllContactsByDescriptionBeginning(Description) Export
	
	ContactsTypesDetailsArray = InteractionsClientServer.ContactsDetails();
	
	QueryText =
	"SELECT
	|	CatalogContact.Ref       AS Contact,
	|	CatalogContact.Description AS Description,
	|	""""                           AS OwnerDescription,
	|	""""                           AS Presentation
	|FROM
	|	Catalog.Users AS CatalogContact
	|WHERE
	|	CatalogContact.Description LIKE &Description
	|	AND (NOT CatalogContact.DeletionMark)
	|";
	
	For each DetailsArrayElement In ContactsTypesDetailsArray Do
		
		If DetailsArrayElement.Name = "Users" Then
			Continue;
		Else
			
			QueryText =QueryText +  "
			|UNION ALL
			|
			|SELECT
			|	CatalogTable.Ref,
			|	CatalogTable." + DetailsArrayElement.ContactPresentationAttributeName + " AS Description,
			|	" + ?(DetailsArrayElement.HasOwner," CatalogTable.Owner.Description","""""") + ",
			|	""""
			|FROM
			|	Catalog." +DetailsArrayElement.Name +" AS CatalogTable
			|WHERE
			|	CatalogTable.Description LIKE &Description "+?(DetailsArrayElement.Hierarchical, " AND (NOT CatalogTable.IsFolder)","")+"
			|	AND (NOT CatalogTable.DeletionMark)";
			
		EndIf;
	
	EndDo;
	
	QueryText = QueryText + "
	|ORDER BY
	|	Description";	
	
	Query = New Query;
	Query.Text = QueryText;
	
	Query.SetParameter("Description", Description + "%");
	Return Query.Execute().Unload(); 
	
EndFunction

// Generates a query text to search for contacts with email addresses by description beginning and 
// runs the query.
//
// Parameters:
//  Description - String - a string that contains the beginning of the contact description.
//  Form - ManagedForm - a form, for which the operation is being executed.
//
// Returns:
//  Boolean - True if at least one contact is found.
//
Function AllContactsByDescriptionBeginningWithEmailAddresses(Description,Form) Export
	
	ContactsTypesDetailsArray = InteractionsClientServer.ContactsDetails();
	
	QueryText =
	" SELECT
	|	CatalogContact.Ref            AS Contact,
	|	CatalogContact.Description      AS Description,
	|	""""                                AS OwnerDescription,
	|	ContactInformationTable.EMAddress AS Presentation
	|FROM
	|	Catalog.Users AS CatalogContact
	|		LEFT JOIN Catalog.Users.ContactInformation AS ContactInformationTable
	|		ON (ContactInformationTable.Ref = CatalogContact.Ref)
	|			AND (ContactInformationTable.Type = VALUE(Enum.ContactInformationTypes.EmailAddress))
	|WHERE
	|	CatalogContact.Description LIKE &Description
	|	AND (NOT CatalogContact.DeletionMark)";
	
	For each DetailsArrayElement In ContactsTypesDetailsArray Do
		
		If DetailsArrayElement.Name = "Users" Then
			Continue;
		Else
			
			QueryText =QueryText +  "
			|UNION ALL
			|
			|SELECT
			|	CatalogTable.Ref,
			|	CatalogTable." + DetailsArrayElement.ContactPresentationAttributeName + " AS Description,
			|	" + ?(DetailsArrayElement.HasOwner," CatalogTable.Owner.Description","""""") + ",
			|	ContactInformationTable.EMAddress
			|FROM
			|	Catalog." +DetailsArrayElement.Name +" AS CatalogTable
			|		LEFT JOIN Catalog." + DetailsArrayElement.Name + ".ContactInformation AS ContactInformationTable
			|		ON (ContactInformationTable.Ref = CatalogTable.Ref)
			|			AND (ContactInformationTable.Type = VALUE(Enum.ContactInformationTypes.EmailAddress))
			|WHERE
			|	CatalogTable.Description LIKE &Description "+?(DetailsArrayElement.Hierarchical," AND (NOT CatalogTable.IsFolder)","")+"
			|	AND (NOT CatalogTable.DeletionMark)";
			
		EndIf;
	
	EndDo;
	
	QueryText = QueryText + "
	|
	|ORDER BY
	|	Description";
	
	Query = New Query;
	Query.Text = QueryText;
	
	Query.SetParameter("Description", Description + "%");
	ContactsTable = Query.Execute().Unload(); 
	
	If ContactsTable = Undefined OR ContactsTable.Count() = 0 Then
		Return False;
	EndIf;
	
	FillFoundContacts(ContactsTable,Form.FoundContacts);
	Return True;
	
EndFunction

// Generates a condition template for the query whether the field to be received in the query matches a possible contact type.
//
// Returns:
//  String - a generated condition template text.
//
Function ConditionTemplateForRefsToContactsForQuery()
	
	ContactsTypesDetailsArray = InteractionsClientServer.ContactsDetails();
	
	TextToReturn =  "InteractionContacts.%FieldName% REFS Catalog.Users";
	
	For each DetailsArrayElement In ContactsTypesDetailsArray Do
	
		If DetailsArrayElement.Name = "Users" Then
			Continue;
		Else
			TextToReturn = TextToReturn + "
			|OR InteractionContacts.%FieldName% REFS Catalog." + DetailsArrayElement.Name;
		EndIf;
	
	EndDo;
		
	Return TextToReturn;
	
EndFunction

// Searches for contacts by an email or an email domain.
//
// Parameters:
//  SearchString - String - a basis for search.
//  ByDomain     - Boolean - indicates that the search must be carried out by a domain.
//  Form - ManagedForm - a form, for which the operation is being executed.	
//
// Returns:
//  Boolean - True if at least one contact is found.
//
Function FindByEmail(SearchString, ByDomain, Form) Export
	
	If ByDomain Then
		ContactsTable = ContactsByDomainAddress(SearchString);
	Else
		ContactsTable = ContactsByEmail(SearchString);
	EndIf;
	
	If ContactsTable = Undefined OR ContactsTable.Count() = 0 Then
		Return False;
	EndIf;
	
	FillFoundContacts(ContactsTable, Form.FoundContacts);
	
	Return True;
	
EndFunction

// Returns contacts by a domain address.
//
// Parameters:
//  DomainName - String - a domain name, by which a search is being carried out.
//
// Returns:
//  ValueTable - a table that contains information about the found contacts.
//
Function ContactsByDomainAddress(DomainName)
	
	If IsBlankString(DomainName) Then
		Return Undefined;
	EndIf;
	
	FirstTable = True;
	QueryText = "";
	
	ContactsDetailsArray = InteractionsClientServer.ContactsDetails();
	For each DetailsArrayElement In ContactsDetailsArray Do
		
		If DetailsArrayElement.SearchByDomain Then
			
			If FirstTable Then
				
				QueryText = QueryText + "SELECT DISTINCT ALLOWED ";
				
			Else
				
				QueryText = QueryText + "
				|UNION ALL
				|
				|SELECT";
				
			EndIf;
			
			QueryText = QueryText + "
			|	ContactInformationTable.Ref AS Contact,
			|	ContactInformationTable.Ref." + DetailsArrayElement.ContactPresentationAttributeName + " AS Description,
			|	ContactInformationTable.EMAddress AS Presentation,
			|	" + ?(DetailsArrayElement.HasOwner,"ContactInformationTable.Ref.Owner.Description ","""""") + ?(FirstTable," AS OwnerDescription ","") +" 
			|FROM
			|	Catalog." + DetailsArrayElement.Name + ".ContactInformation AS ContactInformationTable
			|WHERE
			|	ContactInformationTable.EMAddress LIKE &SearchString";
			
			FirstTable = False;
		EndIf;	
	EndDo;
	
	If NOT FirstTable Then
		QueryText = QueryText + "
		|ORDER BY
		|	Ref,
		|	EMAddress";
	Else
		Return Undefined;
	EndIf;	
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("SearchString", "%@" + DomainName);
	
	Return Query.Execute().Unload();
	
EndFunction

// Searches for contacts by a string.
//
// Parameters:
//  Form - ManagedForm - a form, for which search is performed.
//  ForAddressBook - Boolean - indicates whether the search is carried out for the address book.
//
// Returns:
//  String - a message for a user about search results if necessary.
//
Function ExecuteContactsSearchByString(Form,ForAddressBook = False) Export
	
	Form.FoundContacts.Clear();
	
	If IsBlankString(Form.SearchString) Then
		Return "";
	EndIf;
	
	If FullTextSearch.GetFullTextSearchMode() = FullTextSearchMode.Disable
		OR NOT GetFunctionalOption("UseFullTextSearch") Then
		Return NStr("ru = 'Использование индекса полнотекстового поиска данных запрещено.'; en = 'Full-text search index use is prohibited.'; pl = 'Full-text search index use is prohibited.';de = 'Full-text search index use is prohibited.';ro = 'Full-text search index use is prohibited.';tr = 'Full-text search index use is prohibited.'; es_ES = 'Full-text search index use is prohibited.'");
	EndIf;
	
	MetadataArray = MetadataArrayContacts();
	
	SearchList = FullTextSearch.CreateList(Form.SearchString, 101);
	SearchList.SearchArea = MetadataArray;

	Try
		SearchList.FirstPart();
	Except
		Return NStr("ru = 'При выполнении поиска произошла ошибка, попробуйте изменить выражение поиска.'; en = 'An error occurred when performing search. Try to modify the search expression.'; pl = 'An error occurred when performing search. Try to modify the search expression.';de = 'An error occurred when performing search. Try to modify the search expression.';ro = 'An error occurred when performing search. Try to modify the search expression.';tr = 'An error occurred when performing search. Try to modify the search expression.'; es_ES = 'An error occurred when performing search. Try to modify the search expression.'");
	EndTry;
	
	FoundItemsCount = SearchList.Count();
	If FoundItemsCount = 0 Then
		Return "";
	EndIf;
	
	RefsArray = New Array;
	DetailsMap = New Map;
	For Ind = 0 To Min(FoundItemsCount, 100)-1 Do
		ListItem = SearchList.Get(Ind);
		RefsArray.Add(ListItem.Value);
		DetailsMap.Insert(ListItem.Value, ListItem.Description);
	EndDo;
	
	If ForAddressBook Then
		QueryText = GetSearchForContactsQueryTextByEmailString();
	Else	
		QueryText = GetSearchForContactsByStringQueryText();
	EndIf;
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("RefsArray", RefsArray);
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		NewRow = Form.FoundContacts.Add();
		NewRow.Ref = Selection.Contact;
		NewRow.Presentation = ?(ForAddressBook ,Selection.Presentation,DetailsMap.Get(Selection.Contact));
		NewRow.ContactDescription = Selection.Description 
		          + ?(IsBlankString(Selection.OwnerDescription),
		              "",
		              " (" + Selection.OwnerDescription + ")");
	EndDo;
	
	Return ?(FoundItemsCount < 101, "", NStr("ru = 'Уточните параметры поиска. В списке отображены не все найденные контакты.'; en = 'Review search parameters. Not all found contacts are displayed in the list.'; pl = 'Review search parameters. Not all found contacts are displayed in the list.';de = 'Review search parameters. Not all found contacts are displayed in the list.';ro = 'Review search parameters. Not all found contacts are displayed in the list.';tr = 'Review search parameters. Not all found contacts are displayed in the list.'; es_ES = 'Review search parameters. Not all found contacts are displayed in the list.'"));
	
EndFunction

// Generates a query text for contact search by a string.
//
// Returns:
//  String - a query text.
//
Function GetSearchForContactsByStringQueryText()
	
	ContactsTypesDetailsArray = InteractionsClientServer.ContactsDetails();
	
	QueryText =
	"SELECT DISTINCT ALLOWED
	|	CatalogTable.Ref AS Contact,
	|	CatalogTable.Description AS Description,
	|	"""" AS OwnerDescription,
	|	"""" AS Presentation
	|FROM
	|	Catalog.Users AS CatalogTable
	|WHERE
	|	CatalogTable.Ref IN(&RefsArray)
	|	AND (NOT CatalogTable.DeletionMark)";
	
	For each DetailsArrayElement In ContactsTypesDetailsArray Do
		
		If DetailsArrayElement.Name = "Users" Then
			Continue;
		EndIf;
		
		QueryText =QueryText +  "
		|UNION ALL
		|
		|SELECT
		|	CatalogTable.Ref,
		|	CatalogTable." + DetailsArrayElement.ContactPresentationAttributeName + " AS Description,
		|	" + ?(DetailsArrayElement.HasOwner," CatalogTable.Owner.Description","""""") + ",
		|	""""
		|FROM
		|	Catalog." +DetailsArrayElement.Name +" AS CatalogTable
		|WHERE
		|	CatalogTable.Ref IN(&RefsArray) "+?(DetailsArrayElement.Hierarchical," AND (NOT CatalogTable.IsFolder)","")+"
		|	AND (NOT CatalogTable.DeletionMark)";
		
	EndDo;
	
	QueryText = QueryText + "
	|
	|ORDER BY
	|	Description";
	
	Return QueryText;
	
EndFunction

// Generates a query text to search contacts by a row with getting information on email addresses.
//
// Returns:
//  String - a query text.
//
Function GetSearchForContactsQueryTextByEmailString()
	
	ContactsTypesDetailsArray = InteractionsClientServer.ContactsDetails();
	
	QueryText =
	"SELECT DISTINCT ALLOWED
	|	CatalogTable.Ref AS Contact,
	|	CatalogTable.Description AS Description,
	|	"""" AS OwnerDescription,
	|	ContactInformationTable.EMAddress AS Presentation
	|FROM
	|	Catalog.Users AS CatalogTable
	|		LEFT JOIN Catalog.Users.ContactInformation AS ContactInformationTable
	|		ON (ContactInformationTable.Ref = CatalogTable.Ref)
	|			AND (ContactInformationTable.Type = VALUE(Enum.ContactInformationTypes.EmailAddress))
	|WHERE
	|	CatalogTable.Ref IN(&RefsArray)
	|	AND (NOT CatalogTable.DeletionMark)";
	
	For each DetailsArrayElement In ContactsTypesDetailsArray Do
		
		If DetailsArrayElement.Name = "Users" Then
			Continue;
		EndIf;
		
		QueryText =QueryText + "
		|UNION ALL
		|
		|SELECT
		|	CatalogTable.Ref,
		|	CatalogTable." + DetailsArrayElement.ContactPresentationAttributeName + " AS Description,
		|	" + ?(DetailsArrayElement.HasOwner," CatalogTable.Owner.Description","""""") + ",
		|	ContactInformationTable.EMAddress
		|FROM
		|	Catalog." +DetailsArrayElement.Name +" AS CatalogTable
		|		LEFT JOIN Catalog." + DetailsArrayElement.Name + ".ContactInformation AS ContactInformationTable
		|		ON (ContactInformationTable.Ref = CatalogTable.Ref)
		|			AND (ContactInformationTable.Type = VALUE(Enum.ContactInformationTypes.EmailAddress))
		|WHERE
		|	CatalogTable.Ref IN(&RefsArray) "+?(DetailsArrayElement.Hierarchical," AND (NOT CatalogTable.IsFolder)","")+"
		|	AND (NOT CatalogTable.DeletionMark)";
		
	EndDo;
	
	QueryText = QueryText + "
	|
	|ORDER BY
	|	Description";
	
	Return QueryText;
	
EndFunction

// Gets contacts by an interaction subject, sets a contact search page by the subject as the current 
// page of the search form.
//
// Parameters:
//  FormItems - ManagedFormItemsCollection - grants access to form items.
//  Subject            - CatalogRef, DocumentRef - an interaction subject.
//  ContactsBySubject - ValueTable - a form attribute, in which found contacts are placed.
//  IncludeEmail - Boolean - indicates whether it is necessary to get data on a contact email address.
//
Procedure FillContactsBySubject(FormItems, Topic, ContactsBySubject, IncludeEmail) Export
	
	If Not ValueIsFilled(Topic) Then
		FormItems.AllContactsBySubjectPage.Visible = False;
		Return;
	EndIf;
	
	ContactsTable = ContactsBySubjectOrChain(Topic, IncludeEmail);
	If (ContactsTable = Undefined) OR (ContactsTable.Count() = 0) Then
		FormItems.AllContactsBySubjectPage.Visible = False;
		Return;
	EndIf;
	
	For Each TableRow In ContactsTable Do
		NewRow = ContactsBySubject.Add();
		NewRow.Ref = TableRow.Ref;
		NewRow.Description = TableRow.Description;
		NewRow.CatalogName = TableRow.Ref.Metadata().Name;
		NewRow.DescriptionPresentation = TableRow.DescriptionPresentation;
		If IncludeEmail Then
			NewRow.Address = TableRow.EMAddress;
		EndIf;
	EndDo;
	
	FormItems.PagesLists.CurrentPage = FormItems.AllContactsBySubjectPage;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////////
//  Procedures and functions for getting contact data, interactions, and interaction subjects.

// Returns a reference to the current interaction subject.
// Parameters:
//  Ref - an interaction reference.
//
// Returns:
//  CatalogObject, DocumentObject - an interaction subject.
//
Function GetSubjectValue(Ref) Export

	Attributes = InteractionAttributesStructure(Ref);
	Return ?(Attributes = Undefined, Undefined, Attributes.Topic);
	
EndFunction

// Returns a structure of additional interaction attributes stored in the Subjects register and interaction folders.
// Parameters:
//  Ref - an interaction reference.
//
// Returns:
//  Structure - a structure that contains additional attributes.
//
Function InteractionAttributesStructure(Ref) Export
	
	ReturnStructure = InformationRegisters.InteractionsFolderSubjects.InteractionAttributes();
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	InteractionsFolderSubjects.Topic,
	|	InteractionsFolderSubjects.EmailMessageFolder AS Folder,
	|	InteractionsFolderSubjects.Reviewed,
	|	InteractionsFolderSubjects.ReviewAfter
	|FROM
	|	InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
	|WHERE
	|	InteractionsFolderSubjects.Interaction = &Interaction";
	
	Query.SetParameter("Interaction", Ref);
	
	Result = Query.Execute();
	If NOT Result.IsEmpty() Then
		Selection = Result.Select();
		Selection.Next();
		FillPropertyValues(ReturnStructure, Selection);
	EndIf;
	
	Return ReturnStructure;
	
EndFunction

// Returns a reference to the current email folder.
// Parameters:
//  Ref - an interaction reference.
//
// Returns:
//  CatalogObject, DocumentObject - an interaction subject.
//
Function GetEmailFolder(Email) Export
	
	Query = New Query;
	Query.Text = "SELECT ALLOWED
	|	InteractionsSubjects.EmailMessageFolder
	|FROM
	|	InformationRegister.InteractionsFolderSubjects AS InteractionsSubjects
	|WHERE
	|	InteractionsSubjects.Interaction = &Interaction";
	
	Query.SetParameter("Interaction",Email);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return Catalogs.EmailMessageFolders.EmptyRef();
	Else
		Selection = Result.Select();
		Selection.Next();
		Return Selection.EmailMessageFolder;
	EndIf;
	
EndFunction

// Receives values of interaction document attributes stored in the register and sets them to the 
//  corresponding form attributes.
// Parameters:
//  Form - ManagedForm - an interaction document form.
//
Procedure SetInteractionFormAttributesByRegisterData(Form) Export
	
	AttributesStructure = InteractionAttributesStructure(Form.Object.Ref);
	FillPropertyValues(Form, AttributesStructure, "Topic, Reviewed, ReviewAfter");
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////
//  Procedures and functions for handling interactions.

// Receives a description array of all possible contacts and generates a list of contact values, 
// which can be created interactively.
//
// Returns:
//  ValueList - a value list containing contacts that can be created manually.
//
Function CreateValueListOfInteractivelyCreatedContacts() Export
	
	PossibleContactsTypesDetailsArray = InteractionsClientServer.ContactsDetails();
	ListOfContactsThatCanBeCreated = New ValueList;
	
	For each ArrayElement In PossibleContactsTypesDetailsArray Do
		
		If ArrayElement.InteractiveCreationPossibility AND AccessRight("Insert", Metadata.Catalogs[ArrayElement.Name])Then
			
			ListOfContactsThatCanBeCreated.Add(ArrayElement.Name, ArrayElement.Presentation);
			
		EndIf;
		
	EndDo;
	
	Return ListOfContactsThatCanBeCreated;
	
EndFunction

// Sets an interaction subject by data on the interaction document filling.
//
// Parameters:
//  Parameters - Structure - parameters passed upon an interaction document creation.
//  Subject - DocumentRef, CatalogRef - an interaction subject is set to this procedure according to 
//              the filling data.
//
Procedure SetSubjectByFillingData(Parameters,Topic) Export
	
	If Parameters.Property("Topic")
		AND ValueIsFilled(Parameters.Topic)
		AND (InteractionsClientServer.IsSubject(Parameters.Topic)
		  Or InteractionsClientServer.IsInteraction(Parameters.Basis)) Then
		
		Topic = Parameters.Topic;
		
	ElsIf InteractionsClientServer.IsSubject(Parameters.Basis) Then
		
		Topic = Parameters.Basis;
		
	ElsIf InteractionsClientServer.IsInteraction(Parameters.Basis) Then
		
		Topic = GetSubjectValue(Parameters.Basis);
		
	ElsIf TypeOf(Parameters.Basis) = Type("Structure") AND Parameters.Basis.Property("Base") 
		AND InteractionsClientServer.IsInteraction(Parameters.Basis.Base) Then
		
		Topic = GetSubjectValue(Parameters.Basis.Base);
		
	ElsIf Parameters.FillingValues.Property("Topic") Then
		
		Topic = Parameters.FillingValues.Topic;
		
	ElsIf Not Parameters.CopyingValue.IsEmpty() Then
		
		Topic = GetSubjectValue(Parameters.CopyingValue);
		
	EndIf;
	
EndProcedure

// Generates an array of interaction document participants by a document tabular section.
//
// Parameters:
//  Ref - DocumentRef - a reference to the interaction document.
//
// Returns:
//  Array - an array of structures that contain information about contacts.
//
Function GetParticipantsByTable(Ref) Export
	
	FullObjectName = Ref.Metadata().FullName();
	TableName = ?(TypeOf(Ref) = Type("DocumentRef.SMSMessage"), "Recipients", "Members");
	
	QueryText =
	"SELECT
	|	Members.Contact,
	|	Members.ContactPresentation AS Presentation,
	|	Members.HowToContact AS Address
	|FROM
	|	" + FullObjectName + "." + TableName + " AS Members
	|WHERE
	|	Members.Ref = &Ref";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Ref", Ref);
	
	Return ConvertContactsTableToArray(Query.Execute().Unload());
	
EndFunction

// Generates an array of interaction participant containing one structure by the passed fields.
//
// Parameters:
//  Ref - DocumentRef - a reference to the interaction document.
//
// Returns:
//  Array - an array of structures that contain information about contacts.
//
Function GetParticipantByFields(Contact, Address, Presentation) Export
	
	ContactStructure = New Structure("Contact, Address, Presentation", Contact, Address, Presentation);
	ArrayToGenerate = New Array;
	ArrayToGenerate.Add(ContactStructure);
	Return ArrayToGenerate;
	
EndFunction

// Checks whether the incoming array contains at least one element.
//
// Parameters:
//  Contacts - Array
//
// Returns:
//  Boolean - True if it contains, otherwise, False.
//
Function ContactsFilled(Contacts) Export
	
	Return (ValueIsFilled(Contacts) AND (Contacts.Count() > 0));
	
EndFunction

// Fills the participants tabular section for the Meeting and Planned interaction documents.
//
// Parameters:
//  Contacts - Array - an array containing interaction participants.
//  Members - DocumentTabularSection - a document tabular section to be filled in based on the array.
//                                        
//
Procedure FillContactsForMeeting(Contacts, Members, ContactInformationType = Undefined) Export
	
	If Not ContactsFilled(Contacts) Then
		Return;
	EndIf;
	
	For Each ArrayElement In Contacts Do
		
		NewRow = Members.Add();
		If TypeOf(ArrayElement) = Type("Structure") Then
			NewRow.Contact = ArrayElement.Contact;
			NewRow.ContactPresentation = ArrayElement.Presentation;
			NewRow.HowToContact = ConvertAddressByInformationType(ArrayElement.Address, ContactInformationType);
		Else
			NewRow.Contact = ArrayElement;
		EndIf;
		
		FinishFillingContactsFields(NewRow.Contact, NewRow.ContactPresentation, NewRow.HowToContact, ContactInformationType);
		
	EndDo;
	
EndProcedure

Function ConvertAddressByInformationType(Address, ContactInformationType = Undefined)
	
	If ContactInformationType = Undefined Or IsBlankString(Address) Then
		Return Address;
	EndIf;
	
	If ContactInformationType <> Enums.ContactInformationTypes.Phone Then
		Return Address
	EndIf;
		
	RowsArrayWithPhones = New Array;
	For Each ArrayElement In StrSplit(Address, ";", False) Do
		If PhoneNumberSpecifiedCorrectly(ArrayElement) Then
			RowsArrayWithPhones.Add(ArrayElement);
		EndIf;
	EndDo;
	
	If RowsArrayWithPhones.Count() > 0 Then
		Return StrConcat(RowsArrayWithPhones, ";");
	EndIf;
	
EndFunction

Function NumberToSendFormattingResult(Number) Export
	
	Result = "";
	AllowedChars = "+1234567890";
	For Position = 1 To StrLen(Number) Do
		Char = Mid(Number,Position,1);
		If StrFind(AllowedChars, Char) > 0 Then
			Result = Result + Char;
		EndIf;
	EndDo;
	
	If StrLen(Result) > 10 Then
		FirstChar = Left(Result, 1);
		If FirstChar = "8" Then
			Result = "+7" + Mid(Result, 2);
		ElsIf FirstChar <> "+" Then
			Result = "+" + Result;
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

// Fills in other field values in rows of the interaction document participants tabular section.
//
// Parameters:
//  Contact - CatalogRef - a contact based on whose data other fields will be filled in.
//  Presentation - String - a contact presentation.
//  Address - String - a contact information of the contact.
//  ContactInformationType - Enums.ContactInformationTypes - the contact information of the contact.
//
Procedure FinishFillingContactsFields(Contact, Presentation, Address, ContactInformationType = Undefined) Export
	
	If Not ValueIsFilled(Contact) Then
		Return;
	ElsIf Not IsBlankString(Presentation) AND Not IsBlankString(Address) Then
		Return;
	EndIf;
	
	// For all types except for email.
	If ContactInformationType <> Enums.ContactInformationTypes.EmailAddress Then
		
		If IsBlankString(Address) Then
			InteractionsServerCall.PresentationAndAllContactInformationOfContact(
				Contact, Presentation, Address, ContactInformationType);
		EndIf;
	
	Else
		
		// Checking whether the email address is filled in.
		If StrFind(Address, "@") <> 0 Then
			Return;
		EndIf;
	
		Addresses = InteractionsServerCall.ContactDescriptionAndEmailAddresses(Contact);
		If Addresses <> Undefined AND Addresses.Addresses.Count() > 0 Then
			Item = Addresses.Addresses.Get(0);
			Address         = Item.Value;
			Presentation = Addresses.Description;
		EndIf;
		
	EndIf;
	
EndProcedure

// Generates a presentation string of the interaction participant list.
//
// Parameters:
//  Object - DocumentObject - a string is generated based on the participants tabular section of this document.
//
Procedure GenerateParticipantsList(Object) Export
	
	If  TypeOf(Object) = Type("DocumentObject.SMSMessage") Then
		TableName = "Recipients";
	Else 
		TableName = "Members";
	EndIf;
	
	Object.ParticipantsList = "";
	For Each Member In Object[TableName] Do
		Object.ParticipantsList = Object.ParticipantsList + ?(Object.ParticipantsList = "", "", "; ") + Member.ContactPresentation;
	EndDo;
	
EndProcedure

// Generates a selection list for quick filter by an interaction type using the email client only.
//
// Parameters:
//  Item - FormItem - an item, for which the selection list is being generated.
//
Procedure GenerateChoiceListInteractionTypeEmailOnly(Item)
	
	Item.ChoiceList.Clear();
	Item.ChoiceList.Add("AllMessages", NStr("ru = 'Все письма'; en = 'All emails'; pl = 'All emails';de = 'All emails';ro = 'All emails';tr = 'All emails'; es_ES = 'All emails'"));
	Item.ChoiceList.Add("IncomingMessages", NStr("ru = 'Входящие'; en = 'Incoming'; pl = 'Incoming';de = 'Incoming';ro = 'Incoming';tr = 'Incoming'; es_ES = 'Incoming'"));
	Item.ChoiceList.Add("MessageDrafts", NStr("ru = 'Черновики'; en = 'Drafts'; pl = 'Drafts';de = 'Drafts';ro = 'Drafts';tr = 'Drafts'; es_ES = 'Drafts'"));
	Item.ChoiceList.Add("OutgoingMessages", NStr("ru = 'Исходящие'; en = 'Outgoing'; pl = 'Outgoing';de = 'Outgoing';ro = 'Outgoing';tr = 'Outgoing'; es_ES = 'Outgoing'"));
	Item.ChoiceList.Add("Sent", NStr("ru = 'Отправленные'; en = 'Sent'; pl = 'Sent';de = 'Sent';ro = 'Sent';tr = 'Sent'; es_ES = 'Sent'"));
	Item.ChoiceList.Add("DeletedMessages", NStr("ru = 'Удаленные'; en = 'DeletedItems'; pl = 'DeletedItems';de = 'DeletedItems';ro = 'DeletedItems';tr = 'DeletedItems'; es_ES = 'DeletedItems'"));
	
EndProcedure

// Gets email addresses for a contact array.
//
// Parameters:
//  ContactsArray - Array - an array of references to contacts.
//  Group - String - a group name in the email, for which addresses are searched. For example, Recipients, Copy recipients.
//
// Returns:
//   ValueTable - a table containing contacts and their email addresses.
//
Function GetEmailAddressesForContactsArray(ContactsArray,Folder = "") Export
	
	If ContactsArray.Count() = 0 Then
		Return Undefined;
	EndIf;
	
	ContactsTypesDetailsArray = InteractionsClientServer.ContactsDetails();
	
	QueryText = "
	|SELECT ALLOWED DISTINCT
	|	ContactInformationTable.EMAddress AS Address,
	|	ContactTable.Ref AS Contact
	|INTO AddressContacts
	|FROM
	|	Catalog.Users AS ContactTable
	|		LEFT JOIN Catalog.Users.ContactInformation AS ContactInformationTable
	|		ON (ContactInformationTable.Ref = ContactTable.Ref)
	|			AND (ContactInformationTable.Type = VALUE(Enum.ContactInformationTypes.EmailAddress))
	|WHERE
	|	ContactTable.Ref IN (&ContactsArray)
	|
	|UNION ALL
	|
	|SELECT
	|	ContactInformationTable.EMAddress AS Address,
	|	ContactTable.Ref AS Contact
	|FROM
	|	Catalog.Users AS ContactTable
	|		LEFT JOIN Catalog.Users.ContactInformation AS ContactInformationTable
	|		ON (ContactInformationTable.Ref = ContactTable.Ref)
	|			AND (ContactInformationTable.Type = VALUE(Enum.ContactInformationTypes.EmailAddress))
	|WHERE
	|	 TRUE IN
	|		(SELECT
	|			TRUE
	|		FROM
	|			InformationRegister.UserGroupCompositions AS UserGroupCompositions
	|		WHERE
	|			UserGroupCompositions.User = ContactTable.Ref
	|			AND UserGroupCompositions.UsersGroup IN (&ContactsArray))";
	
	For each DetailsArrayElement In ContactsTypesDetailsArray Do
		
		If DetailsArrayElement.Name = "Users" Then
			Continue;
		Else
			
			QueryText = QueryText + "
			|UNION ALL
			|
			|SELECT
			|	ContactInformationTable.EMAddress,
			|	ContactTable.Ref
			|FROM
			|	Catalog." + DetailsArrayElement.Name + " AS ContactTable
			|		LEFT JOIN Catalog." + DetailsArrayElement.Name + ".ContactInformation AS ContactInformationTable
			|		ON (ContactInformationTable.Ref = ContactTable.Ref)
			|			AND (ContactInformationTable.Type = VALUE(Enum.ContactInformationTypes.EmailAddress))
			|WHERE
			|	ContactTable.Ref IN(&ContactsArray) " + ?(DetailsArrayElement.Hierarchical," AND NOT ContactTable.IsFolder","");
			
		EndIf;
		
	EndDo;
	
	QueryText = QueryText + "
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	AddressContacts.Contact,
	|	PRESENTATION(AddressContacts.Contact) AS Presentation,
	|	&Group
	|FROM
	|	AddressContacts AS AddressContacts
	|ORDER BY
	|	Contact
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AddressContacts.Contact AS Contact,
	|	AddressContacts.Address AS Address
	|FROM
	|	AddressContacts AS AddressContacts
	|ORDER BY
	|	Contact
	|TOTALS
	|BY
	|	Contact
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("ContactsArray",ContactsArray);
	Query.SetParameter("Group",Folder);
	Result = Query.ExecuteBatch();
	
	ResultTable = Result[1].Unload();
	
	TypesArray = New Array;
	TypesArray.Add(Type("String"));
	
	ResultTable.Columns.Add("Address", New TypeDescription(TypesArray, , New StringQualifiers(100)));
	ResultTable.Columns.Add("AddressesList",New TypeDescription(TypesArray));
	ContactsSelection = Result[2].Select(QueryResultIteration.ByGroups);
	
	For each TableRow In ResultTable Do
		ContactsSelection.Next();
		AddressesSelection = ContactsSelection.Select();
		While AddressesSelection.Next() Do
			If IsBlankString(TableRow.Address) Then
				TableRow.Address = AddressesSelection.Address;
			EndIf;
			TableRow.AddressesList = TableRow.AddressesList + ?(IsBlankString(TableRow.AddressesList), "", ";") + AddressesSelection.Address;
		EndDo;
	EndDo;
	
	Return ResultTable;
	
EndFunction

// Gets user session parameters for an outgoing email.
//
// Parameters:
//  Account - CatalogRef.EmailAccounts - an account to be used to send the email.
//  MessageFormat - EnumRef.EmailsEditOptions - an email format.
//  ForNewEmail - Boolean - indicates whether an outgoing email is being created.
//
// Returns:
//   Structure - a structure containing user session parameters for an outgoing email.
//
Function GetUserParametersForOutgoingEmail(EmailAccount,MessageFormat,ForNewEmail) Export
	
	ReturnStructure = New Structure;
	ReturnStructure.Insert("Signature", Undefined);
	ReturnStructure.Insert("RequestDeliveryReceipt", False);
	ReturnStructure.Insert("RequestReadReceipt", False);
	ReturnStructure.Insert("DisplaySourceEmailBody", False);
	ReturnStructure.Insert("IncludeOriginalEmailBody", False);
	
	EmailOperationSettings = GetEmailOperationsSetting();
	EnableSignature = False;

	If ForNewEmail Then
		
		Query = New Query;
		Query.Text = "SELECT
		|	EmailAccountSignatures.AddSignatureForNewMessages,
		|	EmailAccountSignatures.NewMessageSignatureFormat,
		|	EmailAccountSignatures.SignatureForNewMessagesFormattedDocument,
		|	EmailAccountSignatures.SignatureForNewMessagesPlainText
		|FROM
		|	InformationRegister.EmailAccountSettings AS EmailAccountSignatures
		|WHERE
		|	EmailAccountSignatures.EmailAccount = &EmailAccount";
		
		Query.SetParameter("EmailAccount",EmailAccount);
		
		Result = Query.Execute();
		If NOT Result.IsEmpty() Then
			Selection = Result.Select();
			Selection.Next();
			
			EnableSignature = Selection.AddSignatureForNewMessages;
			If EnableSignature Then
				SignatureFormat                  = Selection.NewMessageSignatureFormat;
				SignaturePlainText            = Selection.SignatureForNewMessagesPlainText;
				SignatureFormattedDocument = Selection.SignatureForNewMessagesFormattedDocument.Get();
			EndIf;
			
		EndIf;
		
		If Not EnableSignature Then
			EnableSignature = ?(EmailOperationSettings.Property("AddSignatureForNewMessages"),
			                    EmailOperationSettings.AddSignatureForNewMessages,
			                    False);
			
			If EnableSignature Then
			
				SignatureFormat                  = EmailOperationSettings.NewMessageSignatureFormat;
				SignaturePlainText            = EmailOperationSettings.SignatureForNewMessagesPlainText;
				SignatureFormattedDocument = EmailOperationSettings.NewMessageFormattedDocument;
			
			EndIf;
		EndIf;
		
	Else
		
		Query = New Query;
		Query.Text = "SELECT
		|	EmailAccountSignatures.AddSignatureOnReplyForward,
		|	EmailAccountSignatures.ReplyForwardSignatureFormat,
		|	EmailAccountSignatures.ReplyForwardSignaturePlainText,
		|	EmailAccountSignatures.ReplyForwardSignatureFormattedDocument
		|FROM
		|	InformationRegister.EmailAccountSettings AS EmailAccountSignatures
		|WHERE
		|	EmailAccountSignatures.EmailAccount = &EmailAccount";
		
		Query.SetParameter("EmailAccount",EmailAccount);
		
		Result = Query.Execute();
		If NOT Result.IsEmpty() Then
			
			Selection = Result.Select();
			Selection.Next();
			
			EnableSignature = Selection.AddSignatureOnReplyForward;
			If EnableSignature Then
				SignatureFormat                  = Selection.ReplyForwardSignatureFormat;
				SignaturePlainText            = Selection.ReplyForwardSignaturePlainText;
				SignatureFormattedDocument = Selection.ReplyForwardSignatureFormattedDocument.Get();
			EndIf;
			
		EndIf;
		
		If Not EnableSignature Then
			
			EnableSignature = ?(EmailOperationSettings.Property("AddSignatureOnReplyForward"),
			                    EmailOperationSettings.AddSignatureOnReplyForward,
			                    False);
			
			If EnableSignature Then
				SignatureFormat                  = EmailOperationSettings.ReplyForwardSignatureFormat;
				SignaturePlainText            = EmailOperationSettings.ReplyForwardSignaturePlainText;
				SignatureFormattedDocument = EmailOperationSettings.OnReplyForwardFormattedDocument;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	ReturnStructure.RequestDeliveryReceipt = 
		?(EmailOperationSettings.Property("AlwaysRequestDeliveryReceipt"),
	                                       EmailOperationSettings.AlwaysRequestDeliveryReceipt, False);
	ReturnStructure.RequestReadReceipt = 
		?(EmailOperationSettings.Property("AlwaysRequestReadReceipt"),
	                                        EmailOperationSettings.AlwaysRequestReadReceipt, False);
	ReturnStructure.DisplaySourceEmailBody = 
		?(EmailOperationSettings.Property("DisplaySourceEmailBody"),
	                                       EmailOperationSettings.DisplaySourceEmailBody, False);
	ReturnStructure.IncludeOriginalEmailBody = 
		?(EmailOperationSettings.Property("IncludeOriginalEmailBody"),
	                                       EmailOperationSettings.IncludeOriginalEmailBody, False);
	
	If EnableSignature Then
		
		If MessageFormat = Enums.EmailEditingMethods.NormalText Then
			
			ReturnStructure.Signature = Chars.LF + Chars.LF + SignaturePlainText;
			
		Else
			
			If SignatureFormat = Enums.EmailEditingMethods.NormalText Then
				
				FormattedDocument = New FormattedDocument;
				FormattedDocument.Add(Chars.LF + Chars.LF + SignaturePlainText);
				ReturnStructure.Signature = FormattedDocument;
				
			Else
				
				FormattedDocument = SignatureFormattedDocument;
				FormattedDocument.Insert(FormattedDocument.GetBeginBookmark(),,
				                                 FormattedDocumentItemType.Linefeed);
				FormattedDocument.Insert(FormattedDocument.GetBeginBookmark(),,
				                                 FormattedDocumentItemType.Linefeed);
				ReturnStructure.Signature = FormattedDocument;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return ReturnStructure;
	
EndFunction

// Gets user session parameters for an incoming email.
//
// Returns:
//   EnumRef.ReplyToReadReceiptPolicies - an order of replies to read notifications.
//
Function GetUserParametersForIncomingEmail() Export

	EmailOperationSettings = GetEmailOperationsSetting();
	
	Return ?(EmailOperationSettings.Property("ReplyToReadReceiptPolicies"),
	          EmailOperationSettings.ReplyToReadReceiptPolicies,
	          Enums.ReplyToReadReceiptPolicies.AskBeforeSendReadReceipt);

EndFunction

// Sends an email.
//
// Parameters:
//  Object - DocumentObject.OutgoingEmail - an email to be sent.
//
// Returns:
//   String - an email message ID.
//
Procedure AddToAddresseesParameter(Source, EmailParameters, ParameterName, TableName) Export
	
	If TypeOf(Source) = Type("FormDataStructure") OR TypeOf(Source) = Type("DocumentObject.OutgoingEmail")
		OR TypeOf(Source) = Type("ValueTableRow") Then
		Table = Source[TableName];
	ElsIf TypeOf(Source) = Type("QueryResultSelection") Then
		Table = Source[TableName].Unload();
	Else
		Return;
	EndIf;
	
	If Table.Count() = 0 Then
		Return;
	EndIf;
	
	Recipients = New Array;
	For Each TableRow In Table Do
		Recipients.Add(New Structure("Address,Presentation", TableRow.Address, TableRow.Presentation));
	EndDo;
	
	EmailParameters.Insert(ParameterName, Recipients);
	
EndProcedure

// Sends an email.
//
// Parameters:
//  Object - DocumentObject.OutgoingEmail - an email to be sent.
//
// Returns:
//   String - an email message ID.
//
Function ExecuteEmailSending(Object, Connection = Undefined, EmailParameters = Undefined, MailProtocol = "") Export
	
	If MailProtocol <> "" AND MailProtocol <> "All" AND MailProtocol <> "IMAP" Then
		Return Undefined;
	EndIf;
	
	If EmailParameters = Undefined Then
		EmailParameters = EmailSendingParameters(Object);
	EndIf;
	
	If Connection = Undefined Then
		
		Profile = EmailOperationsInternal.InternetMailProfile(Object.Account);
	
		Try
			
			Connection = New InternetMail;
			ConnectionProtocol = ?(IsBlankString(Profile.IMAPServerAddress),InternetMailProtocol.POP3, InternetMailProtocol.IMAP);
			Connection.Logon(Profile, ConnectionProtocol);
			
			MailProtocol = "";
			
			If ConnectionProtocol = InternetMailProtocol.IMAP Then
				
				If Not (Object.DeleteAfterSend
					Or EmailManagement.OutgoingMailServerNotRequireAdditionalSendingByIMAP(Profile.SMTPServerAddress)) Then
					
					Mailboxes = Connection.GetMailboxes();
					For Each Mailbox In Mailboxes Do
						If Lower(Mailbox) = "sent"
							Or Lower(Mailbox) = "sent" Then
							
							Connection.CurrentMailbox = Mailbox;
							MailProtocol = "All";
							Break;
							
						EndIf;
					EndDo;
					
				EndIf;
				
			EndIf;
			
		Except
			
			ErrorMessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Во время подключения к учетной записи %1 произошла ошибка
					|%2'; 
					|en = 'An error occurred when connecting to account %1
					|%2'; 
					|pl = 'An error occurred when connecting to account %1
					|%2';
					|de = 'An error occurred when connecting to account %1
					|%2';
					|ro = 'An error occurred when connecting to account %1
					|%2';
					|tr = 'An error occurred when connecting to account %1
					|%2'; 
					|es_ES = 'An error occurred when connecting to account %1
					|%2'", Common.DefaultLanguageCode()),
				Object.Account,
				BriefErrorDescription(ErrorInfo()));
			
			Common.MessageToUser(ErrorMessageText, Object.Account);
			
		EndTry;
		
	EndIf;
	
	EmailParameters.Insert("Connection", Connection);
	
	EmailParameters.Insert("MailProtocol", MailProtocol);
	
	EmailID = EmailOperations.SendEmailMessage(Object.Account, EmailParameters);
	
	If MailProtocol = "" Then
		Object.MessageID = EmailParameters.MessageID;
	ElsIf MailProtocol = "IMAP" Then
		Object.MessageIDIMAPSending = EmailParameters.MessageIDIMAPSending;
	ElsIf MailProtocol = "All" Then
		Object.MessageID = EmailParameters.MessageID;
		Object.MessageIDIMAPSending = EmailParameters.MessageIDIMAPSending;
	EndIf;
	
	Return EmailID;
	
EndFunction

Function EmailObjectAttachedFilesData(EmailObject)
	
	Result = New Structure;
	Result.Insert("FilesOwner", EmailObject.Ref);
	Result.Insert("AttachedFilesCatalogName", 
		EmailManagement.MetadataObjectNameOfAttachedEmailFiles(EmailObject.Ref));
		
	InteractionsOverridable.OnReceiveAttachedFiles(EmailObject.Ref, Result);
	
	// CAC:223-off For backward compatibility.
	AttachedEmailFilesData = InteractionsOverridable.AttachedEmailFilesMetadataObjectData(EmailObject);
	// ACC:223-enable
	If AttachedEmailFilesData <> Undefined Then
		Result.AttachedFilesCatalogName = AttachedEmailFilesData.CatalogNameAttachedFiles;
		Result.FilesOwner = AttachedEmailFilesData.Owner;
	EndIf;
	Return Result;
	
EndFunction

Function AttachedEmailFilesData(EmailRef) Export
	
	Result = New Structure;
	Result.Insert("FilesOwner", EmailRef);
	Result.Insert("AttachedFilesCatalogName", 
		EmailManagement.MetadataObjectNameOfAttachedEmailFiles(EmailRef));
		
	InteractionsOverridable.OnReceiveAttachedFiles(EmailRef, Result);
	
	// CAC:223-off For backward compatibility.
	AttachedEmailFilesData = InteractionsOverridable.AttachedEmailFilesMetadataObjectData(EmailRef);
	// ACC:223-enable
	If AttachedEmailFilesData <> Undefined Then
		Result.AttachedFilesCatalogName = AttachedEmailFilesData.CatalogNameAttachedFiles;
		Result.FilesOwner = AttachedEmailFilesData.Owner;
	EndIf;
	Return Result;
	
EndFunction

Function EmailSendingParameters(Object)
	
	If Common.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		ModuleDigitalSignature = Common.CommonModule("DigitalSignature");
		SignatureFilesExtension = ModuleDigitalSignature.PersonalSettings().SignatureFilesExtension;
	Else
		SignatureFilesExtension = "p7s";
	EndIf;
	
	EmailParameters = New Structure;

	AddToAddresseesParameter(Object, EmailParameters,"SendTo", "EmailRecipients");
	AddToAddresseesParameter(Object, EmailParameters,"Cc", "CCRecipients");
	AddToAddresseesParameter(Object, EmailParameters,"BCC", "BccRecipients");
	EmailParameters.Insert("Subject", Object.Subject);
	EmailParameters.Insert("Body", ?(Object.TextType = Enums.EmailTextTypes.PlainText,
	                                   Object.Text, Object.HTMLText));
	EmailParameters.Insert("Encoding", Object.Encoding);
	EmailParameters.Insert("Importance",  EmailManagement.GetImportance(Object.Importance));
	EmailParameters.Insert("TextType", Object.TextType);
	
	If Not IsBlankString(Object.BasisIDs) Then
		EmailParameters.Insert("BasisIDs", Object.BasisIDs);
	EndIf;
	
	AttachmentsArray = New Array;
	
	AttachedEmailFilesData = EmailObjectAttachedFilesData(Object);
	MetadataObjectName = AttachedEmailFilesData.AttachedFilesCatalogName;
	FilesOwner       = AttachedEmailFilesData.FilesOwner;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Files.Description AS FullDescr,
	|	Files.Extension AS Extension,
	|	Files.Ref AS Ref,
	|	Files.EmailFileID
	|FROM
	|	Catalog." + MetadataObjectName + " AS Files
	|WHERE
	|	Files.FileOwner = &FileOwner
	|;
	|
	|//////////////////////////////////////////////////////////////////////
	|SELECT
	|	EmailMessageIncomingMessageAttachments.Email                     AS Email,
	|	EmailMessageIncomingMessageAttachments.SequenceNumberInAttachments AS SequenceNumberInAttachments
	|FROM
	|	Document.OutgoingEmail.EmailAttachments AS EmailMessageIncomingMessageAttachments
	|WHERE
	|	EmailMessageIncomingMessageAttachments.Ref = &FileOwner
	|
	|ORDER BY SequenceNumberInAttachments ASC";
	
	Query.SetParameter("FileOwner", FilesOwner);
	QueryResult = Query.ExecuteBatch();
	
	AttachmentsSelection = QueryResult[0].Select();
	AttachmentEmailTable = QueryResult[1].Unload();
	
	AttachmentsCount = AttachmentEmailTable.Count() + AttachmentsSelection.Count();
	
	DisplayedAttachmentNumber = 1;
	While AttachmentsSelection.Next() Do
		
		AddAttachmentEmailIfRequired(AttachmentEmailTable, AttachmentsArray, DisplayedAttachmentNumber);
		FileName = AttachmentsSelection.FullDescr + ?(AttachmentsSelection.Extension = "", "", "." + AttachmentsSelection.Extension);
		
		If IsBlankString(AttachmentsSelection.EmailFileID) Then
			AddAttachment(AttachmentsArray, FileName, FilesOperations.FileBinaryData(AttachmentsSelection.Ref));
			DisplayedAttachmentNumber = DisplayedAttachmentNumber + 1;
		Else
			AddAttachment(AttachmentsArray,
			                 FileName, 
			                 FilesOperations.FileBinaryData(AttachmentsSelection.Ref), 
			                 AttachmentsSelection.EmailFileID);
		EndIf;
		
		If Common.SubsystemExists("StandardSubsystems.DigitalSignature") Then
			
			ModuleDigitalSignature = Common.CommonModule("DigitalSignature");
			OwnerDigitalSignatures = ModuleDigitalSignature.SetSignatures(AttachmentsSelection.Ref);
			RowNumber = 1;
			For each DS In OwnerDigitalSignatures Do
				FileName = AttachmentsSelection.FullDescr + "-DS("+ RowNumber + ")." + SignatureFilesExtension;
				AddAttachment(AttachmentsArray, FileName, DS.Signature);
				RowNumber = RowNumber + 1;
			EndDo;
			
		EndIf;
		
	EndDo;
	
	While DisplayedAttachmentNumber <= AttachmentsCount Do
		
		AddAttachmentEmailIfRequired(AttachmentEmailTable, AttachmentsArray, DisplayedAttachmentNumber);
		DisplayedAttachmentNumber = DisplayedAttachmentNumber + 1;
		
	EndDo;
	
	EmailParameters.Insert("Attachments", AttachmentsArray);
	EmailParameters.Insert("ProcessTexts", False);
	
	If Object.RequestDeliveryReceipt Then
		EmailParameters.Insert("RequestDeliveryReceipt", True);
	EndIf;
	
	If Object.RequestReadReceipt Then
		EmailParameters.Insert("RequestReadReceipt", True);
	EndIf;
	
	Return EmailParameters;
	
EndFunction

Procedure AddAttachmentEmailIfRequired(AttachmentEmailTable, AttachmentsArray, DisplayedAttachmentNumber)
	
	FoundRow = AttachmentEmailTable.Find(DisplayedAttachmentNumber, "SequenceNumberInAttachments");
	While FoundRow <> Undefined Do
		AddAttachmentEmailOutgoingEmail(AttachmentsArray, FoundRow.Email);
		DisplayedAttachmentNumber = DisplayedAttachmentNumber + 1;
		FoundRow = AttachmentEmailTable.Find(DisplayedAttachmentNumber, "SequenceNumberInAttachments");
	EndDo
	
EndProcedure

Procedure AddAttachmentEmailOutgoingEmail(AttachmentsArray, Email); 

	AttachmentStructure = New Structure;
	
	DataEmailMessageInternet = InternetEmailMessageFromEmail(Email);
	
	If DataEmailMessageInternet.InternetMailMessage = Undefined Then
		Return;
	EndIf;
	
	Presentation = EmailPresentation(DataEmailMessageInternet.InternetMailMessage.Subject,
	                                    DataEmailMessageInternet.EmailDate);
	FileName = Presentation + ".eml";
	
	AttachmentStructure.Insert("Encoding", Email.Encoding);
	AttachmentStructure.Insert("AddressInTempStorage",
	                           PutToTempStorage(DataEmailMessageInternet.InternetMailMessage, 
	                                                         New UUID()));
	AttachmentStructure.Insert("MIMEType","message/rfc822");
	AttachmentStructure.Insert("Presentation", FileName);
	
	AttachmentsArray.Add(AttachmentStructure);
	
EndProcedure 

Procedure AddAttachment(AttachmentsArray, FileName, FileData, ID = Undefined, Encoding = Undefined)
	
	AttachmentData = New Structure;
	AttachmentData.Insert("Presentation", FileName);
	AttachmentData.Insert("AddressInTempStorage", FileData);
	
	If ValueIsFilled(ID) Then
		AttachmentData.Insert("ID", ID);
	EndIf;
	If ValueIsFilled(Encoding) Then
		AttachmentData.Insert("Encoding", Encoding);
	EndIf;
	
	AttachmentsArray.Add(AttachmentData);
	
EndProcedure

Function InternetEmailMessageFromEmail(Email) Export
	
	If TypeOf(Email) = Type("DocumentRef.IncomingEmail") Then
		
		Return InternetEmailMessageFromIncomingEmail(Email);
		
	ElsIf TypeOf(Email) = Type("DocumentRef.OutgoingEmail") Then
		
		Return InternetEmailMessageFromOutgoingEmail(Email);
		
	Else
		Return Undefined;
	EndIf;

EndFunction

Function InternetEmailMessageFromIncomingEmail(Email)
	
	ReturnStructure = New Structure("InternetMailMessage, EmailDate");
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	IncomingEmail.Importance                 AS Importance,
	|	IncomingEmail.IDAtServer   AS ID,
	|	IncomingEmail.DateReceived            AS DateReceived,
	|	IncomingEmail.Text                    AS Text,
	|	IncomingEmail.HTMLText                AS HTMLText,
	|	IncomingEmail.Encoding                AS Encoding,
	|	IncomingEmail.SenderAddress         AS SenderAddress,
	|	IncomingEmail.SenderPresentation AS SenderPresentation,
	|	IncomingEmail.Subject                     AS Subject,
	|	IncomingEmail.RequestDeliveryReceipt       AS RequestDeliveryReceipt,
	|	IncomingEmail.RequestReadReceipt      AS RequestReadReceipt
	|FROM
	|	Document.IncomingEmail AS IncomingEmail
	|WHERE
	|	IncomingEmail.Ref = &Email
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////1
	|SELECT
	|	EmailMessageIncomingMessageRecipients.Address,
	|	EmailMessageIncomingMessageRecipients.Presentation,
	|	EmailMessageIncomingMessageRecipients.Contact
	|FROM
	|	Document.IncomingEmail.EmailRecipients AS EmailMessageIncomingMessageRecipients
	|WHERE
	|	EmailMessageIncomingMessageRecipients.Ref = &Email
	|
	|ORDER BY
	|	EmailMessageIncomingMessageRecipients.LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////2
	|SELECT
	|	EmailMessageIncomingCCRecipients.Address,
	|	EmailMessageIncomingCCRecipients.Presentation,
	|	EmailMessageIncomingCCRecipients.Contact
	|FROM
	|	Document.IncomingEmail.CCRecipients AS EmailMessageIncomingCCRecipients
	|WHERE
	|	EmailMessageIncomingCCRecipients.Ref = &Email
	|
	|ORDER BY
	|	EmailMessageIncomingCCRecipients.LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////3
	|SELECT
	|	EmailMessageIncomingResponseRecipients.Address,
	|	EmailMessageIncomingResponseRecipients.Presentation,
	|	EmailMessageIncomingResponseRecipients.Contact
	|FROM
	|	Document.IncomingEmail.ReplyRecipients AS EmailMessageIncomingResponseRecipients
	|WHERE
	|	EmailMessageIncomingResponseRecipients.Ref = &Email
	|
	|ORDER BY
	|	EmailMessageIncomingResponseRecipients.LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////4
	|SELECT
	|	EmailMessageIncomingReadNotificationAddresses.Address,
	|	EmailMessageIncomingReadNotificationAddresses.Presentation,
	|	EmailMessageIncomingReadNotificationAddresses.Contact
	|FROM
	|	Document.IncomingEmail.ReadReceiptAddresses AS EmailMessageIncomingReadNotificationAddresses
	|WHERE
	|	EmailMessageIncomingReadNotificationAddresses.Ref = &Email
	|
	|ORDER BY
	|	EmailMessageIncomingReadNotificationAddresses.LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////5
	|SELECT
	|	Files.Description AS FullDescr,
	|	Files.Extension AS Extension,
	|	Files.Ref AS Ref,
	|	Files.EmailFileID
	|FROM
	|	Catalog.IncomingEmailAttachedFiles AS Files
	|WHERE
	|	Files.FileOwner = &Email";
	
	Query.SetParameter("Email", Email);
	
	QueryResult = Query.ExecuteBatch();
	
	HeaderSelection = QueryResult[0].Select();
	If HeaderSelection.Next() Then
		
		ObjectInternetEmailMessage = New InternetMailMessage;
		ObjectInternetEmailMessage.Importance               = EmailManagement.GetImportance(HeaderSelection.Importance);
		ObjectInternetEmailMessage.UID.Add(HeaderSelection.ID);
		ObjectInternetEmailMessage.Encoding              = HeaderSelection.Encoding;
		ObjectInternetEmailMessage.Subject                   = HeaderSelection.Subject;
		ObjectInternetEmailMessage.RequestDeliveryReceipt     = HeaderSelection.RequestDeliveryReceipt;
		ObjectInternetEmailMessage.RequestReadReceipt    = HeaderSelection.RequestReadReceipt;
		ObjectInternetEmailMessage.From            = HeaderSelection.SenderAddress;
		
		SenderData = CommonClientServer.ParseStringWithEmailAddresses(HeaderSelection.SenderPresentation, False);
		If TypeOf(SenderData) = Type("Array") AND SenderData.Count() > 0 Then
			ObjectInternetEmailMessage.SenderName = SenderData[0].Presentation;
			ObjectInternetEmailMessage.From    = SenderData[0].Address;
		EndIf;
		
		If IsBlankString(HeaderSelection.HTMLText) Then
		
			AddTextToInternetEmailMessageTexts(ObjectInternetEmailMessage.Texts,
			                                               HeaderSelection.Text, 
			                                               InternetMailTextType.PlainText,
			                                               HeaderSelection.Encoding);
		
		EndIf;
		
		AddTextToInternetEmailMessageTexts(ObjectInternetEmailMessage.Texts,
		                                               HeaderSelection.HTMLText, 
		                                               InternetMailTextType.HTML,
		                                               HeaderSelection.Encoding);
		
		
	Else
		
		Return Undefined;
		
	EndIf;
	
	AddRecipientsToEmailMessageBySelection(ObjectInternetEmailMessage, QueryResult[1].Select(), "To");
	AddRecipientsToEmailMessageBySelection(ObjectInternetEmailMessage, QueryResult[2].Select(), "Cc");
	AddRecipientsToEmailMessageBySelection(ObjectInternetEmailMessage, QueryResult[3].Select(), "ReplyTo");
	AddRecipientsToEmailMessageBySelection(ObjectInternetEmailMessage, QueryResult[4].Select(), "ReadReceiptAddresses");
	AddEmailAttachmentsToEmailMessage(ObjectInternetEmailMessage, QueryResult[5].Select());
	
	ReturnStructure.InternetMailMessage = ObjectInternetEmailMessage;
	ReturnStructure.EmailDate                = HeaderSelection.DateReceived;

	Return ReturnStructure;

EndFunction 

Function InternetEmailMessageFromOutgoingEmail(Email)
	
	ReturnStructure = New Structure("InternetMailMessage, EmailDate");
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	OutgoingEmail.PostingDate           AS PostingDate,
	|	OutgoingEmail.Importance                  AS Importance,
	|	OutgoingEmail.IDAtServer    AS ID,
	|	OutgoingEmail.SenderPresentation  AS SenderPresentation,
	|	OutgoingEmail.Encoding                 AS Encoding,
	|	OutgoingEmail.Text                     AS Text,
	|	OutgoingEmail.HTMLText                 AS HTMLText,
	|	OutgoingEmail.TextType                 AS TextType,
	|	OutgoingEmail.Subject                      AS Subject,
	|	OutgoingEmail.RequestDeliveryReceipt        AS RequestDeliveryReceipt,
	|	OutgoingEmail.RequestReadReceipt       AS RequestReadReceipt
	|FROM
	|	Document.OutgoingEmail AS OutgoingEmail
	|WHERE
	|	OutgoingEmail.Ref = &Email
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////1
	|SELECT
	|	EmailMessageOutgoingMessageRecipients.Address,
	|	EmailMessageOutgoingMessageRecipients.Presentation
	|FROM
	|	Document.OutgoingEmail.EmailRecipients AS EmailMessageOutgoingMessageRecipients
	|WHERE
	|	EmailMessageOutgoingMessageRecipients.Ref = &Email
	|
	|ORDER BY
	|	EmailMessageOutgoingMessageRecipients.LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////2
	|SELECT
	|	EmailMessageOutgoingResponseRecipients.Address,
	|	EmailMessageOutgoingResponseRecipients.Presentation
	|FROM
	|	Document.OutgoingEmail.ReplyRecipients AS EmailMessageOutgoingResponseRecipients
	|WHERE
	|	EmailMessageOutgoingResponseRecipients.Ref = &Email
	|
	|ORDER BY
	|	EmailMessageOutgoingResponseRecipients.LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////3
	|SELECT
	|	EmailMessageOutgoingCCRecipients.Address,
	|	EmailMessageOutgoingCCRecipients.Presentation
	|FROM
	|	Document.OutgoingEmail.CCRecipients AS EmailMessageOutgoingCCRecipients
	|WHERE
	|	EmailMessageOutgoingCCRecipients.Ref = &Email
	|
	|ORDER BY
	|	EmailMessageOutgoingCCRecipients.LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////4
	|SELECT
	|	EmailMessageIncomingMessageAttachments.Email
	|FROM
	|	Document.OutgoingEmail.EmailAttachments AS EmailMessageIncomingMessageAttachments
	|WHERE
	|	EmailMessageIncomingMessageAttachments.Ref = &Email
	|
	|ORDER BY
	|	EmailMessageIncomingMessageAttachments.LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////5
	|SELECT
	|	Files.Description AS FullDescr,
	|	Files.Extension AS Extension,
	|	Files.Ref AS Ref,
	|	Files.EmailFileID
	|FROM
	|	Catalog.OutgoingEmailAttachedFiles AS Files
	|WHERE
	|	Files.FileOwner = &Email";
	
	Query.SetParameter("Email", Email);
	
	QueryResult = Query.ExecuteBatch();
	
	HeaderSelection = QueryResult[0].Select();
	If HeaderSelection.Next() Then
		
		ObjectInternetEmailMessage = New InternetMailMessage;
		ObjectInternetEmailMessage.Importance               = EmailManagement.GetImportance(HeaderSelection.Importance);
		ObjectInternetEmailMessage.UID.Add(HeaderSelection.ID);
		ObjectInternetEmailMessage.Encoding              = HeaderSelection.Encoding;
		ObjectInternetEmailMessage.Subject                   = HeaderSelection.Subject;
		ObjectInternetEmailMessage.RequestDeliveryReceipt     = HeaderSelection.RequestDeliveryReceipt;
		ObjectInternetEmailMessage.RequestReadReceipt    = HeaderSelection.RequestReadReceipt;
		
		SenderData = CommonClientServer.ParseStringWithEmailAddresses(HeaderSelection.SenderPresentation, False);
		
		If TypeOf(SenderData) = Type("Array") AND SenderData.Count() > 0 Then
			ObjectInternetEmailMessage.SenderName = SenderData[0].Presentation;
			ObjectInternetEmailMessage.From    = SenderData[0].Address;
		EndIf;
		
		If IsBlankString(HeaderSelection.HTMLText) Then
		
			AddTextToInternetEmailMessageTexts(ObjectInternetEmailMessage.Texts,
			                                               HeaderSelection.Text, 
			                                               InternetMailTextType.PlainText,
			                                               HeaderSelection.Encoding);
		
		EndIf;
		
		AddTextToInternetEmailMessageTexts(ObjectInternetEmailMessage.Texts,
		                                               HeaderSelection.HTMLText, 
		                                               InternetMailTextType.HTML,
		                                               HeaderSelection.Encoding);
		
	Else
		
		Return Undefined;
		
	EndIf;
	
	AddRecipientsToEmailMessageBySelection(ObjectInternetEmailMessage, QueryResult[1].Select(), "To");
	AddRecipientsToEmailMessageBySelection(ObjectInternetEmailMessage, QueryResult[2].Select(), "ReplyTo");
	AddRecipientsToEmailMessageBySelection(ObjectInternetEmailMessage, QueryResult[3].Select(), "Cc");
	AddEmailAttachmentsToEmailMessage(ObjectInternetEmailMessage, QueryResult[5].Select());
	
	ReturnStructure.InternetMailMessage = ObjectInternetEmailMessage;
	ReturnStructure.EmailDate                = HeaderSelection.PostingDate;

	Return ReturnStructure;
	
EndFunction

Procedure AddTextToInternetEmailMessageTexts(MessageTexts, MessageText, TextType, Encoding)
	
	If Not IsBlankString(MessageText) Then
		
		NewText = MessageTexts.Add(MessageText, TextType);
		NewText.Encoding = Encoding;
		
	EndIf;
	
EndProcedure

Procedure AddRecipientsToEmailMessageBySelection(Message, Selection, TableName)
	
	While Selection.Next() Do
		
		AddRecipientToEmailMessage(Message, TableName, Selection.Address, Selection.Presentation)
		
	EndDo;
	
EndProcedure

Procedure AddRecipientToEmailMessage(Message, TableName, Address, Presentation)
	
	EmailRecipient                 = Message[TableName].Add(Address);
	EmailRecipient.DisplayName = Presentation;
	
EndProcedure

Procedure AddEmailAttachmentsToEmailMessage(Message, AttachmentsSelection)
	
	While AttachmentsSelection.Next() Do
		
		Name   = AttachmentsSelection.FullDescr 
		        + ?(AttachmentsSelection.Extension = "", "", "." + AttachmentsSelection.Extension);
		Data = FilesOperations.FileBinaryData(AttachmentsSelection.Ref);
		
		EmailAttachment = Message.Attachments.Add(Data, Name);

		If NOT IsBlankString(AttachmentsSelection.EmailFileID) Then
			EmailAttachment.CID = AttachmentsSelection.EmailFileID;
		EndIf;
		
		If Common.SubsystemExists("StandardSubsystems.DigitalSignature") Then
			ModuleDigitalSignature = Common.CommonModule("DigitalSignature");
			AttachmentSignatures = ModuleDigitalSignature.SetSignatures(AttachmentsSelection.Ref);
			RowNumber = 1;
			For Each DS In AttachmentSignatures Do
				Name = AttachmentsSelection.FullDescr + "-DS("+ RowNumber + ")." + SignatureFilesExtension();
				Data = DS.Signature;
				
				EmailAttachment = Message.Attachments.Add(Data, Name);
				RowNumber = RowNumber + 1;
			EndDo;
		EndIf;
	EndDo;
	
EndProcedure

Function DataStoredInAttachmentsEmailsDatabase(Email) Export

	Query = New Query;
	Query.Text = "SELECT
	|	EmailMessageIncomingMessageAttachments.Email AS Email,
	|	IncomingEmail.Size AS Size,
	|	IncomingEmail.Subject AS Subject,
	|	IncomingEmail.DateReceived AS Date
	|FROM
	|	Document.OutgoingEmail.EmailAttachments AS EmailMessageIncomingMessageAttachments
	|		INNER JOIN Document.IncomingEmail AS IncomingEmail
	|		ON EmailMessageIncomingMessageAttachments.Email = IncomingEmail.Ref
	|WHERE
	|	EmailMessageIncomingMessageAttachments.Ref = &Email
	|
	|UNION
	|
	|SELECT
	|	EmailMessageIncomingMessageAttachments.Email,
	|	OutgoingEmail.Size,
	|	OutgoingEmail.Subject,
	|	CASE
	|		WHEN OutgoingEmail.PostingDate = DATETIME(1, 1, 1, 1, 1, 1)
	|			THEN OutgoingEmail.Date
	|		ELSE OutgoingEmail.PostingDate
	|	END
	|FROM
	|	Document.OutgoingEmail.EmailAttachments AS EmailMessageIncomingMessageAttachments
	|		INNER JOIN Document.OutgoingEmail AS OutgoingEmail
	|		ON EmailMessageIncomingMessageAttachments.Email = OutgoingEmail.Ref
	|WHERE
	|	EmailMessageIncomingMessageAttachments.Ref = &Email";
	
	Query.SetParameter("Email", Email);
	
	Return Query.Execute().Unload();
	
EndFunction 

// Sets an email form header.
//
// Parameters:
//  Form - ManagedForm - a form, for which the procedure is being executed.
//
Procedure SetEmailFormHeader(Form) Export

	ObjectEmail = Form.Object;
	If NOT ObjectEmail.Ref.IsEmpty() Then
		Form.AutoTitle = False;
		FormHeader = ?(IsBlankString(ObjectEmail.Subject), NStr("ru = 'Письмо без темы'; en = 'Email without subject'; pl = 'Email without subject';de = 'Email without subject';ro = 'Email without subject';tr = 'Email without subject'; es_ES = 'Email without subject'"), ObjectEmail.Subject);
		FormHeader = FormHeader 
		         + ?(TypeOf(ObjectEmail.Ref) = Type("DocumentRef.IncomingEmail"), " (Incoming)", " (Outgoing)");
		Form.Title = FormHeader;
	Else
		If TypeOf(ObjectEmail.Ref) = Type("DocumentRef.OutgoingEmail") Then
			Form.AutoTitle = False;
			Form.Title = NStr("ru = 'Исходящее письмо (создание)'; en = 'Outgoing email (create)'; pl = 'Outgoing email (create)';de = 'Outgoing email (create)';ro = 'Outgoing email (create)';tr = 'Outgoing email (create)'; es_ES = 'Outgoing email (create)'");
		EndIf;
	EndIf;

EndProcedure

#Region UpdateHandlers

Procedure DisableSubsystemSaaS() Export

	If Common.DataSeparationEnabled() Then
		
		Constants.UseEmailClient.Set(False);
		Constants.UseReviewedFlag.Set(False);
		Constants.UseOtherInteractions.Set(False);
		Constants.SendEmailsInHTMLFormat.Set(False);
		
	EndIf;

EndProcedure

// Infobase update procedure for SSL 1.2.1.4.
// Moves emails to predefined folders.
//
Procedure MoveMessagesToPredefinedFolders_1_2_3_4() Export
	
	Query = New Query;
	Query.Text = "SELECT
	|	IncomingEmail.Ref AS Email,
	|	EmailMessageFolders.Ref AS Folder
	|FROM
	|	Document.IncomingEmail AS IncomingEmail
	|		INNER JOIN Catalog.EmailMessageFolders AS EmailMessageFolders
	|		ON IncomingEmail.Account = EmailMessageFolders.Owner
	|WHERE
	|	EmailMessageFolders.Description = &Incoming
	|	AND EmailMessageFolders.PredefinedFolder
	|	AND (NOT IncomingEmail.DeletionMark)
	|
	|UNION ALL
	|
	|SELECT
	|	OutgoingEmail.Ref,
	|	EmailMessageFolders.Ref
	|FROM
	|	Document.OutgoingEmail AS OutgoingEmail
	|		INNER JOIN Catalog.EmailMessageFolders AS EmailMessageFolders
	|		ON OutgoingEmail.Account = EmailMessageFolders.Owner
	|WHERE
	|	OutgoingEmail.EmailStatus = VALUE(Enum.OutgoingEmailStatuses.Sent)
	|	AND EmailMessageFolders.PredefinedFolder
	|	AND EmailMessageFolders.Description = &Sent
	|	AND (NOT OutgoingEmail.DeletionMark)
	|
	|UNION ALL
	|
	|SELECT
	|	OutgoingEmail.Ref,
	|	EmailMessageFolders.Ref
	|FROM
	|	Document.OutgoingEmail AS OutgoingEmail
	|		INNER JOIN Catalog.EmailMessageFolders AS EmailMessageFolders
	|		ON OutgoingEmail.Account = EmailMessageFolders.Owner
	|WHERE
	|	OutgoingEmail.EmailStatus = VALUE(Enum.OutgoingEmailStatuses.Draft)
	|	AND EmailMessageFolders.PredefinedFolder
	|	AND EmailMessageFolders.Description = &Drafts
	|	AND (NOT OutgoingEmail.DeletionMark)
	|
	|UNION ALL
	|
	|SELECT
	|	OutgoingEmail.Ref,
	|	EmailMessageFolders.Ref
	|FROM
	|	Document.OutgoingEmail AS OutgoingEmail
	|		INNER JOIN Catalog.EmailMessageFolders AS EmailMessageFolders
	|		ON OutgoingEmail.Account = EmailMessageFolders.Owner
	|WHERE
	|	OutgoingEmail.EmailStatus = VALUE(Enum.OutgoingEmailStatuses.Outgoing)
	|	AND EmailMessageFolders.PredefinedFolder
	|	AND EmailMessageFolders.Description = &Outgoing
	|	AND (NOT OutgoingEmail.DeletionMark)
	|
	|UNION ALL
	|
	|SELECT
	|	IncomingEmail.Ref,
	|	EmailMessageFolders.Ref
	|FROM
	|	Document.IncomingEmail AS IncomingEmail
	|		INNER JOIN Catalog.EmailMessageFolders AS EmailMessageFolders
	|		ON IncomingEmail.Account = EmailMessageFolders.Owner
	|WHERE
	|	IncomingEmail.DeletionMark
	|	AND EmailMessageFolders.PredefinedFolder
	|	AND EmailMessageFolders.Description = &DeletedItems
	|
	|UNION ALL
	|
	|SELECT
	|	OutgoingEmail.Ref,
	|	EmailMessageFolders.Ref
	|FROM
	|	Document.OutgoingEmail AS OutgoingEmail
	|		INNER JOIN Catalog.EmailMessageFolders AS EmailMessageFolders
	|		ON OutgoingEmail.Account = EmailMessageFolders.Owner
	|WHERE
	|	OutgoingEmail.DeletionMark
	|	AND EmailMessageFolders.PredefinedFolder
	|	AND EmailMessageFolders.Description = &DeletedItems";
	
	SetQueryParametersPredefinedFoldersNames(Query);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		InteractionsServerCall.SetEmailFolder(Selection.Email, Selection.Folder);
		
	EndDo;
	
EndProcedure

// Infobase update procedure for SSL 1.2.1.4.
// Moves an interaction subject from the document attribute to the InteractionsFolderSubjects information register.
//
Procedure CreateEmailFolders_1_2_1_4() Export

	Query = New Query;
	Query.Text = "SELECT
	|	EmailAccounts.Ref
	|FROM
	|	Catalog.EmailAccounts AS EmailAccounts";
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
	
		EmailManagement.CreatePredefinedEmailsFoldersForAccount(Selection.Ref);
	
	EndDo;

EndProcedure

// Infobase update procedure for SSL 1.2.1.4.
// Moves data from the EmployeeResponsibleForProcessingEmails attribute of the EmailAccounts catalog 
// to the EmployeeResponsibleForProcessingEmails and EmployeeResponsibleForMaintainingFolders attributes of information register
// EmailAccountsSettings.
//
Procedure UpdateStorageEmployeeResponsibleAccount_1_2_1_4() Export
	
	Query = New Query;
	Query.Text = "SELECT
	|	EmailAccounts.Ref,
	|	EmailAccounts.DeleteEmployeeResponsibleForEmailProcessing
	|FROM
	|	Catalog.EmailAccounts AS EmailAccounts
	|WHERE
	|	EmailAccounts.DeleteEmployeeResponsibleForEmailProcessing <> VALUE(Catalog.Users.EmptyRef)
	|";
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		RecordManager = InformationRegisters.EmailAccountSettings.CreateRecordManager();
		RecordManager.EmailAccount = Selection.Ref;
		RecordManager.AddSignatureForNewMessages  = False;
		RecordManager.AddSignatureOnReplyForward = False;
		RecordManager.EmployeeResponsibleForProcessingEmails     = Selection.DeleteEmployeeResponsibleForEmailProcessing;
		RecordManager.EmployeeResponsibleForFoldersMaintenance       = Selection.DeleteEmployeeResponsibleForEmailProcessing;
		RecordManager.Write();
		
	EndDo;
	
EndProcedure

// Infobase update procedure for SSL 2.1.3.22.
// Moves data from the IncludeUsernameInPresentation attribute of the EmailAccounts catalog to the 
// IncludeUsernameInPresentation attribute of the EmailAccountsSettings information register.
//
Procedure UpdateStorageIncludeUsernameInPresentation_2_1_3_22() Export
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	EmailAccounts.Ref
	|FROM
	|	InformationRegister.EmailAccountSettings AS EmailAccountSettings
	|		INNER JOIN Catalog.EmailAccounts AS EmailAccounts
	|		ON EmailAccountSettings.EmailAccount = EmailAccounts.Ref
	|WHERE
	|	EmailAccounts.DeleteIncludeUsernameInPresentation
	|	AND NOT EmailAccountSettings.IncludeUsernameInPresentation";
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		RecordSet = InformationRegisters.EmailAccountSettings.CreateRecordSet();
		RecordSet.Filter.EmailAccount.Set(Selection.Ref);
		RecordSet.Read();
		For Each Record In RecordSet Do
			 Record.IncludeUsernameInPresentation = True;
		EndDo;
		InfobaseUpdate.WriteData(RecordSet);
		
	EndDo;
	
EndProcedure

// Infobase update procedure for SSL 1.2.1.4.
// Moves an interaction subject from the document attribute to the InteractionsFolderSubjects information register.
//
Procedure UpdateSubjectStorage_1_2_1_4() Export
	
	Query = New Query;
	Query.Text = "SELECT
	|	Meeting.Ref,
	|	Meeting.DeleteSubject AS Topic
	|FROM
	|	Document.Meeting AS Meeting
	|
	|UNION ALL
	|
	|SELECT
	|	PlannedInteraction.Ref,
	|	PlannedInteraction.DeleteSubject
	|FROM
	|	Document.PlannedInteraction AS PlannedInteraction
	|
	|UNION ALL
	|
	|SELECT
	|	PhoneCall.Ref,
	|	PhoneCall.DeleteSubject AS Topic
	|FROM
	|	Document.PhoneCall AS PhoneCall
	|
	|UNION ALL
	|
	|SELECT
	|	IncomingEmail.Ref,
	|	IncomingEmail.DeleteSubject AS Topic
	|FROM
	|	Document.IncomingEmail AS IncomingEmail
	|
	|UNION ALL
	|
	|SELECT
	|	OutgoingEmail.Ref,
	|	OutgoingEmail.DeleteSubject AS Topic
	|FROM
	|	Document.OutgoingEmail AS OutgoingEmail";
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		SetSubject(Selection.Ref, ?(ValueIsFilled(Selection.Topic), Selection.Topic, Selection.Ref));
		
	EndDo;
	
EndProcedure

// Infobase update procedure for SSL 1.2.1.4.
// Transforms the beginning of the Meeting, Phone call, and Planned interaction document 
// descriptions to the Subject attribute.
//
Procedure ConvertDescriptionToSubject_1_2_1_4() Export
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	Meeting.Ref,
	|	SUBSTRING(Meeting.Details, 1, 1024) AS Details
	|FROM
	|	Document.Meeting AS Meeting
	|WHERE
	|	Meeting.Subject <> """"""""
	|
	|UNION ALL
	|
	|SELECT
	|	PlannedInteraction.Ref,
	|	SUBSTRING(PlannedInteraction.Details, 1, 1024)
	|FROM
	|	Document.PlannedInteraction AS PlannedInteraction
	|WHERE
	|	PlannedInteraction.Subject <> """"""""
	|
	|UNION ALL
	|
	|SELECT
	|	PhoneCall.Ref,
	|	SUBSTRING(PhoneCall.Details, 1, 1024)
	|FROM
	|	Document.PhoneCall AS PhoneCall
	|WHERE
	|	PhoneCall.Subject <> """"""""";
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		If Not IsBlankString(Selection.Details) Then
			InteractionObject       = Selection.Ref.GetObject();
			InteractionObject.Subject  = Selection.Details;
			InfobaseUpdate.WriteData(InteractionObject);
		EndIf;
	EndDo;
	
EndProcedure

// Infobase update procedure for SSL 1.2.1.4.
// Defines the estimated size of outgoing emails.
//
Procedure FillSizeForOutgoingEmails_1_2_1_4() Export

	Query = New Query;
	Query.Text = "SELECT
	|	OutgoingEmail.Ref
	|FROM
	|	Document.OutgoingEmail AS OutgoingEmail";
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
	
		EmailObject = Selection.Ref.GetObject();
		EmailObject.Size = EvaluateOutgoingEmailSize(Selection.Ref);
		InfobaseUpdate.WriteData(EmailObject);
	
	EndDo;

EndProcedure

// Fills codes of predefined folders and recodes the catalog if necessary.
// 
//
Procedure ChangeEmailFoldersEncoding_2_0_1_2() Export

	Query = New Query;
	Query.Text = "SELECT DISTINCT
	|	EmailMessageFolders.Owner AS Owner
	|INTO FoldersWithIssues
	|FROM
	|	Catalog.EmailMessageFolders AS EmailMessageFolders
	|WHERE
	|	EmailMessageFolders.Code = """"
	|	AND EmailMessageFolders.PredefinedFolder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	EmailMessageFolders.Ref
	|FROM
	|	Catalog.EmailMessageFolders AS EmailMessageFolders
	|WHERE
	|	EmailMessageFolders.Owner IN
	|			(SELECT
	|				FoldersWithIssues.Owner
	|			FROM
	|				FoldersWithIssues AS FoldersWithIssues)
	|	AND EmailMessageFolders.PredefinedFolder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	EmailMessageFolders.Ref AS Ref
	|FROM
	|	Catalog.EmailMessageFolders AS EmailMessageFolders
	|WHERE
	|	EmailMessageFolders.Owner IN
	|			(SELECT
	|				FoldersWithIssues.Owner
	|			FROM
	|				FoldersWithIssues AS FoldersWithIssues)
	|	AND (NOT EmailMessageFolders.PredefinedFolder)
	|
	|ORDER BY
	|	EmailMessageFolders.Code";
	
	Result = Query.ExecuteBatch();
	PredefinedSelection = Result[1].Select();
	
	While PredefinedSelection.Next() Do
	
		FolderObject = PredefinedSelection.Ref.GetObject();
		FolderObject.SetNewCode();
		InfobaseUpdate.WriteData(FolderObject);
	
	EndDo;
	
	UserDefinedSelection = Result[2].Select();
	
	While UserDefinedSelection.Next() Do
	
		FolderObject = UserDefinedSelection.Ref.GetObject();
		FolderObject.SetNewCode();
		InfobaseUpdate.WriteData(FolderObject);
	EndDo;

EndProcedure

Function QueryTextOfMarkToProcessingOfBaseEmailsFilling(FullDocumentName) Export

	Text = "
	|SELECT
	|	DocumentTable.Ref AS Ref
	|FROM
	|	DocumentJournal.Interactions AS Interactions
	|		INNER JOIN FullDocumentName AS DocumentTable
	|		ON Interactions.MessageID = DocumentTable.BasisID
	|			AND Interactions.Account = DocumentTable.Account
	|			AND Interactions.Ref <> DocumentTable.InteractionBasis
	|			AND (Interactions.MessageID <> """")
	|			AND (DocumentTable.InteractionBasis <> """")";
	
	Return StrReplace(Text, "FullDocumentName", FullDocumentName);

EndFunction 

Procedure FillBasisInteractionsForDependentEmails(Parameters, FullDocumentName, DocumentMetadata) Export
	
	QueryText = "
	|SELECT
	|	DocumentTable.Ref AS Email,
	|	Interactions.Ref   AS EmailBasis
	|FROM
	|	&TTDocumentsToProcess AS ReferencesToProcess
	|		INNER JOIN Document.OutgoingEmail AS DocumentTable
	|		ON DocumentTable.Ref = ReferencesToProcess.Ref
	|		INNER JOIN DocumentJournal.Interactions AS Interactions
	|		ON Interactions.MessageID = DocumentTable.BasisID
	|			AND Interactions.Account = DocumentTable.Account
	|			AND Interactions.Ref <> DocumentTable.InteractionBasis
	|			AND (Interactions.MessageID <> """")
	|			AND (DocumentTable.InteractionBasis <> """")
	|
	|;
	|////////////////////////////////////////////////////////////////////////////////1
	|SELECT DISTINCT
	|	ReferencesToProcess.Ref
	|FROM
	|	&TTDocumentsToProcess AS ReferencesToProcess
	|;
	|";
	
	QueryText =  StrReplace(QueryText, "FullDocumentName", FullDocumentName);
	
	TempTablesManager = New TempTablesManager;
	Result = InfobaseUpdate.CreateTemporaryTableOfRefsToProcess(Parameters.Queue, FullDocumentName, TempTablesManager);
	If NOT Result.HasDataToProcess Then
		Parameters.ProcessingCompleted = True;
		Return;
	EndIf;
	If NOT Result.HasRecordsInTemporaryTable Then
		Parameters.ProcessingCompleted = False;
		Return;
	EndIf; 
	
	QueryText = StrReplace(QueryText, "&TTDocumentsToProcess", Result.TempTableName);
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	
	Result = Query.ExecuteBatch();
	EmailSelection = Result[0].Select();
	
	// Here are all documents from the queue.
	TableOfRefsToProcess = Result[1].Unload();
	ProcessedDocumentsMap = New Map;
	
	While EmailSelection.Next() Do
		
		BeginTransaction();
		
		Try
			
			Lock = New DataLock;
			LockItem = Lock.Add(FullDocumentName);
			LockItem.SetValue("Ref", EmailSelection.Email);
			Lock.Lock();
			
		Except
			
			RollbackTransaction();
			ProcessedDocumentsMap.Insert(EmailSelection.Email);
			MessageText = NStr("ru = 'Не удалось заблокировать документ: %Recorder% по причине: %Reason%'; en = 'Cannot lock document: %Recorder% for the reason: %Reason%'; pl = 'Cannot lock document: %Recorder% for the reason: %Reason%';de = 'Cannot lock document: %Recorder% for the reason: %Reason%';ro = 'Cannot lock document: %Recorder% for the reason: %Reason%';tr = 'Cannot lock document: %Recorder% for the reason: %Reason%'; es_ES = 'Cannot lock document: %Recorder% for the reason: %Reason%'");
			MessageText = StrReplace(MessageText, "%Recorder%", EmailSelection.Email);
			MessageText = StrReplace(MessageText, "%Reason%", DetailErrorDescription(ErrorInfo()));
			WriteLogEvent(InfobaseUpdate.EventLogEvent(),
			                         EventLogLevel.Warning,
			                         DocumentMetadata,
			                         EmailSelection.Email,
			                         MessageText);
			Continue;
			
		EndTry;

		Try
			
			EmailObject = EmailSelection.Email.GetObject();
			
			If EmailObject = Undefined Then
				
				ProcessedDocumentsMap.Insert(EmailSelection.Email);
				
			Else
				
				EmailObject.InteractionBasis = EmailSelection.EmailBasis;
			
				InfobaseUpdate.WriteObject(EmailObject, True);
			
				ProcessedDocumentsMap.Insert(EmailSelection.Email);
				InfobaseUpdate.MarkProcessingCompletion(EmailSelection.Email,, Parameters.Queue);
				
			EndIf;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			MessageText = NStr("ru = 'Не удалось обработать документ: %Recorder% по причине: %Reason%'; en = 'Cannot process document: %Recorder% for the reason: %Reason%'; pl = 'Cannot process document: %Recorder% for the reason: %Reason%';de = 'Cannot process document: %Recorder% for the reason: %Reason%';ro = 'Cannot process document: %Recorder% for the reason: %Reason%';tr = 'Cannot process document: %Recorder% for the reason: %Reason%'; es_ES = 'Cannot process document: %Recorder% for the reason: %Reason%'");
			MessageText = StrReplace(MessageText, "%Recorder%", EmailSelection.Email);
			MessageText = StrReplace(MessageText, "%Reason%", DetailErrorDescription(ErrorInfo()));
			WriteLogEvent(InfobaseUpdate.EventLogEvent(),
				EventLogLevel.Warning,
				DocumentMetadata,
				EmailSelection.Email,
				MessageText);
			Raise;
			
		EndTry;
			
	EndDo;
	
	For Each TableRow In TableOfRefsToProcess Do
		
		If ProcessedDocumentsMap.Get(TableRow.Ref) = Undefined Then
			InfobaseUpdate.MarkProcessingCompletion(TableRow.Ref,, Parameters.Queue);
		EndIf;
		
	EndDo;
	
	Parameters.ProcessingCompleted = Not InfobaseUpdate.HasDataToProcess(Parameters.Queue, FullDocumentName);
	
EndProcedure

// Fills in a selection list for the "Review after" field.
//
// Parameters:
//  ChoiceList - ValueList - a list that will be filled in with choice values.
//
Procedure FillChoiceListForReviewAfter(ChoiceList) Export
	
	ChoiceList.Clear();
	ChoiceList.Add(15*60,    NStr("ru='Через 15 мин.'; en = 'In 15 min.'; pl = 'In 15 min.';de = 'In 15 min.';ro = 'In 15 min.';tr = 'In 15 min.'; es_ES = 'In 15 min.'"));
	ChoiceList.Add(30*60,    NStr("ru='Через 30 мин.'; en = 'In 30 min.'; pl = 'In 30 min.';de = 'In 30 min.';ro = 'In 30 min.';tr = 'In 30 min.'; es_ES = 'In 30 min.'"));
	ChoiceList.Add(60*60,    NStr("ru='Через 1 час'; en = 'In an hour'; pl = 'In an hour';de = 'In an hour';ro = 'In an hour';tr = 'In an hour'; es_ES = 'In an hour'"));
	ChoiceList.Add(3*60*60,  NStr("ru='Через 3 часа'; en = 'In 3 hours'; pl = 'In 3 hours';de = 'In 3 hours';ro = 'In 3 hours';tr = 'In 3 hours'; es_ES = 'In 3 hours'"));
	ChoiceList.Add(24*60*60, NStr("ru='Завтра'; en = 'Tomorrow'; pl = 'Tomorrow';de = 'Tomorrow';ro = 'Tomorrow';tr = 'Tomorrow'; es_ES = 'Tomorrow'"));
	
EndProcedure

// An event handler when writing for interactions that occur in document forms.
//
// Parameters:
//  CurrentObject - DocumentObject - a document, in which the event occurred.
//
Procedure OnWriteInteractionFromForm(CurrentObject, Form) Export
	
	If Form.Reviewed Then
		Form.ReviewAfter = Date(1,1,1);
	EndIf;
	
	Ref = CurrentObject.Ref;
	
	OldAttributesValues = InteractionAttributesStructure(Ref);
	
	If OldAttributesValues.Topic           = Form.Topic AND ValueIsFilled(Form.Topic)
		AND OldAttributesValues.Reviewed      = Form.Reviewed
		AND OldAttributesValues.ReviewAfter = Form.ReviewAfter Then
		Return;
	EndIf;
	
	CalculateReviewedItems = (OldAttributesValues.Reviewed <> Form.Reviewed)
	                        OR (OldAttributesValues.Topic <> Form.Topic AND ValueIsFilled(Form.Topic));
	
	StructureForWrite = InformationRegisters.InteractionsFolderSubjects.InteractionAttributes();
	StructureForWrite.Topic                 = Form.Topic;
	StructureForWrite.Reviewed             = Form.Reviewed;
	StructureForWrite.ReviewAfter        = Form.ReviewAfter;
	StructureForWrite.CalculateReviewedItems = CalculateReviewedItems;
	
	// If the interaction itself is set as a subject, nothing needs to be done.
	If Form.Topic = Ref Then
		InformationRegisters.InteractionsFolderSubjects.WriteInteractionFolderSubjects(Ref, StructureForWrite);
		CalculateReviewedByContactsOnWriteFromForm(CurrentObject, Form, OldAttributesValues);
		Return;
	EndIf;
	
	// If the interaction is set as a new subject, a subject of the new subject is to be checked.
	If ValueIsFilled(Form.Topic) Then
		
		If InteractionsClientServer.IsInteraction(Form.Topic) Then
			
			SubjectOfSubject = GetSubjectValue(Form.Topic);
			If Not ValueIsFilled(SubjectOfSubject) Then
				// Setting a reference to itself as a subject for the subject.
				StructureForWrite.Topic                 = Form.Topic;
				StructureForWrite.CalculateReviewedItems = True;
				InformationRegisters.InteractionsFolderSubjects.WriteInteractionFolderSubjects(Ref, StructureForWrite);
			Else
				StructureForWrite.Topic                 = SubjectOfSubject;
				StructureForWrite.CalculateReviewedItems = True;
				Form.Topic = SubjectOfSubject;
				InformationRegisters.InteractionsFolderSubjects.WriteInteractionFolderSubjects(Ref, StructureForWrite);
			EndIf;
			
		Else
			
			InformationRegisters.InteractionsFolderSubjects.WriteInteractionFolderSubjects(Ref, StructureForWrite);
			
		EndIf;
		
	Else
		
		StructureForWrite.Topic                 = Ref;
		StructureForWrite.CalculateReviewedItems = True;
		Form.Topic                              = Ref;
		InformationRegisters.InteractionsFolderSubjects.WriteInteractionFolderSubjects(Ref, StructureForWrite);
		
	EndIf;
	
	// If a previous subject is an interaction, you might need to change the subject in the whole chain.
	If ValueIsFilled(OldAttributesValues.Topic) AND InteractionsClientServer.IsInteraction(OldAttributesValues.Topic) Then
		
		If NOT (Ref <> OldAttributesValues.Topic 
			AND (Not ValueIsFilled(Form.Topic) 
			OR InteractionsClientServer.IsInteraction(Form.Topic))) Then
			
			ReplaceSubjectInInteractionsChain(OldAttributesValues.Topic, Form.Topic, Ref);
			
		EndIf;
		
	EndIf;
	
	CalculateReviewedByContactsOnWriteFromForm(CurrentObject, Form, OldAttributesValues);
	
EndProcedure

Procedure CalculateReviewedByContactsOnWriteFromForm(CurrentObject, Form, OldAttributesValues)
	
	If (DoNotSaveContacts(CurrentObject.AdditionalProperties) 
		AND OldAttributesValues.Reviewed      <> Form.Reviewed)
		OR Form.Object.Ref.IsEmpty() Then
		
		InteractionsArray = New Array;
		InteractionsArray.Add(CurrentObject.Ref);
		CalculateReviewedByContacts(InteractionsArray);
		
	EndIf;
	
EndProcedure

// An event handler before writing for interactions that occur in document forms.
//
// Parameters:
//  Form - ManagedForm - a form, in which the event occurred.
//  CurrentObject - DocumentObject - a document, in which the event occurred.
//
Procedure BeforeWriteInteractionFromForm(Form, CurrentObject, ContactsChanged = False) Export
	
	If NOT ContactsChanged Then
		
		CurrentObject.AdditionalProperties.Insert("DoNotSaveContacts", True);
		
	EndIf;
	
	If CurrentObject.Ref.IsEmpty() Then
		CurrentObject.InteractionBasis = Form.InteractionBasis;
	EndIf;

EndProcedure

// Fills in a list of interactions available for creation.
//
// Parameters:
//  DocumentsAvailableForCreation - ValueList - a value list to be filled in.
//
Procedure FillListOfDocumentsAvailableForCreation(DocumentsAvailableForCreation) Export
	
	For each DocumentToRegister In Metadata.DocumentJournals.Interactions.RegisteredDocuments Do
		
		If Not DocumentToRegister.Name = "IncomingEmail" Then
			
			DocumentsAvailableForCreation.Add(DocumentToRegister.Name,DocumentToRegister.Synonym);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Executed when importing saved user settings of the InteractionType quick filter in the 
// interaction document list forms.
//
// Parameters:
//  Form - ManagedForm - a form, for which the procedure is being executed.
//  Settings - Map - settings to import.
//
Procedure OnImportInteractionsTypeFromSettings(Form, Settings) Export

	InteractionType = Settings.Get("InteractionType");
	If InteractionType <> Undefined Then
		Settings.Delete("InteractionType");
	EndIf;
	
	If Form.EmailOnly Then
		If InteractionType = Undefined 
			OR Form.Items.InteractionType.ChoiceList.FindByValue(InteractionType) = Undefined Then
			InteractionType = "AllMessages";
			Settings.Delete("InteractionType");
		EndIf;
	Else
		If InteractionType = Undefined Then
			InteractionType = "All";
			Settings.Delete("InteractionType");
		EndIf;
	EndIf;
	
	Form.InteractionType = InteractionType;

EndProcedure

// Replaces a subject in interaction chain.
//
// Parameters:
//  Chain   - Ref - an interaction subject that will be replaced.
//  Subject	  - Ref - a subject that will replace the previous one.
//  Exclude - Ref - an interaction, where a subject will not be replaced.
//
Procedure ReplaceSubjectInInteractionsChain(Chain, Topic, Exclude = Undefined)
	
	SetPrivilegedMode(True);
	InteractionsArray = InteractionsFromChain(Chain, Exclude);
	InteractionsServerCall.SetSubjectForInteractionsArray(InteractionsArray, Topic);
	
EndProcedure

#EndRegion 

//////////////////////////////////////////////////////////////////////////////////
//   Managing items and attributes of list forms and document forms.

// Dynamically generates the "Address book" and "Select contacts" common forms according to the possible contact types.
//
Procedure AddContactsPickupFormPages(Form) Export
	
	DynamicListTypeDetails = New TypeDescription("DynamicList");
	
	AttributesToAdd = New Array;
	PossibleContactsDetailsArray = InteractionsClientServer.ContactsDetails();
	
	// Creating dynamic lists.
	For each DetailsArrayElement In PossibleContactsDetailsArray Do
		If DetailsArrayElement.Name = "Users" Then
			Continue;
		EndIf;
		
		AttributesToAdd.Add(
			New FormAttribute("List_" + DetailsArrayElement.Name ,DynamicListTypeDetails));
		
	EndDo;
	
	Form.ChangeAttributes(AttributesToAdd);
	
	// Setting main tables and required use of the IsFolder attribute in dynamic lists.
	For each DetailsArrayElement In PossibleContactsDetailsArray Do
		If DetailsArrayElement.Name = "Users" Then
			Continue;
		EndIf;
		
		Form["List_" + DetailsArrayElement.Name].MainTable = "Catalog." + DetailsArrayElement.Name;
		
	EndDo;
	
	For each DetailsArrayElement In PossibleContactsDetailsArray Do
		If DetailsArrayElement.Name = "Users" Then
			Continue;
		EndIf;
		
		If NOT DetailsArrayElement.HasOwner  Then
			
			PageItem = Form.Items.Add(
				"Page_" + DetailsArrayElement.Name,Type("FormGroup"),Form.Items.PagesLists);
			PageItem.Type                  = FormGroupType.Page;
			PageItem.ShowTitle  = True;
			PageItem.Title            = DetailsArrayElement.Presentation;
			PageItem.Group          = ChildFormItemsGroup.Vertical;
			
		EndIf;
		
		ItemTable = Form.Items.Add("Table_" + DetailsArrayElement.Name,
			Type("FormTable"),
			Form.Items[?(DetailsArrayElement.HasOwner,
			"Page_" + DetailsArrayElement.OwnerName,
			"Page_" + DetailsArrayElement.Name)]);
		ItemTable.DataPath = "List_" + DetailsArrayElement.Name;
		ItemTable.SetAction("Selection", "Attachable_CatalogListChoice");
		ItemTable.AutoMaxHeight = False;
		ItemTable.AutoMaxWidth = False;
		If Form.FormName = "CommonForm.SelectContactPerson" Then
			ItemTable.SelectionMode = TableSelectionMode.SingleRow;
			ItemTable.SetAction("OnActivateRow","Attachable_ListContactsOnActivateRow");
		EndIf;
		If DetailsArrayElement.HasOwner Then
			Form.Items["Table_" + DetailsArrayElement.OwnerName].SetAction(
				"OnActivateRow","Attachable_ListOwnerOnActivateRow");
			CommonClientServer.SetDynamicListFilterItem(
				Form["List_" + DetailsArrayElement.Name], "Owner", Undefined, , , True);
			ItemTable.Height = 5;
			Form.Items["Table_" + DetailsArrayElement.OwnerName].Height = 5;
		Else
			ItemTable.Height = 10;
		EndIf;
		
		ColumnRef = Form.Items.Add(
			"Column_" + DetailsArrayElement.Name + "_Ref",Type("FormField"),ItemTable);
		ColumnRef.Type = FormFieldType.InputField;
		ColumnRef.DataPath = "List_" + DetailsArrayElement.Name + ".Ref";
		ColumnRef.TitleLocation = FormItemTitleLocation.None;
		
	EndDo;
	
EndProcedure

// Sets a filter for a dynamic list of interaction documents, excluding documents that do not belong to mail.
//
// Parameters:
//  List - DynamicList - a dynamic list, for which the filter is being set.
//
Procedure CreateFilterByTypeAccordingToFR(List)
	
	FilterGroup = CommonClientServer.CreateFilterItemGroup(
		InteractionsClientServer.DynamicListFilter(List).Items, "FIlterByTypeAccordingToFO",
		DataCompositionFilterItemsGroupType.AndGroup);
	
	FieldName                    = "Type";
	FilterItemComparisonType = DataCompositionComparisonType.NotInList;
	TypesList = New ValueList;
	TypesList.Add(Type("DocumentRef.Meeting"));
	TypesList.Add(Type("DocumentRef.PlannedInteraction"));
	TypesList.Add(Type("DocumentRef.PhoneCall"));
	TypesList.Add(Type("DocumentRef.SMSMessage"));
	RightValue             = TypesList;
	CommonClientServer.AddCompositionItem(
		FilterGroup, FieldName, FilterItemComparisonType, RightValue);

EndProcedure

// Initializes the passed form of the Form interaction list according to functional option values.
// 
// Parameters:
//  Form - ManagedForm - a form, for which attributes are being initialized.
//  Parameters - Structure -
//
Procedure InitializeInteractionsListForm(Form, Parameters) Export

	If Parameters.Property("EmailOnly") AND Parameters.EmailOnly Then
		Form.EmailOnly = True;
	Else
		Form.EmailOnly = NOT GetFunctionalOption("UseOtherInteractions");
	EndIf;
	
	Form.Items.CreateEmailSpecialButtonList.Visible = Form.EmailOnly;
	Form.Items.CreateGroup.Visible = NOT Form.EmailOnly;
	If Form.EmailOnly Then
		Form.Title = NStr("ru = 'Электронная почта'; en = 'Email'; pl = 'Email';de = 'Email';ro = 'Email';tr = 'Email'; es_ES = 'Email'");
		Form.Items.InteractionType.ChoiceListHeight = 6;
		CreateFilterByTypeAccordingToFR(Form.List);
		GenerateChoiceListInteractionTypeEmailOnly(Form.Items.InteractionType);
		Form.Commands.Topic.Title = NStr("ru = 'Установить предмет переписки'; en = 'Set correspondence subject'; pl = 'Set correspondence subject';de = 'Set correspondence subject';ro = 'Set correspondence subject';tr = 'Set correspondence subject'; es_ES = 'Set correspondence subject'");
		Form.Commands.Topic.ToolTip = NStr("ru = 'Установить предмет переписки'; en = 'Set correspondence subject'; pl = 'Set correspondence subject';de = 'Set correspondence subject';ro = 'Set correspondence subject';tr = 'Set correspondence subject'; es_ES = 'Set correspondence subject'");
		Form.Items.Copy.Visible = False;
		If Form.Items.Find("InteractionsTreeCopy") <> Undefined Then
			Form.Items.InteractionsTreeCopy.Visible = False;
		EndIf;
		If Form.Items.Find("InteractionsTreeContextMenuCopy") <> Undefined Then
			Form.Items.InteractionsTreeContextMenuCopy.Visible = False;
		EndIf;
		If Form.Items.Find("ListContextMenuCopy") <> Undefined Then
			Form.Items.ListContextMenuCopy.Visible = False;
		EndIf;
		If Form.Commands.Find("SubjectList") <> Undefined Then
			Form.Commands.SubjectList.Title = NStr("ru = 'Установить предмет переписки'; en = 'Set correspondence subject'; pl = 'Set correspondence subject';de = 'Set correspondence subject';ro = 'Set correspondence subject';tr = 'Set correspondence subject'; es_ES = 'Set correspondence subject'");
			Form.Commands.SubjectList.ToolTip = NStr("ru = 'Установить предмет переписки'; en = 'Set correspondence subject'; pl = 'Set correspondence subject';de = 'Set correspondence subject';ro = 'Set correspondence subject';tr = 'Set correspondence subject'; es_ES = 'Set correspondence subject'");
		EndIf;
	EndIf;
	Form.UseReviewedFlag = GetFunctionalOption("UseReviewedFlag");

EndProcedure

// Determines whether it is necessary to display an address book and forms of choosing user group contact.
//
// Parameters:
//  Form - ManagedForm - a form, for which the procedure will be executed.
//
Procedure ProcessUserGroupsDisplayNecessity(Form) Export
	
	Form.UseUserGroups = GetFunctionalOption("UseUserGroups");
	If Not Form.UseUserGroups Then
		Form.UsersList.CustomQuery = False;
	Else
		Form.UsersList.Parameters.SetParameterValue("UsersGroup", Catalogs.UserGroups.EmptyRef());
	EndIf;
	
EndProcedure
//////////////////////////////////////////////////////////////////////////////////
// Handling interaction subjects.

// Sets a subject for the interaction document.
//
// Parameters:
//  Ref - DocumentRef.IncomingEmail,
//            DocumentRef.OutgoingEmail,
//            DocumentRef.Meeting,
//            DocumentRef.PlannedInteraction,
//            DocumentRef.PhoneCall - an interaction, for which the subject will be set.
//  Subject - ArbitraryRef - a reference to the object to set.
//
Procedure SetSubject(Ref, Topic, CalculateReviewedItems = True) Export
	
	StructureForWrite = InformationRegisters.InteractionsFolderSubjects.InteractionAttributes();
	StructureForWrite.Topic                 = Topic;
	StructureForWrite.CalculateReviewedItems = CalculateReviewedItems;
	InformationRegisters.InteractionsFolderSubjects.WriteInteractionFolderSubjects(Ref, StructureForWrite);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////////
// Generating an email

// Generates an HTML text for an incoming email.
//
// Parameters:
//  Email - DocumentRef.IncomingEmail
//  ForPrint - Boolean - indicates that HTML text is generated for an email print form.
//  ProcessPictures - Boolean - indicates that pictures will be nested in HTML.
//
// Returns:
//   String - a generated HTML text for the incoming email.
//
Function GenerateHTMLTextForIncomingEmail(Email, ForPrint, ProcessPictures,
	DisableExternalResources = True, HasExternalResources = Undefined) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = "
	|SELECT 
	|	IncomingEmail.Ref AS Email,
	|	IncomingEmail.Date,
	|	IncomingEmail.DateReceived,
	|	IncomingEmail.SenderAddress,
	|	IncomingEmail.SenderPresentation,
	|	IncomingEmail.Text,
	|	IncomingEmail.HTMLText,
	|	IncomingEmail.Subject,
	|	IncomingEmail.TextType AS TextType,
	|	IncomingEmail.TextType AS TextTypeConversion,
	|	IncomingEmail.EmailRecipients.(
	|		Ref,
	|		LineNumber,
	|		Address,
	|		Presentation,
	|		Contact
	|	),
	|	IncomingEmail.CCRecipients.(
	|		Ref,
	|		LineNumber,
	|		Address,
	|		Presentation,
	|		Contact
	|	),
	|	ISNULL(EmailAccounts.UserName, """") AS UserAccountUsername,
	|	IncomingEmail.Encoding
	|FROM
	|	Document.IncomingEmail AS IncomingEmail
	|		LEFT JOIN Catalog.EmailAccounts AS EmailAccounts
	|		ON IncomingEmail.Account = EmailAccounts.Ref
	|WHERE
	|	IncomingEmail.Ref = &Email";
	
	Query.SetParameter("Email",Email);
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	GenerationParameters = HTMLDocumentGenerationParametersOnEmailBasis(Selection);
	GenerationParameters.ProcessPictures = ProcessPictures;
	GenerationParameters.DisableExternalResources = DisableExternalResources;
	
	DocumentHTML = GenerateHTMLDocumentBasedOnEmail(GenerationParameters, HasExternalResources);
	
	If ForPrint Then
		GenerateHeaderAndFooterOfEmailPrintForm(Email, DocumentHTML, Selection);
	EndIf;
	
	Return GetHTMLTextFromHTMLDocumentObject(DocumentHTML);
	
EndFunction

// Generates an HTML text for an outgoing email.
//
// Parameters:
//  Email - DocumentRef.OutgoingEmail
//  ForPrint - Boolean - indicates that HTML text is generated for an email print form.
//  ProcessPictures - Boolean - indicates that pictures will be nested in HTML.
//
// Returns:
//   String - a generated HTML text for the outgoing email.
//
Function GenerateHTMLTextForOutgoingEmail(Email, ForPrint, ProcessPictures,
	DisableExternalResources = True, HasExternalResources = Undefined) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	OutgoingEmail.Ref AS Email,
	|	OutgoingEmail.Date,
	|	OutgoingEmail.EmailStatus,
	|	OutgoingEmail.SenderPresentation,
	|	OutgoingEmail.Text,
	|	OutgoingEmail.HTMLText,
	|	OutgoingEmail.Subject,
	|	OutgoingEmail.TextType AS TextType,
	|	OutgoingEmail.TextType AS TextTypeConversion,
	|	OutgoingEmail.InteractionBasis,
	|	OutgoingEmail.IncludeOriginalEmailBody,
	|	OutgoingEmail.EmailRecipients.(
	|		Ref,
	|		LineNumber,
	|		Address,
	|		Presentation,
	|		Contact
	|	),
	|	OutgoingEmail.CCRecipients.(
	|		Ref,
	|		LineNumber,
	|		Address,
	|		Presentation,
	|		Contact
	|	),
	|	ISNULL(EmailAccounts.UserName, """") AS UserAccountUsername
	|FROM
	|	Document.OutgoingEmail AS OutgoingEmail
	|		LEFT JOIN Catalog.EmailAccounts AS EmailAccounts
	|		ON OutgoingEmail.Account = EmailAccounts.Ref
	|WHERE
	|	OutgoingEmail.Ref = &Email";
	
	Query.SetParameter("Email",Email);
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	GenerationParameters = HTMLDocumentGenerationParametersOnEmailBasis(Selection);
	GenerationParameters.ProcessPictures = ProcessPictures;
	GenerationParameters.DisableExternalResources = DisableExternalResources;
	
	DocumentHTML = GenerateHTMLDocumentBasedOnEmail(GenerationParameters, HasExternalResources);
	
	If Selection.EmailStatus = Enums.OutgoingEmailStatuses.Draft 
		AND Selection.IncludeOriginalEmailBody 
		AND Selection.InteractionBasis <> Undefined 
		AND (TypeOf(Selection.InteractionBasis) = Type("DocumentRef.IncomingEmail") 
		OR TypeOf(Selection.InteractionBasis) = Type("DocumentRef.OutgoingEmail")) Then
		
		BaseSelection = GetBaseEmailData(Selection.InteractionBasis);
		
		HTMLText = BaseSelection.HTMLText;
		If StrFind(BaseSelection.HTMLText, "body") = 0 Then
			HTMLText = "<body>" +BaseSelection.HTMLText + "</body>";
		EndIf;
		
		GenerationParameters = HTMLDocumentGenerationParametersOnEmailBasis();
		GenerationParameters.Email = Selection.InteractionBasis;
		GenerationParameters.TextType = BaseSelection.TextType;
		GenerationParameters.Text = BaseSelection.Text;
		GenerationParameters.HTMLText = BaseSelection.HTMLText;
		GenerationParameters.TextTypeConversion = Selection.TextType;
		GenerationParameters.DisableExternalResources = DisableExternalResources;
		
		DocumentHTMLBase = GenerateHTMLDocumentBasedOnEmail(GenerationParameters, HasExternalResources);
		
		ElementBodyHTMLBase = DocumentHTMLBase.Body;
		BodyChildNodesArrayBase = ArrayOfChildNodesContainingHTML(ElementBodyHTMLBase);
		
		DIVElement = AddElementWithAttributes(ElementBodyHTMLBase,
			"div",New Structure("style","border:none;border-left:solid blue 1.5pt;padding:0cm 0cm 0cm 4.0pt"));
		
		For each ChildNode In BodyChildNodesArrayBase Do
			
			DIVElement.AppendChild(ChildNode);
			
		EndDo;
		
		AttributesStructure = New Structure;
		AttributesStructure.Insert("size", "2");
		AttributesStructure.Insert("width", "100%");
		AttributesStructure.Insert("align", "center");
		AttributesStructure.Insert("tabindex", "-1");
		
		HRElement = AddElementWithAttributes(DIVElement, "hr", AttributesStructure);
		InsertHTMLElementAsFirstChildElement(DIVElement,HRElement,BodyChildNodesArrayBase);
		
		BaseEmailHeaderDataStructure = New Structure;
		BaseEmailHeaderDataStructure.Insert("SenderPresentation", BaseSelection.SenderPresentation);
		BaseEmailHeaderDataStructure.Insert("SenderAddress", BaseSelection.SenderAddress);
		BaseEmailHeaderDataStructure.Insert("Date", BaseSelection.Date);
		BaseEmailHeaderDataStructure.Insert("Subject", BaseSelection.Subject);
		BaseEmailHeaderDataStructure.Insert("EmailRecipients", BaseSelection.EmailRecipients);
		BaseEmailHeaderDataStructure.Insert("CCRecipients", BaseSelection.CCRecipients);
		
		FontItem = GenerateEmailHeaderDataItem(DIVElement,
		BaseEmailHeaderDataStructure,
		BaseSelection.MetadataObjectName = "OutgoingEmail");
		InsertHTMLElementAsFirstChildElement(DIVElement,FontItem,BodyChildNodesArrayBase);
		
		BodyChildNodesArrayCurrent = ArrayOfChildNodesContainingHTML(DocumentHTML.Body);
		For Each ChildNode In BodyChildNodesArrayCurrent Do
			
			ElementBodyHTMLBase.InsertBefore(DocumentHTMLBase.ImportNode(ChildNode,True),DIVElement);
			
		EndDo;
		
		DocumentHTML = DocumentHTMLBase;
		
	EndIf;
	
	If ForPrint Then
		GenerateHeaderAndFooterOfEmailPrintForm(Email, DocumentHTML, Selection);
	EndIf;
	
	Return GetHTMLTextFromHTMLDocumentObject(DocumentHTML);
	
EndFunction

// Generates an HTML document based on the email.
//
// Parameters:
//  GenerationParameters - Structure - parameters of generating an HTML document:
//   * Email - DocumentRef.IncomingEmail,
//               DocumentRef.OutgoingEmail - an email to be evaluated.
//   * TextType - EnumRef.EmailsTextTypes - an email text type.
//   * Text - String - an email text.
//   * HTMLText - String - an email text in HTML format.
//   * TextTypeConversion - EnumRef.EmailsTextTypes - a text type to convert the email to.
//                                                                                 
//   * Encoding - String - an email encoding.
//   * ProcessPictures - Boolean - indicates that pictures will be nested in HTML.
//  HasExternalResources - Boolean - a return value, True if a letter contains items imported from the Internet.
//
// Returns:
//   String - a processed email text.
//
Function GenerateHTMLDocumentBasedOnEmail(GenerationParameters, HasExternalResources = Undefined) Export
	
	Email = GenerationParameters.Email;
	TextType = GenerationParameters.TextType;
	Text = GenerationParameters.Text;
	HTMLText = GenerationParameters.HTMLText;
	TextTypeConversion = ?(GenerationParameters.TextTypeConversion = Undefined,
		GenerationParameters.TextType, GenerationParameters.TextTypeConversion);
	Encoding = GenerationParameters.Encoding;
	ProcessPictures = GenerationParameters.ProcessPictures;
	DisableExternalResources = GenerationParameters.DisableExternalResources;
		
	If TextType <> TextTypeConversion 
		AND TextType <> Enums.EmailTextTypes.PlainText Then
		
		IncomingEmailText = GetPlainTextFromHTML(HTMLText);
		
		DocumentHTML = GetHTMLDocumentFromPlainText(IncomingEmailText);
		
	ElsIf TextType = Enums.EmailTextTypes.PlainText 
		OR (TextType.IsEmpty() AND TrimAll(HTMLText) = "") Then
		
		DocumentHTML = GetHTMLDocumentFromPlainText(Text);
		
	Else
		
		EmailEncoding = Encoding;
		
		If IsBlankString(EmailEncoding) Then
			EncodingAttributePosition = StrFind(HTMLText,"charset");
			If EncodingAttributePosition <> 0 Then
				Ind = 0;
				While CharCode(Mid(HTMLText,EncodingAttributePosition + 8 + Ind,1)) <> 34 Do
					EmailEncoding = EmailEncoding + Mid(HTMLText,EncodingAttributePosition + 8 + Ind,1);
					Ind = Ind + 1;
				EndDo
			Else
				EmailEncoding = "utf8";
			EndIf;
		EndIf;
		
		If TypeOf(Email) = Type("Structure") Then
			FilesTable = Email.Attachments;
		Else
			FilesTable = GetEmailAttachmentsWithNonBlankIDs(Email);
		EndIf;
		
		TextToProcess = HTMLText;
		
		If StrOccurrenceCount(Lower(TextToProcess),"<html") = 0 Then
			TextToProcess = "<html>" + TextToProcess + "</html>"
		EndIf;
		
		AttemptNumber = 1;
		EmailText = HTMLTagContent(TextToProcess, "html", True, AttemptNumber);
		While StrFind(Lower(EmailText), "<body") = 0 
			AND Not IsBlankString(EmailText) Do
			AttemptNumber = AttemptNumber + 1;
			EmailText = HTMLTagContent(TextToProcess, "html", True, AttemptNumber);
		EndDo;
		
		If FilesTable.Count() Then
			
			DocumentHTML = ReplacePicturesIDsWithPathToFiles(EmailText, FilesTable, EmailEncoding, ProcessPictures);
			
		Else
			
			DocumentHTML = GetHTMLDocumentObjectFromHTMLText(EmailText, EmailEncoding);
			
		EndIf;
		
	EndIf;
	
	HasExternalResources = HasExternalResources(DocumentHTML);
	DisableUnsafeContent(DocumentHTML, HasExternalResources AND DisableExternalResources);
	
	Return DocumentHTML;
	
EndFunction
	
// Processes an email HTML text.
//
// Parameters:
//  Email - DocumentRef.IncomingEmail,
//            DocumentRef.OutgoingEmail - an email to be evaluated.
//
// Returns:
//   String - a processed email text.
//
Function ProcessHTMLText(Email, DisableExternalResources = True, HasExternalResources = Undefined) Export
	
	AttributesStructure = Common.ObjectAttributesValues(Email,"HTMLText,Encoding");
	HTMLText = AttributesStructure.HTMLText;
	Encoding = AttributesStructure.Encoding;
	
	If Not IsBlankString(HTMLText) Then
		
		// Adding an HTML tag if it is missing. Such emails can come from Gmail, for example.
		// It is required for the correct representation in the form item.
		If StrOccurrenceCount(HTMLText,"<html") = 0 Then
			HTMLText = "<html>" + HTMLText + "</html>"
		EndIf;
		
		FilterHTMLTextContent(HTMLText, Encoding, DisableExternalResources, HasExternalResources);
		
		FilesTable = GetEmailAttachmentsWithNonBlankIDs(Email);
		
		If FilesTable.Count() Then
			HTMLText = HTMLTagContent(HTMLText, "html", True);
			DocumentHTML = ReplacePicturesIDsWithPathToFiles(HTMLText, FilesTable, Encoding);
			
			Return GetHTMLTextFromHTMLDocumentObject(DocumentHTML);
		EndIf;
	EndIf;
	
	Return HTMLText;
	
EndFunction

// Finds a tag content in HTML.
//
// Parameters:
//  Text - String - a searched XML text.
//  TagName - String - a tag whose content is to be found.
//  IncludeStartEndTag - Boolean - indicates that the found item includes start and end tags, the 
//                                               default value is False.
//  SerialNumber - Number - a position, from which the search starts, the default value is 1.
// 
// Returns:
//   String - a string, from which a new line character and a carriage return character are deleted.
//
Function HTMLTagContent(Text, TagName, IncludeStartEndTag = False, SerialNumber = 1) Export
	
	Result = Undefined;
	
	Start    = "<"  + TagName;
	End = "</" + TagName + ">";
	
	FoundPositionStart = StrFind(Lower(Text), Lower(Start), SearchDirection.FromBegin, 1, SerialNumber);
	FoundPositionEnd = StrFind(Lower(Text), Lower(End), SearchDirection.FromBegin, 1, SerialNumber);
	If FoundPositionStart = 0
		Or FoundPositionEnd = 0 Then
		Return "";
	EndIf;
	
	Content = Mid(Text,
	                  FoundPositionStart,
	                  FoundPositionEnd - FoundPositionStart + StrLen(End));
	
	If IncludeStartEndTag Then
		
		Result = TrimAll(Content);
		
	Else
		
		StartTag = Left(Content, StrFind(Content, ">"));
		Content = StrReplace(Content, StartTag, "");
		
		EndTag = Right(Content, StrLen(Content) - StrFind(Content, "<", SearchDirection.FromEnd) + 1);
		Content = StrReplace(Content, EndTag, "");
		
		Result = TrimAll(Content);
		
	EndIf;
	
	Return Result;
	
EndFunction

// Returns outgoing mail format by default for the user, based on the system settings and the format 
// of the last letter sent by the user.
// 
// Parameters:
//   User - CatalogRef.Users - a user.
//
// Returns
//   EnumRef.EmailsEditOptions.
// 
Function DefaultMessageFormat(User) Export
	
	If Not GetFunctionalOption("SendEmailsInHTMLFormat") Then
		Return Enums.EmailEditingMethods.NormalText;
	EndIf;
	
	Query = New Query;
	Query.Text = "SELECT ALLOWED TOP 1
	|	CASE
	|		WHEN OutgoingEmail.TextType = VALUE(Enum.EmailTextTypes.PlainText)
	|			THEN VALUE(Enum.EmailEditingMethods.NormalText)
	|		ELSE VALUE(Enum.EmailEditingMethods.HTML)
	|	END AS MessageFormat,
	|	OutgoingEmail.Date
	|FROM
	|	Document.OutgoingEmail AS OutgoingEmail
	|WHERE
	|	OutgoingEmail.Author = &User
	|	AND (NOT OutgoingEmail.DeletionMark)
	|
	|ORDER BY
	|	OutgoingEmail.Date DESC";
	
	Query.SetParameter("User",User);
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return Enums.EmailEditingMethods.NormalText;
	Else
		Selection = QueryResult.Select();
		Selection.Next();
		Return Selection.MessageFormat;
	EndIf;
	
EndFunction

// Replaces attachment picture IDs with file path in the HTML text and creates an HTML document object.
//
// Parameters:
//  HTMLText - String - an HTML text to process.
//  FilesTable - ValueTable - a table containing information about attached files.
//  Encoding - String - HTML text encoding.
//
// Returns:
//  DocumentHTML - a created HTML document.
//
Function ReplacePicturesIDsWithPathToFiles(HTMLText,FilesTable,Encoding = Undefined, ProcessPictures = False)
	
	DocumentHTML = GetHTMLDocumentObjectFromHTMLText(HTMLText,Encoding);
	
	For each AttachedFile In FilesTable Do
		
		For each Picture In DocumentHTML.Images Do
			
			AttributePictureSource = Picture.Attributes.GetNamedItem("src");
			If AttributePictureSource = Undefined Then
				Continue;
			EndIf;
			
			If StrOccurrenceCount(AttributePictureSource.Value, AttachedFile.EmailFileID) > 0 Then
				
				NewAttributePicture = AttributePictureSource.CloneNode(False);
				If ProcessPictures Then
					If IsTempStorageURL(AttachedFile.Ref) Then
						BinaryData = GetFromTempStorage(AttachedFile.Ref);
						Extension     =  AttachedFile.Extension;
					Else
						FileData = FilesOperations.FileData(AttachedFile.Ref);
						BinaryData = GetFromTempStorage(FileData.BinaryFileDataRef);
						Extension     = FileData.Extension;
					EndIf;
					TextContent = Base64String(BinaryData);
					TextContent = "data:image/" + Mid(Extension,2) + ";base64," + Chars.LF + TextContent;
				Else
					// If picture data could not be received, picture is not displayed. User is not notified about it.
					
					If IsTempStorageURL(AttachedFile.Ref) Then
						TextContent = AttachedFile.Ref;
					Else
						Try
							TextContent = FilesOperations.FileData(AttachedFile.Ref).BinaryFileDataRef;
						Except
							TextContent = "";
						EndTry;
					EndIf;
					
				EndIf;
				
				NewAttributePicture.TextContent = TextContent;
				Picture.Attributes.SetNamedItem(NewAttributePicture);
				
				Break;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	Return DocumentHTML;
	
EndFunction

// Receives attachments of a letter whose ID is not blank.
//
// Parameters:
//  Email - DocumentRef.IncomingEmail,
//            DocumentRef.OutgoingEmail - an email to be evaluated.
//
// Returns:
//   ValueTable   - a table with informations on attachments of email whose ID is not blank.
//
Function GetEmailAttachmentsWithNonBlankIDs(Email) Export
	
	AttachedEmailFilesData = AttachedEmailFilesData(Email);
	MetadataObjectName = AttachedEmailFilesData.AttachedFilesCatalogName;
	FilesOwner       = AttachedEmailFilesData.FilesOwner;
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	AttachedFilesInMessage.Ref,
	|	AttachedFilesInMessage.Description,
	|	AttachedFilesInMessage.Size,
	|	AttachedFilesInMessage.EmailFileID
	|FROM
	|	Catalog." + MetadataObjectName + " AS AttachedFilesInMessage
	|WHERE
	|	AttachedFilesInMessage.FileOwner = &FilesOwner
	|	AND (NOT AttachedFilesInMessage.DeletionMark)
	|	AND AttachedFilesInMessage.EmailFileID <> &BlankRow";
	
	Query.SetParameter("BlankRow","");
	Query.SetParameter("FilesOwner",FilesOwner);
	
	Return Query.Execute().Unload();
	
EndFunction 

// Gets base email data.
//
// Parameters:
//  Email - DocumentRef.IncomingEmail,
//            DocumentRef.OutgoingEmail - an email to be evaluated.
//
// Returns:
//   SelectionFromQueryResults   - estimating email size in bytes.
//
Function GetBaseEmailData(Email) Export
	
	MetadataObjectName = Email.Metadata().Name;
	
	Query = New Query;
	Query.Text = "
	|SELECT EmailMessageBasis.TextType AS TextType,
	|	EmailMessageBasis.Subject AS Subject,
	|	EmailMessageBasis.HTMLText AS HTMLText,
	|	EmailMessageBasis.Text AS Text,
	|" + ?(MetadataObjectName = "IncomingEmail","EmailMessageBasis.SenderAddress","&BlankRow")+" AS SenderAddress,
	|	EmailMessageBasis.SenderPresentation AS SenderPresentation,
	|	EmailMessageBasis.Date AS Date,
	|	&MetadataObjectName AS MetadataObjectName,
	|	EmailMessageBasis.CCRecipients.(
	|		Ref,
	|		LineNumber,
	|		Address,
	|		Presentation,
	|		Contact
	|	) AS CCRecipients,
	|	EmailMessageBasis.EmailRecipients.(
	|		Ref,
	|		LineNumber,
	|		Address,
	|		Presentation,
	|		Contact
	|	) AS EmailRecipients
	|FROM Document." + MetadataObjectName + " AS EmailMessageBasis
	|WHERE
	|	EmailMessageBasis.Ref = &Email";
	
	Query.SetParameter("Email",Email);
	Query.SetParameter("BlankRow","");
	Query.SetParameter("MetadataObjectName",MetadataObjectName);
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	Return Selection;
	
EndFunction

// Processes HTML text for storing to a formatted document.
//
// Parameters:
//  Email - DocumentRef.IncomingEmail,
//            DocumentRef.OutgoingEmail - an email to be evaluated.
//  HTMLText - String - an HTML text to process.
//  AttachmentsStructure - Structure - a structure, where pictures attached to an email are placed.
//
// Returns:
//   Number   - estimating email size in bytes.
//
Function ProcessHTMLTextForFormattedDocument(Email,HTMLText,AttachmentsStructure) Export
	
	If Not IsBlankString(HTMLText) Then
		
		DocumentHTML = GetHTMLDocumentObjectFromHTMLText(HTMLText);
		
		FilesTable = GetEmailAttachmentsWithNonBlankIDs(Email);
		
		If FilesTable.Count() Then
			
			For each AttachedFile In FilesTable Do
				
				For each Picture In DocumentHTML.Images Do
					
					AttributePictureSource = Picture.Attributes.GetNamedItem("src");
					
					If StrOccurrenceCount(AttributePictureSource.Value, AttachedFile.EmailFileID) > 0 Then
						
						NewAttributePicture = AttributePictureSource.CloneNode(False);
						NewAttributePicture.TextContent = AttachedFile.Description;
						Picture.Attributes.SetNamedItem(NewAttributePicture);
						
						AttachmentsStructure.Insert(
							AttachedFile.Description,
							New Picture(GetFromTempStorage(
								FilesOperations.FileData(AttachedFile.Ref).BinaryFileDataRef)));
						
						Break;
						
					EndIf;
					
				EndDo;
				
			EndDo;
			
			Return GetHTMLTextFromHTMLDocumentObject(DocumentHTML);
			
		Else
			
			Return HTMLText;
			
		EndIf;
		
	Else
		
		Return HTMLText;
		
	EndIf;
	
EndFunction

// Gets presentation of incoming email recipients.
//
// Parameters:
//  RecipientsTable  - TabularSection - a tabular section, for which the function is executed.
//
// Returns:
//   StringToReturn - a string with presentation of all tabular section users.
//
Function GetIncomingEmailRecipientsPresentations(RecipientsTable) Export

	StringToReturn = "";
	
	For Each Recipient In RecipientsTable Do
		
		StringToReturn = StringToReturn + "'" 
		         + ?(IsBlankString(Recipient.Presentation), Recipient.Address, Recipient.Presentation + "<"+ Recipient.Address+">") + "'"+ ", ";
		
	EndDo;
	
	If Not IsBlankString(StringToReturn) Then
		
		StringToReturn = Left(StringToReturn,StrLen(StringToReturn) - 2);
		
	EndIf;
	
	Return StringToReturn;

EndFunction

// Generates an HTML item of outgoing email header.
// Parameters:
//  ParentElement - HTMLElement - a parent HTML element, for which a header data item will be added.
//  Selection - QueryResultSelection - a selection by the email data.
//  OnlyBySenderPresentation - Boolean - determines whether it is necessary to include the sender 
//                                              address or his presentation is enough.
//
Function GenerateEmailHeaderDataItem(ParentElement,Selection,OnlyBySenderPresentation = False) Export
	
	DocumentOwner = ParentElement.OwnerDocument;
	
	ItemTable = DocumentOwner.CreateElement("table");
	SetHTMLElementAttribute(ItemTable,"border", "0");
	
	SenderPresentation = Selection.SenderPresentation 
	                           + ?(OnlyBySenderPresentation Or IsBlankString(Selection.SenderAddress),
	                              "",
	                             "[" + Selection.SenderAddress +"]");
	
	AddRowToTable(ItemTable, "From: ", SenderPresentation);
	AddRowToTable(ItemTable, "Sent: ", Format(Selection.Date,"DLF=D'"));
	
	EmailRecipientsTable = ?(TypeOf(Selection.EmailRecipients) = Type("ValueTable"),Selection.EmailRecipients, Selection.EmailRecipients.Unload());
	AddRowToTable(ItemTable, "To: ", GetIncomingEmailRecipientsPresentations(EmailRecipientsTable));
	
	CCRecipientsTable = ?(TypeOf(Selection.CCRecipients) = Type("ValueTable"),Selection.CCRecipients, Selection.CCRecipients.Unload());
	If CCRecipientsTable.Count() > 0 Then
		AddRowToTable(ItemTable, "cc: ", GetIncomingEmailRecipientsPresentations(CCRecipientsTable));

	EndIf;

	
	MailSubject = ?(IsBlankString(Selection.Subject), NStr("ru = '<Без Темы>'; en = '<No Subject>'; pl = '<No Subject>';de = '<No Subject>';ro = '<No Subject>';tr = '<No Subject>'; es_ES = '<No Subject>'"), Selection.Subject);
	AddRowToTable(ItemTable, "Subject: ", MailSubject);
	
	Return ItemTable;
	
EndFunction

// Complements an email body with a print form header.
// Parameters:
//  DocumentHTML - HTMLDocument - a HTML document whose header will be complemented.
//  Selection - QueryResultSelection - a selection by the email data.
//  IsOutgoingEmail - Boolean - True if an email is outgoing, False if the email is incoming.
//
Procedure AddPrintFormHeaderToEmailBody(DocumentHTML, Selection, IsOutgoingEmail) Export
	
	EmailBodyItem = EmailBodyItem(DocumentHTML);
	BodyChildNodesArray = ArrayOfChildNodesContainingHTML(EmailBodyItem);
	
	// Account username.
	UserItem = GenerateAccountUsernameItem(EmailBodyItem, Selection);
	InsertHTMLElementAsFirstChildElement(EmailBodyItem,UserItem, BodyChildNodesArray);
	
	InsertHTMLElementAsFirstChildElement(EmailBodyItem,
	                                           HorizontalSeparatorItem(EmailBodyItem),
	                                           BodyChildNodesArray);
	
	// Email header
	EmailHeaderDataItem = GenerateEmailHeaderDataItem(EmailBodyItem,Selection,IsOutgoingEmail);
	InsertHTMLElementAsFirstChildElement(EmailBodyItem,EmailHeaderDataItem,BodyChildNodesArray);
	BRItem = DocumentHTML.CreateElement("br");
	InsertHTMLElementAsFirstChildElement(EmailBodyItem, BRItem, BodyChildNodesArray);
	
EndProcedure

// Replaces picture names in an HTML document with mail attachment IDs.
// Parameters:
//  DocumentHTML - HTMLDocument - an HTML document, where replacement will be executed.
//  MapsTable - ValueTable - a table of mapping file names to IDs.
//
Procedure ChangePicturesNamesToMailAttachmentsIDsInHTML(DocumentHTML, MapsTable) Export
	
	MapsTable.Indexes.Add("FileName");
	
	For each Picture In DocumentHTML.Images Do
		
		AttributePictureSource = Picture.Attributes.GetNamedItem("src");
		
		FoundRow = MapsTable.Find(AttributePictureSource.TextContent,"FileName");
		If FoundRow <> Undefined Then
			
			NewAttributePicture = AttributePictureSource.CloneNode(False);
			NewAttributePicture.TextContent = String("cid:"+FoundRow.FileIDForHTML);
			Picture.Attributes.SetNamedItem(NewAttributePicture);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Function GenerateAccountUsernameItem(ParentElement,Selection)
	
	FontItem = AddElementWithAttributes(ParentElement, "Font", New Structure("size,face", "3", "Tahoma"));
	AddTextNode(FontItem,Selection.UserAccountUsername, True);
	
	Return FontItem;
	
EndFunction

Procedure GenerateHeaderAndFooterOfEmailPrintForm(Email, DocumentHTML, Selection)
	
	AddPrintFormHeaderToEmailBody(DocumentHTML,Selection,True);
	
	AttachmentTable = EmailManagement.GetEmailAttachments(Email, True,  True);
	If TypeOf(Email) = Type("DocumentRef.OutgoingEmail") Then
		
		AttachmentEmailsTable = DataStoredInAttachmentsEmailsDatabase(Email);
		
		For Each AttachmentEmail In AttachmentEmailsTable Do
		
			NewRow = AttachmentTable.Add();
			NewRow.FileName                  = EmailPresentation(AttachmentEmail.Subject, AttachmentEmail.Date) + ".eml";
			NewRow.PictureIndex            = 0;
			NewRow.SignedWithDS                = False;
			NewRow.EmailFileID = "";
			NewRow.Size                    = AttachmentEmail.Size;
			NewRow.SizePresentation       = InteractionsClientServer.GetFileSizeStringPresentation(AttachmentEmail.Size)
		
		EndDo
		
	EndIf;
	
	If AttachmentTable.Count() > 0 Then
		AddAttachmentFooterToEmailBody(DocumentHTML, AttachmentTable);
	EndIf;
	
EndProcedure

// Estimates an email size.
//
// Parameters:
//  Email - DocumentRef.IncomingEmail,
//            DocumentRef.OutgoingEmail - an email to be evaluated.
//
// Returns:
//   Number   - estimating email size in bytes.
//
Function EvaluateOutgoingEmailSize(Email) Export
	
	Size = 0;
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	SUM(ISNULL(OutgoingEmailAttachedFiles.Size, 0) * 1.5) AS Size
	|FROM
	|	Catalog.OutgoingEmailAttachedFiles AS OutgoingEmailAttachedFiles
	|WHERE
	|	OutgoingEmailAttachedFiles.FileOwner = &Email
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CASE
	|		WHEN OutgoingEmail.TextType = VALUE(Enum.EmailTextTypes.PlainText)
	|			THEN OutgoingEmail.Text
	|		ELSE OutgoingEmail.HTMLText
	|	END AS Text,
	|	OutgoingEmail.Subject
	|FROM
	|	Document.OutgoingEmail AS OutgoingEmail
	|WHERE
	|	OutgoingEmail.Ref = &Email";
	
	Query.SetParameter("Email",Email);
	
	Result = Query.ExecuteBatch();
	If NOT Result[0].IsEmpty() Then
		Selection = Result[0].Select();
		Selection.Next();
		Size = Size + ?(Selection.Size = Null, 0, Selection.Size);
	EndIf;
	
	If NOT Result[1].IsEmpty() Then
		Selection = Result[1].Select();
		Selection.Next();
		Size = Size + StrLen(Selection.Text) + StrLen(Selection.Subject);
		
	EndIf;;
	
	Return Size;

EndFunction

////////////////////////////////////////////////////////////////////////////////////
// Operations with the HTML Document object.

// Gets an array of HTML element child nodes that contain HTML.
//
// Parameters:
//  Element - HTMLElement
//
// Returns:
//   Array   - an array of child nodes that contain HTML.
//
Function ArrayOfChildNodesContainingHTML(Item) Export

	ChildNodesArray = New Array;
	
	For each ChildNode In Item.ChildNodes Do
		
		If TypeOf(ChildNode) = Type("HTMLDivElement")
			OR TypeOf(ChildNode) = Type("HTMLElement")
			OR TypeOf(ChildNode) = Type("DOMText")
			OR TypeOf(ChildNode) = Type("DOMComment")
			OR TypeOf(ChildNode) = Type("HTMLTableElement")
			OR TypeOf(ChildNode) = Type("HTMLPreElement") Then
			
			ChildNodesArray.Add(ChildNode);
			
		EndIf;
		
	EndDo;
	
	Return ChildNodesArray;

EndFunction

// Receives the HTMLDocument object from an HTML text.
//
// Parameters:
//  HTMLText - String - 
//
// Returns:
//   DocumentHTML - a created HTML document.
Function GetHTMLDocumentObjectFromHTMLText(HTMLText,Encoding = Undefined) Export
	
	Builder = New DOMBuilder;
	HTMLReader = New HTMLReader;
	
	NewHTMLText = HTMLText;
	PositionOpenXML = StrFind(NewHTMLText,"<?xml");
	
	If PositionOpenXML > 0 Then
		
		PositionCloseXML = StrFind(NewHTMLText,"?>");
		If PositionCloseXML > 0 Then
			
			NewHTMLText = Left(NewHTMLText,PositionOpenXML - 1) + Right(NewHTMLText,StrLen(NewHTMLText) - PositionCloseXML -1);
			
		EndIf;
		
	EndIf;
	
	If Encoding = Undefined Then
		
		HTMLReader.SetString(HTMLText);
		
	Else
		
		Try
		
			HTMLReader.SetString(HTMLText, Encoding);
		
		Except
			
			HTMLReader.SetString(HTMLText);
			
		EndTry;
		
	EndIf;
	
	Return Builder.Read(HTMLReader);
	
EndFunction

// Gets the HTMLDocument object from a usual text.
//
// Parameters:
//  Text  - String - a text, from which an HTML document will be created.
//
// Returns:
//   DocumentHTML - a created HTML document.
Function GetHTMLDocumentFromPlainText(Text) Export
	
	DocumentHTML = New HTMLDocument;
	
	ItemBody = DocumentHTML.CreateElement("body");
	DocumentHTML.Body = ItemBody;
	
	ItemBlock = DocumentHTML.CreateElement("p");
	ItemBody.AppendChild(ItemBlock);
	
	FontItem = FontItem(DocumentHTML, "2", "Tahoma");
	
	RowsCount = StrLineCount(Text);
	For Ind = 1 To RowsCount Do
		AddTextNode(FontItem, StrGetLine(Text, Ind), False, ?(Ind = RowsCount, False, True));
	EndDo;
	
	ItemBlock.AppendChild(FontItem);
	
	Return DocumentHTML;
	
EndFunction

// Receives an HTML text from the HTMLDocument object.
//
// Parameters:
//  DocumentHTML - HTMLDocument - a document, from which the text will be extracted.
//
// Returns:
//   String - an HTML text
//
Function GetHTMLTextFromHTMLDocumentObject(DocumentHTML) Export
	
	Try
		DOMWriter = New DOMWriter;
		HTMLWriter = New HTMLWriter;
		HTMLWriter.SetString();
		DOMWriter.Write(DocumentHTML,HTMLWriter);
		Return HTMLWriter.Close();
	Except
		Return "";
	EndTry;
	
EndFunction

// Creates an HTML element attribute and sets its text content.
//
// Parameters:
//  HTMLElement - HTMLElement - an element, for which an attribute is set.
//  Name - String - an HTML attribute name.
//  TextContent - String - text content of an attribute.
//
Procedure SetHTMLElementAttribute(HTMLElement,Name,TextContent)
	
	HTMLAttribute = HTMLElement.OwnerDocument.CreateAttribute(Name);
	HTMLAttribute.TextContent = TextContent;
	HTMLElement.Attributes.SetNamedItem(HTMLAttribute);
	
EndProcedure

// Adds a child element with attributes.
//
// Parameters:
//  ParentElement - HTMLElement - an element, to which a child element will be added.
//  Name - String - an HTML element name.
//  Attributes  - Map - a key contains an attribute name, value is a text content.
//
// Returns:
//   HTMLElement - an added element.
//
Function AddElementWithAttributes(ParentElement,Name,Attributes) Export
	
	HTMLElement = ParentElement.OwnerDocument.CreateElement(Name);
	
	For Each Attribute In Attributes Do
		
		SetHTMLElementAttribute(HTMLElement, Attribute.Key, Attribute.Value);
		
	EndDo;
	
	ParentElement.AppendChild(HTMLElement);
	
	Return HTMLElement;
	
EndFunction

// Gets a usual text from an HTML text.
//
// Parameters:
//  HTMLText - String - an HTML text.
//
// Returns:
//   String - a plain text
//
Function GetPlainTextFromHTML(HTMLText) Export
	
	FormattedDocument = New FormattedDocument;
	FormattedDocument.SetHTML(HTMLText, New Structure);
	Return FormattedDocument.GetText();
	
EndFunction

// Adds a text node to HTMLDocument.
//
// Parameters:
//  ParentElement - HTMLElement - an element, to which a child element will be added.
//  Text - String - text node content.
//  Attributes  - Map - a key contains an attribute name, value is a text content.
//
// Returns:
//   HTMLElement - an added element.
//
Procedure AddTextNode(ParentElement, Text, HighlightWithBold = False,AddLineBreak = False)
	
	DocumentOwner = ParentElement.OwnerDocument;
	
	TextNode = DocumentOwner.CreateTextNode(Text);
	
	If HighlightWithBold Then
		BoldItem = DocumentOwner.CreateElement("b");
		BoldItem.AppendChild(TextNode);
		ParentElement.AppendChild(BoldItem);
	Else
		
		ParentElement.AppendChild(TextNode);
		
	EndIf;
	
	If AddLineBreak Then
		ParentElement.AppendChild(DocumentOwner.CreateElement("br"));
	EndIf;
	
EndProcedure

// Inserts an HTML element before the first child node of a parent element.
//
// Parameters:
//  ParentElement - HTMLElement - an element, to which a child element will be added.
//  ElementToInsert - HTMLElement - an HTML element to be inserted.
//  ChildElementsArrayOfParent - Array - a child element array of a parent element.
//
Procedure InsertHTMLElementAsFirstChildElement(ParentElement,
		ElementToInsert,
		ChildElementsArrayOfParent) Export
	
	If ChildElementsArrayOfParent.Count() > 0 Then
		ParentElement.InsertBefore(ElementToInsert, ChildElementsArrayOfParent[0]);
	Else
		ParentElement.AppendChild(ElementToInsert);
	EndIf;
	
EndProcedure

Procedure AddRowToTable(ParentElement, Column1Value = Undefined, Column2Value = Undefined, Column3Value = Undefined)

	DocumentOwner = ParentElement.OwnerDocument;
	TableRowItem = DocumentOwner.CreateElement("tr");
	If Column1Value <> Undefined Then
		AddCellToTable(TableRowItem, Column1Value, True);
	EndIf;
	If Column2Value <> Undefined Then
		AddCellToTable(TableRowItem, Column2Value);
	EndIf;
	If Column3Value <> Undefined Then
		AddCellToTable(TableRowItem, Column3Value);
	EndIf;
	
	ParentElement.AppendChild(TableRowItem);

EndProcedure

Procedure AddCellToTable(RowItem, CellValue, HighlightWithBold = False)
	
	CellItem = RowItem.OwnerDocument.CreateElement("td");
	FontItem = FontItem(RowItem.OwnerDocument, "2", "Tahoma"); 
	
	If HighlightWithBold Then
		BoldItem = FontItem.OwnerDocument.CreateElement("b");
		BoldItem.TextContent = CellValue;
		FontItem.AppendChild(BoldItem);
	Else 
		FontItem.TextContent = CellValue;
	EndIf;
	
	CellItem.AppendChild(FontItem);
	RowItem.AppendChild(CellItem);
	
EndProcedure

Procedure AddAttachmentFooterToEmailBody(DocumentHTML, Attachments) Export

	EmailBodyItem = EmailBodyItem(DocumentHTML);
	EmailBodyItem.AppendChild(HorizontalSeparatorItem(EmailBodyItem));
	
	FontItem = AddElementWithAttributes(EmailBodyItem,
	                                          "Font",
	                                          New Structure("size,face","2", "Tahoma"));
	
	AttachmentsCountString = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Вложений: %1.'; en = 'Attachments: %1'; pl = 'Attachments: %1';de = 'Attachments: %1';ro = 'Attachments: %1';tr = 'Attachments: %1'; es_ES = 'Attachments: %1'"), Attachments.Count());
	AddTextNode(FontItem, AttachmentsCountString, True, True);
	
	For Each Attachment In Attachments Do 
		
		AttachmentPresentation = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = '%1 (%2).'; en = '%1 (%2).'; pl = '%1 (%2).';de = '%1 (%2).';ro = '%1 (%2).';tr = '%1 (%2).'; es_ES = '%1 (%2).'"), Attachment.FileName, Attachment.SizePresentation);
		AddTextNode(FontItem, AttachmentPresentation, , True);
		
	EndDo;
	
	EmailBodyItem.AppendChild(FontItem);
	
EndProcedure

Function HorizontalSeparatorItem(ParentElement)
	
	AttributesStructure = New Structure;
	AttributesStructure.Insert("size", "2");
	AttributesStructure.Insert("width", "100%");
	AttributesStructure.Insert("align", "center");
	AttributesStructure.Insert("tabindex", "-1");
	
	Return  AddElementWithAttributes(ParentElement, "hr", AttributesStructure);
	
EndFunction

Function EmailBodyItem(DocumentHTML)
	
	If DocumentHTML.Body = Undefined Then
		EmailBodyItem = DocumentHTML.CreateElement("body");
		DocumentHTML.Body = EmailBodyItem;
	Else
		EmailBodyItem = DocumentHTML.Body;
	EndIf;
	
	Return EmailBodyItem;
	
EndFunction

Function FontItem(DocumentHTML, Size, FontName)
	
	FontItem = DocumentHTML.CreateElement("Font");
	SetHTMLElementAttribute(FontItem,"size", Size);
	SetHTMLElementAttribute(FontItem,"face", FontName);
	
	Return FontItem;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////////
// Operations with settings

// Returns current user setting.
// If setting is not specified, it returns the ValueIfNotSpecified parameter after passing it.
// 
//
Function GetCurrentUserSetting(ObjectKey,
	SettingsKey = Undefined,
	ValueIfNotSpecified = Undefined)
	
	Result = Common.CommonSettingsStorageLoad(
		ObjectKey,
		SettingsKey,
		ValueIfNotSpecified);
	
	Return Result;
	
EndFunction

// Saves current user setting.
Procedure SaveCurrentUserSetting(ObjectKey, Value, SettingsKey = Undefined)
	
	Common.CommonSettingsStorageSave(
		ObjectKey,
		SettingsKey,
		Value);
		
EndProcedure

// Gets user setting of mail operations.
//
Function GetEmailOperationsSetting() Export
	
	Setting = GetCurrentUserSetting("MailOperations", "UserSettings", New Structure);
	If TypeOf(Setting) <> Type("Structure") Then
		Setting = New Structure;
	EndIf;
	Return Setting;
	
EndFunction

// Saves user setting of email operations.
//
Procedure SaveEmailOperationsSetting(Value) Export
	
	SaveCurrentUserSetting("MailOperations", Value, "UserSettings");
	
EndProcedure 

////////////////////////////////////////////////////////////////////
// Text messages

// Checks delivery statuses for the sent SMS messages.
//
// Parameters:
//  SMSMessage  - DocumentObject.SMSMessage - a document, for which an SMS message delivery status is checked.
//  Modified  - Boolean - indicates that the document was modified.
//
Procedure CheckSMSMessagesDeliveryStatuses(SMSMessage, Modified) Export
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	SMSMessageRecipients.LineNumber,
	|	SMSMessageRecipients.MessageID,
	|	SMSMessageRecipients.MessageState
	|FROM
	|	Document.SMSMessage.Recipients AS SMSMessageRecipients
	|WHERE
	|	SMSMessageRecipients.Ref = &SMSMessage
	|	AND SMSMessageRecipients.MessageID <> """"
	|	AND (SMSMessageRecipients.MessageState = VALUE(Enum.SMSMessagesState.BeingSentByProvider)
	|			OR SMSMessageRecipients.MessageState = VALUE(Enum.SMSMessagesState.SentByProvider)
	|			OR SMSMessageRecipients.MessageState = VALUE(Enum.SMSMessagesState.ErrorOnGetStatusFromProvider))";
	
	Query.SetParameter("SMSMessage", SMSMessage.Ref);
	
	HasChanges = False;
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		MessageState = SMSMessageStateAccordingToDeliveryStatus(SendSMSMessage.DeliveryStatus(Selection.MessageID));
		
		If MessageState <> Selection.MessageState Then
			SMSMessage.Recipients[Selection.LineNumber - 1].MessageState = MessageState;
			HasChanges = True;
		EndIf;
		
	EndDo;
	
	If HasChanges Then
		SMSMessage.State = SMSMessageDocumentState(SMSMessage);
		Modified = True;
	EndIf;
	
EndProcedure

// Determines a status of the "SMS message" document by the status of its incoming SMS messages.
//
// Parameters:
//  SMSMessage  - DocumentObject.SMSMessage - a document whose status has to be determined.
//                                                
//
// Returns:
//   Enums.SMSMessageDocumentStates - a calculated document status.
//
Function SMSMessageDocumentState(SMSMessage)
	
	Query = New Query;
	Query.Text = "SELECT DISTINCT
	|	Recipients.MessageState AS State
	|INTO States
	|FROM
	|	&Recipients AS Recipients
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	States.State
	|FROM
	|	States AS States";
	
	Query.SetParameter("Recipients", SMSMessage.Recipients.Unload());
	
	Result = Query.Execute();
	
	If Result.IsEmpty() Then
		Return Enums.SMSMessageDocumentState.Draft;
	EndIf;
	
	CurrentStatus = Undefined;
	
	Selection = Result.Select();
	While Selection.Next() Do
	
		If Selection.State = Enums.SMSMessagesState.Outgoing Then
			
			Return  Enums.SMSMessageDocumentState.Outgoing;
			
		ElsIf Selection.State = Enums.SMSMessagesState.Draft Then
			
			Return Enums.SMSMessagesState.Draft;
			
		ElsIf Selection.State = Enums.SMSMessagesState.CannotPassToProvider Then
			
			If CurrentStatus = Enums.SMSMessageDocumentState.Delivered Then
				CurrentStatus = Enums.SMSMessageDocumentState.PartiallyDelivered;
			Else
				CurrentStatus = Enums.SMSMessageDocumentState.NotDelivered;
			EndIf;
			
		ElsIf Selection.State = Enums.SMSMessagesState.BeingSentByProvider 
			      OR Selection.State = Enums.SMSMessagesState.SentByProvider
			      OR Selection.State = Enums.SMSMessagesState.ErrorOnGetStatusFromProvider
			      OR Selection.State = Enums.SMSMessagesState.NotSentByProvider Then
			Return Enums.SMSMessageDocumentState.DeliveryInProgress;
		ElsIf Selection.State = Enums.SMSMessagesState.Delivered Then
			If CurrentStatus = Enums.SMSMessageDocumentState.Delivered
				 OR CurrentStatus = Undefined Then
				CurrentStatus = Enums.SMSMessageDocumentState.Delivered;
			Else
				CurrentStatus = Enums.SMSMessageDocumentState.PartiallyDelivered;
			EndIf;
		ElsIf Selection.State = Enums.SMSMessagesState.NotDelivered Then
			If CurrentStatus = Enums.SMSMessageDocumentState.Delivered Then
				CurrentStatus = Enums.SMSMessageDocumentState.PartiallyDelivered;
			Else
				CurrentStatus = Enums.SMSMessageDocumentState.NotDelivered;
			EndIf;
		ElsIf Selection.State = Enums.SMSMessagesState.UnidentifiedByProvider Then
			If CurrentStatus = Enums.SMSMessageDocumentState.Delivered Then
				CurrentStatus = Enums.SMSMessageDocumentState.PartiallyDelivered;
			Else
				CurrentStatus = Enums.SMSMessageDocumentState.NotDelivered;
			EndIf;
		EndIf;
	
	EndDo;
	
	Return CurrentStatus;

EndFunction

// Transforms SMS delivery statuses of the SendSMS subsystem to SMS message statuses of the 
//   Interactions subsystem.
//
// Parameters:
//  DeliveryStatus - Enums.SMSMessagesDeliveryStatuses - a value to be converted.
//
// Returns:
//   Enums.SMSMessagesStates - a converted value.
//
Function SMSMessageStateAccordingToDeliveryStatus(DeliveryStatus);
	
	If DeliveryStatus = "NotSent" Then
		Return Enums.SMSMessagesState.NotSentByProvider;
	ElsIf DeliveryStatus = "Sending" Then
		Return Enums.SMSMessagesState.BeingSentByProvider;
	ElsIf DeliveryStatus = "Sent" Then
		Return Enums.SMSMessagesState.SentByProvider;
	ElsIf DeliveryStatus = "NotDelivered" Then
		Return Enums.SMSMessagesState.NotDelivered;
	ElsIf DeliveryStatus = "Delivered" Then
		Return Enums.SMSMessagesState.Delivered;
	ElsIf DeliveryStatus = "Pending" Then
		Return Enums.SMSMessagesState.UnidentifiedByProvider;
	ElsIf DeliveryStatus = "Error" Then
		Return Enums.SMSMessagesState.ErrorOnGetStatusFromProvider;
	Else
		Return Enums.SMSMessagesState.ErrorOnGetStatusFromProvider;
	EndIf;
	
EndFunction

// Sends SMS messages by the passed SMS message document.
Function SendSMSMessageByDocument(Document) Export
	
	SetPrivilegedMode(True);
	
	If Not SendSMSMessage.SMSMessageSendingSetupCompleted() Then
		Common.MessageToUser(NStr("ru = 'Не выполнены настройки отправки SMS.'; en = 'Settings of SMS sending are not executed.'; pl = 'Settings of SMS sending are not executed.';de = 'Settings of SMS sending are not executed.';ro = 'Settings of SMS sending are not executed.';tr = 'Settings of SMS sending are not executed.'; es_ES = 'Settings of SMS sending are not executed.'"),,"Object");
		InteractionsClientServer.SetStateOutgoingDocumentSMSMessage(Document);
		Return 0;
	EndIf;
	
	NumbersArray     = Document.Recipients.Unload(,"SendingNumber").UnloadColumn("SendingNumber");
	SendingResult = SendSMSMessage.SendSMSMessage(NumbersArray, Document.MessageText," " , Document.SendInTransliteration);
	
	ReportSMSMessageSendingResultsInDocument(Document, SendingResult);
		
	If Not IsBlankString(SendingResult.ErrorDescription) Then 
		Common.MessageToUser(SendingResult.ErrorDescription,,"Document");
	EndIf;

	Return SendingResult.SentMessages.Count();
	
EndFunction

// Executes the procedure of sending SMS messages.
Procedure SendSMSMessage() Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.SendSMSMessage);
	
	SetPrivilegedMode(True);
	
	DocumentMetadata = Metadata.Documents.SMSMessage;
	
	MessageAddresseesTable = New ValueTable;
	MessageAddresseesTable.Columns.Add("LineNumber");
	MessageAddresseesTable.Columns.Add("SendingNumber");
	MessageAddresseesTable.Columns.Add("HowToContact");
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	SMSMessage.Ref AS Ref,
	|	SMSMessage.MessageText,
	|	SMSMessage.SendInTransliteration,
	|	SMSMessageRecipients.LineNumber,
	|	SMSMessageRecipients.SendingNumber,
	|	SMSMessageRecipients.HowToContact
	|FROM
	|	Document.SMSMessage.Recipients AS SMSMessageRecipients
	|		INNER JOIN Document.SMSMessage AS SMSMessage
	|		ON SMSMessageRecipients.Ref = SMSMessage.Ref
	|WHERE
	|	SMSMessageRecipients.MessageState = VALUE(Enum.SMSMessagesState.Outgoing)
	|	AND NOT SMSMessage.DeletionMark
	|	AND SMSMessageRecipients.MessageID = """"
	|	AND CASE
	|			WHEN SMSMessage.DateToSendEmail = DATETIME(1, 1, 1)
	|				THEN TRUE
	|			ELSE SMSMessage.DateToSendEmail < &CurrentDate
	|		END
	|	AND CASE
	|			WHEN SMSMessage.EmailSendingRelevanceDate = DATETIME(1, 1, 1)
	|				THEN TRUE
	|			ELSE SMSMessage.EmailSendingRelevanceDate > &CurrentDate
	|		END
	|TOTALS BY
	|	Ref";
	
	Query.SetParameter("CurrentDate", CurrentSessionDate());
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	DocumentsSelection = Result.Select(QueryResultIteration.ByGroups);
		
	If Not SendSMSMessage.SMSMessageSendingSetupCompleted() Then
		WriteLogEvent(EmailManagement.EventLogEvent(), 
		EventLogLevel.Error, , ,
		NStr("ru = 'Не выполнены настройки отправки SMS.'; en = 'Settings of SMS sending are not executed.'; pl = 'Settings of SMS sending are not executed.';de = 'Settings of SMS sending are not executed.';ro = 'Settings of SMS sending are not executed.';tr = 'Settings of SMS sending are not executed.'; es_ES = 'Settings of SMS sending are not executed.'", Common.DefaultLanguageCode()));
		Return;
	EndIf;
	
	While DocumentsSelection.Next() Do
		
		MessageAddresseesTable.Clear();
		
		AddresseesSelection = DocumentsSelection.Select();
		While AddresseesSelection.Next() Do
			
			MessageText       = AddresseesSelection.MessageText;
			SendInTransliteration = AddresseesSelection.SendInTransliteration;
			
			NewRow = MessageAddresseesTable.Add();
			FillPropertyValues(NewRow, AddresseesSelection);
			
		EndDo;
		
		If MessageAddresseesTable.Count() = 0 Then
			Continue;
		EndIf;
		
		BeginTransaction();
		Try
			
			Lock = New DataLock;
			LockItem = Lock.Add(DocumentMetadata.FullName());
			LockItem.SetValue("Ref", DocumentsSelection.Ref);
			Lock.Lock();
		
			NumbersArray = MessageAddresseesTable.UnloadColumn("SendingNumber");
			SendingResult = SendSMSMessage.SendSMSMessage(NumbersArray, MessageText, "", SendInTransliteration);
			
			If SendingResult.SentMessages.Count() = 0 Then
				RollbackTransaction();
				Continue;
			EndIf;
			
			DocumentObject = DocumentsSelection.Ref.GetObject();
			ReportSMSMessageSendingResultsInDocument(DocumentObject, SendingResult);
			DocumentObject.AdditionalProperties.Insert("DoNotSaveContacts", True);
			DocumentObject.Write();
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			MessageText = NStr("ru = 'Не удалось отправить : %Ref% по причине: %Reason%'; en = 'Cannot send : %Ref% for the reason: %Reason%'; pl = 'Cannot send : %Ref% for the reason: %Reason%';de = 'Cannot send : %Ref% for the reason: %Reason%';ro = 'Cannot send : %Ref% for the reason: %Reason%';tr = 'Cannot send : %Ref% for the reason: %Reason%'; es_ES = 'Cannot send : %Ref% for the reason: %Reason%'");
			MessageText = StrReplace(MessageText, "%Ref%", DocumentsSelection.Ref);
			MessageText = StrReplace(MessageText, "%Reason%", DetailErrorDescription(ErrorInfo()));
			WriteLogEvent(EmailManagement.EventLogEvent(),
			                         EventLogLevel.Warning,
			                         DocumentMetadata,
			                         DocumentsSelection.Ref,
			                         MessageText);
			
		EndTry;
		
	EndDo;

EndProcedure

// Scheduled job handler.
// Updates SMS delivery statuses on schedule.
//
Procedure SMSDeliveryStatusUpdate() Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.SMSDeliveryStatusUpdate);
	
	SetPrivilegedMode(True);
	
	DocumentMetadata = Metadata.Documents.SMSMessage;
	
	ChangedStatusesTable = New ValueTable;
	ChangedStatusesTable.Columns.Add("LineNumber");
	ChangedStatusesTable.Columns.Add("MessageState");
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	SMSMessageRecipients.Ref AS Ref,
	|	SMSMessageRecipients.LineNumber,
	|	SMSMessageRecipients.MessageID,
	|	SMSMessageRecipients.MessageState
	|FROM
	|	Document.SMSMessage.Recipients AS SMSMessageRecipients
	|WHERE
	|	SMSMessageRecipients.MessageID <> """"
	|	AND (SMSMessageRecipients.MessageState = VALUE(Enum.SMSMessagesState.BeingSentByProvider)
	|			OR SMSMessageRecipients.MessageState = VALUE(Enum.SMSMessagesState.SentByProvider)
	|			OR SMSMessageRecipients.MessageState = VALUE(Enum.SMSMessagesState.ErrorOnGetStatusFromProvider))
	|	AND NOT SMSMessageRecipients.Ref.DeletionMark
	|TOTALS BY
	|	Ref";
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	If Not SendSMSMessage.SMSMessageSendingSetupCompleted() Then
		WriteLogEvent(EmailManagement.EventLogEvent(), 
		EventLogLevel.Error, , ,
		NStr("ru = 'Не выполнены настройки отправки SMS.'; en = 'Settings of SMS sending are not executed.'; pl = 'Settings of SMS sending are not executed.';de = 'Settings of SMS sending are not executed.';ro = 'Settings of SMS sending are not executed.';tr = 'Settings of SMS sending are not executed.'; es_ES = 'Settings of SMS sending are not executed.'", Common.DefaultLanguageCode()));
		Return;
	EndIf;
	
	DocumentsSelection = Result.Select(QueryResultIteration.ByGroups);
	
	While DocumentsSelection.Next() Do
		
		ChangedStatusesTable.Clear();
		
		BeginTransaction();
		Try
			
			Lock = New DataLock;
			LockItem = Lock.Add(DocumentMetadata.FullName());
			LockItem.SetValue("Ref", DocumentsSelection.Ref);
			Lock.Lock();
		
			IDsSelection = DocumentsSelection.Select();
			While IDsSelection.Next() Do
				
				MessageState = SMSMessageStateAccordingToDeliveryStatus(SendSMSMessage.DeliveryStatus(IDsSelection.MessageID));
				
				If MessageState <> IDsSelection.MessageState Then
					NewRow = ChangedStatusesTable.Add();
					NewRow.LineNumber        = IDsSelection.LineNumber;
					NewRow.MessageState = MessageState;
				EndIf;
				
			EndDo;
			
			If ChangedStatusesTable.Count() = 0 Then
				Continue;
				RollbackTransaction();
			EndIf;
			
			For Each ChangedStatus In ChangedStatusesTable Do
				DocumentObject = DocumentsSelection.Ref.GetObject();
				DocumentObject.Recipients[ChangedStatus.LineNumber - 1].MessageState = ChangedStatus.MessageState;
			EndDo;
			
			DocumentObject.State = SMSMessageDocumentState(DocumentObject);
			DocumentObject.AdditionalProperties.Insert("DoNotSaveContacts", True);
			DocumentObject.Write();
			
			CommitTransaction();
		
		Except
			
			RollbackTransaction();
			MessageText = NStr("ru = 'Не удалось обновить статусы доставки : %Ref% по причине: %Reason%'; en = 'Cannot update delivery statuses : %Ref% for the reason: %Reason%'; pl = 'Cannot update delivery statuses : %Ref% for the reason: %Reason%';de = 'Cannot update delivery statuses : %Ref% for the reason: %Reason%';ro = 'Cannot update delivery statuses : %Ref% for the reason: %Reason%';tr = 'Cannot update delivery statuses : %Ref% for the reason: %Reason%'; es_ES = 'Cannot update delivery statuses : %Ref% for the reason: %Reason%'");
			MessageText = StrReplace(MessageText, "%Ref%", DocumentsSelection.Ref);
			MessageText = StrReplace(MessageText, "%Reason%", DetailErrorDescription(ErrorInfo()));
			WriteLogEvent(EmailManagement.EventLogEvent(),
			                         EventLogLevel.Warning,
			                         DocumentMetadata,
			                         DocumentsSelection.Ref,
			                         MessageText);
			
		EndTry;
		
	EndDo;
	
EndProcedure

// Sets statuses of the "SMS message" document depending on statuses of separate messages to different contacts.
//
// Parameters:
//  DocumentObject     - DocumentObject.SMSMessage - a document, for which a status is determined.
//  SendingResult  - Structure - the result of sending an SMS message.
//
Procedure ReportSMSMessageSendingResultsInDocument(DocumentObject, SendingResult)
	
	For Each SentMessage In SendingResult.SentMessages Do
		For Each FoundRow In DocumentObject.Recipients.FindRows(New Structure("SendingNumber",SentMessage.RecipientNumber)) Do
			FoundRow.MessageID = SentMessage.MessageID;
			FoundRow.MessageState     = Enums.SMSMessagesState.BeingSentByProvider;
		EndDo;
	EndDo;
	
	DocumentObject.State = SMSMessageDocumentState(DocumentObject);
	
EndProcedure

////////////////////////////////////////////////////////////////////
// Operations with email folders.

// Checks whether the current user is responsible for the account filing.
//
// Parameters:
//  Account - CatalogRef.EmailAccounts - an account to be checked.
//
// Returns:
//   Boolean   - true if the user is responsible, false otherwise.
//
Function UserIsResponsibleForMaintainingFolders(Account) Export
	
	If Users.IsFullUser() Then
		Return True;
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	CASE
	|		WHEN EmailAccounts.AccountOwner = VALUE(Catalog.Users.EmptyRef)
	|			THEN EmailAccountSettings.EmployeeResponsibleForFoldersMaintenance
	|		ELSE EmailAccounts.AccountOwner
	|	END AS EmployeeResponsibleForFoldersMaintenance
	|FROM
	|	InformationRegister.EmailAccountSettings AS EmailAccountSettings
	|		LEFT JOIN Catalog.EmailAccounts AS EmailAccounts
	|		ON EmailAccountSettings.EmailAccount = EmailAccounts.Ref
	|WHERE
	|	EmailAccountSettings.EmailAccount = &EmailAccount
	|	AND EmailAccountSettings.EmployeeResponsibleForFoldersMaintenance = &EmployeeResponsibleForFoldersMaintenance";
	
	Query.SetParameter("EmailAccount", Account);
	Query.SetParameter("EmployeeResponsibleForFoldersMaintenance", Users.AuthorizedUser());
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return False;
	Else
		Return True;
	EndIf;
	
EndFunction 

// Sets a parent for the email folder.
//
// Parameters:
//  Folder  - CatalogRef.EmailFolders - a folder, for which a parent is set.
//  NewParent  - CatalogRef.EmailFolders - a folder that will be set as a parent.
//  DoNotWriteFolder  - Boolean - indicates whether it is necessary to write folder in this procedure.
//
Procedure SetFolderParent(Folder, NewParent, DoNotWriteFolder = False) Export
	
	CatalogMetadata = Metadata.Catalogs.EmailMessageFolders;
	
	Query = New Query;
	Query.Text = "SELECT ALLOWED
	|	EmailMessageFolders.Ref
	|FROM
	|	Catalog.EmailMessageFolders AS EmailMessageFolders
	|WHERE
	|	EmailMessageFolders.Ref IN HIERARCHY(&FolderToMove)
	|	AND EmailMessageFolders.Ref = &NewParent
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	COUNT(DISTINCT EmailMessageFolders.Ref) AS Ref
	|FROM
	|	Catalog.EmailMessageFolders AS EmailMessageFolders
	|WHERE
	|	EmailMessageFolders.Ref IN HIERARCHY
	|			(SELECT
	|				EmailMessageFolders.Ref
	|			FROM
	|				Catalog.EmailMessageFolders AS EmailMessageFolders
	|			WHERE
	|				EmailMessageFolders.PredefinedFolder
	|				AND EmailMessageFolders.Description = &DeletedItems)
	|	AND EmailMessageFolders.Ref = &NewParent";
	
	Query.SetParameter("DeletedItems", NStr("ru = 'Удаленные'; en = 'DeletedItems'; pl = 'DeletedItems';de = 'DeletedItems';ro = 'DeletedItems';tr = 'DeletedItems'; es_ES = 'DeletedItems'"));
	Query.SetParameter("FolderToMove", Folder);
	Query.SetParameter("NewParent", NewParent);
	
	Result = Query.ExecuteBatch();
	If Not Result[0].IsEmpty() Then
		Return;
	EndIf;
	
	If Result[1].IsEmpty() Then
		MoveToDeletedItemsFolder = False;
	Else
		MoveToDeletedItemsFolder = True;
	EndIf;
	
	BeginTransaction();
	Try
		
		Lock = New DataLock;
		LockItem = Lock.Add(CatalogMetadata.FullName());
		LockItem.SetValue("Ref", Folder);
		Lock.Lock();
		
		FolderObject          = Folder.GetObject();
		FolderObject.AdditionalProperties.Insert("ParentChangeProcessed", True);
		
		If Not DoNotWriteFolder Then
			FolderObject.Parent = NewParent;
			FolderObject.Write();
		EndIf;
		
		MoveToDeletedItemsFolder = False;
		
		If NOT NewParent.IsEmpty()Then
			FolderAttributesValues = Common.ObjectAttributesValues(
			NewParent,"PredefinedFolder,Description");
			If FolderAttributesValues <> Undefined 
				AND FolderAttributesValues.PredefinedFolder 
				AND FolderAttributesValues.Description = NStr("ru = 'Удаленные'; en = 'DeletedItems'; pl = 'DeletedItems';de = 'DeletedItems';ro = 'DeletedItems';tr = 'DeletedItems'; es_ES = 'DeletedItems'") Then
				
				MoveToDeletedItemsFolder = True;
				
			EndIf;
		EndIf;
		
		If MoveToDeletedItemsFolder AND NOT FolderObject.DeletionMark Then
			FolderObject.SetDeletionMark(True);
			SetDeletionMarkForFolderEmails(Folder);
		ElsIf FolderObject.DeletionMark AND NOT MoveToDeletedItemsFolder Then
			FolderObject.SetDeletionMark(False);
			SetDeletionMarkForFolderEmails(Folder);
		EndIf;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndProcedure

// Sets a deletion mark for folder emails.
//
// Parameters:
//  Folder  - CatalogRef.EmailFolders - a folder whose emails will be marked for deletion.
//
Procedure SetDeletionMarkForFolderEmails(Folder)
	
	Query = New Query;
	Query.Text = "SELECT
	|	IncomingEmail.Ref,
	|	InteractionsFolderSubjects.EmailMessageFolder.DeletionMark AS DeletionMark
	|FROM
	|	Document.IncomingEmail AS IncomingEmail
	|		LEFT JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
	|		ON (InteractionsFolderSubjects.Interaction = IncomingEmail.Ref)
	|WHERE
	|	InteractionsFolderSubjects.EmailMessageFolder IN HIERARCHY(&Folder)
	|	AND InteractionsFolderSubjects.EmailMessageFolder.DeletionMark <> IncomingEmail.DeletionMark
	|
	|UNION ALL
	|
	|SELECT
	|	OutgoingEmail.Ref,
	|	InteractionsFolderSubjects.EmailMessageFolder.DeletionMark
	|FROM
	|	Document.OutgoingEmail AS OutgoingEmail
	|		LEFT JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
	|		ON (InteractionsFolderSubjects.Interaction = OutgoingEmail.Ref)
	|WHERE
	|	InteractionsFolderSubjects.EmailMessageFolder IN HIERARCHY(&Folder)
	|	AND OutgoingEmail.DeletionMark <> InteractionsFolderSubjects.EmailMessageFolder.DeletionMark";
	
	Query.SetParameter("Folder",Folder);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		EmailObject = Selection.Ref.GetObject();
		EmailObject.AdditionalProperties.Insert("DeletionMarkChangeProcessed",True);
		EmailObject.SetDeletionMark(Selection.DeletionMark);
		
	EndDo;

EndProcedure

// Sets a deletion mark for folder emails.
//
// Parameters:
//  EmailsArray  - Array - an array of emails, for which a folder will be set.
//  Folder  - CatalogRef.EmailFolders - a folder whose emails will be marked for deletion.
//
Procedure SetFolderForEmailsArray(EmailsArray,Folder) Export
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	IncomingEmail.Ref,
	|	IncomingEmail.DeletionMark,
	|	InteractionsFolderSubjects.EmailMessageFolder AS Folder
	|FROM
	|	Document.IncomingEmail AS IncomingEmail
	|		LEFT JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
	|		ON IncomingEmail.Ref = InteractionsFolderSubjects.Interaction
	|WHERE
	|	IncomingEmail.Ref IN(&EmailsArray)
	|	AND InteractionsFolderSubjects.EmailMessageFolder <> &Folder
	|
	|UNION ALL
	|
	|SELECT
	|	OutgoingEmail.Ref,
	|	OutgoingEmail.DeletionMark,
	|	InteractionsFolderSubjects.EmailMessageFolder
	|FROM
	|	Document.OutgoingEmail AS OutgoingEmail
	|		LEFT JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
	|		ON (InteractionsFolderSubjects.Interaction = OutgoingEmail.Ref)
	|WHERE
	|	OutgoingEmail.Ref IN(&EmailsArray)
	|	AND InteractionsFolderSubjects.EmailMessageFolder <> &Folder";
	
	Query.SetParameter("EmailsArray",EmailsArray);
	Query.SetParameter("Folder",Folder);
	
	FolderAttributesValues = Common.ObjectAttributesValues(Folder, "PredefinedFolder,Description");
	If FolderAttributesValues <> Undefined 
		AND FolderAttributesValues.PredefinedFolder 
		AND FolderAttributesValues.Description = NStr("ru = 'Удаленные'; en = 'DeletedItems'; pl = 'DeletedItems';de = 'DeletedItems';ro = 'DeletedItems';tr = 'DeletedItems'; es_ES = 'DeletedItems'") Then
		
		MoveToDeletedItemsFolder = True;
		
	Else
		
		MoveToDeletedItemsFolder = False;
		
	EndIf;
		
	Selection = Query.Execute().Select();

	While Selection.Next() Do
		InteractionsServerCall.SetEmailFolder(Selection.Ref, Folder, False);
		If MoveToDeletedItemsFolder AND NOT Selection.DeletionMark Then
			EmailObject = Selection.Ref.GetObject();
			EmailObject.AdditionalProperties.Insert("DeletionMarkChangeProcessed", True);
			EmailObject.SetDeletionMark(True);
		ElsIf NOT MoveToDeletedItemsFolder AND Selection.DeletionMark Then
			EmailObject = Selection.Ref.GetObject();
			EmailObject.AdditionalProperties.Insert("DeletionMarkChangeProcessed", True);
			EmailObject.SetDeletionMark(False);
		EndIf;
	EndDo;
	
	Selection.Reset();
	TableForCalculation = TableOfDataForReviewedCalculation(Selection, "Folder");
	If TableForCalculation.Find(Folder, "CalculateBy") = Undefined Then
		NewRow = TableForCalculation.Add();
		NewRow.CalculateBy = Folder;
	EndIf;
	CalculateReviewedByFolders(TableForCalculation);
	
EndProcedure

// Sets deletion mark for a folder and letters that it includes.
//
// Parameters:
//  Folder  - CatalogRef.EmailFolders - a folder whose emails will be marked for deletion.
//  ErrorDescription  - String - an error description.
//
Procedure ExecuteEmailsFolderDeletion(Folder, ErrorDescription = "") Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	EmailMessageFolders.Ref
	|FROM
	|	Catalog.EmailMessageFolders AS EmailMessageFolders
	|WHERE
	|	EmailMessageFolders.PredefinedFolder
	|	AND EmailMessageFolders.Description = &DeletedItems
	|	AND EmailMessageFolders.Owner IN
	|			(SELECT
	|				EmailMessageFolders.Owner
	|			FROM
	|				Catalog.EmailMessageFolders AS EmailMessageFolders
	|			WHERE
	|				EmailMessageFolders.Ref = &Folder)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	EmailMessageFolders.Ref AS Folder
	|FROM
	|	Catalog.EmailMessageFolders AS EmailMessageFolders
	|WHERE
	|	EmailMessageFolders.Ref IN HIERARCHY(&Folder)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	IncomingEmail.Ref,
	|	IncomingEmail.DeletionMark AS DeletionMark
	|FROM
	|	InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
	|		INNER JOIN Document.IncomingEmail AS IncomingEmail
	|		ON InteractionsFolderSubjects.Interaction = IncomingEmail.Ref
	|WHERE
	|	InteractionsFolderSubjects.EmailMessageFolder IN HIERARCHY(&Folder)
	|
	|UNION ALL
	|
	|SELECT
	|	OutgoingEmail.Ref,
	|	OutgoingEmail.DeletionMark
	|FROM
	|	InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
	|		INNER JOIN Document.OutgoingEmail AS OutgoingEmail
	|		ON InteractionsFolderSubjects.Interaction = OutgoingEmail.Ref
	|WHERE
	|	InteractionsFolderSubjects.EmailMessageFolder IN HIERARCHY(&Folder)";
	
	Query.SetParameter("Folder", Folder);
	Query.SetParameter("DeletedItems", NStr("ru = 'Удаленные'; en = 'DeletedItems'; pl = 'DeletedItems';de = 'DeletedItems';ro = 'DeletedItems';tr = 'DeletedItems'; es_ES = 'DeletedItems'"));
	
	QueryResultsArray = Query.ExecuteBatch();
	
	If QueryResultsArray[0].IsEmpty() Or QueryResultsArray[2].IsEmpty() Then
		Return;
	EndIf;
	
	DeletedItemsFolderSelection = QueryResultsArray[0].Select();
	DeletedItemsFolderSelection.Next();
	DeletedItemsFolder = DeletedItemsFolderSelection.Ref;
	
	EmailSelection = QueryResultsArray[2].Select();
	FolderSelection  = QueryResultsArray[1].Select();
	
	BeginTransaction();
	
	Try
		
		While EmailSelection.Next() Do
			
			InteractionsServerCall.SetEmailFolder(EmailSelection.Ref, DeletedItemsFolder, False);
			
			If NOT EmailSelection.DeletionMark Then
				EmailObject = EmailSelection.Ref.GetObject();
				EmailObject.SetDeletionMark(True);
			EndIf;
			
		EndDo;
		
		While FolderSelection.Next() Do
			
			FolderObject =  FolderSelection.Folder.GetObject();
			FolderObject.SetDeletionMark(True);
			
		EndDo;
		
		FolderSelection.Reset();
		TableForCalculation = TableOfDataForReviewedCalculation(FolderSelection, "Folder");
		If TableForCalculation.Find(DeletedItemsFolder, "CalculateBy") = Undefined Then
			NewRow = TableForCalculation.Add();
			NewRow.CalculateBy = DeletedItemsFolder;
		EndIf;
		CalculateReviewedByFolders(TableForCalculation);
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		ErrorDescription = NStr("ru = 'При удалении папки произошла ошибка.
		                      |Удаление папки не выполнено.
		                      |Дополнительное описание:
		                      |%AdditionalDetails%'; 
		                      |en = 'Error occurred when deleting the folder.
		                      |Cannot delete the folder.
		                      |Additional details:
		                      |%AdditionalDetails%'; 
		                      |pl = 'Error occurred when deleting the folder.
		                      |Cannot delete the folder.
		                      |Additional details:
		                      |%AdditionalDetails%';
		                      |de = 'Error occurred when deleting the folder.
		                      |Cannot delete the folder.
		                      |Additional details:
		                      |%AdditionalDetails%';
		                      |ro = 'Error occurred when deleting the folder.
		                      |Cannot delete the folder.
		                      |Additional details:
		                      |%AdditionalDetails%';
		                      |tr = 'Error occurred when deleting the folder.
		                      |Cannot delete the folder.
		                      |Additional details:
		                      |%AdditionalDetails%'; 
		                      |es_ES = 'Error occurred when deleting the folder.
		                      |Cannot delete the folder.
		                      |Additional details:
		                      |%AdditionalDetails%'");
		ErrorDescription = StrReplace(ErrorDescription, "%AdditionalDetails%", ErrorInfo().Description);

		Return;
		
	EndTry;
	
EndProcedure

// Determines a folder for an email.
//
// Parameters:
//  Email - DocumentRef.IncomingEmail,
//            DocumentRef.OutgoingEmail - an email, for which a folder is determined.
//
// Returns:
//   CatalogRef.EmailFolders - a folder determined for an email.
//
Function DefineFolderForEmail(Email) Export
	
	SetPrivilegedMode(True);
	
	Folder = DefineDefaultFolderForEmail(Email ,True);
	If ValueIsFilled(Folder) AND (NOT Folder.PredefinedFolder) Then
		Return Folder;
	EndIf;
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	EmailProcessingRules.SettingsComposer AS SettingsComposer,
	|	EmailProcessingRules.PutInFolder AS PutInFolder
	|FROM
	|	Catalog.EmailProcessingRules AS EmailProcessingRules
	|WHERE
	|	EmailProcessingRules.Owner IN
	|			(SELECT
	|				Interactions.Account
	|			FROM
	|				DocumentJournal.Interactions AS Interactions
	|			WHERE
	|				Interactions.Ref = &Email)
	|	AND NOT EmailProcessingRules.DeletionMark
	|
	|ORDER BY
	|	EmailProcessingRules.AddlOrderingAttribute";
	
	Query.SetParameter("Email", Email);
	
	Result = Query.Execute();
	If Not Result.IsEmpty() Then
		Selection = Result.Select();
		While Selection.Next() Do
			
			ProcessingRulesSchema = 
				Catalogs.EmailProcessingRules.GetTemplate("EmailProcessingRuleScheme");
			
			TemplateComposer = New DataCompositionTemplateComposer();
			SettingsComposer = New DataCompositionSettingsComposer;
			SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(ProcessingRulesSchema));
			SettingsComposer.LoadSettings(Selection.SettingsComposer.Get());
			SettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
			CommonClientServer.SetFilterItem(
				SettingsComposer.Settings.Filter,"Ref",Email,DataCompositionComparisonType.Equal);
			
			DataCompositionTemplate = TemplateComposer.Execute(
				ProcessingRulesSchema, SettingsComposer.GetSettings(),,,Type("DataCompositionValueCollectionTemplateGenerator"));
			
			If DataCompositionTemplate.ParameterValues.Count() = 0 Then
				Continue;
			EndIf;
			
			QueryText = DataCompositionTemplate.DataSets.MainDataSet.Query;
			QueryRule = New Query(QueryText);
			For each Parameter In DataCompositionTemplate.ParameterValues Do
				QueryRule.Parameters.Insert(Parameter.Name, Parameter.Value);
			EndDo;
			
			Result = QueryRule.Execute();
			If Not Result.IsEmpty() Then
				Return Selection.PutInFolder;
			EndIf;
			
		EndDo;
	EndIf;
	
	Return Folder;
	
EndFunction

// Determines a default folder for an email.
//
// Parameters:
//  Email - DocumentRef.IncomingEmail,
//            DocumentRef.OutgoingEmail - an email, for which a folder is determined.
//  IncludingBaseEmailChecks  - Boolean - indicates that it is necessary to check if a folder is 
//                                             determined to the base email folder.
//
// Returns:
//   CatalogRef.EmailFolders - a folder determined for an email.
//
Function DefineDefaultFolderForEmail(Email, IncludingBaseEmailChecks = FALSE) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	
	If IncludingBaseEmailChecks Then
		Query.Text = "
		|SELECT
		|	EmailMessageFolders.Ref AS Folder,
		|	Interactions.Ref AS Email
		|INTO FoldersByBasis
		|FROM
		|	DocumentJournal.Interactions AS Interactions
		|		INNER JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
		|			INNER JOIN Catalog.EmailMessageFolders AS EmailMessageFolders
		|			ON InteractionsFolderSubjects.EmailMessageFolder = EmailMessageFolders.Ref
		|				AND ((NOT EmailMessageFolders.PredefinedFolder))
		|		ON (InteractionsFolderSubjects.Interaction = Interactions.InteractionBasis)
		|		INNER JOIN Catalog.EmailAccounts AS EmailAccounts
		|			INNER JOIN InformationRegister.EmailAccountSettings AS EmailAccountSettings
		|			ON EmailAccounts.Ref = EmailAccountSettings.EmailAccount
		|		ON Interactions.Account = EmailAccounts.Ref
		|WHERE
		|	Interactions.Ref = &Email
		|	AND VALUETYPE(Interactions.InteractionBasis) IN (TYPE(Document.OutgoingEmail), TYPE(Document.IncomingEmail))
		|	AND EmailMessageFolders.Owner = Interactions.Account
		|	AND EmailAccountSettings.PutEmailInBaseEmailFolder
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	EmailMessageFolders.Ref,
		|	EmailMessageFolders.Description
		|INTO MailFolders
		|FROM
		|	Catalog.EmailMessageFolders AS EmailMessageFolders
		|WHERE
		|	EmailMessageFolders.PredefinedFolder
		|	AND EmailMessageFolders.Owner IN
		|			(SELECT
		|				Interactions.Account
		|			FROM
		|				DocumentJournal.Interactions AS Interactions
		|			WHERE
		|				Interactions.Ref = &Email)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Interactions.Ref,
		|	CASE
		|		WHEN Interactions.DeletionMark
		|			THEN &DeletedItems
		|		WHEN Interactions.Type = TYPE(Document.IncomingEmail)
		|			THEN &Incoming
		|		WHEN Interactions.Type = TYPE(Document.OutgoingEmail)
		|			THEN CASE
		|					WHEN Interactions.OutgoingEmailStatus = VALUE(Enum.OutgoingEmailStatuses.Draft)
		|						THEN &Drafts
		|					WHEN Interactions.OutgoingEmailStatus = VALUE(Enum.OutgoingEmailStatuses.Sent)
		|						THEN &Sent
		|					WHEN Interactions.OutgoingEmailStatus = VALUE(Enum.OutgoingEmailStatuses.Outgoing)
		|						THEN &Outgoing
		|				END
		|		ELSE &JunkMail
		|	END AS FolderDescription
		|INTO DestinationFolderDescription
		|FROM
		|	DocumentJournal.Interactions AS Interactions
		|WHERE
		|	Interactions.Ref = &Email
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DestinationFolderDescription.Ref AS Email,
		|	CASE
		|		WHEN FoldersByBasis.Folder IS NULL 
		|			THEN MailFolders.Ref
		|		ELSE FoldersByBasis.Folder
		|	END AS Folder
		|FROM
		|	DestinationFolderDescription AS DestinationFolderDescription
		|		INNER JOIN MailFolders AS MailFolders
		|		ON DestinationFolderDescription.FolderDescription = MailFolders.Description
		|		LEFT JOIN FoldersByBasis AS FoldersByBasis
		|		ON DestinationFolderDescription.Ref = FoldersByBasis.Email";
		
	Else
		
		Query.Text = "
		|SELECT
		|	EmailMessageFolders.Ref,
		|	EmailMessageFolders.Description
		|INTO MailFolders
		|FROM
		|	Catalog.EmailMessageFolders AS EmailMessageFolders
		|WHERE
		|	EmailMessageFolders.PredefinedFolder
		|	AND EmailMessageFolders.Owner IN
		|			(SELECT
		|				Interactions.Account
		|			FROM
		|				DocumentJournal.Interactions AS Interactions
		|			WHERE
		|				Interactions.Ref = &Email)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Interactions.Ref,
		|	CASE
		|		WHEN Interactions.DeletionMark
		|			THEN &DeletedItems
		|		WHEN Interactions.Type = TYPE(Document.IncomingEmail)
		|			THEN &Incoming
		|		WHEN Interactions.Type = TYPE(Document.OutgoingEmail)
		|			THEN CASE
		|					WHEN Interactions.OutgoingEmailStatus = VALUE(Enum.OutgoingEmailStatuses.Draft)
		|						THEN &Drafts
		|					WHEN Interactions.OutgoingEmailStatus = VALUE(Enum.OutgoingEmailStatuses.Sent)
		|						THEN &Sent
		|					WHEN Interactions.OutgoingEmailStatus = VALUE(Enum.OutgoingEmailStatuses.Outgoing)
		|						THEN &Outgoing
		|				END
		|		ELSE &JunkMail
		|	END AS FolderDescription
		|INTO DestinationFolderDescription
		|FROM
		|	DocumentJournal.Interactions AS Interactions
		|WHERE
		|	Interactions.Ref = &Email
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DestinationFolderDescription.Ref AS Email,
		|	MailFolders.Ref AS Folder
		|FROM
		|	DestinationFolderDescription AS DestinationFolderDescription
		|		INNER JOIN MailFolders AS MailFolders
		|		ON DestinationFolderDescription.FolderDescription = MailFolders.Description";
		
	EndIf;
	
	Query.SetParameter("Email",Email);
	SetQueryParametersPredefinedFoldersNames(Query);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return Undefined;
	Else
		
		Selection = Result.Select();
		Selection.Next();
		
		Return Selection.Folder;
		
	EndIf;
	
EndFunction

// Sets names of the predefined folders as request parameters.
//
// Parameters:
//  Request  - Request - a request, for which parameters will be set.
//
Procedure SetQueryParametersPredefinedFoldersNames(Query) Export

	Query.SetParameter("DeletedItems", NStr("ru = 'Удаленные'; en = 'DeletedItems'; pl = 'DeletedItems';de = 'DeletedItems';ro = 'DeletedItems';tr = 'DeletedItems'; es_ES = 'DeletedItems'"));
	Query.SetParameter("Incoming", NStr("ru = 'Входящие'; en = 'Incoming'; pl = 'Incoming';de = 'Incoming';ro = 'Incoming';tr = 'Incoming'; es_ES = 'Incoming'"));
	Query.SetParameter("Drafts", NStr("ru = 'Черновики'; en = 'Drafts'; pl = 'Drafts';de = 'Drafts';ro = 'Drafts';tr = 'Drafts'; es_ES = 'Drafts'"));
	Query.SetParameter("Sent", NStr("ru = 'Отправленные'; en = 'Sent'; pl = 'Sent';de = 'Sent';ro = 'Sent';tr = 'Sent'; es_ES = 'Sent'"));
	Query.SetParameter("Outgoing", NStr("ru = 'Исходящие'; en = 'Outgoing'; pl = 'Outgoing';de = 'Outgoing';ro = 'Outgoing';tr = 'Outgoing'; es_ES = 'Outgoing'"));
	Query.SetParameter("JunkMail", NStr("ru = 'Нежелательная почта'; en = 'Junk email'; pl = 'Junk email';de = 'Junk email';ro = 'Junk email';tr = 'Junk email'; es_ES = 'Junk email'"));

EndProcedure

// Sets folders for an email array.
//
// Parameters:
//  EmailsArray  - Array - an email array, for which folders will be set.
//
Procedure SetFoldersForEmailsArray(EmailsArray) Export
	
	Query = New Query;
	Query.Text = "
	|SELECT DISTINCT
	|	InteractionsFolderSubjects.EmailMessageFolder AS Folder
	|FROM
	|	InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
	|WHERE
	|	InteractionsFolderSubjects.Interaction IN(&EmailsArray)";
	
	Query.SetParameter("EmailsArray", EmailsArray);
	
	ArrayOfFoldersForCalculation = Query.Execute().Unload().UnloadColumn("Folder");
	
	FoldersTable = DefineFoldersForEmailsArray(EmailsArray);
	For each TableRow In FoldersTable Do
		InteractionsServerCall.SetEmailFolder(TableRow.Email, TableRow.Folder, False);
		If ValueIsFilled(TableRow.Folder) AND ArrayOfFoldersForCalculation.Find(TableRow.Folder) = Undefined Then
			ArrayOfFoldersForCalculation.Add(TableRow.Folder);
		EndIf;
	EndDo;
		
	CalculateReviewedByFolders(TableOfDataForReviewedCalculation(ArrayOfFoldersForCalculation, "Folder"));
	
EndProcedure

// Determines folders for an email array.
//
// Parameters:
//  EmailsArray  - Array - an email array, for which folders will be determined.
//
// Returns:
//   ValueTable - contains map of letters to folders determined for them.
//
Function DefineFoldersForEmailsArray(EmailsArray)
	
	MapsTable = New ValueTable;
	MapsTable.Columns.Add("Folder");
	MapsTable.Columns.Add("Email");
	
	If EmailsArray.Count() = 0 Then
		Return MapsTable;
	EndIf;
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	EmailProcessingRules.Owner AS Account,
	|	EmailProcessingRules.SettingsComposer,
	|	EmailProcessingRules.PutInFolder
	|FROM
	|	Catalog.EmailProcessingRules AS EmailProcessingRules
	|WHERE
	|	EmailProcessingRules.Owner IN
	|			(SELECT
	|				Interactions.Account
	|			FROM
	|				DocumentJournal.Interactions AS Interactions
	|			WHERE
	|				Interactions.Ref IN (&EmailsArray))
	|	AND (NOT EmailProcessingRules.DeletionMark)
	|
	|ORDER BY
	|	EmailProcessingRules.AddlOrderingAttribute
	|TOTALS BY
	|	Account";
	
	Query.SetParameter("EmailsArray", EmailsArray);
	
	Result = Query.Execute();
	If Not Result.IsEmpty() Then
		SelectionAccount = Result.Select(QueryResultIteration.ByGroups);
		While SelectionAccount.Next() Do
			Selection = SelectionAccount.Select();
			While Selection.Next() Do
				
				ProcessingRulesSchema = 
					Catalogs.EmailProcessingRules.GetTemplate("EmailProcessingRuleScheme");
				
				TemplateComposer = New DataCompositionTemplateComposer();
				SettingsComposer = New DataCompositionSettingsComposer;
				SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(ProcessingRulesSchema));
				SettingsComposer.LoadSettings(Selection.SettingsComposer.Get());
				SettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
				CommonClientServer.SetFilterItem(
					SettingsComposer.Settings.Filter, "Ref", EmailsArray, DataCompositionComparisonType.InList);
				CommonClientServer.SetFilterItem(
					SettingsComposer.Settings.Filter,
					"Ref.Account",
					SelectionAccount.Account,
					DataCompositionComparisonType.Equal);
				
				DataCompositionTemplate = TemplateComposer.Execute(
					ProcessingRulesSchema,
					SettingsComposer.GetSettings(),
					,,
					Type("DataCompositionValueCollectionTemplateGenerator"));
				
				QueryText = DataCompositionTemplate.DataSets.MainDataSet.Query;
				QueryRule = New Query(QueryText);
				For each Parameter In DataCompositionTemplate.ParameterValues Do
					QueryRule.Parameters.Insert(Parameter.Name, Parameter.Value);
				EndDo;
				
				EmailResult = QueryRule.Execute();
				If Not EmailResult.IsEmpty() Then
					EmailSelection = EmailResult.Select();
					While EmailSelection.Next() Do
						
						NewTableRow = MapsTable.Add();
						NewTableRow.Folder = Selection.PutInFolder;
						NewTableRow.Email = EmailSelection.Ref;
						
						ArrayElementIndexForDeletion = EmailsArray.Find(EmailSelection.Ref);
						If ArrayElementIndexForDeletion <> Undefined Then
							EmailsArray.Delete(ArrayElementIndexForDeletion);
						EndIf;
					EndDo;
				EndIf;
				
				If EmailsArray.Count() = 0 Then
					Return MapsTable;
				EndIf;
				
			EndDo;
			
		EndDo;
	EndIf;
	
	If EmailsArray.Count() > 0 Then
		DefineDefaultFoldersForEmailsArray(EmailsArray, MapsTable);
	EndIf;
	
	Return MapsTable;
	
EndFunction

// Determines default folders for an email array.
//
// Parameters:
//  EmailsArray  - Array - an email array, for which folders will be determined.
//  EmailsTable  - ValueTable - a table, to which a map of emails to determined for them folders is placed.
//
Procedure DefineDefaultFoldersForEmailsArray(EmailsArray,EmailsTable)
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	EmailMessageFolders.Ref,
	|	EmailMessageFolders.Description,
	|	EmailMessageFolders.Owner AS Account
	|INTO MailFolders
	|FROM
	|	Catalog.EmailMessageFolders AS EmailMessageFolders
	|WHERE
	|	EmailMessageFolders.PredefinedFolder
	|	AND EmailMessageFolders.Owner IN
	|			(SELECT DISTINCT
	|				Interactions.Account
	|			FROM
	|				DocumentJournal.Interactions AS Interactions
	|			WHERE
	|				Interactions.Ref IN (&EmailsArray))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Interactions.Ref,
	|	CASE
	|		WHEN Interactions.DeletionMark
	|			THEN &DeletedItems
	|		WHEN Interactions.Type = TYPE(Document.IncomingEmail)
	|			THEN &Incoming
	|		WHEN Interactions.Type = TYPE(Document.OutgoingEmail)
	|			THEN CASE
	|					WHEN Interactions.OutgoingEmailStatus = VALUE(Enum.OutgoingEmailStatuses.Draft)
	|						THEN &Drafts
	|					WHEN Interactions.OutgoingEmailStatus = VALUE(Enum.OutgoingEmailStatuses.Sent)
	|						THEN &Sent
	|					WHEN Interactions.OutgoingEmailStatus = VALUE(Enum.OutgoingEmailStatuses.Outgoing)
	|						THEN &Outgoing
	|				END
	|		ELSE &JunkMail
	|	END AS FolderDescription,
	|	Interactions.Account
	|INTO DestinationFolderDescription
	|FROM
	|	DocumentJournal.Interactions AS Interactions
	|WHERE
	|	Interactions.Ref IN(&EmailsArray)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MailFolders.Ref AS Folder,
	|	DestinationFolderDescription.Ref AS Email
	|FROM
	|	DestinationFolderDescription AS DestinationFolderDescription
	|		INNER JOIN MailFolders AS MailFolders
	|		ON DestinationFolderDescription.FolderDescription = MailFolders.Description
	|			AND DestinationFolderDescription.Account = MailFolders.Account";
	
	Query.SetParameter("EmailsArray",EmailsArray);
	SetQueryParametersPredefinedFoldersNames(Query);
	
	Result = Query.Execute();
	If NOT Result.IsEmpty() Then
		CommonClientServer.SupplementTable(Result.Unload(), EmailsTable);
	EndIf;
	
EndProcedure

// Defines a flag of changing a deletion mark when writing an email.
//
// Parameters:
//  EmailObject - DocumentObject.OutgoingEmail,
//                  DocumentObject.IncomingEmail - an email, for which the procedure is executed.
Procedure ProcessDeletionMarkChangeFlagOnWriteEmail(EmailObject) Export
	
	If EmailObject.DeletionMark <> EmailObject.AdditionalProperties.DeletionMark Then
		If NOT EmailObject.AdditionalProperties.Property("DeletionMarkChangeProcessed") Then
			If EmailObject.DeletionMark = True Then
				Folder = DefineDefaultFolderForEmail(EmailObject.Ref);
			Else
				Folder = DefineFolderForEmail(EmailObject.Ref);
			EndIf;
			InteractionsServerCall.SetEmailFolder(EmailObject.Ref, Folder);
		EndIf;
	EndIf;
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////
//  State calculation

// Calculates interaction subject states.
//
// Parameters:
//  FoldersTable  - ValueTable, Undefined - a table of folders that must be calculated.
//             If Undefined, states of all folders are calculated.
//
Procedure CalculateReviewedByFolders(FoldersTable) Export

	SetPrivilegedMode(True);
	Query = New Query;
	
	If FoldersTable = Undefined Then
		
		InformationRegisters.EmailFolderStates.DeleteRecordFromRegister(Undefined);
		
		Query.Text = "
		|SELECT DISTINCT
		|	InteractionsFolderSubjects.EmailMessageFolder AS EmailMessageFolder,
		|	SUM(CASE
		|			WHEN InteractionsFolderSubjects.Reviewed
		|				THEN 0
		|			ELSE 1
		|		END) AS NotReviewedInteractionsCount
		|INTO FoldersToUse
		|FROM
		|	InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
		|WHERE
		|	InteractionsFolderSubjects.EmailMessageFolder <> VALUE(Catalog.EmailMessageFolders.EmptyRef)
		|
		|GROUP BY
		|	InteractionsFolderSubjects.EmailMessageFolder
		|
		|INDEX BY
		|	EmailMessageFolder
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	EmailMessageFolders.Ref AS Folder,
		|	ISNULL(FoldersToUse.NotReviewedInteractionsCount, 0) AS NotReviewed
		|FROM
		|	Catalog.EmailMessageFolders AS EmailMessageFolders
		|		LEFT JOIN FoldersToUse AS FoldersToUse
		|		ON (FoldersToUse.EmailMessageFolder = EmailMessageFolders.Ref)";
		
	Else
		
		If FoldersTable.Count() = 0 Then
			Return;
		EndIf;
		
		Query.Text = "
		|SELECT
		|	FoldersForCalculation.CalculateBy AS Folder
		|INTO FoldersForCalculation
		|FROM
		|	&FoldersForCalculation AS FoldersForCalculation
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	SUM(CASE
		|			WHEN InteractionsFolderSubjects.Reviewed
		|				THEN 0
		|			ELSE 1
		|		END) AS NotReviewedInteractionsCount,
		|	InteractionsFolderSubjects.EmailMessageFolder AS Folder
		|INTO CalculatedFolders
		|FROM
		|	InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
		|WHERE
		|	InteractionsFolderSubjects.EmailMessageFolder IN
		|			(SELECT
		|				FoldersForCalculation.Folder
		|			FROM
		|				FoldersForCalculation AS FoldersForCalculation)
		|
		|GROUP BY
		|	InteractionsFolderSubjects.EmailMessageFolder
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	FoldersForCalculation.Folder,
		|	ISNULL(CalculatedFolders.NotReviewedInteractionsCount, 0) AS NotReviewed
		|FROM
		|	FoldersForCalculation AS FoldersForCalculation
		|		LEFT JOIN CalculatedFolders AS CalculatedFolders
		|		ON FoldersForCalculation.Folder = CalculatedFolders.Folder";
		
		Query.SetParameter("FoldersForCalculation", FoldersTable);
		
	EndIf;
	
	Selection = Query.Execute().Select();

	While Selection.Next() Do
	
		InformationRegisters.EmailFolderStates.ExecuteRecordToRegister(Selection.Folder, Selection.NotReviewed);
	
	EndDo;

EndProcedure

// Calculates interaction contact states.
//
// Parameters:
//  ObjectsTable  - ValueTable, Undefined - a table of contacts that must be calculated.
//             If Undefined, states of all contacts are calculated.
//
Procedure CalculateReviewedByContacts(DataForCalculation) Export

	SetPrivilegedMode(True);
	
	If DataForCalculation = Undefined Then
		
		InformationRegisters.InteractionsContactStates.DeleteRecordFromRegister(Undefined);
		
		While True Do
		
		Query = New Query;
		Query.Text = "
		|SELECT DISTINCT TOP 100
		|	InteractionsContacts.Contact
		|INTO ContactsForSettlement
		|FROM
		|	InformationRegister.InteractionsContacts AS InteractionsContacts
		|		LEFT JOIN InformationRegister.InteractionsContactStates AS InteractionsContactStates
		|		ON InteractionsContacts.Contact = InteractionsContactStates.Contact
		|WHERE
		|	InteractionsContactStates.Contact IS NULL 
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	InteractionsContacts.Contact,
		|	MAX(Interactions.Date) AS LastInteractionDate,
		|	SUM(CASE
		|			WHEN InteractionsFolderSubjects.Reviewed
		|				THEN 0
		|			ELSE 1
		|		END) AS NotReviewedInteractionsCount
		|FROM
		|	ContactsForSettlement AS ContactsForSettlement
		|		INNER JOIN InformationRegister.InteractionsContacts AS InteractionsContacts
		|			INNER JOIN DocumentJournal.Interactions AS Interactions
		|			ON InteractionsContacts.Interaction = Interactions.Ref
		|			INNER JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
		|			ON InteractionsContacts.Interaction = InteractionsFolderSubjects.Interaction
		|		ON ContactsForSettlement.Contact = InteractionsContacts.Contact
		|
		|GROUP BY
		|	InteractionsContacts.Contact";
		
		Result = Query.Execute();
		If Result.IsEmpty() Then
			Return;
		EndIf;
		
		Selection = Result.Select();
		While Selection.Next() Do
			
			InformationRegisters.InteractionsContactStates.ExecuteRecordToRegister(Selection.Contact,
			                                                                          Selection.NotReviewedInteractionsCount,
			                                                                          Selection.LastInteractionDate);
			EndDo;
			
		EndDo;
		
	Else
		
		Query = New Query;
		
		If TypeOf(DataForCalculation) = Type("ValueTable") Then
			
			TextContactsForCalculation = 
			"SELECT
			|	ContactsForSettlement.CalculateBy AS Contact
			|INTO ContactsForSettlement
			|FROM
			|	&ContactsForSettlement AS ContactsForSettlement
			|
			|INDEX BY
			|	Contact
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////";
			
			Query.SetParameter("ContactsForSettlement", DataForCalculation);
			
		ElsIf TypeOf(DataForCalculation) = Type("QueryResultSelection") Then
			
			InteractionsArray = New Array;
			While DataForCalculation.Next() Do
				InteractionsArray.Add(DataForCalculation.Interaction);
			EndDo;
			
			TextContactsForCalculation = 
			"SELECT DISTINCT
			|	InteractionsContacts.Contact
			|INTO ContactsForSettlement
			|FROM
			|	InformationRegister.InteractionsContacts AS InteractionsContacts
			|WHERE
			|	InteractionsContacts.Interaction IN(&InteractionsArray)
			|
			|INDEX BY
			|	Contact
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////";
			
			Query.SetParameter("InteractionsArray", InteractionsArray);
			
		ElsIf TypeOf(DataForCalculation) = Type("Array") Then
			
			TextContactsForCalculation = 
			"SELECT DISTINCT
			|	InteractionsContacts.Contact
			|INTO ContactsForSettlement
			|FROM
			|	InformationRegister.InteractionsContacts AS InteractionsContacts
			|WHERE
			|	InteractionsContacts.Interaction IN(&InteractionsArray)
			|
			|INDEX BY
			|	Contact
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////";
			
			Query.SetParameter("InteractionsArray", DataForCalculation);
			
		Else 
			
			Return;
			
		EndIf;
		
		Query.Text = TextContactsForCalculation + "
		|SELECT
		|	NestedQuery.Contact,
		|	MAX(NestedQuery.LastInteractionDate) AS LastInteractionDate,
		|	SUM(NestedQuery.NotReviewedInteractionsCount) AS NotReviewedInteractionsCount
		|FROM
		|	(SELECT DISTINCT
		|		InteractionsContacts.Contact AS Contact,
		|		Interactions.Ref AS Ref,
		|		ISNULL(Interactions.Date, DATETIME(1, 1, 1)) AS LastInteractionDate,
		|		CASE
		|			WHEN ISNULL(InteractionsFolderSubjects.Reviewed, TRUE)
		|				THEN 0
		|			ELSE 1
		|		END AS NotReviewedInteractionsCount
		|	FROM
		|		ContactsForSettlement AS ContactsForSettlement
		|			LEFT JOIN InformationRegister.InteractionsContacts AS InteractionsContacts
		|				LEFT JOIN DocumentJournal.Interactions AS Interactions
		|				ON InteractionsContacts.Interaction = Interactions.Ref
		|				LEFT JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
		|				ON InteractionsContacts.Interaction = InteractionsFolderSubjects.Interaction
		|			ON ContactsForSettlement.Contact = InteractionsContacts.Contact) AS NestedQuery
		|
		|GROUP BY
		|	NestedQuery.Contact";
		
		Result = Query.Execute();
		Selection = Result.Select();
		
		While Selection.Next() Do
		
			If Selection.LastInteractionDate = Date(1, 1, 1) Then
				InformationRegisters.InteractionsContactStates.DeleteRecordFromRegister(Selection.Contact);
			Else
				InformationRegisters.InteractionsContactStates.ExecuteRecordToRegister(Selection.Contact,
				                                                                          Selection.NotReviewedInteractionsCount,
				                                                                          Selection.LastInteractionDate);
			EndIf;
		
		EndDo;
		
	EndIf;

EndProcedure

// Calculates interaction subject states.
//
// Parameters:
//  ObjectsTable  - ValueTable, Undefined - a table of objects that must be calculated.
//             If Undefined, states of all subjects are calculated.
//
Procedure CalculateReviewedBySubjects(DataForCalculation) Export

	SetPrivilegedMode(True);
	Query = New Query;
	
	If DataForCalculation = Undefined Then
		
		InformationRegisters.InteractionsSubjectsStates.DeleteRecordFromRegister(Undefined);
		
		Query.Text = "
		|SELECT
		|	InteractionsFolderSubjects.Topic,
		|	SUM(CASE
		|			WHEN InteractionsFolderSubjects.Reviewed
		|				THEN 0
		|			ELSE 1
		|		END) AS NotReviewedInteractionsCount,
		|	MAX(Interactions.Date) AS LastInteractionDate,
		|	MAX(ISNULL(InteractionsSubjectsStates.IsActive, FALSE)) AS IsActive
		|FROM
		|	InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
		|		LEFT JOIN DocumentJournal.Interactions AS Interactions
		|		ON InteractionsFolderSubjects.Interaction = Interactions.Ref
		|		LEFT JOIN InformationRegister.InteractionsSubjectsStates AS InteractionsSubjectsStates
		|		ON InteractionsFolderSubjects.Topic = InteractionsSubjectsStates.Topic
		|
		|GROUP BY
		|	InteractionsFolderSubjects.Topic";
		
	Else
		
		If DataForCalculation.Count() = 0 Then
			Return;
		EndIf;
		
		If TypeOf(DataForCalculation) = Type("ValueTable") Then
			
			TextSubjectsForCalculation = "
			|SELECT
			|	SubjectsForCalculation.CalculateBy AS Topic
			|INTO SubjectsForCalculation
			|FROM
			|	&SubjectsForCalculation AS SubjectsForCalculation
			|
			|INDEX BY
			|	Topic
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////";
			
			Query.SetParameter("SubjectsForCalculation", DataForCalculation);
			
		ElsIf TypeOf(DataForCalculation) = Type("Array") Then
			
			TextSubjectsForCalculation = "
			|SELECT DISTINCT
			|	InteractionsFolderSubjects.Topic AS Topic
			|INTO SubjectsForCalculation
			|FROM
			|	InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
			|WHERE
			|	InteractionsFolderSubjects.Interaction IN(&InteractionsArray)
			|
			|INDEX BY
			|	Topic
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////";
			
			Query.SetParameter("InteractionsArray", DataForCalculation);
			
		Else
			
			Return;
			
		EndIf;
		
		Query.Text = TextSubjectsForCalculation + "
		|SELECT
		|	InteractionsFolderSubjects.Topic AS Topic,
		|	SUM(CASE
		|			WHEN InteractionsFolderSubjects.Reviewed
		|				THEN 0
		|			ELSE 1
		|		END) AS NotReviewedInteractionsCount,
		|	MAX(Interactions.Date) AS LastInteractionDate,
		|	MAX(ISNULL(InteractionsSubjectsStates.IsActive, FALSE)) AS IsActive
		|INTO CalculatedSubjects
		|FROM
		|	InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
		|		LEFT JOIN DocumentJournal.Interactions AS Interactions
		|		ON InteractionsFolderSubjects.Interaction = Interactions.Ref
		|		LEFT JOIN InformationRegister.InteractionsSubjectsStates AS InteractionsSubjectsStates
		|		ON InteractionsFolderSubjects.Topic = InteractionsSubjectsStates.Topic
		|WHERE
		|	InteractionsFolderSubjects.Topic IN
		|			(SELECT
		|				SubjectsForCalculation.Topic
		|			FROM
		|				SubjectsForCalculation)
		|
		|GROUP BY
		|	InteractionsFolderSubjects.Topic
		|
		|INDEX BY
		|	Topic
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	SubjectsForCalculation.Topic,
		|	ISNULL(CalculatedSubjects.NotReviewedInteractionsCount, 0) AS NotReviewedInteractionsCount,
		|	ISNULL(CalculatedSubjects.LastInteractionDate, DATETIME(1, 1, 1)) AS LastInteractionDate,
		|	CASE
		|		WHEN CalculatedSubjects.IsActive IS NULL 
		|			THEN ISNULL(InteractionsSubjectsStates.IsActive, FALSE)
		|		ELSE CalculatedSubjects.IsActive
		|	END AS IsActive
		|FROM
		|	SubjectsForCalculation AS SubjectsForCalculation
		|		LEFT JOIN CalculatedSubjects AS CalculatedSubjects
		|		ON SubjectsForCalculation.Topic = CalculatedSubjects.Topic
		|		LEFT JOIN InformationRegister.InteractionsSubjectsStates AS InteractionsSubjectsStates
		|		ON SubjectsForCalculation.Topic = InteractionsSubjectsStates.Topic";
		
		
	EndIf;
	
	Selection = Query.Execute().Select();

	While Selection.Next() Do
		
		If Selection.LastInteractionDate <> Date(1,1,1) OR Selection.IsActive = True  Then
			InformationRegisters.InteractionsSubjectsStates.ExecuteRecordToRegister(Selection.Topic, 
			                                                                          Selection.NotReviewedInteractionsCount,
			                                                                          Selection.LastInteractionDate,
			                                                                          Selection.IsActive);
		Else
			
			InformationRegisters.InteractionsSubjectsStates.DeleteRecordFromRegister(Selection.Topic);
			
		EndIf;
	
	EndDo;

EndProcedure

// Generates a data table to calculate folder states and interaction subjects.
//
// Parameters:
//  DataForCalculation  - Structure, SelectionFromQueryResults, Array - data, on whose basis a table 
//                      will be generated.
//  AttributeName  - String - can be "Subject" or "Folder".
//
// Returns:
//   ValueTable   - a table prepared for calculation.
//
Function TableOfDataForReviewedCalculation(DataForCalculation, AttributeName) Export

	GeneratedTable = New ValueTable;
	If AttributeName = "Folder" Then
		ColumnTypesDetails = New TypeDescription("CatalogRef.EmailMessageFolders");
	ElsIf AttributeName = "Topic" Then
		ColumnTypesDetails = New TypeDescription(New TypeDescription(Metadata.InformationRegisters.InteractionsSubjectsStates.Dimensions.Topic.Type.Types()));
	ElsIf AttributeName = "Contact" Then
		ColumnTypesDetails = New TypeDescription(New TypeDescription(Metadata.InformationRegisters.InteractionsContacts.Dimensions.Contact.Type.Types()));
	EndIf;
	
	GeneratedTable.Columns.Add("CalculateBy", ColumnTypesDetails);
	
	If TypeOf(DataForCalculation) = Type("Structure") Then
		
		NewRecord  = DataForCalculation.NewRecord;
		OldRecord = DataForCalculation.OldRecord;
		
		If ValueIsFilled(NewRecord[AttributeName]) Then
			NewRow = GeneratedTable.Add();
			NewRow.CalculateBy = NewRecord[AttributeName];
		EndIf;
		
		If ValueIsFilled(OldRecord[AttributeName]) AND NewRecord[AttributeName] <> OldRecord[AttributeName] Then
			
			NewRow = GeneratedTable.Add();
			NewRow.CalculateBy = OldRecord[AttributeName];
			
		EndIf;
		
	ElsIf TypeOf(DataForCalculation) = Type("QueryResultSelection") Then
		
		While DataForCalculation.Next() Do
			If ValueIsFilled(DataForCalculation[AttributeName]) AND GeneratedTable.Find(DataForCalculation[AttributeName], "CalculateBy") = Undefined Then
				NewRow = GeneratedTable.Add();
				NewRow.CalculateBy = DataForCalculation[AttributeName];
			EndIf;
		EndDo;
		
	ElsIf TypeOf(DataForCalculation) = Type("Array") Then
		
		For Each ArrayElement In DataForCalculation Do
			If ValueIsFilled(ArrayElement) AND GeneratedTable.Find(ArrayElement, "CalculateBy") = Undefined Then
				NewRow = GeneratedTable.Add();
				NewRow.CalculateBy = ArrayElement;
			EndIf;
		EndDo;
		
	EndIf;
	
	GeneratedTable.Indexes.Add("CalculateBy");
	
	Return GeneratedTable;

EndFunction

// Determines if it is necessary to calculate states of folders, subjects or interaction contacts.
//
// Parameters:
//  AdditionalProperties  - Structure - additional properties of a record set or an interaction document.
//
// Returns:
//   Boolean - indicates if it is necessary to calculate states of folders, subjects, or interaction contacts.
//
Function CalculateReviewedItems(AdditionalProperties) Export
	Var CalculateReviewedItems;

	Return AdditionalProperties.Property("CalculateReviewedItems", CalculateReviewedItems)
		AND CalculateReviewedItems;

EndFunction

// Specifies whether it is necessary to write interaction contacts to an auxiliary information register
//  "Interaction contacts".
//
// Parameters:
//  AdditionalProperties - Structure - additional properties of the interaction document.
//
// Returns:
//   Boolean - indicates whether it is necessary to write interaction contacts to the auxiliary information register
//    "Interaction contacts".
//
Function DoNotSaveContacts(AdditionalProperties)
	Var DoNotSaveContacts;
	
	Return AdditionalProperties.Property("DoNotSaveContacts", DoNotSaveContacts) 
		AND DoNotSaveContacts;

EndFunction

// Sets the read flag to interaction array.
//
// Parameters:
//  InteractionsArray  - Array - an array, to which a flag is being set.
//  FlagValue      - Boolean - the Reviewed flag value.
//  HasChanges         - Boolean - indicates that at least one interaction had his value changed
//                                   Reviewed.
//
Procedure MarkAsReviewed(InteractionsArray, FlagValue, HasChanges) Export

	If InteractionsArray.Count() = 0 Then
		Return;
	EndIf;
		
	Query = New Query;
	Query.Text = "
	|SELECT
	|	InteractionsFolderSubjects.Interaction,
	|	InteractionsFolderSubjects.EmailMessageFolder AS Folder,
	|	InteractionsFolderSubjects.Topic
	|FROM
	|	InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
	|WHERE
	|	InteractionsFolderSubjects.Reviewed <> &FlagValue
	|	AND InteractionsFolderSubjects.Interaction IN(&InteractionsArray)";
	
	Query.SetParameter("InteractionsArray", InteractionsArray);
	Query.SetParameter("FlagValue", FlagValue);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		StructureForWrite = InformationRegisters.InteractionsFolderSubjects.InteractionAttributes();
		StructureForWrite.Reviewed             = FlagValue;
		StructureForWrite.CalculateReviewedItems = False;

		InformationRegisters.InteractionsFolderSubjects.WriteInteractionFolderSubjects(Selection.Interaction, StructureForWrite);
		HasChanges = True;
		
	EndDo;
	
	Selection.Reset();
	CalculateReviewedByFolders(TableOfDataForReviewedCalculation(Selection, "Folder"));
	
	Selection.Reset();
	CalculateReviewedBySubjects(TableOfDataForReviewedCalculation(Selection, "Topic"));
	
	Selection.Reset();
	CalculateReviewedByContacts(Selection);

EndProcedure

// Checks interaction array and leaves only those that require their review date to be changed.
//
// Parameters:
//  InteractionsArray  - Array - an array of interactions whose review date is proposed to be changed.
//  ReviewDate - Date - a new review date.
//
// Returns:
//   Array - an array of interactions whose review date requires to be changed.
//
Function InteractionsArrayForReviewDateChange(InteractionsArray, ReviewDate) Export

	If InteractionsArray.Count() > 0 Then
		Query = New Query;
		Query.Text = "
		|SELECT
		|	InteractionsFolderSubjects.Interaction AS Interaction
		|FROM
		|	InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
		|WHERE
		|	NOT InteractionsFolderSubjects.Reviewed
		|	AND InteractionsFolderSubjects.ReviewAfter <> &ReviewDate
		|	AND InteractionsFolderSubjects.Interaction IN(&InteractionsArray)";
		
		Query.SetParameter("ReviewDate", ReviewDate);
		Query.SetParameter("InteractionsArray", InteractionsArray);
		
		Return Query.Execute().Unload().UnloadColumn("Interaction");
	Else
		
		Return InteractionsArray;
		
	EndIf;

EndFunction

///////////////////////////////////////////////////////////////////////////////////
//  Other procedures and functions

// The procedure fills the time selection list.
// Parameters:
//  FormInputField  - an item that owns the list,
//  Interval        - an interval, with which the list is to be filled, it is an hour by default.
Procedure FillTimeSelectionList(FormInputField, Interval = 3600) Export

	WorkdayBeginning      = '00010101000000';
	WorkdayEnd   = '00010101235959';

	TimesList = FormInputField.ChoiceList;
	TimesList.Clear();

	ListTime = WorkdayBeginning;
	While BegOfHour(ListTime) <= BegOfHour(WorkdayEnd) Do
		If NOT ValueIsFilled(ListTime) Then
			TimePresentation = "00:00";
		Else
			TimePresentation = Format(ListTime,"DF=HH:mm");
		EndIf;

		TimesList.Add(ListTime, TimePresentation);

		ListTime = ListTime + Interval;
	EndDo;

EndProcedure

// Generates a query text of dynamic interaction list depending on navigation panel kind and passed 
// parameter type.
//
// Parameters:
//  FilterValue  - CatalogRef, DocumentRef - a value of navigation panel filter.
//
// Returns:
//   String - a query text of the dynamic list.
//
Function InteractionsListQueryText(FilterValue = Undefined) Export
	
	QueryText ="
	|SELECT
	|	CASE
	|		WHEN InteractionDocumentsLog.Ref REFS Document.Meeting
	|			THEN CASE
	|					WHEN InteractionDocumentsLog.DeletionMark
	|						THEN 10
	|					ELSE 0
	|				END
	|		WHEN InteractionDocumentsLog.Ref REFS Document.PlannedInteraction
	|			THEN CASE
	|					WHEN InteractionDocumentsLog.DeletionMark
	|						THEN 11
	|					ELSE 1
	|				END
	|		WHEN InteractionDocumentsLog.Ref REFS Document.PhoneCall
	|			THEN CASE
	|					WHEN InteractionDocumentsLog.DeletionMark
	|						THEN 12
	|					ELSE 2
	|				END
	|		WHEN InteractionDocumentsLog.Ref REFS Document.IncomingEmail
	|			THEN CASE
	|					WHEN InteractionDocumentsLog.DeletionMark
	|						THEN 13
	|					ELSE 3
	|				END
	|		WHEN InteractionDocumentsLog.Ref REFS Document.OutgoingEmail
	|			THEN CASE
	|					WHEN InteractionDocumentsLog.DeletionMark
	|						THEN 14
	|					ELSE CASE
	|							WHEN InteractionDocumentsLog.OutgoingEmailStatus = VALUE(Enum.OutgoingEmailStatuses.Draft)
	|								THEN 15
	|							WHEN InteractionDocumentsLog.OutgoingEmailStatus = VALUE(Enum.OutgoingEmailStatuses.Outgoing)
	|								THEN 16
	|							ELSE 4
	|						END
	|				END
	|		WHEN InteractionDocumentsLog.Ref REFS Document.SMSMessage
	|			THEN CASE
	|					WHEN InteractionDocumentsLog.DeletionMark
	|						THEN 22
	|					ELSE CASE
	|							WHEN InteractionDocumentsLog.OutgoingEmailStatus = VALUE(Enum.SMSMessageDocumentState.Draft)
	|								THEN 17
	|							WHEN InteractionDocumentsLog.OutgoingEmailStatus = VALUE(Enum.SMSMessageDocumentState.Outgoing)
	|								THEN 18
	|							WHEN InteractionDocumentsLog.OutgoingEmailStatus = VALUE(Enum.SMSMessageDocumentState.DeliveryInProgress)
	|								THEN 19
	|							WHEN InteractionDocumentsLog.OutgoingEmailStatus = VALUE(Enum.SMSMessageDocumentState.PartiallyDelivered)
	|								THEN 21
	|							WHEN InteractionDocumentsLog.OutgoingEmailStatus = VALUE(Enum.SMSMessageDocumentState.NotDelivered)
	|								THEN 23
	|							WHEN InteractionDocumentsLog.OutgoingEmailStatus = VALUE(Enum.SMSMessageDocumentState.Delivered)
	|								THEN 24
	|							ELSE 17
	|						END
	|				END
	|	END AS PictureNumber,
	|	InteractionDocumentsLog.Ref,
	|	InteractionDocumentsLog.Date,
	|	InteractionDocumentsLog.DeletionMark AS DeletionMark,
	|	InteractionDocumentsLog.Number,
	|	InteractionDocumentsLog.Posted,
	|	InteractionDocumentsLog.Author,
	|	InteractionDocumentsLog.InteractionBasis,
	|	InteractionDocumentsLog.Incoming,
	|	InteractionDocumentsLog.Subject,
	|	InteractionDocumentsLog.EmployeeResponsible AS EmployeeResponsible,
	|	ISNULL(InteractionsSubjects.Reviewed, FALSE) AS Reviewed,
	|	ISNULL(InteractionsSubjects.ReviewAfter, DATETIME(1, 1, 1)) AS ReviewAfter,
	|	InteractionDocumentsLog.Members,
	|	InteractionDocumentsLog.Type,
	|	InteractionDocumentsLog.Account,
	|	InteractionDocumentsLog.HasAttachments,
	|	InteractionDocumentsLog.Importance,
	|	CASE
	|		WHEN InteractionDocumentsLog.Importance = VALUE(Enum.InteractionImportanceOptions.High)
	|			THEN 2
	|		WHEN InteractionDocumentsLog.Importance = VALUE(Enum.InteractionImportanceOptions.Low)
	|			THEN 0
	|		ELSE 1
	|	END AS ImportancePictureNumber,
	|	%Topic% AS Topic,
	|	VALUETYPE(InteractionsSubjects.Topic) AS SubjectType,
	|	ISNULL(InteractionsSubjects.EmailMessageFolder, VALUE(Catalog.EmailMessageFolders.EmptyRef)) AS Folder,
	|	InteractionDocumentsLog.SentReceived,
	|	InteractionDocumentsLog.Size,
	|	InteractionDocumentsLog.OutgoingEmailStatus
	|FROM
	|	DocumentJournal.Interactions AS InteractionDocumentsLog
	|		INNER JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsSubjects
	|		ON InteractionDocumentsLog.Ref = InteractionsSubjects.Interaction
	|		%ConnectionTextContactsTable%
	|{WHERE
	|	InteractionDocumentsLog.Ref AS Search
	|	%FilterContact%}";
	
	If FilterValue = Undefined Then
		TextSubject                    = "ISNULL(InteractionsSubjects.Topic, UNDEFINED)";
		TextFilterContact               = "";
		TextJoinContactsTable = "";
	ElsIf InteractionsClientServer.IsSubject(FilterValue) OR InteractionsClientServer.IsInteraction(FilterValue) Then
		TextSubject                    = "ISNULL(CAST(InteractionsSubjects.Topic AS " + FilterValue.Metadata().FullName() + "), UNDEFINED)";
		TextFilterContact               = "";
		TextJoinContactsTable = "";
	Else
		TextSubject                    = "ISNULL(InteractionsSubjects.Topic, UNDEFINED)";
		TextDifferentItems                  = "";
		TextFilterContact               = ",
		                                   |InteractionsContacts.Contact";
		TextJoinContactsTable = "{INNER JOIN InformationRegister.InteractionsContacts AS InteractionsContacts
		                                   |ON InteractionDocumentsLog.Ref = InteractionsContacts.Interaction}";
	EndIf;
	
	QueryText = StrReplace(QueryText, "%Topic%", TextSubject);
	QueryText = StrReplace(QueryText, "%DISTINCT%", TextDifferentItems);
	QueryText = StrReplace(QueryText, "%FilterContact%", TextFilterContact);
	QueryText = StrReplace(QueryText, "%ConnectionTextContactsTable%", TextJoinContactsTable);

	Return QueryText; 

EndFunction

// Fills data of the InteractionContacts information register for the passed interaction array.
//
// Parameters:
//  InteractionsArray - Array - an array, for which the contact data will be filled.
//  CalculateReviewedItems - Boolean - indicates whether it is necessary to calculate interaction contact states.
//
Procedure OnWriteDocument(DocumentObject) Export

	SetPrivilegedMode(True);
	
	If DoNotSaveContacts(DocumentObject.AdditionalProperties) Then
		Return;
	EndIf;
	
	RecordSet = InformationRegisters.InteractionsContacts.CreateRecordSet();
	RecordSet.Filter.Interaction.Set(DocumentObject.Ref);
	
	Table = New ValueTable;
	ContactsTypesDetails = New TypeDescription(ContactsTypes());
	Table.Columns.Add("Contact", ContactsTypesDetails);
	Table.Columns.Add("Presentation", New TypeDescription("String", , New StringQualifiers(100, AllowedLength.Variable)));

	If TypeOf(DocumentObject) = Type("DocumentObject.Meeting") Then
		
		For Each Member In DocumentObject.Members Do
			
			NewRow = Table.Add();
			NewRow.Contact        = Member.Contact;
			NewRow.Presentation  = Member.ContactPresentation;
			
		EndDo;
		
	ElsIf TypeOf(DocumentObject) = Type("DocumentObject.PlannedInteraction") Then
		
		For Each Member In DocumentObject.Members Do
			
			NewRow = Table.Add();
			NewRow.Contact        = Member.Contact;
			NewRow.Presentation  = Member.ContactPresentation;
			
		EndDo;
		
	ElsIf TypeOf(DocumentObject) = Type("DocumentObject.PhoneCall") Then
		
		NewRow = Table.Add();
		NewRow.Contact        = DocumentObject.SubscriberContact;
		NewRow.Presentation  = DocumentObject.SubscriberPresentation;
		
	ElsIf TypeOf(DocumentObject) = Type("DocumentObject.SMSMessage") Then
		
		For Each Caller In DocumentObject.Recipients Do
			
			NewRow = Table.Add();
			NewRow.Contact        = Caller.Contact;
			NewRow.Presentation  = Caller.ContactPresentation;
			
		EndDo;
		
	ElsIf TypeOf(DocumentObject) = Type("DocumentObject.IncomingEmail") Then
		
		NewRow = Table.Add();
		NewRow.Contact        = DocumentObject.SenderContact;
		NewRow.Presentation  = DocumentObject.SenderPresentation;
		
	ElsIf TypeOf(DocumentObject) = Type("DocumentObject.OutgoingEmail") Then
		
		For Each Recipient In DocumentObject.EmailRecipients Do
			
			NewRow = Table.Add();
			NewRow.Contact        = Recipient.Contact;
			NewRow.Presentation  = Recipient.Presentation;
			
		EndDo;
		
		For Each Recipient In DocumentObject.CCRecipients Do
			
			NewRow = Table.Add();
			NewRow.Contact        = Recipient.Contact;
			NewRow.Presentation  = Recipient.Presentation;
			
		EndDo;
		
		For Each Recipient In DocumentObject.BccRecipients Do
			
			NewRow = Table.Add();
			NewRow.Contact        = Recipient.Contact;
			NewRow.Presentation  = Recipient.Presentation;
			
		EndDo;
		
	EndIf;
	
	For Each TableRow In Table Do
		If NOT ValueIsFilled(TableRow.Contact) Then
			TableRow.Contact = Catalogs.Users.EmptyRef();
		EndIf;
	EndDo;
	
	Query = New Query;
	Query.Text = "
	|SELECT DISTINCT
	|	ContactsTable.Contact,
	|	ContactsTable.Presentation
	|INTO ContactsTable
	|FROM
	|	&ContactsTable AS ContactsTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	CASE
	|		WHEN ContactsTable.Contact = VALUE(Catalog.Users.EmptyRef)
	|			THEN ISNULL(StringContactInteractions.Ref, UNDEFINED)
	|		ELSE ContactsTable.Contact
	|	END AS Contact,
	|	ContactsTable.Presentation
	|FROM
	|	ContactsTable AS ContactsTable
	|		LEFT JOIN Catalog.StringContactInteractions AS StringContactInteractions
	|		ON ContactsTable.Presentation = StringContactInteractions.Description
	|			AND (NOT StringContactInteractions.DeletionMark)";
	
	Query.SetParameter("ContactsTable", Table);
	
	Table = Query.Execute().Unload();
	
	For Each TableRow In Table Do
		If TableRow.Contact = Undefined Then
			StringInteractionsContact              = Catalogs.StringContactInteractions.CreateItem();
			StringInteractionsContact.Description = TableRow.Presentation;
			StringInteractionsContact.Write();
			TableRow.Contact                        = StringInteractionsContact.Ref;
		EndIf;
	EndDo;
	
	Table.GroupBy("Contact");
	
	Table.Columns.Add("Interaction");
	Table.FillValues(DocumentObject.Ref, "Interaction");
	RecordSet.AdditionalProperties.Insert("CalculateReviewedItems", True);
	RecordSet.Load(Table);
	
	RecordSet.Write();
	
EndProcedure

// Fills data of the InteractionContacts information register for the passed interaction array.
//
// Parameters:
//  InteractionsArray - Array - an array, for which the contact data will be filled.
//  CalculateReviewedItems - Boolean - indicates whether it is necessary to calculate interaction contact states.
//
Procedure FillInteractionsArrayContacts(InteractionsArray, CalculateReviewedItems = False) Export

	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = "
	|SELECT DISTINCT
	|	MeetingParticipants.Ref AS Interaction,
	|	MeetingParticipants.Contact,
	|	MeetingParticipants.ContactPresentation AS ContactPresentation
	|INTO ContactsInformation
	|FROM
	|	Document.Meeting.Members AS MeetingParticipants
	|		LEFT JOIN InformationRegister.InteractionsContacts AS InteractionsContacts
	|		ON MeetingParticipants.Ref = InteractionsContacts.Interaction
	|WHERE
	|	MeetingParticipants.Ref IN
	|			(&InteractionsArray)
	|
	|UNION
	|
	|SELECT DISTINCT
	|	PlannedInteractionParticipants.Ref,
	|	PlannedInteractionParticipants.Contact,
	|	PlannedInteractionParticipants.ContactPresentation
	|FROM
	|	Document.PlannedInteraction.Members AS PlannedInteractionParticipants
	|		LEFT JOIN InformationRegister.InteractionsContacts AS InteractionsContacts
	|		ON PlannedInteractionParticipants.Ref = InteractionsContacts.Interaction
	|WHERE
	|	PlannedInteractionParticipants.Ref IN
	|			(&InteractionsArray)
	|
	|UNION
	|
	|SELECT DISTINCT
	|	PhoneCall.Ref,
	|	PhoneCall.SubscriberContact,
	|	PhoneCall.SubscriberPresentation
	|FROM
	|	Document.PhoneCall AS PhoneCall
	|		LEFT JOIN InformationRegister.InteractionsContacts AS InteractionsContacts
	|		ON (InteractionsContacts.Interaction = PhoneCall.Ref)
	|WHERE
	|	PhoneCall.Ref IN
	|			(&InteractionsArray)
	|
	|UNION
	|
	|SELECT DISTINCT
	|	SMSMessageRecipients.Ref,
	|	SMSMessageRecipients.Contact,
	|	SMSMessageRecipients.ContactPresentation
	|FROM
	|	Document.SMSMessage.Recipients AS SMSMessageRecipients
	|		LEFT JOIN InformationRegister.InteractionsContacts AS InteractionsContacts
	|		ON SMSMessageRecipients.Ref = InteractionsContacts.Interaction
	|WHERE
	|	SMSMessageRecipients.Ref IN
	|			(&InteractionsArray)
	|
	|UNION
	|
	|SELECT DISTINCT
	|	IncomingEmail.Ref,
	|	IncomingEmail.SenderContact,
	|	IncomingEmail.SenderPresentation
	|FROM
	|	Document.IncomingEmail AS IncomingEmail
	|		LEFT JOIN InformationRegister.InteractionsContacts AS InteractionsContacts
	|		ON (InteractionsContacts.Interaction = IncomingEmail.Ref)
	|WHERE
	|	IncomingEmail.Ref IN
	|			(&InteractionsArray)
	|
	|UNION
	|
	|SELECT DISTINCT
	|	EmailMessageOutgoingMessageRecipients.Ref,
	|	EmailMessageOutgoingMessageRecipients.Contact,
	|	EmailMessageOutgoingMessageRecipients.Presentation
	|FROM
	|	Document.OutgoingEmail.EmailRecipients AS EmailMessageOutgoingMessageRecipients,
	|	InformationRegister.InteractionsContacts AS InteractionsContacts
	|WHERE
	|	EmailMessageOutgoingMessageRecipients.Ref IN
	|			(&InteractionsArray)
	|
	|UNION
	|
	|SELECT DISTINCT
	|	EmailMessageOutgoingCCRecipients.Ref,
	|	EmailMessageOutgoingCCRecipients.Contact,
	|	EmailMessageOutgoingCCRecipients.Presentation
	|FROM
	|	Document.OutgoingEmail.CCRecipients AS EmailMessageOutgoingCCRecipients
	|WHERE
	|	EmailMessageOutgoingCCRecipients.Ref IN
	|			(&InteractionsArray)
	|
	|UNION
	|
	|SELECT DISTINCT
	|	EmailMessageOutgoingBCCRecipients.Ref,
	|	EmailMessageOutgoingBCCRecipients.Contact,
	|	EmailMessageOutgoingBCCRecipients.Presentation
	|FROM
	|	Document.OutgoingEmail.BccRecipients AS EmailMessageOutgoingBCCRecipients
	|		LEFT JOIN InformationRegister.InteractionsContacts AS InteractionsContacts
	|		ON EmailMessageOutgoingBCCRecipients.Ref = InteractionsContacts.Interaction
	|WHERE
	|	EmailMessageOutgoingBCCRecipients.Ref IN
	|			(&InteractionsArray)
	|
	|INDEX BY
	|	ContactPresentation
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	ContactsInformation.Interaction AS Interaction,
	|	CASE
	|		WHEN ContactsInformation.Contact = UNDEFINED
	|			THEN ISNULL(StringContactInteractions.Ref, UNDEFINED)
	|		ELSE ContactsInformation.Contact
	|	END AS Contact,
	|	ContactsInformation.ContactPresentation
	|FROM
	|	ContactsInformation AS ContactsInformation
	|		LEFT JOIN Catalog.StringContactInteractions AS StringContactInteractions
	|		ON ContactsInformation.ContactPresentation = StringContactInteractions.Description
	|TOTALS BY
	|	Interaction";
	
	Query.SetParameter("InteractionsArray", InteractionsArray);
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	SelectionInteraction = QueryResult.Select(QueryResultIteration.ByGroups);
	
	BeginTransaction();
	Try
		
		Lock = New DataLock;
		
		LockItem = Lock.Add("InformationRegister.InteractionsContacts");
		LockAreasTable = New ValueTable;
		LockAreasTable.Columns.Add("Interaction");
		For Each ArrayElement In InteractionsArray Do
			NewRow = LockAreasTable.Add();
			NewRow.Interaction = ArrayElement;
		EndDo;
		LockItem.DataSource = LockAreasTable;
		Lock.Lock();
		
		While SelectionInteraction.Next() Do
			DetailsSelection = SelectionInteraction.Select();
			
			RecordSet = InformationRegisters.InteractionsContacts.CreateRecordSet();
			RecordSet.Filter.Interaction.Set(SelectionInteraction.Interaction);
			
			While DetailsSelection.Next() Do
				
				NewRecord = RecordSet.Add();
				NewRecord.Interaction = SelectionInteraction.Interaction;
				If DetailsSelection.Contact <> Undefined Then
					NewRecord.Contact = DetailsSelection.Contact;
				Else
					StringInteractionsContact              = Catalogs.StringContactInteractions.CreateItem();
					StringInteractionsContact.Description = DetailsSelection.ContactPresentation;
					StringInteractionsContact.Write();
					NewRecord.Contact                         = StringInteractionsContact.Ref;
				EndIf;
				
			EndDo;
			
			If CalculateReviewedItems Then
				RecordSet.AdditionalProperties.Insert("CalculateReviewedItems", True);
			EndIf;
			
			RecordSet.Write();
			
		EndDo;
		
		CommitTransaction();
	
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndProcedure

// Deletes duplicate elements from the array.
//
Function DeleteDuplicateElementsFromArray(Array, DoNotUseUndefined = False) Export
	
	CatalogsTypesDetails  = Catalogs.AllRefsType(); 
	DocumentsTypesDetails    = Documents.AllRefsType(); 
	CCTTypesDetails          = ChartsOfCharacteristicTypes.AllRefsType(); 
	ChartsOfAccountsTypesDetails  = ChartsOfAccounts.AllRefsType(); 
	ChartsOfCalculationsTypesDetails = ChartsOfCalculationTypes.AllRefsType(); 
	
	If TypeOf(Array) = Type("Array") Then 
		
		AlreadyInArray 		   = New Map; 
		WasUndefined 	   = False;
		ArrayElementsCount = Array.Count(); 
		
		For ReverseIndex = 1 To ArrayElementsCount Do 
			
			ArrayElement = Array[ArrayElementsCount - ReverseIndex]; 
			ItemType    = TypeOf(ArrayElement); 
			
			If ArrayElement = Undefined Then
				
				If WasUndefined OR DoNotUseUndefined Then
					Array.Delete(ArrayElementsCount - ReverseIndex); 
				Else
					WasUndefined = True;
				EndIf;
				
				Continue;
				
			ElsIf CatalogsTypesDetails.ContainsType(ItemType) 
			 OR DocumentsTypesDetails.ContainsType(ItemType) 
			 OR CCTTypesDetails.ContainsType(ItemType) 
			 OR ChartsOfAccountsTypesDetails.ContainsType(ItemType) 
			 OR ChartsOfCalculationsTypesDetails.ContainsType(ItemType) Then 
				
				ElementID = String(ArrayElement.UUID()); 
				
			Else 
				
				ElementID = ArrayElement; 
				
			EndIf; 
			
			If AlreadyInArray[ElementID] = True Then 
				Array.Delete(ArrayElementsCount - ReverseIndex); 
			Else 
				AlreadyInArray[ElementID] = True; 
			EndIf; 
			
		EndDo;      
		
	EndIf;
	
	Return Array;
	
EndFunction

Procedure FillStatusSubmenu(SubmenuGroup, Form) Export
	
	If Not GetFunctionalOption("UseReviewedFlag") Then
		Return;
	EndIf;
	
	For each Status In StatusesList() Do
		
		Value = Status.Value;
		
		NewCommand = Form.Commands.Add("SetFilterStatus_" + Value);
		NewCommand.Action = "Attachable_ChangeFilterStatus";
		
		ItemButtonSubmenu = Form.Items.Add("SetFilterStatus_" + Value, Type("FormButton"), 
			SubmenuGroup);
		ItemButtonSubmenu.Type                   = FormButtonType.CommandBarButton;
		ItemButtonSubmenu.CommandName            = NewCommand.Name;
		ItemButtonSubmenu.Title             = Status.Presentation;
		ItemButtonSubmenu.OnlyInAllActions = True;
	
	EndDo;
	
EndProcedure

Procedure FillSubmenuByInteractionType(SubmenuGroup, Form) Export
	
	FiltersList = FiltersListByInteractionsType(Form.EmailOnly);
	For each Filter In FiltersList Do
		
		Value = Filter.Value;
		
		CommandName = "SetFilterInteractionType_" + Value;
		FoundCommand = Form.Commands.Find(CommandName);
		
		If FoundCommand = Undefined Then
			NewCommand = Form.Commands.Add("SetFilterInteractionType_" + Value);
			NewCommand.Action = "Attachable_ChangeFilterInteractionType";
		Else
			NewCommand = FoundCommand;
		EndIf;
		
		ItemButtonSubmenu = Form.Items.Add("SetFilterInteractionType_" + SubmenuGroup.Name + "_"+ Value, Type("FormButton"), SubmenuGroup);
		ItemButtonSubmenu.Type = FormButtonType.CommandBarButton;
		ItemButtonSubmenu.CommandName = NewCommand.Name;
		ItemButtonSubmenu.Title = Filter.Presentation;
		ItemButtonSubmenu.OnlyInAllActions = True;
		
	EndDo;
	
EndProcedure

Procedure ProcessFilterByInteractionsTypeSubmenu(Form) Export

	CaptionPattern = NStr("ru = 'Тип взаимодействий: %1'; en = 'Interaction type: %1'; pl = 'Interaction type: %1';de = 'Interaction type: %1';ro = 'Interaction type: %1';tr = 'Interaction type: %1'; es_ES = 'Interaction type: %1'");
	TypePresentation = FiltersListByInteractionsType(Form.EmailOnly).FindByValue(Form.InteractionType).Presentation;
	Form.Items.InteractionTypeList.Title = StringFunctionsClientServer.SubstituteParametersToString(CaptionPattern, TypePresentation);
	For Each SubmenuItem In Form.Items.InteractionTypeList.ChildItems Do
		If SubmenuItem.Name = ("SetFilterInteractionType_ListInteractionType_" + Form.InteractionType) Then
			SubmenuItem.Check = True;
		Else
			SubmenuItem.Check = False;
		EndIf;
	EndDo	

EndProcedure

Function NewEmailsByAccounts()
	
	Query = New Query;
	Query.Text =
	"SELECT ALLOWED
	|	COUNT(Interactions.Ref) AS EmailsCount,
	|	Interactions.Account AS Account
	|FROM
	|	DocumentJournal.Interactions AS Interactions
	|		LEFT JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsSubjects
	|		ON Interactions.Ref = InteractionsSubjects.Interaction
	|		LEFT JOIN Catalog.EmailAccounts AS EmailAccounts
	|		ON Interactions.Account = EmailAccounts.Ref
	|WHERE
	|	VALUETYPE(Interactions.Ref) = TYPE(Document.IncomingEmail)
	|	AND InteractionsSubjects.Reviewed = FALSE
	|	AND NOT EmailAccounts.Ref IS NULL
	|
	|GROUP BY
	|	Interactions.Account";
	
	Result = Query.Execute().Unload();
	
	Return Result;
	
EndFunction

Function ListOfAvailableSubjectsTypes() Export
	
	SubjectTypeChoiceList = New ValueList;

	For Each SubjectType In Metadata.DefinedTypes.InteractionSubject.Type.Types() Do
		
		SubjectTypeMetadata = Metadata.FindByType(SubjectType);
		If SubjectTypeMetadata = Undefined Then
			Continue;
		EndIf;
		
		If NOT Common.MetadataObjectAvailableByFunctionalOptions(SubjectTypeMetadata) Then
			Continue;
		EndIf;
		
		IsInteraction = InteractionsClientServer.IsInteraction(SubjectType);
		
		SubjectTypeChoiceList.Add(Metadata.FindByType(SubjectType).FullName(), String(SubjectType), IsInteraction);
		
	EndDo;
	
	Return SubjectTypeChoiceList;

EndFunction

Function SignatureFilesExtension()
	
	If Common.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		ModuleDigitalSignature = Common.CommonModule("DigitalSignature");
		Return ModuleDigitalSignature.PersonalSettings().SignatureFilesExtension;
	Else
		Return "p7s";
	EndIf;
	
EndFunction

Procedure ReplaceEmployeeResponsibleInDocument(Interaction, EmployeeResponsible) Export
	
	BeginTransaction();
	
	Try
		
		Lock = New DataLock;
		LockItem = Lock.Add(Metadata.FindByType(TypeOf(Interaction)).FullName());
		LockItem.SetValue("Ref", Interaction);
		Lock.Lock();
		
		Object = Interaction.GetObject();
		Object.EmployeeResponsible = EmployeeResponsible;
		Object.AdditionalProperties.Insert("DoNotSaveContacts", True);
		Object.Write();
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndProcedure

// Checks whether the catalog has a tabular section.
//
// Parameters:
//  CatalogName - String - a name of the catalog to be checked.
//  TabularSectionName - String - a name of the tabular section whose existence is being checked.
//
// Returns:
//  Boolean - True if a tabular section exists.
//
// Example:
//  If Not CatalogHasTabularSection(CatalogName,"ContactInformation") Then
//  	Return;
//  EndIf;
//
Function CatalogHasTabularSection(CatalogName, TabularSectionName)
	
	Return (Metadata.Catalogs[CatalogName].TabularSections.Find(TabularSectionName) <> Undefined);
	
EndFunction 

///////////////////////////////////////////////////////////////////////////////////
//  Message templates

// Generates a structure to write to the InteractionsFolderSubjects information register.
//
// Parameters:
//  Folder - Catalog.EmailsFolders - a folder makes sense for the "Incoming email" documents
//               and "Outgoing email message".
//  Subject - CatalogRef, DocumentRef, indicates an interaction subject.
//  Reviewed      - Boolean - indicates that interaction is reviewed.
//  ReviewAfter - DateTime - a date, until which the interaction is deferred.
//  CalculateReviewedItems - Boolean - indicates that it is necessary to calculate states of a folder and a subject.
//
// Returns:
//   Structure - a generated structure.
//
Function InteractionAttributesStructureForWrite(Topic, Reviewed)
	
	ReturnStructure = InformationRegisters.InteractionsFolderSubjects.InteractionAttributes();
	If Topic <> Undefined Then
		ReturnStructure.Topic = Topic;
	EndIf;
	If Reviewed <> Undefined Then
		ReturnStructure.Reviewed = Reviewed;
	EndIf;
	ReturnStructure.CalculateReviewedItems = True;
	Return ReturnStructure;
	
EndFunction

Function CommentByTemplateDescription(TemplateDescription)

	Return NStr("ru = 'Создано и отправлено по шаблону'; en = 'Created and sent from template'; pl = 'Created and sent from template';de = 'Created and sent from template';ro = 'Created and sent from template';tr = 'Created and sent from template'; es_ES = 'Created and sent from template'") + " - " + TemplateDescription;

EndFunction

////////////////////////////////////////////////////////////////////////////////
// Defining a referenec type.

// Determines whether a reference passed to the function is a contact or not.
//
// Parameters:
//  ObjectRef  - Ref - a reference, to which a check is being executed.
//
// Returns:
//   Boolean   - true if it is a contact, false otherwise.
//
Function IsContact(ObjectRef)
	
	PossibleContactsTypesDetails =  New TypeDescription(ContactsTypes());
	Return PossibleContactsTypesDetails.ContainsType(TypeOf(ObjectRef));
	
EndFunction

// Gets details of possible contacts and generates a type array out of it.
//
// Returns:
//   Array - possible contact types.
//
Function ContactsTypes() 
	
	ContactsDetails = InteractionsClientServer.ContactsDetails();
	Result = New Array;
	For each DetailsArrayElement In ContactsDetails Do
		Result.Add(DetailsArrayElement.Type);
	EndDo;
	Return Result;
	
EndFunction

Function FiltersListByInteractionsType(EmailOnly) Export
	
	FiltersList = New ValueList;
	
	FiltersList.Add("All", NStr("ru = 'Все'; en = 'All'; pl = 'All';de = 'All';ro = 'All';tr = 'All'; es_ES = 'All'"));
	FiltersList.Add("AllMessages", NStr("ru = 'Все письма'; en = 'All emails'; pl = 'All emails';de = 'All emails';ro = 'All emails';tr = 'All emails'; es_ES = 'All emails'"));
	If Not EmailOnly Then
		FiltersList.Add("Meetings", NStr("ru = 'Встречи'; en = 'Meetings'; pl = 'Meetings';de = 'Meetings';ro = 'Meetings';tr = 'Meetings'; es_ES = 'Meetings'"));
		FiltersList.Add("PhoneCalls", NStr("ru = 'Телефонные звонки'; en = 'Phone calls'; pl = 'Phone calls';de = 'Phone calls';ro = 'Phone calls';tr = 'Phone calls'; es_ES = 'Phone calls'"));
		FiltersList.Add("PlannedInteractions", NStr("ru = 'Запланированные взаимодействия'; en = 'Scheduled interactions'; pl = 'Scheduled interactions';de = 'Scheduled interactions';ro = 'Scheduled interactions';tr = 'Scheduled interactions'; es_ES = 'Scheduled interactions'"));
		FiltersList.Add("SMSMessages", NStr("ru = 'Сообщения SMS'; en = 'Text messages'; pl = 'Text messages';de = 'Text messages';ro = 'Text messages';tr = 'Text messages'; es_ES = 'Text messages'"));
	EndIf;
	FiltersList.Add("IncomingMessages", NStr("ru = 'Входящие'; en = 'Incoming'; pl = 'Incoming';de = 'Incoming';ro = 'Incoming';tr = 'Incoming'; es_ES = 'Incoming'"));
	FiltersList.Add("MessageDrafts", NStr("ru = 'Черновики'; en = 'Drafts'; pl = 'Drafts';de = 'Drafts';ro = 'Drafts';tr = 'Drafts'; es_ES = 'Drafts'"));
	FiltersList.Add("OutgoingMessages", NStr("ru = 'Исходящие'; en = 'Outgoing'; pl = 'Outgoing';de = 'Outgoing';ro = 'Outgoing';tr = 'Outgoing'; es_ES = 'Outgoing'"));
	FiltersList.Add("Sent", NStr("ru = 'Отправленные'; en = 'Sent'; pl = 'Sent';de = 'Sent';ro = 'Sent';tr = 'Sent'; es_ES = 'Sent'"));
	FiltersList.Add("DeletedMessages", NStr("ru = 'Удаленные'; en = 'DeletedItems'; pl = 'DeletedItems';de = 'DeletedItems';ro = 'DeletedItems';tr = 'DeletedItems'; es_ES = 'DeletedItems'"));
	If Not EmailOnly Then
		FiltersList.Add("OutgoingCalls", NStr("ru = 'Исходящие звонки'; en = 'Outgoing calls'; pl = 'Outgoing calls';de = 'Outgoing calls';ro = 'Outgoing calls';tr = 'Outgoing calls'; es_ES = 'Outgoing calls'"));
		FiltersList.Add("IncomingCalls", NStr("ru = 'Входящие звонки'; en = 'Incoming calls'; pl = 'Incoming calls';de = 'Incoming calls';ro = 'Incoming calls';tr = 'Incoming calls'; es_ES = 'Incoming calls'"));
	EndIf;
	
	Return FiltersList;
	
EndFunction

Function InteractionTypeByCommandName(CommandName, EmailOnly) Export
	
	FoundPosition = StrFind(CommandName, "_");
	If FoundPosition = 0 Then
		Return "All";
	EndIf;
	
	InteractionTypeString = Right(CommandName, StrLen(CommandName) - FoundPosition);
	If FiltersListByInteractionsType(EmailOnly).FindByValue(InteractionTypeString) = Undefined Then
		Return "All";
	EndIf;
	
	Return InteractionTypeString;
	
EndFunction

Function HTMLDocumentGenerationParametersOnEmailBasis(FillingData = Undefined) Export
	
	Result = New Structure;
	Result.Insert("Email");
	Result.Insert("TextType");
	Result.Insert("Text");
	Result.Insert("HTMLText");
	Result.Insert("TextTypeConversion");
	Result.Insert("Encoding", "");
	Result.Insert("ProcessPictures", False);
	Result.Insert("DisableExternalResources", True);
	
	If ValueIsFilled(FillingData) Then
		FillPropertyValues(Result, FillingData);
	EndIf;
	
	Return Result;
	
EndFunction

// Defines whether a phone number for an SMS message is entered correctly.
//
// Parameters:
//  PhoneNumber - String - a string with a phone number.
//
// Returns:
//   Boolean   - true if the number is entered correctly, false otherwise.
//
Function PhoneNumberSpecifiedCorrectly(PhoneNumber) Export
	
	PhoneNumberChars = "+1234567890";
	SeparatorsChars = "()- ";
	
	FormattedNumber = "";
	For Position = 1 To StrLen(PhoneNumber) Do
		Char = Mid(PhoneNumber, Position, 1);
		If Char = "+" AND Not IsBlankString(FormattedNumber) Then
			Return False;
		EndIf;
		If StrFind(PhoneNumberChars, Char) > 0 Then
			FormattedNumber = FormattedNumber + Char;
		ElsIf StrFind(SeparatorsChars, Char) = 0 Then
			Return False;
		EndIf;
	EndDo;
	
	If IsBlankString(FormattedNumber) Then
		Return False;
	EndIf;
	
	If StrLen(FormattedNumber) < 3 Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

// Generates a subject by a message text based on the first three words.
//
// Parameters:
//  MessageText  - String - a message text, on whose basis a subject is generated.
//
// Returns:
//   String   - a generated message subject.
//
Function SubjectByMessageText(MessageText) Export

	RowsArray = StrSplit(MessageText," ", False);
	MessageSubject = "";
	For Ind = 0 To RowsArray.Count() - 1 Do
		If Ind > 2 Then
			Break;
		EndIf;
		MessageSubject = MessageSubject + RowsArray[Ind] + " ";
	EndDo;
	
	Return Left(MessageSubject, StrLen(MessageSubject) - 1);

EndFunction

Function StatusesList() Export
	
	StatusesList = New ValueList;
	StatusesList.Add("All", NStr("ru = 'Все'; en = 'All'; pl = 'All';de = 'All';ro = 'All';tr = 'All'; es_ES = 'All'"));
	StatusesList.Add("ToReview", NStr("ru = 'К рассмотрению'; en = 'To review'; pl = 'To review';de = 'To review';ro = 'To review';tr = 'To review'; es_ES = 'To review'"));
	StatusesList.Add("Deferred", NStr("ru = 'Отложенные'; en = 'Deferred'; pl = 'Deferred';de = 'Deferred';ro = 'Deferred';tr = 'Deferred'; es_ES = 'Deferred'"));
	StatusesList.Add("Reviewed", NStr("ru = 'Рассмотренные'; en = 'Reviewed'; pl = 'Reviewed';de = 'Reviewed';ro = 'Reviewed';tr = 'Reviewed'; es_ES = 'Reviewed'"));
	
	Return StatusesList;
	
EndFunction

// Receives chain interactions by an interaction subject.
//
// Parameters:
//  Chain	 - Ref - an interaction subject to get interactions for.
//  Exclude - Ref - an interaction that should not be included in the resulting array.
//
// Returns:
//  Array - found interactions.
//
Function InteractionsFromChain(Chain, Exclude)
	
	Query = New Query;
	Query.Text = "SELECT
	|	InteractionsSubjects.Interaction AS Ref
	|FROM
	|	InformationRegister.InteractionsFolderSubjects AS InteractionsSubjects
	|WHERE
	|	InteractionsSubjects.Topic = &Topic
	|	" + ?(Exclude = Undefined,"","  AND InteractionsSubjects.Interaction <> &Exclude ");
	
	Query.SetParameter("Topic", Chain);
	Query.SetParameter("Exclude", Exclude);
	
	Return Query.Execute().Unload().UnloadColumn("Ref");
	
EndFunction

Function SignaturePagesPIcture(ShowPicture) Export

	Return ?(ShowPicture, PictureLib.ReviewedItemCount, New Picture);

EndFunction 

Function EmailPresentation(EmailSubject, EmailDate) Export
	
	Return StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = '%1 от %2'; en = '%1 from %2'; pl = '%1 from %2';de = '%1 from %2';ro = '%1 from %2';tr = '%1 from %2'; es_ES = '%1 from %2'"), 
		InteractionsClientServer.InteractionSubject(EmailSubject), Format(EmailDate, "DLF=D"));
	
EndFunction

Function HasExternalResources(DocumentHTML)
	
	If Not HasAbilityToFilterHTMLContent() Then
		Return False;
	EndIf;
	
	Filters = New Array;
	Filters.Add(FilterByAttribute("src", "^(http|https)://"));
	
	Filter = CombineFilters(Filters);
	FoundNodes = DocumentHTML.FindByFilter(ValueToJSON(Filter));
	
	Return FoundNodes.Count() > 0;
	
EndFunction

Procedure DisableUnsafeContent(DocumentHTML, DisableExternalResources = True)
	
	If Not HasAbilityToFilterHTMLContent() Then
		Return;
	EndIf;
	
	Filters = New Array;
	Filters.Add(FilterByNodeName("script"));
	Filters.Add(FilterByNodeName("link"));
	Filters.Add(FilterByNodeName("iframe"));
	Filters.Add(FilterByAttributeName("onerror"));
	Filters.Add(FilterByAttributeName("onmouseover"));
	Filters.Add(FilterByAttributeName("onmouseout"));
	Filters.Add(FilterByAttributeName("onclick"));
	Filters.Add(FilterByAttributeName("onload"));
	
	Filter = CombineFilters(Filters);
	DocumentHTML.DeleteByFilter(ValueToJSON(Filter));
	
	If DisableExternalResources Then
		Filter = FilterByAttribute("src", "^(http|https)://");
		FoundNodes = DocumentHTML.FindByFilter(ValueToJSON(Filter));
		For Each Node In FoundNodes Do
			Node.Value = "";
		EndDo;
	EndIf;
	
EndProcedure

Function FilterByNodeName(NodeName)
	
	Result = New Structure;
	Result.Insert("type", "elementname");
	Result.Insert("value", New Structure("value, operation", NodeName, "equals"));
	
	Return Result;
	
EndFunction

Function CombineFilters(Filters, CombinationType = "Or")
	
	If Filters.Count() = 1 Then
		Return Filters[0];
	EndIf;
	
	Result = New Structure;
	Result.Insert("type", ?(CombinationType = "AND", "intersection", "union"));
	Result.Insert("value", Filters);
	
	Return Result;
	
EndFunction

Function FilterByAttribute(AttributeName, ValueTemplate)
	
	Filters = New Array;
	Filters.Add(FilterByAttributeName(AttributeName));
	Filters.Add(FilterByAttributeValue(ValueTemplate));
	
	Result = CombineFilters(Filters, "AND");
	
	Return Result;
	
EndFunction

Function FilterByAttributeName(AttributeName)
	
	Result = New Structure;
	Result.Insert("type", "attribute");
	Result.Insert("value", New Structure("value, operation", AttributeName, "nameequals"));
	
	Return Result;
	
EndFunction

Function FilterByAttributeValue(ValueTemplate)
	
	Result = New Structure;
	Result.Insert("type", "attribute");
	Result.Insert("value", New Structure("value, operation", ValueTemplate, "valuematchesregex"));
	
	Return Result;
	
EndFunction

Function ValueToJSON(Value)
	
	JSONWriter = New JSONWriter;
	JSONWriter.SetString();
	WriteJSON(JSONWriter, Value);
	
	Return JSONWriter.Close();
	
EndFunction

Procedure FilterHTMLTextContent(HTMLText, Encoding = Undefined,
	DisableExternalResources = True, HasExternalResources = Undefined) Export
	
	DocumentHTML = GetHTMLDocumentObjectFromHTMLText(HTMLText, Encoding);
	HasExternalResources = HasExternalResources(DocumentHTML);
	DisableUnsafeContent(DocumentHTML, HasExternalResources AND DisableExternalResources);
	HTMLText = GetHTMLTextFromHTMLDocumentObject(DocumentHTML);
	
EndProcedure

Function UnsafeContentDisplayInEmailsProhibited() Export
	Return Constants.DenyDisplayingUnsafeContentInEmails.Get();
EndFunction

#EndRegion
