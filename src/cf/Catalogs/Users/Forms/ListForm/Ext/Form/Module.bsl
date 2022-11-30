///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
//                          HOW TO USE THE FORM                               //
//
// Additional form opening parameters:
//
// ExtendedPick - Boolean - if True, open the extended form for picking users.
//   The extended form requires the
//  ExtendedPickFormParameters parameter.
// ExtendedPickFormParameters - String - reference to a structure that contains extended parameters 
//  for the form used for picking users. The structure is located in a temporary storage.
//  
//  Structure parameters:
//    PickFormTitle - String - the title of the form for picking users.
//    SelectedUsers - Array - an array of previously selected users.
//

#Region Variables

&AtClient
Var LastItem;

#EndRegion

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// The initial setting value (before loading data from the settings).
	SelectHierarchy = True;
	
	FillStoredParameters();
	
	If Parameters.ChoiceMode Then
		StandardSubsystemsServer.SetFormAssignmentKey(ThisObject, "SelectionPick");
		WindowOpeningMode = FormWindowOpeningMode.LockOwnerWindow;
		
	ElsIf Users.IsFullUser() Then
		// Adding the filter by users added by the person responsible for the list.
		CommonClientServer.SetDynamicListFilterItem(
			UsersList, "Prepared", True, ,
			NStr("ru = 'Подготовленные ответственным за список'; en = 'Prepared by person responsible for the list'; pl = 'Przygotowane przez osobę odpowiedzialną za listę';de = 'Erstellt durch den Verantwortlichen der Liste';ro = 'Pregătite de responsabilul pentru listă';tr = 'Liste sorumlusu tarafından hazırlananlar'; es_ES = ' Preparado por el responsable de la lista'"), False,
			DataCompositionSettingsItemViewMode.Normal);
	EndIf;
	
	// If the parameter value is True, hiding users with empty IDs.
	If Parameters.HideUsersWithoutMatchingIBUsers Then
		CommonClientServer.SetDynamicListFilterItem(
			UsersList,
			"IBUserID",
			CommonClientServer.BlankUUID(),
			DataCompositionComparisonType.NotEqual);
	EndIf;
	
	// Hiding internal users.
	If Users.IsFullUser() Then
		CommonClientServer.SetDynamicListFilterItem(
			UsersList, "Internal", False, , , True,
			DataCompositionSettingsItemViewMode.Normal,
			String(New UUID));
	Else
		CommonClientServer.SetDynamicListFilterItem(
			UsersList, "Internal", False, , , True);
	EndIf;
	
	// Hiding the user passed from the user selection form.
	If TypeOf(Parameters.UsersToHide) = Type("ValueList") Then
		
		DCComparisonType = DataCompositionComparisonType.NotInList;
		CommonClientServer.SetDynamicListFilterItem(
			UsersList,
			"Ref",
			Parameters.UsersToHide,
			DCComparisonType);
		
	EndIf;
	
	ApplyConditionalAppearanceAndHideInvalidUsers();
	SetUpUserListParametersForSetPasswordCommand();
	SetAllUsersGroupOrder(UserGroups);
	
	StoredParameters.Insert("AdvancedPick", Parameters.AdvancedPick);
	Items.SelectedUsersAndGroups.Visible = StoredParameters.AdvancedPick;
	StoredParameters.Insert(
		"UseGroups", GetFunctionalOption("UseUserGroups"));
	
	DataSeparationEnabled = Common.DataSeparationEnabled();
	If NOT Users.IsFullUser(, Not DataSeparationEnabled) Then
		If Items.Find("IBUsers") <> Undefined Then
			Items.IBUsers.Visible = False;
		EndIf;
		Items.UsersInfo.Visible = False;
	EndIf;
	
	If Parameters.ChoiceMode Then
	
		If Items.Find("IBUsers") <> Undefined Then
			Items.IBUsers.Visible = False;
		EndIf;
		Items.UsersInfo.Visible = False;
		Items.UserGroups.ChoiceMode = StoredParameters.UsersGroupsSelection;
		// Disabling dragging users in the "select users" and "pick users" forms.
		Items.UsersList.EnableStartDrag = False;
		
		If Parameters.Property("NonExistingIBUsersIDs") Then
			CommonClientServer.SetDynamicListFilterItem(
				UsersList, "IBUserID",
				Parameters.NonExistingIBUsersIDs,
				DataCompositionComparisonType.InList, , True,
				DataCompositionSettingsItemViewMode.Inaccessible);
		EndIf;
		
		If Parameters.CloseOnChoice = False Then
			// Pick mode.
			Items.UsersList.MultipleChoice = True;
			
			If StoredParameters.AdvancedPick Then
				StandardSubsystemsServer.SetFormAssignmentKey(ThisObject, "AdvancedPick");
				ChangeExtendedPickFormParameters();
			EndIf;
			
			If StoredParameters.UsersGroupsSelection Then
				Items.UserGroups.MultipleChoice = True;
			EndIf;
		EndIf;
	Else
		Items.UsersList.ChoiceMode  = False;
		Items.UserGroups.ChoiceMode = False;
		Items.Comments.Visible = False;
		
		CommonClientServer.SetFormItemProperty(Items,
			"SelectUser", "Visible", False);
		
		CommonClientServer.SetFormItemProperty(Items,
			"SelectUsersGroup", "Visible", False);
	EndIf;
	
	StoredParameters.Insert("AllUsersGroup", Catalogs.UserGroups.AllUsers);
	StoredParameters.Insert("CurrentRow", Parameters.CurrentRow);
	ConfigureUserGroupsUsageForm();
	StoredParameters.Delete("CurrentRow");
	
	If Not Common.SubsystemExists("StandardSubsystems.BatchEditObjects")
	 Or Not Users.IsFullUser()
	 Or Common.IsStandaloneWorkplace() Then
		
		Items.FormEditSelectedItems.Visible = False;
		Items.UsersListContextMenuChangeSelectedItems.Visible = False;
	EndIf;
	
	ObjectDetails = New Structure;
	ObjectDetails.Insert("Ref", Catalogs.Users.EmptyRef());
	ObjectDetails.Insert("IBUserID", CommonClientServer.BlankUUID());
	AccessLevel = UsersInternal.UserPropertiesAccessLevel(ObjectDetails);
	
	If Not AccessLevel.ListManagement Then
		Items.FormSetPassword.Visible = False;
		Items.UsersListContextMenuSetPassword.Visible = False;
	EndIf;
	
	If Common.IsStandaloneWorkplace() Then
		ReadOnly = True;
		Items.UserGroups.ReadOnly = True;
	EndIf;
	
	If Common.IsMobileClient() Then
		Items.EndAndClose.Representation = ButtonRepresentation.Picture;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Parameters.ChoiceMode Then
		CurrentFormItemModificationCheck();
	EndIf;
	
#If MobileClient Then
	If StoredParameters.Property("UseGroups") AND StoredParameters.UseGroups Then
		Items.GroupsGroup.Title = String(Items.UserGroups.CurrentData.Ref);
	EndIf;
#EndIf
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If Upper(EventName) = Upper("Write_UserGroups")
	   AND Source = Items.UserGroups.CurrentRow Then
		
		Items.UsersList.Refresh();
		
	ElsIf Upper(EventName) = Upper("Write_ConstantsSet") Then
		
		If Upper(Source) = Upper("UseUserGroups") Then
			AttachIdleHandler("UserGroupsUsageOnChange", 0.1, True);
		EndIf;
		
	ElsIf Upper(EventName) = Upper("ArrangeUsersInGroups") Then
		
		Items.UsersList.Refresh();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeImportDataFromSettingsAtServer(Settings)
	
	If TypeOf(Settings["SelectHierarchy"]) = Type("Boolean") Then
		SelectHierarchy = Settings["SelectHierarchy"];
	EndIf;
	
	If NOT SelectHierarchy Then
		RefreshFormContentOnGroupChange(ThisObject);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SelectHierarchicallyOnChange(Item)
	
	RefreshFormContentOnGroupChange(ThisObject);
	
EndProcedure

&AtClient
Procedure ShowInvalidUsersOnChange(Item)
	ToggleInvalidUsersVisibility(ShowInvalidUsers);
EndProcedure

#EndRegion

#Region UserGroupsFormTableItemsEventHandlers

&AtClient
Procedure UserGroupsOnChange(Item)
	
	ListOnChangeAtServer();
	
EndProcedure

&AtClient
Procedure UserGroupsOnActivateRow(Item)
	
	AttachIdleHandler("UserGroupsAfterActivateRow", 0.1, True);
	
EndProcedure

&AtClient
Procedure UserGroupsValueChoice(Item, Value, StandardProcessing)
	
	StandardProcessing = False;
	
	If Not StoredParameters.AdvancedPick Then
		NotifyChoice(Value);
	Else
		GetPicturesAndFillSelectedItemsList(Value);
	EndIf;
	
EndProcedure

&AtClient
Procedure UserGroupsBeforeAddRow(Item, Cancel, Clone, Parent, Folder)
	
	If NOT Clone Then
		Cancel = True;
		FormParameters = New Structure;
		
		If ValueIsFilled(Items.UserGroups.CurrentRow) Then
			FormParameters.Insert(
				"FillingValues",
				New Structure("Parent", Items.UserGroups.CurrentRow));
		EndIf;
		
		OpenForm(
			"Catalog.UserGroups.ObjectForm",
			FormParameters,
			Items.UserGroups);
	EndIf;
	
EndProcedure

&AtClient
Procedure UserGroupsDrag(Item, DragParameters, StandardProcessing, Row, Field)
	
	StandardProcessing = False;
	
	If SelectHierarchy Then
		ShowMessageBox(,
			NStr("ru = 'Для перетаскивания пользователя в группы необходимо отключить
			           |флажок ""Показывать пользователей нижестоящих групп"".'; 
			           |en = 'To allow dragging users to groups, clear the 
			           |""Show users that belong to subgroups"" check box.'; 
			           |pl = 'Aby przeciągać użytkowników do grup, należy wyłączyć
			           |zaznaczenie ""Показывать пользователей нижестоящих групп"".';
			           |de = 'Um einen Benutzer in eine Gruppe zu ziehen, müssen Sie das
			           |Kontrollkästchen ""Benutzer der unteren Gruppen anzeigen"" deaktivieren.';
			           |ro = 'Pentru a glisa utilizatorul în grupuri debifați
			           |caseta de selectare ""Afișare utilizatorii grupurilor inferioare"".';
			           |tr = 'Kullanıcıyı gruplara  taşımak için, ""Alt grubun kullanıcılarını göster"" onay kutusu 
			           | temizlenmelidir. '; 
			           |es_ES = 'Para arrastrar los nombres de usuario para los grupos quitar
			           |la casilla de verificación ""Mostrar los usuarios del grupo menor"".'"));
		Return;
	EndIf;
	
	If Items.UserGroups.CurrentRow = Row
		Or Row = Undefined Then
		Return;
	EndIf;
	
	If DragParameters.Action = DragAction.Move Then
		Move = True;
	Else
		Move = False;
	EndIf;
	
	GroupMarkedForDeletion = Items.UserGroups.RowData(Row).DeletionMark;
	UsersCount = DragParameters.Value.Count();
	
	ActionExcludeUser = (StoredParameters.AllUsersGroup = Row);
	
	ActionWithUser = ?((StoredParameters.AllUsersGroup = Items.UserGroups.CurrentRow),
		NStr("ru = 'Включить'; en = 'add'; pl = 'Włącz';de = 'hinzufügen';ro = 'adăugați';tr = 'ekle'; es_ES = 'añadir'"),
		?(Move, NStr("ru = 'Переместить'; en = 'move'; pl = 'Przenieś';de = 'Verschieben';ro = 'Mutare';tr = 'Taşı'; es_ES = 'Trasladar'"), NStr("ru = 'Скопировать'; en = 'copy'; pl = 'kopiuj';de = 'kopieren';ro = 'copie';tr = 'kopyala'; es_ES = 'copiar'")));
	
	If GroupMarkedForDeletion Then
		ActionTemplate = ?(Move,
			NStr("ru = 'Группа ""%1"" помечена на удаление. %2'; en = 'Group ""%1"" is marked for deletion. %2'; pl = 'Grupa ""%1"" jest oznaczona do usunięcia. %2';de = 'Die Gruppe ""%1"" wird zum Löschen markiert. %2';ro = 'Grupul ""%1"" este marcat la ștergere. %2';tr = '""%1"" grubu silinmek üzere işaretlendi. %2'; es_ES = 'El grupo ""%1"" está marcado para borrar.%2'"),
			NStr("ru = 'Группа ""%1"" помечена на удаление. %2'; en = 'Group ""%1"" is marked for deletion. %2'; pl = 'Grupa ""%1"" jest oznaczona do usunięcia. %2';de = 'Die Gruppe ""%1"" wird zum Löschen markiert. %2';ro = 'Grupul ""%1"" este marcat la ștergere. %2';tr = '""%1"" grubu silinmek üzere işaretlendi. %2'; es_ES = 'El grupo ""%1"" está marcado para borrar.%2'"));
		ActionWithUser = StringFunctionsClientServer.SubstituteParametersToString(ActionTemplate, String(Row), ActionWithUser);
	EndIf;
	
	If UsersCount = 1 Then
		If ActionExcludeUser Then
			QuestionText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Исключить пользователя ""%1"" из группы ""%2""?'; en = 'Do you want to exclude the user ""%1"" from the group ""%2""?'; pl = 'Wykluczyć użytkownika ""%1"" z grupy ""%2""?';de = 'Den Benutzer ""%1"" aus der Gruppe ""%2"" ausschließen?';ro = 'Excludeți utilizatorul ""%1"" din grupul ""%2""?';tr = '""%1"" kullanıcısı ""%2"" grubundan çıkarılsın mı?'; es_ES = 'Excluir el usuario ""%1"" del grupo ""%2""?'"),
				String(DragParameters.Value[0]),
				String(Items.UserGroups.CurrentRow));
			
		ElsIf Not GroupMarkedForDeletion Then
			QuestionText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = '%1 пользователя ""%2"" в группу ""%3""?'; en = 'Do you want to %1 the user ""%2"" to the group ""%3""?'; pl = '%1 użytkownika ""%2"" do grupy ""%3""?';de = '%1 Benutzer ""%2"" zur Gruppe ""%3""?';ro = '%1 utilizatorul ""%2"" în grupul ""%3""?';tr = '%1 ""%2"" kullanıcıyı ""%3"" grubuna?'; es_ES = '¿%1 usuario ""%2"" al grupo ""%3""?'"),
				ActionWithUser,
				String(DragParameters.Value[0]),
				String(Row));
		Else
			QuestionText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = '%1 пользователя ""%2"" в эту группу?'; en = 'Do you want to %1 the user ""%2"" to this group?'; pl = '%1 użytkownika ""%2"" do tej grupy?';de = '%1 Benutzer ""%2"" zu dieser Gruppe?';ro = '%1 utilizatorul ""%2"" în acest grup?';tr = '%1 ""%2"" kullanıcıyı bu gruba?'; es_ES = '%1 usuario ""%2"" a este grupo?'"),
				ActionWithUser,
				String(DragParameters.Value[0]));
		EndIf;
	Else
		If ActionExcludeUser Then
			QuestionText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Исключить пользователей (%1) из группы ""%2""?'; en = 'Do you want to exclude %1 users from the group ""%2""?'; pl = 'Wykluczyć użytkowników (%1) z grupy ""%2""?';de = 'Benutzer (%1) aus der Gruppe ""%2"" ausschließen?';ro = 'Excludeți utilizatorul (%1) din grupul ""%2""?';tr = '(%1) kullanıcılar ""%2"" grubundan çıkarılsın mı?'; es_ES = 'Excluir usuarios (%1) del grupo ""%2""?'"),
				UsersCount,
				String(Items.UserGroups.CurrentRow));
			
		ElsIf Not GroupMarkedForDeletion Then
			QuestionText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = '%1 пользователей (%2) в группу ""%3""?'; en = 'Do you want to %1 %2 users to the group ""%3""?'; pl = '%1 użytkowników (%2) do grupy ""%3""?';de = '%1 Benutzer (%2) zur Gruppe ""%3""?';ro = '%1 utilizatorii (%2) în grupul ""%3""?';tr = '%1 kullanıcılar (%2 ) ""%3 ""grubuna?'; es_ES = '¿%1 usuarios (%2) al grupo ""%3""?'"),
				ActionWithUser,
				UsersCount,
				String(Row));
		Else
			QuestionText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = '%1 пользователей (%2) в эту группу?'; en = 'Do you want to %1 %2 users to this group?'; pl = '%1 użytkowników (%2) do tej grupy?';de = '%1 Benutzer (%2) zu dieser Gruppe?';ro = '%1 utilizatori (%2) în acest grup?';tr = '%1 kullanıcılar (%2) bu gruba?'; es_ES = '¿%1 usuarios (%2) a este grupo?'"),
				ActionWithUser,
				UsersCount);
		EndIf;
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("DragParameters", DragParameters.Value);
	AdditionalParameters.Insert("Row", Row);
	AdditionalParameters.Insert("Move", Move);
	
	Notification = New NotifyDescription("UserGroupsDragCompletion", ThisObject, AdditionalParameters);
	ShowQueryBox(Notification, QuestionText, QuestionDialogMode.YesNo, 60, DialogReturnCode.Yes);
	
EndProcedure

&AtClient
Procedure UserGroupsDragCheck(Item, DragParameters, StandardProcessing, Row, Field)
	
	If Items.UserGroups.ReadOnly Then
		DragParameters.AllowedActions = DragAllowedActions.DontProcess;
	Else
		StandardProcessing = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region UsersListFormTableItemsEventHandlers

&AtClient
Procedure UsersListOnChange(Item)
	
	ListOnChangeAtServer();
	
EndProcedure

&AtClient
Procedure UsersListOnActivateRow(Item)
	
	If StandardSubsystemsClient.IsDynamicListItem(Items.UsersList) Then
		CanChangePassword = Items.UsersList.CurrentData.CanChangePassword;
	Else
		CanChangePassword = False;
	EndIf;
	
	Items.FormSetPassword.Enabled = CanChangePassword;
	Items.UsersListContextMenuSetPassword.Enabled = CanChangePassword;
	
EndProcedure

&AtClient
Procedure UsersListValueChoice(Item, Value, StandardProcessing)
	
	StandardProcessing = False;
	
	If Not StoredParameters.AdvancedPick Then
		NotifyChoice(Value);
	Else
		GetPicturesAndFillSelectedItemsList(Value);
	EndIf;
	
EndProcedure

&AtClient
Procedure UsersListBeforeAddRow(Item, Cancel, Clone, Parent, Folder)
	
	Cancel = True;
	
	FormParameters = New Structure;
	FormParameters.Insert("NewUserGroup", Items.UserGroups.CurrentRow);
	
	If Clone AND Item.CurrentData <> Undefined Then
		FormParameters.Insert("CopyingValue", Item.CurrentRow);
	EndIf;
	
	OpenForm("Catalog.Users.ObjectForm", FormParameters, Items.UsersList);
	
EndProcedure

&AtClient
Procedure UsersListBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	
	If Not ValueIsFilled(Item.CurrentRow) Then
		Return;
	EndIf;
	
	FormParameters = New Structure("Key", Item.CurrentRow);
	OpenForm("Catalog.Users.ObjectForm", FormParameters, Item);
	
EndProcedure

&AtClient
Procedure UsersListDragCheck(Item, DragParameters, StandardProcessing, Row, Field)
	
	StandardProcessing = False;
	
EndProcedure

#EndRegion

#Region SelectedUsersAndGroupsListFormTableItemsEventHandlers

&AtClient
Procedure SelectedUsersAndGroupsListChoice(Item, RowSelected, Field, StandardProcessing)
	
	DeleteFromSelectedItems();
	SelectedUsersListLastModified = True;
	
EndProcedure

&AtClient
Procedure SelectedUsersAndGroupsListBeforeAddRow(Item, Cancel, Clone, Parent, Folder, Parameter)
	Cancel = True;
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure CreateUsersGroup(Command)
	
	Items.UserGroups.AddRow();
	
EndProcedure

&AtClient
Procedure AssignGroups(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("Users", Items.UsersList.SelectedRows);
	FormParameters.Insert("ExternalUsers", False);
	
	OpenForm("CommonForm.UserGroups", FormParameters);
	
EndProcedure

&AtClient
Procedure SetPassword(Command)
	
	CurrentData = Items.UsersList.CurrentData;
	
	If StandardSubsystemsClient.IsDynamicListItem(CurrentData) Then
		UsersInternalClient.OpenChangePasswordForm(CurrentData.Ref);
	EndIf;
	
EndProcedure

&AtClient
Procedure EndAndClose(Command)
	
	If StoredParameters.AdvancedPick Then
		UsersArray = SelectionResult();
		NotifyChoice(UsersArray);
		SelectedUsersListLastModified = False;
		Close(UsersArray);
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectUserCommand(Command)
	
	UsersArray = Items.UsersList.SelectedRows;
	GetPicturesAndFillSelectedItemsList(UsersArray);
	
EndProcedure

&AtClient
Procedure CancelUserOrGroupSelection(Command)
	
	DeleteFromSelectedItems();
	
EndProcedure

&AtClient
Procedure ClearSelectedUsersAndGroupsList(Command)
	
	DeleteFromSelectedItems(True);
	
EndProcedure

&AtClient
Procedure SelectGroup(Command)
	
	GroupsArray = Items.UserGroups.SelectedRows;
	GetPicturesAndFillSelectedItemsList(GroupsArray);
	
EndProcedure

&AtClient
Procedure UsersInfo(Command)
	
	OpenForm(
		"Report.UsersInfo.ObjectForm",
		New Structure("VariantKey", "UsersInfo"),
		ThisObject,
		"UsersInfo");
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Support of batch object change.

&AtClient
Procedure ChangeSelectedItems(Command)
	
	If CommonClient.SubsystemExists("StandardSubsystems.BatchEditObjects") Then
		ModuleBatchObjectModificationClient = CommonClient.CommonModule("BatchEditObjectsClient");
		ModuleBatchObjectModificationClient.ChangeSelectedItems(Items.UsersList, UsersList);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillStoredParameters()
	
	StoredParameters = New Structure;
	StoredParameters.Insert("UsersGroupsSelection", Parameters.UsersGroupsSelection);
	
EndProcedure

&AtServer
Procedure ApplyConditionalAppearanceAndHideInvalidUsers()
	
	// Conditional appearance.
	AppearanceItem = UsersList.SettingsComposer.Settings.ConditionalAppearance.Items.Add();
	AppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	AppearanceColorItem = AppearanceItem.Appearance.Items.Find("TextColor");
	AppearanceColorItem.Value = Metadata.StyleItems.InaccessibleCellTextColor.Value;
	AppearanceColorItem.Use = True;
	
	FilterItem = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem.LeftValue  = New DataCompositionField("Invalid");
	FilterItem.ComparisonType   = DataCompositionComparisonType.Equal;
	FilterItem.RightValue = True;
	FilterItem.Use  = True;
	
	// Hiding.
	CommonClientServer.SetDynamicListFilterItem(
		UsersList, "Invalid", False, , , True);
	
EndProcedure

&AtServer
Procedure SetAllUsersGroupOrder(List)
	
	Var Order;
	
	// Order.
	Order = List.SettingsComposer.Settings.Order;
	Order.UserSettingID = "DefaultOrder";
	
	Order.Items.Clear();
	
	OrderItem = Order.Items.Add(Type("DataCompositionOrderItem"));
	OrderItem.Field = New DataCompositionField("Predefined");
	OrderItem.OrderType = DataCompositionSortDirection.Desc;
	OrderItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	OrderItem = Order.Items.Add(Type("DataCompositionOrderItem"));
	OrderItem.Field = New DataCompositionField("Description");
	OrderItem.OrderType = DataCompositionSortDirection.Asc;
	OrderItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
EndProcedure

&AtServer
Procedure SetUpUserListParametersForSetPasswordCommand()
	
	UpdateDataCompositionParameterValue(UsersList, "CurrentIBUserID",
		InfoBaseUsers.CurrentUser().UUID);
	
	UpdateDataCompositionParameterValue(UsersList, "BlankUUID",
		CommonClientServer.BlankUUID());
	
	UpdateDataCompositionParameterValue(UsersList, "CanChangeOwnPasswordOnly",
		Not Users.IsFullUser());
	
EndProcedure

&AtClient
Procedure CurrentFormItemModificationCheck()
	
	If CurrentItem <> LastItem Then
		CurrentFormItemOnChange();
		LastItem = CurrentItem;
	EndIf;
	
#If WebClient Then
	AttachIdleHandler("CurrentFormItemModificationCheck", 0.7, True);
#Else
	AttachIdleHandler("CurrentFormItemModificationCheck", 0.1, True);
#EndIf
	
EndProcedure

&AtClient
Procedure CurrentFormItemOnChange()
	
	If CurrentItem = Items.UserGroups Then
		Items.Comments.CurrentPage = Items.GroupComment;
		
	ElsIf CurrentItem = Items.UsersList Then
		Items.Comments.CurrentPage = Items.UserComment;
		
	EndIf
	
EndProcedure

&AtServer
Procedure DeleteFromSelectedItems(DeleteAll = False)
	
	If DeleteAll Then
		SelectedUsersAndGroups.Clear();
		UpdateSelectedUsersAndGroupsListTitle();
		Return;
	EndIf;
	
	ListItemsArray = Items.SelectedUsersAndGroupsList.SelectedRows;
	For Each ListItem In ListItemsArray Do
		SelectedUsersAndGroups.Delete(SelectedUsersAndGroups.FindByID(ListItem));
	EndDo;
	
	UpdateSelectedUsersAndGroupsListTitle();
	
EndProcedure

&AtClient
Procedure GetPicturesAndFillSelectedItemsList(SelectedItemsArray)
	
	SelectedItemsAndPictures = New Array;
	For Each SelectedItem In SelectedItemsArray Do
		
		If TypeOf(SelectedItem) = Type("CatalogRef.Users") Then
			PictureNumber = Items.UsersList.RowData(SelectedItem).PictureNumber;
		Else
			PictureNumber = Items.UserGroups.RowData(SelectedItem).PictureNumber;
		EndIf;
		
		SelectedItemsAndPictures.Add(
			New Structure("SelectedItem, PictureNumber", SelectedItem, PictureNumber));
	EndDo;
	
	FillSelectedUsersAndGroupsList(SelectedItemsAndPictures);
	
EndProcedure

&AtServer
Function SelectionResult()
	
	SelectedUsersValueTable = SelectedUsersAndGroups.Unload( , "User");
	UsersArray = SelectedUsersValueTable.UnloadColumn("User");
	Return UsersArray;
	
EndFunction

&AtServer
Procedure ChangeExtendedPickFormParameters()
	
	// Loading the list of selected users.
	If ValueIsFilled(Parameters.ExtendedPickFormParameters) Then
		ExtendedPickFormParameters = GetFromTempStorage(Parameters.ExtendedPickFormParameters);
	Else
		ExtendedPickFormParameters = Parameters;
	EndIf;
	If TypeOf(ExtendedPickFormParameters.SelectedUsers) = Type("ValueTable") Then
		SelectedUsersAndGroups.Load(ExtendedPickFormParameters.SelectedUsers);
	Else
		For Each SelectedUser In ExtendedPickFormParameters.SelectedUsers Do
			SelectedUsersAndGroups.Add().User = SelectedUser;
		EndDo;
	EndIf;
	Users.FillUserPictureNumbers(SelectedUsersAndGroups, "User", "PictureNumber");
	StoredParameters.Insert("PickFormHeader", ExtendedPickFormParameters.PickFormHeader);
	// Setting parameters of the extended pick form.
	Items.EndAndClose.Visible         = True;
	Items.SelectUserGroup.Visible = True;
	// Making the list of selected users visible.
	Items.SelectedUsersAndGroups.Visible     = True;
	
	If Common.IsMobileClient() Then
		Items.GroupsAndUsers.Group                 = ChildFormItemsGroup.Vertical;
		Items.GroupsAndUsers.DisplayImportance      = DisplayImportance.VeryHigh;
		Items.ContentGroup.Group                    = ChildFormItemsGroup.AlwaysHorizontal;
		Items.SelectGroupGroup.Visible                   = False;
		Items.SelectUserGroup.Visible             = False;
		Items.Move(Items.SelectedUsersAndGroups, Items.ContentGroup, Items.SelectedUsersAndGroups);
	ElsIf GetFunctionalOption("UseUserGroups") Then
		Items.GroupsAndUsers.Group                 = ChildFormItemsGroup.Vertical;
		Items.UsersList.Height                       = 5;
		Items.UserGroups.Height                      = 3;
		ThisObject.Height                                        = 17;
		Items.SelectGroupGroup.Visible                   = True;
		// Making the titles of UsersList and UserGroups lists visible.
		Items.UserGroups.TitleLocation          = FormItemTitleLocation.Top;
		Items.UsersList.TitleLocation           = FormItemTitleLocation.Top;
		Items.UsersList.Title                    = NStr("ru = 'Пользователи в группе'; en = 'Users in group'; pl = 'Użytkowników w grupie';de = 'Benutzer in der Gruppe';ro = 'Utilizatorii din grup';tr = 'Gruptaki kullanıcılar'; es_ES = 'Usuarios en el grupo'");
		If ExtendedPickFormParameters.Property("CannotPickGroups") Then
			Items.SelectGroup.Visible                     = False;
		EndIf;
	Else
		Items.CancelUserSelection.Visible             = True;
		Items.ClearSelectedItemsList.Visible               = True;
	EndIf;
	
	// Adding the number of selected users to the title of the list of selected users and groups.
	UpdateSelectedUsersAndGroupsListTitle();
	
EndProcedure

&AtServer
Procedure UpdateSelectedUsersAndGroupsListTitle()
	
	If StoredParameters.UseGroups Then
		SelectedUsersAndGroupsTitle = NStr("ru = 'Выбранные пользователи и группы (%1)'; en = 'Selected users and groups (%1)'; pl = 'Wybrani użytkownicy i grupy (%1)';de = 'Ausgewählte Benutzer und Gruppen (%1)';ro = 'Utilizatorii și grupurile selectate (%1)';tr = 'Seçilmiş kullanıcılar ve gruplar (%1)'; es_ES = 'Usuarios y grupos seleccionados (%1)'");
	Else
		SelectedUsersAndGroupsTitle = NStr("ru = 'Выбранные пользователи (%1)'; en = 'Selected users (%1)'; pl = 'Wybrani użytkownicy (%1)';de = 'Ausgewählte Benutzer (%1)';ro = 'Utilizatorii selectați (%1)';tr = 'Seçilmiş kullanıcılar (%1)'; es_ES = 'Usuarios seleccionados (%1)'");
	EndIf;
	
	UsersCount = SelectedUsersAndGroups.Count();
	If UsersCount <> 0 Then
		Items.SelectedUsersAndGroupsList.Title = StringFunctionsClientServer.SubstituteParametersToString(
			SelectedUsersAndGroupsTitle, UsersCount);
	Else
		If StoredParameters.UseGroups Then
			Items.SelectedUsersAndGroupsList.Title = NStr("ru = 'Выбранные пользователи и группы'; en = 'Selected users and groups'; pl = 'Wybrani użytkownicy i grupy';de = 'Ausgewählte Benutzer und Gruppen';ro = 'Utilizatori și grupuri selectate';tr = 'Seçilmiş kullanıcılar ve gruplar'; es_ES = 'Usuarios y grupos seleccionados'");
		Else
			Items.SelectedUsersAndGroupsList.Title = NStr("ru = 'Выбранные пользователи'; en = 'Selected users'; pl = 'Wybrani użytkownicy';de = 'Ausgewählte Benutzer';ro = 'Utilizatorii selectați';tr = 'Seçilmiş kullanıcılar'; es_ES = 'Usuarios seleccionados'");
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillSelectedUsersAndGroupsList(SelectedItemsAndPictures)
	
	For Each ArrayRow In SelectedItemsAndPictures Do
		
		SelectedUserOrGroup = ArrayRow.SelectedItem;
		PictureNumber = ArrayRow.PictureNumber;
		
		FilterParameters = New Structure("User", SelectedUserOrGroup);
		ItemsFound = SelectedUsersAndGroups.FindRows(FilterParameters);
		If ItemsFound.Count() = 0 Then
			
			SelectedUsersRow = SelectedUsersAndGroups.Add();
			SelectedUsersRow.User = SelectedUserOrGroup;
			SelectedUsersRow.PictureNumber = PictureNumber;
			SelectedUsersListLastModified = True;
			
		EndIf;
		
	EndDo;
	
	SelectedUsersAndGroups.Sort("User Asc");
	UpdateSelectedUsersAndGroupsListTitle();
	
EndProcedure

&AtClient
Procedure UserGroupsUsageOnChange()
	
	ConfigureUserGroupsUsageForm(True);
	
EndProcedure

&AtServer
Procedure ConfigureUserGroupsUsageForm(GroupUsageChanged = False)
	
	If GroupUsageChanged Then
		StoredParameters.Insert("UseGroups", GetFunctionalOption("UseUserGroups"));
	EndIf;
	
	If StoredParameters.Property("CurrentRow") Then
		
		If TypeOf(StoredParameters.CurrentRow) = Type("CatalogRef.UserGroups") Then
			
			If StoredParameters.UseGroups Then
				Items.UserGroups.CurrentRow = StoredParameters.CurrentRow;
			Else
				Parameters.CurrentRow = Undefined;
			EndIf;
		Else
			CurrentItem = Items.UsersList;
			Items.UserGroups.CurrentRow = Catalogs.UserGroups.AllUsers;
		EndIf;
	Else
		If NOT StoredParameters.UseGroups
		   AND Items.UserGroups.CurrentRow
		     <> Catalogs.UserGroups.AllUsers Then
			
			Items.UserGroups.CurrentRow = Catalogs.UserGroups.AllUsers;
		EndIf;
	EndIf;
	
	Items.SelectHierarchy.Visible = StoredParameters.UseGroups;
	
	If Not AccessRight("Edit", Metadata.Catalogs.UserGroups)
	 Or StoredParameters.AdvancedPick
	 Or Common.IsStandaloneWorkplace() Then
		
		Items.AssignGroups.Visible = False;
		Items.UsersListContextMenuAssignToGroups.Visible = False;
	Else
		Items.AssignGroups.Visible = StoredParameters.UseGroups;
		Items.UsersListContextMenuAssignToGroups.Visible =
			StoredParameters.UseGroups;
	EndIf;
	
	Items.CreateUsersGroup.Visible =
		AccessRight("Insert", Metadata.Catalogs.UserGroups)
		AND StoredParameters.UseGroups
		AND Not Common.IsStandaloneWorkplace();
	
	UsersGroupsSelection = StoredParameters.UsersGroupsSelection
	                        AND StoredParameters.UseGroups
	                        AND Parameters.ChoiceMode;
	
	If Parameters.ChoiceMode Then
		
		CommonClientServer.SetFormItemProperty(Items,
			"SelectUsersGroup", "Visible", ?(StoredParameters.AdvancedPick,
				False, UsersGroupsSelection));
		
		CommonClientServer.SetFormItemProperty(Items,
			"SelectUser", "DefaultButton", ?(StoredParameters.AdvancedPick,
				False, Not UsersGroupsSelection));
		
		CommonClientServer.SetFormItemProperty(Items,
			"SelectUser", "Visible", Not StoredParameters.AdvancedPick);
		
		AutoTitle = False;
		
		If Parameters.CloseOnChoice = False Then
			// Pick mode.
			
			If UsersGroupsSelection Then
				
				If StoredParameters.AdvancedPick Then
					Title = StoredParameters.PickFormHeader;
				Else
					Title = NStr("ru = 'Подбор пользователей и групп'; en = 'Select users and groups'; pl = 'Wybór użytkowników i grup';de = 'Wählen Sie Benutzer und Gruppen aus';ro = 'Selectați utilizatorii și grupurile';tr = 'Kullanıcıları ve grupları seçin'; es_ES = 'Seleccionar usuario y grupos'");
				EndIf;
				
				CommonClientServer.SetFormItemProperty(Items,
					"SelectUser", "Title", NStr("ru = 'Выбрать пользователей'; en = 'Select users'; pl = 'Wybierz użytkowników';de = 'Wählen Sie Benutzer aus';ro = 'Selectați utilizatorii';tr = 'Kullanıcıları seç'; es_ES = 'Seleccionar usuarios'"));
				
				CommonClientServer.SetFormItemProperty(Items,
					"SelectUsersGroup", "Title", NStr("ru = 'Выбрать группы'; en = 'Select groups'; pl = 'Wybierz grupy';de = 'Gruppen auswählen';ro = 'Selectați grupuri';tr = 'Grupları seçin'; es_ES = 'Seleccionar grupos'"));
			Else
				
				If StoredParameters.AdvancedPick Then
					Title = StoredParameters.PickFormHeader;
				Else
					Title = NStr("ru = 'Подбор пользователей'; en = 'Select users'; pl = 'Wybór użytkowników';de = 'Auswahl der Benutzer';ro = 'Selectarea utilizatorilor';tr = 'Kullanıcıları seçin'; es_ES = 'Elegir usuarios'");
				EndIf;
				
			EndIf;
		Else
			// Selection mode.
			If UsersGroupsSelection Then
				Title = NStr("ru = 'Выбор пользователя или группы'; en = 'Select user or group'; pl = 'Wybór użytkownika lub grupy';de = 'Wählen Sie einen Benutzer oder eine Gruppe aus';ro = 'Selectați un utilizator sau un grup';tr = 'Kullanıcı veya grubu seçin'; es_ES = 'Seleccionar el usuario o el grupo'");
				
				CommonClientServer.SetFormItemProperty(Items,
					"SelectUser", "Title", NStr("ru = 'Выбрать пользователя'; en = 'Select user'; pl = 'Wybierz użytkownika';de = 'Nutzer wählen';ro = 'Selectați utilizatorul';tr = 'Kullanıcı seçin'; es_ES = 'Seleccionar el usuario'"));
			Else
				Title = NStr("ru = 'Выбор пользователя'; en = 'Select user'; pl = 'Wybór użytkownika';de = 'Wahl des Benutzers';ro = 'Selectarea utilizatorului';tr = 'Kullanıcı seçimi'; es_ES = 'Selección de usuario'");
			EndIf;
		EndIf;
	EndIf;
	
	RefreshFormContentOnGroupChange(ThisObject);
	
	// Upon the functional option change, force refresh the form view without calling the 
	// RefreshInterface command.
	Items.UserGroups.Visible = False;
	Items.UserGroups.Visible = True;
	
EndProcedure

&AtClient
Procedure UserGroupsAfterActivateRow()
	
	RefreshFormContentOnGroupChange(ThisObject);
	
#If MobileClient Then
	If StoredParameters.Property("AdvancedPick") AND Not StoredParameters.AdvancedPick Then
		Items.GroupsGroup.Title = String(Items.UserGroups.CurrentData.Ref);
		CurrentItem = Items.UsersList;
	EndIf;
#EndIf
EndProcedure

&AtServer
Function MoveUserToNewGroup(UsersArray, NewParentGroup, Move)
	
	If NewParentGroup = Undefined Then
		Return Undefined;
	EndIf;
	
	CurrentParentGroup = Items.UserGroups.CurrentRow;
	UserMessage = UsersInternal.MoveUserToNewGroup(
		UsersArray, CurrentParentGroup, NewParentGroup, Move);
	
	Items.UsersList.Refresh();
	Items.UserGroups.Refresh();
	
	Return UserMessage;
	
EndFunction

&AtClient
Procedure UserGroupsDragCompletion(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.No Then
		Return;
	EndIf;
	
	UserMessage = MoveUserToNewGroup(
		AdditionalParameters.DragParameters,
		AdditionalParameters.Row,
		AdditionalParameters.Move);
	
	If UserMessage.Message = Undefined Then
		Return;
	EndIf;
	
	If UserMessage.HasErrors = False Then
		ShowUserNotification(
			NStr("ru = 'Перемещение пользователей'; en = 'Move users'; pl = 'Przenieś użytkowników';de = 'Verschieben Sie Benutzer';ro = 'Mutați utilizatorii';tr = 'Kullanıcıları taşıyın'; es_ES = 'Mover a los usuarios'"), , UserMessage.Message, PictureLib.Information32);
	Else
		ShowMessageBox(,UserMessage.Message);
	EndIf;
	
	Notify("Write_ExternalUserGroups");
	
EndProcedure

&AtClient
Procedure ToggleInvalidUsersVisibility(ShowInvalidUsers)
	
	CommonClientServer.SetDynamicListFilterItem(
		UsersList, "Invalid", False, , ,
		NOT ShowInvalidUsers);
	
EndProcedure

&AtClientAtServerNoContext
Procedure RefreshFormContentOnGroupChange(Form)
	
	Items = Form.Items;
	AllUsersGroup = PredefinedValue(
		"Catalog.UserGroups.AllUsers");
	
	If NOT Form.StoredParameters.UseGroups
	 OR Items.UserGroups.CurrentRow = AllUsersGroup Then
		
		UpdateDataCompositionParameterValue(Form.UsersList,
			"AllUsers", True);
		
		UpdateDataCompositionParameterValue(Form.UsersList,
			"SelectHierarchy", False);
		
		UpdateDataCompositionParameterValue(Form.UsersList,
			"UsersGroup", AllUsersGroup);
	Else
		UpdateDataCompositionParameterValue(Form.UsersList,
			"AllUsers", False);
		
		UpdateDataCompositionParameterValue(Form.UsersList,
			"SelectHierarchy", Form.SelectHierarchy);
		
		UpdateDataCompositionParameterValue(Form.UsersList,
			"UsersGroup", Items.UserGroups.CurrentRow);
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateDataCompositionParameterValue(Val ParametersOwner,
                                                    Val ParameterName,
                                                    Val ParameterValue)
	
	For each Parameter In ParametersOwner.Parameters.Items Do
		If String(Parameter.Parameter) = ParameterName Then
			
			If Parameter.Use
			   AND Parameter.Value = ParameterValue Then
				Return;
			EndIf;
			Break;
			
		EndIf;
	EndDo;
	
	ParametersOwner.Parameters.SetParameterValue(ParameterName, ParameterValue);
	
EndProcedure

&AtServerNoContext
Procedure ListOnChangeAtServer()
	
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessControlInternal = Common.CommonModule("AccessManagementInternal");
		ModuleAccessControlInternal.StartAccessUpdate();
	EndIf;
	
EndProcedure

#EndRegion
