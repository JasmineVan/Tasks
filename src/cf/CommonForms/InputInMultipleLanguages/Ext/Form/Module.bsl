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
	
	MetadataObject = Parameters.Ref.Metadata();
	Attribute = MetadataObject.Attributes.Find(Parameters.AttributeName);
	If Attribute = Undefined Then
		For each StandardAttribute In MetadataObject.StandardAttributes Do
			If StrCompare(StandardAttribute.Name, Parameters.AttributeName) = 0 Then
				Attribute = StandardAttribute;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	If Attribute = Undefined Then
		ErrorTemplate = NStr("ru='При открытии формы ВводНаРазныхЯзыках в параметре ИмяРеквизита указан не существующий реквизит %1'; en = 'Issue opening the InputInDifferentLanguages form. Attribute %1 specified in the AttributeName parameter does not exist.'; pl = 'Podczas otwierania formularza InputInDifferentLanguages w parametrze AttributeName określony nieistniejący rekwizyt %1';de = 'Wenn Sie das Formular InputInDifferentLanguages im AttributeName öffnen, werden nicht vorhandene Requisiten angegeben %1';ro = 'La deschiderea formei InputInDifferentLanguages în parametrul AttributeName este indicat atributul inexistent %1';tr = 'AttributeName parametresinde InputInDifferentLanguages formu açıldığında mevcut olmayan %1 özellik belirtildi '; es_ES = 'Al abrir el formulario InputInDifferentLanguages en el parámetro AttributeName se ha indicado un requisito no existente %1'");
		Raise StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate, Parameters.AttributeName);
	EndIf;
	
	If Attribute.MultiLine Then
		StandardSubsystemsServer.SetFormAssignmentKey(ThisObject, "MultiLine");
	EndIf;
	
	For Each ConfigurationLanguage In Metadata.Languages Do
		NewString = Languages.Add();
		NewString.LanguageCode = ConfigurationLanguage.LanguageCode;
		NewString.Name = "_" + StrReplace(New UUID, "-", "");
		NewString.Presentation = ConfigurationLanguage.Presentation();
	EndDo;
	
	GenerateInputFieldsInDifferentLanguages(Attribute.MultiLine, Parameters.ReadOnly);
	
	If Not IsBlankString(Parameters.Title) Then
		Title = Parameters.Title;
	Else
		Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru='%1 на разных языках'; en = '%1 in different languages'; pl = '%1 w różnych językach';de = '%1 in verschiedenen Sprachen';ro = '%1 în diferite limbi';tr = '%1 farklı dillerde'; es_ES = '%1 en diferentes idiomas'"), Attribute.Presentation());
	EndIf;
	
	DefaultLanguage = Metadata.DefaultLanguage.LanguageCode;
	
	LanguageDetails = LanguageDetails(CurrentLanguage().LanguageCode);
	If LanguageDetails <> Undefined Then
		ThisObject[LanguageDetails.Name] = Parameters.CurrentValue;
	EndIf;
	
	For each Presentation In Parameters.Presentations Do
		
		LanguageDetails = LanguageDetails(Presentation.LanguageCode);
		If LanguageDetails <> Undefined Then
			If StrCompare(LanguageDetails.LanguageCode, CurrentLanguage().LanguageCode) = 0 Then
				ThisObject[LanguageDetails.Name] = ?(ValueIsFilled(Parameters.CurrentValue), Parameters.CurrentValue, Presentation[Parameters.AttributeName]);
			Else
				ThisObject[LanguageDetails.Name] = Presentation[Parameters.AttributeName];
			EndIf;
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure OK(Command)
	
	Result = New Structure("DefaultLanguage", DefaultLanguage);
	Result.Insert("ValuesInDifferentLanguages", New Array);
	For each Language In Languages Do
		
		If Language.LanguageCode = CurrentLanguage() Then
			Result.Insert("StringInCurrentLanguage", ThisObject[Language.Name]);
		EndIf;
		
		If CurrentLanguage() = DefaultLanguage AND Language.LanguageCode = DefaultLanguage Then
			Continue;
		EndIf;
		
		Result.ValuesInDifferentLanguages.Add(New Structure("LanguageCode, AttributeValue", Language.LanguageCode, ThisObject[Language.Name]));
	EndDo;
	
	Close(Result);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure GenerateInputFieldsInDifferentLanguages(MultilineMode, ReadOnly)
	
	Add = New Array;
	StringType = New TypeDescription("String");
	For Each ConfigurationLanguage In Languages Do
		Add.Add(New FormAttribute(ConfigurationLanguage.Name, StringType,, ConfigurationLanguage.Presentation));
	EndDo;
	
	ChangeAttributes(Add);
	ItemsParent = Items.LanguagesGroup;
	
	For Each ConfigurationLanguage In Languages Do
		
		If StrCompare(ConfigurationLanguage.LanguageCode, CurrentLanguage().LanguageCode) = 0 AND ItemsParent.ChildItems.Count() > 0 Then
			Item = Items.Insert(ConfigurationLanguage.Name, Type("FormField"), ItemsParent, ItemsParent.ChildItems.Get(0));
			CurrentItem = Item;
		Else
			Item = Items.Add(ConfigurationLanguage.Name, Type("FormField"), ItemsParent);
		EndIf;
		
		Item.DataPath        = ConfigurationLanguage.Name;
		Item.Type                = FormFieldType.InputField;
		Item.Width             = 40;
		Item.MultiLine = MultilineMode;
		Item.TitleLocation = FormItemTitleLocation.Top;
		Item.ReadOnly     = ReadOnly;
		
	EndDo;
	
EndProcedure

&AtServer
Function LanguageDetails(LanguageCode)
	
	Filter = New Structure("LanguageCode", LanguageCode);
	FoundItems = Languages.FindRows(Filter);
	If FoundItems.Count() > 0 Then
		Return FoundItems[0];
	EndIf;
	
	Return Undefined;
	
EndFunction


#EndRegion