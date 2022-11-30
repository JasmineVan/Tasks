
#Region ProceduresAndFunctionsOfCommonUse

&AtServer
//Процедура, заполняющая реквизит справочника Подразделения "ИндивидуальныйЦвет" цветом из поля формы "ПолеЦвет", переведенным в запись XML
//
Procedure FillColorAtServer()
	Serializer = New XDTOSerializer(XDTOFactory);
	ObjectXDTO = Serializer.WriteXDTO(FieldColor);
	XMLRecord = New XMLWriter;
	XMLRecord.SetString();
	XDTOFactory.WriteXML(XMLRecord, ObjectXDTO);
	Object.Color = XMLRecord.Close();
EndProcedure

&AtServer
Procedure RefreshAdditionalAttributesItems()
	// en script begin
	//PropertyManagement.UpdateAdditionalAttributeItems(ЭтаФорма, РеквизитФормыВЗначение("Объект"));
	// en script end
EndProcedure

#EndRegion

#Region FormItemsEventsHandlers

&AtClient
//Обработчик события при изменении флага "Установить индивидуальный цвет оформления"
//
Procedure SetIndColorOnChange(Item)
	Items.FieldColor.ReadOnly = NOT Object.SetColor;
	FillColorAtServer();
EndProcedure

&AtClient
//Обработчик события при изменении поля формы "ПолеЦвет"
//
Procedure FieldColorOnChange(Item)
	FillColorAtServer();
EndProcedure 

&AtClient
Procedure DepartmentStateHistoryChoice(Item, SelectedRow, Field, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure ParentOpening(Item, StandardProcessing)
	StandardProcessing = False;
	FormParameters = New Structure;
	FormParameters.Insert("Key", Object.Parent);
	FormParameters.Insert("StructureVersion", Object.StructureVersion);
	OpenForm("Catalog.fmDepartments.ObjectForm", FormParameters, ThisForm);
EndProcedure

&AtClient
Procedure ParentStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	FormParameters = New Structure;
	FormParameters.Insert("Key", Object.Parent);
	FormParameters.Insert("StructureVersion", Object.StructureVersion);
	If UseDepartmentsVersions AND ValueIsFilled(Object.StructureVersion) Then
		OpenForm("Catalog.fmDepartments.Form.VersionChoiceForm", FormParameters, ThisForm);
	Else
		OpenForm("Catalog.fmDepartments.Form.ChoiceForm", FormParameters, ThisForm);
	EndIf;
EndProcedure

&AtClient
Procedure DepartmentStateHistoryBeforeRowChange(Item, Cancel)
	Cancel = True;
EndProcedure

#EndRegion

#Region FormEventsHandlers

&AtClient
Procedure AfterWrite(RecordParameters)
	Notify("DepartmentInfoChange", New Structure("Ref, Parent", Object.Ref, Object.Parent));
	DepartmentStateHistory.Parameters.SetParameterValue("Department", Object.Ref);
	Items.DepartmentStateHistory.Refresh();
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, RecordParameters)
	If Object.DeletionMark Then
		CommonClientServer.MessageToUser(NStr("en='This field can be set only for the department unmarked for deletion.';ru=""Поле 'Вид подразделения' может быть установлено только для непомеченного на удаление подразделения."""),,"DepartmentType",,Cancel);
	EndIf;
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	Items.FieldColor.ReadOnly = NOT Object.SetColor;
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	UseDepartmentsVersions = Constants.fmDepartmentsStructuresVersions.Get();
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemNameForPlacement", "GroupAdditionalAttributes");
	
	// en script begin
	//PropertyManagement.OnCreateAtServer(ЭтаФорма, ДополнительныеПараметры);
	// en script end
	
	If Parameters.Property("Description") Then
		Object.Description = Parameters.Description;
	EndIf;
	If Parameters.Property("DepartmentType") Then
		Object.DepartmentType = Parameters.DepartmentType;
	EndIf;
	If Parameters.Property("Responsible") Then
		Object.Responsible = Parameters.Responsible;
	EndIf;
	If Parameters.Property("BalanceUnit") Then
		Object.BalanceUnit = Parameters.BalanceUnit;
	EndIf;
	If Parameters.Property("StructureVersion") Then
		Object.StructureVersion = Parameters.StructureVersion;
	EndIf;
	If Parameters.Property("Parent")Then
		Object.Parent = Parameters.Parent;
	EndIf;
	DepartmentStateHistory.Parameters.SetParameterValue("Department", Object.Ref);
	If NOT Object.Color = "" Then
		XMLReader = New XMLReader;
		ObjectTypeXDTO	= XDTOFactory.Type("http://v8.1c.ru/8.1/data/ui","Color");
		XMLReader.SetString(Object.Color);
		ObjectXDTO	=	XDTOFactory.ReadXML(XMLReader, ObjectTypeXDTO);
		Serializer	=	New XDTOSerializer(XDTOFactory);
		FieldColor	=	Serializer.ReadXDTO(ObjectXDTO);
	Else
		FieldColor = New Color(0, 0, 0);
	EndIf;
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ChosenValue, ChoiceSource)
	Object.Parent = ChosenValue;
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




