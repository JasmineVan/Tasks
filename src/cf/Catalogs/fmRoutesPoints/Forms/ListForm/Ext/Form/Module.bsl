
&AtClient
// Процедура обработчик события "СписокПриАктивизацииСтроки" 
//
Procedure ListOnActivateRow(Item)
	fmCommonUseClientServer.ChangeListFilterItem(PointStates, "Owner", Items.List.CurrentRow, True);
EndProcedure

&AtClient
// Процедура обработчик команды "Проверить" 
//
Procedure Check(Command)
	If ValueIsFilled(AgreementRoute) Then
		fmProcessManagement.RouteCorrectnessCheck(AgreementRoute);
	Else
		CommonClientServer.MessageToUser(NStr("en='The filter by route is not set.';ru='Не установлен отбор по маршруту!'"));
	EndIf;
EndProcedure

&AtClient
// Процедура обработчик события "ТочкиПредшественникиВыбор" 
//
Procedure PointsPredecessorsChoice(Item, SelectedRow, Field, StandardProcessing)
	OpenValue(Items.PointsPredecessors.CurrentData.RoutePoint);
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Filter.Property("Owner") AND ValueIsFilled(Parameters.Filter.Owner) Then
		AgreementRoute = Parameters.Filter.Owner;
	EndIf;
EndProcedure
