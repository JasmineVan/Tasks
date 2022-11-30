///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	AttributesToExclude = New Array;
	
	If Not Custom Then
		AttributesToExclude.Add("Author");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesToExclude);
	
	If Description <> "" AND ReportsOptions.DescriptionIsUsed(Report, Ref, Description) Then
		Cancel = True;
		Common.MessageToUser(
			StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = '""%1"" занято, необходимо указать другое наименование.'; en = '""%1"" is taken. Enter another description.'; pl = '""%1"" jest już używane, wprowadź inną nazwę.';de = '""%1"" wird bereits verwendet, geben Sie einen anderen Namen ein.';ro = '""%1"" este deja folosit, introduceți un alt nume.';tr = '""%1"" zaten kullanılmakta, başka bir ad girin.'; es_ES = '""%1"" ya está utilizado, introducir otro nombre.'"), Description),
			,
			"Description");
	EndIf;
EndProcedure

Procedure BeforeWrite(Cancel)
	If AdditionalProperties.Property("PredefinedObjectsFilling") Then
		CheckPredefinedReportOptionFilling(Cancel);
	EndIf;
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	UserChangedDeletionMark = (
		Not IsNew()
		AND DeletionMark <> Ref.DeletionMark
		AND Not AdditionalProperties.Property("PredefinedObjectsFilling"));
	
	If Not Custom AND UserChangedDeletionMark Then
		If DeletionMark Then
			ErrorText = NStr("ru = 'Пометка на удаление предопределенного варианта отчета запрещена.'; en = 'Predefined report options cannot be marked for deletion.'; pl = 'Nie można zaznaczyć predefiniowanej opcji sprawozdania do usunięcia.';de = 'Die vordefinierte Berichtsoption kann nicht zum Löschen markiert werden.';ro = 'Este interzisă marcarea la ștergere a variantei predefinite a raportului.';tr = 'Silinmek üzere önceden tanımlanmış rapor seçeneği işaretlenemez.'; es_ES = 'No se puede marcar la opción del informe predefinido para borrar.'");
		Else
			ErrorText = NStr("ru = 'Снятие пометки удаления предопределенного варианта отчета запрещено.'; en = 'Predefined report options cannot be unmarked for deletion.'; pl = 'Nie można usunąć znacznika usunięcia predefiniowanej opcji sprawozdania.';de = 'Das Entfernen der Löschmarkierung einer vordefinierten Version des Berichts ist nicht zulässig.';ro = 'Nu se permite anularea marcării la ștergere a variantei predefinite a raportului.';tr = 'Önceden tanımlanmış bir rapor seçeneğinin işaretini kaldırmak yasaktır.'; es_ES = 'Está prohibido quitar la marca de borrar de la opción predeterminada del informe.'");
		EndIf;
		Raise ErrorText;
	EndIf;
	
	If Not DeletionMark AND UserChangedDeletionMark Then
		DescriptionIsUsed = ReportsOptions.DescriptionIsUsed(Report, Ref, Description);
		OptionKeyIsUsed  = ReportsOptions.OptionKeyIsUsed(Report, Ref, VariantKey);
		If DescriptionIsUsed OR OptionKeyIsUsed Then
			ErrorText = NStr("ru = 'Ошибка снятия пометки удаления варианта отчета:'; en = 'Error unmarking report option for deletion:'; pl = 'Wystąpił błąd podczas usuwania znacznika usunięcia z opcji sprawozdania:';de = 'Beim Löschen der Löschmarkierung der Berichtsoption ist ein Fehler aufgetreten:';ro = 'A apărut o eroare la eliminarea marcajului de ștergere a opțiunii de raport:';tr = 'Rapor seçeneğinin silme işaretini temizlerken bir hata oluştu:'; es_ES = 'Ha ocurrido un error al eliminar la marca de borrado de la opción del informe:'");
			If DescriptionIsUsed Then
				ErrorText = ErrorText + StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Наименование ""%1"" уже занято другим вариантом этого отчета.'; en = 'Name ""%1"" is taken by another option of this report.'; pl = 'Nazwa ""%1"" jest już używana przez inną opcję tego sprawozdania.';de = 'Der Name ""%1"" wird bereits von einer anderen Option dieses Berichts verwendet.';ro = 'Numele ""%1"" este deja utilizat de o altă opțiune a acestui raport.';tr = '""%1"" adı, bu raporun başka bir seçeneği tarafından zaten kullanılıyor.'; es_ES = 'Nombre ""%1"" ya está utilizado por otra opción de este informe.'"),
					Description);
			Else
				ErrorText = ErrorText + StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Ключ варианта ""%1"" уже занят другим вариантом этого отчета.'; en = 'Key ""%1"" is assigned to another option of this report.'; pl = 'Klucz opcji ""%1"" jest już używany przez inną opcję tego sprawozdania.';de = 'Der Schlüssel der Option ""%1"" wird bereits von einer anderen Option dieses Berichts verwendet.';ro = 'Cheia opțiunii ""%1"" este deja utilizată de o altă opțiune a acestui raport.';tr = '""%1"" seçeneğinin anahtarı, bu raporun başka bir seçeneği tarafından zaten kullanılıyor.'; es_ES = 'Clave de la opción ""%1"" ya está utilizada por otra opción de este informe.'"),
					VariantKey);
			EndIf;
			ErrorText = ErrorText + NStr("ru = 'Перед снятием пометки удаления варианта отчета
				|необходимо установить пометку удаления конфликтующего варианта отчета.'; 
				|en = 'Before you unmark the report option for deletion,
				|you must mark the conflicting report option for deletion.'; 
				|pl = 'Przed usuwaniem znacznika usunięcia
				|opcji sprawozdania konieczne jest ustawienie znacznika usunięcia konfliktującego sprawozdania.';
				|de = 'Bevor Sie die Löschmarkierung 
				|der Berichtsoption rückgängig machen ist es erforderlich, die Löschmarkierung der umstrittenen Berichtsoption zu installieren.';
				|ro = 'Înainte de a scoate marcajul la ștergere a variantei raportului
				| trebuie să instalați marcajul la ștergere a variantei de raport care este în conflict.';
				|tr = 'Rapor seçeneğinin
				| silme işaretini işaretlemeden önce, tartışmalı rapor seçeneğinin silme işaretinin yüklenmesi gerekir. '; 
				|es_ES = 'Antes de desmarcar la marca de borrado
				|de la opción del informe, es necesario instalar la marca de borrado de la opción de un informe controversial. '");
			Raise ErrorText;
		EndIf;
	EndIf;
	
	If UserChangedDeletionMark Then
		InteractiveSetDeletionMark = ?(Custom, DeletionMark, False);
	EndIf;
	
	// Delete subsystems marked for deletion from the tabular section.
	RowsToDelete = New Array;
	For Each AssignmentRow In Placement Do
		If AssignmentRow.Subsystem.DeletionMark = True Then
			RowsToDelete.Add(AssignmentRow);
		EndIf;
	EndDo;
	For Each AssignmentRow In RowsToDelete Do
		Placement.Delete(AssignmentRow);
	EndDo;
	
	FillFieldsForSearch();
EndProcedure

#EndRegion

#Region Private

Procedure OnReadPresentationsAtServer() Export
	
	LocalizationServer.OnReadPresentationsAtServer(ThisObject);
	
EndProcedure	

// Fill in the FieldsDescriptions and ParametersAndFiltersDescriptions attributes.
Procedure FillFieldsForSearch()
	Additional = (ReportType = Enums.ReportTypes.Additional);
	If Not Custom AND Not Additional Then
		Return;
	EndIf;
	
	Try
		SetSafeModeDisabled(True);
		SetPrivilegedMode(True);
		ReportsOptions.FillFieldsForSearch(ThisObject);
	Except
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось проиндексировать схему варианта ""%1"" отчета ""%2"":'; en = 'Cannot index the scheme of option ""%1"" of report ""%2"":'; pl = 'Nie można indeksować schematu opcji ""%1"" sprawozdania ""%2"":';de = 'Ein Schema der Option ""%1"" des Berichts ""%2"" kann nicht indiziert werden:';ro = 'Nu se poate indexa o schemă de opțiune ""%1"" a raportului ""%2"":';tr = '""%1"" raporunun ""%2"" seçeneğine ait şema endekslenemiyor:'; es_ES = 'No se puede indexar un esquema de la opción ""%1"" del informe ""%2"":'"),
			VariantKey, String(Report));
		ErrorText = ErrorText + Chars.LF + DetailErrorDescription(ErrorInfo());
		ReportsOptions.WriteToLog(EventLogLevel.Error, ErrorText, Ref);
	EndTry;
EndProcedure

// This procedure fills in a report option parent based on the report reference and predefined settings.
Procedure FillInParent() Export
	QueryText =
	"SELECT ALLOWED TOP 1
	|	Predefined.Ref AS PredefinedVariant
	|INTO ttPredefined
	|FROM
	|	Catalog.PredefinedReportsOptions AS Predefined
	|WHERE
	|	Predefined.Report = &Report
	|	AND Predefined.DeletionMark = FALSE
	|	AND Predefined.GroupByReport
	|
	|ORDER BY
	|	Predefined.Enabled DESC
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED TOP 1
	|	ReportsOptions.Ref
	|FROM
	|	ttPredefined AS ttPredefined
	|		INNER JOIN Catalog.ReportsOptions AS ReportsOptions
	|		ON ttPredefined.PredefinedVariant = ReportsOptions.PredefinedVariant
	|WHERE
	|	ReportsOptions.DeletionMark = FALSE";
	If ReportType = Enums.ReportTypes.Extension Then
		QueryText = StrReplace(QueryText, ".PredefinedReportsOptions", ".PredefinedExtensionsReportsOptions");
	EndIf;
	Query = New Query;
	Query.SetParameter("Report", Report);
	Query.Text = QueryText;
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Parent = Selection.Ref;
	EndIf;
EndProcedure

// Basic checks of data of predefined report options. 
Procedure CheckPredefinedReportOptionFilling(Cancel)
	If DeletionMark Or Not Predefined Then
		Return;
	ElsIf Not ValueIsFilled(Report) Then
		ErrorText = FieldIsRequired("Report");
	ElsIf Not ValueIsFilled(ReportType) Then
		ErrorText = FieldIsRequired("ReportType");
	ElsIf ReportType <> ReportsOptions.ReportType(Report) Then
		ErrorText = NStr("ru = 'Противоречивые значения полей ""%1"" и ""%2""'; en = 'Fields ""%1"" and ""%2"" contains inconsistent values.'; pl = 'Sprzeczne wartości pól ""%1"" i ""%2""';de = 'Inkonsistente Werte der Felder ""%1"" und ""%2""';ro = 'Valorile nepotrivite ale câmpurilor ""%1"" și ""%2""';tr = '""%1"" ve ""%2"" alanlarının tutarsız değerleri'; es_ES = 'Valores incompatibles de los campos ""%1"" y ""%2""'");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, "ReportType", "Report");
	ElsIf Not ValueIsFilled(PredefinedVariant)
		AND (ReportType = Enums.ReportTypes.Internal Or ReportType = Enums.ReportTypes.Extension) Then
		ErrorText = FieldIsRequired("PredefinedVariant");
	Else
		Return;
	EndIf;
	Raise ErrorText;
EndProcedure

Function FieldIsRequired(FieldName)
	Return StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Не заполнено поле ""%1""'; en = 'Field %1 is required.'; pl = 'Pole ""%1"" nie jest wypełnione';de = 'Das Feld ""%1"" ist nicht ausgefüllt';ro = 'Câmpul ""%1"" nu este completat';tr = '""%1"" alanı doldurulmadı.'; es_ES = 'El ""%1"" campo no está rellenado'"), FieldName);
EndFunction

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Niedozwolone wezwanie obiektu na kliencie.';de = 'Unzulässiger Objektaufruf auf dem Client.';ro = 'Apel inadmisibil al obiectului pe client.';tr = 'İstemcide kabul edilmeyen nesne çağrısı.'; es_ES = 'Llamada no disponible del objeto en el cliente.'");
#EndIf