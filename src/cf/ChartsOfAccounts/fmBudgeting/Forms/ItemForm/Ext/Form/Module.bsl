
#Region FormItemsEventsHandlers

&AtClient
// Обработчик события ВалютныйПриИзменении
//
Procedure CurrencyOnChange(Item)
	
	Items.ExtDimensionTypesCurrency.Visible = Object.Currency;
	
EndProcedure // ВалютныйПриИзменении()

&AtClient
// Обработчик события ВидыСубконтоПриНачалеРедактирования
//
Procedure ExtDimensionTypesOnStartEdit(Item, NewLine, Copy)
	
	If NewLine Then
		Item.CurrentData.Sum       = True;
		Item.CurrentData.Currency       = True;
	EndIf;
	
EndProcedure // ВидыСубконтоПриНачалеРедактирования()

#EndRegion

#Region FormEventsHandlers

&AtServer
// Обработчик события ПриСозданииНаСервере
//
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Items.ExtDimensionTypesCurrency.Visible       = Object.Currency;	
	
EndProcedure // ПриСозданииНаСервере()

#EndRegion
