
#Region FormEventsHandlers

&AtClient
Procedure BeforeWrite(Cancel, RecordParameters)
	LanguageCode = NStr("en='en';ru='ru'");
	If Object.ApprovalDate > Object.DateValidUntil Then
		If Object.DateValidUntil <> DATE("00010101") Then
			CommonClientServer.MessageToUser(NStr("en='The end date cannot be earlier than the version start date!';ru='Дата окончания не может быть меньше даты начала действия версии!'"),,,,Cancel);
		EndIf;
	EndIf;
	
	If DateVersionExists(Object.ApprovalDate, Object.Ref) Then
		CommonClientServer.MessageToUser(NStr("en='The version as of the date already exists';ru='Уже существует версия на дату '") + Format(Object.ApprovalDate, "L=" + LanguageCode + "; DF='MMMM yyyy'") + NStr("en=' already exists!';ru='!'"),,,,Cancel);
	EndIf;
EndProcedure

&AtClient
Procedure AfterWrite(RecordParameters)
	If IsNew Then
		StrParameters = New Structure;
		StrParameters.Insert("NewVersionRef", Object.Ref);
		StrParameters.Insert("ApprovalDate", Object.ApprovalDate);
		StrParameters.Insert("DateValidUntil", Object.DateValidUntil);
		Notify("NewHierarchyVersionCreated", StrParameters);
	EndIf;
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	IsNew = NOT ValueIsFilled(Object.Ref);
	LanguageCode = NStr("en='en';ru='ru'");
	PeriodFrom = Format(Object.ApprovalDate, "L=" + LanguageCode + "; DF='MMMM yyyy'");
	PeriodTill = Format(Object.DateValidUntil, "L=" + LanguageCode + "; DF='MMMM yyyy'");
EndProcedure

&AtClient
Procedure ChoiceProcessing(ChosenValue, ChoiceSource)
	LanguageCode = NStr("en='en';ru='ru'");
	Object.Description = NStr("en='Valid from ';ru='Действительна с '") + Format(Object.ApprovalDate, "L=" + LanguageCode + "; DF='MMMM yyyy'");
	If EndOfYear(Object.ApprovalDate) <> EndOfYear(Object.DateValidUntil) Then
		PeriodTill = Format(EndOfYear(Object.ApprovalDate), "L=" + LanguageCode + "; DF='MMMM yyyy'");
		Object.DateValidUntil = EndOfYear(Object.ApprovalDate);
	EndIf
EndProcedure

#EndRegion

#Region ProceduresAndFunctionsOfCommonUse

&AtServerNoContext
Function DateVersionExists(StartVersionDate, Ref)
	Query = New Query;
	Query.Text = "SELECT
	|	DepartmentsStructuresVersions.Ref
	|FROM
	|	Catalog.fmDepartmentsStructuresVersions AS DepartmentsStructuresVersions
	|WHERE
	|	NOT DepartmentsStructuresVersions.DeletionMark
	|	AND DepartmentsStructuresVersions.ApprovalDate = &VersionApprovalDate
	|	AND NOT DepartmentsStructuresVersions.Ref = &Ref";
	
	Query.SetParameter("VersionApprovalDate", StartVersionDate);
	Query.SetParameter("Ref", Ref);
	Selection = Query.Execute().SELECT();
	If Selection.Next() Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction

#EndRegion

#Region FormItemsEventsHandlers

&AtClient
Procedure PeriodFromOnChange(Item)
	fmCommonUseClient.MonthInputOnChange(ThisForm, "Object.ApprovalDate", "PeriodFrom", Modified);
EndProcedure

&AtClient
Procedure PeriodFromStartChoice(Item, ChoiceData, StandardProcessing)
	fmCommonUseClient.MonthInputStartChoice(ThisForm, ThisForm, "Object.ApprovalDate", "PeriodFrom", ,);
EndProcedure

&AtClient
Procedure PeriodFromTuning(Item, Direction, StandardProcessing)
	fmCommonUseClient.MonthInputTuning(ThisForm, "Object.ApprovalDate", "PeriodFrom", Direction, Modified);
EndProcedure

&AtClient
Procedure PeriodFromAutoComplete(Item, Text, ChoiceData, GetDataParameters, Waiting, StandardProcessing)
	fmCommonUseClient.MonthInputTextAutoComplete(Text, ChoiceData, StandardProcessing);
EndProcedure

&AtClient
Procedure PeriodFromTextEditEnd(Item, Text, ChoiceData, GetDataParameters, StandardProcessing)
	fmCommonUseClient.MonthInputTextEditEnd(Text, ChoiceData, StandardProcessing);
EndProcedure

&AtClient
Procedure PeriodTillOnChange(Item)
	fmCommonUseClient.MonthInputOnChange(ThisForm, "Object.DateValidUntil", "PeriodTill", Modified);
EndProcedure

&AtClient
Procedure PeriodTillStartChoice(Item, ChoiceData, StandardProcessing)
	fmCommonUseClient.MonthInputStartChoice(ThisForm, ThisForm, "Object.DateValidUntil", "PeriodTill", ,);
EndProcedure

&AtClient
Procedure PeriodTillTuning(Item, Direction, StandardProcessing)
	fmCommonUseClient.MonthInputTuning(ThisForm, "Object.DateValidUntil", "PeriodTill", Direction, Modified);
EndProcedure

&AtClient
Procedure PeriodTillAutoComplete(Item, Text, ChoiceData, GetDataParameters, Waiting, StandardProcessing)
	fmCommonUseClient.MonthInputTextAutoComplete(Text, ChoiceData, StandardProcessing);
EndProcedure

&AtClient
Procedure PeriodTillTextEditEnd(Item, Text, ChoiceData, GetDataParameters, StandardProcessing)
	fmCommonUseClient.MonthInputTextEditEnd(Text, ChoiceData, StandardProcessing);
EndProcedure

&AtClient
Procedure PeriodFromChoiceProcessing(Item, ChosenValue, StandardProcessing)
	LanguageCode = NStr("en='en';ru='ru'");
	Object.Description = NStr("en='Valid from ';ru='Действительна с '") + Format(Object.ApprovalDate, "L=" + LanguageCode + "; DF='MMMM yyyy'");
EndProcedure

#EndRegion


