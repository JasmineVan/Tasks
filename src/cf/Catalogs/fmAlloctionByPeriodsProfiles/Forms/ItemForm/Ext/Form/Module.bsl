
#Region FormEventsHandlers

&AtClient
Procedure OnOpen(Cancel)
	CalculateSpecificWeight();
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, RecordParameters)
	If Object.Periods.Count()=0 Then
		CommonClientServer.MessageToUser(NStr("en='The periods are not specified.';ru='Не указаны периоды!'"), , "Object.Periods", , Cancel);
	EndIf;
EndProcedure

&AtClient
Procedure AfterWrite(RecordParameters)
	CalculateSpecificWeight();
EndProcedure

#EndRegion

#Region FormItemsEventsHandlers

&AtClient
Procedure PeriodsOnChange(Item)
	CalculateSpecificWeight();
EndProcedure

&AtClient
Procedure PeriodsOnStartEdit(Item, NewLine, Copy)
	If NewLine Then
		CurRow = Items.Periods.CurrentData;
		If Object.Periods.Count()>1 Then
			CurRow.PeriodNumber = Object.Periods[Object.Periods.Count()-2].PeriodNumber+1;
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region ProceduresAndFunctionsOfCommonUse

&AtClient
Procedure CalculateSpecificWeight()
	TotalFraction = Object.Periods.Total("Fraction");
	If TotalFraction=0 Then Return; EndIf;
	SpecificWeightsSum=0;
	For Each CurRow In Object.Periods Do
		CurRow.SpecificWeight = CurRow.Fraction/TotalFraction*100;
		SpecificWeightsSum=SpecificWeightsSum+CurRow.SpecificWeight;
		If CurRow.LineNumber=Object.Periods.Count() AND SpecificWeightsSum<>100 Then
			CurRow.SpecificWeight = CurRow.SpecificWeight + 100 - SpecificWeightsSum;
		EndIf;
	EndDo;
EndProcedure

#EndRegion
