///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ContactInformationKind = Parameters.ContactInformationKind;
	If Not ValueIsFilled(ContactInformationKind) Then
		Raise NStr("ru='Команда не может быть выполнена для указанного объекта из-за некорректного внедрения контактной информации.'; en = 'Cannot execute command for the object. Contact information is invalid.'; pl = 'Polecenie nie może być wykonane dla podanego obiektu z powodu nieprawidłowego wprowadzenia informacji kontaktowych.';de = 'Der Befehl kann für das angegebene Objekt nicht ausgeführt werden, da die Kontaktinformationen falsch eingegeben wurden.';ro = 'Comanda nu poate fi executată pentru obiectul indicat din cauza implementării incorecte a informațiilor de contact.';tr = 'İletişim bilgilerinin yanlış uygulanması nedeniyle komut belirtilen nesne için gerçekleştirilemez.'; es_ES = 'El comando no puede ser rellenada para el objeto indicado a causa de importación incorrecta de información de contacto.'");
	EndIf;
	ContactInformationType = Enums.ContactInformationTypes.WebPage;
	
	Title = ?(Not Parameters.Property("Title") Or IsBlankString(Parameters.Title), String(ContactInformationKind), Parameters.Title);
	
	FieldsValues = DefineAddressValue(Parameters);
	
	If IsBlankString(FieldsValues) Then
		Data = ContactsManager.NewContactInformationDetails(ContactInformationType);
	ElsIf ContactsManagerClientServer.IsJSONContactInformation(FieldsValues) Then
		Data = ContactsManagerInternal.JSONToContactInformationByFields(FieldsValues, Enums.ContactInformationTypes.WebPage);
	Else
		
		If ContactsManagerClientServer.IsXMLContactInformation(FieldsValues) Then
			ReadResults = New Structure;
			ContactInformation = ContactsManagerInternal.ContactsFromXML(FieldsValues, ContactInformationType, ReadResults);
			If ReadResults.Property("ErrorText") Then
				// Recognition errors. A warning must be displayed when opening the form.
				ContactInformation.Presentation = Parameters.Presentation;
			EndIf;
			
			Data = ContactsManagerInternal.ContactInformationToJSONStructure(ContactInformation, ContactInformationType);
			
		Else
			Data = ContactsManager.NewContactInformationDetails(ContactInformationType);
			Data.value = FieldsValues;
			Data.Comment = Parameters.Comment;
		EndIf;
		
	EndIf;
	
	Address        = Data.Value;
	Description = TrimAll(Parameters.Presentation);
	Comment  = Data.Comment;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure OK(Command)
	
	Close(SelectionResult(Address, Description, Comment));
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function DefineAddressValue(Parameters)
	
	FieldsValues = "";
	If Parameters.Property("Value") Then
		If IsBlankString(Parameters.Value) Then
			If Parameters.Property("FieldsValues") Then
				FieldsValues = Parameters.FieldsValues;
			EndIf;
		Else
			FieldsValues = Parameters.Value;
		EndIf;
	Else
		FieldsValues = Parameters.FieldsValues;
	EndIf;
	
	Return FieldsValues;
	
EndFunction

&AtServerNoContext
Function SelectionResult(Address, Description, Comment)
	
	ContactInformationType = Enums.ContactInformationTypes.WebPage;
	WebsiteDescription = ?(ValueIsFilled(Description), Description, Address);
	
	ContactInformation         = ContactsManagerClientServer.NewContactInformationDetails(ContactInformationType );
	ContactInformation.value   = TrimAll(Address);
	ContactInformation.name    = TrimAll(WebsiteDescription);
	ContactInformation.comment = TrimAll(Comment);
	
	ChoiceData = ContactsManagerInternal.ToJSONStringStructure(ContactInformation);
	
	Result = New Structure();
	Result.Insert("Type",                  ContactInformationType);
	Result.Insert("Address",                Address);
	Result.Insert("ContactInformation", ContactsManager.ContactInformationToXML(ChoiceData, Description, ContactInformationType));
	Result.Insert("Value",             ChoiceData);
	Result.Insert("Presentation",        WebsiteDescription);
	Result.Insert("Comment",          ContactInformation.Comment);
	
	Return Result
	
EndFunction

#EndRegion