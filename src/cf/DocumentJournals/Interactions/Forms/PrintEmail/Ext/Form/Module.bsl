﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If NOT Parameters.Property("Email") Then
		Cancel = True;
		Return;
	EndIf;
	
	RestrictedExtensions = FilesOperationsInternal.DeniedExtensionsList();
	
	FillPropertyValues(ThisObject,Parameters,, "CloseOnChoice, CloseOnOwnerClose, ReadOnly");
	Email = Parameters.Email;
	
	Items.BaseEmailPrintGroup.Visible = DoNotCallPrintCommand;
	
	SetHTMLEmailText(Cancel);
	If Cancel Then
		Return;
	EndIf;
	
	GenerateFormTitle(Email);
	GenerateBaseEmailString();
	
	If Attachments.Count() > 0 AND DisplayEmailAttachments Then
		Items.Attachments.Visible = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure HTMLTextOnClick(Item, EventData, StandardProcessing)
	
	InteractionsClient.HTMLFieldOnClick(Item, EventData, StandardProcessing);
	
EndProcedure

&AtClient
Procedure HTMLTextDocumentGenerated(Item)
	
	If Not DoNotCallPrintCommand 
		AND Not PrintDialogFormOnOpenOpened Then
		Items.HTMLText.Document.execCommand("Print");
		PrintDialogFormOnOpenOpened = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure DecorationBaseEmailURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "OpenAttachment"
		AND EmailBasis <> Undefined Then
		
		ShowValue(, EmailBasis);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure WarningAboutUnsafeContentURLProcessing(Item, FormattedStringURL, StandardProcessing)
	If FormattedStringURL = "EnableUnsafeContent" Then
		StandardProcessing = False;
		EnableUnsafeContent = True;
		SetHTMLEmailText();;
	EndIf;
EndProcedure

#EndRegion

#Region AttachmentsFormTableItemsEventHandlers

&AtClient
Procedure AttachmentsChoice(Item, RowSelected, Field, StandardProcessing)
	
	OpenEmailAttachment();
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure PrintEmail(Command)
	
	Items.HTMLText.Document.execCommand("Print");
	
EndProcedure

&AtClient
Procedure OpenAttachment(Command)
	
	OpenEmailAttachment();
	
EndProcedure

&AtClient
Procedure SaveAttachment(Command)
	
	CurrentData = Items.Attachments.CurrentData;
	
	If CurrentData = Undefined Then
		
		Return;
		
	EndIf;
	
	FileNameParts = FileDescriptionAndExtensionByFileName(CurrentData.FileName);
	
	FileData = New Structure;
	FileData.Insert("BinaryFileDataRef",        CurrentData.AddressInTempStorage);
	FileData.Insert("RelativePath",                  "");
	FileData.Insert("UniversalModificationDate",       "");
	FileData.Insert("FileName",                           CurrentData.FileName);
	FileData.Insert("Description",                       FileNameParts.Description);
	FileData.Insert("Extension",                         FileNameParts.Extension);
	FileData.Insert("Size",                             CurrentData.Size);
	FileData.Insert("BeingEditedBy",                        Undefined);
	FileData.Insert("SignedWithDS",                         False);
	FileData.Insert("Encrypted",                         False);
	FileData.Insert("FileBeingEdited",                  False);
	FileData.Insert("CurrentUserEditsFile", False);
	
	FilesOperationsClient.SaveFileAs(FileData);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure OpenEmailAttachment()

	CurrentData = Items.Attachments.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.IsAttachmentEmail Then
		InteractionsClient.OpenAttachmentEmail(CurrentData.AddressInTempStorage, EmailAttachmentOpenParameters(), ThisObject);
		
	ElsIf ValueIsFilled(CurrentData.Ref) Then
		
		If InteractionsClient.IsEmail(CurrentData.Ref)
			Or InteractionsClientServer.IsFileEmail(CurrentData.FileName) Then
			InteractionsClient.OpenAttachmentEmail(CurrentData.Ref, EmailAttachmentOpenParameters(), ThisObject);
		Else
			EmailManagementClient.OpenAttachment(CurrentData.Ref, ThisObject);
		EndIf;
		
	Else
		#If Not WebClient Then
			If IsTempStorageURL(CurrentData.AddressInTempStorage) Then
				TempFolderName = GetTempFileName();
				CreateDirectory(TempFolderName);
				PathToFile = TempFolderName + "\" + CurrentData.FileName;
				BinaryData = GetFromTempStorage(CurrentData.AddressInTempStorage);
				BinaryData.Write(PathToFile);
			EndIf;
			FileSystemClient.OpenFile(PathToFile);
		#Else
			PathToFile = CurrentData.FileNameOnComputer;
			GetFile(PathToFile, CurrentData.FileName, True);
		#EndIf
	EndIf;

EndProcedure

&AtServer
Function EmptyTableRecipients()

	RowTypeDetails = New TypeDescription("String",,New StringQualifiers(100));
	
	TableRecipients = New ValueTable();
	TableRecipients.Columns.Add("Address", RowTypeDetails);
	TableRecipients.Columns.Add("Presentation", RowTypeDetails);
	
	Return TableRecipients;
	
EndFunction

&AtServer
Procedure FillAttachmentsAndGenerateHTMLTextBasedOnAttachmentEmail(AttachmentEmail)
	
	Attachments.Clear();
	AttachmentsWithIDs.Clear();
	
	EmailMessage = New InternetMailMessage;
	
	If IsTempStorageURL(AttachmentEmail) Then
		SourceData = GetFromTempStorage(AttachmentEmail);
	Else
		SourceData = FilesOperations.FileBinaryData(AttachmentEmail);
	EndIf;
	
	EmailMessage.SetSourceData(SourceData);
	
	If EmailMessage.ParseStatus = InternetMailMessageParseStatus.ErrorsDetected Then
		Common.MessageToUser(NStr("ru = 'Не удалось разобрать почтовое сообщение.'; en = 'Cannot parse the email message.'; pl = 'Cannot parse the email message.';de = 'Cannot parse the email message.';ro = 'Cannot parse the email message.';tr = 'Cannot parse the email message.'; es_ES = 'Cannot parse the email message.'"));
		Return;
	EndIf;
	
	EmailRecipients = EmptyTableRecipients();
	EmailManagement.FillInternetEmailAddresses(EmailRecipients, EmailMessage.To);
	CCRecipients  = EmptyTableRecipients();
	EmailManagement.FillInternetEmailAddresses(CCRecipients, EmailMessage.To);
	
	EmailStructure = New Structure("TextType, HTMLText, Text");
	EmailStructure.Insert("Encoding",                    EmailMessage.Encoding);
	EmailStructure.Insert("SenderPresentation",     EmailMessage.SenderName);
	EmailStructure.Insert("SenderAddress",             EmailMessage.From.Address);
	EmailStructure.Insert("Date",                         EmailMessage.PostingDate);
	EmailStructure.Insert("Subject",                         EmailMessage.Subject);
	EmailStructure.Insert("EmailRecipients",             EmailRecipients);
	EmailStructure.Insert("CCRecipients",              CCRecipients);
	UserAccountUsername = ?(IsBlankString(UserAccountUsername),
	                                 UserAccountUserNameOfEmailByAttachment(AttachmentEmail),
	                                 UserAccountUsername);
	EmailStructure.Insert("UserAccountUsername", UserAccountUsername);
	
	EmailSubject = EmailMessage.Subject;
	EmailDate = EmailMessage.PostingDate;
	
	For Each Attachment In EmailMessage.Attachments Do
		
		If NOT IsBlankString(Attachment.CID) 
			AND StrFind(EmailStructure.HTMLText, Attachment.Name) = 0 Then
			
			NewRow = AttachmentsWithIDs.Add();
			NewRow.Description              = Attachment.FileName;
			NewRow.Ref                    = PutToTempStorage(Attachment.Data, UUID);
			NewRow.EmailFileID = Attachment.CID;
			NewRow.Extension                = CommonClientServer.GetFileNameExtension(Attachment.FileName);
			
			Continue;
			
		EndIf;
		
		NewRow = Attachments.Add();
		NewRow.FileName = Attachment.FileName;
		Extension = CommonClientServer.GetFileNameExtension(NewRow.FileName);
		If TypeOf(Attachment.Data) = Type("BinaryData") Then
			
			NewRow.PictureIndex    = FilesOperationsInternalClientServer.GetFileIconIndex(Extension);
			AttachmentData                = Attachment.Data;
			NewRow.IsAttachmentEmail = EmailManagement.FileIsEmail(NewRow.FileName, AttachmentData);
			
		Else
			
			AttachmentData                = Attachment.Data.GetSourceData();
			NewRow.FileName          = Attachment.Data.Subject + ".eml";
			NewRow.PictureIndex    = FilesOperationsInternalClientServer.GetFileIconIndex("eml");
			NewRow.IsAttachmentEmail = True;
			
		EndIf;
		
		NewRow.AddressInTempStorage = PutToTempStorage(AttachmentData, UUID);
		NewRow.SizePresentation       = InteractionsClientServer.GetFileSizeStringPresentation(AttachmentData.Size());
		
	EndDo;
	
	EmailStructure.Insert("Attachments", AttachmentsWithIDs);
	
	EmailManagement.SetEmailText(EmailStructure, EmailMessage);
	
	GenerationParameters = Interactions.HTMLDocumentGenerationParametersOnEmailBasis(EmailStructure);
	GenerationParameters.Email = EmailStructure;
	GenerationParameters.DisableExternalResources = Not EnableUnsafeContent;
	
	DocumentHTML = Interactions.GenerateHTMLDocumentBasedOnEmail(GenerationParameters, HasUnsafeContent);
	
	Interactions.AddPrintFormHeaderToEmailBody(DocumentHTML, EmailStructure, True);
	
	If Attachments.Count() > 0 Then
		Interactions.AddAttachmentFooterToEmailBody(DocumentHTML, Attachments);
	EndIf;
	
	HTMLText = Interactions.GetHTMLTextFromHTMLDocumentObject(DocumentHTML);
	
EndProcedure

&AtServer
Function UserAccountUserNameOfEmailByAttachment(AttachmentEmail)
	
	Query = New Query;
	Query.Text = "
	|SELECT ALLOWED
	|	EmailAccounts.UserName AS UserName,
	|	EmailAccounts.Description
	|FROM
	|	Catalog.IncomingEmailAttachedFiles AS AttachedFilesInMessage
	|		INNER JOIN Document.IncomingEmail AS EmailMessage
	|			INNER JOIN Catalog.EmailAccounts AS EmailAccounts
	|			ON EmailMessage.Account = EmailAccounts.Ref
	|		ON AttachedFilesInMessage.FileOwner = EmailMessage.Ref
	|WHERE
	|	AttachedFilesInMessage.Ref = &Attachment";
	
	If TypeOf(AttachmentEmail) = Type("CatalogRef.OutgoingEmailAttachedFiles") Then
		
		Query.Text = StrReplace(Query.Text,
		                           "Catalog.IncomingEmailAttachedFiles",
		                           "Catalog.OutgoingEmailAttachedFiles");
		Query.Text = StrReplace(Query.Text,
		                           "Document.IncomingEmail", 
		                           "Document.OutgoingEmail");
		
	ElsIf  TypeOf(AttachmentEmail) <> Type("CatalogRef.IncomingEmailAttachedFiles") Then
		Return "";
	EndIf;
	
	Query.SetParameter("Attachment", AttachmentEmail);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		Return ?(IsBlankString(Selection.UserName), Selection.Description, Selection.UserName);
	EndIf;
	
	Return "";
	
EndFunction

&AtServer
Procedure GenerateAttachmensTableForStoredEmail(Email)

	If Not DisplayEmailAttachments Then
		Return;
	EndIf;
	
	AttachmentTable = EmailManagement.GetEmailAttachments(Email, True, True);
	For Each AttachmentsTableRow In AttachmentTable Do
		If IsBlankString(AttachmentsTableRow.EmailFileID) Then
			NewRow = Attachments.Add();
			NewRow.Ref              = AttachmentsTableRow.Ref;
			NewRow.FileName            = AttachmentsTableRow.FileName;
			NewRow.PictureIndex      = AttachmentsTableRow.PictureIndex;
			NewRow.Size              = AttachmentsTableRow.Size;
			NewRow.SizePresentation = AttachmentsTableRow.SizePresentation;
		EndIf;
	EndDo;
	
	If TypeOf(Email) = Type("DocumentRef.OutgoingEmail") Then
		
		AttachmentEmailsTable = Interactions.DataStoredInAttachmentsEmailsDatabase(Email);
		
		For Each AttachmentEmail In AttachmentEmailsTable Do
			
			EmailPresentation = Interactions.EmailPresentation(AttachmentEmail.Subject, AttachmentEmail.Date);
			
			NewRow = Attachments.Add();
			NewRow.Ref               = AttachmentEmail.Email;
			NewRow.FileName             = EmailPresentation;
			NewRow.PictureIndex       = FilesOperationsInternalClientServer.GetFileIconIndex("eml");
			NewRow.SignedWithDS           = False;
			NewRow.Size               = AttachmentEmail.Size;
			NewRow.SizePresentation  = InteractionsClientServer.GetFileSizeStringPresentation(NewRow.Size)
			
		EndDo;
		
	EndIf;

	
	Attachments.Sort("FileName");

EndProcedure

&AtServer
Procedure GenerateFormTitle(Email)

	If NOT DoNotCallPrintCommand Then
		
		Return;
		
	EndIf;
	
	If TypeOf(Email) = Type("DocumentRef.IncomingEmail") Then
		
		EmailAttributes = Common.ObjectAttributesValues(Email, "DateReceived, Subject");
		EmailSubject = EmailAttributes.Subject;
		EmailDate = EmailAttributes.DateReceived;
		
	ElsIf TypeOf(Email) = Type("DocumentRef.OutgoingEmail") Then
		
		EmailAttributes = Common.ObjectAttributesValues(Email, "PostingDate, Date , Subject");
		EmailSubject = EmailAttributes.Subject;
		EmailDate = ?(ValueIsFilled(EmailAttributes.PostingDate), EmailAttributes.PostingDate, EmailAttributes.Date);
		
	EndIf;
	
	Title = Interactions.EmailPresentation(EmailSubject, EmailDate);
	
EndProcedure

&AtClient
Function EmailAttachmentOpenParameters()

	AttachmentParameters = InteractionsClient.EmptyStructureOfAttachmentEmailParameters();
	AttachmentParameters.BaseEmailDate = EmailDate;
	AttachmentParameters.BaseEmailSubject = EmailSubject;
	
	Return AttachmentParameters;

EndFunction

&AtServer
Procedure GenerateBaseEmailString();

	If NOT DoNotCallPrintCommand Then
		
		Return;
		
	EndIf;
	
	StringHeader = New FormattedString(NStr("ru = 'Вложение к письму:'; en = 'Email attachment:'; pl = 'Email attachment:';de = 'Email attachment:';ro = 'Email attachment:';tr = 'Email attachment:'; es_ES = 'Email attachment:'"));
	EmailPresentation = Interactions.EmailPresentation( BaseEmailSubject, BaseEmailDate);
	If EmailBasis = Undefined Then
		StringText = New FormattedString(EmailPresentation);
	Else
		StringText = New FormattedString(EmailPresentation, ,
			StyleColors.HyperlinkColor, , "OpenAttachment");
	EndIf;

	Items.BaseEmailDecoration.Title = New FormattedString(StringHeader, " ", StringText);
	
EndProcedure

&AtClient
Function FileDescriptionAndExtensionByFileName(Val FileName)
	
	Result = New Structure;
	Result.Insert("Extension",   "");
	Result.Insert("Description", "");
	
	RowsArray = StrSplit(FileName, ".", False);
	If RowsArray.Count() > 1 Then
		
		Result.Extension   = RowsArray[RowsArray.Count() - 1];
		Result.Description = Left(FileName, StrLen(FileName) - StrLen(Result.Extension) - 1);
	Else
		Result.Description = FileName;
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Procedure SetSecurityWarningVisiblity()
	UnsafeContentDisplayInEmailsProhibited = Interactions.UnsafeContentDisplayInEmailsProhibited();
	Items.SecurityWarning.Visible = Not UnsafeContentDisplayInEmailsProhibited
		AND HasUnsafeContent AND Not EnableUnsafeContent;
EndProcedure

&AtServer
Procedure SetHTMLEmailText(Cancel = Undefined)
	
	If TypeOf(Email) = Type("DocumentRef.IncomingEmail") Then
		
		HTMLText = Interactions.GenerateHTMLTextForIncomingEmail(Email, True, False, Not EnableUnsafeContent, HasUnsafeContent);
		GenerateAttachmensTableForStoredEmail(Email);
		
	ElsIf TypeOf(Email) = Type("DocumentRef.OutgoingEmail") Then
		
		HTMLText = Interactions.GenerateHTMLTextForOutgoingEmail(Email, True, False, Not EnableUnsafeContent, HasUnsafeContent);
		GenerateAttachmensTableForStoredEmail(Email);
		
	ElsIf TypeOf(Email) = Type("CatalogRef.IncomingEmailAttachedFiles")
		     Or TypeOf(Email) = Type("CatalogRef.OutgoingEmailAttachedFiles")
		     Or IsTempStorageURL(Email) Then
		
		FillAttachmentsAndGenerateHTMLTextBasedOnAttachmentEmail(Email);
		
	Else
		
		Cancel = True;
		
	EndIf;
	
	SetSecurityWarningVisiblity();
	
EndProcedure

#EndRegion
