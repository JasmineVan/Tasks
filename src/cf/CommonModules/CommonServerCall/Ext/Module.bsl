///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

#Region InfobaseData

////////////////////////////////////////////////////////////////////////////////
// Common procedures and functions to manage infobase data.

// Checks whether there are references to the object in the infobase
// When called in a shared session, does not find references in separated areas.
//
// See Common.ReferencesToObjectFound 
//
// Parameters:
//  RefOrRefsArray - AnyRef, Array - an object or a list of objects.
//  SearchInInternalObjects - Boolean - if True, exceptions defined during configuration development 
//      are ignored while searching for references.
//      For more details on exceptions during reference search, see CommonOverridable.
//      OnAddReferenceSearchExceptions. 
//
// Returns:
//  Boolean - True if any references to the object are found.
//
Function RefsToObjectFound(Val RefOrRefArray, Val SearchInInternalObjects = False) Export
	
	Return Common.RefsToObjectFound(RefOrRefArray, SearchInInternalObjects);
	
EndFunction

// Checks posting status of the passed documents and returns the unposted documents.
// 
//
// See CommonUse.CheckDocumentsPosted 
//
// Parameters:
//  Documents - Array - documents to check.
//
// Returns:
//  Array - unposted documents.
//
Function CheckDocumentsPosting(Val Documents) Export
	
	Return Common.CheckDocumentsPosting(Documents);
	
EndFunction

// Attempts to post the documents.
//
// See Common.PostDocuments 
//
// Parameters:
//   Documents - Array - documents to post.
//
// Returns:
//   Array - array of structures with the following properties:
//      * Ref - DocumentRef - document that could not be posted.
//      * ErrorDescription - String         - the text of a posting error.
//
Function PostDocuments(Documents) Export
	
	Return Common.PostDocuments(Documents);
	
EndFunction 

#EndRegion

#Region SettingsStorage

////////////////////////////////////////////////////////////////////////////////
// Saving, reading, and deleting settings from storages.

// Saves a setting to the common settings storage as the Save method of 
// StandardSettingsStorageManager or SettingsStorageManager.<Storage name> object. Setting keys 
// exceeding 128 characters are supported by hashing the key part that exceeds 96 characters.
// 
// If the SaveUserData right is not granted, data save fails and no error is raised.
//
// See CommonUse.CommonSettingsStorageSave 
//
// Parameters:
//   ObjectKey - String - see the Syntax Assistant.
//   SettingsKey - String - see the Syntax Assistant.
//   Settings - Arbitrary - see the Syntax Assistant.
//   SettingsDescription - SettingsDescription - see the Syntax Assistant.
//   UserName - String - see the Syntax Assistant.
//   UpdateCachedValues - Boolean - the flag that indicates whether to execute the method.
//
Procedure CommonSettingsStorageSave(ObjectKey, SettingsKey, Settings,
			SettingsDetails = Undefined,
			Username = Undefined,
			UpdateCachedValues = False) Export
	
	Common.CommonSettingsStorageSave(
		ObjectKey,
		SettingsKey,
		Settings,
		SettingsDetails,
		Username);
		
EndProcedure

// Saves settings to the common settings storage as the Save method of 
// StandardSettingsStorageManager or SettingsStorageManager.<Storage name> object. Setting keys 
// exceeding 128 characters are supported by hashing the key part that exceeds 96 characters.
// 
// If the SaveUserData right is not granted, data save fails and no error is raised.
//
// See Common.CommonSettingsStorageSaveArray 
// 
// Parameters:
//   MultipleSettings - Array of the following values:
//     * Value - Structure - with the following properties:
//         * Object - String - see the ObjectKey parameter in the Syntax Assistant.
//         * Setting - String - see the SettingsKey parameter in the Syntax Assistant.
//         * Value - Arbitrary - see the Settings parameter in the Syntax Assistant.
//
//   UpdateCachedValues - Boolean - the flag that indicates whether to execute the method.
//
Procedure CommonSettingsStorageSaveArray(MultipleSettings, UpdateCachedValues = False) Export
	
	Common.CommonSettingsStorageSaveArray(MultipleSettings, UpdateCachedValues);
	
EndProcedure

// Loads a setting from the general settings storage as the Load method, 
// StandardSettingsStorageManager objects, or SettingsStorageManager.<Storage name>. The setting key 
// supports more than 128 characters by hashing the part that exceeds 96 characters.
// 
// If no settings are found, returns the default value.
// If the SaveUserData right is not granted, the default value is returned and no error is raised.
//
// References to database objects that do not exist are cleared from the return value:
// - The returned reference is replaced by the default value.
// - The references are deleted from the data of Array type.
// - Key is not changed for the data of Structure or Map types, and value is set to Undefined.
// - Recursive analysis of values in the data of Array, Structure, Map types is performed.
//
// See CommonUse.CommonSettingsStorageLoad 
//
// Parameters:
//   ObjectKey - String - see the Syntax Assistant.
//   SettingsKey - String - see the Syntax Assistant.
//   DefaultValue - Arbitrary - a value that is returned if no settings are found.
//                                             If not specified, returns Undefined.
//   SettingsDescription - SettingsDescription - see the Syntax Assistant.
//   UserName - String - see the Syntax Assistant.
//
// Returns:
//   Arbitrary - see the Syntax Assistant.
//
Function CommonSettingsStorageLoad(ObjectKey, SettingsKey, DefaultValue = Undefined,
			SettingsDetails = Undefined,
			Username = Undefined) Export
	
	Return Common.CommonSettingsStorageLoad(
		ObjectKey,
		SettingsKey,
		DefaultValue,
		SettingsDetails,
		Username);
		
EndFunction

// Removes a setting from the general settings storage as the Remove method, 
// StandardSettingsStorageManager objects, or SettingsStorageManager.<Storage name>. The setting key 
// supports more than 128 characters by hashing the part that exceeds 96 characters.
// 
// If the SaveUserData right is not granted, no data is deleted and no error is raised.
//
// See CommonUse.CommonSettingsStorageDelete 
//
// Parameters:
//   ObjectKey - String, Undefined - see the Syntax Assistant.
//   SettingsKey - String, Undefined - see the Syntax Assistant.
//   UserName - String, Undefined - see the Syntax Assistant.
//
Procedure CommonSettingsStorageDelete(ObjectKey, SettingsKey, Username) Export
	
	Common.CommonSettingsStorageDelete(ObjectKey, SettingsKey, Username);
	
EndProcedure

// Saves a setting to the system settings storage as the Save method of 
// StandardSettingsStorageManager object. Setting keys exceeding 128 characters are supported by 
// hashing the key part that exceeds 96 characters.
// If the SaveUserData right is not granted, data save fails and no error is raised.
//
// See CommonUse.SystemSettingsStorageSave 
//
// Parameters:
//   ObjectKey - String - see the Syntax Assistant.
//   SettingsKey - String - see the Syntax Assistant.
//   Settings - Arbitrary - see the Syntax Assistant.
//   SettingsDescription - SettingsDescription - see the Syntax Assistant.
//   UserName - String - see the Syntax Assistant.
//   UpdateCachedValues - Boolean - the flag that indicates whether to execute the method.
//
Procedure SystemSettingsStorageSave(ObjectKey, SettingsKey, Settings,
			SettingsDetails = Undefined,
			Username = Undefined,
			UpdateCachedValues = False) Export
	
	Common.SystemSettingsStorageSave(
		ObjectKey,
		SettingsKey,
		Settings,
		SettingsDetails,
		Username,
		UpdateCachedValues);
	
EndProcedure

// Loads a setting from the system settings storage as the Load method or the 
// StandardSettingsStorageManager object. The setting key supports more than 128 characters by 
// hashing the part that exceeds 96 characters.
// If no settings are found, returns the default value.
// If the SaveUserData right is not granted, the default value is returned and no error is raised.
//
// The return value clears references to a non-existent object in the database, namely:
// - The returned reference is replaced by the default value.
// - The references are deleted from the data of Array type.
// - Key is not changed for the data of Structure or Map types, and value is set to Undefined.
// - Recursive analysis of values in the data of Array, Structure, Map types is performed.
//
// See CommonUse.SystemSettingsStorageLoad 
//
// Parameters:
//   ObjectKey - String - see the Syntax Assistant.
//   SettingsKey - String - see the Syntax Assistant.
//   DefaultValue - Arbitrary - a value that is returned if no settings are found.
//                                             If not specified, returns Undefined.
//   SettingsDescription - SettingsDescription - see the Syntax Assistant.
//   UserName - String - see the Syntax Assistant.
//
// Returns:
//   Arbitrary - see the Syntax Assistant.
//
Function SystemSettingsStorageLoad(ObjectKey, SettingsKey, DefaultValue = Undefined, 
			SettingsDetails = Undefined,
			Username = Undefined) Export
	
	Return Common.SystemSettingsStorageLoad(
		ObjectKey,
		SettingsKey,
		DefaultValue,
		SettingsDetails,
		Username);
	
EndFunction

// Removes a setting from the system settings storage as the Remove method or the 
// StandardSettingsStorageManager object. The setting key supports more than 128 characters by 
// hashing the part that exceeds 96 characters.
// If the SaveUserData right is not granted, no data is deleted and no error is raised.
//
// See CommonUse.SystemSettingsStorageDelete 
//
// Parameters:
//   ObjectKey - String, Undefined - see the Syntax Assistant.
//   SettingsKey - String, Undefined - see the Syntax Assistant.
//   UserName - String, Undefined - see the Syntax Assistant.
//
Procedure SystemSettingsStorageDelete(ObjectKey, SettingsKey, Username) Export
	
	Common.SystemSettingsStorageDelete(ObjectKey, SettingsKey, Username);
	
EndProcedure

// Saves a setting to the form data settings storage as the Save method of 
// StandardSettingsStorageManager or SettingsStorageManager.<Storage name> object. Setting keys 
// exceeding 128 characters are supported by hashing the key part that exceeds 96 characters.
// 
// If the SaveUserData right is not granted, data save fails and no error is raised.
//
// See CommonUse.FormDataSettingsStorageSave 
//
// Parameters:
//   ObjectKey - String - see the Syntax Assistant.
//   SettingsKey - String - see the Syntax Assistant.
//   Settings - Arbitrary - see the Syntax Assistant.
//   SettingsDescription - SettingsDescription - see the Syntax Assistant.
//   UserName - String - see the Syntax Assistant.
//   UpdateCachedValues - Boolean - the flag that indicates whether to execute the method.
//
Procedure FormDataSettingsStorageSave(ObjectKey, SettingsKey, Settings,
			SettingsDetails = Undefined,
			Username = Undefined,
			UpdateCachedValues = False) Export
	
	Common.FormDataSettingsStorageSave(
		ObjectKey,
		SettingsKey,
		Settings,
		SettingsDetails,
		Username,
		UpdateCachedValues);
	
EndProcedure

// Retrieves the setting from the form data settings storage using the Load method for 
// StandardSettingsStorageManager or SettingsStorageManager.<Storage name> objects. Setting keys 
// exceeding 128 characters are supported by hashing the key part that exceeds 96 characters.
// 
// If no settings are found, returns the default value.
// If the SaveUserData right is not granted, the default value is returned and no error is raised.
//
// References to database objects that do not exist are cleared from the return value:
// - The returned reference is replaced by the default value.
// - The references are deleted from the data of Array type.
// - Key is not changed for the data of Structure or Map types, and value is set to Undefined.
// - Recursive analysis of values in the data of Array, Structure, Map types is performed.
//
// See CommonUse.FormDataSettingsStorageLoad 
//
// Parameters:
//   ObjectKey - String - see the Syntax Assistant.
//   SettingsKey - String - see the Syntax Assistant.
//   DefaultValue - Arbitrary - a value that is returned if no settings are found.
//                                             If not specified, returns Undefined.
//   SettingsDescription - SettingsDescription - see the Syntax Assistant.
//   UserName - String - see the Syntax Assistant.
//
// Returns:
//   Arbitrary - see the Syntax Assistant.
//
Function FormDataSettingsStorageLoad(ObjectKey, SettingsKey, DefaultValue = Undefined,
			SettingsDetails = Undefined,
			Username = Undefined) Export
	
	Return Common.FormDataSettingsStorageLoad(
		ObjectKey,
		SettingsKey,
		DefaultValue,
		SettingsDetails,
		Username);
	
EndFunction

// Deletes the setting from the form data settings storage using the Delete method for 
// StandardSettingsStorageManager or SettingsStorageManager.<Storage name> objects. Setting keys 
// exceeding 128 characters are supported by hashing the key part that exceeds 96 characters.
// 
// If the SaveUserData right is not granted, no data is deleted and no error is raised.
//
//  See Common.FormDataSettingsStorageDelete 
//
// Parameters:
//   ObjectKey - String, Undefined - see the Syntax Assistant.
//   SettingsKey - String, Undefined - see the Syntax Assistant.
//   UserName - String, Undefined - see the Syntax Assistant.
//
Procedure FormDataSettingsStorageDelete(ObjectKey, SettingsKey, Username) Export
	
	Common.FormDataSettingsStorageDelete(ObjectKey, SettingsKey, Username);
	
EndProcedure

#EndRegion

#Region ObsoleteProceduresAndFunctions

// Obsolete. Please use SaaS.SetSessionSeparation.
Procedure SetSessionSeparation(Val Usage, Val DataArea = Undefined) Export
	
	If Common.SubsystemExists("StandardSubsystems.SaaS") Then
		ModuleSaaS = Common.CommonModule("SaaS");
		ModuleSaaS.SetSessionSeparation(Usage, DataArea);
	EndIf;
	
EndProcedure

// Obsolete. Use the CommonSettingsStorageSave function instead.
Procedure CommonSettingsStorageSaveArrayAndUpdateCachedValues(StructuresArray) Export
	
	Common.CommonSettingsStorageSaveArray(StructuresArray, True);
	
EndProcedure

// Obsolete. Use the CommonSettingsStorageSave function instead.
Procedure CommonSettingsStorageSaveAndUpdateCachedValues(ObjectKey,
			SettingsKey, Settings) Export
	
	Common.CommonSettingsStorageSave(ObjectKey, SettingsKey, Settings,,, True);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region Styles

////////////////////////////////////////////////////////////////////////////////
// Functions to manage style colors in the client code.

// (See CommonClient.StyleColor)
Function StyleColor(StyleColorName) Export
	
	Return StyleColors[StyleColorName];
	
EndFunction

// (See CommonClient.StyleFont)
Function StyleFont(StyleFontName) Export
	
	Return StyleFonts[StyleFontName];
	
EndFunction

#EndRegion

#EndRegion
