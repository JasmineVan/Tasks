///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If ValueIsFilled(Owner) Then
		AdditionalValuesOwner = Common.ObjectAttributeValue(Owner,
			"AdditionalValuesOwner");
		
		If ValueIsFilled(AdditionalValuesOwner) Then
			ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Дополнительные значения для свойства ""%1"", созданного
				           |по образцу свойства ""%2"" нужно создавать для свойства-образца.'; 
				           |en = 'Additional values for the ""%1"" property created
				           |by sample of the ""%2"" property are to be created for the sample property.'; 
				           |pl = 'Dodatkowe wartości właściwości ""%1"" utworzonej według
				           |wzoru właściwości ""%2"" należy tworzyć dla wzorcowej właściwości.';
				           |de = 'Zusätzliche Werte für die Eigenschaft ""%1"", die auf dem
				           |Modell der Eigenschaft ""%2"" erstellt wurde, müssen für die Mustereigenschaft erstellt werden.';
				           |ro = 'Valorile suplimentare pentru proprietatea ""%1"" creată
				           |după modelul proprietății ""%2"" trebuie create pentru proprietatea-model.';
				           |tr = 'Örnek özelliği için%2 "
" özellik kalıbı kullanılarak oluşturulan ""%1"" özelliği için ek değerler oluşturulmalıdır.'; 
				           |es_ES = 'Valores adicionales para la propiedad ""%1"" creada
				           | en el modelo de la propiedad ""%2"" tienen que crearse para la propiedad de modelo.'"),
				Owner,
				AdditionalValuesOwner);
			
			If IsNew() Then
				Raise ErrorDescription;
			Else
				Common.MessageToUser(ErrorDescription);
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region Internal

Procedure OnReadPresentationsAtServer() Export
	LocalizationServer.OnReadPresentationsAtServer(ThisObject);
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Niedozwolone wezwanie obiektu na kliencie.';de = 'Unzulässiger Objektaufruf auf dem Client.';ro = 'Apel inadmisibil al obiectului pe client.';tr = 'İstemcide kabul edilmeyen nesne çağrısı.'; es_ES = 'Llamada no disponible del objeto en el cliente.'");
#EndIf