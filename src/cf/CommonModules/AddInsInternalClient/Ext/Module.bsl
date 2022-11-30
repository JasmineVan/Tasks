///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

Function IsComponentFromStorage(Location) Export
	
	Return StrStartsWith(Location, "e1cib/data/Catalog.AddIns.AddInStorage");
	
EndFunction

#EndRegion

#Region Private

#Region CheckAddInAvailability

Procedure CheckAddInAvailability(Notification, Context)
	
	Information = AddInInternalServerCall.SavedAddInInformation(
		Context.ID, 
		Context.Version);
	
	Context.Insert("Location", Information.Location);
	
	// Information.State:
	// * NotFound
	// * FoundInStorage
	// * FoundInSharedStorage
	// * DisabledByAdministrator
	
	Result = AddInAvailabilityResult();
	
	If Information.State = "DisabledByAdministrator" Then 
		
		Result.ErrorDescription = NStr("ru = 'Отключена администратором.'; en = 'Disabled by administrator.'; pl = 'Disabled by administrator.';de = 'Disabled by administrator.';ro = 'Disabled by administrator.';tr = 'Disabled by administrator.'; es_ES = 'Disabled by administrator.'");
		ExecuteNotifyProcessing(Notification, Result);
		
	ElsIf Information.State = "NotFound" Then 
		
		If Information.CanImportFromPortal 
			AND Context.SuggestToImport Then 
			
			SearchContext = New Structure;
			SearchContext.Insert("Notification", Notification);
			SearchContext.Insert("Context", Context);
			
			NotificationForms = New NotifyDescription(
				"CheckAddInAvailabilityAfterSearchingAddInOnPortal", 
				ThisObject, 
				SearchContext);
			
			ComponentSearchOnPortal(NotificationForms, Context);
			
		Else 
			Result.ErrorDescription = NStr("ru = 'Компонента не найдена в хранилище.'; en = 'Add-in is not found in the storage.'; pl = 'Add-in is not found in the storage.';de = 'Add-in is not found in the storage.';ro = 'Add-in is not found in the storage.';tr = 'Add-in is not found in the storage.'; es_ES = 'Add-in is not found in the storage.'");
			ExecuteNotifyProcessing(Notification, Result);
		EndIf;
		
	Else
		
		If CurrentClientIsSupportedByAddIn(Information.Attributes) Then
			
			Result.Available = True;
			ExecuteNotifyProcessing(Notification, Result);
			
		Else 
			
			NotificationForms = New NotifyDescription(
				"CheckAddInAvailabilityAfterDisplayingAvailableClientTypes", 
				ThisObject, 
				Notification);
			
			FormParameters = New Structure;
			FormParameters.Insert("NoteText", Context.NoteText);
			FormParameters.Insert("SupportedClients", Information.Attributes);
			
			OpenForm("CommonForm.CannotInstallAddIn", 
				FormParameters,,,,, NotificationForms);
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure CheckAddInAvailabilityAfterSearchingAddInOnPortal(Imported, SearchContext) Export
	
	Notification = SearchContext.Notification;
	Context   = SearchContext.Context;
	
	If Imported Then
		Context.SuggestToImport = False;
		CheckAddInAvailability(Notification, Context);
	Else 
		ExecuteNotifyProcessing(Notification, AddInAvailabilityResult());
	EndIf;
	
EndProcedure

Procedure CheckAddInAvailabilityAfterDisplayingAvailableClientTypes(Result, Notification) Export
	
	ExecuteNotifyProcessing(Notification, AddInAvailabilityResult());
	
EndProcedure

Function AddInAvailabilityResult()
	
	Result = New Structure;
	Result.Insert("Available", False);
	Result.Insert("ErrorDescription");
	
	Return Result;
	
EndFunction

Function CurrentClientIsSupportedByAddIn(Attributes)
	
	SystemInfo = New SystemInfo;
	
	Browser = Undefined;
#If WebClient Then
	Row = SystemInfo.UserAgentInformation;
	
	If StrFind(Row, "Chrome/") > 0 Then
		Browser = "Chrome";
	ElsIf StrFind(Row, "MSIE") > 0 Then
		Browser = "MSIE";
	ElsIf StrFind(Row, "Safari/") > 0 Then
		Browser = "Safari";
	ElsIf StrFind(Row, "Firefox/") > 0 Then
		Browser = "Firefox";
	EndIf;
#EndIf
	
	If SystemInfo.PlatformType = PlatformType.Linux_x86 Then
		
		If Browser = Undefined Then
			Return Attributes.Linux_x86;
		EndIf;
		
		If Browser = "Firefox" Then
			Return Attributes.Linux_x86_Firefox;
		EndIf;
		
		If Browser = "Chrome" Then
			Return Attributes.Linux_x86_Chrome;
		EndIf;
			
	ElsIf SystemInfo.PlatformType = PlatformType.Linux_x86_64 Then
		
		If Browser = Undefined Then
			Return Attributes.Linux_x86_64;
		EndIf;
		
		If Browser = "Firefox" Then
			Return Attributes.Linux_x86_64_Firefox;
		EndIf;
		
		If Browser = "Chrome" Then
			Return Attributes.Linux_x86_64_Chrome;
		EndIf;
		
	ElsIf SystemInfo.PlatformType = PlatformType.MacOS_x86_64 Then
		
		If Browser = "Safari" Then
			Return Attributes.MacOS_x86_64_Safari;
		EndIf;
		
	ElsIf SystemInfo.PlatformType = PlatformType.Windows_x86 Then
		
		If Browser = Undefined Then
			Return Attributes.Windows_x86;
		EndIf;
		
		If Browser = "Firefox" Then
			Return Attributes.Windows_x86_Firefox;
		EndIf;
		
		If Browser = "Chrome" Then
			Return Attributes.Windows_x86_Chrome;
		EndIf;
		
		If Browser = "MSIE" Then
			Return Attributes.Windows_x86_MSIE;
		EndIf;
		
	ElsIf SystemInfo.PlatformType = PlatformType.Windows_x86_64 Then
		
		If Browser = Undefined Then
			Return Attributes.Windows_x86_64;
		EndIf;
		
		If Browser = "Firefox" Then
			Return Attributes.Windows_x86_Firefox;
		EndIf;
		
		If Browser = "Chrome" Then
			Return Attributes.Windows_x86_Chrome;
		EndIf;
		
		If Browser = "MSIE" Then
			Return Attributes.Windows_x86_64_MSIE;
		EndIf;
		
	EndIf;
	
	Return False;
	
EndFunction

#EndRegion

#Region AttachAddInSSL

Procedure AttachAddInSSL(Context) Export 
	
	Notification = New NotifyDescription(
		"AttachAddInAfterAvailabilityCheck", 
		ThisObject, 
		Context);
	
	CheckAddInAvailability(Notification, Context);
	
EndProcedure

Procedure AttachAddInAfterAvailabilityCheck(Result, Context) Export
	
	If Result.Available Then 
		CommonInternalClient.AttachAddInSSL(Context);
	Else
		If Not IsBlankString(Result.ErrorDescription) Then 
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось подключить внешнюю компоненту ""%1"" на клиенте
				           |из хранилища внешних компонент
				           |по причине:
				           |%2'; 
				           |en = 'Cannot attach the ""%1"" add-in
				           |on the client from the add-in storage.
				           |Reason:
				           |%2'; 
				           |pl = 'Cannot attach the ""%1"" add-in
				           |on the client from the add-in storage.
				           |Reason:
				           |%2';
				           |de = 'Cannot attach the ""%1"" add-in
				           |on the client from the add-in storage.
				           |Reason:
				           |%2';
				           |ro = 'Cannot attach the ""%1"" add-in
				           |on the client from the add-in storage.
				           |Reason:
				           |%2';
				           |tr = 'Cannot attach the ""%1"" add-in
				           |on the client from the add-in storage.
				           |Reason:
				           |%2'; 
				           |es_ES = 'Cannot attach the ""%1"" add-in
				           |on the client from the add-in storage.
				           |Reason:
				           |%2'"),
				Context.ID,
				Result.ErrorDescription);
		EndIf;
		
		CommonInternalClient.AttachAddInSSLNotifyOnError(ErrorText, Context);
	EndIf;
	
EndProcedure

#EndRegion

#Region AttachAddInFromWindowsRegistry

// See the AddInClient.AttachAddInFromWindowsRegistry function.
//
Procedure AttachAddInFromWindowsRegistry(Context) Export
	
	If AttachAddInFromWindowsRegistryAttachmentAvailable() Then
		
		Notification = New NotifyDescription(
		"AttachAddInFromWindowsRegistryAfterAttachmentAttempt", ThisObject, Context,
		"AttachAddInFromWIndowsRegisterOnProcessError", ThisObject);
		
		BeginAttachingAddIn(Notification, "AddIn." + Context.ID);
		
	Else 
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось подключить внешнюю компоненту ""%1"" на клиенте
			           |из реестра Windows
			           |по причине:
			           |Подключить компоненту из реестра Windows возможно только в тонком или толстом клиентах Windows.'; 
			           |en = 'Cannot attach the ""%1"" add-in
			           |on the client from Windows registry.
			           |Reason:
			           |Attaching add-ins from Windows is allowed only in the thin and thick clients.'; 
			           |pl = 'Cannot attach the ""%1"" add-in
			           |on the client from Windows registry.
			           |Reason:
			           |Attaching add-ins from Windows is allowed only in the thin and thick clients.';
			           |de = 'Cannot attach the ""%1"" add-in
			           |on the client from Windows registry.
			           |Reason:
			           |Attaching add-ins from Windows is allowed only in the thin and thick clients.';
			           |ro = 'Cannot attach the ""%1"" add-in
			           |on the client from Windows registry.
			           |Reason:
			           |Attaching add-ins from Windows is allowed only in the thin and thick clients.';
			           |tr = 'Cannot attach the ""%1"" add-in
			           |on the client from Windows registry.
			           |Reason:
			           |Attaching add-ins from Windows is allowed only in the thin and thick clients.'; 
			           |es_ES = 'Cannot attach the ""%1"" add-in
			           |on the client from Windows registry.
			           |Reason:
			           |Attaching add-ins from Windows is allowed only in the thin and thick clients.'"),
		Context.ID);
		
		CommonInternalClient.AttachAddInSSLNotifyOnError(ErrorText, Context);
		
	EndIf;
	
EndProcedure

// Continues the AttachAddInFromWindowsRegistry procedure.
Procedure AttachAddInFromWindowsRegistryAfterAttachmentAttempt(Attached, Context) Export
	
	If Attached Then 
		
		ObjectCreationID = Context.ObjectCreationID;
			
		If ObjectCreationID = Undefined Then 
			ObjectCreationID = Context.ID;
		EndIf;
		
		Try
			AttachableModule = New("AddIn." + ObjectCreationID);
			If AttachableModule = Undefined Then 
				Raise NStr("ru = 'Оператор Новый вернул Неопределено'; en = 'The New operator returned Undefined'; pl = 'The New operator returned Undefined';de = 'The New operator returned Undefined';ro = 'The New operator returned Undefined';tr = 'The New operator returned Undefined'; es_ES = 'The New operator returned Undefined'");
			EndIf;
		Except
			AttachableModule = Undefined;
			ErrorText = BriefErrorDescription(ErrorInfo());
		EndTry;
		
		If AttachableModule = Undefined Then 
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось создать объект внешней компоненты ""%1"", подключенной на клиенте
				           |из реестра Windows,
				           |по причине:
				           |%2'; 
				           |en = 'Cannot create object of the ""%1"" add-in attached on the client
				           |from Windows registry.
				           |Reason:
				           |%2'; 
				           |pl = 'Cannot create object of the ""%1"" add-in attached on the client
				           |from Windows registry.
				           |Reason:
				           |%2';
				           |de = 'Cannot create object of the ""%1"" add-in attached on the client
				           |from Windows registry.
				           |Reason:
				           |%2';
				           |ro = 'Cannot create object of the ""%1"" add-in attached on the client
				           |from Windows registry.
				           |Reason:
				           |%2';
				           |tr = 'Cannot create object of the ""%1"" add-in attached on the client
				           |from Windows registry.
				           |Reason:
				           |%2'; 
				           |es_ES = 'Cannot create object of the ""%1"" add-in attached on the client
				           |from Windows registry.
				           |Reason:
				           |%2'"),
				Context.ID,
				ErrorText);
				
			CommonInternalClient.AttachAddInSSLNotifyOnError(ErrorText, Context);
			
		Else 
			CommonInternalClient.AttachAddInSSLNotifyOnAttachment(AttachableModule, Context);
		EndIf;
		
	Else 
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось подключить внешнюю компоненту ""%1"" на клиенте
			           |из реестра Windows
			           |по причине:
			           |Метод НачатьПодключениеВнешнейКомпоненты вернул Ложь.'; 
			           |en = 'Cannot attach the ""%1"" add-in on the client
			           |from Windows registry.
			           |Reason:
			           |The  BeginAttachingAddIn method returned False.'; 
			           |pl = 'Cannot attach the ""%1"" add-in on the client
			           |from Windows registry.
			           |Reason:
			           |The  BeginAttachingAddIn method returned False.';
			           |de = 'Cannot attach the ""%1"" add-in on the client
			           |from Windows registry.
			           |Reason:
			           |The  BeginAttachingAddIn method returned False.';
			           |ro = 'Cannot attach the ""%1"" add-in on the client
			           |from Windows registry.
			           |Reason:
			           |The  BeginAttachingAddIn method returned False.';
			           |tr = 'Cannot attach the ""%1"" add-in on the client
			           |from Windows registry.
			           |Reason:
			           |The  BeginAttachingAddIn method returned False.'; 
			           |es_ES = 'Cannot attach the ""%1"" add-in on the client
			           |from Windows registry.
			           |Reason:
			           |The  BeginAttachingAddIn method returned False.'"),
			Context.ID);
			
		CommonInternalClient.AttachAddInSSLNotifyOnError(ErrorText, Context);
		
	EndIf;
	
EndProcedure

// Continues the AttachAddInFromWindowsRegistry procedure.
Procedure AttachAddInFromWIndowsRegisterOnProcessError(ErrorInformation, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	
	ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Не удалось подключить внешнюю компоненту ""%1"" на клиенте
		           |из реестра Windows
		           |по причине:
		           |%2'; 
		           |en = 'Cannot attach the ""%1"" add-in on the client
		           |from Windows registry.
		           |Reason:
		           |%2'; 
		           |pl = 'Cannot attach the ""%1"" add-in on the client
		           |from Windows registry.
		           |Reason:
		           |%2';
		           |de = 'Cannot attach the ""%1"" add-in on the client
		           |from Windows registry.
		           |Reason:
		           |%2';
		           |ro = 'Cannot attach the ""%1"" add-in on the client
		           |from Windows registry.
		           |Reason:
		           |%2';
		           |tr = 'Cannot attach the ""%1"" add-in on the client
		           |from Windows registry.
		           |Reason:
		           |%2'; 
		           |es_ES = 'Cannot attach the ""%1"" add-in on the client
		           |from Windows registry.
		           |Reason:
		           |%2'"),
		Context.ID,
		BriefErrorDescription(ErrorInformation));
		
	CommonInternalClient.AttachAddInSSLNotifyOnError(ErrorText, Context);
	
EndProcedure

// Continues the AttachAddInFromWindowsRegistry procedure.
Function AttachAddInFromWindowsRegistryAttachmentAvailable()
	
#If WebClient Then
	Return False;
#Else
	Return CommonClient.IsWindowsClient();
#EndIf
	
EndFunction

#EndRegion

#Region InstallAddInSSL

Procedure InstallAddInSSL(Context) Export
	
	Notification = New NotifyDescription(
		"InstallAddInAfterAvailabilityCheck", 
		ThisObject, 
		Context);
	
	CheckAddInAvailability(Notification, Context);
	
EndProcedure

Procedure InstallAddInAfterAvailabilityCheck(Result, Context) Export
	
	If Result.Available Then 
		CommonInternalClient.InstallAddInSSL(Context);
	Else
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось подключить внешнюю компоненту ""%1"" на клиенте
			           |из хранилища внешних компонент
			           |по причине:
			           |%2'; 
			           |en = 'Cannot attach the ""%1"" add-in
			           |on the client from the add-in storage.
			           |Reason:
			           |%2'; 
			           |pl = 'Cannot attach the ""%1"" add-in
			           |on the client from the add-in storage.
			           |Reason:
			           |%2';
			           |de = 'Cannot attach the ""%1"" add-in
			           |on the client from the add-in storage.
			           |Reason:
			           |%2';
			           |ro = 'Cannot attach the ""%1"" add-in
			           |on the client from the add-in storage.
			           |Reason:
			           |%2';
			           |tr = 'Cannot attach the ""%1"" add-in
			           |on the client from the add-in storage.
			           |Reason:
			           |%2'; 
			           |es_ES = 'Cannot attach the ""%1"" add-in
			           |on the client from the add-in storage.
			           |Reason:
			           |%2'"),
			Context.ID,
			Result.ErrorDescription);
			
		CommonInternalClient.InstallAddInSSLNotifyOnError(ErrorText, Context);
	EndIf;
	
EndProcedure

#EndRegion

#Region ImportAddInFromFile

// see the AddInClient.ImportAddInFromFile function.
//
Procedure ImportAddInFromFile(Context) Export 
	
	Information = AddInInternalServerCall.SavedAddInInformation(Context.ID, Context.Version);
	
	If Information.ImportFromFileIsAvailable Then
		
		AdditionalInformationSearchParameters = Context.AdditionalInformationSearchParameters;
		
		FormParameters = New Structure;
		FormParameters.Insert("ShowImportFromFileDialogOnOpen", True);
		FormParameters.Insert("ReturnImportResultFromFile", True);
		FormParameters.Insert("AdditionalInformationSearchParameters", AdditionalInformationSearchParameters);
		
		If Information.State = "FoundInStorage"
			Or Information.State = "DisabledByAdministrator" Then
			
			FormParameters.Insert("ShowImportFromFileDialogOnOpen", False);
			FormParameters.Insert("Key", Information.Ref);
		EndIf;
		
		Notification = New NotifyDescription("ImportAddInFromFileAfterImport", ThisObject, Context);
		OpenForm("Catalog.AddIns.ObjectForm", FormParameters,,,,, Notification);
		
	Else 
		
		Notification = New NotifyDescription("ImportAddInFromFileAfterAvailabilityWarnings", ThisObject, Context);
		ShowMessageBox(Notification, 
			NStr("ru = 'Загрузка внешней компоненты прервана
			           |по причине:
			           |Требуются права администратора'; 
			           |en = 'Add-in import is canceled
			           |due to: 
			           |You must have administrative rights'; 
			           |pl = 'Add-in import is canceled
			           |due to: 
			           |You must have administrative rights';
			           |de = 'Add-in import is canceled
			           |due to: 
			           |You must have administrative rights';
			           |ro = 'Add-in import is canceled
			           |due to: 
			           |You must have administrative rights';
			           |tr = 'Add-in import is canceled
			           |due to: 
			           |You must have administrative rights'; 
			           |es_ES = 'Add-in import is canceled
			           |due to: 
			           |You must have administrative rights'"));
		
	EndIf;
	
EndProcedure

// ImportAComponentFromAFile procedure continuation.
Procedure ImportAddInFromFileAfterAvailabilityWarnings(Context) Export
	
	Result = AddInImportResult();
	Result.Imported = False;
	ExecuteNotifyProcessing(Context.Notification, Result);
	
EndProcedure

// ImportAComponentFromAFile procedure continuation.
Procedure ImportAddInFromFileAfterImport(Result, Context) Export
	
	// Result:
	// - Structure - Imported.
	// - Undefined - DialogBoxIsClosed.
	
	UserClosedDialogBox = (Result = Undefined);
	
	Notification = Context.Notification;
	
	If UserClosedDialogBox Then 
		Result = AddInImportResult();
		Result.Imported = False;
	EndIf;
	
	ExecuteNotifyProcessing(Notification, Result);
	
EndProcedure

// ImportAComponentFromAFile procedure continuation.
Function AddInImportResult() Export
	
	Result = New Structure;
	Result.Insert("Imported", False);
	Result.Insert("ID", "");
	Result.Insert("Version", "");
	Result.Insert("Description", "");
	Result.Insert("AdditionalInformation", New Map);
	
	Return Result;
	
EndFunction

#EndRegion

#Region ComponentSearchOnPortal

// Parameters:
//  Notification - NotifyDescription - .
//  Context - Structure - procedure context:
//      * ExplanationText - String - .
//      * ID - String - .
//      * Version - String, Undefined - .
//
Procedure ComponentSearchOnPortal(Notification, Context)
	
	FormParameters = New Structure;
	FormParameters.Insert("NoteText", Context.NoteText);
	FormParameters.Insert("ID", Context.ID);
	FormParameters.Insert("Version", Context.Version);
	
	NotificationForms = New NotifyDescription("AddInSearchOnPortalOnGenerateResult", ThisObject, Notification);
	
	OpenForm("Catalog.AddIns.Form.SearchForComponentOn1CITSPortal", 
		FormParameters,,,,, NotificationForms)
	
EndProcedure

Procedure AddInSearchOnPortalOnGenerateResult(Result, Notification) Export
	
	Imported = (Result = True); // It is Undefined on close form.
	ExecuteNotifyProcessing(Notification, Imported);
	
EndProcedure

#EndRegion

#Region UpdateAddInsFromPortal

// Parameters:
//  RefArrray - Array - .
//
Procedure UpdateAddInsFromPortal(Notification, RefsArray) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("RefsArray", RefsArray);
	
	NotificationForms = New NotifyDescription("UpdateAddInFromPortalOnGenerateResult", ThisObject, Notification);
	
	OpenForm("Catalog.AddIns.Form.ComponentsUpdateFrom1CITSPortal", 
		FormParameters,,,,, NotificationForms);
	
EndProcedure

Procedure UpdateAddInFromPortalOnGenerateResult(Result, Notification) Export
	
	ExecuteNotifyProcessing(Notification, Undefined);
	
EndProcedure

#EndRegion

#Region SaveAddInToFile

// Parameters:
//  Reference - CatalogRef.AddIns - add-in container in the infobase.
//
Procedure SaveAddInToFile(Ref) Export 
	
	Location = GetURL(Ref, "AddInStorage");
	FileName = AddInInternalServerCall.ComponentFileName(Ref);
	
	SavingParameters = FileSystemClient.FileSavingParameters();
	SavingParameters.Dialog.Title = NStr("ru = 'Выберите файл для сохранения внешней компоненты'; en = 'Select a file to save the add-in to'; pl = 'Select a file to save the add-in to';de = 'Select a file to save the add-in to';ro = 'Select a file to save the add-in to';tr = 'Select a file to save the add-in to'; es_ES = 'Select a file to save the add-in to'");
	SavingParameters.Dialog.Filter    = NStr("ru = 'Файлы внешних компонент (*.zip)|*.zip|Все файлы (*.*)|*.*'; en = 'Add-in files (*.zip)|*.zip|All files (*.*)|*.*'; pl = 'Add-in files (*.zip)|*.zip|All files (*.*)|*.*';de = 'Add-in files (*.zip)|*.zip|All files (*.*)|*.*';ro = 'Add-in files (*.zip)|*.zip|All files (*.*)|*.*';tr = 'Add-in files (*.zip)|*.zip|All files (*.*)|*.*'; es_ES = 'Add-in files (*.zip)|*.zip|All files (*.*)|*.*'");
	
	Context = New Structure;
	Context.Insert("Ref", Ref);
	
	Notification = New NotifyDescription("SaveAddInToFileAfterReceivingFiles", ThisObject, Context);
	
	FileSystemClient.SaveFile(Notification, Location, FileName, SavingParameters);
	
EndProcedure

// Continuation of the SaveAddInToFile procedure.
Procedure SaveAddInToFileAfterReceivingFiles(ReceivedFiles, Context) Export
	
	If ReceivedFiles <> Undefined 
		AND ReceivedFiles.Count() > 0 Then
		
		ShowUserNotification(NStr("ru = 'Сохранение в файл'; en = 'Save to file'; pl = 'Save to file';de = 'Save to file';ro = 'Save to file';tr = 'Save to file'; es_ES = 'Save to file'"),,
			NStr("ru = 'Внешняя компонента успешно сохранена в файл.'; en = 'Add-in was successfully saved to the file.'; pl = 'Add-in was successfully saved to the file.';de = 'Add-in was successfully saved to the file.';ro = 'Add-in was successfully saved to the file.';tr = 'Add-in was successfully saved to the file.'; es_ES = 'Add-in was successfully saved to the file.'"), PictureLib.Done32);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
