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
	
	DataProcessorName = "ImportBankClassifier";
	HasDataImportSource = Metadata.DataProcessors.Find(DataProcessorName) <> Undefined;
	
	CanUpdateClassifier =
		Not Common.DataSeparationEnabled() // Automatic update in SaaS mode.
		AND Not Common.IsSubordinateDIBNode()   // The distributed infobase node is updated automatically.
		AND AccessRight("Update", Metadata.Catalogs.BankClassifier); //  A user with sufficient rights.

	Items.FormImportClassifier.Visible = CanUpdateClassifier AND HasDataImportSource;
	
	If Not Users.IsFullUser() Or Not CanUpdateClassifier Then
		ReadOnly = True;
	EndIf;
	
	SwitchInactiveBanksVisibility(False);
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure ImportClassifier(Command)
	BankManagerClient.OpenClassifierImportForm(ThisObject, True);
EndProcedure

&AtClient
Procedure ShowInactiveBanks(Command)
	SwitchInactiveBanksVisibility(Not Items.FormShowInactiveBanks.Check);
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SwitchInactiveBanksVisibility(Visibility)
	
	Items.FormShowInactiveBanks.Check = Visibility;
	
	CommonClientServer.SetDynamicListFilterItem(
			List, "OutOfBusiness", False, , , Not Visibility);
			
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	List.ConditionalAppearance.Items.Clear();
	Item = List.ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OutOfBusiness");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
EndProcedure

#EndRegion
