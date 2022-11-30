///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Generates a string according to the specified pattern.
// The possible tag values in the template:
// - <span style='Property name: Style item name'>String</span> -  formats text with style items described in the style attibute
// - <b>String </b>-highlights a string by the ImportantLabelFont style item that matches the semi 
// bold font. - <a href='Ref'>String</a> - adds a hyperlink.
// - <img src='Calendar'> - adds a picture from the picture library.
// The style attribute is used to arrange the text. The attribute can be used for the span and a tags.
// First goes a style property name, then a style item name through the colon.
// Style properties:
//  - color - defines text color. For example, color: HyperlinkColor.
//  - background-color - defines color of the text background. For example, background-color: TotalsGroupBackground.
//  - font - defines text font. For example, font: MainListItem.
// Style properties are separated by semicolon. For eample, style='color: HyperlinkColor; font: MainListItem'
// Nested tags are not supported.
//
// Parameters:
//  StringTemplate - String - a string containing formatting tags.
//  Parameter<n>  - String - parameter value to insert.
//
// Returns:
//  FormattedString - a converted string.
//
// Example:
//  StringFunctionsClient.FormattedString(NStr("en='<span style=""color: LockedAttributeColor; font:
//  ImportantLabelFont""> The lowest</span> supported version is <b>1.1</b>. <a href = ""Update"">Update</a>
//  the application.'")); StringFunctionsClient.FormattedString(NStr("en='Mode: <img 
//  src=""EditInDialog""> <a style=""color: ModifiedAttributeValueColor; background-color: ModifiedAttributeValueBackground""
//  href=""e1cib/command/DataProcessor.Editor"">Editing</a>'"));
//  StringFunctionsClient.FormattedString(NStr("en='Current date <img src=""Calendar""><span style=""font:
//  ImportantLabelFont"">%1</span>'"), CurrentSessionDate());//
//
Function FormattedString(Val StringPattern, Val Parameter1 = Undefined, Val Parameter2 = Undefined,
	Val Parameter3 = Undefined, Val Parameter4 = Undefined, Val Parameter5 = Undefined) Export
	
	ClientRunParameters = StandardSubsystemsClient.ClientRunParameters();
	StyleItems = ClientRunParameters.StyleItems;
	
	Return StringFunctionsClientServer.GenerateFormattedString(StringPattern, StyleItems, Parameter1, Parameter2, Parameter3, Parameter4, Parameter5);
	
EndFunction

#EndRegion

