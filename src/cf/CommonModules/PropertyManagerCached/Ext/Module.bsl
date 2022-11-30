///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// For internal use only.
//
Function PredefinedPropertiesSets() Export
	
	Return Catalogs.AdditionalAttributesAndInfoSets.PredefinedPropertiesSets();
	
EndFunction

// For internal use only.
//
Function PropertiesSetsDescriptions() Export
	
	Return PropertyManagerInternal.PropertiesSetsDescriptions();
	
EndFunction

#EndRegion