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
	
	If NOT ValueIsFilled(Object.Ref)
	   AND Parameters.FillingValues.Property("Description") Then
		
		Object.Description = Parameters.FillingValues.Description;
	EndIf;
	
	If NOT Parameters.HideOwner Then
		Items.Owner.Visible = True;
	EndIf;
	
	If TypeOf(Parameters.ShowWeight) = Type("Boolean") Then
		ShowWeight = Parameters.ShowWeight;
	Else
		ShowWeight = Common.ObjectAttributeValue(Object.Owner, "AdditionalValuesWithWeight");
	EndIf;
	
	If ShowWeight = True Then
		Items.Weight.Visible = True;
		StandardSubsystemsServer.SetFormAssignmentKey(ThisObject, "ValuesWithWeight");
	Else
		Items.Weight.Visible = False;
		Object.Weight = 0;
		StandardSubsystemsServer.SetFormAssignmentKey(ThisObject, "ValuesWithoutWeight");
	EndIf;
	
	SetTitle();
	
	ItemsToLocalize = New Array;
	ItemsToLocalize.Add(Items.Description);
	LocalizationServer.OnCreateAtServer(ItemsToLocalize);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Change_ValueIsCharacterizedByWeightCoefficient"
	   AND Source = Object.Owner Then
		
		If Parameter = True Then
			Items.Weight.Visible = True;
		Else
			Items.Weight.Visible = False;
			Object.Weight = 0;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	LocalizationServer.BeforeWriteAtServer(CurrentObject);
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	EndIf;
	// End StandardSubsystems.AccessManagement
	
	SetTitle();
	LocalizationServer.OnReadAtServer(ThisObject, CurrentObject);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_ObjectPropertyValueHierarchy",
		New Structure("Ref", Object.Ref), Object.Ref);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.AccessManagement
	
	LocalizationServer.OnReadAtServer(ThisObject, CurrentObject);
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DescriptionOpen(Item, StandardProcessing)
	LocalizationClient.OnOpen(Object, Item, "Description", StandardProcessing);
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetTitle()
	
	If CurrentLanguage() = Metadata.DefaultLanguage Then
		AttributesValues = Common.ObjectAttributesValues(
			Object.Owner, "Title, ValueFormTitle");
	Else
		Attributes = New Array;
		Attributes.Add("Title");
		Attributes.Add("ValueFormTitle");
		AttributesValues = PropertyManagerInternal.LocalizedAttributesValues(Object.Owner, Attributes);
	EndIf;
	
	PropertyName = TrimAll(AttributesValues.ValueFormTitle);
	
	If NOT IsBlankString(PropertyName) Then
		If ValueIsFilled(Object.Ref) Then
			Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = '%1 (%2)'; en = '%1 (%2)'; pl = '%1 (%2)';de = '%1 (%2)';ro = '%1 (%2)';tr = '%1 (%2)'; es_ES = '%1 (%2)'"),
				Object.Description,
				PropertyName);
		Else
			Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = '%1 (Создание)'; en = '%1 (Create)'; pl = '%1 (Utworzenie)';de = ' %1 (Erstellung)';ro = '%1 (Creare)';tr = '%1 (oluşturma)'; es_ES = '%1 (Creación)'"), PropertyName);
		EndIf;
	Else
		PropertyName = String(AttributesValues.Title);
		
		If ValueIsFilled(Object.Ref) Then
			Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = '%1 (Значение свойства %2)'; en = '%1 (%2 property value)'; pl = '%1 (Znaczenie właściwości %2)';de = '%1 (Wert des Attributs %2)';ro = '%1 (Valoarea proprietății %2)';tr = '%1 (özniteliğin değeri %2)'; es_ES = '%1 (valor del atributo %2)'"),
				Object.Description,
				PropertyName);
		Else
			Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Значение свойства %1 (Создание)'; en = '%1 property value (Create)'; pl = 'Znaczenie właściwości %1 (Utwórz)';de = 'Wert des Attributs %1(Erstellung) ';ro = 'Valoarea proprietății %1 (Creare)';tr = 'Öznitelik değeri %1 (Oluşturma)'; es_ES = 'Valor del atributo %1 (Crear)'"), PropertyName);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion
