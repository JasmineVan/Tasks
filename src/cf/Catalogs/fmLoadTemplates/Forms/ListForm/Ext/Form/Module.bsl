
&AtClient
Procedure Load(Command)
	CurRow = Items.List.CurrentRow;
	If NOT CurRow = Undefined Then
		OpeningParameters = New Structure("LoadTemplate", CurRow);
		OpenForm("Catalog.fmLoadTemplates.Form.ImportForm", OpeningParameters);
	EndIf;
EndProcedure

&AtClient
Procedure ExportImport(Command)
	SelectedRowsList = New ValueList;
	For Each RowArr In Items.List.SelectedRows Do
		SelectedRowsList.Add(RowArr);
	EndDo;
	OpenForm("CommonForm.fmExportImportForm", 
		New Structure("Title, SelectedRows, ExportObjectName",
			NStr("en='Export/import of import templates';ru='Экспорт/импорт шаблонов загрузки'"), SelectedRowsList, "Catalogs.fmLoadTemplates"),
		ThisForm,,,,,FormWindowOpeningMode.LockOwnerWindow);
EndProcedure


