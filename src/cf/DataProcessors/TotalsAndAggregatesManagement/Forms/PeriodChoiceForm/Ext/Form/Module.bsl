///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	PeriodForAccumulationRegisters = EndOfPeriod(AddMonth(CurrentSessionDate(), -1));
	PeriodForAccountingRegisters = EndOfPeriod(CurrentSessionDate());
	
	Items.PeriodForAccountingRegisters.Enabled  = Parameters.AccountingReg;
	Items.PeriodForAccumulationRegisters.Enabled = Parameters.AccumulationReg;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PeriodForAccumulationRegisterOnChange(Item)
	
	PeriodForAccumulationRegisters = EndOfPeriod(PeriodForAccumulationRegisters);
	
EndProcedure

&AtClient
Procedure PeriodForAccountingRegisterOnChange(Item)
	
	PeriodForAccountingRegisters = EndOfPeriod(PeriodForAccountingRegisters);
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure OK(Command)
	
	SelectionResult = New Structure("PeriodForAccumulationRegisters, PeriodForAccountingRegisters");
	FillPropertyValues(SelectionResult, ThisObject);
	
	NotifyChoice(SelectionResult);
	
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Function EndOfPeriod(Date)
	
	Return EndOfDay(EndOfMonth(Date));
	
EndFunction

#EndRegion
