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
	If Parameters.Property("ReportFormOpeningParameters", ReportFormOpeningParameters) Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	Available = ?(Object.AvailableToAuthorOnly, "1", "2");
	
	FullRightsToOptions = ReportsOptions.FullRightsToOptions();
	RightToThisOption = FullRightsToOptions Or Object.Author = Users.AuthorizedUser();
	If Not RightToThisOption Then
		ReadOnly = True;
		Items.SubsystemsTree.ReadOnly = True;
	EndIf;
	
	If Object.DeletionMark Then
		Items.SubsystemsTree.ReadOnly = True;
	EndIf;
	
	If Not Object.Custom Then
		Items.Description.ReadOnly = True;
		Items.Available.ReadOnly = True;
		Items.Author.ReadOnly = True;
		Items.Author.AutoMarkIncomplete = False;
	EndIf;
	
	IsExternal = (Object.ReportType = Enums.ReportTypes.External);
	If IsExternal Then
		Items.SubsystemsTree.ReadOnly = True;
	EndIf;
	
	Items.Available.ReadOnly = Not FullRightsToOptions;
	Items.Author.ReadOnly = Not FullRightsToOptions;
	Items.VisibleByDefault.ReadOnly = Not FullRightsToOptions;
	Items.TechnicalInformation.Visible = FullRightsToOptions;
	
	// Filling in a report name for the View command.
	If Object.ReportType = Enums.ReportTypes.Internal
		Or Object.ReportType = Enums.ReportTypes.Extension Then
		ReportName = Object.Report.Name;
	ElsIf Object.ReportType = Enums.ReportTypes.Additional Then
		ReportName = Object.Report.ObjectName;
	Else
		ReportName = Object.Report;
	EndIf;
	
	RefillTree(False);
	
	ItemsToLocalize = New Array;
	ItemsToLocalize.Add(Items.Description);
	ItemsToLocalize.Add(Items.Details);
	LocalizationServer.OnCreateAtServer(ItemsToLocalize);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	If ReportFormOpeningParameters <> Undefined Then
		Cancel = True;
		ReportsOptionsClient.OpenReportForm(Undefined, ReportFormOpeningParameters);
	EndIf;
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If Source <> ThisObject
		AND (EventName = ReportsOptionsClient.EventNameChangingOption()
			Or EventName = "Write_ConstantsSet") Then
		RefillTree(True);
		Items.SubsystemsTree.Expand(SubsystemsTree.GetItems()[0].GetID(), True);
	EndIf;
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	// Writing properties related to a predefined report option.
	DetailsChanged = False;
	If IsPredefined Then
		
		PredefinedOption = CurrentObject.PredefinedVariant.GetObject();
		LocalizationServer.OnReadPresentationsAtServer(PredefinedOption);
		
		CurrentObject.DefaultVisibilityOverridden = 
			Object.VisibleByDefault <> PredefinedOption.VisibleByDefault;
		DetailsChanged = Not IsBlankString(Object.Details) AND Lower(TrimAll(Object.Details)) <> Lower(TrimAll(PredefinedOption.Details));
		If Not DetailsChanged Then
			CurrentObject.Details = "";
			For each OptionPresentation In CurrentObject.Presentations Do 
				OptionPresentation.Details = "";
			EndDo;	
		EndIf;
	EndIf;
	
	// Writing the subsystems tree.
	DestinationTree = FormAttributeToValue("SubsystemsTree", Type("ValueTree"));
	If CurrentObject.IsNew() Then
		ChangedSections = DestinationTree.Rows.FindRows(New Structure("Use", 1), True);
	Else
		ChangedSections = DestinationTree.Rows.FindRows(New Structure("Modified", True), True);
	EndIf;
	ReportsOptions.SubsystemsTreeWrite(CurrentObject, ChangedSections);
	
	LocalizationServer.BeforeWriteAtServer(CurrentObject);
	If IsPredefined AND Not DetailsChanged Then
		CurrentObject.Presentations.Clear();
	EndIf;	
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	EndIf;
	// End StandardSubsystems.AccessManagement

	RefillTree(False);
	FillFromPredefinedOption(CurrentObject);
	LocalizationServer.OnReadAtServer(ThisObject, CurrentObject);
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	ReportsOptionsClient.UpdateOpenForms(Object.Ref, ThisObject);
	StandardSubsystemsClient.ExpandTreeNodes(ThisObject, "SubsystemsTree", "*", True);
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.AccessManagement
	
	FillFromPredefinedOption(CurrentObject);
	LocalizationServer.OnReadAtServer(ThisObject, CurrentObject);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DescriptionStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	ReportsOptionsClient.EditMultilineText(ThisObject, Item.EditText, Object, "Details", NStr("ru = 'Описание'; en = 'Details'; pl = 'Szczegóły';de = 'Einzelheiten';ro = 'Detalii';tr = 'Ayrıntılar'; es_ES = 'Detalles'"));
EndProcedure

&AtClient
Procedure AvailableOnChange(Item)
	Object.AvailableToAuthorOnly = (ThisObject.Available = "1");
EndProcedure

&AtClient
Procedure DescriptionOpen(Item, StandardProcessing)
	LocalizationClient.OnOpen(Object, Item, "Description", StandardProcessing);
EndProcedure

&AtClient
Procedure DetailsOpen(Item, StandardProcessing)
	LocalizationClient.OnOpen(Object, Item, "Details", StandardProcessing);
EndProcedure

#EndRegion

#Region SubsystemsTreeFormTableItemsEventHandlers

&AtClient
Procedure SubsystemsTreeUsageOnChange(Item)
	ReportsOptionsClient.SubsystemsTreeUsageOnChange(ThisObject, Item);
EndProcedure

&AtClient
Procedure SubsystemsTreeImportanceOnChange(Item)
	ReportsOptionsClient.SubsystemsTreeImportanceOnChange(ThisObject, Item);
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	ReportsOptions.SetSubsystemsTreeConditionalAppearance(ThisObject);
	
EndProcedure

&AtServer
Function RefillTree(Read)
	SelectedRows = ReportsServer.RememberSelectedRows(ThisObject, "SubsystemsTree", "Ref");
	If Read Then
		ThisObject.Read();
	EndIf;
	DestinationTree = ReportsOptions.SubsystemsTreeGenerate(ThisObject, Object);
	ValueToFormAttribute(DestinationTree, "SubsystemsTree");
	ReportsServer.RestoreSelectedRows(ThisObject, "SubsystemsTree", SelectedRows);
	Return True;
EndFunction

&AtServer
Procedure FillFromPredefinedOption(OptionObject)
	
	IsPredefined = Not OptionObject.Custom
		AND (OptionObject.ReportType = Enums.ReportTypes.Internal
			Or OptionObject.ReportType = Enums.ReportTypes.Extension)
		AND ValueIsFilled(OptionObject.PredefinedVariant);
	If Not IsPredefined Then
		Return;
	EndIf;		
			
	PredefinedOption = OptionObject.PredefinedVariant.GetObject();
	If OptionObject.DefaultVisibilityOverridden = False Then
		OptionObject.VisibleByDefault = PredefinedOption.VisibleByDefault;
	EndIf;
	
	OptionObject.Description = PredefinedOption.Description;
	
	OptionPresentations = OptionObject.Presentations.Unload();
	OptionObject.Presentations.Clear();
	OptionObject.Presentations.Load(PredefinedOption.Presentations.Unload());
	
	If IsBlankString(OptionObject.Details) Then
		OptionObject.Details = PredefinedOption.Details;
	Else
		OptionObject.Presentations.Sort("LanguageCode");
		OptionPresentations.Sort("LanguageCode");
		For each OptionPresentation In OptionObject.Presentations Do
			OptionDetails = OptionPresentations.Find(OptionPresentation.LanguageCode, "LanguageCode");
			OptionPresentation.Details = OptionDetails.Details;
		EndDo;
	EndIf;
EndProcedure

#EndRegion
