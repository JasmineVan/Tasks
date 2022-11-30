
#If Server OR ThickClientOrdinaryApplication OR ExternalConnection Then

#Region ProgramInterface

Function DefaultDocumentTime() Export
	
	Return New Structure("Hours, Minutes", 20, 0);
	
EndFunction

#EndRegion

////////////////////////////////////////////////////////////////////////////////
// ПРОЦЕДУРЫ И ФУНКЦИИ ПЕЧАТИ

// Заполняет список команд печати.
// 
// Параметры:
//   КомандыПечати - ТаблицаЗначений - состав полей см. в функции УправлениеПечатью.СоздатьКоллекциюКомандПечати
//
Procedure AddPrintCommands(PrintCommands) Export

	// Бухгалтерская справка
	PrintCommand = PrintCommands.Add();
	PrintCommand.ID = "BudgetOperation";
	PrintCommand.Presentation = NStr("en='Budget transaction';ru='Бюджетная операция'");
	PrintCommand.Handler    = "PrintManagementAccClient.ExecutePrintCommand";
	
EndProcedure

Function BudgetOperationPrint(ObjectsArray, PintObjects) Export
	
	SetPrivilegedMode(True);
	
	SprDocument = New SpreadsheetDocument;
	
	// Зададим параметры макета по умолчанию
	SprDocument.HeaderSize = 0;
	SprDocument.FooterSize  = 0;
	SprDocument.FitToPage             = True;
	SprDocument.PageOrientation      = PageOrientation.Landscape;
	SprDocument.PrintParametersName     = "Print_Parameters_fmBudgetingOperation_BudgetOperation";
	
	// en script begin
	//ПечатьТорговыхДокументов.УстановитьМинимальныеПоляПечати(ТабДокумент);
	// en script end
	
	Template = PrintManagement.PrintFormTemplate("Document.fmBudgetingOperation.PF_MXL_BudgetOperation");
	
	Query = New Query();
	Query.SetParameter("ObjectsArray", ObjectsArray);
	Query.Text = 
	"SELECT
	|	fmBudgetingRecordsWithExtDimensions.LineNumber AS LineNumber,
	|	fmBudgetingRecordsWithExtDimensions.AccountDr AS AccountDr,
	|	fmBudgetingRecordsWithExtDimensions.ProjectDr AS ProjectDr,
	|	fmBudgetingRecordsWithExtDimensions.DepartmentDr AS DepartmentDr,
	|	fmBudgetingRecordsWithExtDimensions.ItemDr AS ItemDr,
	|	fmBudgetingRecordsWithExtDimensions.ExtDimensionDr1 AS ExtDimensionDr1,
	|	fmBudgetingRecordsWithExtDimensions.ExtDimensionDr2 AS ExtDimensionDr2,
	|	fmBudgetingRecordsWithExtDimensions.ExtDimensionDr3 AS ExtDimensionDr3,
	|	fmBudgetingRecordsWithExtDimensions.AccountCr AS AccountCr,
	|	fmBudgetingRecordsWithExtDimensions.ProjectCr AS ProjectCr,
	|	fmBudgetingRecordsWithExtDimensions.DepartmentCr AS DepartmentCr,
	|	fmBudgetingRecordsWithExtDimensions.ItemCr AS ItemCr,
	|	fmBudgetingRecordsWithExtDimensions.ExtDimensionCr1 AS ExtDimensionCr1,
	|	fmBudgetingRecordsWithExtDimensions.ExtDimensionCr2 AS ExtDimensionCr2,
	|	fmBudgetingRecordsWithExtDimensions.ExtDimensionCr3 AS ExtDimensionCr3,
	|	fmBudgetingRecordsWithExtDimensions.BalanceUnit AS BalanceUnit,
	|	fmBudgetingRecordsWithExtDimensions.Scenario AS Scenario,
	|	fmBudgetingRecordsWithExtDimensions.CurrencyDr AS CurrencyDr,
	|	fmBudgetingRecordsWithExtDimensions.CurrencyCr AS CurrencyCr,
	|	fmBudgetingRecordsWithExtDimensions.Amount AS Amount,
	|	fmBudgetingRecordsWithExtDimensions.CurrencyAmountDr AS CurrencyAmountDr,
	|	fmBudgetingRecordsWithExtDimensions.CurrencyAmountCr AS CurrencyAmountCr,
	|	fmBudgetingRecordsWithExtDimensions.Content AS Content,
	|	fmBudgetingRecordsWithExtDimensions.Recorder AS Recorder
	|INTO TTfmBudgeting
	|FROM
	|	AccountingRegister.fmBudgeting.RecordsWithExtDimensions(, , Recorder IN (&ObjectsArray), , ) AS fmBudgetingRecordsWithExtDimensions
	|
	|INDEX BY
	|	fmBudgetingRecordsWithExtDimensions.Recorder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	fmBudgetingOperation.Ref AS Ref,
	|	fmBudgetingOperation.Number AS Number,
	|	fmBudgetingOperation.Responsible AS Responsible,
	|	fmBudgetingOperation.DATE AS DATE,
	|	fmBudgetingOperation.Content AS OperationContent,
	|	TTfmBudgeting.LineNumber AS LineNumber,
	|	TTfmBudgeting.AccountDr AS AccountDr,
	|	TTfmBudgeting.ProjectDr AS ProjectDr,
	|	TTfmBudgeting.DepartmentDr AS DepartmentDr,
	|	TTfmBudgeting.ItemDr AS ItemDr,
	|	TTfmBudgeting.ExtDimensionDr1 AS ExtDimensionDr1,
	|	TTfmBudgeting.ExtDimensionDr2 AS ExtDimensionDr2,
	|	TTfmBudgeting.ExtDimensionDr3 AS ExtDimensionDr3,
	|	TTfmBudgeting.AccountCr AS AccountCr,
	|	TTfmBudgeting.ProjectCr AS ProjectCr,
	|	TTfmBudgeting.DepartmentCr AS DepartmentCr,
	|	TTfmBudgeting.ItemCr AS ItemCr,
	|	TTfmBudgeting.ExtDimensionCr1 AS ExtDimensionCr1,
	|	TTfmBudgeting.ExtDimensionCr2 AS ExtDimensionCr2,
	|	TTfmBudgeting.ExtDimensionCr3 AS ExtDimensionCr3,
	|	TTfmBudgeting.BalanceUnit AS BalanceUnit,
	|	TTfmBudgeting.Scenario AS Scenario,
	|	TTfmBudgeting.CurrencyDr AS CurrencyDr,
	|	TTfmBudgeting.CurrencyCr AS CurrencyCr,
	|	TTfmBudgeting.Amount AS Amount,
	|	TTfmBudgeting.CurrencyAmountDr AS CurrencyAmountDr,
	|	TTfmBudgeting.CurrencyAmountCr AS CurrencyAmountCr,
	|	TTfmBudgeting.Content AS Content
	|FROM
	|	Document.fmBudgetingOperation AS fmBudgetingOperation
	|		LEFT JOIN TTfmBudgeting AS TTfmBudgeting
	|		ON fmBudgetingOperation.Ref = TTfmBudgeting.Recorder
	|WHERE
	|	fmBudgetingOperation.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	fmBudgetingOperation.DATE,
	|	fmBudgetingOperation.Ref,
	|	LineNumber";
	
	Selection = Query.Execute().SELECT();
	
	FirstDocument = True;
	
	While Selection.NextByFieldValue("Ref") Do
		
		If NOT FirstDocument Then
			SprDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument = False;
		// Запомним номер строки, с которой начали выводить текущий документ.
		LineNumberStart = SprDocument.TableHeight + 1;
		
		// Получаем области макета для вывода в табличный документ.
		DocumentHeader   = Template.GetArea("Header");
		TableTitle = Template.GetArea("TableTitle");
		TableRow    = Template.GetArea("TableRow");
		TableFooter    = Template.GetArea("TableFooter");
		DocumentFooter  = Template.GetArea("Footer");
				
		// Выведем шапку документа.
		
		HeaderStructure = New Structure;
		HeaderStructure.Insert("BalanceUnit",    Selection.BalanceUnit);
		HeaderStructure.Insert("Scenario",    Selection.Scenario);
		// en script begin
		//СтруктураШапки.Вставить("НомерДокумента", ПрефиксацияОбъектовКлиентСервер.НомерНаПечать(Выборка.Номер, Истина, Ложь));
		HeaderStructure.Insert("DocumentNumber", Selection.Number);
		// en script end
		HeaderStructure.Insert("DocumentDate",  Format(Selection.DATE, "DLF=D"));
		HeaderStructure.Insert("Content",     Selection.OperationContent);
		
		DocumentHeader.Parameters.Fill(HeaderStructure);
		SprDocument.Output(DocumentHeader);
		
		// Выведем заголовок таблицы.
		SprDocument.Output(TableTitle);
		
		// Выведем строки документа.
		While Selection.Next() Do
			
			TableRow.Parameters.Fill(Selection);
			
			AnalyticsDr = ?(ValueIsFilled(Selection.ProjectDr), String(Selection.ProjectDr) + Chars.LF, "")
				+ ?(ValueIsFilled(Selection.DepartmentDr), String(Selection.DepartmentDr) + Chars.LF, "")
			    +?(ValueIsFilled(Selection.ItemDr), String(Selection.ItemDr) + Chars.LF, "")
				+ ?(ValueIsFilled(Selection.ExtDimensionDr1), String(Selection.ExtDimensionDr1) + Chars.LF, "")
				+ ?(ValueIsFilled(Selection.ExtDimensionDr2), String(Selection.ExtDimensionDr2) + Chars.LF, "")
				+ ?(ValueIsFilled(Selection.ExtDimensionDr3), String(Selection.ExtDimensionDr3), "");
			
			AnalyticsCr = ?(ValueIsFilled(Selection.ProjectCr), String(Selection.ProjectCr) + Chars.LF, "")
				+ ?(ValueIsFilled(Selection.DepartmentCr), String(Selection.DepartmentCr) + Chars.LF, "")
			    +?(ValueIsFilled(Selection.ItemCr), String(Selection.ItemCr) + Chars.LF, "")
				+ ?(ValueIsFilled(Selection.ExtDimensionCr1), String(Selection.ExtDimensionCr1) + Chars.LF, "")
				+ ?(ValueIsFilled(Selection.ExtDimensionCr2), String(Selection.ExtDimensionCr2) + Chars.LF, "")
				+ ?(ValueIsFilled(Selection.ExtDimensionCr3), String(Selection.ExtDimensionCr3), "");
				
			AnalyticsStructure = New Structure("AnalyticsDr,AnalyticsCr", AnalyticsDr, AnalyticsCr);
			TableRow.Parameters.Fill(AnalyticsStructure);
			
			// Проверим, помещается ли строка с подвалом.
			RowWithFooter = New Array;
			RowWithFooter.Add(TableRow);
			RowWithFooter.Add(TableFooter);
			RowWithFooter.Add(DocumentFooter);
			
			// en script begin
			//Если НЕ ОбщегоНазначенияБПВызовСервера.ПроверитьВыводТабличногоДокумента(ТабДокумент, СтрокаСПодвалом) Тогда
				
				// Выведем подвал таблицы.
				SprDocument.Output(TableFooter);
					
				// Выведем разрыв страницы.
				SprDocument.PutHorizontalPageBreak();

				// Выведем заголовок таблицы.
				SprDocument.Output(TableTitle);
				
			//КонецЕсли;
			// en script end
			
			SprDocument.Output(TableRow);
			
		EndDo;
		
		// Выведем подвал таблицы.
		SprDocument.Output(TableFooter);
		
		// Выведем подвал документа.
		SprDocument.Output(DocumentFooter);
		
		// В табличном документе зададим имя области, в которую был 
		// выведен объект. Нужно для возможности печати покомплектно.
		PrintManagement.SetDocumentPrintArea(SprDocument, 
			LineNumberStart, PintObjects, Selection.Ref);

	EndDo;

	Return SprDocument;

EndFunction

Procedure Print(ObjectsArray, PrintParameters, PrintedFormsCollection,
	PintObjects, OutputParameters) Export
	
	// Проверяем, нужно ли для макета ПлатежноеПоручение формировать табличный документ.
	If PrintManagement.MustPrintTemplate(PrintedFormsCollection, "BudgetOperation") Then
		
		// Формируем табличный документ и добавляем его в коллекцию печатных форм.
		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintedFormsCollection, "BudgetOperation", NStr("en='Budget transaction';ru='Бюджетная операция'"), 
			BudgetOperationPrint(ObjectsArray, PintObjects), , "Document.fmBudgetingOperation.PF_MXL_BudgetOperation");
	EndIf;
	
EndProcedure

#EndIf
