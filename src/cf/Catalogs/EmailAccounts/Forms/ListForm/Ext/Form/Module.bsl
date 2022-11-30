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
	
	Items.ShowPersonalUsersAccounts.Visible = Users.IsFullUser();
	
	SwitchPersonalAccountsVisibility(List,
		ShowPersonalUsersAccounts,
		Users.CurrentUser());
	
	SwitchInvalidAccountsVisibility(List, ShowInvalidAccounts);
	Items.AccountOwner.Visible = ShowPersonalUsersAccounts;
	Items.ShowInvalidAccounts.Enabled = ShowPersonalUsersAccounts;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ShowPersonalUsersAccountsOnChange(Item)
	
	SwitchPersonalAccountsVisibility(List,
		ShowPersonalUsersAccounts,
		UsersClient.CurrentUser());
	
	Items.AccountOwner.Visible = ShowPersonalUsersAccounts;
	Items.ShowInvalidAccounts.Enabled = ShowPersonalUsersAccounts;
	
	ShowInvalidAccounts = ShowInvalidAccounts AND ShowPersonalUsersAccounts;
	SwitchInvalidAccountsVisibility(List, ShowInvalidAccounts);
	
EndProcedure

&AtClient
Procedure ShowInvalidItemsOnChange(Item)
	SwitchInvalidAccountsVisibility(List, ShowInvalidAccounts);
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure SwitchPersonalAccountsVisibility(List, ShowPersonalUsersAccounts, CurrentUser)
	UsersList = New Array;
	UsersList.Add(PredefinedValue("Catalog.Users.EmptyRef"));
	UsersList.Add(CurrentUser);
	CommonClientServer.SetDynamicListFilterItem(
		List, "AccountOwner", UsersList, DataCompositionComparisonType.InList, ,
			Not ShowPersonalUsersAccounts);
EndProcedure

&AtClientAtServerNoContext
Procedure SwitchInvalidAccountsVisibility(List, ShowInvalidItems)
	CommonClientServer.SetDynamicListFilterItem(
		List, "OwnerInvalid", False, DataCompositionComparisonType.Equal, ,
			Not ShowInvalidItems);
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	List.ConditionalAppearance.Items.Clear();
	Item = List.ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OwnerInvalid");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
EndProcedure

#EndRegion