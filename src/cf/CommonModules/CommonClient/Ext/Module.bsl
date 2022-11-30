///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

#Region UserNotification

// ACC:142-disable 4 optional parameters for compatibility with the CommonClientServer.InformUser 
// obsolete procedure.

// Generates and displays the message that can relate to a form item.
//
// See Common.InformUser 
//
// Parameters:
//  UserMessageText - String - a mesage text.
//  DataKey - AnyRef - the infobase record key or object that message refers to.
//  Field - String - a form attribute description.
//  DataPath - String - a data path (a path to a form attribute).
//  Cancel - Boolean - an output parameter. Always True.
//
// Example:
//
//  1. Showing the message associated with the object attribute near the managed form field
//  CommonClient.InformUser(
//   NStr("en = 'Error message.'"), ,
//   "FieldInFormAttributeObject",
//   "Object");
//
//  An alternative variant of using in the object form module
//  CommonClient.InformUser(
//   NStr("en = 'Error message.'"), ,
//   "Object.FieldInFormAttributeObject");
//
//  2. Showing a message for the form attribute, next to the managed form field:
//  CommonClient.InformUser(
//   NStr("en = 'Error message.'"), ,
//   "FormAttributeName");
//
//  3. To display a message associated with an infobase object:
//  CommonClient.InformUser(
//   NStr("en = 'Error message.'"), InfobaseObject, "Responsible person",,Cancel);
//
//  4. To display a message from a link to an infobase object:
//  CommonClient.InformUser(
//   NStr("en = 'Error message.'"), Reference, , , Cancel);
//
//  Scenarios of incorrect using:
//   1. Passing DataKey and DataPath parameters at the same time.
//   2. Passing a value of an illegal type to the DataKey parameter.
//   3. Specifying a reference without specifying a field (and/or a data path).
//
Procedure MessageToUser(
	Val MessageToUserText,
	Val DataKey = Undefined,
	Val Field = "",
	Val DataPath = "",
	Cancel = False) Export
	
	CommonInternalClientServer.MessageToUser(
		MessageToUserText,
		DataKey,
		Field,
		DataPath,
		Cancel);
	
EndProcedure

// ACC:142-enable

// Returns the code of the default configuration language, for example, "en".
//
// See Common.DefaultLanguageCode 
//
// Returns:
//  String - language code.
//
Function DefaultLanguageCode() Export
	
	Return StandardSubsystemsClient.ClientParameter("DefaultLanguageCode");
	
EndFunction

#EndRegion

#Region InfobaseData

////////////////////////////////////////////////////////////////////////////////
// Common procedures and functions to manage infobase data.

// Returns a reference to the predefined item by its full name.
// Only the following objects can contain predefined objects:
//   - catalogs,
//   - charts of characteristic types,
//   - charts of accounts,
//   - charts of calculation types.
// After changing the list of predefined items, it is recommended that you run
// the UpdateCachedValues() method to clear the cache for Cached modules in the current session.
//
// See Common.PredefinedItem 
//
// Parameters:
//   PredefinedItemFullName - String - full path to the predefined item including the name.
//     The format is identical to the PredefinedValue() global context function.
//     Example:
//       "Catalog.ContactInformationKinds.UserEmail"
//       "ChartOfAccounts.SelfFinancing.Materials"
//       "ChartOfCalculationTypes.Accruals.SalaryPayments".
//
// Returns:
//   AnyRef - reference to the predefined item.
//   Undefined - if the predefined item exists in metadata but not in the infobase.
//
Function PredefinedItem(PredefinedItemFullName) Export
	
	If CommonInternalClientServer.UseStandardGettingPredefinedItemFunction(
		PredefinedItemFullName) Then 
		
		Return PredefinedValue(PredefinedItemFullName);
	EndIf;
	
	PredefinedItemFields = CommonInternalClientServer.PredefinedItemNameByFields(PredefinedItemFullName);
	
	PredefinedValues = StandardSubsystemsClientCached.RefsByPredefinedItemsNames(
		PredefinedItemFields.FullMetadataObjectName);
	
	Return CommonInternalClientServer.PredefinedItem(
		PredefinedItemFullName, PredefinedItemFields, PredefinedValues);
	
EndFunction

#EndRegion

#Region ConditionCalls

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions for calling optional subsystems.

// Returns True if the "functional" subsystem exists in the configuration.
// Intended for calling optional subsystems (conditional calls).
//
// A subsystem is considered functional if its "Include in command interface" check box is cleared.
//
// See Common.SubsystemExists 
//
// Parameters:
//  FullSubsystemName - String - the full name of the subsystem metadata object without the 
//                        "Subsystem." part, case-sensitive.
//                        Example: "StandardSubsystems.ReportOptions".
//
// Example:
//  If Common.SubsystemExists("StandardSubsystems.ReportOptions") Then
//  	ModuleReportOptions = Common.CommonModule("ReportOptions");
//  	ModuleReportOptions.<Method name>();
//  EndIf.
//
// Returns:
//  Boolean - True if exists.
//
Function SubsystemExists(FullSubsystemName) Export
	
	ParameterName = "StandardSubsystems.ConfigurationSubsystems";
	If ApplicationParameters[ParameterName] = Undefined Then
		SubsystemsNames = StandardSubsystemsClient.ClientParametersOnStart().SubsystemsNames;
		ApplicationParameters.Insert(ParameterName, SubsystemsNames);
	EndIf;
	SubsystemsNames = ApplicationParameters[ParameterName];
	Return SubsystemsNames.Get(FullSubsystemName) <> Undefined;
	
EndFunction

// Returns a reference to a common module or manager module by name.
//
// See Common.CommonModule 
//
// Parameters:
//  Name - String - name of a common module.
//
// Returns:
//  CommonModule, ObjectManagerModule - a common module.
//
// Example:
//	If Common.SubsystemExists("StandardSubsystems.ConfigurationUpdate") Then
//		ModuleSoftwareUpdate = Common.CommonModule("ConfigurationUpdate");
//		ModuleSoftwareUpdate.<Method name>();
//	EndIf.
//
//	If Common.SubsystemExists("StandardSubsystems.FullTextSearch") then
//		ModuleFullTextSearchServer = Common.CommonModule("FullTextSearchServer").
//		ModuleFullTextSearchServer.<Method name>();
//	EndIf.
//
Function CommonModule(Name) Export
	
	Module = Eval(Name);
	
#If Not WebClient Then
	
	// The check is skipped as the module does not exist for this server type in the web client.
	// 
	
	If TypeOf(Module) <> Type("CommonModule") Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Общий модуль ""%1"" не найден.'; en = 'Common module %1 is not found.'; pl = 'Nie znaleziono wspólnego modułu ""%1"".';de = 'Gemeinsames Modul ""%1"" wurde nicht gefunden.';ro = 'Modulul comun ""%1"" nu a fost găsit.';tr = 'Ortak modül ""%1"" bulunamadı.'; es_ES = 'Módulo común ""%1"" no se ha encontrado.'"), 
			Name);
	EndIf;
	
#EndIf
	
	Return Module;
	
EndFunction

#EndRegion

#Region CurrentEnvironment

////////////////////////////////////////////////////////////////////////////////
// The details functions of the current client application environment and operating system.

// Returns True if the client application is running on Windows.
//
// See Common.IsWindowsClient 
//
// Returns:
//  Boolean - False if no client application is available.
//
Function IsWindowsClient() Export
	
	ClientPlatformType = ClientPlatformType();
	Return ClientPlatformType = PlatformType.Windows_x86
		Or ClientPlatformType = PlatformType.Windows_x86_64;
	
EndFunction

// Returns True if the client application is running on Linux.
//
// See Common.IsLinuxClient 
//
// Returns:
//  Boolean - False if no client application is available.
//
Function IsLinuxClient() Export
	
	ClientPlatformType = ClientPlatformType();
	Return ClientPlatformType = PlatformType.Linux_x86
		Or ClientPlatformType = PlatformType.Linux_x86_64;
	
EndFunction

// Returns True if the client application runs on OS X.
//
// See Common.IsOSXClient 
//
// Returns:
//  Boolean - False if no client application is available.
//
Function IsOSXClient() Export
	
	ClientPlatformType = ClientPlatformType();
	Return ClientPlatformType = PlatformType.MacOS_x86
		Or ClientPlatformType = PlatformType.MacOS_x86_64;
	
EndFunction

// Returns True if a client application is connected to the infobase through a web server.
//
// See Common.ClientConnectedOverWebServer 
//
// Returns:
//  Boolean - True if the application is connected.
//
Function ClientConnectedOverWebServer() Export
	
	Return StrFind(Upper(InfoBaseConnectionString()), "WS=") = 1;
	
EndFunction

// Returns True if debug mode is enabled.
//
// See Common.DebugMode 
//
// Returns:
//  Boolean - True if debug mode is enabled.
//
Function DebugMode() Export
	
	Return StrFind(LaunchParameter, "DebugMode") > 0;
	
EndFunction

// Returns the amount of RAM available to the client application.
//
// See Common.RAMAvailableForClientApplication 
//
// Returns:
//  Number - the number of GB of RAM, with tenths-place accuracy.
//  Undefined - no client application is available, meaning CurrentRunMode() = Undefined.
//
Function RAMAvailableForClientApplication() Export
	
	SystemInformation = New SystemInfo;
	Return Round(SystemInformation.RAM / 1024, 1);
	
EndFunction

// Determines the infobase mode: file (True) or client/server (False).
// This function uses the InfobaseConnectionString parameter. You can specify this parameter explicitly.
//
// See Common.FileInfobase 
//
// Parameters:
//  InfobaseConnectionString - String - the parameter is applied if you need to check a connection 
//                 string for another infobase.
//
// Returns:
//  Boolean - True if it is a file infobase.
//
Function FileInfobase(Val InfobaseConnectionString = "") Export
	
	If Not IsBlankString(InfobaseConnectionString) Then
		Return StrFind(Upper(InfobaseConnectionString), "FILE=") = 1;
	EndIf;
	
	Return StandardSubsystemsClient.ClientParameter("FileInfobase");
	
EndFunction

// Returns the client platform type.
//
// Returns:
//  PlatformType, Undefined - the type of the platform running a client. In the web client mode, if 
//                               the actual platform type does not match the PlatformType value, returns Undefined.
//
Function ClientPlatformType() Export
	
	SystemInfo = New SystemInfo;
	Return SystemInfo.PlatformType
	
EndFunction

#EndRegion

#Region Dates

////////////////////////////////////////////////////////////////////////////////
// Functions to work with dates considering the session timezone

// Returns current date in the session time zone.
// It is designed to be used instead of CurrentDate() function in the client code in cases when it 
// is impossible to transfer algorithm into the server code.
//
// The returned time is close to the CurrentSessionDate function result in the server code.
// The time inaccuracy is associated with the server call execution time.
// Besides, if you set the time on the client computer, the function will not take this change into 
// account immediately, but only after you again clear the cache of reused values (see also the 
// UpdateCachedValues method).
// Why do the algorithms for which the exact time is crucially important must be placed in the 
// server code but not in the client code.
//
// Returns:
//  Date - the actual session date.
//
Function SessionDate() Export
	
	If StandardSubsystemsClient.ApplicationStartCompleted() Then
		ClientParameters = StandardSubsystemsClient.ClientRunParameters();
	Else
		ClientParameters = StandardSubsystemsClient.ClientParametersOnStart();
	EndIf;
	
	Return CurrentDate() + ClientParameters.SessionTimeOffset;
	
EndFunction

// Returns the GMT session date converted from the local session date.
//
// The returned time is close to the ToUniversalTime() function result in the server context.
// The time inaccuracy is associated with the server call execution time.
// The function replaced the obsolete function ToUniversalTime().
//
// Returns:
//  Date - the universal session date.
//
Function UniversalDate() Export
	
	If StandardSubsystemsClient.ApplicationStartCompleted() Then
		ClientParameters = StandardSubsystemsClient.ClientRunParameters();
	Else
		ClientParameters = StandardSubsystemsClient.ClientParametersOnStart();
	EndIf;
	
	SessionDate = CurrentDate() + ClientParameters.SessionTimeOffset;
	Return SessionDate + ClientParameters.UniversalTimeCorrection;
	
EndFunction

// Convert a local date to the "YYYY-MM-DDThh:mm:ssTZD" format (ISO 8601).
//
// See Common.LocalDatePresentationWithOffset 
//
// Parameters:
//  LocalDate - Date - a date in the session time zone.
// 
// Returns:
//   String - the date sting presentation.
//
Function LocalDatePresentationWithOffset(LocalDate) Export
	
	Offset = StandardSubsystemsClient.ClientRunParameters().StandardTimeOffset;
	Return CommonInternalClientServer.LocalDatePresentationWithOffset(LocalDate, Offset);
	
EndFunction

#EndRegion

#Region Data

////////////////////////////////////////////////////////////////////////////////
// Common procedures and functions for applied types and value collections.

// Creates a complete recursive copy of a structure, map, array, list, or value table consistent 
// with the child item type. For object-type values (for example, CatalogObject or DocumentObject), 
// the procedure returns references to the source objects instead of copying the content.
//
// See Common.CopyRecursive 
//
// Parameters:
//  Source - Structure, FixedStructure,
//             Map, FixedMap,
//             Array, FixedArray,
//             ValueList - an object that needs to be copied.
//  FixData - Boolean, Undefined - if it is True, then fix, if it is False, remove the fixing, if it 
//                          is Undefined, do not change.
//
// Returns:
//  Structure, FixedStructure,
//  Map, FixedMap,
//  Array, FixedArray,
//  ValueList - a copy of the object passed in the Source parameter.
//
Function CopyRecursive(Source, FixData = Undefined) Export
	
	Var Target;
	
	SourceType = TypeOf(Source);
	
	If SourceType = Type("Structure")
		Or SourceType = Type("FixedStructure") Then
		Target = CommonInternalClient.CopyStructure(Source, FixData);
	ElsIf SourceType = Type("Map")
		Or SourceType = Type("FixedMap") Then
		Target = CommonInternalClient.CopyMap(Source, FixData);
	ElsIf SourceType = Type("Array")
		Or SourceType = Type("FixedArray") Then
		Target = CommonInternalClient.CopyArray(Source, FixData);
	ElsIf SourceType = Type("ValueList") Then
		Target = CommonInternalClient.CopyValueList(Source, FixData);
	Else
		Target = Source;
	EndIf;
	
	Return Target;
	
EndFunction

// Checking that the Parameter command contains an ExpectedType object.
// Otherwise, returns False and displays the standard user message.
// This situation is possible, for example, when a row that contains a group is selected in a list.
//
// Application: commands that manage dynamic list items in forms.
// 
// Parameters:
//  Parameter - Array, AnyRef - the command parameter.
//  ExpectedType - Type - the expected type.
//
// Returns:
//  Boolean - True if the parameter type matches the expected type.
//
// Example:
// 
//   If Not CheckCommandParameterType(Items.List.SelectedRows,
//      Type("TaskRef.PerformerTask")) Then
//      Return;
//   EndIf.
//   ...
Function CheckCommandParameterType(Val Parameter, Val ExpectedType) Export
	
	If Parameter = Undefined Then
		Return False;
	EndIf;
	
	Result = True;
	
	If TypeOf(Parameter) = Type("Array") Then
		// Checking whether the array contains only one element, and its type does not match the expected type.
		Result = NOT (Parameter.Count() = 1 AND TypeOf(Parameter[0]) <> ExpectedType);
	Else
		Result = TypeOf(Parameter) = ExpectedType;
	EndIf;
	
	If NOT Result Then
		ShowMessageBox(,NStr("ru = 'Действие не может быть выполнено для выбранного элемента.'; en = 'The object does not support this type of operations.'; pl = 'Nie można wykonać czynności dla wybranego elementu.';de = 'Aktion kann für das ausgewählte Element nicht ausgeführt werden.';ro = 'Acțiunea nu poate fi executată pentru elementul selectat.';tr = 'Seçilen öğe için işlem yapılamaz.'; es_ES = 'Acción no puede ejecutarse para el artículo seleccionado.'"));
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Forms

////////////////////////////////////////////////////////////////////////////////
// Common client procedures to work with forms.

// Asks whether the user wants to continue the action that will discard the changes:
// "Data was changed. Save the changes?"
// Use in form modules BeforeClose event handlers of the objects that can be written to infobase.
// 
// The message presentation depends on the form modification property.
// To display an arbitrary form question:
//  see the Common.ShowArbitraryFormClosingConfirmation() procedure.
//
// Parameters:
//  SaveAndCloseNotification - NotifyDescription - name of the procedure to be called once the OK button is clicked.
//  Cancel - Boolean - a return parameter that indicates whether the action is canceled.
//  Exit - Boolean - indicates whether the form closes on exit the application.
//  WarningText - String - the warning message text. The deafult text is:
//                                          "Data was changed. Save the changes?"
//  WarningTextOnExit - String - the return value that contains warning text displayed to users on 
//                                          exit the application. The default value is:
//                                          "Data was changed. All changes will be lost.".
//
// Example:
//
//  &AtClient
//  Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
//    Notification = New NotifyDescription("SelectAndClose", ThisObject);
//    CommonClient.ShowFormClosingConfirmation(Notification, Cancel, Exit);
//  EndProcedure
//  
//  &AtClient
//  Procedure SelectAndClose(Result= Undefined, AdditionalParameters = Undefined) Export
//     // Writing form data.
//     // ...
//     Modified = False; // Do not show form closing notification again.
//     Close(<SelectionResult>);
//  EndProcedure
//
Procedure ShowFormClosingConfirmation(
		Val SaveAndCloseNotification, 
		Cancel, 
		Val WorkCompletion, 
		Val WarningText = "", 
		WarningTextOnExit = Undefined) Export
	
	Form = SaveAndCloseNotification.Module;
	If Not Form.Modified Then
		Return;
	EndIf;
	
	Cancel = True;
	
	If WorkCompletion Then
		If WarningTextOnExit = "" Then // Parameter from BeforeClose is passed.
			WarningTextOnExit = NStr("ru = 'Данные были изменены. Все изменения будут потеряны.'; en = 'The data was changed. All changes will be lost.'; pl = 'Dane zostały zmienione. Wszystkie zmiany zostaną utracone.';de = 'Daten geändert. Alle Änderungen gehen verloren.';ro = 'Datele au fost modificate. Toate modificările vor fi pierdute.';tr = 'Veri değişti. Tüm değişiklikler kaybolacak.'; es_ES = 'Datos cambiados. Todos los cambios se perderán.'");
		EndIf;
		Return;
	EndIf;
	
	Parameters = New Structure();
	Parameters.Insert("SaveAndCloseNotification", SaveAndCloseNotification);
	Parameters.Insert("WarningText", WarningText);
	
	ParameterName = "StandardSubsystems.FormClosingConfirmationParameters";
	If ApplicationParameters[ParameterName] = Undefined Then
		ApplicationParameters.Insert(ParameterName, Undefined);
	EndIf;
	
	CurrentParameters = ApplicationParameters["StandardSubsystems.FormClosingConfirmationParameters"];
	If CurrentParameters <> Undefined
	   AND CurrentParameters.SaveAndCloseNotification.Module = Parameters.SaveAndCloseNotification.Module Then
		Return;
	EndIf;
	
	ApplicationParameters["StandardSubsystems.FormClosingConfirmationParameters"] = Parameters;
	
	Form.Activate();
	AttachIdleHandler("ConfirmFormClosingNow", 0.1, True);
	
EndProcedure

// Asks whether the user wants to continue the action that closes the form.
// Is intended to be used in BeforeClose event notification handlers.
// To display a question in a form that can be written to the infobase:
//  see the CommonClient.ShowFormClosingConfirmation() procedure.
//
// Parameters:
//  Form - ManagedForm - the form that calls the warning dialog.
//  Cancel - Boolean - a return parameter that indicates whether the action is canceled.
//  Exit - Boolean - indicates whether the application will be closed.
//  WarningText - String - the warning message text.
//  CloseFormWithoutConfirmationAttributeName - String - the name of the flag attribute that 
//                                 indicates whether to show the warning.
//  CloseNotifyDescription    - NotifyDescription - name of the procedure to be called once the OK button is clicked.
//
// Example: 
//  WarningText = NStr("en = 'Close the wizard?'");
//  CommonClient.ShowArbitraryFormClosingConfirmation(
//      ThisObject, Cancel, MessageText, "CloseFormWithoutConfirmation");
//
Procedure ShowArbitraryFormClosingConfirmation(
		Val Form, 
		Cancel, 
		Val WorkCompletion, 
		Val WarningText, 
		Val CloseFormWithoutConfirmationAttributeName, 
		Val CloseNotifyDescription = Undefined) Export
		
	If Form[CloseFormWithoutConfirmationAttributeName] Then
		Return;
	EndIf;
	
	Cancel = True;
	If WorkCompletion Then
		Return;
	EndIf;
	
	Parameters = New Structure();
	Parameters.Insert("Form", Form);
	Parameters.Insert("WarningText", WarningText);
	Parameters.Insert("CloseFormWithoutConfirmationAttributeName", CloseFormWithoutConfirmationAttributeName);
	Parameters.Insert("CloseNotifyDescription", CloseNotifyDescription);
	
	ParameterName = "StandardSubsystems.FormClosingConfirmationParameters";
	If ApplicationParameters[ParameterName] = Undefined Then
		ApplicationParameters.Insert(ParameterName, Undefined);
	EndIf;
	ApplicationParameters["StandardSubsystems.FormClosingConfirmationParameters"] = Parameters;
	
	AttachIdleHandler("ConfirmArbitraryFormClosingNow", 0.1, True);
	
EndProcedure

// Updates the application interface keeping the current active window.
//
Procedure RefreshApplicationInterface() Export
	
	CurrentActiveWindow = ActiveWindow();
	RefreshInterface();
	If CurrentActiveWindow <> Undefined Then
		CurrentActiveWindow.Activate();
	EndIf;
	
EndProcedure

// Notifies opened forms and dynamic lists about changes in a single object.
//
// Parameters:
//  Source   - AnyRef,
//             InformationRegisterRecordKey,
//             AccumulationRegisterRecordKey,
//             AccountingRegisterRecordKey,
//             CalculationRegisterRecordKey - a changed object reference or changed register record 
//                                        key, whose update status to be provided to dynamic lists and forms.
//  AdditionalParameters - Arbitrary - parameters to be passed in the Notify method.
//
Procedure NotifyObjectChanged(Source, Val AdditionalParameters = Undefined) Export
	If AdditionalParameters = Undefined Then
		AdditionalParameters = New Structure;
	EndIf;
	Notify("Write_" + CommonInternalClient.MetadataObjectName(TypeOf(Source)), AdditionalParameters, Source);
	NotifyChanged(Source);
EndProcedure

// Notifies opened forms and dynamic lists about changes in multiple objects.
//
// Parameters:
//  Source - Type, TypeDescription - object type or types, whose update status to be provided to 
//                                  dynamic lists and forms.
//           - Array - a list of changed references or register record keys, whose update status to 
//                      be provided to dynamic lists and forms.
//  AdditionalParameters - Arbitrary - parameters to be passed in the Notify method.
//
Procedure NotifyObjectsChanged(Source, Val AdditionalParameters = Undefined) Export
	
	If AdditionalParameters = Undefined Then
		AdditionalParameters = New Structure;
	EndIf;
	
	If TypeOf(Source) = Type("Type") Then
		NotifyChanged(Source);
		Notify("Write_" + CommonInternalClient.MetadataObjectName(Source), AdditionalParameters);
	ElsIf TypeOf(Source) = Type("TypeDescription") Then
		For Each Type In Source.Types() Do
			NotifyChanged(Type);
			Notify("Write_" + CommonInternalClient.MetadataObjectName(Type), AdditionalParameters);
		EndDo;
	ElsIf TypeOf(Source) = Type("Array") Then
		If Source.Count() = 1 Then
			NotifyObjectChanged(Source[0], AdditionalParameters);
		Else
			NotifiedTypes = New Map;
			For Each Ref In Source Do
				NotifiedTypes.Insert(TypeOf(Ref));
			EndDo;
			For Each Type In NotifiedTypes Do
				NotifyChanged(Type.Key);
				Notify("Write_" + CommonInternalClient.MetadataObjectName(Type.Key), AdditionalParameters);
			EndDo;
		EndIf;
	EndIf;

EndProcedure

#EndRegion

#Region EditingForms

////////////////////////////////////////////////////////////////////////////////
// Functions that process multiline text edition (for example, document comments).
// 

// Opens the multiline text edit form.
//
// Parameters:
//  ClosingNotification - NotifyDescription - the details of the procedure to be called when the 
//                            text entry form is closed. Contains the same parameters as method
//                            ShowInputString.
//  MultilineText - String - a text to be edited.
//  Title - String - the text to be displayed in the from title.
//
// Example:
//
//   Notification = New NotifyDescription("CommentEndEntering", ThisObject);
//   CommonClient.FormMultilineTextEditingShow(Notification, Item.EditingText);
//
//   &AtClient
//   Procedure CommentEndEntering(Val EnteredText, Val AdditionalParameters) Export
//      If EnteredText = Undefined Then
//		   Return;
//   	EndIf;
//	
//	   Object.MultilineComment = EnteredText;
//	   Modified = True;
//   EndProcedure
//
Procedure ShowMultilineTextEditingForm(Val ClosingNotification, 
	Val MultilineText, Val Title = Undefined) Export
	
	If Title = Undefined Then
		ShowInputString(ClosingNotification, MultilineText,,, True);
	Else
		ShowInputString(ClosingNotification, MultilineText, Title,, True);
	EndIf;
	
EndProcedure

// Opens the multiline comment editing form.
//
// Parameters:
//  MultilineText - String - a text to be edited.
//  OwnerForm      - ManagedForm - the form that owns the field a user entering a comment into.
//  AttributeName       - String - the name of the form attribute the user comment will be stored to.
//                                The default value is Object.Comment.
//  Title          - String - a text to be displayed in the form title.
//                                The default value is Comment.
//
// Example:
//  CommonClient.ShowCommentEditingForm(
//  	Item.EditingText, ThisObject, Object.Comment);
//
Procedure ShowCommentEditingForm(
	Val MultilineText, 
	Val OwnerForm, 
	Val AttributeName = "Object.Comment", 
	Val Title = Undefined) Export
	
	Context = New Structure;
	Context.Insert("OwnerForm", OwnerForm);
	Context.Insert("AttributeName", AttributeName);
	
	Notification = New NotifyDescription(
		"CommentInputCompletion", 
		CommonInternalClient, 
		Context);
	
	FormHeader = ?(Title <> Undefined, Title, NStr("ru='Комментарий'; en = 'Comment'; pl = 'Komentarz';de = 'Kommentar';ro = 'Cometariu';tr = 'Yorum'; es_ES = 'Comentario'"));
	
	ShowMultilineTextEditingForm(Notification, MultilineText, FormHeader);
	
EndProcedure

#EndRegion

#Region UserSettings

// Saves personal application user settings.
//
// Parameters:
//	Setting - Structure - a collection of settings:
//	 * RemindAboutFileSystemExtensionInstallation - Boolean - the flag indicating whether to notify 
//                                                               users on extension installation.
//	 * AskConfirmationOnExit - Boolean - the flag indicating whether to ask confirmation before the user exits the application.
//
Procedure SavePersonalSettings(Settings) Export
	
	If Settings.Property("RemindAboutFileSystemExtensionInstallation") Then
		ApplicationParameters["StandardSubsystems.SuggestFileSystemExtensionInstallation"] = 
			Settings.RemindAboutFileSystemExtensionInstallation;
	EndIf;
	
	If Settings.Property("AskConfirmationOnExit") Then
		StandardSubsystemsClient.SetClientParameter("AskConfirmationOnExit",
			Settings.AskConfirmationOnExit);
	EndIf;
		
	If Settings.Property("PersonalFilesOperationsSettings") Then
		StandardSubsystemsClient.SetClientParameter("PersonalFilesOperationsSettings",
			Settings.PersonalFilesOperationsSettings);
	EndIf;
	
EndProcedure

#EndRegion

#Region Styles

////////////////////////////////////////////////////////////////////////////////
// Functions to manage style colors in the client code.

// The function gets the style color by a style item name.
//
// Parameters:
//  StyleColorName - String - style item name.
//
// Returns:
//    Color - the style color.
//
Function StyleColor(StyleColorName) Export
	
	Return CommonClientCached.StyleColor(StyleColorName);
	
EndFunction

// The function gets the style font by a style item name.
//
// Parameters:
//   StyleFontName - String - the style item name.
//
// Returns:
//  Font - the style font.
//
Function StyleFont(StyleFontName) Export
	
	Return CommonClientCached.StyleFont(StyleFontName);
	
EndFunction

#EndRegion

#Region AddIns

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions to connect and install add-ins from configuration templates.

// Returns parameter structure. See the AttachAddInFromTemplate procedure.
//
// Returns:
//  Structure - a collection of the following parameters:
//      * Cached - Boolean - use component caching on the client (the default value is True).
//      * SuggestInstall - Boolean - (default value is True) prompt to install and update an add-in.
//      * NoteText       - String - a text that describes the add-in purpose and which functionality requires the add-in.
//      * ObjectsCreationIDs - Array - the creation IDs of object module instances. Applicable only 
//                 with add-ins that have a number of object creation IDs. Ignored if the ID 
//                 parameter is specified.
//
// Example:
//
//  AttachmentParameters = CommonClient.AddInAttachmentParameters();
//  AttachmentParameters.NoteText = NStr("en = 'To use a barcode scanner, install
//                                             |the 1C:Barcode scanners (NativeApi) add-in.'");
//
Function AddInAttachmentParameters() Export
	
	Parameters = New Structure;
	Parameters.Insert("Cached", True);
	Parameters.Insert("SuggestInstall", True);
	Parameters.Insert("NoteText", "");
	Parameters.Insert("ObjectsCreationIDs", New Array);
	
	Return Parameters;
	
EndFunction

// Connects an add-in based on Native API and COM technology in an asynchronous mode.
// The add-inn must be stored in the configuration template in as a ZIP file.
// Web client can display dialog with installation tips.
//
// Parameters:
//  Notification - NotifyDescription - connection notification details with the following parameters:
//      * Result - Structure - add-in connection result:
//          ** Connected - Boolean - connection flag.
//          ** AttachableModule - AddIn - an instance of the add-in.
//                                - FixedMap - the add-in object instances stored in 
//                                     AttachmentParameters.ObjectsCreationIDs.
//                                     Key - ID, Value - object instance.
//          ** ErrorDescription     - String - a brief error description. Empty string on cancel by user.
//      * AdditionalParameters - Structure - a value that was specified when creating the NotifyDescription object.
//  ID - String - the add-in identification code.
//  FullTemplateName - String - the full name of the template used as the add-in location.
//  AttachmentParameters - Structure, Undefined - see the AddInAttachmentParameters function.
//
// Example:
//
//  Notification = New NotifyDescription("AttachAddInSSLCompletion", ThisObject);
//
//  AttachmentParameters = CommonClient.AddInAttachmentParameters();
//  AttachmentParameters.NoteText = NStr("en = 'To apply for the certificate,
//                                             install the CryptS add-in.'");
//
//  CommonClient.AttachAddInFromTemplate(Notification,
//      "CryptS",
//      "DataProcessor.ApplicationForNewQualifiedCertificateIssue.Template.ExchangeComponent",
//      AttachmentParameters);
//
//  &AtClient
//  Procedure AttachAddInSSLCompletion(Result, AdditionalParameters) Export
//
//      AttachableModule = Undefined;
//
//      If Result.Attached Then
//          AttachableModule = Result.AttachableModule;
//      Else
//          If Not IsBlankString(Result.ErrorDescription) Then
//              ShowMessageBox (, Result.ErrorDescription);
//          EndIf.
//      EndIf.
//
//      If AttachableModule <> Undefined Then
//          // AttachableModule contains the instance of the attached add-in.
//      EndIf.
//
//      AttachableModule = Undefined;
//
//  EndProcedure
//
Procedure AttachAddInFromTemplate(Notification, ID, FullTemplateName,
	AttachmentParameters = Undefined) Export
	
	Parameters = AddInAttachmentParameters();
	If AttachmentParameters <> Undefined Then
		FillPropertyValues(Parameters, AttachmentParameters);
	EndIf;
	
	Context = New Structure;
	Context.Insert("Notification", Notification);
	Context.Insert("ID", ID);
	Context.Insert("Location", FullTemplateName);
	Context.Insert("Cached", Parameters.Cached);
	Context.Insert("SuggestInstall", Parameters.SuggestInstall);
	Context.Insert("NoteText", Parameters.NoteText);
	Context.Insert("ObjectsCreationIDs", Parameters.ObjectsCreationIDs);
	
	CommonInternalClient.AttachAddInSSL(Context);
	
EndProcedure

// Returns a parameter structure. See the InstallAddInFromTemplate procedure.
//
// Returns:
//  Structure - a collection of the following parameters:
//      * NoteText - String - purpose of an add-in and what applications do not operate without it.
//
// Example:
//
//  InstallationParameters = CommonClient.AddInInstallParameters();
//  InstallationParameters.NoteText = NStr("en = 'To use a barcode scanner, install
//                                           |the 1C:Barcode scanners (NativeApi) add-in.'");
//
Function AddInInstallParameters() Export
	
	Parameters = New Structure;
	Parameters.Insert("NoteText", "");
	
	Return Parameters;
	
EndFunction

// Connects an add-in based on Native API and COM technology in an asynchronous mode.
// The add-inn must be stored in the configuration template in as a ZIP file.
//
// Parameters:
//  Notification - NotifyDescription - notification details of add-in installation:
//      * Structure - Completed - install component result:
//          ** Installed - Boolean - installation flag.
//          ** ErrorDescription - String - a brief error description. Empty string on cancel by user.
//      * AdditionalParameters - Structure - a value that was specified when creating the NotifyDescription object.
//  FullTemplateName - String - the full name of the template used as the add-in location.
//  InstallationParameters - Structure, Undefined - see the AddInInstallParameters function.
//
// Example:
//
//  Notification = New NotifyDescription("SetCompletionComponent", ThisObject);
//
//  InstallationParameters = CommonClient.AddInInstallParameters();
//  InstallationParameters.NoteText = NStr("en = 'To apply for the certificate,
//                                           install the CryptS add-in.'");
//
//  CommonClient.InstallAddInFromTemplate(Notification,
//      "DataProcessor.ApplicationForNewQualifiedCertificateIssue.Template.ExchangeComponent",
//      InstallationParameters);
//
//  &AtClient
//  Procedure InstallAddInEnd(Result, AdditionalParameters) Export
//
//      If Not Result.Installed and Not IsBlankString(Result.ErrorDescription) Then
//          ShowMessageBox (, Result.ErrorDescription);
//      EndIf.
//
//  EndProcedure
//
Procedure InstallAddInFromTemplate(Notification, FullTemplateName, InstallationParameters = Undefined) Export
	
	Parameters = AddInInstallParameters();
	If InstallationParameters <> Undefined Then
		FillPropertyValues(Parameters, InstallationParameters);
	EndIf;
	
	Context = New Structure;
	Context.Insert("Notification", Notification);
	Context.Insert("Location", FullTemplateName);
	Context.Insert("NoteText", Parameters.NoteText);
	
	CommonInternalClient.InstallAddInSSL(Context);
	
EndProcedure

#EndRegion

#Region ExternalConnection

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions for managing external connections.

// Registers the comcntr.dll component for the current platform version.
// If the registration is successful, the procedure suggests the user to restart the client session 
// in order to registration takes effect.
//
// Is called before a client script that uses the COM connection manager (V83.COMConnector) and is 
// initiated by interactive user actions.
// 
// Parameters:
//  RestartSession - Boolean - if True, after the COM connector is registered, the session restart 
//      dialog box is called.
//  Notification - NotifyDescription - notification on registration result.
//      - Registered - Boolean - True if the COM connector is registered without errors.
//      - AdditionalParameters - Arbitrary - a value that was specified when creating the 
//            NotifyDescription object.
//
// Example:
//  RegisterCOMConnector();
//
Procedure RegisterCOMConnector(Val RestartSession = True, 
	Val Notification = Undefined) Export
	
	Context = New Structure;
	Context.Insert("RestartSession", RestartSession);
	Context.Insert("Notification", Notification);
	
	If CommonInternalClient.RegisterCOMConnectorRegistrationIsAvailable() Then 
	
		ApplicationStartupParameters = FileSystemClient.ApplicationStartupParameters();
#If Not WebClient AND Not MobileClient Then
		ApplicationStartupParameters.CurrentDirectory = BinDir();
#EndIf
		ApplicationStartupParameters.Notification = New NotifyDescription(
			"RegisterCOMConnectorOnCheckRegistration", CommonInternalClient, Context);
		ApplicationStartupParameters.WaitForCompletion = True;
		
		CommandText = "regsvr32.exe /n /i:user /s comcntr.dll";
		
		FileSystemClient.StartApplication(CommandText, ApplicationStartupParameters);
		
	Else 
		
		CommonInternalClient.RegisterCOMConnectorNotifyOnError(Context);
		
	EndIf;
	
EndProcedure

// Establishes an external infobase connection with the passed parameters and returns a pointer to 
// the connection.
//
// See Common.EstablishExternalConnectionWithInfobase 
//
// Parameters:
//  Parameters - Structure - see CommonClientServer.ParametersStructureForExternalConnection 
// 
// Returns:
//  Structure - connection details:
//    * Connection - COMObject, Undefined - if the connection is established, returns a COM object reference. Otherwise, returns Undefined.
//    * BriefErrorDescription - String - a brief error description;
//    * DetailedErrorDescription - String - a detailed error details;
//    * ErrorAttachingAddIn - Boolean - a COM connection error flag.
//
Function EstablishExternalConnectionWithInfobase(Parameters) Export
	
	ConnectionUnavailable = IsLinuxClient() Or IsOSXClient();
	BriefErrorDescription = NStr("ru = 'Прямое подключение к информационной базе доступно только на клиенте под управлением ОС Windows.'; en = 'Only Windows clients support direct infobase connections.'; pl = 'Bezpośrednie podłączenie do bazy informacyjnej jest dostępne tylko dla klienta w systemie operacyjnym SO Windows.';de = 'Eine direkte Verbindung zur Informationsbasis ist nur auf dem Client mit dem Betriebssystem Windows möglich.';ro = 'Conectarea directă la baza de date este disponibilă numai pe serverul gestionat de SO Windows.';tr = 'Windows OS kapsamında bir istemcideki veritabanına doğrudan bağlantı mevcut değildir.'; es_ES = 'Conexión directa a la infobase solo está disponible en un cliente bajo OS Windows.'");
	
	Return CommonInternalClientServer.EstablishExternalConnectionWithInfobase(Parameters, ConnectionUnavailable, BriefErrorDescription);
	
EndFunction

#EndRegion

#Region Backup

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions for backup in the user mode.

// Checks whether the backup can be done in the user mode.
//
// Returns:
//  Boolean - True if the installation is suggested.
//
Function PromptToBackUp() Export
	
	Result = False;
	SubsystemsIntegrationSSLClient.OnCheckIfCanBackUpInUserMode(Result);
	Return Result;
	
EndFunction

// Prompt users for back up.
Procedure PromptUserToBackUp() Export
	
	SubsystemsIntegrationSSLClient.OnPromptUserForBackup();
	
EndProcedure

#EndRegion

#Region ObsoleteProceduresAndFunctions

// Obsolete. Use instead:
//  OpenURL to pass a URL or a website link.
//  OpenExplorer to pass the path to a file or directory in Explorer.
//  OpenFileInViewer to open a file in a associated application.
//
// Follows a link to visit an infobase object or external object.
// For example a link to a site or path to a folder.
//
// Parameters:
//  Reference - Reference - a link to follow.
//
Procedure GoToLink(Ref) Export
	
	#If ThickClientOrdinaryApplication Then
		// Platform design feature: GotoURL is not supported by ordinary applications running in the thick client mode.
		Notification = New NotifyDescription;
		BeginRunningApplication(Notification, Ref);
	#Else
		GotoURL(Ref);
	#EndIf
	
EndProcedure

// Obsolete. Please use FileSystemClient.AttachFileOperationsExtension
// Suggests the user to install the file system extension in the web client.
// The function to be incorporated in the beginning of code areas that process files.
//
// Parameters:
//   OnCloseNotifyDescription - NotifyDescription - the description of the procedure to be called 
//                                    once a form is closed. Parameters:
//                                      ExtensionAttached - Boolean - True if the extension is attached.
//                                      AdditionalParameters - Arbitrary - the parameters specified in
//                                                                               OnCloseNotifyDescription.
//   SuggestionText - String - the message text. If the text is not specified, the default text is displayed.
//   CanContinueWithoutInstalling - If True, show the ContinueWithoutInstalling button. If False, 
//                                              show the Cancel button.
//
// Example:
//
//    Notification = New NotifyDescription("PrintDocumentCompletion", ThisObject);
//    MessageText = NStr("en = 'To print the document, install the file system extension.'");
//    CommonClient.ShowFileSystemExtensionInstallationQuestion(Notification, MessageText);
//
//    Procedure PrintDocumentCompletion(ExtensionAttached, AdditionalParameters) Export
//      If ExtensionAttached Then
//        // Script that print a document only if the file system extension is attached.
//        // ...
//      Else
//        // Script that print a document if the file system extension is not attached.
//        // ...
//      EndIf.
Procedure ShowFileSystemExtensionInstallationQuestion(
		OnCloseNotifyDescription, 
		SuggestionText = "", 
		CanContinueWithoutInstalling = True) Export
	
	FileSystemClient.AttachFileOperationsExtension(
		OnCloseNotifyDescription, 
		SuggestionText, 
		CanContinueWithoutInstalling);
	
EndProcedure

// Obsolete. Please use FileSystemClient.AttachFileOperationsExtension
// Suggests the user to attach the file system extension in the web client and, in case of refuse, 
// notifies about impossibility of action continuation.
// Is intended to be used at the beginning of a script that can process files only if the file 
// system extension is attached.
//
// Parameters:
//  OnCloseNotifyDescription - NotifyDescription - the description of the procedure to be called if 
//                                                     the extension is attached. Parameters:
//                                                      Result - Boolean - always True.
//                                                      AdditionalParameters - Undefined.
//  SuggestionText - String - text of suggestion to attach the file system extension.
//                                 If the text is not specified, the default text is displayed.
//  WarningText - String - warning text that notifies the user that the action cannot be continued.
//                                 If the text is not specified, the default text is displayed.
//
// Returns:
//  Boolean - True if the extension is attached.
//   
// Example:
//
//    Notification = New NotifyDescription("PrintDocumentCompletion", ThisObject);
//    MessageText = NStr("en = 'To print the document, install the file system extension.'");
//    CommonClient.CheckFileSystemExtensionAttached(Notification, MessageText);
//
//    Procedure PrintDocumentCompletion(Result, AdditionalParameters) Export
//        // Script that print a document only if the file system extension is attached.
//        // ...
Procedure CheckFileSystemExtensionAttached(OnCloseNotifyDescription, Val SuggestionText = "", 
	Val WarningText = "") Export
	
	Parameters = New Structure("OnCloseNotifyDescription,WarningText", 
		OnCloseNotifyDescription, WarningText, );
	Notification = New NotifyDescription("CheckFileSystemExtensionAttachedCompletion",
		CommonInternalClient, Parameters);
	FileSystemClient.AttachFileOperationsExtension(Notification, SuggestionText);
	
EndProcedure

// Obsolete. Please use FileSystemClient.AttachFileOperationsExtension
// Returns the value of the "Suggest file system extension installation" user setting.
//
// Returns:
//  Boolean - True if the installation is suggested.
//
Function SuggestFileSystemExtensionInstallation() Export
	
	SystemInfo = New SystemInfo();
	ClientID = SystemInfo.ClientID;
	Return CommonServerCall.CommonSettingsStorageLoad(
		"ApplicationSettings/SuggestFileSystemExtensionInstallation", ClientID, True);
	
EndFunction

// Obsolete. Please use FileSystemClient.OpenFile
// Opens the file in the application associated with the file type.
// Prevents executable files from opening.
//
// Parameters:
//  PathToFile - String - the full path to the file to open.
//  Notification - NotifyDescription - notification on file open attempt.
//      If the notification is not specified and an error occurs, the method shows a warning.
//      - ApplicationStarted - Boolean - True if the external application opened successfully.
//      - AdditionalParameters - Arbitrary - a value that was specified when creating the NotifyDescription object.
//
// Example:
//  CommonClient.OpenFileInViewer(DocumentsDir() + "test.pdf");
//  CommonClient.OpenFileInViewer(DocumentsDir() + "test.xlsx");
//
Procedure OpenFileInViewer(PathToFile, Val Notification = Undefined) Export
	
	If Notification = Undefined Then 
		FileSystemClient.OpenFile(PathToFile);
	Else
		OpeningParameters = FileSystemClient.FileOpeningParameters();
		OpeningParameters.ForEditing = True;
		FileSystemClient.OpenFile(PathToFile, Notification,, OpeningParameters);
	EndIf;
	
EndProcedure

// Obsolete. Please use FileSystemClient.OpenExplorer
// Opens Windows Explorer to the specified directory.
// If a file path is specified, the pointer is placed on the file.
//
// Parameters:
//  PathToDirectoryOrFile - String - the full path to a file or folder on the drive.
//
// Example:
//  // For Windows OS
//  CommonClient.OpenExplorer("C:\Users");
//  CommonClient.OpenExplorer("C:\Program Files\1cv8\common\1cestart.exe");
//  // For Linux OS
//  CommonClient.OpenExplorer("/home/");
//  CommonClient.OpenExplorer("/opt/1C/v8.3/x86_64/1cv8c");
//
Procedure OpenExplorer(PathToDirectoryOrFile) Export
	
	FileSystemClient.OpenExplorer(PathToDirectoryOrFile);
	
EndProcedure

// Obsolete. Please use FileSystemClient.OpenURL
// Opens a URL in an application associated with URL protocol.
//
// Valid protocols: http, https, e1c, v8help, mailto, tel, skype.
//
// Do not use protocol file:// to open Explorer or a file.
// - To Open Explorer, use OpenExplorer. 
// - To open a file in an associated application, use OpenFileInViewer. 
//
// Parameters:
//  URL - Reference - a link to open.
//  Notification - NotifyDescription - notification on file open attempt.
//      If the notification is not specified and an error occurs, the method shows a warning.
//      - ApplicationStarted - Boolean - True if the external application opened successfully.
//      - AdditionalParameters - Arbitrary - a value that was specified when creating the NotifyDescription object.
//
// Example:
//  CommonClient.OpenURL("e1cib/navigationpoint/startpage"); // Home page.
//  CommonClient.OpenURL("v8help://1cv8/QueryLanguageFullTextSearchInData");
//  CommonClient.OpenURL("https://1c.ru");
//  CommonClient.OpenURL("mailto:help@1c.ru");
//  CommonClient.OpenURL("skype:echo123?call");
//
Procedure OpenURL(URL, Val Notification = Undefined) Export
	
	FileSystemClient.OpenURL(URL, Notification);
	
EndProcedure

// Obsolete. Please use FileSystemClient.CreateTemporaryDirectory
// Gets temporary directory name.
//
// Parameters:
//  Notification - NotifyDescription - notification on getting directory name attempt.
//      * DirectoryName - String - path to the directory.
//      * AdditionalParameters - Structure - a value that was specified when creating the NotifyDescription object.
//  Extension - Sting - the suffix in the directory name, which helps to identify the directory for analysis.
//
Procedure CreateTemporaryDirectory(Val Notification, Extension = "") Export 
	
	FileSystemClient.CreateTemporaryDirectory(Notification, Extension);
	
EndProcedure

#EndRegion

#EndRegion
