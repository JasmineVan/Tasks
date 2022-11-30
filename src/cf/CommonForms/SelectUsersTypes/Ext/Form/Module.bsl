///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Title = Parameters.Title;
	
	PresentationsArray = ?(Parameters.IsFilter,
		StringFunctionsClientServer.SplitStringIntoSubstringsArray(Parameters.Purpose, ", "),
		Undefined);
	
	If Parameters.SelectUsers Then
		AddTypeRow(Catalogs.Users.EmptyRef(), Type("CatalogRef.Users"), PresentationsArray);
	EndIf;
	
	If ExternalUsers.UseExternalUsers() Then
		
		BlankRefs = UsersInternalCached.BlankRefsOfAuthorizationObjectTypes();
		For Each EmptyRef In BlankRefs Do
			AddTypeRow(EmptyRef, TypeOf(EmptyRef), PresentationsArray);
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Select(Command)
	
	Close(Purpose);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure AddTypeRow(Value, Type, PresentationsArray)
	
	Presentation = Metadata.FindByType(Type).Synonym;
	
	If Parameters.IsFilter Then
		Checkmark = PresentationsArray.Find(Presentation) <> Undefined;
	Else
		FilterParameters = New Structure;
		FilterParameters.Insert("UsersType", Value);
		FoundRows = Parameters.Purpose.FindRows(FilterParameters);
		Checkmark = FoundRows.Count() = 1;
	EndIf;
	
	Purpose.Add(Value, Presentation, Checkmark);
	
EndProcedure

#EndRegion