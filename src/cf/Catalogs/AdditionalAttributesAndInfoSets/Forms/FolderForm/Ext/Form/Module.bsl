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
	
	ReadOnly = True;
	
	SetPropertiesTypes = PropertyManagerInternal.SetPropertiesTypes(Object.Ref);
	UseAddlAttributes = SetPropertiesTypes.AdditionalAttributes;
	UseAddlInfo  = SetPropertiesTypes.AdditionalInfo;
	
	If UseAddlAttributes AND UseAddlInfo Then
		Title = Object.Description + " " + NStr("ru = '(Группа наборов дополнительных реквизитов и сведений)'; en = '(Additional attributes and information set group)'; pl = '(Grupa zestawów dodatkowych atrybutów i informacji)';de = '(Gruppe von Sätzen zusätzlicher Attribute und Informationen)';ro = '(Grupul seturilor de atribute și date suplimentare)';tr = '(Ek nitelikler ve bilgi kümeleri grubu)'; es_ES = '(Grupo de conjuntos de atributos adicionales e información)'")
		
	ElsIf UseAddlAttributes Then
		Title = Object.Description + " " + NStr("ru = '(Группа наборов дополнительных реквизитов)'; en = '(Additional attributes set group)'; pl = '(Grupa zestawów dodatkowych atrybutów)';de = '(Gruppe von Sätzen zusätzlicher Attribute)';ro = '(Grupul seturilor de atribute suplimentare)';tr = '(Ek nitelikler grubu)'; es_ES = '(Grupo de conjuntos de atributos adicionales)'")
		
	ElsIf UseAddlInfo Then
		Title = Object.Description + " " + NStr("ru = '(Группа наборов дополнительных сведений)'; en = '(Additional information set group)'; pl = '(Grupa dodatkowych zestawów informacji)';de = '(Gruppe zusätzlicher Informationssätze)';ro = '(Grupul seturilor de date suplimentare)';tr = '(Ek bilgi grubu)'; es_ES = '(Grupo de conjuntos de la información adicional)'")
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.AccessManagement
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	EndIf;
	// End StandardSubsystems.AccessManagement

EndProcedure

#EndRegion
