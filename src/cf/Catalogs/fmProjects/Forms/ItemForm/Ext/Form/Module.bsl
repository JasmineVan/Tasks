
#Region FormEventsHandler

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemNameForPlacement", "GroupAdditionalAttributes");
	// en script begin
	//PropertyManagement.OnCreateAtServer(ЭтаФорма, ДополнительныеПараметры);
	// en script end
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
