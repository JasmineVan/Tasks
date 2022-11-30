
&AtClient
// Процедура обработчик "ПередЗаписью" 
//
Procedure BeforeWrite(Cancel, RecordParameters)
	
	If ValueIsFilled(Record.BeginDate) AND ValueIsFilled(Record.EndDate) 
	AND Record.BeginDate > Record.EndDate Then
		CommonClientServer.MessageToUser(NStr("en='The replacement start date must be less than the end date or equal it.';ru='Дата начала замены должна быть меньше или равна дате окончания!'"), , , ,Cancel);
	EndIf;
	
	If ValueIsFilled(Record.Responsible) AND ValueIsFilled(Record.ResponsibleReplacing) 
	AND Record.Responsible = Record.ResponsibleReplacing Then
		CommonClientServer.MessageToUser(NStr("en='A responsible person and a replacement responsible person shall be different!';ru='Ответственный и заменяющий должны быть разными!'"), , , ,Cancel);
	EndIf;
	
EndProcedure
