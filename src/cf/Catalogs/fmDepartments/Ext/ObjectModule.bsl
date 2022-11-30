
Var mIsNew; // Для определения при записи элемента новый или нет.
Var mOldBalanceUnit;
Var mOldDepartmentType;
Var mOldParent;
Var mParent;
Var mOldResponsible;

#If Server OR ThickClientOrdinaryApplication OR ExternalConnection Then

Procedure BeforeWrite(Cancel)
	
	mIsNew = IsNew();
	mOldBalanceUnit = Ref.BalanceUnit;
	mOldDepartmentType = Ref.DepartmentType;
	mOldParent = Ref.Parent;
	mOldResponsible = Ref.Responsible;
	mParent = Parent;
	
	If NOT fmBudgeting.ReturnDepartmentStructureActualVersion()=StructureVersion Then
		Parent = mOldParent;
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If mIsNew AND ValueIsFilled(StructureVersion) Then
		NewRecord = InformationRegisters.fmDepartmentHierarchy.CreateRecordManager();
		NewRecord.StructureVersion = StructureVersion;
		NewRecord.Department = Ref;
		NewRecord.DepartmentParent = mParent;
		NewRecord.Level = fmBudgeting.ReturnParentLevelFromIR(mParent, StructureVersion) + 1;
		Try
			NewRecord.Write();
		Except
			CommonClientServer.MessageToUser(NStr("en='Failed to save a new department to the hierarchy';ru='Не удалось записать новое подразделение в иерархию'"),,,,Cancel);
		EndTry;
	EndIf;
	
	If mOldDepartmentType<>DepartmentType OR mOldBalanceUnit<>BalanceUnit OR mOldResponsible <> Responsible Then
		//Проверим, изменялись ли периодические реквизиты за текущий месяц для данного подразделения
		DepartmentsState = InformationRegisters.fmDepartmentsState.CreateRecordManager();
		DepartmentsState.Department = Ref;
		DepartmentsState.DepartmentType = DepartmentType;
		DepartmentsState.BalanceUnit = BalanceUnit;
		DepartmentsState.Responsible = Responsible;
		DepartmentsState.Period = CurrentSessionDate();
		Try
			DepartmentsState.Write();
		Except
			CommonClientServer.MessageToUser(NStr("en='Failed to save changes in the department status';ru='Не удалось записать изменения в состоянии подразделения'"),,,,Cancel);
		EndTry;
	EndIf;
	
	If NOT mIsNew AND (mOldParent<>mParent OR mOldResponsible<>Responsible OR mOldBalanceUnit<>BalanceUnit) Then
		NewRecord = InformationRegisters.fmDepartmentHierarchy.CreateRecordSet();
		NewRecord.Filter.StructureVersion.Set(StructureVersion);
		NewRecord.Filter.Department.Set(Ref);
		NewRecord.Read();
		NewRecord[0].DepartmentParent = mParent;
		Try
			NewRecord.Write();
		Except
			CommonClientServer.MessageToUser(NStr("en='Failed to change a department in the hierarchy';ru='Не удалось изменить подразделение в иерархии'"),,,,Cancel);
		EndTry;
	EndIf;
EndProcedure

Procedure Filling(FillingData, FillingText, StandardProcessing)
	BalanceUnit = fmCommonUseServer.GetDefaultValue("MainBalanceUnit");
	StructureVersion = fmBudgeting.ReturnDepartmentStructureActualVersion();
EndProcedure

#EndIf
