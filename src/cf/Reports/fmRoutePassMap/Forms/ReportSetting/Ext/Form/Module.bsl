
&AtClient
// Процедура обработчик команды "ОК" 
//
Procedure OK(Command)
	Close(True);
EndProcedure

&AtClient
Procedure ItemHeightOnChange(Item)
	If ItemHeight < 32 Then
		ItemHeight = 32;
	EndIf;
EndProcedure
