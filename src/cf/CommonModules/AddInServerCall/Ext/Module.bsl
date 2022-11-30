///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Information on add-in by ID and version.
//
// Parameters:
//   ID - String - the add-in ID.
//  Version - String - (optional) component version.
//
// Returns:
//  Structure - component information
//      * Exists - Boolean - shows whether the component is absent.
//      * EditingAvailable - Boolean - indicates that the area administrator can change the add-in.
//      * ErrorDescription - String - a brief error description.
//      *  ID - String - the add-in ID.
//      * Version - String - component version.
//      * Description - String - component description and short info.
//
// Example:
//
//  Result = AddInServerCall.InformationOnAddIn("InputDevice", "8.1.7.10");
//
//  If Result.Exists Then
//      ID = Result.ID;
//      Version = Result.Version;
//      Description = Result.Description;
//  Else
//      CommonClientServer.MessageToUser(Result.ErrorDescription);
//  EndIf.
//
Function AddInInformation(ID, Version = Undefined) Export
	
	Result = ResultInformationOnComponent();
	Result.ID = ID;
	
	Information = AddInsInternal.SavedAddInInformation(ID, Version);
	
	If Information.State = "NotFound" Then
		Result.ErrorDescription = NStr("ru = 'Внешняя компонента не найдена'; en = 'Add-in not found'; pl = 'Add-in not found';de = 'Add-in not found';ro = 'Add-in not found';tr = 'Add-in not found'; es_ES = 'Add-in not found'");
		Return Result;
	EndIf;
	
	If Information.State = "DisabledByAdministrator" Then
		Result.ErrorDescription = NStr("ru = 'Внешняя компонента отключена'; en = 'Add-in is disabled'; pl = 'Add-in is disabled';de = 'Add-in is disabled';ro = 'Add-in is disabled';tr = 'Add-in is disabled'; es_ES = 'Add-in is disabled'");
		Return Result;
	EndIf;
	
	Result.Exist = True;
	Result.EditingAvailable = True;
	
	If Information.State = "FoundInSharedStorage" Then
		Result.EditingAvailable = False;
	EndIf;
	
	Result.Version = Information.Attributes.Version;
	Result.Description = Information.Attributes.Description;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Private

Function ResultInformationOnComponent()
	
	Result = New Structure;
	Result.Insert("Exist", False);
	Result.Insert("EditingAvailable", False);
	Result.Insert("ID", "");
	Result.Insert("Version", "");
	Result.Insert("Description", "");
	Result.Insert("ErrorDescription", "");
	
	Return Result;
	
EndFunction

#EndRegion