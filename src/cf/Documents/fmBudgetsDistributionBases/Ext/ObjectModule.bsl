
#If Server OR ThickClientOrdinaryApplication OR ExternalConnection Then

#Region EventsHandlers

Procedure FillCheckProcessing(Cancel, CheckingAttributes)
	
	If DistributionBase.BaseType=Enums.fmDistributionBaseTypes.ProjectsBase Then
		If NOT ValueIsFilled(DistributionDepartment) Then
			CommonClientServer.MessageToUser(NStr("en='The ""Department"" field is not filled in.';ru='Поле ""Подразделение"" не заполнено!'"), , , , Cancel);
		EndIf;
	EndIf;
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	// Регистр БазыРаспределения.
	RegisterRecords.fmBudgetsDistributionBases.Write = True;
	For Each BaseCurRow In Bases Do
		If BaseCurRow.Active Then
			RegisterRecord = RegisterRecords.fmBudgetsDistributionBases.Add();
			RegisterRecord.DateFrom = BegOfMonth(DATE);
			RegisterRecord.DateTo = EndOfMonth(EndDate);
			RegisterRecord.DistributionBase = DistributionBase;
			RegisterRecord.BalanceUnit = BalanceUnit;
			RegisterRecord.DistributionDepartment = DistributionDepartment;
			RegisterRecord.DistributionItem = DistributionItem;
			RegisterRecord.DistributionProject = DistributionProject;
			RegisterRecord.Department = BaseCurRow.Department;
			RegisterRecord.Project = BaseCurRow.Project;
			RegisterRecord.Scenario = Scenario;
			RegisterRecord.BaseValue = BaseCurRow.BaseValue;
		EndIf;
	EndDo;
	
EndProcedure

Procedure Filling(FillingData, FillingText, StandardProcessing)
	// en script begin
	//ЗаполнениеДокументов.Заполнить(ЭтотОбъект, ДанныеЗаполнения);
	// en script end
EndProcedure

#EndRegion

#EndIf
