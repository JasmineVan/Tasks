///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Handler of the OnChange event of the contact information form field.
// It is called from the attachable actions when deploying the Contacts subsystem.
//
// Parameters:
//     Form             - ManagedForm - a form of a contact information owner.
//     Item           - FormField        - a form item containing contact information presentation.
//     IsTabularSection - Boolean           - a flag specifying that the item is part of a form table.
//
Procedure OnChange(Form, Item, IsTabularSection = False) Export
	
	OnContactInformationChange(Form, Item, IsTabularSection, True);
	
EndProcedure

// Handler of the StartChoice event of the contact information form field.
// It is called from the attachable actions when deploying the Contacts subsystem.
//
// Parameters:
//     Form                - ManagedForm - a form of a contact information owner.
//     Item              - FormField        - a form item containing contact information presentation.
//     Modified   - Boolean - a flag indicating that the form was modified.
//     StandardProcessing - Boolean           - a flag indicating that standard processing is required for the form event.
//     OpeningParameters    - Structure        - opening parameters of the contact information input form.
//
Procedure StartChoice(Form, Item, Modified = True, StandardProcessing = False, OpeningParameters = Undefined) Export
	StandardProcessing = False;
	
	Result = New Structure;
	Result.Insert("AttributeName", Item.Name);
	
	IsTabularSection = IsTabularSection(Item);
	
	If IsTabularSection Then
		FillingData = Form.Items[Form.CurrentItem.Name].CurrentData;
		If FillingData = Undefined Then
			Return;
		EndIf;
	Else
		FillingData = Form;
	EndIf;
	
	RowData = GetAdditionalValueString(Form, Item, IsTabularSection);
	
	// Setting presentation equal to the attribute if the presentation was modified directly in the form field and no longer matches the attribute.
	UpdateConextMenu = False;
	If Item.Type = FormFieldType.InputField Then
		If FillingData[Item.Name] <> Item.EditText Then
			FillingData[Item.Name] = Item.EditText;
			OnContactInformationChange(Form, Item, IsTabularSection, False);
			UpdateConextMenu  = True;
			Form.Modified = True;
		EndIf;
		EditText = Item.EditText;
	Else
		If RowData <> Undefined AND ValueIsFilled(RowData.Value) Then
			EditText = Form[Item.Name];
		Else
			EditText = "";
		EndIf;
	EndIf;
	
	ContactInformationParameters = Form.ContactInformationParameters[RowData.ItemForPlacementName];
	
	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("ContactInformationKind", RowData.Kind);
	FormOpenParameters.Insert("Value",                RowData.Value);
	FormOpenParameters.Insert("Presentation",           EditText);
	FormOpenParameters.Insert("ReadOnly",          Form.ReadOnly Or Item.ReadOnly);
	FormOpenParameters.Insert("PremiseType",            ContactInformationParameters.AddressParameters.PremiseType);
	FormOpenParameters.Insert("Country",                  ContactInformationParameters.AddressParameters.Country);
	FormOpenParameters.Insert("IndexOf",                  ContactInformationParameters.AddressParameters.IndexOf);
	FormOpenParameters.Insert("ContactInformationAdditionalAttributesDetails", Form.ContactInformationAdditionalAttributesDetails);
	
	If Not IsTabularSection Then
		FormOpenParameters.Insert("Comment", RowData.Comment);
	EndIf;
	
	If ValueIsFilled(OpeningParameters) AND TypeOf(OpeningParameters) = Type("Structure") Then
		For each ValueAndKey In OpeningParameters Do
			FormOpenParameters.Insert(ValueAndKey.Key, ValueAndKey.Value);
		EndDo;
	EndIf;
	
	Notification = New NotifyDescription("PresentationStartChoiceCompletion", ThisObject, New Structure);
	Notification.AdditionalParameters.Insert("FillingData",        FillingData);
	Notification.AdditionalParameters.Insert("IsTabularSection",       IsTabularSection);
	Notification.AdditionalParameters.Insert("PlacementItemName",   RowData.ItemForPlacementName);
	Notification.AdditionalParameters.Insert("RowData",            RowData);
	Notification.AdditionalParameters.Insert("Item",                 Item);
	Notification.AdditionalParameters.Insert("Result",               Result);
	Notification.AdditionalParameters.Insert("Form",                   Form);
	Notification.AdditionalParameters.Insert("UpdateConextMenu", UpdateConextMenu);
	
	OpenContactInformationForm(FormOpenParameters,, Notification);
	
EndProcedure

// Handler of the Clearing event for a contact information form field.
// It is called from the attachable actions when deploying the Contacts subsystem.
//
// Parameters:
//     Form        - ManagedForm - a form of a contact information owner.
//     AttributeName - String           - a name of a form attribute related to contact information presentation.
//
Procedure Clearing(Val Form, Val AttributeName) Export
	
	Result = New Structure("AttributeName", AttributeName);
	FoundRow = Form.ContactInformationAdditionalAttributesDetails.FindRows(Result)[0];
	FoundRow.Value      = "";
	FoundRow.Presentation = "";
	FoundRow.Comment   = "";
	
	Form[AttributeName] = "";
	Form.Modified = True;
		
	If FoundRow.Type = PredefinedValue("Enum.ContactInformationTypes.Address") Then
		Result.Insert("UpdateConextMenu", True);
		Result.Insert("ItemForPlacementName", FoundRow.ItemForPlacementName);
	EndIf;
	
	UpdateFormContactInformation(Form, Result);
EndProcedure

// Handler of the command related to contact information (write an email, open an address, and so on).
// It is called from the attachable actions when deploying the Contacts subsystem.
//
// Parameters:
//     Form      - ManagedForm - a form of a contact information owner.
//     CommandName - String           - a name of the automatically generated action command.
//
Procedure ExecuteCommand(Val Form, Val CommandName) Export
	
	If StrStartsWith(CommandName, "ContactInformationAddInputField") Then
		
		ItemForPlacementName = Mid(CommandName, StrLen("ContactInformationAddInputField") + 1);
		Notification = New NotifyDescription("ContactInformationAddInputFieldCompletion", ThisObject, New Structure);
		Notification.AdditionalParameters.Insert("Form", Form);
		Notification.AdditionalParameters.Insert("ItemForPlacementName", ItemForPlacementName);
		Notification.AdditionalParameters.Insert("CommandName", CommandName);
		Form.ShowChooseFromMenu(Notification, Form.ContactInformationParameters[ItemForPlacementName].ItemsToAddList, Form.Items[CommandName]);
		Return;
		
	ElsIf StrStartsWith(CommandName, "Command") Then
		
		AttributeName = StrReplace(CommandName, "Command", "");
		ContextMenuCommand = Undefined;
		
	ElsIf StrStartsWith(CommandName, "MenuSubmenuAddress") Then
		
		AttributeName         = StrReplace(CommandName, "MenuSubmenuAddress", "");
		Position              = StrFind(AttributeName, "_ContactInformationField");
		SourceAttributeName = Left(AttributeName, Position -1);
		AttributeName         = Mid(AttributeName, Position + 1);
		ContextMenuCommand = Undefined;
		
	ElsIf StrStartsWith(CommandName, "YandexMapMenu") 
		OR StrStartsWith(CommandName, "GoogleMapMenu") Then
		
		ContextMenuCommand = ContextMenuCommand(CommandName);
		AttributeName = Mid(ContextMenuCommand.AttributeName, StrLen("Menu") + 1);
		
	Else
		
		ContextMenuCommand = ContextMenuCommand(CommandName);
		AttributeName = ContextMenuCommand.AttributeName;
		
	EndIf;
	
	Result = New Structure("AttributeName", AttributeName);
	FoundRows = Form.ContactInformationAdditionalAttributesDetails.FindRows(Result);
	If FoundRows.Count() = 0 Then
		Return;
	EndIf;
	
	FoundRow          = FoundRows[0];
	ContactInformationType  = FoundRow.Type;
	ItemForPlacementName = FoundRow.ItemForPlacementName;
	Result.Insert("ItemForPlacementName", ItemForPlacementName);
	
	If ContextMenuCommand <> Undefined Then
		If ContextMenuCommand.Command = "Comment" Then
			EnterComment(Form, ContextMenuCommand.AttributeName, FoundRow, Result);
		ElsIf ContextMenuCommand.Command = "History" Then
			OpenHistoryChangeForm(Form, FoundRow);
		ElsIf ContextMenuCommand.Command = "YandexMap" Then
			ShowAddressOnMap(FoundRow.Presentation, "Yandex.Maps");
		ElsIf ContextMenuCommand.Command = "GoogleMap" Then
			ShowAddressOnMap(FoundRow.Presentation, "GoogleMaps");
		Else
			FirstItem = FoundRow.AttributeName;
			Index = Form.ContactInformationAdditionalAttributesDetails.IndexOf(FoundRow);
			If ContextMenuCommand.MovementDirection = 1 Then
				If Index < Form.ContactInformationAdditionalAttributesDetails.Count() - 1 Then
					SecondItem = Form.ContactInformationAdditionalAttributesDetails.Get(Index + 1).AttributeName;
				EndIf;
			Else
				If Index > 0 Then
					SecondItem = Form.ContactInformationAdditionalAttributesDetails.Get(Index - 1).AttributeName;
				EndIf;
			EndIf;
			Result = New Structure("ReorderItems, FirstItem, SecondItem", True, FirstItem, SecondItem);
			Form.CurrentItem = Form.Items[SecondItem];
			UpdateFormContactInformation(Form, Result);
		EndIf;
		
	ElsIf ContactInformationType = PredefinedValue("Enum.ContactInformationTypes.Address") Then
		
		Result = New Structure("AttributeName", SourceAttributeName);
		ConsumerRow = Form.ContactInformationAdditionalAttributesDetails.FindRows(Result)[0];
		
		Comment = ConsumerRow.Comment; // Saving the old comment.
		If ConsumerRow.Property("InternationalAddressFormat") AND ConsumerRow.InternationalAddressFormat Then
			
			FillPropertyValues(ConsumerRow, FoundRow, "Comment");
			AddressPresentation = StringFunctionsClientServer.LatinString(FoundRow.Presentation);
			ConsumerRow.Presentation        = AddressPresentation;
			Form[ConsumerRow.AttributeName]  = AddressPresentation;
			ConsumerRow.Value             = ContactInformationManagementInternalServerCall.ContactsByPresentation(AddressPresentation, ContactInformationType);
			
		Else
			
			FillPropertyValues(ConsumerRow, FoundRow, "Value, Presentation,Comment");
			Form[ConsumerRow.AttributeName] = FoundRow.Presentation;
			
		EndIf;
		
		Form.Modified = True;
		Result = New Structure();
		Result.Insert("UpdateConextMenu",  True);
		Result.Insert("AttributeName",             ConsumerRow.AttributeName);
		Result.Insert("Comment",              Comment);
		Result.Insert("ItemForPlacementName", FoundRow.ItemForPlacementName);
		UpdateFormContactInformation(Form, Result);
		
	ElsIf ContactInformationType = PredefinedValue("Enum.ContactInformationTypes.EmailAddress") Then
		MailAddr = Form.Items[AttributeName].EditText;
		ContactInformationSource = Form.ContactInformationParameters[ItemForPlacementName].Owner;
		CreateEmail("", MailAddr, ContactInformationType, ContactInformationSource);
	ElsIf ContactInformationType = PredefinedValue("Enum.ContactInformationTypes.Phone") Then
		CanSendSMSMessage = Form.ContactInformationParameters[ItemForPlacementName].CanSendSMSMessage;
		
		Parameters = New Structure("PhoneNumber, ContactInformationType, ContactInformationSource");
		Parameters.PhoneNumber = Form.Items[AttributeName].EditText;
		Parameters.ContactInformationType = ContactInformationType;
		Parameters.ContactInformationSource = Form.ContactInformationParameters[ItemForPlacementName].Owner;
		
		If IsBlankString(Parameters.PhoneNumber) Then
			If CanSendSMSMessage Then
				WarningText = NStr("ru = 'Для совершения звонка или отправки SMS требуется ввести номер телефона.'; en = 'To make a call or send a text message, enter a phone number.'; pl = 'W celu nawiązania połączenia lub wysłania wiadomości SMS należy wprowadzić numer telefonu.';de = 'Um einen Anruf zu tätigen oder eine SMS zu versenden, müssen Sie eine Telefonnummer eingeben.';ro = 'Pentru apelare sau trimiterea SMS trebuie să introduceți numărul de telefon.';tr = 'Aramak veya SMS göndermek için telefon numarasını girin.'; es_ES = 'Para llamar o enviar SMS se requiere introducir el número del teléfono.'");
			Else
				WarningText = NStr("ru = 'Для совершения звонка требуется ввести номер телефона.'; en = 'To make a call, enter a phone number.'; pl = 'W celu nawiązania połączenia należy podać numer telefonu.';de = 'Um einen Anruf zu tätigen, müssen Sie eine Telefonnummer eingeben.';ro = 'Pentru apelare trebuie să introduceți numărul de telefon.';tr = 'Aramak için telefon numarasını girin.'; es_ES = 'Para llamar se requiere introducir el número del teléfono.'");
			EndIf;
			ShowMessageBox(, WarningText);
		ElsIf CanSendSMSMessage Then
			List = New ValueList;
			List.Add("MakeCall", NStr("ru = 'Позвонить'; en = 'Make call'; pl = 'Zadzwoń';de = 'Anruf';ro = 'Apel';tr = 'Ara'; es_ES = 'Llamada'"),, PictureLib.MakeCall);
			List.Add("SendSMSMessage", NStr("ru = 'Отправить SMS...'; en = 'Send text message...'; pl = 'Wyślij SMS...';de = 'SMS senden...';ro = 'Trimite SMS...';tr = 'SMS gönder...'; es_ES = 'Enviar SMS...'"),, PictureLib.SendSMSMessage);
			NotificationMenu = New NotifyDescription("AfterChoiceFromPhoneMenu", ThisObject, Parameters);
			Form.ShowChooseFromMenu(NotificationMenu, List, Form.Items[CommandName]);
		Else
			Telephone(Parameters.PhoneNumber);
		EndIf;
		
	ElsIf ContactInformationType = PredefinedValue("Enum.ContactInformationTypes.Skype") Then
		Parameters = New Structure("SkypeUsername");
		Parameters.SkypeUsername = Form.Items[AttributeName].EditText;
		List = New ValueList;
		List.Add("MakeCall", NStr("ru = 'Позвонить'; en = 'Make call'; pl = 'Zadzwoń';de = 'Anruf';ro = 'Apel';tr = 'Ara'; es_ES = 'Llamada'"));
		List.Add("StartChat", NStr("ru = 'Начать чат'; en = 'Start a chat'; pl = 'Rozpocznij czat';de = 'Chat beginnen';ro = 'Începe conversația';tr = 'Sohbeti başlat'; es_ES = 'Empezar la conversación'"));
		NotificationMenu = New NotifyDescription("AfterChoiceFromSkypeMenu", ThisObject, Parameters);
		Form.ShowChooseFromMenu(NotificationMenu, List, Form.Items[CommandName]);
		
	ElsIf ContactInformationType = PredefinedValue("Enum.ContactInformationTypes.WebPage") Then
		HyperlinkAddress = Form.Items[AttributeName].EditText;
		GoToWebLink("", HyperlinkAddress, ContactInformationType);
	EndIf;
	
EndProcedure

// URL handler for opening a web page.
// It is called from the attachable actions when deploying the Contacts subsystem.
//
// Parameters:
//   Form                - ManagedForm - a form of a contact information owner.
//   Item              - FormField - a form item containing contact information presentation.
//   FormattedStringURL - String - a value of the formatted string URL. The parameter is passed by 
//                                                       the link.
//   StandardProcessing  - Boolean - this parameter stores the flag of whether the standard (system) 
//                                event processing is executed. If this parameter is set to False in 
//                                the processing procedure, standard processing is skipped.
//                                
//
Procedure URLProcessing(Form, Item, FormattedStringURL, StandardProcessing) Export
	
	StandardProcessing = False;
	HyperlinkAddress = Form[Item.Name];
	If FormattedStringURL = ContactsManagerClientServer.WebsiteURL() Or TrimAll(String(HyperlinkAddress)) = ContactsManagerClientServer.BlankAddressTextAsHyperlink() Then
		
		StandardChoiceProcessing = True;
		StartChoice(Form, Item, true, StandardChoiceProcessing);
		
	Else
		GoToWebLink("", FormattedStringURL);
	EndIf;
	
EndProcedure

// Handler of the AutoComplete event of a contact information form field for selecting address options by the entered string.
// It is called from the attachable actions when deploying the Contacts subsystem.
//
// Parameters:
//     Item                  - FormField - a form item containing contact information presentation.
//     Text                    - String         - a text string entered by the user in the contact information field.
//     ChoiceData             - ValueList - contains a value list that will be used for standard 
//                                                 event processing.
//     GetDataParameters - Structure, Undefined - contains search parameters that will be passed to 
//                                the GetChoiceData method. For more information, see details of the 
//                                form field extension for the AutoComplete input field in Syntax Assistant.
//     Wait -   Number       - an interval in seconds between text input and an event.
//                                If 0, the event was not triggered by text input but it was called 
//                                to generate a quick selection list.
//     StandardProcessing     - Boolean         - this parameter stores the flag of whether the 
//                                standard (system) event processing is executed. If this parameter 
//                                is set to False in the processing procedure, standard processing 
//                                is skipped.
//
Procedure AutoCompleteAddress(Item, Text, ChoiceData, DataGetParameters, Wait, StandardProcessing) Export
	
	If StrLen(Text) > 2 Then
		SearchString = Text;
	ElsIf StrLen(Item.EditText) > 2 Then
		SearchString = Item.EditText;
	Else
		Return;
	EndIf;
	
	If StrLen(SearchString) > 2 Then
		ContactInformationManagementInternalServerCall.AddressAutoComplete(SearchString, ChoiceData);
		If TypeOf(ChoiceData) = Type("ValueList") Then
			StandardProcessing = (ChoiceData.Count() = 0);
		EndIf;
	EndIf;
	
EndProcedure

// Handler of the CoiceProcessing event of the contact information form field.
// It is called from the attachable actions when deploying the Contacts subsystem.
//
// Parameters:
//     Form             - ManagedForm - a form of a contact information owner.
//     SelectedValue - String           - a selected value that will be set as a value of the 
//                                            contact information input field.
//     AttributeName - String                - a name of a form attribute related to contact information presentation.
//     StandardProcessing - Boolean        - this parameter stores the flag of whether the standard 
//                                            (system) event processing is executed. If this 
//                                            parameter is set to False in the processing procedure, 
//                                            standard processing is skipped.
//
Procedure ChoiceProcessing(Val Form, Val SelectedValue, Val AttributeName, StandardProcessing = False) Export
	
	StandardProcessing = False;
	Form[AttributeName] = SelectedValue.Presentation;
	
	Filter = New Structure("AttributeName", AttributeName);
	Form.ContactInformationAdditionalAttributesDetails.FindRows(Filter);
	FoundRows = Form.ContactInformationAdditionalAttributesDetails.FindRows(New Structure("AttributeName", AttributeName));
	If FoundRows.Count() > 0 Then
		FoundRows[0].Presentation = SelectedValue.Presentation;
		FoundRows[0].Value      = SelectedValue.Address;
	EndIf;
	
EndProcedure

// Opens the address input form for the contact information form.
// It is called from the attachable actions when deploying the Contacts subsystem.
//
// Parameters:
//     Form     - ManagedForm - a form of a contact information owner.
//     Result - Arbitrary     - data provided by the command handler.
//
Procedure OpenAddressInputForm(Form, Result) Export
	
	If Result <> Undefined Then
		If Result.Property("AddressFormItem") Then
			StartChoice(Form, Form.Items[Result.AddressFormItem]);
		EndIf;
	EndIf;
	
EndProcedure

// Handler of the refresh operation for the contact information form.
// It is called from the attachable actions when deploying the Contacts subsystem.
//
// Parameters:
//     Form     - ManagedForm - a form of a contact information owner.
//     Result - Arbitrary     - data provided by the command handler.
//
Procedure FormRefreshControl(Form, Result) Export
	
	// Address input form callback analysis.
	OpenAddressInputForm(Form, Result);
	
EndProcedure

// Handler of the ChoiceProcessing event for a country.
// Implements functionality for automated creation of WorldCountries catalog item based on user choice.
//
// Parameters:
//     Item              - FormField    - an item containing the country to be edited.
//     SelectedValue    - Arbitrary - a selection value.
//     StandardProcessing - Boolean       - a flag indicating that standard processing is required for the form event.
//
Procedure WorldCountryChoiceProcessing(Item, SelectedValue, StandardProcessing) Export
	If Not StandardProcessing Then 
		Return;
	EndIf;
	
	SelectedValueType = TypeOf(SelectedValue);
	If SelectedValueType = Type("Array") Then
		ConversionList = New Map;
		For Index = 0 To SelectedValue.UBound() Do
			Data = SelectedValue[Index];
			If TypeOf(Data) = Type("Structure") AND Data.Property("Code") Then
				ConversionList.Insert(Index, Data.Code);
			EndIf;
		EndDo;
		
		If ConversionList.Count() > 0 Then
			ContactInformationManagementInternalServerCall.WorldCountriesCollectionByClassifierData(ConversionList);
			For Each KeyValue In ConversionList Do
				SelectedValue[KeyValue.Key] = KeyValue.Value;
			EndDo;
		EndIf;
		
	ElsIf SelectedValueType = Type("Structure") AND SelectedValue.Property("Code") Then
		SelectedValue = ContactInformationManagementInternalServerCall.WorldCountryByClassifierData(SelectedValue.Code);
		
	EndIf;
	
EndProcedure

// Constructor used to create a structure with contact information form opening parameters.
//
// Parameters:
//  ContactInformationKind  - CatalogRef.ContactInformationKinds, Structure - a kind of contact information being edited.
//                             The structure of the kind is generated by the constructor function, 
//                             see ContactsManager.ContactInformationKindParameters 
//  Value                 - String - a serialized value of contact information fields in the JSON or XML format.
//  Presentation            - String - optional. Contact information presentation.
//  Comment              - String - a contact information comment.
//  ContactInformationType - EnumRef.ContactInformationTypes - optional. Contact information type.
//                                      If specified, the fields matching the type are added to the returned structure.
// 
// Returns:
//  Structure - contains the following fields:
//  * ContactInformationKind - CatalogRef.ContactInformationKinds, Structure - a kind of contact information being edited.
//  * Value                - String - a value of contact information fields in the JSON or XML format.
//  * Presentation           - String - a contact information presentation.
//  * ContactInformationType - EnumRef.ContactInformationTypes - the contact information type, 
//                                                                            provided that it was specified in the parameters.
//  * Country                  - String - a country (only if Address is specified as contact information type).
//  * State                  - String - a value of the state field (only if Address is specified as contact information type).
//                                       Relevant for the EEU countries.
//  * PostalCode                  - String - a country (only if Address is specified as contact information type).
//  * PremiseType - String - a premise type in the address input form (only if Address is specified 
//                                       as contact information type).
//  * CountryCode               - String - a phone code of a country (only if Phone is specified as contact information type).
//  * CityCode               - String - a phone code of a city (only if Phone is specified as contact information type).
//  * PhoneNumber           - String - a phone number (only if Phone is specified as contact information type).
//  * Extension              - String - an extension (only if Phone is specified as contact information type).
//  * Title               - String - a form title. Default title is presentation of a contact information kind.
//
Function ContactInformationFormParameters(ContactInformationKind, Value,
	Presentation = Undefined, Comment = Undefined, ContactInformationType = Undefined) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("ContactInformationKind", ContactInformationKind);
	FormParameters.Insert("Value", Value);
	FormParameters.Insert("Presentation", Presentation);
	FormParameters.Insert("Comment", Comment);
	If ContactInformationType <> Undefined Then
		FormParameters.Insert("ContactInformationType", ContactInformationType);
		If ContactInformationType = PredefinedValue("Enum.ContactInformationTypes.Address") Then
			FormParameters.Insert("Country");
			FormParameters.Insert("State");
			FormParameters.Insert("IndexOf");
			FormParameters.Insert("PremiseType", "Apartment");
		ElsIf ContactInformationType = PredefinedValue("Enum.ContactInformationTypes.Phone") Then
			FormParameters.Insert("CountryCode");
			FormParameters.Insert("CityCode");
			FormParameters.Insert("PhoneNumber");
			FormParameters.Insert("Extension");
		EndIf;
	EndIf;
	
	If TypeOf(ContactInformationKind) = Type("Structure") AND ContactInformationKind.Property("Description") Then
		FormParameters.Insert("Title", ContactInformationKind.Description);
	Else
		FormParameters.Insert("Title", String(ContactInformationKind));
	EndIf;
	
	Return FormParameters;
	
EndFunction

// Opens an appropriate contact information form for editing or viewing.
//
//  Parameters:
//      Parameters    - Arbitrary - the ContactInformationFormParameters function result.
//      Owner     - Arbitrary - a form parameter.
//      Notification   - NotifyDescription - used to process form closing.
//
//  Returns:
//   ManagedForm - a requested form.
//
Function OpenContactInformationForm(Parameters, Owner = Undefined, Notification = Undefined) Export
	Parameters.Insert("OpenByScenario", True);
	Return OpenForm("DataProcessor.ContactInformationInput.Form", Parameters, Owner,,,, Notification);
EndFunction

// Creates a contact information email.
//
// Parameters:
//  FieldsValues - String, Structure, Map, ValueList - a contact information value.
//  Presentation - String - a contact information presentation. Used if it is impossible to 
//                              determine a presentation based on a parameter. FieldsValues (the Presentation field is not available).
//  ExpectedKind  - CatalogRef.ContactInformationKinds, EnumRef.ContactInformationTypes,
//                         Structure - used to determine a type if it is impossible to determine it by the FieldsValues field.
//  ContactInformationSource - Arbitrary - an owner object of contact information.
//
Procedure CreateEmail(Val FieldsValues, Val Presentation = "", ExpectedKind = Undefined, ContactInformationSource = Undefined) Export
	
	ContactInformation = ContactInformationManagementInternalServerCall.TransformContactInformationXML(
		New Structure("FieldsValues, Presentation, ContactInformationKind", FieldsValues, Presentation, ExpectedKind));
		
	InformationType = ContactInformation.ContactInformationType;
	If InformationType <> PredefinedValue("Enum.ContactInformationTypes.EmailAddress") Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Нельзя создать письмо по контактной информацию с типом ""%1""'; en = 'Cannot create an email from contact information of the ""%1"" type.'; pl = 'Nie można utworzyć wiadomości e-mail według informacji kontaktowych z typem ""%1""';de = 'Kann keine E-Mail nach Kontaktinformationen mit dem Typ ""%1"" erstellen';ro = 'Nu puteți crea e-mail pe informațiile de contact cu tipul ""%1""';tr = '""%1"" tür iletişim bilgileri ile e-posta adresini oluşturamaz'; es_ES = 'No se puede crear un correo electrónico por la información de contacto con el tipo ""%1""'"), InformationType);
	EndIf;
	
	If FieldsValues = "" AND IsBlankString(Presentation) Then
		ShowMessageBox(,NStr("ru = 'Для отправки письма необходимо ввести адрес электронной почты.'; en = 'To send an email, enter an email address.'; pl = 'W celu wysłania wiadomości należy wpisać adres e-mail.';de = 'Um eine E-Mail zu versenden, müssen Sie eine E-Mail-Adresse eingeben.';ro = 'Pentru trimiterea scrisorii trebuie să introduceți adresa e-mail.';tr = 'E-posta göndermek için e-posta adresi girilmelidir.'; es_ES = 'Para enviar el correo es necesario introducir la dirección del correo electrónico.'"));
		Return;
	EndIf;
	
	XMLData = ContactInformation.XMLData;
	MailAddr = ContactInformationManagementInternalServerCall.ContactInformationCompositionString(XMLData);
	If TypeOf(MailAddr) <> Type("String") Then
		Raise NStr("ru = 'Ошибка получения адреса электронной почты, неверный тип контактной информации'; en = 'Error getting email address. Invalid contact information type.'; pl = 'Wystąpił błąd podczas odbierania adresu e-mail, nieprawidłowy typ informacji kontaktowych';de = 'Beim Empfang der E-Mail-Adresse ist ein Fehler aufgetreten, falscher Kontaktinformationstyp';ro = 'Eroare la primirea adresei de e-mail, tipul informațiilor de contact este incorect';tr = 'E-posta adresi alınırken bir hata oluştu, iletişim bilgilerin türü yanlış'; es_ES = 'Ha ocurrido un error al recibir la dirección de correo electrónico, tipo de la información de contacto incorrecto'");
	EndIf;
	
	If CommonClient.SubsystemExists("StandardSubsystems.EmailOperations") Then
		ModuleEmailOperationsClient = CommonClient.CommonModule("EmailOperationsClient");
		
		Recipient = New Array;
		Recipient.Add(New Structure("Address, Presentation, ContactInformationSource", 
			MailAddr, StrReplace(String(ContactInformationSource), ",", ""), ContactInformationSource));
		SendOptions = New Structure("Recipient", Recipient);
		ModuleEmailOperationsClient.CreateNewEmailMessage(SendOptions);
	Else
		FileSystemClient.OpenURL("mailto:" + MailAddr);
	EndIf;
	
EndProcedure

// Creates a contact information email.
//
// Parameters:
//  FieldsValues                - String, Structure, Map, ValueList - contact information.
//  Presentation                - String - a presentation. Used if it is impossible to determine a presentation based on a parameter.
//                                           FieldsValues (the Presentation field is not available).
//  ExpectedKind                 - CatalogRef.ContactInformationKinds, EnumRef.ContactInformationTypes,
//                                  Structure - used to determine a type if it is impossible to determine it by
//                                              the FieldsValues field.
//  ContactInformationSource - AnyRef - an object that is a contact information source.
//
Procedure CreateSMSMessage(Val FieldsValues, Val Presentation = "", ExpectedKind = Undefined, ContactInformationSource = "") Export
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.SendSMSMessage") Then
		Raise NStr("ru = 'Отправка SMS недоступна.'; en = 'Text messaging is not available.'; pl = 'Wysyłanie wiadomości SMS nie jest dostępne.';de = 'Das Senden von SMS ist nicht verfügbar.';ro = 'Trimiterea de SMS nu este accesibilă.';tr = 'SMS gönderilemez.'; es_ES = 'El envío de SMS no disponible.'");
	EndIf;
	
	ContactInformation = ContactInformationManagementInternalServerCall.TransformContactInformationXML(
		New Structure("FieldsValues, Presentation, ContactInformationKind", FieldsValues, Presentation, ExpectedKind));
		
	InformationType = ContactInformation.ContactInformationType;
	If InformationType <> PredefinedValue("Enum.ContactInformationTypes.Phone") Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Нельзя отправитьSMS по контактной информацию с типом ""%1""'; en = 'Cannot send a text message from contact information of the ""%1"" type.'; pl = 'Nie można wysłać wiadomość SMS zgodnie informacji kontaktowej z rodzajem ""%1""';de = 'Sie können keine SMS über Kontaktinformationen mit dem Typ ""%1"" senden';ro = 'Nu se poate trimite SMS pe informațiile de contact cu tipul ""%1""';tr = '""%1"" tür iletişim bilgileri ile SMS gönderilemez'; es_ES = 'No se puede enviar SMS por la información de contacto con el tipo ""%1""'"), InformationType);
	EndIf;
	
	If FieldsValues = "" AND IsBlankString(Presentation) Then
		ShowMessageBox(,NStr("ru = 'Для отправки SMS необходимо ввести номер телефона.'; en = 'To send a text message, enter a phone number.'; pl = 'W celu wysłania wiadomości SMS, należy wpisać numer telefonu.';de = 'Um eine SMS zu versenden, müssen Sie eine Telefonnummer eingeben.';ro = 'Pentru trimiterea SMS trebuie să introduceți numărul de telefon.';tr = 'SMS göndermek için telefon numarası girilmelidir.'; es_ES = 'Para enviar SMS es necesario introducir el número de teléfono.'"));
		Return;
	EndIf;
	
	XMLData = ContactInformation.XMLData;
	If ValueIsFilled(XMLData) Then
		RecipientNumber = ContactInformationManagementInternalServerCall.ContactInformationCompositionString(XMLData);
	EndIf;
	If NOT ValueIsFilled(RecipientNumber) Then
		RecipientNumber = TrimAll(Presentation);
	EndIf;
	
	#If MobileClient Then
		SMS = New SMSMessage();
		SMS.To.Add(RecipientNumber);
		TelephonyTools.SendSMS(SMS, True);
		Return;
	#EndIf
	
	RecipientInfo = New Structure();
	RecipientInfo.Insert("Phone",                      RecipientNumber);
	RecipientInfo.Insert("Presentation",                String(ContactInformationSource));
	RecipientInfo.Insert("ContactInformationSource", ContactInformationSource);
	
	RecipientsNumbers = New Array;
	RecipientsNumbers.Add(RecipientInfo);
	
	ModuleSMSClient = CommonClient.CommonModule("SMSClient");
	ModuleSMSClient.SendSMSMessage(RecipientsNumbers, "", New Structure("Transliterate", False));
	
EndProcedure

// Makes a call to the passed phone number via SIP telephony or via Skype if SIP telephony is not 
// available.
//
// Parameters:
//  PhoneNumber - String - a phone number to which the call will be made.
//
Procedure Telephone(PhoneNumber) Export
	
	PhoneNumber = StringFunctionsClientServer.ReplaceCharsWithOther("()_- ", PhoneNumber, "");
	
	ProtocolName = "tel"; // use "tel" by default.
	
	#If MobileClient Then
		TelephonyTools.DialNumber(PhoneNumber, True);
		Return;
	#EndIf
	
	#If NOT WebClient Then
		AvailableProtocolName = TelephonyApplicationInstalled();
		If AvailableProtocolName = Undefined Then
			StringWithWarning = New FormattedString(
					NStr("ru = 'Для совершения звонка требуется установить программу телефонии, например'; en = 'To make a call, install a telecommunication application. For example'; pl = 'Aby nawiązać połączenie, należy zainstalować aplikację telefonii, np.';de = 'Um einen Anruf zu tätigen, müssen Sie ein Telefonie-Programm installieren, zum Beispiel';ro = 'Pentru apelare trebuie să instalați programul de telefonie, de exemplu';tr = 'Arama yapmak için telefon uygulaması indirilmelidir, örneğin'; es_ES = 'Para llamar se requiere instalar el programa de telefonía, por ejemplo'"),
					 " ", New FormattedString("Skype",,,, "http://www.skype.com"), ".");
			ShowMessageBox(Undefined, StringWithWarning);
			Return;
		ElsIf NOT IsBlankString(AvailableProtocolName) Then
			ProtocolName = AvailableProtocolName;
		EndIf;
	#EndIf
	
	CommandLine = ProtocolName + ":" + PhoneNumber;
	
	Notification = New NotifyDescription("AfterStartApplication", ThisObject);
	FileSystemClient.OpenURL(CommandLine, Notification);
	
EndProcedure

// Calls via Skype.
//
// Parameters:
//  SkypeUsername - String - a Skype username.
//
Procedure CallSkype(SkypeUsername) Export
	
	OpenSkype("skype:" + SkypeUsername + "?call");

EndProcedure

// Open conversation window (chat) in Skype
//
// Parameters:
//  SkypeUsername - String - a Skype username.
//
Procedure StartCoversationInSkype(SkypeUsername) Export
	
	OpenSkype("skype:" + SkypeUsername + "?chat");
	
EndProcedure

// Opens a contact information reference.
//
// Parameters:
//  FieldsValues - String, Structure, Map, ValueList - contact information.
//  Presentation - String - a presentation. Used if it is impossible to determine a presentation based on a parameter.
//                            FieldsValues (the Presentation field is not available).
//  ExpectedKind  - CatalogRef.ContactInformationKinds, EnumRef.ContactInformationTypes, Structure -
//                      used to determine a type if it is impossible to determine it by the FieldsValues field.
//
Procedure GoToWebLink(Val FieldsValues, Val Presentation = "", ExpectedKind = Undefined) Export
	
	If ExpectedKind = Undefined Then
		ExpectedKind = PredefinedValue("Enum.ContactInformationTypes.WebPage");
	EndIf;
	
	ContactInformation = ContactInformationManagementInternalServerCall.TransformContactInformationXML(
		New Structure("FieldsValues, Presentation, ContactInformationKind", FieldsValues, Presentation, ExpectedKind));
	InformationType = ContactInformation.ContactInformationType;
	
	If InformationType <> PredefinedValue("Enum.ContactInformationTypes.WebPage") Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Нельзя открыть ссылку по контактной информации с типом ""%1""'; en = 'Cannot follow a link from contact information of the ""%1"" type.'; pl = 'Nie można otworzyć odwołania do informacji kontaktowych dla ""%1"" typu ';de = 'Eine Kontaktinformationsreferenz für den Typ ""%1"" kann nicht geöffnet werden';ro = 'Nu se poate deschide linkul pe informațiile de contact cu tipul ""%1""';tr = '""%1"" türü için bir iletişim bilgileri referansı açılamıyor'; es_ES = 'No se puede abrir una referencia de la información de contacto para el tipo ""%1""'"), InformationType);
	EndIf;
		
	XMLData = ContactInformation.XMLData;

	HyperlinkAddress = ContactInformationManagementInternalServerCall.ContactInformationCompositionString(XMLData);
	If TypeOf(HyperlinkAddress) <> Type("String") Then
		Raise NStr("ru = 'Ошибка получения ссылки, неверный тип контактной информации'; en = 'Error getting URL. Invalid contact information type.'; pl = 'Wystąpił błąd podczas odbierania referencyjnego, nieprawidłowego typu informacji kontaktowych';de = 'Beim Empfang der Referenz ist ein Fehler aufgetreten, falscher Kontaktinformationstyp';ro = 'Eroare de obținere a referinței, tip incorect al informațiilor de contact';tr = 'Referans alınırken bir hata oluştu, iletişim bilgilerin türü yanlış'; es_ES = 'Ha ocurrido un error al recibir la referencia, tipo de la información de contacto incorrecto'");
	EndIf;
	
	If StrFind(HyperlinkAddress, "://") > 0 Then
		FileSystemClient.OpenURL(HyperlinkAddress);
	Else
		FileSystemClient.OpenURL("http://" + HyperlinkAddress);
	EndIf;
EndProcedure

// Shows an address in a browser on Yandex.Maps or Google Maps.
//
// Parameters:
//  Address                       - String - a text presentation of an address.
//  MapServiceName - String - a name of a map service where the address should be shown:
//                                         Yandex.Maps or GoogleMaps.
//
Procedure ShowAddressOnMap(Address, MapServiceName) Export
	CodedAddress = URLEncode(Address);
	If MapServiceName = "GoogleMaps" Then
		CommandLine = "https://maps.google.ru/?q=" + CodedAddress;
	Else
		CommandLine = "https://maps.yandex.ru/?text=" + CodedAddress;
	EndIf;
	
	FileSystemClient.OpenURL(CommandLine);
	
EndProcedure

// Displays a form with history of contact information changes.
//
// Parameters:
//  Form                         - ManagedForm - a form with contact information.
//  ContactInformationParameters - Structure - information about a contact information item.
//
Procedure OpenHistoryChangeForm(Form, ContactInformationParameters) Export
	
	Result = New Structure("Kind", ContactInformationParameters.Kind);
	FoundRows = Form.ContactInformationAdditionalAttributesDetails.FindRows(Result);
	
	ContactInformationList = New Array;
	For each ContactInformationRow In FoundRows Do
		ContactInformation = New Structure("Presentation, Value, FieldsValues, ValidFrom, Comment");
		FillPropertyValues(ContactInformation, ContactInformationRow);
		ContactInformationList.Add(ContactInformation);
	EndDo;
	
	AdditionalParameters = New Structure("Form");
	AdditionalParameters.Insert("ItemName", ContactInformationParameters.AttributeName);
	AdditionalParameters.Insert("Kind", ContactInformationParameters.Kind);
	AdditionalParameters.Insert("ItemForPlacementName", ContactInformationParameters.ItemForPlacementName);
	AdditionalParameters.Form = Form;
	
	FormParameters = New Structure("ContactInformationList", ContactInformationList);
	FormParameters.Insert("ContactInformationKind", ContactInformationParameters.Kind);
	FormParameters.Insert("ReadOnly", Form.ReadOnly);

	ClosingNotification = New NotifyDescription("AfterClosingHistoryForm", ContactsManagerClient, AdditionalParameters);
	OpenForm("DataProcessor.ContactInformationInput.Form.ContactInformationHistory", FormParameters, Form,,,, ClosingNotification);
	
EndProcedure

#Region ObsoleteProceduresAndFunctions

// Obsolete. Use AddressAutoComplete instead.
// Handler of the AutoComplete event of the contact information form field.
// It is called from the attachable actions when deploying the Contacts subsystem.
//
// Parameters:
//     Text                - String         - a text string entered by the user in the contact information field.
//     ChoiceData         - ValueList - contains a value list that will be used for standard event 
//                                             processing.
//     StandardProcessing - Boolean         - this parameter stores the flag of whether the standard 
//                                             (system) event processing is executed. If this 
//                                             parameter is set to False in the processing procedure, 
//                                             standard processing is skipped.
//
Procedure AutoComplete(Val Text, ChoiceData, StandardProcessing = False) Export
	
	If StrLen(Text) > 2 Then
		AutoCompleteAddress(Undefined, Text, ChoiceData, Undefined, 0, StandardProcessing);
	EndIf;
	
EndProcedure

// Obsolete. Use OnChange instead.
//
// Parameters:
//     Form             - ManagedForm - a form of a contact information owner.
//     Item           - FormField        - a form item containing contact information presentation.
//     IsTabularSection - Boolean           - a flag specifying that the item is part of a form table.
//
Procedure PresentationOnChange(Form, Item, IsTabularSection = False) Export
	OnChange(Form, Item, IsTabularSection);
EndProcedure

// Obsolete. Use StartChoice instead.
//
// Parameters:
//     Form                - ManagedForm - a form of a contact information owner.
//     Item              - FormField        - a form item containing contact information presentation.
//     Modified   - Boolean - a flag indicating that the form was modified.
//     StandardProcessing - Boolean           - a flag indicating that standard processing is required for the form event.
//
// Returns:
//  Undefined - not used, backward compatibility.
//
Function PresentationStartChoice(Form, Item, Modified = True, StandardProcessing = False) Export
	StartChoice(Form, Item, Modified, StandardProcessing);
	Return Undefined;
EndFunction

// Obsolete. Use Clearing instead.
//
// Parameters:
//     Form        - ManagedForm - a form of a contact information owner.
//     AttributeName - String           - a name of a form attribute related to contact information presentation.
//
// Returns:
//  Undefined - not used, backward compatibility.
//
Function ClearingPresentation(Form, AttributeName) Export
	Clearing(Form, AttributeName);
	Return Undefined;
EndFunction

// Obsolete. Use ExecuteCommand instead.
//
// Parameters:
//     Form      - ManagedForm - a form of a contact information owner.
//     CommandName - String           - a name of the automatically generated action command.
//
// Returns:
//  Undefined - not used, backward compatibility.
//
Function AttachableCommand(Form, CommandName) Export
	ExecuteCommand(Form, CommandName);
	Return Undefined;
EndFunction

#EndRegion

#EndRegion

#Region Internal

// Nonmodal dialog completion.

Procedure AfterClosingHistoryForm(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	Form = AdditionalParameters.Form;
	
	Filter = New Structure("Kind", AdditionalParameters.Kind);
	FoundRows = Form.ContactInformationAdditionalAttributesDetails.FindRows(Filter);
	
	OldComment = Undefined;
	For each ContactInformationRow In FoundRows Do
		If NOT ContactInformationRow.IsHistoricalContactInformation Then
			OldComment = ContactInformationRow.Comment;
		EndIf;
		Form.ContactInformationAdditionalAttributesDetails.Delete(ContactInformationRow);
	EndDo;
	
	UpdateParameters = New Structure;
	For Each ContactInformationRow In Result.History Do
		RowData = Form.ContactInformationAdditionalAttributesDetails.Add();
		FillPropertyValues(RowData, ContactInformationRow);
		If NOT ContactInformationRow.IsHistoricalContactInformation Then
			If IsBlankString(ContactInformationRow.Presentation)
				AND Result.Property("EditInDialogOnly")
				AND Result.EditInDialogOnly Then
					Presentation = ContactsManagerClientServer.BlankAddressTextAsHyperlink();
			Else
				Presentation = ContactInformationRow.Presentation;
			EndIf;
			Form[AdditionalParameters.ItemName] = Presentation;
			RowData.AttributeName = AdditionalParameters.ItemName;
			RowData.ItemForPlacementName = AdditionalParameters.ItemForPlacementName;
			If RowData.Comment <> OldComment Then
				UpdateParameters.Insert("IsCommentAddition", True);
				UpdateParameters.Insert("ItemForPlacementName", AdditionalParameters.ItemForPlacementName);
				UpdateParameters.Insert("AttributeName", AdditionalParameters.ItemName);
			EndIf;
		EndIf;
	EndDo;
	
	Form.Modified = True;
	If ValueIsFilled(UpdateParameters) Then
		UpdateFormContactInformation(Form, UpdateParameters);
	EndIf;
EndProcedure

Procedure PresentationStartChoiceCompletion(Val ClosingResult, Val AdditionalParameters) Export
	
	If TypeOf(ClosingResult) <> Type("Structure") Then
		If AdditionalParameters.Property("UpdateConextMenu") 
			AND AdditionalParameters.UpdateConextMenu Then
				Result = New Structure();
				Result.Insert("UpdateConextMenu",  True);
				Result.Insert("ItemForPlacementName", AdditionalParameters.PlacementItemName);
				UpdateFormContactInformation(AdditionalParameters.Form, Result);
		EndIf;
		Return;
	EndIf;
	
	FillingData = AdditionalParameters.FillingData;
	DataOnForm    = AdditionalParameters.RowData;
	Result        = AdditionalParameters.Result;
	Item          = AdditionalParameters.Item;
	Form            = AdditionalParameters.Form;
	
	PresentationText = ClosingResult.Presentation;
	Comment        = ClosingResult.Comment;
	
	If DataOnForm.Property("StoreChangeHistory") AND DataOnForm.StoreChangeHistory Then
		ContactInformationAdditionalAttributesDetails = FillingData.ContactInformationAdditionalAttributesDetails;
		Filter = New Structure("Kind", DataOnForm.Kind);
		FoundRows = ContactInformationAdditionalAttributesDetails.FindRows(Filter);
		For Each ContactInformationRow In FoundRows Do
			ContactInformationAdditionalAttributesDetails.Delete(ContactInformationRow);
		EndDo;
		
		Filter = New Structure("Kind", DataOnForm.Kind);
		FoundRows = ClosingResult.ContactInformationAdditionalAttributesDetails.FindRows(Filter);
		
		If FoundRows.Count() > 1 Then
			
			RowWithValidAddress = Undefined;
			MinDate = Undefined;
			
			For Each ContactInformationRow In FoundRows Do
				
				NewContactInformation = ContactInformationAdditionalAttributesDetails.Add();
				FillPropertyValues(NewContactInformation, ContactInformationRow);
				NewContactInformation.ItemForPlacementName = AdditionalParameters.PlacementItemName;
				
				If RowWithValidAddress = Undefined
					OR ContactInformationRow.ValidFrom > RowWithValidAddress.ValidFrom Then
						RowWithValidAddress = ContactInformationRow;
				EndIf;
				If MinDate = Undefined
					OR ContactInformationRow.ValidFrom < MinDate Then
						MinDate = ContactInformationRow.ValidFrom;
				EndIf;
				
			EndDo;
			
			// Correcting invalid addresses without the original fill date
			If ValueIsFilled(MinDate) Then
				Filter = New Structure("ValidFrom", MinDate);
				RowsWithMinDate = ContactInformationAdditionalAttributesDetails.FindRows(Filter);
				If RowsWithMinDate.Count() > 0 Then
					RowsWithMinDate[0].ValidFrom = Date(1, 1, 1);
				EndIf;
			EndIf;
			
			If RowWithValidAddress <> Undefined Then
				PresentationText = RowWithValidAddress.Presentation;
				Comment        = RowWithValidAddress.Comment;
			EndIf;
			
		ElsIf FoundRows.Count() = 1 Then
			NewContactInformation = ContactInformationAdditionalAttributesDetails.Add();
			FillPropertyValues(NewContactInformation, FoundRows[0],, "ValidFrom");
			NewContactInformation.ItemForPlacementName = AdditionalParameters.PlacementItemName;
			DataOnForm.ValidFrom = Date(1, 1, 1);
		EndIf;
		
	EndIf;
	
	If AdditionalParameters.IsTabularSection Then
		FillingData[Item.Name + "Value"]      = ClosingResult.Value;
		
	Else
		Form.Items.Find(Item.Name).ExtendedToolTip.Title = Comment;
		
		If ClosingResult.Type = PredefinedValue("Enum.ContactInformationTypes.WebPage") Then
			PresentationText = ContactsManagerClientServer.WebsiteAddress(PresentationText, ClosingResult.Address);
		EndIf;
		
		DataOnForm.Presentation = PresentationText;
		DataOnForm.Value      = ClosingResult.Value;
		DataOnForm.Comment   = Comment;
	EndIf;
	
	If ClosingResult.Property("AddressAsHyperlink")
		AND ClosingResult.AddressAsHyperlink
		AND NOT ValueIsFilled(PresentationText) Then
			FillingData[Item.Name] = ContactsManagerClientServer.BlankAddressTextAsHyperlink();
	Else
		FillingData[Item.Name] = PresentationText;
	EndIf;
	
	If ClosingResult.Type = PredefinedValue("Enum.ContactInformationTypes.Address") Then
		Result.Insert("UpdateConextMenu", True);
	EndIf;
	
	Form.Modified = True;
	UpdateFormContactInformation(Form, Result);
EndProcedure

Procedure ContactInformationAddInputFieldCompletion(Val SelectedItem, Val AdditionalParameters) Export
	If SelectedItem = Undefined Then
		// Canceling selection
		Return;
	EndIf;
	
	Result = New Structure();
	Result.Insert("KindToAdd", SelectedItem.Value);
	Result.Insert("ItemForPlacementName", AdditionalParameters.ItemForPlacementName);
	Result.Insert("CommandName", AdditionalParameters.CommandName);
	If SelectedItem.Value.Type = PredefinedValue("Enum.ContactInformationTypes.Address") Then
		Result.Insert("UpdateConextMenu", True);
	EndIf;
	
	UpdateFormContactInformation(AdditionalParameters.Form, Result);
EndProcedure

Procedure AfterStartApplication(ApplicationStarted, Parameters) Export
	
	If Not ApplicationStarted Then 
		StringWithWarning = New FormattedString(
			NStr("ru = 'Для совершения звонка требуется установить программу телефонии, например'; en = 'To make a call, install a telecommunication application. For example'; pl = 'Aby nawiązać połączenie, należy zainstalować aplikację telefonii, np.';de = 'Um einen Anruf zu tätigen, müssen Sie ein Telefonie-Programm installieren, zum Beispiel';ro = 'Pentru apelare trebuie să instalați programul de telefonie, de exemplu';tr = 'Arama yapmak için telefon uygulaması indirilmelidir, örneğin'; es_ES = 'Para llamar se requiere instalar el programa de telefonía, por ejemplo'"),
			 " ", New FormattedString("Skype",,,, "http://www.skype.com"), ".");
		ShowMessageBox(Undefined, StringWithWarning);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure AfterChoiceFromPhoneMenu(SelectedItem, Parameters) Export
	
	If SelectedItem <> Undefined Then
		If SelectedItem.Value = "SendSMSMessage" Then
			CreateSMSMessage("", Parameters.PhoneNumber, Parameters.ContactInformationType, Parameters.ContactInformationSource);
		Else
			Telephone(Parameters.PhoneNumber);
		EndIf;
	EndIf;
EndProcedure

Procedure AfterChoiceFromSkypeMenu(SelectedItem, Parameters) Export
	
	If SelectedItem = Undefined Then
		Return;
	EndIf;
	
	If SelectedItem.Value = "MakeCall" Then
		CallSkype(Parameters.SkypeUsername);
	ElsIf SelectedItem.Value = "StartChat" Then
		StartCoversationInSkype(Parameters.SkypeUsername);
	EndIf;

EndProcedure

Procedure OpenSkype(CommandLine)
	
	#If NOT WebClient Then
		If IsBlankString(TelephonyApplicationInstalled("skype")) Then
			ShowMessageBox(Undefined, NStr("ru = 'Для совершения звонка по Skype требуется установить программу.'; en = 'Install Skype to make a call.'; pl = 'Aby nawiązać połączenie przez Skype, musisz zainstalować program.';de = 'Um einen Anruf über Skype zu tätigen, ist es erforderlich, das Programm zu installieren.';ro = 'Pentru a efectua un apel pe Skype este necesar să instalați programul.';tr = 'Skype araması yapmak için programı yüklemeniz gerekir.'; es_ES = 'Para hacer una llamada en Skype, se requiere instalar el programa.'"));
			Return;
		EndIf;
	#EndIf
	
	Notification = New NotifyDescription("AfterStartApplication", ThisObject);
	FileSystemClient.OpenURL(CommandLine, Notification);
	
EndProcedure

// Returns a string of additional values by attribute name.
//
// Parameters:
//    Form   - ManagedForm - a form to pass.
//    Item - FormStructureWithCollectionData - form data.
//
// Returns:
//    CollectionString - found data.
//    Undefined    - if no data is available.
//
Function GetAdditionalValueString(Form, Item, IsTabularSection = False)
	
	Filter = New Structure("AttributeName", Item.Name);
	Rows = Form.ContactInformationAdditionalAttributesDetails.FindRows(Filter);
	RowData = ?(Rows.Count() = 0, Undefined, Rows[0]);
	
	If IsTabularSection AND RowData <> Undefined Then
		
		RowPath = Form.Items[Form.CurrentItem.Name].CurrentData;
		
		RowData.Presentation = RowPath[Item.Name];
		RowData.Value      = RowPath[Item.Name + "Value"];
		
	EndIf;
	
	Return RowData;
	
EndFunction

// Processes entering a comment using the context menu.
Procedure EnterComment(Val Form, Val AttributeName, Val FoundRow, Val Result)
	Comment = FoundRow.Comment;
	
	Notification = New NotifyDescription("EnterCommentCompletion", ThisObject, New Structure);
	Notification.AdditionalParameters.Insert("Form", Form);
	Notification.AdditionalParameters.Insert("CommentAttributeName", "Comment" + AttributeName);
	Notification.AdditionalParameters.Insert("FoundRow", FoundRow);
	Notification.AdditionalParameters.Insert("PreviousComment", Comment);
	Notification.AdditionalParameters.Insert("Result", Result);
	Notification.AdditionalParameters.Insert("ItemForPlacementName", FoundRow.ItemForPlacementName);
	
	CommonClient.ShowMultilineTextEditingForm(Notification, Comment, 
		NStr("ru = 'Комментарий'; en = 'Comment'; pl = 'Uwagi';de = 'Kommentar';ro = 'Cometariu';tr = 'Yorum'; es_ES = 'Comentario'"));
EndProcedure

// Completes a nonmodal dialog.
Procedure EnterCommentCompletion(Val Comment, Val AdditionalParameters) Export
	If Comment = Undefined Or Comment = AdditionalParameters.PreviousComment Then
		// Canceling entry or no changes.
		Return;
	EndIf;
	
	CommentWasEmpty  = IsBlankString(AdditionalParameters.PreviousComment);
	CommentBecameEmpty = IsBlankString(Comment);
	
	AdditionalParameters.FoundRow.Comment = Comment;
	
	If CommentWasEmpty AND Not CommentBecameEmpty Then
		AdditionalParameters.Result.Insert("IsCommentAddition", True);
	ElsIf Not CommentWasEmpty AND CommentBecameEmpty Then
		AdditionalParameters.Result.Insert("IsCommentAddition", False);
	Else
		If AdditionalParameters.Form.Items.Find(AdditionalParameters.CommentAttributeName) <> Undefined Then
			Item = AdditionalParameters.Form.Items[AdditionalParameters.CommentAttributeName];
			Item.Title = Comment;
		Else
			AdditionalParameters.Result.Insert("IsCommentAddition", True);
		EndIf;
	EndIf;
	
	AdditionalParameters.Form.Modified = True;
	UpdateFormContactInformation(AdditionalParameters.Form, AdditionalParameters.Result)
EndProcedure

// Context call
Procedure UpdateFormContactInformation(Form, Result)

	Form.Attachable_UpdateContactInformation(Result);
	
EndProcedure

Procedure OnContactInformationChange(Form, Item, IsTabularSection, UpdateForm)
	
	IsTabularSection = IsTabularSection(Item);
	
	If IsTabularSection Then
		FillingData = Form.Items[Form.CurrentItem.Name].CurrentData;
		If FillingData = Undefined Then
			Return;
		EndIf;
	Else
		FillingData = Form;
	EndIf;
	
	// Clearing presentation if clearing is required.
	RowData = GetAdditionalValueString(Form, Item, IsTabularSection);
	If RowData = Undefined Then 
		Return;
	EndIf;
	
	Text = Item.EditText;
	If IsBlankString(Text) Then
		
		FillingData[Item.Name] = "";
		If IsTabularSection Then
			FillingData[Item.Name + "Value"] = "";
		EndIf;
		RowData.Presentation = "";
		RowData.Value      = "";
		Result = New Structure("UpdateConextMenu, ItemForPlacementName", True, RowData.ItemForPlacementName);
		If UpdateForm Then
			UpdateConextMenu(Form, RowData.ItemForPlacementName);
		EndIf;
		Return;
		
	EndIf;
	
	If RowData.Property("StoreChangeHistory")
		AND RowData.StoreChangeHistory
		AND BegOfDay(RowData.ValidFrom) <> BegOfDay(CommonClient.SessionDate()) Then
		HistoricalContactInformation = Form.ContactInformationAdditionalAttributesDetails.Add();
		FillPropertyValues(HistoricalContactInformation, RowData);
		HistoricalContactInformation.IsHistoricalContactInformation = True;
		HistoricalContactInformation.AttributeName = "";
		RowData.ValidFrom = BegOfDay(CommonClient.SessionDate());
	EndIf;
	
	RowData.Value = ContactInformationManagementInternalServerCall.ContactsByPresentation(Text, RowData.Kind);
	RowData.Presentation = Text;
	
	If IsTabularSection Then
		FillingData[Item.Name + "Value"]      = RowData.Value;
	EndIf;
	
	If RowData.Type = PredefinedValue("Enum.ContactInformationTypes.Address") AND UpdateForm Then
		Result = New Structure("UpdateConextMenu, ItemForPlacementName", True, RowData.ItemForPlacementName);
		UpdateFormContactInformation(Form, Result)
	EndIf;

EndProcedure

Function IsTabularSection(Item)
	
	Parent = Item.Parent;
	
	While TypeOf(Parent) <> Type("ManagedForm") Do
		
		If TypeOf(Parent) = Type("FormTable") Then
			Return True;
		EndIf;
		
		Parent = Parent.Parent;
		
	EndDo;
	
	Return False;
	
EndFunction

// determining a context menu command.
Function ContextMenuCommand(CommandName)
	
	Result = New Structure("Command, MovementDirection, AttributeName", Undefined, 0, Undefined);
	
	AttributeName = ?(StrStartsWith(CommandName, "ContextMenuSubmenu"),
		StrReplace(CommandName, "ContextMenuSubmenu", ""), StrReplace(CommandName, "ContextMenu", ""));
		
	If StrStartsWith(AttributeName, "Up") Then
		Result.AttributeName = StrReplace(AttributeName, "Up", "");
		Result.MovementDirection = -1;
		Result.Command = "Up";
	ElsIf StrStartsWith(AttributeName, "History") Then
		Result.AttributeName = StrReplace(AttributeName, "History", "");
		Result.Command = "History";
	ElsIf StrStartsWith(AttributeName, "Down") Then
		Result.AttributeName = StrReplace(AttributeName, "Down", "");
		Result.MovementDirection = 1;
		Result.Command = "Down";
	ElsIf StrStartsWith(AttributeName, "YandexMap") Then
		Result.AttributeName = StrReplace(AttributeName, "YandexMap", "");
		Result.Command = "YandexMap";
	ElsIf StrStartsWith(AttributeName, "GoogleMap") Then
		Result.AttributeName = StrReplace(AttributeName, "GoogleMap", "");
		Result.Command = "GoogleMap";
	Else
		Result.AttributeName = StrReplace(AttributeName, "Comment", "");
		Result.Command = "Comment";
	EndIf;
	
	Return Result;
	
EndFunction

// Checks whether the telephony application is installed on the computer. 
//  Check is available only in thin client for Windows.
//
// Parameters:
//  ProtocolName - String - a name of an URI protocol to be checked. Available options are "skype", "tel", and "sip".
//                          If the parameter is not specified, all protocols are checked.
// 
// Returns:
//  String - a name of an available URI protocol is registered in the registry. Blank string - if a protocol is unavailable.
//  Undefined if check is impossible.
//
Function TelephonyApplicationInstalled(ProtocolName = Undefined)
	
	If CommonClient.IsWindowsClient() Then
		If ValueIsFilled(ProtocolName) Then
			Return ?(ProtocolNameRegisteredInRegistry(ProtocolName), ProtocolName, "");
		Else
			ProtocolList = New Array;
			ProtocolList.Add("tel");
			ProtocolList.Add("sip");
			ProtocolList.Add("skype");
			For each ProtocolName In ProtocolList Do
				If ProtocolNameRegisteredInRegistry(ProtocolName) Then
					Return ProtocolName;
				EndIf;
			EndDo;
			Return Undefined;
		EndIf;
	EndIf;
	
	// Considering that the application is always available for Linux and MacOS.
	// if an error occurs, it will be processed at startup.
	Return ProtocolName;
EndFunction

Function ProtocolNameRegisteredInRegistry(ProtocolName)
	
#If MobileClient Then
	Return False;
#Else
	Try
		Shell = New COMObject("Wscript.Shell");
		Shell.RegRead("HKEY_CLASSES_ROOT\" + ProtocolName + "\");
	Except
		Return False;
	EndTry;
	Return True;
#EndIf

EndFunction

////////////////////////////////////////////////////////////////////////////////
// Returns a string in which all non-alphanumeric characters (except -_.) are replaced with the 
// percent sign (%) followed by two hexadecimal digits and spaces encoded as plus signs (+). The 
// string is encoded in the same way as post data of WWW form, that is, as in 
// application/x-www-form-urlencoded media type.

Function URLEncode(Row) 
	Result = "";
	For CharNumber = 1 To StrLen(Row) Do
		CharCode = CharCode(Row, CharNumber);
		Char = Mid(Row, CharNumber, 1);
		
		// ignoring A...Z, a...z, 0...9
		If StrFind("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789", Char) > 0 Then // encoding characters -_.!~*\() as unsafe
			Result = Result + Char;
			Continue;
		EndIf;
		
		If Char = " " Then
			Result = Result + "+";
			Continue;
		EndIf;
		
		If CharCode <= 127 Then // 0x007F
			Result = Result + BytePresentation(CharCode);
		ElsIf CharCode <= 2047 Then // 0x07FF 
			Result = Result 
					  + BytePresentation(
					  					   BinaryArrayToNumber(
																LogicalBitwiseOr(
																			 NumberToBinaryArray(192,8),
																			 NumberToBinaryArray(Int(CharCode / Pow(2,6)),8)))); // 0xc0 | (ch >> 6)
			Result = Result 
					  + BytePresentation(
					  					   BinaryArrayToNumber(
										   						LogicalBitwiseOr(
																			 NumberToBinaryArray(128,8),
																			 LogicalBitwiseAnd(
																			 			NumberToBinaryArray(CharCode,8),
																						NumberToBinaryArray(63,8)))));  //0x80 | (ch & 0x3F)
		Else  // 0x7FF < ch <= 0xFFFF
			Result = Result 
					  + BytePresentation	(
					  						 BinaryArrayToNumber(
																  LogicalBitwiseOr(
																			   NumberToBinaryArray(224,8), 
																			   NumberToBinaryArray(Int(CharCode / Pow(2,12)),8)))); // 0xe0 | (ch >> 12)
											
			Result = Result 
					  + BytePresentation(
					  					   BinaryArrayToNumber(
										   						LogicalBitwiseOr(
																			 NumberToBinaryArray(128,8),
																			 LogicalBitwiseAnd(
																			 			NumberToBinaryArray(Int(CharCode / Pow(2,6)),8),
																						NumberToBinaryArray(63,8)))));  //0x80 | ((ch >> 6) & 0x3F)
											
			Result = Result 
					  + BytePresentation(
					  					   BinaryArrayToNumber(
										   						LogicalBitwiseOr(
																			 NumberToBinaryArray(128,8),
																			 LogicalBitwiseAnd(
																			 			NumberToBinaryArray(CharCode,8),
																						NumberToBinaryArray(63,8)))));  //0x80 | (ch & 0x3F)
								
		EndIf;
	EndDo;
	Return Result;
EndFunction

Function BytePresentation(Val Byte)
	Result = "";
	CharactersString = "0123456789ABCDEF";
	For Counter = 1 To 2 Do
		Result = Mid(CharactersString, Byte % 16 + 1, 1) + Result;
		Byte = Int(Byte / 16);
	EndDo;
	Return "%" + Result;
EndFunction

Function NumberToBinaryArray(Val Number, Val TotalDigits = 32)
	Result = New Array;
	CurrentDigit = 0;
	While CurrentDigit < TotalDigits Do
		CurrentDigit = CurrentDigit + 1;
		Result.Add(Boolean(Number % 2));
		Number = Int(Number / 2);
	EndDo;
	Return Result;
EndFunction

Function BinaryArrayToNumber(Array)
	Result = 0;
	For DigitNumber = -(Array.Count()-1) To 0 Do
		Result = Result * 2 + Number(Array[-DigitNumber]);
	EndDo;
	Return Result;
EndFunction

Function LogicalBitwiseAnd(BinaryArray1, BinaryArray2)
	Result = New Array;
	For Index = 0 To BinaryArray1.Count()-1 Do
		Result.Add(BinaryArray1[Index] AND BinaryArray2[Index]);
	EndDo;	
	Return Result;
EndFunction

Function LogicalBitwiseOr(BinaryArray1, BinaryArray2)
	Result = New Array;
	For Index = 0 To BinaryArray1.Count()-1 Do
		Result.Add(BinaryArray1[Index] Or BinaryArray2[Index]);
	EndDo;	
	Return Result;
EndFunction

Procedure UpdateConextMenu(Form, ItemForPlacementName)
	
	ContactInformationParameters = Form.ContactInformationParameters[ItemForPlacementName];
	AllRows = Form.ContactInformationAdditionalAttributesDetails;
	FoundRows = AllRows.FindRows( 
		New Structure("Type, IsTabularSectionAttribute", PredefinedValue("Enum.ContactInformationTypes.Address"), False));
		
	TotalCommands = 0;
	For Each CIRow In AllRows Do
		
		If TotalCommands > 50 Then // Restriction for a large number of addresses on the form
			Break;
		EndIf;
		
		If CIRow.Type <> PredefinedValue("Enum.ContactInformationTypes.Address") Then
			Continue;
		EndIf;
		
		SubmenuCopyAddresses = Form.Items.Find("SubmenuCopyAddresses" + CIRow.AttributeName);
		ContextSubmenuCopyAddresses = Form.Items.Find("ContextSubmenuCopyAddresses" + CIRow.AttributeName);
		If SubmenuCopyAddresses <> Undefined AND ContextSubmenuCopyAddresses = Undefined Then
			Continue;
		EndIf;
			
		CommandsCountInSubmenu = 0;
		AddressesListInSubmenu = New Map();
		AddressesListInSubmenu.Insert(Upper(CIRow.Presentation), True);
		
		For Each Address In FoundRows Do
			
			If CommandsCountInSubmenu > 7 Then // Restriction for a large number of addresses on the form
				Break;
			EndIf;
			
			If Address.IsHistoricalContactInformation Or Address.AttributeName = CIRow.AttributeName Then
				Continue;
			EndIf;
			
			CommandName = "MenuSubmenuAddress" + CIRow.AttributeName + "_" + Address.AttributeName;
			Command = Form.Commands.Find(CommandName);
			If Command = Undefined Then
				Command = Form.Commands.Add(CommandName);
				Command.ToolTip = NStr("ru = 'Скопировать адрес'; en = 'Copy address'; pl = 'Skopiować adres';de = 'Adresse kopieren';ro = 'Copie adresa';tr = 'Adresi kopyala'; es_ES = 'Copiar la dirección'");
				Command.Action = "Attachable_ContactInformationExecuteCommand";
				Command.ModifiesStoredData = True;
				
				ContactInformationParameters.AddedItems.Add(CommandName, 9, True);
				CommandsCountInSubmenu = CommandsCountInSubmenu + 1;
			EndIf;
			
			AddressPresentation = ?(CIRow.InternationalAddressFormat,
				StringFunctionsClientServer.LatinString(Address.Presentation), Address.Presentation);
			
			If AddressesListInSubmenu[Upper(Address.Presentation)] <> Undefined Then
				AddressPresentation = "";
			Else
				AddressesListInSubmenu.Insert(Upper(Address.Presentation), True);
			EndIf;
			
			If SubmenuCopyAddresses <> Undefined Then
				AddButtonCopyAddress(Form, CommandName,
					AddressPresentation, ContactInformationParameters, SubmenuCopyAddresses);
				EndIf;
				
			If ContextSubmenuCopyAddresses <> Undefined Then
				AddButtonCopyAddress(Form, CommandName, 
					AddressPresentation, ContactInformationParameters, ContextSubmenuCopyAddresses);
			EndIf;
			
		EndDo;
		TotalCommands = TotalCommands + CommandsCountInSubmenu;
	EndDo;
	
EndProcedure

Procedure AddButtonCopyAddress(Form, CommandName, ItemTitle, ContactInformationParameters, Submenu)
	
	ItemName = Submenu.Name + "_" + CommandName;
	Button = Form.Items.Find(ItemName);
	If Button = Undefined Then
		Button = Form.Items.Add(ItemName, Type("FormButton"), Submenu);
		Button.CommandName = CommandName;
		ContactInformationParameters.AddedItems.Add(ItemName, 1);
	EndIf;
	Button.Title = ItemTitle;
	Button.Visible = ValueIsFilled(ItemTitle);

EndProcedure

#EndRegion
