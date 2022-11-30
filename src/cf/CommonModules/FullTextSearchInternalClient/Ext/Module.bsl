///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

Procedure ShowExclusiveChangeModeWarning() Export
	
	QuestionText = 
		NStr("ru = 'Для изменения режима полнотекстового поиска требуется 
		           |завершение сеансов всех пользователей, кроме текущего.'; 
		           |en = 'To change the full-text search mode, close all sessions,
		           |except for the current user session.'; 
		           |pl = 'Aby zmienić tryb wyszukiwania pełnotekstowego należy 
		           |zakończyć sesje wszystkich użytkowników, oprócz bieżącego.';
		           |de = 'Um den Volltextsuchmodus zu ändern, müssen Sie alle 
		           |Benutzersitzungen mit Ausnahme der aktuellen beenden.';
		           |ro = 'Pentru a schimba modul de căutare full-text este necesară 
		           |finalizarea sesiunilor tuturor utilizatorilor, cu excepția celei curente.';
		           |tr = 'Tam metin arama modunu değiştirmek için geçerli olan hariç 
		           |tüm kullanıcı oturumlarını sonlandırmanız gerekir.'; 
		           |es_ES = 'Para cambiar el modo de la búsqueda de texto completo se requiere 
		           |finalizar todas las sesiones de todos los usuarios a excepción de la actual.'");
	
	Buttons = New ValueList;
	Buttons.Add("ActiveUsers", NStr("ru = 'Активные пользователи'; en = 'Active users'; pl = 'Aktywni użytkownicy';de = 'Aktive Benutzer';ro = 'Utilizatori activi';tr = 'Aktif kullanıcılar'; es_ES = 'Usuarios activos'"));
	Buttons.Add(DialogReturnCode.Cancel);
	
	Handler = New NotifyDescription("AfterDisplayWarning", ThisObject);
	ShowQueryBox(Handler, QuestionText, Buttons,, "ActiveUsers");
	
EndProcedure

Procedure AfterDisplayWarning(Response, ExecutionParameters) Export
	
	If Response = "ActiveUsers" Then
		StandardSubsystemsClient.OpenActiveUserList();
	EndIf
	
EndProcedure

#EndRegion