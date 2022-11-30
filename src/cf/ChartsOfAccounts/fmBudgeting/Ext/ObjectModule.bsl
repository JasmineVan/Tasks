
#Region StandardProceduresAndFunctions

// Стандартный обработчик ПередЗаписью элемента плана счетов
Procedure BeforeWrite(Cancel)
	
	Order = GetCodeOrder();
	If IsBlankString(Order) Then
		Order = Code;
	EndIf;
	
EndProcedure //ПередЗаписью()

#EndRegion
