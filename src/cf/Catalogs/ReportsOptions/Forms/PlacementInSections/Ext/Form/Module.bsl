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
	
	SetConditionalAppearance();
	
	MixedImportance = NStr("ru = 'Различная'; en = 'Mixed'; pl = 'Różne';de = 'Unterschiedlich';ro = 'Diferit';tr = 'Farklı'; es_ES = 'Diferente'");
	
	// The number of report options is checked before opening the form.
	OptionsToAssign.LoadValues(Parameters.Variants);
	OptionsCount = OptionsToAssign.Count();
	FillSections();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	If ErrorMessages <> Undefined Then
		Cancel = True;
		ClearMessages();
		StandardSubsystemsClient.ShowQuestionToUser(Undefined, 
			StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = '%1
				|Подробности:
				|%2'; 
				|en = '%1
				|Details:
				|%2'; 
				|pl = '%1
				|Szczegóły:
				|%2';
				|de = '%1
				|Einzelheiten:
				|%2';
				|ro = '%1
				|Detalii:
				|%2';
				|tr = '%1
				|Detaylar:
				|%2'; 
				|es_ES = '%1
				|Detalles:
				|%2'"), ErrorMessages.Text, ErrorMessages.More), QuestionDialogMode.OK);
	EndIf;
EndProcedure

#EndRegion

#Region SubsystemsTreeFormTableItemsEventHandlers

&AtClient
Procedure SubsystemsTreeUsageOnChange(Item)
	ReportsOptionsClient.SubsystemsTreeUsageOnChange(ThisObject, Item);
EndProcedure

&AtClient
Procedure SubsystemsTreeImportanceOnChange(Item)
	ReportsOptionsClient.SubsystemsTreeImportanceOnChange(ThisObject, Item);
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Assign(Command)
	WriteAtServer();
	NotificationText = NStr("ru = 'Изменены настройки вариантов отчетов (%1 шт.).'; en = 'Settings changed for %1 report options.'; pl = 'Zmieniono ustawienia opcji sprawozdania (%1 szt.).';de = 'Berichtsoptionseinstellungen wurden geändert (%1Elemente).';ro = 'Setările pentru opțiunile de raport au fost modificate (%1 elementele).';tr = 'Report option settings were changed (%1 öğe).'; es_ES = 'Configuraciones de la opción del informe se han cambiado (%1 artículos).'");
	NotificationText = StringFunctionsClientServer.SubstituteParametersToString(NotificationText, Format(OptionsToAssign.Count(), "NZ=0; NG=0"));
	ShowUserNotification(, , NotificationText);
	ReportsOptionsClient.UpdateOpenForms();
	Close();
EndProcedure

&AtClient
Procedure ClearAll(Command)
	ClearSectionsCheckBoxes();
	Items.SubsystemsTree.Expand(SubsystemsTree.GetItems()[0].GetID(), True);
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SubsystemsTreeImportance.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SubsystemsTree.Importance");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("MixedImportance");

	Item.Appearance.SetParameterValue("TextColor", StyleColors.LockedAttributeColor);
	
	ReportsOptions.SetSubsystemsTreeConditionalAppearance(ThisObject);
	
EndProcedure

&AtServer
Procedure ClearSectionsCheckBoxes()
	
	DestinationTree = FormAttributeToValue("SubsystemsTree", Type("ValueTree"));
	FoundItems = DestinationTree.Rows.FindRows(New Structure("Use", 1), True);
	For Each TreeRow In FoundItems Do
		TreeRow.Use = 0;
		TreeRow.Modified = True;
	EndDo;
	
	FoundItems = DestinationTree.Rows.FindRows(New Structure("Use", 2), True);
	For Each TreeRow In FoundItems Do
		TreeRow.Use = 0;
		TreeRow.Modified = True;
	EndDo;
	
	ValueToFormAttribute(DestinationTree, "SubsystemsTree");
EndProcedure
	
&AtServer
Procedure FillSections()
	
	QueryText =
	"SELECT ALLOWED
	|	ReportsOptions.Ref,
	|	ReportsOptions.PredefinedVariant,
	|	CASE
	|		WHEN ReportsOptions.DeletionMark
	|			THEN 1
	|		WHEN &FullRightsToOptions = FALSE
	|				AND ReportsOptions.Author <> &CurrentUser
	|			THEN 2
	|		WHEN NOT ReportsOptions.Report IN (&UserReports)
	|			THEN 3
	|		WHEN ReportsOptions.Ref IN (&DIsabledApplicationOptions)
	|			THEN 4
	|		ELSE 0
	|	END AS Reason
	|INTO ttOptions
	|FROM
	|	Catalog.ReportsOptions AS ReportsOptions
	|WHERE
	|	ReportsOptions.Ref IN(&OptionsArray)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ttOptions.Ref AS Ref,
	|	ConfigurationPlacement.Subsystem AS Subsystem,
	|	ConfigurationPlacement.Important AS Important,
	|	ConfigurationPlacement.SeeAlso AS SeeAlso
	|INTO ttCommon
	|FROM
	|	ttOptions AS ttOptions
	|		INNER JOIN Catalog.PredefinedReportsOptions.Placement AS ConfigurationPlacement
	|		ON (ttOptions.Reason = 0)
	|			AND ttOptions.PredefinedVariant = ConfigurationPlacement.Ref
	|
	|UNION ALL
	|
	|SELECT
	|	ttOptions.Ref,
	|	ExtensionsPlacement.Subsystem,
	|	ExtensionsPlacement.Important,
	|	ExtensionsPlacement.SeeAlso
	|FROM
	|	ttOptions AS ttOptions
	|		INNER JOIN Catalog.PredefinedExtensionsReportsOptions.Placement AS ExtensionsPlacement
	|		ON (ttOptions.Reason = 0)
	|			AND ttOptions.PredefinedVariant = ExtensionsPlacement.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ReportOptionsPlacement.Ref AS Ref,
	|	ReportOptionsPlacement.Use AS Use,
	|	ReportOptionsPlacement.Subsystem AS Subsystem,
	|	ReportOptionsPlacement.Important AS Important,
	|	ReportOptionsPlacement.SeeAlso AS SeeAlso
	|INTO ttSeparated
	|FROM
	|	ttOptions AS ttOptions
	|		INNER JOIN Catalog.ReportsOptions.Placement AS ReportOptionsPlacement
	|		ON (ttOptions.Reason = 0)
	|			AND ttOptions.Ref = ReportOptionsPlacement.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	ttOptions.Ref,
	|	ttOptions.Reason AS Reason
	|FROM
	|	ttOptions AS ttOptions
	|WHERE
	|	ttOptions.Reason <> 0
	|
	|ORDER BY
	|	Reason
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(SeparatedSettings.Subsystem, CommonSettings.Subsystem) AS Ref,
	|	SUM(1) AS Count,
	|	CASE
	|		WHEN ISNULL(SeparatedSettings.Important, CommonSettings.Important) = TRUE
	|			THEN &ImportantPresentation
	|		WHEN ISNULL(SeparatedSettings.SeeAlso, CommonSettings.SeeAlso) = TRUE
	|			THEN &SeeAlsoPresentation
	|		ELSE """"
	|	END AS Importance
	|FROM
	|	ttCommon AS CommonSettings
	|		FULL JOIN ttSeparated AS SeparatedSettings
	|		ON CommonSettings.Ref = SeparatedSettings.Ref
	|			AND CommonSettings.Subsystem = SeparatedSettings.Subsystem
	|WHERE
	|	(SeparatedSettings.Use = TRUE
	|			OR SeparatedSettings.Use IS NULL )
	|
	|GROUP BY
	|	ISNULL(SeparatedSettings.Subsystem, CommonSettings.Subsystem),
	|	CASE
	|		WHEN ISNULL(SeparatedSettings.Important, CommonSettings.Important) = TRUE
	|			THEN &ImportantPresentation
	|		WHEN ISNULL(SeparatedSettings.SeeAlso, CommonSettings.SeeAlso) = TRUE
	|			THEN &SeeAlsoPresentation
	|		ELSE """"
	|	END";
	
	Query = New Query;
	Query.SetParameter("FullRightsToOptions",        ReportsOptions.FullRightsToOptions());
	Query.SetParameter("CurrentUser",          Users.AuthorizedUser());
	Query.SetParameter("OptionsArray",              OptionsToAssign.UnloadValues());
	Query.SetParameter("UserReports",           ReportsOptions.CurrentUserReports());
	Query.SetParameter("DIsabledApplicationOptions", ReportsOptionsCached.DIsabledApplicationOptions());
	Query.SetParameter("ImportantPresentation",          ReportsOptions.ImportantPresentation());
	Query.SetParameter("SeeAlsoPresentation",         ReportsOptions.SeeAlsoPresentation());
	
	Query.Text = QueryText;
	TempTables = Query.ExecuteBatch();
	
	FilteredOptions = TempTables[3].Unload();
	ErrorsCount = FilteredOptions.Count();
	
	If ErrorsCount > 0 Then
		ErrorMessages = New Structure("Text, More");
		CurrentReason = 0;
		ErrorMessages.More = "";
		For Each TableRow In FilteredOptions Do
			If CurrentReason <> TableRow.Reason Then
				CurrentReason = TableRow.Reason;
				ErrorMessages.More = ErrorMessages.More + Chars.LF + Chars.LF;
				If CurrentReason = 1 Then
					ErrorMessages.More = ErrorMessages.More + NStr("ru = 'Помеченные на удаление:'; en = 'Marked for deletion:'; pl = 'Zaznaczone do usunięcia:';de = 'Zum Löschen markiert:';ro = 'Marcate pentru ștergere:';tr = 'Silinmek üzere işaretlendi'; es_ES = 'Marcado para borrar:'");
				ElsIf CurrentReason = 2 Then
					ErrorMessages.More = ErrorMessages.More + NStr("ru = 'Недостаточно прав для изменения:'; en = 'Insufficient rights to modify:'; pl = 'Niewystarczające prawa do zmiany:';de = 'Unzureichende Änderungsrechte:';ro = 'Drepturi suficiente pentru a schimba:';tr = 'Değiştirme hakları yetersiz:'; es_ES = 'Insuficientes derechos para cambiar:'");
				ElsIf CurrentReason = 3 Then
					ErrorMessages.More = ErrorMessages.More + NStr("ru = 'Отчет отключен или недоступен по правам:'; en = 'The report is disabled or cannot be accessed with the rights:'; pl = 'Sprawozdanie jest wyłączone lub niedostępne dla tych uprawnień:';de = 'Der Bericht ist für die Rechte deaktiviert oder nicht verfügbar:';ro = 'Raportul este dezactivat sau indisponibil pentru drepturile:';tr = 'Rapor, haklar için devre dışı bırakılmış veya kullanılamıyor:'; es_ES = 'El informe está desactivado o no está disponible para los derechos:'");
				ElsIf CurrentReason = 4 Then
					ErrorMessages.More = ErrorMessages.More + NStr("ru = 'Вариант отчета отключен по функциональной опции:'; en = 'Report option is disabled using the functional option:'; pl = 'Opcja sprawozdnia jest wyłączona za pomocą opcji funkcjonalnej:';de = 'Berichtsoption wird mit Hilfe der funktionellen Option deaktiviert:';ro = 'Opțiunea de raport este dezactivată utilizând opțiunea funcțională:';tr = 'Rapor seçeneği, işlevsel seçenek kullanılarak devre dışı bırakıldı:'; es_ES = 'Opción del informe está desactivada utilizando la opción funcional:'");
				EndIf;
			EndIf;
			
			ErrorMessages.More = TrimL(ErrorMessages.More) + Chars.LF + "    - " + String(TableRow.Ref);
			OptionsToAssign.Delete(OptionsToAssign.FindByValue(TableRow.Ref));
		EndDo;
		
		OptionsCount = OptionsToAssign.Count();
		
		If OptionsCount = 0 Then
			ErrorMessages.Text = NStr("ru = 'Недостаточно прав для размещения в разделах выбранных вариантов отчетов.'; en = 'Insufficient rights to assign selected report options to sections.'; pl = 'Niewystarczające uprawnienia do umieszczania wybranych opcji sprawozdania w sekcjach.';de = 'Unzureichende Rechte zum Platzieren der ausgewählten Berichtsoptionen in Abschnitten.';ro = 'Drepturile insuficiente pentru plasarea opțiunilor de rapoarte selectate în secțiuni.';tr = 'Seçili rapor seçeneklerini bölümlere yerleştirmek için yetersiz haklar.'; es_ES = 'Insuficientes derechos para colocar las opciones del informe seleccionadas en las secciones.'");
		Else
			ErrorMessages.Text = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Недостаточно прав для размещения в разделах некоторых вариантов отчетов (%1).'; en = 'Insufficient rights to assign %1 report options to sections.'; pl = 'Niewystarczające uprawnienia do umieszczania niektórych opcji sprawozdania (%1) w sekcjach.';de = 'Unzureichende Rechte zum Platzieren einiger Berichtsoptionen (%1) in Abschnitten.';ro = 'Drepturile insuficiente pentru a plasa în secțiuni câteva opțiuni de raportare (%1).';tr = 'Bazı rapor seçeneklerini (%1) bölümlere yerleştirmek için yetersiz haklar.'; es_ES = 'Insuficientes derechos para colocar algunas opciones del informe (%1) a las secciones.'"),
				Format(ErrorsCount, "NG="));
		EndIf;
		
		ErrorMessages = New FixedStructure(ErrorMessages);
	EndIf;
	
	SubsystemsOccurrences = TempTables[4].Unload();
	
	SourceTree = ReportsOptionsCached.CurrentUserSubsystems();
	
	DestinationTree = FormAttributeToValue("SubsystemsTree", Type("ValueTree"));
	DestinationTree.Rows.Clear();
	
	AddSubsystemsToTree(DestinationTree, SourceTree, SubsystemsOccurrences);
	
	ValueToFormAttribute(DestinationTree, "SubsystemsTree");
EndProcedure

&AtServer
Procedure WriteAtServer()
	
	DestinationTree = FormAttributeToValue("SubsystemsTree", Type("ValueTree"));
	ChangedSections = DestinationTree.Rows.FindRows(New Structure("Modified", True), True);
	
	BeginTransaction();
	Try
		Lock = New DataLock;
		For Each ReportOption In OptionsToAssign Do
			LockItem = Lock.Add(Metadata.Catalogs.ReportsOptions.FullName());
			LockItem.SetValue("Ref", ReportOption.Value);
		EndDo;
		Lock.Lock();
			
		For Each ReportOption In OptionsToAssign Do
			OptionObject = ReportOption.Value.GetObject();
			ReportsOptions.SubsystemsTreeWrite(OptionObject, ChangedSections);
			OptionObject.Write();
		EndDo;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

&AtServer
Procedure AddSubsystemsToTree(DestinationParent, SourceParent, SubsystemsOccurrences)
	For Each Source In SourceParent.Rows Do
		
		Destination = DestinationParent.Rows.Add();
		FillPropertyValues(Destination, Source);
		
		OccurrencesOfThisSubsystem = SubsystemsOccurrences.Copy(New Structure("Ref", Destination.Ref));
		If OccurrencesOfThisSubsystem.Count() = 1 Then
			Destination.Importance = OccurrencesOfThisSubsystem[0].Importance;
		ElsIf OccurrencesOfThisSubsystem.Count() = 0 Then
			Destination.Importance = "";
		Else
			Destination.Importance = MixedImportance; // It is also used for conditional appearance.
		EndIf;
		
		OptionsOccurrences = OccurrencesOfThisSubsystem.Total("Count");
		If OptionsOccurrences = OptionsCount Then
			Destination.Use = 1;
		ElsIf OptionsOccurrences = 0 Then
			Destination.Use = 0;
		Else
			Destination.Use = 2;
		EndIf;
		
		// Recursion
		AddSubsystemsToTree(Destination, Source, SubsystemsOccurrences);
	EndDo;
EndProcedure

#EndRegion