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
		Title = Object.Description + " " + NStr("ru = '(Набор дополнительных реквизитов и сведений)'; en = '(Additional attributes and information set)'; pl = '(Zestaw dodatkowych atrybutów i informacji)';de = '(Sätze von zusätzlichen Attributen und Informationen)';ro = '(Set de atribute și date suplimentare)';tr = '(Ek nitelikler ve bilgi kümesi)'; es_ES = '(Grupo de atributos adicionales e información)'")
		
	ElsIf UseAddlAttributes Then
		Title = Object.Description + " " + NStr("ru = '(Набор дополнительных реквизитов)'; en = '(Additional attributes set)'; pl = '(Dodatkowy zestaw atrybutów)';de = '(Zusätzlicher Attribut Satz)';ro = '(Set de atribute suplimentare)';tr = '(Ek nitelikler kümesi)'; es_ES = '(Conjunto de atributos adicionales)'")
		
	ElsIf UseAddlInfo Then
		Title = Object.Description + " " + NStr("ru = '(Набор дополнительных сведений)'; en = '(Additional information set)'; pl = '(Zestaw dodatkowych informacji)';de = '(Weitere Informationen Satz)';ro = '(Set de informații suplimentare)';tr = '(Ek bilgi kümesi)'; es_ES = '(Conjunto de la información adicional)'")
	EndIf;
	
	If NOT UseAddlAttributes AND Object.AdditionalAttributes.Count() = 0 Then
		Items.AdditionalAttributes.Visible = False;
	EndIf;
	
	If NOT UseAddlInfo AND Object.AdditionalInfo.Count() = 0 Then
		Items.AdditionalInfo.Visible = False;
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
