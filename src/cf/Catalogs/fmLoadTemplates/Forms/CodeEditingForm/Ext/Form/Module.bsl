
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If ValueIsFilled(Parameters.Code) Then
		Code = Parameters.Code;
	Else
		Code = NStr("en='// The code is running on the server."
"// The ""Value"" variable contains a read-in value, and the final value is also assigned to this value."
"// The ""Attributes"" structure contains read-in unit values."
""
"Value = Value;';ru='// Код выполняется на сервере."
"// Переменная ""Значение"" содержит считанное значение, в нее же присваивается итоговое значение."
"// Структура ""Реквизиты"" содержит считанные единичные значения."
""
"Значение = Значение;'");
	EndIf;
EndProcedure

&AtClient
Procedure OK(Command)
	Close(TrimAll(Code));
EndProcedure
