///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// The function gets the style color by a style item name.
//
// Parameters:
//   StyleColorName - String - Style item name.
//
// Returns:
//   Color.
//
Function StyleColor(StyleColorName) Export
	
	Return CommonServerCall.StyleColor(StyleColorName);
	
EndFunction

// The function gets the style font by a style item name.
//
// Parameters:
//   StyleFontName - String -  the style font name.
//
// Returns:
//   Font.
//
Function StyleFont(StyleFontName) Export
	
	Return CommonServerCall.StyleFont(StyleFontName);
	
EndFunction

#EndRegion
