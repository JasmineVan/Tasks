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
	
	SetConditionalAppearance();
	
	ReadOnly = True;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure EnableEditing(Command)
	
	ReadOnly = False;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	// Conditional appearance.
	AppearanceItem = List.SettingsComposer.Settings.ConditionalAppearance.Items.Add();
	AppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	DecorationTextItem = AppearanceItem.Appearance.Items.Find("Text");
	DecorationTextItem.Value = NStr("ru = 'Разрешенная пустая группа доступа'; en = 'Allowed blank access group'; pl = 'Dozwolone pusta grupa dostępu';de = 'Erlaubte leere Zugriffsgruppe';ro = 'Grupul gol de acces permis';tr = 'Izin verilen boş erişim grubu'; es_ES = 'Grupo de acceso permitido vacío'");
	DecorationTextItem.Use = True;
	
	FilterItem = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem.LeftValue  = New DataCompositionField("AccessGroup");
	FilterItem.ComparisonType   = DataCompositionComparisonType.Equal;
	FilterItem.RightValue = Catalogs.AccessGroups.EmptyRef();
	FilterItem.Use  = True;
	
	FieldItem = AppearanceItem.Fields.Items.Add();
	FieldItem.Field = New DataCompositionField("AccessGroup");
	FieldItem.Use = True;
	
EndProcedure

#EndRegion
