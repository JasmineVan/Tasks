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
	
	MarkedObjectsDeletion = Parameters.MarkedObjectsDeletion;
	If MarkedObjectsDeletion Then
		Title = NStr("ru = 'Не удалось выполнить удаление помеченных объектов'; en = 'Cannot delete the marked objects'; pl = 'Nie można usunąć zaznaczonych obiektów';de = 'Die markierten Objekte können nicht gelöscht werden';ro = 'Nu se pot șterge obiectele marcate';tr = 'İşaretli nesneler silinemiyor'; es_ES = 'No se puede borrar los objetos marcados'");
		Items.ErrorMessageText.Title = NStr("ru = 'Невозможно выполнить удаление помеченных объектов, т.к. в программе работают другие пользователи:'; en = 'Cannot delete the marked objects as other users are signed in:'; pl = 'Nie można usunąć wybranych obiektów, ponieważ inni użytkownicy korzystają z aplikacji:';de = 'Ausgewählte Objekte können nicht gelöscht werden, wenn andere Benutzer die Anwendung verwenden:';ro = 'Nu se pot șterge obiectele selectate pe măsură ce alți utilizatori utilizează aplicația:';tr = 'Seçilen kullanıcılar, uygulamayı kullanan diğer kullanıcılar tarafından silinemiyor:'; es_ES = 'No se puede borrar los objetos seleccionados porque otros usuarios están utilizando la aplicación:'");
	EndIf;
	
	CheckExclusiveModeAtServer();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If ExclusiveModeAvailable Then
		Cancel = True;
		ExecuteNotifyProcessing(OnCloseNotifyDescription, False);
		Return;
	EndIf;
	
	If Parameters.MarkedObjectsDeletion Then
		IBConnectionsClient.SetTerminateAllSessionsExceptCurrentFlag(True);
	EndIf;
	AttachIdleHandler("CheckExclusiveMode", 30);
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	If Parameters.MarkedObjectsDeletion Then
		IBConnectionsClient.SetTerminateAllSessionsExceptCurrentFlag(False);
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ActiveUsersClick(Item)
	
	NotifyDescription = New NotifyDescription("OpenActiveUserListCompletion", ThisObject);
	OpenForm("DataProcessor.ActiveUsers.Form.ActiveUsers", , , , , ,
		NotifyDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ActiveUsers2Click(Item)
	
	NotifyDescription = New NotifyDescription("OpenActiveUserListCompletion", ThisObject);
	OpenForm("DataProcessor.ActiveUsers.Form.ActiveUsers" , , , , , ,
		NotifyDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure EndSessionsAndRepeat(Command)
	
	Items.PagesGroup.CurrentPage = Items.Wait;
	Items.RetryApplicationStartForm.Visible = False;
	Items.TerminateSessionsAndRestartApplicationForm.Visible = False;
	
	// Setting the infobase lock parameters.
	CheckExclusiveMode();
	LockFileInfobase();
	IBConnectionsClient.SetSessionTerminationHandlers(True);
	AttachIdleHandler("WaitForUserSessionTermination", 60);
	
EndProcedure

&AtClient
Procedure AbortApplicationStart(Command)
	
	CancelFileInfobaseLock();
	
	Close(True);
	
EndProcedure

&AtClient
Procedure RetryApplicationStart(Command)
	
	Close(False);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure OpenActiveUserListCompletion(Result, AdditionalParameters) Export
	CheckExclusiveMode();
EndProcedure

&AtClient
Procedure CheckExclusiveMode()
	
	CheckExclusiveModeAtServer();
	If ExclusiveModeAvailable Then
		Close(False);
		Return;
	EndIf;
		
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateActiveSessionCount(Form)
	
	If Form.ActiveSessionCount > 0 Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Активные пользователи (%1)'; en = 'Active users (%1)'; pl = 'Aktywni użytkownicy (%1)';de = 'Aktive Benutzer (%1)';ro = 'Utilizatori activi (%1)';tr = 'Aktif kullanıcılar (%1)'; es_ES = 'Usuarios activos (%1)'"), 
			Form.ActiveSessionCount);
	Else
		Text = NStr("ru = 'Активные пользователи'; en = 'Active users'; pl = 'Aktywni użytkownicy';de = 'Aktive Benutzer';ro = 'Utilizatori activi';tr = 'Aktif kullanıcılar'; es_ES = 'Usuarios activos'");
	EndIf;	
	
	Form.Items.ActiveUsers.Title = Text;
	Form.Items.ActiveUsersWait.Title = Text;
	Form.Items.ActiveUsers.ExtendedTooltip.Title = Form.ExclusiveModeSettingError;
	Form.Items.ActiveUsersWait.ExtendedTooltip.Title = Form.ExclusiveModeSettingError;
	
EndProcedure

&AtServer
Procedure CheckExclusiveModeAtServer()
	
	InfobaseSessions = GetInfoBaseSessions();
	CurrentUserSessionNumber = InfoBaseSessionNumber();
	ActiveSessionCount = 0;
	For Each IBSession In InfobaseSessions Do
		If IBSession.ApplicationName = "Designer"
			Or IBSession.SessionNumber = CurrentUserSessionNumber Then
			Continue;
		EndIf;
		ActiveSessionCount = ActiveSessionCount + 1;
	EndDo;
	
	ExclusiveModeAvailable = False;
	ExclusiveModeSettingError = "";
	If ActiveSessionCount = 0 Then
		Try
			SetExclusiveMode(True);
		Except
			ExclusiveModeSettingError = NStr("ru = 'Техническая информация:'; en = 'Details:'; pl = 'Informacja techniczna:';de = 'Technische Information:';ro = 'Informații tehnice:';tr = 'Teknik bilgi:'; es_ES = 'Información técnica:'") + " " 
				+ BriefErrorDescription(ErrorInfo());
		EndTry;
		If ExclusiveMode() Then
			SetExclusiveMode(False);
		EndIf;
		ExclusiveModeAvailable = True;
	EndIf;	
	UpdateActiveSessionCount(ThisObject);
	
EndProcedure

&AtClient
Procedure WaitForUserSessionTermination()
	
	UserSessionsTerminationDuration = UserSessionsTerminationDuration + 1;
	If UserSessionsTerminationDuration < 3 Then
		Return;
	EndIf;
	
	CancelFileInfobaseLock();
	Items.PagesGroup.CurrentPage = Items.Information;
	If MarkedObjectsDeletion Then
		Items.ErrorMessageText.Title = NStr("ru = 'Невозможно выполнить удаление помеченных объектов, т.к. не удалось завершить работу пользователей:'; en = 'Cannot delete the marked objects because the following user sessions are not closed:'; pl = 'Nie można usunąć oznaczonych obiektów, ponieważ niektóre sesje użytkowników nadal są aktywne:';de = 'Es ist nicht möglich, die gekennzeichneten Objekte zu löschen, da die Benutzer ihre Arbeit nicht beenden konnten:';ro = 'Nu puteți executa ștergerea obiectelor marcate, deoarece nu a fost finalizat lucrul utilizatorilor:';tr = 'Kullanıcı sonlandırılamadığı için etiketli nesneleri silemezsiniz:'; es_ES = 'No se puede eliminar los objetos marcados porque no se ha podido terminar el trabajo de usuarios:'");
	Else	
		Items.ErrorMessageText.Title = NStr("ru = 'Невозможно выполнить обновление версии программы, т.к. не удалось завершить работу пользователей:'; en = 'Cannot update the application version because the following user sessions are not closed:'; pl = 'Nie można zaktualizować wersji aplikacji, ponieważ niektóre sesje użytkowników nadal są aktywne:';de = 'Die Anwendungsversion kann nicht aktualisiert werden, da einige Benutzersitzungen noch aktiv sind:';ro = 'Eșec la actualizarea versiunii programului, deoarece nu a fost finalizat lucrul utilizatorilor:';tr = 'Bazı kullanıcı oturumları hala etkin olduğundan uygulama sürümü güncellenemiyor:'; es_ES = 'No se puede actualizar la versión de la aplicación porque algunas sesiones del usuario aún están activas:'");
	EndIf;
	Items.RetryApplicationStartForm.Visible = True;
	Items.TerminateSessionsAndRestartApplicationForm.Visible = True;
	DetachIdleHandler("WaitForUserSessionTermination");
	UserSessionsTerminationDuration = 0;
	
EndProcedure

&AtServer
Procedure LockFileInfobase()
	
	Object.DisableUserAuthorisation = True;
	If MarkedObjectsDeletion Then
		Object.LockEffectiveFrom = CurrentSessionDate() + 2*60;
		Object.LockEffectiveTo = Object.LockEffectiveFrom + 60;
		Object.MessageForUsers = NStr("ru = 'Программа заблокирована для удаления помеченных объектов.'; en = 'The application is locked to delete marked objects.'; pl = 'Aplikacja jest zablokowana do usuwania wybranych obiektów.';de = 'Die Anwendung ist zum Löschen ausgewählter Objekte gesperrt.';ro = 'Aplicația este blocată pentru ștergerea obiectelor selectate.';tr = 'Seçilen nesneleri silmek için uygulama kilitlendi.'; es_ES = 'La aplicación está bloqueda para borrar los objetos seleccionados.'");
	Else
		Object.LockEffectiveFrom = CurrentSessionDate() + 2*60;
		Object.LockEffectiveTo = Object.LockEffectiveFrom + 5*60;
		Object.MessageForUsers = NStr("ru = 'Программа заблокирована для обновления на новую версию.'; en = 'The application is locked for update to a new version.'; pl = 'Zaktualizowanie programu do nowej wersji nie udało się ponieważ program jest zablokowany.';de = 'Das Programm ist für das Update auf eine neue Version gesperrt.';ro = 'Aplicația este blocată pentru actualizare cu versiunea nouă.';tr = 'Program yeni sürüme yükseltmek için kilitlendi.'; es_ES = 'El programa está bloqueado para actualizar a versión nueva.'");
	EndIf;
	
	Try
		FormAttributeToValue("Object").SetLock();
	Except
		WriteLogEvent(IBConnections.EventLogEvent(),
			EventLogLevel.Error,,, 
			DetailErrorDescription(ErrorInfo()));
		Common.MessageToUser(BriefErrorDescription(ErrorInfo()));
	EndTry;
	
EndProcedure

&AtServer
Procedure CancelFileInfobaseLock()
	
	FormAttributeToValue("Object").CancelLock();
	
EndProcedure

#EndRegion
