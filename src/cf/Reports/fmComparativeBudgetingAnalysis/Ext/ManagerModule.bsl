
#If Server OR ThickClientOrdinaryApplication OR ExternalConnection Then

#Region ProgramInterface
// Инициализирует набор параметров, задающих флаги выполнения дополнительных действий над сущностями, обрабатываемыми.
// в процессе формирования отчета.
//
// Возвращаемое значение:
//   Структура   - флаги, задающие необходимость дополнительных действий.
Function GetReportExecutionParameters() Export
	Return New Structure();
EndFunction
#EndRegion

#EndIf




