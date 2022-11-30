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
	
	Items.ShowPersonalUsersAccounts.Visible =
		Users.IsFullUser();
	
	SwitchPersonalAccountsVisibility(List,
		ShowPersonalUsersAccounts,
		Users.CurrentUser());
	
	Items.AccountOwner.Visible = ShowPersonalUsersAccounts;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ShowPersonalUsersAccountsOnChange(Item)
	
	SwitchPersonalAccountsVisibility(List,
		ShowPersonalUsersAccounts,
		UsersClient.CurrentUser());
	
	Items.AccountOwner.Visible = ShowPersonalUsersAccounts;
	
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
		
#EndRegion