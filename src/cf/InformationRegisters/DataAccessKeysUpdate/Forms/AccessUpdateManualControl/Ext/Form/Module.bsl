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
	
	UpdateDataItemsAccessKeys = True;
	UpdateAccessKeysRights = True;
	DeleteObsoleteInternalData = True;
	
	If Not StandardSubsystemsServer.ApplicationVersionUpdatedDynamically() Then
		ListsWithRestriction = AccessManagementInternalCached.ListsWithRestriction();
	Else
		ListsWithRestriction = AccessManagementInternal.ActiveAccessRestrictionParameters(Undefined,
			Undefined, False);
	EndIf;
	
	Lists = New Array;
	Lists.Add("Catalog.SetsOfAccessGroups");
	For Each ListDetails In ListsWithRestriction Do
		FullName = ListDetails.Key;
		Lists.Add(FullName);
		If Not AccessManagementInternal.IsReferenceTableType(FullName) Then
			Continue;
		EndIf;
		EmptyRef = PredefinedValue(FullName + ".EmptyRef");
		AccessUpdateObjectsTypes.Add(EmptyRef, String(TypeOf(EmptyRef)));
		AccessUpdateObjectsTypesTablesNames.Add(EmptyRef, FullName);
	EndDo;
	AccessUpdateObjectsTypes.SortByPresentation();
	
	IDs = Common.MetadataObjectIDs(Lists);
	
	For Each IDDetails In IDs Do
		ListsToUpdate.Add(IDDetails.Value,
			String(IDDetails.Value), True);
	EndDo;
	
	ListsToUpdate.SortByPresentation();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AccessUpdateObjectStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentTypeItem = AccessUpdateObjectsTypes.FindByValue(
		SelectedAccessUpdateObjectType);
	
	If CurrentTypeItem = Undefined Then
		CurrentTypeItem = AccessUpdateObjectsTypes[0];
	EndIf;
	
	AccessUpdateObjectsTypes.ShowChooseItem(
		New NotifyDescription("BeginSelectUpdateObjectFollowUp", ThisObject),
		NStr("ru = 'Выбор типа данных'; en = 'Select data type'; pl = 'Wybierz typ danych';de = 'Wählen Sie den Datentyp aus';ro = 'Select data type';tr = 'Veri türünü seçin'; es_ES = 'Seleccionar el tipo de datos'"),
		CurrentTypeItem);
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure ShowAccessToObject(Command)
	
	If Not ValueIsFilled(AccessUpdateObject) Then
		ShowMessageBox(, NStr("ru = 'Выберите объект.'; en = 'Select an object.'; pl = 'Wybierz obiekt.';de = 'Wählen Sie ein Objekt aus.';ro = 'Selectați obiectul.';tr = 'Nesneyi seçin.'; es_ES = 'Seleccionar el objeto.'"));
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateAccessToObject(Command)
	
	ShowMessageBox(, UpdateAccessToObjectAtServer());
	
EndProcedure

&AtClient
Procedure ScheduleListsAccessUpdate(Command)
	
	If Not UpdateDataItemsAccessKeys
	   AND Not UpdateAccessKeysRights
	   AND Not DeleteObsoleteInternalData Then
	
		ShowMessageBox(, NStr("ru = 'Выберите хотя бы один вид обновления.'; en = 'Select at least one update kind.'; pl = 'Wybierz co najmniej jeden typ aktualizacji.';de = 'Wählen Sie mindestens eine Art von Aktualisierung aus.';ro = 'Selectați cel puțin un tip de actualizare.';tr = 'En az bir güncelleme türü seçin.'; es_ES = 'Seleccione aunque sea un tipo de actualización.'"));
		Return;
	EndIf;
	
	If Not ScheduleListsAccessUpdateAtServer() Then
		ShowMessageBox(, NStr("ru = 'Выберите хотя бы один список.'; en = 'Select at least one list.'; pl = 'Wybierz co najmniej jedną listę.';de = 'Wählen Sie mindestens eine Liste aus.';ro = 'Selectați cel puțin o listă.';tr = 'Lütfen en az bir liste seçin.'; es_ES = 'Seleccione aunque sea una lista.'"));
		Return;
	EndIf;
	
	Notify("Write_UpdateDataAccessKeys", New Structure, Undefined);
	Notify("Write_UpdateUserAccessKeys", New Structure, Undefined);
	
	ShowUserNotification(NStr("ru = 'Обновление запланировано.'; en = 'Update has been scheduled.'; pl = 'Aktualizacja jest zaplanowana.';de = 'Eine Aktualisierung ist geplant.';ro = 'Actualizarea este planificată.';tr = 'Yükseltme planlandı.'; es_ES = 'Actualización planificada.'"));
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function UpdateAccessToObjectAtServer()
	
	If Not ValueIsFilled(AccessUpdateObject) Then
		Return NStr("ru = 'Выберите объект.'; en = 'Select an object.'; pl = 'Wybierz obiekt.';de = 'Wählen Sie ein Objekt aus.';ro = 'Selectați obiectul.';tr = 'Nesneyi seçin.'; es_ES = 'Seleccionar el objeto.'");
	EndIf;
	
	AccessManagementInternal.ClearAccessGroupsValuesCacheToCalculateRights();
	
	FullName = AccessUpdateObject.Metadata().FullName();
	TransactionID = New UUID;
	
	Text = "";
	
	UpdateAccessToObjectForUsersKind(AccessUpdateObject,
		FullName, TransactionID, False, Text);
	
	UpdateAccessToObjectForUsersKind(AccessUpdateObject,
		FullName, TransactionID, True, Text);
	
	Return Text;
	
EndFunction

&AtServer
Procedure UpdateAccessToObjectForUsersKind(ObjectRef, FullName, TransactionID, ForExternalUsers, Text)
	
	RestrictionParameters = AccessManagementInternal.RestrictionParameters(FullName,
		TransactionID, ForExternalUsers);
	
	Text = Text + ?(Text = "", "", Chars.LF + Chars.LF);
	If ForExternalUsers Then
		If RestrictionParameters.AccessDenied Then
			Text = Text + NStr("ru = 'Для внешних пользователей (доступ запрещен):'; en = 'For external users (access denied):'; pl = 'Dla użytkowników zewnętrznych (odmowa dostępu):';de = 'Für externe Benutzer (Zugriff verweigert):';ro = 'Pentru utilizatori externi (accesul interzis):';tr = 'Harici kullanıcılar için (erişim yasaklandı):'; es_ES = 'Para usuarios externos (acceso prohibido):'");
			
		ElsIf RestrictionParameters.RestrictionDisabled Then
			Text = Text + NStr("ru = 'Для внешних пользователей (ограничение отключено):'; en = 'For external users (restriction disabled):'; pl = 'Dla użytkowników zewnętrznych (ograniczenie wyłączone):';de = 'Für externe Benutzer (Einschränkung deaktiviert):';ro = 'Pentru utilizatori externi (restricția dezactivată):';tr = 'Harici kullanıcılar için (kısıtlama devre dışı bırakıldı):'; es_ES = 'Para usuarios externos (restricción desactivada):'");
		Else
			Text = Text + NStr("ru = 'Для внешних пользователей:'; en = 'For external users:'; pl = 'Dla użytkowników zewnętrznych:';de = 'Für externe Benutzer:';ro = 'Pentru utilizatori externi:';tr = 'Harici kullanıcılar için:'; es_ES = 'Para usuarios externos:'");
		EndIf;
	Else
		If RestrictionParameters.AccessDenied Then
			Text = Text + NStr("ru = 'Для пользователей (доступ запрещен):'; en = 'For users (access denied):'; pl = 'Dla użytkowników (odmowa dostępu):';de = 'Für Benutzer (Zugriff verweigert):';ro = 'Pentru utilizatori (accesul interzis):';tr = 'Kullanıcılar için (erişim yasaklandı):'; es_ES = 'Para usuarios (acceso prohibido):'");
			
		ElsIf RestrictionParameters.RestrictionDisabled Then
			Text = Text + NStr("ru = 'Для пользователей (ограничение отключено):'; en = 'For users (restriction disabled):'; pl = 'Dla użytkowników (ograniczenie wyłączone):';de = 'Für Benutzer (Einschränkung deaktiviert):';ro = 'Pentru utilizatori (restricția dezactivată):';tr = 'Kullanıcılar için (kısıtlama devre dışı bırakıldı):'; es_ES = 'Para usuarios (restricción desactivada):'");
		Else
			Text = Text + NStr("ru = 'Для пользователей:'; en = 'For users:'; pl = 'Dla użytkowników:';de = 'Für Benutzer:';ro = 'Pentru utilizatori:';tr = 'Kullanıcılar için:'; es_ES = 'Para usuarios:'");
		EndIf;
	EndIf;
	
	SourceAccessKeyObsolete = AccessManagementInternal.SourceAccessKeyObsolete(
		ObjectRef, RestrictionParameters);
	
	HasRightsChanges = False;
	
	AccessManagementInternal.UpdateAccessKeysOfDataItemsOnWrite(ObjectRef,
		RestrictionParameters, TransactionID, True, HasRightsChanges);
	
	If RestrictionParameters.DoNotWriteAccessKeys Then
		Text = Text + Chars.LF + NStr("ru = '1. Обновление не требуется. Ключ доступа объекта не используется.'; en = '1. Update is not required. The object access key is not used.'; pl = '1. Aktualizacja nie jest wymagana. Klucz dostępu obiektu nie jest używany.';de = '1. Eine Aktualisierung ist nicht erforderlich. Der Objektzugriffsschlüssel wird nicht verwendet.';ro = '1. Actualizarea nu este necesară. Cheia de acces a obiectului nu se utilizează.';tr = '1. Güncelleme gerekmez. Nesne Erişim Anahtarı kullanılmıyor.'; es_ES = '1. La actualización no se requiere. La clave de acceso del objeto no se usa.'");
		
	ElsIf RestrictionParameters.WriteAlwaysAllowedAccessKey Then
		If SourceAccessKeyObsolete Then
			Text = Text + Chars.LF + NStr("ru = '1. У объекта установлен всегда разрешенный ключ доступа.'; en = '1. The object access key is always allowed.'; pl = '1. Obiekt posiada ustawiony zawsze dozwolony klucz dostępu.';de = '1. Das Objekt hat immer einen gültigen Zugriffsschlüssel installiert.';ro = '1. Pentru obiect este instalată cheia de acces întotdeauna permisă.';tr = '1. Nesnenin her zaman izin verilen bir erişim anahtarı vardır.'; es_ES = '1. Para el objeto ha sido indicada siempre una clave de acceso permitida.'");
		Else
			Text = Text + Chars.LF + NStr("ru = '1. Обновление не требуется. У объекта ключ доступа уже всегда разрешенный.'; en = '1. Update is not required. The object access key is always allowed.'; pl = '1. Aktualizacja nie jest wymagana. Obiekt już posiada ustawiony zawsze dozwolony klucz dostępu.';de = '1. Eine Aktualisierung ist nicht erforderlich. Das Objekt hat einen Zugriffsschlüssel, der immer erlaubt ist.';ro = '1. Actualizarea nu este necesară. Cheia de acces a obiectului deja este întotdeauna permisă.';tr = '1. Güncelleme gerekmez. Nesnenin erişim anahtarına zaten izin verildi.'; es_ES = '1. No se requiere la actualización. La clave del objeto está siempre permitida.'");
		EndIf;
	Else
		If SourceAccessKeyObsolete Then
			Text = Text + Chars.LF + NStr("ru = '1. У объекта обновлен ключ доступа.'; en = '1. The object access key is updated.'; pl = '1. Obiekt ma zaktualizowany klucz dostępu.';de = '1. Das Objekt hat einen aktualisierten Zugriffsschlüssel.';ro = '1. Cheia de acces a obiectului este actualizată.';tr = '1. Nesnenin erişim anahtarı güncellendi.'; es_ES = '1. El objeto tiene una clave de acceso actualizada.'");
		Else
			Text = Text + Chars.LF + NStr("ru = '1. Обновление не требуется. У объекта ключ доступа не устарел.'; en = '1. Update is not required. The object access key is not obsolete.'; pl = '1. Aktualizacja nie jest wymagana. Klucz dostępu do obiektu nie jest nieaktualny.';de = '1. Eine Aktualisierung ist nicht erforderlich. Der Zugriffsschlüssel des Objekts ist nicht veraltet.';ro = '1. Actualizarea nu este necesară. Cheia de acces a obiectului nu este învechită.';tr = '1. Güncelleme gerekmez. Nesnenin erişim anahtarı eskimedi.'; es_ES = '1. No se requiere actualización. La clave de acceso del objeto no se ha caducado.'");
		EndIf;
	EndIf;
	
	If RestrictionParameters.DoNotWriteAccessKeys Then
		Text = Text + Chars.LF + NStr("ru = '2. Обновление не требуется. Ключ доступа объекта не используется.'; en = '2. Update is not required. The object access key is not used.'; pl = '2. Aktualizacja nie jest wymagana. Klucz dostępu obiektu nie jest używany.';de = '2. Eine Aktualisierung ist nicht erforderlich. Der Objektzugriffsschlüssel wird nicht verwendet.';ro = '2. Actualizarea nu este necesară. Cheia de acces a obiectului nu se utilizează.';tr = '2. Güncelleme gerekmez. Nesne Erişim Anahtarı kullanılmıyor.'; es_ES = '2. La actualización no se requiere. La clave de acceso del objeto no se usa.'");
		
	ElsIf RestrictionParameters.WriteAlwaysAllowedAccessKey Then
		If HasRightsChanges Then
			Text = Text + Chars.LF
				+ NStr("ru = '2. У всегда разрешенного ключа доступа обновлен состав
				             |   групп доступа или пользователей или внешних пользователей.'; 
				             |en = '2. 
				             |Access groups, users, or external users of the access key, which is always allowed, have been updated.'; 
				             |pl = '2. Zawsze dozwolony klucz dostępu zaktualizował skład
				             | grup dostępu lub użytkowników lub użytkowników zewnętrznych.';
				             |de = '2. Der immer zulässige Zugriffsschlüssel hat die Zusammensetzung
				             |   der Zugriffsgruppen oder Benutzer oder externen Benutzer aktualisiert.';
				             |ro = '2. La cheia de acces întotdeauna permisă este actualizată componența
				             | grupurilor de acces al utilizatorilor sau al utilizatorilor externi.';
				             |tr = '2. Her zaman izin verilen erişim anahtarının, erişim gruplarının veya kullanıcıların veya harici kullanıcıların 
				             |kapsamı güncel.'; 
				             |es_ES = '2. El contenido de la clave de acceso siempre permitida ha sido actualizado
				             |   el grupo de acceso o de usuarios o de usuarios externos.'");
		Else
			Text = Text + Chars.LF
				+ NStr("ru = '2. Обновление не требуется. У всегда разрешенного ключа доступа
				             |   состав групп доступа, пользователей и внешних пользователей не устарел.'; 
				             |en = '2. Update is not required. Access groups, users, or external users of the access key,
				             | which is always allowed, are not obsolete.'; 
				             |pl = '2. Aktualizacja nie jest wymagana. Zawsze dozwolony klucz dostępu
				             | listy grup dostępu, użytkowników i użytkowników zewnętrznych jest aktualny.';
				             |de = '2. Eine Aktualisierung ist nicht erforderlich. Mit dem immer zulässigen Zugriffsschlüssel
				             |   ist die Zusammensetzung der Zugriffsgruppen, Benutzer und externen Benutzer nicht veraltet.';
				             |ro = '2. Actualizarea nu este necesară. La cheia de acces
				             |  întotdeauna permisă nu este învechită componența grupurilor de acces al utilizatorilor și utilizatorilor externi.';
				             |tr = '2. Güncelleme gerekmez. Her zaman izin 
				             |verilen erişim anahtarın erişim gruplarının, kullanıcıların ve harici kullanıcıların kapsamı eskimedi.'; 
				             |es_ES = '2. La actualización no se requiere. Para la clave siempre permitida
				             |   el contenido de grupos de acceso, de usuarios y usuarios externos no se ha caducado.'");
		EndIf;
		
	ElsIf HasRightsChanges Then
		If RestrictionParameters.HasUsersRestriction Then
			If ForExternalUsers Then
				Text = Text + Chars.LF + NStr("ru = '2. У ключа доступа обновлен состав внешних пользователей.'; en = '2. External users of the access key have been updated.'; pl = '2. Klucz dostępu zawiera zaktualizowaną listę użytkowników zewnętrznych.';de = '2. Der Zugriffsschlüssel verfügt über eine aktualisierte Zusammensetzung externer Benutzer.';ro = '2. La cheia de acces este actualizată componența utilizatorilor externi.';tr = '2. Erişim anahtarının, harici kullanıcıların kapsamı güncellendi.'; es_ES = '2. El contenido de usuarios externos de la clave de acceso se ha actualizado.'");
			Else
				Text = Text + Chars.LF + NStr("ru = '2. У ключа доступа обновлен состав пользователей.'; en = '2. Users of the access key have been updated.'; pl = '2. Klucz dostępu zaktualizował listę użytkowników.';de = '2. Der Zugriffsschlüssel verfügt über eine aktualisierte Zusammensetzung von Benutzern.';ro = '2. La cheia de acces este actualizată componența utilizatorilor.';tr = '2. Erişim anahtarının, kullanıcıların kapsamı güncellendi.'; es_ES = '2. El contenido de usuarios de la clave de acceso se ha actualizado.'");
			EndIf;
		Else
			Text = Text + Chars.LF + NStr("ru = '2. У ключа доступа обновлен состав групп доступа.'; en = '2. Access groups of the access key have been updated.'; pl = '2. Klucz dostępu zaktualizował skład grup dostępu.';de = '2. Der Zugriffsschlüssel verfügt über eine aktualisierte Zusammensetzung von Zugriffsgruppen.';ro = '2. La cheia de acces este actualizată componența grupurilor de acces.';tr = '2. Erişim anahtarının, erişim grupların kapsamı güncellendi.'; es_ES = '2. El contenido de grupos de acceso de la clave de acceso se ha actualizado.'");
		EndIf;
	Else
		If RestrictionParameters.HasUsersRestriction Then
			If ForExternalUsers Then
				Text = Text + Chars.LF + NStr("ru = '2. Обновление не требуется. У ключа доступа состав внешних пользователей не устарел.'; en = '2. Update is not required. External users of the access key are not obsolete.'; pl = '2. Aktualizacja nie jest wymagana. W kluczu dostępu skład zewnętrznych użytkowników nie jest nieaktualny.';de = '2. Eine Aktualisierung ist nicht erforderlich. Bei dem Zugriffsschlüssel ist die Zusammensetzung externer Benutzer nicht veraltet.';ro = '2. Actualizarea nu este necesară. Componența utilizatorilor externi la cheia de acces nu este învechită.';tr = '2. Güncelleme gerekmez. Erişim anahtarı dış kullanıcıların kapsamı eskimedi.'; es_ES = '2. No se requiere la actualización. El contenido de los usuarios externos de la clave de acceso no se ha caducado.'");
			Else
				Text = Text + Chars.LF + NStr("ru = '2. Обновление не требуется. У ключа доступа состав пользователей не устарел.'; en = '2. Update is not required. Users of the access key are not obsolete.'; pl = '2. Aktualizacja nie jest wymagana. W kluczu dostępu skład użytkowników nie jest nieaktualny.';de = '2. Eine Aktualisierung ist nicht erforderlich. Bei dem Zugriffsschlüssel ist die Zusammensetzung der Benutzer nicht veraltet.';ro = '2. Actualizarea nu este necesară. Componența utilizatorilor la cheia de acces nu este învechită.';tr = '2. Güncelleme gerekmez. Erişim anahtarın kullanıcı kapsamı eskimedi.'; es_ES = '2. No se requiere la actualización. El contenido de los usuarios de la clave de acceso no se ha caducado.'");
			EndIf;
		Else
			Text = Text + Chars.LF + NStr("ru = '2. Обновление не требуется. У ключа доступа состав групп доступа не устарел.'; en = '2. Update is not required. Access groups of the access key are not obsolete.'; pl = '2. Aktualizacja nie jest wymagana. W kluczu dostępu skład grup dostępu nie jest nieaktualny.';de = '2. Eine Aktualisierung ist nicht erforderlich. Bei dem Zugriffsschlüssel ist die Zusammensetzung der Zugriffsgruppe nicht veraltet.';ro = '2. Actualizarea nu este necesară. Componența grupurilor de acces la cheia de acces nu este învechită.';tr = '2. Güncelleme gerekmez. Erişim anahtarın erişim grupların kapsamı eskimedi.'; es_ES = '2. No se requiere la actualización. El contenido de los grupos de acceso de la clave de acceso no se ha caducado.'");
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Function ScheduleListsAccessUpdateAtServer()
	
	Lists = New Array;
	For Each ListItem In ListsToUpdate Do
		If ListItem.Check Then
			Lists.Add(ListItem.Value);
		EndIf;
	EndDo;
	
	If Lists.Count() = 0 Then
		Return False;
	EndIf;
	
	If Lists.Count() = ListsToUpdate.Count() Then
		Lists = Undefined;
	EndIf;
	
	AccessManagementInternal.ClearAccessGroupsValuesCacheToCalculateRights();
	
	If UpdateDataItemsAccessKeys Or UpdateAccessKeysRights Then
		PlanningParameters = AccessManagementInternal.AccessUpdatePlanningParameters();
		PlanningParameters.IsUpdateContinuation = True;
		If Not UpdateDataItemsAccessKeys Then
			PlanningParameters.DataAccessKeys = False;
		EndIf;
		If Not UpdateAccessKeysRights Then
			PlanningParameters.AllowedAccessKeys = False;
		EndIf;
		PlanningParameters.Details = "ScheduleManualAccessUpdate";
		AccessManagementInternal.ScheduleAccessUpdate(Lists, PlanningParameters);
	EndIf;
	
	If DeleteObsoleteInternalData Then
		PlanningParameters = AccessManagementInternal.AccessUpdatePlanningParameters();
		PlanningParameters.IsObsoleteItemsDataProcessor = True;
		PlanningParameters.Details = "ScheduleManualAccessUpdate";
		AccessManagementInternal.ScheduleAccessUpdate(Lists, PlanningParameters);
	EndIf;
	
	AccessManagementInternal.SetAccessUpdate(False);
	AccessManagementInternal.SetAccessUpdate(True);
	
	Return True;
	
EndFunction

// AccessUpdateObjectStartChoice event handler continuation.
&AtClient
Procedure BeginSelectUpdateObjectFollowUp(SelectedItem, NotDefined) Export
	
	If SelectedItem = Undefined Then
		Return;
	EndIf;
	
	SelectedAccessUpdateObjectType = SelectedItem.Value;
	If TypeOf(AccessUpdateObject) <> TypeOf(SelectedAccessUpdateObjectType) Then
		AccessUpdateObject = SelectedAccessUpdateObjectType;
	EndIf;
	
	AccessValueStartChoiceCompletion();
	
EndProcedure

// Completes the AccessUpdateObjectStartChoice event handler.
&AtClient
Procedure AccessValueStartChoiceCompletion()
	
	FormParameters = New Structure;
	FormParameters.Insert("ChoiceMode", True);
	FormParameters.Insert("CurrentRow", AccessUpdateObject);
	
	ListItem = AccessUpdateObjectsTypesTablesNames.FindByValue(
		SelectedAccessUpdateObjectType);
	
	If ListItem = Undefined Then
		Return;
	EndIf;
	ChoiceFormName = ListItem.Presentation + ".ChoiceForm";
	
	OpenForm(ChoiceFormName, FormParameters, Items.AccessUpdateObject);
	
EndProcedure

#EndRegion
