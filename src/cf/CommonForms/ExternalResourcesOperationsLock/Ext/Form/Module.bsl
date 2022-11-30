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
	
	EventLogEventName = ExternalResourcesOperationsLock.EventLogEventName();
	
	LockParameters = ExternalResourcesOperationsLock.SavedLockParameters();
	CheckServerName = LockParameters.CheckServerName;
	
	If Parameters.LockDecisionMaking Then
		
		UnlockText = ScheduledJobsInternal.SettingValue("UnlockCommandPlacement");
		DataSeparationEnabled = Common.DataSeparationEnabled();
		DataSeparationChanged = LockParameters.DataSeparationEnabled <> DataSeparationEnabled;
		
		If DataSeparationEnabled Then
			Items.InfobaseMoved.Title = NStr("ru = 'Приложение перемещено'; en = 'The application is transferred'; pl = 'Aplikacja została przemieszczona';de = 'Die Anwendung wurde verschoben.';ro = 'Aplicația a fost transferată';tr = 'Uygulama taşındı'; es_ES = 'Aplicación trasladada'");
			Items.IsInfobaseCopy.Title = NStr("ru = 'Это копия приложения'; en = 'This is an application copy'; pl = 'To jest kopia aplikacji';de = 'Dies ist eine Kopie der Anwendung';ro = 'Aceasta este copia aplicației';tr = 'Bu uygulamanın kopyası'; es_ES = 'Es la copia de la aplicación'");
			Title = NStr("ru = 'Приложение было перемещено или восстановлено из резервной копии'; en = 'The application was transferred or restored from backup'; pl = 'Aplikacja została przemieszczona albo odzyskana z kopii zapasowej';de = 'Die Anwendung wurde aus der Sicherung verschoben oder wiederhergestellt';ro = 'Aplicația a fost transferată sau restabilită din copia de rezervă';tr = 'Uygulama taşındı veya yedek kopyadan yenilendi'; es_ES = 'La aplicación ha sido trasladada o restablecida de la copia de reserva'");
		EndIf;
		
		If Not DataSeparationEnabled AND Not DataSeparationChanged Then
			
			ScalableClusterClarification = ?(Common.FileInfobase(), "",
				NStr("ru = '• При работе в масштабируемом кластере для предотвращения ложных срабатываний из-за смены компьютеров, выступающих
				           |  в роли рабочих серверов, отключите проверку имени компьютера, нажмите <b>Еще - Проверять имя сервера.</b>'; 
				           |en = '• When using a scalable cluster, to prevent false starts due to change of  computers acting
				           | as working servers, turn off the computer name check, click <b>More actions - Check server name.</b>'; 
				           |pl = '• Podczas pracy w klastrze skalowalnym, aby zapobiec fałszywym alarmom z powodu zmiany komputerów działających
				           | jako serwery robocze, wyłącz sprawdzanie nazwy komputera, kliknij na <b>Więcej - Sprawdź nazwę serwera.</b>';
				           |de = '- Wenn Sie in einem skalierbaren Cluster arbeiten, deaktivieren Sie die Prüfung auf Computernamen, um Fehlalarme zu vermeiden, da Sie die Computer ändern, die als 
				           |Server fungieren, klicken Sie auf <b>Mehr - Servername prüfen.</b>';
				           |ro = '• În timpul lucrului în clusterul scalabil pentru evitarea activărilor false din cauza schimbării computerelor care apar
				           | în calitate de servere, dezactivați verificarea numelui computerului, tastați <b>Mai multe - Verifică numele serverului.</b>';
				           |tr = '• Ölçüklenen kümede çalışırken iş sunucuları olarak çalışan bilgisayarların değiştiğinden dolayı oluşan yanlış devreye girmelerini önlemek için 
				           |  bilgisayar adını kontrol etme işlevini devre dışı bırakın <b>Daha fazla - Sunucu adını kontrol edin''i tıklayın.</b>'; 
				           |es_ES = '• Al trabajar en el clúster escalable para prevenir falsas alarmas a causa de cambiar los ordenadores que funcionan
				           | como servidores de trabajo, desactive la prueba del nombre de ordenador, pulse <b>Más - Comprobar nombre de servidor.</b>'"));
			
			WarningLabel = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Работа со всеми внешними ресурсами (синхронизация данных, отправка почты и т.п.), выполняемая по расписанию,
				           |заблокирована для предотвращения конфликтов с основой информационной базой.
				           |
				           |%1
				           |
				           |<a href = ""ЖурналРегистрации"">Техническая информация о причине блокировки</a>
				           |
				           |• Если информационная база будет использоваться для ведения учета, нажмите <b>Информационная база перемещена</b>.
				           |• Если это копия информационной базы, нажмите <b>Это копия информационной базы</b>.
				           |%2
				           |
				           |%3'; 
				           |en = 'Operations with all external resources (data synchronization, email sending, and so on) executed on schedule
				           |are locked to prevent conflicts with the main infobase.
				           |
				           |%1
				           |
				           |<a href = ""EventLog"">Technical information on lock reason</a>
				           |
				           |• If the infobase will be used for accounting, click <b>Infobase is transferred</b>.
				           |• If it is a copy of the infobase, click<b>This is an infobase copy</b>.
				           |%2
				           |
				           |%3'; 
				           |pl = 'Praca ze wszystkimi zasobami zewnętrznymi (synchronizacja danych, wysyłanie poczty, itp.), wykonanymi według harmonogramu,
				           |jest zablokowana, aby zapobiec konfliktom z główną bazą informacyjną.
				           |
				           |%1
				           |
				           |<a href = ""ЖурналРегистрации""> Informacje techniczne o przyczynie blokady</a>
				           |
				           |• Jeśli baza informacyjna zostanie wykorzystana do przechowywania zapisów, kliknij na <b>Baza informacyjna przeniesiona</b>.
				           |• Jeśli jest to kopia bazy informacyjnej, wtedy kliknij na <b>To jest kopia bazy informacyjnej</b>.
				           |%2
				           |
				           |%3';
				           |de = 'Die Arbeit mit allen externen Ressourcen (Datensynchronisation, Mailversand, etc.), die planmäßig durchgeführt werden,
				           | wird blockiert, um Konflikte mit der Hauptinformationsbasis zu vermeiden.
				           |
				           |%1
				           |
				           |<a href = ""Ereignisprotokoll"">Technische Informationen über den Grund für die Blockierung</a>
				           |
				           |- Wenn die Informationsbasis für die Buchhaltung verwendet werden soll, klicken Sie auf<b>Informationsbasis verschoben</b>.
				           |- Wenn es sich um eine Kopie der Informationsbasis handelt, klicken Sie auf<b>Dies ist eine Kopie der Informationsbasis</b>.
				           |%2
				           |
				           |%3';
				           |ro = 'Lucrul cu toate resursele externe (sincronizarea datelor, trimiterea poștei etc.), executat conform orarului, 
				           |este blocat pentru evitarea conflictelor cu baza de informații principală.
				           |
				           |%1
				           |
				           |<a href = ""ЖурналРегистрации"">Informații tehnice despre cauza blocării</a>
				           |
				           |• Dacă baza de informații va fi utilizată pentru ținerea evidenței, atunci tastați <b>Baza de informații este transferată</b>.
				           |• Dacă aceasta este copia bazei de informații, atunci tastați <b>Aceasta este copia bazei de informații</b>.
				           |%2
				           |
				           |%3';
				           |tr = 'Grafiğe göre yapılan tüm dış kaynaklar ile çalışma (veri eşleşmesi, posta gönderimi vs.),
				           |temel veri tabanı ile çatışmaları önlemek için bloke edildi.
				           |
				           |%1
				           |
				           |<a href = ""KayıtÖnlüğü"">Kilitleme nedeni hakkında teknik bilgiler</a>
				           |
				           |• Veri tabanı muhasebe için kullanılacaksa <b>Veri tabanı taşındı''yı tıklayın</b>.
				           |• Bu veri tabanın kopyası ise <b>Bu veri tabanın kopyasıdır''ı tıklayın</b>.
				           |%2
				           |
				           |%3'; 
				           |es_ES = 'El uso de todos los recursos exteriores (sincronización de datos, envío de correo etc.) que se realiza por calendario
				           |está bloqueado para prevenir los conflictos con la base de información principal.
				           |
				           |%1
				           |
				           |<a href = ""ЖурналРегистрации"">Información técnica de razón del bloqueo</a>
				           |
				           |• Si la base de información se usará para contabilizar pulse <b>La base de información se ha trasladado</b>.
				           |• Si es copia de la base de información pulse <b>Es copia de la base de información</b>.
				           |%2
				           |
				           |%3'"),
				LockParameters.LockReason,
				ScalableClusterClarification,
				UnlockText);
		ElsIf Not DataSeparationEnabled AND DataSeparationChanged Then
			WarningLabel = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Работа со всеми внешними ресурсами (синхронизация данных, отправка почты и т.п.), выполняемая по расписанию,
				           |заблокирована для предотвращения конфликтов с приложением в Интернете.
				           |
				           |<b>Информационная база была загружена из приложения в Интернете</b>
				           |
				           |• Если информационная база будет использоваться для ведения учета, нажмите <b>Информационная база перемещена</b>.
				           |• Если это копия информационной базы, нажмите <b>Это копия информационной базы</b>.
				           |
				           |%1'; 
				           |en = 'Operations with all external resources (data synchronization, email sending, and so on) executed on schedule
				           | are locked to prevent conflicts with the online application.
				           |
				           |<b> The infobase was downloaded from an online application</b>
				           |
				           | • If an infobase will be used for accounting, click <b>Infobase is transferred</b>.
				           |• If it is a copy of the infobase, click<b>This is an infobase copy</b>.
				           |
				           |%1'; 
				           |pl = 'Praca ze wszystkimi zasobami zewnętrznymi (synchronizacja danych, wysyłanie poczty, itp.), wykonanymi wg harmonogramu,
				           |jest zablokowana, aby zapobiec konfliktom z aplikacją w Internecie.
				           |
				           |<b>Baza informacyjna została pobrana z aplikacji w Internecie</b>
				           |
				           |• Jeśli baza informacyjna zostanie wykorzystana do prowadzenia księgowości, kliknij <b>Baza informacyjna przeniesiona</b>.
				           |• Jeśli jest to kopia bazy informacyjnej, wtedy kliknij na<b>To jest kopia bazy informacyjnej</b>.
				           |
				           |%1';
				           |de = 'Das planmäßige Arbeiten mit allen externen Ressourcen (Datensynchronisation, Mailversand, etc.) ist gesperrt, 
				           |um Konflikte mit der Anwendung im Internet zu vermeiden. 
				           |
				           |<b>Informationsdatenbank wurde von der Internetanwendung heruntergeladen</b>
				           |
				           |- Wenn die Informationsdatenbank für Abrechnungszwecke verwendet werden soll, klicken Sie auf<b>Informationsdatenbank wird verschoben</b>.
				           |- Wenn es sich um eine Kopie der Datenbank handelt, klicken Sie auf<b>Dies ist eine Kopie der Datenbank</b>.
				           |
				           |%1';
				           |ro = 'Lucrul cu toate resursele externe (sincronizarea datelor, trimiterea poștei etc.), executat conform orarului, 
				           |este blocat pentru evitarea conflictelor cu aplicația în Internet.
				           |
				           |<b> Baza de informații a fost importată din aplicația în Internet</b>
				           |
				           |• Dacă baza de informații va fi utilizată pentru ținerea evidenței, atunci tastați <b>Baza de informații este transferată</b>.
				           |• Dacă aceasta este copia bazei de informații, atunci tastați <b>Aceasta este copia bazei de informații</b>.
				           |
				           |%1';
				           |tr = 'Grafiğe göre yapılan tüm dış kaynaklar ile çalışma (veri eşleşmesi, posta gönderimi vs.),
				           |Internet''teki uygulama ile çatışmaları önlemek için bloke edildi. 
				           |
				           |<b> Veri tabanı İnternet''teki uygulamadan yüklenmiştir </b>
				           |
				           | • Veri tabanı muhasebe için kullanılacaksa <b> Veritabanı taşındı ''yı</b> tıklayın. • Bu veri tabanın kopyası ise 
				           |;Bu veri tabanın kopyasıdır''ı tıklayın<b>.</b>
				           |
				           |%1'; 
				           |es_ES = 'El uso de todos los recursos exteriores (sincronización de datos, envío de correo etc.) que se realiza por calendario
				           |está bloqueado para prevenir los conflictos con la aplicación en Internet.
				           |
				           |<b>La base de información ha sido descargada de la aplicación de Internet</b>
				           |
				           |• Si la base de información se usará para contabilizar pulse <b>La base de información se ha trasladado</b>.
				           |• Si es copia de la base de información pulse <b>Es copia de la base de información</b>.
				           |
				           |%1'"),
				UnlockText);
		ElsIf DataSeparationEnabled AND Not DataSeparationChanged Then
			WarningLabel = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Работа со всеми внешними ресурсами (синхронизация данных, отправка почты и т.п.), выполняемая по расписанию,
				           |заблокирована для предотвращения конфликтов с приложением в Интернете.
				           |
				           |<b>Приложение было перемещено</b>
				           |
				           |• Если приложение будет использоваться для ведения учета, нажмите <b>Приложение перемещено</b>.
				           |• Если это копия приложения, нажмите <b>Это копия приложения</b>.
				           |
				           |%1'; 
				           |en = 'Operations with all external resources (data synchronization, email sending, and so on) executed on schedule
				           | are locked to prevent conflicts with the online application.
				           |
				           |<b>The application was transferred</b>
				           |
				           |• If the application will be used for accounting, click<b>The application is transferred</b>.
				           |• If it is a copy of the application, click<b>This is an application copy</b>.
				           |
				           |%1'; 
				           |pl = 'Praca ze wszystkimi zasobami zewnętrznymi (synchronizacja danych, wysyłanie poczty, itp.), wykonanymi wg harmonogramu,
				           |jest zablokowana, aby zapobiec konfliktom z aplikacją w Internecie.
				           |
				           |<b>Aplikacja została przeniesiona</b>
				           |
				           |• Jeśli aplikacja zostanie użyta do rozliczania, kliknij <b>Aplikacja została przemieszczona</b>.
				           |• Jeśli jest to kopia aplikacji, kliknij <b>To jest kopia aplikacji</b>.
				           |
				           |%1';
				           |de = 'Das planmäßige Arbeiten mit allen externen Ressourcen (Datensynchronisation, Mailversand, etc.) ist gesperrt,
				           |um Konflikte mit der Anwendung im Internet zu vermeiden. 
				           |
				           |<b>Anwendung wurde verschoben</b>
				           |
				           |- Wenn die Anwendung für Abrechnungszwecke verwendet werden soll, tippen Sie auf <b>die Anwendung wurde verschoben</b>.
				           | - Wenn es sich um eine Kopie der Anwendung handelt, tippen Sie auf <b>Dies ist eine Kopie der Anwendung</b>.
				           |
				           |%1';
				           |ro = 'Lucrul cu toate resursele externe (sincronizarea datelor, trimiterea poștei etc.), executat conform orarului, 
				           |este blocat pentru evitarea conflictelor cu aplicația în Internet.
				           |
				           |<b> Aplicația a fost transferată</b>
				           |
				           |• Dacă aplicația va fi utilizată pentru ținerea evidenței, atunci tastați <b>Aplicația este transferată</b>.
				           |• Dacă aceasta este copia aplicației, atunci tastați <b>Aceasta este copia aplicației</b>.
				           |
				           |%1';
				           |tr = 'Grafiğe göre yapılan tüm dış kaynaklar ile çalışma (veri eşleşmesi, posta gönderimi vs.),
				           |Internet''teki uygulama ile çatışmaları önlemek için bloke edildi. 
				           |
				           |<b> Uygulama taşındı </b>
				           |
				           | • Veri tabanı muhasebe için kullanılacaksa <b> Veritabanı taşındı ''yı</b> tıklayın. • Bu uygulamanın kopyası ise 
				           |;Bu uygulamanın kopyasıdır''ı tıklayın<b>.</b>
				           |
				           |%1'; 
				           |es_ES = 'El uso de todos los recursos exteriores (sincronización de datos, envío de correo etc.) que se realiza por calendario
				           |está bloqueado para prevenir los conflictos con la aplicación en Internet.
				           |
				           |<b>La aplicación ha sido trasladada</b>
				           |
				           |• Si la aplicación se usará para contabilizar pulse <b>La aplicación se ha trasladado</b>.
				           |• Si es copia de la base de información pulse <b>Es copia de la base de información</b>.
				           |
				           |%1'"),
				UnlockText);
		Else // If DataSeparationEnabled and DataSeparationChanged
			WarningLabel = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Работа со всеми внешними ресурсами (синхронизация данных, отправка почты и т.п.), выполняемая по расписанию,
				           |заблокирована для предотвращения конфликтов с локальной версией.
				           |
				           |Приложение было загружено из локальной версии
				           |
				           |• Если приложение будет использоваться для ведения учета, нажмите <b>Приложение перемещено</b>.
				           |• Если это копия приложения, нажмите <b>Это копия приложения</b>.
				           |
				           |%1'; 
				           |en = 'Operations with all external resources (data synchronization, email sending, and so on) executed on schedule
				           | are locked to prevent conflicts with the local version.
				           |
				           |The application was downloaded from the local version
				           |
				           |• If the application will be used for accounting, click<b>The application is transferred</b>.
				           |• If it is a copy of the application, click <b>This is an application copy</b>.
				           |
				           |%1'; 
				           |pl = 'Praca ze wszystkimi zasobami zewnętrznymi (synchronizacja danych, wysyłanie poczty, itp.), wykonanymi wg harmonogramu,
				           |jest zablokowana, aby zapobiec konfliktom z wersją lokalną.
				           |
				           |Aplikacja została pobrana z wersji lokalnej.
				           |
				           |• Jeśli aplikacja zostanie użyta do rozliczania, kliknij <b>Aplikacja została przemieszczona</b>.
				           |• Jeśli jest to kopia aplikacji, kliknij <b>To jest kopia aplikacji</b>.
				           |
				           |%1';
				           |de = 'Das Arbeiten mit allen externen Ressourcen (Datensynchronisation, Mailversand, etc.), die nach dem Zeitplan durchgeführt werden, ist gesperrt,
				           |um Konflikte mit der lokalen Version zu vermeiden.
				           |
				           |Die Anwendung wurde von der lokalen Version heruntergeladen
				           |
				           |- Wenn die Anwendung für Abrechnungszwecke verwendet werden soll, klicken Sie auf die Schaltfläche <b>Anwendung wird verschoben</b>.
				           |- Wenn es sich um eine Kopie der Anwendung handelt, tippen Sie auf <b>Dies ist eine Kopie der Anwendung</b>.
				           |
				           |%1 ';
				           |ro = 'Lucrul cu toate resursele externe (sincronizarea datelor, trimiterea poștei etc.), executat conform orarului, 
				           |este blocat pentru evitarea conflictelor cu versiunea locală.
				           |
				           |Aplicația a fost importată din versiunea locală
				           |
				           |• Dacă aplicația va fi utilizată pentru ținerea evidenței, atunci tastați <b>Aplicația este transferată</b>.
				           |• Dacă aceasta este copia aplicației, atunci tastați <b>Aceasta este copia aplicației</b>.
				           |
				           |%1';
				           |tr = 'Grafiğe göre yapılan tüm dış kaynaklar ile çalışma (veri eşleşmesi, posta gönderimi vs.),
				           |lokal sürüm ile çatışmaları önlemek için bloke edildi. 
				           |
				           |Uygulama lokal sürümden yüklendi 
				           |
				           |Uygulama muhasebe için kullanılacaksa <b> Uygulama taşındı ''yı</b> tıklayın.</b> • Bu uygulamanın kopyası ise 
				           |;Bu uygulamanın kopyasıdır''ı tıklayın<b>.
				           |
				           |%1'; 
				           |es_ES = 'El uso de todos los recursos exteriores (sincronización de datos, envío de correo etc.) que se realiza por calendario
				           |está bloqueado para prevenir los conflictos con la versión local.
				           |
				           |La aplicación ha sido descargada de la versión local
				           |
				           |• Si la aplicación se usará para contabilizar pulse <b>La aplicación se ha trasladado</b>.
				           |• Si es copia de la base de información pulse <b>Es copia de la base de información</b>.
				           |
				           |%1'"),
				UnlockText);
		EndIf;
		
		Items.WarningLabel.Title = StringFunctionsClientServer.FormattedString(WarningLabel);
		
		If Common.FileInfobase() Then
			Items.FormMoreGroup.Visible = False;
		Else
			Items.FormCheckServerName.Check = CheckServerName;
			Items.FormHelp.Visible = False;
		EndIf;
		
	Else
		Items.FormParametersGroup.CurrentPage = Items.LockParametersGroup;
		Items.WarningLabel.Visible = False;
		Items.WriteAndClose.DefaultButton = True;
		Title = NStr("ru = 'Параметры блокировки работы с внешними ресурсами'; en = 'Lock settings of external resources'; pl = 'Parametry blokowania pracy z zasobami zewnętrznymi';de = 'Parameter für die Sperrrung der Arbeit mit externen Ressourcen';ro = 'Parametrii de blocare a lucrului cu resursele externe';tr = 'Dış kaynak kilitleme seçenekleri'; es_ES = 'Los parámetros del bloqueo del uso de los recursos externos'");
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure LabelWarningURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	FormParameters.Insert("EventLogEvent", EventLogEventName);
	OpenForm("DataProcessor.EventLog.Form.EventLog", FormParameters);
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure InfobaseMoved(Command)
	
	AllowExternalResources();
	StandardSubsystemsClient.SetAdvancedApplicationCaption();
	RefreshInterface();
	Close();
	
EndProcedure

&AtClient
Procedure IsInfobaseCopy(Command)
	
	DenyExternalResources();
	StandardSubsystemsClient.SetAdvancedApplicationCaption();
	RefreshInterface();
	Close();
	
EndProcedure

&AtClient
Procedure CheckServerName(Command)
	
	CheckServerName = Not CheckServerName;
	Items.FormCheckServerName.Check = CheckServerName;
	SetServerNameCheckInLockParameters(CheckServerName);
	
EndProcedure

&AtClient
Procedure WriteAndClose(Command)
	
	SetServerNameCheckInLockParameters(CheckServerName);
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Procedure AllowExternalResources()
	
	ExternalResourcesOperationsLock.AllowExternalResources();
	
EndProcedure

&AtServerNoContext
Procedure DenyExternalResources()
	
	ExternalResourcesOperationsLock.DenyExternalResources();
	
EndProcedure

&AtServerNoContext
Procedure SetServerNameCheckInLockParameters(CheckServerName)
	
	ExternalResourcesOperationsLock.SetServerNameCheckInLockParameters(CheckServerName);
	
EndProcedure

#EndRegion
