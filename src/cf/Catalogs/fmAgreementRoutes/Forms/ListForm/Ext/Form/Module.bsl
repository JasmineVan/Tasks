
&AtClient
// Процедура обработчик команды "Проверить" 
//
Procedure Check(Command)
	CurRow = Items.List.CurrentRow;
	If ValueIsFilled(CurRow) Then
		fmProcessManagement.RouteCorrectnessCheck(CurRow);
	Else
		CommonClientServer.MessageToUser(NStr("en='The route is unselected.';ru='Не выделен маршрут!'"));
	EndIf;
EndProcedure

