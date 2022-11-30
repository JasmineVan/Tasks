///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Clone, Parent, Folder)
	Cancel = True;
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure DeleteRecords(Command)
	
	QuestionText = NStr("ru = 'Удаление записей по версиям объектов может привести к невозможности 
		|выполнения анализа всей цепочки изменений этих объектов. Продолжить?'; 
		|en = 'If you delete object version records, the analysis of
		|the object change sequence might be unavailable. Continue?'; 
		|pl = 'Usuwanie wpisów wg wersji obiektu może spowodować uniemożliwienie 
		| przeprowadzenia analizy całego łańcucha zmian tych obiektów. Chcesz kontynuować?';
		|de = 'Das Löschen von Datensätzen nach Versionen von Objekten kann dazu führen, 
		| dass die gesamte Kette der Änderungen an diesen Objekten nicht analysiert werden kann. Fortfahren?';
		|ro = 'Ștergerea înregistrărilor versiunilor obiectelor poate conduce la imposibilitatea
		|analizării întregului lanț de modificări ale acestor obiecte. Continuați?';
		|tr = 'Nesne sürüm kayıtlarının silinmesi, tüm nesne değişim zincirinin analizini 
		|gerçekleştirememeye neden olabilir. Devam et?'; 
		|es_ES = 'Eliminación de los registros de la versión del objeto puede causar la incapacidad de 
		|realizar el análisis de toda la cadena de cambios del objeto. ¿Continuar?'");
		
	NotifyDescription = New NotifyDescription("DeleteRecordsCompletion", ThisObject, Items.List.SelectedRows);
	ShowQueryBox(NotifyDescription, QuestionText, QuestionDialogMode.YesNo, , DialogReturnCode.No, NStr("ru = 'Предупреждение'; en = 'Warning'; pl = 'Ostrzeżenie';de = 'Warnung';ro = 'Avertisment';tr = 'Uyarı'; es_ES = 'Aviso'"));
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure DeleteRecordsCompletion(QuestionResult, RecordList) Export
	If QuestionResult = DialogReturnCode.Yes Then
		DeleteVersionsFromRegister(RecordList);
	EndIf;
EndProcedure

&AtServer
Procedure DeleteVersionsFromRegister(Val RecordList)
	
	For Each RecordKey In RecordList Do
		RecordSet = InformationRegisters.ObjectsVersions.CreateRecordSet();
		
		RecordSet.Filter.Object.Value = RecordKey.Object;
		RecordSet.Filter.Object.ComparisonType = ComparisonType.Equal;
		RecordSet.Filter.Object.Use = True;
		
		RecordSet.Filter.VersionNumber.Value = RecordKey.VersionNumber;
		RecordSet.Filter.VersionNumber.ComparisonType = ComparisonType.Equal;
		RecordSet.Filter.VersionNumber.Use = True;
		
		RecordSet.Write(True);
	EndDo;
	
	Items.List.Refresh();
	
EndProcedure

#EndRegion
