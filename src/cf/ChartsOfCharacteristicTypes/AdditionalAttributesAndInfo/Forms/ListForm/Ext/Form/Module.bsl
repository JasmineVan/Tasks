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
	
	CommonClientServer.SetDynamicListParameter(
		List,
		"CommonPropertiesGroupPresentation",
		NStr("ru = 'Общие (для нескольких наборов)'; en = 'Shared (for multiple sets)'; pl = 'Wspólne (dla kilku zestawów)';de = 'Allgemein (für mehrere Sätze)';ro = 'Comun (pentru mai multe seturi)';tr = 'Ortak (birkaç küme için)'; es_ES = 'Común (para varios conjuntos)'"),
		True);
	
	// Grouping properties to sets.
	DataGroup = List.SettingsComposer.Settings.Structure.Add(Type("DataCompositionGroup"));
	DataGroup.UserSettingID = "GroupPropertiesBySets";
	DataGroup.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	GroupFields = DataGroup.GroupFields;
	
	DataGroupItem = GroupFields.Items.Add(Type("DataCompositionGroupField"));
	DataGroupItem.Field = New DataCompositionField("PropertiesSetGroup");
	DataGroupItem.Use = True;
	
EndProcedure

#EndRegion
