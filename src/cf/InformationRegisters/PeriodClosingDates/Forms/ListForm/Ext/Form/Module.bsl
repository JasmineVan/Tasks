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
	SetOrder();
	
	ReadOnly = True;
	
	PeriodClosingDatesInternal.UpdatePeriodClosingDatesSections();
	
	// Setting up the command.
	SectionsProperties = PeriodClosingDatesInternal.SectionsProperties();
	Items.FormDataImportRestrictionDates.Visible = SectionsProperties.ImportRestrictionDatesImplemented;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Clone, Parent, Folder)
	
	Cancel = True;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure PeriodEndClosingDates(Command)
	
	OpenForm("InformationRegister.PeriodClosingDates.Form.PeriodClosingDates");
	
EndProcedure

&AtClient
Procedure DataImportRestrictionDates(Command)
	
	FormParameters = New Structure("DataImportRestrictionDates", True);
	OpenForm("InformationRegister.PeriodClosingDates.Form.PeriodClosingDates", FormParameters);
	
EndProcedure

&AtClient
Procedure EnableEditing(Command)
	
	ReadOnly = False;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	List.SettingsComposer.Settings.ConditionalAppearance.Items.Clear();
	
	For Each UserType In Metadata.InformationRegisters.PeriodClosingDates.Dimensions.User.Type.Types() Do
		MetadataObject = Metadata.FindByType(UserType);
		If NOT Metadata.ExchangePlans.Contains(MetadataObject) Then
			Continue;
		EndIf;
		
		ApplyAppearanceValue(Common.ObjectManagerByFullName(MetadataObject.FullName()).EmptyRef(),
			MetadataObject.Presentation() + ": " + NStr("ru = '<Все информационные базы>'; en = '<All infobases>'; pl = '<Wszystkie bazy informacyjne>';de = '<Alle Infobases>';ro = '<Toate bazele de date> ';tr = '<Tüm bilgi tabanları>'; es_ES = '<Todas infobases>'"));
	EndDo;
	
	ApplyAppearanceValue(Undefined,
		NStr("ru = 'Неопределено'; en = 'Undefined'; pl = 'Nieokreślona';de = 'Nicht definiert';ro = 'Nedefinit';tr = 'Tanımlanmamış'; es_ES = 'No definido'"));
	
	ApplyAppearanceValue(Catalogs.Users.EmptyRef(),
		NStr("ru = 'Пустой пользователь'; en = 'Empty user'; pl = 'Pusty użytkownik';de = 'Leerer Benutzer';ro = 'Utilizatorul gol';tr = 'Boş kullanıcı'; es_ES = 'Usuario vacío'"));
	
	ApplyAppearanceValue(Catalogs.UserGroups.EmptyRef(),
		NStr("ru = 'Пустая группа пользователей'; en = 'Empty user group'; pl = 'Pusta grupa użytkowników';de = 'Leere Benutzergruppe';ro = 'Goliți grupul de utilizatori';tr = 'Boş kullanıcı grubu'; es_ES = 'Grupo de usuarios vacíos'"));
	
	ApplyAppearanceValue(Catalogs.ExternalUsers.EmptyRef(),
		NStr("ru = 'Пустой внешний пользователь'; en = 'Empty external user'; pl = 'Pusty użytkownik zewnętrzny';de = 'Leerer externer Benutzer';ro = 'Ștergeți utilizator extern';tr = 'Boş harici kullanıcı'; es_ES = 'Usuario externo vacío'"));
	
	ApplyAppearanceValue(Catalogs.ExternalUsersGroups.EmptyRef(),
		NStr("ru = 'Пустая группа внешних пользователей'; en = 'Empty external user group'; pl = 'Pusta grupa użytkowników zewnętrznych';de = 'Leere externe Benutzergruppe';ro = 'Grupează grupul extern de utilizatori';tr = 'Boş harici kullanıcı grubu'; es_ES = 'Grupo de usuarios externos vacíos'"));
	
	ApplyAppearanceValue(Enums.PeriodClosingDatesPurposeTypes.ForAllUsers,
		"<" + Enums.PeriodClosingDatesPurposeTypes.ForAllUsers + ">");
	
	ApplyAppearanceValue(Enums.PeriodClosingDatesPurposeTypes.ForAllInfobases,
		"<" + Enums.PeriodClosingDatesPurposeTypes.ForAllInfobases + ">");
	
EndProcedure

&AtServer
Procedure ApplyAppearanceValue(Value, Text)
	
	AppearanceItem = List.SettingsComposer.Settings.ConditionalAppearance.Items.Add();
	AppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	AppearanceItem.Appearance.SetParameterValue("Text", Text);
	
	FilterItem = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem.LeftValue = New DataCompositionField("User");
	FilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	FilterItem.RightValue = Value;
	
	FieldItem = AppearanceItem.Fields.Items.Add();
	FieldItem.Field = New DataCompositionField("User");
	
EndProcedure

&AtServer
Procedure SetOrder()
	
	Order = List.SettingsComposer.Settings.Order;
	Order.Items.Clear();
	
	OrderItem = Order.Items.Add(Type("DataCompositionOrderItem"));
	OrderItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	OrderItem.Field = New DataCompositionField("User");
	OrderItem.OrderType = DataCompositionSortDirection.Asc;
	OrderItem.Use = True;
	
	OrderItem = Order.Items.Add(Type("DataCompositionOrderItem"));
	OrderItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	OrderItem.Field = New DataCompositionField("Section");
	OrderItem.OrderType = DataCompositionSortDirection.Asc;
	OrderItem.Use = True;
	
	OrderItem = Order.Items.Add(Type("DataCompositionOrderItem"));
	OrderItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	OrderItem.Field = New DataCompositionField("Object");
	OrderItem.OrderType = DataCompositionSortDirection.Asc;
	OrderItem.Use = True;
	
EndProcedure

#EndRegion
