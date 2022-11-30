
#If Server OR ThickClientOrdinaryApplication OR ExternalConnection Then

Var mIsNew; // Для определения при записи элемента новый или нет.
Var mOldCompany;
Var mOldResponsible;

Procedure OnWrite(Cancel)
	If mIsNew OR mOldResponsible<>Responsible Then
		NewRecord = InformationRegisters.fmStateBalanceUnit.CreateRecordManager();
		NewRecord.BalanceUnit = Ref;
		NewRecord.Responsible = Responsible;
		NewRecord.Period = CurrentSessionDate();
		Try
			NewRecord.Write();
		Except
		EndTry;
	EndIf;
EndProcedure

Procedure BeforeWrite(Cancel)
	mIsNew = IsNew();
	mOldResponsible = Ref.Responsible;
EndProcedure

#EndIf


