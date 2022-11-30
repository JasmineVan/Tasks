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
	
	Items.BankOperationsDiscontinuedPages.Visible = Object.OutOfBusiness Or Users.IsFullUser();
	Items.BankOperationsDiscontinuedPages.CurrentPage = ?(Users.IsFullUser(),
		Items.BankOperationsDiscontinuedCheckBoxPage, Items.BankOperationsDiscontinuedLabelPage);
		
	If Object.OutOfBusiness Then
		WindowOptionsKey = "OutOfBusiness";
		Items.BankOperationsDiscontinuedLabel.Title = BankManager.InvalidBankNote(Object.Ref);
	EndIf;
	
	If Common.IsMobileClient() Then
		Items.HeaderGroup.ItemsAndTitlesAlign = ItemsAndTitlesAlignVariant.ItemsRightTitlesLeft;
		Items.DomesticPaymentsDetailsGroup.ItemsAndTitlesAlign = ItemsAndTitlesAlignVariant.ItemsRightTitlesLeft;
		Items.InternationalPaymentsDetailsGroup.ItemsAndTitlesAlign = ItemsAndTitlesAlignVariant.ItemsRightTitlesLeft;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	If Common.SubsystemExists("SaaSTechnology.SaaS.DataExchangeSaaS") Then
		
		ModuleStandaloneMode = Common.CommonModule("StandaloneMode");
		ModuleStandaloneMode.ObjectOnReadAtServer(CurrentObject, ThisObject.ReadOnly);
		
	EndIf;
	
EndProcedure

#EndRegion
