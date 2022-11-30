///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Describes transliteration rules for a national alphabet into Latin characters.
//
// Parameters:
//  Rules- Map - a key as a national alphabet letter, a value as a Latin alphabet letter.
//
Procedure OnFillTransliterationRules(Rules) Export
	
	// Localization start
	
	// ACC:547-disable
	// ACC:488-disable
	
	// The following code fragment performs a conditional call of the OnFillTransliterationRules 
	// procedure but only if the StringFunctionsClientServerRussia module exists.
	
	#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
		
		If Metadata.CommonModules.Find("StringFunctionsClientServerRussia") <> Undefined Then 
			ModuleStringFunctionsClientServerRussia = Common.CommonModule("StringFunctionsClientServerRussia");
			ModuleStringFunctionsClientServerRussia.OnFillTransliterationRules(Rules);
		EndIf;
	#Else
		ModuleStringFunctionsClientServerRussia = Eval("StringFunctionsClientServerRussia");
		If TypeOf(ModuleStringFunctionsClientServerRussia) = Type("CommonModule") Then
			ModuleStringFunctionsClientServerRussia.OnFillTransliterationRules(Rules);
		EndIf;
	#EndIf
	// ACC:488-enable
	// ACC:547-enable
	
	// Localization end
	
EndProcedure

#EndRegion