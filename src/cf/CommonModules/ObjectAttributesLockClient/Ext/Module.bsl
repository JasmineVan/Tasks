///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Allows editing of locked form items linked to the specified attributes.
//
// Parameters:
//  Form - ManagedForm - form, in which it is required to allow to edit form items of the specified 
//                 attributes.
//
//  FollowUpHandler - Undefined - no actions after the procedure execution.
//                       - NotifyDescription - notification that is called after the procedure execution.
//                         A Boolean parameter is passed to the notification handler:
//                           True - no references are found or the user decided to allow editing.
//                           False - no visible attributes are locked, or references are found and 
//                                    the user decided to cancel the operation.
//
Procedure AllowObjectAttributeEdit(Val Form, ContinuationHandler = Undefined) Export
	
	LockedAttributes = Attributes(Form);
	
	If LockedAttributes.Count() = 0 Then
		ShowAllVisibleAttributesUnlockedWarning(
			New NotifyDescription("AllowObjectAttributeEditAfterWarning",
				ObjectAttributesLockInternalClient, ContinuationHandler));
		Return;
	EndIf;
	
	AttributesSynonyms = New Array;
	
	For Each AttributeDetails In Form.AttributeEditProhibitionParameters Do
		If LockedAttributes.Find(AttributeDetails.AttributeName) <> Undefined Then
			AttributesSynonyms.Add(AttributeDetails.Presentation);
		EndIf;
	EndDo;
	
	RefsArray = New Array;
	RefsArray.Add(Form.Object.Ref);
	
	Parameters = New Structure;
	Parameters.Insert("Form", Form);
	Parameters.Insert("LockedAttributes", LockedAttributes);
	Parameters.Insert("ContinuationHandler", ContinuationHandler);
	
	CheckObjectRefs(
		New NotifyDescription("AllowObjectAttributeEditAfterCheckRefs",
			ObjectAttributesLockInternalClient, Parameters),
		RefsArray,
		AttributesSynonyms);
	
EndProcedure

// Sets the availability of form items associated with the specified attributes whose editing is 
// allowed. If an attribute array is passed, attributes allowed for editing will be supplemented 
// first.
//   If unlocking of form items linked to the specified attributes
// is released for all the attributes, the button that allows editing becomes unavailable.
//
// Parameters:
//  Form - ManagedForm - form, in which it is required to allow to edit form items of the specified 
//                 attributes.
//  
//  Attributes - Array - values:
//                  * String - names of attributes whose editing shall be allowed.
//                    It is used when the AllowObjectAttributeEdit function is not used.
//               - Undefined - a set of attributes available for editing is not changed. The form 
//                 items linked to the attributes whose editing is allowed, become available.
//                 
//
Procedure SetFormItemEnabled(Val Form, Val Attributes = Undefined) Export
	
	SetAttributeEditEnabling(Form, Attributes);
	
	For Each DescriptionOfAttributeToLock In Form.AttributeEditProhibitionParameters Do
		If DescriptionOfAttributeToLock.EditingAllowed Then
			For Each FormItemToLock In DescriptionOfAttributeToLock.ItemsToLock Do
				FormItem = Form.Items.Find(FormItemToLock.Value);
				If FormItem <> Undefined Then
					If TypeOf(FormItem) = Type("FormField")
					   AND FormItem.Type <> FormFieldType.LabelField
					 Or TypeOf(FormItem) = Type("FormTable") Then
						FormItem.ReadOnly = False;
					Else
						FormItem.Enabled = True;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
EndProcedure

// Prompts a user to confirm that they want to allow attribute editing and checks if there are any 
// references to the object in the infobase.
//
// Parameters:
//  FollowUpHandler - NotifyDescription - notification called after the check.
//                         A Boolean parameter is passed to the notification handler:
//                           True - no references are found or the user decided to allow editing.
//                           False - no visible attributes are locked, or references are found and 
//                                    the user decided to cancel the operation.
//  RefArrray - Array - values:
//                           * Reference - searched references in various objects.
//  AttributeSynonyms - Array - values:
//                           * String - attribute synonyms displayed to a user.
//
Procedure CheckObjectRefs(Val ContinuationHandler, Val RefsArray, Val AttributesSynonyms) Export
	
	DialogTitle = NStr("ru = 'Разрешение редактирования реквизитов'; en = 'Allow attribute edit'; pl = 'Zezwalaj na edycję atrybutów';de = 'Bearbeitung von Attributen zulassen';ro = 'Permiteți editarea atributelor';tr = 'Düzenleme özelliklerine izin ver'; es_ES = 'Permitir la edición de atributos'");
	
	AttributesPresentation = "";
	For Each AttributeSynonym In AttributesSynonyms Do
		AttributesPresentation = AttributesPresentation + AttributeSynonym + "," + Chars.LF;
	EndDo;
	AttributesPresentation = Left(AttributesPresentation, StrLen(AttributesPresentation) - 2);
	
	If AttributesSynonyms.Count() > 1 Then
		QuestionText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Для того чтобы не допустить рассогласования данных в программе,
			           |следующие реквизиты не доступны для редактирования:
			           |%1.
			           |
			           |Перед тем, как разрешить их редактирование, рекомендуется оценить последствия,
			           |проверив все места использования этого элемента в программе.
			           |Поиск мест использования может занять длительное время.'; 
			           |en = 'To prevent data inconsistency, the following attributes are locked for editing:
			           |%1.
			           |
			           |It is recommended that you consider possible consequences before you allow editing.
			           |Please view the locations where the attributes are used.
			           |Generating the list of locations might take a while.'; 
			           |pl = 'W celu niedopuszczenia zakłóceń danych w programie,
			           |następujące atrybuty nie są dostępne do edycji:
			           |%1.
			           |
			           |Przed pozwoleniem ich edycji zalecane jest ocenić konsekwencje,
			           |sprawdzić wszystkie miejsca stosowania tego elementu w programie.
			           |Wyszukanie miejsc stosowania może zająć dużo czasu.';
			           |de = 'Um Fehlausrichtungen von Daten in der Anwendung zu vermeiden, 
			           |können die Attribute nicht wie folgt bearbeitet werden: 
			           |%1.
			           |
			           | Vor dem Zulassen der Bearbeitung wird empfohlen, die Konsequenzen
			           |zu bewerten, indem Sie alle Stellen dieser Elementverwendung in der Anwendung überprüfen.
			           |Das Suchen von Einsatzorten kann lange dauern.';
			           |ro = 'Pentru a evita discordanța datelor în aplicație,
			           |următoarele atribute nu sunt accesibile pentru editare:
			           |%1.
			           |
			           |Înainte de a permite editarea lor, se recomandă evaluarea consecințelor
			           |prin verificarea tuturor locurilor de utilizare a acestui element din aplicație.
			           |Căutarea locurilor de utilizare poate dura mult timp.';
			           |tr = 'Uygulamadaki verilerin yanlış hizalanmasını önlemek için, 
			           |özellikler aşağıdaki gibi düzenlenemez:
			           |%1. 
			           |
			           |Düzenlemelerine  izin vermeden önce, uygulamada bu öğenin kullanımının tüm yerlerini  kontrol ederek sonuçların 
			           |değerlendirilmesi önerilir. 
			           |Kullanım yerlerinin aranması uzun zaman alabilir.'; 
			           |es_ES = 'Para evitar el desajuste de datos en la aplicación,
			           |los atributos no se editan de la siguiente manera: 
			           |%1.
			           |
			           |Antes de permitir su edición, se recomienda evaluar las consecuencias
			           |revisando todos las ubicaciones del uso de este artículo en la aplicación.
			           |Búsqueda de ubicaciones de uso puede llevar mucho tiempo. '"),
			AttributesPresentation);
	Else
		If RefsArray.Count() = 1 Then
			QuestionText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Для того чтобы не допустить рассогласования данных в программе,
				           |реквизит %1 не доступен для редактирования.
				           |
				           |Перед тем, как разрешить его редактирование, рекомендуется оценить последствия,
				           |проверив все места использования ""%2"" в программе.
				           |Поиск мест использования может занять длительное время.'; 
				           |en = 'To prevent data inconsistency, attribute %1 is locked for editing.
				           |
				           |It is recommended that you consider possible consequences before you allow editing .
				           |Please view the locations where the %2 is used.
				           |Generating the list of locations might take a while.'; 
				           |pl = 'Aby uniknąć niedopasowania danych w aplikacji,
				           |atrybut %1 nie jest edytowalny.
				           |
				           |Przed zezwoleniem na jego edycję, zaleca się ocenić konsekwencje,
				           |sprawdzając wszystkie miejsca użycia elementu ""%2"" w aplikacji.
				           |Wyszukiwanie miejsc użycia może zająć dużo czasu.';
				           |de = 'Um Fehlausrichtung von Daten in der Anwendung zu vermeiden, kann 
				           |das %1 Attribut nicht bearbeitet werden. 
				           |
				           |Vor dem Zulassen seiner Bearbeitung wird empfohlen, die Konsequenzen zu bewerten
				           |, indem alle Stellen der ""%2"" Artikelverwendung in der Anwendung überprüft werden. 
				           |Das Suchen von Einsatzorten kann lange dauern.';
				           |ro = 'Pentru a evita discordanța datelor în aplicație,
				           |atributul %1 nu este accesibil pentru editare.
				           |
				           |Înainte de a permite editarea lui, se recomandă evaluarea consecințelor
				           |prin verificarea tuturor locurilor de utilizare a ""%2"" din aplicație.
				           |Căutarea locurilor de utilizare poate dura mult timp.';
				           |tr = 'Uygulamadaki verilerin yanlış hizalanmasını önlemek için, 
				           |özellik %1 düzenlenemez. 
				           |
				           |Düzenlemesine  izin vermeden önce, uygulamadaki "
" öğesinin tüm kullanım yerlerini  kontrol ederek sonuçların 
				           |değerlendirilmesi önerilir. %2Kullanım yerlerinin aranması uzun zaman alabilir.'; 
				           |es_ES = 'Para evitar el desajuste de datos en la aplicación,
				           | el %1 atributo no es editable.
				           |
				           |Antes de permitir su edición, se recomienda evaluar las consecuencias
				           |revisando todas las ubicaciones del uso del artículo ""%2"" en la aplicación.
				           |Búsqueda de ubicaciones de uso puede llevar mucho tiempo.'"),
				AttributesPresentation, RefsArray[0]);
		Else
			QuestionText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Для того чтобы не допустить рассогласования данных в программе,
				           |реквизит %1 не доступен для редактирования.
				           |
				           |Перед тем, как разрешить его редактирование, рекомендуется оценить последствия,
				           |проверив все места использования выбранных элементов (%2) в программе.
				           |Поиск мест использования может занять длительное время.'; 
				           |en = 'To prevent data inconsistency, attribute %1 is locked for editing.
				           |
				           |It is recommended that you consider possible consequences before you allow editing .
				           |Please view the locations where selected items (%2) are used.
				           |Generating the list of locations might take a while.'; 
				           |pl = 'W celu niedopuszczenia zakłóceń danych w programie,
				           |atrybut %1 nie jest dostępny do edycji.
				           |
				           |Przed pozwoleniem jego edycji, zalecane jest ocenić konsekwencje,
				           |sprawdzić wszystkie miejsca stosowania wybranych elementów (%2) w programie.
				           |Wyszukanie miejsc stosowania może zająć dużo czasu.';
				           |de = 'Um Fehlausrichtung von Daten in der Anwendung zu vermeiden, kann 
				           |das %1 Attribut nicht bearbeitet werden. 
				           |
				           |Vor dem Zulassen seiner Bearbeitung wird empfohlen, die Konsequenzen zu bewerten
				           |, indem alle Stellen der ""%2"" Artikelverwendung in der Anwendung überprüft werden. 
				           |Das Suchen von Einsatzorten kann lange dauern.';
				           |ro = 'Pentru a evita discordanța datelor în aplicație,
				           |atributul %1 nu este accesibil pentru editare.
				           |
				           |Înainte de a permite editarea lui, se recomandă evaluarea consecințelor
				           |prin verificarea tuturor locurilor de utilizare a elementelor selectate ""%2"" din aplicație.
				           |Căutarea locurilor de utilizare poate dura mult timp.';
				           |tr = 'Uygulamadaki verilerin yanlış hizalanmasını önlemek için, 
				           |özellik %1 düzenlenemez. 
				           |
				           |Düzenlemesine  izin vermeden önce, uygulamadaki "
" öğesinin tüm kullanım yerlerini  kontrol ederek sonuçların 
				           |değerlendirilmesi önerilir. %2Kullanım yerlerinin aranması uzun zaman alabilir.'; 
				           |es_ES = 'Para evitar el desajuste de datos en la aplicación,
				           | el atributo %1 no es editable.
				           |
				           |Antes de permitir su edición, se recomienda evaluar las consecuencias
				           |revisando todas las ubicaciones del uso del artículo (%2) en la aplicación.
				           |Búsqueda de ubicaciones de uso puede llevar mucho tiempo.'"),
				AttributesPresentation, RefsArray.Count());
		EndIf;
	EndIf;
	
	Parameters = New Structure;
	Parameters.Insert("RefsArray", RefsArray);
	Parameters.Insert("AttributesSynonyms", AttributesSynonyms);
	Parameters.Insert("DialogTitle", DialogTitle);
	Parameters.Insert("ContinuationHandler", ContinuationHandler);
	
	Buttons = New ValueList;
	Buttons.Add(DialogReturnCode.Yes, NStr("ru = 'Проверить и разрешить'; en = 'View and allow'; pl = 'Sprawdź i kontynuuj';de = 'Überprüfen und erlauben';ro = 'Verificați și permiteți';tr = 'Kontrol et ve izin ver'; es_ES = 'Revisar y permitir'"));
	Buttons.Add(DialogReturnCode.No, NStr("ru = 'Отмена'; en = 'Cancel'; pl = 'Anuluj';de = 'Abbrechen';ro = 'Revocare';tr = 'İptal'; es_ES = 'Cancelar'"));
	
	ShowQueryBox(
		New NotifyDescription("CheckObjectReferenceAfterValidationConfirm",
			ObjectAttributesLockInternalClient, Parameters),
		QuestionText, Buttons, , DialogReturnCode.Yes, DialogTitle);
	
EndProcedure

// Allows editing the attributes whose descriptions are given in the form.
//  Used when form item availability is changed explicitly
// without using the SetFormItemEnabled function.
//
// Parameters:
//  Form - Managed Form - form, in which you need to allow editing of object attributes.
//  
//  Attributes - Array - values.
//                  * String - attribute names to mark as allowed for editing.
//  
//  EditAllowed - Boolean - flag that shows whether you want to allow attribute editing.
//                            The value will not be set to True if you are not authorized to edit the attribute.
//                          - Undefined - do not change the attribute editing status.
// 
//  RightToEdit - Boolean - flag used to override availability of unlocking attributes. It is 
//                        determined automatically using the AccessRight method.
//                      - Undefined - do not change the RightToEdit property.
// 
Procedure SetAttributeEditEnabling(Val Form, Val Attributes,
			Val EditingAllowed = True, Val RightToEdit = Undefined) Export
	
	If TypeOf(Attributes) = Type("Array") Then
		
		For Each Attribute In Attributes Do
			AttributeDetails = Form.AttributeEditProhibitionParameters.FindRows(New Structure("AttributeName", Attribute))[0];
			If TypeOf(RightToEdit) = Type("Boolean") Then
				AttributeDetails.EditRight = RightToEdit;
			EndIf;
			If TypeOf(EditingAllowed) = Type("Boolean") Then
				AttributeDetails.EditingAllowed = AttributeDetails.EditRight AND EditingAllowed;
			EndIf;
		EndDo;
	EndIf;
	
	// Updating the availability of AllowObjectAttributeEdit command.
	AllAttributesUnlocked = True;
	
	For each DescriptionOfAttributeToLock In Form.AttributeEditProhibitionParameters Do
		If DescriptionOfAttributeToLock.EditRight
		AND NOT DescriptionOfAttributeToLock.EditingAllowed Then
			AllAttributesUnlocked = False;
			Break;
		EndIf;
	EndDo;
	
	If AllAttributesUnlocked Then
		Form.Items.AllowObjectAttributeEdit.Enabled = False;
	EndIf;
	
EndProcedure

// Returns an array of attribute names specified in the AttributesLockParameters form property based 
// on the attribute names specified in the object manager module excluding the attributes with 
// RightToEdit = False.
//
// Parameters:
//  Form - ManagedForm - object form with a required standard Object attribute.
//  OnlyBlocked - Boolean - you can set this parameter to False for debug purposes, to get a list of 
//                  all visible attributes that can be unlocked.
//  OnlyVisible - Boolean - set this parameter to False to get and unlock all object attributes.
//
// Returns:
//  Array - values:
//   * String - attribute names.
//
Function Attributes(Val Form, Val OnlyBlocked = True, OnlyVisible = True) Export
	
	Attributes = New Array;
	
	For Each DescriptionOfAttributeToLock In Form.AttributeEditProhibitionParameters Do
		
		If DescriptionOfAttributeToLock.EditRight
		   AND (    DescriptionOfAttributeToLock.EditingAllowed = False
		      OR OnlyBlocked = False) Then
			
			AddAttribute = False;
			For Each FormItemToLock In DescriptionOfAttributeToLock.ItemsToLock Do
				FormItem = Form.Items.Find(FormItemToLock.Value);
				If FormItem <> Undefined AND (FormItem.Visible Or NOT OnlyVisible) Then
					AddAttribute = True;
					Break;
				EndIf;
			EndDo;
			If AddAttribute Then
				Attributes.Add(DescriptionOfAttributeToLock.AttributeName);
			EndIf;
		EndIf;
	EndDo;
	
	Return Attributes;
	
EndFunction

// Displays a warning that all visible attributes are unlocked.
// The warning is required when the unlock command remains enabled because of invisible locked 
// attributes.
//
// Parameters:
//  FollowUpHandler - Undefined - no actions after the procedure execution.
//                       - NotifyDescription - notification that is called after the procedure execution.
//
Procedure ShowAllVisibleAttributesUnlockedWarning(ContinuationHandler = Undefined) Export
	
	ShowMessageBox(ContinuationHandler,
		NStr("ru = 'Редактирование всех видимых реквизитов объекта уже разрешено.'; en = 'Editing visible attributes of the object is already allowed.'; pl = 'Edytowanie wszystkich widocznych atrybutów obiektów jest dozwolone.';de = 'Bearbeiten aller sichtbaren Objektattribute erlaubt.';ro = 'Modificarea tuturor atributelor vizibile ale obiectului este permisă deja.';tr = 'İzin verilen tüm görünen nesne niteliklerini düzenleme.'; es_ES = 'Edición de todos los atributos del objeto visibles permitida.'"));
	
EndProcedure

#EndRegion
