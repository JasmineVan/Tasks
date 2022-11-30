///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

&AtClient
Var UsersContinueAdding, SelectedUser, SelectedClosingDateIndicationMethod;

#EndRegion

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	PeriodClosingDatesInternal.UpdatePeriodClosingDatesSections();
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		InterfaceVersion82 = True;
		Items.UsersAdd.OnlyInAllActions = False;
		Items.ClosingDatesAdd.OnlyInAllActions = False;
	EndIf;
	
	// Caching the current date on the server.
	BegOfDay = BegOfDay(CurrentSessionDate());
	
	// Fill in section properties.
	SectionsProperties = PeriodClosingDatesInternal.SectionsProperties();
	FillPropertyValues(ThisObject, SectionsProperties);
	Table = New ValueTable;
	Table.Columns.Add("Ref", New TypeDescription("ChartOfCharacteristicTypesRef.PeriodClosingDatesSections"));
	Table.Columns.Add("Presentation", New TypeDescription("String",,,, New StringQualifiers(150)));
	Table.Columns.Add("IsCommonDate",  New TypeDescription("Boolean"));
	For Each Section In Sections Do
		If TypeOf(Section.Key) = Type("String") Then
			Continue;
		EndIf;
		NewRow = Table.Add();
		FillPropertyValues(NewRow, Section.Value);
		If Not ValueIsFilled(Section.Value.Ref) Then
			NewRow.Presentation = CommonDatePresentationText();
			NewRow.IsCommonDate  = True;
		EndIf;
	EndDo;
	SectionsTableAddress = PutToTempStorage(Table, UUID);
	
	// Prepare the table for setting or removing form locks.
	Dimensions = Metadata.InformationRegisters.PeriodClosingDates.Dimensions;
	Table = New ValueTable;
	Table.Columns.Add("Section",       Dimensions.Section.Type);
	Table.Columns.Add("Object",       Dimensions.Object.Type);
	Table.Columns.Add("User", Dimensions.User.Type);
	Locks = New Structure;
	Locks.Insert("FormID",   UUID);
	Locks.Insert("Content",               Table);
	Locks.Insert("BegOfDay",            BegOfDay);
	Locks.Insert("NoSectionsAndObjects", NoSectionsAndObjects);
	Locks.Insert("SectionEmptyRef",   SectionEmptyRef);
	
	LocksAddress = PutToTempStorage(Locks, UUID);
	
	// Form field setting
	If Parameters.DataImportRestrictionDates Then
		
		If Not SectionsProperties.ImportRestrictionDatesImplemented Then
			Raise PeriodClosingDatesInternal.ErrorTextImportRestrictionDatesNotImplemented();
		EndIf;
		
		If Not Users.IsFullUser() Then
			Raise NStr("ru = 'Недостаточно прав для работы с датами запрета загрузки.'; en = 'Insufficient rights to operate with data import restriction dates.'; pl = 'Niewystarczające uprawnienia do pracy z datami zakazu pobierania.';de = 'Unzureichende Rechte zur Arbeit mit Download-Verbotszeiten.';ro = 'Drepturi insuficiente pentru lucrul cu datele de interdicție a importului.';tr = 'İçe aktarma yasağı tarihleri ile çalışmak için yetki yetersizdir.'; es_ES = 'Insuficientes derechos para trabajar con las fechas de restricción de la carga.'");
		EndIf;
		
		Items.ClosingDatesUsageDisabledLabel.Title =
			NStr("ru = 'Даты запрета загрузки данных прошлых периодов из других программ отключены в настройках.'; en = 'Data import restriction dates of previous periods from other applications are disabled in the settings.'; pl = 'Daty zakazu pobierania danych z poprzednich programów z innych programów są wyłączone w ustawieniach.';de = 'Das Datum des Verbots des Herunterladens früherer Daten aus anderen Programmen ist in den Einstellungen deaktiviert.';ro = 'Datele de interdicție a importului de date din perioadele precedente din alte programe sunt dezactivate în setări.';tr = 'Diğer programlardan geçmiş dönemlerin veri içe aktarılmasını yasaklayan tarihler ayarlarda devre dışı bırakıldı.'; es_ES = 'Las fechas de restricción de la carga de los datos de los períodos anteriores de otros programas están desactivadas en los ajustes.'");
		
		Title = NStr("ru = 'Даты запрета загрузки данных'; en = 'Data import restriction dates'; pl = 'Daty zakazu importu danych';de = 'Abschlussdaten des Datenimports';ro = 'Datele de interdicție a importului de date';tr = 'Verilerin içe aktarılmasına kapatıldığı tarihler'; es_ES = 'Fechas de cierre de la importación de datos'");
		Items.SetPeriodEndClosingDate.ChoiceList.FindByValue("ForAllUsers").Presentation =
			NStr("ru = 'Для всех информационных баз'; en = 'For all infobases'; pl = 'Dla wszystkich baz informacyjnych';de = 'Für alle Infobases';ro = 'Pentru toate bazele de date';tr = 'Tüm veritabanları için'; es_ES = 'Para todas infobases'");
		Items.SetPeriodEndClosingDate.ChoiceList.FindByValue("ForUsers").Presentation =
			NStr("ru = 'По информационным базам'; en = 'By infobases'; pl = 'Wg baz informacyjnych';de = 'Durch Infobases';ro = 'Conform bază de date';tr = 'Veritabanlarına göre'; es_ES = 'Por infobases'");
		
		Items.UsersFullPresentation.Title =
			NStr("ru = 'Программа: информационная база'; en = 'Application: infobase'; pl = 'Aplikacja: baza informacyjna';de = 'Anwendung: Infobase';ro = 'Aplicație: Bază de date';tr = 'Uygulama: veri tabanı'; es_ES = 'Aplicación: infobase'");
		
		ValueForAllUsers = Enums.PeriodClosingDatesPurposeTypes.ForAllInfobases;
		
		UserTypes =
			Metadata.InformationRegisters.PeriodClosingDates.Dimensions.User.Type.Types();
		
		For Each UserType In UserTypes Do
			MetadataObject = Metadata.FindByType(UserType);
			If Not Metadata.ExchangePlans.Contains(MetadataObject) Then
				Continue;
			EndIf;
			EmptyRefOfExchangePlanNode = Common.ObjectManagerByFullName(
				MetadataObject.FullName()).EmptyRef();
			
			UserTypesList.Add(
				EmptyRefOfExchangePlanNode, MetadataObject.Presentation());
		EndDo;
		Items.Users.RowsPicture = PictureLib.IconsExchangePlanNode;
		
		URL =
			"e1cib/command/InformationRegister.PeriodClosingDates.Command.DataImportRestrictionDates";
	Else
		If Not AccessRight("Edit", Metadata.InformationRegisters.PeriodClosingDates)
		 Or Not AccessRight("View", Metadata.ChartsOfCharacteristicTypes.PeriodClosingDatesSections) Then
			Raise NStr("ru = 'Недостаточно прав для работы с датами запрета изменения.'; en = 'Insufficient rights to operate with period-end closing dates.'; pl = 'Niewystarczające uprawnienia do pracy z datami zakazu zmiany.';de = 'Unzureichende Rechte auf Arbeit mit Daten des Änderungsverbots.';ro = 'Drepturi insuficiente pentru lucrul cu datele de interdicție a modificării.';tr = 'Değişiklik yasağı tarihleri ile çalışmak için yetki yetersizdir.'; es_ES = 'Insuficientes derechos para trabajar con las fechas de restricción del cambio.'");
		EndIf;
		
		Items.ClosingDatesUsageDisabledLabel.Title =
			NStr("ru = 'Даты запрета ввода и редактирования данных прошлых периодов отключены в настройках программы.'; en = 'Dates of restriction of entering and editing previous period data are disabled in the application settings.'; pl = 'Daty zakazu wprowadzania i edycji danych poprzednich okresów są wyłączone w ustawieniach programu.';de = 'Die Termine für das Verbot der Eingabe und Bearbeitung von Altdaten sind in den Programmeinstellungen deaktiviert.';ro = 'Datele de interdicție a introducerii și editării datelor perioadelor precedente sunt dezactivate în setările programului.';tr = 'Geçmiş dönemlere ait verilerin son giriş ve düzenlenmesinin tarihleri program ayarlarında devre dışı bırakıldı.'; es_ES = 'Las fechas de restricción de introducir y editar los datos de los períodos anteriores están desactivadas en los ajustes del programa.'");
		Items.UsersFullPresentation.Title = 
			?(GetFunctionalOption("UseUserGroups"),
			NStr("ru = 'Пользователь, группа пользователей'; en = 'User, user group'; pl = 'Użytkownik, grupa użytkowników';de = 'Benutzer, Benutzergruppe';ro = 'Utilizatorul, grupul de utilizatori';tr = 'Kullanıcı, kullanıcı grubu'; es_ES = 'Usuario, grupo de usuarios'"), NStr("ru = 'Пользователь'; en = 'User'; pl = 'Użytkownik';de = 'Benutzer';ro = 'Utilizator';tr = 'Kullanıcı'; es_ES = 'Usuario'"));
		ValueForAllUsers = Enums.PeriodClosingDatesPurposeTypes.ForAllUsers;
		UserTypesList.Add(
			Type("CatalogRef.Users"),        NStr("ru = 'Пользователь'; en = 'User'; pl = 'Użytkownik';de = 'Benutzer';ro = 'Utilizator';tr = 'Kullanıcı'; es_ES = 'Usuario'"));
		UserTypesList.Add(
			Type("CatalogRef.ExternalUsers"), NStr("ru = 'Внешний пользователь'; en = 'External user'; pl = 'Użytkownik zewnętrzny';de = 'Externer Benutzer';ro = 'Utilizator extern';tr = 'Harici kullanıcı'; es_ES = 'Usuario externo'"));
		
		URL = "e1cib/command/InformationRegister.PeriodClosingDates.Command.PeriodEndClosingDates";
	EndIf;
	
	List = Items.PeriodEndClosingDateSettingMethod.ChoiceList;
	
	If NoSectionsAndObjects Then
		Items.PeriodEndClosingDateSettingMethod.Visible =
			ValueIsFilled(CurrentClosingDateIndicationMethod(
				"*", SingleSection, ValueForAllUsers, BegOfDay));
		
		List.Delete(List.FindByValue("BySectionsAndObjects"));
		List.Delete(List.FindByValue("BySections"));
		List.Delete(List.FindByValue("ByObjects"));
		
	ElsIf Not ShowSections Then
		List.Delete(List.FindByValue("BySectionsAndObjects"));
		List.Delete(List.FindByValue("BySections"));
	ElsIf AllSectionsWithoutObjects Then
		List.Delete(List.FindByValue("BySectionsAndObjects"));
		List.Delete(List.FindByValue("ByObjects"));
	Else
		List.Delete(List.FindByValue("ByObjects"));
	EndIf;
	
	UseExternalUsers = ExternalUsers.UseExternalUsers();
	CatalogExternalUsersAvailable = AccessRight("View", Metadata.Catalogs.ExternalUsers);
	
	UpdateAtServer();
	
	StandardSubsystemsServer.SetGroupTitleRepresentation(
		ThisObject, "CurrentUserPresentation");
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectedValue, ChoiceSource)
	
	If Upper(ChoiceSource.FormName) = Upper("InformationRegister.PeriodClosingDates.Form.PeriodEndClosingDateEdit") Then
		
		If SelectedValue <> Undefined Then
			SelectedRows = Items.ClosingDates.SelectedRows;
			
			For Each SelectedRow In SelectedRows Do
				Row = ClosingDates.FindByID(SelectedRow);
				Row.PeriodEndClosingDateDetails              = SelectedValue.PeriodEndClosingDateDetails;
				Row.PermissionDaysCount         = SelectedValue.PermissionDaysCount;
				Row.PeriodEndClosingDate                      = SelectedValue.PeriodEndClosingDate;
				WriteDetailsAndPeriodEndClosingDate(Row);
			EndDo;
			SetFieldsToCalculate(ClosingDates.GetItems());
			UpdateClosingDatesAvailabilityOfCurrentUser();
		EndIf;
		
		// Cancel lock of selected rows.
		UnlockAllRecordsAtServer(LocksAddress);
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If Upper(EventName) <> Upper("Write_ConstantsSet") Then
		Return;
	EndIf;
	
	If Upper(Source) = Upper("UseImportForbidDates")
	 Or Upper(Source) = Upper("UsePeriodClosingDates") Then
		
		AttachIdleHandler("OnChangeOfRestrictionDatesUsage", 0.1, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit Then
		Return;
	EndIf;
	
	QuestionText = NotificationTextOfUnusedSettingModes();
	If Not ValueIsFilled(QuestionText) Then
		Return;
	EndIf;
	
	QuestionText = NStr("ru = 'Заданные настройки дат запрета будут автоматически скорректированы.'; en = 'The period-end closing date settings will be adjusted automatically.'; pl = 'Określone ustawienia daty zakazu zostaną automatycznie dostosowane.';de = 'Die voreingestellten Einstellungen für das Verbotsdatum werden automatisch korrigiert.';ro = 'Setările specificate ale datelor de interdicție vor fi corectate automat.';tr = 'Belirtilen yasak tarih ayarları otomatik olarak ayarlanır.'; es_ES = 'Los ajustes establecidos de restricción serán automáticamente corregidos.'") 
		+ Chars.LF + Chars.LF + QuestionText + Chars.LF + Chars.LF + NStr("ru = 'Закрыть?'; en = 'Close?'; pl = 'Chcesz zamknąć?';de = 'Schließen?';ro = 'Închideți?';tr = 'Kapatılsın mı?'; es_ES = '¿Cerrar?'");
	CommonClient.ShowArbitraryFormClosingConfirmation(
		ThisObject, Cancel, Exit, QuestionText, "CloseFormWithoutConfirmation");
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	UnlockAllRecordsAtServer(LocksAddress);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OnChangeOfRestrictionDatesUsage()
	
	OnChangeOfRestrictionDatesUsageAtServer();
	
EndProcedure

&AtServer
Procedure OnChangeOfRestrictionDatesUsageAtServer()
	
	Items.ClosingDatesUsage.CurrentPage = ?(Parameters.DataImportRestrictionDates
		AND Not Constants.UseImportForbidDates.Get()
		Or Not Parameters.DataImportRestrictionDates
		AND Not Constants.UsePeriodClosingDates.Get(), 
		Items.Disabled, Items.Enabled);
	
EndProcedure

&AtClient
Procedure SetPeriodEndClosingDateOnChange(Item)
	
	SelectedValue = SetPeriodEndClosingDateNew;
	If SetPeriodEndClosingDate = SelectedValue Then
		Return;
	EndIf;
	
	CurrentSettingOfPeriodEndClosingDate = CurrentSettingOfPeriodEndClosingDate(Parameters.DataImportRestrictionDates);
	If CurrentSettingOfPeriodEndClosingDate = "ForUsers" AND SelectedValue = "ForAllUsers" Then
		
		If HasUnavailableObjects Then
			ShowMessageBox(, NStr("ru = 'Недостаточно прав для изменения дат запрета.'; en = 'You are not authorized to edit period-end closing dates.'; pl = 'Nie masz wystarczających uprawnień, aby zmienić dat zakazów.';de = 'Nicht genügend Berechtigungen zum Ändern der Sperrdaten.';ro = 'Drepturi insuficiente pentru modificarea datelor de interdicție.';tr = 'Yasak tarihlerini değiştirmek için yeterli hak yok.'; es_ES = 'Insuficientes derechos para cambiar las fechas de restricción.'"));
			Return;	
		EndIf;	
			
		QuestionText = NStr("ru = 'Отключить все даты запрета, кроме установленных для всех пользователей?'; en = 'Do you want to turn off all period-end closing dates except the dates applied for all users?'; pl = 'Chcesz odłączyć wszystkie daty zakazu, z wyjątkiem tych, ustawionych dla wszystkich użytkowników?';de = 'Alle Verbotsdaten außer den für alle Benutzer festgelegten deaktivieren?';ro = 'Dezactivați toate datele de interdicție, cu excepția celor stabilite pentru toți utilizatorii?';tr = 'Tüm kullanıcılar için belirlenenlerin dışında tüm yasak tarihleri devre dışı bırakılsın mı?'; es_ES = 'Desactivar todas las fechas de restricción excepto las instaladas para todos los usuarios?'");
		ShowQueryBox(
			New NotifyDescription(
				"SetPeriodEndClosingDateChoiceProcessingContinue", ThisObject, SelectedValue),
			QuestionText,
			QuestionDialogMode.YesNo);
		Return;	
	EndIf;
	
	SetPeriodEndClosingDate = SelectedValue;
	ChangeSettingOfPeriodEndClosingDate(SelectedValue, False);
	
EndProcedure

&AtClient
Procedure ClosingDateIndicationMethodClear(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure ClosingDateIndicationMethodChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	If PeriodEndClosingDateSettingMethod = ValueSelected Then
		Return;
	EndIf;
	
	SelectedClosingDateIndicationMethod = ValueSelected;
	
	AttachIdleHandler("IndicationMethodOfClosingDateChoiceProcessingIdleHandler", 0.1, True);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Identical event handlers of PeriodClosingDates and EditPeriodEndClosingDate forms.

&AtClient
Procedure PeriodEndClosingDateDetailsOnChange(Item)
	
	PeriodClosingDatesInternalClientServer.SpecifyPeriodEndClosingDateSetupOnChange(ThisObject);
	WriteCommonPeriodEndClosingDateWithDetails();
	AttachIdleHandler("UpdatePeriodEndClosingDateDisplayOnChangeIdleHandler", 0.1, True);
	
EndProcedure

&AtClient
Procedure PeriodEndClosingDateDetailsClear(Item, StandardProcessing)
	
	StandardProcessing = False;
	PeriodEndClosingDateDetails = Items.PeriodEndClosingDateDetails.ChoiceList[0].Value;
	PeriodClosingDatesInternalClientServer.SpecifyPeriodEndClosingDateSetupOnChange(ThisObject);
	WriteCommonPeriodEndClosingDateWithDetails();
	AttachIdleHandler("UpdatePeriodEndClosingDateDisplayOnChangeIdleHandler", 0.1, True);
	
EndProcedure

&AtClient
Procedure PeriodEndClosingDateOnChange(Item)
	
	PeriodClosingDatesInternalClientServer.SpecifyPeriodEndClosingDateSetupOnChange(ThisObject);
	WriteCommonPeriodEndClosingDateWithDetails();
	AttachIdleHandler("UpdatePeriodEndClosingDateDisplayOnChangeIdleHandler", 0.1, True);
	
EndProcedure

&AtClient
Procedure EnableDataChangeBeforePeriodEndClosingDateOnChange(Item)
	
	PeriodClosingDatesInternalClientServer.SpecifyPeriodEndClosingDateSetupOnChange(ThisObject);
	WriteCommonPeriodEndClosingDateWithDetails();
	AttachIdleHandler("UpdatePeriodEndClosingDateDisplayOnChangeIdleHandler", 0.1, True);
	
EndProcedure

&AtClient
Procedure PermissionDaysCountOnChange(Item)
	
	PeriodClosingDatesInternalClientServer.SpecifyPeriodEndClosingDateSetupOnChange(ThisObject);
	WriteCommonPeriodEndClosingDateWithDetails();
	AttachIdleHandler("UpdatePeriodEndClosingDateDisplayOnChangeIdleHandler", 0.1, True);
	
EndProcedure

&AtClient
Procedure PermissionDaysCountAutoComplete(Item, Text, ChoiceData, Wait, StandardProcessing)
	
	If IsBlankString(Text) Then
		Return;
	EndIf;
	
	PermissionDaysCount = Number(Text);
	
	PeriodClosingDatesInternalClientServer.SpecifyPeriodEndClosingDateSetupOnChange(ThisObject);
	WriteCommonPeriodEndClosingDateWithDetails();
	AttachIdleHandler("UpdatePeriodEndClosingDateDisplayOnChangeIdleHandler", 0.1, True);
	
EndProcedure

&AtClient
Procedure MoreOptionsClick(Item)
	
	ExtendedModeSelected = True;
	Items.ExtendedMode.Visible = True;
	Items.OperationModesGroup.CurrentPage = Items.ExtendedMode;
	
EndProcedure

&AtClient
Procedure LessOptionsClick(Item)
	
	ExtendedModeSelected = False;
	Items.ExtendedMode.Visible = False;
	Items.OperationModesGroup.CurrentPage = Items.SimpleMode;
	
EndProcedure

#EndRegion

#Region UsersFormTableItemsEventHandlers

&AtClient
Procedure UsersSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	AttachIdleHandler("UsersChangeRow", 0.1, True);
	
EndProcedure

&AtClient
Procedure UsersOnActivateRow(Item)
	
	AttachIdleHandler("UpdateUserDataIdleHandler", 0.1, True);
	
EndProcedure

&AtClient
Procedure UsersRestoreCurrentRowAfterCancelOnActivateRow()
	
	Items.Users.CurrentRow = UsersCurrentRow;
	
EndProcedure

&AtClient
Procedure UsersBeforeAddRow(Item, Cancel, Clone, Parent, Folder)
	
	// Do not copy as users cannot be repeated.
	If Clone Then
		Cancel = True;
		Return;
	EndIf;
	
	If UsersContinueAdding <> True Then
		Cancel = True;
		UsersContinueAdding = True;
		Items.Users.AddRow();
		Return;
	EndIf;
	
	UsersContinueAdding = Undefined;
	
	ClosingDates.GetItems().Clear();
	
EndProcedure

&AtClient
Procedure UsersBeforeRowChange(Item, Cancel)
	
	CurrentData = Item.CurrentData;
	Field          = Item.CurrentItem;
	
	If Field <> Items.UsersFullPresentation AND Not ValueIsFilled(CurrentData.Presentation) Then
		// All values other than a predefined value "<For all users>" are to be filled in before setting 
		// details or a period-end closing date.
		Item.CurrentItem = Items.UsersFullPresentation;
	EndIf;
	
	Items.UsersComment.ReadOnly =
		Not ValueIsFilled(CurrentData.Presentation);
	
	If ValueIsFilled(CurrentData.Presentation) Then
		DataDetails = New Structure("PeriodEndClosingDate, PeriodEndClosingDateDetails, Comment");
		FillPropertyValues(DataDetails, CurrentData);
		
		LockUserRecordSetAtServer(CurrentData.User,
			LocksAddress, DataDetails);
		
		FillPropertyValues(CurrentData, DataDetails);
	EndIf;
	
EndProcedure

&AtClient
Procedure UsersBeforeDelete(Item, Cancel)
	
	Cancel = True;
	
	CurrentData = Items.Users.CurrentData;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("CurrentData", CurrentData);
	
	// Item for all users is always present.
	AdditionalParameters.Insert("ClosingDatesForAllUsers",
		CurrentData.User = ValueForAllUsers);
	
	If ValueIsFilled(CurrentData.Presentation) AND Not CurrentData.NoPeriodEndClosingDate Then
		// Confirm to delete users with records.
		If AdditionalParameters.ClosingDatesForAllUsers Then
			QuestionText = NStr("ru = 'Отключить даты запрета для всех пользователей?'; en = 'Do you want to turn off period-end closing dates for all users?'; pl = 'Chcesz odłączyć daty zakazu dla wszystkich użytkowników?';de = 'Verbotsdaten für alle Benutzer deaktivieren?';ro = 'Dezactivați datele de interdicție stabilite pentru toți utilizatorii?';tr = 'Tüm kullanıcılar için yasak tarihleri kapatılsın mı?'; es_ES = '¿Desactivar las fechas de restricción para todos los usuarios?'");
		Else
			If TypeOf(CurrentData.User) = Type("CatalogRef.Users") Then
				QuestionText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Отключить даты запрета для ""%1""?'; en = 'Do you want to turn off period-end closing dates for ""%1""?'; pl = 'Chcesz odłączyć daty zakazu dla ""%1""?';de = 'Verbotsdaten für ""%1"" deaktivieren?';ro = 'Dezactivați datele de interdicție pentru ""%1""?';tr = '""%1"" için yasak tarihleri kapatılsın mı?'; es_ES = '¿Desactivar las fechas de restricción para ""%1""?'"), CurrentData.User);
				
			ElsIf TypeOf(CurrentData.User) = Type("CatalogRef.UserGroups") Then
				QuestionText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Отключить даты запрета для группы пользователей ""%1""?'; en = 'Do you want to turn off period-end closing dates for ""%1"" user group?'; pl = 'Chcesz odłączyć daty zakazu dla grupy użytkowników ""%1""?';de = 'Verbotsdaten für Benutzergruppen deaktivieren ""%1""?';ro = 'Dezactivați datele de interdicție pentru grupul de utilizatori ""%1""?';tr = '""%1"" Kullanıcı grubu için yasak tarihleri kapatılsın mı?'; es_ES = '¿Desactivar las fechas de restricción para el grupo de usuarios ""%1""?'"), CurrentData.User);
				
			ElsIf TypeOf(CurrentData.User) = Type("CatalogRef.ExternalUsers") Then
				QuestionText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Отключить даты запрета для внешнего пользователя ""%1""?'; en = 'Do you want to turn off period-end closing dates for external user ""%1""?'; pl = 'Chcesz odłączyć daty zakazu dla zewnętrznego użytkownika ""%1""?';de = 'Verbotsdaten für externe Benutzer deaktivieren ""%1""?';ro = 'Dezactivați datele de interdicție pentru utilizatorul extern ""%1""?';tr = '""%1"" harici kullanıcı grubu için yasak tarihleri kapatılsın mı?'; es_ES = '¿Desactivar las fechas de restricción para el usuario externo ""%1""?'"), CurrentData.User);
				
			ElsIf TypeOf(CurrentData.User) = Type("CatalogRef.ExternalUsersGroups") Then
				QuestionText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Отключить даты запрета для группы внешних пользователей ""%1""?'; en = 'Do you want to turn off period-end closing dates for external user group ""%1""?'; pl = 'Chcesz odłączyć daty zakazu dla grupy zewnętrznych użytkowników ""%1""?';de = 'Verbotsdaten für externe Benutzergruppen deaktivieren ""%1""?';ro = 'Dezactivați datele de interdicție pentru grupul de utilizatori externi ""%1""?';tr = '""%1"" harici kullanıcı grubu için yasak tarihleri kapatılsın mı?'; es_ES = '¿Desactivar las fechas de restricción para el grupo de los usuarios externos ""%1""?'"), CurrentData.User);
			Else
				QuestionText = NStr("ru = 'Отключить даты запрета?'; en = 'Do you want to turn off period-end closing dates?'; pl = 'Chcesz odłączyć daty zakazu?';de = 'Die Verbotsdaten deaktivieren?';ro = 'Dezactivați datele de interdicție?';tr = 'Yasak tarihleri kapatılsın mı?'; es_ES = '¿Desactivar las fechas de restricción?'")
			EndIf;
		EndIf;
		
		ShowQueryBox(
			New NotifyDescription(
				"UsersBeforeDeleteConfirmation", ThisObject, AdditionalParameters),
			QuestionText, QuestionDialogMode.YesNo);
		
	Else
		UsersBeforeDeleteContinue(Undefined, AdditionalParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure UsersOnStartEdit(Item, NewRow, Clone)
	
	CurrentData = Items.Users.CurrentData;
	
	If Not ValueIsFilled(CurrentData.Presentation) Then
		CurrentData.PictureNumber = -1;
		AttachIdleHandler("UsersOnStartEditIdleHandler", 0.1, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure UsersOnEditEnd(Item, NewRow, CancelEdit)
	
	SelectedUser = Undefined;
	
	UnlockAllRecordsAtServer(LocksAddress);
	
	Items.UsersFullPresentation.ReadOnly = False;
	Items.UsersComment.ReadOnly = False;
	
EndProcedure

&AtClient
Procedure UsersChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	UsersChoiceProcessingAtServer(ValueSelected);
	
EndProcedure

&AtServer
Procedure UsersChoiceProcessingAtServer(SelectedValue)
	
	Filter = New Structure("User");
	
	For Each Value In SelectedValue Do
		Filter.User = Value;
		If ClosingDatesUsers.FindRows(Filter).Count() = 0 Then
			LockAndWriteBlankDates(LocksAddress,
				SectionEmptyRef, SectionEmptyRef, Filter.User, "");
			
			UserDetails = ClosingDatesUsers.Add();
			UserDetails.User  = Filter.User;
			
			UserDetails.Presentation = UserPresentationText(
				ThisObject, Filter.User);
			
			UserDetails.FullPresentation = UserDetails.Presentation;
		EndIf;
	EndDo;
	
	FillPicturesNumbersOfClosingDatesUsers(ThisObject);
	
	UnlockAllRecordsAtServer(LocksAddress);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Event handlers of the FullPresentation item of the Users form table.

&AtClient
Procedure UsersFullPresentationOnChange(Item)
	
	CurrentData = Items.Users.CurrentData;
	
	If Not ValueIsFilled(CurrentData.FullPresentation) Then
		CurrentData.FullPresentation = CurrentData.Presentation;
	EndIf;
	
EndProcedure

&AtClient
Procedure UsersFullPresentationStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.Users.CurrentData;
	If CurrentData.User = ValueForAllUsers Then
		Return;
	EndIf;
	
	// Users can be replaced with themselves or with users not selected in the list.
	SelectPickUsers();
	
EndProcedure

&AtClient
Procedure UsersFullPresentationClear(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure UsersFullPresentationOpen(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If ValueIsFilled(Items.Users.CurrentData.User) Then
		ShowValue(, Items.Users.CurrentData.User);
	EndIf;
	
EndProcedure

&AtClient
Procedure UsersFullPresentationChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.Users.CurrentData;
	If CurrentData.User = ValueSelected Then
		CurrentData.FullPresentation = CurrentData.Presentation;
		Return;
	EndIf;
	
	SelectedUser = ValueSelected;
	AttachIdleHandler("UsersFullPresentationChoiceProcessingIdleHandler", 0.1, True);
	
EndProcedure

&AtClient
Procedure UsersFullPresentationAutoComplete(Item, Text, ChoiceData, Wait, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		StandardProcessing = False;
		ChoiceData = GenerateUserSelectionData(Text);
	EndIf;
	
EndProcedure

&AtClient
Procedure UsersFullPresentationTextEditEnd(Item, Text, ChoiceData, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		StandardProcessing = False;
		ChoiceData = GenerateUserSelectionData(Text);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Event handlers of the Comment item of the Users form table.

&AtClient
Procedure UsersCommentOnChange(Item)
	
	CurrentData = Items.Users.CurrentData;
	
	WriteComment(CurrentData.User, CurrentData.Comment);
	NotifyChanged(Type("InformationRegisterRecordKey.PeriodClosingDates"));
	
EndProcedure

#EndRegion

#Region ItemsEventHandlersOfPeriodEndClosingDateFormTable

&AtClient
Procedure ClosingDatesChoice(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	AttachIdleHandler("ClosingDatesChangeRow", 0.1, True);
	
EndProcedure

&AtClient
Procedure ClosingDatesOnActivateRow(Item)
	
	ClosingDatesSetCommandsAvailability(Items.ClosingDates.CurrentData <> Undefined);
	
EndProcedure

&AtClient
Procedure ClosingDatesBeforeAddRow(Item, Cancel, Clone, Parent, Folder)
	
	If Not Items.ClosingDatesAdd.Enabled Then
		Cancel = True;
		Return;
	EndIf;
	
	If Clone
	 Or AllSectionsWithoutObjects
	 Or PeriodEndClosingDateSettingMethod = "BySections" Then
		
		Cancel = True;
		Return;
	EndIf;
	
	If CurrentUser = Undefined Then
		Cancel = True;
		Return;
	EndIf;
	
	CurrentSection = CurrentSection(, True);
	If CurrentSection = SectionEmptyRef Then
		ShowMessageBox(, MessageTextInSelectedSectionClosingDatesForObjectsNotSet(CurrentSection));
		Cancel = True;
		Return;
	EndIf;
	
	SectionObjectsTypes = Sections.Get(CurrentSection).ObjectsTypes;
	
	CurrentData = Items.ClosingDates.CurrentData;
	
	If SectionObjectsTypes <> Undefined
	   AND SectionObjectsTypes.Count() > 0 Then
		
		If ShowCurrentUserSections Then
			Parent = CurrentData.GetParent();
			
			If Not CurrentData.IsSection
			      AND Parent <> Undefined Then
				// Adding the object to the section.
				Cancel = True;
				Item.CurrentRow = Parent.GetID();
				Item.AddRow();
			EndIf;
		ElsIf Item.CurrentRow <> Undefined Then
			Cancel = True;
			Item.CurrentRow = Undefined;
			Item.AddRow();
		EndIf;
	Else
		ShowMessageBox(, MessageTextInSelectedSectionClosingDatesForObjectsNotSet(CurrentSection));
		Cancel = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure ClosingDatesBeforeRowChange(Item, Cancel)
	
	If Not Items.ClosingDatesChange.Enabled Then
		Cancel = True;
		Return;
	EndIf;
	
	CurrentData = Item.CurrentData;
	Field = Items.ClosingDates.CurrentItem;
	
	// Going to an available field or opening a form.
	OpenPeriodEndClosingDateEditForm = False;
	
	If Field = Items.ClosingDatesFullPresentation Then
		If CurrentData.IsSection Then
			If IsAllUsers(CurrentUser) Then
				// All sections are always filled in, do not change them.
				If CurrentData.PeriodEndClosingDateDetails <> "Custom"
				 Or Field = Items.ClosingDatesDetailsClosingDatesPresentation Then
					OpenPeriodEndClosingDateEditForm = True;
				Else
					CurrentItem = Items.ClosingDatesClosingDate;
				EndIf;
			EndIf;
			
		ElsIf ValueIsFilled(CurrentData.Presentation) Then
			If CurrentData.PeriodEndClosingDateDetails <> "Custom"
			 Or Field = Items.ClosingDatesDetailsClosingDatesPresentation Then
				OpenPeriodEndClosingDateEditForm = True;
			Else
				CurrentItem = Items.ClosingDatesClosingDate;
			EndIf;
		EndIf;
	Else
		If Not ValueIsFilled(CurrentData.Presentation) Then
			// Fill in the object before changing description or a period-end closing date, otherwise, data 
			// cannot be written to the register.
			CurrentItem = Items.ClosingDatesFullPresentation;
			
		ElsIf CurrentData.PeriodEndClosingDateDetails <> "Custom"
			  Or Field = Items.ClosingDatesDetailsClosingDatesPresentation Then
			OpenPeriodEndClosingDateEditForm = True;
			
		ElsIf CurrentItem = Items.ClosingDatesClosingDate Then
			CurrentItem = Items.ClosingDatesClosingDate;
		EndIf;
	EndIf;
	
	// Locking the record before editing.
	If ValueIsFilled(CurrentData.Presentation) Then
		ReadProperties = LockUserRecordAtServer(LocksAddress,
			CurrentSection(), CurrentData.Object, CurrentUser);
		
		UpdateReadPropertiesValues(
			CurrentData, ReadProperties, Items.Users.CurrentData);
	EndIf;
	
	If OpenPeriodEndClosingDateEditForm Then
		Cancel = True;
		EditPeriodEndClosingDateInForm();
	EndIf;
	
	If Cancel Then
		Items.ClosingDatesFullPresentation.ReadOnly = False;
		Items.ClosingDatesDetailsClosingDatesPresentation.ReadOnly = False;
		Items.ClosingDatesClosingDate.ReadOnly = False;
	Else
		// Locking unavailable fields.
		Items.ClosingDatesFullPresentation.ReadOnly =
			ValueIsFilled(CurrentData.Presentation);
		
		Items.ClosingDatesDetailsClosingDatesPresentation.ReadOnly = True;
		Items.ClosingDatesClosingDate.ReadOnly =
			    Not ValueIsFilled(CurrentData.Presentation)
			Or CurrentData.PeriodEndClosingDateDetails <> "Custom";
	EndIf;
	
EndProcedure

&AtClient
Procedure ClosingDatesBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	CurrentData = Items.ClosingDates.CurrentData;
	SeveralSectionsSelected = Items.ClosingDates.SelectedRows.Count() > 1;
	
	If SeveralSectionsSelected Then
		QuestionText = NStr("ru = 'Отключить даты запрета для выбранных разделов?'; en = 'Do you want to turn off period-end closing dates for the selected sections?'; pl = 'Chcesz odłączyć daty zakazu dla wybranych sekcji?';de = 'Sperrdaten für ausgewählte Abschnitte deaktivieren?';ro = 'Dezactivați datele de interdicție pentru compartimentele selectate?';tr = 'Seçilen bölümler için yasak tarihlerini devre dışı bırak?'; es_ES = '¿Desactivar las fechas de restricción para apartados seleccionados?'");
	ElsIf CurrentData.IsSection Then
		If ValueIsFilled(CurrentData.Section) Then
			If CurrentData.GetItems().Count() > 0 Then
				QuestionText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Отключить все настроенные даты запрета для раздела ""%1"" и его объектов?'; en = 'Do you want to turn off all period-end closing dates for section ""%1"" and its objects?'; pl = 'Chcesz odłączyć wszystkie skonfigurowane daty zakazu dla sekcji ""%1"" i jej obiektów?';de = 'Alle konfigurierten Verbotsdaten für den Abschnitt ""%1"" und seine Objekte deaktivieren?';ro = 'Dezactivați toate datele de interdicție setate pentru compartimentul ""%1"" și obiectele lui?';tr = '""%1"" bölümü ve onun nesneleri için tüm ayarlanan yasak tarihleri kapatılsın mı?'; es_ES = '¿Desactivar todas las fechas de restricción ajustadas para la sección ""%1"" y sus objetos?'"), CurrentData.Section);
			Else
				QuestionText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Отключить дату запрета для раздела ""%1""?'; en = 'Do you want to turn off the period-end closing date for section ""%1""?'; pl = 'Chcesz odłączyć datę zakazu dla sekcji ""%1""?';de = 'Das Verbotsdatum für den Abschnitt ""%1"" deaktivieren?';ro = 'Dezactivați data de interdicție pentru compartimentul ""%1""?';tr = '""%1"" bölüm için yasak tarihi kapatılsın mı?'; es_ES = '¿Desactivar la fecha de restricción para la sección ""%1""?'"), CurrentData.Section);
			EndIf;
		Else
			QuestionText = NStr("ru = 'Отключить общую дату запрета для всех разделов?'; en = 'Do you want to turn off the single-date restriction setting for all sections?'; pl = 'Chcesz odłączyć całkowitą datę zakazu dla wszystkich sekcji?';de = 'Das gesamte Verbotsdatum für alle Abschnitte deaktivieren?';ro = 'Dezactivați data de interdicție comună pentru toate compartimentele?';tr = 'Tüm bölümler için ortak yasak tarihi kapatılsın mı?'; es_ES = '¿Desactivar la fecha de restricción común para todas las secciones?'");
		EndIf;
	Else
		QuestionText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Отключить дату запрета для объекта ""%1""?'; en = 'Do you want to turn off the period-end closing date for object ""%1""?'; pl = 'Chcesz odłączyć datę zakazu na obiekcie ""%1""?';de = 'Verbotsdatum für Objekt ""%1"" deaktivieren?';ro = 'Dezactivați data de interdicție pentru obiectul ""%1""?';tr = '""%1"" nesne için yasak tarihi kapatılsın mı?'; es_ES = '¿Desactivar la fecha de restricción del objeto ""%1""?'"), CurrentData.Object);
	EndIf;
	
	If SeveralSectionsSelected Then
		ShowQueryBox(New NotifyDescription("ClosingDatesBeforeDeleteRowCompletion", 
			ThisObject, Items.ClosingDates.SelectedRows),
			QuestionText, QuestionDialogMode.YesNo);
		Return;
	EndIf;	
		
	If CurrentData.IsSection Then
		SectionItems = CurrentData.GetItems();
		
		If PeriodEndClosingDateSet(CurrentData, CurrentUser) Or SectionItems.Count() > 0 Then
			// Deleting a period-end closing date for the section (i.e. all section objects).
			ShowQueryBox(New NotifyDescription("ClosingDatesBeforeDeleteSection", ThisObject, CurrentData),
				QuestionText, QuestionDialogMode.YesNo);
		Else
			MessageText = NStr("ru = 'Для отключения даты запрета по конкретному объекту необходимо выбрать интересующий объект в одном из разделов.'; en = 'To turn off a period-end closing date for an object, select the object in one of the sections.'; pl = 'Aby wyłączyć datę zakazu dla danego obiektu, musisz wybrać obiekt, będący przedmiotem zainteresowania, w jednej z sekcji.';de = 'Um das Verbotsdatum für ein bestimmtes Objekt zu deaktivieren, sollten Sie das Objekt von Interesse in einem der Abschnitte auswählen.';ro = 'Pentru dezactivarea datei de interdicție pentru obiectul concret trebuie să selectați obiectul dorit în unul din compartimente.';tr = 'Belirli bir nesnenin yasak tarihini devre dışı bırakmak için, bölümlerden birinde ilgili nesneyi seçmeniz gerekir.'; es_ES = 'Para desactivar la fecha de restricción por el objeto concreto es necesario seleccionar este objeto en una de las secciones.'");
			ShowMessageBox(, MessageText);
		EndIf;
		Return;
	EndIf;
		
	If PeriodEndClosingDateSet(CurrentData, CurrentUser) Then
		// Deleting a period-end closing date for the object by section.
		ShowQueryBox(New NotifyDescription("ClosingDatesBeforeDeleteRowCompletion", ThisObject, 
			Items.ClosingDates.SelectedRows),	QuestionText, QuestionDialogMode.YesNo);
		Return;
	EndIf;
	
	ClosingDatesOnDelete(CurrentData);
	
EndProcedure

&AtClient
Procedure ClosingDatesOnStartEdit(Item, NewRow, Clone)
	
	If Not NewRow Then
		Return;
	EndIf;
	
	If Not Items.ClosingDates.CurrentData.IsSection Then
		Items.ClosingDates.CurrentData.Section = CurrentSection(, True);
	EndIf;
	If IsAllUsers(CurrentUser) Or Not Items.ClosingDates.CurrentData.IsSection Then
		Items.ClosingDates.CurrentData.PeriodEndClosingDateDetails = "Custom";
	EndIf;
	SetClosingDateDetailsPresentation(Items.ClosingDates.CurrentData);
	AttachIdleHandler("IdleHandlerSelectObjects", 0.1, True);
	
EndProcedure

&AtClient
Procedure ClosingDatesOnEditEnd(Item, NewRow, CancelEdit)
	
	CurrentData = Items.ClosingDates.CurrentData;
	
	If CurrentUser <> Undefined Then
		WriteDetailsAndPeriodEndClosingDate(CurrentData);
	EndIf;
	
	UnlockAllRecordsAtServer(LocksAddress);
	
	Items.ClosingDatesFullPresentation.ReadOnly = False;
	Items.ClosingDatesDetailsClosingDatesPresentation.ReadOnly = False;
	SetClosingDateDetailsPresentation(CurrentData);
	UpdateClosingDatesAvailabilityOfCurrentUser();
	
EndProcedure

&AtClient
Procedure ClosingDatesChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.ClosingDates.CurrentData;
	If CurrentData <> Undefined AND CurrentData.Object = ValueSelected Then
		Return;
	EndIf;
	
	SectionID = Undefined;
	
	If ShowCurrentUserSections Then
		Parent = CurrentData.GetParent();
		If Parent = Undefined Then
			ObjectCollection    = CurrentData.GetItems();
			SectionID = CurrentData.GetID();
		Else
			ObjectCollection    = Parent.GetItems();
			SectionID = Parent.GetID();
		EndIf;
	Else
		ObjectCollection = ClosingDates.GetItems();
	EndIf;
	
	If TypeOf(ValueSelected) = Type("Array") Then
		Objects = ValueSelected;
	Else
		Objects = New Array;
		Objects.Add(ValueSelected);
	EndIf;
	
	ObjectsForAdding = New Array;
	For Each Object In Objects Do
		ValueNotFound = True;
		For Each Row In ObjectCollection Do
			If Row.Object = Object Then
				ValueNotFound = False;
				Break;
			EndIf;
		EndDo;
		If ValueNotFound Then
			ObjectsForAdding.Add(Object);
		EndIf;
	EndDo;
	
	If ObjectsForAdding.Count() > 0 Then
		WriteDates = CurrentUser <> Undefined;
		
		If WriteDates Then
			Comment = CurrentUserComment(ThisObject);
			
			LockAndWriteBlankDates(LocksAddress,
				CurrentSection(, True), ObjectsForAdding, CurrentUser, Comment);
			
			NotifyChanged(Type("InformationRegisterRecordKey.PeriodClosingDates"));
		EndIf;
		
		For Each CurrentObject In ObjectsForAdding Do
			ObjectDetails = ObjectCollection.Add();
			ObjectDetails.Section        = CurrentSection(, True);
			ObjectDetails.Object        = CurrentObject;
			ObjectDetails.Presentation = String(CurrentObject);
			ObjectDetails.FullPresentation = ObjectDetails.Presentation;
			ObjectDetails.PeriodEndClosingDateDetails = "Custom";
			ObjectDetails.RecordExists = WriteDates;
		EndDo;
		SetFieldsToCalculate(ObjectCollection);
		
		If SectionID <> Undefined Then
			Items.ClosingDates.Expand(SectionID, True);
		EndIf;
	EndIf;
	
	UpdateClosingDatesAvailabilityOfCurrentUser();
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Event handlers of the FullPresentation item of the ClosingDates form table.

&AtClient
Procedure ClosingDatesFullPresentationStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	SelectPickObjects();
	
EndProcedure

&AtClient
Procedure ClosingDatesFullPresentationClear(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure ClosingDatesFullPresentationChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.ClosingDates.CurrentData;
	
	If CurrentData.Object = ValueSelected Then
		Return;
	EndIf;
	
	// Object can be replaced only with another object, which is not in the list.
	If ShowCurrentUserSections Then
		ObjectCollection = CurrentData.GetParent().GetItems();
	Else
		ObjectCollection = ClosingDates.GetItems();
	EndIf;
	
	ValueFound = True;
	For Each Row In ObjectCollection Do
		If Row.Object = ValueSelected Then
			ValueFound = False;
			Break;
		EndIf;
	EndDo;
	
	If Not ValueFound Then
		ShowMessageBox(, StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = '""%1"" уже есть в списке объектов'; en = '""%1"" is already in the object list'; pl = '""%1"" już jest na liście objektów.';de = '""%1"" ist bereits auf der Liste der Objekte';ro = '""%1"" deja există în lista obiectelor';tr = '""%1"" nesne listesinde zaten mevcut'; es_ES = '""%1"" ya existe en la lista de objetos'"), ValueSelected));
		Return;
	EndIf;
	
	If CurrentData.Object <> ValueSelected Then
		
		PropertiesValues = GetCurrentPropertiesValues(
			CurrentData, Items.Users.CurrentData);
		
		If Not ReplaceObjectInUserRecordAtServer(
					CurrentData.Section,
					CurrentData.Object,
					ValueSelected,
					CurrentUser,
					PropertiesValues,
					LocksAddress) Then
			
			ShowMessageBox(, StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = '""%1"" уже есть в списке объектов.
					|Обновите данные формы (клавиша F5).'; 
					|en = '""%1"" is already in the object list.
					|Refresh the form (F5).'; 
					|pl = '""%1"" już znajduje się na liście obiektów. 
					|Zaktualizuj dane formularza (klawisz F5).';
					|de = '""%1"" ist bereits auf der Liste der Objekte.
					|Aktualisieren Sie die Formulardaten (Taste F5).';
					|ro = '""%1"" deja există în lista obiectelor.
					|Actualizați datele formei (tasta F5).';
					|tr = '""%1"" nesne listesinde zaten mevcut. 
					|Form bilgilerini yenileyin (F5 tuşu).'; 
					|es_ES = '""%1"" ya existe en la lista de objetos.
					|Actualice los datos del formulario (tecla F5).'"), ValueSelected));
			Return;
		Else
			UpdateReadPropertiesValues(
				CurrentData, PropertiesValues, Items.Users.CurrentData);
			
			NotifyChanged(Type("InformationRegisterRecordKey.PeriodClosingDates"));
		EndIf;
	EndIf;
	
	// Setting the selected object.
	CurrentData.Object = ValueSelected;
	CurrentData.Presentation = String(CurrentData.Object);
	CurrentData.FullPresentation = CurrentData.Presentation;
	Items.ClosingDates.EndEditRow(False);
	Items.ClosingDates.CurrentItem = Items.ClosingDatesClosingDate;
	AttachIdleHandler("ClosingDatesChangeRow", 0.1, True);
	
	UpdateClosingDatesAvailabilityOfCurrentUser();
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Event handlers of the PeriodEndClosingDate item of the ClosingDates form table.

&AtClient
Procedure ClosingDatesPeriodEndClosingDateOnChange(Item)
	
	WriteDetailsAndPeriodEndClosingDate();
	
	UpdateClosingDatesAvailabilityOfCurrentUser();
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Update(Command)
	
	UpdateAtServer();
	ExpandUserData();
	
EndProcedure

&AtClient
Procedure PickObjects(Command)
	
	If CurrentUser = Undefined Then
		Return;
	EndIf;
	
	SelectPickObjects(True);
	
EndProcedure

&AtClient
Procedure PickUsers(Command)
	
	SelectPickUsers(True);
	
EndProcedure

&AtClient
Procedure ShowReport(Command)
	
	If Parameters.DataImportRestrictionDates Then
		ReportFormName = "Report.ImportRestrictionDates.Form";
	Else
		ReportFormName = "Report.PeriodClosingDates.Form";
	EndIf;
	
	OpenForm(ReportFormName);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// Marking a required user.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UsersFullPresentation.Name);
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	FIlterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FIlterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FIlterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ClosingDatesUsers.FullPresentation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	FIlterGroup2 = FIlterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FIlterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FIlterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ClosingDatesUsers.User");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ValueList = New ValueList;
	ValueList.Add(Enums.PeriodClosingDatesPurposeTypes.ForAllUsers);
	ValueList.Add(Enums.PeriodClosingDatesPurposeTypes.ForAllInfobases);
	ItemFilter.RightValue = ValueList;
	
	ItemFilter = FIlterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ClosingDatesUsers.NoPeriodEndClosingDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	// Marking a required object.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ClosingDatesFullPresentation.Name);
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ClosingDates.FullPresentation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	// Registering a blank date.
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ClosingDatesClosingDate.Name);
	
	Item.Appearance.SetParameterValue("Text", "");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ClosingDates.PeriodEndClosingDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	// Appearance of a period-end closing date value is not set.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ClosingDatesDetailsClosingDatesPresentation.Name);
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ClosingDates.PeriodEndClosingDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	// Default period-end closing date.
	Item = ConditionalAppearance.Items.Add();
	Item.Appearance.SetParameterValue("Text", NStr("ru = 'Во всех остальных случаях, когда ниже нет уточняющих настроек.'; en = 'Default settings. Effective when there are no overriding settings.'; pl = 'We wszystkich innych przypadkach, gdy poniżej nie ma ustawień określających.';de = 'In allen anderen Fällen, wenn es unten keine klärenden Einstellungen gibt.';ro = 'În toate celelalte cazuri, când mai jos nu există setări de concretizare.';tr = 'Diğer tüm durumlarda, aşağıda netleştirme ayarları yoktur.'; es_ES = 'En otros todos casos cuando no hay ajustes especificados.'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UsersComment.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ClosingDatesUsers.User");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.PeriodClosingDatesPurposeTypes.ForAllUsers);
	ValueList.Add(Enums.PeriodClosingDatesPurposeTypes.ForAllInfobases);
	ItemFilter.RightValue = ValueList;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ClosingDatesUsers.Comment");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
EndProcedure

&AtClient
Procedure ClosingDatesChangeRow()
	
	Items.ClosingDates.ChangeRow();
	
EndProcedure

&AtClient
Procedure UsersChangeRow()
	
	Items.Users.ChangeRow();
	
EndProcedure

&AtClient
Procedure SetPeriodEndClosingDateChoiceProcessingContinue(Response, SelectedValue) Export
	
	If Response = DialogReturnCode.No Then
		SetPeriodEndClosingDateNew = SetPeriodEndClosingDate; 
		Return;
	EndIf;
	
	SetPeriodEndClosingDate = SelectedValue;
	ChangeSettingOfPeriodEndClosingDate(SelectedValue, True);
	
EndProcedure

&AtClient
Procedure IndicationMethodOfClosingDateChoiceProcessingIdleHandler()
	
	SelectedValue = SelectedClosingDateIndicationMethod;
	
	Data = Undefined;
	CurrentMethod = CurrentClosingDateIndicationMethod(CurrentUser,
		SingleSection, ValueForAllUsers, BegOfDay, Data);
	
	QuestionText = "";
	If CurrentMethod = "BySectionsAndObjects" AND SelectedValue = "SingleDate" Then
		QuestionText = NStr("ru = 'Отключить даты запрета, установленные для разделов и объектов?'; en = 'Do you want to turn off period-end closing dates for sections and objects?'; pl = 'Chcesz odłączyć daty zakazów ustawione dla sekcji i obiektów?';de = 'Verbotsdaten für Partitionen und Objekte deaktivieren?';ro = 'Dezactivați datele de interdicție stabilite pentru compartimente și obiecte?';tr = 'Bölümler ve nesneler için yasak tarihleri kapatılsın mi?'; es_ES = '¿Desactivar las fechas de restricción para secciones y objetos?'");
		
	ElsIf CurrentMethod = "BySectionsAndObjects" AND SelectedValue = "BySections"
	      Or CurrentMethod = "ByObjects"          AND SelectedValue = "SingleDate" Then
		QuestionText = NStr("ru = 'Отключить даты запрета, установленные для объектов?'; en = 'Do you want to turn period-end closing dates for objects?'; pl = 'Chcesz odłączyć daty zakazów ustawione dla obiektów?';de = 'Verbotsdaten für Objekte deaktivieren?';ro = 'Dezactivați datele de interdicție stabilite pentru obiecte?';tr = 'Nesneler için belirlenen yasak tarihleri devre dışı bırakılsın mı?'; es_ES = '¿Desactivar las fechas de restricción para objetos?'");
		
	ElsIf CurrentMethod = "BySectionsAndObjects" AND SelectedValue = "ByObjects"
	      Or CurrentMethod = "BySections"          AND SelectedValue = "ByObjects"
	      Or CurrentMethod = "BySections"          AND SelectedValue = "SingleDate" Then
		QuestionText = NStr("ru = 'Отключить даты запрета, установленные для разделов?'; en = 'Do you want to turn off period-end closing dates for sections?'; pl = 'Chcesz odłączyć daty zakazów ustawione dla sekcji?';de = 'Verbotsdaten für Abschnitte deaktivieren?';ro = 'Dezactivați datele de interdicție stabilite pentru compartimente?';tr = 'Bölümler için belirlenen yasak tarihleri kapatılsın mi?'; es_ES = '¿Desactivar las fechas de restricción para secciones?'");
		
	EndIf;
	
	If ValueIsFilled(QuestionText) Then
		
		If HasUnavailableObjects Then
			ShowMessageBox(, NStr("ru = 'Недостаточно прав для изменения дат запрета.'; en = 'You are not authorized to change period-end closing dates.'; pl = 'Nie masz wystarczających uprawnień, aby zmienić dat zakazów.';de = 'Nicht genügend Berechtigungen zum Ändern der Sperrdaten.';ro = 'Drepturi insuficiente pentru modificarea datelor de interdicție.';tr = 'Yasak tarihlerini değiştirmek için yeterli hak yok.'; es_ES = 'Insuficientes derechos para cambiar las fechas de restricción.'"));
			Return;	
		EndIf;	
			
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("Data", Data);
		AdditionalParameters.Insert("SelectedValue", SelectedValue);
		
		ShowQueryBox(
			New NotifyDescription(
				"IndicationMethodOfPeriodEndClosingDateChoiceProcessingContinue",
				ThisObject,
				AdditionalParameters),
			QuestionText,
			QuestionDialogMode.YesNo);
		Return;	
	EndIf;
	
	PeriodEndClosingDateSettingMethod = SelectedValue;
	ErrorText = "";
	ReadUserData(ThisObject, ErrorText, SelectedValue, Data);
	If ValueIsFilled(ErrorText) Then
		CommonClient.MessageToUser(ErrorText);
	EndIf;
	
EndProcedure

&AtClient
Procedure IndicationMethodOfPeriodEndClosingDateChoiceProcessingContinue(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.No Then
		Return;
	EndIf;
	
	PeriodEndClosingDateSettingMethod = AdditionalParameters.SelectedValue;
	
	DeleteExtraOnChangePeriodEndClosingDateIndicationMethod(
		AdditionalParameters.SelectedValue,
		CurrentUser,
		SetPeriodEndClosingDate);
	
	Items.Users.Refresh();
	
	ErrorText = "";
	ReadUserData(ThisObject, ErrorText,
		AdditionalParameters.SelectedValue, AdditionalParameters.Data);
	
	If ValueIsFilled(ErrorText) Then
		CommonClient.MessageToUser(ErrorText);
	EndIf;
	
EndProcedure

&AtClient
Procedure UsersFullPresentationChoiceProcessingIdleHandler()
	
	CurrentData = Items.Users.CurrentData;
	If CurrentData = Undefined Or SelectedUser = Undefined Then
		Return;
	EndIf;
	SelectedValue = SelectedUser;
	
	// You can replace the user only with another user that is not in the list.
	// 
	Filter = New Structure("User", SelectedValue);
	Rows = ClosingDatesUsers.FindRows(Filter);
	
	If Rows.Count() = 0 Then
		If Not ReplaceUserRecordSet(CurrentUser, SelectedValue, LocksAddress) Then
			ShowMessageBox(, StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = '""%1"" уже есть в списке пользователей.
					|Обновите данные формы (клавиша F5).'; 
					|en = '""%1"" is already in the user list.
					|Refresh the form (F5).'; 
					|pl = '""%1"" już znajduje się na liście użytkowników. 
					|Zaktualizuj dane formularza (klawisz F5).';
					|de = '""%1"" ist bereits auf der Liste der Benutzer.
					| Aktualisieren Sie die Formulardaten (Taste F5).';
					|ro = '""%1"" deja există în lista utilizatorilor.
					|Actualizați datele formei (tasta F5).';
					|tr = '""%1"" kullanıcı listesinde zaten mevcut. 
					|Form bilgilerini yenileyin (F5 tuşu).'; 
					|es_ES = '""%1"" ya existe en la lista de usuarios.
					|Actualice los datos del formulario (tecla F5).'"), SelectedValue));
			Return;
		EndIf;
		// Setting the selected user.
		CurrentUser = Undefined;
		CurrentData.User  = SelectedValue;
		CurrentData.Presentation = UserPresentationText(ThisObject, SelectedValue);
		CurrentData.FullPresentation = CurrentData.Presentation;
		
		Items.UsersComment.ReadOnly = False;
		FillPicturesNumbersOfClosingDatesUsers(ThisObject, Items.Users.CurrentRow);
		Items.Users.EndEditRow(False);
		
		UpdateUserData();
		
		NotifyChanged(Type("InformationRegisterRecordKey.PeriodClosingDates"));
		Items.Users.CurrentItem = Items.UsersComment;
		AttachIdleHandler("UsersChangeRow", 0.1, True);
	Else
		ShowMessageBox(, StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = '""%1"" уже есть в списке пользователей.'; en = '""%1"" is already in the user list.'; pl = '""%1"" już jest na liście użytkowników.';de = '""%1"" ist bereits auf der Benutzerliste.';ro = '""%1"" deja există în lista utilizatorilor.';tr = '""%1"" kullanıcı listesinde zaten mevcut'; es_ES = '""%1"" ya existe en la lista de usuarios.'"), SelectedValue));
	EndIf;
	
EndProcedure

&AtClient
Procedure UsersBeforeDeleteConfirmation(Response, AdditionalParameters) Export
	
	If Response <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	DeleteUserRecordSet(AdditionalParameters.CurrentData.User,
		LocksAddress);
	
	If AdditionalParameters.ClosingDatesForAllUsers Then
		If PeriodEndClosingDateSettingMethod = "SingleDate" Then
			PeriodEndClosingDate         = '00010101';
			PeriodEndClosingDateDetails = "";
			RecordExists = False;
			PeriodClosingDatesInternalClientServer.SpecifyPeriodEndClosingDateSetupOnChange(ThisObject);
			PeriodClosingDatesInternalClientServer.UpdatePeriodEndClosingDateDisplayOnChange(ThisObject);
		EndIf;
		AdditionalParameters.Insert("DataDeleted");
		UpdateClosingDatesAvailabilityOfCurrentUser();
	EndIf;
	
	NotifyChanged(Type("InformationRegisterRecordKey.PeriodClosingDates"));
	
	UsersBeforeDeleteContinue(Undefined, AdditionalParameters);
	
EndProcedure

&AtClient
Procedure UsersBeforeDeleteContinue(NotDefined, AdditionalParameters)
	
	CurrentData = AdditionalParameters.CurrentData;
	
	If AdditionalParameters.ClosingDatesForAllUsers Then
		If ShowCurrentUserSections Then
			For Each SectionDetails In ClosingDates.GetItems() Do
				If PeriodEndClosingDateSet(SectionDetails, CurrentUser)
				 Or SectionDetails.GetItems().Count() > 0 Then
					SectionDetails.PeriodEndClosingDate         = '00010101';
					SectionDetails.PeriodEndClosingDateDetails = "";
					SectionDetails.GetItems().Clear();
					SectionDetails.RecordExists = False;
					SetClosingDateDetailsPresentation(SectionDetails);
				EndIf;
			EndDo;
		Else
			If ClosingDates.GetItems().Count() > 0 Then
				ClosingDates.GetItems().Clear();
			EndIf;
		EndIf;
		CurrentData.NoPeriodEndClosingDate = True;
		CurrentData.FullPresentation = CurrentData.Presentation;
		Return;
	EndIf;
	
	PeriodEndClosingDateSettingMethod = Undefined;
	UsersOnDelete();
	
EndProcedure

&AtClient
Procedure UsersOnDelete()
	
	Index = ClosingDatesUsers.IndexOf(ClosingDatesUsers.FindByID(
		Items.Users.CurrentRow));
	
	ClosingDatesUsers.Delete(Index);
	
	If ClosingDatesUsers.Count() <= Index AND Index > 0 Then
		Index = Index -1;
	EndIf;
	
	If ClosingDatesUsers.Count() > 0 Then
		Items.Users.CurrentRow =
			ClosingDatesUsers[Index].GetID();
	EndIf;
	
EndProcedure

&AtClient
Procedure ClosingDatesBeforeDeleteSection(Response, CurrentData) Export
	
	If Response <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	DisableClosingDateForSection(CurrentData);
	NotifyChanged(Type("InformationRegisterRecordKey.PeriodClosingDates"));
	
EndProcedure

&AtClient
Procedure DisableClosingDateForSection(Val CurrentData)
	
	SectionItems = CurrentData.GetItems();
	
	SectionObjects = New Array;
	SectionObjects.Add(CurrentData.Section);
	For Each DataItem In SectionItems Do
		SectionObjects.Add(DataItem.Object);
	EndDo;
	
	DeleteUserRecord(LocksAddress,
		CurrentData.Section, SectionObjects, CurrentUser);
	
	SectionItems.Clear();
	CurrentData.PeriodEndClosingDate         = '00010101';
	CurrentData.PeriodEndClosingDateDetails = "";
	CurrentData.PermissionDaysCount = 0;
	SetClosingDateDetailsPresentation(CurrentData);

EndProcedure

&AtClient
Procedure ClosingDatesBeforeDeleteRowCompletion(Response, SelectedRows) Export
	
	If Response <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	For each SelectedRow In SelectedRows Do
		CurrentData = ClosingDates.FindByID(SelectedRow);
		If CurrentData = Undefined Then // previously deleted
			Continue;
		EndIf;
			
		If CurrentData.IsSection Then
			DisableClosingDateForSection(CurrentData);
			Continue;
		EndIf;	
		
		CurrentSection = CurrentData.GetParent();
		DeleteUserRecord(LocksAddress, 
			CurrentSection.Section, CurrentData.Object, CurrentUser);
		If CurrentSection() = CurrentData.Object Then
			// Common date is deleted.
			PeriodEndClosingDate         = '00010101';
			PeriodEndClosingDateDetails = "";
			RecordExists    = False;
		EndIf;
		
		ClosingDatesOnDelete(CurrentData);
	EndDo;
	
	NotifyChanged(Type("InformationRegisterRecordKey.PeriodClosingDates"));
	
EndProcedure

&AtClient
Procedure ClosingDatesOnDelete(CurrentData)
	
	CurrentParent = CurrentData.GetParent();
	If CurrentParent = Undefined Then
		ClosingDatesItems = ClosingDates.GetItems();
	Else
		ClosingDatesItems = CurrentParent.GetItems();
	EndIf;
	
	Index = ClosingDatesItems.IndexOf(CurrentData);
	ClosingDatesItems.Delete(Index);
	If ClosingDatesItems.Count() <= Index AND Index > 0 Then
		Index = Index -1;
	EndIf;
	
	If ClosingDatesItems.Count() > 0 Then
		Items.ClosingDates.CurrentRow = ClosingDatesItems[Index].GetID();
		
	ElsIf CurrentParent <> Undefined Then
		Items.ClosingDates.CurrentRow = CurrentParent.GetID();
	EndIf;
	
	UpdateClosingDatesAvailabilityOfCurrentUser();
	
EndProcedure

&AtServer
Procedure UpdateAtServer()
	
	OnChangeOfRestrictionDatesUsageAtServer();
	
	// Calculating a restriction date setting.
	SetPeriodEndClosingDate = CurrentSettingOfPeriodEndClosingDate(Parameters.DataImportRestrictionDates);
	SetPeriodEndClosingDateNew = SetPeriodEndClosingDate;
	// Setting visibility according to the calculated import restriction date setting.
	SetVisibility();
	
	// Caching the current date on the server.
	BegOfDay = BegOfDay(CurrentSessionDate());
	
	OldUser = CurrentUser;
	
	ReadUsers();
	
	Filter = New Structure("User", OldUser);
	FoundRows = ClosingDatesUsers.FindRows(Filter);
	If FoundRows.Count() = 0 Then
		CurrentUser = ValueForAllUsers;
	Else
		Items.Users.CurrentRow = FoundRows[0].GetID();
		CurrentUser = OldUser;
	EndIf;
	
	ErrorText = "";
	ReadUserData(ThisObject, ErrorText);
	If ValueIsFilled(ErrorText) Then
		Common.MessageToUser(ErrorText);
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateUserDataIdleHandler()
	
	UpdateUserData();
	
EndProcedure

&AtClient
Procedure UpdateUserData()
	
	CurrentData = Items.Users.CurrentData;
	
	If CurrentData = Undefined
	 Or Not ValueIsFilled(CurrentData.Presentation) Then
		
		NewUser = Undefined;
	Else
		NewUser = CurrentData.User;
	EndIf;
	
	If NewUser = CurrentUser Then
		Return;
	EndIf;
	
	IndicationMethodValueInList =
		Items.PeriodEndClosingDateSettingMethod.ChoiceList.FindByValue(PeriodEndClosingDateSettingMethod);
	
	If CurrentUser <> Undefined AND IndicationMethodValueInList <> Undefined Then
		
		CurrentIndicationMethod = CurrentClosingDateIndicationMethod(
			CurrentUser, SingleSection, ValueForAllUsers, BegOfDay);
		
		CurrentIndicationMethod =
			?(ValueIsFilled(CurrentIndicationMethod), CurrentIndicationMethod, "SingleDate");
		
		// Warning before a significant change in the form appearance.
		If CurrentIndicationMethod <> IndicationMethodValueInList.Value 
			AND Not (IndicationMethodValueInList.Value = "BySectionsAndObjects" 
				AND (CurrentIndicationMethod = "BySections" Or CurrentIndicationMethod = "ByObjects")) Then
				
			ListItem = Items.PeriodEndClosingDateSettingMethod.ChoiceList.FindByValue(
				CurrentIndicationMethod);
			
			ShowQueryBox(
				New NotifyDescription(
					"UpdateUserDateCompletion",
					ThisObject,
					NewUser),
				MessageTextExcessSetting(
					IndicationMethodValueInList.Value,
					?(ListItem = Undefined, CurrentIndicationMethod, ListItem.Presentation),
					CurrentUser,
					ThisObject) + Chars.LF + Chars.LF + NStr("ru = 'Продолжить?'; en = 'Continue?'; pl = 'Kontynuować?';de = 'Fortsetzen?';ro = 'Continuați?';tr = 'Devam et?'; es_ES = '¿Continuar?'"),
				QuestionDialogMode.YesNo);
			Return;
		EndIf;
	EndIf;
	
	UpdateUserDateCompletion(Undefined, NewUser);
	
EndProcedure

&AtClient
Procedure UpdateUserDateCompletion(Response, NewUser) Export
	
	If Response = DialogReturnCode.No Then
		Filter = New Structure("User", CurrentUser);
		FoundRows = ClosingDatesUsers.FindRows(Filter);
		If FoundRows.Count() > 0 Then
			UsersCurrentRow = FoundRows[0].GetID();
			AttachIdleHandler(
				"UsersRestoreCurrentRowAfterCancelOnActivateRow", 0.1, True);
		EndIf;
		Return;
	EndIf;
	
	CurrentUser = NewUser;
	
	// Reading the current user data.
	If NewUser = Undefined Then
		PeriodEndClosingDateSettingMethod = "SingleDate";
		ClosingDates.GetItems().Clear();
		Items.UserData.CurrentPage = Items.UserNotSelectedPage;
	Else
		ErrorText = "";
		ReadUserData(ThisObject, ErrorText);
		If ValueIsFilled(ErrorText) Then
			CommonClient.MessageToUser(ErrorText);
		EndIf;
		ExpandUserData();
	EndIf;
	
	UpdateClosingDatesAvailabilityOfCurrentUser();
	
	// Locking commands Pick, Add (object) until a section is selected.
	ClosingDatesSetCommandsAvailability(False);
	
EndProcedure

&AtServer
Procedure ReadUsers()
	
	Query = New Query;
	Query.SetParameter("AllSectionsWithoutObjects",     AllSectionsWithoutObjects);
	Query.SetParameter("DataImportRestrictionDates", Parameters.DataImportRestrictionDates);
	Query.Text =
	"SELECT DISTINCT
	|	PRESENTATION(PeriodClosingDates.User) AS FullPresentation,
	|	PeriodClosingDates.User,
	|	CASE
	|		WHEN VALUETYPE(PeriodClosingDates.User) = TYPE(Enum.PeriodClosingDatesPurposeTypes)
	|			THEN 0
	|		ELSE 1
	|	END AS CommonAssignment,
	|	PRESENTATION(PeriodClosingDates.User) AS Presentation,
	|	MAX(PeriodClosingDates.Comment) AS Comment,
	|	FALSE AS NoPeriodEndClosingDate,
	|	-1 AS PictureNumber
	|FROM
	|	InformationRegister.PeriodClosingDates AS PeriodClosingDates
	|WHERE
	|	NOT(PeriodClosingDates.Section <> PeriodClosingDates.Object
	|				AND VALUETYPE(PeriodClosingDates.Object) = TYPE(ChartOfCharacteristicTypes.PeriodClosingDatesSections))
	|	AND NOT(VALUETYPE(PeriodClosingDates.Object) <> TYPE(ChartOfCharacteristicTypes.PeriodClosingDatesSections)
	|				AND &AllSectionsWithoutObjects)
	|
	|GROUP BY
	|	PeriodClosingDates.User
	|
	|HAVING
	|	PeriodClosingDates.User <> UNDEFINED AND
	|	CASE
	|		WHEN VALUETYPE(PeriodClosingDates.User) = TYPE(Catalog.Users)
	|				OR VALUETYPE(PeriodClosingDates.User) = TYPE(Catalog.UserGroups)
	|				OR VALUETYPE(PeriodClosingDates.User) = TYPE(Catalog.ExternalUsers)
	|				OR VALUETYPE(PeriodClosingDates.User) = TYPE(Catalog.ExternalUsersGroups)
	|				OR PeriodClosingDates.User = VALUE(Enum.PeriodClosingDatesPurposeTypes.ForAllUsers)
	|			THEN &DataImportRestrictionDates = FALSE
	|		ELSE &DataImportRestrictionDates = TRUE
	|	END";
	
	// Incorrect records are excluded from the selection if the following conditions are met:
	// - object with the value of the CCT.PeriodClosingDatesSections type can be only equal to the section.
	DataExported = Query.Execute().Unload();
	
	// Filling full presentation of users.
	For Each Row In DataExported Do
		Row.Presentation       = UserPresentationText(ThisObject, Row.User);
		Row.FullPresentation = Row.Presentation;
	EndDo;
	
	// Filling a presentation of all users.
	AllUsersDetails = DataExported.Find(ValueForAllUsers, "User");
	If AllUsersDetails = Undefined Then
		AllUsersDetails = DataExported.Insert(0);
		AllUsersDetails.User = ValueForAllUsers;
		AllUsersDetails.NoPeriodEndClosingDate = True;
	EndIf;
	AllUsersDetails.Presentation       = PresentationTextForAllUsers(ThisObject);
	AllUsersDetails.FullPresentation = AllUsersDetails.Presentation;
	
	DataExported.Sort("CommonAssignment Asc, FullPresentation Asc");
	ValueToFormAttribute(DataExported, "ClosingDatesUsers");
	
	FillPicturesNumbersOfClosingDatesUsers(ThisObject);
	
	CurrentUser = ValueForAllUsers;
	
EndProcedure

&AtClient
Procedure ExpandUserData()
	
	If ShowCurrentUserSections Then
		For Each SectionDetails In ClosingDates.GetItems() Do
			Items.ClosingDates.Expand(SectionDetails.GetID(), True);
		EndDo;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure ReadUserData(Form, ErrorText, CurrentIndicationMethod = Undefined, Data = Undefined)
	
	If Form.SetPeriodEndClosingDate = "ForUsers" Then
		
		FoundRows = Form.ClosingDatesUsers.FindRows(
			New Structure("User", Form.CurrentUser));
		
		If FoundRows.Count() > 0 Then
			Form.Items.CurrentUserPresentation.Title =
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Настройка для ""%1"":'; en = 'Setting for ""%1"":'; pl = 'Ustawienia do ""%1"":';de = 'Einstellung für ""%1"":';ro = 'Setarea pentru ""%1"":';tr = '""%1"" için ayarlar:'; es_ES = 'Ajuste para ""%1"":'"), FoundRows[0].Presentation);
		EndIf;
	EndIf;
	
	Form.Items.UserData.CurrentPage =
		Form.Items.UserSelectedPage;
	
	Form.ClosingDates.GetItems().Clear();
	
	If CurrentIndicationMethod = Undefined Then
		CurrentIndicationMethod = CurrentClosingDateIndicationMethod(
			Form.CurrentUser,
			Form.SingleSection,
			Form.ValueForAllUsers,
			Form.BegOfDay,
			Data);
		
		CurrentIndicationMethod = ?(CurrentIndicationMethod = "", "SingleDate", CurrentIndicationMethod);
		If Form.PeriodEndClosingDateSettingMethod <> CurrentIndicationMethod Then
			Form.PeriodEndClosingDateSettingMethod = CurrentIndicationMethod;
		EndIf;
	EndIf;
	
	If Form.PeriodEndClosingDateSettingMethod = "SingleDate" Then
		Form.Items.DateSettingMethodBySectionsObjects.Visible = False;
		Form.Items.DateSettingMethods.CurrentPage = Form.Items.DateSettingMethodSingleDate;
		// For pinning the "Advanced features" group
		Form.Items.ClosingDates.VerticalStretch = False;
		
		FillPropertyValues(Form, Data);
		Form.EnableDataChangeBeforePeriodEndClosingDate = Form.PermissionDaysCount <> 0;
		PeriodClosingDatesInternalClientServer.SpecifyPeriodEndClosingDateSetupOnChange(Form, False);
		PeriodClosingDatesInternalClientServer.UpdatePeriodEndClosingDateDisplayOnChange(Form);
		Form.Items.PeriodEndClosingDateDetails.ReadOnly = False;
		Form.Items.PeriodEndClosingDate.ReadOnly = False;
		Form.Items.EnableDataChangeBeforePeriodEndClosingDate.ReadOnly = False;
		Form.Items.PermissionDaysCount.ReadOnly = False;
		Try
			LockUserRecordAtServer(Form.LocksAddress,
				Form.SectionEmptyRef,
				Form.SectionEmptyRef,
				Form.CurrentUser,
				True);
		Except
			Form.Items.PeriodEndClosingDateDetails.ReadOnly = True;
			Form.Items.PeriodEndClosingDate.ReadOnly = True;
			Form.Items.EnableDataChangeBeforePeriodEndClosingDate.ReadOnly = True;
			Form.Items.PermissionDaysCount.ReadOnly = True;
			
			ErrorText = BriefErrorDescription(ErrorInfo());
		EndTry;
		Return;
	EndIf;
	
	Form.Items.DateSettingMethodBySectionsObjects.Visible = True;
	Form.Items.DateSettingMethods.CurrentPage = Form.Items.DateSettingMethodBySectionsObjects;
	Form.Items.ClosingDates.VerticalStretch = True;
	
	SetCommandBarOfClosingDates(Form);
	
	ClosingDatesParameters = New Structure;
	ClosingDatesParameters.Insert("BegOfDay",                    Form.BegOfDay);
	ClosingDatesParameters.Insert("User",                 Form.CurrentUser);
	ClosingDatesParameters.Insert("SingleSection",           Form.SingleSection);
	ClosingDatesParameters.Insert("ShowSections",            Form.ShowSections);
	ClosingDatesParameters.Insert("AllSectionsWithoutObjects",        Form.AllSectionsWithoutObjects);
	ClosingDatesParameters.Insert("SectionsWithoutObjects",           Form.SectionsWithoutObjects);
	ClosingDatesParameters.Insert("SectionsTableAddress",         Form.SectionsTableAddress);
	ClosingDatesParameters.Insert("FormID",           Form.UUID);
	ClosingDatesParameters.Insert("ClosingDateIndicationMethod",    Form.PeriodEndClosingDateSettingMethod);
	ClosingDatesParameters.Insert("ValueForAllUsers", Form.ValueForAllUsers);
	ClosingDatesParameters.Insert("DataImportRestrictionDates",    Form.Parameters.DataImportRestrictionDates);
	ClosingDatesParameters.Insert("LocksAddress", Form.LocksAddress);
	
	ClosingDates = UserClosingDates(ClosingDatesParameters);
	Form.ShowCurrentUserSections = ClosingDates.ShowCurrentUserSections;
	Form.HasUnavailableObjects = ClosingDates.HasUnavailableObjects;

	// Importing user data to the collection.
	RowsCollection = Form.ClosingDates.GetItems();
	RowsCollection.Clear();
	For Each Row In ClosingDates.ClosingDates Do
		NewRow = RowsCollection.Add();
		FillPropertyValues(NewRow, Row.Value);
		SetClosingDateDetailsPresentation(NewRow);
		SubstringsCollection = NewRow.GetItems();
		
		For Each Substring In Row.Value.SubstringsList Do
			NewSubstring = SubstringsCollection.Add();
			FillPropertyValues(NewSubstring, Substring.Value);
			FillByInternalDetailsOfPeriodEndClosingDate(
				NewSubstring, NewSubstring.PeriodEndClosingDateDetails);
			
			SetClosingDateDetailsPresentation(NewSubstring);
		EndDo;
		
		If NewRow.IsSection Then
			NewRow.SectionWithoutObjects =
				Form.SectionsWithoutObjects.Find(NewRow.Section) <> Undefined;
		EndIf;
	EndDo;
	
	// Setting the field of the ClosingDates form.
	If Form.ShowCurrentUserSections Then
		If Form.AllSectionsWithoutObjects Then
			// Data is used only by the Section dimension.
			// Object dimension is filled in with the Section dimension value.
			// No object display is required.
			Form.Items.ClosingDatesFullPresentation.Title = NStr("ru = 'Раздел'; en = 'Section'; pl = 'Rozdział';de = 'Abschnitt';ro = 'Secțiune';tr = 'Bölüm'; es_ES = 'Sección'");
			Form.Items.ClosingDates.Representation = TableRepresentation.List;
			
		Else
			Form.Items.ClosingDatesFullPresentation.Title = NStr("ru = 'Раздел, объект'; en = 'Section, object'; pl = 'Rozdział, obiekt';de = 'Abschnitt, Objekt';ro = 'Secțiune, obiect';tr = 'Bölüm, nesne'; es_ES = 'Sección, objeto'");
			Form.Items.ClosingDates.Representation = TableRepresentation.Tree;
		EndIf;
	Else
		ObjectsTypesPresentations = "";
		SectionObjectsTypes = Form.Sections.Get(Form.SingleSection).ObjectsTypes;
		If SectionObjectsTypes <> Undefined Then
			For Each TypeProperties In SectionObjectsTypes Do
				ObjectsTypesPresentations = ObjectsTypesPresentations + Chars.LF
					+ TypeProperties.Presentation;
			EndDo;
		EndIf;
		Form.Items.ClosingDatesFullPresentation.Title = TrimAll(ObjectsTypesPresentations);
		Form.Items.ClosingDates.Representation = TableRepresentation.List;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function UserClosingDates(Val Form)
	
	UnlockAllRecordsAtServer(Form.LocksAddress);
	
	Result = New Structure;
	Result.Insert("ShowCurrentUserSections", 
		Form.ShowSections
		Or Form.ClosingDateIndicationMethod = "BySections"
		Or Form.ClosingDateIndicationMethod = "BySectionsAndObjects");
	Result.Insert("HasUnavailableObjects", False);
	Result.Insert("ClosingDates", New ValueList);
	
	// Preparing a value tree of period-end closing dates.
	If Result.ShowCurrentUserSections Then
		ReadClosingDates = ReadUserDataWithSections(
			Form.User,
			Form.AllSectionsWithoutObjects,
			Form.SectionsWithoutObjects,
			Form.SectionsTableAddress,
			Form.BegOfDay,
			Form.DataImportRestrictionDates);
	Else
		ReadClosingDates = ReadUserDataWithoutSections(
			Form.User, Form.SingleSection);
	EndIf;
	
	// For passing from a server to the client in a thick client.
	StringFields = "FullPresentation, Presentation, Section, Object,
	             |PeriodEndClosingDate, PeriodEndClosingDateDetails, PermissionDaysCount,
	             |NoPeriodEndClosingDate, IsSection, SubstringsList, RecordExists";
	
	For Each String In ReadClosingDates.Rows Do
		
		NewString = New Structure(StringFields);
		FillPropertyValues(NewString, String);
		NewString.SubstringsList = New ValueList;
		
		For Each Substring In String.Rows Do
			
			If Not RefAvailableForReading(NewString.Object) Then
				Result.HasUnavailableObjects = True;
			EndIf;	
			NewSubstring = New Structure(StringFields);
			FillPropertyValues(NewSubstring, Substring);
			NewString.SubstringsList.Add(NewSubstring);
			
		EndDo;
		
		Result.ClosingDates.Add(NewString);
	EndDo;
	
	Return Result;
	
EndFunction

&AtServerNoContext
Function ReadUserDataWithSections(Val User,
                                              Val AllSectionsWithoutObjects,
                                              Val SectionsWithoutObjects,
                                              Val SectionsTableAddress,
                                              Val BegOfDay,
                                              Val DataImportRestrictionDates)
	
	// Preparing a value tree of period-end closing dates with the first level by sections.
	// 
	Query = New Query;
	Query.SetParameter("User",              User);
	Query.SetParameter("AllSectionsWithoutObjects",     AllSectionsWithoutObjects);
	Query.SetParameter("DataImportRestrictionDates", DataImportRestrictionDates);
	Query.SetParameter("SectionsTable", GetFromTempStorage(SectionsTableAddress));
	Query.Text =
	"SELECT DISTINCT
	|	SectionsTable.Ref AS Ref,
	|	SectionsTable.Presentation AS Presentation,
	|	SectionsTable.IsCommonDate AS IsCommonDate
	|INTO SectionsTable
	|FROM
	|	&SectionsTable AS SectionsTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Sections.Ref AS Ref,
	|	Sections.Presentation AS Presentation,
	|	Sections.IsCommonDate AS IsCommonDate
	|INTO Sections
	|FROM
	|	(SELECT
	|		SectionsTable.Ref AS Ref,
	|		SectionsTable.Presentation AS Presentation,
	|		SectionsTable.IsCommonDate AS IsCommonDate
	|	FROM
	|		SectionsTable AS SectionsTable
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		PeriodClosingDates.Section,
	|		PeriodClosingDates.Section.Description,
	|		FALSE
	|	FROM
	|		InformationRegister.PeriodClosingDates AS PeriodClosingDates
	|			LEFT JOIN SectionsTable AS SectionsTable
	|			ON PeriodClosingDates.Section = SectionsTable.Ref
	|	WHERE
	|		SectionsTable.Ref IS NULL
	|		AND PeriodClosingDates.User <> UNDEFINED
	|		AND CASE
	|				WHEN VALUETYPE(PeriodClosingDates.User) = TYPE(Catalog.Users)
	|						OR VALUETYPE(PeriodClosingDates.User) = TYPE(Catalog.UserGroups)
	|						OR VALUETYPE(PeriodClosingDates.User) = TYPE(Catalog.ExternalUsers)
	|						OR VALUETYPE(PeriodClosingDates.User) = TYPE(Catalog.ExternalUsersGroups)
	|						OR PeriodClosingDates.User = VALUE(Enum.PeriodClosingDatesPurposeTypes.ForAllUsers)
	|					THEN &DataImportRestrictionDates = FALSE
	|				ELSE &DataImportRestrictionDates = TRUE
	|			END) AS Sections
	|
	|INDEX BY
	|	Sections.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	Sections.Ref AS Section,
	|	Sections.IsCommonDate AS IsCommonDate,
	|	Sections.Presentation AS SectionPresentation,
	|	PeriodClosingDates.Object AS Object,
	|	PRESENTATION(PeriodClosingDates.Object) AS FullPresentation,
	|	PRESENTATION(PeriodClosingDates.Object) AS Presentation,
	|	CASE
	|		WHEN PeriodClosingDates.Object IS NULL
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS NoPeriodEndClosingDate,
	|	PeriodClosingDates.PeriodEndClosingDate AS PeriodEndClosingDate,
	|	PeriodClosingDates.PeriodEndClosingDateDetails AS PeriodEndClosingDateDetails,
	|	FALSE AS IsSection,
	|	0 AS PermissionDaysCount,
	|	TRUE AS RecordExists
	|FROM
	|	Sections AS Sections
	|		LEFT JOIN InformationRegister.PeriodClosingDates AS PeriodClosingDates
	|		ON Sections.Ref = PeriodClosingDates.Section
	|			AND (PeriodClosingDates.User = &User)
	|			AND (NOT(PeriodClosingDates.Section <> PeriodClosingDates.Object
	|					AND VALUETYPE(PeriodClosingDates.Object) = TYPE(ChartOfCharacteristicTypes.PeriodClosingDatesSections)))
	|			AND (NOT(VALUETYPE(PeriodClosingDates.Object) <> TYPE(ChartOfCharacteristicTypes.PeriodClosingDatesSections)
	|					AND &AllSectionsWithoutObjects))
	|
	|ORDER BY
	|	IsCommonDate DESC,
	|	SectionPresentation
	|TOTALS
	|	MAX(IsCommonDate),
	|	MAX(SectionPresentation),
	|	MIN(NoPeriodEndClosingDate),
	|	MAX(IsSection)
	|BY
	|	Section";
	
	ReadClosingDates = Query.Execute().Unload(QueryResultIteration.ByGroups);
	
	For Each Row In ReadClosingDates.Rows Do
		Row.Presentation = Row.SectionPresentation;
		Row.Object    = Row.Section;
		Row.IsSection = True;
		SectionRow = Row.Rows.Find(Row.Section, "Object");
		If SectionRow <> Undefined Then
			Row.RecordExists = True;
			Row.PeriodEndClosingDate = PeriodClosingDatesInternal.PeriodEndClosingDateByDetails(
				SectionRow.PeriodEndClosingDateDetails, SectionRow.PeriodEndClosingDate, BegOfDay);
			
			If ValueIsFilled(SectionRow.PeriodEndClosingDateDetails) Then
				FillByInternalDetailsOfPeriodEndClosingDate(Row, SectionRow.PeriodEndClosingDateDetails);
			Else
				Row.PeriodEndClosingDateDetails = "Custom";
			EndIf;
			Row.Rows.Delete(SectionRow);
		Else
			If Row.Rows.Count() = 1
			   AND Row.Rows[0].Object = Null Then
				
				Row.Rows.Delete(Row.Rows[0]);
			EndIf;
		EndIf;
		Row.FullPresentation = Row.Presentation;
		For Each Substring In Row.Rows Do
			Substring.PeriodEndClosingDate = PeriodClosingDatesInternal.PeriodEndClosingDateByDetails(
				Substring.PeriodEndClosingDateDetails, Substring.PeriodEndClosingDate, BegOfDay);
		EndDo;
	EndDo;
	
	Return ReadClosingDates;
	
EndFunction

&AtServerNoContext
Function ReadUserDataWithoutSections(Val User, Val SingleSection)
	
	// Value tree with the first level by objects.
	BeginTransaction();
	Try
		Query = New Query;
		Query.SetParameter("User",           User);
		Query.SetParameter("SingleSection",     SingleSection);
		Query.SetParameter("CommonDatePresentation", CommonDatePresentationText());
		Query.Text =
		"SELECT ALLOWED
		|	VALUE(ChartOfCharacteristicTypes.PeriodClosingDatesSections.EmptyRef) AS Section,
		|	VALUE(ChartOfCharacteristicTypes.PeriodClosingDatesSections.EmptyRef) AS Object,
		|	&CommonDatePresentation AS FullPresentation,
		|	&CommonDatePresentation AS Presentation,
		|	ISNULL(SingleDate.PeriodEndClosingDate, DATETIME(1, 1, 1, 0, 0, 0)) AS PeriodEndClosingDate,
		|	ISNULL(SingleDate.PeriodEndClosingDateDetails, """") AS PeriodEndClosingDateDetails,
		|	TRUE AS IsSection,
		|	0 AS PermissionDaysCount,
		|	TRUE AS RecordExists
		|FROM
		|	(SELECT
		|		TRUE AS TrueValue) AS Value
		|		LEFT JOIN (SELECT
		|			PeriodClosingDates.PeriodEndClosingDate AS PeriodEndClosingDate,
		|			PeriodClosingDates.PeriodEndClosingDateDetails AS PeriodEndClosingDateDetails
		|		FROM
		|			InformationRegister.PeriodClosingDates AS PeriodClosingDates
		|		WHERE
		|			PeriodClosingDates.User = &User
		|			AND PeriodClosingDates.Section = VALUE(ChartOfCharacteristicTypes.PeriodClosingDatesSections.EmptyRef)
		|			AND PeriodClosingDates.Object = VALUE(ChartOfCharacteristicTypes.PeriodClosingDatesSections.EmptyRef)) AS SingleDate
		|		ON (TRUE)
		|
		|UNION ALL
		|
		|SELECT
		|	&SingleSection,
		|	PeriodClosingDates.Object,
		|	PRESENTATION(PeriodClosingDates.Object),
		|	PRESENTATION(PeriodClosingDates.Object),
		|	PeriodClosingDates.PeriodEndClosingDate,
		|	PeriodClosingDates.PeriodEndClosingDateDetails,
		|	FALSE,
		|	0,
		|	TRUE
		|FROM
		|	InformationRegister.PeriodClosingDates AS PeriodClosingDates
		|WHERE
		|	PeriodClosingDates.User = &User
		|	AND PeriodClosingDates.Section = &SingleSection
		|	AND VALUETYPE(PeriodClosingDates.Object) <> TYPE(ChartOfCharacteristicTypes.PeriodClosingDatesSections)";
		
		ReadClosingDates = Query.Execute().Unload(QueryResultIteration.ByGroups);
	
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Index = ReadClosingDates.Rows.Count()-1;
	While Index >= 0 Do
		Row = ReadClosingDates.Rows[Index];
		FillByInternalDetailsOfPeriodEndClosingDate(Row, Row.PeriodEndClosingDateDetails);
		Index = Index - 1;
	EndDo;
	
	Return ReadClosingDates;
	
EndFunction

&AtServerNoContext
Function RefAvailableForReading(RefToCheck)
	
	QueryText = "
	|SELECT ALLOWED TOP 1
	|	1
	|FROM
	|	[TableName]
	|WHERE
	|	Ref = &Ref
	|";
	
	QueryText = StrReplace(QueryText, "[TableName]", Common.TableNameByRef(RefToCheck));
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Ref", RefToCheck);
	
	Return NOT Query.Execute().IsEmpty();
	
EndFunction

&AtServerNoContext
Procedure LockUserRecordSetAtServer(Val User, Val LocksAddress, DataDetails = Undefined)
	
	BeginTransaction();
	Try
		Query = New Query;
		Query.SetParameter("User", User);
		Query.Text =
		"SELECT
		|	PeriodClosingDates.Section,
		|	PeriodClosingDates.Object,
		|	PeriodClosingDates.User,
		|	PeriodClosingDates.PeriodEndClosingDate,
		|	PeriodClosingDates.PeriodEndClosingDateDetails,
		|	PeriodClosingDates.Comment
		|FROM
		|	InformationRegister.PeriodClosingDates AS PeriodClosingDates
		|WHERE
		|	PeriodClosingDates.User = &User";
		
		DataExported = Query.Execute().Unload();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Locks = GetFromTempStorage(LocksAddress);
	Try
		For Each RecordDetails In DataExported Do
			If LockRecordAtServer(RecordDetails, LocksAddress) Then
				If DataDetails <> Undefined Then
					// Rereading fields PeriodEndClosingDate, PeriodEndClosingDateDetails, and Comment.
					If Locks.NoSectionsAndObjects Then
						If RecordDetails.Section = Locks.SectionEmptyRef
						   AND RecordDetails.Object = Locks.SectionEmptyRef Then
							DataDetails.PeriodEndClosingDate         = RecordDetails.PeriodEndClosingDate;
							DataDetails.PeriodEndClosingDateDetails = RecordDetails.PeriodEndClosingDateDetails;
							DataDetails.Comment         = RecordDetails.Comment;
						EndIf;
					Else
						DataDetails.Comment = RecordDetails.Comment;
					EndIf;
				EndIf;
			EndIf;
		EndDo;
	Except
		UnlockAllRecordsAtServer(LocksAddress);
		Raise;
	EndTry;
	
EndProcedure

&AtServerNoContext
Procedure UnlockAllRecordsAtServer(LocksAddress)
	
	Locks = GetFromTempStorage(LocksAddress);
	RecordKeyValues = New Structure("Section, Object, User");
	Try
		Index = Locks.Content.Count() - 1;
		While Index >= 0 Do
			FillPropertyValues(RecordKeyValues, Locks.Content[Index]);
			RecordKey = InformationRegisters.PeriodClosingDates.CreateRecordKey(RecordKeyValues);
			UnlockDataForEdit(RecordKey, Locks.FormID);
			Locks.Content.Delete(Index);
			Index = Index - 1;
		EndDo;
	Except
		PutToTempStorage(Locks, LocksAddress);
		Raise;
	EndTry;
	PutToTempStorage(Locks, LocksAddress);
	
EndProcedure

&AtServerNoContext
Function LockRecordAtServer(RecordKeyDetails, LocksAddress)
	
	Locks = GetFromTempStorage(LocksAddress);
	RecordKeyValues = New Structure("Section, Object, User");
	FillPropertyValues(RecordKeyValues, RecordKeyDetails);
	RecordKey = InformationRegisters.PeriodClosingDates.CreateRecordKey(RecordKeyValues);
	LockDataForEdit(RecordKey, , Locks.FormID);
	LockAdded = False;
	If Locks.Content.FindRows(RecordKeyValues) = 0 Then
		FillPropertyValues(Locks.Content.Add(), RecordKeyValues);
		LockAdded = True;
	EndIf;
	PutToTempStorage(Locks, LocksAddress);
	
	Return LockAdded;
	
EndFunction

&AtServerNoContext
Function ReplaceUserRecordSet(OldUser, NewUser, LocksAddress)
	
	Locks = GetFromTempStorage(LocksAddress);
	
	If OldUser <> Undefined Then
		LockUserRecordSetAtServer(OldUser, LocksAddress);
	EndIf;
	LockUserRecordSetAtServer(NewUser, LocksAddress);
	
	RecordSet = InformationRegisters.PeriodClosingDates.CreateRecordSet();
	RecordSet.Filter.User.Set(NewUser, True);
	RecordSet.Read();
	If RecordSet.Count() > 0 Then
		Return False;
	EndIf;
	
	If OldUser <> Undefined Then
		BeginTransaction();
		Try
			RecordSet.Filter.User.Set(OldUser, True);
			RecordSet.Read();
			UserData = RecordSet.Unload();
			RecordSet.Clear();
			RecordSet.Write();
			
			UserData.FillValues(NewUser, "User");
			RecordSet.Filter.User.Set(NewUser, True);
			RecordSet.Load(UserData);
			RecordSet.Write();
			
			CommitTransaction();
		Except
			RollbackTransaction();
			UnlockAllRecordsAtServer(LocksAddress);
			Raise;
		EndTry;
	Else
		LockAndWriteBlankDates(LocksAddress,
			Locks.SectionEmptyRef, Locks.SectionEmptyRef, NewUser, "");
	EndIf;
	
	UnlockAllRecordsAtServer(LocksAddress);
	
	Return True;
	
EndFunction

&AtServerNoContext
Procedure DeleteUserRecordSet(Val User, Val LocksAddress)
	
	LockUserRecordSetAtServer(User, LocksAddress);
	
	RecordSet = InformationRegisters.PeriodClosingDates.CreateRecordSet();
	RecordSet.Filter.User.Set(User, True);
	RecordSet.Write();
	
	UnlockAllRecordsAtServer(LocksAddress);
	
EndProcedure

&AtServerNoContext
Procedure WriteComment(User, Comment);
	
	RecordSet = InformationRegisters.PeriodClosingDates.CreateRecordSet();
	RecordSet.Filter.User.Set(User, True);
	RecordSet.Read();
	UserData = RecordSet.Unload();
	UserData.FillValues(Comment, "Comment");
	RecordSet.Load(UserData);
	RecordSet.Write();
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateReadPropertiesValues(CurrentPropertiesValues, ReadProperties, CommentCurrentData = False)
	
	If ReadProperties.Comment <> Undefined Then
		
		If CommentCurrentData = False Then
			CurrentPropertiesValues.Comment = ReadProperties.Comment;
			
		ElsIf CommentCurrentData <> Undefined Then
			CommentCurrentData.Comment = ReadProperties.Comment;
		EndIf;
	EndIf;
	
	If ReadProperties.PeriodEndClosingDate <> Undefined Then
		CurrentPropertiesValues.PeriodEndClosingDate              = ReadProperties.PeriodEndClosingDate;
		CurrentPropertiesValues.PeriodEndClosingDateDetails      = ReadProperties.PeriodEndClosingDateDetails;
		CurrentPropertiesValues.PermissionDaysCount = ReadProperties.PermissionDaysCount;
		SetClosingDateDetailsPresentation(CurrentPropertiesValues);
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function GetCurrentPropertiesValues(CurrentData, CommentCurrentData)
	
	Properties = New Structure;
	Properties.Insert("PeriodEndClosingDate");
	Properties.Insert("PeriodEndClosingDateDetails");
	Properties.Insert("PermissionDaysCount");
	Properties.Insert("Comment");
	
	If CommentCurrentData <> Undefined Then
		Properties.Comment = CommentCurrentData.Comment;
	EndIf;
	
	Properties.PeriodEndClosingDate              = CurrentData.PeriodEndClosingDate;
	Properties.PeriodEndClosingDateDetails      = CurrentData.PeriodEndClosingDateDetails;
	Properties.PermissionDaysCount = CurrentData.PermissionDaysCount;
	
	Return Properties;
	
EndFunction

&AtServerNoContext
Function LockUserRecordAtServer(Val LocksAddress, Val Section, Val Object,
			 Val User, Val UnlockPreviouslyLocked = False)
	
	If UnlockPreviouslyLocked Then
		UnlockAllRecordsAtServer(LocksAddress);
	EndIf;
	
	RecordKeyValues = New Structure;
	RecordKeyValues.Insert("Section",       Section);
	RecordKeyValues.Insert("Object",       Object);
	RecordKeyValues.Insert("User", User);
	
	LockRecordAtServer(RecordKeyValues, LocksAddress);
	
	RecordManager = InformationRegisters.PeriodClosingDates.CreateRecordManager();
	FillPropertyValues(RecordManager, RecordKeyValues);
	RecordManager.Read();
	
	ReadProperties = New Structure;
	ReadProperties.Insert("PeriodEndClosingDate");
	ReadProperties.Insert("PeriodEndClosingDateDetails");
	ReadProperties.Insert("PermissionDaysCount");
	ReadProperties.Insert("Comment");
	
	If RecordManager.Selected() Then
		Locks = GetFromTempStorage(LocksAddress);
		ReadProperties.PeriodEndClosingDate = PeriodClosingDatesInternal.PeriodEndClosingDateByDetails(
			RecordManager.PeriodEndClosingDateDetails, RecordManager.PeriodEndClosingDate, Locks.BegOfDay);
		
		ReadProperties.Comment = RecordManager.Comment;
		FillByInternalDetailsOfPeriodEndClosingDate(
			ReadProperties, RecordManager.PeriodEndClosingDateDetails);
	Else
		BeginTransaction();
		Try
			Query = New Query;
			Query.SetParameter("User", RecordKeyValues.User);
			Query.Text =
			"SELECT TOP 1
			|	PeriodClosingDates.Comment
			|FROM
			|	InformationRegister.PeriodClosingDates AS PeriodClosingDates
			|WHERE
			|	PeriodClosingDates.User = &User";
			Selection = Query.Execute().Select();
			
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
		
		If Selection.Next() Then
			ReadProperties.Comment = Selection.Comment;
		EndIf;
	EndIf;
	
	Return ReadProperties;
	
EndFunction

&AtServerNoContext
Function ReplaceObjectInUserRecordAtServer(Val Section, Val OldObject, Val NewObject, Val User,
			CurrentPropertiesValues, LocksAddress)
	
	// Locking a new record and checking if it exists.
	LockUserRecordAtServer(LocksAddress, Section, NewObject, User);
	
	RecordKeyValues = New Structure;
	RecordKeyValues.Insert("Section",       Section);
	RecordKeyValues.Insert("Object",       NewObject);
	RecordKeyValues.Insert("User", User);
	
	RecordManager = InformationRegisters.PeriodClosingDates.CreateRecordManager();
	FillPropertyValues(RecordManager, RecordKeyValues);
	RecordManager.Read();
	If RecordManager.Selected() Then
		UnlockAllRecordsAtServer(LocksAddress);
		Return False;
	EndIf;
	
	If ValueIsFilled(OldObject) Then
		// Locking an old record
		ReadProperties = LockUserRecordAtServer(LocksAddress,
			Section, OldObject, User);
		
		UpdateReadPropertiesValues(CurrentPropertiesValues, ReadProperties);
		
		RecordKeyValues.Object = OldObject;
		FillPropertyValues(RecordManager, RecordKeyValues);
		RecordManager.Read();
		If RecordManager.Selected() Then
			RecordManager.Delete();
		EndIf;
	EndIf;
	
	If ValueIsFilled(CurrentPropertiesValues.PeriodEndClosingDateDetails) Then
		RecordManager.Section              = Section;
		RecordManager.Object              = NewObject;
		RecordManager.User        = User;
		RecordManager.PeriodEndClosingDate         = InternalPeriodEndClosingDate(CurrentPropertiesValues);
		RecordManager.PeriodEndClosingDateDetails = InternalDetailsOfPeriodEndClosingDate(CurrentPropertiesValues);
		RecordManager.Comment         = CurrentPropertiesValues.Comment;
		RecordManager.Write();
	EndIf;
	
	UnlockAllRecordsAtServer(LocksAddress);
	
	Return True;
	
EndFunction

&AtClient
Function CurrentSection(CurrentData = Undefined, ObjectsSection = False)
	
	If CurrentData = Undefined Then
		CurrentData = Items.ClosingDates.CurrentData;
	EndIf;
	
	If NoSectionsAndObjects
	 Or PeriodEndClosingDateSettingMethod = "SingleDate" Then
		
		CurrentSection = SectionEmptyRef;
		
	ElsIf ShowCurrentUserSections Then
		If CurrentData.IsSection Then
			CurrentSection = CurrentData.Section;
		Else
			CurrentSection = CurrentData.GetParent().Section;
		EndIf;
		
	Else // The only section hidden from a user.
		If CurrentData <> Undefined
		   AND CurrentData.Section = SectionEmptyRef
		   AND Not ObjectsSection Then
			
			CurrentSection = SectionEmptyRef;
		Else
			CurrentSection = SingleSection;
		EndIf;
	EndIf;
	
	Return CurrentSection;
	
EndFunction

&AtClient
Procedure WriteCommonPeriodEndClosingDateWithDetails();
	
	Data = CurrentDataOfCommonPeriodEndClosingDate();
	WriteDetailsAndPeriodEndClosingDate(Data);
	RecordExists = Data.RecordExists;
	
	UpdateClosingDatesAvailabilityOfCurrentUser();
	
EndProcedure

&AtClient
Procedure UpdatePeriodEndClosingDateDisplayOnChangeIdleHandler()
	
	PeriodClosingDatesInternalClientServer.UpdatePeriodEndClosingDateDisplayOnChange(ThisObject);
	
EndProcedure

&AtClient
Function CurrentDataOfCommonPeriodEndClosingDate()
	
	Data = New Structure;
	Data.Insert("Object",                   SectionEmptyRef);
	Data.Insert("Section",                   SectionEmptyRef);
	Data.Insert("PeriodEndClosingDateDetails",      PeriodEndClosingDateDetails);
	Data.Insert("PermissionDaysCount", PermissionDaysCount);
	Data.Insert("PeriodEndClosingDate",              PeriodEndClosingDate);
	Data.Insert("RecordExists",         RecordExists);
	
	Return Data;
	
EndFunction

&AtClient
Procedure WriteDetailsAndPeriodEndClosingDate(CurrentData = Undefined)
	
	If CurrentData = Undefined Then
		CurrentData = Items.ClosingDates.CurrentData;
	EndIf;
	
	If PeriodEndClosingDateSet(CurrentData, CurrentUser, True) Then
		// Writing details or a period-end closing date.
		Comment = CurrentUserComment(ThisObject);
		RecordPeriodEndClosingDateWithDetails(
			CurrentData.Section,
			CurrentData.Object,
			CurrentUser,
			InternalPeriodEndClosingDate(CurrentData),
			InternalDetailsOfPeriodEndClosingDate(CurrentData),
			Comment);
		CurrentData.RecordExists = True;
	Else
		DeleteUserRecord(LocksAddress,
			CurrentData.Section,
			CurrentData.Object,
			CurrentUser);
		
		CurrentData.RecordExists = False;
	EndIf;
	
	NotifyChanged(Type("InformationRegisterRecordKey.PeriodClosingDates"));
	
EndProcedure

&AtServerNoContext
Procedure RecordPeriodEndClosingDateWithDetails(Val Section, Val Object, Val User, Val PeriodEndClosingDate, Val InternalDetailsOfPeriodEndClosingDate, Val Comment)
	
	RecordManager = InformationRegisters.PeriodClosingDates.CreateRecordManager();
	RecordManager.Section              = Section;
	RecordManager.Object              = Object;
	RecordManager.User        = User;
	RecordManager.PeriodEndClosingDate         = PeriodEndClosingDate;
	RecordManager.PeriodEndClosingDateDetails = InternalDetailsOfPeriodEndClosingDate;
	RecordManager.Comment = Comment;
	RecordManager.Write();
	
EndProcedure

&AtServerNoContext
Procedure DeleteUserRecord(Val LocksAddress, Val Section, Val Object, Val User)
	
	RecordManager = InformationRegisters.PeriodClosingDates.CreateRecordManager();
	
	If TypeOf(Object) = Type("Array") Then
		Objects = Object;
	Else
		Objects = New Array;
		Objects.Add(Object);
	EndIf;
	
	For Each CurrentObject In Objects Do
		LockUserRecordAtServer(LocksAddress,
			Section, CurrentObject, User);
	EndDo;
	
	For Each CurrentObject In Objects Do
		RecordManager.Section = Section;
		RecordManager.Object = CurrentObject;
		RecordManager.User = User;
		RecordManager.Read();
		If RecordManager.Selected() Then
			RecordManager.Delete();
		EndIf;
	EndDo;
	
	UnlockAllRecordsAtServer(LocksAddress);
	
EndProcedure

&AtClient
Procedure UpdateClosingDatesAvailabilityOfCurrentUser()
	
	NoPeriodEndClosingDate = True;
	If PeriodEndClosingDateSettingMethod = "SingleDate" Then
		Data = CurrentDataOfCommonPeriodEndClosingDate();
		NoPeriodEndClosingDate = Not PeriodEndClosingDateSet(Data, CurrentUser);
	Else
		For Each Row In ClosingDates.GetItems() Do
			WithoutSectionPeriodEndClosingDate = True;
			If PeriodEndClosingDateSet(Row, CurrentUser) Then
				WithoutSectionPeriodEndClosingDate = False;
			EndIf;
			For Each SubordinateRow In Row.GetItems() Do
				If PeriodEndClosingDateSet(SubordinateRow, CurrentUser) Then
					SubordinateRow.NoPeriodEndClosingDate = False;
					WithoutSectionPeriodEndClosingDate = False;
				Else
					SubordinateRow.NoPeriodEndClosingDate = True;
				EndIf;
			EndDo;
			Row.FullPresentation = Row.Presentation;
			Row.NoPeriodEndClosingDate = WithoutSectionPeriodEndClosingDate;
			NoPeriodEndClosingDate = NoPeriodEndClosingDate AND WithoutSectionPeriodEndClosingDate;
		EndDo;
	EndIf;
	
	If Items.Users.CurrentData <> Undefined Then
		Items.Users.CurrentData.NoPeriodEndClosingDate = NoPeriodEndClosingDate;
	EndIf;
	
EndProcedure

&AtClient
Procedure UsersOnStartEditIdleHandler()
	
	SelectPickUsers();
	
EndProcedure

&AtClient
Procedure SelectPickUsers(Select = False)
	
	If Parameters.DataImportRestrictionDates Then
		SelectPickExchangePlansNodes(Select);
		Return;
	EndIf;
	
	If UseExternalUsers Then
		ShowTypeSelectionUsersOrExternalUsers(
			New NotifyDescription("SelectPickUsersCompletion", ThisObject, Select));
	Else
		SelectPickUsersCompletion(False, Select);
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectPickUsersCompletion(ExternalUsersSelectionAndPickup, Select) Export
	
	If ExternalUsersSelectionAndPickup = Undefined Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("ChoiceMode", True);
	FormParameters.Insert("CurrentRow",
		?(Items.Users.CurrentData = Undefined,
		  Undefined,
		  Items.Users.CurrentData.User));
	
	If ExternalUsersSelectionAndPickup Then
		FormParameters.Insert("SelectExternalUsersGroups", True);
	Else
		FormParameters.Insert("UsersGroupsSelection", True);
	EndIf;
	
	If Select Then
		FormParameters.Insert("CloseOnChoice", False);
		FormOwner = Items.Users;
	Else
		FormOwner = Items.UsersFullPresentation;
	EndIf;
	
	If ExternalUsersSelectionAndPickup Then
	
		If CatalogExternalUsersAvailable Then
			OpenForm("Catalog.ExternalUsers.ChoiceForm", FormParameters, FormOwner);
		Else
			ShowMessageBox(, NStr("ru = 'Недостаточно прав для выбора внешних пользователей.'; en = 'Insufficient rights to select external users.'; pl = 'Niewystarczające uprawnienia do wyboru użytkowników zewnętrznych.';de = 'Unzureichende Rechte zur Auswahl externer Benutzer.';ro = 'Drepturile insuficiente pentru selectarea utilizatorilor externi.';tr = 'Harici kullanıcıları seçmek için yetersiz hak.'; es_ES = 'Insuficientes derechos para seleccionar usuarios externos.'"));
		EndIf;
	Else
		OpenForm("Catalog.Users.ChoiceForm", FormParameters, FormOwner);
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectPickExchangePlansNodes(Select)
	
	FormParameters = New Structure;
	FormParameters.Insert("ChoiceMode", True);
	FormParameters.Insert("SelectAllNodes", True);
	FormParameters.Insert("ExchangePlansForSelection", UserTypesList.UnloadValues());
	FormParameters.Insert("CurrentRow",
		?(Items.Users.CurrentData = Undefined,
		  Undefined,
		  Items.Users.CurrentData.User));
	
	If Select Then
		FormParameters.Insert("CloseOnChoice", False);
		FormParameters.Insert("MultipleChoice", True);
		FormOwner = Items.Users;
	Else
		FormOwner = Items.UsersFullPresentation;
	EndIf;
	
	OpenForm("CommonForm.SelectExchangePlanNodes", FormParameters, FormOwner);
	
EndProcedure

&AtServerNoContext
Function GenerateUserSelectionData(Val Text,
                                             Val IncludeGroups = True,
                                             Val IncludeExternalUsers = Undefined,
                                             Val NoUsers = False)
	
	Return Users.GenerateUserSelectionData(
		Text,
		IncludeGroups,
		IncludeExternalUsers,
		NoUsers);
	
EndFunction

&AtClient
Procedure ShowTypeSelectionUsersOrExternalUsers(ContinuationHandler)
	
	ExternalUsersSelectionAndPickup = False;
	
	If UseExternalUsers Then
		
		UserTypesList.ShowChooseItem(
			New NotifyDescription(
				"ShowTypeSelectionUsersOrExternalUsersCompletion",
				ThisObject,
				ContinuationHandler),
			HeaderTextDataTypeSelection(),
			UserTypesList[0]);
	Else
		ExecuteNotifyProcessing(ContinuationHandler, ExternalUsersSelectionAndPickup);
	EndIf;
	
EndProcedure

&AtClient
Procedure ShowTypeSelectionUsersOrExternalUsersCompletion(SelectedItem, ContinuationHandler) Export
	
	If SelectedItem <> Undefined Then
		ExternalUsersSelectionAndPickup =
			SelectedItem.Value = Type("CatalogRef.ExternalUsers");
		
		ExecuteNotifyProcessing(ContinuationHandler, ExternalUsersSelectionAndPickup);
	Else
		ExecuteNotifyProcessing(ContinuationHandler, Undefined);
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillPicturesNumbersOfClosingDatesUsers(Form, CurrentRow = Undefined)
	
	Rows = New Array;
	If CurrentRow = Undefined Then
		Rows = Form.ClosingDatesUsers;
	Else
		Rows.Add(Form.ClosingDatesUsers.FindByID(CurrentRow));
	EndIf;
	
	RowsArray = New Array;
	For Each Row In Rows Do
		RowProperties = New Structure("User, PictureNumber");
		FillPropertyValues(RowProperties, Row);
		RowsArray.Add(RowProperties);
	EndDo;
	
	FillPicturesNumbersOfClosingDatesUsersAtServer(RowsArray,
		Form.Parameters.DataImportRestrictionDates);
	
	Index = Rows.Count()-1;
	While Index >= 0 Do
		FillPropertyValues(Rows[Index], RowsArray[Index], "PictureNumber");
		Index = Index - 1;
	EndDo;
	
EndProcedure

&AtServerNoContext
Procedure FillPicturesNumbersOfClosingDatesUsersAtServer(RowsArray, DataImportRestrictionDates)
	
	If DataImportRestrictionDates Then
		
		For Each Row In RowsArray Do
			
			If Row.User =
					Enums.PeriodClosingDatesPurposeTypes.ForAllInfobases Then
				
				Row.PictureNumber = -1;
				
			ElsIf Not ValueIsFilled(Row.User) Then
				Row.PictureNumber = 0;
				
			ElsIf Row.User
			        = Common.ObjectManagerByRef(Row.User).ThisNode() Then
				
				Row.PictureNumber = 1;
			Else
				Row.PictureNumber = 2;
			EndIf;
		EndDo;
	Else
		Users.FillUserPictureNumbers(
			RowsArray, "User", "PictureNumber");
	EndIf;
	
EndProcedure

&AtClient
Procedure IdleHandlerSelectObjects()
	
	SelectPickObjects();
	
EndProcedure

&AtClient
Procedure ClosingDatesSetCommandsAvailability(Val CommandsAvailability)
	
	Items.ClosingDatesChange.Enabled                = CommandsAvailability;
	Items.ClosingDatesContextMenuChange.Enabled = CommandsAvailability;
	
	If PeriodEndClosingDateSettingMethod = "ByObjects" Then
		CommandsAvailability = True;
	EndIf;
	
	Items.ClosingDatesPick.Enabled = CommandsAvailability;
	
	Items.ClosingDatesAdd.Enabled                = CommandsAvailability;
	Items.PeriodEndClosingDatesContextMenuAdd.Enabled = CommandsAvailability;
	
EndProcedure

&AtClient
Procedure SelectPickObjects(Select = False)
	
	// Select data type
	CurrentSection = CurrentSection(, True);
	If CurrentSection = SectionEmptyRef Then
		ShowMessageBox(, MessageTextInSelectedSectionClosingDatesForObjectsNotSet(CurrentSection));
		Return;
	EndIf;
	SectionObjectsTypes = Sections.Get(CurrentSection).ObjectsTypes;
	If SectionObjectsTypes = Undefined Or SectionObjectsTypes.Count() = 0 Then
		ShowMessageBox(, MessageTextInSelectedSectionClosingDatesForObjectsNotSet(CurrentSection));
		Return;
	EndIf;
	
	TypesList = New ValueList;
	For Each TypeProperties In SectionObjectsTypes Do
		TypesList.Add(TypeProperties.FullName, TypeProperties.Presentation);
	EndDo;
	
	If TypesList.Count() = 1 Then
		SelectPickObjectsCompletion(TypesList[0], Select);
	Else
		TypesList.ShowChooseItem(
			New NotifyDescription("SelectPickObjectsCompletion", ThisObject, Select),
			HeaderTextDataTypeSelection(),
			TypesList[0]);
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectPickObjectsCompletion(Item, Select) Export
	
	If Item = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Items.ClosingDates.CurrentData;
	
	FormParameters = New Structure;
	FormParameters.Insert("ChoiceMode", True);
	FormParameters.Insert("CurrentRow",
		?(CurrentData = Undefined, Undefined, CurrentData.Object));
	
	If Select Then
		FormParameters.Insert("CloseOnChoice", False);
		FormOwner = Items.ClosingDates;
	Else
		FormOwner = Items.ClosingDatesFullPresentation;
	EndIf;
	
	OpenForm(Item.Value + ".ChoiceForm", FormParameters, FormOwner);
	
EndProcedure

&AtClient
Function NotificationTextOfUnusedSettingModes()
	
	If Not ValueIsFilled(CurrentUser) Then
		Return "";
	EndIf;
	
	SetClosingDatesInDatabase = "";
	IndicationMethodInDatabase = "";
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("BegOfDay",                    BegOfDay);
	AdditionalParameters.Insert("DataImportRestrictionDates",    Parameters.DataImportRestrictionDates);
	AdditionalParameters.Insert("User",                 CurrentUser);
	AdditionalParameters.Insert("SingleSection",           SingleSection);
	AdditionalParameters.Insert("ValueForAllUsers", ValueForAllUsers);
	
	GetCurrentSettings(
		SetClosingDatesInDatabase, IndicationMethodInDatabase, AdditionalParameters);
	
	// User notification
	NotificationText = "";
	If IsAllUsers(CurrentUser) AND IndicationMethodInDatabase = "" Then
		IndicationMethodInDatabase = "SingleDate";
	EndIf;
	
	If PeriodEndClosingDateSettingMethod <> IndicationMethodInDatabase
	   AND (SetPeriodEndClosingDate = SetClosingDatesInDatabase
	      Or IsAllUsers(CurrentUser) ) Then
		
		ListItem = Items.PeriodEndClosingDateSettingMethod.ChoiceList.FindByValue(IndicationMethodInDatabase);
		If ListItem = Undefined Then
			IndicationMethodInDatabasePresentation = IndicationMethodInDatabase;
		Else
			IndicationMethodInDatabasePresentation = ListItem.Presentation;
		EndIf;
		
		If IndicationMethodInDatabasePresentation <> "" Then
			NotificationText = NotificationText + MessageTextExcessSetting(
				PeriodEndClosingDateSettingMethod,
				IndicationMethodInDatabasePresentation,
				CurrentUser,
				ThisObject);
		EndIf;
	EndIf;
	
	Return NotificationText;
	
EndFunction

&AtServerNoContext
Procedure GetCurrentSettings(SetPeriodEndClosingDate, IndicationMethod, Val Parameters)
	
	SetPeriodEndClosingDate = CurrentSettingOfPeriodEndClosingDate(Parameters.DataImportRestrictionDates);
	IndicationMethod = CurrentClosingDateIndicationMethod(
		Parameters.User,
		Parameters.SingleSection,
		Parameters.ValueForAllUsers,
		Parameters.BegOfDay);
	
EndProcedure

&AtServerNoContext
Function CurrentSettingOfPeriodEndClosingDate(DataImportRestrictionDates)
	
	BeginTransaction();
	Try
		Query = New Query;
		Query.SetParameter("DataImportRestrictionDates", DataImportRestrictionDates);
		Query.Text =
		"SELECT TOP 1
		|	TRUE AS HasProhibitions
		|FROM
		|	InformationRegister.PeriodClosingDates AS PeriodClosingDates
		|WHERE
		|	(PeriodClosingDates.User = UNDEFINED
		|			OR CASE
		|				WHEN VALUETYPE(PeriodClosingDates.User) = TYPE(Catalog.Users)
		|						OR VALUETYPE(PeriodClosingDates.User) = TYPE(Catalog.UserGroups)
		|						OR VALUETYPE(PeriodClosingDates.User) = TYPE(Catalog.ExternalUsers)
		|						OR VALUETYPE(PeriodClosingDates.User) = TYPE(Catalog.ExternalUsersGroups)
		|						OR PeriodClosingDates.User = VALUE(Enum.PeriodClosingDatesPurposeTypes.ForAllUsers)
		|					THEN &DataImportRestrictionDates = FALSE
		|				ELSE &DataImportRestrictionDates = TRUE
		|			END)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT TOP 1
		|	TRUE AS ForUsers
		|FROM
		|	InformationRegister.PeriodClosingDates AS PeriodClosingDates
		|WHERE
		|	(PeriodClosingDates.User = UNDEFINED
		|			OR CASE
		|				WHEN VALUETYPE(PeriodClosingDates.User) = TYPE(Catalog.Users)
		|						OR VALUETYPE(PeriodClosingDates.User) = TYPE(Catalog.UserGroups)
		|						OR VALUETYPE(PeriodClosingDates.User) = TYPE(Catalog.ExternalUsers)
		|						OR VALUETYPE(PeriodClosingDates.User) = TYPE(Catalog.ExternalUsersGroups)
		|					THEN &DataImportRestrictionDates = FALSE
		|				ELSE &DataImportRestrictionDates = TRUE
		|			END)
		|	AND VALUETYPE(PeriodClosingDates.User) <> TYPE(Enum.PeriodClosingDatesPurposeTypes)";
		
		QueryResults = Query.ExecuteBatch();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	If QueryResults[0].IsEmpty() Then
		CurrentSettingOfClosingDates = "ForAllUsers";
		
	ElsIf QueryResults[1].IsEmpty() Then
		CurrentSettingOfClosingDates = "ForAllUsers";
	Else
		CurrentSettingOfClosingDates = "ForUsers";
	EndIf;
	
	Return CurrentSettingOfClosingDates;
	
EndFunction

&AtServer
Procedure SetVisibility()
	
	ChangeVisibility(Items.ClosingDateSetting, True);
	If Parameters.DataImportRestrictionDates Then
		If SetPeriodEndClosingDate = "ForAllUsers" Then
			ExtendedTooltip = NStr("ru = 'Даты запрета загрузки данных из других программ действуют одинаково для всех пользователей.'; en = 'Data import restriction dates from other applications are applied the same way for all users.'; pl = 'Daty zakazu pobierania danych od innych programów są takie same dla wszystkich użytkowników.';de = 'Daten, die das Herunterladen von Daten aus anderen Programmen verbieten, sind für alle Benutzer gleich.';ro = 'Datele de interdicție a importului de date din alte programe funcționează la fel pentru toți utilizatorii.';tr = 'Diğer programlardan veri indirmeyi yasaklayan tarihler tüm kullanıcılar için aynı şekilde çalışır.'; es_ES = 'La fecha de restricción de descargar los datos de otros programas funcionan del mismo modo para todos los usuarios.'");
		Else
			ExtendedTooltip = NStr("ru = 'Персональная настройка дат запрета загрузки данных прошлых периодов из других программ для выбранных пользователей.'; en = 'Custom setup of data import restriction dates of previous periods from other applications for selected users.'; pl = 'Personalne ustawienia dat zakazu pobierania danych z poprzednich okresów z innych programów dla wybranych użytkowników.';de = 'Personalisieren Sie das Datum des Verbots des Herunterladens von Daten früherer Zeiträume aus anderen Programmen für ausgewählte Benutzer.';ro = 'Setarea personală a datelor de interdicție a importului de date din perioadele precedente din alte programe pentru utilizatorii selectați.';tr = 'Seçilen kullanıcılar için diğer programlardan geçmiş dönemlerin verilerini indirmeyi yasaklayan tarihlerin kişisel olarak yapılandırılması.'; es_ES = 'El ajuste personal de las fechas de restricción de descargar los datos de los períodos anteriores de otros programas para los usuarios seleccionados.'");
		EndIf;
	Else
		If SetPeriodEndClosingDate = "ForAllUsers" Then
			ExtendedTooltip = NStr("ru = 'Даты запрета ввода и редактирования данных прошлых периодов действуют одинаково для всех пользователей.'; en = 'Dates of restriction of entering and editing previous period data are applied the same way for all users.'; pl = 'Daty zakazu wprowadzania i edycji danych z poprzednich okresów są takie same dla wszystkich użytkowników.';de = 'Die Termine für das Verbot der Eingabe und Bearbeitung von Daten früherer Zeiträume sind für alle Benutzer gleich.';ro = 'Datele de interdicție a introducerii și editării datelor din perioadele precedente funcționează la fel pentru toți utilizatorii.';tr = 'Geçmiş dönemlerin veri girişini ve düzenlenmesini yasaklayan tarihler tüm kullanıcılar için aynı şekilde çalışır.'; es_ES = 'La fecha de restricción de introducción y edición de los datos de los períodos anteriores funcionan del mismo modo para todos los usuarios.'");
		Else
			ExtendedTooltip = NStr("ru = 'Персональная настройка дат запрета ввода и редактирования данных прошлых периодов для выбранных пользователей.'; en = 'Custom setup of period-end closing dates of previous periods for the selected users.'; pl = 'Personalne ustawienia dat wprowadzania i edycji danych z poprzednich okresów dla wybranych użytkowników.';de = 'Persönliche Einstellung von Verbotsdaten der Eingabe und Bearbeitung von Daten früherer Zeiträume für ausgewählte Benutzer.';ro = 'Setarea personală a datelor de interdicție a introducerii și editării datelor din perioadele precedente pentru utilizatorii selectați.';tr = 'Seçilen kullanıcılar için geçmiş dönemlerin veri girişini ve düzenlemesini yasaklayan tarihleri kişisel olarak yapılandırılması.'; es_ES = 'El ajuste personal de las fechas de restricción de introducción y edición de los datos de los períodos anteriores para los usuarios seleccionados.'");
		EndIf;
	EndIf;
	Items.SetClosingDateNote.Title = ExtendedTooltip;
	
	If SetPeriodEndClosingDate <> "ForAllUsers" Then
		ChangeVisibility(Items.SpecifedUsersList, True);
		Items.CurrentUserPresentation.ShowTitle = True;
	Else
		ChangeVisibility(Items.SpecifedUsersList, False);
		Items.CurrentUserPresentation.ShowTitle = False;
	EndIf;
	
	If SetPeriodEndClosingDate <> "ForUsers" Then
		Items.UserData.CurrentPage = Items.UserSelectedPage;
	EndIf;
	
EndProcedure

&AtServer
Procedure ChangeVisibility(Item, Visibility)
	
	If Item.Visible <> Visibility Then
		Item.Visible = Visibility;
	EndIf;
	
EndProcedure

&AtServer
Procedure ChangeSettingOfPeriodEndClosingDate(Val SelectedValue, Val DeleteExtra)
	
	If DeleteExtra Then
		
		BeginTransaction();
		Try
			Query = New Query;
			Query.SetParameter("DataImportRestrictionDates",
				Parameters.DataImportRestrictionDates);
			
			If SelectedValue = "ForAllUsers" Then
				Query.SetParameter("KeepForAllUsers", True);
			Else
				Query.SetParameter("DataImportRestrictionDates", Undefined);
			EndIf;
			
			Query.Text =
			"SELECT
			|	PeriodClosingDates.Section,
			|	PeriodClosingDates.Object,
			|	PeriodClosingDates.User
			|FROM
			|	InformationRegister.PeriodClosingDates AS PeriodClosingDates
			|WHERE
			|	(PeriodClosingDates.User = UNDEFINED
			|			OR CASE
			|				WHEN VALUETYPE(PeriodClosingDates.User) = TYPE(Catalog.Users)
			|						OR VALUETYPE(PeriodClosingDates.User) = TYPE(Catalog.UserGroups)
			|						OR VALUETYPE(PeriodClosingDates.User) = TYPE(Catalog.ExternalUsers)
			|						OR VALUETYPE(PeriodClosingDates.User) = TYPE(Catalog.ExternalUsersGroups)
			|						OR PeriodClosingDates.User = VALUE(Enum.PeriodClosingDatesPurposeTypes.ForAllUsers)
			|					THEN &DataImportRestrictionDates = FALSE
			|				ELSE &DataImportRestrictionDates = TRUE
			|			END)
			|	AND CASE
			|			WHEN VALUETYPE(PeriodClosingDates.User) = TYPE(Enum.PeriodClosingDatesPurposeTypes)
			|				THEN &KeepForAllUsers = FALSE
			|			ELSE TRUE
			|		END";
			RecordKeysValues = Query.Execute().Unload();
			
			// Locking records being deleted.
			For Each RecordKeyValues In RecordKeysValues Do
				LockUserRecordAtServer(LocksAddress,
					RecordKeyValues.Section,
					RecordKeyValues.Object,
					RecordKeyValues.User);
			EndDo;
			
			// Deleting locked records.
			For Each RecordKeyValues In RecordKeysValues Do
				DeleteUserRecord(LocksAddress,
					RecordKeyValues.Section,
					RecordKeyValues.Object,
					RecordKeyValues.User);
			EndDo;
			
			CommitTransaction();
		Except
			RollbackTransaction();
			UnlockAllRecordsAtServer(LocksAddress);
			Raise;
		EndTry;
		UnlockAllRecordsAtServer(LocksAddress);
	EndIf;
	
	ReadUsers();
	ErrorText = "";
	ReadUserData(ThisObject, ErrorText);
	If ValueIsFilled(ErrorText) Then
		Common.MessageToUser(ErrorText);
	EndIf;
	
	SetVisibility();
	
EndProcedure

&AtServerNoContext
Function CurrentClosingDateIndicationMethod(Val User, Val SingleSection, Val ValueForAllUsers, Val BegOfDay, Data = Undefined)
	
	BeginTransaction();
	Try
		Query = New Query;
		Query.SetParameter("User",                 User);
		Query.SetParameter("SingleSection",           SingleSection);
		Query.SetParameter("EmptyDate",                   '00010101');
		Query.SetParameter("ValueForAllUsers", ValueForAllUsers);
		Query.Text =
		"SELECT TOP 1
		|	TRUE AS TrueValue
		|FROM
		|	InformationRegister.PeriodClosingDates AS PeriodClosingDates
		|WHERE
		|	NOT(&User <> PeriodClosingDates.User
		|				AND &User <> ""*"")
		|	AND NOT(PeriodClosingDates.Section = VALUE(ChartOfCharacteristicTypes.PeriodClosingDatesSections.EmptyRef)
		|				AND PeriodClosingDates.Object = VALUE(ChartOfCharacteristicTypes.PeriodClosingDatesSections.EmptyRef))
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT TOP 1
		|	TRUE AS TrueValue
		|FROM
		|	InformationRegister.PeriodClosingDates AS PeriodClosingDates
		|WHERE
		|	NOT(&User <> PeriodClosingDates.User
		|				AND &User <> ""*"")
		|	AND PeriodClosingDates.Section <> VALUE(ChartOfCharacteristicTypes.PeriodClosingDatesSections.EmptyRef)
		|	AND PeriodClosingDates.Object <> VALUE(ChartOfCharacteristicTypes.PeriodClosingDatesSections.EmptyRef)
		|	AND PeriodClosingDates.Object <> PeriodClosingDates.Section
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT TOP 1
		|	TRUE AS TrueValue
		|FROM
		|	InformationRegister.PeriodClosingDates AS PeriodClosingDates
		|WHERE
		|	NOT(&User <> PeriodClosingDates.User
		|				AND &User <> ""*"")
		|	AND PeriodClosingDates.Section <> VALUE(ChartOfCharacteristicTypes.PeriodClosingDatesSections.EmptyRef)
		|	AND PeriodClosingDates.Section <> &SingleSection
		|
		|UNION ALL
		|
		|SELECT TOP 1
		|	TRUE
		|FROM
		|	InformationRegister.PeriodClosingDates AS PeriodClosingDates
		|WHERE
		|	NOT(&User <> PeriodClosingDates.User
		|				AND &User <> ""*"")
		|	AND PeriodClosingDates.Section <> VALUE(ChartOfCharacteristicTypes.PeriodClosingDatesSections.EmptyRef)
		|	AND PeriodClosingDates.Section = PeriodClosingDates.Object";
		
		QueryResults = Query.ExecuteBatch();
		
		CurrentClosingDateIndicationMethod = "";
		
		Query.Text =
		"SELECT
		|	PeriodClosingDates.PeriodEndClosingDate,
		|	PeriodClosingDates.PeriodEndClosingDateDetails
		|FROM
		|	InformationRegister.PeriodClosingDates AS PeriodClosingDates
		|WHERE
		|	PeriodClosingDates.User = &User
		|	AND PeriodClosingDates.Section = VALUE(ChartOfCharacteristicTypes.PeriodClosingDatesSections.EmptyRef)
		|	AND PeriodClosingDates.Object = VALUE(ChartOfCharacteristicTypes.PeriodClosingDatesSections.EmptyRef)";
		Selection = Query.Execute().Select();
		SingleDateIsRead = Selection.Next();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	If Data = Undefined Then
		Data = New Structure;
		Data.Insert("PeriodEndClosingDateDetails", "");
		Data.Insert("PeriodEndClosingDate", '00010101');
		Data.Insert("PermissionDaysCount", 0);
		Data.Insert("RecordExists", SingleDateIsRead);
	EndIf;
	
	If SingleDateIsRead Then
		Data.PeriodEndClosingDate = PeriodClosingDatesInternal.PeriodEndClosingDateByDetails(
			Selection.PeriodEndClosingDateDetails, Selection.PeriodEndClosingDate, BegOfDay);
		FillByInternalDetailsOfPeriodEndClosingDate(Data, Selection.PeriodEndClosingDateDetails);
	EndIf;
	
	If QueryResults[0].IsEmpty() Then
		// Absent by objects and sections, when it is blank.
		CurrentClosingDateIndicationMethod = ?(SingleDateIsRead, "SingleDate", "");
		
	ElsIf Not QueryResults[1].IsEmpty() Then
		// Exists by objects, when it is not blank.
		
		If QueryResults[2].IsEmpty()
		   AND ValueIsFilled(SingleSection) Then
			// Only by SingleSection (without section dates), when it is blank.
			CurrentClosingDateIndicationMethod = "ByObjects";
		Else
			CurrentClosingDateIndicationMethod = "BySectionsAndObjects";
		EndIf;
	Else
		CurrentClosingDateIndicationMethod = "BySections";
	EndIf;
	
	Return CurrentClosingDateIndicationMethod;
	
EndFunction

&AtServer
Procedure DeleteExtraOnChangePeriodEndClosingDateIndicationMethod(Val SelectedValue, Val CurrentUser, Val SetPeriodEndClosingDate)
	
	RecordSet = InformationRegisters.PeriodClosingDates.CreateRecordSet();
	RecordSet.Filter.User.Set(CurrentUser);
	RecordSet.Read();
	Index = RecordSet.Count()-1;
	While Index >= 0 Do
		Record = RecordSet[Index];
		If  SelectedValue = "SingleDate" Then
			If Not (  Record.Section = SectionEmptyRef
					 AND Record.Object = SectionEmptyRef ) Then
				RecordSet.Delete(Record);
			EndIf;
		ElsIf SelectedValue = "BySections" Then
			If Record.Section <> Record.Object
			 Or Record.Section = SectionEmptyRef
			   AND Record.Object = SectionEmptyRef Then
				RecordSet.Delete(Record);
			EndIf;
		ElsIf SelectedValue = "ByObjects" Then
			If Record.Section = Record.Object
			   AND Record.Section <> SectionEmptyRef
			   AND Record.Object <> SectionEmptyRef Then
				RecordSet.Delete(Record);
			EndIf;
		EndIf;
		Index = Index-1;
	EndDo;
	RecordSet.Write();
	
	ErrorText = "";
	ReadUserData(ThisObject, ErrorText);
	If ValueIsFilled(ErrorText) Then
		Common.MessageToUser(ErrorText);
	EndIf;
	
EndProcedure

&AtClient
Procedure EditPeriodEndClosingDateInForm()
	
	SelectedRows = Items.ClosingDates.SelectedRows;
	// Canceling selection of section rows with objects.
	Index = SelectedRows.Count()-1;
	UpdateSelection = False;
	While Index >= 0 Do
		Row = ClosingDates.FindByID(SelectedRows[Index]);
		If Not ValueIsFilled(Row.Presentation) Then
			SelectedRows.Delete(Index);
			UpdateSelection = True;
		EndIf;
		Index = Index - 1;
	EndDo;
	
	If SelectedRows.Count() = 0 Then
		ShowMessageBox(, NStr("ru ='Выделенные строки не заполнены.'; en = 'The selected lines are not filled in.'; pl = 'Zaznaczone wiersze nie są wypełnione.';de = 'Die ausgewählten Zeilen sind nicht ausgefüllt.';ro = 'Liniile selectate nu sunt completate.';tr = 'Seçilen satırlar doldurulmadı.'; es_ES = 'Las líneas seleccionadas no están rellenadas.'"));
		Return;
	EndIf;
	
	If UpdateSelection Then
		Items.ClosingDates.Refresh();
		ShowMessageBox(
			New NotifyDescription("EditPeriodEndClosingDateInFormCompletion", ThisObject, SelectedRows),
			NStr("ru = 'Снято выделение с незаполненных строк.'; en = 'Unfilled lines are unchecked.'; pl = 'Zaznaczenie niewypełnionych wierszy zostało usunięte.';de = 'Unausgefüllte Zeilen sind nicht markiert.';ro = 'De pe rândurile necompletate este scoasă selecția.';tr = 'Doldurulmamış satırlar işaretlenmemiş.'; es_ES = 'Filas no rellenadas están sin revisar.'"));
	Else
		EditPeriodEndClosingDateInFormCompletion(SelectedRows)
	EndIf;
	
EndProcedure

&AtClient
Procedure EditPeriodEndClosingDateInFormCompletion(SelectedRows) Export
	
	// Locking records of the selected rows.
	For Each SelectedRow In SelectedRows Do
		CurrentData = ClosingDates.FindByID(SelectedRow);
		
		ReadProperties = LockUserRecordAtServer(LocksAddress,
			CurrentSection(CurrentData), CurrentData.Object, CurrentUser);
		
		UpdateReadPropertiesValues(
			CurrentData, ReadProperties, Items.Users.CurrentData);
	EndDo;
	
	// Changing description of a period-end closing date.
	FormParameters = New Structure;
	FormParameters.Insert("UserPresentation", "");
	FormParameters.Insert("SectionPresentation", "");
	FormParameters.Insert("Object", "");
	If SetPeriodEndClosingDate = "ForUsers" Then
		FormParameters.UserPresentation = Items.Users.CurrentData.Presentation;
	Else
		FormParameters.UserPresentation = PresentationTextForAllUsers(ThisObject);
	EndIf;
	
	CurrentData = Items.ClosingDates.CurrentData;
	FormParameters.Insert("PeriodEndClosingDateDetails", CurrentData.PeriodEndClosingDateDetails);
	FormParameters.Insert("PermissionDaysCount", CurrentData.PermissionDaysCount);
	FormParameters.Insert("PeriodEndClosingDate", CurrentData.PeriodEndClosingDate);
	FormParameters.Insert("NoClosingDatePresentation", NoClosingDatePresentation(CurrentData));
	
	If SelectedRows.Count() = 1 Then
		If CurrentData.IsSection Then
			FormParameters.SectionPresentation = CurrentData.Presentation;
		Else
			FormParameters.Object = CurrentData.Object;
			If PeriodEndClosingDateSettingMethod <> "ByObjects" Then
				FormParameters.SectionPresentation = CurrentData.GetParent().Presentation;
			EndIf;	
		EndIf;
	Else
		FormParameters.Object = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Выбранные строки (%1)'; en = 'Selected lines (%1)'; pl = 'Wybrane wierszy (%1)';de = 'Ausgewählte Zeilen (%1)';ro = 'Rândurile selectate (%1)';tr = 'Seçilmiş satırlar (%1)'; es_ES = 'Líneas seleccionadas (%1)'"), SelectedRows.Count());
	EndIf;
	
	OpenForm("InformationRegister.PeriodClosingDates.Form.PeriodEndClosingDateEdit",
		FormParameters, ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetFieldsToCalculate(Val Data)
	
	For each DataString In Data Do
		SetClosingDateDetailsPresentation(DataString);
		For each DataString In DataString.GetItems() Do
			SetClosingDateDetailsPresentation(DataString);
		EndDo;	
	EndDo;	
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetClosingDateDetailsPresentation(Val Data)
	
	// Presentation of the period-end closing date value that is not set.
	If Not ValueIsFilled(Data.PeriodEndClosingDate) Then
		Data.PeriodEndClosingDateDetailsPresentation = NoClosingDatePresentation(Data);
		If Not IsBlankString(Data.PeriodEndClosingDateDetailsPresentation) Then
			Return;
		EndIf;	
	EndIf;
	
	Presentation = PeriodClosingDatesInternalClientServer.ClosingDatesDetails()[Data.PeriodEndClosingDateDetails];
	If Data.PermissionDaysCount > 0 Then
		Presentation = Presentation + " (" + Format(Data.PermissionDaysCount, "NG=") + ")";
	EndIf;
	Data.PeriodEndClosingDateDetailsPresentation = Presentation;
	
EndProcedure

&AtClientAtServerNoContext
Function NoClosingDatePresentation(Data)
	
	If Data.IsSection AND Not Data.Section.IsEmpty() Then
		Return NStr("ru = 'Общая дата для всех разделов'; en = 'Single date for all sections'; pl = 'Łączna data dla wszystkich działów';de = 'Gesamtdatum für alle Abschnitte';ro = 'Data comună pentru toate compartimentele';tr = 'Tüm bölümler için ortak veri'; es_ES = 'Fecha común para todas las secciones'");
	ElsIf Not Data.IsSection Then	
		SectionData = Data.GetParent();
		If SectionData = Undefined Then
			Return "";
		ElsIf Not ValueIsFilled(SectionData.PeriodEndClosingDate) Then
			Return StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Общая дата для раздела ""%1""'; en = 'Single date for section %1'; pl = 'Łączna data dla działu ""%1""';de = 'Gesamtdatum für alle Abschnitte ""%1""';ro = 'Data comună pentru compartimentul ""%1""';tr = 'Bölüm için genel tarih ""%1""'; es_ES = 'Fecha común para el apartado ""%1""'"), SectionData.Presentation);
		Else	
			Return SectionData.PeriodEndClosingDateDetailsPresentation + " (" + SectionData.Presentation + ")";
		EndIf;
	EndIf;
	Return ""; 
		
EndFunction	

&AtClientAtServerNoContext
Function InternalPeriodEndClosingDate(Data)
	
	If ValueIsFilled(Data.PeriodEndClosingDateDetails)
	   AND Data.PeriodEndClosingDateDetails <> "Custom" Then
		
		Return '00020202'; // The relative period-end closing date.
	EndIf;
	
	Return Data.PeriodEndClosingDate;
	
EndFunction

&AtClientAtServerNoContext
Function InternalDetailsOfPeriodEndClosingDate(Val Data)
	
	InternalDetails = "";
	If Data.PeriodEndClosingDateDetails <> "Custom" Then
		InternalDetails = TrimAll(
			Data.PeriodEndClosingDateDetails + Chars.LF
				+ Format(Data.PermissionDaysCount, "NG=0"));
	EndIf;
	
	Return InternalDetails;
	
EndFunction

&AtClientAtServerNoContext
Procedure FillByInternalDetailsOfPeriodEndClosingDate(Val Data, Val InternalDetails)
	
	Data.PeriodEndClosingDateDetails = "Custom";
	Data.PermissionDaysCount = 0;
	
	If ValueIsFilled(InternalDetails) Then
		PeriodEndClosingDateDetails = StrGetLine(InternalDetails, 1);
		PermissionDaysCount = StrGetLine(InternalDetails, 2);
		If PeriodClosingDatesInternalClientServer.ClosingDatesDetails()[PeriodEndClosingDateDetails] = Undefined Then
			Data.PeriodEndClosingDate = '00030303'; // Unknown format.
		Else
			Data.PeriodEndClosingDateDetails = PeriodEndClosingDateDetails;
			If ValueIsFilled(PermissionDaysCount) Then
				TypeDescriptionNumber = New TypeDescription("Number",,,
					New NumberQualifiers(2, 0, AllowedSign.Nonnegative));
				Data.PermissionDaysCount = TypeDescriptionNumber.AdjustValue(PermissionDaysCount);
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function IsAllUsers(User)
	
	Return TypeOf(User) = Type("EnumRef.PeriodClosingDatesPurposeTypes");
	
EndFunction

&AtClientAtServerNoContext
Function PeriodEndClosingDateSet(Data, User, BeforeWrite = False)
	
	If Not BeforeWrite Then
		Return Data.RecordExists;
	EndIf;
	
	If Data.Object <> Data.Section AND Not ValueIsFilled(Data.Object) Then
		Return False;
	EndIf;
	
	Return Data.PeriodEndClosingDateDetails <> "";
	
EndFunction

&AtServerNoContext
Procedure LockAndWriteBlankDates(LocksAddress, Section, Object, User, Comment)
	
	If TypeOf(Object) = Type("Array") Then
		ObjectsForAdding = Object;
	Else
		ObjectsForAdding = New Array;
		ObjectsForAdding.Add(Object);
	EndIf;
	
	For Each CurrentObject In ObjectsForAdding Do
		LockUserRecordAtServer(LocksAddress,
			Section, CurrentObject, User);
	EndDo;
	
	For Each CurrentObject In ObjectsForAdding Do
		RecordPeriodEndClosingDateWithDetails(
			Section,
			CurrentObject,
			User,
			'00010101',
			"",
			Comment);
	EndDo;
	
	UnlockAllRecordsAtServer(LocksAddress);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetCommandBarOfClosingDates(Form)
	
	Items = Form.Items;
	
	If IsAllUsers(Form.CurrentUser) Then
		If Form.PeriodEndClosingDateSettingMethod = "BySections" Then
			// ClosingDatesWithoutSectionsSelectionWithoutObjectsSelection
			SetProperty(Items.ClosingDatesPick.Visible, False);
			SetProperty(Items.ClosingDatesAdd.Visible,  False);
			SetProperty(Items.PeriodEndClosingDatesContextMenuAdd.Visible, False);
		Else
			// ClosingDatesWithoutSectionsSelectionWithObjectsSelection
			SetProperty(Items.ClosingDatesPick.Visible, True);
			SetProperty(Items.ClosingDatesAdd.Visible,  True);
			SetProperty(Items.PeriodEndClosingDatesContextMenuAdd.Visible, True);
		EndIf;
	Else
		If Form.PeriodEndClosingDateSettingMethod = "BySections" Then
			// ClosingDatesWithSectionsSelectionWithoutObjectsSelection
			SetProperty(Items.ClosingDatesPick.Visible, False);
			SetProperty(Items.ClosingDatesAdd.Visible,  False);
			SetProperty(Items.PeriodEndClosingDatesContextMenuAdd.Visible, False);
			
		ElsIf Form.PeriodEndClosingDateSettingMethod = "ByObjects" Then
			// ClosingDatesWithCommonDateSelectionWithObjectsSelection
			SetProperty(Items.ClosingDatesPick.Visible, True);
			SetProperty(Items.ClosingDatesAdd.Visible,  True);
			SetProperty(Items.PeriodEndClosingDatesContextMenuAdd.Visible, True);
		Else
			// ClosingDatesWithSectionsSelectionWithObjectsSelection
			SetProperty(Items.ClosingDatesPick.Visible, True);
			SetProperty(Items.ClosingDatesAdd.Visible,  True);
			SetProperty(Items.PeriodEndClosingDatesContextMenuAdd.Visible, True);
		EndIf;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetProperty(Property, Value)
	If Property <> Value Then
		Property = Value;
	EndIf;
EndProcedure

&AtClientAtServerNoContext
Function CurrentUserComment(Form)
	
	If Form.SetPeriodEndClosingDate = "ForUsers" Then
		Return Form.Items.Users.CurrentData.Comment;
	EndIf;
	
	Return "";
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Auxiliary functions of user interface lines.

&AtClientAtServerNoContext
Function PresentationTextForAllUsers(Form)
	
	Return "<" + Form.ValueForAllUsers + ">";
	
EndFunction

&AtClientAtServerNoContext
Function UserPresentationText(Form, User)
	
	If Form.Parameters.DataImportRestrictionDates Then
		For Each ListValue In Form.UserTypesList Do
			If TypeOf(ListValue.Value) = TypeOf(User) Then
				If ValueIsFilled(User) Then
					Return ListValue.Presentation + ": " + String(User);
				Else
					Return ListValue.Presentation + ": " + NStr("ru = '<Все информационные базы>'; en = '<All infobases>'; pl = '<Wszystkie bazy informacyjne>';de = '<Alle Infobases>';ro = '<Toate bazele de date> ';tr = '<Tüm bilgi tabanları>'; es_ES = '<Todas infobases>'");
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	If ValueIsFilled(User) Then
		Return String(User);
	EndIf;
	
	Return String(TypeOf(User));
	
EndFunction

&AtClientAtServerNoContext
Function CommonDatePresentationText()
	
	Return "<" + NStr("ru = 'Общая дата для всех разделов'; en = 'Single date for all sections'; pl = 'Łączna data dla wszystkich działów';de = 'Gesamtdatum für alle Abschnitte';ro = 'Data comună pentru toate compartimentele';tr = 'Tüm bölümler için ortak veri'; es_ES = 'Fecha común para todas las secciones'") + ">";
	
EndFunction

&AtClientAtServerNoContext
Function MessageTextExcessSetting(IndicationMethodInForm, IndicationMethodInDatabase, CurrentUser, Form)
	
	If IndicationMethodInForm = "BySections" Or IndicationMethodInForm = "BySectionsAndObjects" Then
		If IsAllUsers(CurrentUser) Then
			Return StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Ни для одного раздела не были введены даты запрета, 
					|поэтому для всех пользователей будет действовать более простая настройка ""%1"".'; 
					|en = 'No sections have effective period-end closing dates.
					|A general setting %1 will be applied to all users.'; 
					|pl = 'Do żadnej sekcji nie zostały wprowadzone daty zakazu, 
					|więc dla wszystkich użytkowników będzie działać bardziej proste ustawienie ""%1"".';
					|de = 'Für keinen der Abschnitte wurden Verbotsdaten eingegeben,
					|so dass alle Benutzer eine einfachere Einstellung ""%1"" haben.';
					|ro = 'Pentru nici un compartiment nu au fost introduse datele de interdicție, 
					|de aceea pentru toți utilizatorii va funcționa setarea simplă ""%1"".';
					|tr = 'Hiçbir bölüm için yasaklanma tarihleri girilmedi, %1bu nedenle tüm kullanıcılar için daha kolay bir "
" ayarı geçerli olacaktır.'; 
					|es_ES = 'No están introducidas las fechas de restricción para ninguna sección, 
					|por eso para todos los usuarios funcionará el ajuste más simple ""%1"".'"),
				IndicationMethodInDatabase);
		Else
			Return StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Ни для одного раздела не были введены даты запрета, 
					|поэтому для ""%1"" будет действовать более простая настройка ""%2"".'; 
					|en = 'No sections have effective period-end closing dates.
					|A general setting %1 will be applied to %2.'; 
					|pl = 'Do żadnej sekcji nie zostały wprowadzone daty zakazu, 
					|więc dla ""%1"" będzie działać bardziej proste ustawienie ""%2"".';
					|de = 'Für keinen der Abschnitte wurden Verbotsdaten eingegeben, 
					|so dass der ""%1"" eine einfachere Einstellung für ""%2"" hat.';
					|ro = 'Pentru nici un compartiment nu au fost introduse datele de interdicție, 
					|de aceea pentru ""%1"" va funcționa setarea simplă ""%2"".';
					|tr = 'Hiçbir bölüm için yasaklanma tarihleri girilmedi, %1bu nedenle ""%2"" için daha kolay bir "
" ayarı geçerli olacaktır.'; 
					|es_ES = 'No están introducidas las fechas de restricción para ninguna sección, 
					|por eso para ""%1"" funcionará el ajuste más simple ""%2"".'"),
				CurrentUser, IndicationMethodInDatabase);
		EndIf;
	Else // ByObjects
		If IsAllUsers(CurrentUser) Then
			Return StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Ни для одного объекта не были введены даты запрета, 
					|поэтому для всех пользователей будет действовать более простая настройка ""%1"".'; 
					|en = 'No objects have effective period-end closing dates.
					|A general setting %1 will be applied to all users.'; 
					|pl = 'Do żadnego obiektu nie zostały wprowadzone daty zakazu, 
					|więc dla wszystkich użytkowników będzie działać bardziej proste ustawienie ""%1"".';
					|de = 'Es wurden keine Verbotsdaten für ein Objekt eingegeben, 
					|so dass alle Benutzer eine einfachere Einstellung ""%1"" haben.';
					|ro = 'Pentru nici un obiect nu au fost introduse datele de interdicție, 
					|de aceea pentru toți utilizatorii va funcționa setarea simplă ""%1"".';
					|tr = 'Hiçbir nesne için yasaklanma tarihleri girilmedi, %1bu nedenle tüm kullanıcılar için daha kolay bir "
" ayarı geçerli olacaktır.'; 
					|es_ES = 'No están introducidas las fechas de restricción para ningún objeto, 
					|por eso para todos los usuarios funcionará el ajuste más simple ""%1"".'"),
				IndicationMethodInDatabase);
		Else
			Return StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Ни для одного объекта не были введены даты запрета, 
					|поэтому для ""%1"" будет действовать более простая настройка ""%2"".'; 
					|en = 'No objects have effective period-end closing dates.
					|A general setting %1 will be applied to %2.'; 
					|pl = 'Do żadnej obiektu nie zostały wprowadzone daty zakazu, 
					|więc dla ""%1"" będzie działać bardziej proste ustawienie ""%2"".';
					|de = 'Es wurden keine Verbotsdaten für ein Objekt eingegeben, 
					|so dass eine einfachere Einstellung von ""%2"" für ""%1"" funktioniert.';
					|ro = 'Pentru nici un obiect nu au fost introduse datele de interdicție, 
					|de aceea pentru ""%1"" va funcționa setarea simplă ""%2"".';
					|tr = 'Hiçbir nesne için yasaklanma tarihleri girilmedi, %1bu nedenle ""%2"" için daha kolay bir "
" ayarı geçerli olacaktır.'; 
					|es_ES = 'No están introducidas las fechas de restricción para ningún objeto, 
					|por eso para ""%1"" funcionará el ajuste más simple ""%2"".'"),
				CurrentUser, IndicationMethodInDatabase);
		EndIf;
	EndIf;
	
EndFunction

&AtClient
Function MessageTextInSelectedSectionClosingDatesForObjectsNotSet(Section)
	
	Return ?(Section <> SectionEmptyRef, 
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'В разделе ""%1"" не предусмотрена установка дат запрета для отдельных объектов.'; en = 'Period-end closing date setting is not available for separate objects in the ""%1"" section.'; pl = 'W sekcji ""%1"" nie jest przewidziane ustawienie dat zakazu dla poszczególnych obiektów.';de = 'Der Abschnitt ""%1"" enthält nicht die Einstellung von Verbotsdaten für einzelne Objekte.';ro = 'În compartimentul ""%1"" nu este prevăzută stabilirea datelor de interdicție pentru obiecte separate.';tr = '""%1"" bölümünde ayrı nesneler için yasaklama tarihleri öngörülmemiştir.'; es_ES = 'En la sección ""%1"" no está prevista la instalación de las fechas de restricción para algunos objetos.'"), Section),
		NStr("ru = 'Для установки дат запрета по отдельным объектам выберите один из разделов ниже и нажмите ""Подобрать"".'; en = 'To set a period-end closing date for some objects, choose one of the sections below, and then click Select.'; pl = 'W celu ustawienia dat zakazu wg obiektów pojedynczych wybierz jedną z sekcji niżej i kliknij ""Dopasuj"".';de = 'Um die Verbotsdaten für einzelne Objekte festzulegen, wählen Sie einen der folgenden Abschnitte aus und klicken Sie auf ""Anpassen"".';ro = 'Pentru stabilirea datelor de interdicție pentru obiecte separate selectați unul din compartimente mai jos și tastați ""Selectare"".';tr = 'Yasak tarihlerini tek tek nesnelere ayarlamak için aşağıdaki bölümlerden birini seçin ve ""Seç"" ''i tıklayın.'; es_ES = 'Para instalar las fechas de restricción por unos objetos seleccione una de las secciones abajo y pulse ""Escoger"".'"));
	
EndFunction

&AtClientAtServerNoContext
Function HeaderTextDataTypeSelection()
	
	Return NStr("ru = 'Выбор типа данных'; en = 'Select data type'; pl = 'Wybierz typ danych';de = 'Wählen Sie den Datentyp aus';ro = 'Select data type';tr = 'Veri türünü seçin'; es_ES = 'Seleccionar el tipo de datos'");
	
EndFunction

#EndRegion
