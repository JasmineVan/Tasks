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
	
	SetAllExternalUsersGroupOrder(List);
	
	If Parameters.ChoiceMode Then
		StandardSubsystemsServer.SetFormAssignmentKey(ThisObject, "SelectionPick");
		WindowOpeningMode = FormWindowOpeningMode.LockOwnerWindow;
		
		// Excluding "All external users" group from the list of available parents.
		CommonClientServer.SetDynamicListFilterItem(
			List, "Ref", Catalogs.ExternalUsersGroups.AllExternalUsers,
			DataCompositionComparisonType.NotEqual, , Parameters.Property("SelectParent"));
		
		If Parameters.CloseOnChoice = False Then
			// Pick mode.
			Title = NStr("ru = 'Подбор групп внешних пользователей'; en = 'Select external user groups'; pl = 'Dobór grup użytkowników zewnętrznych';de = 'Wählen Sie externe Benutzergruppen';ro = 'Selectați grupuri de utilizatori externe';tr = 'Harici kullanıcı grupları seçin'; es_ES = 'Seleccionar los grupos de usuarios externos'");
			Items.List.MultipleChoice = True;
			Items.List.SelectionMode = TableSelectionMode.MultiRow;
		Else
			Title = NStr("ru = 'Выбор группы внешних пользователей'; en = 'Select external user groups'; pl = 'Wybór grupy użytkowników zewnętrznych';de = 'Wählen Sie eine externe Benutzergruppe';ro = 'Selectați un grup de utilizatori extern';tr = 'Harici kullanıcı grubu seçin'; es_ES = 'Seleccionar un grupo de usuarios externos'");
		EndIf;
	Else
		Items.List.ChoiceMode = False;
	EndIf;
	
	If Common.IsStandaloneWorkplace() Then
		ReadOnly = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnChange(Item)
	
	ListOnChangeAtServer();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetAllExternalUsersGroupOrder(List)
	
	Var Order;
	
	// Order.
	Order = List.SettingsComposer.Settings.Order;
	Order.UserSettingID = "DefaultOrder";
	
	Order.Items.Clear();
	
	OrderItem = Order.Items.Add(Type("DataCompositionOrderItem"));
	OrderItem.Field = New DataCompositionField("Predefined");
	OrderItem.OrderType = DataCompositionSortDirection.Desc;
	OrderItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	OrderItem.Use = True;
	
	OrderItem = Order.Items.Add(Type("DataCompositionOrderItem"));
	OrderItem.Field = New DataCompositionField("Description");
	OrderItem.OrderType = DataCompositionSortDirection.Asc;
	OrderItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	OrderItem.Use = True;
	
EndProcedure

&AtServerNoContext
Procedure ListOnChangeAtServer()
	
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessControlInternal = Common.CommonModule("AccessManagementInternal");
		ModuleAccessControlInternal.StartAccessUpdate();
	EndIf;
	
EndProcedure

#EndRegion
