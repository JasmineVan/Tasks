///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

// The following parameters are expected:
//
//     MasterFormID      - UUID - an ID of the form, through the storage of which exchange is 
//                                                                 performed.
//     CompositionSchemaAddress            - String - an address of the temporary storage of the 
//                                                composition schema with the settings being edited.
//     FilterComposerSettingsAddress - String - an address of the temporary storage with editable composer settings.
//     FilterAreaPresentation      - String - a presentation for title generation.
//
// Returns the selection result:
//
//     Undefined - an editing cancellation.
//     String       - an address of the temporary storage of new composer settings.
//

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	MasterFormID = Parameters.MasterFormID;
	
	PrefilterComposer = New DataCompositionSettingsComposer;
	PrefilterComposer.Initialize( 
		New DataCompositionAvailableSettingsSource(Parameters.CompositionSchemaAddress) );
		
	FilterComposerSettingsAddress = Parameters.FilterComposerSettingsAddress;
	PrefilterComposer.LoadSettings(GetFromTempStorage(FilterComposerSettingsAddress));
	DeleteFromTempStorage(FilterComposerSettingsAddress);
	
	Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Правила отбора ""%1""'; en = 'Filter rule: %1'; pl = 'Reguły filtrów wyboru ""%1""';de = 'Filterregeln ""%1""';ro = 'Regulile de filtrare ""%1""';tr = '""%1"" kurallarını filtrele'; es_ES = 'Reglas del filtro ""%1""'"), Parameters.FilterAreaPresentation);
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Select(Command)
	
	If Modified Then
		NotifyChoice(FilterComposerSettingsAddress());
	Else
		Close();
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function FilterComposerSettingsAddress()
	Return PutToTempStorage(PrefilterComposer.Settings, MasterFormID)
EndFunction

#EndRegion

