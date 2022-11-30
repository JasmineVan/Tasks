
////////////////////////////////////////////////////////////////////////////////
// ПЕРЕМЕННЫЕ МОДУДЛЯ

Var IndentWidth Export; // переменная - ширина отступа при оформлении карты маршрута
Var IndentHeight Export; // переменная - высота отступа при оформлении карты маршрута
Var IndentBeforeArrow Export; // переменная - отступ перед элементом "стрелка" при оформлении карты маршрута
Var OutputStagesList Export; // переменная - массив точек, подлежащих выводу.

Var DetailsList Export; // СписокРасшифровок
Var WebClient Export; // ВебКлиент

////////////////////////////////////////////////////////////////////////////////
// ЭКСПОРТИРУЕМЫЕ ПРОЦЕДУРЫ И ФУНКЦИИ

// Процедура формирует отчет
//
Procedure GenerateReport(SpreadsheetDocumentField) Export
	
	Var Levels; //локальная переменная процедуры - уровни элементов на карте маршрута
	If ItemHeight < 32 Then 
		ItemHeight = 32;
	EndIf;
	
	// Заполним комментарии.
	Comments = fmProcessManagement.GetComments(RouteDocument, RouteModel, Version);
	
	// Получим последний несогласованный этап.
	Query = New Query(
	"SELECT ALLOWED
	|	RouteStatesSliceLast.RoutePoint AS RoutePoint
	|FROM
	|	InformationRegister.fmRouteStates.SliceLast(
	|			&Period,
	|			Document = &RouteDocument
	|				AND AgreementRoute = &RouteModel AND Version = &Version) AS RouteStatesSliceLast
	|WHERE
	|	RouteStatesSliceLast.PointState = Value(Catalog.fmRoutePointsStates.EmptyRef)
	|	OR RouteStatesSliceLast.PointState.StageCompleted = 2
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	RoutesPoints.Ref AS RoutePoint
	|FROM
	|	Catalog.fmRoutesPoints AS RoutesPoints
	|WHERE
	|	RoutesPoints.Owner = &RouteModel
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	RoutesPoints.Ref AS RoutePoint
	|FROM
	|	Catalog.fmRoutesPoints AS RoutesPoints
	|		LEFT JOIN Catalog.fmRoutesPoints.PointsPredecessors AS RoutesPointsPointsPredecessors
	|		ON RoutesPoints.Ref = RoutesPointsPointsPredecessors.RoutePoint
	|WHERE
	|	RoutesPoints.Owner = &RouteModel
	|	AND RoutesPointsPointsPredecessors.RoutePoint IS NULL ");
	
	Query.SetParameter("RouteDocument", RouteDocument);
	Query.SetParameter("RouteModel", RouteModel);
	Query.SetParameter("Period", Period);
	Query.SetParameter("Version", Version);
	QueryResult = Query.ExecuteBatch();
	CurStages = QueryResult[0].Unload().UnloadColumn("RoutePoint");
	FinalPoints = QueryResult[2].Unload().UnloadColumn("RoutePoint");
	OutputStagesList = QueryResult[1].Unload().UnloadColumn("RoutePoint");
	
	If NOT OutputAllPoints Then 
		For Each EndPoint In FinalPoints Do
			ProcessOutputStagesList(EndPoint, CurStages);
		EndDo;
	EndIf;
	
	Stages = GetStagesTable(RouteModel, Levels);
	OutputStagesDiagram(Stages, Levels, SpreadsheetDocumentField);
	Stages = Undefined;
	Levels = Undefined;
	
EndProcedure

Procedure ProcessOutputStagesList(Point, CurStages)
	
	For Each CurPoint In Point.PointsPredecessors Do
		
		If CurStages.Find(CurPoint.RoutePoint) <> Undefined Then 
			IndexOf = OutputStagesList.Find(Point);
			If IndexOf <> Undefined Then 
				OutputStagesList.Delete(IndexOf);
			EndIf;
			ProcessOutputStagesList(CurPoint.RoutePoint, CurStages);
		Else
			ProcessOutputStagesList(CurPoint.RoutePoint, CurStages);
		EndIf;
		
	EndDo;
	
	For Each CurPoint In Point.PointsPredecessors Do
		
		IndexOf = OutputStagesList.Find(CurPoint.RoutePoint);
		If IndexOf = Undefined Then 
			IndexOf = OutputStagesList.Find(Point);
			If IndexOf <> Undefined Then 
				OutputStagesList.Delete(IndexOf);
			EndIf;
		EndIf;
		
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// ПРОЦЕДУРЫ И ФУНКЦИИ, ВЫЗЫВАЕМЫЕ ИЗ ОБРАБОТЧИКОВ

// Функция определяет положение этапа на графике по оси Х
// 
Function DefineNewPositionInLevels(StageRow, FilledXLevels, Preference = Undefined)
	
	If NOT Preference = Undefined AND FilledXLevels[Preference] = Undefined Then
		Result = Preference;
	Else
		Result = 0;
		
		While NOT FilledXLevels[Result] = Undefined Do
			Result = Result + 1;
		EndDo;
		
	EndIf;
	FilledXLevels.Insert(Result, True);
	Return Result;
	
EndFunction

// Процедура рассчитывает положение этапа на графике по оси Х
// 
Procedure CalculateLevelX(StageRow, Stages)
	
	If NOT StageRow.LevelX = Undefined Then
		Return;
	EndIf;
	
	StageRow.PointsPredecessors.Columns.Add("PredecessorStageRow");
	If StageRow.PointsPredecessors.Count() Then
		MaxLevel = 0;
		For Each PredecessorRow In StageRow.PointsPredecessors Do
			
			PredecessorRow.PredecessorStageRow = Stages.Find(PredecessorRow.RoutePoint, "Stage");
			CalculateLevelX(PredecessorRow.PredecessorStageRow, Stages);
			MaxLevel = Max(MaxLevel, PredecessorRow.PredecessorStageRow.LevelX);
			
		EndDo;
		StageRow.LevelX = MaxLevel + 1;
	Else
		StageRow.LevelX = 0;
	EndIf;
	
EndProcedure

// Процедура рассчитывает положение этапа на графике по оси Х
// 
Procedure CalculateLevelY(StageRow, Stages)
	
	If NOT StageRow.LevelL = Undefined Then
		Return;
	EndIf;
	
	StageRow.PointsPredecessors.Columns.Add("PredecessorStageRow");
	If StageRow.PointsPredecessors.Count() Then
		MaxLevel = 0;
		For Each PredecessorRow In StageRow.PointsPredecessors Do
			
			PredecessorRow.PredecessorStageRow = Stages.Find(PredecessorRow.ID, "ID");
			CalculateLevelY(PredecessorRow.PredecessorStageRow, Stages);
			MaxLevel = Max(MaxLevel, PredecessorRow.PredecessorStageRow.LevelL);
			
		EndDo;
		StageRow.LevelL = MaxLevel + 1;
	Else
		StageRow.LevelL = 0;
	EndIf;
	
EndProcedure

// Функция возвращает таблицу этапов по шаблону процесса, 
// с дополнительными промежуточными данными
//
// Функция возвращает таблицу этапов по шаблону процесса, 
// с дополнительными промежуточными данными
//
Function GetStagesTable(RouteModel, Levels)
	
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	ProcessesPoints.Ref AS Stage,
	|	ProcessesPoints.PointsPredecessors.(
	|		RoutePoint
	|	),
	|	1 AS Counter,
	|	""00000000-0000-0000-0000-000000000000"" AS ID
	|FROM
	|	Catalog.fmRoutesPoints AS ProcessesPoints
	|WHERE
	|	ProcessesPoints.Owner = &RouteModel
	|	AND NOT ProcessesPoints.DeletionMark";
	
	Query.SetParameter("RouteModel", RouteModel);
	Query.SetParameter("OutputStagesList", OutputStagesList);
	Query.SetParameter("RouteDocument", RouteDocument);
	Stages = Query.Execute().Unload();
	
	For Each StageRow In Stages Do
		StageRow.ID = String(New UUID());
	EndDo;
	
	For Each StageRow In Stages Do
		
		StageRow.PointsPredecessors.Columns.Add("ID");
		ArrayForDeletion   = New Array();
		For Each PredecessorPoint In StageRow.PointsPredecessors Do
			FoundRows = Stages.FindRows(New Structure("Stage", PredecessorPoint.RoutePoint));
			If FoundRows.Count() > 0 Then
				ArrayForDeletion.Add(PredecessorPoint);
			EndIf;
		EndDo;
		
		For Each PredecessorPoint In ArrayForDeletion Do
			FoundRows = Stages.FindRows(New Structure("Stage", PredecessorPoint.RoutePoint));
			For Each StageRowForAdding In FoundRows Do
				NewLine = StageRow.PointsPredecessors.Add();
				NewLine.RoutePoint = StageRowForAdding.Stage;
				NewLine.ID            = StageRowForAdding.ID;
			EndDo;
		EndDo;
		
		For Each PredecessorPoint In ArrayForDeletion Do
			StageRow.PointsPredecessors.Delete(PredecessorPoint);
		EndDo;
		
	EndDo;
	
	Stages.Columns.Add("LevelL");
	Stages.Columns.Add("PredecessorsCount");
	
	For Each StageRow In Stages Do
		CalculateLevelY(StageRow, Stages);
		StageRow.PredecessorsCount = StageRow.PointsPredecessors.Count();
	EndDo;
	
	Stages.Sort("LevelL, PredecessorsCount");
	
	Stages.Columns.Add("LevelX");
	
	Levels = New Structure("X, Y", New Map, New Map);
	LevelL = 0;
	LevelRows = Stages.FindRows(New Structure("LevelL", LevelL));
	While LevelRows.Count() Do
		StructureY = New Structure("IndentY, FilledXLevels", 0, New Map);
		Levels.Y.Insert(LevelL, StructureY);
		LevelX = -1;
		For Each StageRow In LevelRows Do
			
			StageRow.PointsPredecessors.Columns.Add("IndentX", New TypeDescription("Number"));
			StageRow.PointsPredecessors.Columns.Add("IndentY", New TypeDescription("Number"));
			If StageRow.PointsPredecessors.Count() = 0 Then
				LevelX = LevelX + 1;
			Else
				
				If StageRow.PointsPredecessors.Count() = 1 Then
					Preference =StageRow.PointsPredecessors[0].PredecessorStageRow.LevelX;
				Else
					Preference = Undefined;
				EndIf;
				
				LevelX = DefineNewPositionInLevels(StageRow, StructureY.FilledXLevels, Preference);
				
				For Each PredecessorRow In StageRow.PointsPredecessors Do
					
					StructureY.IndentY = 0;
					
					If NOT StageRow.LevelL = PredecessorRow.PredecessorStageRow.LevelL + 1 Then
						StructureX = Levels.X[PredecessorRow.PredecessorStageRow.LevelX];
						StructureX.IndentX = 0;
						PredecessorRow.IndentX = 0;
					EndIf;
					
					PredecessorRow.IndentY = 0;
				EndDo;
				
			EndIf;
			
			StructureX = Levels.X[LevelX];
			If StructureX = Undefined Then
				StructureX = New Structure("IndentX", 0);
				Levels.X.Insert(LevelX, StructureX);
			EndIf;
			
			StageRow.LevelX = LevelX;
			
		EndDo;
		
		LevelL = LevelL + 1;
		LevelRows = Stages.FindRows(New Structure("LevelL", LevelL));
	EndDo;
	
	Return Stages;
	
EndFunction

// Процедура выводит диаграмму этапов в поле табличного документа
//
Procedure OutputStagesDiagram(Stages, Levels, SpreadsheetDocumentField)
	
	SpreadsheetDocument = New SpreadsheetDocument();
	
	StageLeft = IndentWidth;
	For Each StructureX In Levels.X Do
		
		If StructureX.Key Then
			StageLeft = StageLeft + Max(StructureX.Value.IndentX + 1, 2) * IndentWidth + ItemWidth;
		EndIf;
		
		StructureX.Value.Insert("StageLeft", StageLeft);
		
	EndDo;
	
	StageTop = IndentHeight;
	For Each StructureY In Levels.Y Do
		
		If StructureY.Key Then
			StageTop = StageTop + Max(Levels.Y[StructureY.Key - 1].IndentY + 1, 1) * IndentHeight + ItemHeight;
		EndIf;
		
		StructureY.Value.Insert("StageTop", StageTop);
		
	EndDo;
	
	For Each StructureX In Levels.X Do
		
		LevelRows = Stages.FindRows(New Structure("LevelX", StructureX.Key));
		
		For Each StageRow In LevelRows Do
			
			DrawTies(SpreadsheetDocument, StageRow, Levels);
			
		EndDo;
		
	EndDo;
	
	IncreasingDuration = 0;
	For Each StructureX In Levels.X Do
		
		LevelRows = Stages.FindRows(New Structure("LevelX", StructureX.Key));
		
		For Each StageRow In LevelRows Do
			
			DrawStage(SpreadsheetDocument, StageRow, Levels);
		EndDo;
		
	EndDo;
	
	SpreadsheetDocumentField.Clear();
	SpreadsheetDocumentField.Put(SpreadsheetDocument);
	
EndProcedure

// Процедура рисует этап на поле табличного документа
//
Procedure DrawStage(SpreadsheetDocument, StageRow, Levels)
	
	Details = StageRow.Stage;
	lcStage = StageRow.Stage;
	
	lcPointStage	= Undefined;
	lcResponsibles		= New Array();
	lcStateDate		= Undefined;
	lcComment		= Undefined;
	lcDepartments		= New Array();
	lcStatePointDescription = "";
	
	If OutputStagesList.Find(lcStage) <> Undefined Then
		
		Query = New Query;
		Query.Text = 
		"SELECT ALLOWED
		|	RouteStatesSliceLast.PointState,
		|	RouteStatesSliceLast.Responsible,
		|	RouteStatesSliceLast.Period AS StateDate,
		|	RouteStatesSliceLast.Comment,
		|	RouteStatesSliceLast.Department
		|FROM
		|	InformationRegister.fmRouteStates.SliceLast(
		|			&Period,
		|			Document = &RouteDocument
		|				AND AgreementRoute = &RouteModel
		|				AND RoutePoint = &RoutePoint AND Version = &Version
		|				AND NOT RoutePoint.DeletionMark) AS RouteStatesSliceLast
		|
		|ORDER BY
		|	StateDate DESC";
		
		Query.SetParameter("RouteDocument", RouteDocument);
		Query.SetParameter("RouteModel", RouteModel);
		Query.SetParameter("Version", Version);
		Query.SetParameter("RoutePoint", lcStage);
		Query.SetParameter("Period", Period);
		
		Selection = Query.Execute().Unload();
		If Selection.Count() > 0 Then
			lcPointStage	= Selection[0].PointState;
			lcStateDate		= Selection[0].StateDate;
			lcComment		= Selection[0].Comment;
			lcStatePointDescription = lcPointStage.Description;
			lcResponsibles = Selection.UnloadColumn("Responsible");
			lcDepartments = Selection.UnloadColumn("Department");
		EndIf;
		If Selection.Count() > 1 Then 
			lcPointStage = Catalogs.RoutePointsStates.EmptyRef();
		EndIf;
	EndIf;
	
	//Состояние этапа
	StateDetail = New Structure();  
	StateDetail.Insert("StageDetail");
	StateDetail.Insert("RouteDocument", RouteDocument);
	StateDetail.Insert("RouteModel"  , RouteModel);
	StateDetail.Insert("RoutePoint"   , lcStage);
	StateDetail.Insert("Period"          , lcStateDate);
	StateDetail.Insert("Comment"     , lcComment);
	StateDetail.Insert("Departments"   , lcDepartments);
	
	//Верхний прямоугольник название этапа	
	If lcPointStage = Undefined OR NOT lcPointStage.StageCompleted = 0 Then
		FontBold = True;
		LineThickness = 1;
	Else
		FontBold = False;
		LineThickness = 3;
	EndIf;
	
	StageTop = Levels.Y[StageRow.LevelL].StageTop;
	StageLeft = Levels.X[StageRow.LevelX].StageLeft;
	
	Picture = SpreadsheetDocument.Drawings.Add(SpreadsheetDocumentDrawingType.Rectangle);
	Picture.Left = StageLeft;
	Picture.Top = StageTop;
	Picture.Width = ItemWidth;
	Picture.Height = ItemHeight;
	
	Picture.Line = New Line(SpreadsheetDocumentDrawingLineType.Solid, LineThickness);
	
	TextLineHeight = 4;
	
	Picture = DrawText(SpreadsheetDocument, lcStage.Description, StateDetail, StageLeft, StageTop, ItemWidth, TextLineHeight * 2);
	Picture.Font = New Font(Picture.Font,,,FontBold);
	
	Picture = DrawText(SpreadsheetDocument, lcStatePointDescription, StateDetail, StageLeft, StageTop, ItemWidth, TextLineHeight * 1);
	Picture.Font = New Font(Picture.Font,,,FontBold);
	
	BackColor = Undefined;
	If lcPointStage <> Undefined Then
		If lcPointStage.ColorType = "Absolute" Then
			BackColor = New Color(lcPointStage.Red, lcPointStage.Green, lcPointStage.Blue);
		Else
			BackColor = lcPointStage.ColorStorage.Get();
		EndIf;
	EndIf;
	If BackColor <> Undefined Then
		Picture.BackColor = BackColor;
	EndIf;
	
	//Ответственный
	TextResponsibles = "";
	For Each Responsible In lcResponsibles Do
		TextResponsibles = TextResponsibles + TrimAll(Responsible) + ", ";
	EndDo;
	TextResponsibles = Left(TextResponsibles, StrLen(TextResponsibles) - 2);
	Picture = DrawText(SpreadsheetDocument, TextResponsibles, StateDetail, StageLeft, StageTop, ItemWidth, TextLineHeight);
	Picture.Font = New Font(Picture.Font,,,FontBold);
	Picture.TextPlacement = SpreadsheetDocumentTextPlacementType.Cut;
	If BackColor <> Undefined Then
		Picture.BackColor = BackColor;
	EndIf;
	
	//Дата согласования
	Picture = DrawText(SpreadsheetDocument, lcStateDate, StateDetail, StageLeft, StageTop, ItemWidth, TextLineHeight);
	Picture.Font = New Font(Picture.Font,,,FontBold);
	If BackColor <> Undefined Then
		Picture.BackColor = BackColor;
	EndIf;
	
	//Комментарий
	Picture = DrawText(SpreadsheetDocument, lcComment, StateDetail,  StageLeft, StageTop, ItemWidth, TextLineHeight * 3);
	Picture.Font = New Font(Picture.Font,,,FontBold);
	If BackColor <> Undefined Then
		Picture.BackColor = BackColor;
	EndIf;
	
EndProcedure

// Процедура рисует связи этапа на поле табличного документа
//
Procedure DrawTies(SpreadsheetDocument, StageRow, Levels)
	
	StageTop = Levels.Y[StageRow.LevelL].StageTop;
	
	StageLeft = Levels.X[StageRow.LevelX].StageLeft;
	
	For Each PredecessorRow In StageRow.PointsPredecessors Do
		
		PredecessorStageRow = PredecessorRow.PredecessorStageRow;
		
		PredecessorTop = Levels.Y[PredecessorStageRow.LevelL].StageTop;
		PredecessorLeft = Levels.X[PredecessorStageRow.LevelX].StageLeft;
		
		Details = New Structure("Stage, PredecessorStage", StageRow.Stage, PredecessorRow.RoutePoint);
		Details.Insert("TransitionDetail");
		Flag = ?(PredecessorStageRow.LevelX > StageRow.LevelX, -1, 1);
		If PredecessorStageRow.LevelL + 1 = StageRow.LevelL Then
			LineLeft   = PredecessorLeft + ItemWidth/2;
			LineTop   = PredecessorTop + ItemHeight;
			
			DrawLine(SpreadsheetDocument, Details, LineLeft, LineTop, 0, (StageTop - LineTop) - IndentBeforeArrow);
			If PredecessorStageRow.LevelX = StageRow.LevelX Then
				DrawLine(SpreadsheetDocument, Details, LineLeft, LineTop, 0, 0);
			Else
				DrawLine(SpreadsheetDocument, Details, LineLeft, LineTop, StageLeft - LineLeft + ItemWidth *2/4, 0);
			EndIf;
			
			DrawLine(SpreadsheetDocument, Details, LineLeft, LineTop, 0, StageTop - LineTop);
			DrawArrow(SpreadsheetDocument, Details, LineLeft, LineTop);
			
		Else
			
			LineLeft   = PredecessorLeft + ItemWidth / 4 * 2;
			LineTop   = PredecessorTop + ItemHeight;
			
			DrawLine(SpreadsheetDocument, Details, LineLeft, LineTop, 0, StageTop - LineTop - IndentBeforeArrow);
			
			If PredecessorStageRow.LevelX = StageRow.LevelX Then
				DrawLine(SpreadsheetDocument, Details, LineLeft, LineTop, -ItemWidth/2, 0);
			Else
				DrawLine(SpreadsheetDocument, Details, LineLeft, LineTop,StageLeft-LineLeft +ItemWidth * 2/4, 0);
			EndIf;
			
			DrawLine(SpreadsheetDocument, Details, LineLeft, LineTop, 0, StageTop-LineTop);
			DrawArrow(SpreadsheetDocument, Details, LineLeft, LineTop);
			
			
		EndIf;
	EndDo;
	
EndProcedure

// Функция выводит рисунок типа "текст" в табличный документ 
//
Function DrawText(SpreadsheetDocument, Text, Details, Left, Top, Width, Height)
	
	Picture = SpreadsheetDocument.Drawings.Add(SpreadsheetDocumentDrawingType.Text);
	
	Picture.Left   = Left;
	Picture.Top   = Top;
	Picture.Width = Width;
	Picture.Height = Height;
	
	Picture.Details = Details;
	
	If WebClient <> Undefined AND WebClient AND TypeOf(Details) = Type("Structure") Then 
		
		DetailsList.Add(Details);
		Picture.Details = DetailsList.Count() - 1;
		
	EndIf;
	
	If Height = 1 Then 
		Picture.TextPlacement = SpreadsheetDocumentTextPlacementType.Cut;
	EndIf;
	Picture.Text = Text;
	
	Top = Top + Height;
	
	Return Picture;
	
EndFunction // ()

// Функция выводит рисунок типа "линия" в табличный документ
//
Procedure DrawLine(SpreadsheetDocument, Details, LineLeft, LineTop, LineWidth, LineHeight);
	
	Line = SpreadsheetDocument.Drawings.Add(SpreadsheetDocumentDrawingType.Line);
	Line.Left   = LineLeft;
	Line.Top   = LineTop;
	Line.Width = LineWidth;
	Line.Height = LineHeight;
	
	Line.Details = Details;
	Line.Line = New Line(SpreadsheetDocumentDrawingLineType.Solid, 1);
	
	LineLeft = LineLeft + LineWidth;
	LineTop = LineTop + LineHeight;
	
EndProcedure

// Функция выводит рисунок из линий, в виде изгиба, в табличный документ
//
// Функция выводит рисунок из линий, в виде стрелки, в табличный документ
//
Procedure DrawArrow(SpreadsheetDocument, Details, LineLeft, LineTop)
	
	Line = SpreadsheetDocument.Drawings.Add(SpreadsheetDocumentDrawingType.Line);
	Line.Left   = LineLeft - 1.5;
	Line.Top   = LineTop - 1.5;
	Line.Width = 1.5;
	Line.Height = 1.5;
	
	Line.Details = Details;
	Line.Line = New Line(SpreadsheetDocumentDrawingLineType.Solid, 1);
	
	Line = SpreadsheetDocument.Drawings.Add(SpreadsheetDocumentDrawingType.Line);
	Line.Left   = LineLeft + 1.5;
	Line.Top   = LineTop - 1.5;
	Line.Width = -1.5;
	Line.Height =  1.5;
	
	Line.Details = Details;
	Line.Line = New Line(SpreadsheetDocumentDrawingLineType.Solid, 1);
	
EndProcedure

ItemWidth   = 40;
ItemHeight   = 32;
IndentWidth = 4;
IndentHeight = 10;
IndentBeforeArrow = 5;

DetailsList = New ValueList();
WebClient = False;



