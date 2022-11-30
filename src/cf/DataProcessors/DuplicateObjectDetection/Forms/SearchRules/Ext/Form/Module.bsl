///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

// The following parameters are expected:
//
//     SearchForDuplicatesArea        - String               - a full name of the table metadata of the area previously selected for search.
//     FilterAreaPresentation - String - a presentation for title generation.
//     AppliedRulesDetails   - String, Undefined - a text of applied rules. If it is not specified,
//                                   there are no applied rules.
//
//     SettingsAddress - String - an address of the temporary settings storage. Structure with the following fields is expected:
//         TakeAppliedRulesIntoAccount - Boolean - a previous settings flag is True by default.
//         SearchRules              - ValueTable - editable settings. The following columns are expected:
//             Attribute - String  - an attribute name to compare.
//             AttributePresentation - String - an attribute presentation to compare.
//             Rule - String - a selected comparison option: "Equal" is an equality match, "Like" is 
//                                 a similarity match, and "" means "ignore".
//             ComparisonOptions - ValueList - available comparison options, whose value is one of 
//                                                  the rule options.
//
// Returns the selection result:
//     Undefined - an editing cancellation.
//     String       - an address of the temporary storage of new settings points to a structure similar to the parameter
//                    SettingsAddress.
//

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Parameters.Property("AppliedRuleDetails", AppliedRuleDetails);
	DuplicatesSearchArea = Parameters.DuplicatesSearchArea;

	Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Правила поиска дублей ""%1""'; en = 'Duplicate search rule: %1'; pl = 'Reguły wyszukiwania duplikatów ""%1""';de = 'Regeln der Suche nach Duplikaten ""%1""';ro = 'Regulile de căutare a duplicatelor ""%1""';tr = '""%1"" çiftleri için arama kuralları '; es_ES = 'Reglas de la búsqueda de duplicados ""%1""'"), Parameters.FilterAreaPresentation);
	
	InitialSettings = GetFromTempStorage(Parameters.SettingsAddress);
	DeleteFromTempStorage(Parameters.SettingsAddress);
	InitialSettings.Property("TakeAppliedRulesIntoAccount", TakeAppliedRulesIntoAccount);
	
	If AppliedRuleDetails = Undefined Then // Rules are not defined
		Items.AppliedRestrictionsGroup.Visible = False;
		WindowOptionsKey = "NoAppliedRestrictionsGroup";
	Else
		Items.TakeAppliedRulesIntoAccount.Visible = CanCancelAppliedRules();
	EndIf;
	
	// Filling and adjusting rules.
	SearchRules.Load(InitialSettings.SearchRules);
	For Each RuleRow In SearchRules Do
		RuleRow.Use = Not IsBlankString(RuleRow.Rule);
	EndDo;
	
	For Each Item In InitialSettings.AllComparisonOptions Do
		If Not IsBlankString(Item.Value) Then
			FillPropertyValues(AllSearchRulesComparisonTypes.Add(), Item);
		EndIf;
	EndDo;
	
	SetColorsAndConditionalAppearance();
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	ThisObject.RefreshDataRepresentation();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure TakeAppliedRulesIntoAccountOnChange(Item)
	
	If TakeAppliedRulesIntoAccount Then
		Return;
	EndIf;
	
	Details = New NotifyDescription("ClearingAppliedRulesUsageCompletion", ThisObject);
	
	TitleText = NStr("ru = 'Предупреждение'; en = 'Warning'; pl = 'Ostrzeżenie';de = 'Warnung';ro = 'Avertisment';tr = 'Uyarı'; es_ES = 'Aviso'");
	QuestionText   = NStr("ru = 'Внимание: поиск и удаление дублей элементов без учета поставляемых ограничений
	                            |может привести к рассогласованию данных в программе.
	                            |
	                            |Отключить использование поставляемых ограничений?'; 
	                            |en = 'Warning: deleting duplicates with the default restrictions
	                            |turned off might result in data inconsistency.
	                            |
	                            |Do you still want to turn off the default restrictions?'; 
	                            |pl = 'Uwaga: wyszukiwanie i usuwanie duplikatów elementów bez uwzględnienia dostarczanych ograniczeń
	                            |może doprowadzić do niedopasowania danych w programie.
	                            |
	                            |Wyłączyć korzystanie z dostarczanych ograniczeń?';
	                            |de = 'Achtung: Das Suchen und Löschen von doppelten Elementen ohne Berücksichtigung der vorgegebenen Einschränkungen
	                            |kann zu Datenfehlern im Programm führen.
	                            |
	                            |Die Verwendung der vorgegebenen Einschränkungen deaktivieren?';
	                            |ro = 'Atenție: căutarea și ștergerea duplicatelor de elemente fără a ține cont de restricțiile furnizate
	                            |poate duce la discordanța datelor în aplicație.
	                            |
	                            |Dezactivați utilizarea restricțiilor furnizate?';
	                            |tr = 'Uyarı:  Öğe kopyalarının teslim edilen
	                            | kısıtlamaları göz ardı etmesini arama ve  silme, uygulamada verilerin yanlış hizalanmasına neden olabilir. 
	                            |
	                            |Teslim edilen kısıtlamaları kullanım dışı bırakılsın mı?'; 
	                            |es_ES = 'Aviso: restricciones enviadas de ignorar los duplicados del artículo de la búsqueda y la eliminación
	                            |pueden causar una desalineación de datos en la aplicación.
	                            |
	                            |¿Desactivar el uso de restricciones enviadas?'");
	
	ShowQueryBox(Details, QuestionText, QuestionDialogMode.YesNo,,DialogReturnCode.No, TitleText);
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSearchRules

&AtClient
Procedure SearchRulesChoice(Item, RowSelected, Field, StandardProcessing)
	ColumnName = Field.Name;
	If ColumnName = "SearchRulesComparisonType" Then
		StandardProcessing = False;
		SelectComparisonType();
	EndIf;
EndProcedure

&AtClient
Procedure SearchRulesUseOnChange(Item)
	TableRow = Items.SearchRules.CurrentData;
	If TableRow.Use Then
		If IsBlankString(TableRow.Rule) AND TableRow.ComparisonOptions.Count() > 0 Then
			TableRow.Rule = TableRow.ComparisonOptions[0].Value
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure SearchRulesComparisonTypeStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	SelectComparisonType();
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure CompleteEditing(Command)
	SelectionErrorsText = SelectionErrors();
	If SelectionErrorsText <> Undefined Then
		ShowMessageBox(, SelectionErrorsText);
		Return;
	EndIf;
	
	NotifyChoice(SelectionResult());
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SelectComparisonType()
	TableRow = Items.SearchRules.CurrentData;
	If TableRow = Undefined Then
		Return;
	EndIf;
	
	ChoiceList = TableRow.ComparisonOptions;
	Count = ChoiceList.Count();
	If Count = 0 Then
		Return;
	EndIf;
	
	Context = New Structure("IDRow", TableRow.GetID());
	Handler = New NotifyDescription("EndingComparisonTypeSelection", ThisObject, Context);
	If Count = 1 AND Not TableRow.Use Then
		ExecuteNotifyProcessing(Handler, ChoiceList[0]);
		Return;
	EndIf;
	
	ShowChooseFromMenu(Handler, ChoiceList);
EndProcedure

&AtClient
Procedure EndingComparisonTypeSelection(Result, Context) Export
	If Result = Undefined Then
		Return;
	EndIf;
	
	TableRow = SearchRules.FindByID(Context.IDRow);
	If TableRow = Undefined Then
		Return;
	EndIf;
	
	TableRow.Rule      = Result.Value;
	TableRow.Use = True;
EndProcedure

&AtClient
Function SelectionErrors()
	
	If AppliedRuleDetails <> Undefined AND TakeAppliedRulesIntoAccount Then
		// There are application rules and they are used. There are no errors.
		Return Undefined;
	EndIf;
	
	For Each RulesRow In SearchRules Do
		If RulesRow.Use Then
			// User rule is specified. There are no errors.
			Return Undefined;
		EndIf;
	EndDo;
	
	Return NStr("ru ='Необходимо указать хотя бы одно правило поиска дублей.'; en = 'Specify at least one duplicate search rule.'; pl = 'Podaj co najmniej jedną regułę do podwójnego wyszukiwania.';de = 'Geben Sie mindestens eine Regel für die Duplikatsuche an.';ro = 'Specificați cel puțin o regulă pentru căutarea duplicatelor.';tr = 'Çiftleri arama için en az bir kural belirtin.'; es_ES = 'Especificar como mínimo una regla para la búsqueda de duplicados.'");
EndFunction

&AtClient
Procedure ClearingAppliedRulesUsageCompletion(Val Response, Val AdditionalParameters) Export
	If Response = DialogReturnCode.Yes Then
		Return 
	EndIf;
	
	TakeAppliedRulesIntoAccount = True;
EndProcedure

&AtServerNoContext
Function CanCancelAppliedRules()
	
	Result = AccessRight("DataAdministration", Metadata);
	Return Result;
	
EndFunction

&AtServer
Function SelectionResult()
	
	Result = New Structure;
	Result.Insert("TakeAppliedRulesIntoAccount", TakeAppliedRulesIntoAccount);
	
	SelectedRules = SearchRules.Unload();
	For Each RulesRow In SelectedRules  Do
		If Not RulesRow.Use Then
			RulesRow.Rule = "";
		EndIf;
	EndDo;
	SelectedRules.Columns.Delete("Use");
	
	Result.Insert("SearchRules", SelectedRules );
	
	Return PutToTempStorage(Result);
EndFunction

&AtServer
Procedure SetColorsAndConditionalAppearance()
	ConditionalAppearanceItems = ConditionalAppearance.Items;
	ConditionalAppearanceItems.Clear();
	
	InaccessibleDataColor = StyleColorOrAuto("InaccessibleDataColor", 192, 192, 192);
	
	For Each ListItem In AllSearchRulesComparisonTypes Do
		AppearanceItem = ConditionalAppearanceItems.Add();
		
		AppearanceFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
		AppearanceFilter.LeftValue = New DataCompositionField("SearchRules.Rule");
		AppearanceFilter.ComparisonType = DataCompositionComparisonType.Equal;
		AppearanceFilter.RightValue = ListItem.Value;
		
		AppearanceField = AppearanceItem.Fields.Items.Add();
		AppearanceField.Field = New DataCompositionField("SearchRulesComparisonType");
		
		AppearanceItem.Appearance.SetParameterValue("Text", ListItem.Presentation);
	EndDo;
	
	// Do not use
	AppearanceItem = ConditionalAppearanceItems.Add();
	
	AppearanceFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	AppearanceFilter.LeftValue = New DataCompositionField("SearchRules.Use");
	AppearanceFilter.ComparisonType = DataCompositionComparisonType.Equal;
	AppearanceFilter.RightValue = False;
	
	AppearanceField = AppearanceItem.Fields.Items.Add();
	AppearanceField.Field = New DataCompositionField("SearchRulesComparisonType");
	
	AppearanceItem.Appearance.SetParameterValue("TextColor", InaccessibleDataColor);
EndProcedure

&AtServerNoContext
Function StyleColorOrAuto(Val Name, Val Red = Undefined, Green = Undefined, Blue = Undefined)

	StyleItem = Metadata.StyleItems.Find(Name);
	If StyleItem <> Undefined AND StyleItem.Type = Metadata.ObjectProperties.StyleElementType.Color Then
		Return StyleColors[Name];
	EndIf;
	
	Return ?(Red = Undefined, New Color, New Color(Red, Green, Blue));
EndFunction

#EndRegion

