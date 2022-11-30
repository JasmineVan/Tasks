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
	
	If Parameters.ChoiceMode Then
		StandardSubsystemsServer.SetFormAssignmentKey(ThisObject, "SelectionPick");
	EndIf;
	
	If Parameters.ChoiceMode Then
		WindowOpeningMode = FormWindowOpeningMode.LockOwnerWindow;
		
		// Hiding the Administrator profile.
		CommonClientServer.SetDynamicListFilterItem(
			List, "Ref", Catalogs.AccessGroupProfiles.Administrator,
			DataCompositionComparisonType.NotEqual, , True);
		
		Items.List.ChoiceFoldersAndItems = Parameters.ChoiceFoldersAndItems;
		
		AutoTitle = False;
		If Parameters.CloseOnChoice = False Then
			// Pick mode.
			Items.List.MultipleChoice = True;
			Items.List.SelectionMode = TableSelectionMode.MultiRow;
			
			Title = NStr("ru = 'Подбор профилей групп доступа'; en = 'Pick access group profiles'; pl = 'Wybór profili grupy dostępu';de = 'Wählen Sie Zugriffsgruppenprofile aus';ro = 'Selectarea profilelor grupurilor de acces';tr = 'Erişim grubu profillerini seç.'; es_ES = 'Seleccionar los perfiles del grupo de acceso'");
		Else
			Title = NStr("ru = 'Выбор профиля групп доступа'; en = 'Select access group profile'; pl = 'Wybierz profil grupy dostępu';de = 'Wählen Sie ein Zugriffsgruppenprofil aus';ro = 'Alegerea profilului grupurilor de acces';tr = 'Erişim grubu profilini seç'; es_ES = 'Seleccionar un perfil del grupo de acceso'");
		EndIf;
	Else
		Items.List.ChoiceMode = False;
	EndIf;
	
	If Parameters.Property("ProfilesWithRolesMarkedForDeletion") Then
		ShowProfiles = "OutdatedProfiles";
	Else
		ShowProfiles = "AllProfiles";
	EndIf;
	
	If Not Parameters.ChoiceMode Then
		SetFilter();
	Else
		Items.ShowProfiles.Visible = False;
	EndIf;
	
	If Common.IsStandaloneWorkplace() Then
		ReadOnly = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ShowProfilesOnChange(Item)
	
	SetFilter();
	
EndProcedure

&AtClient
Procedure UsersKindStartChoice(Item, ChoiceData, StandardProcessing)
	
	NotifyDescription = New NotifyDescription("AfterAssignmentChoice", ThisObject);
	
	UsersInternalClient.SelectPurpose(ThisObject,
		NStr("ru = 'Выбор назначения профилей'; en = 'Select profile assignment'; pl = 'Wybór przydziału profili';de = 'Auswahl der Profilzuordnung';ro = 'Alegerea destinației profilelor';tr = 'Profil amaçlarının seçimi'; es_ES = 'Selección de asignación de perfiles'"), True, True, NotifyDescription);
	
EndProcedure

&AtClient
Procedure UsersKindClear(Item, StandardProcessing)
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "Ref.Purpose.UsersType", , , , False);
		
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnChange(Item)
	
	ListOnChangeAtServer();
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Update(Command)
	
	UpdateAtServer();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure UpdateAtServer()
	
	SetFilter();
	
	Items.List.Refresh();
	
EndProcedure

&AtServer
Procedure SetFilter()
	
	If ShowProfiles = "OutdatedProfiles" Then
		CommonClientServer.SetDynamicListFilterItem(List,
			"Ref",
			Catalogs.AccessGroupProfiles.IncompatibleAccessGroupsProfiles(),
			DataCompositionComparisonType.InList, , True);
	Else
		CommonClientServer.SetDynamicListFilterItem(List,
			"Ref", , , , False);
	EndIf;
	
	If ShowProfiles = "SuppliedProfiles" Then
		CommonClientServer.SetDynamicListFilterItem(List,
			"Ref.SuppliedDataID",
			CommonClientServer.BlankUUID(),
			DataCompositionComparisonType.NotEqual, , True);
		
	ElsIf ShowProfiles = "UnsuppliedProfiles" Then
		CommonClientServer.SetDynamicListFilterItem(List,
			"Ref.SuppliedDataID",
			CommonClientServer.BlankUUID(),
			DataCompositionComparisonType.Equal, , True);
	Else
		CommonClientServer.SetDynamicListFilterItem(List,
			"Ref.SuppliedDataID", , , , False);
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterAssignmentChoice(TypesArray, AdditionalParameters) Export
	
	If TypesArray.Count() <> 0 Then
		CommonClientServer.SetDynamicListFilterItem(List,
			"Ref.Purpose.UsersType",
			TypesArray,
			DataCompositionComparisonType.InList, , True);
	Else
		CommonClientServer.SetDynamicListFilterItem(
			List, "Ref.Purpose.UsersType", , , , False);
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure ListOnChangeAtServer()
	
	AccessManagementInternal.StartAccessUpdate();
	
EndProcedure

#EndRegion
