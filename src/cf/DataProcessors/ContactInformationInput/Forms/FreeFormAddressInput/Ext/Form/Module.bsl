///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

// The form is parameterized:
//
//      Title - String - a form title.
//      FieldsValues - String - a serialized contact information value or an empty string used to 
//                                enter a new one.
//      Presentation - String - an address presentation (used only when working with old data).
//      ContactInformationKind - CatalogRef. ContactInformationKinds, Structure - details of what is 
//                                being edited.
//      Comment - String - an optional comment to be placed in the Comment field.
//
//      ReturnValueList - Boolean - an optional flag indicating a return field value.
//                                 ContactInformation will have the ValueList type (compatibility).
//
//  Selection result:
//      Structure - the following fields:
//          * ContactInformation - String - contact information XML.
//          * Presentation - String - a presentation.
//          * Comment - String - a comment.
//          * EnteredInFreeFormat - Boolean - an input flag.
//

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not Parameters.Property("OpenByScenario") Then
		Raise NStr("ru = 'Обработка не предназначена для непосредственного использования.'; en = 'The data processor is not intended for direct usage.'; pl = 'Opracowanie nie jest przeznaczone do bezpośredniego użycia.';de = 'Der Datenprozessor ist nicht für den direkten Gebrauch bestimmt.';ro = 'Procesarea nu este destinată pentru utilizare nemijlocită.';tr = 'Veri işlemcisi doğrudan kullanım için uygun değildir.'; es_ES = 'Procesador de datos no está destinado al uso directo.'");
	EndIf;
	
	// Form settings
	Parameters.Property("ReturnValueList", ReturnValueList);
	
	MainCountry           = MainCountry();
	ContactInformationKind  = ContactsManagerInternal.ContactInformationKindStructure(Parameters.ContactInformationKind);
	OnCreateAtServerStoreChangeHistory();
	
	Title = ?(IsBlankString(Parameters.Title), ContactInformationKind.Description, Parameters.Title);
	
	HideObsoleteAddresses  = ContactInformationKind.HideObsoleteAddresses;
	ContactInformationType     = ContactInformationKind.Type;
	
	// Attempting to fill data based on parameter values.
	FieldsValues = DefineAddressValue(Parameters);
	
	If IsBlankString(FieldsValues) Then
		LocalityDetailed = ContactsManager.NewContactInformationDetails(Enums.ContactInformationTypes.Address); // New address
		LocalityDetailed.AddressType = ContactsManagerClientServer.AddressInFreeForm();
	ElsIf ContactsManagerClientServer.IsJSONContactInformation(FieldsValues) Then
		AddressData = ContactsManagerInternal.JSONToContactInformationByFields(FieldsValues, Enums.ContactInformationTypes.Address);
		LocalityDetailed = PrepareAddressForInput(AddressData);
	Else
		XDTOContact = ExtractObsoleteAddressFormat(FieldsValues, ContactInformationType);
		AddressData = ContactsManagerInternal.ContactInformationToJSONStructure(XDTOContact, ContactInformationType);
		LocalityDetailed = PrepareAddressForInput(AddressData);
	EndIf;
	
	SetAttributesValueByContactInformation(ThisObject, LocalityDetailed);
	
	If ValueIsFilled(LocalityDetailed.Comment) Then
		Items.MainPages.PagesRepresentation = FormPagesRepresentation.TabsOnTop;
		Items.CommentPage.Picture = CommonClientServer.CommentPicture(Comment);
	Else
		Items.MainPages.PagesRepresentation = FormPagesRepresentation.None;
	EndIf;
	
	SetFormUsageKey();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If ValueIsFilled(WarningTextOnOpen) Then
		CommonClient.MessageToUser(WarningTextOnOpen,, WarningFieldOnOpen);
	EndIf;
	
	DisplayFieldsByAddressType();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	Notification = New NotifyDescription("ConfirmAndClose", ThisObject);
	CommonClient.ShowFormClosingConfirmation(Notification, Cancel, Exit);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CountryOnChange(Item)
	
	DisplayFieldsByAddressType();
	
EndProcedure

&AtClient
Procedure CountryClear(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure CountryAutoComplete(Item, Text, ChoiceData, Wait, StandardProcessing)
	
	If Wait = 0 Then
		// Generating the quick selection list.
		If IsBlankString(Text) Then
			ChoiceData = New ValueList;
		EndIf;
		Return;
	EndIf;

EndProcedure

&AtClient
Procedure CountryTextInputEnd(Item, Text, ChoiceData, StandardProcessing)
	
	If IsBlankString(Text) Then
		StandardProcessing = False;
	EndIf;
	
#If WebClient Then
	// Bypassing platform specifics.
	StandardProcessing = False;
	ChoiceData         = New ValueList;
	ChoiceData.Add(Country);
#EndIf

EndProcedure

&AtClient
Procedure CountryChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	ContactsManagerClient.WorldCountryChoiceProcessing(Item, ValueSelected, StandardProcessing);
	
EndProcedure


&AtClient
Procedure CommentOnChange(Item)
	
	LocalityDetailed.Comment = Comment;
	AttachIdleHandler("SetCommentIcon", 0.1, True);
	
EndProcedure

&AtClient
Procedure ForeignAddressPresentationOnChange(Item)
	
	LocalityDetailed.Value = AddressPresentation;
	LocalityDetailed.AddressType = ContactsManagerClientServer.AddressInFreeForm();
	LocalityDetailed.Comment = Comment;
	LocalityDetailed.Country = String(Country);
	
EndProcedure

// House, premises

&AtClient
Procedure AddressOnDateAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	If StrCompare(Text, NStr("ru='начало учета'; en = 'accounting start date'; pl = 'początek rachunkowości';de = 'Anfang der Abrechnung';ro = 'începutul evidenței';tr = 'kayıt başlangıcı'; es_ES = 'inicio de contabilidad'")) = 0 Or IsBlankString(Text) Then
		Items.AddressOnDate.EditFormat = "";
	EndIf;
EndProcedure

&AtClient
Procedure AddressOnDateOnChange(Item)
	
	If Not EnterNewAddress Then
		
		Filter = New Structure("Kind", ContactInformationKind.Ref);
		FoundRows = ContactInformationAdditionalAttributesDetails.FindRows(Filter);
		Result = DefineValidDate(AddressOnDate, FoundRows);
		
		If Result.CurrentRow <> Undefined Then
			Type = Result.CurrentRow.Type;
			AddressValidFrom = Result.ValidFrom;
			LocalityDetailed = AddressWithHistory(Result.CurrentRow.Value);
		Else
			Type = PredefinedValue("Enum.ContactInformationTypes.Address");
			AddressValidFrom = AddressOnDate;
			LocalityDetailed = ContactsManagerClientServer.NewContactInformationDetails(Type);
		EndIf;
		
		
		
		If ValueIsFilled(Result.ValidTo) Then
			TextHistoricalAddress = " " + StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'действует по %1'; en = 'valid until %1'; pl = 'ważne do %1';de = 'gültig bis %1';ro = 'valabil până la %1';tr = '%1 kadar geçerli'; es_ES = 'está vigente hasta %1'"), Format(Result.ValidTo - 10, "DLF=DD"));
		Else
			TextHistoricalAddress = NStr("ru = 'действует по настоящее время.'; en = 'valid as of today.'; pl = 'ważne do chwili obecnej.';de = 'gültig bis zur Gegenwart.';ro = 'valabil până în momentul de față.';tr = 'şu ana kadar geçerli.'; es_ES = 'está vigente hasta la fecha.'");
		EndIf;
		Items.AddressStillValid.Title = TextHistoricalAddress;
	Else
		AddressValidFrom = AddressOnDate;
	EndIf;
	
	TextOfAccountingStart = NStr("ru = 'начало учета'; en = 'accounting start date'; pl = 'początek rachunkowości';de = 'Anfang der Abrechnung';ro = 'începutul evidenței';tr = 'kayıt başlangıcı'; es_ES = 'inicio de contabilidad'");
	Items.AddressOnDate.EditFormat = ?(ValueIsFilled(AddressOnDate), "", "DF='""" + TextOfAccountingStart  + """'");
	
EndProcedure

&AtServerNoContext
Function AddressWithHistory(FieldsValues)
	
	Return ContactsManagerInternal.JSONToContactInformationByFields(FieldsValues, Enums.ContactInformationTypes.Address);
	
EndFunction

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure OkCommand(Command)
	ConfirmAndClose();
EndProcedure

&AtClient
Procedure CancelCommand(Command)
	Modified = False;
	Close();
EndProcedure

&AtClient
Procedure ClearAddress(Command)
	
	ClearAddressClient();
	
	
EndProcedure

&AtClient
Procedure ChangeHistory(Command)
	
	AdditionalParameters = New Structure;
	
	AdditionalAttributesDetails = ContactInformationAdditionalAttributesDetails;
	ContactInformationList = FillContactInformationList(ContactInformationKind.Ref, AdditionalAttributesDetails);
	
	FormParameters = New Structure("ContactInformationList", ContactInformationList);
	FormParameters.Insert("ContactInformationKind", ContactInformationKind.Ref);
	FormParameters.Insert("ReadOnly", ThisObject.ReadOnly);
	FormParameters.Insert("FromAddressEntryForm", True);
	FormParameters.Insert("ValidFrom", AddressOnDate);
	
	ClosingNotification = New NotifyDescription("AfterClosingHistoryForm", ThisObject, AdditionalParameters);
	OpenForm("DataProcessor.ContactInformationInput.Form.ContactInformationHistory", FormParameters, ThisObject,,,, ClosingNotification);
	
EndProcedure

&AtClient
Procedure AddComment(Command)
	Items.MainPages.PagesRepresentation = FormPagesRepresentation.TabsOnTop;
	Items.MainPages.CurrentPage = Items.CommentPage;
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SetCommentIcon()
	Items.CommentPage.Picture = CommonClientServer.CommentPicture(Comment);
EndProcedure

&AtClient
Procedure ConfirmAndClose(Result = Undefined, AdditionalParameters = Undefined) Export
	
	If Modified Then // When unmodified, it functions as "cancel".
		Context = New Structure("ContactInformationKind, LocalityDetailed, MainCountry, Country");
		FillPropertyValues(Context, ThisObject);
		Result = FlagUpdateSelectionResults(Context, ReturnValueList);
		
		// Reading contact information kind flags again.
		ContactInformationKind = Context.ContactInformationKind;
		
		Result = Result.ChoiceData;
		If ContactInformationKind.StoreChangeHistory Then
			ProcessContactInformationWithHistory(Result);
		EndIf;
		
		If TypeOf(Result) = Type("Structure") Then
			Result.Insert("ContactInformationAdditionalAttributesDetails", ContactInformationAdditionalAttributesDetails);
		EndIf;
		
		ClearModifiedOnChoice();
#If WebClient Then
		CloseFlag = CloseOnChoice;
		CloseOnChoice = False;
		NotifyChoice(Result);
		CloseOnChoice = CloseFlag;
#Else
		NotifyChoice(Result);
#EndIf
		SaveFormState();
		
	ElsIf Comment <> CommentCopy Then
		// Only the comment was modified, attempting to revert.
		Result = CommentChoiceOnlyResult(Parameters.FieldsValues, Parameters.Presentation, Comment);
		Result = Result.ChoiceData;
		
		ClearModifiedOnChoice();
#If WebClient Then
		CloseFlag = CloseOnChoice;
		CloseOnChoice = False;
		NotifyChoice(Result);
		CloseOnChoice = CloseFlag;
#Else
		NotifyChoice(Result);
#EndIf
		SaveFormState();
		
	Else
		Result = Undefined;
	EndIf;
	
	If (ModalMode Or CloseOnChoice) AND IsOpen() Then
		ClearModifiedOnChoice();
		SaveFormState();
		Close(Result);
	EndIf;

EndProcedure

&AtClient
Procedure ProcessContactInformationWithHistory(Result)
	
	Result.Insert("ValidFrom", ?(EnterNewAddress, AddressOnDate, AddressValidFrom));
	AttributeName = "";
	Filter = New Structure("Kind", Result.Kind);
	
	ValidAddressString = Undefined;
	DateChanged         = True;
	CurrentAddressDate        = CommonClient.SessionDate();
	Delta                   = AddressOnDate - CurrentAddressDate;
	MinDelta        = ?(Delta > 0, Delta, -Delta);
	FoundRows          = ContactInformationAdditionalAttributesDetails.FindRows(Filter);
	For Each FoundRow In FoundRows Do
		If ValueIsFilled(FoundRow.AttributeName) Then
			AttributeName = FoundRow.AttributeName;
		EndIf;
		If FoundRow.ValidFrom = AddressOnDate Then
			DateChanged = False;
			ValidAddressString = FoundRow;
			Break;
		EndIf;
		
		Delta = CurrentAddressDate - FoundRow.ValidFrom;
		Delta = ?(Delta > 0, Delta, -Delta);
		If Delta <= MinDelta Then
			MinDelta = Delta;
			ValidAddressString = FoundRow;
		EndIf;
	EndDo;
	
	If DateChanged Then
		
		Filter = New Structure("ValidFrom, Kind", AddressValidFrom, Result.Kind);
		StringsWithAddress = ContactInformationAdditionalAttributesDetails.FindRows(Filter);
		
		EditableAddressPresentation = ?(StringsWithAddress.Count() > 0, StringsWithAddress[0].Presentation, "");
		If StrCompare(Result.Presentation, EditableAddressPresentation) <> 0 Then
			NewContactInformation = ContactInformationAdditionalAttributesDetails.Add();
			FillPropertyValues(NewContactInformation, Result);
			NewContactInformation.FieldsValues           = Result.ContactInformation;
			NewContactInformation.Value                = Result.Value;
			NewContactInformation.ValidFrom              = AddressOnDate;
			NewContactInformation.StoreChangeHistory = True;
			If ValidAddressString = Undefined Then
				Filter = New Structure("IsHistoricalContactInformation, Kind", False, Result.Kind);
				FoundRows = ContactInformationAdditionalAttributesDetails.FindRows(Filter);
				For each FoundRow In FoundRows Do
					FoundRow.IsHistoricalContactInformation = True;
					FoundRow.AttributeName = "";
				EndDo;
				NewContactInformation.AttributeName = AttributeName;
				NewContactInformation.IsHistoricalContactInformation = False;
			Else
				NewContactInformation.IsHistoricalContactInformation = True;
				Result.Presentation                = ValidAddressString.Presentation;
				Result.ContactInformation         = ValidAddressString.FieldsValues;
				Result.Value = ValidAddressString.Value;
			EndIf;
		ElsIf StrCompare(Result.Comment, ValidAddressString.Comment) <> 0 AND StringsWithAddress.Count() > 0 Then
			// Only the comment is changed.
			StringsWithAddress[0].Comment = Result.Comment;
		EndIf;
	Else
		If StrCompare(Result.Presentation, ValidAddressString.Presentation) <> 0
			OR StrCompare(Result.Comment, ValidAddressString.Comment) <> 0 Then
				FillPropertyValues(ValidAddressString, Result);
				ValidAddressString.FieldsValues                       = Result.ContactInformation;
				ValidAddressString.Value                            = Result.Value;
				ValidAddressString.AttributeName                        = AttributeName;
				ValidAddressString.IsHistoricalContactInformation = False;
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure AfterClosingHistoryForm(Result, AdditionalParameters) Export

	If Result = Undefined Then
		Return;
	EndIf;
	
	EnterNewAddress = ?(Result.Property("EnterNewAddress"), Result.EnterNewAddress, False);
	If EnterNewAddress Then
		AddressValidFrom = AddressOnDate;
		AddressOnDate = Result.CurrentAddress;
		LocalityDetailed = ContactsManagerClientServer.NewContactInformationDetails(PredefinedValue("Enum.ContactInformationTypes.Address"));
	Else
		Filter = New Structure("Kind", ContactInformationKind.Ref);
		FoundRows = ContactInformationAdditionalAttributesDetails.FindRows(Filter);
		
		AttributeName = "";
		For Each ContactInformationRow In FoundRows Do
			If NOT ContactInformationRow.IsHistoricalContactInformation Then
				AttributeName = ContactInformationRow.AttributeName;
			EndIf;
			ContactInformationAdditionalAttributesDetails.Delete(ContactInformationRow);
		EndDo;
		
		For Each ContactInformationRow In Result.History Do
			RowData = ContactInformationAdditionalAttributesDetails.Add();
			FillPropertyValues(RowData, ContactInformationRow);
			If NOT ContactInformationRow.IsHistoricalContactInformation Then
				RowData.AttributeName = AttributeName;
			EndIf;
			If BegOfDay(Result.CurrentAddress) = BegOfDay(ContactInformationRow.ValidFrom) Then
				AddressOnDate = Result.CurrentAddress;
				LocalityDetailed = JSONStringToStructure(ContactInformationRow.Value);
				
			EndIf;
		EndDo;
	EndIf;
	
	DisplayInformationAboutAddressValidityDate(AddressOnDate);
	
	If NOT ThisObject.Modified Then
		ThisObject.Modified = Result.Modified;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function JSONStringToStructure(Value)
	Return ContactsManagerInternal.JSONToContactInformationByFields(Value, Enums.ContactInformationTypes.Address);
EndFunction

&AtClient
Procedure SaveFormState()
	SetFormUsageKey();
	SavedInSettingsDataModified = True;
EndProcedure

&AtClient
Procedure ClearModifiedOnChoice()
	Modified = False;
	CommentCopy   = Comment;
EndProcedure

&AtServerNoContext
Function FlagUpdateSelectionResults(Context, ReturnValueList = False)
	// Updating some flags
	FlagsValue = ContactsManagerInternal.ContactInformationKindStructure(Context.ContactInformationKind.Ref);
	
	Context.ContactInformationKind.OnlyNationalAddress = FlagsValue.OnlyNationalAddress;
	Context.ContactInformationKind.CheckValidity   = FlagsValue.CheckValidity;

	Return SelectionResult(Context, ReturnValueList);
EndFunction

&AtServerNoContext
Function SelectionResult(Context, ReturnValueList = False)

	LocalityDetailed = Context.LocalityDetailed;
	Result      = New Structure("ChoiceData, FillingErrors");
	
	ChoiceData = LocalityDetailed;
	
	Result.ChoiceData = New Structure;
	Result.ChoiceData.Insert("ContactInformation", 
		ContactsManagerInternal.ContactsFromJSONToXML(ChoiceData, Context.ContactInformationKind.Type));
	Result.ChoiceData.Insert("Value", ContactsManagerInternal.ToJSONStringStructure(ChoiceData));
	Result.ChoiceData.Insert("Presentation", LocalityDetailed.Value);
	Result.ChoiceData.Insert("Comment", LocalityDetailed.Comment);
	Result.ChoiceData.Insert("EnteredInFreeFormat",
		ContactsManagerInternal.AddressEnteredInFreeFormat(LocalityDetailed));
		
	// filling errors
	Result.FillingErrors = New Array;
		
	If Context.ContactInformationKind.Type = Enums.ContactInformationTypes.Address 
		AND Context.ContactInformationKind.EditInDialogOnly Then
			AddressAsHyperlink = True;
	Else
			AddressAsHyperlink = False;
	EndIf;
	Result.ChoiceData.Insert("AddressAsHyperlink", AddressAsHyperlink);
	
	// Suppressing line breaks in the separately returned presentation.
	Result.ChoiceData.Presentation = TrimAll(StrReplace(Result.ChoiceData.Presentation, Chars.LF, " "));
	Result.ChoiceData.Insert("Kind", Context.ContactInformationKind.Ref);
	Result.ChoiceData.Insert("Type", Context.ContactInformationKind.Type);
	
	Return Result;
EndFunction

&AtServerNoContext
Function FillContactInformationList(ContactInformationKind, ContactInformationAdditionalAttributesDetails)

	Filter = New Structure("Kind", ContactInformationKind);
	FoundRows = ContactInformationAdditionalAttributesDetails.FindRows(Filter);
	
	ContactInformationList = New Array;
	For each ContactInformationRow In FoundRows Do
		ContactInformation = New Structure("Presentation, Value, FieldsValues, ValidFrom, Comment");
		FillPropertyValues(ContactInformation, ContactInformationRow);
		ContactInformationList.Add(ContactInformation);
	EndDo;
	
	Return ContactInformationList;
EndFunction

&AtServer
Function CommentChoiceOnlyResult(ContactInfo, Presentation, Comment)
	
	If IsBlankString(ContactInfo) Then
		NewContactInfo = ContactsManagerInternal.XMLAddressInXDTO("");
		NewContactInfo.Comment = Comment;
		NewContactInfo = ContactsManagerInternal.XDTOContactsInXML(NewContactInfo);
		AddressEnteredInFreeFormat = False;
		
	ElsIf ContactsManagerClientServer.IsXMLContactInformation(ContactInfo) Then
		// Copy
		NewContactInfo = ContactInfo;
		// Modifying the NewContactInfo value.
		ContactsManager.SetContactInformationComment(NewContactInfo, Comment);
		AddressEnteredInFreeFormat = ContactsManagerInternal.AddressEnteredInFreeFormat(ContactInfo);
		
	Else
		NewContactInfo = ContactInfo;
		AddressEnteredInFreeFormat = False;
	EndIf;
	
	Result = New Structure("ChoiceData, FillingErrors", New Structure, New ValueList);
	Result.ChoiceData.Insert("ContactInformation", NewContactInfo);
	Result.ChoiceData.Insert("Presentation", Presentation);
	Result.ChoiceData.Insert("Comment", Comment);
	Result.ChoiceData.Insert("EnteredInFreeFormat", AddressEnteredInFreeFormat);
	Return Result;
EndFunction

&AtClient
Procedure DisplayFieldsByAddressType()
	
	LocalityDetailed.Country = TrimAll(Country);
	
	If ContactInformationKind.IncludeCountryInPresentation Then
		UpdateAddressPresentation();
	EndIf;
	
EndProcedure

&AtServer
Procedure SetAttributesValueByContactInformation(AddressInfo, AddressData)
	
	// Common attributes
	AddressInfo.AddressPresentation = AddressData.Value;
	If AddressData.Property("Comment") Then
		AddressInfo.Comment         = AddressData.Comment;
	EndIf;
	
	// Comment copy used to analyze changes.
	AddressInfo.CommentCopy = AddressInfo.Comment;
	
	RefToMainCountry = MainCountry();
	CountryData = Undefined;
	If AddressData.Property("Country") AND ValueIsFilled(AddressData.Country) Then
		CountryData = Catalogs.WorldCountries.WorldCountryData(, TrimAll(AddressData.Country));
	EndIf;
	
	If CountryData = Undefined Then
		// Country data is found neither in the catalog nor in the ARCC.
		AddressInfo.Country    = RefToMainCountry;
		AddressInfo.CountryCode = RefToMainCountry.Code;
	Else
		AddressInfo.Country    = CountryData.Ref;
		AddressInfo.CountryCode = CountryData.Code;
	EndIf;
		
	AddressInfo.AddressPresentation = AddressData.Value;
	
EndProcedure

&AtServer
Procedure DeleteItemGroup(Folder)
	While Folder.ChildItems.Count()>0 Do
		Item = Folder.ChildItems[0];
		If TypeOf(Item)=Type("FormGroup") Then
			DeleteItemGroup(Item);
		EndIf;
		Items.Delete(Item);
	EndDo;
	Items.Delete(Folder);
EndProcedure

&AtServer
Procedure DisplayInformationAboutAddressValidityDate(ValidFrom)
	
	If EnterNewAddress Then
		TextHistoricalAddress = NStr("ru = ''");
		AddressOnDate = ValidFrom;
		Items.HistoricalAddressGroup.Visible = ValueIsFilled(ValidFrom);
	Else
		
		Filter = New Structure("Kind", ContactInformationKind.Ref);
		FoundRows = ContactInformationAdditionalAttributesDetails.FindRows(Filter);
		If FoundRows.Count() = 0 
			OR (FoundRows.Count() = 1 AND IsBlankString(FoundRows[0].Presentation)) Then
				AddressOnDate = Date(1, 1, 1);
				Items.HistoricalAddressGroup.Visible = False;
				Items.ChangeHistory.Visible = False;
		Else
			Result = DefineValidDate(ValidFrom, FoundRows);
			AddressOnDate = Result.ValidFrom;
			AddressValidFrom = Result.ValidFrom;
			
			If NOT ValueIsFilled(Result.ValidFrom)
				AND IsBlankString(Result.CurrentRow.Presentation) Then
					Items.HistoricalAddressGroup.Visible = False;
			ElsIf ValueIsFilled(Result.ValidTo) Then
				TextHistoricalAddress = " " + StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'действует по %1'; en = 'valid until %1'; pl = 'ważne do %1';de = 'gültig bis %1';ro = 'valabil până la %1';tr = '%1 kadar geçerli'; es_ES = 'está vigente hasta %1'"), Format(Result.ValidTo - 10, "DLF=DD"));
			Else
				TextHistoricalAddress = NStr("ru = 'действует по настоящее время.'; en = 'valid as of today.'; pl = 'ważne do chwili obecnej.';de = 'gültig bis zur Gegenwart.';ro = 'valabil până în momentul de față.';tr = 'şu ana kadar geçerli.'; es_ES = 'está vigente hasta la fecha.'");
			EndIf;
			DisplayRecordsCountInHistoryChange();
		EndIf;
	EndIf;
	
	Items.AddressStillValid.Title = TextHistoricalAddress;
	Items.AddressOnDate.EditFormat = ?(ValueIsFilled(AddressOnDate), "", "DF='""" + NStr("ru='начало учета'; en = 'accounting start date'; pl = 'początek rachunkowości';de = 'Anfang der Abrechnung';ro = 'începutul evidenței';tr = 'kayıt başlangıcı'; es_ES = 'inicio de contabilidad'") + """'");
	
EndProcedure

&AtServer
Procedure DisplayRecordsCountInHistoryChange()
	
	Filter = New Structure("Kind", ContactInformationKind.Ref);
	FoundRows = ContactInformationAdditionalAttributesDetails.FindRows(Filter);
	If FoundRows.Count() > 1 Then
		Items.ChangeHistoryHyperlink.Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru='История изменений (%1)'; en = 'Change history (%1)'; pl = 'Historia edycji (%1)';de = 'Änderungshistorie (%1)';ro = 'Istoria modificărilor (%1)';tr = 'Değişiklik geçmişi (%1)'; es_ES = 'Historial de cambios (%1)'"), FoundRows.Count());
		Items.ChangeHistoryHyperlink.Visible = True;
	ElsIf FoundRows.Count() = 1 AND IsBlankString(FoundRows[0].FieldsValues) Then
		Items.ChangeHistoryHyperlink.Visible = False;
	Else
		Items.ChangeHistoryHyperlink.Title = NStr("ru='История изменений'; en = 'Change history'; pl = 'Historia zmian';de = 'Geschichte der Änderungen';ro = 'Istoricul schimbărilor';tr = 'Değişim tarihi'; es_ES = 'Cambiar historia'");
		Items.ChangeHistoryHyperlink.Visible = True;
	EndIf;

EndProcedure

&AtClientAtServerNoContext
Function DefineValidDate(ValidFrom, History)
	
	Result = New Structure("ValidTo, ValidFrom, CurrentRow");
	If History.Count() = 0 Then
		Return Result;
	EndIf;
	
	CurrentRow        = Undefined;
	ValidTo          = Undefined;
	Min              = -1;
	MinComparative = Undefined;
	
	For each HistoryString In History Do
		Delta = HistoryString.ValidFrom - ValidFrom;
		If Delta <= 0 AND (MinComparative = Undefined OR Delta > MinComparative) Then
			CurrentRow        = HistoryString;
			MinComparative = Delta;
		EndIf;

		If Min = -1 Then
			Min       = Delta + 1;
			CurrentRow = HistoryString;
		EndIf;
		If Delta > 0 AND ModuleNumbers(Delta) < ModuleNumbers(Min) Then
			ValidTo = HistoryString.ValidFrom;
			Min     = ModuleNumbers(Delta);
		EndIf;
	EndDo;
	
	Result.ValidTo   = ValidTo;
	Result.ValidFrom    = CurrentRow.ValidFrom;
	Result.CurrentRow = CurrentRow;
	
	Return Result;
EndFunction

&AtClientAtServerNoContext
Function ModuleNumbers(Number)
	Return Max(Number, -Number);
EndFunction

&AtClient
Procedure ClearAddressClient()
	
	For each AddressItem In LocalityDetailed Do
		
		If AddressItem.Key = "Type" Then
			Continue;
		ElsIf AddressItem.Key = "Buildings"  OR AddressItem.Key = "Apartments" Then
			LocalityDetailed[AddressItem.Key] = New Array;
		Else
			LocalityDetailed[AddressItem.Key] = "";
		EndIf;
		
	EndDo;
	
	If ContactInformationKind.OnlyNationalAddress Then
		LocalityDetailed.Country = MainCountry();
	EndIf;
	
	LocalityDetailed.AddressType = ContactsManagerClientServer.AddressInFreeForm();
	
EndProcedure

&AtServer
Procedure SetFormUsageKey()
	WindowOptionsKey = String(Country);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////////////////////////

&AtServer
Procedure OnCreateAtServerStoreChangeHistory()
	
	If ContactInformationKind.StoreChangeHistory Then
		If Parameters.Property("ContactInformationAdditionalAttributesDetails") Then
			For each CIRow In Parameters.ContactInformationAdditionalAttributesDetails Do
				NewRow = ContactInformationAdditionalAttributesDetails.Add();
				FillPropertyValues(NewRow, CIRow);
			EndDo;
		Else
			Items.ChangeHistory.Visible           = False;
		EndIf;
		Items.ChangeHistoryHyperlink.Visible = NOT Parameters.Property("FromHistoryForm");
		EnterNewAddress = ?(Parameters.Property("EnterNewAddress"), Parameters.EnterNewAddress, False);
		If EnterNewAddress Then
			ValidFrom = Parameters.ValidFrom;
		Else
			ValidFrom = ?(ValueIsFilled(Parameters.ValidFrom), Parameters.ValidFrom, CurrentSessionDate());
		EndIf;
		DisplayInformationAboutAddressValidityDate(ValidFrom);
	Else
		Items.ChangeHistory.Visible           = False;
		Items.HistoricalAddressGroup.Visible    = False;
	EndIf;

EndProcedure

&AtServer
Function DefineAddressValue(Parameters)
	
	If Parameters.Property("Value") Then
		If IsBlankString(Parameters.Value) AND ValueIsFilled(Parameters.FieldsValues) Then
			FieldsValues = Parameters.FieldsValues;
		Else
			FieldsValues = Parameters.Value;
		EndIf;
	Else
		FieldsValues = Parameters.FieldsValues;
	EndIf;
	Return FieldsValues;

EndFunction

&AtServer
Function ExtractObsoleteAddressFormat(Val FieldsValues, Val ContactInformationType)
	
	Var XDTOContact, ReadResults;
	
	If ContactsManagerClientServer.IsXMLContactInformation(FieldsValues)
		AND ContactInformationType = Enums.ContactInformationTypes.Address Then
		ReadResults = New Structure;
		XDTOContact = ContactsManagerInternal.ContactsFromXML(FieldsValues, ContactInformationType, ReadResults);
		If ReadResults.Property("ErrorText") Then
			// Recognition errors. A warning must be displayed when opening the form.
			WarningTextOnOpen = ReadResults.ErrorText;
			XDTOContact.Presentation   = Parameters.Presentation;
			XDTOContact.Content.Country   = String(MainCountry);
		EndIf;
	Else
		XDTOContact = ContactsManagerInternal.XMLAddressInXDTO(FieldsValues, Parameters.Presentation, );
		If Parameters.Property("Country") AND ValueIsFilled(Parameters.Country) Then
			If TypeOf(Parameters.Country) = TypeOf(Catalogs.WorldCountries.EmptyRef()) Then
				XDTOContact.Content.Country = Parameters.Country.Description;
			Else
				XDTOContact.Content.Country = String(Parameters.Country);
			EndIf;
		Else
			XDTOContact.Content.Country = MainCountry.Description;
		EndIf;
	EndIf;
	If Parameters.Comment <> Undefined Then
		// Creating a new comment to prevent comment import from contact information.
		XDTOContact.Comment = Parameters.Comment;
	EndIf;
	Return XDTOContact;

EndFunction

&AtClient
Procedure UpdateAddressPresentation()
	AddressPresentation = LocalityDetailed.Value;
EndProcedure

&AtServerNoContext
Function MainCountry()
	
	If Metadata.CommonModules.Find("AddressManagerClientServer") <> Undefined Then
		
		ModuleAddressManagerClientServer = Common.CommonModule("AddressManagerClientServer");
		Return ModuleAddressManagerClientServer.MainCountry();
		
	EndIf;
	
	Return Catalogs.WorldCountries.EmptyRef();

EndFunction

&AtServer
Function PrepareAddressForInput(Data)
	
	LocalityDetailed = ContactsManagerClientServer.NewContactInformationDetails(PredefinedValue("Enum.ContactInformationTypes.Address"));
	FillPropertyValues(LocalityDetailed, Data);
	
	For each AddressItem In LocalityDetailed Do
		
		If StrEndsWith(AddressItem.Key, "ID")
			AND TypeOf(AddressItem.Value) = Type("String")
			AND StrLen(AddressItem.Value) = 36 Then
				LocalityDetailed[AddressItem.Key] = New UUID(AddressItem.Value);
		EndIf;
		
	EndDo;
	
	Return LocalityDetailed;
	
EndFunction

#EndRegion