///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

&AtClient
Var CommonInternalData;

&AtClient
Var OperationsContextsTempStorage;

#EndRegion

#Region EventHandlers

&AtClient
Procedure OnOpen(Cancel)
	
	CommonInternalData = New Map;
	Cancel = True;
	
	OperationsContextsTempStorage = New Map;
	AttachIdleHandler("DeleteObsoleteOperationsContexts", 300);
	
EndProcedure

#EndRegion

#Region Private

// CAC:78-off: to securely pass data between forms on the client without sending them to the server.
&AtClient
Procedure OpenNewForm(FormKind, ServerParameters, ClientParameters = Undefined,
			CompletionProcessing = Undefined, Val NewFormOwner = Undefined) Export
// CAC:78-on: to securely pass data between forms on the client without sending them to the server.
	
	FormsKinds =
		",DataSigning,DataEncryption,DataDecryption,
		|,SelectSigningOrDecryptionCertificate,CertificateCheck,";
	
	If StrFind(FormsKinds, "," + FormKind + ",") = 0 Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Ошибка в процедуре ОткрытьНовуюФорму. ВидФормы ""%1"" не поддерживается.'; en = 'An error occurred in the OpenNewForm procedure. ""%1"" FormKind is not supported.'; pl = 'An error occurred in the OpenNewForm procedure. ""%1"" FormKind is not supported.';de = 'An error occurred in the OpenNewForm procedure. ""%1"" FormKind is not supported.';ro = 'An error occurred in the OpenNewForm procedure. ""%1"" FormKind is not supported.';tr = 'An error occurred in the OpenNewForm procedure. ""%1"" FormKind is not supported.'; es_ES = 'An error occurred in the OpenNewForm procedure. ""%1"" FormKind is not supported.'"),
			FormKind);
	EndIf;
	
	If NewFormOwner = Undefined Then
		NewFormOwner = New UUID;
	EndIf;
	
	NewFormName = "Catalog.DigitalSignatureAndEncryptionKeysCertificates.Form." + FormKind;
	
	Context = New Structure;
	Form = OpenForm(NewFormName, ServerParameters, NewFormOwner,,,,
		New NotifyDescription("OpenNewFormClosingNotification", ThisObject, Context));
	
	If Form = Undefined Then
		If TypeOf(CompletionProcessing) = Type("NotifyDescription") Then
			ExecuteNotifyProcessing(CompletionProcessing, Undefined);
		EndIf;
		Return;
	EndIf;
	
	StandardSubsystemsClient.SetFormStorageOption(Form, True);
	
	Context.Insert("Form", Form);
	Context.Insert("CompletionProcessing", CompletionProcessing);
	Context.Insert("ClientParameters", ClientParameters);
	Context.Insert("Notification", New NotifyDescription("ExtendStoringOperationContext", ThisObject));
	
	Notification = New NotifyDescription("OpenNewFormFollowUp", ThisObject, Context);
	
	If ClientParameters = Undefined Then
		Form.ContinueOpening(Notification, CommonInternalData);
	Else
		Form.ContinueOpening(Notification, CommonInternalData, ClientParameters);
	EndIf;
	
EndProcedure

// Continues the OpenNewForm procedure.
&AtClient
Procedure OpenNewFormFollowUp(Result, Context) Export
	
	If Context.Form.IsOpen() Then
		Return;
	EndIf;
	
	UpdateFormStorage(Context);
	
	If TypeOf(Context.CompletionProcessing) = Type("NotifyDescription") Then
		ExecuteNotifyProcessing(Context.CompletionProcessing, Result);
	EndIf;
	
EndProcedure

// Continues the OpenNewForm procedure.
&AtClient
Procedure OpenNewFormClosingNotification(Result, Context) Export
	
	UpdateFormStorage(Context);
	
	If TypeOf(Context.CompletionProcessing) = Type("NotifyDescription") Then
		ExecuteNotifyProcessing(Context.CompletionProcessing, Result);
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateFormStorage(Context)
	
	StandardSubsystemsClient.SetFormStorageOption(Context.Form, False);
	Context.Form.OnCloseNotifyDescription = Undefined;
	
	If TypeOf(Context.ClientParameters) = Type("Structure")
	   AND Context.ClientParameters.Property("DataDetails")
	   AND TypeOf(Context.ClientParameters.DataDetails) = Type("Structure")
	   AND Context.ClientParameters.DataDetails.Property("OperationContext")
	   AND TypeOf(Context.ClientParameters.DataDetails.OperationContext) = Type("ManagedForm") Then
	
	#If WebClient Then
		ExtendStoringOperationContext(Context.ClientParameters.DataDetails.OperationContext);
	#EndIf
	EndIf;
	
EndProcedure

&AtClient
Procedure ExtendStoringOperationContext(Form) Export
	
	If TypeOf(Form) = Type("ManagedForm") Then
		OperationsContextsTempStorage.Insert(Form,
			New Structure("Form, Time", Form, CommonClient.SessionDate()));
	EndIf;
	
EndProcedure

&AtClient
Procedure DeleteObsoleteOperationsContexts()
	
	RefsToFormsToDelete = New Array;
	For Each KeyAndValue In OperationsContextsTempStorage Do
		
		If KeyAndValue.Value.Form.IsOpen() Then
			OperationsContextsTempStorage[KeyAndValue.Key].Time = CommonClient.SessionDate();
			
		ElsIf KeyAndValue.Value.Time + 15*60 < CommonClient.SessionDate() Then
			RefsToFormsToDelete.Add(KeyAndValue.Key);
		EndIf;
	EndDo;
	
	For Each Form In RefsToFormsToDelete Do
		OperationsContextsTempStorage.Delete(Form);
	EndDo;
	
EndProcedure

&AtClient
Procedure SetCertificatePassword(CertificateReference, Password, PasswordNote) Export // CAC:78 - an exception for secure password storage.
	
	SpecifiedPasswords = CommonInternalData.Get("SpecifiedPasswords");
	SpecifiedPasswordsNotes = CommonInternalData.Get("SpecifiedPasswordsExplanations");
	
	If SpecifiedPasswords = Undefined Then
		SpecifiedPasswords = New Map;
		CommonInternalData.Insert("SpecifiedPasswords", SpecifiedPasswords);
		SpecifiedPasswordsNotes = New Map;
		CommonInternalData.Insert("SpecifiedPasswordsExplanations", SpecifiedPasswordsNotes);
	EndIf;
	
	SpecifiedPasswords.Insert(CertificateReference, ?(Password = Undefined, Password, String(Password)));
	
	NewPasswordNote = New Structure;
	NewPasswordNote.Insert("NoteText", "");
	NewPasswordNote.Insert("HyperlinkNote", False);
	NewPasswordNote.Insert("ToolTipText", "");
	NewPasswordNote.Insert("ProcessAction", Undefined);
	
	If TypeOf(PasswordNote) = Type("Structure") Then
		FillPropertyValues(NewPasswordNote, PasswordNote);
	EndIf;
	
	SpecifiedPasswordsNotes.Insert(CertificateReference, NewPasswordNote);
	
EndProcedure

#EndRegion
