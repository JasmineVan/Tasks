
#If Server OR ThickClientOrdinaryApplication OR ExternalConnection Then
	
&AtServer
Procedure RefreshLevelsAtServer() Export
	Query = New Query;
	Query.Text = "SELECT
	               |	DepartmentsStructuresVersions.Ref
	               |FROM
	               |	Catalog.fmDepartmentsStructuresVersions AS DepartmentsStructuresVersions
	               |WHERE
	               |	NOT DepartmentsStructuresVersions.DeletionMark";
	Selection = Query.Execute().SELECT();
	
	While Selection.Next() Do
			oVersion = Selection.Ref;
			StrParameters = New Structure;
			StrParameters.Insert("StructureVersionForBuilding", oVersion);
			StrParameters.Insert("HeaderPeriodEnd", oVersion.DateValidUntil);
			StrParameters.Insert("LimitByAccessGroups", False);
			StrParameters.Insert("OutputTree", True);
			DepartmentTree = fmBudgeting.DepartmentCommonTree(StrParameters);
			FillDepartmentsTreeLevelsInRegister(oVersion,, DepartmentTree.Rows, 1);
	EndDo;
EndProcedure

&AtServer
Procedure FillDepartmentsTreeLevelsInRegister(oVersion, oHierarchyType, TreeRows, RowsLevel)
	For Each LevelRow In TreeRows Do
		//проставим в записях рс уровни и перейдм ниже
		RecordInIR = InformationRegisters.fmDepartmentHierarchy.CreateRecordManager();
		RecordInIR.StructureVersion = oVersion;
		RecordInIR.Department = LevelRow.Department;
		If TypeOf(LevelRow.Parent) = Type("CatalogRef.fmDepartments") Then
			RecordInIR.DepartmentParent = LevelRow.Parent;
		Else
			If NOT LevelRow.Parent = Undefined Then
				RecordInIR.DepartmentParent = LevelRow.Parent.Department;
			EndIf;
		EndIf;
		RecordInIR.Read();
		If RecordInIR.Selected() Then
			RecordInIR.Level = RowsLevel;
			RecordInIR.Write();
		EndIf;
		FillDepartmentsTreeLevelsInRegister(oVersion, oHierarchyType, LevelRow.Rows, RowsLevel + 1);
	EndDo;
EndProcedure

#EndIf
