
////////////////////////////////////////////////////////////////////////////////
// ОБРАБОТЧИКИ СОБЫТИЙ ОБЪЕКТА

// Процедура обработчик "ОбработкаЗаполнения" 
//
Procedure Filling(FillingData, StandardProcessing)
	
	If IsNew() Then
		RndGen      = New RandomNumberGenerator();
		Red  = RndGen.RandomNumber(0, 255);
		Blue    = RndGen.RandomNumber(0, 255);
		Green  = RndGen.RandomNumber(0, 255);
		ColorType = NStr("en='Absolute';ru='Абсолютный'");
	EndIf;
	
EndProcedure

// Процедура обработчик "ОбработкаПроверкиЗаполнения" 
//
Procedure FillCheckProcessing(Cancel, CheckingAttributes)
	
	If DataExchange.Load Then
		Return;
	EndIf;
		
	// Проверим, чтобы указанная точка возврата была из списка возможных точек возврата.
	If StageCompleted = 0 AND ValueIsFilled(ReturnPoint)
	AND fmProcessManagement.GettingPreviousStagesList(Owner, 1).Find(ReturnPoint) = Undefined Then
		CommonClientServer.MessageToUser(NStr("en='The specified return point is not included in possible return points of the selected route point.';ru='Указанная точка возврата не входит в возможные точки возврата выбранной точки маршрута!'"), , , , Cancel);
	EndIf;
	
	If StageCompleted = 0 AND Owner.PointsPredecessors.Count() = 0 Then
		CommonClientServer.MessageToUser(NStr("en='For the route start point, the returning to the previous level status is prohibited.';ru='Для начальной точки маршрута не допустимо состояния с возвратом на предыдущий уровень!'"), , , , Cancel);
	EndIf;
	
EndProcedure


