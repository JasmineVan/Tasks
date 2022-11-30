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
	
	VariantKey = Parameters.CurrentSettingsKey;
	CurrentUser = Users.AuthorizedUser();
	
	ReportInformation = ReportsOptions.GenerateReportInformationByFullName(Parameters.ObjectKey);
	If TypeOf(ReportInformation.ErrorText) = Type("String") Then
		Raise ReportInformation.ErrorText;
	EndIf;
	ReportInformation.Delete("ReportMetadata");
	ReportInformation.Delete("ErrorText");
	ReportInformation.Insert("ReportFullName", Parameters.ObjectKey);
	ReportInformation = New FixedStructure(ReportInformation);
	
	FullRightsToOptions = ReportsOptions.FullRightsToOptions();
	
	If Not FullRightsToOptions Then
		Items.ShowPersonalReportsOptionsByOtherAuthors.Visible = False;
		Items.ShowPersonalReportsOptionsOfOtherAuthorsCM.Visible = False;
		ShowPersonalReportsOptionsByOtherAuthors = False;
	EndIf;
	
	FillOptionsList();
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	Show = Settings.Get("ShowPersonalReportsOptionsByOtherAuthors");
	If Show <> ShowPersonalReportsOptionsByOtherAuthors Then
		ShowPersonalReportsOptionsByOtherAuthors = Show;
		Items.ShowPersonalReportsOptionsByOtherAuthors.Check = Show;
		Items.ShowPersonalReportsOptionsOfOtherAuthorsCM.Check = Show;
		FillOptionsList();
	EndIf;
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If EventName = ReportsOptionsClient.EventNameChangingOption()
		Or EventName = "Write_ConstantsSet" Then
		FillOptionsList();
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterAuthorOnChange(Item)
	FilterEnabled = ValueIsFilled(FilterAuthor);
	
	GroupsOrOptions = ReportOptionsTree.GetItems();
	For Each GroupOrOption In GroupsOrOptions Do
		HasEnabledItems = Undefined;
		NestedOptions = GroupOrOption.GetItems();
		For Each Option In NestedOptions Do
			Option.HiddenByFilter = FilterEnabled AND Option.Author <> FilterAuthor;
			If Not Option.HiddenByFilter Then
				HasEnabledItems = True;
			ElsIf HasEnabledItems = Undefined Then
				HasEnabledItems = False;
			EndIf;
		EndDo;
		If HasEnabledItems = Undefined Then // Group is an option.
			GroupOrOption.HiddenByFilter = FilterEnabled AND GroupOrOption.Author <> FilterAuthor;
		Else // This is folder.
			GroupOrOption.HiddenByFilter = HasEnabledItems;
		EndIf;
	EndDo;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersReportOptionTree

&AtClient
Procedure ReportOptionsTreeOnActivateRow(Item)
	Option = Items.ReportOptionsTree.CurrentData;
	If Option = Undefined Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(Option.VariantKey) Then
		OptionDetails = "";
	Else
		OptionDetails = Option.Details;
	EndIf;
EndProcedure

&AtClient
Procedure ReportOptionsTreeBeforeChangeRow(Item, Cancel)
	Cancel = True;
	OpenOptionForChange();
EndProcedure

&AtClient
Procedure ReportOptionsTreeBeforeAddRow(Item, Cancel, Clone, Parent, Folder)
	Cancel = True;
EndProcedure

&AtClient
Procedure ReportOptionsTreeBeforeDelete(Item, Cancel)
	Cancel = True;
	
	Option = Items.ReportOptionsTree.CurrentData;
	If Option = Undefined Or Not ValueIsFilled(Option.VariantKey) Then
		Return;
	EndIf;
	
	If Option.PictureIndex = 4 Then
		QuestionText = NStr("ru = 'Снять с ""%1"" пометку на удаление?'; en = 'Do you want to unmark %1 for deletion?'; pl = 'Oczyścić znacznik usunięcia dla ""%1""?';de = 'Löschzeichen für ""%1"" löschen?';ro = 'Scoateți marcajul la ștergere de pe ""%1""?';tr = '""%1"" silme işareti kaldırılsın mı?'; es_ES = '¿Eliminar la marca para borrar para ""%1""?'");
	Else
		QuestionText = NStr("ru = 'Пометить ""%1"" на удаление?'; en = 'Do you want to mark %1 for deletion?'; pl = 'Zaznaczyć ""%1"" do usunięcia?';de = 'Markieren Sie ""%1"" zum Löschen?';ro = 'Marcați ""%1"" la ștergere?';tr = '""%1"" silinmek üzere işaretlensin mi?'; es_ES = '¿Marcar ""%1"" para borrar?'");
	EndIf;
	QuestionText = StringFunctionsClientServer.SubstituteParametersToString(QuestionText, Option.Description);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Variant", Option);
	Handler = New NotifyDescription("ReportOptionsTreeBeforeDeleteCompletion", ThisObject, AdditionalParameters);
	ShowQueryBox(Handler, QuestionText, QuestionDialogMode.YesNo, 60, DialogReturnCode.Yes);
EndProcedure

&AtClient
Procedure ReportOptionsTreeChoice(Item, RowSelected, Field, StandardProcessing)
	StandardProcessing = False;
	SelectAndClose();
EndProcedure

&AtClient
Procedure ReportOptionsTreeValueChoice(Item, Value, StandardProcessing)
	StandardProcessing = False;
	SelectAndClose();
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure ShowPersonalReportsOptionsByOtherAuthors(Command)
	ShowPersonalReportsOptionsByOtherAuthors = Not ShowPersonalReportsOptionsByOtherAuthors;
	Items.ShowPersonalReportsOptionsByOtherAuthors.Check = ShowPersonalReportsOptionsByOtherAuthors;
	Items.ShowPersonalReportsOptionsOfOtherAuthorsCM.Check = ShowPersonalReportsOptionsByOtherAuthors;
	
	FillOptionsList();
	
	For Each TreeGroup In ReportOptionsTree.GetItems() Do
		If TreeGroup.HiddenByFilter = False Then
			Items.ReportOptionsTree.Expand(TreeGroup.GetID(), True);
		EndIf;
	EndDo;
EndProcedure

&AtClient
Procedure Update(Command)
	FillOptionsList();
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReportOptionsTree.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReportOptionsTreePresentation.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReportOptionsTreeAuthor.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ReportOptionsTree.HiddenByFilter");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Visible", False);
	Item.Appearance.SetParameterValue("Show", False);

	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReportOptionsTreePresentation.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReportOptionsTreeAuthor.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ReportOptionsTree.CurrentUserAuthor");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.MyReportOptionsColor);

EndProcedure

&AtClient
Procedure SelectAndClose()
	Option = Items.ReportOptionsTree.CurrentData;
	If Option = Undefined Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(Option.VariantKey) Then
		Return;
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("VariantKey", Option.VariantKey);
	If Option.PictureIndex = 4 Then
		QuestionText = NStr("ru = 'Выбранный вариант отчета помечен на удаление.
		|Выбрать этот варианта отчета?'; 
		|en = 'Selected report option is marked for deletion.
		|Do you want to select this report option?'; 
		|pl = 'Wybrany wariant raportu został zaznaczony do usunięcia.
		|Wybrać ten wariant raportu?';
		|de = 'Die ausgewählte Berichtsoption ist zum Löschen markiert. 
		|Wählen Sie diese Berichtsoption?';
		|ro = 'Varianta selectată a raportului este marcată la ștergere.
		|Selectați această variantă a raportului?';
		|tr = 'Seçilen rapor seçeneği silinmek üzere işaretlenmiştir. 
		|Bu rapor seçeneği belirtilsin mi?'; 
		|es_ES = 'Opción del informe seleccionada está marcada para borrar.
		|¿Seleccionar esta opción del informe?'");
		Handler = New NotifyDescription("SelectAndCloseCompletion", ThisObject, AdditionalParameters);
		ShowQueryBox(Handler, QuestionText, QuestionDialogMode.YesNo, 60);
	Else
		SelectAndCloseCompletion(DialogReturnCode.Yes, AdditionalParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectAndCloseCompletion(Response, AdditionalParameters) Export
	If Response = DialogReturnCode.Yes Then
		Close(New SettingsChoice(AdditionalParameters.VariantKey));
	EndIf;
EndProcedure

&AtClient
Procedure OpenOptionForChange()
	Option = Items.ReportOptionsTree.CurrentData;
	If Option = Undefined Or Not ValueIsFilled(Option.Ref) Then
		Return;
	EndIf;
	If Not OptionChangeRight(Option, FullRightsToOptions) Then
		WarningText = NStr("ru = 'Недостаточно прав для изменения варианта ""%1"".'; en = 'Insufficient rights to modify report option %1.'; pl = 'Brak wystarczających uprawnień do zmiany wariantu ""%1"".';de = 'Nicht ausreichende Rechte, um die Option ""%1"" zu ändern.';ro = 'Drepturile insuficiente pentru modificarea variantei ""%1"".';tr = '""%1"" opsiyonunu değiştirmek için haklar yetersiz.'; es_ES = 'Insuficientes derechos para cambiar la variante ""%1"".'");
		WarningText = StringFunctionsClientServer.SubstituteParametersToString(WarningText, Option.Description);
		ShowMessageBox(, WarningText);
		Return;
	EndIf;
	ReportsOptionsClient.ShowReportSettings(Option.Ref);
EndProcedure

&AtClient
Procedure ReportOptionsTreeBeforeDeleteCompletion(Response, AdditionalParameters) Export
	If Response = DialogReturnCode.Yes Then
		DeleteOptionAtServer(AdditionalParameters.Variant.Ref, AdditionalParameters.Variant.PictureIndex);
	EndIf;
EndProcedure

&AtClientAtServerNoContext
Function OptionChangeRight(Option, FullRightsToOptions)
	Return FullRightsToOptions Or Option.CurrentUserAuthor;
EndFunction

&AtServer
Procedure FillOptionsList()
	
	CurrentOptionKey = VariantKey;
	If ValueIsFilled(Items.ReportOptionsTree.CurrentRow) Then
		CurrentTreeRow = ReportOptionsTree.FindByID(Items.ReportOptionsTree.CurrentRow);
		If ValueIsFilled(CurrentTreeRow.VariantKey) Then
			CurrentOptionKey = CurrentTreeRow.VariantKey;
		EndIf;
	EndIf;
	
	FilterReports = New Array;
	FilterReports.Add(ReportInformation.Report);
	SearchParameters = New Structure("Reports,DeletionMark,OnlyPersonal", 
		FilterReports, False, Not ShowPersonalReportsOptionsByOtherAuthors);
	ReportOptionsTable = ReportsOptions.ReportOptionTable(SearchParameters);
	
	// Populate autocalculated columns
	ReportOptionsTable.Columns.Add("CurrentUserAuthor", New TypeDescription("Boolean"));	
	ReportOptionsTable.Columns.Add("PictureIndex", New TypeDescription("Number", New NumberQualifiers(1, 0, AllowedSign.Any)));	
	ReportOptionsTable.Columns.Add("Order", New TypeDescription("Number", New NumberQualifiers(1, 0, AllowedSign.Any)));	
	For each Option In ReportOptionsTable Do
		Option.CurrentUserAuthor = (Option.Author = CurrentUser);
		Option.PictureIndex = ?(Option.DeletionMark, 4, ?(Option.Custom, 3, 5));
		Option.Order = ?(Option.DeletionMark, 3, 1);
	EndDo;

	If ReportInformation.ReportType = Enums.ReportTypes.External 
		AND Not SettingsStorages.ReportsVariantsStorage.AddExternalReportOptions(
			ReportOptionsTable, ReportInformation.ReportFullName, ReportInformation.ReportName) Then
		Return;
	EndIf;
	
	ReportOptionsTable.Sort("Order ASC, Description ASC");
	ReportOptionsTree.GetItems().Clear();
	TreeGroups = New Map;
	TreeGroups.Insert(1, ReportOptionsTree.GetItems());
	
	For Each OptionInfo In ReportOptionsTable Do
		If Not ValueIsFilled(OptionInfo.VariantKey) Then
			Continue;
		EndIf;
		TreeRowsSet = TreeGroups.Get(OptionInfo.Order);
		If TreeRowsSet = Undefined Then
			TreeGroup = ReportOptionsTree.GetItems().Add();
			TreeGroup.GroupNumber = OptionInfo.Order;
			If OptionInfo.Order = 3 Then
				TreeGroup.Description = NStr("ru = 'Помеченные на удаление'; en = 'Marked for deletion'; pl = 'Zaznaczony do usunięcia';de = 'Zum Löschen markiert';ro = 'Marcate pentru ștergere';tr = 'Silinmek üzere işaretlendi'; es_ES = 'Marcado para borrar'");
				TreeGroup.PictureIndex = 1;
				TreeGroup.AuthorPicture = -1;
			EndIf;
			TreeRowsSet = TreeGroup.GetItems();
			TreeGroups.Insert(OptionInfo.Order, TreeRowsSet);
		EndIf;
		
		Option = TreeRowsSet.Add();
		FillPropertyValues(Option, OptionInfo);
		Option.GroupNumber = OptionInfo.Order;
		If Option.VariantKey = CurrentOptionKey Then
			Items.ReportOptionsTree.CurrentRow = Option.GetID();
		EndIf;
		Option.AuthorPicture = ?(Option.AvailableToAuthorOnly, -1, 0);
	EndDo;
	
EndProcedure

&AtServerNoContext
Procedure DeleteOptionAtServer(ReportOptionsRef, PictureIndex)
	
	BeginTransaction();
	Try
		Lock = New DataLock;
		LockItem = Lock.Add("Catalog.ReportsOptions");
		LockItem.SetValue("Ref", ReportOptionsRef);
		
		OptionObject = ReportOptionsRef.GetObject();
		DeletionMark = Not OptionObject.DeletionMark;
		Custom = OptionObject.Custom;
		OptionObject.SetDeletionMark(DeletionMark);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;	
	PictureIndex = ?(DeletionMark, 4, ?(Custom, 3, 5));
	
EndProcedure

#EndRegion
