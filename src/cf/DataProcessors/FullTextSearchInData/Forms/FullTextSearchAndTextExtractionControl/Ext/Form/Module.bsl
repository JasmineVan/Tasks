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
	
	UseFullTextSearch = FullTextSearchServer.UseSearchFlagValue();
	
	If Common.SubsystemExists("StandardSubsystems.FilesOperations")
	   AND Users.IsFullUser() Then
		
		// Visibility settings at startup.
		Items.ExtractTextAutomaticallyGroup.Visible =
			  Users.IsFullUser(, True)
			AND Not Common.DataSeparationEnabled()
			AND Not Common.IsMobileClient();
		
	Else
		Items.ExtractTextAutomaticallyGroup.Visible = False;
	EndIf;
	
	If Items.ExtractTextAutomaticallyGroup.Visible Then
		
		If Common.FileInfobase() Then
			ChoiceList = Items.ExtractFilesTextsAtWindowsServer.ChoiceList;
			ChoiceList[0].Presentation = NStr("ru = 'Все рабочие станции работают под управлением ОС Windows'; en = 'All workstations run on Windows.'; pl = 'Wszystkie stacje robocze pracują pod kontrolą SO Windows';de = 'Alle Workstations laufen unter Windows-Betriebssystem';ro = 'Toate stațiile de lucru sunt gestionate de SO Windows';tr = 'Tüm iş istasyonları Windows işletim sistemi altında çalışır'; es_ES = 'Todas las estaciones de trabajo funcionan bajo el OS Windows'");
			
			ChoiceList = Items.ExtractFilesTextsAtLinuxServer.ChoiceList;
			ChoiceList[0].Presentation = NStr("ru = 'Одна или несколько рабочих станций работают под управлением ОС Linux'; en = 'One or more workstations run on Linux.'; pl = 'Jedna lub kilka stacji roboczych pracują pod kontrolą SO Linux';de = 'Eine oder mehrere Workstations arbeiten mit Linux-Betriebssystem';ro = 'Una sau mai multe stații de lucru sunt gestionate de SO Linux';tr = 'Bir ya da birkaç iş istasyonu Linux OS altında çalışır'; es_ES = 'Una o varias estaciones de trabajo funcionan bajo el OS Linux'");
		EndIf;
		
		// Form attributes values.
		ExtractTextFilesOnServer = ?(ConstantsSet.ExtractTextFilesOnServer, 1, 0);
	
		ScheduledJobsInfo = New Structure;
		FillScheduledJobInfo("TextExtraction");
	Else
		AutoTitle = False;
		Title = NStr("ru = 'Управление полнотекстовым поиском'; en = 'Full-text search management'; pl = 'Kierowanie wyszukiwaniem tekstowym';de = 'Verwalten Sie die Volltextsuche';ro = 'Gestionarea căutarea full-text';tr = 'Tam metin aramayı yönet'; es_ES = 'Gestionar la búsqueda de texto completo'");
		Items.SectionDetails.Title =
			NStr("ru = 'Включение и отключение полнотекстового поиска, обновление индекса полнотекстового поиска.'; en = 'Full-text search toggle, search index update.'; pl = 'Włączanie i wyłączanie wyszukiwania pełnotekstowego, aktualizacja indeksu wyszukiwania pełnotekstowego.';de = 'Aktivierung und Deaktivierung der Volltextsuche, Aktualisierung des Volltextsuchindex.';ro = 'Activarea și dezactivarea căutării full-text, actualizarea indexului de căutare full-text.';tr = 'Tam metin aramanın etkinleştirilmesi ve devre dışı bırakılması, tam metin arama dizininin güncellenmesi.'; es_ES = 'Activación y desactivación de la búsqueda de texto completo, actualización del índice de la búsqueda de texto completo.'");
	EndIf;
	
	// Update items states.
	SetAvailability();
	
	StandardSubsystemsServer.SetGroupTitleRepresentation(
		ThisObject, "ExtractTextAutomaticallyGroup");
	
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
	
	FullTextSearchClient.UseSearchFlagChangeNotificationProcessing(
		EventName, 
		UseFullTextSearch);
	
	SetAvailability();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure UseFullTextSearchOnChange(Item)
	
	FullTextSearchClient.OnChangeUseSearchFlag(UseFullTextSearch);
	
EndProcedure

&AtClient
Procedure ExtractFilesTextsAtServerOnChange(Item)
	Attachable_OnChangeAttribute(Item, False);
EndProcedure

&AtClient
Procedure DataToIndexMaxSizeOnChange(Item)
	
	Attachable_OnChangeAttribute(Item);
	
EndProcedure

&AtClient
Procedure RestrictDataToIndexMaxSizeOnChange(Item)
	
	Attachable_OnChangeAttribute(Item);
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure UpdateIndex(Command)
	UpdateIndexServer();
	ShowUserNotification(NStr("ru = 'Полнотекстовый поиск'; en = 'Full-text search'; pl = 'Wyszukiwanie pełnotekstowe';de = 'Volltextsuche';ro = 'Căutare în tot textul';tr = 'Tam metin arama'; es_ES = 'Búsqueda de texto completo'"),, NStr("ru = 'Индекс успешно обновлен'; en = 'Index has been updated'; pl = 'Indeks został pomyślnie zaktualizowany';de = 'Index erfolgreich aktualisiert';ro = 'Indexul este actualizat cu succes';tr = 'Dizin başarı ile güncellendi'; es_ES = 'Índice ha sido actualizado con éxito'"));
EndProcedure

&AtClient
Procedure ClearIndex(Command)
	ClearIndexServer();
	ShowUserNotification(NStr("ru = 'Полнотекстовый поиск'; en = 'Full-text search'; pl = 'Wyszukiwanie pełnotekstowe';de = 'Volltextsuche';ro = 'Căutare în tot textul';tr = 'Tam metin arama'; es_ES = 'Búsqueda de texto completo'"),, NStr("ru = 'Индекс успешно очищен'; en = 'Index has been cleaned up'; pl = 'Indeks został pomyślnie oczyszczony';de = 'Index erfolgreich gereinigt';ro = 'Indexul este golit cu succes';tr = 'Dizin başarı ile temizlendi'; es_ES = 'Índice ha sido limpiado con éxito'"));
EndProcedure

&AtClient
Procedure CheckIndex(Command)
	Try
		CheckIndexServer();
	Except
		ErrorMessageText = 
			NStr("ru = 'В настоящее время проверка индекса невозможна, так как выполняется его очистка или обновление.'; en = 'Cannot check index status. The index is being updated or cleaned up.'; pl = 'Obecnie weryfikacja indeksu nie jest możliwa, ponieważ wykonuje się jego czyszczenie lub aktualizacja.';de = 'Der Index kann derzeit nicht überprüft werden, da er gereinigt oder aktualisiert wird.';ro = 'Actualmente indexul nu poate fi verificat, deoarece se execută golirea sau actualizarea lui.';tr = 'Dizin doğrulama şu anda mümkün değildir, çünkü temizleme veya güncelleme yapılır.'; es_ES = 'Actualmente es imposible comprobar el índice porque se está limpiando o se está actualizando.'");
		CommonClient.MessageToUser(ErrorMessageText);
	EndTry;
	
	ShowUserNotification(NStr("ru = 'Полнотекстовый поиск'; en = 'Full-text search'; pl = 'Wyszukiwanie pełnotekstowe';de = 'Volltextsuche';ro = 'Căutare în tot textul';tr = 'Tam metin arama'; es_ES = 'Búsqueda de texto completo'"),, NStr("ru = 'Индекс содержит корректные данные'; en = 'Index is up to date'; pl = 'Indeks zawiera prawidłowe dane';de = 'Der Index enthält korrekte Daten';ro = 'Indexul conține date corecte';tr = 'Dizin doğru veri içermektedir'; es_ES = 'El índice contiene los datos correctos'"));
EndProcedure

&AtClient
Procedure EditScheduledJob(Command)
	ScheduledJobsHyperlinkClick("TextExtraction");
EndProcedure

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Client

&AtClient
Procedure Attachable_OnChangeAttribute(Item, UpdateInterface = True)
	
	Result = OnChangeAttributeServer(Item.Name);
	
	RefreshReusableValues();
	
	If Result.Property("CannotEnableFullTextSearchMode") Then
		// Display a warning message.
		QuestionText = NStr("ru = 'Для изменения режима полнотекстового поиска требуется завершение сеансов всех пользователей, кроме текущего.'; en = 'To change the full-text search mode, close all sessions, except for the current user session.'; pl = 'Aby zmienić tryb wyszukiwania pełnotekstowego należy zakończyć sesje wszystkich użytkowników, oprócz bieżącego.';de = 'Um den Volltextsuchmodus zu ändern, müssen alle Benutzer außer dem aktuellen Benutzer abgemeldet werden.';ro = 'Pentru a schimba modul de căutare full-text este necesară finalizarea sesiunilor tuturor utilizatorilor, cu excepția celei curente.';tr = 'Tam metin arama modunu değiştirmek için mevcut kullanıcı dışındaki tüm kullanıcı oturumlarını tamamlamanız gerekir.'; es_ES = 'Para cambiar el modo de texto completo se requiere terminar todas las sesiones de todos los usuarios a excepción de la actual.'");
		
		Buttons = New ValueList;
		Buttons.Add("ActiveUsers", NStr("ru = 'Активные пользователи'; en = 'Active users'; pl = 'Aktualni użytkownicy';de = 'Active Users';ro = 'Utilizatori activi';tr = 'Aktif kullanıcılar'; es_ES = 'Usuarios activos'"));
		Buttons.Add(DialogReturnCode.Cancel);
		
		Handler = New NotifyDescription("OnChangeAttributeAfterAnswerToQuestion", ThisObject);
		ShowQueryBox(Handler, QuestionText, Buttons, , "ActiveUsers");
		Return;
	EndIf;
	
	If UpdateInterface Then
		RefreshInterface = True;
		AttachIdleHandler("UpdateApplicationInterface", 2, True);
	EndIf;
	
	If Result.ConstantName <> "" Then
		Notify("Write_ConstantsSet", New Structure, Result.ConstantName);
	EndIf;
	
EndProcedure

&AtClient
Procedure ScheduledJobsHyperlinkClick(PredefinedItemName)
	Info = ScheduledJobsInfo[PredefinedItemName];
	If Info.ID = Undefined Then
		Return;
	EndIf;
	Context = New Structure;
	Context.Insert("PredefinedItemName", PredefinedItemName);
	Context.Insert("FlagChanged", False);
	Handler = New NotifyDescription("ScheduledJobsAfterChangeSchedule", ThisObject, Context);
	Dialog = New ScheduledJobDialog(Info.Schedule);
	Dialog.Show(Handler);
EndProcedure

&AtClient
Procedure ScheduledJobsAfterChangeSchedule(Schedule, Context) Export
	If Schedule = Undefined Then
		If Context.FlagChanged Then
			ThisObject[Context.CheckBoxName] = False;
		EndIf;
		Return;
	EndIf;
	
	Changes = New Structure("Schedule", Schedule);
	If Context.FlagChanged Then
		ThisObject[Context.CheckBoxName] = True;
		Changes.Insert("Use", True);
	EndIf;
	ScheduledJobsSave(Context.PredefinedItemName, Changes, True);
EndProcedure

&AtClient
Procedure OnChangeAttributeAfterAnswerToQuestion(Response, ExecutionParameters) Export
	If Response = "ActiveUsers" Then
		StandardSubsystemsClient.OpenActiveUserList();
	EndIf;
EndProcedure

&AtClient
Procedure UpdateApplicationInterface()
	
	If RefreshInterface = True Then
		RefreshInterface = False;
		CommonClient.RefreshApplicationInterface();
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Server call

&AtServer
Procedure UpdateIndexServer()
	FullTextSearch.UpdateIndex(False, False);
	SetAvailability("Command.UpdateIndex");
EndProcedure

&AtServer
Procedure ClearIndexServer()
	FullTextSearch.ClearIndex();
	SetAvailability("Command.ClearIndex");
EndProcedure

&AtServer
Procedure CheckIndexServer()
	IndexContainsCorrectData = FullTextSearch.CheckIndex();
	SetAvailability("Command.CheckIndex", True);
EndProcedure

&AtServer
Function OnChangeAttributeServer(ItemName)
	
	DataPathAttribute = Items[ItemName].DataPath;
	
	Result = SaveAttributeValue(DataPathAttribute);
	
	SetAvailability(DataPathAttribute);
	
	If Result.Property("CannotEnableFullTextSearchMode") Then
		Return Result;
	EndIf;
	
	RefreshReusableValues();
	
	Return Result;
	
EndFunction

&AtServer
Procedure ScheduledJobsSave(PredefinedItemName, Changes, SetVisibilityAvailability)
	Info = ScheduledJobsInfo[PredefinedItemName];
	If Info.ID = Undefined Then
		Return;
	EndIf;
	ScheduledJobsServer.ChangeJob(Info.ID, Changes);
	FillPropertyValues(Info, Changes);
	ScheduledJobsInfo.Insert(PredefinedItemName, Info);
	If SetVisibilityAvailability Then
		SetAvailability("ScheduledJob." + PredefinedItemName);
	EndIf;
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Server

&AtServer
Function SaveAttributeValue(DataPathAttribute)
	Result = New Structure("ConstantName", "");
	
	// Saving values of attributes not directly related to constants (in ratio one to one).
	If DataPathAttribute = "" Then
		Return Result;
	EndIf;
	
	NameParts = StrSplit(DataPathAttribute, ".");
	If NameParts.Count() <> 2 Then
		If DataPathAttribute = "ExtractTextFilesOnServer" Then
			ConstantName = "ExtractTextFilesOnServer";
			ConstantsSet.ExtractTextFilesOnServer = ExtractTextFilesOnServer;
			Changes = New Structure("Use", ConstantsSet.ExtractTextFilesOnServer);
			ScheduledJobsSave("TextExtraction", Changes, False);
		ElsIf DataPathAttribute = "IndexedDataMaxSize"
			Or DataPathAttribute = "LimitMaxIndexedDataSize" Then
			Try
				If LimitMaxIndexedDataSize Then
					// When you enable the restriction for the first time, the default value of the platform 1 MB is set.
					If IndexedDataMaxSize = 0 Then
						IndexedDataMaxSize = 1;
					EndIf;
					If FullTextSearch.GetMaxIndexedDataSize() <> IndexedDataMaxSize * 1048576 Then
						FullTextSearch.SetMaxIndexedDataSize(IndexedDataMaxSize * 1048576);
					EndIf;
				Else
					FullTextSearch.SetMaxIndexedDataSize(0);
				EndIf;
			Except
				WriteLogEvent(
					NStr("ru = 'Полнотекстовый поиск'; en = 'Full-text search'; pl = 'Wyszukiwanie pełnotekstowe';de = 'Volltextsuche';ro = 'Căutare în tot textul';tr = 'Tam metin arama'; es_ES = 'Búsqueda de texto completo'", Common.DefaultLanguageCode()),
					EventLogLevel.Error,
					,
					,
					DetailErrorDescription(ErrorInfo()));
				Result.Insert("CannotEnableFullTextSearchMode", True);
				Return Result;
			EndTry;
		EndIf;
	Else	
		ConstantName = NameParts[1];
	EndIf;
	
	If IsBlankString(ConstantName) Then
		Return Result;
	EndIf;	
	
	ConstantManager = Constants[ConstantName];
	ConstantValue = ConstantsSet[ConstantName];
	
	If ConstantManager.Get() <> ConstantValue Then
		ConstantManager.Set(ConstantValue);
	EndIf;
	
	Result.ConstantName = ConstantName;
	Return ConstantName;
	
EndFunction

&AtServer
Procedure SetAvailability(DataPathAttribute = "", IndexChecked = False)
	
	Status = FullTextSearchServer.FullTextSearchStatus();
	
	Items.FullTextSearchManagementGroup.Enabled = (UseFullTextSearch = 1);
	Items.ExtractTextAutomaticallyGroup.Enabled = (UseFullTextSearch = 1);
	
	If DataPathAttribute = ""
		Or DataPathAttribute = "LimitMaxIndexedDataSize"
		Or DataPathAttribute = "IndexedDataMaxSize"
		Or DataPathAttribute = "UseFullTextSearch"
		Or DataPathAttribute = "Command.UpdateIndex"
		Or DataPathAttribute = "Command.ClearIndex"
		Or DataPathAttribute = "Command.CheckIndex" Then
		
		If UseFullTextSearch = 1 Then
			IndexUpdateDate = FullTextSearch.UpdateDate();
			IndexTrue = (Status = "SearchAllowed");
			If IndexChecked AND Not IndexContainsCorrectData Then
				IndexStatus = NStr("ru = 'Требуется очистка и обновление'; en = 'Cleanup and update required'; pl = 'Wymagane jest czyszczenie i aktualizacja';de = 'Reinigung und Aktualisierung erforderlich';ro = 'Este necesară golirea și actualizarea';tr = 'Temizleme ve güncelleme gerekir'; es_ES = 'Se requiere limpiar y actualizar'");
			ElsIf IndexTrue Then
				IndexStatus = NStr("ru = 'Обновление не требуется'; en = 'No update required'; pl = 'Aktualizacja nie jest potrzebna';de = 'Update nicht erforderlich';ro = 'Nu este necesară actualizarea';tr = 'Güncelleme gerekmiyor'; es_ES = 'No se requiere una actualización'");
			Else
				IndexStatus = NStr("ru = 'Требуется обновление'; en = 'Update required'; pl = 'Wymagana aktualizacja';de = 'Aktualisierung erforderlich';ro = 'Actualizare necesară';tr = 'Güncelleştirme gerekli'; es_ES = 'Actualización requerida'");
			EndIf;
		Else
			IndexUpdateDate = '00010101';
			IndexTrue = False;
			IndexStatus = NStr("ru = 'Полнотекстовый поиск отключен'; en = 'Full-text search is disabled'; pl = 'Wyszukiwanie pełnotekstowe jest wyłączone';de = 'Die Volltextsuche ist deaktiviert';ro = 'Căutare text complet este dezactivată';tr = 'Tam metin araması devre dışı'; es_ES = 'Búsqueda de texto completo está desactivada'");
		EndIf;
		IndexedDataMaxSize = FullTextSearch.GetMaxIndexedDataSize() / 1048576;
		LimitMaxIndexedDataSize = IndexedDataMaxSize <> 0;
		
		Items.IndexedDataMaxSize.Enabled = LimitMaxIndexedDataSize;
		Items.MBDecoration.Enabled = LimitMaxIndexedDataSize;
		
		If (IndexChecked AND Not IndexContainsCorrectData)
			Or Not IndexTrue Then
			Items.IndexStatus.Font = New Font(, , True);
		Else
			Items.IndexStatus.Font = New Font;
		EndIf;
		
		Items.UpdateIndex.Enabled = Not IndexTrue;
		
	EndIf;
	
	If Items.ExtractTextAutomaticallyGroup.Visible
		AND (DataPathAttribute = ""
		Or DataPathAttribute = "ExtractTextFilesOnServer"
		Or DataPathAttribute = "ScheduledJob.TextExtraction") Then
		Items.EditScheduledJob.Enabled = ConstantsSet.ExtractTextFilesOnServer;
		Items.StartTextExtraction.Enabled       = Not ConstantsSet.ExtractTextFilesOnServer;
		If ConstantsSet.ExtractTextFilesOnServer Then
			Info = ScheduledJobsInfo["TextExtraction"];
			SchedulePresentation = String(Info.Schedule);
			SchedulePresentation = Upper(Left(SchedulePresentation, 1)) + Mid(SchedulePresentation, 2);
		Else
			SchedulePresentation = NStr("ru = 'Автоматическое извлечение текстов не выполняется.'; en = 'Automatic text extraction is not scheduled.'; pl = 'Automatyczne pobieranie tekstów nie jest wykonywane.';de = 'Der automatische Textabruf wird nicht durchgeführt.';ro = 'Extragerea automată a textelor nu se execută.';tr = 'Metinlerin otomatik olarak alınması başarısız.'; es_ES = 'No se realiza la extracción automática de textos.'");
		EndIf;
		Items.EditScheduledJob.ExtendedTooltip.Title = SchedulePresentation;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillScheduledJobInfo(PredefinedItemName)
	Info = New Structure("ID, Use, Schedule");
	ScheduledJobsInfo.Insert(PredefinedItemName, Info);
	Job = ScheduledJobsFindPredefinedItem(PredefinedItemName);
	If Job = Undefined Then
		Return;
	EndIf;
	Info.ID = Job.UUID;
	Info.Use = Job.Use;
	Info.Schedule    = Job.Schedule;
EndProcedure

&AtServer
Function ScheduledJobsFindPredefinedItem(PredefinedItemName)
	Filter = New Structure("Metadata", PredefinedItemName);
	FoundItems = ScheduledJobsServer.FindJobs(Filter);
	Return ?(FoundItems.Count() = 0, Undefined, FoundItems[0]);
EndFunction

#EndRegion
