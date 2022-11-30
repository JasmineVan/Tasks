///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

&AtClient
Var ChoiceContext;

#EndRegion

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("ChoiceMode") AND Parameters.ChoiceMode = True Then
		WindowOpeningMode = FormWindowOpeningMode.LockOwnerWindow;
		Items.List.ChoiceMode = True;
	EndIf;
	
	FileInfobase = Common.FileInfobase();
	
	Interactions.InitializeInteractionsListForm(ThisObject, Parameters);
	DetermineAvailabilityFullTextSearch();
	
	CommonClientServer.SetDynamicListFilterItem(Tabs, "Owner", Users.CurrentUser(),,, True);
	
	AddToNavigationPanel();
	Interactions.FillStatusSubmenu(Items.StatusList, ThisObject);
	Interactions.FillSubmenuByInteractionType(Items.InteractionTypeList, ThisObject);
	
	For Each SubjectType In Metadata.InformationRegisters.InteractionsFolderSubjects.Resources.Topic.Type.Types() Do
		If EmailOnly 
			AND (SubjectType = Type("DocumentRef.Meeting") OR SubjectType = Type("DocumentRef.PhoneCall") 
			OR SubjectType = Type("DocumentRef.PlannedInteraction") OR SubjectType = Type("DocumentRef.SMSMessage")) Then
			Continue;
		EndIf;
		SubjectTypeChoiceList.Add(Metadata.FindByType(SubjectType).FullName(), String(SubjectType));
	EndDo;
	
	InteractionType = ?(EmailOnly, "AllMessages","All");
	Status = "All";
	
	CurrentNavigationPanelName = CommonClientServer.StructureProperty(Parameters, "CurrentNavigationPanelName");
	CurrentRef = CommonClientServer.StructureProperty(Parameters, "CurrentRow");
	If ValueIsFilled(CurrentRef) Then
		PrepareFormSettingsForCurrentRefOutput(CurrentRef);
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Insert("CommandBar", Items.NavigationPanelListGroup.ChildItems.NavigationOptionCommandBar);
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	Interactions.FillListOfDocumentsAvailableForCreation(DocumentsAvailableForCreation);
	UnsafeContentDisplayInEmailsProhibited = Interactions.UnsafeContentDisplayInEmailsProhibited();
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	If Parameters.Property("CurrentNavigationPanelName") Then
		Settings.Delete("CurrentNavigationPanelName");
	EndIf;
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	If IsBlankString(CurrentNavigationPanelName) Or Items.Find(CurrentNavigationPanelName) = Undefined Then
		CurrentNavigationPanelName = "SubjectPage";
	ElsIf CurrentNavigationPanelName = "PropertiesPage" Then
		If AddlAttributesPropertiesTable.FindRows(New 
				Structure("AddlAttributeInfo",CurrentPropertyOfNavigationPanel)).Count() = 0 Then
			CurrentNavigationPanelName = "SubjectPage";
		EndIf;
	EndIf;
	
	Items.NavigationPanelPages.CurrentPage = Items[CurrentNavigationPanelName];
	
	Status = Settings.Get("Status");
	If Status <> Undefined Then
		Settings.Delete("Status");
	EndIf;
	If Not UseReviewedFlag Then
		Status = "All";
	EndIf;
	If ValueIsFilled(Status) Then
		OnChangeStatusServer(False);
	EndIf;

	EmployeeResponsible = Settings.Get("EmployeeResponsible");
	If EmployeeResponsible <> Undefined Then
		OnChangeEmployeeResponsibleServer(False);
		Settings.Delete("EmployeeResponsible");
	EndIf;
	
	Interactions.OnImportInteractionsTypeFromSettings(ThisObject, Settings);
	
	OnChangeTypeServer(False);
	UpdateNavigationPanelAtServer();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If Upper(EventName) = Upper("Write_InteractionTabs") Then
		If Items.NavigationPanelPages.CurrentPage = Items.TabsPage Then
			Items.Tabs.Refresh();
			ProcessNavigationPanelRowActivation();
		EndIf;
	ElsIf Upper(EventName) = Upper("Write_EmailFolders") 
		Or Upper(EventName) = Upper("MessageProcessingRulesApplied")
		Or Upper(EventName) = Upper("SendAndReceiveEmailDone") Then
		If Items.NavigationPanelPages.CurrentPage = Items.FoldersPage Then
			RefreshNavigationPanel();
			RestoreExpandedTreeNodes();
		EndIf;
	ElsIf Upper(EventName) = Upper("InteractionSubjectEdit") Then
		If Items.NavigationPanelPages.CurrentPage = Items.SubjectPage Then
			RefreshNavigationPanel();
		EndIf;
	EndIf;
	
EndProcedure 

&AtClient
Procedure OnOpen(Cancel)
	
	If IsBlankString(CurrentNavigationPanelName) 
		Or IsBlankString(Status) 
		Or IsBlankString(InteractionType)  Then
		
		SetInitialValuesOnOpen();
		
	EndIf;
	
	RestoreExpandedTreeNodes();
	
EndProcedure

&AtServer
Procedure SetInitialValuesOnOpen()
	
	Items.NavigationPanelPages.CurrentPage = Items.SubjectPage;
	Status = "All";
	InteractionType = "All";
	OnChangeStatusServer(False);
	OnChangeTypeServer(False);
	UpdateNavigationPanelAtServer();

EndProcedure

&AtClient
Procedure NavigationProcessing(NavigationObject, StandardProcessing)
	If Not ValueIsFilled(NavigationObject) Or NavigationObject = Items.List.CurrentRow Then
		Return;
	EndIf;
	
	NavigationProcessingAtServer(NavigationObject);
	RestoreExpandedTreeNodes();
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectedValue, ChoiceSource)
	
	If ChoiceContext = "EmployeeResponsibleExecute" Then
		
		If SelectedValue <> Undefined Then
			SetEmployeeResponsible(SelectedValue, Undefined);
		EndIf;
		
		RestoreExpandedTreeNodes();
		
	ElsIf ChoiceContext = "EmployeeResponsibleList" Then
		
		If SelectedValue <> Undefined Then
			SetEmployeeResponsible(SelectedValue, Items.List.SelectedRows);
		EndIf;
		
		RestoreExpandedTreeNodes();
		
	ElsIf ChoiceContext = "SubjectExecuteSubjectType" Then
		
		If SelectedValue = Undefined Then
			Return;
		EndIf;
		
		ChoiceContext = "SubjectExecute";
		
		FormParameters = New Structure;
		FormParameters.Insert("ChoiceMode", True);
		
		OpenForm(SelectedValue + ".ChoiceForm", FormParameters, ThisObject);
		
		Return;
		
	ElsIf ChoiceContext = "SubjectListSubjectType" Then
		
		If SelectedValue = Undefined Then
			Return;
		EndIf;
		
		ChoiceContext = "SubjectList";
		
		FormParameters = New Structure;
		FormParameters.Insert("ChoiceMode", True);
		
		OpenForm(SelectedValue + ".ChoiceForm", FormParameters, ThisObject);
		
		Return;
		
	ElsIf ChoiceContext = "SubjectExecute" Then
		
		If SelectedValue <> Undefined Then
			SetSubject(SelectedValue, Undefined);
		EndIf;
		
		RestoreExpandedTreeNodes();
		
	ElsIf ChoiceContext = "SubjectList" Then
		
		If SelectedValue <> Undefined Then
			SetSubject(SelectedValue, Items.List.SelectedRows);
		EndIf;
		
		RestoreExpandedTreeNodes();
		
	ElsIf ChoiceContext = "MoveToFolder" Then
		
		If SelectedValue <> Undefined Then
			
			CurrentItemName = CurrentItem.Name;
			FoldersCurrentData = Items.Folders.CurrentData;
			
			If StrStartsWith(CurrentItemName, "List") Then
				ExecuteTransferToEmailsArrayFolder(Items[CurrentItemName].SelectedRows, SelectedValue);
			Else
				SetFolderParent(FoldersCurrentData.Value, SelectedValue);
			EndIf;
			
			RestoreExpandedTreeNodes();
			
		EndIf;
		
	EndIf;
	
	ChoiceContext = Undefined;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure NavigationPanelOnActivateRow(Item)
	
	If Item.Name = "Subjects" 
		AND Items.NavigationPanelPages.CurrentPage <> Items.SubjectPage Then
		Return;
	ElsIf Item.Name = "Contacts" 
		AND Items.NavigationPanelPages.CurrentPage <> Items.ContactPage Then
		Return;
	ElsIf Item.Name = "Tabs" 
		AND Items.NavigationPanelPages.CurrentPage <> Items.TabsPage Then
		Return;
	ElsIf Item.Name = "Properties" 
		AND Items.NavigationPanelPages.CurrentPage <> Items.PropertiesPage Then
		Return;
	ElsIf Item.Name = "Folders" 
		AND Items.NavigationPanelPages.CurrentPage <> Items.FoldersPage Then
		Return;
	ElsIf Item.Name = "Categories" 
		AND Items.NavigationPanelPages.CurrentPage <> Items.CategoriesPage Then
		Return;
	EndIf;
	
	If DoNotTestNavigationPanelActivation Then
		DoNotTestNavigationPanelActivation = False;
	Else
		AttachIdleHandler("ProcessNavigationPanelRowActivation", 0.2, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure EmployeeResponsibleOnChange(Item)
	
	OnChangeEmployeeResponsibleServer(True);
	RestoreExpandedTreeNodes();
	
EndProcedure

&AtClient
Procedure InteractionTypeOnChange(Item)
	
	OnChangeTypeServer();
	RestoreExpandedTreeNodes();
	
EndProcedure

&AtClient
Procedure ListOnChange(Item)
	
	RefreshNavigationPanel();
	RestoreExpandedTreeNodes();
	
EndProcedure

&AtClient
Procedure PersonalSettings(Command)
	
	OpenForm("DocumentJournal.Interactions.Form.EmailOperationSettings", , ThisObject);
	
EndProcedure

&AtClient
Procedure ListOnActivateRow(Item)
	
	If Items.List.CurrentData = Undefined AND DisplayReadingPane Then
		If Items.PagesPreview.CurrentPage <> Items.PreviewPlainTextPage Then
			Items.PagesPreview.CurrentPage = Items.PreviewPlainTextPage;
		EndIf;
		Preview = "";
		HTMLPreview = "<HTML><BODY></BODY></HTML>";
		InteractionPreviewGeneratedFor = Undefined;
		
	Else
		
		If CorrectChoice(Item.Name,True) 
			AND InteractionPreviewGeneratedFor <> Items.List.CurrentData.Ref Then
			
			If Items.List.SelectedRows.Count() = 1 Then
				
				AttachIdleHandler("ProcessListRowActivation",0.1,True);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure ListChoice(Item, RowSelected, Field, StandardProcessing)
	
	If Items.List.ChoiceMode Then
		StandardProcessing = False;
		NotifyChoice(RowSelected);
	EndIf;
	
EndProcedure

&AtClient
Procedure FoldersSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	CurrentData = Item.CurrentData;
	ShowValue(, CurrentData.Value);
	
EndProcedure

&AtClient
Procedure NavigationPanelContactsChoice(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	CurrentData = Item.CurrentData;
	If Not TypeOf(CurrentData.Contact) = Type("CatalogRef.StringContactInteractions") Then
		ShowValue( ,CurrentData.Contact);
	EndIf;
	
EndProcedure

&AtClient
Procedure SubjectsNavigationPanelChoice(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Item.CurrentData;
	If CurrentData <> Undefined Then
		StandardProcessing = False;
		ShowValue( ,CurrentData.Topic);
	EndIf;
	
EndProcedure

&AtClient
Procedure SubjectsNavigationPanelBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure SubjectsNavigationPanelBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure ContactsBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure ContactsBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure FoldersBeforeAddRow(Item, Cancel, Clone, Parent, Folder)
	
	Cancel = True;
	
	CurrentData = Items.Folders.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.HasEditPermission = 0 Then
		ShowMessageBox(, NStr("ru = 'Недостаточно прав для создания папки.'; en = 'Insufficient rights to create a folder.'; pl = 'Insufficient rights to create a folder.';de = 'Insufficient rights to create a folder.';ro = 'Insufficient rights to create a folder.';tr = 'Insufficient rights to create a folder.'; es_ES = 'Insufficient rights to create a folder.'"));
		Return;
	EndIf;
		
	ParametersStructure = New Structure;
	ParametersStructure.Insert("Owner", CurrentData.Account);
	If TypeOf(CurrentData.Value) = Type("CatalogRef.EmailMessageFolders") Then
		ParametersStructure.Insert("Parent", CurrentData.Value);
	EndIf;
	
	FormParameters = New Structure("FillingValues", ParametersStructure);
	OpenForm("Catalog.EmailMessageFolders.ObjectForm", FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure FoldersBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	
	CurrentData = Items.Folders.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If TypeOf(CurrentData.Value) = Type("CatalogRef.EmailAccounts")
		OR CurrentData.HasEditPermission = 0 OR CurrentData.PredefinedFolder Then
		Return;
	EndIf;
	
	QuestionText = NStr("ru = 'Удалить папку ""'; en = 'Delete folder ""'; pl = 'Delete folder ""';de = 'Delete folder ""';ro = 'Delete folder ""';tr = 'Delete folder ""'; es_ES = 'Delete folder ""'") + String(CurrentData.Value) 
	+ NStr("ru = '"" и переместить все ее содержимое в папку ""Удаленные""'; en = '"" and transfer all its contents to the ""Deleted"" folder'; pl = '"" and transfer all its contents to the ""Deleted"" folder';de = '"" and transfer all its contents to the ""Deleted"" folder';ro = '"" and transfer all its contents to the ""Deleted"" folder';tr = '"" and transfer all its contents to the ""Deleted"" folder'; es_ES = '"" and transfer all its contents to the ""Deleted"" folder'");
	
	AdditionalParameters = New Structure("CurrentData", CurrentData);
	OnCloseNotifyHandler = New NotifyDescription("QuestionOnFolderDeletionAfterCompletion", ThisObject, AdditionalParameters);
	ShowQueryBox(OnCloseNotifyHandler, QuestionText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtServer
Function DeleteFolderServer(Folder)
	
	ErrorDescription = "";
	Interactions.ExecuteEmailsFolderDeletion(Folder, ErrorDescription);
	If IsBlankString(ErrorDescription) Then
		RefreshNavigationPanel();
	EndIf;
	
	Return ErrorDescription;
	
EndFunction

&AtClient
Procedure StatusOnChange(Item)
	
	OnChangeStatusServer(True);
	RestoreExpandedTreeNodes();
	
EndProcedure

&AtClient
Procedure InteractionTypeStatusClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure SearchStringOnChange(Item)
	
	DetailsSPFound.Clear();
	
	If SearchString <> "" Then
		
		ExecuteFullTextSearch();
		
	Else
		AdvancedSearch = False;
		CommonClientServer.SetDynamicListFilterItem(
			List, 
			"Search",
			Undefined,
			DataCompositionComparisonType.Equal,,False);
		Items.DetailSPFound.Visible = AdvancedSearch;
	EndIf;
	
EndProcedure

&AtClient
Procedure SearchStringAutoComplete(Item, Text, ChoiceData, Wait, StandardProcessing)
	
	StandardProcessing = False;
	ChoiceData = New ValueList;
	
	FoundItemsCount = 0;
	For each ListItem In Items.SearchString.ChoiceList Do
		If Left(Upper(ListItem.Value), StrLen(TrimAll(Text))) = Upper(TrimAll(Text)) Then
			ChoiceData.Add(ListItem.Value);
			FoundItemsCount = FoundItemsCount + 1;
			If FoundItemsCount > 7 Then
				Break;
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure 

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Clone, Parent, Folder)
	
	InteractionsClient.ListBeforeAddRow(Item, Cancel, Clone, EmailOnly, DocumentsAvailableForCreation);
	
EndProcedure

&AtClient
Procedure NavigationPanelTreeNodeBeforeCollapse(Item, Row, Cancel)
	
	TreeName = Item.Name;
	
	If Item.CurrentRow <> Undefined Then
		RowData = Items[TreeName].RowData(Row);
		If RowData <> Undefined Then
			SaveNodeStateInSettings(TreeName, RowData.Value, False);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure NavigationPanelTreeNodeBeforeExpand(Item, Row, Cancel)
	
	TreeName = Item.Name;
	
	If Item.CurrentRow <> Undefined Then
		RowData = Items[TreeName].RowData(Row);
		If RowData <> Undefined Then
			SaveNodeStateInSettings(TreeName, RowData.Value, True);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure HTMLPreviewOnClick(Item, EventData, StandardProcessing)
	
	InteractionsClient.HTMLFieldOnClick(Item, EventData, StandardProcessing);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////////
// Processing dragging

&AtClient
Procedure SubjectsDragCheck(Item, DragParameters, StandardProcessing, Row, Field)
	
	If (Row = Undefined) OR (DragParameters.Value = Undefined) Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	If TypeOf(DragParameters.Value) = Type("Array") Then
		
		For each ArrayElement In DragParameters.Value Do
			If InteractionsClientServer.IsInteraction(ArrayElement) Then
				Return;
			EndIf;
		EndDo;
	EndIf;
	
	DragParameters.Action = DragAction.Cancel;

EndProcedure

&AtClient
Procedure SubjectsDrag(Item, DragParameters, StandardProcessing, Row, Field)
	
	StandardProcessing = False;
	
	If TypeOf(DragParameters.Value) = Type("Array") Then
		
		InteractionsServerCall.SetSubjectForInteractionsArray(DragParameters.Value,
			Row, True);
			
	EndIf;
	
	RefreshNavigationPanel();
	
EndProcedure

&AtClient
Procedure FoldersDragCheck(Item, DragParameters, StandardProcessing, Row, Field)
	
	If (Row = Undefined) OR (DragParameters.Value = Undefined) Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	AssignmentRow = Folders.FindByID(Row);
	
	If TypeOf(DragParameters.Value) = Type("Array") Then
		
		If TypeOf(AssignmentRow.Value) = Type("CatalogRef.EmailAccounts") 
			OR AssignmentRow.HasEditPermission = 0 Then
			DragParameters.Action = DragAction.Cancel;
			Return;
		EndIf;
		
		For each ArrayElement In DragParameters.Value Do
			If Not InteractionsClient.IsEmail(ArrayElement) Then
				Continue;
			EndIf;
			
			DragParameters.Action = DragAction.Cancel;
			RowData = Items.List.RowData(ArrayElement);
			If RowData.Account = AssignmentRow.Account Then
				DragParameters.Action = DragAction.Move;
				Return;
			EndIf;
		EndDo;
		DragParameters.Action = DragAction.Cancel;
		
	ElsIf TypeOf(DragParameters.Value) = Type("Number") Then
		
		RowDrag = Folders.FindByID(DragParameters.Value);
		If RowDrag.Account <> AssignmentRow.Account Then
			DragParameters.Action = DragAction.Cancel;
			Return;
		EndIf;
		
		ParentRow = AssignmentRow;
		While TypeOf(ParentRow.Value) <> Type("CatalogRef.EmailAccounts") Do
			If RowDrag = ParentRow Then
				DragParameters.Action = DragAction.Cancel;
				Return;
			EndIf;
			ParentRow = ParentRow.GetParent();
		EndDo;
		
	Else
		
		DragParameters.Action = DragAction.Cancel;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FoldersDrag(Item, DragParameters, StandardProcessing, Row, Field)
	
	StandardProcessing = False;
	
	AssignmentRow = Folders.FindByID(Row);
	
	If TypeOf(DragParameters.Value) = Type("Array") Then
		ExecuteTransferToEmailsArrayFolder(DragParameters.Value, AssignmentRow.Value);
	ElsIf TypeOf(DragParameters.Value) = Type("Number") Then
		DragRowData = Folders.FindByID(DragParameters.Value);
		If NOT DragRowData.GetParent() = AssignmentRow Then
			SetFolderParent(DragRowData.Value,
			                        ?(TypeOf(AssignmentRow.Value) = Type("CatalogRef.EmailAccounts"),
			                        PredefinedValue("Catalog.EmailMessageFolders.EmptyRef"),
			                        AssignmentRow.Value));
		EndIf;
			
	EndIf;
	
	RefreshNavigationPanel(AssignmentRow.Value);
	RestoreExpandedTreeNodes();
	
EndProcedure

&AtClient
Procedure FoldersDragStart(Item, DragParameters, Perform)
	
	If DragParameters.Value = Undefined Then
		Return;
	EndIf;
	
	RowData = Folders.FindByID(DragParameters.Value);
	If TypeOf(RowData.Value) = Type("CatalogRef.EmailAccounts") 
		OR RowData.PredefinedFolder OR RowData.HasEditPermission = 0 Then
		Perform = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure ListDrag(Item, DragParameters, StandardProcessing, Row, Field)
	
	StandardProcessing = False;
	
	ListFileNames = New ValueList;
	
	If TypeOf(DragParameters.Value) = Type("File") 
		AND DragParameters.Value.IsFile() Then
		
		ListFileNames.Add(DragParameters.Value.FullName,DragParameters.Value.Name);
		
	ElsIf TypeOf(DragParameters.Value) = Type("Array") Then
		
		If DragParameters.Value.Count() >= 1 
			AND TypeOf(DragParameters.Value[0]) = Type("File") Then
			
			For Each ReceivedFile In DragParameters.Value Do
				If TypeOf(ReceivedFile) = Type("File") AND ReceivedFile.IsFile() Then
					ListFileNames.Add(ReceivedFile.FullName,ReceivedFile.Name);
				EndIf;
			EndDo;
		EndIf;
		
	EndIf;
	
	FormParameters = New Structure("Attachments", ListFileNames);
	OpenForm("Document.OutgoingEmail.ObjectForm", FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure ListDragCheck(Item, DragParameters, StandardProcessing, Row, Field)
	
	StandardProcessing = False;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Update(Command)
	
	UpdateAtServer();
	RestoreExpandedTreeNodes();
	
EndProcedure

&AtClient
Procedure SendReceiveEmailExecute(Command)
	
	If NOT FileInfobase Then
		Return;
	EndIf;
	
	ClearMessages();
	
	EmailManagementClient.SendReceiveUserEmail(UUID, ThisObject, Items.List);
	
EndProcedure

&AtClient
Procedure Reply(Command)
	
	If CorrectChoice(Items.List.Name, True) Then
		CurrentInteraction = Items.List.CurrentData.Ref;
		If TypeOf(CurrentInteraction) <> Type("DocumentRef.IncomingEmail") Then
			ShowMessageBox(, NStr("ru = 'Команда ""Ответить"" может быть выполнена только для входящего письма.'; en = 'You can click ""Reply"" only for incoming messages.'; pl = 'You can click ""Reply"" only for incoming messages.';de = 'You can click ""Reply"" only for incoming messages.';ro = 'You can click ""Reply"" only for incoming messages.';tr = 'You can click ""Reply"" only for incoming messages.'; es_ES = 'You can click ""Reply"" only for incoming messages.'"));
			Return;
		EndIf;
	Else
		Return;
	EndIf;
	
	Base = New Structure("Base,Command",CurrentInteraction, "Reply");
	OpeningParameters = New Structure("Base", Base);
	OpenForm("Document.OutgoingEmail.ObjectForm", OpeningParameters);
	
EndProcedure

&AtClient
Procedure ReplyToAll(Command)
	
	If CorrectChoice(Items.List.Name, True) Then
		CurrentInteraction = Items.List.CurrentData.Ref;
		If TypeOf(CurrentInteraction) <> Type("DocumentRef.IncomingEmail") Then
			ShowMessageBox(, NStr("ru = 'Команда ""Ответить всем"" может быть выполнена только для входящего письма.'; en = 'You can click ""Reply to all"" only for incoming messages.'; pl = 'You can click ""Reply to all"" only for incoming messages.';de = 'You can click ""Reply to all"" only for incoming messages.';ro = 'You can click ""Reply to all"" only for incoming messages.';tr = 'You can click ""Reply to all"" only for incoming messages.'; es_ES = 'You can click ""Reply to all"" only for incoming messages.'"));
			Return;
		EndIf;
	Else
		Return;
	EndIf;
	
	Base = New Structure("Base,Command",CurrentInteraction, "ReplyToAll");
	OpeningParameters = New Structure("Base", Base);
	OpenForm("Document.OutgoingEmail.ObjectForm", OpeningParameters);
	
EndProcedure

&AtClient
Procedure Forward(Command)
	
	If CorrectChoice(Items.List.Name, True) Then
		CurrentInteraction = Items.List.CurrentData.Ref;
		If TypeOf(CurrentInteraction) <> Type("DocumentRef.OutgoingEmail") 
			AND TypeOf(CurrentInteraction) <> Type("DocumentRef.IncomingEmail") Then
			ShowMessageBox(, NStr("ru = 'Команда ""Переслать"" может быть выполнена только для писем.'; en = 'You can click ""Forward"" only for messages.'; pl = 'You can click ""Forward"" only for messages.';de = 'You can click ""Forward"" only for messages.';ro = 'You can click ""Forward"" only for messages.';tr = 'You can click ""Forward"" only for messages.'; es_ES = 'You can click ""Forward"" only for messages.'"));
			Return;
		EndIf;
	Else
		Return;
	EndIf;
	
	Base = New Structure("Base,Command", CurrentInteraction, "Forward");
	OpeningParameters = New Structure("Base", Base);
	OpenForm("Document.OutgoingEmail.ObjectForm", OpeningParameters);

EndProcedure

&AtClient
Procedure SwitchNavigationPanel(Command)
	
	SwitchNavigationPanelServer(Command.Name);
	RestoreExpandedTreeNodes();
	
EndProcedure 

&AtClient
Procedure SetNavigationMethodByContact(Command)
	
	SwitchNavigationPanel(Command);
	
EndProcedure

&AtClient
Procedure SetNavigationMethodBySubject(Command)
	
	SwitchNavigationPanel(Command);
	
EndProcedure

&AtClient
Procedure SetNavigationMethodByTabs(Command)
	
	SwitchNavigationPanel(Command);
	
EndProcedure

&AtClient
Procedure SetNavigationMethodByFolders(Command)
	
	SwitchNavigationPanel(Command);
	
EndProcedure

&AtClient
Procedure EmployeeResponsibleExecute(Command)
	
	ChoiceContext = "EmployeeResponsibleExecute";
	
	FormParameters = New Structure;
	FormParameters.Insert("ChoiceMode",True);
	
	OpenForm("Catalog.Users.Form.ListForm", FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure EmployeeResponsibleList(Command)
	
	CurrentItemName = Items.List.Name;
	If StrStartsWith(CurrentItemName, "List") AND Not CorrectChoice(CurrentItemName) Then
		Return;
	EndIf;
	
	ChoiceContext = "EmployeeResponsibleList";
	
	FormParameters = New Structure;
	FormParameters.Insert("ChoiceMode",True);
	
	OpenForm("Catalog.Users.Form.ListForm", FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure ReviewedExecute(Command)
	
	SetReviewedFlag(Undefined,True);
	RestoreExpandedTreeNodes();

EndProcedure

&AtClient
Procedure MarkAsReviewed(Command)
	
	ReviewedExecuteList(True);
	
EndProcedure

&AtClient
Procedure InteractionsBySubject(Command)
	
	CurrentItemName = Items.List.Name;
	If Not CorrectChoice(CurrentItemName,True) Then
		Return;
	EndIf;
	
	Topic = Items[CurrentItemName].CurrentData.Topic;
	
	If InteractionsClientServer.IsSubject(Topic) Then
		
		FilterStructure = New Structure;
		FilterStructure.Insert("Topic", Topic);
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("InteractionType", "Topic");
		
		FormParameters = New Structure;
		FormParameters.Insert("Filter", FilterStructure);
		FormParameters.Insert("AdditionalParameters", AdditionalParameters);
		
	ElsIf InteractionsClientServer.IsInteraction(Topic) Then
		
		FilterStructure = New Structure;
		FilterStructure.Insert("Topic", Topic);
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("InteractionType", "Interaction");
		
		FormParameters = New Structure;
		FormParameters.Insert("Filter", FilterStructure);
		FormParameters.Insert("AdditionalParameters", AdditionalParameters);
		
	Else
		Return;
	EndIf;

	OpenForm(
		"DocumentJournal.Interactions.Form.ParametricListForm",
		FormParameters,
		ThisObject);
	
EndProcedure

&AtClient
Procedure ClearReviewedFlag(Command)
	
	ReviewedExecuteList(False);
	
EndProcedure

&AtClient
Procedure ReviewedExecuteList(FlagValues)
	
	CurrentItemName = Items.List.Name;
	If Not CorrectChoice(CurrentItemName) Then
		Return;
	EndIf;
	
	SetReviewedFlag(Items[CurrentItemName].SelectedRows, FlagValues);
	RestoreExpandedTreeNodes();
	
EndProcedure

&AtClient
Procedure SubjectExecute(Command)
	
	ChoiceContext = "SubjectExecuteSubjectType";
	OpenForm("DocumentJournal.Interactions.Form.SelectSubjectType",,ThisObject);

EndProcedure

&AtClient
Procedure SubjectList(Command)
	
	CurrentItemName = Items.List.Name;
	If Not CorrectChoice(CurrentItemName) Then
		Return;
	EndIf;
	
	ChoiceContext = "SubjectListSubjectType";
	OpenForm("DocumentJournal.Interactions.Form.SelectSubjectType",,ThisObject);
	
EndProcedure

&AtClient
Procedure AddToTabs(Command)
	
	CurrentItemName = CurrentItem.Name;
	If StrStartsWith(CurrentItemName, "List") AND Not CorrectChoice(CurrentItemName) Then
		ShowMessageBox(, NStr("ru = 'Не выбран элемент для добавления в закладки.'; en = 'Item for adding to tabs is not selected.'; pl = 'Item for adding to tabs is not selected.';de = 'Item for adding to tabs is not selected.';ro = 'Item for adding to tabs is not selected.';tr = 'Item for adding to tabs is not selected.'; es_ES = 'Item for adding to tabs is not selected.'"));
		Return;
	EndIf;
	
	ItemToAdd = Undefined;
	If StrStartsWith(CurrentItemName, "List") Then
		ItemToAdd = Items[CurrentItemName].SelectedRows;
	ElsIf CurrentItemName = "Properties" Or CurrentItemName = "Categories" Or CurrentItemName = "Folders" Then
		CurrentData = Items[CurrentItemName].CurrentData;
		If CurrentData <> Undefined Then
			ItemToAdd = New Structure("Value", CurrentData.Value);
		EndIf;
	ElsIf CurrentItemName = "NavigationPanelSubjects" Then
		CurrentData = Items.NavigationPanelSubjects.CurrentData;
		If CurrentData <> Undefined Then
			ItemToAdd = New Structure("Value", CurrentData.Topic);
		EndIf;
	Else
		CurrentData = Items[CurrentItemName].CurrentData;
		If CurrentData <> Undefined Then
			ItemToAdd = New Structure("Value,TypeDescription", CurrentData.Value, CurrentData.TypeDescription);
		EndIf;
	EndIf;
	
	If ItemToAdd = Undefined Then
		ShowMessageBox(, NStr("ru = 'Не выбран элемент для добавления в закладки.'; en = 'Item for adding to tabs is not selected.'; pl = 'Item for adding to tabs is not selected.';de = 'Item for adding to tabs is not selected.';ro = 'Item for adding to tabs is not selected.';tr = 'Item for adding to tabs is not selected.'; es_ES = 'Item for adding to tabs is not selected.'"));
		Return;
	EndIf;
	
	Result = AddToTabsServer(ItemToAdd, CurrentItemName);
	If Not Result.ItemAdded Then
		ShowMessageBox(, Result.ErrorMessageText);
		Return;
	EndIf;
	ShowUserNotification(NStr("ru = 'Добавлены в закладки:'; en = 'Added to tabs:'; pl = 'Added to tabs:';de = 'Added to tabs:';ro = 'Added to tabs:';tr = 'Added to tabs:'; es_ES = 'Added to tabs:'"),
		Result.ItemURL, Result.ItemPresentation, PictureLib.Information32);
	
EndProcedure

&AtClient
Procedure DeferReviewExecute(Command)
	
	CurrentItemName = CurrentItem.Name;
	If StrStartsWith(CurrentItemName, "List") AND Not CorrectChoice(CurrentItemName) Then
		Return;
	EndIf;
	
	ProcessingDate = CommonClient.SessionDate();
	
	AdditionalParameters = New Structure("CurrentItemName", Undefined);
	OnCloseNotifyHandler = New NotifyDescription("ProcessingDateChoiceOnCompletion", ThisObject, AdditionalParameters);
	ShowInputDate(OnCloseNotifyHandler, ProcessingDate, NStr("ru = 'Отработать после'; en = 'Process after'; pl = 'Process after';de = 'Process after';ro = 'Process after';tr = 'Process after'; es_ES = 'Process after'"), DateFractions.DateTime);
	
EndProcedure

&AtClient
Procedure DeferListReview(Command)
	
	CurrentItemName = Items.List.Name;
	If Not CorrectChoice(CurrentItemName) Then
		Return;
	EndIf;
	
	ProcessingDate = CommonClient.SessionDate();
	
	AdditionalParameters = New Structure("CurrentItemName", CurrentItemName);
	OnCloseNotifyHandler = New NotifyDescription("ProcessingDateChoiceOnCompletion", ThisObject, AdditionalParameters);
	ShowInputDate(OnCloseNotifyHandler, ProcessingDate, NStr("ru = 'Отработать после'; en = 'Process after'; pl = 'Process after';de = 'Process after';ro = 'Process after';tr = 'Process after'; es_ES = 'Process after'"), DateFractions.DateTime);

EndProcedure

&AtClient
Procedure CreateMeeting(Command)
	
	CreateNewInteraction("Meeting");
	
EndProcedure

&AtClient
Procedure CreateScheduledInteraction(Command)
	
	CreateNewInteraction("PlannedInteraction");
	
EndProcedure

&AtClient
Procedure CreatePhoneCall(Command)
	
	CreateNewInteraction("PhoneCall");
	
EndProcedure

&AtClient
Procedure CreateEmail(Command)
	
	CreateNewInteraction("OutgoingEmail");
	
EndProcedure

&AtClient
Procedure CreateSMSMessage(Command)
	
	CreateNewInteraction("SMSMessage");
	
EndProcedure

&AtClient
Procedure ApplyProcessingRules(Command)

	CurrentData = Items.Folders.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.HasEditPermission = 0 
		OR TypeOf(CurrentData.Value) = Type("CatalogRef.EmailAccounts") Then
		Return;
	EndIf;
		
	ParametersStructure = New Structure;
	ParametersStructure.Insert("Account", CurrentData.Account);
	ParametersStructure.Insert("ForEmailsInFolder", CurrentData.Value);
	
	OpenForm("Catalog.EmailProcessingRules.Form.RulesApplication", ParametersStructure);
	
EndProcedure

&AtClient
Procedure MoveToFolder(Command)
	
	CurrentItemName = CurrentItem.Name;
	If StrStartsWith(CurrentItemName, "List") AND Not CorrectChoice(CurrentItemName) Then
		Return;
	EndIf;
	
	FoldersCurrentData = Items.Folders.CurrentData;
	If FoldersCurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentItemName = "Folders" Then
		If TypeOf(FoldersCurrentData.Value) = Type("CatalogRef.EmailAccounts") 
			OR FoldersCurrentData.PredefinedFolder Then
			ShowMessageBox(, NStr("ru = 'Команда не может быть выполнена для данного объекта'; en = 'Command cannot be executed for this object'; pl = 'Command cannot be executed for this object';de = 'Command cannot be executed for this object';ro = 'Command cannot be executed for this object';tr = 'Command cannot be executed for this object'; es_ES = 'Command cannot be executed for this object'"));
			Return;
		ElsIf FoldersCurrentData.HasEditPermission = 0 Then
			ShowMessageBox(, NStr("ru = 'Недостаточно прав для изменения папок.'; en = 'Insufficient rights to change folders.'; pl = 'Insufficient rights to change folders.';de = 'Insufficient rights to change folders.';ro = 'Insufficient rights to change folders.';tr = 'Insufficient rights to change folders.'; es_ES = 'Insufficient rights to change folders.'"));
			Return;
		EndIf;
	EndIf;
	
	ChoiceContext = "MoveToFolder";
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", New Structure("Owner", FoldersCurrentData.Account));
	FormParameters.Insert("ChoiceMode", True);
	
	OpenForm("Catalog.EmailMessageFolders.ChoiceForm", FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure EditNavigationPanelValue(Command)
	
	Item = CurrentItemNavigationPanelList();
	If Item = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Item.CurrentData;
	If CurrentData <> Undefined Then
		
		DisplayedValue = Undefined;
		If CurrentData.Property("Contact") AND TypeOf(CurrentData.Contact) <> Type("CatalogRef.StringContactInteractions") Then
			DisplayedValue = CurrentData.Contact;
		ElsIf CurrentData.Property("Topic") Then
			DisplayedValue = CurrentData.Topic;
		ElsIf CurrentData.Property("Value") AND TypeOf(CurrentData.Value) <> Type("String") Then
			DisplayedValue = CurrentData.Value;
		EndIf;
		
		If DisplayedValue <> Undefined Then
			ShowValue(, DisplayedValue);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ImportantContactsOnly(Command)
	
	ImportantContactsOnly = Not ImportantContactsOnly;
	FillContactsPanel();
	
EndProcedure

&AtClient
Procedure ImportantSubjectsOnly(Command)
	
	ImportantSubjectsOnly = Not ImportantSubjectsOnly;
	FillSubjectsPanel();
	
EndProcedure

&AtClient
Procedure ActiveSubjectsOnly(Command)
	
	ShowAllActiveSubjects = Not ShowAllActiveSubjects;
	FillSubjectsPanel();
	
EndProcedure

&AtClient
Procedure DisplayReadingPane(Command)
	
	DisplayReadingPane = Not DisplayReadingPane;
	ListOnActivateRow(Items.List);
	ManageVisibilityOnSwitchNavigationPanel();
	
EndProcedure

&AtClient
Procedure Attachable_ChangeFilterStatus(Command)
	
	ChangeFilterStatusServer(Command.Name);	
	RestoreExpandedTreeNodes();
	
EndProcedure

&AtClient
Procedure Attachable_ChangeFilterInteractionType(Command)

	ChangeFilterInteractionTypeServer(Command.Name);
	RestoreExpandedTreeNodes();

EndProcedure

&AtClient
Procedure EditNavigationPanelView(Command)
	
	NavigationPanelHidden = Not NavigationPanelHidden;
	ManageVisibilityOnSwitchNavigationPanel();
	
EndProcedure

&AtClient
Procedure ForwardAsAttachment(Command)
	
	ClearMessages();
	
	If NOT CorrectChoice("List", True) Then
		Return;
	EndIf;
	
	CurrentData = Items.List.CurrentData;
	
	If CurrentData.Type = Type("DocumentRef.IncomingEmail")
		Or (CurrentData.Type = Type("DocumentRef.OutgoingEmail")
		    AND CurrentData.OutgoingEmailStatus = PredefinedValue("Enum.OutgoingEmailStatuses.Sent")) Then
		
		Base = New Structure("Base,Command",CurrentData.Ref, "ForwardAsAttachment");
		OpeningParameters = New Structure("Base", Base);
		OpenForm("Document.OutgoingEmail.Form.DocumentForm", OpeningParameters);
	
	Else
		
		MessageText = NStr("ru = 'Пересылать как вложения можно только отправленные и полученные письма.'; en = 'Only sent and received emails can be forwarded as attachments.'; pl = 'Only sent and received emails can be forwarded as attachments.';de = 'Only sent and received emails can be forwarded as attachments.';ro = 'Only sent and received emails can be forwarded as attachments.';tr = 'Only sent and received emails can be forwarded as attachments.'; es_ES = 'Only sent and received emails can be forwarded as attachments.'");
		ShowMessageBox(, MessageText); 
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	NavigationPanelSubjects.ConditionalAppearance.Items.Clear();
	ContactsNavigationPanel.ConditionalAppearance.Items.Clear();

	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.Date.Name);
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.SentReceived", Items.SentReceived.Name);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Properties.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Properties.NotReviewed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = 0;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseReviewedFlag");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Font", New Font(WindowsFonts.DefaultGUIFont, , , True, False, False, False, ));
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Folders.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Folders.NotReviewed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = 0;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseReviewedFlag");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Font", New Font(WindowsFonts.DefaultGUIFont, , , True, False, False, False, ));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Categories.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Categories.NotReviewed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = 0;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseReviewedFlag");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Font", New Font(WindowsFonts.DefaultGUIFont, , , True, False, False, False, ));

	//

	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.List.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.Reviewed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseReviewedFlag");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Font", New Font(WindowsFonts.DefaultGUIFont, , , True, False, False, False, ));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SearchString.Name);

	FIlterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FIlterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FIlterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SearchString");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;

	ItemFilter = FIlterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdvancedSearch");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("BackColor", StyleColors.FieldBackColor);
	
#Region ReviewedContacts

	Item = ContactsNavigationPanel.ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("Contact");
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("NotReviewedInteractionsCount");

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("NotReviewedInteractionsCount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("Font", New Font(WindowsFonts.DefaultGUIFont, , , True, False, False, False, ));
	
#EndRegion

#Region ReviewedSubjects

	Item = NavigationPanelSubjects.ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("Topic");
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("NotReviewedInteractionsCount");

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("NotReviewedInteractionsCount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("Font", New Font(WindowsFonts.DefaultGUIFont, , , True, False, False, False, ));

#EndRegion
	
EndProcedure

/////////////////////////////////////////////////////////////////////////////////
// Processing quick filter change.

&AtServer
Procedure ChangeFilterInteractionTypeServer(CommandName)

	InteractionType = Interactions.InteractionTypeByCommandName(CommandName, EmailOnly);
	OnChangeTypeServer();

EndProcedure

&AtServer
Procedure OnChangeStatusServer(UpdateNavigationPanel)
	
	DateForFilter = CurrentSessionDate();
	InteractionsClientServer.QuickFilterListOnChange(ThisObject, "Status", DateForFilter);
	
	CaptionPattern = NStr("ru = 'Статус: %1'; en = 'Status: %1'; pl = 'Status: %1';de = 'Status: %1';ro = 'Status: %1';tr = 'Status: %1'; es_ES = 'Status: %1'");
	StatusPresentation = Interactions.StatusesList().FindByValue(Status).Presentation;
	Items.StatusList.Title = StringFunctionsClientServer.SubstituteParametersToString(CaptionPattern, StatusPresentation);
	For Each SubmenuItem In Items.StatusList.ChildItems Do
		If SubmenuItem.Name = ("SetFilterStatus_" + Status) Then
			SubmenuItem.Check = True;
		Else
			SubmenuItem.Check = False;
		EndIf;
	EndDo;
	
	If UpdateNavigationPanel Then
		RefreshNavigationPanel();
	EndIf;

EndProcedure

&AtServer
Procedure ChangeFilterStatusServer(CommandName)
	Status = StatusByCommandName(CommandName);
	OnChangeStatusServer(True);
EndProcedure

&AtServer
Function StatusByCommandName(CommandName)
	
	FoundPosition = StrFind(CommandName, "_");
	If FoundPosition = 0 Then
		Return "All";
	EndIf;
	
	RowStatus = Right(CommandName, StrLen(CommandName) - FoundPosition);
	If Interactions.StatusesList().FindByValue(RowStatus) = Undefined Then
		Return "All";
	EndIf;
	
	Return RowStatus;
	
EndFunction

&AtServer
Procedure OnChangeEmployeeResponsibleServer(UpdateNavigationPanel)

	InteractionsClientServer.QuickFilterListOnChange(ThisObject,"EmployeeResponsible");

	If UpdateNavigationPanel Then
		RefreshNavigationPanel();
	EndIf;
	
EndProcedure

&AtServer
Procedure OnChangeTypeServer(UpdateNavigationPanel = True)
	
	Interactions.ProcessFilterByInteractionsTypeSubmenu(ThisObject);
	
	InteractionsClientServer.OnChangeFilterInteractionType(ThisObject, InteractionType);
	If UpdateNavigationPanel Then
		RefreshNavigationPanel();
	EndIf;
	
EndProcedure

/////////////////////////////////////////////////////////////////////////////////
//    Processing activation of list rows and navigation panel.

&AtClient
Procedure ProcessListRowActivation()
	
	HasUnsafeContent = False;
	EnableUnsafeContent = False;
	SetSecurityWarningVisiblity(ThisObject);
	
	ListName = "List";
	
	If CorrectChoice(ListName,True) Then
		
		If DisplayReadingPane Then
			
			PreviewPageName = Items.PagesPreview.CurrentPage.Name;
			If InteractionPreviewGeneratedFor <> Items[ListName].CurrentData.Ref Then
				DisplayInteractionPreview(Items[ListName].CurrentData.Ref, PreviewPageName);
				If PreviewPageName <> Items.PagesPreview.CurrentPage.Name Then
					Items.PagesPreview.CurrentPage = Items[PreviewPageName];
				EndIf;
			EndIf;
			
		EndIf;
		
		If AdvancedSearch Then
			FillDetailsSPFound(Items[ListName].CurrentData.Ref);
		Else
			DetailSPFound = "";
		EndIf;
		
	Else
		
		If DisplayReadingPane Then
			If Items.PagesPreview.CurrentPage <> Items.PreviewPlainTextPage Then
				Items.PagesPreview.CurrentPage = Items.PreviewPlainTextPage;
			EndIf;
			Preview = "";
			HTMLPreview = "<HTML><BODY></BODY></HTML>";
			InteractionPreviewGeneratedFor = Undefined;
		EndIf;
		DetailSPFound = "";
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessNavigationPanelRowActivation();
	
	If NavigationPanelHidden Then
		Return;
	EndIf;
	
	If Items.NavigationPanelPages.CurrentPage = Items.ContactPage Then
		CurrentData = Items.NavigationPanelContacts.CurrentData;
		If CurrentData <> Undefined Then
			
			If CurrentData.Contact = ValueSetAfterFillNavigationPanel Then
				ValueSetAfterFillNavigationPanel = Undefined;
				Return;
			EndIf;
			
			ChangeFilterList("Contacts",New Structure("Value,TypeDescription",
			                    CurrentData.Contact, Undefined));
			SaveCurrentActiveValueInSettings("Contacts",CurrentData.Contact);
			
		EndIf;
	ElsIf Items.NavigationPanelPages.CurrentPage = Items.SubjectPage Then
		CurrentData = Items.NavigationPanelSubjects.CurrentData;
		If CurrentData <> Undefined Then
			
			If CurrentData.Topic = ValueSetAfterFillNavigationPanel Then
				ValueSetAfterFillNavigationPanel = Undefined;
				Return;
			EndIf;
			
			ChangeFilterList("Subjects",New Structure("Value,TypeDescription",
			                    CurrentData.Topic, Undefined));
			SaveCurrentActiveValueInSettings("Subjects", CurrentData.Topic);
		Else
			ChangeFilterList("Subjects",New Structure("Value,TypeDescription",
			                    Undefined, Undefined));
		EndIf;
	ElsIf Items.NavigationPanelPages.CurrentPage = Items.FoldersPage Then
		CurrentData = Items.Folders.CurrentData;
		If CurrentData <> Undefined Then
			ChangeFilterList("Folders",New Structure("Value,Account",
			                    CurrentData.Value, CurrentData.Account));
			SaveCurrentActiveValueInSettings("Folders", CurrentData.Value);
		EndIf;
	ElsIf Items.NavigationPanelPages.CurrentPage = Items.TabsPage Then
		CurrentData = Items.Tabs.CurrentData;
		If CurrentData <> Undefined AND NOT CurrentData.IsFolder Then
			ChangeFilterList("Tabs",New Structure("Value", CurrentData.Ref));
			SaveCurrentActiveValueInSettings("Tabs", CurrentData.Ref);
		Else
			CreateNavigationPanelFilterGroup();
		EndIf;
	ElsIf Items.NavigationPanelPages.CurrentPage = Items.PropertiesPage Then
		CurrentData = Items.Properties.CurrentData;
		If CurrentData <> Undefined Then
			ChangeFilterList("Properties",New Structure("Value", CurrentData.Value));
			SaveCurrentActiveValueInSettings("Properties", CurrentData.Value);
		EndIf;
	ElsIf Items.NavigationPanelPages.CurrentPage = Items.CategoriesPage Then
		CurrentData = Items.Categories.CurrentData;
		If CurrentData <> Undefined Then
			ChangeFilterList("Categories",New Structure("Value", CurrentData.Value));
			SaveCurrentActiveValueInSettings("Categories", CurrentData.Value);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure SaveCurrentActiveValueInSettings(TreeName, Value)

	If TreeName = "Properties" Then
		TreeName  = "Properties_" + String(CurrentPropertyOfNavigationPanel);
	EndIf;
	
	FoundRows =  NavigationPanelTreesSettings.FindRows(New Structure("TreeName",TreeName));
	If FoundRows.Count() = 1 Then
		SettingsTreeRow = FoundRows[0];
	ElsIf FoundRows.Count() > 1 Then
		SettingsTreeRow = FoundRows[0];
		For Ind = 1 To FoundRows.Count()-1 Do
			NavigationPanelTreesSettings.Delete(FoundRows[Ind]);
		EndDo;
	Else
		SettingsTreeRow = NavigationPanelTreesSettings.Add();
		SettingsTreeRow.TreeName = TreeName;
	EndIf;
	
	SettingsTreeRow.CurrentValue = Value;

EndProcedure 

&AtServer
Function CreateNavigationPanelFilterGroup()

	Return CommonClientServer.CreateFilterItemGroup(
	                    InteractionsClientServer.DynamicListFilter(List).Items,
	                    "FIlterNavigationPanel",
	                    DataCompositionFilterItemsGroupType.AndGroup);

EndFunction

&AtServer
Procedure ChangeFilterList(TableName, DataForProcessing);
	
	If TableName = "Subjects" OR TableName = "Contacts" Then
		DynamicListQueryText = Interactions.InteractionsListQueryText(DataForProcessing.Value);
	Else
		DynamicListQueryText = Interactions.InteractionsListQueryText();
	EndIf;
	
	ListPropertiesStructure              = Common.DynamicListPropertiesStructure();
	ListPropertiesStructure.QueryText = DynamicListQueryText;
		
	Common.SetDynamicListProperties(Items.List, ListPropertiesStructure);
	
	FilterGroup = CreateNavigationPanelFilterGroup();
	
	If DataForProcessing.Value = NStr("ru = 'Все'; en = 'All'; pl = 'All';de = 'All';ro = 'All';tr = 'All'; es_ES = 'All'") Then
		
		InteractionsClientServer.DynamicListFilter(List).Items.Delete(FilterGroup);
		Return;
		
	EndIf;
	
	CaptionPattern = "%1 (%2)";
	
	If TableName = "Subjects" Then
		
		FieldName                    = "Topic";
		FilterItemComparisonType = DataCompositionComparisonType.Equal;
		RightValue             = DataForProcessing.Value;
		FilterName = NStr("ru = 'Предмет'; en = 'Subject'; pl = 'Subject';de = 'Subject';ro = 'Subject';tr = 'Subject'; es_ES = 'Subject'");
		FilterValue = DataForProcessing.Value;
		
	ElsIf TableName = "Folders" Then
		
			FieldName                    = "Type";
			FilterItemComparisonType = DataCompositionComparisonType.InList;
			TypesList = New ValueList;
			TypesList.Add(Type("DocumentRef.IncomingEmail"));
			TypesList.Add(Type("DocumentRef.OutgoingEmail"));
			RightValue             = TypesList;
			
			CommonClientServer.AddCompositionItem(FilterGroup, FieldName,
			                                                       FilterItemComparisonType, RightValue);
			
			FilterValue = DataForProcessing.Value;
			
			If TypeOf(DataForProcessing.Value) = Type("CatalogRef.EmailMessageFolders") Then
				
				FieldName                    = "Folder";
				FilterItemComparisonType = DataCompositionComparisonType.Equal;
				RightValue             = DataForProcessing.Value;
				FilterName = NStr("ru = 'Папка'; en = 'Folder'; pl = 'Folder';de = 'Folder';ro = 'Folder';tr = 'Folder'; es_ES = 'Folder'");
				
			Else
				
				FieldName                    = "Account";
				FilterItemComparisonType = DataCompositionComparisonType.Equal;
				RightValue             = DataForProcessing.Value;
				FilterName = NStr("ru = 'Учетная запись'; en = 'Account'; pl = 'Account';de = 'Account';ro = 'Account';tr = 'Account'; es_ES = 'Account'");
				
			EndIf;
		
	ElsIf TableName = "Contacts" Then
		
		FieldName                    = "Contact";
		FilterItemComparisonType = DataCompositionComparisonType.Equal;
		RightValue             = DataForProcessing.Value;
		FilterName = NStr("ru = 'Контакт'; en = 'Contact'; pl = 'Contact';de = 'Contact';ro = 'Contact';tr = 'Contact'; es_ES = 'Contact'");
		FilterValue = DataForProcessing.Value;
		
	ElsIf TableName = "Properties" Then
		
		FieldName = "Ref.[" + CurrentPropertyOfNavigationPanel.Description + "]";
		FilterName = CurrentPropertyOfNavigationPanel.Description;
		If TypeOf(DataForProcessing.Value) = Type("String") 
			AND DataForProcessing.Value = NStr("ru = 'Не указан'; en = 'Not specified'; pl = 'Not specified';de = 'Not specified';ro = 'Not specified';tr = 'Not specified'; es_ES = 'Not specified'") Then
			
			FilterItemComparisonType = DataCompositionComparisonType.NotFilled;
			RightValue             = "";
			FilterValue = NStr("ru = 'Не указан'; en = 'Not specified'; pl = 'Not specified';de = 'Not specified';ro = 'Not specified';tr = 'Not specified'; es_ES = 'Not specified'");
			
		Else
			
			FilterItemComparisonType = DataCompositionComparisonType.Equal;
			RightValue             = DataForProcessing.Value;
			FilterValue = DataForProcessing.Value;
			
		EndIf;
		
	ElsIf TableName = "Categories" Then
		
		FieldName =  "Ref.[" + String(DataForProcessing.Value) + "]";
		FilterItemComparisonType = DataCompositionComparisonType.Equal;
		RightValue             = True;
		FilterName      = NStr("ru = 'Категория'; en = 'Category'; pl = 'Category';de = 'Category';ro = 'Category';tr = 'Category'; es_ES = 'Category'");
		FilterValue = String(DataForProcessing.Value);
		
	ElsIf TableName = "Tabs" Then
		
		CompositionSetup = DataForProcessing.Value.SettingsComposer.Get();
		If CompositionSetup = Undefined Then
			Return;
		EndIf;
		CompositionSchema = DocumentJournals.Interactions.GetTemplate("SchemaInteractionsFilter");
		SchemaURL = PutToTempStorage(CompositionSchema ,UUID);
		SettingsComposer = New DataCompositionSettingsComposer;
		SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(SchemaURL));
		
		SettingsComposer.LoadSettings(CompositionSetup);
		SettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
		
		CopyFilter(FilterGroup,SettingsComposer.Settings.Filter);
		NavigationPanelTitle   = StringFunctionsClientServer.SubstituteParametersToString(CaptionPattern, NStr("ru = 'Закладка'; en = 'Tab'; pl = 'Tab';de = 'Tab';ro = 'Tab';tr = 'Tab'; es_ES = 'Tab'"), DataForProcessing.Value);
		
		Return;
		
	Else
		
		NavigationPanelTitle = "";
		Return;
		
	EndIf;
	
	NavigationPanelTitleTooltip = StringFunctionsClientServer.SubstituteParametersToString(CaptionPattern, FilterValue, FilterName);
	NavigationPanelTitle = FilterValue;
	If StrLen(NavigationPanelTitle) > 30 Then
		NavigationPanelTitle = Left(NavigationPanelTitle, 27) + "...";
	EndIf;
	CommonClientServer.AddCompositionItem(FilterGroup ,FieldName, 
	                                                       FilterItemComparisonType, RightValue);
	
EndProcedure

&AtServer
Procedure DisplayInteractionPreview(InteractionsDocumentRef, CurrentPageName)
	
	If TypeOf(InteractionsDocumentRef) = Type("DocumentRef.IncomingEmail") Then
		
		CurrentPageName = Items.HTMLPreviewPage.Name;
		HTMLPreview = Interactions.GenerateHTMLTextForIncomingEmail(InteractionsDocumentRef, False, False, Not EnableUnsafeContent, HasUnsafeContent);
		Preview = "";
		
		
	ElsIf TypeOf(InteractionsDocumentRef) = Type("DocumentRef.OutgoingEmail") Then
		
		CurrentPageName = Items.HTMLPreviewPage.Name;
		HTMLPreview = Interactions.GenerateHTMLTextForOutgoingEmail(InteractionsDocumentRef, False, False, Not EnableUnsafeContent, HasUnsafeContent);
		Preview = "";
		
	Else
		HasUnsafeContent = False;
		
		CurrentPageName = Items.PreviewPlainTextPage.Name;
		If TypeOf(InteractionsDocumentRef) = Type("DocumentRef.SMSMessage") Then
			Preview = InteractionsDocumentRef.MessageText;
		Else
			Preview = InteractionsDocumentRef.Details;
		EndIf;
		HTMLPreview = "<HTML><BODY></BODY></HTML>";
		
	EndIf;
	
	If StrFind(HTMLPreview,"<BODY>") = 0 Then
		HTMLPreview = "<HTML><BODY>" + HTMLPreview + "</BODY></HTML>";
	EndIf;
	
	InteractionPreviewGeneratedFor = InteractionsDocumentRef;
	SetSecurityWarningVisiblity(ThisObject);
	
EndProcedure

/////////////////////////////////////////////////////////////////////////////////
//    Switching and filling navigation panels.

&AtServer
Procedure SwitchNavigationPanelServer(CommandName)
	
	If CommandName = "SetNavigationMethodByContact" Then
		FillContactsPanel();
		Items.NavigationPanelPages.CurrentPage = Items.ContactPage;
	ElsIf CommandName = "SetNavigationMethodBySubject" Then
		FillSubjectsPanel();
		Items.NavigationPanelPages.CurrentPage = Items.SubjectPage;
	ElsIf CommandName = "SetNavigationMethodByFolders" Then
		FillFoldersTree();
		Items.NavigationPanelPages.CurrentPage = Items.FoldersPage;
	ElsIf CommandName = "SetNavigationMethodByTabs" Then
		Items.NavigationPanelPages.CurrentPage = Items.TabsPage;
	ElsIf CommandName = "SetOptionByCategories" Then
		FillCategoriesTable();
		Items.NavigationPanelPages.CurrentPage = Items.CategoriesPage;
	ElsIf StrFind(CommandName,"SetOptionByProperty") > 0 Then
		FillPropertiesTree(CommandName);
		Items.NavigationPanelPages.CurrentPage = Items.PropertiesPage;
	EndIf;
	
	NavigationPanelHidden = False;
	CurrentNavigationPanelName = Items.NavigationPanelPages.CurrentPage.Name;
	ManageVisibilityOnSwitchNavigationPanel();
	AfterFillNavigationPanel();

EndProcedure

&AtServer
Procedure ManageVisibilityOnSwitchNavigationPanel()
	
	CurrentNavigationPanelPage = Items.NavigationPanelPages.CurrentPage;
	IsFolders    = (CurrentNavigationPanelPage = Items.FoldersPage);
	
	Items.ListContextMenuMoveToFolder.Visible          = IsFolders;
	Items.SentReceived.Visible                            = IsFolders;
	Items.Size.Visible                                        = IsFolders;
	Items.CreateEmailSpecialButtonList.Visible = IsFolders OR EmailOnly;
	Items.ReplyList.Visible                                = IsFolders OR EmailOnly;
	Items.ReplyToAllList.Visible                            = IsFolders OR EmailOnly;
	Items.ForwardList.Visible                               = IsFolders OR EmailOnly;
	Items.SendReceiveMailList.Visible                  = (IsFolders OR EmailOnly) AND FileInfobase;

	Items.Date.Visible                              = NOT IsFolders;
	Items.CreateGroup.Visible                     = NOT IsFolders AND NOT EmailOnly;
	Items.ListContextMenuCopy.Visible  = Not IsFolders AND Not EmailOnly;
	Items.Copy.Visible                       = Not IsFolders AND Not EmailOnly;
	
	Items.PagesPreview.Visible                   = DisplayReadingPane;
	Items.DisplayReadingPaneList.Check            = DisplayReadingPane;
	
	Items.NavigationPanelGroup.Visible                  = NOT NavigationPanelHidden;
	
	ChangeNavigationPanelDisplayCommand = Commands.Find("EditNavigationPanelView");
	If NavigationPanelHidden Then
		Items.EditNavigationPanelView.Picture = PictureLib.RightArrow;
		ChangeNavigationPanelDisplayCommand.ToolTip = NStr("ru = 'Показать панель навигации'; en = 'Show navigation panel'; pl = 'Show navigation panel';de = 'Show navigation panel';ro = 'Show navigation panel';tr = 'Show navigation panel'; es_ES = 'Show navigation panel'");
		ChangeNavigationPanelDisplayCommand.Title = NStr("ru = 'Показать панель навигации'; en = 'Show navigation panel'; pl = 'Show navigation panel';de = 'Show navigation panel';ro = 'Show navigation panel';tr = 'Show navigation panel'; es_ES = 'Show navigation panel'");
	Else
		Items.EditNavigationPanelView.Picture = PictureLib.LeftArrow;
		ChangeNavigationPanelDisplayCommand.ToolTip = NStr("ru = 'Скрыть панель навигации'; en = 'Hide navigation panel'; pl = 'Hide navigation panel';de = 'Hide navigation panel';ro = 'Hide navigation panel';tr = 'Hide navigation panel'; es_ES = 'Hide navigation panel'");
		ChangeNavigationPanelDisplayCommand.Title = NStr("ru = 'Скрыть панель навигации'; en = 'Hide navigation panel'; pl = 'Hide navigation panel';de = 'Hide navigation panel';ro = 'Hide navigation panel';tr = 'Hide navigation panel'; es_ES = 'Hide navigation panel'");
	EndIf;
	
	SetNavigationPanelViewTitle();
	
EndProcedure

&AtServer
Procedure SetNavigationPanelViewTitle(FilterValue = Undefined)
	
	For each SubordinateItem In Items.SelectNavigationOption.ChildItems Do
		If TypeOf(SubordinateItem) = Type("FormButton") Then
			SubordinateItem.Check = False;
		EndIf;
	EndDo;
	
	If NavigationPanelHidden Then
		Items.SelectNavigationOption.Title = ?(IsBlankString(NavigationPanelTitle), 
		                                              NStr("ru = 'Не указан'; en = 'Not specified'; pl = 'Not specified';de = 'Not specified';ro = 'Not specified';tr = 'Not specified'; es_ES = 'Not specified'"),
		                                              NavigationPanelTitle);
		Items.SelectNavigationOption.ToolTip = ?(IsBlankString(NavigationPanelTitle),
		                                              NStr("ru = 'Не указан'; en = 'Not specified'; pl = 'Not specified';de = 'Not specified';ro = 'Not specified';tr = 'Not specified'; es_ES = 'Not specified'") + NavigationPanelTitleTooltip,
		                                              NavigationPanelTitleTooltip);
	Else
	
		If Items.NavigationPanelPages.CurrentPage = Items.PropertiesPage Then
			Items.SelectNavigationOption.Title = NStr("ru = 'По'; en = 'To'; pl = 'To';de = 'To';ro = 'To';tr = 'To'; es_ES = 'To'") + " " + CurrentPropertyPresentation;
			FoundRows = AddlAttributesPropertiesTable.FindRows(New Structure("AddlAttributeInfo",
			                                                          CurrentPropertyOfNavigationPanel));
			If FoundRows.Count() > 0 Then
				Items["AdditionalButtonPropertyNavigationOptionSelection_" + String(FoundRows[0].SequenceNumber)].Check = True;
			EndIf;

		ElsIf Items.NavigationPanelPages.CurrentPage = Items.TabsPage Then
			
			Items.SelectNavigationOption.Title = NStr("ru = 'По закладкам'; en = 'By bookmarks'; pl = 'By bookmarks';de = 'By bookmarks';ro = 'By bookmarks';tr = 'By bookmarks'; es_ES = 'By bookmarks'");
			Items.SetNavigationMethodByTabs.Check = True;
			
		ElsIf Items.NavigationPanelPages.CurrentPage = Items.SubjectPage Then
			
			Items.SelectNavigationOption.Title = NStr("ru = 'По предметам'; en = 'By subjects'; pl = 'By subjects';de = 'By subjects';ro = 'By subjects';tr = 'By subjects'; es_ES = 'By subjects'");
			Items.SetNavigationMethodBySubject.Check = True;
			
		ElsIf Items.NavigationPanelPages.CurrentPage = Items.ContactPage Then
			
			Items.SelectNavigationOption.Title = NStr("ru = 'По контактам'; en = 'By contacts'; pl = 'By contacts';de = 'By contacts';ro = 'By contacts';tr = 'By contacts'; es_ES = 'By contacts'");
			Items.SetNavigationMethodByContact.Check = True;
			
		ElsIf Items.NavigationPanelPages.CurrentPage = Items.FoldersPage Then
			
			Items.SelectNavigationOption.Title = NStr("ru = 'По папкам'; en = 'By folders'; pl = 'By folders';de = 'By folders';ro = 'By folders';tr = 'By folders'; es_ES = 'By folders'");
			Items.SetNavigationMethodByFolders.Check = True;
			
		ElsIf Items.NavigationPanelPages.CurrentPage = Items.CategoriesPage Then
			
			Items.SelectNavigationOption.Title = NStr("ru = 'По категориям'; en = 'By categories'; pl = 'By categories';de = 'By categories';ro = 'By categories';tr = 'By categories'; es_ES = 'By categories'");
			Items["AdditionalButtonCategoryNavigationOptionSelection"].Check = True;
			
		EndIf;
		
		Items.SelectNavigationOption.ToolTip = NStr("ru = 'Выберите варианта навигации'; en = 'Select navigation option'; pl = 'Select navigation option';de = 'Select navigation option';ro = 'Select navigation option';tr = 'Select navigation option'; es_ES = 'Select navigation option'");
		
	EndIf;
	
EndProcedure

&AtServer
Procedure AddRowAll(FormDataCollection, PictureNumber = 0)
	
	If TypeOf(FormDataCollection) = Type("FormDataTree") Then
		NewRow = FormDataCollection.GetItems().Add();
	Else
		NewRow = FormDataCollection.Add();
	EndIf;
	
	NewRow.Value = NStr("ru = 'Все'; en = 'All'; pl = 'All';de = 'All';ro = 'All';tr = 'All'; es_ES = 'All'");
	NewRow.Presentation = NStr("ru = 'Все'; en = 'All'; pl = 'All';de = 'All';ro = 'All';tr = 'All'; es_ES = 'All'");
	NewRow.PictureNumber = PictureNumber;
	
EndProcedure

&AtServer
Procedure FillPropertiesTree(CommandName = "")
	
	Properties.GetItems().Clear();
	
	If Not IsBlankString(CommandName) Then
		
		PropertyNumberInTable = Number(Right(CommandName, 1));
		
		FoundRows = AddlAttributesPropertiesTable.FindRows(New Structure("SequenceNumber", PropertyNumberInTable));
		CurrentPropertyOfNavigationPanel                   = FoundRows[0].AddlAttributeInfo;
		CurrentPropertyOfNavigationPanelIsAttribute = FoundRows[0].IsAttribute;
		CurrentPropertyPresentation                    = FoundRows[0].Presentation;
		
	EndIf;
	
	Items.PropertiesPresentation.Title  = CurrentPropertyPresentation;
	
	Query = New Query;
	ConditionText = "";
	
	ConditionTextByListFilter =  GetQueryTextByListFilter(Query);
	If Not IsBlankString(ConditionTextByListFilter) Then
		Query.Text = ConditionTextByListFilter;
		
		ConditionText = " WHERE
			|(DocumentInteractions.Ref IN
			|	(SELECT DISTINCT
			|		ListFilter.Ref
			|	FROM
			|		ListFilter AS ListFilter))";
	
	EndIf;
	
	If CurrentPropertyOfNavigationPanelIsAttribute Then
		Query.Text = Query.Text + "
		|SELECT ALLOWED
		|	NestedQuery.Value AS Value,
		|	SUM(NestedQuery.NotReviewed) AS NotReviewed,
		|	1 AS PictureNumber,
		|	PRESENTATION(NestedQuery.Value) AS Presentation
		|FROM
		|	(SELECT
		|		DocumentInteractions.Ref AS Ref,
		|		ISNULL(DocumentInteractionsAdditionalAttributes.Value, &NotSpecified) AS Value,
		|		CASE
		|			WHEN InteractionsFolderSubjects.Reviewed
		|				THEN 0
		|			ELSE 1
		|		END AS NotReviewed
		|	FROM
		|		Document.OutgoingEmail AS DocumentInteractions
		|		LEFT JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
		|			ON DocumentInteractions.Ref = InteractionsFolderSubjects.Interaction
		|			LEFT JOIN Document.OutgoingEmail.AdditionalAttributes AS DocumentInteractionsAdditionalAttributes
		|			ON (DocumentInteractionsAdditionalAttributes.Ref = DocumentInteractions.Ref)
		|				AND (DocumentInteractionsAdditionalAttributes.Property = &Property)
		|		" + ConditionText + "
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		DocumentInteractions.Ref,
		|		ISNULL(DocumentInteractionsAdditionalAttributes.Value, &NotSpecified),
		|		CASE
		|			WHEN InteractionsFolderSubjects.Reviewed
		|				THEN 0
		|			ELSE 1
		|		END
		|	FROM
		|		Document.IncomingEmail AS DocumentInteractions
		|		LEFT JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
		|			ON DocumentInteractions.Ref = InteractionsFolderSubjects.Interaction
		|			LEFT JOIN Document.IncomingEmail.AdditionalAttributes AS DocumentInteractionsAdditionalAttributes
		|			ON (DocumentInteractionsAdditionalAttributes.Ref = DocumentInteractions.Ref)
		|				AND (DocumentInteractionsAdditionalAttributes.Property = &Property)
		|		" + ConditionText + "
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		DocumentInteractions.Ref,
		|		ISNULL(DocumentInteractionsAdditionalAttributes.Value, &NotSpecified),
		|		CASE
		|			WHEN InteractionsFolderSubjects.Reviewed
		|				THEN 0
		|			ELSE 1
		|		END
		|	FROM
		|		Document.Meeting AS DocumentInteractions
		|		LEFT JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
		|			ON DocumentInteractions.Ref = InteractionsFolderSubjects.Interaction
		|			LEFT JOIN Document.Meeting.AdditionalAttributes AS DocumentInteractionsAdditionalAttributes
		|			ON (DocumentInteractionsAdditionalAttributes.Ref = DocumentInteractions.Ref)
		|				AND (DocumentInteractionsAdditionalAttributes.Property = &Property)
		|		" + ConditionText + "
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		DocumentInteractions.Ref,
		|		ISNULL(DocumentInteractionsAdditionalAttributes.Value, &NotSpecified),
		|		CASE
		|			WHEN InteractionsFolderSubjects.Reviewed
		|				THEN 0
		|			ELSE 1
		|		END
		|	FROM
		|		Document.PhoneCall AS DocumentInteractions
		|		LEFT JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
		|			ON DocumentInteractions.Ref = InteractionsFolderSubjects.Interaction
		|			LEFT JOIN Document.SMSMessage.AdditionalAttributes AS DocumentInteractionsAdditionalAttributes
		|			ON (DocumentInteractionsAdditionalAttributes.Ref = DocumentInteractions.Ref)
		|				AND (DocumentInteractionsAdditionalAttributes.Property = &Property)
		|		" + ConditionText + "
		|
		|	UNION ALL
		|	
		|	SELECT
		|		DocumentInteractions.Ref,
		|		ISNULL(DocumentInteractionsAdditionalAttributes.Value, &NotSpecified),
		|		CASE
		|			WHEN InteractionsFolderSubjects.Reviewed
		|				THEN 0
		|			ELSE 1
		|		END
		|	FROM
		|		Document.SMSMessage AS DocumentInteractions
		|		LEFT JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
		|			ON DocumentInteractions.Ref = InteractionsFolderSubjects.Interaction
		|			LEFT JOIN Document.SMSMessage.AdditionalAttributes AS DocumentInteractionsAdditionalAttributes
		|			ON (DocumentInteractionsAdditionalAttributes.Ref = DocumentInteractions.Ref)
		|				AND (DocumentInteractionsAdditionalAttributes.Property = &Property)
		|		" + ConditionText + "
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		DocumentInteractions.Ref,
		|		ISNULL(DocumentInteractionsAdditionalAttributes.Value, &NotSpecified),
		|		CASE
		|			WHEN InteractionsFolderSubjects.Reviewed
		|				THEN 0
		|			ELSE 1
		|		END
		|	FROM
		|		Document.PlannedInteraction AS DocumentInteractions
		|		LEFT JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
		|			ON DocumentInteractions.Ref = InteractionsFolderSubjects.Interaction
		|			LEFT JOIN Document.PlannedInteraction.AdditionalAttributes AS DocumentInteractionsAdditionalAttributes
		|			ON (DocumentInteractionsAdditionalAttributes.Ref = DocumentInteractions.Ref)
		|				AND (DocumentInteractionsAdditionalAttributes.Property = &Property)
		|		" + ConditionText + " ) AS NestedQuery
		|
		|GROUP BY
		|	NestedQuery.Value
		|
		|ORDER BY
		|Value
		|
		|TOTALS BY
		|Value HIERARCHY";
		
	Else
		
		Query.Text = Query.Text + "
		|SELECT ALLOWED
		|	NestedQuery.Value,
		|	SUM(NestedQuery.NotReviewed) AS NotReviewed,
		|	1 AS PictureNumber,
		|	PRESENTATION(NestedQuery.Value) AS Presentation
		|FROM
		|	(SELECT
		|		DocumentInteractions.Ref AS Ref,
		|		CASE
		|			WHEN InteractionsFolderSubjects.Reviewed
		|				THEN 0
		|			ELSE 1
		|		END AS NotReviewed,
		|		ISNULL(AdditionalInfo.Value, &NotSpecified) AS Value
		|	FROM
		|		DocumentJournal.Interactions AS DocumentInteractions
		|		LEFT JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
		|			ON DocumentInteractions.Ref = InteractionsFolderSubjects.Interaction
		|			LEFT JOIN InformationRegister.AdditionalInfo AS AdditionalInfo
		|			ON DocumentInteractions.Ref = AdditionalInfo.Object
		|				AND (AdditionalInfo.Property = &Property)
		|		" + ConditionText + " ) AS NestedQuery
		|
		|GROUP BY
		|	NestedQuery.Value
		|
		|ORDER BY
		|Value
		|
		|TOTALS BY
		|Value HIERARCHY";
		
	EndIf;
	
	Query.SetParameter("Property",CurrentPropertyOfNavigationPanel);
	Query.SetParameter("NotSpecified", NStr("ru = 'Не указан'; en = 'Not specified'; pl = 'Not specified';de = 'Not specified';ro = 'Not specified';tr = 'Not specified'; es_ES = 'Not specified'"));
	
	Result = Query.Execute();
	Tree = Result.Unload(QueryResultIteration.ByGroupsWithHierarchy);
	
	RowsFirstLevel = Properties.GetItems();
	
	For Each Row In Tree.Rows Do
		PropertyRow =  RowsFirstLevel.Add();
		FillPropertyValues(PropertyRow, Row);
		PropertyRow.PictureNumber = ?(TypeOf(PropertyRow.Value) = Type("String"),0,1);
		PropertyRow.Presentation = String(PropertyRow.Value) 
		                               + ?(Row.NotReviewed = 0 Or Not UseReviewedFlag,
		                               "", " (" + String(Row.NotReviewed) + ")");
		AddRowsToNavigationTree(Row, PropertyRow, True, 1);
	EndDo;
	
	AddRowAll(Properties, 2);
	
EndProcedure

&AtServer
Procedure FillSubjectsPanel()
	
	ListParameters = Common.DynamicListPropertiesStructure();
	
	FilterDestination = NavigationPanelSubjects.SettingsComposer.FixedSettings.Filter;
	FilterDestination.Items.Clear();
	
	If ImportantSubjectsOnly Then
		
		Query = New Query;
		QueryTextByFilter = GetQueryTextByListFilter(Query);
		StringToSearchBy = Right(QueryTextByFilter, StrLen(QueryTextByFilter) -  StrFind(QueryTextByFilter,"WHERE") + 1);
		ConditionStringsArray = StrSplit(StringToSearchBy, Chars.LF, False);
		ConditionsTextByDocumentJournal = "";
		ConditionsTextByRegister          = "";
		Ind = 1;
		
		For Each ConditionString In ConditionStringsArray Do
			ConditionString = StrReplace(ConditionString,"&R","&Par");
			If Ind = 2 Then
				ConditionString = " AND " + ConditionString;
			EndIf;
			If StrFind(ConditionString, "InteractionDocumentsLog") Then
				ConditionsTextByDocumentJournal = ConditionsTextByDocumentJournal + ConditionString + Chars.LF;
			ElsIf StrFind(ConditionString, "InteractionsSubjects") Then
				If IsBlankString(ConditionsTextByRegister) Then
					ConditionString = Right(ConditionString, StrLen(ConditionString) - 3);
				EndIf;
				ConditionsTextByRegister = ConditionsTextByRegister + ConditionString + Chars.LF;
			EndIf;
			
			Ind = Ind + 1;
		EndDo;
		
		If Not IsBlankString(ConditionsTextByRegister) Then
			ConditionsTextByRegister = "WHERE" + " " + ConditionsTextByRegister
		EndIf;
		
		DynamicListQueryText = "
		|SELECT
		|	InteractionsSubjectsStates.Topic,
		|	InteractionsSubjectsStates.NotReviewedInteractionsCount,
		|	InteractionsSubjectsStates.LastInteractionDate,
		|	InteractionsSubjectsStates.IsActive AS IsActive,
		|	VALUETYPE(InteractionsSubjectsStates.Topic) AS SubjectType
		|FROM
		|	InformationRegister.InteractionsSubjectsStates AS InteractionsSubjectsStates
		|WHERE
		|	TRUE IN
		|			(SELECT TOP 1
		|				TRUE
		|			FROM
		|				InformationRegister.InteractionsFolderSubjects AS InteractionsSubjects
		|					INNER JOIN DocumentJournal.Interactions AS InteractionDocumentsLog
		|					ON InteractionsSubjects.Topic = InteractionsSubjectsStates.Topic
		|							AND InteractionsSubjects.Interaction = InteractionDocumentsLog.Ref
		|							%DocumentJournalConditionText%
		|			%FolderRegisterConnectionText%)";
		
		DynamicListQueryText = StrReplace(DynamicListQueryText, "%DocumentJournalConditionText%", ConditionsTextByDocumentJournal);
		DynamicListQueryText = StrReplace(DynamicListQueryText, "%FolderRegisterConnectionText%", ConditionsTextByRegister);
		
		ListParameters.QueryText = DynamicListQueryText;
		Common.SetDynamicListProperties(Items.NavigationPanelSubjects, ListParameters);
		
		For each QueryParameter In Query.Parameters Do
			If StrStartsWith(QueryParameter.Key, "R") Then
				ParameterName = "Par" + Right(QueryParameter.Key, StrLen(QueryParameter.Key)-1);
			Else
				ParameterName = QueryParameter.Key;
			EndIf;
			CommonClientServer.SetDynamicListParameter(NavigationPanelSubjects, ParameterName, QueryParameter.Value);
		EndDo;
		
	Else
		
		DynamicListQueryText = "
		|SELECT
		|	InteractionsSubjectsStates.Topic,
		|	InteractionsSubjectsStates.NotReviewedInteractionsCount,
		|	InteractionsSubjectsStates.LastInteractionDate,
		|	InteractionsSubjectsStates.IsActive AS IsActive,
		|	VALUETYPE(InteractionsSubjectsStates.Topic) AS SubjectType
		|FROM
		|	InformationRegister.InteractionsSubjectsStates AS InteractionsSubjectsStates
		|WHERE
		|	TRUE IN
		|			(SELECT TOP 1
		|				TRUE
		|			FROM
		|				InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
		|					INNER JOIN DocumentJournal.Interactions AS InteractionDocumentsLog
		|					ON InteractionsFolderSubjects.Topic = InteractionsSubjectsStates.Topic
		|							AND InteractionsFolderSubjects.Interaction = InteractionDocumentsLog.Ref)";
		
		ListParameters.QueryText = DynamicListQueryText;
		Common.SetDynamicListProperties(Items.NavigationPanelSubjects, ListParameters);
		
	EndIf;
	
	If ShowAllActiveSubjects Then
		CommonClientServer.SetFilterItem(FilterDestination,"IsActive", True,DataCompositionComparisonType.Equal);
	EndIf;
	
	Items.SubjectsNavigationPanelContextMenuImportantObjectsOnly.Check = ImportantSubjectsOnly;
	Items.SubjectsNavigationPanelContextMenuActiveSubjectsOnly.Check = ShowAllActiveSubjects;

EndProcedure

&AtServer
Procedure FillCategoriesTable()
	
	Categories.Clear();

	Query = New Query;
	ConditionTextAttributes = "";
	ConditionTextInfo  = "";
	
	ConditionTextByListFilter = GetQueryTextByListFilter(Query);
	If Not IsBlankString(ConditionTextByListFilter) Then
		Query.Text = ConditionTextByListFilter;
		
		ConditionTextAttributes = " AND
			|InteractionAdditionalAttributes.Ref IN
			|	(SELECT DISTINCT
			|		ListFilter.Ref
			|	FROM
			|		ListFilter AS ListFilter)";
		
		ConditionTextInfo = " AND
			|AdditionalInfo.Object IN
			|	(SELECT DISTINCT
			|		ListFilter.Ref
			|	FROM
			|		ListFilter AS ListFilter)";
	
	EndIf;
		
	Query.Text = Query.Text + "
	|SELECT ALLOWED
	|	BooleanProperties.AddlAttributeInfo AS Property,
	|	BooleanProperties.IsAttribute
	|INTO BooleanProperties
	|FROM
	|	&BooleanProperties AS BooleanProperties
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	PRESENTATION(NestedQuery.Property) AS Presentation,
	|	NestedQuery.Property AS Value,
	|	SUM(NestedQuery.NotReviewed) AS NotReviewed
	|FROM
	|	(SELECT
	|		InteractionAdditionalAttributes.Property AS Property,
	|		SUM(CASE
	|				WHEN InteractionsFolderSubjects.Reviewed
	|					THEN 0
	|				ELSE 1
	|			END) AS NotReviewed
	|	FROM
	|		Document.Meeting.AdditionalAttributes AS InteractionAdditionalAttributes
	|			INNER JOIN Document.Meeting AS Interaction
	|			ON InteractionAdditionalAttributes.Ref = Interaction.Ref
	|			LEFT JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
	|			ON InteractionAdditionalAttributes.Ref = InteractionsFolderSubjects.Interaction
	|	WHERE
	|		InteractionAdditionalAttributes.Property IN
	|				(SELECT
	|					BooleanProperties.Property
	|				FROM
	|					BooleanProperties AS BooleanProperties
	|				WHERE
	|					BooleanProperties.IsAttribute) " + ConditionTextAttributes + "
	|	
	|	GROUP BY
	|		InteractionAdditionalAttributes.Property
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		InteractionAdditionalAttributes.Property,
	|		SUM(CASE
	|				WHEN InteractionsFolderSubjects.Reviewed
	|					THEN 0
	|				ELSE 1
	|			END)
	|	FROM
	|		Document.PhoneCall.AdditionalAttributes AS InteractionAdditionalAttributes
	|			INNER JOIN Document.PhoneCall AS Interaction
	|			ON InteractionAdditionalAttributes.Ref = Interaction.Ref
	|			LEFT JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
	|			ON InteractionAdditionalAttributes.Ref = InteractionsFolderSubjects.Interaction
	|	WHERE
	|		InteractionAdditionalAttributes.Property IN
	|				(SELECT
	|					BooleanProperties.Property
	|				FROM
	|					BooleanProperties AS BooleanProperties
	|				WHERE
	|					BooleanProperties.IsAttribute) " + ConditionTextAttributes + "
	|	
	|	GROUP BY
	|		InteractionAdditionalAttributes.Property
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		InteractionAdditionalAttributes.Property,
	|		SUM(CASE
	|				WHEN InteractionsFolderSubjects.Reviewed
	|					THEN 0
	|				ELSE 1
	|			END)
	|	FROM
	|		Document.PlannedInteraction.AdditionalAttributes AS InteractionAdditionalAttributes
	|			INNER JOIN Document.PlannedInteraction AS Interaction
	|			ON InteractionAdditionalAttributes.Ref = Interaction.Ref
	|			LEFT JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
	|			ON InteractionAdditionalAttributes.Ref = InteractionsFolderSubjects.Interaction
	|	WHERE
	|		InteractionAdditionalAttributes.Property IN
	|				(SELECT
	|					BooleanProperties.Property
	|				FROM
	|					BooleanProperties AS BooleanProperties
	|				WHERE
	|					BooleanProperties.IsAttribute) " + ConditionTextAttributes + "
	|	
	|	GROUP BY
	|		InteractionAdditionalAttributes.Property
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		InteractionAdditionalAttributes.Property,
	|		SUM(CASE
	|				WHEN InteractionsFolderSubjects.Reviewed
	|					THEN 0
	|				ELSE 1
	|			END)
	|	FROM
	|		Document.IncomingEmail.AdditionalAttributes AS InteractionAdditionalAttributes
	|			INNER JOIN Document.IncomingEmail AS Interaction
	|			ON InteractionAdditionalAttributes.Ref = Interaction.Ref
	|			LEFT JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
	|			ON InteractionAdditionalAttributes.Ref = InteractionsFolderSubjects.Interaction
	|	WHERE
	|		InteractionAdditionalAttributes.Property IN
	|				(SELECT
	|					BooleanProperties.Property
	|				FROM
	|					BooleanProperties AS BooleanProperties
	|				WHERE
	|					BooleanProperties.IsAttribute) " + ConditionTextAttributes + "
	|	
	|	GROUP BY
	|		InteractionAdditionalAttributes.Property
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		InteractionAdditionalAttributes.Property,
	|		SUM(CASE
	|				WHEN InteractionsFolderSubjects.Reviewed
	|					THEN 0
	|				ELSE 1
	|			END)
	|	FROM
	|		Document.OutgoingEmail.AdditionalAttributes AS InteractionAdditionalAttributes
	|			INNER JOIN Document.OutgoingEmail AS Interaction
	|			ON InteractionAdditionalAttributes.Ref = Interaction.Ref
	|			LEFT JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
	|			ON InteractionAdditionalAttributes.Ref = InteractionsFolderSubjects.Interaction
	|	WHERE
	|		InteractionAdditionalAttributes.Property IN
	|				(SELECT
	|					BooleanProperties.Property
	|				FROM
	|					BooleanProperties AS BooleanProperties
	|				WHERE
	|					BooleanProperties.IsAttribute) " + ConditionTextAttributes + "
	|	
	|	GROUP BY
	|		InteractionAdditionalAttributes.Property
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		AdditionalInfo.Property,
	|		SUM(CASE
	|				WHEN InteractionsFolderSubjects.Reviewed
	|					THEN 0
	|				ELSE 1
	|			END)
	|	FROM
	|		InformationRegister.AdditionalInfo AS AdditionalInfo
	|			INNER JOIN DocumentJournal.Interactions AS Interactions
	|			ON AdditionalInfo.Object = Interactions.Ref
	|			LEFT JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
	|			ON Interactions.Ref = InteractionsFolderSubjects.Interaction
	|	WHERE
	|		AdditionalInfo.Property IN
	|				(SELECT
	|					BooleanProperties.Property
	|				FROM
	|					BooleanProperties AS BooleanProperties
	|				WHERE
	|					(NOT BooleanProperties.IsAttribute))
	|		AND VALUETYPE(AdditionalInfo.Object) IN (TYPE(Document.PlannedInteraction), TYPE(Document.Meeting), TYPE(Document.PhoneCall), TYPE(Document.IncomingEmail), TYPE(Document.OutgoingEmail), TYPE(Document.PlannedInteraction), TYPE(Document.SMSMessage))
	|				 " + ConditionTextInfo + "
	|	
	|	GROUP BY
	|		AdditionalInfo.Property) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.Property";
	
	Query.SetParameter("BooleanProperties", AddlAttributesPropertiesTableOfBooleanType.Unload());
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		NewRow = Categories.Add();
		FillPropertyValues(NewRow,Selection);
		NewRow.PictureNumber = 0;
		NewRow.Presentation = String(Selection.Presentation) 
		                            + ?(Selection.NotReviewed = 0 Or Not UseReviewedFlag,
		                                "", " (" + String(Selection.NotReviewed) + ")");
		
	EndDo;
	
	AddRowAll(Properties, 2);
	
EndProcedure

&AtServer
Procedure FillContactsPanel()
	
	ListPropertiesStructure = Common.DynamicListPropertiesStructure();
	
	If ImportantContactsOnly Then
		
		Query = New Query;
		QueryTextByFilter = GetQueryTextByListFilter(Query);
		StringToSearchBy = Right(QueryTextByFilter, StrLen(QueryTextByFilter) -  StrFind(QueryTextByFilter,"WHERE") + 1);
		ConditionStringsArray = StrSplit(StringToSearchBy, Chars.LF, False);
		ConditionsTextByDocumentJournal = "";
		ConditionsTextByRegister          = "";
		Ind = 1;
		
		For Each ConditionString In ConditionStringsArray Do
			ConditionString = StrReplace(ConditionString,"&R","&Par");
			If Ind = 2 Then
				ConditionString = " AND " + ConditionString;
			EndIf;
			If StrFind(ConditionString, "InteractionDocumentsLog") Then
				ConditionsTextByDocumentJournal = ConditionsTextByDocumentJournal + ConditionString + Chars.LF;
			ElsIf  StrFind(ConditionString, "InteractionsSubjects") Then
				ConditionsTextByRegister = ConditionsTextByRegister + ConditionString + Chars.LF;
			EndIf;
			
			Ind = Ind + 1;
		EndDo;
		
		DynamicListQueryText = 
		"SELECT
		|	InteractionsContactStates.Contact,
		|	InteractionsContactStates.NotReviewedInteractionsCount,
		|	InteractionsContactStates.LastInteractionDate,
		|	3 AS PictureNumber,
		|	VALUETYPE(InteractionsContactStates.Contact) AS ContactType
		|FROM
		|	InformationRegister.InteractionsContactStates AS InteractionsContactStates
		|WHERE
		|	TRUE IN
		|			(SELECT TOP 1
		|				TRUE
		|			FROM
		|				InformationRegister.InteractionsContacts AS InteractionsContacts
		|					INNER JOIN DocumentJournal.Interactions AS InteractionDocumentsLog
		|					ON
		|						InteractionsContacts.Contact = InteractionsContactStates.Contact
		|							AND InteractionsContacts.Interaction = InteractionDocumentsLog.Ref
		|							%DocumentJournalConditionText%
		|					INNER JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsSubjects
		|					ON
		|						InteractionsContacts.Contact = InteractionsContactStates.Contact
		|							AND InteractionsContacts.Interaction = InteractionsSubjects.Interaction
		|							%FolderRegisterConnectionText%)";
		
		DynamicListQueryText = StrReplace(DynamicListQueryText, "%DocumentJournalConditionText%", ConditionsTextByDocumentJournal);
		DynamicListQueryText = StrReplace(DynamicListQueryText, "%FolderRegisterConnectionText%", ConditionsTextByRegister);
		
		ListPropertiesStructure.QueryText = DynamicListQueryText;
		Common.SetDynamicListProperties(Items.NavigationPanelContacts, ListPropertiesStructure);
		
		For each QueryParameter In Query.Parameters Do
			If StrStartsWith(QueryParameter.Key, "R") Then
				ParameterName = "Par" + Right(QueryParameter.Key, StrLen(QueryParameter.Key)-1);
			Else
				ParameterName = QueryParameter.Key;
			EndIf;
			CommonClientServer.SetDynamicListParameter(ContactsNavigationPanel, ParameterName, QueryParameter.Value);
		EndDo;
		
	Else
		
		DynamicListQueryText = "
		|SELECT
		|	InteractionsContactStates.Contact,
		|	InteractionsContactStates.NotReviewedInteractionsCount,
		|	InteractionsContactStates.LastInteractionDate,
		|	3 AS PictureNumber,
		|	VALUETYPE(InteractionsContactStates.Contact) AS ContactType
		|FROM
		|	InformationRegister.InteractionsContactStates AS InteractionsContactStates";
		
		ListPropertiesStructure.QueryText = DynamicListQueryText;
		Common.SetDynamicListProperties(Items.NavigationPanelContacts, ListPropertiesStructure);
		
	EndIf;
	
	Items.NavigationPanelContactsContextMenuOnlyImportantContacts.Check = ImportantContactsOnly;
	
EndProcedure

&AtServer
Procedure FillFoldersTree()
	
	Folders.GetItems().Clear();
	
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	EmailAccounts.Ref AS Account,
	|	EmailMessageFolders.Ref AS Value,
	|	ISNULL(NotReviewedFolders.NotReviewedInteractionsCount, 0) AS NotReviewed,
	|	EmailMessageFolders.PredefinedFolder AS PredefinedFolder,
	|	CASE
	|		WHEN CASE
	|					WHEN EmailAccounts.AccountOwner = VALUE(Catalog.Users.EmptyRef)
	|						THEN EmailAccountSettings.EmployeeResponsibleForFoldersMaintenance = &CurrentUser
	|					ELSE EmailAccounts.AccountOwner = &CurrentUser
	|				END
	|				OR &FullRightsRoleAvailable
	|			THEN 1
	|		ELSE 0
	|	END AS HasEditPermission,
	|	CASE
	|		WHEN NOT EmailMessageFolders.PredefinedFolder
	|			THEN 7
	|		ELSE CASE
	|				WHEN EmailMessageFolders.Description = &Incoming
	|					THEN 1
	|				WHEN EmailMessageFolders.Description = &Sent
	|					THEN 2
	|				WHEN EmailMessageFolders.Description = &Drafts
	|					THEN 3
	|				WHEN EmailMessageFolders.Description = &Outgoing
	|					THEN 4
	|				WHEN EmailMessageFolders.Description = &JunkMail
	|					THEN 5
	|				WHEN EmailMessageFolders.Description = &DeletedItems
	|					THEN 6
	|			END
	|	END AS PictureNumber
	|FROM
	|	Catalog.EmailAccounts AS EmailAccounts
	|		LEFT JOIN Catalog.EmailMessageFolders AS EmailMessageFolders
	|		ON (EmailMessageFolders.Owner = EmailAccounts.Ref)
	|		LEFT JOIN InformationRegister.EmailFolderStates AS NotReviewedFolders
	|		ON (NotReviewedFolders.Folder = EmailMessageFolders.Ref)
	|		LEFT JOIN InformationRegister.EmailAccountSettings AS EmailAccountSettings
	|		ON (EmailMessageFolders.Owner = EmailAccountSettings.EmailAccount)
	|WHERE
	|	NOT ISNULL(EmailAccountSettings.DoNotUseInIntegratedMailClient, FALSE)
	|	AND NOT EmailMessageFolders.DeletionMark
	|	AND NOT EmailAccounts.DeletionMark
	|	AND (EmailAccounts.AccountOwner = &CurrentUser
	|			OR EmailAccounts.AccountOwner = VALUE(Catalog.Users.EmptyRef))
	|
	|ORDER BY
	|	EmailMessageFolders.Code
	|TOTALS
	|	SUM(NotReviewed),
	|	SUM(HasEditPermission)
	|BY
	|	Account,
	|	Value HIERARCHY";
	
	Query.SetParameter("CurrentUser", Users.AuthorizedUser());
	Query.SetParameter("FullRightsRoleAvailable", Users.IsFullUser());
	Interactions.SetQueryParametersPredefinedFoldersNames(Query);
	Result = Query.Execute();
	Tree = Result.Unload(QueryResultIteration.ByGroupsWithHierarchy);
	RowsFirstLevel = Folders.GetItems();
	
	For Each Row In Tree.Rows Do
		
		AccountRow = RowsFirstLevel.Add();
		AccountRow.Account        = Row.Account;
		AccountRow.Value             = Row.Account;
		AccountRow.PictureNumber        = 0;
		AccountRow.NotReviewed        = Row.NotReviewed;
		AccountRow.HasEditPermission = Row.HasEditPermission;
		AccountRow.Presentation = String(AccountRow.Value) 
		                              + ?(Row.NotReviewed = 0 Or Not UseReviewedFlag,
		                              "", " (" + String(Row.NotReviewed) + ")");
		
		AddRowsToNavigationTree(Row, AccountRow);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure AddRowsToNavigationTree(ParentString, ParentRow, ExecuteCheck = True, PictureNumber = -1)
	
	For Each Row In ParentString.Rows Do
		
		If ExecuteCheck AND (Row.Value = ParentString.Value Or Row.Value = Undefined) Then
			Continue;
		EndIf;
		
		NewRow = ParentRow.GetItems().Add();
		FillPropertyValues(NewRow,Row);
		
		If Row.PictureNumber = Null AND PictureNumber <> -1 Then
			NewRow.PictureNumber = PictureNumber;
		EndIf;
	
		If InteractionsClientServer.IsInteraction(Row.Value) Then
			DetailsRow = Row.Rows[0];
			NewRow.Presentation = ?(IsBlankString(DetailsRow.Subject), 
				NStr("ru = 'Тема не указана'; en = 'Subject is not specified'; pl = 'Subject is not specified';de = 'Subject is not specified';ro = 'Subject is not specified';tr = 'Subject is not specified'; es_ES = 'Subject is not specified'"), DetailsRow.Subject) + " " + NStr("ru ='от'; en = 'from'; pl = 'from';de = 'from';ro = 'from';tr = 'from'; es_ES = 'from'") + " " 
				+ Format(DetailsRow.Date, "DLF=DT") + ?(Row.NotReviewed = 0 Or Not UseReviewedFlag,
				                                          "", 
				                                          " (" + String(Row.NotReviewed) + ")");
			NewRow.PictureNumber = DetailsRow.PictureNumber;
		Else
			NewRow.Presentation = String(NewRow.Value) 
			         + ?(Row.NotReviewed = 0 Or Not UseReviewedFlag, 
			             "", 
			             " (" + String(Row.NotReviewed) + ")");
			If Row.PictureNumber = Null AND PictureNumber = -1 AND Row.Rows.Count() > 0 Then
				NewRow.PictureNumber = Row.Rows[0].PictureNumber;
			EndIf;
		EndIf;
		
		AddRowsToNavigationTree(Row, NewRow);
		
	EndDo;
	
EndProcedure

&AtServer
Function GetQueryTextByListFilter(Query)
	
	If InteractionsClientServer.DynamicListFilter(List).Items.Count() > 0 Then
		
		SchemaInteractionsFilter = DocumentJournals.Interactions.GetTemplate("SchemaInteractionsFilter");
		
		TemplateComposer = New DataCompositionTemplateComposer();
		SettingsComposer = New DataCompositionSettingsComposer;
		SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(SchemaInteractionsFilter));
		SettingsComposer.LoadSettings(SchemaInteractionsFilter.DefaultSettings);
		
		CopyFilter(SettingsComposer.Settings.Filter, InteractionsClientServer.DynamicListFilter(List),,, True);
		
		If ValueIsFilled(Items.List.Period.StartDate) OR  ValueIsFilled(Items.List.Period.EndDate) Then
			SettingsComposer.Settings.DataParameters.SetParameterValue("Interval", Items.List.Period);
		EndIf;
		
		DataCompositionTemplate = TemplateComposer.Execute(SchemaInteractionsFilter, SettingsComposer.GetSettings(),,,
			Type("DataCompositionValueCollectionTemplateGenerator"));
		
		If DataCompositionTemplate.ParameterValues.Count() = 0 Then
			Return "";
		ElsIf DataCompositionTemplate.ParameterValues.Count() = 2 
			AND (NOT ValueIsFilled(DataCompositionTemplate.ParameterValues.StartDate.Value)) 
			AND (NOT ValueIsFilled(DataCompositionTemplate.ParameterValues.EndDate.Value)) Then
			Return "";
		EndIf;
		
		QueryText = DataCompositionTemplate.DataSets.MainDataSet.Query;
		
		For each Parameter In DataCompositionTemplate.ParameterValues Do
			Query.Parameters.Insert(Parameter.Name, Parameter.Value);
		EndDo;
		
		QueryText = QueryText +"
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
		FoundItemFROM = StrFind(QueryText,"FROM");
		If FoundItemFROM <> 0 Then
			QueryText = Left(QueryText,FoundItemFROM - 1) + "  INTO ListFilter
			|  " + Right(QueryText,StrLen(QueryText) - FoundItemFROM + 1);
			
		EndIf;
		
	Else
		
		Return "";
		
	EndIf;
	
	Return QueryText;
	
EndFunction

&AtServer
Procedure RefreshNavigationPanel(CurrentRowValue = Undefined, SetDontTestNavigationPanelActivationFlag = True)
	
	CurrentNavigationPanelPage = Items.NavigationPanelPages.CurrentPage;
	
	If CurrentNavigationPanelPage = Items.ContactPage Then
		FillContactsPanel();
	ElsIf CurrentNavigationPanelPage = Items.SubjectPage Then
		FillSubjectsPanel();
	ElsIf CurrentNavigationPanelPage = Items.FoldersPage Then
		FillFoldersTree();
	ElsIf CurrentNavigationPanelPage = Items.PropertiesPage Then
		FillPropertiesTree();
	ElsIf CurrentNavigationPanelPage = Items.CategoriesPage Then
		FillCategoriesTable();
	EndIf;
	
	AfterFillNavigationPanel(SetDontTestNavigationPanelActivationFlag);
	
EndProcedure

&AtServer
Procedure AfterFillNavigationPanel(SetDontTestNavigationPanelActivationFlag = True)
	
	If NOT SetDontTestNavigationPanelActivationFlag Then
		Return;
	EndIf;
	
	ValueSetAfterFillNavigationPanel = Undefined;
	
	Settings = GetSavedSettingsOfNavigationPanelTree(Items.NavigationPanelPages.CurrentPage.Name,
		CurrentPropertyOfNavigationPanel,NavigationPanelTreesSettings);
	
	If Settings = Undefined Then
		Return;
	EndIf;
	
	SettingsValue = Settings.SettingsValue;
	
	If NOT (Items.NavigationPanelPages.CurrentPage = Items.SubjectPage 
		OR Items.NavigationPanelPages.CurrentPage = Items.ContactPage
		OR Items.NavigationPanelPages.CurrentPage = Items.TabsPage) Then
		PositionOnRowAccordingToSavedValue(SettingsValue.CurrentValue, Settings.TreeName);
	EndIf;
	
	
	If Items.NavigationPanelPages.CurrentPage = Items.ContactPage Then
		
		Items.NavigationPanelContacts.CurrentRow = InformationRegisters.InteractionsContactStates.CreateRecordKey(New Structure("Contact", SettingsValue.CurrentValue));

			ChangeFilterList("Contacts",New Structure("Value,TypeDescription",
			                    SettingsValue.CurrentValue, Undefined));
			
		ValueSetAfterFillNavigationPanel = SettingsValue.CurrentValue;
		
	ElsIf Items.NavigationPanelPages.CurrentPage = Items.FoldersPage Then
		
		CurrentData = Folders.FindByID(Items.Folders.CurrentRow);
		If CurrentData = Undefined AND Folders.GetItems().Count() > 0 Then
			CurrentData =  Folders.GetItems()[0];
		EndIf;
		
		If CurrentData <> Undefined Then
			ChangeFilterList("Folders",New Structure("Value,Account",
			                   CurrentData.Value, CurrentData.Account));
		EndIf;
		
	ElsIf Items.NavigationPanelPages.CurrentPage = Items.SubjectPage Then
		
		If ValueIsFilled(Items.NavigationPanelSubjects.CurrentRow) Then
			Return;
		EndIf;
		
		Items.NavigationPanelSubjects.CurrentRow = InformationRegisters.InteractionsSubjectsStates.CreateRecordKey(New Structure("Topic", SettingsValue.CurrentValue));
		
		ChangeFilterList("Subjects",New Structure("Value,TypeDescription",
		                    SettingsValue.CurrentValue, Undefined));
		
		ValueSetAfterFillNavigationPanel = SettingsValue.CurrentValue;

	ElsIf Items.NavigationPanelPages.CurrentPage = Items.PropertiesPage Then
		
		CurrentData = Properties.FindByID(Items.Properties.CurrentRow);
		
		If CurrentData = Undefined Then
			Items.Properties.CurrentRow = FindStringInFormDataTree(Properties,NStr("ru = 'Все'; en = 'All'; pl = 'All';de = 'All';ro = 'All';tr = 'All'; es_ES = 'All'"),"Value",False);
			CurrentData = Properties.FindByID(Items.Properties.CurrentRow);
		EndIf;
		
		If CurrentData <> Undefined Then
			ChangeFilterList("Properties",New Structure("Value", CurrentData.Value));
		EndIf;
		
	ElsIf Items.NavigationPanelPages.CurrentPage = Items.CategoriesPage Then
		
		CurrentData = Categories.FindByID(Items.Categories.CurrentRow);
		
		If CurrentData = Undefined Then
			Items.Categories.CurrentRow = FindRowInCollectionFormData(Categories,NStr("ru = 'Все'; en = 'All'; pl = 'All';de = 'All';ro = 'All';tr = 'All'; es_ES = 'All'"),"Value");
			CurrentData = Categories.FindByID(Items.Categories.CurrentRow);
		EndIf;
		
		If CurrentData <> Undefined Then
			ChangeFilterList("Categories",New Structure("Value", CurrentData.Value));
		EndIf;
		
	ElsIf Items.NavigationPanelPages.CurrentPage = Items.TabsPage Then
		
		Items.Tabs.CurrentRow = SettingsValue.CurrentValue;
		ChangeFilterList("Tabs", New Structure("Value", SettingsValue.CurrentValue));
		
	EndIf;
	
	DoNotTestNavigationPanelActivation = True;

EndProcedure

&AtServer
Procedure UpdateAtServer()

	RefreshNavigationPanel( ,False);

EndProcedure

&AtServer
Procedure AddToNavigationPanel()
	
	If Not Common.SubsystemExists("StandardSubsystems.Interactions") Then
		Return;
	EndIf;
	ModulePropertyManager = Common.CommonModule("PropertyManager");
	
	Sets = New Array;
	Sets.Add(ModulePropertyManager.PropertiesSetByName("Document_Meeting"));
	Sets.Add(ModulePropertyManager.PropertiesSetByName("Document_PlannedInteraction"));
	Sets.Add(ModulePropertyManager.PropertiesSetByName("Document_PhoneCall"));
	Sets.Add(ModulePropertyManager.PropertiesSetByName("Document_IncomingEmail"));
	Sets.Add(ModulePropertyManager.PropertiesSetByName("Document_OutgoingEmail"));
	Sets.Add(ModulePropertyManager.PropertiesSetByName("Document_SMSMessage"));
	
	Query = New Query;
	Query.SetParameter("Sets", Sets);
	Query.Text = "
	|SELECT DISTINCT ALLOWED
	|	AdditionalAttributeAndDataSetsAdditionalAttributes.Property,
	|	PRESENTATION(AdditionalAttributeAndDataSetsAdditionalAttributes.Property) AS Presentation,
	|	TRUE AS IsAddlAttribute
	|INTO AddlAttributesAndInfo
	|FROM
	|	Catalog.AdditionalAttributesAndInfoSets.AdditionalAttributes AS AdditionalAttributeAndDataSetsAdditionalAttributes
	|WHERE
	|	AdditionalAttributeAndDataSetsAdditionalAttributes.Ref IN (&Sets)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	AdditionalAttributeAndDataSetsAdditionalData.Property,
	|	PRESENTATION(AdditionalAttributeAndDataSetsAdditionalData.Property),
	|	FALSE
	|FROM
	|	Catalog.AdditionalAttributesAndInfoSets.AdditionalInfo AS AdditionalAttributeAndDataSetsAdditionalData
	|WHERE
	|	AdditionalAttributeAndDataSetsAdditionalData.Ref IN (&Sets)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AddlAttributesAndInfo.Property,
	|	AddlAttributesAndInfo.Presentation,
	|	AddlAttributesAndInfo.IsAddlAttribute,
	|	AdditionalAttributesAndInfo.ValueType
	|FROM
	|	AddlAttributesAndInfo AS AddlAttributesAndInfo
	|		INNER JOIN ChartOfCharacteristicTypes.AdditionalAttributesAndInfo AS AdditionalAttributesAndInfo
	|		ON AddlAttributesAndInfo.Property = AdditionalAttributesAndInfo.Ref";
	
	Ind = 0;
	TypesDetailsBoolean = New TypeDescription("Boolean");
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		If Selection.ValueType = TypesDetailsBoolean Then
			NewRow = AddlAttributesPropertiesTableOfBooleanType.Add();
		Else
			
		NewCommand = Commands.Add("SetOptionByProperty_" + String(Ind));
		NewCommand.Action = "SwitchNavigationPanel";
		
		ItemButtonSubmenu = Items.Add("AdditionalButtonPropertyNavigationOptionSelection_" 
		                       + String(Ind),Type("FormButton"), Items.SelectNavigationOption);
		ItemButtonSubmenu.Type = FormButtonType.CommandBarButton;
		ItemButtonSubmenu.CommandName = NewCommand.Name;
		ItemButtonSubmenu.Title = NStr("ru = 'По'; en = 'To'; pl = 'To';de = 'To';ro = 'To';tr = 'To'; es_ES = 'To'") + " " + Selection.Presentation;
			
			NewRow = AddlAttributesPropertiesTable.Add();
			NewRow.SequenceNumber = Ind;
			Ind = Ind + 1;
			
		EndIf;
		
		NewRow.AddlAttributeInfo = Selection.Property;
		NewRow.IsAttribute = Selection.IsAddlAttribute;
		NewRow.Presentation = Selection.Presentation;
		
	EndDo;
	
	If AddlAttributesPropertiesTableOfBooleanType.Count() > 0 Then
	
		NewCommand = Commands.Add("SetOptionByCategories");
		NewCommand.Action = "SwitchNavigationPanel";
		
		ItemButtonSubmenu = Items.Add("AdditionalButtonCategoryNavigationOptionSelection", 
			Type("FormButton"), Items.SelectNavigationOption);
		ItemButtonSubmenu.Type = FormButtonType.CommandBarButton;
		ItemButtonSubmenu.CommandName = NewCommand.Name;
		ItemButtonSubmenu.Title = NStr("ru = 'По категориям'; en = 'By categories'; pl = 'By categories';de = 'By categories';ro = 'By categories';tr = 'By categories'; es_ES = 'By categories'");
	
	EndIf;
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////
//    Saving node statuses and navigation panel tree values.

&AtClientAtServerNoContext
Function GetSavedSettingsOfNavigationPanelTree(
	CurrentPageNameOfNavigationPanel,
	CurrentPropertyOfNavigationPanel,
	NavigationPanelTreesSettings)

	If CurrentPageNameOfNavigationPanel = "SubjectPage" Then
		TreeName = "Subjects";
		SettingName = "Subjects";
	ElsIf CurrentPageNameOfNavigationPanel = "ContactPage" Then
		TreeName = "Contacts";
		SettingName = "Contacts";
	ElsIf CurrentPageNameOfNavigationPanel = "CategoriesPage" Then
		TreeName = "Categories";
		SettingName = "Categories";
	ElsIf CurrentPageNameOfNavigationPanel = "FoldersPage" Then
		TreeName = "Folders";
		SettingName = "Folders";
	ElsIf CurrentPageNameOfNavigationPanel = "PropertiesPage" Then
		TreeName = "Properties";
		SettingName = "Properties_" + String(CurrentPropertyOfNavigationPanel);
	ElsIf CurrentPageNameOfNavigationPanel = "TabsPage" Then
		TreeName = "Tabs";
		SettingName = "Tabs";
	Else
		Return Undefined;
	EndIf;
	
	FoundRows =  NavigationPanelTreesSettings.FindRows(New Structure("TreeName", SettingName));
	If FoundRows.Count() = 1 Then
		SettingsTreeRow = FoundRows[0];
	ElsIf FoundRows.Count() > 1 Then
		SettingsTreeRow = FoundRows[0];
		For Ind = 1 To FoundRows.Count()-1 Do
			NavigationPanelTreesSettings.Delete(FoundRows[Ind]);
		EndDo;
	Else
		Return Undefined;
	EndIf;
	
	Return New Structure("TreeName,SettingsValue",TreeName,SettingsTreeRow);

EndFunction

&AtClient
Procedure SaveNodeStateInSettings(TreeName, Value, Expansion);
	
	If TreeName = "Properties" Then
		TreeName =  "Properties_" + String(CurrentPropertyOfNavigationPanel);
	EndIf;
	
	FoundRows =  NavigationPanelTreesSettings.FindRows(New Structure("TreeName",TreeName));
	If FoundRows.Count() = 1 Then
		SettingsTreeRow = FoundRows[0];
	ElsIf FoundRows.Count() > 1 Then
		SettingsTreeRow = FoundRows[0];
		For Ind = 1 To FoundRows.Count()-1 Do
			NavigationPanelTreesSettings.Delete(FoundRows[Ind]);
		EndDo;
	Else
		If Expansion Then
			SettingsTreeRow = NavigationPanelTreesSettings.Add();
			SettingsTreeRow.TreeName = TreeName;
		Else
			Return;
		EndIf;
	EndIf;
	
	FoundListItem = SettingsTreeRow.ExpandedNodes.FindByValue(Value);
	
	If Expansion Then
		
		If FoundListItem = Undefined Then
			
			SettingsTreeRow.ExpandedNodes.Add(Value);
			
		EndIf;
		
	Else
		
		If FoundListItem <> Undefined Then
			
			SettingsTreeRow.ExpandedNodes.Delete(FoundListItem);
			
		EndIf;
	
	EndIf;
	
EndProcedure

&AtClient
Procedure RestoreExpandedTreeNodes()
	
	If Items.NavigationPanelPages.CurrentPage = Items.SubjectPage 
		OR Items.NavigationPanelPages.CurrentPage = Items.ContactPage Then
		AttachIdleHandler("ProcessNavigationPanelRowActivation", 0.2, True);
		Return;
	EndIf;
	
	Settings = GetSavedSettingsOfNavigationPanelTree(Items.NavigationPanelPages.CurrentPage.Name,
		CurrentPropertyOfNavigationPanel,NavigationPanelTreesSettings);
		
	If Settings = Undefined Then
		Return;
	EndIf;
	
	SettingsValue = Settings.SettingsValue;
	
	If Settings.TreeName <> "Categories" Then
		ExpandedNodesIDsMap = New Map;
		
		If SettingsValue.ExpandedNodes.Count() Then
			DetermineExpandedNodesIDs(SettingsValue.ExpandedNodes, 
				ExpandedNodesIDsMap, ThisObject[Settings.TreeName].GetItems());
		EndIf;
		
		For each MapItem In ExpandedNodesIDsMap Do
			Items[Settings.TreeName].Expand(MapItem.Value);
		EndDo;
		
		For each ListItem In SettingsValue.ExpandedNodes Do
			If ExpandedNodesIDsMap.Get(ListItem.Value) = Undefined Then
				SettingsValue.ExpandedNodes.Delete(ListItem);
			EndIf;
		EndDo;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DetermineExpandedNodesIDs(ExpandedNodesList, IDsMap, TreeRows)

	For each Item In TreeRows Do
		If ExpandedNodesList.FindByValue(Item.Value) <> Undefined Then
			ParentElement = Item.GetParent();
			If ParentElement = Undefined OR IDsMap.Get(ParentElement.Value) <> Undefined Then
				IDsMap.Insert(Item.Value,Item.GetID());
			EndIf;
		EndIf;
		DetermineExpandedNodesIDs(ExpandedNodesList, IDsMap, Item.GetItems());
	EndDo;
		
EndProcedure

&AtServer
Procedure PositionOnRowAccordingToSavedValue(CurrentRowValue,
	                                                             ItemName,
	                                                             RowAll = Undefined)
	
	If CurrentRowValue <> Undefined Then
		If ItemName <> "Categories" Then
			FoundRowID = FindStringInFormDataTree(ThisObject[ItemName],
				CurrentRowValue,"Value",True);
		Else
			FoundRowID = FindRowInCollectionFormData(ThisObject[ItemName],
				CurrentRowValue,"Value");
		EndIf;
		If FoundRowID > 0 Then
			Items[ItemName].CurrentRow = FoundRowID;
		Else
			Items[ItemName].CurrentRow = ?(RowAll = Undefined, 0, RowAll.GetID());
		EndIf;
	Else
		Items[ItemName].CurrentRow = ?(RowAll = Undefined, 0, RowAll.GetID());
	EndIf;

EndProcedure

///////////////////////////////////////////////////////////////////////////////
// Procedures and functions of command processing.

// Set a responsible person for selected interactions - the server part.
// Parameters:
//  Interactions - a list of selected interactions.
//  Responsible person - a responsible person being set.
&AtServer
Procedure SetEmployeeResponsible(EmployeeResponsible, Val DataForProcessing)
	
	UpdateNavigationPanel = False;
	
	If DataForProcessing <> Undefined Then
		
		For Each Interaction In DataForProcessing Do
			If ValueIsFilled(Interaction)
				AND Interaction.EmployeeResponsible <> EmployeeResponsible Then
				
				Interactions.ReplaceEmployeeResponsibleInDocument(Interaction, EmployeeResponsible);
				UpdateNavigationPanel = True;
				
			EndIf;
		EndDo;
		
	Else
		
		InteractionsArray = GetInteractionsByListFilter(EmployeeResponsible,"EmployeeResponsible");
		
		For Each Interaction In InteractionsArray Do
			
			Interactions.ReplaceEmployeeResponsibleInDocument(Interaction, EmployeeResponsible);
			UpdateNavigationPanel = True;
			
		EndDo; 
		
	EndIf;
	
	If UpdateNavigationPanel Then
		RefreshNavigationPanel(, NOT IsPanelWithDynamicList(CurrentNavigationPanelName));
	EndIf;
	
EndProcedure

// Set the Reviewed flag for selected interactions - the server part.
// Parameters:
//  Interactions - a list of selected interactions.
&AtServer
Procedure SetReviewedFlag(Val DataForProcessing, FlagValue)
	
	UpdateNavigationPanel = False;
	
	If DataForProcessing <> Undefined Then
		
		InteractionsArray = New Array;
		
		For Each Interaction In DataForProcessing Do
			If ValueIsFilled(Interaction) Then
				InteractionsArray.Add(Interaction);
			EndIf;
		EndDo;
		
		Interactions.MarkAsReviewed(InteractionsArray,FlagValue, UpdateNavigationPanel);
		
	Else
		
		InteractionsArray = GetInteractionsByListFilter(FlagValue, "Reviewed");
		
		For Each Interaction In InteractionsArray Do
			Interactions.MarkAsReviewed(InteractionsArray,FlagValue, UpdateNavigationPanel);
		EndDo;
		
	EndIf;
	
	If UpdateNavigationPanel Then
		RefreshNavigationPanel(, NOT IsPanelWithDynamicList(CurrentNavigationPanelName));
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function IsPanelWithDynamicList(CurrentNavigationPanelName)

	If CurrentNavigationPanelName = "SubjectPage" OR CurrentNavigationPanelName = "ContactPage" Then
		Return True;
	Else
		Return False;
	EndIf;

EndFunction

&AtServer
Function AddToTabsServer(Val DataForProcessing, FormItemName)
	
	Result = New Structure;
	Result.Insert("ItemAdded", False);
	Result.Insert("ItemURL", "");
	Result.Insert("ItemPresentation", "");
	Result.Insert("ErrorMessageText", "");
		
	CompositionSchema = DocumentJournals.Interactions.GetTemplate("SchemaInteractionsFilter");
	SchemaURL = PutToTempStorage(CompositionSchema, UUID);
	
	SettingsComposer = New DataCompositionSettingsComposer;
	SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(SchemaURL));
	SettingsComposer.LoadSettings(CompositionSchema.DefaultSettings);
	
	If StrStartsWith(FormItemName, "List") Then
		
		InteractionsList = New ValueList;
		
		For Each Interaction In DataForProcessing Do
			If ValueIsFilled(Interaction) Then
				InteractionsList.Add(Interaction);
			EndIf;
		EndDo;
		
		If InteractionsList.Count() = 0 Then
			Result.ErrorMessageText = NStr("ru = 'Не выбран элемент для добавления в закладки.'; en = 'Item for adding to tabs is not selected.'; pl = 'Item for adding to tabs is not selected.';de = 'Item for adding to tabs is not selected.';ro = 'Item for adding to tabs is not selected.';tr = 'Item for adding to tabs is not selected.'; es_ES = 'Item for adding to tabs is not selected.'");
			Return Result;
		EndIf;
		
		CommonClientServer.AddCompositionItem(SettingsComposer.Settings.Filter,
			"Ref", DataCompositionComparisonType.InList, InteractionsList);
		TabDescription = ?(EmailOnly, NStr("ru = 'Избранные письма'; en = 'Selected emails'; pl = 'Selected emails';de = 'Selected emails';ro = 'Selected emails';tr = 'Selected emails'; es_ES = 'Selected emails'"), NStr("ru = 'Избранные взаимодействия'; en = 'Favorite interactions'; pl = 'Favorite interactions';de = 'Favorite interactions';ro = 'Favorite interactions';tr = 'Favorite interactions'; es_ES = 'Favorite interactions'"));
		If InteractionsList.Count() > 1 Then
			Text = ?(EmailOnly, NStr("ru = 'Выбранные письма (%1)'; en = 'Selected emails (%1)'; pl = 'Selected emails (%1)';de = 'Selected emails (%1)';ro = 'Selected emails (%1)';tr = 'Selected emails (%1)'; es_ES = 'Selected emails (%1)'"), NStr("ru = 'Выбранные взаимодействия (%1)'; en = 'Selected interactions (%1)'; pl = 'Selected interactions (%1)';de = 'Selected interactions (%1)';ro = 'Selected interactions (%1)';tr = 'Selected interactions (%1)'; es_ES = 'Selected interactions (%1)'"));
			Result.ItemPresentation = StringFunctionsClientServer.SubstituteParametersToString(Text, InteractionsList.Count());
		Else
			Result.ItemPresentation = Common.SubjectString(InteractionsList[0].Value);
			Result.ItemURL = GetURL(InteractionsList[0].Value);
		EndIf;
	Else
		
		If DataForProcessing.Value = NStr("ru = 'Все'; en = 'All'; pl = 'All';de = 'All';ro = 'All';tr = 'All'; es_ES = 'All'") Then
			Result.ErrorMessageText = NStr("ru = 'Закладку без отбора создать нельзя.'; en = 'Cannot create a tab without filter.'; pl = 'Cannot create a tab without filter.';de = 'Cannot create a tab without filter.';ro = 'Cannot create a tab without filter.';tr = 'Cannot create a tab without filter.'; es_ES = 'Cannot create a tab without filter.'");
			Return Result;
		EndIf;
		
		FilterGroupByNavigationPanel = CommonClientServer.FindFilterItemByPresentation(
		    InteractionsClientServer.DynamicListFilter(List).Items,
		    "FIlterNavigationPanel");
		If FilterGroupByNavigationPanel = Undefined Then
				Result.ErrorMessageText = NStr("ru = 'Не выбран элемент для добавления в закладки.'; en = 'Item for adding to tabs is not selected.'; pl = 'Item for adding to tabs is not selected.';de = 'Item for adding to tabs is not selected.';ro = 'Item for adding to tabs is not selected.';tr = 'Item for adding to tabs is not selected.'; es_ES = 'Item for adding to tabs is not selected.'");
				Return Result;
		EndIf;
		
		CopyFilter(SettingsComposer.Settings.Filter, FilterGroupByNavigationPanel, True);
		If FormItemName = "NavigationPanelSubjects" Then
			
			If Common.RefTypeValue(DataForProcessing.Value) Then
				
				TabDescription       = NStr("ru = 'Предмет'; en = 'Subject'; pl = 'Subject';de = 'Subject';ro = 'Subject';tr = 'Subject'; es_ES = 'Subject'") + " = " + String(DataForProcessing.Value); 
				Text = ?(EmailOnly, NStr("ru = 'Письма по предмету %1'; en = 'Emails by subject %1'; pl = 'Emails by subject %1';de = 'Emails by subject %1';ro = 'Emails by subject %1';tr = 'Emails by subject %1'; es_ES = 'Emails by subject %1'"), NStr("ru = 'Взаимодействия по предмету %1'; en = 'Interactions on the subject %1'; pl = 'Interactions on the subject %1';de = 'Interactions on the subject %1';ro = 'Interactions on the subject %1';tr = 'Interactions on the subject %1'; es_ES = 'Interactions on the subject %1'"));
				Result.ItemPresentation = StringFunctionsClientServer.SubstituteParametersToString(Text, Common.SubjectString(DataForProcessing.Value));
				Result.ItemURL = GetURL(DataForProcessing.Value);
				
			ElsIf DataForProcessing.Value = NStr("ru = 'Не указан'; en = 'Not specified'; pl = 'Not specified';de = 'Not specified';ro = 'Not specified';tr = 'Not specified'; es_ES = 'Not specified'") Then
				
				TabDescription       = NStr("ru = 'Предмет не указан'; en = 'Subject is not specified'; pl = 'Subject is not specified';de = 'Subject is not specified';ro = 'Subject is not specified';tr = 'Subject is not specified'; es_ES = 'Subject is not specified'");
				Result.ItemPresentation = ?(EmailOnly, NStr("ru = 'Письма без предмета'; en = 'Emails without subject'; pl = 'Emails without subject';de = 'Emails without subject';ro = 'Emails without subject';tr = 'Emails without subject'; es_ES = 'Emails without subject'"), NStr("ru = 'Взаимодействия без предмета'; en = 'Interaction without subject'; pl = 'Interaction without subject';de = 'Interaction without subject';ro = 'Interaction without subject';tr = 'Interaction without subject'; es_ES = 'Interaction without subject'"));
				
			ElsIf DataForProcessing.Value = NStr("ru = 'Прочие вопросы'; en = 'Other matters'; pl = 'Other matters';de = 'Other matters';ro = 'Other matters';tr = 'Other matters'; es_ES = 'Other matters'") Then
				
				TabDescription       = NStr("ru = 'Прочие вопросы'; en = 'Other matters'; pl = 'Other matters';de = 'Other matters';ro = 'Other matters';tr = 'Other matters'; es_ES = 'Other matters'");
				Result.ItemPresentation = ?(EmailOnly, NStr("ru = 'Прочие письма'; en = 'Other emails'; pl = 'Other emails';de = 'Other emails';ro = 'Other emails';tr = 'Other emails'; es_ES = 'Other emails'"), NStr("ru = 'Прочие взаимодействия'; en = 'Other interactions'; pl = 'Other interactions';de = 'Other interactions';ro = 'Other interactions';tr = 'Other interactions'; es_ES = 'Other interactions'"));
				
			Else
				
				TabDescription       = NStr("ru = 'Тип предмета'; en = 'Subject type'; pl = 'Subject type';de = 'Subject type';ro = 'Subject type';tr = 'Subject type'; es_ES = 'Subject type'") + " " + String(DataForProcessing.TypeDescription.Types()[0]);
				Result.ItemPresentation = ?(EmailOnly, NStr("ru = 'Письма по: %1'; en = 'Emails by: %1'; pl = 'Emails by: %1';de = 'Emails by: %1';ro = 'Emails by: %1';tr = 'Emails by: %1'; es_ES = 'Emails by: %1'"), NStr("ru = 'Взаимодействия по: %1'; en = 'Interactions on:%1'; pl = 'Interactions on:%1';de = 'Interactions on:%1';ro = 'Interactions on:%1';tr = 'Interactions on:%1'; es_ES = 'Interactions on:%1'"));
				Result.ItemPresentation = StringFunctionsClientServer.SubstituteParametersToString(Result.ItemPresentation, DataForProcessing.TypeDescription.Types()[0]);
				
			EndIf;
			
		ElsIf FormItemName = "Properties" Then
			
			If TypeOf(DataForProcessing.Value) = Type("String") 
				AND DataForProcessing.Value = NStr("ru = 'Не указан'; en = 'Not specified'; pl = 'Not specified';de = 'Not specified';ro = 'Not specified';tr = 'Not specified'; es_ES = 'Not specified'") Then
				TabDescription       = CurrentPropertyOfNavigationPanel.Description + " " + NStr("ru = 'не указан'; en = 'not specified'; pl = 'not specified';de = 'not specified';ro = 'not specified';tr = 'not specified'; es_ES = 'not specified'");
				Result.ItemPresentation = ?(EmailOnly, NStr("ru = 'Письма'; en = 'Emails'; pl = 'Emails';de = 'Emails';ro = 'Emails';tr = 'Emails'; es_ES = 'Emails'"), NStr("ru = 'Взаимодействия'; en = 'Interactions'; pl = 'Interactions';de = 'Interactions';ro = 'Interactions';tr = 'Interactions'; es_ES = 'Interactions'"));
			Else
				TabDescription       = CurrentPropertyOfNavigationPanel.Description + " = " + String(DataForProcessing.Value);
				Result.ItemPresentation = ?(EmailOnly, 
				                                   NStr("ru = 'Письма с заданным свойством: %1'; en = 'Emails with the specified property: %1'; pl = 'Emails with the specified property: %1';de = 'Emails with the specified property: %1';ro = 'Emails with the specified property: %1';tr = 'Emails with the specified property: %1'; es_ES = 'Emails with the specified property: %1'"), 
				                                   NStr("ru = 'Взаимодействия с заданным свойством: %1'; en = 'Interactions with specified property: %1'; pl = 'Interactions with specified property: %1';de = 'Interactions with specified property: %1';ro = 'Interactions with specified property: %1';tr = 'Interactions with specified property: %1'; es_ES = 'Interactions with specified property: %1'"));
				Result.ItemPresentation = 
					StringFunctionsClientServer.SubstituteParametersToString(Result.ItemPresentation, DataForProcessing.Value);
			EndIf;
			
		ElsIf FormItemName = "Categories" Then
			
			TabDescription       = NStr("ru = 'Входит в категорию'; en = 'Belongs to the category'; pl = 'Belongs to the category';de = 'Belongs to the category';ro = 'Belongs to the category';tr = 'Belongs to the category'; es_ES = 'Belongs to the category'") + " " + String(DataForProcessing.Value);
			Result.ItemPresentation = ?(EmailOnly, NStr("ru = 'Письма из категории: %1'; en = 'Emails from category: %1'; pl = 'Emails from category: %1';de = 'Emails from category: %1';ro = 'Emails from category: %1';tr = 'Emails from category: %1'; es_ES = 'Emails from category: %1'"), NStr("ru = 'Взаимодействия из категории: %1'; en = 'Interactions from the category: %1'; pl = 'Interactions from the category: %1';de = 'Interactions from the category: %1';ro = 'Interactions from the category: %1';tr = 'Interactions from the category: %1'; es_ES = 'Interactions from the category: %1'"));
			Result.ItemPresentation = 
				StringFunctionsClientServer.SubstituteParametersToString(Result.ItemPresentation, DataForProcessing.Value);
			
		ElsIf FormItemName = "Contacts" Then
			
			If Common.RefTypeValue(DataForProcessing.Value) Then
				
				TabDescription       = NStr("ru = 'Контакт'; en = 'Contact'; pl = 'Contact';de = 'Contact';ro = 'Contact';tr = 'Contact'; es_ES = 'Contact'") + " = " + String(DataForProcessing.Value); 
				Text = ?(EmailOnly, NStr("ru = 'Письма по контакту %1'; en = 'Emails by contact %1'; pl = 'Emails by contact %1';de = 'Emails by contact %1';ro = 'Emails by contact %1';tr = 'Emails by contact %1'; es_ES = 'Emails by contact %1'"), NStr("ru = 'Взаимодействия по контакту %1'; en = 'Interactions by contact %1'; pl = 'Interactions by contact %1';de = 'Interactions by contact %1';ro = 'Interactions by contact %1';tr = 'Interactions by contact %1'; es_ES = 'Interactions by contact %1'"));
				Result.ItemPresentation = 
					StringFunctionsClientServer.SubstituteParametersToString(Text, Common.SubjectString(DataForProcessing.Value));
				Result.ItemURL = GetURL(DataForProcessing.Value);
				
			ElsIf DataForProcessing.Value = NStr("ru = 'Контакт не подобран'; en = 'Contact is not selected'; pl = 'Contact is not selected';de = 'Contact is not selected';ro = 'Contact is not selected';tr = 'Contact is not selected'; es_ES = 'Contact is not selected'") Then
				
				TabDescription       = NStr("ru = 'Контакт не указан'; en = 'Contact is not specified'; pl = 'Contact is not specified';de = 'Contact is not specified';ro = 'Contact is not specified';tr = 'Contact is not specified'; es_ES = 'Contact is not specified'");
				Result.ItemPresentation = ?(EmailOnly, NStr("ru = 'Письма без подобранных контактов'; en = 'Emails without selected contacts'; pl = 'Emails without selected contacts';de = 'Emails without selected contacts';ro = 'Emails without selected contacts';tr = 'Emails without selected contacts'; es_ES = 'Emails without selected contacts'"), NStr("ru = 'Взаимодействия без подобранных контактов'; en = 'Interactions without selected contacts'; pl = 'Interactions without selected contacts';de = 'Interactions without selected contacts';ro = 'Interactions without selected contacts';tr = 'Interactions without selected contacts'; es_ES = 'Interactions without selected contacts'"));
				
			Else
				
				TabDescription       = NStr("ru = 'Тип контакта'; en = 'Contact type'; pl = 'Contact type';de = 'Contact type';ro = 'Contact type';tr = 'Contact type'; es_ES = 'Contact type'") + " " + String(DataForProcessing.TypeDescription.Types()[0]);
				Result.ItemPresentation = ?(EmailOnly, NStr("ru = 'Письма по контактам: %1'; en = 'Emails by contacts: %1'; pl = 'Emails by contacts: %1';de = 'Emails by contacts: %1';ro = 'Emails by contacts: %1';tr = 'Emails by contacts: %1'; es_ES = 'Emails by contacts: %1'"), NStr("ru = 'Взаимодействия по контактам: %1'; en = 'Interactions by contacts: %1'; pl = 'Interactions by contacts: %1';de = 'Interactions by contacts: %1';ro = 'Interactions by contacts: %1';tr = 'Interactions by contacts: %1'; es_ES = 'Interactions by contacts: %1'"));
				Result.ItemPresentation = StringFunctionsClientServer.SubstituteParametersToString(Result.ItemPresentation, DataForProcessing.TypeDescription.Types()[0]);
				
			EndIf;

		ElsIf FormItemName = "Folders" Then
			
			TabDescription       = NStr("ru = 'В папке'; en = 'In folder'; pl = 'In folder';de = 'In folder';ro = 'In folder';tr = 'In folder'; es_ES = 'In folder'") + " " + String(DataForProcessing.Value);
			Result.ItemPresentation = ?(EmailOnly, NStr("ru = 'Письма в папке: %1'; en = 'Emails are in folder: %1'; pl = 'Emails are in folder: %1';de = 'Emails are in folder: %1';ro = 'Emails are in folder: %1';tr = 'Emails are in folder: %1'; es_ES = 'Emails are in folder: %1'"), NStr("ru = 'Взаимодействия в папке: %1'; en = 'Interactions in the folder: %1'; pl = 'Interactions in the folder: %1';de = 'Interactions in the folder: %1';ro = 'Interactions in the folder: %1';tr = 'Interactions in the folder: %1'; es_ES = 'Interactions in the folder: %1'"));
			Result.ItemPresentation = StringFunctionsClientServer.SubstituteParametersToString(Result.ItemPresentation, DataForProcessing.Value);
			
		EndIf;
		
	EndIf;
	
	Query = New Query;
	Query.Text = "SELECT
	|	InteractionsTabs.Ref,
	|	InteractionsTabs.Description,
	|	InteractionsTabs.SettingsComposer
	|FROM
	|	Catalog.InteractionsTabs AS InteractionsTabs
	|WHERE
	|	NOT InteractionsTabs.IsFolder
	|	AND NOT InteractionsTabs.DeletionMark";
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		If ValueInXML(SettingsComposer.GetSettings()) =  ValueInXML(Selection.SettingsComposer.Get()) Then
			Result.ErrorMessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Закладка с такими настройками уже существует : %1'; en = 'Tab with these settings already exists : %1'; pl = 'Tab with these settings already exists : %1';de = 'Tab with these settings already exists : %1';ro = 'Tab with these settings already exists : %1';tr = 'Tab with these settings already exists : %1'; es_ES = 'Tab with these settings already exists : %1'"),
				Selection.Description);
			Return Result;
		EndIf;
	EndDo;
	
	Tab = Catalogs.InteractionsTabs.CreateItem();
	Tab.Owner = Users.AuthorizedUser();
	Tab.Description = TabDescription;
	Tab.SettingsComposer = New ValueStorage(SettingsComposer.GetSettings());
	Tab.Write();
	
	Items.Tabs.Refresh();
	
	Result.ItemAdded = True;
	Return Result;
	
EndFunction

&AtServerNoContext
Function ValueInXML(Value)
	
	Record = New XMLWriter();
	Record.SetString();
	XDTOSerializer.WriteXML(Record, Value);
	Return Record.Close();
	
EndFunction

// Set a subject for selected interactions - the server part.
// Parameters:
//  Interactions - a list of selected interactions.
//  Subject - an interaction subject being set.
&AtServer
Procedure SetSubject(Topic, Val DataForProcessing)
	
	If DataForProcessing <> Undefined Then
		
		Query = New Query;
		Query.Text = "SELECT
		|	Interactions.Ref
		|FROM
		|	DocumentJournal.Interactions AS Interactions
		|		INNER JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
		|		ON Interactions.Ref = InteractionsFolderSubjects.Interaction
		|WHERE
		|	InteractionsFolderSubjects.Topic <> &Topic
		|	AND Interactions.Ref IN (&InteractionsArray)";
		
		Query.SetParameter("InteractionsArray",DataForProcessing );
		Query.SetParameter("Topic", Topic);
		
		InteractionsArray = Query.Execute().Unload().UnloadColumn("Ref");
		
	Else
		
		InteractionsArray = GetInteractionsByListFilter(Topic, "Topic");
		
	EndIf;
	
	If InteractionsArray.Count() > 0 Then
		InteractionsServerCall.SetSubjectForInteractionsArray(InteractionsArray, Topic, True);
		RefreshNavigationPanel();
	EndIf;
	
EndProcedure

&AtServer
Procedure DeferReview(ReviewDate, Val DataForProcessing)
	
	If DataForProcessing <> Undefined Then
		
		InteractionsArray = Interactions.InteractionsArrayForReviewDateChange(DataForProcessing, ReviewDate);
		
	Else
		
		InteractionsArray = GetInteractionsByListFilter(True, "Reviewed");
		
	EndIf;
	
	For Each Interaction In InteractionsArray Do
		
		Attributes = InformationRegisters.InteractionsFolderSubjects.InteractionAttributes();
		Attributes.ReviewAfter        = ReviewDate;
		Attributes.CalculateReviewedItems = False;
		InformationRegisters.InteractionsFolderSubjects.WriteInteractionFolderSubjects(Interaction, Attributes);
		
	EndDo;
	
	If InteractionsArray.Count() > 0 Then
		RefreshNavigationPanel();
	EndIf;
	
EndProcedure

&AtClient
Procedure CreateNewInteraction(ObjectType)
	
	CreationParameters = New Structure;
		
	If CurrentNavigationPanelName = "ContactPage" Then
		CurrentData = Items.NavigationPanelContacts.CurrentData;
		If CurrentData <> Undefined Then
			CreationParameters.Insert("FillingValues",New Structure("Contact", CurrentData.Contact));
		EndIf;
	ElsIf CurrentNavigationPanelName = "SubjectPage" Then
		CurrentData = Items.NavigationPanelSubjects.CurrentData;
		If CurrentData <> Undefined Then
			CreationParameters.Insert("FillingValues",New Structure("Topic", CurrentData.Topic));
		EndIf;
	EndIf;
	
	InteractionsClient.CreateNewInteraction(ObjectType,CreationParameters, ThisObject);

EndProcedure

&AtServer
Function GetInteractionsByListFilter(AdditionalFilterAttributeValue = Undefined, AdditionalFilterAttributeName = "")
	
	Query = New Query;
	
	If Items.NavigationPanelPages.CurrentPage = Items.ContactPage Then
		FilterScheme = DocumentJournals.Interactions.GetTemplate("SchemaFilterInteractionsContact");
	Else
		FilterScheme = DocumentJournals.Interactions.GetTemplate("SchemaInteractionsFilter");
	EndIf;
	
	TemplateComposer = New DataCompositionTemplateComposer();
	SettingsComposer = New DataCompositionSettingsComposer;
	SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(FilterScheme));
	SettingsComposer.LoadSettings(FilterScheme.DefaultSettings);
	
	CopyFilter(SettingsComposer.Settings.Filter, InteractionsClientServer.DynamicListFilter(List));
	
	// Adding a filter with a comparison kind NOT for group commands.
	If AdditionalFilterAttributeValue <> Undefined Then
		FilterItem = SettingsComposer.Settings.Filter.Items.Add(Type("DataCompositionFilterItem"));
		FilterItem.LeftValue = New DataCompositionField(AdditionalFilterAttributeName);
		FilterItem.ComparisonType = DataCompositionComparisonType.NotEqual;
		FilterItem.RightValue = AdditionalFilterAttributeValue;
	EndIf;
	
	DataCompositionTemplate = TemplateComposer.Execute(FilterScheme, SettingsComposer.GetSettings()
		,,, Type("DataCompositionValueCollectionTemplateGenerator"));
	
	QueryText = DataCompositionTemplate.DataSets.MainDataSet.Query;
	
	For each Parameter In DataCompositionTemplate.ParameterValues Do
		Query.Parameters.Insert(Parameter.Name, Parameter.Value);
	EndDo;
	
	Query.Text = QueryText;
	
	Return Query.Execute().Unload().UnloadColumn("Ref");
	
EndFunction

&AtServer
Procedure SetFolderParent(Folder, NewParent)
	
	Interactions.SetFolderParent(Folder, NewParent);
	RefreshNavigationPanel();
	
EndProcedure

&AtServer
Procedure ExecuteTransferToEmailsArrayFolder(VAL EmailsArray, Folder)

	Interactions.SetFolderForEmailsArray(EmailsArray, Folder);
	RefreshNavigationPanel(Folder);

EndProcedure

/////////////////////////////////////////////////////////////////////////////////////////
// Full-text search

&AtServer
Procedure DetermineAvailabilityFullTextSearch() 
	
	If GetFunctionalOption("UseFullTextSearch") 
		AND FullTextSearch.GetFullTextSearchMode() = FullTextSearchMode.Enable Then
		SearchHistory = Common.CommonSettingsStorageLoad("InteractionSearchHistory", "");
		If SearchHistory <> Undefined Then
			Items.SearchString.ChoiceList.LoadValues(SearchHistory);
		EndIf;
	Else
		Items.SearchString.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteFullTextSearch()
	
	FoundItemsCount = 0;
	ErrorText = FindInteractionsFullTextSearch(FoundItemsCount);
	If ErrorText = Undefined Then
		AdvancedSearch = True;
		NotificationText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Найдено %1 %2.'; en = 'Found %1 %2.'; pl = 'Found %1 %2.';de = 'Found %1 %2.';ro = 'Found %1 %2.';tr = 'Found %1 %2.'; es_ES = 'Found %1 %2.'"),
			?(EmailOnly,NStr("ru = 'писем'; en = 'emails'; pl = 'emails';de = 'emails';ro = 'emails';tr = 'emails'; es_ES = 'emails'"), NStr("ru = 'взаимодействий'; en = 'interactions'; pl = 'interactions';de = 'interactions';ro = 'interactions';tr = 'interactions'; es_ES = 'interactions'")) + ": ",
			String(FoundItemsCount));
		ShowUserNotification(NotificationText);
		CurrentData = Items.List.CurrentData;
		If CurrentData <> Undefined Then
			FillDetailsSPFound(Items.List.CurrentData.Ref);
		Else
			DetailSPFound = "";
		EndIf;
	Else
		If NOT ErrorText = NStr("ru = 'Ничего не найдено'; en = 'No results found'; pl = 'No results found';de = 'No results found';ro = 'No results found';tr = 'No results found'; es_ES = 'No results found'") Then
			ShowUserNotification(ErrorText);
		Else
			AdvancedSearch = False;
		EndIf;
	EndIf;
	
	Items.DetailSPFound.Visible = AdvancedSearch;
	
EndProcedure

&AtServer
Function FindInteractionsFullTextSearch(ItemsCount)

	// set search parameters
	SearchArea = New Array;
	BatchSize = 200;
	SearchList = FullTextSearch.CreateList(SearchString, BatchSize);
	SearchArea.Add(Metadata.Documents.IncomingEmail);
	SearchArea.Add(Metadata.Documents.OutgoingEmail);
	SearchArea.Add(Metadata.Catalogs.IncomingEmailAttachedFiles);
	SearchArea.Add(Metadata.Catalogs.OutgoingEmailAttachedFiles);
	SearchArea.Add(Metadata.InformationRegisters.InteractionsFolderSubjects);

	If Not EmailOnly Then
		SearchArea.Add(Metadata.Documents.PhoneCall);
		SearchArea.Add(Metadata.Documents.Meeting);
		SearchArea.Add(Metadata.Documents.PlannedInteraction);
		SearchArea.Add(Metadata.Catalogs.PhoneCallAttachedFiles);
		SearchArea.Add(Metadata.Catalogs.MeetingAttachedFiles);
		SearchArea.Add(Metadata.Catalogs.PlannedInteractionAttachedFiles);
	EndIf;
	SearchList.SearchArea = SearchArea;

	SearchList.FirstPart();

	// Return if search has too many results.
	If SearchList.TooManyResults() Then
		CommonClientServer.SetDynamicListFilterItem(
			List,
			"Search",
			Documents.IncomingEmail.EmptyRef(),
			DataCompositionComparisonType.Equal,, True);
		Items.SearchString.BackColor = StyleColors.ErrorFullTextSearchBackground;
		Return NStr("ru = 'Слишком много результатов, уточните запрос.'; en = 'Too many results, narrow your search.'; pl = 'Too many results, narrow your search.';de = 'Too many results, narrow your search.';ro = 'Too many results, narrow your search.';tr = 'Too many results, narrow your search.'; es_ES = 'Too many results, narrow your search.'");
	EndIf;

	// Return if search has no results.
	If SearchList.TotalCount() = 0 Then
		CommonClientServer.SetDynamicListFilterItem(
			List,
			"Search",
			Documents.IncomingEmail.EmptyRef(),
			DataCompositionComparisonType.Equal,, True);
		Items.SearchString.BackColor = StyleColors.ErrorFullTextSearchBackground;
		Return NStr("ru = 'Ничего не найдено'; en = 'No results found'; pl = 'No results found';de = 'No results found';ro = 'No results found';tr = 'No results found'; es_ES = 'No results found'");
	EndIf;
	
	ItemsCount = SearchList.TotalCount();
	
	StartPosition = 0;
	EndPosition = ?(ItemsCount > BatchSize, BatchSize, ItemsCount) - 1;
	HasNextBatch = True;

	// Process the FTS results by portions.
	While HasNextBatch Do
		For ItemsCounter = 0 To EndPosition Do
			
			Item = SearchList.Get(ItemsCounter);
			NewRow = DetailsSPFound.Add();
			FillPropertyValues(NewRow,Item);
			If InteractionsClientServer.IsAttachedInteractionsFile(Item.Value) Then
				NewRow.Interaction = Item.Value.FileOwner;
			ElsIf TypeOf(Item.Value) = Type("InformationRegisterRecordKey.InteractionsFolderSubjects") Then
				NewRow.Interaction =  Item.Value.Interaction;
			Else
				NewRow.Interaction = Item.Value;
			EndIf;
			
		EndDo;
		StartPosition = StartPosition + BatchSize;
		HasNextBatch = (StartPosition < ItemsCount - 1);
		If HasNextBatch Then
			EndPosition = 
			?(ItemsCount > StartPosition + BatchSize, BatchSize,
			ItemsCount - StartPosition) - 1;
			SearchList.NextPart();
		EndIf;
	EndDo;
	
	If DetailsSPFound.Count() = 0 Then
		CommonClientServer.SetDynamicListFilterItem(
			List,
			"Search",
			Documents.IncomingEmail.EmptyRef(),
			DataCompositionComparisonType.Equal,, True);
		Items.SearchString.BackColor = StyleColors.ErrorFullTextSearchBackground;
		Return NStr("ru = 'Ничего не найдено.'; en = 'None found.'; pl = 'None found.';de = 'None found.';ro = 'None found.';tr = 'None found.'; es_ES = 'None found.'");
	EndIf;
	
	// Deleting an item from search history if it was there.
	NumberOfFoundListItem = Items.SearchString.ChoiceList.FindByValue(SearchString);
	While NumberOfFoundListItem <> Undefined Do
		Items.SearchString.ChoiceList.Delete(NumberOfFoundListItem);
		NumberOfFoundListItem = Items.SearchString.ChoiceList.FindByValue(SearchString);
	EndDo;
	
	// And put it on top.
	Items.SearchString.ChoiceList.Insert(0, SearchString);
	While Items.SearchString.ChoiceList.Count() > 100 Do
		Items.SearchString.ChoiceList.Delete(Items.SearchString.ChoiceList.Count() - 1);
	EndDo;
	Common.CommonSettingsStorageSave(
		"InteractionSearchHistory",
		"",
		Items.SearchString.ChoiceList.UnloadValues());
	
	CommonClientServer.SetDynamicListFilterItem(
			List,
			"Search",
			DetailsSPFound.Unload(,"Interaction").UnloadColumn("Interaction"),
			DataCompositionComparisonType.InList,, True);
			
	Items.SearchString.BackColor = StyleColors.FieldBackColor;
	Return Undefined;
	
EndFunction

&AtClient
Procedure FillDetailsSPFound(Interaction)

	DetailsString = DetailsSPFound.FindRows(New Structure("Interaction",Interaction));
	If DetailsString.Count() = 0 Then
		DetailSPFound = "";
	Else
		TableRowWithDetails = DetailsString[0];
		If InteractionsClientServer.IsAttachedInteractionsFile(TableRowWithDetails.Value) Then
			TextFound = NStr("ru = 'Найдено в присоединенном файле'; en = 'Found in the attached file'; pl = 'Found in the attached file';de = 'Found in the attached file';ro = 'Found in the attached file';tr = 'Found in the attached file'; es_ES = 'Found in the attached file'");
		Else
			TextFound = NStr("ru = 'Найдено в'; en = 'Found in'; pl = 'Found in';de = 'Found in';ro = 'Found in';tr = 'Found in'; es_ES = 'Found in'");
		EndIf;
		
		DetailSPFound = TextFound + " - " + TableRowWithDetails.Details;
	EndIf;

EndProcedure 

///////////////////////////////////////////////////////////////////////////////
// Other procedures and functions

&AtServer
Function FindRowInCollectionFormData(WhereToFind, Value, Column)

	FoundRows = WhereToFind.FindRows(New Structure(Column, Value));
	If FoundRows.Count() > 0 Then
		Return FoundRows[0].GetID();
	EndIf;
	
	Return -1;
	
EndFunction

&AtServer
Function FindStringInFormDataTree(WhereToFind, Value, Column, SearchSubordinateItems)
	
	TreeItems = WhereToFind.GetItems();
	
	For each TreeItem In TreeItems Do
		If TreeItem[Column] = Value Then
			Return TreeItem.GetID();
		ElsIf  SearchSubordinateItems Then
			FoundRowID =  FindStringInFormDataTree(TreeItem, Value,Column, SearchSubordinateItems);
			If FoundRowID >=0 Then
				Return FoundRowID;
			EndIf;
		EndIf;
	EndDo;
	
	Return -1;
	
EndFunction

&AtClient
Function CurrentItemNavigationPanelList()

	If Items.NavigationPanelPages.CurrentPage = Items.ContactPage Then
		Return Items.NavigationPanelContacts;
	ElsIf Items.NavigationPanelPages.CurrentPage = Items.SubjectPage Then
		Return Items.NavigationPanelSubjects;
	ElsIf Items.NavigationPanelPages.CurrentPage = Items.FoldersPage Then
		Return Items.Folders;
	ElsIf Items.NavigationPanelPages.CurrentPage = Items.PropertiesPage Then
		Return Items.Properties;
	ElsIf Items.NavigationPanelPages.CurrentPage = Items.CategoriesPage Then
		Return Items.Categories;
	Else
		Return Undefined;
	EndIf;

EndFunction

&AtClient
Function CorrectChoice(ListName, ByCurrentString = False)
	
	GroupingType = Type("DynamicalListGroupRow");
	If ByCurrentString Then
		
		If TypeOf(Items[ListName].CurrentRow) <> GroupingType AND Items[ListName].CurrentData <> Undefined Then
			Return True;
		EndIf;
		
	Else
		
		For Each Item In Items[ListName].SelectedRows Do
			If TypeOf(Item) <> GroupingType Then
				Return True;
			EndIf;
		EndDo;
		
	EndIf;
	
	Return False;
	
EndFunction 

&AtServer
Procedure CopyFilter(Destination, Source, DeleteGroupPresentation = False, DeleteUnusedItems = True, DoNotEnableNavigationPanelFilter = False)
	
	For each SourceFilterItem In Source.Items Do
		
		If DeleteUnusedItems AND (Not SourceFilterItem.Use) Then
			Continue;
		EndIf;
		
		If DoNotEnableNavigationPanelFilter AND TypeOf(SourceFilterItem) = Type("DataCompositionFilterItemGroup") 
			AND SourceFilterItem.Presentation = "FIlterNavigationPanel" Then
			
			Continue;
			
		EndIf;
		
		If TypeOf(SourceFilterItem) = Type("DataCompositionFilterItem") 
			AND SourceFilterItem.LeftValue = New DataCompositionField("Search") Then
			Continue;
		EndIf;
		
		FilterItem = Destination.Items.Add(TypeOf(SourceFilterItem));
		FillPropertyValues(FilterItem, SourceFilterItem);
		If TypeOf(SourceFilterItem) = Type("DataCompositionFilterItemGroup") Then
			If DeleteGroupPresentation Then
				FilterItem.Presentation = "";
			EndIf;
			CopyFilter(FilterItem, SourceFilterItem);
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure QuestionOnFolderDeletionAfterCompletion(QuestionResult, AdditionalParameters) Export

	If QuestionResult = DialogReturnCode.Yes Then
		
		ErrorDescription =  DeleteFolderServer(AdditionalParameters.CurrentData.Value);
		If NOT IsBlankString(ErrorDescription) Then
			ShowMessageBox(, ErrorDescription);
		Else
			RestoreExpandedTreeNodes();
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessingDateChoiceOnCompletion(SelectedDate, AdditionalParameters) Export
	
	CurrentItemName = AdditionalParameters.CurrentItemName;
	
	If SelectedDate <> Undefined Then
		DeferReview(SelectedDate, ?(CurrentItemName = Undefined, Undefined, Items[CurrentItemName].SelectedRows));
		RestoreExpandedTreeNodes();
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateNavigationPanelAtServer()
	
	RefreshNavigationPanel();
	ManageVisibilityOnSwitchNavigationPanel();
	
EndProcedure

&AtServer
Procedure PrepareFormSettingsForCurrentRefOutput(CurrentRef)
	CurrentNavigationPanelName = "SubjectPage";
	If InteractionsClientServer.IsSubject(CurrentRef) Then
		Topic = CurrentRef;
	ElsIf InteractionsClientServer.IsInteraction(CurrentRef) Then
		Topic = Interactions.InteractionAttributesStructure(CurrentRef).Topic;
	Else
		Topic = Undefined;
	EndIf;
	If ValueIsFilled(Topic) Then
		Items.NavigationPanelSubjects.CurrentRow = InformationRegisters.InteractionsSubjectsStates.CreateRecordKey(New Structure("Topic", Topic));
		ChangeFilterList("Subjects", New Structure("Value, TypeDescription", Topic, Undefined));
	EndIf;
EndProcedure

&AtServer
Procedure NavigationProcessingAtServer(CurrentRef)
	PrepareFormSettingsForCurrentRefOutput(CurrentRef);
	
	If SearchString <> "" Then
		SearchString = "";
		AdvancedSearch = False;
		CommonClientServer.SetDynamicListFilterItem(
			List, 
			"Search",
			Undefined,
			DataCompositionComparisonType.Equal,,False);
		Items.DetailSPFound.Visible = AdvancedSearch;
	EndIf;
	
	InteractionType = "All";
	Status = "All";
	EmployeeResponsible = Undefined;
	InteractionsClientServer.QuickFilterListOnChange(ThisObject,"EmployeeResponsible");
	OnChangeTypeServer(True);
	
	NavigationPanelHidden = False;
	Items.NavigationPanelPages.CurrentPage = Items[CurrentNavigationPanelName];
	ManageVisibilityOnSwitchNavigationPanel();
EndProcedure

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

&AtClient
Procedure WarningAboutUnsafeContentURLProcessing(Item, FormattedStringURL, StandardProcessing)
	If FormattedStringURL = "EnableUnsafeContent" Then
		StandardProcessing = False;
		EnableUnsafeContent = True;
		DisplayInteractionPreview(InteractionPreviewGeneratedFor, Items.PagesPreview.CurrentPage.Name);
	EndIf;
EndProcedure

// End StandardSubsystems.AttachableCommands

&AtClientAtServerNoContext
Procedure SetSecurityWarningVisiblity(Form)
	Form.Items.SecurityWarning.Visible = Not Form.UnsafeContentDisplayInEmailsProhibited
		AND Form.HasUnsafeContent AND Not Form.EnableUnsafeContent;
EndProcedure

#EndRegion
