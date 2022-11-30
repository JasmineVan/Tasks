
#If Server OR ThickClientOrdinaryApplication OR ExternalConnection Then

Procedure BeforeWrite(Cancel)
	
	// Если элемент справочника пометили на удаление, то удалим все записи с данной структурой сведений из РС "Структуры сведений ввода и вывода данных"
	If Ref.DeletionMark = False AND DeletionMark = True Then 
		
		Query = New Query();
		Query.Text = "SELECT
		|	fmBindingInfoStructuresToDepartments.InfoStructure,
		|	fmBindingInfoStructuresToDepartments.Department
		|FROM
		|	InformationRegister.fmBindingInfoStructuresToDepartments AS fmBindingInfoStructuresToDepartments
		|WHERE
		|	fmBindingInfoStructuresToDepartments.InfoStructure = &InfoStructure";
		
		Query.SetParameter("InfoStructure", Ref);
		
		InfoStructureRegisterForDataInputAndOutput = InformationRegisters.fmBindingInfoStructuresToDepartments;
		
		Selection = Query.Execute().SELECT();
		While Selection.Next() Do
			Record = InfoStructureRegisterForDataInputAndOutput.CreateRecordManager();
			Record.InfoStructure 	= Selection.InfoStructure;
			Record.Department 		= Selection.Department;
			Record.Delete();
		EndDo;
	EndIf;
	
EndProcedure //ПередЗаписью()

#EndIf


