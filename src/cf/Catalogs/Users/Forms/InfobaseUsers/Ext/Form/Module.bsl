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
	
	DataSeparationEnabled = Common.DataSeparationEnabled();
	If NOT Users.IsFullUser(, Not DataSeparationEnabled) Then
		Raise NStr("ru = 'Недостаточно прав для открытия списка пользователей информационной базы.'; en = 'Insufficient rights to access the infobase user list.'; pl = 'Niewystarczające uprawnienia do otwierania listy użytkowników bazy informacyjnej.';de = 'Unzureichende Rechte zum Öffnen der Infobase-Benutzerliste.';ro = 'Drepturi insuficiente pentru a deschide lista de utilizatori de baze de date.';tr = 'Veritabanı kullanıcı listesini açmak için yetersiz haklar.'; es_ES = 'Insuficientes derechos para abrir la lista de usuarios de la infobase.'");
	EndIf;
	
	Users.FindAmbiguousIBUsers(Undefined);
	
	UsersTypes.Add(Type("CatalogRef.Users"));
	If GetFunctionalOption("UseExternalUsers") Then
		UsersTypes.Add(Type("CatalogRef.ExternalUsers"));
	EndIf;
	
	ShowOnlyItemsProcessedInDesigner = True;
	
	FillIBUsers();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "IBUserAdded"
	 OR EventName = "IBUserChanged"
	 OR EventName = "IBUserDeleted"
	 OR EventName = "MappingToNonExistingIBUserCleared" Then
		
		FillIBUsers();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ShowOnlyItemsProcessedInDesignerOnChange(Item)
	
	FillIBUsers();
	
EndProcedure

#EndRegion

#Region IBUsersFormTableItemsEventHandlers

&AtClient
Procedure IBUsersOnActivateRow(Item)
	
	CurrentData = Items.IBUsers.CurrentData;
	
	If CurrentData = Undefined Then
		CanDelete     = False;
		CanMap = False;
		CanGoToUser  = False;
		CanCancelMapping = False;
	Else
		CanDelete     = Not ValueIsFilled(CurrentData.Ref);
		CanMap = Not ValueIsFilled(CurrentData.Ref);
		CanGoToUser  = ValueIsFilled(CurrentData.Ref);
		CanCancelMapping = ValueIsFilled(CurrentData.Ref);
	EndIf;
	
	Items.IBUsersDelete.Enabled = CanDelete;
	
	Items.IBUsersGoToUser.Enabled                = CanGoToUser;
	Items.IBUsersContextMenuGoToUser.Enabled = CanGoToUser;
	
	Items.IBUsersMap.Enabled       = CanMap;
	Items.IBUsersMapToNewUser.Enabled = CanMap;
	
	Items.IBUsersCancelMapping.Enabled = CanCancelMapping;
	
EndProcedure

&AtClient
Procedure IBUsersBeforeDelete(Item, Cancel)
	
	Cancel = True;
	
	If Not ValueIsFilled(Items.IBUsers.CurrentData.Ref) Then
		DeleteCurrentIBUser(True);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Update(Command)
	
	FillIBUsers();
	
EndProcedure

&AtClient
Procedure Map(Command)
	
	MapIBUser();
	
EndProcedure

&AtClient
Procedure MapToNewUser(Command)
	
	MapIBUser(True);
	
EndProcedure

&AtClient
Procedure GoToUser(Command)
	
	OpenUserByRef();
	
EndProcedure

&AtClient
Procedure CancelMapping(Command)
	
	If Items.IBUsers.CurrentData = Undefined Then
		Return;
	EndIf;
	
	Buttons = New ValueList;
	Buttons.Add("CancelMapping", NStr("ru = 'Отменить сопоставление'; en = 'Clear mapping'; pl = 'Skasować mapowanie';de = 'Abbrechen Zuordnung';ro = 'Curăță maparea';tr = 'Eşleştirmeyi temizle'; es_ES = 'Eliminar el mapeo'"));
	Buttons.Add("KeepMapping", NStr("ru = 'Оставить сопоставление'; en = 'Keep mapping'; pl = 'Zostawić mapowanie';de = 'Belassen Sie die Zuordnung';ro = 'Menține confruntarea';tr = 'Eşleştirmeyi bırak'; es_ES = 'Abandonar el mapeo'"));
	
	ShowQueryBox(
		New NotifyDescription("CancelMappingFollowUp", ThisObject),
		NStr("ru = 'Отмена сопоставления пользователя информационной базы с пользователем в справочнике.
		           |
		           |Отмена сопоставления требуется крайне редко - только если сопоставление было выполнено некорректно, например,
		           |при обновлении информационной базы, поэтому не рекомендуется отменять сопоставление по любой другой причине.'; 
		           |en = 'Do you want to clear the mapping between the infobase user and the application user?
		           |
		           |It is required in rare cases when a mapping is incorrect
		           |(for example, an infobase update might generate an incorrect mapping). It is recommended that you never clear correct mappings.'; 
		           |pl = 'Anuluj mapowanie użytkownika bazy informacyjnej z użytkownikiem w katalogu.
		           |
		           |Anulowanie mapowania jest wymagane bardzo rzadko, tylko jeśli
		           |mapowanie zostało wykonane niepoprawnie, na przykład podczas aktualizacji bazy informacyjnej, dlatego nie zaleca się anulowania mapowania z jakiegokolwiek innego powodu.';
		           |de = 'Brechen Sie die Zuordnung des infobase-Benutzers mit dem Benutzer im Katalog ab. 
		           |
		           |Das Löschen der Zuordnung ist sehr selten erforderlich, nur wenn die Zuordnung
		           | nicht korrekt ausgeführt wurde, zum Beispiel beim Aktualisieren einer Infobase, daher ist es nicht empfehlenswert, die Zuordnung aus einem anderen Grund abzubrechen.';
		           |ro = 'Anularea confruntării utilizatorului bazei de informații cu utilizatorul în clasificator.
		           |
		           |Anularea confruntării este necesară foarte rar, numai dacă confruntarea a fost executată incorect, de exemplu,
		           |la actualizarea bazei de date, din aceste considerente nu este recomandat să anulați confruntarea pentru orice alt motiv.';
		           |tr = 'Veritabanı kullanıcısını katalogdaki kullanıcıyla eşleştirmeyi iptal edin. 
		           |
		           |Eşleştirme  iptali çok nadiren gereklidir, ancak eşleştirme 
		           |yanlış bir şekilde  tamamlandığında, örneğin bir veritabanın güncellenmesi durumunda,  başka herhangi bir nedenden dolayı eşleştirmenin iptal edilmesi tavsiye  edilmez.'; 
		           |es_ES = 'Cancelar el mapeo del usuario de la infobase con el usuario en el catálogo.
		           |
		           |Se requiere muy raramemente cancelar el mapeo, solo si el mapeo
		           |se ha finalizado de forma incorrecta, por ejemplo, al actualizar una infobase, así que no se recomienda cancelar el mapeo por cualquier otro motivo.'"),
		Buttons,
		,
		"KeepMapping");
		
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FullName.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Name.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.StandardAuthentication.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OSAuthentication.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OSUser.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OpenIDAuthentication.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("IBUsers.AddedInDesigner");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.SpecialTextColor);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FullName.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Name.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.StandardAuthentication.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OSAuthentication.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OSUser.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OpenIDAuthentication.Name);

	FIlterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FIlterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FIlterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("IBUsers.ModifiedInDesigner");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = FIlterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("IBUsers.DeletedInDesigner");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Name.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.StandardAuthentication.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OSAuthentication.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OpenIDAuthentication.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("IBUsers.DeletedInDesigner");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Text", NStr("ru = '<Нет данных>'; en = '<No data>'; pl = '<Brak danych>';de = '<Keine Daten>';ro = '<Nu există date>';tr = '<Veri yok>'; es_ES = '<No hay datos>'"));
	Item.Appearance.SetParameterValue("Format", NStr("ru = 'БЛ=Нет; БИ=Да'; en = 'BF=No; BT=Yes'; pl = 'BL=Nie; BI=Tak';de = 'BL=Nein; BI=Ja';ro = 'BF=Nu; BT=Da';tr = 'BF=Hayır; BT=Evet'; es_ES = 'BF=No; BT=Sí'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OSAuthentication.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("IBUsers.OSUser");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("Format", NStr("ru = 'БЛ=; БИ=Да'; en = 'BF=; BT=Yes'; pl = 'BF=; BT=Tak';de = 'BF=; BT=Ja';ro = 'BF=; BT=Da';tr = 'BF=; BT=Evet'; es_ES = 'BF=; BT=Sí'"));

EndProcedure

&AtServer
Procedure FillIBUsers()
	
	BlankUUID = CommonClientServer.BlankUUID();
	
	If Items.IBUsers.CurrentRow <> Undefined Then
		Row = IBUsers.FindByID(Items.IBUsers.CurrentRow);
	Else
		Row = Undefined;
	EndIf;
	
	IBUserCurrentID =
		?(Row = Undefined, BlankUUID, Row.IBUserID);
	
	IBUsers.Clear();
	NonExistingIBUsersIDs.Clear();
	NonExistingIBUsersIDs.Add(BlankUUID);
	
	Query = New Query;
	Query.SetParameter("BlankUUID", BlankUUID);
	Query.Text =
	"SELECT
	|	Users.Ref AS Ref,
	|	Users.Description AS FullName,
	|	Users.IBUserID,
	|	FALSE AS IsExternalUser
	|FROM
	|	Catalog.Users AS Users
	|WHERE
	|	Users.IBUserID <> &BlankUUID
	|
	|UNION ALL
	|
	|SELECT
	|	ExternalUsers.Ref,
	|	ExternalUsers.Description,
	|	ExternalUsers.IBUserID,
	|	TRUE
	|FROM
	|	Catalog.ExternalUsers AS ExternalUsers
	|WHERE
	|	ExternalUsers.IBUserID <> &BlankUUID";
	
	DataExported = Query.Execute().Unload();
	DataExported.Indexes.Add("IBUserID");
	DataExported.Columns.Add("Mapped", New TypeDescription("Boolean"));
	
	AllIBUsers = InfoBaseUsers.GetUsers();
	
	For Each InfobaseUser In AllIBUsers Do
		
		ModifiedInDesigner = False;
		Row = DataExported.Find(InfobaseUser.UUID, "IBUserID");
		PropertiesIBUser = Users.IBUserProperies(InfobaseUser.UUID);
		If PropertiesIBUser = Undefined Then
			PropertiesIBUser = Users.NewIBUserDetails();
		EndIf;
		
		If Row <> Undefined Then
			Row.Mapped = True;
			If Row.FullName <> PropertiesIBUser.FullName Then
				ModifiedInDesigner = True;
			EndIf;
		EndIf;
		
		If ShowOnlyItemsProcessedInDesigner
		   AND Row <> Undefined
		   AND Not ModifiedInDesigner Then
			
			Continue;
		EndIf;
		
		NewRow = IBUsers.Add();
		NewRow.FullName                   = PropertiesIBUser.FullName;
		NewRow.Name                         = PropertiesIBUser.Name;
		NewRow.StandardAuthentication   = PropertiesIBUser.StandardAuthentication;
		NewRow.OSAuthentication            = PropertiesIBUser.OSAuthentication;
		NewRow.IBUserID = PropertiesIBUser.UUID;
		NewRow.OSUser              = PropertiesIBUser.OSUser;
		NewRow.OpenIDAuthentication        = PropertiesIBUser.OpenIDAuthentication;
		
		If Row = Undefined Then
			// The infobase user is not in the catalog.
			NewRow.AddedInDesigner = True;
		Else
			NewRow.Ref                           = Row.Ref;
			NewRow.MappedToExternalUser = Row.IsExternalUser;
			
			NewRow.ModifiedInDesigner = ModifiedInDesigner;
		EndIf;
		
	EndDo;
	
	Filter = New Structure("Mapped", False);
	Rows = DataExported.FindRows(Filter);
	For each Row In Rows Do
		NewRow = IBUsers.Add();
		NewRow.FullName                        = Row.FullName;
		NewRow.Ref                           = Row.Ref;
		NewRow.MappedToExternalUser = Row.IsExternalUser;
		NewRow.DeletedInDesigner             = True;
		NonExistingIBUsersIDs.Add(Row.IBUserID);
	EndDo;
	
	Filter = New Structure("IBUserID", IBUserCurrentID);
	Rows = IBUsers.FindRows(Filter);
	If Rows.Count() > 0 Then
		Items.IBUsers.CurrentRow = Rows[0].GetID();
	EndIf;
	
EndProcedure

&AtServer
Procedure DeleteIBUser(IBUserID, Cancel)
	
	Try
		Users.DeleteIBUser(IBUserID);
	Except
		Common.MessageToUser(BriefErrorDescription(ErrorInfo()), , , , Cancel);
	EndTry;
	
EndProcedure

&AtClient
Procedure OpenUserByRef()
	
	CurrentData = Items.IBUsers.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If ValueIsFilled(CurrentData.Ref) Then
		OpenForm(
			?(CurrentData.MappedToExternalUser,
				"Catalog.ExternalUsers.ObjectForm",
				"Catalog.Users.ObjectForm"),
			New Structure("Key", CurrentData.Ref));
	EndIf;
	
EndProcedure

&AtClient
Procedure DeleteCurrentIBUser(DeleteRow = False)
	
	ShowQueryBox(
		New NotifyDescription("DeleteCurrentIBUserCompletion", ThisObject, DeleteRow),
		NStr("ru = 'Удалить пользователя информационной базы?'; en = 'Do you want to delete the infobase user?'; pl = 'Usunąć użytkownika bazy informacyjnej?';de = 'Infobase Benutzer löschen?';ro = 'Ștergeți utilizatorul bazei de date?';tr = 'Veritabanı kullanıcısı silinsin mi?'; es_ES = '¿Borrar el usuario de la infobase?'"),
		QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure DeleteCurrentIBUserCompletion(Response, DeleteRow) Export
	
	If Response = DialogReturnCode.Yes Then
		Cancel = False;
		DeleteIBUser(
			Items.IBUsers.CurrentData.IBUserID, Cancel);
		
		If Not Cancel AND DeleteRow Then
			IBUsers.Delete(Items.IBUsers.CurrentData);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure MapIBUser(WithNew = False)
	
	If UsersTypes.Count() > 1 Then
		UsersTypes.ShowChooseItem(
			New NotifyDescription("MapIBUserForItemType", ThisObject, WithNew),
			NStr("ru = 'Выбор типа данных'; en = 'Select data type'; pl = 'Wybierz typ danych';de = 'Wählen Sie den Datentyp aus';ro = 'Select data type';tr = 'Veri türünü seçin'; es_ES = 'Seleccionar el tipo de datos'"),
			UsersTypes[0]);
	Else
		MapIBUserForItemType(UsersTypes[0], WithNew);
	EndIf;
	
EndProcedure

&AtClient
Procedure MapIBUserForItemType(ListItem, WithNew) Export
	
	If ListItem = Undefined Then
		Return;
	EndIf;
	
	CatalogName = ?(ListItem.Value = Type("CatalogRef.Users"), "Users", "ExternalUsers");
	
	If Not WithNew Then
		FormParameters = New Structure;
		FormParameters.Insert("ChoiceMode", True);
		FormParameters.Insert("NonExistingIBUsersIDs", NonExistingIBUsersIDs);
		
		OpenForm("Catalog." + CatalogName + ".ChoiceForm", FormParameters,,,,,
			New NotifyDescription("MapIBUserToItem", ThisObject, CatalogName));
	Else
		MapIBUserToItem("New", CatalogName);
	EndIf;
	
EndProcedure

&AtClient
Procedure MapIBUserToItem(Item, CatalogName) Export
	
	If Not ValueIsFilled(Item) AND Item <> "New" Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	
	If Item <> "New" Then
		FormParameters.Insert("Key", Item);
	EndIf;
	
	FormParameters.Insert("IBUserID",
		Items.IBUsers.CurrentData.IBUserID);
	
	OpenForm("Catalog." + CatalogName + ".ObjectForm", FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure CancelMappingFollowUp(Response, Context) Export
	
	If Response = "CancelMapping" Then
		CancelMappingAtServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure CancelMappingAtServer()
	
	CurrentRow = IBUsers.FindByID(
		Items.IBUsers.CurrentRow);
	
	Object = CurrentRow.Ref.GetObject();
	Object.IBUserID = Undefined;
	Object.DataExchange.Load = True;
	Object.Write();
	
	FillIBUsers();
	
EndProcedure

#EndRegion
