///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Returns a table of prefix generating attributes specified in the overridable module.
//
Function PrefixGeneratingAttributes() Export
	
	Objects = New ValueTable;
	Objects.Columns.Add("Object");
	Objects.Columns.Add("Attribute");
	
	ObjectsPrefixesOverridable.GetPrefixGeneratingAttributes(Objects);
	
	ObjectsAttributes = New Map;
	
	For each Row In Objects Do
		ObjectsAttributes.Insert(Row.Object.FullName(), Row.Attribute);
	EndDo;
	
	Return New FixedMap(ObjectsAttributes);
	
EndFunction

#EndRegion
