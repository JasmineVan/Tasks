
#If Server OR ThickClientOrdinaryApplication OR ExternalConnection Then

////////////////////////////////////////////////////////////////////////////////
// ПРОЦЕДУРЫ И ФУНКЦИИ ОБЩЕГО НАЗНАЧЕНИЯ

// Устанавливает/снимает признак активности движений документа в зависимости от пометки удаления.
// Следует вызывать перед записью измененной пометки удаления.
// Помеченный на удаление документ не должен иметь активных движений.
// Не помеченный на удаление документ может иметь неактивные движения.
Procedure SynchronizeRecordActivitiesWithDeletionMark()
	
	
	If NOT DeletionMark 
		AND Common.ObjectAttributeValue(Ref, "DeletionMark") = DeletionMark Then
		// Не помеченный на удаление документ может иметь неактивные движения.
		// Однако, при снятии пометки удаления все движения становятся активными.
		Return;
	EndIf;
	
	Active = NOT DeletionMark;
	
	For Each RegisterRecord In RegisterRecords Do
		
		If RegisterRecord.Write = False Then // При работе формы набор может быть уже "потроган" (прочитан, модифицирован)
			// Набор никто не трогал
			RegisterRecord.Read();
		EndIf;
		
		For Each String In RegisterRecord Do
			
			If String.Active = Active Then
				Continue;
			EndIf;
			
			String.Active   = Active;
			RegisterRecord.Write = True; // На случай, если набор был прочитан выше
			
		EndDo;
		
	EndDo;
	
EndProcedure
		
////////////////////////////////////////////////////////////////////////////////
// ПРОЦЕДУРЫ - ОБРАБОТЧИКИ СОБЫТИЙ

Procedure OnCopy(CopyObject)

	DATE = BegOfDay(Common.CurrentUserDate());
	Responsible = Users.CurrentUser();
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	// en script begin
	//ЗаполнениеДокументов.Заполнить(ЭтотОбъект, ДанныеЗаполнения);
	// en script end
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)

	If DataExchange.Load Then
		Return;
	EndIf;
	
	For Each RecordSet In RegisterRecords Do
		
		If RecordSet.Count() = 0 Then
			Continue;
		EndIf;
		
		EmptyTable   = RecordSet.UnloadColumns();
		HasBalanceUnit = EmptyTable.Columns.Find("BalanceUnit") <> Undefined;
		HasPeriod      = EmptyTable.Columns.Find("Period") <> Undefined;
		HasScenario = EmptyTable.Columns.Find("Scenario")<> Undefined;
		
		If NOT (HasBalanceUnit OR HasPeriod OR HasScenario) Then
			Continue;
		EndIf;
		
		RecordTable = RecordSet.Unload();
		If HasBalanceUnit Then
			RecordTable.FillValues(BalanceUnit, "BalanceUnit");
		EndIf;
		If HasPeriod Then
			RecordTable.FillValues(DATE, "Period");
		EndIf;
		If HasScenario Then
			RecordTable.FillValues(Scenario, "Scenario");
		EndIf;
		RecordSet.Load(RecordTable);
		OperationAmount = RecordSet.Total("Amount");
		
	EndDo;
	
	SynchronizeRecordActivitiesWithDeletionMark();
	
EndProcedure // ПередЗаписью()

#EndIf
