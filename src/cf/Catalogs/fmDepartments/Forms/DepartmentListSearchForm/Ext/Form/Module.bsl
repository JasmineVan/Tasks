
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("CurColumn") Then
		If Parameters.CurColumn = "DepartmentTreeMainDepartment" OR Parameters.CurColumn = "Tree2Description" Then
			//по подразделению
			If Parameters.Property("CurDepartment") Then
				SearchAttribute = "1";
				SearchValue = String(Parameters.CurDepartment.Description);
			EndIf;
		Else
			//по коду
			If Parameters.Property("CurDepartmentCode") Then
				SearchAttribute = "2";
				SearchValue = String(Parameters.CurDepartmentCode);
			EndIf;
		EndIf;
	EndIf;
	If Parameters.Property("ParentDepartment") Then
		CurrentGroup = ?(Parameters.ParentDepartment = Undefined, NStr("en='Root group';ru='Корневая группа'") , Parameters.ParentDepartment	);
	Else
		CurrentGroup = NStr("en='Root group';ru='Корневая группа'");
	EndIf;
	SearchMethod = 2;
EndProcedure

#EndRegion

#Region CommandHandlers

&AtClient
Procedure ExecuteSearch(Command)
	ResSearchStructure = New Structure;
	ResSearchStructure.Insert("SearchAttribute", SearchAttribute);
	ResSearchStructure.Insert("SearchValue", SearchValue);
	ResSearchStructure.Insert("SearchMethod", SearchMethod);
	If ValueIsFilled(CurrentGroup) AND TypeOf(CurrentGroup)= Type("CatalogRef.fmDepartments") Then
		If SearchInCurrentGroupOnly Then
			ResSearchStructure.Insert("RootDepartment", CurrentGroup);
		EndIf;
	EndIf;
	ThisForm.Close(ResSearchStructure);
EndProcedure

&AtClient
Procedure CloseForm(Command)
	ThisForm.Close(Undefined);
EndProcedure

#EndRegion
