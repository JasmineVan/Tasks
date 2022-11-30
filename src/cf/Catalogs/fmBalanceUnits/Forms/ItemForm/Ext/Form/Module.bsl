
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemNameForPlacement", "GroupAdditionalAttributes");
	// en script begin
	//PropertyManagement.OnCreateAtServer(ЭтаФорма, ДополнительныеПараметры);
	// en script end
	StateBalanceUnit.Parameters.SetParameterValue("BalanceUnit", Object.Ref);
	
	//заполним таблицу организаций
	For Counter = 1 To 5 Do
		If ValueIsFilled(Object["Company"+Counter]) Then
			NewR = Companies.Add();
			NewR.Company = Object["Company"+Counter];
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure AfterWrite(RecordParameters)
	StateBalanceUnit.Parameters.SetParameterValue("BalanceUnit", Object.Ref);
	Items.StateBalanceUnit.Refresh();
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	// Подсистема "Свойства"
	// en script begin
	//Если PropertyManagementClient.ProcessNofifications(ЭтаФорма, ИмяСобытия, Параметр) Тогда
	//	ОбновитьЭлементыДополнительныхРеквизитов();
	//КонецЕсли;
	// en script end
EndProcedure


&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, RecordParameters)
	// Обработчик подсистемы "Свойства"
	// en script begin
	//PropertyManagement.BeforeWriteAtServer(ЭтаФорма, ТекущийОбъект);
	// en script end
	
	Counter = 1;
	For Each String In Companies Do
		CurrentObject["Company"+Counter] = String.Company;
		Counter = Counter + 1;
	EndDo;
	
EndProcedure

#EndRegion

#Region ProceduresAndFunctionsOfCommonUse

&AtServer
Procedure RefreshAdditionalAttributesItems()
	// en script begin
	//PropertyManagement.UpdateAdditionalAttributeItems(ЭтаФорма, РеквизитФормыВЗначение("Объект"));
	// en script end
EndProcedure

#EndRegion

#Region FormItemsEventsHandlers

&AtClient
Procedure StateBalanceUnitBeforeChange(Item, Cancel)
	Cancel = True;
EndProcedure

&AtClient
Procedure CompaniesBeforeAdd(Item, Cancel, Copy, Parent, Group, Parameter)
	If ThisForm.Companies.Count() = 5 Then
		CommonClientServer.MessageToUser(NStr("en='You cannot enter more than 5 companies';ru='Более 5 организаций ввести нельзя'"), , , , Cancel);
	EndIf;
EndProcedure

#EndRegion

