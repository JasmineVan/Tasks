///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Converts entered English letters to the Russian layout upon selecting an address
//
Procedure ConvertAddressInput(Text) Export
	RussianKeys = "ЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮЁ";
	EnglishKeys = "QWERTYUIOP[]ASDFGHJKL;'ZXCVBNM,.`";
	Text = Upper(Text);
	For Position = 0 To StrLen(Text) Do
		Char = Mid(Text, Position, 1);
		CharPosition = StrFind(EnglishKeys, Char);
		If CharPosition > 0 Then
			Text = StrReplace(Text, Char, Mid(RussianKeys, CharPosition, 1));
		EndIf;
	EndDo;
	
EndProcedure

Procedure ShowClassifier(OpeningParameters, FormOwner, WindowOpenMode = Undefined) Export
	
	OpenForm("Catalog.WorldCountries.Form.Classifier", OpeningParameters, FormOwner,,,,, WindowOpenMode);
	
EndProcedure

#EndRegion



