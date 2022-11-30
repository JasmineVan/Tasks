
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If NOT Parameters.Property("StructureVersion") Then
		UseDepartmentsStructures = Constants.fmDepartmentsStructuresVersions.Get();
	EndIf;
	ConditionalAppearanceAtServer();
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	If UseDepartmentsStructures Then
		Cancel = True;
		OpenForm("Catalog.fmDepartments.Form.VersionListForm",, FormOwner);
	EndIf;
EndProcedure

&AtClient
Procedure ChangeDepartmentType(Command)
	CurRow = Items.List.CurrentRow;
	If CurRow = Undefined Then
		CommonClientServer.MessageToUser(NStr("en='You should select a department to be modified.';ru='Необходимо выбрать подразделение для изменения'"),);
	Else
		If CurRow = Undefined Then
			CommonClientServer.MessageToUser(NStr("en='You should select a row with a department.';ru='Необходимо выделить строку с подразделением'"));
			Return;
		EndIf;
		Handler = New NotifyDescription("ChangeColor",ThisObject);
		OpenForm("Catalog.fmDepartments.Form.ChangeColorForm", New Structure("CurDepartment", CurRow),ThisForm,,,,Handler,FormWindowOpeningMode.Independent);
	EndIf;
EndProcedure

&AtServer
Procedure ChangeColor(Sel,AddPar)
	If NOT ValueIsFilled(Sel.SetType) Then
		Return;
	EndIf;
	ChangeColorAtServer(Sel);
	ConditionalAppearanceAtServer();
EndProcedure

&AtServer
Procedure ConditionalAppearanceAtServer()
	Catalogs.fmDepartments.ColorTreeItems(ConditionalAppearance,"List","List.DepartmentType","List.Ref");
EndProcedure

&AtServer
Procedure ChangeColorAtServer(ChosenValue)
	If TypeOf(ChosenValue) = Type("Structure") Then
		WithChildren = ChosenValue.WithChildren;
		SetType = ChosenValue.SetType;
		CurDepartment = ChosenValue.CurDepartment;
		CurItem = Items.List.CurrentRow;
		If NOT WithChildren Then
			//меняем тип только тек подразделения
			CurDepObject = CurDepartment.GetObject();
			CurDepObject.DepartmentType = SetType;
			If CurDepObject.DeletionMark Then
				WarnText = StrTemplate(NStr("en='Department %1% is marked for deletion. For this reason, the color will not be updated in the list';ru='Подразделение %1% помечено на удаление. Цвет не будет обновлен в списке'"), String(CurDepObject));
				CommonClientServer.MessageToUser(WarnText);
			EndIf;
			Try
				CurDepObject.Write();
			Except
				CommonClientServer.MessageToUser(ErrorDescription());
			EndTry;
		ElsIf ValueIsFilled(CurItem) Then
			//меняем только то, что видим, поэтому будем брать внутренние элементы через дерево на форме
			ChangedDepartmentsArray = New Array;
			ChangedDepartmentsArray.Add(CurItem);
			ChildSelection = Catalogs.fmDepartments.SELECT(CurItem);
			While ChildSelection.Next() Do
				ChangedDepartmentsArray.Add(ChildSelection.Ref);
			EndDo;
			For Each oDepartment In ChangedDepartmentsArray Do
				If oDepartment.DeletionMark Then
					WarnText = StrTemplate(NStr("en='Department %1% is marked for deletion. For this reason, the color will not be updated in the list';ru='Подразделение %1% помечено на удаление. Цвет не будет обновлен в списке'"), String(oDepartment));
					CommonClientServer.MessageToUser(WarnText);
				EndIf;
				CurDepObject = oDepartment.GetObject();
				CurDepObject.DepartmentType = SetType;
				Try
					CurDepObject.Write();
				Except
					CommonClientServer.MessageToUser(ErrorDescription());
				EndTry;
			EndDo;
		EndIf;
	EndIf;
EndProcedure

&AtClient
//Обработчки нажатия на кнопку "Организационная структура"
//
Procedure GenerateOrgStructureReport(Command)
	OpeningParameters = New Structure;
	OpeningParameters.Insert("Department",	Items.List.CurrentRow);
	OpeningParameters.Insert("GenerateOnOpen", True);
	OpenForm("Report.fmOrganizationalDepartmentsStructure.Form.ReportForm", OpeningParameters);
EndProcedure //СформироватьОтчетОргСтруктуры()



