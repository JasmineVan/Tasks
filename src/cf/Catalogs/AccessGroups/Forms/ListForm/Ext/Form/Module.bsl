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
	
	If Parameters.ChoiceMode Then
		StandardSubsystemsServer.SetFormAssignmentKey(ThisObject, "SelectionPick");
	Else
		Items.List.ChoiceMode = False;
	EndIf;
	
	PersonalAccessGroupsParent = Catalogs.AccessGroups.PersonalAccessGroupsParent(True);
	
	SimplifiedAccessRightsSetupInterface = AccessManagementInternal.SimplifiedAccessRightsSetupInterface();
	
	If SimplifiedAccessRightsSetupInterface Then
		CommonClientServer.SetFormItemProperty(Items,
			"FormCreate", "Visible", False);
		
		CommonClientServer.SetFormItemProperty(Items,
			"ListContextMenuCreate", "Visible", False);
		
		CommonClientServer.SetFormItemProperty(Items,
			"FormCopy", "Visible", False);
		
		CommonClientServer.SetFormItemProperty(Items,
			"ListContextMenuCopy", "Visible", False);
	EndIf;
	
	List.Parameters.SetParameterValue("Profile", Parameters.Profile);
	If ValueIsFilled(Parameters.Profile) Then
		Items.Profile.Visible = False;
		Items.List.Representation = TableRepresentation.List;
		AutoTitle = False;
		
		Title = NStr("ru = 'Группы доступа'; en = 'Access groups'; pl = 'Grupy dostępu';de = 'Zugriffsgruppen';ro = 'Grupuri de acces';tr = 'Erişim grupları'; es_ES = 'Grupos de acceso'");
		
		CommonClientServer.SetFormItemProperty(Items,
			"FormCreateFolder", "Visible", False);
		
		CommonClientServer.SetFormItemProperty(Items,
			"ListContextMenuCreateGroup", "Visible", False);
	EndIf;
	
	If NOT AccessRight("Read", Metadata.Catalogs.AccessGroupProfiles) Then
		Items.Profile.Visible = False;
	EndIf;
	
	If NOT Users.IsFullUser() Then
		// Hiding the Administrators access group.
		CommonClientServer.SetDynamicListFilterItem(
			List, "Ref", Catalogs.AccessGroups.Administrators,
			DataCompositionComparisonType.NotEqual, , True);
	EndIf;
	
	ChoiceMode = Parameters.ChoiceMode;
	
	If Parameters.ChoiceMode Then
		
		WindowOpeningMode = FormWindowOpeningMode.LockOwnerWindow;
		Items.List.ChoiceFoldersAndItems = Parameters.ChoiceFoldersAndItems;
		
		AutoTitle = False;
		If Parameters.CloseOnChoice = False Then
			// Pick mode.
			Items.List.MultipleChoice = True;
			Items.List.SelectionMode = TableSelectionMode.MultiRow;
			
			Title = NStr("ru = 'Подбор групп доступа'; en = 'Pick access groups'; pl = 'Wybierz grupy dostępu';de = 'Wählen Sie Zugriffsgruppen aus';ro = 'Selectarea grupurilor de acces';tr = 'Erişim gruplarını seçin'; es_ES = 'Seleccionar los grupos de acceso'");
		Else
			Title = NStr("ru = 'Выбор группы доступа'; en = 'Select access group'; pl = 'Wybierz grupę dostępu';de = 'Wählen Sie Zugriffsgruppe aus';ro = 'Selectați grupul de acces';tr = 'Erişim grubunu seç'; es_ES = 'Seleccionar el grupo de acceso'");
		EndIf;
	EndIf;
	
	If Common.IsStandaloneWorkplace() Then
		ReadOnly = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnChange(Item)
	
	ListOnChangeAtServer();
	
EndProcedure

&AtClient
Procedure ListOnActivateRow(Item)
	
	If Not StandardSubsystemsClient.IsDynamicListItem(Items.List) Then
		Return;
	EndIf;
	
	TransferAvailable = NOT ValueIsFilled(Items.List.CurrentData.User)
	                  AND Items.List.CurrentData.Ref <> PersonalAccessGroupsParent;
	
	CommonClientServer.SetFormItemProperty(Items,
		"FormMoveItem", "Enabled", TransferAvailable);
	
	CommonClientServer.SetFormItemProperty(Items,
		"ListContextMenuMoveItem", "Enabled", TransferAvailable);
	
	CommonClientServer.SetFormItemProperty(Items,
		"ListMoveItem", "Enabled", TransferAvailable);
	
EndProcedure

&AtClient
Procedure ListValueChoice(Item, Value, StandardProcessing)
	
	If Value = PersonalAccessGroupsParent Then
		StandardProcessing = False;
		ShowMessageBox(, NStr("ru = 'Эта группа только для персональных групп доступа.'; en = 'This group is only for personal access groups.'; pl = 'Ten folder może zawierać tylko osobiste grupy dostępu.';de = 'Dieser Ordner kann nur persönliche Zugriffsgruppen enthalten.';ro = 'Acest grup este numai pentru grupurile de acces personale.';tr = 'Bu klasör sadece kişisel erişim grupları içerebilir.'; es_ES = 'Esta carpeta puede contener solo los grupos de acceso personal.'"));
	EndIf;
	
EndProcedure

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Clone, Parent, Folder)
	
	If Parent = PersonalAccessGroupsParent Then
		
		Cancel = True;
		
		If Folder Then
			ShowMessageBox(, NStr("ru = 'В этой группе не используются подгруппы.'; en = 'Subgroups are not used in this group.'; pl = 'Ten folder nie może zawierać podfolderów.';de = 'Dieser Ordner darf keine Unterordner enthalten.';ro = 'În acest grup nu se utilizează subgrupuri.';tr = 'Bu klasör alt klasörler içeremez.'; es_ES = 'Esta carpeta no puede contener subcarpetas.'"));
			
		ElsIf SimplifiedAccessRightsSetupInterface Then
			ShowMessageBox(,
				NStr("ru = 'Персональные группы доступа
				           |создаются только в форме ""Права доступа"".'; 
				           |en = 'Personal access groups
				           |can be created only in the ""Access rights"" form.'; 
				           |pl = 'Prywatne grupy dostępu
				           |są tworzone tylko w formularzu ""Prawa dostępu"".';
				           |de = 'Persönliche Zugangsgruppen
				           |werden nur in Form von ""Zugangsrechten"" angelegt.';
				           |ro = 'Grupurile de acces personale
				           |se creează numai în forma ""Drepturi de acces"".';
				           |tr = 'Kişisel erişim grubu yalnızca 
				           |""Erişim hakları"" formunda oluşturulabilir.'; 
				           |es_ES = 'Los grupos de acceso personales
				           |se crean solo en el formulario ""Derechos de acceso"".'"));
		Else
			ShowMessageBox(, NStr("ru = 'Персональные группы доступа не используются.'; en = 'Personal access groups are not used.'; pl = 'Osobiste grupy dostępu nie są dostępne.';de = 'Persönliche Zugriffsgruppen sind nicht verfügbar.';ro = 'Grupurile de acces personale nu se utilizează.';tr = 'Kişisel erişim grupları mevcut değildir.'; es_ES = 'Grupos de acceso personal no están disponibles.'"));
		EndIf;
		
	ElsIf NOT Folder
	        AND SimplifiedAccessRightsSetupInterface Then
		
		Cancel = True;
		
		ShowMessageBox(,
			NStr("ru = 'Используются только персональные группы доступа,
			           |которые создаются только в форме ""Права доступа"".'; 
			           |en = 'Only personal access groups
			           |created in the ""Access rights"" form are used.'; 
			           |pl = 'Są używane wyłącznie prywatne grupy dostępu,
			           |które są tworzone tylko w formularzu ""Prawa dostępu"".';
			           |de = 'Es werden nur persönliche Zugriffsgruppen verwendet,
			           |die nur in Form von ""Zugriffsrechten"" angelegt werden.';
			           |ro = 'Se utilizează numai grupurile de acces personale
			           |care se creează numai în forma ""Drepturi de acces"".';
			           |tr = 'Yalnızca ""Erişim hakları"" formunda oluşturulan kişisel erişim grupları 
			           |kullanılabilir.'; 
			           |es_ES = 'Se usan solo grupos de acceso personales
			           |que se crean solo en el formulario ""Derechos de acceso"".'"));
	EndIf;
	
EndProcedure

&AtClient
Procedure ListBeforeChangeRow(Item, Cancel)
	
	CurrentData = Item.CurrentData;
	
	If CurrentData = Undefined
	 Or CurrentData.IsFolder Then
		Return;
	EndIf;
	
	Cancel = True;
	
	FormParameters = New Structure("Key", CurrentData.Ref);
	OpenForm("Catalog.AccessGroups.ObjectForm", FormParameters, Item);
	
EndProcedure

&AtServerNoContext
Procedure ListOnReceiveDataAtServer(ItemName, Settings, Rows)
	
	For Each Row In Rows Do
		If TypeOf(Row.Key) <> Type("CatalogRef.AccessGroups") Then
			Continue;
		EndIf;
		Data = Row.Value.Data;
		
		If Data.IsFolder
		 Or Not ValueIsFilled(Data.User) Then
			Continue;
		EndIf;
		
		Data.Description =
			AccessManagementInternalClientServer.PresentationAccessGroups(Data);
		
	EndDo;
	
EndProcedure

&AtClient
Procedure ListDrag(Item, DragParameters, StandardProcessing, Row, Field)
	
	If Row = PersonalAccessGroupsParent Then
		StandardProcessing = False;
		ShowMessageBox(, NStr("ru = 'Эта папка только для персональных групп доступа.'; en = 'This folder is for personal access groups only.'; pl = 'Ten folder może zawierać tylko osobiste grupy dostępu.';de = 'Dieser Ordner kann nur persönliche Zugriffsgruppen enthalten.';ro = 'Acest folder poate conține numai grupuri de acces personale.';tr = 'Bu klasör sadece kişisel erişim grupları içerebilir.'; es_ES = 'Esta carpeta puede contener solo los grupos de acceso personal.'"));
		
	ElsIf DragParameters.Value = PersonalAccessGroupsParent Then
		StandardProcessing = False;
		ShowMessageBox(, NStr("ru = 'Папка персональных групп доступа не переносится.'; en = 'Personal access groups folder cannot be moved.'; pl = 'Nie można przenieść folderu osobistych grup dostępu.';de = 'Der Ordner für persönliche Zugriffsgruppen kann nicht verschoben werden.';ro = 'Nu puteți muta folderul grupurilor de acces personale.';tr = 'Kişisel erişim grupları klasörü taşınamaz.'; es_ES = 'No se puede mover la carpeta de los grupos de acceso personal.'"));
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure ListOnChangeAtServer()
	
	AccessManagementInternal.StartAccessUpdate();
	
EndProcedure

#EndRegion
