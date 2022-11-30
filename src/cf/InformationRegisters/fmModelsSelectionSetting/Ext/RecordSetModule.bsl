
// Процедура - обработчик события объекта "ПередЗаписью"
//
Procedure BeforeWrite(Cancel, Replacement)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	For Each CurRecord In ThisObject Do
		Query = New Query;
		Query.Text = "SELECT ALLOWED
		               |	ModelsSelectionSetting.AgreementRoute,
		               |	ModelsSelectionSetting.DocumentType,
		               |	ModelsSelectionSetting.OperationType,
		               |	ModelsSelectionSetting.BalanceUnit,
		               |	ModelsSelectionSetting.Department,
		               |	ModelsSelectionSetting.AmountFrom,
		               |	ModelsSelectionSetting.Currency,
		               |	ModelsSelectionSetting.AmountTo
		               |FROM
		               |	InformationRegister.fmModelsSelectionSetting AS ModelsSelectionSetting
		               |WHERE
		               |	ModelsSelectionSetting.BalanceUnit = &BalanceUnit
		               |	AND ModelsSelectionSetting.DocumentType = &DocumentType
		               |	AND ModelsSelectionSetting.OperationType = &OperationType
		               |	AND ModelsSelectionSetting.Department = &Department
		               |	AND ModelsSelectionSetting.Currency = &Currency
		               |	AND (NOT(ModelsSelectionSetting.AmountFrom < &AmountFrom
		               |					AND ModelsSelectionSetting.AmountTo < &AmountFrom
		               |				OR ModelsSelectionSetting.AmountFrom > &AmountTo
		               |					AND ModelsSelectionSetting.AmountTo > &AmountTo))
		               |	AND ModelsSelectionSetting.AmountFrom <> &AmountFrom";
		
		Query.Parameters.Insert("BalanceUnit", CurRecord.BalanceUnit);
		Query.Parameters.Insert("Department", CurRecord.Department);
		Query.Parameters.Insert("DocumentType", CurRecord.DocumentType);
		Query.Parameters.Insert("OperationType", CurRecord.OperationType);
		Query.Parameters.Insert("Currency", CurRecord.Currency);
		Query.Parameters.Insert("AmountFrom", CurRecord.AmountFrom);
		Query.Parameters.Insert("AmountTo", CurRecord.AmountTo);
		
		Selection = Query.Execute().SELECT();
		If Selection.Next() Then
			CommonClientServer.MessageToUser("Некорректно введены сумма от и до! Пересекаются интервалы с ранее введенными записями!", , , , , Cancel);
		EndIf;
	EndDo;
	
EndProcedure // ПередЗаписью()
