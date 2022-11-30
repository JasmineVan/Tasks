///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

Procedure AllowObjectAttributeEditAfterWarning(ContinuationHandler) Export
	
	If ContinuationHandler <> Undefined Then
		ExecuteNotifyProcessing(ContinuationHandler, False);
	EndIf;
	
EndProcedure

Procedure AllowObjectAttributeEditAfterCheckRefs(Result, Parameters) Export
	
	If Result Then
		ObjectAttributesLockClient.SetAttributeEditEnabling(
			Parameters.Form, Parameters.LockedAttributes);
		
		ObjectAttributesLockClient.SetFormItemEnabled(Parameters.Form);
	EndIf;
	
	If Parameters.ContinuationHandler <> Undefined Then
		ExecuteNotifyProcessing(Parameters.ContinuationHandler, Result);
	EndIf;
	
EndProcedure

Procedure CheckObjectReferenceAfterValidationConfirm(Response, Parameters) Export
	
	If Response <> DialogReturnCode.Yes Then
		ExecuteNotifyProcessing(Parameters.ContinuationHandler, False);
		Return;
	EndIf;
		
	If Parameters.RefsArray.Count() = 0 Then
		ExecuteNotifyProcessing(Parameters.ContinuationHandler, True);
		Return;
	EndIf;
	
	If CommonServerCall.RefsToObjectFound(Parameters.RefsArray) Then
		
		If Parameters.RefsArray.Count() = 1 Then
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Элемент ""%1"" уже используется в других местах в программе.
				           |Не рекомендуется разрешать редактирование из-за риска рассогласования данных.'; 
				           |en = '%1 is used in other locations in the application.
				           |Editing this item might lead to data inconsistency.'; 
				           |pl = 'Element ""%1"" jest już używany w innych miejscach aplikacji.
				           |Nie zaleca się zezwalania na edycję ze względu na ryzyko niezgodności danych.';
				           |de = 'Element ""%1"" wird bereits an anderen Stellen in der Anwendung verwendet. 
				           |Es wird nicht empfohlen, die Bearbeitung aufgrund des Risikos von Datenverlagerungen zuzulassen.';
				           |ro = 'Elementul ""%1"" este deja utilizat în alte locuri din aplicație.
				           |Nu este recomandat să permiteți editarea din cauza riscului de discordanță a datelor.';
				           |tr = '""%1"" Öğesi, uygulamadaki diğer yerlerde zaten kullanılıyor. 
				           |Veri yanlış hizalama riskinden dolayı düzenlemeye izin verilmemesi önerilir.'; 
				           |es_ES = 'El artículo ""%1"" ya está utilizado en otras ubicaciones en la aplicación.
				           |No se recomienda permitir la edición debido al riesgo del desajuste de datos.'"),
				Parameters.RefsArray[0]);
		Else
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Выбранные элементы (%1) уже используются в других местах в программе.
				           |Не рекомендуется разрешать редактирование из-за риска рассогласования данных.'; 
				           |en = '%1selected items are used in other locations in the application.
				           |Editing these items might lead to data inconsistency.'; 
				           |pl = 'Wybrane elementy (%1) są już używane w innych miejscach aplikacji. 
				           |Nie zaleca się zezwalania na edycję ze względu na ryzyko niezgodności danych.';
				           |de = 'Ausgewählte Elemente (%1) werden bereits an anderen Stellen in der Anwendung verwendet. 
				           |Es wird nicht empfohlen, die Bearbeitung aufgrund des Risikos von Datenverlagerungen zuzulassen.';
				           |ro = 'Elementele selectate (%1) sunt deja utilizate în alte locuri din aplicație.
				           | Nu este recomandat să permiteți editarea din cauza riscului de discordanță a datelor.';
				           |tr = 'Seçilmiş öğeler (%1), uygulamadaki diğer yerlerde zaten kullanılıyor. 
				           |nVeri yanlış hizalama riskinden dolayı düzenlemeye izin verilmemesi önerilir.'; 
				           |es_ES = 'Artículos seleccionados (%1) ya se utilizan en otras ubicaciones en la aplicación.
				           |No se recomienda permitir la edición debido al riesgo del desajuste de datos.'"),
				Parameters.RefsArray.Count());
		EndIf;
		
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Yes, NStr("ru = 'Разрешить редактирование'; en = 'Allow edit'; pl = 'Udostępnić edycję';de = 'Bearbeitung aktivieren';ro = 'Permite editarea';tr = 'Düzenlemeyi etkinleştir'; es_ES = 'Activar la edición'"));
		Buttons.Add(DialogReturnCode.No, NStr("ru = 'Отмена'; en = 'Cancel'; pl = 'Anuluj';de = 'Abbrechen';ro = 'Revocare';tr = 'İptal'; es_ES = 'Cancelar'"));
		ShowQueryBox(
			New NotifyDescription(
				"CheckObjectRefsAfterEditConfirmation", ThisObject, Parameters),
			MessageText, Buttons, , DialogReturnCode.No, Parameters.DialogTitle);
	Else
		If Parameters.RefsArray.Count() = 1 Then
			ShowUserNotification(NStr("ru = 'Редактирование реквизитов разрешено'; en = 'Attribute edit allowed'; pl = 'Edycja atrybutów jest dozwolona';de = 'Attributbearbeitung ist erlaubt';ro = 'Editarea atributelor este permisă';tr = 'Özellik düzenlemeye izin verilir'; es_ES = 'Edición del atributo está permitida'"),
				GetURL(Parameters.RefsArray[0]), Parameters.RefsArray[0]);
		Else
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Разрешено редактирование реквизитов объектов (%1)'; en = 'Attribute edit allowed for %1 objects'; pl = 'Edytowanie atrybutów obiektu jest dozwolone (%1)';de = 'Bearbeiten von Objektattributen ist erlaubt (%1)';ro = 'Editarea atributelor obiectelor este permisă (%1)';tr = 'Nesne özelliklerinin düzenlenmesine izin verilir (%1)'; es_ES = 'Edición de los atributos del objeto está permitida (%1)'"),
				Parameters.RefsArray.Count());
			
			ShowUserNotification(NStr("ru = 'Редактирование реквизитов разрешено'; en = 'Attribute edit allowed'; pl = 'Edycja atrybutów jest dozwolona';de = 'Attributbearbeitung ist erlaubt';ro = 'Editarea atributelor este permisă';tr = 'Özellik düzenlemeye izin verilir'; es_ES = 'Edición del atributo está permitida'"),,
				MessageText);
		EndIf;
		ExecuteNotifyProcessing(Parameters.ContinuationHandler, True);
	EndIf;
	
EndProcedure

Procedure CheckObjectRefsAfterEditConfirmation(Response, Parameters) Export
	
	ExecuteNotifyProcessing(Parameters.ContinuationHandler, Response = DialogReturnCode.Yes);
	
EndProcedure

#EndRegion
