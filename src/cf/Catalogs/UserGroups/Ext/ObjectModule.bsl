///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var PreviousParent; // Value of the group parent before changes, to be used in OnWrite event handler.
                      // 

Var PreviousUserGroupComposition; // User group content (list of users) before changes, to be used in OnWrite event handler.
                                       // 
                                       // 

Var IsNew; // Shows whether a new object was written.
                // Used in OnWrite event handler.

#EndRegion

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	VerifiedObjectAttributes = New Array;
	Errors = Undefined;
	
	// Checking the parent.
	If Parent = Catalogs.UserGroups.AllUsers Then
		CommonClientServer.AddUserError(Errors,
			"Object.Parent",
			NStr("ru = 'Предопределенная группа ""Все пользователи"" не может быть родителем.'; en = 'Cannot use the predefined group ""All users"" as a parent.'; pl = 'Wstępnie zdefiniowana grupa ""Wszyscy użytkownicy"" nie może być grupą nadrzędną.';de = 'Die vordefinierte Gruppe ""Alle Benutzer"" darf keine übergeordnete Gruppe sein.';ro = 'Grupul predefinit ""Toți utilizatorii"" nu poate fi un grup părinte.';tr = 'Ön tanımlı ""Tüm kullanıcılar"" grubu ana grup olamaz.'; es_ES = 'Grupo predefinido ""Todos usuarios"" no puede ser el grupo original.'"),
			"");
	EndIf;
	
	// Checking for unfilled and duplicate users.
	VerifiedObjectAttributes.Add("Content.User");
	
	For each CurrentRow In Content Do;
		RowNumber = Content.IndexOf(CurrentRow);
		
		// Checking whether the value is filled.
		If NOT ValueIsFilled(CurrentRow.User) Then
			CommonClientServer.AddUserError(Errors,
				"Object.Content[%1].User",
				NStr("ru = 'Пользователь не выбран.'; en = 'User is not selected.'; pl = 'Użytkownik nie jest wybrany.';de = 'Benutzer ist nicht ausgewählt.';ro = 'Utilizatorul nu este selectat.';tr = 'Kullanıcı seçilmedi.'; es_ES = 'Usuario no seleccionado.'"),
				"Object.Content",
				RowNumber,
				NStr("ru = 'Пользователь в строке %1 не выбран.'; en = 'User is not selected in line #%1.'; pl = 'W wierszu %1 nie wybrano użytkownika.';de = 'Benutzer in Zeile %1 ist nicht ausgewählt.';ro = 'Utilizatorul din rândul %1 nu este selectat.';tr = '%1 satırındaki kullanıcı seçilmedi.'; es_ES = 'Usuario en la línea %1 no está seleccionado.'"));
			Continue;
		EndIf;
		
		// Checking for duplicate values.
		FoundValues = Content.FindRows(New Structure("User", CurrentRow.User));
		If FoundValues.Count() > 1 Then
			CommonClientServer.AddUserError(Errors,
				"Object.Content[%1].User",
				NStr("ru = 'Пользователь повторяется.'; en = 'Duplicate user.'; pl = 'Użytkownik powtarza się.';de = 'Benutzer wird wiederholt.';ro = 'Utilizatorul se repetă.';tr = 'Kullanıcı tekrarlandı.'; es_ES = 'Usuario repetido.'"),
				"Object.Content",
				RowNumber,
				NStr("ru = 'Пользователь в строке %1 повторяется.'; en = 'Duplicate user in line #%1.'; pl = 'Użytkownik w wierszu %1 powtarza się.';de = 'Benutzer in Zeile%1 wird wiederholt.';ro = 'Utilizatorul din rândul %1 se repetă.';tr = '%1Satırdaki kullanıcı tekrarlandı.'; es_ES = 'Usuario en la línea %1 está repetido.'"));
		EndIf;
	EndDo;
	
	CommonClientServer.ReportErrorsToUser(Errors, Cancel);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, VerifiedObjectAttributes);
	
EndProcedure

// Cancels actions that cannot be performed on the "All users" group.
Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	IsNew = IsNew();
	
	If Ref = Catalogs.UserGroups.AllUsers Then
		If NOT Parent.IsEmpty() Then
			Raise
				NStr("ru = 'Предопределенная группа ""Все пользователи""
				           |может быть только в корне.'; 
				           |en = 'The position of the predefined group ""All users"" cannot be changed.
				           |It is the root of the group tree.'; 
				           |pl = 'Predefiniowana grupa ""Wszyscy użytkownicy""
				           |może znajdować się tylko w katalogu głównym.';
				           |de = 'Die vordefinierte Gruppe ""Alle Benutzer""
				           |kann nur im Stammverzeichnis sein.';
				           |ro = 'Grupul predefinit ""Toți utilizatorii"" 
				           |poate fi doar în rădăcină.';
				           |tr = 'Ön tanımlı ""Tüm kullanıcılar"" grubu 
				           |sadece kökte olabilir.'; 
				           |es_ES = 'Grupo predefinido ""Todos los usuarios""
				           |puede estar solo en la raíz.'");
		EndIf;
		If Content.Count() > 0 Then
			Raise
				NStr("ru = 'Добавление пользователей в группу
				           |""Все пользователи"" не поддерживается.'; 
				           |en = 'Cannot add users to group
				           |""All users.""'; 
				           |pl = 'Dodawanie użytkowników do folderu
				           |""Wszyscy użytkownicy"" nie jest obsługiwane.';
				           |de = 'Das Hinzufügen von Benutzern zur Gruppe
				           |""Alle Benutzer"" wird nicht unterstützt.';
				           |ro = 'Adăugarea utilizatorilor în grupul
				           |""Toți utilizatorii"" nu este susținută.';
				           |tr = 'Kullanıcıların ""Tüm kullanıcılar"" 
				           |klasörüne ekleme işlemi desteklenmiyor.'; 
				           |es_ES = 'Añadir los usuarios en el grupo
				           |""Todos los usuarios"" no se admite.'");
		EndIf;
	Else
		If Parent = Catalogs.UserGroups.AllUsers Then
			Raise
				NStr("ru = 'Предопределенная группа ""Все пользователи""
				           |не может быть родителем.'; 
				           |en = 'Cannot use the predefined group ""All users""
				           |as a parent.'; 
				           |pl = 'Wstępnie zdefiniowana grupa ""Wszyscy użytkownicy""
				           |nie może być grupą nadrzędną.';
				           |de = 'Die vordefinierte Gruppe ""Alle Benutzer""
				           |kann nicht übergeordnet sein.';
				           |ro = 'Grupul predefinit ""Toți utilizatorii"" 
				           |nu poate fi părinte.';
				           |tr = 'Ön tanımlı ""Tüm kullanıcılar"" 
				           |grubu ana grup olamaz.'; 
				           |es_ES = 'El grupo predeterminado ""Todos los usuarios""
				           |no puede ser padre.'");
		EndIf;
		
		PreviousParent = ?(
			Ref.IsEmpty(),
			Undefined,
			Common.ObjectAttributeValue(Ref, "Parent"));
			
		If ValueIsFilled(Ref)
		   AND Ref <> Catalogs.UserGroups.AllUsers Then
			
			PreviousUserGroupComposition =
				Common.ObjectAttributeValue(Ref, "Content").Unload();
		EndIf;
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	ItemsToChange = New Map;
	ModifiedGroups   = New Map;
	
	If Ref <> Catalogs.UserGroups.AllUsers Then
		
		CompositionChanges = UsersInternal.ColumnValueDifferences(
			"User",
			Content.Unload(),
			PreviousUserGroupComposition);
		
		UsersInternal.UpdateUserGroupComposition(
			Ref, CompositionChanges, ItemsToChange, ModifiedGroups);
		
		If PreviousParent <> Parent Then
			
			If ValueIsFilled(Parent) Then
				UsersInternal.UpdateUserGroupComposition(
					Parent, , ItemsToChange, ModifiedGroups);
			EndIf;
			
			If ValueIsFilled(PreviousParent) Then
				UsersInternal.UpdateUserGroupComposition(
					PreviousParent, , ItemsToChange, ModifiedGroups);
			EndIf;
		EndIf;
		
		UsersInternal.UpdateUserGroupCompositionUsage(
			Ref, ItemsToChange, ModifiedGroups);
		
		If Not Users.IsFullUser() Then
			CheckChangeCompositionRight(CompositionChanges);
		EndIf;
	EndIf;
	
	UsersInternal.AfterUserGroupsUpdate(
		ItemsToChange, ModifiedGroups);
	
	SSLSubsystemsIntegration.AfterAddChangeUserOrGroup(Ref, IsNew);
	
EndProcedure

#EndRegion

#Region Private

Procedure CheckChangeCompositionRight(CompositionChanges)
	
	Query = New Query;
	Query.SetParameter("Users", CompositionChanges);
	Query.Text =
	"SELECT
	|	Users.Description AS Description
	|FROM
	|	Catalog.Users AS Users
	|WHERE
	|	Users.Ref IN(&Users)
	|	AND NOT Users.Prepared";
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	ErrorText =
		NStr("ru = 'Недостаточно прав доступа.
		           |
		           |В состав участников групп пользователей можно добавлять и удалять только
		           |новых (добавленных) пользователей, у которых включен признак Подготовлен.
		           |
		           |Запрещено добавлять и удалять существующих пользователей:'; 
		           |en = 'Insufficient access rights.
		           |
		           |Only new (added) users marked as ""Requires approval"" can be added to or removed from
		           |the list of group members.
		           |
		           |You cannot add or remove the following users:'; 
		           |pl = 'Niewystarczające prawa dostępu.
		           |
		           |Tylko nowych (dodanych) użytkowników oznaczonych jako ""Wymaga zatwierdzenia"" można dodać lub
		           |usunąć z listy członków grupy.
		           |
		           |Nie można dodawać ani usuwać następujących użytkowników:';
		           |de = 'Nicht genügend Zugriffsrechte.
		           |
		           |Sie können nur
		           |neue (hinzugefügte) Benutzer hinzufügen und löschen, wenn das Attribut Vorbereitet für die Teilnehmer von Benutzergruppen aktiviert ist.
		           |
		           |Es ist verboten, bestehende Benutzer hinzuzufügen oder zu löschen:';
		           |ro = 'Drepturi de acces insuficiente.
		           |
		           |În componența grupurilor de utilizatori puteți adăuga și șterge numai
		           |utilizatorii noi (adăugați), la care este activat indicele Pregătit.
		           |
		           |Este interzisă adăugarea și ștergerea utilizatorilor existenți:';
		           |tr = 'Yeterli erişim izni yok. 
		           |
		           |Kullanıcı grubu katılımcılarına yalnızca 
		           |yeni (eklenen) kullanıcıları ekleyebilir ve silebilirsiniz. 
		           |
		           |Mevcut kullanıcıları eklemek veya kaldırmak yasaktır:'; 
		           |es_ES = 'Insuficientes derechos de acceso.
		           |
		           |En el conjunto de los participantes de los grupos de usuarios se puede añadir y eliminar solo
		           |los usuarios nuevos (añadidos) que tienen el atributo Preparado activado.
		           |
		           |Está prohibido añadir y eliminar los usuarios existentes:'");
	
	Selection = QueryResult.Select();
	While Selection.Next() Do
		ErrorText = ErrorText + Chars.LF + Selection.Description;
	EndDo;
	
	Raise ErrorText;
	
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Niedozwolone wezwanie obiektu na kliencie.';de = 'Unzulässiger Objektaufruf auf dem Client.';ro = 'Apel inadmisibil al obiectului pe client.';tr = 'İstemcide kabul edilmeyen nesne çağrısı.'; es_ES = 'Llamada no disponible del objeto en el cliente.'");
#EndIf