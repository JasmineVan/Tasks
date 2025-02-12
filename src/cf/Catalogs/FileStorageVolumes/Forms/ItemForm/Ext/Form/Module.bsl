﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

&AtClient
Var CurrentWriteParameters;

#EndRegion

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Object.Ref.IsEmpty() Then
		Object.FillOrder = FindMaxOrder() + 1;
	Else
		Items.FullPathLinux.WarningOnEditRepresentation
			= WarningOnEditRepresentation.Show;
		
		Items.FullPathWindows.WarningOnEditRepresentation
			= WarningOnEditRepresentation.Show;
		
		CurrentSizeInBytes = FilesOperationsInternal.CalculateFileSizeInVolume(
			Object.Ref);
			
		ActualSize = CurrentSizeInBytes / (1024 * 1024);
		If ActualSize = 0 AND CurrentSizeInBytes <> 0 Then
			ActualSize = 1;
		EndIf;
	EndIf;
	
	If Common.IsWindowsServer() Then 
		
		Items.FullPathWindows.AutoMarkIncomplete = True;
	Else
		Items.FullPathLinux.AutoMarkIncomplete = True;
	EndIf;
	
	If Common.IsMobileClient() Then
		Items.Description.TitleLocation = FormItemTitleLocation.Top;
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	Notification = New NotifyDescription("WriteAndCloseNotification", ThisObject);
	CommonClient.ShowFormClosingConfirmation(Notification, Cancel, Exit);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If Not WriteParameters.Property("ExternalResourcesAllowed") Then
		Cancel = True;
		CurrentWriteParameters = WriteParameters;
		AttachIdleHandler("AllowExternalResourceBeginning", 0.1, True);
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If ValueIsFilled(NewRef) AND CurrentObject.IsNew() Then
		CurrentObject.SetNewObjectRef(NewRef);
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	If WriteParameters.Property("WriteAndClose") Then
		Close();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	CurrentObject = FormAttributeToValue("Object");
	
	If FillCheckAlreadyExecuted Then
		FillCheckAlreadyExecuted = False;
		CurrentObject.AdditionalProperties.Insert("SkipBasicFillingCheck");
	Else
		CurrentObject.AdditionalProperties.Insert("SkipDirectoryAccessCheck");
	EndIf;
	
	CheckedAttributes.Clear();
	
	If Not CurrentObject.CheckFilling() Then
		Cancel = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FullPathWindowsOnChange(Item)
	
	// Deleting extra spaces and adding a slash at the end if it is missing.
	If Not IsBlankString(Object.FullPathWindows) Then
		
		If StrStartsWith(Object.FullPathWindows, " ") Or StrEndsWith(Object.FullPathWindows, " ") Then
			Object.FullPathWindows = TrimAll(Object.FullPathWindows);
		EndIf;
		
		If Not StrEndsWith(Object.FullPathWindows, "\") Then
			Object.FullPathWindows = Object.FullPathWindows + "\";
		EndIf;
		
		If StrEndsWith(Object.FullPathWindows, "\\") Then
			Object.FullPathWindows = Left(Object.FullPathWindows, StrLen(Object.FullPathWindows) - 1);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FullPathLinuxOnChange(Item)
	
	// Deleting extra spaces and adding a slash at the end if it is missing.
	If Not IsBlankString(Object.FullPathLinux) Then
		
		If StrStartsWith(Object.FullPathLinux, " ") Or StrEndsWith(Object.FullPathLinux, " ") Then
			Object.FullPathLinux = TrimAll(Object.FullPathLinux);
		EndIf;
		
		If Not StrEndsWith(Object.FullPathLinux, "/") Then
			Object.FullPathLinux = Object.FullPathLinux + "/";
		EndIf;
		
		If StrEndsWith(Object.FullPathLinux, "//") Then
			Object.FullPathLinux = Left(Object.FullPathLinux, StrLen(Object.FullPathLinux) - 1);
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure WriteAndClose(Command)
	
	Write(New Structure("WriteAndClose"));
	
EndProcedure

&AtClient
Procedure CheckVolumeIntegrity(Command)
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	If NOT ValueIsFilled(Object.Ref) Then
			QuestionText = NStr("ru = 'Для выполнения проверки целостности требуется записать сведения о томе.
					|Записать?'; 
					|en = 'To proceed with the integrity check, please save the volume data.
					|Do you want to save the data?'; 
					|pl = 'Dla weryfikacji integralności jest konieczne zapisanie informacji o woluminie.
					|Zapisać?';
					|de = 'Um die Integritätsprüfung durchzuführen, ist es notwendig, die Datenträgerinformationen aufzuschreiben.
					|Aufschreiben?';
					|ro = 'Pentru verificarea integrității trebuie să înregistrați datele despre volum.
					|Înregistrați?';
					|tr = 'Bütünlük denetimi gerçekleştirmek için birim bilgilerini yazmanız gerekir. 
					|Kaydedilsin mi?'; 
					|es_ES = 'Para comprobar la integridad se requiere guardar la información del tomo.
					|¿Guardar?'");
			Notification = New NotifyDescription("WriteFormRequiredToCheckVolumeIntegrity", ThisObject);
			ShowQueryBox(Notification, QuestionText, QuestionDialogMode.YesNo);
	Else
		RunVolumeIntegrityCheck();
	EndIf;
	
EndProcedure

&AtClient
Procedure DeleteUnnecessaryFiles(Command)
	OpeningParameters = New Structure("FileStorageVolume", Object.Ref);
	OpenForm("Catalog.FileStorageVolumes.Form.DeleteUnnecessaryFilesFromVolume", OpeningParameters, ThisObject);
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure WriteFormRequiredToCheckVolumeIntegrity(Write, AdditionalParameters) Export
	
	If Write = DialogReturnCode.Yes Then
		WriteAtServer();
		RunVolumeIntegrityCheck();
	EndIf;
	
EndProcedure

&AtClient
Procedure RunVolumeIntegrityCheck()
	
	ReportParameters = New Structure();
	ReportParameters.Insert("GenerateOnOpen", True);
	ReportParameters.Insert("Filter", New Structure("Volume", Object.Ref));
	
	OpenForm("Report.VolumeIntegrityCheck.ObjectForm", ReportParameters);

EndProcedure

&AtClient
Procedure WriteAndCloseNotification(Result, Context) Export
	
	Write(New Structure("WriteAndClose"));
	
EndProcedure

// Finds maximum order among the volumes.
&AtServer
Function FindMaxOrder()
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	MAX(Volumes.FillOrder) AS MaxNumber
	|FROM
	|	Catalog.FileStorageVolumes AS Volumes";
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		If Selection.MaxNumber = Null Then
			Return 0;
		Else
			Return Number(Selection.MaxNumber);
		EndIf;
	EndIf;
	
	Return 0;
	
EndFunction

&AtClient
Procedure AllowExternalResourceBeginning()
	
	If CommonClient.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		ExternalResourceQueries = New Array;
		If Not CheckFillingAtServer(ExternalResourceQueries) Then
			Return;
		EndIf;
		
		ClosingNotification = New NotifyDescription(
			"AllowExternalResourceCompletion", ThisObject, CurrentWriteParameters);
		ModuleSafeModeManagerClient = CommonClient.CommonModule("SafeModeManagerClient");
		ModuleSafeModeManagerClient.ApplyExternalResourceRequests(ExternalResourceQueries, ThisObject, ClosingNotification);
	EndIf;
	
EndProcedure

&AtServer
Function CheckFillingAtServer(ExternalResourceQueries)
	
	If Not CheckFilling() Then
		Return False;
	EndIf;
	
	FillCheckAlreadyExecuted = True;
	
	If ValueIsFilled(Object.Ref) Then
		ObjectRef = Object.Ref;
	Else
		If Not ValueIsFilled(NewRef) Then
			NewRef = Catalogs.FileStorageVolumes.GetRef();
		EndIf;
		ObjectRef = NewRef;
	EndIf;
	
	ExternalResourceQueries.Add(
		Catalogs.FileStorageVolumes.RequestToUseExternalResourcesForVolume(
			ObjectRef, Object.FullPathWindows, Object.FullPathLinux));
	
	Return True;
	
EndFunction

&AtClient
Procedure AllowExternalResourceCompletion(Result, WriteParameters) Export
	
	If Result = DialogReturnCode.OK Then
		WriteParameters.Insert("ExternalResourcesAllowed");
		Write(WriteParameters);
	EndIf;
	
EndProcedure

&AtServer
Procedure WriteAtServer()
	Write();
EndProcedure

#EndRegion
