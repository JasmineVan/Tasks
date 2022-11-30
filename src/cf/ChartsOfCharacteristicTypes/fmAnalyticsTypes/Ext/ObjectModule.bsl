
#If Server OR ThickClientOrdinaryApplication OR ExternalConnection Then

Procedure FillCheckProcessing(Cancel, CheckingAttributes)
	If ValueType.Types().Count()>1 Then
		CommonClientServer.MessageToUser(NStr("ru='Составной тип значения запрещён!';en='A composite value type is prohibited.'"), , , , Cancel);
	EndIf;
EndProcedure

#EndIf
