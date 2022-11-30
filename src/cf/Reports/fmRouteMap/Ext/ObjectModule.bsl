
////////////////////////////////////////////////////////////////////////////////
// ПЕРЕМЕННЫЕ МОДУДЛЯ

Var IndentWidth Export; // переменная - ширина отступа при оформлении карты маршрута
Var IndentHeight Export; // переменная - высота отступа при оформлении карты маршрута
Var IndentBeforeArrow Export; // переменная - отступ перед элементом "стрелка" при оформлении карты маршрута
Var HiddenStagesList Export; // переменная - массив последующих точек, не подлежащих выводу.

Var DetailsList Export; // СписокРасшифровок
Var WebClient Export; // ВебКлиент
Var StagesTS Export;

////////////////////////////////////////////////////////////////////////////////
// ЭКСПОРТИРУЕМЫЕ ПРОЦЕДУРЫ И ФУНКЦИИ

// Процедура формирует отчет
//
Procedure GenerateReport(SpreadsheetDocumentField) Export
	
	Var Levels; //локальная переменная процедуры - уровни элементов на карте маршрута
	
	If ItemHeight < 24 Then 
		ItemHeight = 24
	EndIf;
	Stages = GetStagesTable(RouteModel, Levels);
	OutputStagesDiagram(Stages, Levels, SpreadsheetDocumentField);
	Stages = Undefined;
	Levels = Undefined;
	
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
			
			PredecessorRow.PredecessorStageRow = Stages.Find(PredecessorRow.RoutePoint, "Stage");
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
	"SELECT
	|	ProcessesPoints.Ref AS Stage,
	|	ProcessesPoints.PointsPredecessors.(
	|		RoutePoint
	|	),
	|	1 AS Counter
	|FROM
	|	Catalog.fmRoutesPoints AS ProcessesPoints
	|WHERE
	|	ProcessesPoints.Owner = &RouteModel
	|	AND NOT ProcessesPoints.DeletionMark";
	Query.SetParameter("RouteModel", RouteModel);
	Stages = Query.Execute().Unload();
	
	StagesTS = Stages.UnloadColumn("Stage");
	
	Stages.Columns.Add("LevelL");
	Stages.Columns.Add("PredecessorsCount");
	
	For Each StageRow In Stages Do
		CalculateLevelY(StageRow, Stages);
		StageRow.PredecessorsCount = StageRow.PointsPredecessors.Count();
	EndDo;
	
	Stages.Sort("LevelL, PredecessorsCount");
	
	StagesTS = Stages.Copy();
	
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
	
	Template = GetTemplate("Template");
	SpreadsheetDocumentField.Put(SpreadsheetDocument);
	
EndProcedure

// Процедура рисует этап на поле табличного документа
//
Procedure DrawStage(SpreadsheetDocument, StageRow, Levels)
	
	StageTop = Levels.Y[StageRow.LevelL].StageTop;
	StageLeft = Levels.X[StageRow.LevelX].StageLeft;
	
	TextLineHeight = 4;
	
	//Расшифровка = СтрокаЭтапа.Этап;
	Details = New Structure("RoutePoint, Route", StageRow.Stage, RouteModel);
	
	Text = StageRow.Stage;
	Picture = DrawText(SpreadsheetDocument, Text, Details, StageLeft, StageTop, ItemWidth, TextLineHeight * 3);
	Picture.Font = New Font(Picture.Font,,,True);
	
	If ValueIsFilled(StageRow.Stage) Then 
		Picture.BackColor = New Color(230, 230, 255);
	EndIf;
	
	MiddleText = "" + StageRow.Stage.AccessTypeToRoutePoint;
	
	BottomText = MiddleText + Chars.LF + "";
	If StageRow.Stage.AccessTypeToRoutePoint = Enums.fmAccessTypeToRoutePoint.FixedDepartment Then
		BottomText = BottomText + TrimAll(StageRow.Stage.Department);
	ElsIf StageRow.Stage.AccessTypeToRoutePoint = Enums.fmAccessTypeToRoutePoint.DocumentDepartment Then
		BottomText = BottomText + NStr("en='Document department level:';ru='Уровень подразделения документа: '") + StageRow.Stage.DepartmentLevel;
	ElsIf StageRow.Stage.AccessTypeToRoutePoint = Enums.fmAccessTypeToRoutePoint.ManageType Then
		BottomText = BottomText + StageRow.Stage.ManageType;
	ElsIf StageRow.Stage.AccessTypeToRoutePoint = Enums.fmAccessTypeToRoutePoint.FixedUser Then
		BottomText = BottomText + TrimAll(StageRow.Stage.User);
	EndIf;
	
	Picture = DrawText(SpreadsheetDocument, BottomText, Details, StageLeft, StageTop, ItemWidth, TextLineHeight * 3);
	Picture.BottomBorder = True;
	
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
	
	Picture.BottomBorder = False;
	
	Picture.Details = Details;
	
	If WebClient <> Undefined AND WebClient AND TypeOf(Details) = Type("Structure") Then 
		
		DetailsList.Add(Details);
		Picture.Details = DetailsList.Count() - 1;
		
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
	
	//Линия.Расшифровка = Расшифровка;
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
	
	//Линия.Расшифровка = Расшифровка;
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
ItemHeight   = 24;
IndentWidth = 4;
IndentHeight = 10;
IndentBeforeArrow = 5;

DetailsList = New ValueList();
WebClient = False;
StagesTS = New ValueTable();


