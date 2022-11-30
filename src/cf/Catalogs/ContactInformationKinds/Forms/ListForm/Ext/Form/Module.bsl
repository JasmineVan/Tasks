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
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	List.Parameters.SetParameterValue("IsMainLanguage", CurrentLanguage() = Metadata.DefaultLanguage);
	List.Parameters.SetParameterValue("LanguageCode", CurrentLanguage().LanguageCode);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Clone, Parent, Folder)
	
	// Check whether the group is copied.
	If Clone AND Folder Then
		Cancel = True;
		
		ShowMessageBox(, NStr("ru='Добавление новых групп в справочнике запрещено.'; en = 'Adding new groups to the catalog is prohibited.'; pl = 'Dodawanie nowych grup do katalogu jest zabronione.';de = 'Das Hinzufügen von neuen Gruppen in den Katalog ist verboten.';ro = 'Adăugarea de noi grupuri în catalog este interzisă.';tr = 'Kataloğa yeni grupların eklenmesi yasaktır.'; es_ES = 'Está prohibido añadir nuevos grupos al catálogo.'"));
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.List);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result)
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.List, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	Item = List.ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Used");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	Item.Appearance.SetParameterValue("Visible", False);
	
EndProcedure

#EndRegion