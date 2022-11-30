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
	
	SetTitle();
	
	ItemsToLocalize = New Array;
	ItemsToLocalize.Add(Items.Description);
	LocalizationServer.OnCreateAtServer(ItemsToLocalize);
	
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
	
	AttributesValues = Common.ObjectAttributesValues(
		Object.Owner, "Title, ValueFormTitle");
	
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
			Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = '%1 (Группа значений свойства %2)'; en = '%1 (%2 property value group)'; pl = '%1 (Grupa wartości właściwości %2)';de = '%1 (Gruppe von Werten für das Attribut %2)';ro = '%1 (Grup de valori ale proprietății %2)';tr = '%1 ( %2 özniteliğinin değerler grubu)'; es_ES = '%1 (grupo de valores para el atributo %2)'"),
				Object.Description,
				PropertyName);
		Else
			Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Группа значений свойства %1 (Создание)'; en = '%1 property value group (Create)'; pl = 'Grupa wartości %1 właściwości (Utworzenie)';de = 'Gruppe von Attributen für %1 (Erstellung)';ro = 'Grupul de valori ale proprietății %1 (Creare)';tr = '%1 için öznitelikler grubu (Oluşturma)'; es_ES = 'Grupo de atributos para %1 (Creación)'"), PropertyName);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion
