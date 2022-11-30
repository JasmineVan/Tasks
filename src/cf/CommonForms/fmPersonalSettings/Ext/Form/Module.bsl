
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	MainProject =							fmCommonUseServer.GetDefaultValue("MainProject");
	MainBalanceUnit =						fmCommonUseServer.GetDefaultValue("MainBalanceUnit");
	MainScenario =							fmCommonUseServer.GetDefaultValue("MainScenario");
	MainDepartment =						fmCommonUseServer.GetDefaultValue("MainDepartment");
	ReadOnly = NOT AccessRight("SaveUserData", Metadata);
	
	
	// СтандартныеПодсистемы.Пользователи
	AuthorizedUser = Users.AuthorizedUser();
	// Конец СтандартныеПодсистемы.Пользователи
	
EndProcedure


&AtClient
Procedure BeforeClose(Cancel, Shutdown, WarningText, StandardProcessing)
	
	If Shutdown AND Modified Then
		Cancel = True;
		Return;
	EndIf;

	If Modified Then
		Cancel = True;
		Notification = New NotifyDescription("QueryBeforeCloseEnd", ThisObject);
		ShowQueryBox(Notification, NStr("en='Data has been changed. Save changes?';ru='Данные были изменены. Сохранить изменения?'"), QuestionDialogMode.YesNoCancel);
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure SaveAndClose(Command)
	
	WriteData();
	
	Close();
	
EndProcedure

&AtClient
Procedure Write(Command)
	
	WriteData();
	
EndProcedure

#EndRegion

#Region ProceduresAndFunctionsOfCommonUse

&AtServer
Procedure SaveSettingsServer()
	
	fmCommonUseServer.SetDefaultValue("MainProject",              MainProject);
	fmCommonUseServer.SetDefaultValue("MainScenario",            MainScenario);
	fmCommonUseServer.SetDefaultValue("MainBalanceUnit",                 MainBalanceUnit);
	fmCommonUseServer.SetDefaultValue("MainDepartment",       MainDepartment);
	RefreshReusableValues();
	
	Modified = False;
EndProcedure

&AtClient
Procedure WriteData()
	
	SaveSettingsServer();
	
EndProcedure

&AtClient
Procedure QueryBeforeCloseEnd(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		SaveAndClose(Undefined);
	ElsIf Result = DialogReturnCode.No Then
		Modified = False;
		Close();
	EndIf;
	
EndProcedure

&AtServer
Function GetCurrentDate()
	Return CurrentSessionDate();
EndFunction
#EndRegion

#Region FormItemsEventsHandlers

&AtClient
Procedure MainBalanceUnitOnChange(Item)
	fmBudgeting.BalanceUnitDepartmentCompatible(MainBalanceUnit, MainDepartment, GetCurrentDate(), "Department");
EndProcedure

&AtClient
Procedure MainDepartmentOnChange(Item)
	fmBudgeting.BalanceUnitDepartmentCompatible(MainBalanceUnit, MainDepartment, GetCurrentDate(), "BalanceUnit");
EndProcedure

#EndRegion




