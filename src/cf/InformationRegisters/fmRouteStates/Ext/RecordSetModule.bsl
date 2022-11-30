
// Функция определяет, есть ли переход на следующий уровень маршрута
//
Function IsTransitionToNextLevel(Document, RoutePoint, Version, LevelPointsList = Undefined, BalanceUnit)
	
	Query = New Query(
	"SELECT ALLOWED
	|	ProcessesPointsStagesPredecessors.Ref AS Ref
	|INTO TTFollowingPoints
	|FROM
	|	Catalog.fmRoutesPoints.PointsPredecessors AS ProcessesPointsStagesPredecessors
	|WHERE
	|	ProcessesPointsStagesPredecessors.RoutePoint = &RoutePoint
	|	AND NOT ProcessesPointsStagesPredecessors.Ref.DeletionMark
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	RoutesPointsPointsPredecessors.RoutePoint AS RoutePoint
	|INTO TTParallelPoints
	|FROM
	|	Catalog.fmRoutesPoints.PointsPredecessors AS RoutesPointsPointsPredecessors
	|WHERE
	|	RoutesPointsPointsPredecessors.Ref IN
	|			(SELECT
	|				TTFollowingPoints.Ref
	|			FROM
	|				TTFollowingPoints AS TTFollowingPoints)
	|	AND NOT RoutesPointsPointsPredecessors.RoutePoint.DeletionMark
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	RouteStatesSliceLast.RoutePoint,
	|	RouteStatesSliceLast.Department
	|FROM
	|	InformationRegister.fmRouteStates.SliceLast(
	|			,
	|			Document = &Document AND Version = &Version
	|				AND (RoutePoint IN
	|						(SELECT
	|							TTParallelPoints.RoutePoint
	|						FROM
	|							TTParallelPoints AS TTParallelPoints)
	|					AND %AddCondition)) AS RouteStatesSliceLast
	|WHERE
	|	(RouteStatesSliceLast.PointState = Value(Catalog.fmRoutePointsStates.EmptyRef)
	|			OR RouteStatesSliceLast.PointState.StageCompleted <> 1)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTParallelPoints.RoutePoint
	|FROM
	|	TTParallelPoints AS TTParallelPoints");
	
	Query.SetParameter("Document", Document);
	Query.SetParameter("Version", Version);
	Query.SetParameter("RoutePoint", RoutePoint);
	Query.SetParameter("Department", BalanceUnit);
	
	If ValueIsFilled(BalanceUnit) Then 
		
		AddCondition = "(RoutePoint <> &RoutePoint OR (RoutePoint = &RoutePoint AND Department <> &Department))";
		
		If fmProcessManagement.IsDynamicStage(Document) Then 
			
			//МассивБалансоваяЕдиница = Новый Массив();
			//МассивБалансоваяЕдиница.Добавить(Справочники.уфПодразделения.ПустаяСсылка());
			//БалансоваяЕдиницаДокумента = Документ.РасшифровкаПлатежа.Выгрузить(,"БалансоваяЕдиница");
			//БалансоваяЕдиницаДокумента.Свернуть("БалансоваяЕдиница");
			//Для Каждого ТекСтрока Из БалансоваяЕдиницаДокумента Цикл
			//	МассивБалансоваяЕдиница.Добавить(ТекСтрока.БалансоваяЕдиница);
			//КонецЦикла;
			//
			//ДопУсловие = ДопУсловие + " И БалансоваяЕдиница В (&МассивБалансоваяЕдиница)";
			//Запрос.УстановитьПараметр("МассивБалансоваяЕдиница", МассивБалансоваяЕдиница);
			
		EndIf;
	Else
		AddCondition = "RoutePoint <> &RoutePoint";
	EndIf;
	Query.Text = StrReplace(Query.Text, "%AddCondition", AddCondition);
	
	BathResult = Query.ExecuteBatch();
	If NOT LevelPointsList = Undefined Then
		LevelPointsList = BathResult[3].Unload().UnloadColumn("RoutePoint");
	EndIf;
	Result = BathResult[2].SELECT();
	If Result.Next() Then
		Return False;
	Else
		Return True;
	EndIf;
	
EndFunction // ЕстьПереходНаСледующийУровень()	

Procedure FinishAgreement(Record, Cancel)
	
	// Установим документу состояние утверждения и при необходимости проведем.
	fmProcessManagement.SetDocumentState(Record.Document, Catalogs.fmDocumentState.Approved, Record.Version, Cancel);
	
	// Сформируем комментарий для письма.
	CommentToLetter = fmProcessManagement.GetComments(Record.Document, Record.AgreementRoute, Record.Version);
	If ValueIsFilled(Record.Comment) Then
		If ValueIsFilled(CommentToLetter) Then
			CommentToLetter = CommentToLetter + Chars.LF + Chars.LF;
		EndIf;
		CommentToLetter = CommentToLetter + TrimAll(Record.Responsible) + " " + Record.Period + ":" + Chars.LF + Record.Comment;
	EndIf;
	
	If TypeOf(Record.Document)=Type("DocumentRef.fmBudget") Then
		
		VersionText = fmProcessManagement.GenerateVersionText(Record.Version);
		MessageTopic = NStr("en='The budget department is approved ""';ru='Согласован бюджет подразделения ""'") + TrimAll(Record.Document.Department) + NStr("en='"" for ';ru='"" за '") +
		Year(Record.Document.BeginOfPeriod) + NStr("en='year, scenario ""';ru=' год, сценарий ""'") + TrimAll(Record.Document.Scenario) + VersionText + """";
		
		LetterText = NStr("en='Hello, ';ru='Здравствуйте, '")+ TrimAll(Record.Document.Responsible) + "!" + Chars.LF + Chars.LF +
		NStr("en='The budget department is approved ""';ru='Согласован бюджет подразделения ""'") + TrimAll(Record.Document.Department) + NStr("en='"" for ';ru='"" за '") +
		Year(Record.Document.BeginOfPeriod) + NStr("en='year, scenario ""';ru=' год, сценарий ""'") + TrimAll(Record.Document.Scenario) + VersionText + NStr("en='"", Undergoing approval ""';ru='"", проходящий маршрут согласования ""'") +
		TrimAll(Record.AgreementRoute) + NStr("en='"" at the point ""';ru='"" в точке ""'") + TrimAll(Record.RoutePoint) + """.";
		If ValueIsFilled(CommentToLetter) Then
			LetterText = LetterText + Chars.LF + Chars.LF + NStr("en='Comments:';ru='Комментарии:'") + Chars.LF + CommentToLetter;
		EndIf;
		fmProcessManagement.AddRefToLetterText(LetterText, Record.Document);
		
		fmEmailManagement.SendMailViaNotification(Record.Document.Responsible, MessageTopic, LetterText);
		
		// Отправим при необходимости письма заменяющим.
		VTOfReplaces = fmProcessManagement.GetReplacesListParameters(Record.Document.Responsible);
		For Each CurReplace In VTOfReplaces Do
			
			MessageTopic = MessageTopic + NStr("en='(replacement of responsible';ru=' (замена ответственного '") + TrimAll(Record.Document.Responsible) + ")";
			
			LetterText = NStr("en='Hello, ';ru='Здравствуйте, '") + TrimAll(CurReplace.Replacing) + "!" + Chars.LF + Chars.LF +
			NStr("en='The budget department is approved ""';ru='Согласован бюджет подразделения ""'") + TrimAll(Record.Document.Department) + NStr("en='"" for ';ru='"" за '") +
			Year(Record.Document.BeginOfPeriod) + NStr("en='year, scenario ""';ru=' год, сценарий ""'") + TrimAll(Record.Document.Scenario) + VersionText + NStr("en='"", Undergoing approval ""';ru='"", проходящий маршрут согласования ""'") +
			TrimAll(Record.AgreementRoute) + NStr("en='"" at the point ""';ru='"" в точке ""'") + TrimAll(Record.RoutePoint) + """.";
			LetterText = LetterText + Chars.LF + NStr("en='The letter is initialized due to the replacement of a responsible person';ru='Письмо инициировано заменой ответственного пользователя '") + TrimAll(Record.Document.Responsible);
			If ValueIsFilled(CommentToLetter) Then
				LetterText = LetterText + Chars.LF + Chars.LF + NStr("en='Comments:';ru='Комментарии:'") + Chars.LF + CommentToLetter;
			EndIf;
			fmProcessManagement.AddRefToLetterText(LetterText, Record.Document);
			
			fmEmailManagement.SendMailViaNotification(CurReplace.Replacing, MessageTopic, LetterText);
			
		EndDo;
		
		// Удалим необработанные точки маршрута согласования 
		// (пустые записи могут быть в случае преждевременного согласования).
		fmProcessManagement.ClearEmptyRouteStates(Record.Document, Record.AgreementRoute, Record.Version, Cancel, " согласован досрочно", CommentToLetter);
		
		// Необходимо перекинуть движения с предвартельного бюджета в бюджет.
		// чтобы не тормозить проведение, просто перекинем сами движения.
		If Record.Document.OperationType=Enums.fmBudgetOperationTypes.Cashflows Then
			// ДДС.
			RecordSet = AccumulationRegisters.fmCashflowBudget.CreateRecordSet();
			RecordSet.Filter.Recorder.Set(Record.Document);
			RecordSet.Read();
			For Each CurRecord In RecordSet Do
				If CurRecord.VersionPeriod = Record.Version AND ValueIsFilled(CurRecord.NotAgreedAmount) Then
					CurRecord.Amount = CurRecord.NotAgreedAmount;
					CurRecord.CurrencyAmount = CurRecord.NotAgreedCurrencyAmount;
					CurRecord.NotAgreedAmount = 0;
					CurRecord.NotAgreedCurrencyAmount = 0;
				EndIf;
			EndDo;
			If RecordSet.Count()<>0 Then
				Try
					RecordSet.Write();
				Except
					CommonClientServer.MessageToUser("Не удалось провести бюджет!" + ErrorDescription(), , , , Cancel);
					Return;
				EndTry;
			EndIf;
		Else
			// ДиР.
			RecordSet = AccumulationRegisters.fmIncomesAndExpenses.CreateRecordSet();
			RecordSet.Filter.Recorder.Set(Record.Document);
			RecordSet.Read();
			For Each CurRecord In RecordSet Do
				If CurRecord.VersionPeriod = Record.Version AND ValueIsFilled(CurRecord.NotAgreedAmount) Then
					CurRecord.Amount = CurRecord.NotAgreedAmount;
					CurRecord.CurrencyAmount = CurRecord.NotAgreedCurrencyAmount;
					CurRecord.NotAgreedAmount = 0;
					CurRecord.NotAgreedCurrencyAmount = 0;
				EndIf;
			EndDo;
			If RecordSet.Count()<>0 Then
				Try
					RecordSet.Write();
				Except
					CommonClientServer.MessageToUser("Не удалось провести бюджет!" + ErrorDescription(), , , , Cancel);
					Return;
				EndTry;
			EndIf;
		EndIf;
		
	Else
		
		MessageTopic = "Согласована заявка на расход Departments """ + TrimAll(Record.Document.Department) + """ на " + Format(Record.Document.ExpenceDate, "DLF=DD");
		
		LetterText = "Здравствуйте, "+ TrimAll(Record.Document.Responsible) + "!" + Chars.LF + Chars.LF +
		"Согласована заявка на расход Departments """ + TrimAll(Record.Document.Department) + """ на " +
		Format(Record.Document.ExpenceDate, "DLF=DD") + ", проходящая маршрут согласования """ +
		TrimAll(Record.AgreementRoute) + """ IN точке """ + TrimAll(Record.RoutePoint) + """.";
		If ValueIsFilled(CommentToLetter) Then
			LetterText = LetterText + Chars.LF + Chars.LF + "Comments:" + Chars.LF + CommentToLetter;
		EndIf;
		fmProcessManagement.AddRefToLetterText(LetterText, Record.Document);
		
		fmEmailManagement.SendMailViaNotification(Record.Document.Responsible, MessageTopic, LetterText);
		
		// Отправим при необходимости письма заменяющим.
		VTOfReplaces = fmProcessManagement.GetReplacesListParameters(Record.Document.Responsible);
		For Each CurReplace In VTOfReplaces Do
			
			MessageTopic = MessageTopic + " (Replace ответственного " + TrimAll(Record.Document.Responsible) + ")";
			
			LetterText = "Здравствуйте, " + TrimAll(CurReplace.Replacing) + "!" + Chars.LF + Chars.LF +
			"Согласована заявка Departments """ + TrimAll(Record.Document.Department) + """ на " +
			Format(Record.Document.ExpenceDate, "DLF=DD") + ", проходящая маршрут согласования """ +
			TrimAll(Record.AgreementRoute) + """ IN точке """ + TrimAll(Record.RoutePoint) + """.";
			LetterText = LetterText + Chars.LF + "Письмо инициировано заменой Вами ответственного пользователя " + TrimAll(Record.Document.Responsible);
			If ValueIsFilled(CommentToLetter) Then
				LetterText = LetterText + Chars.LF + Chars.LF + "Comments:" + Chars.LF + CommentToLetter;
			EndIf;
			fmProcessManagement.AddRefToLetterText(LetterText, Record.Document);
			
			fmEmailManagement.SendMailViaNotification(CurReplace.Replacing, MessageTopic, LetterText);
			
		EndDo;
		
		// Удалим необработанные точки маршрута согласования 
		// (пустые записи могут быть в случае преждевременного согласования).
		fmProcessManagement.ClearEmptyRouteStates(Record.Document, Record.AgreementRoute, Record.Version, Cancel, " согласован досрочно", CommentToLetter);
		
	EndIf;
	
EndProcedure

// Процедура - обработчик события объекта "ПередЗаписью"
//
Procedure BeforeWrite(Cancel, Replacement)
	
	// Если обмен данными или промежуточная запись, тогда ничего не делаем.
	If DataExchange.Load OR AdditionalProperties.Property("IntermediateRecord") OR Cancel Then
		Return;
	EndIf;
		
	For Each Record In ThisObject Do
		
		// Пустые состояния нет смысла обрабатывать.
		If NOT ValueIsFilled(Record.PointState) Then
			Continue;
		EndIf;
		
		// Всегда корректируем непосредственно того, кто редактирует точку.
		Record.Responsible = SessionParameters.CurrentUser;
		
		PointResult = Record.PointState.StageCompleted;
		
		If PointResult = 1 Then
			// Точка согласована.
			
			If fmProcessManagement.AgreementEnd(Record.AgreementRoute, Record.Document, Record.RoutePoint, Record.Department, Record.Version) Then
				// Документ согласован.
				FinishAgreement(Record, Cancel);
			Else
				// Согласована промежуточная точка.
				
				// Установим промежуточное состояние.
				fmProcessManagement.SetDocumentState(Record.Document, Record.PointState.State, Record.Version, Cancel);
				
				TransitionPoint = Record.PointState.TransitionPoint;
				
				// Если все паралельные точки согласованы, то происходит переход на следующий уровень.
				LevelPointsList = New Array();
				If ValueIsFilled(TransitionPoint) OR IsTransitionToNextLevel(Record.Document, Record.RoutePoint, Record.Version, LevelPointsList, Record.Department) Then
					
					// Определим точки возврата.
					If ValueIsFilled(TransitionPoint) Then
						FollowingPointsList = New Array();
						FollowingPointsList.Add(TransitionPoint);
					Else
						FollowingPointsList = fmProcessManagement.GettingFollowingStagesList(LevelPointsList);
						// Если ответственный следующей точки этот же человек,
						// то перескочим на следующий уровень.
						If FollowingPointsList.Count()=1 Then
							ResponsibleOfCurPoint = fmProcessManagement.GetResponsibleOfRoutePoint(Record.Document, FollowingPointsList[0]);
							If ResponsibleOfCurPoint=Record.Responsible Then
								FollowingPointsList = fmProcessManagement.GettingFollowingStagesList(FollowingPointsList);
								If FollowingPointsList.Count()=0 Then
									FinishAgreement(Record, Cancel);
									Return;
								EndIf;
							EndIf;
						EndIf;
					EndIf;
					
					StatesRecordSet = InformationRegisters.fmRouteStates.CreateRecordSet();
					StatesRecordSet.Filter.Document.Set(Record.Document);
					StatesRecordSet.Filter.AgreementRoute.Set(Record.AgreementRoute);
					StatesRecordSet.Filter.Version.Set(Record.Version);
					StatesRecordSet.Read();
					StatesRecordSet.AdditionalProperties.Insert("IntermediateRecord", True);
					
					// Будем хранить пользователей для отправки писем после успешной записи состояний.
					VTLettersSending = New ValueTable();
					VTLettersSending.Columns.Add("Responsible");
					VTLettersSending.Columns.Add("Document");
					VTLettersSending.Columns.Add("RoutePoint");
					VTLettersSending.Columns.Add("AgreementRoute");
					VTLettersSending.Columns.Add("Version");
					
					// Сформируем комментарий для письма.
					CommentToLetter = fmProcessManagement.GetComments(Record.Document, Record.AgreementRoute, Record.Version);
					If ValueIsFilled(Record.Comment) Then
						If ValueIsFilled(CommentToLetter) Then
							CommentToLetter = CommentToLetter + Chars.LF + Chars.LF;
						EndIf;
						CommentToLetter = CommentToLetter + TrimAll(Record.Responsible) + " " + Record.Period + ":" + Chars.LF + Record.Comment;
					EndIf;
					
					For Each CurPoint In FollowingPointsList Do
						
						If fmProcessManagement.IsDynamicStage(Record.Document, CurPoint) Then
							
							//ТабБалансоваяЕдиница = Запись.Документ.РасшифровкаПлатежа.Выгрузить(, "БалансоваяЕдиница");
							//Если ТипЗнч(Запись.Документ) = Тип("ДокументСсылка.ЗаявкаНаРасходованиеСредств") 
							//	И Запись.Документ.ВидОперации = Перечисления.ВидыОперацийЗаявкиНаРасходование.ПеречислениеЗППоВедомостям Тогда 
							//	ТабБалансоваяЕдиница = Запись.Документ.Ведомости.Выгрузить(, "БалансоваяЕдиница");
							//КонецЕсли;
							//ТабБалансоваяЕдиница.Свернуть("БалансоваяЕдиница");
							//Если ТабБалансоваяЕдиница.НайтиСтроки(Новый Структура("БалансоваяЕдиница", Справочники.Подразделения.ПустаяСсылка())).Количество() = ТабБалансоваяЕдиница.Количество() Тогда 
							//	
							//	// В тч нет заполненных БалансоваяЕдиница
							//	CommonClientServer.MessageToUser("Не удалось сформировать записи! " + "В документе " + СокрЛП(Запись.Документ) + " не найдены БалансоваяЕдиница для динамической точки " + СокрЛП(ТекТочка), Отказ);
							//	Возврат;
							//
							//Иначе
							//	
							//	Для Каждого ТекСтрока Из ТабБалансоваяЕдиница Цикл
							//		
							//		Если ЗначениеЗаполнено(ТекСтрока.БалансоваяЕдиница) Тогда 
							//			
							//			НоваяЗапись						= НаборЗаписейСостояний.Добавить();
							//			НоваяЗапись.Документ	= Запись.Документ;
							//			НоваяЗапись.Период				= ТекущаяДата();
							//			НоваяЗапись.МаршрутСогласования		= Запись.МаршрутСогласования;
							//			НоваяЗапись.ТочкаМаршрута		= ТекТочка;
							//			НоваяЗапись.БалансоваяЕдиница					= ТекСтрока.БалансоваяЕдиница;
							//			НоваяЗапись.Ответственный 		= укфУправлениеПроцессами.ПолучитьОтветственногоТочкиМаршрута(Запись.Документ, ТекТочка, ТекСтрока.БалансоваяЕдиница);
							//			
							//			НоваяСтрока = ТЗОтправкаПисем.Добавить();
							//			ЗаполнитьЗначенияСвойств(НоваяСтрока, НоваяЗапись);
							//			
							//		КонецЕсли;
							//		
							//	КонецЦикла;
							//	
							//КонецЕсли;
							
						Else
							
							NewRecord = StatesRecordSet.Add();
							NewRecord.Document = Record.Document;
							NewRecord.Period = CurrentSessionDate();
							NewRecord.AgreementRoute = Record.AgreementRoute;
							NewRecord.Version = Record.Version;
							NewRecord.RoutePoint = CurPoint;
							NewRecord.Responsible = fmProcessManagement.GetResponsibleOfRoutePoint(Record.Document, CurPoint);
							
							NewLine = VTLettersSending.Add();
							FillPropertyValues(NewLine, NewRecord);
							
						EndIf;
					EndDo;
					
					Try
						StatesRecordSet.Write();
					Except
						CommonClientServer.MessageToUser("Не удалось сформировать записи!" + ErrorDescription(), , , , Cancel);
						Return;
					EndTry;	
					
					// Если запись прошла успешно, значит можно отправлять письма.
					For Each CurRecord In VTLettersSending Do
						If ValueIsFilled(CurRecord.Responsible) AND NOT Cancel Then
							
							If TypeOf(CurRecord.Document)=Type("DocumentRef.fmBudget") Then
								
								VersionText = fmProcessManagement.GenerateVersionText(CurRecord.Version);
								MessageTopic = NStr("en='Approval of department budget ""';ru='Согласование бюджета подразделения ""'") + TrimAll(CurRecord.Document.Department) + NStr("en='"" for ';ru='"" за '") +
								Year(CurRecord.Document.BeginOfPeriod) + NStr("en='year, scenario ""';ru=' год, сценарий ""'") + TrimAll(CurRecord.Document.Scenario) + VersionText + """";
								
								LetterText = NStr("en='Hello, ';ru='Здравствуйте, '") + TrimAll(CurRecord.Responsible) + "!" + Chars.LF + Chars.LF +
								NStr("en='The department budget is received for approval ""';ru='Поступил на согласование бюджет подразделения ""'") + TrimAll(CurRecord.Document.Department) + NStr("en='"" for ';ru='"" за '") +
								Year(CurRecord.Document.BeginOfPeriod) + NStr("en='year, scenario ""';ru=' год, сценарий ""'") + TrimAll(CurRecord.Document.Scenario) + VersionText + NStr("en='"", Undergoing approval ""';ru='"", проходящий маршрут согласования ""'") +
								TrimAll(CurRecord.AgreementRoute) + NStr("en='"" at the point ""';ru='"" в точке ""'") + TrimAll(CurRecord.RoutePoint) + """.";
								If ValueIsFilled(CommentToLetter) Then
									LetterText = LetterText + Chars.LF + Chars.LF + NStr("en='Comments:';ru='Комментарии:'") + Chars.LF + CommentToLetter;
								EndIf;
								fmProcessManagement.AddRefToLetterText(LetterText, CurRecord.Document);
								
								fmEmailManagement.SendMailViaNotification(CurRecord.Responsible, MessageTopic, LetterText);
								
								// Отправим при необходимости письма заменяющим.
								VTOfReplaces = fmProcessManagement.GetReplacesListParameters(CurRecord.Responsible);
								For Each CurReplace In VTOfReplaces Do
									
									MessageTopic = MessageTopic + NStr("en='(replacement of responsible';ru=' (замена ответственного '") + TrimAll(CurRecord.Responsible) + ")";
									
									LetterText = NStr("en='Hello, ';ru='Здравствуйте, '") + TrimAll(CurReplace.Replacing) + "!" + Chars.LF + Chars.LF +
									NStr("en='The department budget is received for approval ""';ru='Поступил на согласование бюджет подразделения ""'") + TrimAll(CurRecord.Document.Department) + NStr("en='"" for ';ru='"" за '") +
									Year(CurRecord.Document.BeginOfPeriod) + NStr("en='year, scenario ""';ru=' год, сценарий ""'") + TrimAll(CurRecord.Document.Scenario) + VersionText + NStr("en='"", Undergoing approval ""';ru='"", проходящий маршрут согласования ""'") +
									TrimAll(CurRecord.AgreementRoute) + NStr("en='"" at the point ""';ru='"" в точке ""'") + TrimAll(CurRecord.RoutePoint) + """.";
									LetterText = LetterText + Chars.LF + NStr("en='The letter is initialized due to the replacement of a responsible person';ru='Письмо инициировано заменой ответственного пользователя '") + TrimAll(CurRecord.Responsible);
									If ValueIsFilled(CommentToLetter) Then
										LetterText = LetterText + Chars.LF + Chars.LF + NStr("en='Comments:';ru='Комментарии:'") + Chars.LF + CommentToLetter;
									EndIf;
									fmProcessManagement.AddRefToLetterText(LetterText, CurRecord.Document);
									
									fmEmailManagement.SendMailViaNotification(CurReplace.Replacing, MessageTopic, LetterText);
									
								EndDo;
								
							Else
								
								MessageTopic = "Agreement заявки на расход Departments """ + TrimAll(CurRecord.Document.Department) + """ на " + Format(CurRecord.Document.ExpenceDate, "DLF=DD");
								
								LetterText = "Здравствуйте, "+ TrimAll(CurRecord.Responsible) + "!" + Chars.LF + Chars.LF +
								"K Вам поступила на Agreement заявка на расход Departments """ + TrimAll(CurRecord.Document.Department) + """ на " +
								Format(CurRecord.Document.ExpenceDate, "DLF=DD") + ", проходящая маршрут согласования """ +
								TrimAll(CurRecord.AgreementRoute) + """ IN точке """ + TrimAll(CurRecord.RoutePoint) + """.";
								If ValueIsFilled(CommentToLetter) Then
									LetterText = LetterText + Chars.LF + Chars.LF + "Comments:" + Chars.LF + CommentToLetter;
								EndIf;
								fmProcessManagement.AddRefToLetterText(LetterText, CurRecord.Document);
								
								fmEmailManagement.SendMailViaNotification(CurRecord.Responsible, MessageTopic, LetterText);
								
								// Отправим при необходимости письма заменяющим.
								VTOfReplaces = fmProcessManagement.GetReplacesListParameters(CurRecord.Responsible);
								For Each CurReplace In VTOfReplaces Do
									
									MessageTopic = MessageTopic + " (Replace ответственного " + TrimAll(CurRecord.Responsible) + ")";
									
									LetterText = "Здравствуйте, " + TrimAll(CurReplace.Replacing) + "!" + Chars.LF + Chars.LF +
									"K Вам поступил на Agreement заявка на расход Departments """ + TrimAll(CurRecord.Document.Department) + """ на " +
									Format(CurRecord.Document.ExpenceDate, "DLF=DD") + ", проходящая маршрут согласования """ +
									TrimAll(CurRecord.AgreementRoute) + """ IN точке """ + TrimAll(CurRecord.RoutePoint) + """.";
									LetterText = LetterText + Chars.LF + "Письмо инициировано заменой Вами ответственного пользователя " + TrimAll(CurRecord.Responsible);
									If ValueIsFilled(CommentToLetter) Then
										LetterText = LetterText + Chars.LF + Chars.LF + "Comments:" + Chars.LF + CommentToLetter;
									EndIf;
									fmProcessManagement.AddRefToLetterText(LetterText, CurRecord.Document);
									
									fmEmailManagement.SendMailViaNotification(CurReplace.Replacing, MessageTopic, LetterText);
									
								EndDo;
								
							EndIf;
							
						EndIf;
					EndDo;
					
				EndIf;
			EndIf;
			
		ElsIf PointResult = 0 Then
			// Точка не согласована. Документ отправлен на доработку.
			
			// Установим промежуточное состояние или снимем состояние утверждения.
			NewState = Record.PointState.State;
			If ValueIsFilled(NewState) Then
				fmProcessManagement.SetDocumentState(Record.Document, NewState, Record.Version, Cancel);
			ElsIf fmProcessManagement.GetDocumentState(Record.Document, Record.Version) = Catalogs.fmDocumentState.Approved Then
				fmProcessManagement.SetDocumentState(Record.Document, Catalogs.fmDocumentState.OnExecution, Record.Version, Cancel);
			EndIf;	
				
			// Определим точки возврата.
			ReturnPoint = Record.PointState.ReturnPoint;
			If ValueIsFilled(ReturnPoint) Then
				ReturnPoints = New Array();
				ReturnPoints.Add(ReturnPoint);
			Else
				ReturnPoints = fmProcessManagement.GettingPreviousStagesList(Record.RoutePoint);
			EndIf;
			
			StatesRecordSet = InformationRegisters.fmRouteStates.CreateRecordSet();
			StatesRecordSet.Filter.Document.Set(Record.Document);
			StatesRecordSet.Filter.AgreementRoute.Set(Record.AgreementRoute);
			StatesRecordSet.Filter.Version.Set(Record.Version);
			StatesRecordSet.Read();
			StatesRecordSet.AdditionalProperties.Insert("IntermediateRecord", True);
						
			// Будем хранить пользователей для отправки писем после успешной записи состояний.
			VTLettersSending = New ValueTable();
			VTLettersSending.Columns.Add("Responsible");
			VTLettersSending.Columns.Add("Document");
			VTLettersSending.Columns.Add("RoutePoint");
			VTLettersSending.Columns.Add("AgreementRoute");
			VTLettersSending.Columns.Add("Version");
			VTLettersSending.Columns.Add("Delete");
			VTLettersSending.Columns.Add("PointDeletion");
			VTLettersSending.Columns.Add("ResponsibleDeletion");
			
			DeletingStagesList = New Array();
			
			FillDeletingStagesList(ReturnPoints, DeletingStagesList);
			
			// Удалим необработанные точки маршрута согласования, 
			//смысла их отрабатывать больше нет, так как будет возврат еще раз.
			DeletingRecordsList = New ValueList();
			For Each CurRecord In StatesRecordSet Do
				If NOT ValueIsFilled(CurRecord.PointState) AND CurRecord.RoutePoint <> Record.RoutePoint
					AND DeletingStagesList.Find(CurRecord.RoutePoint) <> Undefined Then
					DeletingRecordsList.Add(CurRecord);
					
					NewLine = VTLettersSending.Add();
					FillPropertyValues(NewLine, CurRecord);
					NewLine.Delete = True;
					NewLine.PointDeletion = Record.RoutePoint;
					NewLine.ResponsibleDeletion = Record.Responsible;
				EndIf;	
			EndDo;
			For Each CurRecord In DeletingRecordsList Do
				StatesRecordSet.Delete(CurRecord.Value);
			EndDo;
						
			// Добавим новые записи с пустым состоянием для тех, кому теперь надо согласовать.
			For Each CurPoint In ReturnPoints Do
				
				If fmProcessManagement.IsDynamicStage(Record.Document, CurPoint) Then
					
					//ТабБалансоваяЕдиница = Запись.Документ.РасшифровкаПлатежа.Выгрузить(, "БалансоваяЕдиница");
					//Если ТипЗнч(Запись.Документ) = Тип("ДокументСсылка.ЗаявкаНаРасходованиеСредств") 
					//	И Запись.Документ.ВидОперации = Перечисления.ВидыОперацийЗаявкиНаРасходование.ПеречислениеЗППоВедомостям Тогда 
					//	ТабБалансоваяЕдиница = Запись.Документ.Ведомости.Выгрузить(, "БалансоваяЕдиница");
					//КонецЕсли;
					//ТабБалансоваяЕдиница.Свернуть("БалансоваяЕдиница");
					//Если ТабБалансоваяЕдиница.НайтиСтроки(Новый Структура("БалансоваяЕдиница", Справочники.Подразделения.ПустаяСсылка())).Количество() = ТабБалансоваяЕдиница.Количество() Тогда 
					//	
					//	// В тч нет заполненных БалансоваяЕдиница
					//	CommonClientServer.MessageToUser("Не удалось сформировать записи! " + "В документе " + СокрЛП(Запись.Документ) + " не найдены БалансоваяЕдиница для динамической точки " + СокрЛП(ТекТочка), Отказ);
					//	Возврат;
					//	
					//Иначе
					//	
					//	Для Каждого ТекСтрока Из ТабБалансоваяЕдиница Цикл
					//		
					//		Если ЗначениеЗаполнено(ТекСтрока.БалансоваяЕдиница) Тогда 
					//			
					//			НоваяЗапись						= НаборЗаписейСостояний.Добавить();
					//			НоваяЗапись.Документ	= Запись.Документ;
					//			НоваяЗапись.Период				= ТекущаяДата();
					//			НоваяЗапись.МаршрутСогласования		= Запись.МаршрутСогласования;
					//			НоваяЗапись.ТочкаМаршрута		= ТекТочка;
					//			НоваяЗапись.БалансоваяЕдиница					= ТекСтрока.БалансоваяЕдиница;
					//			НоваяЗапись.Ответственный 		= укфУправлениеПроцессами.ПолучитьОтветственногоТочкиМаршрута(Запись.Документ, ТекТочка, ТекСтрока.БалансоваяЕдиница);
					//			НоваяЗапись.Комментарий			= ?(ЗначениеЗаполнено(Запись.Комментарий), СокрЛП(Запись.Ответственный) + ": " + Запись.Комментарий, "");
					//			
					//			НоваяСтрока = ТЗОтправкаПисем.Добавить();
					//			ЗаполнитьЗначенияСвойств(НоваяСтрока, НоваяЗапись);
					//			НоваяСтрока.Удаление = Ложь;
					//			
					//		КонецЕсли;
					//		
					//	КонецЦикла;
					//	
					//КонецЕсли;
					
				Else
					
					NewRecord						= StatesRecordSet.Add();
					NewRecord.Document	= Record.Document;
					NewRecord.Period				= CurrentSessionDate();
					NewRecord.AgreementRoute		= Record.AgreementRoute;
					NewRecord.Version		= Record.Version;
					NewRecord.RoutePoint		= CurPoint;
					NewRecord.Responsible 		= fmProcessManagement.GetResponsibleOfRoutePoint(Record.Document, CurPoint);
					NewRecord.Comment			= "";
					
					NewLine = VTLettersSending.Add();
					FillPropertyValues(NewLine, NewRecord);
					NewLine.Delete = False;
					
				EndIf;
				
			EndDo;
			
			Try
				StatesRecordSet.Write();
			Except
				CommonClientServer.MessageToUser("Не удалось сформировать записи по маршруту согласования!" + ErrorDescription(), , , , Cancel);
				Return;
			EndTry;
			
			// Сформируем комментарий для письма.
			CommentToLetter = fmProcessManagement.GetComments(Record.Document, Record.AgreementRoute, Record.Version);
			If ValueIsFilled(Record.Comment) Then
				If ValueIsFilled(CommentToLetter) Then
					CommentToLetter = CommentToLetter + Chars.LF + Chars.LF;
				EndIf;
				CommentToLetter = CommentToLetter + TrimAll(Record.Responsible) + " " + Record.Period + ":" + Chars.LF + Record.Comment;
			EndIf;	
			
			// Если запись прошла успешно, значит можно отправлять письма.
			For Each CurRow In VTLettersSending Do
				VersionText = fmProcessManagement.GenerateVersionText(CurRow.Version);
				If ValueIsFilled(CurRow.Responsible) AND NOT Cancel Then
					If TypeOf(CurRow.Document)=Type("DocumentRef.fmBudget") Then
						If CurRow.Delete Then
							MessageTopic = NStr("en='Cancel approval of the department budget ""';ru='Отмена согласования бюджета подразделения ""'") + TrimAll(CurRow.Document.Department) + NStr("en='"" for ';ru='"" за '") +
							Year(CurRow.Document.BeginOfPeriod) + NStr("en='year, scenario ""';ru=' год, сценарий ""'") + TrimAll(CurRow.Document.Scenario) + VersionText + """";
							
							LetterText = NStr("en='Hello, ';ru='Здравствуйте, '")+ TrimAll(CurRow.Responsible) + "!" + Chars.LF + Chars.LF +
							NStr("en='Cancel approval of the department budget""';ru='Отмена согласования бюджета подразделения""'") + TrimAll(CurRow.Document.Department) + NStr("en='"" for ';ru='"" за '") +
							Year(CurRow.Document.BeginOfPeriod) + NStr("en='year, scenario ""';ru=' год, сценарий ""'") + TrimAll(CurRow.Document.Scenario) + VersionText + NStr("en='"", Undergoing approval ""';ru='"", проходящий маршрут согласования ""'") +
							TrimAll(CurRow.AgreementRoute) + NStr("en='"" at the point ""';ru='"" в точке ""'") + TrimAll(CurRow.RoutePoint) + NStr("en='"" rejected  by user';ru='"" отклонен пользователем '") + TrimAll(CurRow.ResponsibleDeletion) + NStr("en='"" at the point ""';ru='"" в точке ""'") + TrimAll(CurRow.PointDeletion) + """.";
						Else
							MessageTopic = NStr("en='Department budget reapproval "" ';ru='Повторное согласование бюджета подразделения ""'") + TrimAll(CurRow.Document.Department) + NStr("en='"" for ';ru='"" за '") +
							Year(CurRow.Document.BeginOfPeriod) + NStr("en='year, scenario ""';ru=' год, сценарий ""'") + TrimAll(CurRow.Document.Scenario) + VersionText + """";
							
							LetterText = NStr("en='Hello, ';ru='Здравствуйте, '")+ TrimAll(CurRow.Responsible) + "!" + Chars.LF + Chars.LF +
							NStr("en='The department budget is received for reapproval ""';ru='Поступил на повторное согласование бюджет подразделения ""'") + TrimAll(CurRow.Document.Department) + NStr("en='"" for ';ru='"" за '") +
							Year(CurRow.Document.BeginOfPeriod) + NStr("en='year, scenario ""';ru=' год, сценарий ""'") + TrimAll(CurRow.Document.Scenario) + VersionText + NStr("en='"", Undergoing approval ""';ru='"", проходящий маршрут согласования ""'") +
							TrimAll(CurRow.AgreementRoute) + NStr("en='"" at the point ""';ru='"" в точке ""'") + TrimAll(CurRow.RoutePoint) + """.";
						EndIf;
						If ValueIsFilled(CommentToLetter) Then
							LetterText = LetterText + Chars.LF + Chars.LF + NStr("en='Comments:';ru='Комментарии:'") + Chars.LF + CommentToLetter;
						EndIf;
						fmProcessManagement.AddRefToLetterText(LetterText, CurRow.Document);
						
						fmEmailManagement.SendMailViaNotification(CurRow.Responsible, MessageTopic, LetterText);
						
						// Отправим при необходимости письма заменяющим.
						VTOfReplaces = fmProcessManagement.GetReplacesListParameters(CurRow.Responsible);
						For Each CurReplace In VTOfReplaces Do
							
							If CurRow.Delete Then
								MessageTopic = NStr("en='Cancel approval of the department budget ""';ru='Отмена согласования бюджета подразделения ""'") + TrimAll(CurRow.Document.Department) + NStr("en='"" for ';ru='"" за '") +
								Year(CurRow.Document.BeginOfPeriod) + NStr("en='year, scenario ""';ru=' год, сценарий ""'") + TrimAll(CurRow.Document.Scenario) + VersionText + """";
								
								LetterText = NStr("en='Hello, ';ru='Здравствуйте, '")+ TrimAll(CurReplace.Replacing) + "!" + Chars.LF + Chars.LF +
								NStr("en='Cancel approval of the department budget""';ru='Отмена согласования бюджета подразделения""'") + TrimAll(CurRow.Document.Department) + NStr("en='"" for ';ru='"" за '") +
								Year(CurRow.Document.BeginOfPeriod) + NStr("en='year, scenario ""';ru=' год, сценарий ""'") + TrimAll(CurRow.Document.Scenario) + VersionText + NStr("en='"", Undergoing approval ""';ru='"", проходящий маршрут согласования ""'") +
								TrimAll(CurRow.AgreementRoute) + NStr("en='"" at the point ""';ru='"" в точке ""'") + TrimAll(CurRow.RoutePoint) + NStr("en='"" rejected  by user';ru='"" отклонен пользователем '") + TrimAll(CurRow.ResponsibleDeletion) + NStr("en='"" at the point ""';ru='"" в точке ""'") + TrimAll(CurRow.PointDeletion) + """.";
							Else
								MessageTopic = NStr("en='Department budget reapproval "" ';ru='Повторное согласование бюджета подразделения ""'") + TrimAll(CurRow.Document.Department) + NStr("en='"" for ';ru='"" за '") +
								Year(CurRow.Document.BeginOfPeriod) + NStr("en='year, scenario ""';ru=' год, сценарий ""'") + TrimAll(CurRow.Document.Scenario) + VersionText + """";
								
								LetterText = NStr("en='Hello, ';ru='Здравствуйте, '")+ TrimAll(CurReplace.Replacing) + "!" + Chars.LF + Chars.LF +
								NStr("en='The department budget is received for reapproval ""';ru='Поступил на повторное согласование бюджет подразделения ""'") + TrimAll(CurRow.Document.Department) + NStr("en='"" for ';ru='"" за '") +
								Year(CurRow.Document.BeginOfPeriod) + NStr("en='year, scenario ""';ru=' год, сценарий ""'") + TrimAll(CurRow.Document.Scenario) + VersionText + NStr("en='"", Undergoing approval ""';ru='"", проходящий маршрут согласования ""'") +
								TrimAll(CurRow.AgreementRoute) + NStr("en='"" at the point ""';ru='"" в точке ""'") + TrimAll(CurRow.RoutePoint) + """.";
							EndIf;
							MessageTopic = MessageTopic + NStr("en='(replacement of responsible';ru=' (замена ответственного '") + TrimAll(CurRow.Responsible) + ")";
							If ValueIsFilled(CommentToLetter) Then
								LetterText = LetterText + Chars.LF + Chars.LF + NStr("en='Comments:';ru='Комментарии:'") + Chars.LF + CommentToLetter;
							EndIf;
							LetterText = LetterText + Chars.LF + NStr("en='The letter is initialized due to the replacement of a responsible person';ru='Письмо инициировано заменой ответственного пользователя '") + TrimAll(CurRow.Responsible);
							fmProcessManagement.AddRefToLetterText(LetterText, CurRow.Document);
							
							fmEmailManagement.SendMailViaNotification(CurReplace.Replacing, MessageTopic, LetterText);
							
						EndDo;
					Else
						If CurRow.Delete Then
							MessageTopic = NStr("en='Cancel approval';ru='Отмена согласования '") + TrimAll(CurRow.Document);
							
							LetterText = NStr("en='Hello, ';ru='Здравствуйте, '") + TrimAll(CurRow.Responsible) + "!" + Chars.LF + Chars.LF +
							NStr("en='Cancel approval';ru='Отмена согласования '") + TrimAll(CurRow.Document) + NStr("en=', Undergoing approval ""';ru=', проходящего маршрут согласования ""'") +
							TrimAll(CurRow.AgreementRoute) + NStr("en='"" at the point ""';ru='"" в точке ""'") + TrimAll(CurRow.RoutePoint) + NStr("en='"" rejected  by user';ru='"" отклонена пользователем '") + TrimAll(CurRow.ResponsibleDeletion) + NStr("en='"" at the point ""';ru='"" в точке ""'") + TrimAll(CurRow.PointDeletion) + """.";
						Else
							MessageTopic = NStr("en='Reapproval ';ru='Повторное согласование '") + TrimAll(CurRow.Document);
							
							LetterText = NStr("en='Hello, ';ru='Здравствуйте, '") + TrimAll(CurRow.Responsible) + "!" + Chars.LF + Chars.LF +
							NStr("en='Received for reapproval';ru='Поступил на повторное согласование '") + TrimAll(CurRow.Document) + NStr("en=', Undergoing approval ""';ru=', проходящего маршрут согласования ""'") +
							TrimAll(CurRow.AgreementRoute) + NStr("en='"" at the point ""';ru='"" в точке ""'") + TrimAll(CurRow.RoutePoint) + """.";
						EndIf;
						If ValueIsFilled(CommentToLetter) Then
							LetterText = LetterText + Chars.LF + Chars.LF + NStr("en='Comments:';ru='Комментарии:'") + Chars.LF + CommentToLetter;
						EndIf;
						fmProcessManagement.AddRefToLetterText(LetterText, CurRow.Document);
						
						fmEmailManagement.SendMailViaNotification(CurRow.Responsible, MessageTopic, LetterText);
						
						// Отправим при необходимости письма заменяющим.
						VTOfReplaces = fmProcessManagement.GetReplacesListParameters(CurRow.Responsible);
						For Each CurReplace In VTOfReplaces Do
							
							If CurRow.Delete Then
								MessageTopic = NStr("en='Cancel approval';ru='Отмена согласования '") + TrimAll(CurRow.Document);
								
								LetterText = NStr("en='Hello, ';ru='Здравствуйте, '") + TrimAll(CurReplace.Replacing) + "!" + Chars.LF + Chars.LF +
								NStr("en='Cancel approval ';ru='Отмена согласования '") + TrimAll(CurRow.Document) + NStr("en=', Undergoing approval ""';ru=', проходящего маршрут согласования ""'") +
								TrimAll(CurRow.AgreementRoute) + NStr("en='"" at the point ""';ru='"" в точке ""'") + TrimAll(CurRow.RoutePoint) + NStr("en='"" rejected  by user';ru='"" отклонена пользователем '") + TrimAll(CurRow.ResponsibleDeletion) + NStr("en='"" at the point ""';ru='"" в точке ""'") + TrimAll(CurRow.PointDeletion) + """.";
							Else
								MessageTopic = NStr("en='Reapproval ';ru='Повторное согласование '") + TrimAll(CurRow.Document);
								
								LetterText = NStr("en='Hello, ';ru='Здравствуйте, '") + TrimAll(CurReplace.Replacing) + "!" + Chars.LF + Chars.LF +
								NStr("en='Received for reapproval';ru='Поступил на повторное согласование '") + TrimAll(CurRow.Document) +
								NStr("en=', Undergoing approval ""';ru=', проходящего маршрут согласования ""'") +
								TrimAll(CurRow.AgreementRoute) + NStr("en='"" at the point ""';ru='"" в точке ""'") + TrimAll(CurRow.RoutePoint) + """.";
							EndIf;
							MessageTopic = MessageTopic + NStr("en='(replacement of responsible';ru=' (замена ответственного '") + TrimAll(CurRow.Responsible) + ")";
							If ValueIsFilled(CommentToLetter) Then
								LetterText = LetterText + Chars.LF + Chars.LF + NStr("en='Comments:';ru='Комментарии:'") + Chars.LF + CommentToLetter;
							EndIf;
							LetterText = LetterText + Chars.LF + NStr("en='The letter is initialized due to the replacement of a responsible person';ru='Письмо инициировано заменой ответственного пользователя '") + TrimAll(CurRow.Responsible);
							fmProcessManagement.AddRefToLetterText(LetterText, CurRow.Document);
							
							fmEmailManagement.SendMailViaNotification(CurReplace.Replacing, MessageTopic, LetterText);
							
						EndDo;
					EndIf;
				EndIf;
			EndDo;
			
		Else
			// Согласование документа прекращено.
			
			// Установим промежуточное состояние или снимем состояние утверждения.
			NewState = Record.PointState.State;
			If ValueIsFilled(NewState) Then
				fmProcessManagement.SetDocumentState(Record.Document, NewState, Record.Version, Cancel);
			ElsIf fmProcessManagement.GetDocumentState(Record.Document, Record.Version) = Catalogs.fmDocumentState.Approved Then
				fmProcessManagement.SetDocumentState(Record.Document, Catalogs.fmDocumentState.Отклонен, Record.Version, Cancel);
			EndIf;
			
			// Сформируем комментарий для письма.
			CommentToLetter = "";
			If ValueIsFilled(Record.Comment) Then
				CommentToLetter = TrimAll(Record.Responsible) + ": " + Record.Comment;
			EndIf;	
			
			// Удалим необработанные точки маршрута согласования, смысла их отрабатывать больше нет.
			fmProcessManagement.ClearEmptyRouteStates(Record.Document, Record.AgreementRoute, Record.Version, Cancel, " окончательно отклонен", CommentToLetter);
			
			// Распроведём отменённый документ.
			If Record.Document.Posted Then
				DocumentObject = Record.Document.GetObject();
				Try
					DocumentObject.Write(DocumentWriteMode.UndoPosting);
				Except
					CommonClientServer.MessageToUser("Не удалось отменить проведение документа!" + ErrorDescription(), , , , Cancel);
					Return;
				EndTry;
			EndIf;
			
		EndIf;
		
	EndDo;
		
EndProcedure // ПередЗаписью()

Procedure FillDeletingStagesList(Points, DeletingStagesList)
	
	Query = New Query(
	"SELECT
	|	RoutesPointsPointsPredecessors.Ref AS RoutePoint
	|FROM
	|	Catalog.fmRoutesPoints.PointsPredecessors AS RoutesPointsPointsPredecessors
	|WHERE
	|	RoutesPointsPointsPredecessors.RoutePoint IN(&ReturnPoints)
	|
	|GROUP BY
	|	RoutesPointsPointsPredecessors.Ref");
	Query.SetParameter("ReturnPoints", Points);
	Result = Query.Execute().Unload().UnloadColumn("RoutePoint");
	
	If Result.Count() > 0 Then
		For Each Stage In Result Do 
			DeletingStagesList.Add(Stage);
		EndDo;
		FillDeletingStagesList(Result, DeletingStagesList);
	EndIf;
	
EndProcedure



