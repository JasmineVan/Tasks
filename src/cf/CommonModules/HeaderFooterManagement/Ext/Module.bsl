///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
// HeaderFooterControl: setting and output mechanism of headers and footers.
//
////////////////////////////////////////////////////////////////////////////////

#Region Public

// Gets header and footer settings received earlier. If settings are missing, a lank setting form is 
// returned.
//
// Returns:
//   Structure - values of headers and footers settings.
Function HeaderOrFooterSettings() Export
	Var Settings;
	
	Storage = Constants.HeaderOrFooterSettings.Get();
	If TypeOf(Storage) = Type("ValueStorage") Then
		Settings = Storage.Get();
		If TypeOf(Settings) = Type("Structure") Then
			If Not Settings.Property("Header") 
				Or Not Settings.Property("Footer") Then
				Settings = Undefined;
			Else
				AddHeaderOrFooterSettings(Settings.Header);
				AddHeaderOrFooterSettings(Settings.Footer);
			EndIf;
		EndIf;
	EndIf;
	
	If Settings = Undefined Then
		Settings = BlankHeaderOrFooterSettings();
	EndIf;
	
	Return Settings;
EndFunction

#EndRegion

#Region Private

// Saves settings of headers and footers passed in the parameter to use them later.
//
// Parameters:
//  Settings - Structure - values of headers and footers settings to be saved.
//
Procedure SaveHeadersAndFootersSettings(Settings) Export
	Constants.HeaderOrFooterSettings.Set(New ValueStorage(Settings));
EndProcedure

// Sets the ReportDescription and User parameter values in template row.
//
//  Template - String - setting a header or footer whose parameter values are not set yet.
//  ReportDescription - String - a parameter value that will be inserted to the template.
//  User - CatalogRef.Users - a parameter value that will be inserted to the template.
//
// Returns:
//   String - a header or footer setting with the set template values.
//
Function PropertyValueFromTemplate(Template, ReportDescription, User)
	Result = StrReplace(Template, "[&ReportDescription]", TrimAll(ReportDescription));
	Result = StrReplace(Result, "[&User]"  , TrimAll(User));
	
	Return Result;
EndFunction

// Sets headers and footers in a spreadsheet document.
//
// Parameters:
//  SpreadsheetDocument - SpreadsheetDocument - a document that requires setting headers and footers.
//  ReportDescription - String - a parameter value that will be inserted to the template.
//  User - CatalogRef.Users - a parameter value that will be inserted to the template.
//  HeaderOrFooterSettings - Structure - individual settings of headers and footers.
//
Procedure SetHeadersAndFooters(SpreadsheetDocument, ReportDescription = "", User = Undefined, HeaderOrFooterSettings = Undefined) Export
	If User = Undefined Then
		User = Users.AuthorizedUser();
	EndIf;
	
	If HeaderOrFooterSettings = Undefined Then 
		HeaderOrFooterSettings = HeaderOrFooterSettings();
	EndIf;
	
	HeaderOrFooterProperties = HeaderOrFooterProperties(HeaderOrFooterSettings.Header, ReportDescription, User);
	FillPropertyValues(SpreadsheetDocument.Header, HeaderOrFooterProperties);
	
	HeaderOrFooterProperties = HeaderOrFooterProperties(HeaderOrFooterSettings.Footer, ReportDescription, User);
	FillPropertyValues(SpreadsheetDocument.Footer, HeaderOrFooterProperties);
EndProcedure

// Returns property values of a header or a footer.
//
// Parameters:
//  HeaderOrFooterSettings - Structure - see BlankHeaderOrFooterSettings(). 
//  ReportDescription - String - a parameter value that will be inserted to the [&ReportDescription] template.
//  User - CatalogRef.Users - a value that will be inserted to the [&User] template.
//
// Returns:
//   Structure - values of headers and footers settings.
//
Function HeaderOrFooterProperties(HeaderOrFooterSettings, ReportDescription, User)
	HeaderOrFooterProperties = New Structure;
	If ValueIsFilled(HeaderOrFooterSettings.LeftText)
		Or ValueIsFilled(HeaderOrFooterSettings.CenterText)
		Or ValueIsFilled(HeaderOrFooterSettings.RightText) Then
		
		HeaderOrFooterProperties.Insert("Output", True);
		HeaderOrFooterProperties.Insert("HomePage", HeaderOrFooterSettings.HomePage);
		HeaderOrFooterProperties.Insert("VerticalAlign", HeaderOrFooterSettings.VerticalAlign);
		HeaderOrFooterProperties.Insert("LeftText", PropertyValueFromTemplate(
			HeaderOrFooterSettings.LeftText, ReportDescription, User));
		HeaderOrFooterProperties.Insert("CenterText", PropertyValueFromTemplate(
			HeaderOrFooterSettings.CenterText, ReportDescription, User));
		HeaderOrFooterProperties.Insert("RightText", PropertyValueFromTemplate(
			HeaderOrFooterSettings.RightText, ReportDescription, User));
		
		If HeaderOrFooterSettings.Property("Font") AND HeaderOrFooterSettings.Font <> Undefined Then
			HeaderOrFooterProperties.Insert("Font", HeaderOrFooterSettings.Font);
		Else
			HeaderOrFooterProperties.Insert("Font", New Font);
		EndIf;
	Else
		HeaderOrFooterProperties.Insert("Output", False);
	EndIf;
	
	Return HeaderOrFooterProperties;
EndFunction

// Headers and footers settings wizard.
//
// Returns:
//   Structure - settings of headers and footers with default values.
//
Function BlankHeaderOrFooterSettings()
	Header = New Structure;
	Header.Insert("LeftText", "");
	Header.Insert("CenterText", "");
	Header.Insert("RightText", "");
	Header.Insert("Font", New Font);
	Header.Insert("VerticalAlign", VerticalAlign.Bottom);
	Header.Insert("HomePage", 0);
	
	Footer = New Structure;
	Footer.Insert("LeftText", "");
	Footer.Insert("CenterText", "");
	Footer.Insert("RightText", "");
	Footer.Insert("Font", New Font);
	Footer.Insert("VerticalAlign", VerticalAlign.Top);
	Footer.Insert("HomePage", 0);
	
	Return New Structure("Header, Footer", Header, Footer);
EndFunction

Procedure AddHeaderOrFooterSettings(HeaderOrFooterSettings)
	If Not HeaderOrFooterSettings.Property("LeftText")
		Or TypeOf(HeaderOrFooterSettings.LeftText) <> Type("String") Then
		HeaderOrFooterSettings.Insert("LeftText", "");
	EndIf;
	If Not HeaderOrFooterSettings.Property("CenterText")
		Or TypeOf(HeaderOrFooterSettings.CenterText) <> Type("String") Then
		HeaderOrFooterSettings.Insert("CenterText", "");
	EndIf;
	If Not HeaderOrFooterSettings.Property("RightText")
		Or TypeOf(HeaderOrFooterSettings.RightText) <> Type("String") Then
		HeaderOrFooterSettings.Insert("RightText", "");
	EndIf;
	If Not HeaderOrFooterSettings.Property("Font")
		Or TypeOf(HeaderOrFooterSettings.Font) <> Type("Font") Then
		HeaderOrFooterSettings.Insert("Font", New Font);
	EndIf;
	If Not HeaderOrFooterSettings.Property("VerticalAlign")
		Or TypeOf(HeaderOrFooterSettings.VerticalAlign) <> Type("VerticalAlign") Then
		HeaderOrFooterSettings.Insert("VerticalAlign", VerticalAlign.Center);
	EndIf;
	If Not HeaderOrFooterSettings.Property("HomePage")
		Or TypeOf(HeaderOrFooterSettings.HomePage) <> Type("Number")
		Or HeaderOrFooterSettings.HomePage < 0 Then
		HeaderOrFooterSettings.Insert("HomePage", 0);
	EndIf;
EndProcedure

// Defines if settings are standard or blank.
//
// Parameters:
//  Settings - Structure - see HeaderOrFooterSettings(). 
//
// Returns:
//   Structure - info on header or footer setting status:
//     * Standard - Boolean - True if passed settings correspond to standard (common) settings that 
//                     are stored in the HeaderOrFooterSettings constant.
//     * Blank - Boolean - True if passed settings correspond to blank settings returned by the 
//                BlankHeaderOrFooterSettings() function.
//
Function HeadersAndFootersSettingsStatus(Settings) Export 
	SettingsStatus = New Structure("Standard, Empty");
	SettingsStatus.Standard = Common.DataMatch(Settings, HeaderOrFooterSettings());
	SettingsStatus.Empty = Common.DataMatch(Settings, BlankHeaderOrFooterSettings());
	
	Return SettingsStatus;
EndFunction

#EndRegion