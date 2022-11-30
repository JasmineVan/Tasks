
////////////////////////////////////////////////////////////////////////////////
// СЛУЖЕБНЫЕ ПРОЦЕДУРЫ И ФУНКЦИИ

&AtServer
// Процедура обработчик "ПодготовитьФормуНаСервере" 
//
Procedure AssembleFormAtServer()
	
	If Object.ColorType = NStr("en='Absolute';ru='Абсолютный'") Then
		StageColor  = New Color(Object.Red, Object.Green, Object.Blue);
	Else
		StageColor = Object.Ref.ColorStorage.Get();
	EndIf;
	
	FormManagement(ThisForm);
	
EndProcedure

&AtClientAtServerNoContext
// Процедура обработчик "УправлениеФормой" 
//
Procedure FormManagement(Form)
	
	Items = Form.Items;
	Object   = Form.Object;
	
	Items.ReturnPoint.Visible = (Object.StageCompleted = 0);
	Items.TransitionPoint.Visible = (Object.StageCompleted = 1);
	
EndProcedure

&AtServerNoContext
// Функция обработчик "ПолучитьЗначениеРеквизита" 
//
Function GetAttributeValue(Ref, AttributeName)
	Return Ref[AttributeName];
EndFunction


////////////////////////////////////////////////////////////////////////////////
// ОБРАБОТЧИКИ СОБЫТИЙ ФОРМЫ

&AtServer
// Процедура обработчик "ПриСозданииНаСервере" 
//
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	AssembleFormAtServer();
EndProcedure

&AtServer
// Процедура обработчик "ПередЗаписьюНаСервере" 
//
Procedure BeforeWriteAtServer(Cancel, CurrentObject, RecordParameters)
	
	CurrentObject.ColorType = TrimAll(StageColor.Type);
	CurrentObject.Green  = StageColor.G;
	CurrentObject.Red  = StageColor.R;
	CurrentObject.Blue    = StageColor.B;
	If CurrentObject.ColorType <> NStr("en='Absolute';ru='Абсолютный'") Then 
		CurrentObject.ColorStorage = New ValueStorage(StageColor);
	EndIf;
	CurrentObject.Color = TrimAll(StageColor);
	
EndProcedure

&AtServer
// Процедура обработчик "ОбработкаПроверкиЗаполненияНаСервере" 
//
Procedure FillCheckProcessingAtServer(Cancel, CheckingAttributes)
	
	// Запрещено устанавливать в произвольной точке состояние утверждения.
	If Object.State = Catalogs.fmDocumentState.Approved Then
		CommonClientServer.MessageToUser(NStr("en='It is forbidden to set the approval status for the document at the route point!';ru='Запрещено устанавливать в точке маршрута состояние утверждения для документа!'"), , , , Cancel);
	EndIf;
	
EndProcedure


////////////////////////////////////////////////////////////////////////////////
// ОБРАБОТЧИКИ СОБЫТИЙ ПОЛЕЙ ФОРМЫ

&AtClient
// Процедура обработчик события "ЭтапВыполненПриИзменении" 
//
Procedure StageCompletedOnChange(Item)
	FormManagement(ThisForm);
EndProcedure

&AtClient
// Процедура обработчик события "ЭтапВыполнен1ПриИзменении" 
//
Procedure StageCompleted1OnChange(Item)
	FormManagement(ThisForm);
EndProcedure

&AtClient
// Процедура обработчик события "ЭтапВыполнен2ПриИзменении" 
//
Procedure StageCompleted2OnChange(Item)
	FormManagement(ThisForm);
EndProcedure

&AtClient
// Процедура обработчик события "ТочкаВозвратаНачалоВыбора" 
//
Procedure ReturnPointStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	// Выбирать точку возврата можно только при указанной точке маршрута.
	If NOT ValueIsFilled(Object.Owner) Then
		CommonClientServer.MessageToUser(NStr("en='First, it is necessary to specify a route point for this status.';ru='Сначала необходимо указать точку маршрута для данного состояния!'"));
		Return;
	EndIf;
	
	PointsList = New ValueList();
	PointsList.LoadValues(fmProcessManagement.GettingPreviousStagesList(Object.Owner, True));
	
	FilterStructure = New Structure();
	FilterStructure.Insert("Ref", PointsList);
	OpenForm("Catalog.fmRoutesPoints.ChoiceForm", New Structure("Filter", FilterStructure), Item);
	
EndProcedure

&AtClient
Procedure TransitionPointStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	// Выбирать точку возврата можно только при указанной точке маршрута.
	If NOT ValueIsFilled(Object.Owner) Then
		CommonClientServer.MessageToUser(NStr("en='First, it is necessary to specify a route point for this status.';ru='Сначала необходимо указать точку маршрута для данного состояния!'"));
		Return;
	EndIf;
	
	FilterStructure = New Structure();
	FilterStructure.Insert("Owner", GetAttributeValue(Object.Owner, "Owner"));
	OpenForm("Catalog.fmRoutesPoints.ChoiceForm", New Structure("Filter", FilterStructure), Item);
	
EndProcedure

