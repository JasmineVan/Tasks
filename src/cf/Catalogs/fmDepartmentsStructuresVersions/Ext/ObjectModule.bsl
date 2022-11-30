
#If Server OR ThickClientOrdinaryApplication OR ExternalConnection Then
	
Procedure Filling(FillingData, FillingText, StandardProcessing)
	MostLastVersion = fmBudgeting.ReturnDepartmentStructureActualVersion();
	VersionDates = ReturnVersionDates(MostLastVersion);
	If ValueIsFilled(VersionDates.VersionEndDate) Then
		If CurrentDate()>VersionDates.VersionEndDate Then
			ApprovalDate = EndOfMonth(CurrentDate())+1;
		Else
			ApprovalDate = EndOfDay(VersionDates.VersionEndDate)+1;
		EndIf;
	Else
		ApprovalDate = EndOfMonth(EndOfYear(VersionDates.ApprovalDate))+1;
	EndIf;
	LanguageCode = NStr("en='en';ru='ru'");
	Description = NStr("en='Valid from ';ru='Действительна с '") + Format(ApprovalDate, "L=" + LanguageCode + "; DF='MMMM yyyy'");
	DateValidUntil = EndOfYear(ApprovalDate);
EndProcedure
	
Procedure OnWrite(Cancel)
	If DataExchange.Load Then
		Return;
	EndIf;
EndProcedure
	
Procedure BeforeWrite(Cancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	If NOT ThisObject.DeletionMark Then
		If DateValidUntil = DATE("00010101") Then
			ActionDate = DATE("39991231");
		Else
			ActionDate = DateValidUntil;
		EndIf;
		
		Query = New Query;
		Query.Text = "SELECT
		               |	DepartmentsStructuresVersions.ApprovalDate AS ApprovalDate,
		               |	DepartmentsStructuresVersions.Ref AS Ref,
		               |	DepartmentsStructuresVersions.DateValidUntil AS DateValidUntil
		               |FROM
		               |	Catalog.fmDepartmentsStructuresVersions AS DepartmentsStructuresVersions
		               |WHERE
		               |	NOT DepartmentsStructuresVersions.DeletionMark
		               |	AND DepartmentsStructuresVersions.ApprovalDate <= &EndDate
		               |	AND (DepartmentsStructuresVersions.DateValidUntil >= &BeginDate
		               |			OR DepartmentsStructuresVersions.DateValidUntil = &EmptyDate)
		               |	AND NOT DepartmentsStructuresVersions.Ref = &VersionToExclude
		               |
		               |ORDER BY
		               |	ApprovalDate DESC";
					   
		Query.SetParameter("BeginDate", ApprovalDate);
		Query.SetParameter("EndDate", DateValidUntil);
		Query.SetParameter("VersionToExclude", Ref);
		Query.SetParameter("EmptyDate",DATE("00010101"));
		SelectionOfExistingVersionsDates = Query.Execute().Unload();
		VersionsList = New ValueList;
		
		// Проверим на наличие версии с пустой датой и очистим ,если версии пересекаются.
		Selection = Query.Execute().SELECT();
		While Selection.Next() Do
			If NOT ValueIsFilled(Selection.DateValidUntil) Then
				VersionToChange = Catalogs.fmDepartmentsStructuresVersions.FindByAttribute("DateValidUntil",DATE('00010101')).GetObject();
				VersionToChange.DateValidUntil = EndOfYear(VersionToChange.ApprovalDate);
				VersionToChange.Write();
				FoundVersion = SelectionOfExistingVersionsDates.FindRows(New Structure("DateValidUntil",DATE('00010101')));
				For Each TableRow In FoundVersion Do
					SelectionOfExistingVersionsDates.Delete(TableRow);
				EndDo;
			EndIf;
		EndDo;
		If SelectionOfExistingVersionsDates.Count()>0 Then
			VersionsArray = SelectionOfExistingVersionsDates.UnloadColumn("Ref");
			VersionsArray = SelectionOfExistingVersionsDates.UnloadColumn("DateValidUntil");
			VersionsList.LoadValues(VersionsArray);
		EndIf;
		
		If VersionsList.Count() > 0 Then
			CommonClientServer.MessageToUser(NStr("en='Period versions cannot be overlapped.';ru='Периоды версий не должны пересекаться!'"),,,,Cancel);
		EndIf;
	EndIf;
EndProcedure
	
Function ReturnVersionDates(Version)
	Return New Structure("ApprovalDate, VersionEndDate", Version.ApprovalDate, Version.DateValidUntil);
EndFunction
	
#EndIf
