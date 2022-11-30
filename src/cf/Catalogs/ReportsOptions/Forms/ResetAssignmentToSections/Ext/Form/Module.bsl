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
	
	If Not Parameters.Property("Variants") Or TypeOf(Parameters.Variants) <> Type("Array") Then
		ErrorText = NStr("ru = 'Не указаны варианты отчетов.'; en = 'No report options provided.'; pl = 'Opcje sprawozdania nie zostały określone.';de = 'Berichtsoptionen sind nicht angegeben.';ro = 'Opțiunile pentru rapoarte nu sunt specificate.';tr = 'Rapor seçenekleri belirtilmemiş.'; es_ES = 'Opciones del informe no especificadas.'");
		Return;
	EndIf;
	
	DefineBehaviorInMobileClient();
	OptionsToAssign.LoadValues(Parameters.Variants);
	Filter();
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	If Not IsBlankString(ErrorText) Then
		Cancel = True;
		ShowMessageBox(, ErrorText);
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure ResetCommand(Command)
	SelectedOptionsCount = OptionsToAssign.Count();
	If SelectedOptionsCount = 0 Then
		ShowMessageBox(, NStr("ru = 'Не указаны варианты отчетов.'; en = 'No report options provided.'; pl = 'Opcje sprawozdania nie zostały określone.';de = 'Berichtsoptionen sind nicht angegeben.';ro = 'Opțiunile pentru rapoarte nu sunt specificate.';tr = 'Rapor seçenekleri belirtilmemiş.'; es_ES = 'Opciones del informe no especificadas.'"));
		Return;
	EndIf;
	
	OptionsCount = ResetAssignmentSettingsServer(OptionsToAssign);
	If OptionsCount = 1 AND SelectedOptionsCount = 1 Then
		OptionRef = OptionsToAssign[0].Value;
		NotificationTitle = NStr("ru = 'Сброшены настройки размещения варианта отчета'; en = 'Report option assignment settings have been reset.'; pl = 'Ustawienia ulokowania opcji sprawozdania zostały zresetowane';de = 'Die Placement-Einstellungen der Berichtsoption wurden zurückgesetzt';ro = 'Setările de plasare ale opțiunii de raportare au fost resetate';tr = 'Rapor seçeneğinin yerleştirme ayarları sıfırlandı'; es_ES = 'Configuraciones de colocación de la opción del informe se han restablecido'");
		NotificationRef    = GetURL(OptionRef);
		NotificationText     = String(OptionRef);
		ShowUserNotification(NotificationTitle, NotificationRef, NotificationText);
	Else
		NotificationText = NStr("ru = 'Сброшены настройки размещения
		|вариантов отчетов (%1 шт.).'; 
		|en = 'Assignment settings for %1 report options
		|have been reset.'; 
		|pl = 'Zresetowano ustawienia rozmieszczania
		|wariantów raportów (%1 szt.).';
		|de = 'Setzen Sie die Einstellungen für die Platzierung
		| von Berichtsvarianten (%1 Stk.) zurück.';
		|ro = 'Setările de plasare
		|a variantelor de rapoarte au fost resetate (%1 elemente).';
		|tr = 'Rapor 
		|seçenekleri yerleştirme ayarları sıfırlandı (%1 adet).'; 
		|es_ES = 'Los ajustes para la colocación de
		|las variantes del informe se han restablecido (%1 piezas).'");
		NotificationText = StringFunctionsClientServer.SubstituteParametersToString(NotificationText, Format(OptionsCount, "NZ=0; NG=0"));
		ShowUserNotification(, , NotificationText);
	EndIf;
	ReportsOptionsClient.UpdateOpenForms();
	Close();
EndProcedure

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Server call

&AtServerNoContext
Function ResetAssignmentSettingsServer(Val OptionsToAssign)
	OptionsCount = 0;
	BeginTransaction();
	Try
		Lock = New DataLock;
		For Each ListItem In OptionsToAssign Do
			LockItem = Lock.Add(Metadata.Catalogs.ReportsOptions.FullName());
			LockItem.SetValue("Ref", ListItem.Value);
		EndDo;
		Lock.Lock();
		
		For Each ListItem In OptionsToAssign Do
			OptionObject = ListItem.Value.GetObject();
			If ReportsOptions.ResetReportOptionSettings(OptionObject) Then
				OptionObject.Write();
				OptionsCount = OptionsCount + 1;
			EndIf;
		EndDo;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	Return OptionsCount;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Server

&AtServer
Procedure DefineBehaviorInMobileClient()
	If Not Common.IsMobileClient() Then 
		Return;
	EndIf;
	
	CommandBarLocation = FormCommandBarLabelLocation.Auto;
EndProcedure

&AtServer
Procedure Filter()
	
	CountBeforeFilter = OptionsToAssign.Count();
	
	Query = New Query;
	Query.SetParameter("OptionsArray", OptionsToAssign.UnloadValues());
	Query.SetParameter("InternalType", Enums.ReportTypes.Internal);
	Query.SetParameter("ExtensionType", Enums.ReportTypes.Extension);
	Query.Text =
	"SELECT DISTINCT
	|	ReportOptionsPlacement.Ref
	|FROM
	|	Catalog.ReportsOptions AS ReportOptionsPlacement
	|WHERE
	|	ReportOptionsPlacement.Ref IN(&OptionsArray)
	|	AND ReportOptionsPlacement.Custom = FALSE
	|	AND ReportOptionsPlacement.ReportType IN (&InternalType, &ExtensionType)
	|	AND ReportOptionsPlacement.DeletionMark = FALSE";
	
	OptionsArray = Query.Execute().Unload().UnloadColumn("Ref");
	OptionsToAssign.LoadValues(OptionsArray);
	
	CountAfterFilter = OptionsToAssign.Count();
	If CountBeforeFilter <> CountAfterFilter Then
		If CountAfterFilter = 0 Then
			ErrorText = NStr("ru = 'Сброс настроек размещения выбранных вариантов отчетов не требуется по одной или нескольким причинам:
			|- Выбраны пользовательские варианты отчетов.
			|- Выбраны помеченные на удаление варианты отчетов.
			|- Выбраны варианты дополнительных или внешних отчетов.'; 
			|en = 'You do not have to reset assignment settings for selected report options due to one or more of the following reasons:
			|- Selected report options are custom options.
			|- Selected report options are marked for deletion.
			|- Selected report options are additional or external reports.'; 
			|pl = 'Resetowanie ustawień rozmieszczania wybranych wariantów raportów nie jest konieczne z jednego lub kilku powodów:
			|- Wybrano niestandardowe warianty raportów.
			|- Wybrano zaznaczone do usunięcia warianty raportów.
			|- Wybrano warianty dodatkowych raportów lub raportów zewnętrznych.';
			|de = 'Ein Zurücksetzen der Platzierung der ausgewählten Berichtsoptionen ist aus einem oder mehreren Gründen nicht erforderlich:
			|- Benutzerdefinierte Berichtsoptionen wurden ausgewählt.
			|- Die zum Löschen markierten Berichtsoptionen sind ausgewählt.
			|- Die Optionen für zusätzliche oder externe Berichte sind ausgewählt. ';
			|ro = 'Nu este necesar să resetați setările de plasare a variantelor de rapoarte selectate pentru unul sau mai multe motive:
			|- Sunt selectate variantele de utilizator ale rapoartelor .
			|- Sunt selectate variantele de raportare marcate la ștergere.
			|- Sunt selectate variantele rapoartelor suplimentare sau externe.';
			|tr = 'Seçilen rapor seçeneklerinin ayarlarının sıfırlanması bir veya 
			|birkaç nedenden dolayı gerekmemektedir:- Özel rapor seçenekleri seçildi. 
			|- Silinmek üzere işaretlenmiş raporlama seçenekleri seçildi.
			|- Ek veya harici raporlar seçenekleri seçildi.'; 
			|es_ES = 'No es necesario restablecer los ajustes de las variantes de informes seleccionadas por un o varios motivos:
			|- Variantes de informes personalizadas se han seleccionado.
			|- Variantes de informes marcadas para borrar se han seleccionado.
			| - Variantes de informes adicionales o externas se han seleccionado.'");
			Return;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion
