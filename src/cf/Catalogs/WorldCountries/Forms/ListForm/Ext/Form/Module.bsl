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
	
	// Initializing internal flags.
	CanAddToCatalog = ContactsManagerInternal.HasRightToAdd();
	
	If Metadata.CommonModules.Find("AddressManager") = Undefined Then
		ClassifierDataAvailable = False;
	ElsIf Parameters.AllowClassifierData = Undefined Then
		ClassifierDataAvailable = True;
	Else
		BooleanType = New TypeDescription("Boolean");
		ClassifierDataAvailable = BooleanType.AdjustValue(Parameters.AllowClassifierData);
	EndIf;
	
	OnlyClassifierData = Parameters.OnlyClassifierData;
	Parameters.Property("ChoiceMode", ChoiceMode);
	
	// Allowing items
	Items.List.ChoiceMode = ChoiceMode;
	CommonClientServer.SetFormItemProperty(Items, "ListSelect", "DefaultButton", ChoiceMode);
	Items.Create.Visible  = CanAddToCatalog;
	
	If Not ClassifierDataAvailable Then
		// Showing catalog items only.
		Items.ListClassifier.Visible = False;
		// Hiding classifier buttons.
		Items.ListSelectFromClassifier.Visible = False;
		Items.ListClassifier.Visible           = False;
		If CanAddToCatalog Then
			Items.ListCreate.OnlyInAllActions     = False;
			Items.ListCreate.DefaultButton         = Not ChoiceMode;
			Items.ListCreate.Title =               "";
		EndIf;
		
		Return;
	EndIf;
	
	If ChoiceMode Then
		If OnlyClassifierData Then
			If CanAddToCatalog Then
				// Selecting only countries listed in the classifier.
				OpenClassifierForm = True
				
			Else
				// Showing only items present both in the catalog and in the classifier.
				SetCatalogAndClassifierIntersectionFilter();
				// Hiding classifier buttons.
				Items.ListSelectFromClassifier.Visible = False;
				Items.ListClassifier.Visible           = False;
			EndIf;
			
		Else
			If Not CanAddToCatalog Then
				// Hiding classifier buttons.
				Items.ListSelectFromClassifier.Visible = False;
				Items.ListClassifier.Visible           = False;
			EndIf;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If OpenClassifierForm Then
		// Selecting only countries listed in the classifier; opening classifier form for selection.
		OpeningParameters = New Structure;
		OpeningParameters.Insert("ChoiceMode",        True);
		OpeningParameters.Insert("CloseOnChoice", CloseOnChoice);
		OpeningParameters.Insert("CurrentRow",      Items.List.CurrentRow);
		OpeningParameters.Insert("WindowOpeningMode",  WindowOpeningMode);
		OpeningParameters.Insert("CurrentRow",      Items.List.CurrentRow);
		
		ShowClassifier(OpeningParameters, FormOwner);
		Cancel = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If EventName="Catalog.WorldCountries.Update" Then
		RefreshCountriesListDisplay();
	EndIf;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ChoiceProcessingList(Item, ValueSelected, StandardProcessing)
	If ChoiceMode Then
		// Selecting from classifier.
		NotifyChoice(ValueSelected);
	EndIf;
EndProcedure

&AtClient
Procedure NewObjectWriteProcessingList(Item, Source, StandardProcessing)
	RefreshCountriesListDisplay();
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure OpenClassifier(Command)
	// Opening for viewing
	OpeningParameters = New Structure;
	OpeningParameters.Insert("CurrentRow", Items.List.CurrentRow);
	
	ShowClassifier(OpeningParameters, Items.List);
	
EndProcedure

&AtClient
Procedure SelectFromClassifier(Command)
	
	// Opening for selection
	OpeningParameters = New Structure;
	OpeningParameters.Insert("ChoiceMode", True);
	OpeningParameters.Insert("CloseOnChoice", CloseOnChoice);
	OpeningParameters.Insert("CurrentRow", Items.List.CurrentRow);
	OpeningParameters.Insert("WindowOpeningMode", WindowOpeningMode);
	OpeningParameters.Insert("CurrentRow", Items.List.CurrentRow);
	
	ShowClassifier(OpeningParameters, Items.List, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ShowClassifier(OpeningParameters, FormOwner, WindowOpenMode = Undefined);
	
	If Not ClassifierDataAvailable Then
		Return;
	EndIf;

	ModuleAddressManagerClient = CommonClient.CommonModule("AddressManagerClient");
	ModuleAddressManagerClient.ShowClassifier( OpeningParameters, FormOwner, WindowOpenMode);
	
EndProcedure

&AtClient
Procedure RefreshCountriesListDisplay()
	
	If RefFilterItemID<>Undefined Then
		// An additional filter is set and it is to be updated.
		SetCatalogAndClassifierIntersectionFilter();
	EndIf;
	
	Items.List.Refresh();
EndProcedure

&AtServer
Procedure SetCatalogAndClassifierIntersectionFilter()
	ListFilter = List.SettingsComposer.FixedSettings.Filter;
	
	If RefFilterItemID=Undefined Then
		FilterItem = ListFilter.Items.Add(Type("DataCompositionFilterItem"));
		
		FilterItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
		FilterItem.LeftValue    = New DataCompositionField("Ref");
		FilterItem.ComparisonType     = DataCompositionComparisonType.InList;
		FilterItem.Use    = True;
		
		RefFilterItemID = ListFilter.GetIDByObject(FilterItem);
	Else
		FilterItem = ListFilter.GetObjectByID(RefFilterItemID);
	EndIf;
	
	Query = New Query("
		|SELECT
		|	Code, Description
		|INTO
		|	Classifier
		|FROM
		|	&Classifier AS Classifier
		|INDEX BY
		|	Code, Description
		|;////////////////////////////////////////////////////////////
		|SELECT 
		|	Ref
		|FROM
		|	Catalog.WorldCountries AS WorldCountries
		|INNER JOIN
		|	Classifier AS Classifier
		|ON
		|	WorldCountries.Code = Classifier.Code
		|	AND WorldCountries.Description = Classifier.Description
		|");
	
	ModuleAddressManager = Common.CommonModule("AddressManager");
	Query.SetParameter("Classifier", ModuleAddressManager.ClassifierTable());
	FilterItem.RightValue = Query.Execute().Unload().UnloadColumn("Ref");
EndProcedure

#EndRegion
