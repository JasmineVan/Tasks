///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// See AddInsService.InformationAboutSavedComponent 
//
Function SavedAddInInformation(ID, Version = Undefined) Export
	
	Return AddInsInternal.SavedAddInInformation(ID, Version);
	
EndFunction

// Add-in file name to save to the file.
//
Function ComponentFileName(Ref) Export 
	
	Return Common.ObjectAttributeValue(Ref, "FileName");
	
EndFunction

#EndRegion

