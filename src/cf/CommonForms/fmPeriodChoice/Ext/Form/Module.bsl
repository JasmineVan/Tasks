
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	Parameters.Property("Value", ChosenPeriod);
	If NOT ValueIsFilled(ChosenPeriod) Then
		ChosenPeriod = BegOfMonth(CurrentSessionDate());
	EndIf;
	
	If NOT Parameters.Property("RequestPeriodChoiceModeFromOwner", RequestPeriodChoiceModeFromOwner) Then
		RequestPeriodChoiceModeFromOwner = False;
	EndIf;
	
	SetPeriodChoiceMode(ThisForm, Parameters.PeriodChoiceMode);
	
	ChosenPeriodButtonBackColor = New Color(235, 231, 205);
	ButtonBackColor = StyleColors.ButtonBackColor;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	RefreshRepresentation();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventsHandlers

&AtClient
Procedure ChosenPeriodOnChange(Item)
	
	YearChanged = True;
	MarkedPeriod = Undefined;
	SetChosenPeriod(Year(ChosenPeriod), Month(ChosenPeriod));
	
EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure CommandMonth01(Command)
	SetChosenPeriod(Year(ChosenPeriod), 1);
	MarkedPeriod = ChosenPeriod;
EndProcedure

&AtClient
Procedure CommandMonth02(Command)
	SetChosenPeriod(Year(ChosenPeriod), 2);
	MarkedPeriod = ChosenPeriod;
EndProcedure

&AtClient
Procedure CommandMonth03(Command)
	SetChosenPeriod(Year(ChosenPeriod), 3);
	MarkedPeriod = ChosenPeriod;
EndProcedure

&AtClient
Procedure CommandMonth04(Command)
	SetChosenPeriod(Year(ChosenPeriod), 4);
	MarkedPeriod = ChosenPeriod;
EndProcedure

&AtClient
Procedure CommandMonth05(Command)
	SetChosenPeriod(Year(ChosenPeriod), 5);
	MarkedPeriod = ChosenPeriod;
EndProcedure

&AtClient
Procedure CommandMonth06(Command)
	SetChosenPeriod(Year(ChosenPeriod), 6);
	MarkedPeriod = ChosenPeriod;
EndProcedure

&AtClient
Procedure CommandMonth07(Command)
	SetChosenPeriod(Year(ChosenPeriod), 7);
	MarkedPeriod = ChosenPeriod;
EndProcedure

&AtClient
Procedure CommandMonth08(Command)
	SetChosenPeriod(Year(ChosenPeriod), 8);
	MarkedPeriod = ChosenPeriod;
EndProcedure

&AtClient
Procedure CommandMonth09(Command)
	SetChosenPeriod(Year(ChosenPeriod), 9);
	MarkedPeriod = ChosenPeriod;
EndProcedure

&AtClient
Procedure CommandMonth10(Command)
	SetChosenPeriod(Year(ChosenPeriod), 10);
	MarkedPeriod = ChosenPeriod;
EndProcedure

&AtClient
Procedure CommandMonth11(Command)
	SetChosenPeriod(Year(ChosenPeriod), 11);
	MarkedPeriod = ChosenPeriod;
EndProcedure

&AtClient
Procedure CommandMonth12(Command)
	SetChosenPeriod(Year(ChosenPeriod), 12);
	MarkedPeriod = ChosenPeriod;
EndProcedure

&AtClient
Procedure CommandQuarter1(Command)
	SetChosenPeriod(Year(ChosenPeriod), 1);
	MarkedPeriod = ChosenPeriod;
EndProcedure

&AtClient
Procedure CommandQuarter2(Command)
	SetChosenPeriod(Year(ChosenPeriod), 4);
	MarkedPeriod = ChosenPeriod;
EndProcedure

&AtClient
Procedure CommandQuarter3(Command)
	SetChosenPeriod(Year(ChosenPeriod), 7);
	MarkedPeriod = ChosenPeriod;
EndProcedure

&AtClient
Procedure CommandQuarter4(Command)
	SetChosenPeriod(Year(ChosenPeriod), 10);
	MarkedPeriod = ChosenPeriod;
EndProcedure

&AtClient
Procedure CommandHalfYear1(Command)
	SetChosenPeriod(Year(ChosenPeriod), 1);
	MarkedPeriod = ChosenPeriod;
EndProcedure

&AtClient
Procedure CommandHalfYear2(Command)
	SetChosenPeriod(Year(ChosenPeriod), 7);
	MarkedPeriod = ChosenPeriod;
EndProcedure

&AtClient
Procedure CommandChoose(Command)
	ExecuteChoice();
EndProcedure

&AtClient
Procedure CommandCancel(Command)
	Close();
EndProcedure

&AtClient
Procedure CommandDecreaseYear(Command)
	
	ChosenYear = Year(ChosenPeriod) - 1;
	MarkedPeriod = Undefined;
	SetChosenPeriod(ChosenYear, Month(ChosenPeriod));
	
EndProcedure

&AtClient
Procedure CommandIncreaseYear(Command)
	
	ChosenYear = Year(ChosenPeriod) + 1;
	MarkedPeriod = Undefined;
	SetChosenPeriod(ChosenYear, Month(ChosenPeriod));
	
EndProcedure

#EndRegion

#Region ServiceProceduresAdFunctions

&AtClient
Procedure CheckPeriodChoiceMode()
	
	If RequestPeriodChoiceModeFromOwner Then
		SetPeriodChoiceMode(ThisForm, FormOwner.PeriodChoiceMode(ChosenPeriod));
	EndIf;
	
EndProcedure
	
&AtClientAtServerNoContext
Procedure SetPeriodChoiceMode(Form, VAL ChoiceMode)
	
	If NOT ValueIsFilled(ChoiceMode) Then
		ChoiceMode = "Month";
	EndIf; 
	
	If Form.PeriodChoiceMode = Upper(ChoiceMode) Then
		Return;
	EndIf; 
	
	Form.PeriodChoiceMode = Upper(ChoiceMode);
	
	GroupMonthesVisible = False;
	GroupQuartersVisible = False;
	GroupHalfYearsVisible = False;
		
	If Form.PeriodChoiceMode = "MONTH" Then
		
		GroupMonthesVisible = True;
		Form.ChosenPeriod = BegOfMonth(Form.ChosenPeriod);
		
	ElsIf Form.PeriodChoiceMode = "QUARTER" Then
		
		GroupQuartersVisible = True;
		QuarterNumber = Int((Month(Form.ChosenPeriod) - 1) / 3 + 1);
		Form.ChosenPeriod = DATE(Year(Form.ChosenPeriod), (QuarterNumber - 1) * 3 + 1, 1);
		
	ElsIf Form.PeriodChoiceMode = "HALFYEAR" Then
		
		GroupHalfYearsVisible = True;
		Form.ChosenPeriod = DATE(Year(Form.ChosenPeriod), ?(Month(Form.ChosenPeriod) < 7, 1, 7), 1);
		
	EndIf;
	
	fmCommonUseClientServer.SetFormItemProperty(
		Form.Items,
		"GroupMonthes",
		"Visible",
		GroupMonthesVisible);
	
	fmCommonUseClientServer.SetFormItemProperty(
		Form.Items,
		"GroupQuarters",
		"Visible",
		GroupQuartersVisible);
		
	fmCommonUseClientServer.SetFormItemProperty(
		Form.Items,
		"GroupHalfYears",
		"Visible",
		GroupHalfYearsVisible);
		
EndProcedure

&AtClient
Procedure RefreshRepresentation()
	
	CheckPeriodChoiceMode();
	
	If PeriodChoiceMode = "MONTH" Then
		
		For MonthNumber = 1 To 12 Do
			
			MonthButton = Items["CommandMonth" + Format(MonthNumber, "ND=2; NLZ=")];
			If MonthNumber = Month(ChosenPeriod) Then
				
				If MonthButton.BackColor <> ChosenPeriodButtonBackColor Then
					MonthButton.BackColor = ChosenPeriodButtonBackColor;
				EndIf;
				ThisForm.CurrentItem = MonthButton;
				
			Else
				
				If MonthButton.BackColor <> ButtonBackColor Then
					MonthButton.BackColor = ButtonBackColor;
				EndIf;
				
			EndIf;
			
		EndDo;
		
		PeriodAsString = Format(ChosenPeriod, "L=en_US; DF='MMMM yyyy'")
		
	ElsIf PeriodChoiceMode = "QUARTER" Then
		
		MonthQuarter = (Month(ChosenPeriod) - 1) / 3 + 1;
		For QuarterNumber = 1 To 4 Do
			
			QuarterButton = Items["CommandQuarter" + Format(QuarterNumber, "ND=1")];
			If QuarterNumber = MonthQuarter Then
				
				If QuarterButton.BackColor <> ChosenPeriodButtonBackColor Then
					QuarterButton.BackColor = ChosenPeriodButtonBackColor;
				EndIf;
				
				ThisForm.CurrentItem = QuarterButton;
				
			Else
				
				If QuarterButton.BackColor <> ButtonBackColor Then
					QuarterButton.BackColor = ButtonBackColor;
				EndIf;
				
			EndIf;
			
		EndDo;
		
		PeriodAsString = Format(MonthQuarter, "ND=1") + " Quarter " + Format(ChosenPeriod,"DF=yyyy");
		
	Else
		
		If Month(ChosenPeriod) = 1 Then
			Items.CommandHalfYear1.BackColor = ChosenPeriodButtonBackColor;
			Items.CommandHalfYear2.BackColor = ButtonBackColor;
			PeriodAsString = "1 HalfYear " + Format(ChosenPeriod,"DF=yyyy");
		Else
			Items.CommandHalfYear1.BackColor = ButtonBackColor;
			Items.CommandHalfYear2.BackColor = ChosenPeriodButtonBackColor;
			PeriodAsString = "2 HalfYear " + Format(ChosenPeriod,"DF=yyyy");
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SetChosenPeriod(Year, Month)
	
	If MarkedPeriod = DATE(Year, Month, 1) AND NOT YearChanged Then
		ExecuteChoice();
	EndIf; 
	
	If Year < 1 Then
		Year = 1;
	EndIf; 
	
	YearChanged = False;
	ChosenPeriod = DATE(Year, Month, 1);
	
	RefreshRepresentation();
	
EndProcedure

&AtClient
Procedure ExecuteChoice()
	Close(ChosenPeriod);
	//rarus fm begin
	NotifyChoice(ChosenPeriod);
	//rarus fm end
EndProcedure

#EndRegion





