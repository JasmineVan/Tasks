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

Var ExternalUserGroupPreviousComposition; // External user group content before changes to use in OnWrite event handler.
                                              // 
                                              // 

Var ExternalUserGroupPreviousRolesComposition; // External users group roles content before changes, to be used in OnWrite event handler.
                                                   // 
                                                   // 

Var AllAuthorizationObjectsPreviousValue; // AllAuthorizationObjects attribute value before change to use in OnWrite event handler.
                                           // 
                                           // 

Var IsNew; // Shows whether a new object was written.
                // Used in OnWrite event handler.

#EndRegion

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If AdditionalProperties.Property("VerifiedObjectAttributes") Then
		VerifiedObjectAttributes = AdditionalProperties.VerifiedObjectAttributes;
	Else
		VerifiedObjectAttributes = New Array;
	EndIf;
	
	Errors = Undefined;
	
	// Checking the parent.
	ErrorText = ParentCheckErrorText();
	If ValueIsFilled(ErrorText) Then
		CommonClientServer.AddUserError(Errors,
			"Object.Parent", ErrorText, "");
	EndIf;
	
	// Checking for unfilled and duplicate external users.
	VerifiedObjectAttributes.Add("Content.ExternalUser");
	
	// Checking the group purpose.
	ErrorText = PurposeCheckErrorText();
	If ValueIsFilled(ErrorText) Then
		CommonClientServer.AddUserError(Errors,
			"Object.Purpose", ErrorText, "");
	EndIf;
	VerifiedObjectAttributes.Add("Purpose");
	
	For each CurrentRow In Content Do
		RowNumber = Content.IndexOf(CurrentRow);
		
		// Checking whether the value is filled.
		If NOT ValueIsFilled(CurrentRow.ExternalUser) Then
			CommonClientServer.AddUserError(Errors,
				"Object.Content[%1].ExternalUser",
				NStr("ru = 'Внешний пользователь не выбран.'; en = 'The external user is not specified.'; pl = 'Użytkownik zewnętrzny nie jest wybrany.';de = 'Externer Benutzer ist nicht ausgewählt.';ro = 'Utilizator extern nu este selectat.';tr = 'Harici kullanıcı seçilmedi.'; es_ES = 'Usuario externo no está seleccionado.'"),
				"Object.Content",
				RowNumber,
				NStr("ru = 'Внешний пользователь в строке %1 не выбран.'; en = 'The external user is not specified in line #%1.'; pl = 'Użytkownik zewnętrzny w wierszu %1 nie został wybrany.';de = 'Externer Benutzer in Zeile %1 wurde nicht ausgewählt.';ro = 'Utilizatorul extern în rândul %1 nu a fost selectat.';tr = '%1Satırında harici kullanıcı seçilmedi.'; es_ES = 'Usuario externo en la línea %1 no se ha seleccionado.'"));
			Continue;
		EndIf;
		
		// Checking for duplicate values.
		FoundValues = Content.FindRows(New Structure("ExternalUser", CurrentRow.ExternalUser));
		If FoundValues.Count() > 1 Then
			CommonClientServer.AddUserError(Errors,
				"Object.Content[%1].ExternalUser",
				NStr("ru = 'Внешний пользователь повторяется.'; en = 'Duplicate external user.'; pl = 'Użytkownik zewnętrzny powtarza się.';de = 'Externer Benutzer wird wiederholt.';ro = 'Utilizatorul extern se repetă.';tr = 'Harici kullanıcı tekrarlandı.'; es_ES = 'Usuario externo está repetido.'"),
				"Object.Content",
				RowNumber,
				NStr("ru = 'Внешний пользователь в строке %1 повторяется.'; en = 'Duplicate external user in line #%1.'; pl = 'Użytkownik zewnętrzny w wierszu %1 powtarza się.';de = 'Externer Benutzer in der Zeile %1 wird wiederholt.';ro = 'Utilizatorul extern în rândul %1 se repetă.';tr = '%1Satırında harici kullanıcı tekrarlandı.'; es_ES = 'Usuario externo en la línea %1 está repetido.'"));
		EndIf;
	EndDo;
	
	CommonClientServer.ReportErrorsToUser(Errors, Cancel);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, VerifiedObjectAttributes);
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If NOT UsersInternal.CannotEditRoles() Then
		QueryResult = Common.ObjectAttributeValue(Ref, "Roles");
		If TypeOf(QueryResult) = Type("QueryResult") Then
			ExternalUserGroupPreviousRolesComposition = QueryResult.Unload();
		Else
			ExternalUserGroupPreviousRolesComposition = Roles.Unload(New Array);
		EndIf;
	EndIf;
	
	IsNew = IsNew();
	
	If Ref = Catalogs.ExternalUsersGroups.AllExternalUsers Then
		FillPurposeWithAllExternalUsersTypes();
		AllAuthorizationObjects  = False;
	EndIf;
	
	ErrorText = ParentCheckErrorText();
	If ValueIsFilled(ErrorText) Then
		Raise ErrorText;
	EndIf;
	
	If Ref = Catalogs.ExternalUsersGroups.AllExternalUsers Then
		If Content.Count() > 0 Then
			Raise
				NStr("ru = 'Добавление участников в предопределенную группу ""Все внешние пользователи"" запрещено.'; en = 'Cannot add members to the predefined group ""All external users.""'; pl = 'Dodawanie uczestników do wcześniej zdefiniowanej grupy ""Wszyscy użytkownicy zewnętrzni"" jest zabronione.';de = 'Das Hinzufügen von Teilnehmern zur vordefinierten Gruppe ""Alle externen Benutzer"" ist verboten.';ro = 'Adăugarea participanților în grupul predefinit ""Toți utilizatorii externi"" este interzisă.';tr = 'Önceden belirlenen ""Tüm harici kullanıcılar"" grubuna yeni üyelerin eklenmesi yasaktır.'; es_ES = 'Añadir participantes al grupo predefinido ""Todos usuarios externos"" está prohibido.'");
		EndIf;
	Else
		ErrorText = PurposeCheckErrorText();
		If ValueIsFilled(ErrorText) Then
			Raise ErrorText;
		EndIf;
		
		PreviousValues = Common.ObjectAttributesValues(
			Ref, "AllAuthorizationObjects, Parent");
		
		PreviousParent                      = PreviousValues.Parent;
		AllAuthorizationObjectsPreviousValue = PreviousValues.AllAuthorizationObjects;
		
		If ValueIsFilled(Ref)
		   AND Ref <> Catalogs.ExternalUsersGroups.AllExternalUsers Then
			
			QueryResult = Common.ObjectAttributeValue(Ref, "Content");
			If TypeOf(QueryResult) = Type("QueryResult") Then
				ExternalUserGroupPreviousComposition = QueryResult.Unload();
			Else
				ExternalUserGroupPreviousComposition = Content.Unload(New Array);
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If UsersInternal.CannotEditRoles() Then
		IsExternalUserGroupRoleCompositionChanged = False;
		
	Else
		IsExternalUserGroupRoleCompositionChanged =
			UsersInternal.ColumnValueDifferences(
				"Role",
				Roles.Unload(),
				ExternalUserGroupPreviousRolesComposition).Count() <> 0;
	EndIf;
	
	ItemsToChange = New Map;
	ModifiedGroups   = New Map;
	
	If Ref <> Catalogs.ExternalUsersGroups.AllExternalUsers Then
		
		If AllAuthorizationObjects
		 OR AllAuthorizationObjectsPreviousValue = True Then
			
			UsersInternal.UpdateExternalUserGroupCompositions(
				Ref, , ItemsToChange, ModifiedGroups);
		Else
			CompositionChanges = UsersInternal.ColumnValueDifferences(
				"ExternalUser",
				Content.Unload(),
				ExternalUserGroupPreviousComposition);
			
			UsersInternal.UpdateExternalUserGroupCompositions(
				Ref, CompositionChanges, ItemsToChange, ModifiedGroups);
			
			If PreviousParent <> Parent Then
				
				If ValueIsFilled(Parent) Then
					UsersInternal.UpdateExternalUserGroupCompositions(
						Parent, , ItemsToChange, ModifiedGroups);
				EndIf;
				
				If ValueIsFilled(PreviousParent) Then
					UsersInternal.UpdateExternalUserGroupCompositions(
						PreviousParent, , ItemsToChange, ModifiedGroups);
				EndIf;
			EndIf;
		EndIf;
		
		UsersInternal.UpdateUserGroupCompositionUsage(
			Ref, ItemsToChange, ModifiedGroups);
	EndIf;
	
	If IsExternalUserGroupRoleCompositionChanged Then
		UsersInternal.UpdateExternalUsersRoles(Ref);
	EndIf;
	
	UsersInternal.AfterUpdateExternalUserGroupCompositions(
		ItemsToChange, ModifiedGroups);
	
	SSLSubsystemsIntegration.AfterAddChangeUserOrGroup(Ref, IsNew);
	
EndProcedure

#EndRegion

#Region Private

Procedure FillPurposeWithAllExternalUsersTypes()
	
	Purpose.Clear();
	
	BlankRefs = UsersInternalCached.BlankRefsOfAuthorizationObjectTypes();
	For Each EmptyRef In BlankRefs Do
		NewRow = Purpose.Add();
		NewRow.UsersType = EmptyRef;
	EndDo;
	
EndProcedure

Function ParentCheckErrorText()
	
	If Parent = Catalogs.ExternalUsersGroups.AllExternalUsers Then
		Return
			NStr("ru = 'Предопределенная группа ""Все внешние пользователи"" не может быть родителем.'; en = 'Cannot use the predefined group ""All external users"" as a parent.'; pl = 'Wstępnie zdefiniowana grupa ""Wszyscy użytkownicy zewnętrzni"" nie może być grupą nadrzędną.';de = 'Die vordefinierte Gruppe ""Alle externen Benutzer"" darf keine übergeordnete Gruppe sein.';ro = 'Grupul predefinit ""Toți utilizatorii externi"" nu poate fi un grup părinte.';tr = 'Önceden belirlenen ""Tüm harici kullanıcılar"" grubu ana grup olamaz.'; es_ES = 'Grupo predefinido ""Todos usuarios externos"" no puede ser un grupo original.'");
	EndIf;
	
	If Ref = Catalogs.ExternalUsersGroups.AllExternalUsers Then
		If Not Parent.IsEmpty() Then
			Return
				NStr("ru = 'Предопределенная группа ""Все внешние пользователи"" не может быть перемещена.'; en = 'Cannot move the predefined group ""All external users.""'; pl = 'Predefiniowana grupa ""Wszyscy użytkownicy zewnętrzni"" nie może zostać przeniesiona.';de = 'Vordefinierte Gruppe ""Alle externen Benutzer"" kann nicht verschoben werden.';ro = 'Grupul predefinit ""Toți utilizatorii externi"" nu poate fi mutat.';tr = 'Önceden belirlenen ""Tüm harici kullanıcılar"" grubu taşınamaz.'; es_ES = 'Grupo predefinido ""Todos usuarios externos"" no puede moverse.'");
		EndIf;
	Else
		If Parent = Catalogs.ExternalUsersGroups.AllExternalUsers Then
			Return
				NStr("ru = 'Невозможно добавить подгруппу к предопределенной группе ""Все внешние пользователи"".'; en = 'Cannot add a subgroup to the predefined group ""All external users.""'; pl = 'Nie można dodać podgrupy do wstępnie zdefiniowanej grupy ""Wszyscy użytkownicy zewnętrzni"".';de = 'Die Untergruppe kann der vordefinierten Gruppe ""Alle externen Benutzer"" nicht hinzugefügt werden.';ro = 'Subgrupul nu poate fi adăugat la grupul predefinit ""Toți utilizatorii externi"".';tr = 'Önceden belirlenen ""Tüm harici kullanıcılar"" grubuna alt grubun eklenmesi yasaktır.'; es_ES = 'No se puede añadir un subgrupo al grupo predefinido ""Todos usuarios externos"".'");
			
		ElsIf Parent.AllAuthorizationObjects Then
			Return StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Невозможно добавить подгруппу к группе ""%1"",
				           |так как в число ее участников входят все пользователи.'; 
				           |en = 'Cannot add a subgroup to the group ""%1""
				           |because it includes all users.'; 
				           |pl = 'Nie można dodać podgrupy do grupy ""%1"",
				           |ponieważ obejmuje ona wszystkich użytkowników.';
				           |de = 'Es ist nicht möglich, eine Untergruppe zur Gruppe ""%1"" hinzuzufügen,
				           |da alle Benutzer Mitglieder dieser Gruppe sind.';
				           |ro = 'Subgrupul nu poate fi adăugat la grupul ""%1"", 
				           |deoarece el include toți utilizatorii.';
				           |tr = '""%1"" grubuna tüm kullanıcılar dahil edildiği için, 
				           |alt grup eklenemez.'; 
				           |es_ES = 'No se puede añadir un subgrupo al grupo ""%1"",
				           |porque este incluye a todos usuarios.'"), Parent);
		EndIf;
		
		If AllAuthorizationObjects AND ValueIsFilled(Parent) Then
			Return
				NStr("ru = 'Невозможно переместить группу, в число участников которой входят все пользователи.'; en = 'Cannot move a group that includes all users.'; pl = 'Nie można przenieść grupy zawierającej wszystkich użytkowników.';de = 'Die Gruppe, die alle Benutzer enthält, kann nicht verschoben werden.';ro = 'Nu puteți muta grupul care include toți utilizatorii.';tr = 'Tüm kullanıcıları içeren grup taşınamaz.'; es_ES = 'No se puede mover el grupo que incluye a todos usuarios.'");
		EndIf;
	EndIf;
	
	Return "";
	
EndFunction

Function PurposeCheckErrorText()
	
	// Checking whether the group purpose is filled.
	If Purpose.Count() = 0 Then
		Return NStr("ru = 'Не указан вид участников группы.'; en = 'The type of group members is not specified.'; pl = 'Nie wskazano rodzaju członków grupy.';de = 'Der Typ der Gruppenmitglieder ist nicht angegeben.';ro = 'Tipul membrilor grupului nu este indicat.';tr = 'Grup üyelerin türü belirtilmedi.'; es_ES = 'El tipo de los participantes del grupo no se ha especificado.'");
	EndIf;
	
	// Checking whether the group of all authorization objects of the specified type is unique.
	If AllAuthorizationObjects Then
		
		// Checking whether the purpose matches the "All external users" group.
		AllExternalUsersGroup = Catalogs.ExternalUsersGroups.AllExternalUsers;
		AllExternalUsersPurpose = Common.ObjectAttributeValue(
			AllExternalUsersGroup, "Purpose").Unload().UnloadColumn("UsersType");
		PurposesArray = Purpose.UnloadColumn("UsersType");
		
		If CommonClientServer.ValueListsAreEqual(AllExternalUsersPurpose, PurposesArray) Then
			Return
				NStr("ru = 'Невозможно создать группу, совпадающую по назначению
				           |с предопределенной группой ""Все внешние пользователи"".'; 
				           |en = 'Cannot create a group having the same purpose
				           | as the predefined group ""All external users.""'; 
				           |pl = 'Nie można utworzyć grupy o tym samym celu,
				           | co wstępnie zdefiniowana grupa ""Wszyscy użytkownicy zewnętrzni"".';
				           |de = 'Es ist nicht möglich, eine Gruppe zu erstellen,
				           |die mit der vordefinierten Gruppe ""Alle externen Benutzer"" übereinstimmt.';
				           |ro = 'Nu puteți crea grupul care coincide după destinație
				           |cu grupul predefinit ""Toți utilizatorii externi"".';
				           |tr = 'Amacı, önceden belirlenmiş ""Tüm harici kullanıcılar"" grubu 
				           |ile aynı olan grup yaratılamaz.'; 
				           |es_ES = 'Es imposible crear un grupo que coincide por el valor
				           |con el grupo predeterminado ""Todos los usuarios externos"".'");
		EndIf;
		
		Query = New Query;
		Query.SetParameter("Ref", Ref);
		Query.SetParameter("UsersTypes", Purpose.Unload());
		
		Query.Text =
		"SELECT
		|	UsersTypes.UsersType
		|INTO UsersTypes
		|FROM
		|	&UsersTypes AS UsersTypes
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	PRESENTATION(ExternalUsersGroups.Ref) AS RefPresentation
		|FROM
		|	Catalog.ExternalUsersGroups.Purpose AS ExternalUsersGroups
		|WHERE
		|	TRUE IN
		|			(SELECT TOP 1
		|				TRUE
		|			FROM
		|				UsersTypes AS UsersTypes
		|			WHERE
		|				ExternalUsersGroups.Ref <> &Ref
		|				AND ExternalUsersGroups.Ref.AllAuthorizationObjects
		|				AND VALUETYPE(UsersTypes.UsersType) = VALUETYPE(ExternalUsersGroups.UsersType))";
		
		QueryResult = Query.Execute();
		If NOT QueryResult.IsEmpty() Then
		
			Selection = QueryResult.Select();
			Selection.Next();
			
			Return StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Уже существует группа ""%1"",
				           |в число участников которой входят все пользователи указанных видов.'; 
				           |en = 'An existing group ""%1""
				           | includes all users of the specified types.'; 
				           |pl = 'Grupa ""%1"", 
				           |do której należą wszyscy użytkownicy wskazanych rodzajów, już istnieje.';
				           |de = 'Es gibt bereits eine Gruppe von ""%1"",
				           |zu deren Mitgliedern alle Benutzer dieses Typs gehören.';
				           |ro = 'Deja există grupul ""%1"" 
				           |care include toți utilizatorii de tipurile indicate.';
				           |tr = '""%1"" grup zaten var ve 
				           | belirtilen türünden tüm kullanıcıları içermektedir.'; 
				           |es_ES = 'El grupo ""%1"" ya existe e
				           |incluye a todos usuarios del tipo.'"),
				Selection.RefPresentation);
		EndIf;
	EndIf;
	
	// Checking whether authorization object type is equal to the parent type (Undefined parent type is 
	// allowed).
	If ValueIsFilled(Parent) Then
		
		ParentUsersType = Common.ObjectAttributeValue(
			Parent, "Purpose").Unload().UnloadColumn("UsersType");
		UsersType = Purpose.UnloadColumn("UsersType");
		
		For Each UserType In UsersType Do
			If ParentUsersType.Find(UserType) = Undefined Then
				Return StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Вид участников группы должен быть как у вышестоящей
					           |группы внешних пользователей ""%1"".'; 
					           |en = 'The group members type must be identical to the members type
					           |of the parent external user group ""%1.""'; 
					           |pl = 'Rodzaj członków grupy powinien być taki sam, jak w wyższej
					           |grupie użytkowników zewnętrznych ""%1"".';
					           |de = 'Die Ansicht der Gruppenmitglieder sollte die gleiche sein wie die der übergeordneten
					           |Gruppe der externen Benutzer ""%1"".';
					           |ro = 'Tipul de participanți ai grupului trebuie să fie ca la grupul
					           |superior de utilizatori externi ""%1"".';
					           |tr = '""%1"" Grup üyelerinin türü, "
" harici kullanıcı grubundaki gibi olmalıdır.'; 
					           |es_ES = 'El tipo de los participantes del grupo debe ser como para el grupo superior
					           | de los usuarios externos ""%1"".'"), Parent);
			EndIf;
		EndDo;
	EndIf;
	
	// Checking whether the external user group has subordinate groups (if its member type is set to 
	// "All users with specified type").
	If AllAuthorizationObjects
		AND ValueIsFilled(Ref) Then
		Query = New Query;
		Query.SetParameter("Ref", Ref);
		Query.Text =
		"SELECT
		|	PRESENTATION(ExternalUsersGroups.Ref) AS RefPresentation
		|FROM
		|	Catalog.ExternalUsersGroups AS ExternalUsersGroups
		|WHERE
		|	ExternalUsersGroups.Parent = &Ref";
		
		QueryResult = Query.Execute();
		If NOT QueryResult.IsEmpty() Then
			Return
				NStr("ru = 'Невозможно изменить вид участников группы,
				           |так как у нее имеются подгруппы.'; 
				           |en = 'Cannot change the type of group 
				           | members as the group contains subgroups.'; 
				           |pl = 'Nie można zmienić rodzaju uczestników grupy,
				           |ponieważ ma ona podgrupy.';
				           |de = 'Es ist nicht möglich, das Erscheinungsbild der Gruppenmitglieder zu ändern,
				           |da es Untergruppen gibt.';
				           |ro = 'Nu puteți modificat tipul de membri ai grupului,
				           |deoarece el are subgrupe.';
				           |tr = '"
" grubu alt gruplara sahip olduğundan dolayı katılımcıların türü değiştirilemez.'; 
				           |es_ES = 'No se puede cambiar un tipo de participantes del grupo
				           |porque tiene subgrupos.'");
		EndIf;
	EndIf;
	
	// Checking whether no subordinate items with another type are available before changing 
	// authorization object type (so that type can be cleared).
	If ValueIsFilled(Ref) Then
		
		Query = New Query;
		Query.SetParameter("Ref", Ref);
		Query.SetParameter("UsersTypes", Purpose);
		Query.Text =
		"SELECT
		|	UsersTypes.UsersType
		|INTO UsersTypes
		|FROM
		|	&UsersTypes AS UsersTypes
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	PRESENTATION(ExternalUserGroupsAssignment.Ref) AS RefPresentation
		|FROM
		|	Catalog.ExternalUsersGroups.Purpose AS ExternalUserGroupsAssignment
		|WHERE
		|	TRUE IN
		|			(SELECT TOP 1
		|				TRUE
		|			FROM
		|				UsersTypes AS UsersTypes
		|			WHERE
		|				ExternalUserGroupsAssignment.Ref.Parent = &Ref
		|				AND VALUETYPE(ExternalUserGroupsAssignment.UsersType) <> VALUETYPE(UsersTypes.UsersType))";
		
		QueryResult = Query.Execute();
		If NOT QueryResult.IsEmpty() Then
			
			Selection = QueryResult.Select();
			Selection.Next();
			
			Return StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Невозможно изменить вид участников группы,
				           |так как у нее имеется подгруппа ""%1"" с другим назначением участников.'; 
				           |en = 'Cannot change the type of group members
				           |as the group contains the subgroup ""%1"" with different member types.'; 
				           |pl = 'Zmiana rodzaju członków grupy nie jest możliwa,
				           |ponieważ posiada ona podgrupę ""%1"" z innym przydziałem członków.';
				           |de = 'Es ist nicht möglich, das Erscheinungsbild von Gruppenmitgliedern zu ändern,
				           |da sie eine Untergruppe ""%1"" mit einer anderen Teilnehmerzuordnung hat.';
				           |ro = 'Nu puteți modificat tipul de membri ai grupului,
				           |deoarece el are subgrupul ""%1"" cu altă destinație a participanților.';
				           |tr = 'Başka bir katılımcı atamasına sahip bir "
" alt grubuna sahip olduğu için %1grup üyelerinin türü değiştirilemez.'; 
				           |es_ES = 'Es necesario cambiar el tipo de los participantes del grupo
				           |porque tiene un subgrupo ""%1"" con otra asignación de usuarios.'"),
				Selection.RefPresentation);
		EndIf;
	EndIf;
	
	Return "";
	
EndFunction

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Niedozwolone wezwanie obiektu na kliencie.';de = 'Unzulässiger Objektaufruf auf dem Client.';ro = 'Apel inadmisibil al obiectului pe client.';tr = 'İstemcide kabul edilmeyen nesne çağrısı.'; es_ES = 'Llamada no disponible del objeto en el cliente.'");
#EndIf