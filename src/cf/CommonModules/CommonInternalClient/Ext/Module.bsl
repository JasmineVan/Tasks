///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// Checks whether the passed string is an internal URL.
//  
// Parameters:
//  String - String - URL.
//
// Returns:
//  Boolean -  a check result.
//
Function IsURL(Row) Export
	
	Return StrStartsWith(Row, "e1c:")
		Or StrStartsWith(Row, "e1cib/")
		Or StrStartsWith(Row, "e1ccs/");
	
EndFunction

// Converts startup parameters of the current session to the parameters to be passed to the script
// For example, using the following key, you can sign in to the application:
// /C ExternalOperationStartupParameters=/TestClient -TPort 48050 /C DebugMode;DebugMode
// Forwards to the script /TestClient -TPort 48050 /C DebugMode
//
// Returns:
//  String - a parameter value.
//
Function EnterpriseStartupParametersFromScript() Export
	
	Var ParameterValue;
	
	StartParameters = StringFunctionsClientServer.ParametersFromString(LaunchParameter);
	If Not StartParameters.Property("ExternalOperationStartupParameters", ParameterValue) Then 
		ParameterValue = "";
	EndIf;
	
	Return ParameterValue;
	
EndFunction

#Region AddIns

// Parameters:
//  Context - Structure - procedure context:
//      * Notification - NotifyDescription - .
//      * ID - String - 
//      * Location - String - 
//      * Cached - Boolean -
//      * SuggestInstall - Boolean -.
//      * NoteText - String - .
//      * ObjectsCreationIDs
//
Procedure AttachAddInSSL(Context) Export
	
	If IsBlankString(Context.ID) Then 
		AddInContainsOneObjectClass = (Context.ObjectsCreationIDs.Count() = 0);
		
		If AddInContainsOneObjectClass Then 
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось подключить внешнюю компоненту на клиенте
				           |%1
				           |по причине:
				           |Не допустимо одновременно не указывать и Идентификатор и ИдентификаторыСозданияОбъектов'; 
				           |en = 'Cannot attach the add-in on the client
				           |%1
				           |Reason:
				           |Either the ID or the ObjectsCreationIDs must be specified.'; 
				           |pl = 'Podłączenie do komponentu zewnętrznego nie powiodło się dla klienta
				           |%1
				           |z powodu:
				           |Nie dopuszczalne jest jednocześnie nie wskazywać i ID i ObjectsCreationIDs';
				           |de = 'Eine externe Komponente konnte aus folgendem Grund nicht mit dem Client
				           |%1
				           | verbunden werden:
				           |Es ist nicht erlaubt, nicht gleichzeitig ID und ObjectsCreationIDs anzugeben.';
				           |ro = 'Eșec de conectare a componentei externe pe client
				           |%1
				           |din motivul:
				           |Nu se permite să nu indicați concomitent și ID și ObjectsCreationIDs';
				           |tr = 'Dış bileşen 
				           |%1
				           |istemcide aşağıdaki nedenle bağlanamadı: 
				           | ID ve ObjectsCreationIDs aynı anda belirtilmesine izin verilmez'; 
				           |es_ES = 'No se ha podido conectar el componente externo en el cliente
				           |%1
				           |a causa de:
				           |Se debe especificar el ID o los ObjectsCreationIDs.'"), 
				Context.Location);
		Else
			// In case when the add in contains several classes of objects.
			// An ID is used only to display the add in in the texts of errors.
			// Collect the ID to display.
			Context.ID = StrConcat(Context.ObjectsCreationIDs, ", ");
		EndIf;
	EndIf;
	
	If Not ValidAddInLocation(Context.Location) Then 
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось подключить внешнюю компоненту ""%1"" на клиенте
			           |%2
			           |по причине:
			           |Не допустимо подключить компоненты из указанного местоположения.'; 
			           |en = 'Cannot attach add-in ""%1"" on the client
			           |%2
			           |Reason:
			           |Attaching add-ins from this location is not allowed.'; 
			           |pl = 'Podłączenie do komponentu zewnętrznego nie powiodło się ""%1"" dla klienta
			           |%2
			           |z powodu:
			           |Nie dopuszczalne jest podłączenie komponentów ze wskazanej lokalizacji.';
			           |de = 'Eine externe Komponente ""%1"" konnte auf dem Client
			           |%2
			           |nicht verbunden werden, da:
			           |Es ist nicht erlaubt, Komponenten vom angegebenen Standort aus zu verbinden.';
			           |ro = 'Eșec de conectare a componentei externe ""%1"" pe client
			           |%2
			           |din motivul:
			           |Nu se permite conectarea componentei din locația indicată.';
			           |tr = 'Harici bileşen ""%1"" istemcide aşağıdaki nedenle 
			           |%2
			           |bağlanamadı: 
			           |bileşenlerin belirtilen konumdan bağlanmasına izin verilmez.'; 
			           |es_ES = 'No se ha podido conectar un componente externo ""%1"" en el cliente 
			           |%2
			           |a causa de:
			           |No se admite conectar los componentes de la ubicación indicada.'"), 
			Context.ID,
			Context.Location);
	EndIf;
	
	If Context.Cached Then 
		
		AttachableModule = GetAddInObjectFromCache(Context.Location);
		If AttachableModule <> Undefined Then 
			AttachAddInSSLNotifyOnAttachment(AttachableModule, Context);
			Return;
		EndIf;
		
	EndIf;
	
	// Checking the connection of the external add in in this session earlier.
	SymbolicName = GetAddInSymbolicNameFromCache(Context.Location);
	
	If SymbolicName = Undefined Then 
		
		// Generating a unique name.
		SymbolicName = "From" + StrReplace(String(New UUID), "-", "");
		
		Context.Insert("SymbolicName", SymbolicName);
		
		Notification = New NotifyDescription(
			"AttachAddInSSLAfterAttachmentAttempt", ThisObject, Context,
			"AttachAddInSSLOnProcessError", ThisObject);
		
		BeginAttachingAddIn(Notification, Context.Location, SymbolicName);
		
	Else 
		
		// If the cache already has a symbolic name, it means that the add-in has already been attached to this session.
		Attached = True;
		Context.Insert("SymbolicName", SymbolicName);
		AttachAddInSSLAfterAttachmentAttempt(Attached, Context);
		
	EndIf;
	
EndProcedure

// Continue the AttachAddInSSL procedure.
Procedure AttachAddInSSLNotifyOnAttachment(AttachableModule, Context) Export
	
	Result = AddInAttachmentResult();
	Result.Attached = True;
	Result.AttachableModule = AttachableModule;
	ExecuteNotifyProcessing(Context.Notification, Result);
	
EndProcedure

// Continue the AttachAddInSSL procedure.
Procedure AttachAddInSSLNotifyOnError(ErrorDescription, Context) Export
	
	Notification = Context.Notification;
	
	Result = AddInAttachmentResult();
	Result.ErrorDescription = ErrorDescription;
	ExecuteNotifyProcessing(Notification, Result);
	
EndProcedure

// Parameters:
//  Context - Structure - procedure context:
//      * Notification - NotifyDescription - .
//      * Location - String -
//      * NoteText - String - .
//
Procedure InstallAddInSSL(Context) Export
	
	If Not ValidAddInLocation(Context.Location) Then 
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось установить внешнюю компоненту ""%1"" на клиенте
			           |%2
			           |по причине:
			           |Не допустимо устанавливать компоненты из указанного местоположения.'; 
			           |en = 'Cannot install add-in ""%1"" on the client
			           |%2
			           |Reason:
			           |Installing add-ins from this location is not allowed.'; 
			           |pl = 'Nie udało się ustawić komponent zewnętrzny ""%1"" dla klienta
			           |%2
			           |z powodu:
			           |Nie dopuszczalne jest ustawienie komponentu ze wskazanej lokalizacji.';
			           |de = 'Die externe Komponente ""%1"" konnte auf dem Client
			           |%2
			           | aus folgendem Grund nicht installiert werden:
			           |Es ist nicht erlaubt, Komponenten vom angegebenen Ort aus zu installieren.';
			           |ro = 'Eșec de instalare a componentei externe ""%1"" pe client
			           |%2
			           |din motivul:
			           |Nu se permite instalarea componentei din locația indicată.';
			           |tr = 'Harici bileşen ""%1"" istemcide aşağıdaki nedenle 
			           |%2
			           |bağlanamadı: 
			           |bileşenlerin belirtilen konumdan bağlanmasına izin verilmez.'; 
			           |es_ES = 'No se ha podido instalar un componente externo ""%1"" en el cliente 
			           |%2
			           |a causa de:
			           |No se admite instalar los componentes de la ubicación indicada.'"), 
			Context.ID,
			Context.Location);
	EndIf;
	
	// Checking the connection of the external add in in this session earlier.
	SymbolicName = GetAddInSymbolicNameFromCache(Context.Location);
	
	If SymbolicName = Undefined Then
		
		Notification = New NotifyDescription(
			"InstallAddInSSLAfterAnswerToInstallationQuestion", ThisObject, Context);
		
		FormParameters = New Structure;
		FormParameters.Insert("NoteText", Context.NoteText);
		
		OpenForm("CommonForm.AddInInstallationQuestion", 
			FormParameters,,,,, Notification);
		
	Else 
		
		// If the cache already has a symbolic name, it means that the add-in has already been attached to 
		// this session and it means that the external add-in is installed.
		Result = AddInInstallationResult();
		Result.Insert("Installed", True);
		ExecuteNotifyProcessing(Context.Notification, Result);
		
	EndIf;
	
EndProcedure

// Continue the InstallAddInSSL procedure.
Procedure InstallAddInSSLNotifyOnError(ErrorDescription, Context) Export
	
	Notification = Context.Notification;
	
	Result = AddInInstallationResult();
	Result.ErrorDescription = ErrorDescription;
	ExecuteNotifyProcessing(Notification, Result);
	
EndProcedure

#EndRegion

#Region SpreadsheetDocument

////////////////////////////////////////////////////////////////////////////////
// Spreadsheet document functions.

// Generates the selected area details of the spreadsheet document.
//
// Parameters:
//  SpreadsheetDocument - SpreadsheetDocument - a document whose cell values are included in the settlement.
//
// Returns:
//   Structure - contains:
//       * SelectedAreas - Array - contains structures with the following properties:
//           * Top - Number - a row number of the upper area boun.
//           * Bottom - Number - a row number of the lower area bound.
//           * Left - Number - a column number of the upper area bound.
//           * Right - Number - a column number of the lower area bound.
//           * AreaType - SpreadsheetDocumentCellsAreaType - Columns, Rectangle, Rows, Table.
//       * CalculateAtServer - Boolean - indicates whether the settlement must be executed on the server.
//
Function CellsIndicatorsCalculationParameters(SpreadsheetDocument) Export 
	IndicatorsCalculationParameters = New Structure;
	IndicatorsCalculationParameters.Insert("SelectedAreas", New Array);
	IndicatorsCalculationParameters.Insert("CalculateAtServer", False);
	
	SelectedAreas = IndicatorsCalculationParameters.SelectedAreas;
	For Each SelectedArea In SpreadsheetDocument.SelectedAreas Do
		If TypeOf(SelectedArea) <> Type("SpreadsheetDocumentRange") Then
			Continue;
		EndIf;
		AreaBoundaries = New Structure("Top, Bottom, Left, Right, AreaType");
		FillPropertyValues(AreaBoundaries, SelectedArea);
		SelectedAreas.Add(AreaBoundaries);
	EndDo;
	
	SelectedAll = False;
	If SelectedAreas.Count() = 1 Then 
		SelectedArea = SelectedAreas[0];
		SelectedAll = Not Boolean(
			SelectedArea.Top
			+ SelectedArea.Bottom
			+ SelectedArea.Left
			+ SelectedArea.Right);
	EndIf;
	
	IndicatorsCalculationParameters.CalculateAtServer = (SelectedAll Or SelectedAreas.Count() >= 100);
	
	Return IndicatorsCalculationParameters;
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region Data

#Region CopyRecursive

Function CopyStructure(SourceStructure, FixData) Export 
	
	ResultingStructure = New Structure;
	
	For Each KeyAndValue In SourceStructure Do
		ResultingStructure.Insert(KeyAndValue.Key, 
			CommonClient.CopyRecursive(KeyAndValue.Value, FixData));
	EndDo;
	
	If FixData = True 
		Or FixData = Undefined
		AND TypeOf(SourceStructure) = Type("FixedStructure") Then 
		Return New FixedStructure(ResultingStructure);
	EndIf;
	
	Return ResultingStructure;
	
EndFunction

Function CopyMap(SourceMap, FixData) Export 
	
	ResultingMap = New Map;
	
	For Each KeyAndValue In SourceMap Do
		ResultingMap.Insert(KeyAndValue.Key, 
			CommonClient.CopyRecursive(KeyAndValue.Value, FixData));
	EndDo;
	
	If FixData = True 
		Or FixData = Undefined
		AND TypeOf(SourceMap) = Type("FixedMap") Then 
		Return New FixedMap(ResultingMap);
	EndIf;
	
	Return ResultingMap;
	
EndFunction

Function CopyArray(SourceArray, FixData) Export 
	
	ResultingArray = New Array;
	
	For Each Item In SourceArray Do
		ResultingArray.Add(CommonClient.CopyRecursive(Item, FixData));
	EndDo;
	
	If FixData = True 
		Or FixData = Undefined
		AND TypeOf(SourceArray) = Type("FixedArray") Then 
		Return New FixedArray(ResultingArray);
	EndIf;
	
	Return ResultingArray;
	
EndFunction

Function CopyValueList(SourceList, FixData) Export
	
	ResultingList = New ValueList;
	
	For Each ListItem In SourceList Do
		ResultingList.Add(
			CommonClient.CopyRecursive(ListItem.Value, FixData), 
			ListItem.Presentation, 
			ListItem.Check, 
			ListItem.Picture);
	EndDo;
	
	Return ResultingList;
	
EndFunction

#EndRegion

#EndRegion

#Region Forms

Function MetadataObjectName(Type) Export
	
	ParameterName = "StandardSubsystems.MetadataObjectNames";
	If ApplicationParameters[ParameterName] = Undefined Then
		ApplicationParameters.Insert(ParameterName, New Map);
	EndIf;
	MetadataObjectNames = ApplicationParameters[ParameterName];
	
	Result = MetadataObjectNames[Type];
	If Result = Undefined Then
		Result = StandardSubsystemsServerCall.MetadataObjectName(Type);
		MetadataObjectNames.Insert(Type, Result);
	EndIf;
	
	Return Result;
	
EndFunction

Procedure ConfirmFormClosing() Export
	
	ParameterName = "StandardSubsystems.FormClosingConfirmationParameters";
	If ApplicationParameters[ParameterName] = Undefined Then
		ApplicationParameters.Insert(ParameterName, Undefined);
	EndIf;
	
	Parameters = ApplicationParameters["StandardSubsystems.FormClosingConfirmationParameters"];
	If Parameters = Undefined Then
		Return;
	EndIf;
	
	Notification = New NotifyDescription("ConfirmFormClosingCompletion", ThisObject, Parameters);
	If IsBlankString(Parameters.WarningText) Then
		QuestionText = NStr("ru = 'Данные были изменены. Сохранить изменения?'; en = 'The data was changed. Do you want to save the changes?'; pl = 'Dane zostały zmienione. Czy chcesz zapisać zmiany?';de = 'Die Daten wurden geändert. Möchten Sie Änderungen speichern?';ro = 'Data was changed. Do you want to save changes?';tr = 'Veri değiştirildi. Değişiklikleri kaydetmek istiyor musunuz?'; es_ES = 'Datos se han cambiado. ¿Quiere guardar los cambios?'");
	Else
		QuestionText = Parameters.WarningText;
	EndIf;
	
	ShowQueryBox(Notification, QuestionText, QuestionDialogMode.YesNoCancel, ,
		DialogReturnCode.No);
	
EndProcedure

Procedure ConfirmFormClosingCompletion(Response, Parameters) Export
	
	ApplicationParameters["StandardSubsystems.FormClosingConfirmationParameters"] = Undefined;
	
	If Response = DialogReturnCode.Yes Then
		ExecuteNotifyProcessing(Parameters.SaveAndCloseNotification);
		
	ElsIf Response = DialogReturnCode.No Then
		Form = Parameters.SaveAndCloseNotification.Module;
		Form.Modified = False;
		Form.Close();
	Else
		Form = Parameters.SaveAndCloseNotification.Module;
		Form.Modified = True;
	EndIf;
	
EndProcedure

Procedure ConfirmArbitraryFormClosing() Export
	
	ParameterName = "StandardSubsystems.FormClosingConfirmationParameters";
	If ApplicationParameters[ParameterName] = Undefined Then
		ApplicationParameters.Insert(ParameterName, Undefined);
	EndIf;
	
	Parameters = ApplicationParameters["StandardSubsystems.FormClosingConfirmationParameters"];
	If Parameters = Undefined Then
		Return;
	EndIf;
	ApplicationParameters["StandardSubsystems.FormClosingConfirmationParameters"] = Undefined;
	QuestionMode = QuestionDialogMode.YesNo;
	
	Notification = New NotifyDescription("ConfirmArbitraryFormClosingCompletion", ThisObject, Parameters);
	
	ShowQueryBox(Notification, Parameters.WarningText, QuestionMode);
	
EndProcedure

Procedure ConfirmArbitraryFormClosingCompletion(Response, Parameters) Export
	
	Form = Parameters.Form;
	If Response = DialogReturnCode.Yes
		Or Response = DialogReturnCode.OK Then
		Form[Parameters.CloseFormWithoutConfirmationAttributeName] = True;
		If Parameters.CloseNotifyDescription <> Undefined Then
			ExecuteNotifyProcessing(Parameters.CloseNotifyDescription);
		EndIf;
		Form.Close();
	Else
		Form[Parameters.CloseFormWithoutConfirmationAttributeName] = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region EditingForms

Procedure CommentInputCompletion(Val EnteredText, Val AdditionalParameters) Export
	
	If EnteredText = Undefined Then
		Return;
	EndIf;	
	
	FormAttribute = AdditionalParameters.OwnerForm;
	
	PathToFormAttribute = StrSplit(AdditionalParameters.AttributeName, ".");
	// If the type of the attribute is "Object.Comment" and so on
	If PathToFormAttribute.Count() > 1 Then
		For Index = 0 To PathToFormAttribute.Count() - 2 Do 
			FormAttribute = FormAttribute[PathToFormAttribute[Index]];
		EndDo;
	EndIf;	
	
	FormAttribute[PathToFormAttribute[PathToFormAttribute.Count() - 1]] = EnteredText;
	AdditionalParameters.OwnerForm.Modified = True;
	
EndProcedure

#EndRegion

#Region AddIns

#Region AttachAddIn

// Continue the AttachAddInSSL procedure.
Procedure AttachAddInSSLAfterAttachmentAttempt(Attached, Context) Export 
	
	If Attached Then 
		
		// Saving the fact of attaching the external add-in to this session.
		WriteAddInSymbolicNameToCache(Context.Location, Context.SymbolicName);
		
		AttachableModule = Undefined;
		
		Try
			AttachableModule = NewAddInObject(Context);
		Except
			// The error text has already been composed to the NewAddInObject, you just need to notify.
			ErrorText = BriefErrorDescription(ErrorInfo());
			AttachAddInSSLNotifyOnError(ErrorText, Context);
			Return;
		EndTry;
		
		If Context.Cached Then 
			WriteAddInObjectToCache(Context.Location, AttachableModule)
		EndIf;
		
		AttachAddInSSLNotifyOnAttachment(AttachableModule, Context);
		
	Else 
		
		If Context.SuggestInstall Then 
			AttachAddInSSLStartInstallation(Context);
		Else 
			ErrorText =  StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось подключить внешнюю компоненту ""%1"" на клиенте
				           |%2
				           |по причине:
				           |Метод НачатьПодключениеВнешнейКомпоненты вернул Ложь.'; 
				           |en = 'Cannot attach add-in ""%1"" on the client
				           |%2
				           |Reason:
				           |Method BeginAttachingAddIn returned False.'; 
				           |pl = 'Podłączenie do komponentu zewnętrznego nie powiodło się ""%1"" dla klienta
				           |%2
				           |z powodu:
				           |Metoda BeginAttachingAddIn wrócił Falsz.';
				           |de = 'Die externe Komponente ""%1"" konnte aus folgendem Grund nicht auf dem Client
				           |%2
				           |verbunden werden:
				           |Methode BeginAttachingAddIn gaben False zurück.';
				           |ro = 'Eșec de conectare a componentei externe ""%1"" pe client
				           |%2
				           |din motivul:
				           |Metoda BeginAttachingAddIn a returnat Ложь.';
				           |tr = '
				           | istemcinin ""%1"" harici bileşeni ""%2""
				           | nedenle bağlanamadı: 
				           |Yöntem BeginAttachingAddIn iade etti Yanlış.'; 
				           |es_ES = 'No se ha podido conectar un componente externo ""%1"" en el cliente
				           |de la plantilla ""%2""
				           |a causa de:
				           |Método BeginAttachingAddIn ha devuelto Falso.'"),
				Context.ID,
				AddInLocationPresentation(Context.Location));
			
			AttachAddInSSLNotifyOnError(ErrorText, Context);
		EndIf;
		
	EndIf;
	
EndProcedure

// Continue the AttachAddInSSL procedure.
Procedure AttachAddInSSLStartInstallation(Context)
	
	Notification = New NotifyDescription(
		"AttachAddInSSLAfterInstallation", ThisObject, Context);
	
	InstallationContext = New Structure;
	InstallationContext.Insert("Notification", Notification);
	InstallationContext.Insert("Location", Context.Location);
	InstallationContext.Insert("NoteText", Context.NoteText);
	
	InstallAddInSSL(InstallationContext);
	
EndProcedure

// Continue the AttachAddInSSL procedure.
Procedure AttachAddInSSLAfterInstallation(Result, Context) Export 
	
	If Result.Installed Then 
		// One attempt to install has already passed, if the component does not connect this time, do not 
		// offer to install it again.
		Context.SuggestInstall = False;
		AttachAddInSSL(Context);
	Else 
		// Adding details to ErrorDescription is not required as the text has already been generated during the installation.
		// If a user canceled the installation, ErrorDescription is a blank string.
		AttachAddInSSLNotifyOnError(Result.ErrorDescription, Context);
	EndIf;
	
EndProcedure

// Continue the AttachAddInSSL procedure.
Procedure AttachAddInSSLOnProcessError(ErrorInformation, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	
	ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Не удалось подключить внешнюю компоненту ""%1"" на клиенте
		           |%2
		           |по причине:
		           |%3'; 
		           |en = 'Cannot attach add-in ""%1"" on the client
		           |%2
		           |Reason:
		           |%3'; 
		           |pl = 'Podłączenie do komponentu zewnętrznego nie powiodło się ""%1"" dla klienta
		           |%2
		           |z powodu:
		           |%3';
		           |de = 'Eine externe Komponente ""%1"" konnte aus diesem Grund auf dem Client
		           |%2
		           |nicht angeschlossen werden:
		           |%3';
		           |ro = 'Eșec de conectare a componentei externe ""%1"" pe client
		           |%2
		           |din motivul:
		           |%3';
		           |tr = '
		           | istemcinin ""%1"" harici bileşeni ""%2""
		           | nedenle bağlanamadı: 
		           |%3'; 
		           |es_ES = 'No se ha podido conectar un componente externo ""%1"" en el cliente
		           |%2
		           |a causa de:
		           |%3'"),
		Context.ID,
		AddInLocationPresentation(Context.Location),
		BriefErrorDescription(ErrorInformation));
		
	AttachAddInSSLNotifyOnError(ErrorText, Context);
	
EndProcedure

// Creates an instance of external component (or a couple of instances)
Function NewAddInObject(Context)
	
	AddInContainsOneObjectClass = (Context.ObjectsCreationIDs.Count() = 0);
	
	If AddInContainsOneObjectClass Then 
		
		Try
			AttachableModule = New("AddIn." + Context.SymbolicName + "." + Context.ID);
			If AttachableModule = Undefined Then 
				Raise NStr("ru = 'Оператор Новый вернул Неопределено'; en = 'The New operator returned Undefined.'; pl = 'Operator Nowy zwrócił Nieokreślone';de = 'Operator Neu zurückgegeben Undefiniert';ro = 'Operatorul Nou a returnat Nedefinit';tr = 'Operatör Yeni iade etti Belirsiz'; es_ES = 'Operador Nuevo ha devuelto No determinado'");
			EndIf;
		Except
			AttachableModule = Undefined;
			ErrorText = BriefErrorDescription(ErrorInfo());
		EndTry;
		
		If AttachableModule = Undefined Then 
			
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось создать объект внешней компоненты ""%1"", подключенной на клиенте
				           |%2,
				           |по причине:
				           |%3'; 
				           |en = 'Cannot create an object for add-in ""%1"" attached on the client
				           |%2
				           |Reason:
				           |%3'; 
				           |pl = 'Nie udało się utworzyć  obiekt komponentów zewnętrznych ""%1"", podłączonych dla klienta
				           |%2,
				           |z powodu:
				           |%3';
				           |de = 'Es war nicht möglich, ein Objekt der externen Komponente ""%1"" zu erstellen, das mit dem Client
				           |%2
				           | verbunden ist, aus folgendem Grund:
				           |%3';
				           |ro = 'Eșec la crearea obiectului componentei externe ""%1"" conectate pe clientul 
				           |%2,
				           |din motivul:
				           |%3';
				           |tr = '%1 sunucuda bağlanan "
" harici bileşenin nesnesi ""%2"" oluşturulamadı, 
				           | nedeni: 
				           |%3'; 
				           |es_ES = 'No se ha podido crear un objeto del componente externo ""%1"" conectado en el cliente
				           |%2
				           |a causa de:
				           |%3'"),
				Context.ID,
				AddInLocationPresentation(Context.Location),
				ErrorText);
			
		EndIf;
		
	Else 
		
		AttachableModules = New Map;
		For each ObjectID In Context.ObjectsCreationIDs Do 
			
			Try
				AttachableModule = New("AddIn." + Context.SymbolicName + "." + ObjectID);
				If AttachableModule = Undefined Then 
					Raise NStr("ru = 'Оператор Новый вернул Неопределено'; en = 'The New operator returned Undefined.'; pl = 'Operator Nowy zwrócił Nieokreślone';de = 'Operator Neu zurückgegeben Undefiniert';ro = 'Operatorul Nou a returnat Nedefinit';tr = 'Operatör Yeni iade etti Belirsiz'; es_ES = 'Operador Nuevo ha devuelto No determinado'");
				EndIf;
			Except
				AttachableModule = Undefined;
				ErrorText = BriefErrorDescription(ErrorInfo());
			EndTry;
			
			If AttachableModule = Undefined Then 
				
				Raise StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Не удалось создать объект ""%1"" внешней компоненты ""%2"", подключенной на клиенте
					           |%3,
					           |по причине:
					           |%4'; 
					           |en = 'Cannot create object ""%1"" for add-in ""%2"" attached on the client
					           |%3
					           |Reason:
					           |%4'; 
					           |pl = 'Nie udało się utworzyć  obiekt ""%1"" komponentów zewnętrznych ""%2"", jest podłączonych dla klienta
					           |%3,
					           |z powodu:
					           |%4';
					           |de = 'Das Objekt ""%1"" der mit dem Client
					           |%3 verbundenen externen Komponente ""%2"" konnte aus 
					           |folgendem Grund nicht erstellt werden:
					           |%4';
					           |ro = 'Eșec la crearea obiectului ""%1"" al componentei externe ""%2"" conectate pe clientul 
					           |%3,
					           |din motivul:
					           |%4';
					           |tr = '%1 sunucuda bağlanan "
" harici bileşenin nesnesi ""%2"" oluşturulamadı, 
					           | nedeni: 
					           |%3%4'; 
					           |es_ES = 'No se ha podido crear un objeto ""%1"" del componente externo ""%2"" conectado en el cliente
					           |%3
					           |a causa de:
					           |%4'"),
					ObjectID,
					Context.ID,
					AddInLocationPresentation(Context.Location),
					ErrorText);
				
			EndIf;
			
			AttachableModules.Insert(ObjectID, AttachableModule);
			
		EndDo;
		
		AttachableModule = New FixedMap(AttachableModules);
		
	EndIf;
	
	Return AttachableModule;
	
EndFunction

// Continue the AttachAddInSSL procedure.
Function AddInAttachmentResult()
	
	Result = New Structure;
	Result.Insert("Attached", False);
	Result.Insert("ErrorDescription", "");
	Result.Insert("AttachableModule", Undefined);
	
	Return Result;
	
EndFunction

// Continue the AttachAddInSSL procedure.
Function AddInLocationPresentation(Location)
	
	If StrStartsWith(Location, "e1cib/") Then
		Return NStr("ru = 'из хранилища внешних компонент'; en = 'from an external component storage.'; pl = 'z przechowywania komponentów zewnętrznych';de = 'aus dem Speicher externer Komponenten';ro = 'din storagele componentelor externe';tr = 'harici bileşenlerin deposundan'; es_ES = 'del almacenamiento de los componentes externos'");
	Else 
		Return StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'из макета ""%1""'; en = 'from template ""%1.""'; pl = 'z makiety ""%1""';de = 'aus dem Modell ""%1""';ro = 'din macheta ""%1""';tr = 'maketten %1'; es_ES = 'de la plantilla ""%1""'"),
			Location);
	EndIf;
	
EndFunction

#EndRegion

#Region InstallAddIn

// Continue the InstallAddInSSL procedure.
Procedure InstallAddInSSLAfterAnswerToInstallationQuestion(Response, Context) Export
	
	// Result:
	// - DialogReturnCode.Yes - Install.
	// - DialogReturnCode.Cancel - Cancel
	// - Undefined - the dialog box is closed.
	If Response = DialogReturnCode.Yes Then
		InstallAddInSSLStartInstallation(Context);
	Else
		Result = AddInInstallationResult();
		ExecuteNotifyProcessing(Context.Notification, Result);
	EndIf;
	
EndProcedure

// Continue the InstallAddInSSL procedure.
Procedure InstallAddInSSLStartInstallation(Context)
	
	Notification = New NotifyDescription(
		"InstallAddInSSLAfterInstallationAttempt", ThisObject, Context,
		"InstallAddInSSLOnProcessError", ThisObject);
	
	BeginInstallAddIn(Notification, Context.Location);
	
EndProcedure

// Continue the InstallAddInSSL procedure.
Procedure InstallAddInSSLAfterInstallationAttempt(Context) Export 
	
	Result = AddInInstallationResult();
	Result.Insert("Installed", True);
	
	ExecuteNotifyProcessing(Context.Notification, Result);
	
EndProcedure

// Continue the InstallAddInSSL procedure.
Procedure InstallAddInSSLOnProcessError(ErrorInformation, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	
	ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Не удалось установить внешнюю компоненту ""%1"" на клиенте 
		           |%2
		           |по причине:
		           |%3'; 
		           |en = 'Cannot install add-in ""%1"" on the client
		           |%2
		           |Reason:
		           |%3'; 
		           |pl = 'Nie udało się ustawić komponent zewnętrzny ""%1"" dla klienta 
		           |%2
		           |z powodu:
		           |%3';
		           |de = 'Eine externe Komponente ""%1"" konnte auf dem Client 
		           |%2
		           |nicht installiert werden, wegen:
		           |%3';
		           |ro = 'Eșec la instalarea componentei externe ""%1"" pe clientul 
		           |%2
		           |din motivul:
		           |%3';
		           |tr = '
		           | istemcinin ""%1"" harici bileşeni ""%2""
		           | nedenle bağlanamadı: 
		           |%3'; 
		           |es_ES = 'No se ha podido instalar un componente externo ""%1"" en el cliente
		           |%2
		           |a causa de:
		           |%3'"),
		Context.ID,
		AddInLocationPresentation(Context.Location),
		BriefErrorDescription(ErrorInformation));
	
	Result = AddInInstallationResult();
	Result.ErrorDescription = ErrorText;
	
	ExecuteNotifyProcessing(Context.Notification, Result);
	
EndProcedure

// Continue the InstallAddInSSL procedure.
Function AddInInstallationResult()
	
	Result = New Structure;
	Result.Insert("Installed", False);
	Result.Insert("ErrorDescription", "");
	
	Return Result;
	
EndFunction

#EndRegion

// Check the correctness of add-in location.
Function ValidAddInLocation(Location)
	
	If CommonClient.SubsystemExists("StandardSubsystems.AddIns") Then
		ModuleAddInsInternalClient = CommonClient.CommonModule("AddInsInternalClient");
		If ModuleAddInsInternalClient.IsComponentFromStorage(Location) Then
			Return True;
		EndIf;
	EndIf;
	
	If CommonClient.SubsystemExists("StandardSubsystems.SaaS.AddInsSaaS") Then
		ModuleAddInsSaaSInternalClient = CommonClient.CommonModule("AddInsSaaSInternalClient");
		If ModuleAddInsSaaSInternalClient.IsComponentFromStorage(Location) Then
			Return True;
		EndIf;
	EndIf;
	
	Return IsTemplate(Location);
	
EndFunction

// Checks that the location indicates the add-in.
Function IsTemplate(Location)
	
	PathSteps = StrSplit(Location, ".");
	If PathSteps.Count() < 2 Then 
		Return False;
	EndIf;
	
	Path = New Structure;
	Try
		For each PathStep In PathSteps Do 
			Path.Insert(PathStep);
		EndDo;
	Except
		Return False;
	EndTry;
	
	Return True;
	
EndFunction

// Gets the symbolic name of the external add-in from the cache, if it was previously attached.
Function GetAddInSymbolicNameFromCache(ObjectKey)
	
	SymbolicName = Undefined;
	CachedSymbolicNames = ApplicationParameters["StandardSubsystems.AddIns.SymbolicNames"];
	
	If TypeOf(CachedSymbolicNames) = Type("FixedMap") Then
		SymbolicName = CachedSymbolicNames.Get(ObjectKey);
	EndIf;
	
	Return SymbolicName;
	
EndFunction

// Writes the symbolic name of the external add-in to the cache.
Procedure WriteAddInSymbolicNameToCache(ObjectKey, SymbolicName)
	
	Map = New Map;
	CachedSymbolicNames = ApplicationParameters["StandardSubsystems.AddIns.SymbolicNames"];
	
	If TypeOf(CachedSymbolicNames) = Type("FixedMap") Then
		
		If CachedSymbolicNames.Get(ObjectKey) <> Undefined Then // It is already in the cache.
			Return;
		EndIf;
		
		For each Item In CachedSymbolicNames Do
			Map.Insert(Item.Key, Item.Value);
		EndDo;
		
	EndIf;
	
	Map.Insert(ObjectKey, SymbolicName);
	
	ApplicationParameters.Insert("StandardSubsystems.AddIns.SymbolicNames",
		New FixedMap(Map));
	
EndProcedure

// Receives an object that is an instance of the add-in from the cache.
Function GetAddInObjectFromCache(ObjectKey)
	
	AttachableModule = Undefined;
	CachedObjects = ApplicationParameters["StandardSubsystems.AddIns.Objects"];
	
	If TypeOf(CachedObjects) = Type("FixedMap") Then
		AttachableModule = CachedObjects.Get(ObjectKey);
	EndIf;
	
	Return AttachableModule;
	
EndFunction

// Writes the instance of the add-in to the cache.
Procedure WriteAddInObjectToCache(ObjectKey, AttachableModule)
	
	Map = New Map;
	CachedObjects = ApplicationParameters["StandardSubsystems.AddIns.Objects"];
	
	If TypeOf(CachedObjects) = Type("FixedMap") Then
		For each Item In CachedObjects Do
			Map.Insert(Item.Key, Item.Value);
		EndDo;
	EndIf;
	
	Map.Insert(ObjectKey, AttachableModule);
	
	ApplicationParameters.Insert("StandardSubsystems.AddIns.Objects",
		New FixedMap(Map));
	
EndProcedure

#EndRegion

#Region ExternalConnection

// The procedure that follows CommonClient.RegisterCOMConnector.
Procedure RegisterCOMConnectorOnCheckRegistration(Result, Context) Export
	
	ApplicationStarted = Result.ApplicationStarted;
	ErrorDescription = Result.ErrorDescription;
	ReturnCode = Result.ReturnCode;
	RestartSession = Context.RestartSession;
	
	If ApplicationStarted Then
		
		If RestartSession Then
			
			Notification = New NotifyDescription("RegisterCOMConnectorOnCheckAnswerAboutRestart", 
				CommonInternalClient, Context);
			
			QuestionText = 
				NStr("ru = 'Для завершения перерегистрации компоненты comcntr необходимо перезапустить программу.
				           |Перезапустить сейчас?'; 
				           |en = 'To complete the registration of comcntr component, restart the application.
				           |Do you want to restart it now?'; 
				           |pl = 'Dla zakończenia ponownej rejestracji komponentu comcntr należy ponownie uruchomić program.
				           |Zrestartować teraz?';
				           |de = 'Um die Rückmeldung von Comcntr-Komponenten abzuschließen, müssen Sie das Programm neu starten.
				           |Jetzt neu starten?';
				           |ro = 'Pentru a finaliza reînregistrarea componentei comcntr trebuie să reporniți aplicația.
				           |Relansați acum?';
				           |tr = 'Comcntr bileşeninin kaydını bitirmek için uygulamayı yeniden başlatmanız gerekir. 
				           |Şimdi yeniden başlat?'; 
				           |es_ES = 'Para finalizar el registro del componente comcntr, usted tiene que reiniciar la aplicación.
				           |¿Reiniciar ahora?'");
			
			ShowQueryBox(Notification, QuestionText, QuestionDialogMode.YesNo);
			
		Else 
			
			Notification = Context.Notification;
			
			Registered = True;
			ExecuteNotifyProcessing(Notification, Registered);
			
		EndIf;
		
	Else 
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Ошибка при регистрации компоненты comcntr.
			           |Код ошибки regsvr32: %1'; 
			           |en = 'An error occurred registering the comcntr component.
			           |Error code regsvr32: %1'; 
			           |pl = 'Błąd podczas rejestrowania komponentów comcntr.
			           |Kod błędu regsvr32: %1';
			           |de = 'Fehler bei der Registrierung von Comcntr-Komponenten.
			           |Fehlercode regsvr32: %1';
			           |ro = 'Eroare la înregistrarea componentei comcntr.
			           |Codul erorii regsvr32: %1';
			           |tr = 'Comcntr öğesinin kaydı esnasında bir hata oluştu.
			           |Hata kodu regsvr32: %1'; 
			           |es_ES = 'Error al registrar los componentes comcntr.
			           |Código de error regsvr32: %1'"),
			ReturnCode);
			
		If ReturnCode = 5 Then
			MessageText = MessageText + " " + NStr("ru = 'Недостаточно прав доступа.'; en = 'Insufficient access rights.'; pl = 'Niewystarczające prawa dostępu.';de = 'Unzureichende Zugriffsrechte.';ro = 'Drepturi de acces insuficiente.';tr = 'Yetersiz erişim hakları.'; es_ES = 'Insuficientes derechos de acceso.'");
		Else 
			MessageText = MessageText + Chars.LF + ErrorDescription;
		EndIf;
		
		EventLogClient.AddMessageForEventLog(
			NStr("ru = 'Регистрация компоненты comcntr'; en = 'Registration of comcntr component'; pl = 'Rejestracja komponentu Comcntr';de = 'Registrierung der Comcntr-Komponente';ro = 'Înregistrarea componentei comcntr';tr = 'Comcntr bileşen kaydı'; es_ES = 'Registro del componente comcntr'", CommonClient.DefaultLanguageCode()), 
			"Error", 
			MessageText,,
			True);
		
		Notification = New NotifyDescription("RegisterCOMConnectorNotifyOnError", 
			CommonInternalClient, Context);
		
		ShowMessageBox(Notification, MessageText);
		
	EndIf;
	
EndProcedure

// The procedure that follows CommonClient.RegisterCOMConnector.
Procedure RegisterCOMConnectorOnCheckAnswerAboutRestart(Response, Context) Export
	
	If Response = DialogReturnCode.Yes Then
		ApplicationParameters.Insert("StandardSubsystems.SkipExitConfirmation", True);
		Exit(True, True);
	Else 
		RegisterCOMConnectorNotifyOnError(Context);
	EndIf;

EndProcedure

// The procedure that follows CommonClient.RegisterCOMConnector.
Procedure RegisterCOMConnectorNotifyOnError(Context) Export
	
	Notification = Context.Notification;
	
	If Notification <> Undefined Then
		Registered = False;
		ExecuteNotifyProcessing(Notification, Registered);
	EndIf;
	
EndProcedure

// The procedure that follows CommonClient.RegisterCOMConnector.
Function RegisterCOMConnectorRegistrationIsAvailable() Export
	
#If WebClient Or MobileClient Then
	Return False;
#Else
	ClientRunParametersOnStart = StandardSubsystemsClient.ClientParametersOnStart();
	Return Not CommonClient.ClientConnectedOverWebServer()
		AND Not ClientRunParametersOnStart.IsBaseConfigurationVersion
		AND Not ClientRunParametersOnStart.IsTrainingPlatform;
#EndIf
	
EndFunction

#EndRegion

#Region ObsoleteProceduresAndFunctions

#Region FileOperationsExtension

// Obsolete. It is used in CommonClient.CheckFileSystemExtensionAttached.
Procedure CheckFileSystemExtensionAttachedCompletion(ExtensionAttached, AdditionalParameters) Export
	
	If ExtensionAttached Then
		ExecuteNotifyProcessing(AdditionalParameters.OnCloseNotifyDescription);
		Return;
	EndIf;
	
	MessageText = AdditionalParameters.WarningText;
	If IsBlankString(MessageText) Then
		MessageText = NStr("ru = 'Действие недоступно, так как не установлено расширение для веб-клиента 1С:Предприятие.'; en = 'Cannot perform the operation because 1C:Enterprise web client extension is not installed.'; pl = 'Ta czynność jest niedostępna ponieważ rozszerzenie dla klienta sieci Web 1C:Enterprise nie jest zainstalowane.';de = 'Die Aktion ist nicht als Erweiterung für 1C verfügbar: Der Enterprise-Webclient ist nicht installiert.';ro = 'Acțiunea nu este disponibilă, deoarece extensia pentru web-clientul 1C:Enterprise nu este instalată.';tr = 'Eylem 1C:İşletme için bir eklenti olarak mevcut değildir web istemcisi yüklü değil.'; es_ES = 'La acción no está disponible porque una extensión para el cliente web de la 1C:Empresa no está instalada.'")
	EndIf;
	ShowMessageBox(, MessageText);
	
EndProcedure

#EndRegion

#EndRegion

#EndRegion