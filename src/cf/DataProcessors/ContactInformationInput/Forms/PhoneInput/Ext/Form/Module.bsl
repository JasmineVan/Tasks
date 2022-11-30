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
//
// -------------------------------------------------------------------------------------------------

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Parameters.Property("ReturnValueList", ReturnValueList);
	
	// Copying parameters to attributes.
	If TypeOf(Parameters.ContactInformationKind) = Type("CatalogRef.ContactInformationKinds") Then
		ContactInformationKind = Parameters.ContactInformationKind;
		ContactInformationType = ContactInformationKind.Type;
	Else
		ContactInformationKindStructure = Parameters.ContactInformationKind;
		ContactInformationType = ContactInformationKindStructure.Type;
	EndIf;
	
	CheckValidity      = ContactInformationKind.CheckValidity;
	Title = ?(IsBlankString(Parameters.Title), String(ContactInformationKind), Parameters.Title);
	IsNew = False;
	
	FieldsValues = DefineAddressValue(Parameters);
	
	If IsBlankString(FieldsValues) Then
		Data = ContactsManager.NewContactInformationDetails(ContactInformationType);
		IsNew = True;
	ElsIf ContactsManagerClientServer.IsJSONContactInformation(FieldsValues) Then
		Data = ContactsManagerInternal.JSONToContactInformationByFields(FieldsValues, Enums.ContactInformationTypes.Phone);
	Else
		
		If ContactsManagerClientServer.IsXMLContactInformation(FieldsValues) Then
			ReadResults = New Structure;
			ContactInformation = ContactsManagerInternal.ContactsFromXML(FieldsValues, ContactInformationType, ReadResults);
			If ReadResults.Property("ErrorText") Then
				// Recognition errors. A warning must be displayed when opening the form.
				WarningTextOnOpen = ReadResults.ErrorText;
				ContactInformation.Presentation   = Parameters.Presentation;
			EndIf;
		Else
			If ContactInformationType = Enums.ContactInformationTypes.Phone Then
				ContactInformation = ContactsManagerInternal.PhoneDeserialization(FieldsValues, Parameters.Presentation, ContactInformationType);
			Else
				ContactInformation = ContactsManagerInternal.FaxDeserialization(FieldsValues, Parameters.Presentation, ContactInformationType);
			EndIf;
		EndIf;
		
		Data = ContactsManagerInternal.ContactInformationToJSONStructure(ContactInformation, ContactInformationType);
		
	EndIf;
	
	ContactInformationAttibutesValues(Data);
	
	Items.Extension.Visible = ContactInformationKind.PhoneWithExtension;
	Items.ClearPhone.Visible = False;
	
	Codes = Common.CommonSettingsStorageLoad("DataProcessor.ContactInformationInput.Form.PhoneInput", "CountryAndCityCodes");
	If TypeOf(Codes) = Type("Structure") Then
		If IsNew Then
				Codes.Property("CountryCode", CountryCode);
				Codes.Property("CityCode", CityCode);
		EndIf;
		
		If Codes.Property("CityCodesList") Then
			Items.CityCode.ChoiceList.LoadValues(Codes.CityCodesList);
		EndIf;
	EndIf;
	
	If ContactInformationKind.StoreChangeHistory Then
		If Parameters.Property("ContactInformationAdditionalAttributesDetails") Then
			For each CIRow In Parameters.ContactInformationAdditionalAttributesDetails Do
				NewRow = ContactInformationAdditionalAttributesDetails.Add();
				FillPropertyValues(NewRow, CIRow);
			EndDo;
		EndIf;
	EndIf;
	
	If Common.IsMobileClient() Then
		
		CommandBarLocation = FormCommandBarLabelLocation.Auto;
		
		CommonClientServer.SetFormItemProperty(Items, "Presentation", "InputHint", NStr("ru ='Представление'; en = 'Presentation'; pl = 'Nazwa';de = 'Präsentation';ro = 'Prezentare';tr = 'Sunum'; es_ES = 'Presentación'"));
		CommonClientServer.SetFormItemProperty(Items, "OkCommand", "Picture", PictureLib.WriteAndClose);
		CommonClientServer.SetFormItemProperty(Items, "OkCommand", "Representation", ButtonRepresentation.Picture);
		CommonClientServer.SetFormItemProperty(Items, "Cancel", "Visible", False);
		
		CommonClientServer.SetFormItemProperty(Items, "CountryCode", "TitleLocation", FormItemTitleLocation.Left);
		CommonClientServer.SetFormItemProperty(Items, "CityCode", "TitleLocation", FormItemTitleLocation.Left);
		CommonClientServer.SetFormItemProperty(Items, "PhoneNumber", "TitleLocation", FormItemTitleLocation.Left);
		CommonClientServer.SetFormItemProperty(Items, "Extension", "TitleLocation", FormItemTitleLocation.Left);
		
		If Items.CityCode.ChoiceList.Count() < 2 Then
			
			Items.CityCode.DropListButton = Undefined;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Not IsBlankString(WarningTextOnOpen) Then
		AttachIdleHandler("Attachable_WarnAfterOpenForm", 0.1, True);
	EndIf;
	
	If ValueIsFilled(CityCode) Then
		CurrentItem = Items.CityCode;
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	Notification = New NotifyDescription("ConfirmAndClose", ThisObject);
	CommonClient.ShowFormClosingConfirmation(Notification, Cancel, Exit);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CountryCodeOnChange(Item)
	
	FillPhonePresentation();
	
EndProcedure

&AtClient
Procedure AreaCodeOnChange(Item)
	
	If (CountryCode = "+7" OR CountryCode = "8") AND StrStartsWith(CityCode, "9") AND StrLen(CityCode) <> 3 Then
		CommonClient.MessageToUser(NStr("ru = 'Коды мобильных телефонов начинающиеся на цифру 9 имеют фиксированную длину в 3 цифры, например - 916.'; en = 'If code of a cell phone begins with 9, it must have 3-digit length. For example, 916.'; pl = 'Kody telefonów komórkowych zaczynające się od 9 mają stałą długość 3 cyfr, na przykład 916.';de = 'Vorwahlen von Mobiltelefonen, die mit der Zahl 9 beginnen, haben eine feste Länge von 3 Ziffern, zum Beispiel- 916.';ro = 'Codurile de telefoane mobile care încep cu cifra 9 au o lungime fixă de 3 cifre, de exemplu - 916.';tr = '9 rakamıyla başlayan cep telefonu kodları, örneğin 3 basamaklı sabit bir uzunluğa sahiptir - 916.'; es_ES = 'Los códigos de los teléfonos móviles que empiezan con el número 9 tienen una longitud fija de 3 números, por ejemplo - 916.'"),, "CityCode");
	EndIf;
	
	FillPhonePresentation();
EndProcedure

&AtClient
Procedure PhoneNumberOnChange(Item)
	
	FillPhonePresentation();
	
EndProcedure

&AtClient
Procedure ExtensionOnChange(Item)
	
	FillPhonePresentation();
	
EndProcedure

&AtClient
Procedure CommentOnChange(Item)
	FillPhonePresentation();
EndProcedure

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
Procedure ClearPhone(Command)
	
	ClearPhoneServer();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure Attachable_WarnAfterOpenForm()
	
	CommonClient.MessageToUser(WarningTextOnOpen);
	
EndProcedure

&AtClient
Procedure ConfirmAndClose(Result = Undefined, AdditionalParameters = Undefined) Export
	
	// When unmodified, it functions as "cancel".
	
	If Modified Then
		
		HasFillingErrors = False;
		// Determining whether validation is required.
		If CheckValidity Then
			ErrorsList = PhoneFillingErrors();
			HasFillingErrors = ErrorsList.Count() > 0;
		EndIf;
		If HasFillingErrors Then
			NotifyFillErrors(ErrorsList);
			Return;
		EndIf;
		
		Result = SelectionResult();
	
		ClearModifiedOnChoice();
		NotifyChoice(Result);
		
	ElsIf Comment <> CommentCopy Then
		// Only the comment was modified, attempting to revert.
		Result = CommentChoiceOnlyResult();
		
		ClearModifiedOnChoice();
		NotifyChoice(Result);
		
	Else
		Result = Undefined;
		
	EndIf;
	
	If (ModalMode Or CloseOnChoice) AND IsOpen() Then
		ClearModifiedOnChoice();
		Close(Result);
	EndIf;
	
EndProcedure

&AtClient
Procedure ClearModifiedOnChoice()
	
	Modified = False;
	CommentCopy   = Comment;
	
EndProcedure

&AtServer
Function SelectionResult()
	
	Result = New Structure();
	
	ChoiceList = Items.CityCode.ChoiceList;
	ListItem = ChoiceList.FindByValue(CityCode);
	If ListItem = Undefined Then
		ChoiceList.Insert(0, CityCode);
		If ChoiceList.Count() > 10 Then
			ChoiceList.Delete(10);
		EndIf;
	Else
		Index = ChoiceList.IndexOf(ListItem);
		If Index <> 0 Then
			ChoiceList.Move(Index, -Index);
		EndIf;
	EndIf;
	
	Codes = New Structure("CountryCode, CityCode, CityCodesList", CountryCode, CityCode, ChoiceList.UnloadValues());
	Common.CommonSettingsStorageSave("DataProcessor.ContactInformationInput.Form.PhoneInput", "CountryAndCityCodes", Codes, NStr("ru = 'Коды страны и города'; en = 'Codes of country and city.'; pl = 'Kody kraju i miasta';de = 'Коды страны и города';ro = 'Codul țării și orașului';tr = 'Ülke ve şehir kodu'; es_ES = 'Códigos de país y ciudad'"));
	
	ContactInformation = ContactInformationByAttributesValues();
	
	ChoiceData = ContactsManagerInternal.ToJSONStringStructure(ContactInformation);
	
	Result.Insert("Kind", ContactInformationKind);
	Result.Insert("Type", ContactInformationType);
	Result.Insert("ContactInformation", ContactsManager.ContactInformationToXML(ChoiceData, ContactInformation.Value, ContactInformationType));
	Result.Insert("Value", ChoiceData);
	Result.Insert("Presentation", ContactInformation.Value);
	Result.Insert("Comment", ContactInformation.Comment);
	Result.Insert("ContactInformationAdditionalAttributesDetails",
		ContactInformationAdditionalAttributesDetails);
	
	Return Result
EndFunction

&AtServer
Function CommentChoiceOnlyResult()
	
	ContactInfo = DefineAddressValue(Parameters);
	If IsBlankString(ContactInfo) Then
		If ContactInformationType = Enums.ContactInformationTypes.Phone Then
			ContactInfo = ContactsManagerInternal.PhoneDeserialization("", "", ContactInformationType);
		Else
			ContactInfo = ContactsManagerInternal.FaxDeserialization("", "", ContactInformationType);
		EndIf;
		ContactsManager.SetContactInformationComment(ContactInfo, Comment);
		ContactInfo = ContactsManager.ContactInformationToXML(ContactInfo);
		
	ElsIf ContactsManagerClientServer.IsXMLContactInformation(ContactInfo) Then
		ContactsManager.SetContactInformationComment(ContactInfo, Comment);
	EndIf;
	
	Return New Structure("ContactInformation, Presentation, Comment",
		ContactInfo, Parameters.Presentation, Comment);
EndFunction

// Fills in form attributes based on XTDO object of the Contact information type.
&AtServer
Procedure ContactInformationAttibutesValues(InformationToEdit)
	
	// Common attributes
	Presentation = InformationToEdit.Value;
	Comment   = InformationToEdit.Comment;
	
	// Comment copy used to analyze changes.
	CommentCopy = Comment;
	
	CountryCode     = InformationToEdit.CountryCode;
	CityCode     = InformationToEdit.AreaCode;
	PhoneNumber = InformationToEdit.Number;
	Extension    = InformationToEdit.ExtNumber;
	
EndProcedure

// Returns an XTDO object of the Contact information type based on attribute values.
&AtServer
Function ContactInformationByAttributesValues()
	
	Result = ContactsManagerClientServer.NewContactInformationDetails(ContactInformationType);
	
	Result.CountryCode = CountryCode;
	Result.AreaCode    = CityCode;
	Result.Number      = PhoneNumber;
	Result.ExtNumber   = Extension;
	Result.Value       = ContactsManagerClientServer.GeneratePhonePresentation(CountryCode, CityCode, PhoneNumber, Extension, "");
	Result.Comment     = Comment;
	
	Return Result;
	
EndFunction

&AtClient
Procedure FillPhonePresentation()
	
	AttachIdleHandler("FillPhonePresentationNow", 0.1, True);
	
EndProcedure    

&AtClient
Procedure FillPhonePresentationNow()
	
	Presentation = ContactsManagerClientServer.GeneratePhonePresentation(CountryCode, CityCode, PhoneNumber, Extension, Comment);
	
EndProcedure

// Returns a list of filling errors as a value list:
//      Presentation   - an error description.
//      Value - XPath for the field.
&AtClient
Function PhoneFillingErrors()
	
	ErrorsList = New ValueList;
	FullPhoneNumber = CountryCode + CityCode + PhoneNumber;
	PhoneNumberNumbersOnly = NumbersOnly(FullPhoneNumber);
	
	If StrLen(PhoneNumberNumbersOnly) > 15 Then
		ErrorsList.Add("PhoneNumber", NStr("ru = 'Номер телефона слишком длинный'; en = 'Phone number is too long.'; pl = 'Zbyt długi numer telefonu';de = 'Die Telefonnummer ist zu lang';ro = 'Numărul de telefon este prea lung';tr = 'Telefon numarası çok uzun'; es_ES = 'Número de teléfono es demasiado largo'"));
	EndIf;
	
	If PhoneNumberContainsProhibitedChars(FullPhoneNumber) Then
		ErrorsList.Add("PhoneNumber", NStr("ru = 'Номер телефона содержит недопустимые символы'; en = 'Phone number contains illegal characters.'; pl = 'Numer telefonu zawiera nieprawidłowe znaki.';de = 'Die Telefonnummer enthält ungültige Zeichen';ro = 'Numerele de telefoane conțin simboluri inadmisibile';tr = 'Telefon numarası uygunsuz karakterleri içeriyor'; es_ES = 'Número de teléfonos contiene símbolos inadmisibles'"));
	EndIf;
	
	If CountryCode = "7" OR CountryCode = "+7" Then
		If StrLen(NumbersOnly(PhoneNumber)) > 7 Then
			ErrorsList.Add("PhoneNumber", NStr("ru = 'В России номер телефона не может быть больше 7 цифр'; en = 'Russian phone numbers cannot contain more than 7 digits.'; pl = 'W Rosji numer telefonu nie może przekraczać 7 cyfr';de = 'In Russland darf die Telefonnummer nicht mehr als 7-stellig sein';ro = 'În Rusia numerele de telefon nu pot fi mai mari decât 7 cifre';tr = 'Rusya''da telefon numarası 7 haneden fazla olamaz'; es_ES = 'En Rusia el número de teléfono no puede superar 7 dígitos'"));
		EndIf;
	EndIf;
	
	If StrStartsWith(CityCode, "9") AND StrLen(CityCode) <> 3 Then
		ErrorsList.Add("PhoneNumber", NStr("ru = 'В России номера мобильных телефонов должны содержать 3 цифры'; en = 'Prefix in Russian cell phone numbers must contain 3 digits.'; pl = 'W Rosji numery telefonów komórkowych muszą zawierać 3 cyfry';de = 'In Russland müssen die Mobiltelefonnummern 3-stellig sein';ro = 'În Rusia numerele de telefoane mobile trebuie să conțină 3 cifre';tr = 'Rusya''da cep telefon numaraları 3 rakam içermelidir'; es_ES = 'En Rusia los números de teléfonos móviles deben contener 3 dígitos'"));
	EndIf;
	
	Return ErrorsList;
EndFunction

// Notifies of any filling errors based on PhoneFillingErrorsServer function results.
&AtClient
Procedure NotifyFillErrors(ErrorsList)
	
	If ErrorsList.Count()=0 Then
		ShowMessageBox(, NStr("ru='Телефон введен корректно.'; en = 'The phone number is valid.'; pl = 'Podano prawidłowy numer telefonu.';de = 'Gültige Telefonnummer eingegeben.';ro = 'Număr de telefon validat introdus.';tr = 'Geçerli telefon numarası girildi.'; es_ES = 'Número de teléfono válido introducido.'"));
		Return;
	EndIf;
	
	ClearMessages();
	
	// Values are XPaths. Presentations store error descriptions.
	For Each Item In ErrorsList Do
		CommonClient.MessageToUser(Item.Presentation,,,
		FormDataPathByXPath(Item.Value));
	EndDo;
	
EndProcedure    

&AtClient 
Function FormDataPathByXPath(XPath) 
	Return XPath;
EndFunction

&AtServer
Procedure ClearPhoneServer()
	CountryCode     = "";
	CityCode     = "";
	PhoneNumber = "";
	Extension    = "";
	Comment   = "";
	Presentation = "";
	
	Modified = True;
EndProcedure

// Checks whether the string contains only ~
//
// Parameters:
//  CheckString          - String - a string to check.
//
// Returns:
//   Boolean - True - the string contains only numbers or is empty, False - the string contains other characters.
//
&AtClient
Function PhoneNumberContainsProhibitedChars(Val CheckString)
	
	AllowedCharactersList = "+-.,() wp1234567890";
	Return StrSplit(CheckString, AllowedCharactersList, False).Count() > 0;
	
EndFunction

&AtClient
Function NumbersOnly(Val Row)
	
	ExcessCharacters = StrConcat(StrSplit(Row, "0123456789"), "");
	Result     = StrConcat(StrSplit(Row, ExcessCharacters), "");
	
	Return Result;
	
EndFunction

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

#EndRegion
