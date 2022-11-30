
//////////////////////////////////////////////////////////////////////////////////////////////////////
// ПРОЦЕДУРЫ И ФУНКЦИИ НАСТРОЙКИ ОТОБРАЖЕНИЯ СОГЛАСОВАНИЯ ДОКУМЕНТОВ

// Настройка отображения доступности формы, кнопки согласования и текста гиперссылки.
//
Procedure SetAgreementViewOnForm(Form) Export
	
	FormItems = Form.Items;
	Object = Form.Object;
	
	CurPeriod = fmProcessManagement.AgreementCheckDate(Object);
	ObjectCurrentVersion = fmBudgeting.DetermineDocumentVersion(Object);
	FormItems.Agreement.Visible = False;
	Form.HasAgreement = True;
		
	If (TypeOf(Object.Ref)=Type("DocumentRef.fmBudget") AND Object.Scenario.ScenarioType=Enums.fmBudgetingScenarioTypes.Fact)
	OR NOT AgreeDocument(Object.Department, ChartsOfCharacteristicTypes.fmAgreeDocumentTypes[Object.Ref.Metadata().Name], CurPeriod) Then
		FormItems.AgreeForm.Visible = False;
		Form.HasAgreement = False;
		Return;
	EndIf;
	
	// Проверим возможность редактирования документа.
	Form.ReadOnly = fmProcessManagement.DisableDocumentEditionOnAgreement(Object.Ref, ObjectCurrentVersion);
	FormItems.AgreeForm.Enabled = NOT Form.ReadOnly;
	FormItems.Agreement.Enabled = NOT Form.ReadOnly;
	
	Query = New Query;
	Query.Text = "SELECT ALLOWED
	               |	fmRouteStatesSliceLast.AgreementRoute AS Route,
	               |	fmRouteStatesSliceLast.RoutePoint,
	               |	fmRouteStatesSliceLast.PointState,
	               |	fmRouteStatesSliceLast.Responsible,
	               |	fmRouteStatesSliceLast.Period AS Period
	               |INTO TTRoutePassingPoints
	               |FROM
	               |	InformationRegister.fmRouteStates.SliceLast(
	               |			,
	               |			Document = &Document
	               |				AND AgreementRoute = &Route
	               |				AND Version = &Version) AS fmRouteStatesSliceLast
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	TTRoutePassingPoints.Route,
	               |	TTRoutePassingPoints.RoutePoint,
	               |	TTRoutePassingPoints.PointState,
	               |	TTRoutePassingPoints.Responsible,
	               |	TTRoutePassingPoints.Period AS Period
	               |FROM
	               |	TTRoutePassingPoints AS TTRoutePassingPoints
	               |
	               |ORDER BY
	               |	Period DESC
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	TTRoutePassingPoints.Route,
	               |	TTRoutePassingPoints.RoutePoint,
	               |	TTRoutePassingPoints.PointState,
	               |	TTRoutePassingPoints.Responsible,
	               |	TTRoutePassingPoints.Period AS Period
	               |FROM
	               |	TTRoutePassingPoints AS TTRoutePassingPoints
	               |WHERE
	               |	TTRoutePassingPoints.PointState = Value(Catalog.fmRoutePointsStates.EmptyRef)
	               |
	               |ORDER BY
	               |	Period DESC";
	
	Query.SetParameter("Document", Object.Ref);
	Query.SetParameter("Route", Object.AgreementRoute);
	Query.SetParameter("Version", ObjectCurrentVersion);
	BathResult = Query.ExecuteBatch();
	
	// Если точек нет вообще, значит по маршруту данному не согласовывался, иначе преобразуем кнопку согласования. 
	PointsSelection = BathResult[1].SELECT();
	EmptyPointsSelection = BathResult[2].SELECT();
	FirstPoint = False;
	If PointsSelection.Next() Then
		// Если нет пустых состояний для точек, то кнопку согласования делаем недоступной.
		If NOT EmptyPointsSelection.Next() Then
			FormItems.AgreeForm.Enabled = False;
			FormItems.Agreement.Enabled = False;
		EndIf;
		Form.Commands.Agree.Title = NStr("en='Approve';ru='Согласовать'");
		Form.Commands.Agree.Representation = ButtonRepresentation.PictureAndText;
		Form.Commands.Agree.ToolTip = NStr("en='Approve and close';ru='Согласовать и закрыть'");
	EndIf;
	
	AgreementStart = Form.Commands.Agree.Title = NStr("en='Submit for approval';ru='Отправить на согласование'");
	FormItems.Agreement.Visible = NOT AgreementStart;
	FormItems.AgreeForm.Title = ?(AgreementStart, NStr("en='Submit for approval';ru='Отправить на согласование'"), "");
	
EndProcedure // НастроитьОтображениеСогласованияНаФорме()


////////////////////////////////////////////////////////////////////////////////////////////////////////
//// ПРОЦЕДУРЫ И ФУНКЦИИ ОБЩЕГО НАЗНАЧЕНИЯ ДЛЯ СОГЛАСОВАНИЯ ДОКУМЕНТОВ

// Функция возвращает признак необходимости согласования определенного подразделения
//
Function AgreeDocument(Department, DocumentType, DATE) Export
	
	Query = New Query("SELECT
	                      |	DepartmentsAgreementSettingSliceLast.Agree
	                      |FROM
	                      |	InformationRegister.fmDepartmentsAgreementSetting.SliceLast(
	                      |			&DATE,
	                      |			Department = &Department
	                      |				AND DocumentType IN (&DocumentType, &DocumentTypeEmptyRef)) AS DepartmentsAgreementSettingSliceLast");
	Query.SetParameter("Department", Department);
	Query.SetParameter("DocumentType", DocumentType);
	Query.SetParameter("DocumentTypeEmptyRef", ChartsOfCharacteristicTypes.fmAgreeDocumentTypes.EmptyRef());
	Query.SetParameter("DATE", DATE);
	Result = Query.Execute().SELECT();
	If Result.Next() Then
		Return Result.Agree;
	Else
		Return False;
	EndIf;
	
EndFunction // СогласовыватьВидДокумента()

Function GetComments(Document, Route, Version) Export
	
	// Заполним комментарии.
	Query = New Query("SELECT
	                      |	fmRouteStates.Period,
	                      |	fmRouteStates.Responsible,
	                      |	fmRouteStates.Comment
	                      |FROM
	                      |	InformationRegister.fmRouteStates AS fmRouteStates
	                      |WHERE
	                      |	fmRouteStates.Document = &Document
	                      |	AND fmRouteStates.AgreementRoute = &Route
	                      |	AND fmRouteStates.Version = &Version
	                      |	AND (CAST(fmRouteStates.Comment AS String(10))) <> """"
	                      |
	                      |ORDER BY
	                      |	Period");
	Query.SetParameter("Document", Document);
	Query.SetParameter("Route", Route);
	Query.SetParameter("Version", Version);
	Result = Query.Execute().Unload();
	Comments = "";
	For Each CurRow In Result Do
		If ValueIsFilled(Comments) Then
			Comments = Comments + Chars.LF + Chars.LF;
		EndIf;
		Comments = Comments + CurRow.Responsible + " " + Format(CurRow.Period, "DF='dd.MM.yyyy hh:mm'") + ":" + Chars.LF + CurRow.Comment;
	EndDo;
	Return Comments;
	
EndFunction

// Функция определяет возможность редактирования документа на маршруте согласования пользователем.
//
Function DisableDocumentEditionOnAgreement(DocumentObject, Version) Export
	
	// Новый документ можно редактировать всегда и всем.
	If NOT ValueIsFilled(DocumentObject.Ref) Then
		Return False;
	EndIf;
	
	// Разрешено редактирование документа пользователям с правами администратора.
	If IsInRole("SystemAdministrator") Then
		Return False;
	EndIf;
	
	CurUser = SessionParameters.CurrentUser;
	Ref = DocumentObject.Ref;
	Route = DocumentObject.AgreementRoute;
	
	// Если документ не находится на согласовании, то его можно редактировать
	If NOT DocumentOnAgreement(Ref, Version) Then
		Return False;
	EndIf;
	
	// Получим список пользователей, которые в текущий момент согласовывают документ,
	// список самих точек, а так же список их замен.
	IsProhibition = True;
	Query = New Query("SELECT ALLOWED
	                      |	fmRouteStatesSliceLast.RoutePoint AS RoutePoint,
	                      |	fmRouteStatesSliceLast.RoutePoint.AccessTypeToRoutePoint AS AccessType,
	                      |	fmRouteStatesSliceLast.RoutePoint.DepartmentLevel AS DepartmentLevel,
	                      |	fmRouteStatesSliceLast.RoutePoint.User AS User,
	                      |	fmRouteStatesSliceLast.RoutePoint.Department AS Department,
	                      |	fmRouteStatesSliceLast.RoutePoint.ManageType AS ManageType,
	                      |	fmRouteStatesSliceLast.Document.Responsible AS DocumentResponsible,
	                      |	fmRouteStatesSliceLast.Department AS DocumentDepartment,
	                      |	fmRouteStatesSliceLast.RoutePoint.AgreementState AS PointState,
	                      |	fmRouteStatesSliceLast.Period AS Period
	                      |FROM
	                      |	InformationRegister.fmRouteStates.SliceLast(
	                      |			,
	                      |			Document = &DocumentRef
	                      |				AND AgreementRoute = &AgreementRoute
	                      |				AND Version = &Version) AS fmRouteStatesSliceLast
	                      |WHERE
	                      |	fmRouteStatesSliceLast.PointState = Value(Catalog.fmRoutePointsStates.EmptyRef)
	                      |
	                      |ORDER BY
	                      |	Period
	                      |;
	                      |
	                      |////////////////////////////////////////////////////////////////////////////////
	                      |SELECT ALLOWED
	                      |	fmResponsiblesReplacements.Responsible AS Responsible
	                      |FROM
	                      |	InformationRegister.fmResponsiblesReplacements AS fmResponsiblesReplacements
	                      |WHERE
	                      |	fmResponsiblesReplacements.ResponsibleReplacing = &CurUser
	                      |	AND (fmResponsiblesReplacements.BeginDate <= &CurrentDate
	                      |			OR fmResponsiblesReplacements.BeginDate = DATETIME(1, 1, 1, 0, 0, 0))
	                      |	AND (fmResponsiblesReplacements.EndDate >= &CurrentDate
	                      |			OR fmResponsiblesReplacements.EndDate = DATETIME(1, 1, 1, 0, 0, 0))");
	
	Query.SetParameter("DocumentRef", Ref);
	Query.SetParameter("Version", Version);
	Query.SetParameter("AgreementRoute", Route);
	Query.SetParameter("CurUser", CurUser);
	Query.SetParameter("CurrentDate", BegOfDay(CurrentSessionDate()));
	Result = Query.ExecuteBatch();
	
	ReplacingList = Result[1].Unload().UnloadColumn("Responsible");
	
	// Будем проверять возможность редактирования открытых точек.
	OpenPoints = Result[0].Unload();
	For Each CurPoint In OpenPoints Do
		Responsible = GetResponsibleOfRoutePoint(Ref, CurPoint.RoutePoint);
		If Responsible <> CurUser AND ReplacingList.Find(Responsible) = Undefined Then 
			Continue;
		Else
			IsProhibition = False;
		EndIf;
	EndDo;
	
	// Если все предыдущие этапы не дали нужных результатов, то такой документ нельзя редактировать.
	Return IsProhibition;
	
EndFunction // ЗапретитьРедактированиеДокументаПриСогласовании() 	

// Функция определяет возможность редактирования пользователем точки маршрута согласования
//
Function DenyPointProcessing(PointParameters, User, ReplacingList, BeginOfPeriod) Export
	
	// Проверим возможность редактирования в зависимости от настроек точки маршрута с учетом списка замен.
	If PointParameters.AccessType = Enums.fmAccessTypeToRoutePoint.NoLimit Then
		Return False;
	ElsIf PointParameters.AccessType = Enums.fmAccessTypeToRoutePoint.FixedDepartment Then
		UserDepartment = GetDepartmentResponsible(PointParameters.RoutePointDepartment, BeginOfPeriod);
		If User = UserDepartment Then
			Return False;
		ElsIf NOT ReplacingList.Find(UserDepartment) = Undefined Then
			Return False;
		EndIf;	
	ElsIf PointParameters.AccessType = Enums.fmAccessTypeToRoutePoint.DocumentDepartment Then
		If PointParameters.DepartmentLevel = 0 Then
			DocumentDepartmentUser = GetDepartmentResponsible(PointParameters.DocumentDepartment, BeginOfPeriod);
		Else
			DocumentDepartment = GetDepartmentParent(PointParameters.DocumentDepartment, PointParameters.DepartmentLevel);
			If DocumentDepartment = Undefined Then
				// Ошибка, будет сообщение из функции "ПолучитьРодителяБалансоваяЕдиница". 
				Return True;
			EndIf;
			DocumentDepartmentUser = GetDepartmentResponsible(DocumentDepartment, BeginOfPeriod);
		EndIf;
		If User = DocumentDepartmentUser Then
			Return False;
		ElsIf NOT ReplacingList.Find(DocumentDepartmentUser) = Undefined Then
			Return False;
		EndIf;
	ElsIf PointParameters.AccessType = Enums.fmAccessTypeToRoutePoint.FixedUser Then
		If User = PointParameters.User Then
			Return False;
		ElsIf NOT ReplacingList.Find(PointParameters.User) = Undefined Then
			Return False;
		EndIf;
	ElsIf PointParameters.AccessType = Enums.fmAccessTypeToRoutePoint.ManageType Then
		DocumentDepartment = FindDepartmentByManagementType(PointParameters.DocumentDepartment, PointParameters.ManageType);
		If DocumentDepartment = Undefined Then
			// Ошибка, будет сообщение из функции "ПолучитьРодителяПодразделения". 
			Return True;
		EndIf;
		DocumentDepartmentUser = GetDepartmentResponsible(DocumentDepartment, BeginOfPeriod);
		If User = DocumentDepartmentUser Then
			Return False;
		ElsIf NOT ReplacingList.Find(DocumentDepartmentUser) = Undefined Then
			Return False;
		EndIf;
	EndIf;
	
	Return True;
	
EndFunction // ЗапретитьОбработкуТочки()

// Функция возвращает родителя подразделения
//
Function GetDepartmentParent(Department, Level) Export
	
	CurrentLevel       = Level;
	CurrentDepartment = Department;
	
	While CurrentLevel <> 0 Do
		CurrentLevel = CurrentLevel - 1;
		QueryParent = New Query("SELECT ALLOWED
		                              |	Departments.Parent AS Parent
		                              |FROM
		                              |	Catalog.fmDepartments AS Departments
		                              |WHERE
		                              |	Departments.Ref = &Ref");
		QueryParent.SetParameter("Ref", CurrentDepartment);
		Result = QueryParent.Execute().SELECT();
		Result.Next();
		If NOT ValueIsFilled(Result.Parent) Then
			CommonClientServer.MessageToUser(NStr("en='The document department structure fails to comply with the specified level.';ru='Структура подразделения документа не соответствует указанному уровню!'"));
			Return Undefined;
		EndIf;
		CurrentDepartment = Result.Parent;
	EndDo;
	
	Return CurrentDepartment;
	
EndFunction // ПолучитьРодителяПодразделения()

// Функция возвращает родителя подразделения по указанному типу управления
//
Function FindDepartmentByManagementType(Department, ManageType) Export
	
	CurrentDepartment = Department;
	CurrentManagementType = Department.DepartmentType;
	
	While CurrentManagementType <> ManageType Do
		QueryParent = New Query("SELECT ALLOWED
		                              |	Departments.Parent AS Parent,
		                              |	Departments.Parent.ManageType AS ManageType
		                              |FROM
		                              |	Catalog.fmDepartments AS Departments
		                              |WHERE
		                              |	Departments.Ref = &Department");
		QueryParent.SetParameter("Department", CurrentDepartment);
		Result = QueryParent.Execute().SELECT();
		Result.Next();
		If NOT ValueIsFilled(Result.Parent) Then
			CommonClientServer.MessageToUser(StrTemplate(NStr("en='The department with management type ""%1"" is not found.';ru='Не найдено подразделение с типом управления ""%1""!'"), TrimAll(ManageType)));
			Return Undefined;
		EndIf;
		CurrentDepartment = Result.Parent;
		CurrentManagementType = Result.ManageType;
	EndDo;
	
	Return CurrentDepartment;
	
EndFunction // НайтиПодразделениеПоТипуУправления()

// Процедура формирует движения по маршруту согласования
//
Procedure GenerateRouteRecords(lcRef, lcRoute, Cancel, Version, Comment="") Export
	
	// Проверим, по какому маршруту была сделана последняя запись 
	// для данного документа и была ли запись по текущему маршруту.
	QueryPassingCheck = New Query("SELECT ALLOWED
	                                         |	fmRouteStates.AgreementRoute AS Route,
	                                         |	fmRouteStates.Period AS Period,
	                                         |	fmRouteStates.Version
	                                         |FROM
	                                         |	InformationRegister.fmRouteStates.SliceLast(
	                                         |			,
	                                         |			Document = &Document
	                                         |				AND Version = &Version) AS fmRouteStates
	                                         |
	                                         |ORDER BY
	                                         |	Period DESC
	                                         |;
	                                         |
	                                         |////////////////////////////////////////////////////////////////////////////////
	                                         |SELECT ALLOWED
	                                         |	fmRouteStates.AgreementRoute AS Route
	                                         |FROM
	                                         |	InformationRegister.fmRouteStates.SliceLast(
	                                         |			,
	                                         |			Document = &Document
	                                         |				AND AgreementRoute = &Route
	                                         |				AND Version = &Version) AS fmRouteStates");
	QueryPassingCheck.SetParameter("Document", lcRef);
	QueryPassingCheck.SetParameter("Route", lcRoute);
	QueryPassingCheck.SetParameter("Version", Version);
	Result = QueryPassingCheck.ExecuteBatch();
	
	Selection = Result[0].SELECT();
	If Selection.Next() Then
		//Значит движения были.
		If Selection.Route = lcRoute Then
			// Маршрут не изменился.
			
			// выполним анализ изменения состава БалансоваяЕдиница в документе заявка на расход
			If IsDynamicStage(lcRef) Then 
				
			//	Запрос = Новый Запрос();
			//	Запрос.Текст = 
			//	"ВЫБРАТЬ РАЗРЕШЕННЫЕ
			//	|	уфСостоянияПрохожденияМаршрутаСрезПоследних.ТочкаМаршрута
			//	|ПОМЕСТИТЬ ДинамическиеТочки
			//	|ИЗ
			//	|	РегистрСведений.уфСостоянияПрохожденияМаршрута.СрезПоследних(
			//	|			,
			//	|			Документ = &Документ
			//	|				И Маршрут = &Маршрут
			//	|				И ТочкаМаршрута.ВидДоступаКТочкеМаршрута = ЗНАЧЕНИЕ(Перечисление.укфВидДоступаКТочкеМаршрута.ПоБалансоваяЕдиницаЗаявки)) КАК уфСостоянияПрохожденияМаршрутаСрезПоследних
			//	|
			//	|СГРУППИРОВАТЬ ПО
			//	|	уфСостоянияПрохожденияМаршрутаСрезПоследних.ТочкаМаршрута
			//	|;
			//	|
			//	|////////////////////////////////////////////////////////////////////////////////
			//	|ВЫБРАТЬ РАЗРЕШЕННЫЕ
			//	|	ЗаявкаНаРасходованиеСредствРасшифровкаПлатежа.БалансоваяЕдиница
			//	|ИЗ
			//	|	Документ.ЗаявкаНаРасходованиеСредств.РасшифровкаПлатежа КАК ЗаявкаНаРасходованиеСредствРасшифровкаПлатежа
			//	|		ЛЕВОЕ СОЕДИНЕНИЕ РегистрСведений.уфСостоянияПрохожденияМаршрута.СрезПоследних(
			//	|				,
			//	|				Документ = &Документ
			//	|					И Маршрут = &Маршрут
			//	|					И ТочкаМаршрута В
			//	|						(ВЫБРАТЬ
			//	|							ДинамическиеТочки.ТочкаМаршрута
			//	|						ИЗ
			//	|							ДинамическиеТочки)) КАК уфСостоянияПрохожденияМаршрутаСрезПоследних
			//	|		ПО ЗаявкаНаРасходованиеСредствРасшифровкаПлатежа.Ссылка = уфСостоянияПрохожденияМаршрутаСрезПоследних.Документ
			//	|			И ЗаявкаНаРасходованиеСредствРасшифровкаПлатежа.БалансоваяЕдиница = уфСостоянияПрохожденияМаршрутаСрезПоследних.БалансоваяЕдиница
			//	|ГДЕ
			//	|	ЗаявкаНаРасходованиеСредствРасшифровкаПлатежа.Ссылка = &Документ
			//	|	И уфСостоянияПрохожденияМаршрутаСрезПоследних.БалансоваяЕдиница ЕСТЬ NULL 
			//	|
			//	|СГРУППИРОВАТЬ ПО
			//	|	ЗаявкаНаРасходованиеСредствРасшифровкаПлатежа.БалансоваяЕдиница
			//	|;
			//	|
			//	|////////////////////////////////////////////////////////////////////////////////
			//	|ВЫБРАТЬ
			//	|	ДинамическиеТочки.ТочкаМаршрута
			//	|ИЗ
			//	|	ДинамическиеТочки КАК ДинамическиеТочки
			//	|;
			//	|
			//	|////////////////////////////////////////////////////////////////////////////////
			//	|ВЫБРАТЬ РАЗРЕШЕННЫЕ
			//	|	ЗаявкаНаРасходованиеСредствРасшифровкаПлатежа.БалансоваяЕдиница
			//	|ИЗ
			//	|	Документ.ЗаявкаНаРасходованиеСредств.РасшифровкаПлатежа КАК ЗаявкаНаРасходованиеСредствРасшифровкаПлатежа
			//	|ГДЕ
			//	|	ЗаявкаНаРасходованиеСредствРасшифровкаПлатежа.Ссылка = &Документ
			//	|	И ЗаявкаНаРасходованиеСредствРасшифровкаПлатежа.БалансоваяЕдиница <> ЗНАЧЕНИЕ(Справочник.Подразделения.ПустаяСсылка)";
			//	
			//	Запрос.УстановитьПараметр("Документ", лкСсылка);
			//	Запрос.УстановитьПараметр("Маршрут", лкМаршрут);
			//	
			//	Если ТипЗнч(лкСсылка) = Тип("ДокументСсылка.ЗаявкаНаРасходованиеСредств") 
			//		И лкСсылка.ВидОперации = Перечисления.ВидыОперацийЗаявкиНаРасходование.ПеречислениеЗППоВедомостям Тогда 
			//		Запрос.Текст = СтрЗаменить(Запрос.Текст, "Документ.ЗаявкаНаРасходованиеСредств.РасшифровкаПлатежа", "Документ.ЗаявкаНаРасходованиеСредств.Ведомости");
			//	КонецЕсли;
			//	
			//	Результат = Запрос.ВыполнитьПакет();
			//	Если Результат[3].Пустой() Тогда 
			//		// В тч нет заполненных БалансоваяЕдиница
			//		CommonClientServer.MessageToUser("В документе не найдены БалансоваяЕдиница для динамических точек маршрута!", Отказ);
			//		Возврат;
			//	КонецЕсли;
			//	
			//	Если НЕ Результат[1].Пустой() И НЕ Результат[2].Пустой() Тогда 
			//		
			//		// Удалим необработанные точки маршрута согласования.
			//		УправлениеПроцессами.ОчиститьПустыеСостоянияМаршрута(лкСсылка, лкМаршрут, Отказ, " был изменен", "");
			//	
			//		НаборЗаписейСостояний = РегистрыСведений.уфСостоянияПрохожденияМаршрута.СоздатьНаборЗаписей();
			//		НаборЗаписейСостояний.Отбор.Документ.Установить(лкСсылка);
			//		НаборЗаписейСостояний.Отбор.Маршрут.Установить(лкМаршрут);
			//		НаборЗаписейСостояний.Прочитать();
			//		НаборЗаписейСостояний.ДополнительныеСвойства.Вставить("ПромежуточнаяЗапись", Истина);
			//		
			//		// Будем хранить пользователей для отправки писем после успешной записи состояний.
			//		ТЗОтправкаПисем = Новый ТаблицаЗначений();
			//		ТЗОтправкаПисем.Колонки.Добавить("Ответственный");
			//		ТЗОтправкаПисем.Колонки.Добавить("Документ");
			//		ТЗОтправкаПисем.Колонки.Добавить("ТочкаМаршрута");
			//		ТЗОтправкаПисем.Колонки.Добавить("Маршрут");
			//			
			//		ДинамическиеТочки = Результат[2].Выбрать();
			//		СписокБалансоваяЕдиница = Результат[1].Выбрать();
			//		Пока ДинамическиеТочки.Следующий() Цикл
			//			
			//			Пока СписокБалансоваяЕдиница.Следующий() Цикл
			//				
			//				НоваяЗапись						= НаборЗаписейСостояний.Добавить();
			//				НоваяЗапись.Документ	= лкСсылка;
			//				НоваяЗапись.Период				= ТекущаяДата();
			//				НоваяЗапись.Маршрут		= лкМаршрут;
			//				НоваяЗапись.ТочкаМаршрута		= ДинамическиеТочки.ТочкаМаршрута;
			//				НоваяЗапись.БалансоваяЕдиница					= СписокБалансоваяЕдиница.БалансоваяЕдиница;
			//				НоваяЗапись.Ответственный 		= УправлениеПроцессами.ПолучитьОтветственногоТочкиМаршрута(лкСсылка, ДинамическиеТочки.ТочкаМаршрута, СписокБалансоваяЕдиница.БалансоваяЕдиница);
			//						
			//				НоваяСтрока = ТЗОтправкаПисем.Добавить();
			//				ЗаполнитьЗначенияСвойств(НоваяСтрока, НоваяЗапись);
			//				
			//			КонецЦикла;
			//			
			//		КонецЦикла;
			//		
			//		Попытка
			//			НаборЗаписейСостояний.Записать();
			//		Исключение
			//			CommonClientServer.MessageToUser("Не удалось сформировать записи!" + ОписаниеОшибки(), Отказ);
			//			Возврат;
			//		КонецПопытки;
			//		
			//		// Если запись прошла успешно, значит можно отправлять письма.
			//		Если Константы.укфОтправлятьУведомлениеПриСогласовании.Получить() Тогда
			//			УчетнаяЗаписьОтправкиУведомлений = Константы.укфУчетнаяЗаписьОтправкиУведомлений.Получить();
			//			Для Каждого ТекЗапись Из ТЗОтправкаПисем Цикл
			//				Если ЗначениеЗаполнено(ТекЗапись.Ответственный) И НЕ Отказ Тогда
			//					ТемаСообщения = "Согласование документа """ + СокрЛП(ТекЗапись.Документ) + """ (маршрут согласования """ +
			//					СокрЛП(ТекЗапись.Маршрут) + """, точка маршрута """ + СокрЛП(ТекЗапись.ТочкаМаршрута) + """)";						
			//					ТекстПисьма = "Здравствуйте, "+ СокрЛП(ТекЗапись.Ответственный) + "!" + Символы.ПС + Символы.ПС +
			//					"К Вам поступил на согласование документ """ + СокрЛП(ТекЗапись.Документ) + """, проходящий маршрут согласования  """ +
			//					СокрЛП(ТекЗапись.Маршрут) + """ в точке """ + СокрЛП(ТекЗапись.ТочкаМаршрута) + """.";						
			//					УправлениеПроцессами.ДобавитьСсылкуКТекстуПисьма(ТекстПисьма, ТекЗапись.Документ);
			//					УправлениеЭлектроннойПочтой.ОтправитьПисьмо(Отказ, УчетнаяЗаписьОтправкиУведомлений, ТекстПисьма, ТекЗапись.Ответственный, ТемаСообщения);
			//					// Отправим при необходимости письма заменяющим.
			//					ТЗЗамен = УправлениеПроцессами.ПолучитьСписокЗаменИПараметры(ТекЗапись.Ответственный);
			//					Для Каждого ТекЗамена ИЗ ТЗЗамен Цикл
			//						Если ТекЗамена.ОтправлятьУведомление И НЕ Отказ Тогда
			//							ТемаСообщения = ТемаСообщения + "(замена ответственного " + СокрЛП(ТекЗапись.Ответственный) + ")";
			//							ТекстПисьма = "Здравствуйте, "+ СокрЛП(ТекЗамена.Заменяющий) + "!" + Символы.ПС + Символы.ПС +
			//							"К Вам поступил на согласование документ """ + СокрЛП(ТекЗапись.Документ) + """, проходящий маршрут согласования  """ +
			//							СокрЛП(ТекЗапись.Маршрут) + """ в точке """ + СокрЛП(ТекЗапись.ТочкаМаршрута) + """." + Символы.ПС + "Письмо инициировано заменой Вами ответственного пользователя " + СокрЛП(ТекЗапись.Ответственный);
			//							УправлениеПроцессами.ДобавитьСсылкуКТекстуПисьма(ТекстПисьма, ТекЗапись.Документ);
			//							УправлениеЭлектроннойПочтой.ОтправитьПисьмо(Отказ, УчетнаяЗаписьОтправкиУведомлений, ТекстПисьма, ТекЗамена.Заменяющий, ТемаСообщения);
			//						КонецЕсли;
			//					КонецЦикла;
			//				КонецЕсли;
			//			КонецЦикла;
			//		КонецЕсли;
			//		
			//	КонецЕсли;
			//	
			EndIf;
			
			Return;
			
		Else
			// Если по этому маршруту уже было согласование в прошлом. Необходимо его очистить.
			QueryRoute = Result[1].SELECT();
			If QueryRoute.Next() Then
				RecordSet = InformationRegisters.fmRouteStates.CreateRecordSet();
				RecordSet.Filter.Document.Set(lcRef);
				RecordSet.Filter.AgreementRoute.Set(lcRoute);
				RecordSet.Filter.Version.Set(Version);
				RecordSet.Read();
				If RecordSet.Count() > 0 Then
					RecordSet.Clear();
					Try
						RecordSet.Write();
					Except
						CommonClientServer.MessageToUser(StrTemplate(NStr("en='Failed to clear the approval route for document ""%1""!  %2';ru='Для документа ""%1"" не удалось очистить маршрут согласования! %2'"), TrimAll(lcRef), ErrorDescription()), , , , Cancel);
						Return;
					EndTry;	
				EndIf;			
			EndIf;	
		EndIf;				
		// Необходимо почистить пустые состояния по старому маршруту.
		ClearEmptyRouteStates(lcRef, Selection.Route, Selection.Version, Cancel, NStr("en='modified the approval route for';ru=' изменил маршрут согласования на'"));
	EndIf;
	
	InitialRoutePoints = GetInitialRouteModelPoints(lcRoute);
	// Начальная точка согласования должна быть одна, но для совместимости с предыдущими релизами	
	// оставлена возможность отработки нескольких точек маршрута.	
	For Each ProcessesPoints In InitialRoutePoints Do
		
		Record					= InformationRegisters.fmRouteStates.CreateRecordManager();
		Record.PointState	= ProcessesPoints.AgreementState;
		If NOT ValueIsFilled(Record.PointState) Then
			CommonClientServer.MessageToUser(NStr("en='The approval status is not set for the route point!';ru='Для точки маршрута не задано состояние утверждения!'"), , , , Cancel);
			Return;
		EndIf;	
		Record.Document	= lcRef;
		Record.Period			= CurrentDate();
		Record.AgreementRoute	= lcRoute;
		Record.RoutePoint	= ProcessesPoints.Point;
		Record.Version = Version;
		Record.Comment = Comment;
		
		Try
			Record.Write();
		Except			
			CommonClientServer.MessageToUser(StrTemplate(NStr("en='Failed to generate the initial stage of the route for the document! %1';ru='Для документа не удалось сформировать начальный этап прохождения маршрута! %1'"), ErrorDescription()), , , , Cancel);
		EndTry;
		
	EndDo;
	
EndProcedure // СформироватьДвиженияПоМаршруту()

// Функция возвращает модель маршрута согласования по параметрам
//
Function GetCorrespondingRoute(DataStructure) Export
	
	Query = New Query;
	Query.Text = "SELECT ALLOWED
	               |	ModelsSelectionSetting.BalanceUnit AS BalanceUnit,
	               |	ModelsSelectionSetting.Department AS Department,
	               |	ModelsSelectionSetting.DocumentType AS DocumentType,
	               |	ModelsSelectionSetting.AgreementRoute AS AgreementRoute,
	               |	ModelsSelectionSetting.OperationType AS OperationType
	               |FROM
	               |	InformationRegister.fmModelsSelectionSetting AS ModelsSelectionSetting
	               |WHERE
	               |	ModelsSelectionSetting.Department IN (&Department, &DepartmentEmptyRef)
	               |	AND ModelsSelectionSetting.BalanceUnit IN (&BalanceUnit, &BalanceUnitEmptyRef)
	               |	AND ModelsSelectionSetting.DocumentType IN (&DocumentType, &DocumentTypeEmptyRef)
	               |	AND (ModelsSelectionSetting.Currency = &Currency
	               |				AND ModelsSelectionSetting.AmountFrom <= &DocumentAmount
	               |				AND ModelsSelectionSetting.AmountTo >= &DocumentAmount
	               |			OR ModelsSelectionSetting.Currency = &CurrencyEmptyRef)
	               |	AND ModelsSelectionSetting.OperationType IN (&OperationType, &OperationTypeEmptyRef)
	               |
	               |ORDER BY
	               |	OperationType DESC,
	               |	BalanceUnit DESC,
	               |	Department DESC";
	
	Query.SetParameter("BalanceUnit", DataStructure.BalanceUnit);
	Query.SetParameter("BalanceUnitEmptyRef", Catalogs.fmBalanceUnits.EmptyRef());
	Query.SetParameter("OperationType", DataStructure.OperationType);
	Query.SetParameter("OperationTypeEmptyRef", Enums.fmBudgetOperationTypes.EmptyRef());
	Query.SetParameter("Department", DataStructure.Department);
	Query.SetParameter("DepartmentEmptyRef", Catalogs.fmDepartments.EmptyRef());
	Query.SetParameter("Currency", DataStructure.Currency);
	Query.SetParameter("CurrencyEmptyRef", Catalogs.Currencies.EmptyRef());
	Query.SetParameter("DocumentAmount", DataStructure.DocumentAmount);
	Query.SetParameter("DocumentType", ChartsOfCharacteristicTypes.fmAgreeDocumentTypes[DataStructure.DocumentName]);
	Query.SetParameter("DocumentTypeEmptyRef", ChartsOfCharacteristicTypes.fmAgreeDocumentTypes.EmptyRef());
	
	Selection = Query.Execute().SELECT();	
	If Selection.Next() Then
		Return Selection.AgreementRoute;
	Else
		Return Catalogs.fmAgreementRoutes.EmptyRef();
	EndIf;
	
EndFunction // ПолучитьСоответствующуюМаршрут()

// Процедура устанавливает новую модель и состояние для объекта документа.
//
Procedure SetNewStateAndModelOfRouteDocument(DBObject, Route) Export
	
	OldModel = Route;
	// структура необходимых реквизитов, для определения маршрута
	DocumentDataStructure = New Structure();
	DocumentDataStructure.Insert("BalanceUnit", DBObject.BalanceUnit);
	DocumentDataStructure.Insert("OperationType", DBObject.OperationType);
	DocumentDataStructure.Insert("Department", DBObject.Department);
	DocumentDataStructure.Insert("Currency", DBObject.Currency);
	DocumentDataStructure.Insert("DocumentAmount", DBObject.TotalAmount);
	DocumentDataStructure.Insert("DocumentName", DBObject.Metadata().Name);
	
	Route = GetCorrespondingRoute(DocumentDataStructure);
	
	If Route <> OldModel Then
		Version = fmBudgeting.DetermineDocumentVersion(DBObject.Ref);
		If GetDocumentState(DBObject.Ref, Version) = Catalogs.fmDocumentState.Approved Then
			Cancel = False;
			SetDocumentState(DBObject.Ref, Catalogs.fmDocumentState.OnApproval, Version, Cancel);
		EndIf;
	EndIf;
	
EndProcedure // УстановитьНовоеСостояниеИМодельДокументаМаршрута()		

// Функция возвращает таблицу значений из заменяющих ответственного, периода действия замены,
// а также необходимости отправлять уведомления.
//
Function GetReplacesListParameters(Responsible, DATE = Undefined) Export
	
	Query = New Query();
	Query.Text = 
	"SELECT
	|	fmResponsiblesReplacements.ResponsibleReplacing AS Replacing,
	|	fmResponsiblesReplacements.BeginDate,
	|	fmResponsiblesReplacements.EndDate
	|FROM
	|	InformationRegister.fmResponsiblesReplacements AS fmResponsiblesReplacements
	|WHERE
	|	fmResponsiblesReplacements.Responsible = &Responsible
	|	AND (fmResponsiblesReplacements.BeginDate <= &DATE
	|			OR fmResponsiblesReplacements.BeginDate = DATETIME(1, 1, 1, 0, 0, 0))
	|	AND (fmResponsiblesReplacements.EndDate >= &DATE
	|			OR fmResponsiblesReplacements.EndDate = DATETIME(1, 1, 1, 0, 0, 0))";
	Query.SetParameter("Responsible", Responsible);
	Query.SetParameter("DATE", BegOfDay(?(DATE = Undefined, CurrentSessionDate(), DATE)));
	
	Return Query.Execute().Unload();	
	
EndFunction // ПолучитьСписокЗаменИПараметры()	

// Функция возвращает ответственного по параметрам точки маршрута.
//
Function GetResponsibleOfRoutePoint(Document, RoutePoint, BalanceUnit = Undefined) Export
	
	DynamicPoint = IsDynamicStage(Document, RoutePoint);
	
	QueryPointParameters = New Query("SELECT ALLOWED DISTINCT
	                                    |	RoutesPoints.AccessTypeToRoutePoint AS AccessType,
	                                    |	RoutesPoints.DepartmentLevel,
	                                    |	RoutesPoints.User,
	                                    |	RoutesPoints.ManageType,
	                                    |	ISNULL(DepartmentsStatePoint.Responsible, Value(Catalog.Users.EmptyRef)) AS UserDepartment,
	                                    |	AgreementDocument.Ref.Responsible AS Responsible,
	                                    |	AgreementDocument.Department AS DocumentDepartment,
	                                    |	ISNULL(DepartmentsStateDocument.Responsible, Value(Catalog.Users.EmptyRef)) AS DocumentDepartmentUser
	                                    |FROM
	                                    |	Catalog.fmRoutesPoints AS RoutesPoints
	                                    |	LEFT JOIN InformationRegister.fmDepartmentsState.SliceLast(&Period, ) AS DepartmentsStatePoint
	                                    |	ON RoutesPoints.Department = DepartmentsStatePoint.Department,
	                                    |	Document."+ Document.Metadata().Name + ?(DynamicPoint, ".PlanData", "") + " AS AgreementDocument
	                                    |	LEFT JOIN InformationRegister.fmDepartmentsState.SliceLast(&Period, ) AS DepartmentsStateDocument
	                                    |	ON AgreementDocument.Department = DepartmentsStateDocument.Department
	                                    |WHERE
	                                    |	RoutesPoints.Ref = &RoutePoint
	                                    |	AND AgreementDocument.Ref = &Document
										|	AND %AddCondition");
										
	QueryPointParameters.SetParameter("Document", Document);
	If TypeOf(Document)=Type("DocumentRef.fmBudget") Then
		QueryPointParameters.SetParameter("Period", Document.BeginOfPeriod);
	Else
		QueryPointParameters.SetParameter("Period", Document.ExpenseDate);
	EndIf;
	QueryPointParameters.SetParameter("RoutePoint", RoutePoint);
	QueryPointParameters.SetParameter("BalanceUnit", BalanceUnit);
	QueryPointParameters.Text = StrReplace(QueryPointParameters.Text, "%AddCondition", ?(DynamicPoint, "AgreementDocument.%BalanceUnit = &BalanceUnit", "True"));
	PointParameters = QueryPointParameters.Execute().SELECT();
	PointParameters.Next();
	
	// Найдем ответственного в зависимости от настроек точки маршрута с учетом списка замен.
	If PointParameters.AccessType = Enums.fmAccessTypeToRoutePoint.NoLimit Then
		Return PointParameters.Responsible;
	ElsIf PointParameters.AccessType = Enums.fmAccessTypeToRoutePoint.FixedDepartment Then
		If ValueIsFilled(PointParameters.UserDepartment) Then
			Return PointParameters.UserDepartment;
		Else
			Raise StrTemplate(NStr("en='The responsible person for point ""%1"" of route ""%2"" is not specified';ru='Не определен ответственный для точки ""%1"" маршрута ""%2""'"), RoutePoint, RoutePoint.Owner);
		EndIf;
	ElsIf PointParameters.AccessType = Enums.fmAccessTypeToRoutePoint.DocumentDepartment Then
	//ИЛИ ПараметрыТочки.ВидДоступа = Перечисления.уфВидДоступаКТочкеМаршрута.ПодразделениеТЧДокумента Тогда
		If PointParameters.DepartmentLevel = 0 Then
			If ValueIsFilled(PointParameters.DocumentDepartmentUser) Then
				Return PointParameters.DocumentDepartmentUser;
			Else
				Raise StrTemplate(NStr("en='The responsible person for point ""%1"" of route ""%2"" is not specified';ru='Не определен ответственный для точки ""%1"" маршрута ""%2""'"), RoutePoint, RoutePoint.Owner);
			EndIf;
		Else
			DocumentDepartment = fmProcessManagement.GetDepartmentParent(PointParameters.DocumentDepartment, PointParameters.DepartmentLevel);
			If DocumentDepartment = Undefined Then
				Raise StrTemplate(NStr("en='The responsible person for point ""%1"" of route ""%2"" is not specified';ru='Не определен ответственный для точки ""%1"" маршрута ""%2""'"), RoutePoint, RoutePoint.Owner);
			Else
				CurResponsible = GetDepartmentResponsible(DocumentDepartment, Document.BeginOfPeriod);
				If ValueIsFilled(CurResponsible) Then
					Return CurResponsible;
				Else
					Raise StrTemplate(NStr("en='The responsible person for point ""%1"" of route ""%2"" is not specified';ru='Не определен ответственный для точки ""%1"" маршрута ""%2""'"), RoutePoint, RoutePoint.Owner);
				EndIf;
			EndIf;
		EndIf;
	ElsIf PointParameters.AccessType = Enums.fmAccessTypeToRoutePoint.FixedUser Then
		Return PointParameters.User;
	ElsIf PointParameters.AccessType = Enums.fmAccessTypeToRoutePoint.ManageType Then
		DocumentDepartment = fmProcessManagement.FindDepartmentByManagementType(PointParameters.DocumentDepartment, PointParameters.ManageType);
		If DocumentDepartment = Undefined Then
			Raise StrTemplate(NStr("en='The responsible person for point ""%1"" of route ""%2"" is not specified';ru='Не определен ответственный для точки ""%1"" маршрута ""%2""'"), RoutePoint, RoutePoint.Owner);
		Else
			CurResponsible = GetDepartmentResponsible(DocumentDepartment, Document.BeginOfPeriod);
			If ValueIsFilled(CurResponsible) Then
				Return CurResponsible;
			Else
				Raise StrTemplate(NStr("en='The responsible person for point ""%1"" of route ""%2"" is not specified';ru='Не определен ответственный для точки ""%1"" маршрута ""%2""'"), RoutePoint, RoutePoint.Owner);
			EndIf;
		EndIf;
	EndIf;
	
EndFunction

// Функция возвращает ответственного по подразделению.
//
Function GetDepartmentResponsible(Department, VAL DATE=Undefined) Export
	
	If DATE=Undefined Then
		DATE=CurrentSessionDate();
	EndIf;
	
	Query = New Query();
	Query.Text = 
	"SELECT
	|	DepartmentsStateSliceLast.Responsible
	|FROM
	|	InformationRegister.fmDepartmentsState.SliceLast(&Period, Department = &Department) AS DepartmentsStateSliceLast";
	Query.SetParameter("Department", Department);
	Query.SetParameter("Period", CurrentDate());
	Result = Query.Execute().SELECT();
	
	If Result.Next() AND ValueIsFilled(Result.Responsible) Then 
		Return Result.Responsible;
	Else
		CommonClientServer.MessageToUser(StrTemplate(NStr("en='The responsible person for department ""%1"" is not found.';ru='Не найден ответственный за подразделение ""%1""!'"), TrimAll(Department)));
		Return Catalogs.Users.EmptyRef();
	EndIf;
	
EndFunction

// Процедура выполняет согласование по умолчанию всех точек для указанного документа по маршруту согласования
//
Procedure AgreeDocumentByAllPoints(Document, Route, Comment = "") Export
	
	BeginTransaction();
	
	CurUser = SessionParameters.CurrentUser;
	DynamicPoint = IsDynamicStage(Document);
	
	// Получим список пользователей, которые в текущий момент согласовывают документ,
	// список самих точек, а так же список их замен.
	Query = New Query("SELECT ALLOWED
	                      |	RoutesPointsPointsPredecessors.RoutePoint
	                      |INTO TTPredecessor
	                      |FROM
	                      |	Catalog.fmRoutesPoints.PointsPredecessors AS RoutesPointsPointsPredecessors
	                      |WHERE
	                      |	RoutesPointsPointsPredecessors.RoutePoint.Owner = &Route
	                      |	AND (NOT RoutesPointsPointsPredecessors.RoutePoint.DeletionMark)
	                      |;
	                      |
	                      |////////////////////////////////////////////////////////////////////////////////
	                      |SELECT ALLOWED
	                      |	ISNULL(DepartmentsStatePoint.Responsible, Value(Catalog.Users.EmptyRef)) AS UserDepartment,
	                      |	RoutesPoints.AccessTypeToRoutePoint AS AccessType,
	                      |	RoutesPoints.DepartmentLevel AS DepartmentLevel,
	                      |	RoutesPoints.User AS User,
	                      |	RoutesPoints.Ref AS RoutePoint,
	                      |	RoutesPoints.AgreementState AS PointState,
						  |	AgreementDocument.Department AS DocumentDepartment,
	                      |	ISNULL(DepartmentsStateDocument.Responsible, Value(Catalog.Users.EmptyRef)) AS DocumentDepartmentUser
	                      |FROM
	                      |	Catalog.fmRoutesPoints AS RoutesPoints
						  |	LEFT JOIN InformationRegister.fmDepartmentsState.SliceLast(&Period, ) AS DepartmentsStatePoint
						  |	ON RoutesPoints.Department = DepartmentsStatePoint.Department,
	                      |	Document." + Document.Metadata().Name + ?(DynamicPoint, ".PaymentDetails", "") + " AS AgreementDocument
	                      |	LEFT JOIN InformationRegister.fmDepartmentsState.SliceLast(&Period, ) AS DepartmentsStateDocument
	                      |	ON AgreementDocument.Department = DepartmentsStateDocument.Department
	                      |WHERE
	                      |	(NOT RoutesPoints.DeletionMark)
	                      |	AND RoutesPoints.Owner = &Route
	                      |	AND (NOT RoutesPoints.Ref IN
	                      |				(SELECT
	                      |					TTPredecessor.RoutePoint
	                      |				FROM
	                      |					TTPredecessor AS TTPredecessor))
	                      |	AND AgreementDocument.Ref = &DocumentRef
	                      |;
	                      |
	                      |////////////////////////////////////////////////////////////////////////////////
	                      |SELECT ALLOWED
	                      |	fmRouteStatesSliceLast.RoutePoint.AccessTypeToRoutePoint AS AccessType,
	                      |	fmRouteStatesSliceLast.RoutePoint.DepartmentLevel AS DepartmentLevel,
	                      |	fmRouteStatesSliceLast.Document.Department AS DocumentDepartment,
						  |	fmRouteStatesSliceLast.RoutePoint.Department AS RoutePointDepartment,
	                      |	fmRouteStatesSliceLast.RoutePoint.User AS User,
	                      |	fmRouteStatesSliceLast.RoutePoint.ManageType AS ManageType,
						  |	fmRouteStatesSliceLast.RoutePoint AS RoutePoint,
						  |	fmRouteStatesSliceLast.Version AS Version,
						  |	fmRouteStatesSliceLast.RoutePoint.AgreementState AS PointState,
						  |	fmRouteStatesSliceLast.Period AS Period
						  |FROM
						  |	InformationRegister.fmRouteStates.SliceLast(
	                      |			,
	                      |			Document = &DocumentRef
	                      |				AND AgreementRoute = &Route) AS fmRouteStatesSliceLast
	                      |WHERE
	                      |	fmRouteStatesSliceLast.PointState = Value(Catalog.fmRoutePointsStates.EmptyRef)
	                      |
	                      |ORDER BY
	                      |	Period
	                      |;
	                      |
	                      |////////////////////////////////////////////////////////////////////////////////
	                      |SELECT ALLOWED
	                      |	fmResponsiblesReplacements.Responsible
	                      |FROM
	                      |	InformationRegister.fmResponsiblesReplacements AS fmResponsiblesReplacements
	                      |WHERE
	                      |	fmResponsiblesReplacements.ResponsibleReplacing = &CurUser
	                      |	AND (fmResponsiblesReplacements.BeginDate <= &CurrentDate
	                      |			OR fmResponsiblesReplacements.BeginDate = DATETIME(1, 1, 1, 0, 0, 0))
	                      |	AND (fmResponsiblesReplacements.EndDate >= &CurrentDate
	                      |			OR fmResponsiblesReplacements.EndDate = DATETIME(1, 1, 1, 0, 0, 0))");
	
	Query.SetParameter("DocumentRef", Document);
	If TypeOf(Document)=Type("DocumentRef.fmBudget") Then
		Query.SetParameter("Period", Document.BeginOfPeriod);
	Else
		Query.SetParameter("Period", Document.ExpenseDate);
	EndIf;
	Query.SetParameter("Route", Route);
	Query.SetParameter("CurUser", CurUser);
	Query.SetParameter("CurrentDate", BegOfDay(CurrentDate()));
	
	Result = Query.ExecuteBatch();
	
	ReplacingList = Result[3].Unload().UnloadColumn("Responsible");
	
	// Записывать будем по одной точке, так как параллельные точки могут 
	// выполняться и можно пропустить переход на следующий уровень.
	RegisterRecord = InformationRegisters.fmRouteStates.CreateRecordManager();
	// Будем проверять возможность редактирования открытых точек.
	OpenPoints = Result[2].Unload();
	AgreementPoints = New Array();
	For Each CurPoint In OpenPoints Do
		If NOT DenyPointProcessing(CurPoint, CurUser, ReplacingList, ?(TypeOf(Document)=Type("DocumentRef.fmBudget"), Document.BeginOfPeriod, Document.DATE)) Then
			If NOT ValueIsFilled(CurPoint.PointState) Then
				CommonClientServer.MessageToUser(NStr("en='The default approval status is not set for the route point!';ru='Для точки маршрута не указано состояние согласования по умолчанию!'"));
				RollbackTransaction();
				Return;
			EndIf;	
			RegisterRecord.Document = Document;
			RegisterRecord.AgreementRoute = Route;
			RegisterRecord.RoutePoint = CurPoint.RoutePoint;
			RegisterRecord.Version = CurPoint.Version;
			RegisterRecord.Period = CurPoint.Period;
			If IsDynamicStage(Document, CurPoint.RoutePoint) Then 
				RegisterRecord.Department = CurPoint.DocumentDepartment;
			EndIf;
			RegisterRecord.Read();
			// Возможно кто-то или что-то успело сделать с записью, поэтому проверим как она считалась.
			If RegisterRecord.Selected() Then
				RegisterRecord.PointState = CurPoint.PointState;
				// Установим дату изменения состояния точки.
				RegisterRecord.Period = CurrentDate();
				RegisterRecord.Comment = Comment;
				RegisterRecord.Write();
				// Сохраним согласованную точку, чтобы не согласовывать ее вне очереди.
				AgreementPoints.Add(CurPoint.RoutePoint);
			Else				
				CommonClientServer.MessageToUser(StrTemplate(NStr("en='Failed to set an approval status for route point by default! %1';ru='Не удалось для точки маршрута установить состояние согласования по умолчанию! %1'"), ErrorDescription()));
				RollbackTransaction();
				Return;
			EndIf;
		EndIf;
	EndDo;
	
	CommitTransaction();
	
EndProcedure // СогласоватьДокументПоВсемТочкам()	

// Процедура выполняет отклонение документа по маршруту согласования
// для указанного пользователя (если пользователь не указан, то берется из параметров сеанса).
//
Procedure RejectDocument(Document, Route, Comment = "") Export
	
	BeginTransaction();
	
	CurUser = SessionParameters.CurrentUser;
	DynamicPoint = IsDynamicStage(Document);
	
	// Получим список пользователей, которые в текущий момент согласовывают документ,
	// список самих точек, а так же список их замен.
	Query = New Query("SELECT ALLOWED
	                      |	fmRouteStatesSliceLast.RoutePoint.AccessTypeToRoutePoint AS AccessType,
	                      |	fmRouteStatesSliceLast.RoutePoint.DepartmentLevel AS DepartmentLevel,
	                      |	fmRouteStatesSliceLast.RoutePoint.User AS User,
	                      |	fmRouteStatesSliceLast.RoutePoint AS RoutePoint,
	                      |	fmRouteStatesSliceLast.Version AS Version,
	                      |	fmRouteStatesSliceLast.RoutePoint.DeviationState AS PointState,
	                      |	fmRouteStatesSliceLast.Period AS Period,
	                      |	fmRouteStatesSliceLast.RoutePoint.PointsPredecessors.(
	                      |		Ref 
	                      |	) AS PointsPredecessors,
	                      |	fmRouteStatesSliceLast.Document.Department AS DocumentDepartment,
	                      |	fmRouteStatesSliceLast.RoutePoint.Department AS RoutePointDepartment,
	                      |	fmRouteStatesSliceLast.RoutePoint.ManageType AS ManageType
	                      |FROM
	                      |	InformationRegister.fmRouteStates.SliceLast(
	                      |			,
	                      |			Document = &DocumentRef
	                      |				AND AgreementRoute = &Route) AS fmRouteStatesSliceLast
	                      |WHERE
	                      |	fmRouteStatesSliceLast.PointState = Value(Catalog.fmRoutePointsStates.EmptyRef)
	                      |
	                      |ORDER BY
	                      |	Period
	                      |;
	                      |
	                      |////////////////////////////////////////////////////////////////////////////////
	                      |SELECT ALLOWED
	                      |	fmResponsiblesReplacements.Responsible
	                      |FROM
	                      |	InformationRegister.fmResponsiblesReplacements AS fmResponsiblesReplacements
	                      |WHERE
	                      |	fmResponsiblesReplacements.ResponsibleReplacing = &CurUser
	                      |	AND (fmResponsiblesReplacements.BeginDate <= &CurrentDate
	                      |			OR fmResponsiblesReplacements.BeginDate = DATETIME(1, 1, 1, 0, 0, 0))
	                      |	AND (fmResponsiblesReplacements.EndDate >= &CurrentDate
	                      |			OR fmResponsiblesReplacements.EndDate = DATETIME(1, 1, 1, 0, 0, 0))");
	
	Query.SetParameter("DocumentRef", Document);
	Query.SetParameter("Route", Route);
	Query.SetParameter("CurUser", CurUser);
	Query.SetParameter("CurrentDate", BegOfDay(CurrentDate()));

	Result = Query.ExecuteBatch();
	
	ReplacingList = Result[1].Unload().UnloadColumn("Responsible");
	
	// Записывать будем по одной точке, так как параллельные точки могут 
	// выполняться и можно пропустить переход на следующий уровень.
	RegisterRecord = InformationRegisters.fmRouteStates.CreateRecordManager();		
	// Будем проверять возможность редактирования открытых точек.
	OpenPoints = Result[0].Unload();
	AgreementPoints = New Array();
	For Each CurPoint In OpenPoints Do
		If NOT DenyPointProcessing(CurPoint, CurUser, ReplacingList, ?(TypeOf(Document)=Type("DocumentRef.fmBudget"), Document.BeginOfPeriod, Document.DATE)) Then
			
			If CurPoint.PointsPredecessors.Count() = 0 Then
				Continue;
			EndIf;
			
			If NOT ValueIsFilled(CurPoint.PointState) Then
				CommonClientServer.MessageToUser(NStr("en='The default deviation status is not set for the route point!';ru='Для точки маршрута не указано состояние отклонения по умолчанию!'"));
				RollbackTransaction();
				Return;
			EndIf;
			
			RegisterRecord.Document = Document;
			RegisterRecord.AgreementRoute = Route;
			RegisterRecord.RoutePoint = CurPoint.RoutePoint;
			RegisterRecord.Version = CurPoint.Version;
			RegisterRecord.Period = CurPoint.Period;
			RegisterRecord.Read();
			// Возможно кто-то или что-то успело сделать с записью, поэтому проверим как она считалась.
			If RegisterRecord.Selected() Then
				RegisterRecord.PointState = CurPoint.PointState;
				// Установим дату изменения состояния точки.
				RegisterRecord.Period = CurrentDate();
				RegisterRecord.Comment = Comment;
				Try
					RegisterRecord.Write();
					// Сохраним согласованную точку, чтобы не согласовывать ее вне очереди.
					AgreementPoints.Add(CurPoint.RoutePoint);
				Except
					CommonClientServer.MessageToUser(StrTemplate(NStr("en='Failed to set a deviation status for the route point by default! %1';ru='Не удалось для точки маршрута установить состояние отклонения по умолчанию! %1'"), ErrorDescription()));
					RollbackTransaction();
					Return;
				EndTry;
			Else
				CommonClientServer.MessageToUser(StrTemplate(NStr("en='Failed to set a deviation status for the route point by default! %1';ru='Не удалось для точки маршрута установить состояние отклонения по умолчанию! %1'"), ErrorDescription()));
				RollbackTransaction();
				Return;
			EndIf;
			Break;
			
		EndIf;
	EndDo;
	
	CommitTransaction();
	
EndProcedure // ОтклонитьДокумент()

// Процедура очищает указанный маршрут 
Procedure ClearEmptyRouteStates(Document, Route, Version, Cancel = False, DeletionReason = "", CommentToLetter = "") Export
	
	// Если был отказ раньше, то нет смысла писать/читать БД.
	If Cancel Then
		Return;
	EndIf;
	
	// Будем хранить пользователей для отправки писем после успешной записи состояний.
	VTLettersSending = New ValueTable();
	VTLettersSending.Columns.Add("Responsible");
	VTLettersSending.Columns.Add("Document");
	VTLettersSending.Columns.Add("RoutePoint");
	VTLettersSending.Columns.Add("Route");
	VTLettersSending.Columns.Add("Version");
	
	RecordDeletionSet = InformationRegisters.fmRouteStates.CreateRecordSet();
	RecordDeletionSet.Filter.Document.Set(Document);
	RecordDeletionSet.Filter.AgreementRoute.Set(Route);
	RecordDeletionSet.Filter.Version.Set(Version);
	RecordDeletionSet.Read();
	RecordDeletionSet.AdditionalProperties.Insert("IntermediateRecord", True);
	
	DeletingRecordsList = New ValueList();
	For Each CurRecord In RecordDeletionSet Do
		If NOT ValueIsFilled(CurRecord.PointState) Then
			DeletingRecordsList.Add(CurRecord);
			NewLine = VTLettersSending.Add();
			FillPropertyValues(NewLine, CurRecord);
		EndIf;	
	EndDo;
	
	If DeletingRecordsList.Count() > 0 Then
		For Each CurRecord In DeletingRecordsList Do
			RecordDeletionSet.Delete(CurRecord.Value);
		EndDo;
		Try
			RecordDeletionSet.Write();
		Except			
			CommonClientServer.MessageToUser(StrTemplate(NStr("en='Failed to clear the route of unprocessed points! %1';ru='Не удалось очистить маршрут от необработанных точек! %1'"), ErrorDescription()), , , , Cancel);
			Return;
		EndTry;	
	EndIf;
	
	// Если запись прошла успешно, значит можно отправлять письма.
	For Each CurRecord In VTLettersSending Do
		If ValueIsFilled(CurRecord.Responsible) AND NOT Cancel Then
			
			If TypeOf(CurRecord.Document)=Type("DocumentRef.fmBudget") Then
				
				VersionText = GenerateVersionText(CurRecord.Version);
				MessageTopic = StrTemplate(NStr("en='Cancel budget approval of department ""%1"" for %2 year, scenario ""%3""';ru='Отмена согласования бюджета подразделения ""%1"" за %2 год, сценарий ""%3""'"), TrimAll(CurRecord.Document.Department), Year(CurRecord.Document.BeginOfPeriod), TrimAll(CurRecord.Document.Scenario) + VersionText);
				
				LetterText = NStr("en='Hello, ';ru='Здравствуйте, '")+ TrimAll(CurRecord.Responsible) + "!" + Chars.LF + Chars.LF +
				NStr("en='Cancel approval of the department budget""';ru='Отмена согласования бюджета подразделения""'") + TrimAll(CurRecord.Document.Department) + NStr("en='"" for ';ru='"" за '") +
				Year(CurRecord.Document.BeginOfPeriod) + NStr("en='year, scenario ""';ru=' год, сценарий ""'") + TrimAll(CurRecord.Document.Scenario) + VersionText + NStr("en='"", Undergoing approval ""';ru='"", проходящий маршрут согласования ""'") +
				TrimAll(CurRecord.Route) + NStr("en='"" at the point ""';ru='"" в точке ""'") + TrimAll(CurRecord.RoutePoint) + """" + DeletionReason + ".";
				If ValueIsFilled(CommentToLetter) Then
					LetterText = LetterText + Chars.LF + NStr("en='Comment';ru='Комментарий '") + CommentToLetter;
				EndIf;
				AddRefToLetterText(LetterText, CurRecord.Document);
				
				fmEmailManagement.SendMailViaNotification(CurRecord.Responsible, MessageTopic, LetterText, Document);
				
				// Отправим при необходимости письма заменяющим.
				VTOfReplaces = fmProcessManagement.GetReplacesListParameters(CurRecord.Responsible);
				For Each CurReplace In VTOfReplaces Do
					
					MessageTopic = StrTemplate(NStr("en='%1 (replacement of responsible %2)';ru='%1 (замена ответственного %2)'"),MessageTopic , TrimAll(CurRecord.Responsible));
					
					LetterText = NStr("en='Hello, ';ru='Здравствуйте, '")+ TrimAll(CurReplace.Replacing) + "!" + Chars.LF + Chars.LF +
					NStr("en='Cancel approval of the department budget""';ru='Отмена согласования бюджета подразделения""'") + TrimAll(CurRecord.Document.Department) + NStr("en='"" for ';ru='"" за '") +
					Year(CurRecord.Document.BeginOfPeriod) + NStr("en='year, scenario ""';ru=' год, сценарий ""'") + TrimAll(CurRecord.Document.Scenario) + VersionText + NStr("en='"", Undergoing approval ""';ru='"", проходящий маршрут согласования ""'") +
					TrimAll(CurRecord.Route) + NStr("en='"" at the point ""';ru='"" в точке ""'") + TrimAll(CurRecord.RoutePoint) + """" + DeletionReason + ".";
					If ValueIsFilled(CommentToLetter) Then
						LetterText = LetterText + Chars.LF + NStr("en='Comment';ru='Комментарий '") + CommentToLetter;
					EndIf;
					LetterText = LetterText + Chars.LF + NStr("en='The letter is initiated by substitution of responsible user';ru='Письмо инициировано заменой Вами ответственного пользователя '") + TrimAll(CurRecord.Responsible);
					AddRefToLetterText(LetterText, CurRecord.Document);
					
					fmEmailManagement.SendMailViaNotification(CurReplace.Replacing, MessageTopic, LetterText, Document);
					
				EndDo;
				
			Else
				
				MessageTopic = StrTemplate(NStr("en='Cancel expense request approval of department ""%1"" as of %2';ru='Отмена согласования заявки на расход подразделения ""%1"" на %2'"), TrimAll(CurRecord.Document.Department), Format(CurRecord.Document.ExpenseDate, "DLF=DD"));
				
				LetterText = NStr("en='Hello, ';ru='Здравствуйте, '")+ TrimAll(CurRecord.Responsible) + "!" + Chars.LF + Chars.LF +
				NStr("en='Cancel approval of the department expense request""';ru='Отмена согласования заявки на расход подразделения""'") + TrimAll(CurRecord.Document.Department) + NStr("en='"" as of';ru='"" на '") +
				Format(CurRecord.Document.ExpenseDate, "DLF=DD") + NStr("en=', Undergoing approval ""';ru=', проходящей маршрут согласования ""'") +
				TrimAll(CurRecord.Route) + NStr("en='"" at the point ""';ru='"" в точке ""'") + TrimAll(CurRecord.RoutePoint) + """" + DeletionReason + ".";
				If ValueIsFilled(CommentToLetter) Then
					LetterText = LetterText + Chars.LF + NStr("en='Comment';ru='Комментарий '") + CommentToLetter;
				EndIf;
				AddRefToLetterText(LetterText, CurRecord.Document);
				
				fmEmailManagement.SendMailViaNotification(CurRecord.Responsible, MessageTopic, LetterText, Document);
				
				// Отправим при необходимости письма заменяющим.
				VTOfReplaces = fmProcessManagement.GetReplacesListParameters(CurRecord.Responsible);
				For Each CurReplace In VTOfReplaces Do
					
					MessageTopic = StrTemplate(NStr("en='%1 (replacement of responsible %2)';ru='%1 (замена ответственного %2)'"), MessageTopic, TrimAll(CurRecord.Responsible));
					
					LetterText = NStr("en='Hello, ';ru='Здравствуйте, '")+ TrimAll(CurReplace.Replacing) + "!" + Chars.LF + Chars.LF +
					NStr("en='Cancel approval of the department expense request""';ru='Отмена согласования заявки на расход подразделения""'") + TrimAll(CurRecord.Document.Department) + NStr("en='"" as of';ru='"" на '") +
					Format(CurRecord.Document.ExpenseDate, "DLF=DD") + NStr("en=', Undergoing approval ""';ru=', проходящей маршрут согласования ""'") +
					TrimAll(CurRecord.Route) + NStr("en='"" at the point ""';ru='"" в точке ""'") + TrimAll(CurRecord.RoutePoint) + """" + DeletionReason + ".";
					If ValueIsFilled(CommentToLetter) Then
						LetterText = LetterText + Chars.LF + NStr("en='Comment';ru='Комментарий '") + CommentToLetter;
					EndIf;
					LetterText = LetterText + Chars.LF + NStr("en='The letter is initiated by substitution of responsible user';ru='Письмо инициировано заменой Вами ответственного пользователя '") + TrimAll(CurRecord.Responsible);
					AddRefToLetterText(LetterText, CurRecord.Document);
					
					fmEmailManagement.SendMailViaNotification(CurReplace.Replacing, MessageTopic, LetterText, Document);
					
				EndDo;
				
			EndIf;
			
		EndIf;
	EndDo;
	
EndProcedure // ОчиститьПустыеСостоянияМаршрута()

// Функция определяет, находится ли данный документ на согласовании
//
Function DocumentOnAgreement(DocumentRef, Version)
	
	Query = New Query(
	"SELECT ALLOWED TOP 1
	|	fmRouteStatesSliceLast.PointState
	|FROM
	|	InformationRegister.fmRouteStates.SliceLast(
	|			,
	|			Document = &Document
	|				AND Version = &Version) AS fmRouteStatesSliceLast");
	
	Query.SetParameter("Document", DocumentRef);
	Query.SetParameter("Version", Version);
	Result = Query.Execute().SELECT();
	
	Return Result.Next();
	
EndFunction // ДокументНаСогласовании()

// Процедура выполняет проверку корректности настройки маршрута
//
Procedure RouteCorrectnessCheck(Route) Export
	
	If Route.IsFolder Then
		Return;
	EndIf;
	
	NoErrors = True;
	CommonClientServer.MessageToUser(StrTemplate(NStr("en='Verification of the accuracy of ""%1"" approval route settings:';ru='Проверка корректности настройки маршрута согласования ""%1"":'"), TrimAll(Route)));
	
	// Проверим количество начальных точек, должна быть только одна.
	InitialPoints = GetInitialRouteModelPoints(Route);
	If InitialPoints.Count() = 0 Then
		CommonClientServer.MessageToUser(NStr("en='The start route point is not found.';ru='Не обнаружена начальная точка маршрута!'"));
		NoErrors = False;
	ElsIf InitialPoints.Count() > 1 Then
		CommonClientServer.MessageToUser(NStr("en='You cannot have more than one start point in the route.';ru='Недопустимо наличие более одной начальной точки в маршруте!'"));
		NoErrors = False;
	Else
		For Each CurRow In InitialPoints Do
			// Проверим, чтобы у начальной точки было был доступ "Без ограничений"
			If NOT CurRow.Point.AccessTypeToRoutePoint = Enums.fmAccessTypeToRoutePoint.NoLimit Then
				CommonClientServer.MessageToUser(NStr("en='For the route start point, the ""Without restrictions"" access type can be set only.';ru='Для начальной точки маршрута может быть установлен только вид доступа ""Без ограничений""!'"));
				NoErrors = False;
			EndIf;
		EndDo;
	EndIf;	
	
	// Получим данные о точках маршрута и произведем их проверку.
	Query = New Query(
	"SELECT
	|	RoutesPoints.Ref,
	|	RoutesPoints.AgreementState,
	|	RoutesPoints.DeviationState,
	|	RoutesPoints.AccessTypeToRoutePoint,
	|	RoutesPoints.Department AS Department
	|FROM
	|	Catalog.fmRoutesPoints AS RoutesPoints
	|WHERE
	|	RoutesPoints.Owner = &Route
	|	AND NOT RoutesPoints.DeletionMark");
	Query.SetParameter("Route", Route);
	Result = Query.Execute().SELECT();
	FinalPoints = New Array();
	While Result.Next() Do
		
		// Посчитаем количество конечных точек.
		If FinalStage(Result.Ref) Then
			FinalPoints.Add(Result.Ref);
		EndIf;
		
		// У каждой точки должно быть указано состояние согласования.
		If NOT ValueIsFilled(Result.AgreementState) Then
			CommonClientServer.MessageToUser(StrTemplate(NStr("en='The default approval status is not specified for route point ""%1""! It is impossible to cancel this point by clicking the ""Approve"" button.';ru='У точки маршрута ""%1"" не указано состояние согласования по умолчанию! Невозможно согласовать такую точку по кнопке ""Согласовать""!'"), TrimAll(Result.Ref)));
			NoErrors = False;
		EndIf;
		
		// У каждой точки должно быть указано состояние отклонения.
		If NOT ValueIsFilled(Result.DeviationState) AND  Result.Ref.PointsPredecessors.Count()<> 0 Then
			CommonClientServer.MessageToUser(StrTemplate(NStr("en='The default deviation status is not specified for route point ""%1""! It is impossible to cancel this point by clicking the ""Cancel"" button.';ru='У точки маршрута ""%1"" не указано состояние отклонения по умолчанию! Невозможно отклонить такую точку по кнопке ""Отклонить""!'"), TrimAll(Result.Ref)));
			NoErrors = False;
		EndIf;
		
		// Если доступ к точке по фиксированному подразделению, 
		// то у такого подразделения должен быть указан ответственный.
		If Result.AccessTypeToRoutePoint = Enums.fmAccessTypeToRoutePoint.FixedDepartment
			AND NOT ValueIsFilled(GetDepartmentResponsible(Result.Department)) Then
			NoErrors = False;
		EndIf;
		
		// Проверим, чтобы у точек были состояния.
		PointStates = Catalogs.fmRoutePointsStates.SELECT(, Result.Ref);
		If PointStates.Next() Then
			If PointStates.State = Catalogs.fmDocumentState.Approved Then				
				CommonClientServer.MessageToUser(StrTemplate(NStr("en='The Confirmed status of the document is specified for route point  ""%1"" with status ""%2"". This status is set automatically when approved at the end point!';ru='У точки маршрута ""%1"" в состоянии ""%2"" указано состояние для документа ""Утвержден"". Данное состояние устанавливается автоматически при согласовании в конечной точке!'"), TrimAll(Result.Ref), PointStates.Ref));
				NoErrors = False;
			EndIf;
			While PointStates.Next() Do
				If PointStates.State = Catalogs.fmDocumentState.Approved Then
					CommonClientServer.MessageToUser(StrTemplate(NStr("en='The Confirmed status of the document is specified for route point  ""%1"" with status ""%2"". This status is set automatically when approved at the end point!';ru='У точки маршрута ""%1"" в состоянии ""%2"" указано состояние для документа ""Утвержден"". Данное состояние устанавливается автоматически при согласовании в конечной точке!'"), TrimAll(Result.Ref), PointStates.Ref));
					NoErrors = False;
				EndIf;
			EndDo;
		Else			
			CommonClientServer.MessageToUser(StrTemplate(NStr("en='No status is detected for route point ""%1"".';ru='У точки маршрута ""%1"" не обнаружено ни одного состояния!'"), Result.Ref));
			NoErrors = False;
		EndIf;	
		
	EndDo;	
	
	// Конечная точка должна быть только одна.
	If FinalPoints.Count() = 0 Then
		CommonClientServer.MessageToUser(NStr("en='The end route point is not found.';ru='Не обнаружена конечная точка маршрута!'"));
		NoErrors = False;
	ElsIf FinalPoints.Count() > 1 Then
		CommonClientServer.MessageToUser(NStr("en='You cannot have more than one end point in the route.';ru='Недопустимо наличие более одной конечной точки в маршруте!'"));
		NoErrors = False;
	EndIf;
	
	If NoErrors Then
		CommonClientServer.MessageToUser(NStr("en='No errors found!';ru='Ошибок не обнаружено!'"));
	EndIf;	
	
EndProcedure // ПроверкаКорректностиМаршрута()	

// Процедура обработчик "ДобавитьСсылкуКТекстуПисьма" 
//
Procedure AddRefToLetterText(Text, Ref) Export 
	
	RefText = GetURL(Ref);
	IBRef  = GetInfoBaseURL();
	Text = Text + Chars.LF + Chars.LF + "Ref " + ?(TypeOf(Ref)=Type("DocumentRef.fmBudget") , "Budget: ", "заявку: ") + RefText;
	If Find(IBRef, "http") > 0 Then
		Text = Text + Chars.LF + "Web-Ref: " + IBRef + "/#" + RefText;
	EndIf;
	
EndProcedure

Function GetDocumentState(Document, Version) Export
	
	Query = New Query();
	Query.Text = 
	"SELECT
	|	fmDocumentStateSliceLast.State
	|FROM
	|	InformationRegister.fmDocumentState.SliceLast(
	|			,
	|			Document = &Document
	|				AND Version = &Version) AS fmDocumentStateSliceLast";
	Query.SetParameter("Document", Document);
	Query.SetParameter("Version", Version);
	Result = Query.Execute().SELECT();
	If Result.Next() Then 
		Return Result.State;
	Else
		Return Catalogs.fmDocumentState.EmptyRef();
	EndIf;
	
EndFunction

// Процедура устанавливает документу переданное состояние и проводит документ при необходимости
//
Procedure SetDocumentState(Document, State, Version, Cancel=False) Export
	
	If Cancel OR NOT ValueIsFilled(State) Then Return; EndIf;
	
	// получаем последнее состояние и меняем его при необходимости
	CurState = GetDocumentState(Document, Version);
	If CurState <> State Then 
		RecordState = InformationRegisters.fmDocumentState.CreateRecordManager();
		RecordState.Period                 = CurrentDate();
		RecordState.Document               = Document;
		RecordState.Version                 = Version;
		RecordState.State              = State;
		Try
			RecordState.Write();
		Except
			CommonClientServer.MessageToUser(StrTemplate(NStr("en='Failed to assign status ""%2"" %3 to document ""%1""';ru='Не удалось установить документу ""%1"" состояние ""%2"" %3'"), TrimAll(Document), TrimAll(State), ErrorDescription()), , , , Cancel);
		EndTry;
	EndIf;
	
EndProcedure // УстановитьСостояниеДокумента()

Function AgreementCheckDate(Ref) Export
	If TypeOf(Ref.Ref)=Type("DocumentRef.fmBudget") Then
		BudgetVersioning = Constants.fmBudgetVersioning.Get();
		If BudgetVersioning=Enums.fmBudgetVersioning.EveryDay
		OR BudgetVersioning=Enums.fmBudgetVersioning.EveryMonth Then
			Return Ref.ActualVersion;
		Else
			Return Ref.BeginOfPeriod;
		EndIf;
	Else
		Return Ref.DATE;
	EndIf;
EndFunction

Function GenerateVersionText(CurrentVersion) Export
	
	BudgetVersioning = Constants.fmBudgetVersioning.Get();
	If BudgetVersioning=Enums.fmBudgetVersioning.EveryMonth Then
		Return StrTemplate(NStr("en='"", version"" %1';ru='"", версия"" %1'"), Format(CurrentVersion, "L=en; DF='MMMM yyyy'"));
	ElsIf BudgetVersioning=Enums.fmBudgetVersioning.EveryDay Then
		Return StrTemplate(NStr("en='"", version"" %1';ru='"", версия"" %1'"), Format(CurrentVersion, "L=en; DF = 'dd MMMM yyyy'"));
	Else
		Return "";
	EndIf;
	
EndFunction


//////////////////////////////////////////////////////////////////////////////////////////////////////
// ОБРАБОТЧИКИ ПОДПИСОК НА СОБЫТИЯ СОГЛАСОВАНИЯ ДОКУМЕНТОВ

// Обработчик подписки на событие "ПередЗаписью" документа согласование
// Поиск подходящей модели согласования.
//
Procedure BeforeWriteAgreementRouteSearchDocumentBeforeWrite(Source, Cancel, WriteMode, PostingMode) Export
	
	// Служебная проверка.
	If Source.AdditionalProperties.Property("SkipAgreement") Then
		Return;
	EndIf;
	
	// Определим дату проверки.
	CurPeriod = fmProcessManagement.AgreementCheckDate(Source);
	
	If (TypeOf(Source.Ref)=Type("DocumentRef.fmBudget") AND Source.Scenario.ScenarioType=Enums.fmBudgetingScenarioTypes.Fact)
	OR NOT AgreeDocument(Source.Department, ChartsOfCharacteristicTypes.fmAgreeDocumentTypes[Source.Ref.Metadata().Name], CurPeriod) Then
		Return;
	Else
		CurrentVersion = fmBudgeting.DetermineDocumentVersion(Source);
	EndIf;
	
	// В случае каких-либо действий с документом проверим, а можно ли его редактировать пользователю.
	If DisableDocumentEditionOnAgreement(Source, CurrentVersion) Then 		
		CommonClientServer.MessageToUser(StrTemplate(NStr("en='It is forbidden to edit document ""%1"". The document is being approved or finalized.';ru='Запрещено редактирования документа ""%1"". Документ находится на согласовании или окончательно согласован.'"), Source.Ref), , , , Cancel);
		Return;
	EndIf;
	
	// Выполним поиск маршрута и начало его согласования при необходимости.
	SetNewStateAndModelOfRouteDocument(Source, Source.AgreementRoute);
	
	// Если пустой маршрут согласования и в настройках запрещено иметь документы без маршрута, то это ошибка записи.
	Agreement = False;
	If NOT ValueIsFilled(Source.AgreementRoute) 
	AND ((Source.AdditionalProperties.Property("Agreement", Agreement) AND Agreement) OR DocumentOnAgreement(Source.Ref, CurrentVersion)) Then
		CommonClientServer.MessageToUser(NStr("en='The appropriate route is not found';ru='Не обнаружен подходящий маршрут согласования!'"), , , , Cancel);
	EndIf;
	
EndProcedure // ПередЗаписьюДокументаПоискМаршрутаСогласованияПередЗаписью()

// Обработчик подписки на событие "ПриЗаписи" документа согласование
// Формируются начальные точки маршрута при необходимости.
//
Procedure OnWriteAgreementDocumentOnWrite(Source, Cancel) Export
	
	// Служебная проверка.
	If Source.AdditionalProperties.Property("SkipAgreement") Then
		Return;
	EndIf;
	
	// Определим дату проверки.
	CurPeriod = fmProcessManagement.AgreementCheckDate(Source);
	
	If (TypeOf(Source.Ref)=Type("DocumentRef.fmBudget") AND Source.Scenario.ScenarioType=Enums.fmBudgetingScenarioTypes.Fact)
	OR NOT AgreeDocument(Source.Department, ChartsOfCharacteristicTypes.fmAgreeDocumentTypes[Source.Ref.Metadata().Name], CurPeriod) Then
		Return;
	Else
		CurrentVersion = fmBudgeting.DetermineDocumentVersion(Source);
	EndIf;
	
	Agreement = False;
	If (Source.AdditionalProperties.Property("Agreement", Agreement) AND Agreement) 
	OR DocumentOnAgreement(Source.Ref, CurrentVersion) Then
		
		// Если состояния еще нет, то переводим в состояние "НаСогласовании" или указанное в первой точке.
		CurState = GetDocumentState(Source.Ref, CurrentVersion);
		If CurState = Catalogs.fmDocumentState.EmptyRef()
		OR CurState = Catalogs.fmDocumentState.Prepared Then
			InitialState = Catalogs.fmDocumentState.OnApproval;
			InitialPoints = GetInitialRouteModelPoints(Source.AgreementRoute);
			For Each CurPoint In InitialPoints Do
				If ValueIsFilled(CurPoint.DocumentState) Then
					InitialState = CurPoint.DocumentState;
				EndIf;	
			EndDo;	
			SetDocumentState(Source.Ref, InitialState, CurrentVersion);
		EndIf;
		
		Comment = "";
		If Source.AdditionalProperties.Property("Comment") Then
			Comment = Source.AdditionalProperties.Comment;
		EndIf;
		
		GenerateRouteRecords(Source.Ref, Source.AgreementRoute, Cancel, CurrentVersion, Comment);
		
	EndIf;
	
EndProcedure // ПриЗаписиДокументаСогласованиеПриЗаписи()


//////////////////////////////////////////////////////////////////////////////////////////////////////
// ПРОЦЕДУРЫ И ФУНКЦИИ ПО РАБОТЕ С ДЕРЕВОМ МАРШРУТА

// Функция определяет явлеется ли указанна точка (точки) маршрута конечной.
//
Function FinalStage(Stages) Export
	
	NextStagesQuery = New Query;
	NextStagesQuery.Text = 
	"SELECT ALLOWED
	|	ProcessesPointsStagesPredecessors.Ref
	|FROM
	|	Catalog.fmRoutesPoints.PointsPredecessors AS ProcessesPointsStagesPredecessors
	|WHERE
	|	ProcessesPointsStagesPredecessors.RoutePoint IN(&ProcessStages)
	|	AND NOT ProcessesPointsStagesPredecessors.Ref.DeletionMark";
	NextStagesQuery.SetParameter("ProcessStages", Stages);
	
	Selection = NextStagesQuery.Execute().SELECT();
	If Selection.Next() Then
		Return False;
	Else
		Return True;
	EndIf;
	
EndFunction // КонечныйЭтап()

// Функция определяет явлеется ли указанна точка (точки) маршрута конечной.
//
Function AgreementEnd(Route, Document, Stage, Department, VAL Version=Undefined) Export
	
	If NOT FinalStage(Stage) Then 
		Return False;
	EndIf;
	
	If Version=Undefined Then
		Version=Document.ActualVersion;
	EndIf;
	
	NextStagesQuery = New Query;
	NextStagesQuery.Text = 
	"SELECT
	|	RoutesPointsPointsPredecessors.RoutePoint
	|INTO PointsPredecessors
	|FROM
	|	Catalog.fmRoutesPoints.PointsPredecessors AS RoutesPointsPointsPredecessors
	|WHERE
	|	RoutesPointsPointsPredecessors.Ref.Owner = &Owner
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoutesPoints.Ref
	|INTO FinalPoints
	|FROM
	|	Catalog.fmRoutesPoints AS RoutesPoints
	|WHERE
	|	NOT RoutesPoints.Ref IN
	|				(SELECT
	|					Points.RoutePoint
	|				FROM
	|					PointsPredecessors AS Points)
	|	AND RoutesPoints.Owner = &Owner
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	fmRouteStatesSliceLast.RoutePoint,
	|	fmRouteStatesSliceLast.PointState,
	|	fmRouteStatesSliceLast.Department
	|FROM
	|	InformationRegister.fmRouteStates.SliceLast(
	|			,
	|			Document = &Document AND Version=&Version
	|				AND RoutePoint IN
	|					(SELECT
	|						FinalPoints.Ref
	|					FROM
	|						FinalPoints AS FinalPoints)) AS fmRouteStatesSliceLast
	|WHERE
	|	ISNULL(fmRouteStatesSliceLast.PointState.StageCompleted, 0) <> 1
	|	AND NOT(fmRouteStatesSliceLast.RoutePoint = &Stage
	|				AND fmRouteStatesSliceLast.Department = &Department)";
	NextStagesQuery.SetParameter("Owner", Route);
	NextStagesQuery.SetParameter("Stage", Stage);
	NextStagesQuery.SetParameter("Document", Document);
	NextStagesQuery.SetParameter("Version", Version);
	NextStagesQuery.SetParameter("Department", Department);
	
	Selection = NextStagesQuery.Execute().SELECT();
	Return NOT Selection.Next();
	
EndFunction // КонечныйЭтап()

// Функция получения списка предыдущих точек маршрута
//
// Параметры:
// МассивЭтапов - Массив точек маршрутов или точка маршрута, для которых надо получить предшествующие точки
// Уровень - 0 предыдущий, 1 - все предыдущие
//
// Возвращаемое значение:
// Массив из предыдущих точек
Function GettingPreviousStagesList(VAL StagesArray, Level = 0) Export
	
	Query = New Query;
	Query.Text = "SELECT ALLOWED
	|	ProcessesPointsStagesPredecessors.RoutePoint AS RoutePoint
	|FROM
	|	Catalog.fmRoutesPoints.PointsPredecessors AS ProcessesPointsStagesPredecessors
	|WHERE
	|	ProcessesPointsStagesPredecessors.Ref IN(&ProcessStages)
	|	AND (NOT ProcessesPointsStagesPredecessors.RoutePoint.DeletionMark)";	
	Query.SetParameter("ProcessStages", StagesArray);
	
	PreviousStagesArray = Query.Execute().Unload().UnloadColumn("RoutePoint");
	
	// Получим рекурсивно все предыдущие точки при необходимости.
	If Level = 1 AND PreviousStagesArray.Count() > 0 Then
		AddStagesArray = GettingPreviousStagesList(PreviousStagesArray, 1);
		For Each It In AddStagesArray Do
			PreviousStagesArray.Add(It);
		EndDo;
	EndIf;
	
	fmCommonUseServerCall.DeleteDuplicatedArrayItems(PreviousStagesArray);	
	Return PreviousStagesArray;
	
EndFunction // ПолучениеСпискаПредыдущихЭтапов()

// Функция получения списка последующих точек маршрута
//
// Параметры:
// МассивЭтапов - Массив точек маршрутов или точка маршрута, для которых надо получить последующие точки
// Уровень - 0 предыдущий, 1 - все предыдущие; (по-умолчанию 0)
//
// Возвращаемое значение:
// Массив из предыдущих точек
Function GettingFollowingStagesList(VAL StagesArray, Level = 0) Export
	
	NextStagesQuery = New Query;
	NextStagesQuery.Text = "SELECT ALLOWED
	|	ProcessesPointsStagesPredecessors.Ref AS RoutePoint
	|FROM
	|	Catalog.fmRoutesPoints.PointsPredecessors AS ProcessesPointsStagesPredecessors
	|WHERE
	|	ProcessesPointsStagesPredecessors.RoutePoint IN(&ProcessStages)
	|	AND (NOT ProcessesPointsStagesPredecessors.Ref.DeletionMark)";	
	NextStagesQuery.SetParameter("ProcessStages", StagesArray);
	
	NextStagesArray = NextStagesQuery.Execute().Unload().UnloadColumn("RoutePoint");
	
	// Получим рекурсивно все последующие точки при необходимости.
	If Level = 1 AND NextStagesArray.Count() > 0 Then		
		AddStagesArray = GettingFollowingStagesList(NextStagesArray, 1);
		For Each It In AddStagesArray Do
			NextStagesArray.Add(It);
		EndDo;
	EndIf;
	
	fmCommonUseServerCall.DeleteDuplicatedArrayItems(NextStagesArray);
	Return NextStagesArray;
	
EndFunction // ПолучениеСпискаПоследующихЭтапов()

// Функция возвращает таблицу значений с исходными точками маршрута по модели согласования
// и состояние согласования по умолчанию для каждой точки.
//
Function GetInitialRouteModelPoints(Route) Export
	
	// Начальная точка согласования должна быть одна, но для совместимости с предыдущими релизами	
	// оставлена возможность отработки нескольких точек маршрута.
	
	Query = New Query();
	Query.Text = "SELECT ALLOWED
	|	SUM(CASE
	|			WHEN RoutesPointsPointsPredecessors.Ref IS NULL 
	|				Then 0
	|			Else 1
	|		END) AS PredecessorsCount,
	|	RoutesPoints.Ref AS Point
	|INTO TTPredecessorPointsCount
	|FROM
	|	Catalog.fmRoutesPoints AS RoutesPoints
	|		LEFT JOIN Catalog.fmRoutesPoints.PointsPredecessors AS RoutesPointsPointsPredecessors
	|		ON RoutesPoints.Ref = RoutesPointsPointsPredecessors.Ref
	|WHERE
	|	RoutesPoints.Owner = &Route
	|	AND NOT RoutesPoints.DeletionMark
	|
	|GROUP BY
	|	RoutesPoints.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTPredecessorPointsCount.Point AS Point,
	|	TTPredecessorPointsCount.Point.AgreementState AS AgreementState,
	|	TTPredecessorPointsCount.Point.AgreementState.State AS DocumentState
	|FROM
	|	TTPredecessorPointsCount AS TTPredecessorPointsCount
	|WHERE
	|	TTPredecessorPointsCount.PredecessorsCount = 0";	
	Query.SetParameter("Route", Route);
	
	Result = Query.ExecuteBatch();	
	Return Result[1].Unload(); 
	
EndFunction // ПолучитьИсходныеТочкиМоделиМаршрута()

// Функция определяет, является ли точка динамическая
// и подходит ли документ для динамической точки
Function IsDynamicStage(DocumentRef, RoutePoint = Undefined) Export
	Return False;
EndFunction











