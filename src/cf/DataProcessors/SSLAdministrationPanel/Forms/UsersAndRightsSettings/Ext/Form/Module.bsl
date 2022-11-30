///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

&AtClient
Var RefreshInterface;

#EndRegion

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not Users.CommonAuthorizationSettingsUsed() Then
		Items.UsersAuthorizationSettingsGroup.Visible = False;
		Items.ExternalUsersListGroupIndent.Visible = False;
		Items.ExternalUsersAuthorizationSettingsGroup.Visible = False;
		Items.ExternalUsersGroup.Group
			= ChildFormItemsGroup.AlwaysHorizontal;
	EndIf;
	
	If Common.DataSeparationEnabled()
	 Or StandardSubsystemsServer.IsBaseConfigurationVersion()
	 Or Common.IsStandaloneWorkplace()
	 Or Not UsersInternal.ExternalUsersEmbedded() Then
		
		Items.ExternalUsersGroup.Visible = False;
		Items.SectionDetails.Title =
			NStr("ru = 'Администрирование пользователей, настройка групп доступа, управление пользовательскими настройками.'; en = 'Manage users, configure access groups, grant access to external users, and manage user settings.'; pl = 'Administracja użytkowników, konfigurowanie grup dostępu, zarządzanie ustawieniami użytkowników.';de = 'Benutzerverwaltung, Konfiguration von Zugriffsgruppen, Verwaltung von Benutzereinstellungen.';ro = 'Administrarea utilizatorilor, setarea grupurilor de acces, administrarea setărilor de utilizator.';tr = 'Kullanıcı yönetimi, erişim gruplarını yapılandırma, kullanıcı ayarlarını yönetme.'; es_ES = 'La administración de usuarios, ajuste de los grupos del acceso, gestión de los ajustes de usuarios.'");
	EndIf;
	
	If StandardSubsystemsServer.IsBaseConfigurationVersion()
	 Or Common.IsStandaloneWorkplace() Then
		
		Items.UseUserGroups.Enabled = False;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagementInternal = Common.CommonModule("AccessManagementInternal");
		SimplifiedInterface = ModuleAccessManagementInternal.SimplifiedAccessRightsSetupInterface();
		Items.OpenAccessGroups.Visible            = NOT SimplifiedInterface;
		Items.UseUserGroups.Visible = NOT SimplifiedInterface;
		Items.AccessUpdateAtRecordLevel.Visible =
			ModuleAccessManagementInternal.LimitAccessAtRecordLevelUniversally(True);
		
		If Common.IsStandaloneWorkplace() Then
			Items.LimitAccessAtRecordLevel.Enabled = False;
		EndIf;
	Else
		Items.AccessGroupsGroup.Visible = False;
	EndIf;
	
	If Not Common.SubsystemExists("StandardSubsystems.PeriodClosingDates") Then
		Items.PeriodClosingDatesGroup.Visible = False;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.PersonalDataProtection") Then
		Items.OpenPersonalDataAccessEventsRegistrationSettingsGroup.Visible =
			  Not Common.DataSeparationEnabled()
			AND Users.IsFullUser(, True);
	Else
		Items.PersonalDataProtectionGroup.Visible = False;
	EndIf;
	
	// Update items states.
	SetAvailability();
	
	ApplicationSettingsOverridable.UsersAndRightsSettingsOnCreateAtServer(ThisObject);
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	If Exit Then
		Return;
	EndIf;
	UpdateApplicationInterface();
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName <> "Write_ConstantsSet" Then
		Return;
	EndIf;
	
	If Source = "UseSurvey" 
		AND CommonClient.SubsystemExists("StandardSubsystems.Survey") Then
		
		Read();
		SetAvailability();
		
	ElsIf Source = "UseHidePersonalDataOfSubjects" Then
		Read();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure UseUsersGroupsOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure RestrictAccessOnRecordsLevelOnChange(Item)
	
	If ConstantsSet.LimitAccessAtRecordLevelUniversally Then
		QuestionText =
			NStr("ru = 'Настройки групп доступа вступят в силу постепенно
			           |(см. ход по ссылке ""Обновление доступа на уровне записей"").
			           |
			           |Обновление доступа может замедлить работу программы и выполняться
			           |от нескольких секунд до часов (в зависимости от объема данных).'; 
			           |en = 'Access groups settings will take effect gradually
			           |(to view the progress, click ""View record-level access update progress"").
			           |
			           |This might slow down the application. This might take
			           |from several seconds to many hours (depending on the amount of data).'; 
			           |pl = 'Ustawienia grupy dostępu zaczną obowiązywać stopniowo
			           |(zob. ruch na łączu ""Aktualizuj dostęp na poziomie zapisu"").
			           |
			           |Aktualizacja dostępu może spowolnić program i działać
			           |od kilka sekund do kilku godzin (w zależności od ilości danych).';
			           |de = 'Die Einstellungen der Zugriffsgruppen werden schrittweise wirksam
			           |(siehe Link ""Aktualisierung des Zugriffs auf Datensatzebene"").
			           |
			           |Die Aktualisierung des Zugriffs kann das Programm verlangsamen und
			           |von einigen Sekunden bis zu Stunden dauern (abhängig von der Datenmenge).';
			           |ro = 'Setările grupurilor de acces vor intra în vigoare treptat
			           |(vezi progresul urmând linkul ""Actualizarea accesului la nivel de înregistrări"").
			           |
			           |Actualizarea accesului poate încetini lucrul aplicației și poate dura
			           |de la câteva secunde până la ore (în funcție de volumul de date).';
			           |tr = 'Erişim grubu ayarları aşamalı olarak etkili olacaktır 
			           |(“Kayıt Seviyesinde Erişimi Güncelle” bağlantısındaki harekete bakınız). 
			           |
			           |Erişim güncelleme programı yavaşlatabilir 
			           |ve birkaç saniye ile saatlerce çalışabilir (veri miktarına bağlı olarak).'; 
			           |es_ES = 'Los ajustes de grupos de acceso entrarán en vigor por etapas
			           |(véase las etapas por enlace ""Actualización de acceso en nivel de registro"").
			           |
			           |La actualización de acceso puede ralentizar el funcionamiento del programa y ejecutarse
			           |de unos segundo a unas horas (depende del volumen de datos).'");
		If ConstantsSet.LimitAccessAtRecordLevel Then
			QuestionText = NStr("ru = 'Включить ограничение доступа на уровне записей?'; en = 'Do you want to enable record-level access restrictions?'; pl = 'Chcesz włączyć ograniczenie dostępu na poziomie zapisów?';de = 'Zugriffsbeschränkung auf Schreibebene aktivieren?';ro = 'Activați restricționarea accesului la nivelul înregistrărilor?';tr = 'Giriş seviyesi giriş kısıtlaması etkinleştirilsin mi?'; es_ES = '¿Activar la restricción de acceso en nivel de registros?'")
				+ Chars.LF + Chars.LF + QuestionText;
		Else
			QuestionText = NStr("ru = 'Выключить ограничение доступа на уровне записей?'; en = 'Do you want to disable record-level access restrictions?'; pl = 'Chcesz wyłączyć ograniczenie dostępu na poziomie zapisów?';de = 'Zugriffsbeschränkung auf Schreibebene deaktivieren?';ro = 'Dezactivați restricționarea accesului la nivelul înregistrărilor?';tr = 'Kayıt düzeyinde erişimi kapat?'; es_ES = '¿Desactivar la restricción de acceso en nivel de registros?'")
				+ Chars.LF + Chars.LF + QuestionText;
		EndIf;
		
	ElsIf ConstantsSet.LimitAccessAtRecordLevel Then
		QuestionText =
			NStr("ru = 'Включить ограничение доступа на уровне записей?
			           |
			           |Потребуется заполнение данных, которое будет выполняться частями
			           |регламентным заданием ""Заполнение данных для ограничения доступа""
			           |(ход выполнения в журнале регистрации).
			           |
			           |Выполнение может сильно замедлить работу программы и выполняться
			           |от нескольких секунд до многих часов (в зависимости от объема данных).'; 
			           |en = 'Do you want to enable record-level access restrictions?
			           |
			           |This requires data population that will be performed in batches
			           |by the ""Populate access restrictions data"" scheduled job
			           |(to check the progress, see the event log).
			           |
			           |This might slow down the application. This might take
			           |from several seconds to many hours (depending on the amount of data).'; 
			           |pl = 'Czy chcesz wprowadzić
			           |
			           |ograniczenie dostępu na poziomie zapisów?
			           |Wymagane będą wypełnienie danych, które
			           |będą wykonywane przez części zadań harmonogramu ""Wypełnienie danych dla ograniczenia dostępu"" (krok wykonania w dzienniku zdarzeń).
			           |
			           |Wykonanie może znacznie
			           |spowolnić pracę aplikacji i jest wykonywane od kilku sekund do wielu godzin (w zależności od ilości danych).';
			           |de = 'Möchten Sie die 
			           |
			           |Zugriffsbeschränkung für die Schreibstufe aktivieren?
			           |Es werden Fülldaten benötigt, die von
			           |den Arbeitsplanteilen ""Daten für Zugriffsbeschränkung füllen"" ausgeführt werden (Schritt im Ereignisprotokollmonitor durchführen). 
			           |
			           |Die Ausführung kann die
			           |Anwendungsarbeit stark verlangsamen und wird von einigen Sekunden bis zu vielen Stunden ausgeführt (abhängig vom Datenvolumen).';
			           |ro = 'Activați restricția de acces la nivel de înregistrări?
			           |
			           |Va fi necesară completarea datelor, care va fi executată pe părți
			           |cu ajutorul sarcinii reglementare ""Completarea datelor pentru restricționarea accesului""
			           |(cursul executării în registrul logare).
			           |
			           |Executarea poate încetini esențial lucrul programului și poate dura
			           |de la câteva secunde până la mai multe ore (în funcție de volumul de date).';
			           |tr = 'Yazma düzeyindeki 
			           |
			           |erişim kısıtlamasını etkinleştirmek ister misiniz? 
			           |Programlama  iş parçaları ""Erişim kısıtlaması için veri doldurma"" (program günlüğü  olayında adımı gerçekleştir)
			           | verisinin doldurulması gerekecektir. 
			           |
			           |Yürütme, uygulama işlemlerini büyük  ölçüde yavaşlatabilir ve 
			           |birkaç saniye ile birkaç saat arasında  gerçekleştirilir (veri hacmine bağlı olarak).'; 
			           |es_ES = '¿Quiere activar
			           |
			           |la restricción de acceso a nivel de grabación?
			           |Se requerirá el relleno de datos que
			           |se ejecutará por las partes de la tarea programada ""Relleno de datos para la restricción de acceso"" (realizar el paso en la pantalla del registro de eventos).
			           |
			           |Ejecución puede en gran parte frenar el
			           |trabajo de la aplicación, y se ejecuta desde varios segundos a muchas horas (dependiendo del volumen de datos).'");
	Else
		QuestionText = "";
	EndIf;
	
	If ValueIsFilled(QuestionText) Then
		ShowQueryBox(
			New NotifyDescription(
				"UseRecordsLevelSecurityOnChangeCompletion",
				ThisObject, Item),
			QuestionText, QuestionDialogMode.YesNo);
	Else
		UseRecordsLevelSecurityOnChangeCompletion(DialogReturnCode.Yes, Item);
	EndIf;
	
EndProcedure

&AtClient
Procedure UseExternalUsersOnChange(Item)
	
	If ConstantsSet.UseExternalUsers Then
		
		QuestionText =
			NStr("ru = 'Разрешить доступ внешним пользователям?
			           |
			           |При входе в программу список выбора пользователей станет пустым
			           |(реквизит ""Показывать в списке выбора"" в карточках всех
			           | пользователей будет очищен и скрыт).'; 
			           |en = 'Do you want to allow external user access?
			           |
			           |This will clear the user selection list in the authorization window
			           |(the ""Show in selection list"" attribute will be cleared and hidden from all user profiles).
			           |'; 
			           |pl = 'Zezwolić na dostęp użytkownikom zewnętrznym?
			           |
			           |Po wejściu do programu lista wyboru użytkowników będzie pusta
			           |(rekwizyt ""Pokaż na liście wyboru"" w kartach wszystkich
			           | użytkowników będzie wyczyszczony i ukryty).';
			           |de = 'Zugriff für externe Benutzer erlauben?
			           |
			           |Wenn Sie das Programm aufrufen, wird die Benutzerauswahlliste leer
			           |(das Attribut ""In Auswahlliste anzeigen"" in den Benutzerprofilen wird gelöscht und ausgeblendet).
			           |';
			           |ro = 'Permiteți accesul utilizatorilor externi?
			           |
			           |La intrare în program lista utilizatorilor va fi goală
			           |(atributul ""Afișare în lista de selectare"" în fișele tuturor
			           | utilizatorilor va fi golit și ascuns).';
			           |tr = 'Harici kullanıcılara erişime izin ver? 
			           |
			           |Programa girdiğinizde, kullanıcı seçimi listesi boş olur 
			           |(tüm 
			           |kullanıcıların kartlarında ""Seçim listesinde göster"" ayrıntıları temizlenir ve gizlenir).'; 
			           |es_ES = '¿Permitir el acceso a los usuarios externos?
			           |
			           |Al entrar en el programa la lista de selección de usuarios estará vacía
			           | (el requisito ""Mostrar en la lista de selección"" en las tarjetas de todos los
			           | usuarios será limpiado y ocultado).'");
		
		ShowQueryBox(
			New NotifyDescription(
				"UseExternalUsersOnChangeCompletion",
				ThisObject,
				Item),
			QuestionText,
			QuestionDialogMode.YesNo);
	Else
		QuestionText =
			NStr("ru = 'Запретить доступ внешним пользователям?
			           |
			           |Реквизит ""Вход в программу разрешен"" будет
			           |очищен в карточках всех внешних пользователей.'; 
			           |en = 'Do you want to deny external user access?
			           |
			           |This will clear the ""Can sign in"" attribute 
			           |in all external user profiles.'; 
			           |pl = 'Uniemożliwić dostęp użytkownikom zewnętrznym?
			           |
			           |Rekwizyty ""Logowanie do programu dozwolone"" będzie
			           |wyczyszczony w kartach wszystkich użytkowników zewnętrznych.';
			           |de = 'Zugriff für externe Benutzer verweigern? 
			           |
			           |Das Attribut ""Login in das Programm ist erlaubt"" wird
			           |in allen externen Benutzerprofilen gelöscht.';
			           |ro = 'Interziceți accesul utilizatorilor externi?
			           |
			           |Atributul ""Intrarea în program este permisă"" va fi
			           |golit în fișele tuturor utilizatorilor externi.';
			           |tr = 'Harici kullanıcıların erişimini engelle? 
			           |
			           |""Programa girişine izin verilir"" sahne tüm dış kullanıcıların kartlarında 
			           |temizlenecektir.'; 
			           |es_ES = '¿Prohibir acceder a los usuarios externos?
			           |
			           |El requisito ""Está permitido entrar en el programa"" será
			           |limpiado en las tarjetas de todos los usuarios externos.'");
		
		ShowQueryBox(
			New NotifyDescription(
				"UseExternalUsersOnChangeCompletion",
				ThisObject,
				Item),
			QuestionText,
			QuestionDialogMode.YesNo);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure CatalogExternalUsers(Command)
	OpenForm("Catalog.ExternalUsers.ListForm", , ThisObject);
EndProcedure

&AtClient
Procedure ExternalUsersAuthorizationSettings(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("ShowExternalUsersSettings", True);
	
	OpenForm("CommonForm.UserAuthorizationSettings", FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure AccessUpdateOnRecordsLevel(Command)
	
	OpenForm("InformationRegister" + "." + "DataAccessKeysUpdate" + "."
		+ "Form" + "." + "AccessUpdateAtRecordLevel");
	
EndProcedure

&AtClient
Procedure ConfigurePeriodClosingDates(Command)
	
	If CommonClient.SubsystemExists("StandardSubsystems.PeriodClosingDates") Then
		ModulePeriodClosingDatesInternalClient = CommonClient.CommonModule("PeriodClosingDatesInternalClient");
		ModulePeriodClosingDatesInternalClient.OpenPeriodEndClosingDates(ThisObject);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Client

&AtClient
Procedure Attachable_OnChangeAttribute(Item, UpdateInterface = True)
	
	ConstantsNamesArray = OnChangeAttributeServer(Item.Name);
	
	RefreshReusableValues();
	
	If UpdateInterface Then
		RefreshInterface = True;
		AttachIdleHandler("UpdateApplicationInterface", 2, True);
	EndIf;
	
	For Each ConstantName In ConstantsNamesArray Do
		If ConstantName <> "" Then
			Notify("Write_ConstantsSet", New Structure, ConstantName);
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure Attachable_PDHidingSettingsOnChange(Item)
	
	If CommonClient.SubsystemExists("StandardSubsystems.PersonalDataProtection") Then
		ModulePersonalDataProtectionClient = CommonClient.CommonModule("PersonalDataProtectionClient");
		ModulePersonalDataProtectionClient.OnChangePersonalDataHidingSettings(ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateApplicationInterface()
	
	If RefreshInterface = True Then
		RefreshInterface = False;
		CommonClient.RefreshApplicationInterface();
	EndIf;
	
EndProcedure

&AtClient
Procedure UseRecordsLevelSecurityOnChangeCompletion(Response, Item) Export
	
	If Response = DialogReturnCode.No Then
		ConstantsSet.LimitAccessAtRecordLevel = Not ConstantsSet.LimitAccessAtRecordLevel;
		Return;
	EndIf;
	
	Attachable_OnChangeAttribute(Item);
	
	If Not ConstantsSet.LimitAccessAtRecordLevel Then
		
	EndIf;
	
EndProcedure

&AtClient
Procedure UseExternalUsersOnChangeCompletion(Response, Item) Export
	
	If Response = DialogReturnCode.No Then
		ConstantsSet.UseExternalUsers = Not ConstantsSet.UseExternalUsers;
	Else
		Attachable_OnChangeAttribute(Item);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Server call

&AtServer
Function OnChangeAttributeServer(ItemName)
	
	ConstantsNamesArray = New Array;
	
	DataPathAttribute = Items[ItemName].DataPath;
	
	BeginTransaction();
	Try
		
		ConstantName = SaveAttributeValue(DataPathAttribute);
		ConstantsNamesArray.Add(ConstantName);
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	SetAvailability(DataPathAttribute);
	
	RefreshReusableValues();
	
	Return ConstantsNamesArray;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Server

&AtServer
Function SaveAttributeValue(DataPathAttribute)
	
	NameParts = StrSplit(DataPathAttribute, ".");
	If NameParts.Count() <> 2 Then
		Return "";
	EndIf;
	
	ConstantName = NameParts[1];
	ConstantManager = Constants[ConstantName];
	ConstantValue = ConstantsSet[ConstantName];
	CurrentValue	= ConstantManager.Get();
	If CurrentValue <> ConstantValue Then
		Try
			ConstantManager.Set(ConstantValue);
		Except
			ConstantsSet[ConstantName] = CurrentValue;
			Raise;
		EndTry;
	EndIf;
	
	Return ConstantName;
	
EndFunction

&AtServer
Procedure SetAvailability(DataPathAttribute = "")
	
	If DataPathAttribute = "ConstantsSet.UseExternalUsers"
	 Or DataPathAttribute = "" Then
		
		UseExternalUsers = ConstantsSet.UseExternalUsers;
		
		Items.OpenExternalUsers.Enabled         = UseExternalUsers;
		Items.ExternalUsersAuthorizationSettings.Enabled = UseExternalUsers;
		
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.PeriodClosingDates")
		AND (DataPathAttribute = "ConstantsSet.UsePeriodClosingDates"
		Or DataPathAttribute = "") Then
		
		Items.ConfigurePeriodClosingDates.Enabled = ConstantsSet.UsePeriodClosingDates;
	EndIf;
	
	
	
EndProcedure

#EndRegion
