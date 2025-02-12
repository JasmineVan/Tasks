﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// Determines the profile assignment.
//
// Parameters:
//  Profile - CatalogObject.AccessGroupsProfiles - a profile with the Assignment tabular section.
//          - FormDataStructure - a profile object structure in the form.
//          - Structure, FixedStructure - supplied profile description.
//
// Returns:
//  String - "ForAdministrators", "ForUsers", "ForExternalUsers",
//           "BothForUsersAndExternalUsers".
//
Function ProfileAssignment(Profile) Export
	
	AssignmentForUsers = False;
	AssignmentForExternalUsers = False;
	
	For Each AssignmentDetails In Profile.Purpose Do
		If TypeOf(Profile.Purpose) = Type("Array")
		 Or TypeOf(Profile.Purpose) = Type("FixedArray") Then
			Type = TypeOf(AssignmentDetails);
		Else
			Type = TypeOf(AssignmentDetails.UsersType);
		EndIf;
		If Type = Type("CatalogRef.Users") Then
			AssignmentForUsers = True;
		EndIf;
		If Type <> Type("CatalogRef.Users") AND Type <> Undefined Then
			AssignmentForExternalUsers = True;
		EndIf;
	EndDo;
	
	If AssignmentForUsers AND AssignmentForExternalUsers Then
		Return "BothForUsersAndExternalUsers";
		
	ElsIf AssignmentForExternalUsers Then
		Return "ForExternalUsers";
	EndIf;
	
	Return "ForAdministrators";
	
EndFunction

// Checks whether the access kind matches the profile assignment.
//
// Parameters:
//  AccessKind - String, Ref - access kind description.
//  ProfileAssignment - String - returned by the ProfileAssignment function.
//
Function AccessKindMatchesProfileAssignment(Val AccessKind, ProfileAssignment) Export
	
	If AccessKind = "Users"
	 Or TypeOf(AccessKind) = Type("CatalogRef.Users") Then
		
		Return ProfileAssignment <> "BothForUsersAndExternalUsers"
		      AND ProfileAssignment <> "ForExternalUsers";
		
	ElsIf AccessKind = "ExternalUsers"
	      Or TypeOf(AccessKind) = Type("CatalogRef.ExternalUsers") Then
		
		Return ProfileAssignment = "ForExternalUsers";
	EndIf;
	
	Return True;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Management of AccessKinds and AccessValues tables in edit forms.

// For internal use only.
Procedure FillAllAllowedPresentation(Form, AccessKindDetails, AddValuesCount = True) Export
	
	Parameters = AllowedValuesEditFormParameters(Form);
	
	If AccessKindDetails.AllAllowed Then
		If Form.IsAccessGroupProfile AND NOT AccessKindDetails.PresetAccessKind Then
			Name = "AllAllowedByDefault";
		Else
			Name = "AllAllowed";
		EndIf;
	Else
		If Form.IsAccessGroupProfile AND NOT AccessKindDetails.PresetAccessKind Then
			Name = "AllDeniedByDefault";
		Else
			Name = "AllDenied";
		EndIf;
	EndIf;
	
	AccessKindDetails.AllAllowedPresentation =
		Form.PresentationsAllAllowed.FindRows(New Structure("Name", Name))[0].Presentation;
	
	If NOT AddValuesCount Then
		Return;
	EndIf;
	
	If Form.IsAccessGroupProfile AND NOT AccessKindDetails.PresetAccessKind Then
		Return;
	EndIf;
	
	Filter = FilterInAllowedValuesEditFormTables(Form, AccessKindDetails.AccessKind);
	
	ValuesCount = Parameters.AccessValues.FindRows(Filter).Count();
	
	If Form.IsAccessGroupProfile Then
		If ValuesCount = 0 Then
			NumberAndSubject = NStr("ru = 'не назначены'; en = 'not assigned'; pl = 'nie przypisane';de = 'nicht zugewiesen';ro = 'nu atribuie';tr = 'atanmadı'; es_ES = 'no asignado'");
		Else
			NumberAndSubject = Format(ValuesCount, "NG=") + " "
				+ UsersInternalClientServer.IntegerSubject(ValuesCount,
					"", NStr("ru = 'значение,значения,значений,,,,,,0'; en = 'value,values,values,,,,,,0'; pl = 'wartość,wartości,wartości,,,,,,0';de = 'Wert,Werte,Werte,,,,,,0';ro = 'valoarea,valorile,valorile,,,,,,0';tr = 'değer, değerler, değerler,,,,,,0'; es_ES = 'valor,del valor,de los valores,,,,,,0'"));
		EndIf;
		
		AccessKindDetails.AllAllowedPresentation =
			AccessKindDetails.AllAllowedPresentation
				+ " (" + NumberAndSubject + ")";
		Return;
	EndIf;
	
	If ValuesCount = 0 Then
		Presentation = ?(AccessKindDetails.AllAllowed,
			NStr("ru = 'Все разрешены, без исключений'; en = 'All allowed, without exceptions'; pl = 'Wszystkie dozwolone bez wyjątków';de = 'Alles ohne Ausnahmen erlaubt';ro = 'Toate permise fără excepții';tr = 'İstisnasız hepsine izin verildi'; es_ES = 'Todo permitido sin excepciones'"),
			NStr("ru = 'Все запрещены, без исключений'; en = 'All denied without exceptions'; pl = 'Wszystkie zabronione bez wyjątków';de = 'Alles ohne Ausnahmen verboten';ro = 'Toate interzise fără excepții';tr = 'İstisnasız hepsi yasak'; es_ES = 'Todo prohibido sin excepciones'"));
	Else
		NumberAndSubject = Format(ValuesCount, "NG=") + " "
			+ UsersInternalClientServer.IntegerSubject(ValuesCount,
				"", NStr("ru = 'значения,значений,значений,,,,,,0'; en = 'values,values,values,,,,,,0'; pl = 'wartości,wartości,wartości,,,,,,0';de = 'Werte,Werte,Werte,,,,,,0';ro = 'valoarea,valorile,valorile,,,,,,0';tr = 'değer, değerler, değerler,,,,,,0'; es_ES = 'del valor,de los valores,de los valores,,,,,,0'"));
		
		Presentation = StringFunctionsClientServer.SubstituteParametersToString(
			?(AccessKindDetails.AllAllowed,
				NStr("ru = 'Все разрешены, кроме %1'; en = 'All allowed, except %1'; pl = 'Wszystkie dozwolone za wyjątkiem %1';de = 'Alles erlaubt außer für %1';ro = 'Toate sunt permise, cu excepția %1';tr = '%1 Hariç hepsine izin verildi'; es_ES = 'Todo permitido excepto a %1'"),
				NStr("ru = 'Все запрещены, кроме %1'; en = 'All denied, except %1'; pl = 'Wszystkie zabronione za wyjątkiem %1';de = 'Alle verboten außer für %1';ro = 'Toate interzise, cu excepția %1';tr = '%1 hariç hepsi yasak'; es_ES = 'Todo prohibido excepto a %1'")),
			NumberAndSubject);
	EndIf;
	
	AccessKindDetails.AllAllowedPresentation = Presentation;
	
EndProcedure

// For internal use only.
Procedure FillNumbersOfAccessValuesRowsByKind(Form, AccessKindDetails) Export
	
	Parameters = AllowedValuesEditFormParameters(Form);
	
	Filter = FilterInAllowedValuesEditFormTables(Form, AccessKindDetails.AccessKind);
	AccessValuesByKind = Parameters.AccessValues.FindRows(Filter);
	
	CurrentNumber = 1;
	For each Row In AccessValuesByKind Do
		Row.RowNumberByKind = CurrentNumber;
		CurrentNumber = CurrentNumber + 1;
	EndDo;
	
EndProcedure

// For internal use only.
Procedure OnChangeCurrentAccessKind(Form, ProcessingAtClient = True) Export
	
	Items = Form.Items;
	Parameters = AllowedValuesEditFormParameters(Form);
	
	CanEditValues = False;
	
	If ProcessingAtClient Then
		CurrentData = Items.AccessKinds.CurrentData;
	Else
		CurrentData = Parameters.AccessKinds.FindByID(
			?(Items.AccessKinds.CurrentRow = Undefined, -1, Items.AccessKinds.CurrentRow));
	EndIf;
	
	If CurrentData <> Undefined Then
		
		If CurrentData.AccessKind <> Undefined
		   AND NOT CurrentData.Used Then
			
			If NOT Items.AccessKindNotUsedText.Visible Then
				Items.AccessKindNotUsedText.Visible = True;
			EndIf;
		Else
			If Items.AccessKindNotUsedText.Visible Then
				Items.AccessKindNotUsedText.Visible = False;
			EndIf;
		EndIf;
		
		Form.CurrentAccessKind = CurrentData.AccessKind;
		
		If NOT Form.IsAccessGroupProfile OR CurrentData.PresetAccessKind Then
			CanEditValues = True;
		EndIf;
		
		If CanEditValues Then
			
			If Form.IsAccessGroupProfile Then
				Items.AccessKindsTypes.CurrentPage = Items.PresetAccessKind;
			EndIf;
			
			// Setting a value filter.
			RefreshRowsFilter = False;
			RowsFilter = Items.AccessValues.RowFilter;
			Filter = FilterInAllowedValuesEditFormTables(Form, CurrentData.AccessKind);
			
			If RowsFilter = Undefined Then
				RefreshRowsFilter = True;
				
			ElsIf Filter.Property("AccessGroup") AND RowsFilter.AccessGroup <> Filter.AccessGroup Then
				RefreshRowsFilter = True;
				
			ElsIf RowsFilter.AccessKind <> Filter.AccessKind
			        AND NOT (RowsFilter.AccessKind = "" AND Filter.AccessKind = Undefined) Then
				
				RefreshRowsFilter = True;
			EndIf;
			
			If RefreshRowsFilter Then
				If CurrentData.AccessKind = Undefined Then
					Filter.AccessKind = "";
				EndIf;
				Items.AccessValues.RowFilter = New FixedStructure(Filter);
			EndIf;
			
		ElsIf Form.IsAccessGroupProfile Then
			Items.AccessKindsTypes.CurrentPage = Items.NormalAccessKind;
		EndIf;
		
		If CurrentData.AccessKind = Form.AccessKindUsers Then
			LabelPattern = ?(CurrentData.AllAllowed,
				NStr("ru = 'Запрещенные значения (%1) - текущий пользователь всегда разрешен'; en = 'Denied values (%1), the current user is always allowed'; pl = 'Wartości zabronione (%1) - bieżący użytkownik jest zawsze dozwolony';de = 'Verbotene Werte (%1) - der aktuelle Benutzer ist immer erlaubt';ro = 'Valori interzise (%1) - utilizatorul curent este întotdeauna permis';tr = 'Yasak değerler (%1) - geçerli kullanıcıya her zaman izin verilir'; es_ES = 'Valores prohibidos (%1) - el usuario actual siempre está permitido'"),
				NStr("ru = 'Разрешенные значения (%1) - текущий пользователь всегда разрешен'; en = 'Allowed values (%1), the current user is always allowed'; pl = 'Dozwolone wartości (%1) - bieżący użytkownik jest zawsze dozwolony';de = 'Erlaubte Werte (%1) - der aktuelle Benutzer ist immer erlaubt';ro = 'Valorile permise (%1) - utilizatorul curent este întotdeauna permis';tr = 'İzin verilen değerler (%1) - geçerli kullanıcıya her zaman izin verilir'; es_ES = 'Valores permitidos (%1) - el usuario actual está siempre permitido'") );
		
		ElsIf CurrentData.AccessKind = Form.AccessKindExternalUsers Then
			LabelPattern = ?(CurrentData.AllAllowed,
				NStr("ru = 'Запрещенные значения (%1) - текущий внешний пользователь всегда разрешен'; en = 'Denied values (%1), the current external user is always allowed'; pl = 'Wartości zabronione (%1) - bieżący użytkownik zewnętrzny jest zawsze dozwolony';de = 'Verbotene Werte (%1) - der aktuelle externe Benutzer ist immer erlaubt';ro = 'Valori interzise (%1) - utilizatorul extern curent este întotdeauna permis ';tr = 'Yasak değerler (%1) - geçerli harici kullanıcıya her zaman izin verilir'; es_ES = 'Valores prohibidos (%1) - el usuario externo actual siempre está permitido'"),
				NStr("ru = 'Разрешенные значения (%1) - текущий внешний пользователь всегда разрешен'; en = 'Allowed values (%1), the current external user is always allowed'; pl = 'Dozwolone wartości (%1) - bieżący użytkownik zewnętrzny jest zawsze dozwolony';de = 'Erlaubte Werte (%1) - der aktuelle externe Benutzer ist immer erlaubt';ro = 'Valorile permise (%1) - utilizatorul extern curent este întotdeauna permis';tr = 'İzin verilen değerler (%1) - geçerli harici kullanıcıya her zaman izin verilir'; es_ES = 'Valores permitidos (%1) - el usuario externo actual siempre está permitido'") );
		Else
			LabelPattern = ?(CurrentData.AllAllowed,
				NStr("ru = 'Запрещенные значения (%1)'; en = 'Denied values (%1)'; pl = 'Wartości zabronione (%1)';de = 'Verbotene Werte (%1)';ro = 'Valori interzise (%1)';tr = 'Yasak değerler (%1)'; es_ES = 'Valores prohibidos (%1)'"),
				NStr("ru = 'Разрешенные значения (%1)'; en = 'Allowed values (%1)'; pl = 'Dozwolone wartości (%1)';de = 'Erlaubte Werte (%1)';ro = 'Valorile permise (%1)';tr = 'İzin verilen değerler (%1)'; es_ES = 'Valores permitidos (%1)'") );
		EndIf;
		
		// Refreshing the AccessKindLabel field
		Form.AccessKindLabel = StringFunctionsClientServer.SubstituteParametersToString(LabelPattern,
			String(CurrentData.AccessTypePresentation));
		
		FillAllAllowedPresentation(Form, CurrentData);
	Else
		If Items.AccessKindNotUsedText.Visible Then
			Items.AccessKindNotUsedText.Visible = False;
		EndIf;
		
		Form.CurrentAccessKind = Undefined;
		Items.AccessValues.RowFilter = New FixedStructure(
			FilterInAllowedValuesEditFormTables(Form, Undefined));
		
		If Parameters.AccessKinds.Count() = 0 Then
			Parameters.AccessValues.Clear();
		EndIf;
	EndIf;
	
	Form.CurrentTypeOfValuesToSelect  = Undefined;
	Form.CurrentTypesOfValuesToSelect = New ValueList;
	
	If CanEditValues Then
		Filter = New Structure("AccessKind", CurrentData.AccessKind);
		AccessKindsTypesDetails = Form.AllTypesOfValuesToSelect.FindRows(Filter);
		For each AccessKindTypeDetails In AccessKindsTypesDetails Do
			
			Form.CurrentTypesOfValuesToSelect.Add(
				AccessKindTypeDetails.ValuesType,
				AccessKindTypeDetails.TypePresentation);
		EndDo;
	Else
		If CurrentData <> Undefined Then
			
			Filter = FilterInAllowedValuesEditFormTables(
				Form, CurrentData.AccessKind);
			
			For each Row In Parameters.AccessValues.FindRows(Filter) Do
				Parameters.AccessValues.Delete(Row);
			EndDo
		EndIf;
	EndIf;
	
	If Form.CurrentTypesOfValuesToSelect.Count() = 0 Then
		Form.CurrentTypesOfValuesToSelect.Add(Undefined, NStr("ru = 'Неопределено'; en = 'Undefined'; pl = 'Nieokreślona';de = 'Nicht definiert';ro = 'Nedefinit';tr = 'Tanımlanmamış'; es_ES = 'No definido'"));
	EndIf;
	
	Items.AccessValues.Enabled = CanEditValues;
	
EndProcedure

// For internal use only.
Function AllowedValuesEditFormParameters(Form, CurrentObject = Undefined) Export
	
	Parameters = New Structure;
	Parameters.Insert("PathToTables", "");
	
	If CurrentObject <> Undefined Then
		TablesStorage = CurrentObject;
		
	ElsIf ValueIsFilled(Form.TablesStorageAttributeName) Then
		Parameters.Insert("PathToTables", Form.TablesStorageAttributeName + ".");
		TablesStorage = Form[Form.TablesStorageAttributeName];
	Else
		TablesStorage = Form;
	EndIf;
	
	OptionalAttributes = New Structure("Purpose");
	FillPropertyValues(OptionalAttributes, TablesStorage);
	Parameters.Insert("Purpose",      OptionalAttributes.Purpose);
	Parameters.Insert("AccessKinds",     TablesStorage.AccessKinds);
	Parameters.Insert("AccessValues", TablesStorage.AccessValues);
	
	Return Parameters;
	
EndFunction

// For internal use only.
Function FilterInAllowedValuesEditFormTables(Form, AccessKind = "NoFilterByAccessKind") Export
	
	Filter = New Structure;
	
	Structure = New Structure("CurrentAccessGroup", "AttributeNotExists");
	FillPropertyValues(Structure, Form);
	
	If Structure.CurrentAccessGroup <> "AttributeNotExists" Then
		Filter.Insert("AccessGroup", Structure.CurrentAccessGroup);
	EndIf;
	
	If AccessKind <> "NoFilterByAccessKind" Then
		Filter.Insert("AccessKind", AccessKind);
	EndIf;
	
	Return Filter;
	
EndFunction

// For internal use only.
Procedure FillAccessKindsPropertiesInForm(Form) Export
	
	Parameters = AllowedValuesEditFormParameters(Form);
	
	AccessKindsFilter = FilterInAllowedValuesEditFormTables(Form);
	AccessKinds = Parameters.AccessKinds.FindRows(AccessKindsFilter);
	
	For each Row In AccessKinds Do
		
		Row.Used = True;
		
		If Row.AccessKind <> Undefined Then
			Filter = New Structure("Ref", Row.AccessKind);
			FoundRows = Form.AllAccessKinds.FindRows(Filter);
			If FoundRows.Count() > 0 Then
				Row.AccessTypePresentation = FoundRows[0].Presentation;
				Row.Used            = FoundRows[0].Used;
			EndIf;
		EndIf;
		
		FillAllAllowedPresentation(Form, Row);
		
		FillNumbersOfAccessValuesRowsByKind(Form, Row);
	EndDo;
	
EndProcedure

// For internal use only.
Procedure ProcessingOfCheckOfFillingAtServerAllowedValuesEditForm(
		Form, Cancel, CheckedTablesAttributes, Errors, DontCheck = False) Export
	
	Items = Form.Items;
	Parameters = AllowedValuesEditFormParameters(Form);
	If Parameters.Purpose <> Undefined Then
		ProfileAssignment = ProfileAssignment(Parameters);
	EndIf;
	
	CheckedTablesAttributes.Add(Parameters.PathToTables + "AccessKinds.AccessKind");
	CheckedTablesAttributes.Add(Parameters.PathToTables + "AccessValues.AccessKind");
	CheckedTablesAttributes.Add(Parameters.PathToTables + "AccessValues.AccessValue");
	
	If DontCheck Then
		Return;
	EndIf;
	
	AccessKindsFilter = FilterInAllowedValuesEditFormTables(Form);
	
	AccessKinds = Parameters.AccessKinds.FindRows(AccessKindsFilter);
	AccessKindIndex = AccessKinds.Count()-1;
	
	// Checking for unfilled or duplicate access kinds.
	While NOT Cancel AND AccessKindIndex >= 0 Do
		
		AccessKindRow = AccessKinds[AccessKindIndex];
		
		// Checking whether the access kind is filled.
		If AccessKindRow.AccessKind = Undefined Then
			CommonClientServer.AddUserError(Errors,
				Parameters.PathToTables + "AccessKinds[%1].AccessKind",
				NStr("ru = 'Вид доступа не выбран.'; en = 'The access kind is not selected.'; pl = 'Rodzaj dostępu nie został wybrany.';de = 'Zugriffsart wurde nicht ausgewählt.';ro = 'Tipul de acces nu a fost selectat.';tr = 'Erişim türü seçilmedi.'; es_ES = 'Tipo de acceso no se ha seleccionado.'"),
				"AccessKinds",
				AccessKinds.Find(AccessKindRow),
				NStr("ru = 'Вид доступа в строке %1 не выбран.'; en = 'The access kind in row %1 is not selected.'; pl = 'Rodzaj dostępu w wierszu %1 nie został wybrany.';de = 'Zugriffsart in Zeile %1 wurde nicht ausgewählt.';ro = 'Tipul de acces în rândul %1 nu a fost selectat.';tr = '%1 satırdaki erişim türü seçilmedi.'; es_ES = 'Tipo de acceso en la línea %1 no se ha seleccionado.'"),
				Parameters.AccessKinds.IndexOf(AccessKindRow));
			Cancel = True;
			Break;
		EndIf;
		
		// Checking whether the access kind matches the profile assignment.
		If Parameters.Purpose <> Undefined
		  AND Not AccessKindMatchesProfileAssignment(AccessKindRow.AccessKind, ProfileAssignment) Then
			
			CommonClientServer.AddUserError(Errors,
				Parameters.PathToTables + "AccessKinds[%1].AccessKind",
				StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Вид доступа ""%1"" не соответствует назначению профиля.'; en = 'Access kind ""%1"" does not correspond to the profile assignment.'; pl = 'Typ dostępu ""%1"" nie pasuje do celu profilu.';de = 'Der Zugriffstyp ""%1"" entspricht nicht dem Zweck des Profils.';ro = 'Tipul de acces ""%1"" nu corespunde destinației profilului.';tr = '""%1"" erişim türü profilin amacına uygun değildir.'; es_ES = 'El tipo de acceso ""%1"" no corresponde a la asignación del perfil.'"),
					AccessKindRow.AccessTypePresentation),
				"AccessKinds",
				AccessKinds.Find(AccessKindRow),
				StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Вид доступа ""%1"" в строке %%1 не соответствует назначению профиля.'; en = 'Access kind ""%1"" in row %%1 does not correspond to the profile assignment.'; pl = 'Typ dostępu ""%1"" w wierszu %%1 nie pasuje do celu profilu.';de = 'Der Zugriffstyp ""%1"" in der Zeichenfolge %%1 entspricht nicht dem Zweck des Profils.';ro = 'Tipul de acces ""%1"" în rândul %%1 nu corespunde destinației profilului.';tr = '""%1 satırındaki ""%1"" erişim türü profilin amacına uygun değildir.'; es_ES = 'El tipo de acceso ""%1"" en la línea %%1 no corresponde a la asignación del perfil.'"),
					AccessKindRow.AccessTypePresentation),
				Parameters.AccessKinds.IndexOf(AccessKindRow));
			Cancel = True;
			Break;
		EndIf;
		
		// Checking for duplicate access kinds.
		AccessKindsFilter.Insert("AccessKind", AccessKindRow.AccessKind);
		FoundAccessKinds = Parameters.AccessKinds.FindRows(AccessKindsFilter);
		
		If FoundAccessKinds.Count() > 1 Then
			CommonClientServer.AddUserError(Errors,
				Parameters.PathToTables + "AccessKinds[%1].AccessKind",
				StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Вид доступа ""%1"" повторяется.'; en = 'Access kind ""%1"" is repeated.'; pl = 'Typ dostępu ""%1"" powtarza się.';de = 'Der Zugriffstyp ""%1"" wiederholt sich.';ro = 'Tipul de acces ""%1"" se repetă.';tr = '""%1"" erişim türü tekrarlandı.'; es_ES = 'Tipo de acceso ""%1"" se repite.'"),
					AccessKindRow.AccessTypePresentation),
				"AccessKinds",
				AccessKinds.Find(AccessKindRow),
				StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Вид доступа ""%1"" в строке %%1 повторяется.'; en = 'Access kind ""%1"" in line %%1  is repeated.'; pl = 'Typ dostępu ""%1"" w wierszu %%1 powtarza się.';de = 'Der Zugriffstyp ""%1"" in der Zeichenfolge %%1 wiederholt sich.';ro = 'Tipul de acces ""%1"" în rândul %%1 se repetă.';tr = '""%1 satırındaki ""%1"" erişim türü tekrarlandı.'; es_ES = 'Tipo de acceso ""%1"" en la línea %%1 se repite.'"),
					AccessKindRow.AccessTypePresentation),
				Parameters.AccessKinds.IndexOf(AccessKindRow));
			Cancel = True;
			Break;
		EndIf;
		
		AccessValuesFilter = FilterInAllowedValuesEditFormTables(
			Form, AccessKindRow.AccessKind);
		
		AccessValues = Parameters.AccessValues.FindRows(AccessValuesFilter);
		AccessValueIndex = AccessValues.Count()-1;
		
		While NOT Cancel AND AccessValueIndex >= 0 Do
			
			AccessValueRow = AccessValues[AccessValueIndex];
			
			// Checking whether the access value is filled.
			If AccessValueRow.AccessValue = Undefined Then
				Items.AccessKinds.CurrentRow = AccessKindRow.GetID();
				Items.AccessValues.CurrentRow = AccessValueRow.GetID();
				
				CommonClientServer.AddUserError(Errors,
					Parameters.PathToTables + "AccessValues[%1].AccessValue",
					NStr("ru = 'Значение не выбрано.'; en = 'The value is not selected.'; pl = 'Wartość nie jest wybrana.';de = 'Wert ist nicht ausgewählt.';ro = 'Valoarea nu este selectată.';tr = 'Değer seçilmedi'; es_ES = 'Valor no está seleccionado.'"),
					"AccessValues",
					AccessValues.Find(AccessValueRow),
					NStr("ru = 'Значение в строке %1 не выбрано.'; en = 'The value in line %1 is not selected.'; pl = 'Wartość w wierszu %1 nie jest wybrana.';de = 'Wert in Zeile %1 ist nicht ausgewählt.';ro = 'Valoarea în rândul %1 nu este selectată.';tr = '%1Satırdaki değer seçilmedi.'; es_ES = 'Valor en la línea %1 no está seleccionado.'"),
					Parameters.AccessValues.IndexOf(AccessValueRow));
				Cancel = True;
				Break;
			EndIf;
			
			// Checking for duplicate values.
			AccessValuesFilter.Insert("AccessValue", AccessValueRow.AccessValue);
			FoundValues = Parameters.AccessValues.FindRows(AccessValuesFilter);
			
			If FoundValues.Count() > 1 Then
				Items.AccessKinds.CurrentRow = AccessKindRow.GetID();
				Items.AccessValues.CurrentRow = AccessValueRow.GetID();
				
				CommonClientServer.AddUserError(Errors,
					Parameters.PathToTables + "AccessValues[%1].AccessValue",
					NStr("ru = 'Значение повторяется.'; en = 'Duplicate value.'; pl = 'Wartość powtarza się.';de = 'Der Wert wird wiederholt.';ro = 'Valoarea se repetă.';tr = 'Değer tekrarlandı.'; es_ES = 'Valor está repetido.'"),
					"AccessValues",
					AccessValues.Find(AccessValueRow),
					NStr("ru = 'Значение в строке %1 повторяется.'; en = 'Duplicate value in line %1.'; pl = 'Wartość w wierszu %1 powtarza się.';de = 'Der Wert in der Zeile %1 wird wiederholt.';ro = 'Valoarea în rândul %1 se repetă.';tr = '%1Satırdaki değer tekrarlandı.'; es_ES = 'Valor en la línea %1 está repetido.'"),
					Parameters.AccessValues.IndexOf(AccessValueRow));
				Cancel = True;
				Break;
			EndIf;
			
			AccessValueIndex = AccessValueIndex - 1;
		EndDo;
		AccessKindIndex = AccessKindIndex - 1;
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

Function PresentationAccessGroups(Data) Export
	
	Return Data.Description + ": " + Data.User;
	
EndFunction

#EndRegion
