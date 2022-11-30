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
	
	ReadOnly = True;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure EnableEditing(Command)
	
	ReadOnly = False;
	
EndProcedure

&AtClient
Procedure UpdateRegisterData(Command)
	
	HasChanges = False;
	
	UpdateRegisterDataAtServer(HasChanges);
	
	If HasChanges Then
		Text = NStr("ru = 'Обновление выполнено успешно.'; en = 'The update is completed.'; pl = 'Aktualizacja zakończona pomyślnie.';de = 'Das Update war erfolgreich.';ro = 'Actualizarea este executată cu succes.';tr = 'Güncelleme başarılı.'; es_ES = 'Actualización se ha realizado con éxito.'");
	Else
		Text = NStr("ru = 'Обновление не требуется.'; en = 'The update is not required.'; pl = 'Aktualizacja nie jest wymagana.';de = 'Update ist nicht erforderlich.';ro = 'Actualizarea nu este necesară.';tr = 'Güncelleme gerekmiyor.'; es_ES = 'No se requiere una actualización.'");
	EndIf;
	
	ShowMessageBox(, Text);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	List.SettingsComposer.Settings.ConditionalAppearance.Items.Clear();
	
	ApplyDataGroupAppearance(0, NStr("ru = 'Стандартные значения доступа'; en = 'Standard access values'; pl = 'Domyślne wartości dostępu';de = 'Standardzugriffswerte';ro = 'Valorile de acces standard';tr = 'Varsayılan erişim değerleri'; es_ES = 'Valores de acceso por defecto'"));
	ApplyDataGroupAppearance(1, NStr("ru = 'Обычные/внешние пользователи'; en = 'Regular or external users'; pl = 'Zwykli/zewnętrzni użytkownicy';de = 'Standard / externe Benutzer';ro = 'Utilizatori standard / externi';tr = 'Standart/dış kullanıcılar'; es_ES = 'Usuarios estándar/externos'"));
	ApplyDataGroupAppearance(2, NStr("ru = 'Обычные/внешние группы пользователей'; en = 'Regular or external user groups'; pl = 'Grupy zwykli/zewnętrzni użytkownicy';de = 'Standard / externe Benutzergruppe';ro = 'Grupuri utilizator standard/extern';tr = 'Standart/dış kullanıcı grupları'; es_ES = 'Grupos de usuarios estándar/externos'"));
	ApplyDataGroupAppearance(3, NStr("ru = 'Группы исполнителей'; en = 'Assignee groups'; pl = 'Grupy wykonawców';de = 'Performer Gruppen';ro = 'Grupuri executant';tr = 'Icracı gruplar'; es_ES = 'Grupos de ejecutores'"));
	ApplyDataGroupAppearance(4, NStr("ru = 'Объекты авторизации'; en = 'Authorization objects'; pl = 'Obiekty autoryzacji';de = 'Berechtigungsobjekte';ro = 'Obiecte de autorizare';tr = 'Doğrulama nesneleri'; es_ES = 'Objetos de autorización'"));
	
EndProcedure

&AtServer
Procedure ApplyDataGroupAppearance(DataGroup, Text)
	
	AppearanceItem = List.SettingsComposer.Settings.ConditionalAppearance.Items.Add();
	AppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	FieldItem = AppearanceItem.Fields.Items.Add();
	FieldItem.Field = New DataCompositionField("DataGroup");
	
	FilterItem = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem.LeftValue = New DataCompositionField("DataGroup");
	FilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	FilterItem.RightValue = DataGroup;
	
	AppearanceItem.Appearance.SetParameterValue("Text", Text);
	
EndProcedure

&AtServer
Procedure UpdateRegisterDataAtServer(HasChanges)
	
	SetPrivilegedMode(True);
	
	InformationRegisters.AccessValuesGroups.UpdateRegisterData(HasChanges);
	
	Items.List.Refresh();
	
EndProcedure

#EndRegion
