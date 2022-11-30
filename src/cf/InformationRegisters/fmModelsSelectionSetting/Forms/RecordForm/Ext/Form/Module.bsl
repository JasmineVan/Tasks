
&AtClient
// Процедура обработчик "ПередЗаписью" 
//
Procedure BeforeWrite(Cancel, RecordParameters)
	
	// Произведем необходимые проверки перез записью.
	If (ValueIsFilled(Record.AmountFrom) OR ValueIsFilled(Record.AmountTo)) AND NOT ValueIsFilled(Record.Currency) Then
		CommonClientServer.MessageToUser("Поле ""Валюта"" не заполнено", , , , , Cancel);
	EndIf;
	
	If Record.AmountFrom > Record.AmountTo Then
		CommonClientServer.MessageToUser("Сумма от должна быть меньше суммы до", , , , , Cancel);
	EndIf;
	
EndProcedure
