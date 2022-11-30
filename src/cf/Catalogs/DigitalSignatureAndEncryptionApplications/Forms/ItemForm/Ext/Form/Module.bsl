///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

&AtClient
Var SelectedApplicationDescription;

#EndRegion

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Common.IsSubordinateDIBNode() Then
		ReadOnly = True;
	EndIf;
	
	SettingsToSupply = Catalogs.DigitalSignatureAndEncryptionApplications.ApplicationsSettingsToSupply();
	For each SettingToSupply In SettingsToSupply Do
		Items.Description.ChoiceList.Add(SettingToSupply.Presentation);
	EndDo;
	Items.Description.ChoiceList.Add("", NStr("ru = '<Другая программа>'; en = '<Another application>'; pl = '<Another application>';de = '<Another application>';ro = '<Another application>';tr = '<Another application>'; es_ES = '<Another application>'"));
	
	// Filling in a new object by the supplied setting.
	If Not ValueIsFilled(Object.Ref) Then
		Filter = New Structure("ID", Parameters.SuppliedSettingID);
		Rows = SettingsToSupply.FindRows(Filter);
		If Rows.Count() > 0 Then
			FillPropertyValues(Object, Rows[0]);
			Object.Description = Rows[0].Presentation;
			Items.Description.ReadOnly = True;
			Items.ApplicationName.ReadOnly = True;
			Items.ApplicationType.ReadOnly = True;
		EndIf;
	EndIf;
	
	// Filling in the list of algorithms.
	Filter = New Structure("ApplicationName, ApplicationType", Object.ApplicationName, Object.ApplicationType);
	Rows = SettingsToSupply.FindRows(Filter);
	SettingToSupply = ?(Rows.Count() = 0, Undefined, Rows[0]);
	FillAlgorithmsChoiceLists(SettingToSupply);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	FillSelectedApplicationAlgorithms();
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// It is required to update the list of applications and their parameters on the server and on the 
	// client.
	RefreshReusableValues();
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_DigitalSignatureAndEncryptionSoftware", New Structure, Object.Ref);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	Query = New Query;
	Query.SetParameter("Ref", Object.Ref);
	Query.SetParameter("ApplicationName", Object.ApplicationName);
	Query.SetParameter("ApplicationType", Object.ApplicationType);
	Query.Text =
	"SELECT TOP 1
	|	TRUE AS TrueValue
	|FROM
	|	Catalog.DigitalSignatureAndEncryptionApplications AS DigitalSignatureAndEncryptionApplications
	|WHERE
	|	DigitalSignatureAndEncryptionApplications.Ref <> &Ref
	|	AND DigitalSignatureAndEncryptionApplications.ApplicationName = &ApplicationName
	|	AND DigitalSignatureAndEncryptionApplications.ApplicationType = &ApplicationType";
	
	If Not Query.Execute().IsEmpty() Then
		Cancel = True;
		Common.MessageToUser(
			NStr("ru = 'Программа с указанным именем и типом уже добавлена в список.'; en = 'Application with the specified name and type has already been added to the list.'; pl = 'Application with the specified name and type has already been added to the list.';de = 'Application with the specified name and type has already been added to the list.';ro = 'Application with the specified name and type has already been added to the list.';tr = 'Application with the specified name and type has already been added to the list.'; es_ES = 'Application with the specified name and type has already been added to the list.'"),
			,
			"Object.ApplicationName");
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DescriptionOnChange(Item)
	
	FillSelectedApplicationSettings(Object.Description);
	FillSelectedApplicationAlgorithms();
	
EndProcedure

&AtClient
Procedure DescriptionChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	If ValueSelected = "" Then
		Object.Description = "";
		Object.ApplicationName = "";
		Object.ApplicationType = 0;
		Object.SignAlgorithm = "";
		Object.HashAlgorithm = "";
		Object.EncryptAlgorithm = "";
	EndIf;
	
	SelectedApplicationDescription = ValueSelected;
	
	AttachIdleHandler("IdleHandlerDescriptionChoiceProcessing", 0.1, True);
	
EndProcedure

&AtClient
Procedure ApplicationNameOnChange(Item)
	
	FillSelectedApplicationAlgorithms();
	
EndProcedure

&AtClient
Procedure ApplicationTypeOnChange(Item)
	
	FillSelectedApplicationAlgorithms();
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure SetDeletionMark(Command)
	
	If Not Modified Then
		SetDeletionMarkCompletion();
		Return;
	EndIf;
	
	ShowQueryBox(
		New NotifyDescription("SetDeletionMarksAfterAnswerQuestion", ThisObject),
		NStr("ru = 'Для установки отметки удаления необходимо записать сделанные изменения.
		           |Записать данные?'; 
		           |en = 'To set the deletion mark, write the changes you have made.
		           |Write the data?'; 
		           |pl = 'To set the deletion mark, write the changes you have made.
		           |Write the data?';
		           |de = 'To set the deletion mark, write the changes you have made.
		           |Write the data?';
		           |ro = 'To set the deletion mark, write the changes you have made.
		           |Write the data?';
		           |tr = 'To set the deletion mark, write the changes you have made.
		           |Write the data?'; 
		           |es_ES = 'To set the deletion mark, write the changes you have made.
		           |Write the data?'"), QuestionDialogMode.YesNo);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillSelectedApplicationSettings(Presentation)
	
	SettingsToSupply = Catalogs.DigitalSignatureAndEncryptionApplications.ApplicationsSettingsToSupply();
	
	SettingToSupply = SettingsToSupply.Find(Presentation, "Presentation");
	If SettingToSupply <> Undefined Then
		FillPropertyValues(Object, SettingToSupply);
		Object.Description = SettingToSupply.Presentation;
	EndIf;
	
	FillAlgorithmsChoiceLists(SettingToSupply);
	
EndProcedure

&AtServer
Procedure FillAlgorithmsChoiceLists(SettingToSupply)
	
	SuppliedSignatureAlgorithms.Clear();
	SuppliedHashAlgorithms.Clear();
	SuppliedEncryptionAlgorithms.Clear();
	
	If SettingToSupply = Undefined Then
		Return;
	EndIf;
	
	SuppliedSignatureAlgorithms.LoadValues(SettingToSupply.SignAlgorithms);
	SuppliedHashAlgorithms.LoadValues(SettingToSupply.HashAlgorithms);
	SuppliedEncryptionAlgorithms.LoadValues(SettingToSupply.EncryptAlgorithms);
	
EndProcedure

&AtClient
Procedure FillSelectedApplicationAlgorithms()
	
	BeginAttachingCryptoExtension(New NotifyDescription(
		"FillAlgorithmsForSelectedApplicationAfterAttachCryptographyExtension", ThisObject));
	
EndProcedure

// Continues the FillSelectedApplicationAlgorithms procedure.
&AtClient
Procedure FillAlgorithmsForSelectedApplicationAfterAttachCryptographyExtension(Attached, Context) Export
	
	If Not Attached Then
		FillSelectedApplicationAlgorithmsAfterGetInformation(Undefined, Context);
		Return;
	EndIf;
	
	If Not CommonClient.IsWindowsClient() Then
		PersonalSettings = DigitalSignatureClient.PersonalSettings();
		ApplicationPath = PersonalSettings.PathsToDigitalSignatureAndEncryptionApplications.Get(
			Object.Ref);
	Else
		ApplicationPath = "";
	EndIf;
	
	CryptoTools.BeginGettingCryptoModuleInformation(New NotifyDescription(
			"FillSelectedApplicationAlgorithmsAfterGetInformation", ThisObject, ,
			"FillAlgorithmsForSelectedApplicationAfterGetDataError", ThisObject),
		Object.ApplicationName, ApplicationPath, Object.ApplicationType);
	
EndProcedure

// Continues the FillSelectedApplicationAlgorithms procedure.
&AtClient
Procedure FillAlgorithmsForSelectedApplicationAfterGetDataError(ErrorInformation, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	
	FillSelectedApplicationAlgorithmsAfterGetInformation(Undefined, Context);
	
EndProcedure

// Continues the FillSelectedApplicationAlgorithms procedure.
&AtClient
Procedure FillSelectedApplicationAlgorithmsAfterGetInformation(ModuleInformation, Context) Export
	
	// If the crypto manager is not available and not from the supplied ones, algorithm names are filled 
	// in manually.
	
	If ModuleInformation <> Undefined
	   AND Object.ApplicationName <> ModuleInformation.Name
	   AND CommonClient.IsWindowsClient() Then
		
		ModuleInformation = Undefined;
	EndIf;
	
	If ModuleInformation = Undefined Then
		Items.SignAlgorithm.ChoiceList.LoadValues(
			SuppliedSignatureAlgorithms.UnloadValues());
		
		Items.HashAlgorithm.ChoiceList.LoadValues(
			SuppliedHashAlgorithms.UnloadValues());
		
		Items.EncryptAlgorithm.ChoiceList.LoadValues(
			SuppliedEncryptionAlgorithms.UnloadValues());
	Else
		Items.SignAlgorithm.ChoiceList.LoadValues(
			New Array(ModuleInformation.SignAlgorithms));
		
		Items.HashAlgorithm.ChoiceList.LoadValues(
			New Array(ModuleInformation.HashAlgorithms));
		
		Items.EncryptAlgorithm.ChoiceList.LoadValues(
			New Array(ModuleInformation.EncryptAlgorithms));
	EndIf;
	
	Items.SignAlgorithm.DropListButton =
		Items.SignAlgorithm.ChoiceList.Count() <> 0;
	
	Items.HashAlgorithm.DropListButton =
		Items.HashAlgorithm.ChoiceList.Count() <> 0;
	
	Items.EncryptAlgorithm.DropListButton =
		Items.EncryptAlgorithm.ChoiceList.Count() <> 0;
	
EndProcedure

&AtClient
Procedure SetDeletionMarksAfterAnswerQuestion(Response, Context) Export
	
	If Response <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	If Not Write() Then
		Return;
	EndIf;
	
	SetDeletionMarkCompletion();
	
EndProcedure
	
&AtClient
Procedure SetDeletionMarkCompletion()
	
	Object.DeletionMark = Not Object.DeletionMark;
	Write();
	
	Notify("Write_DigitalSignatureAndEncryptionSoftware", New Structure, Object.Ref);
	
EndProcedure

// Continues the DescriptionChoiceProcessing procedure.
&AtClient
Procedure IdleHandlerDescriptionChoiceProcessing()
	
	FillSelectedApplicationSettings(SelectedApplicationDescription);
	FillSelectedApplicationAlgorithms();
	
EndProcedure

#EndRegion
