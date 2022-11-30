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
	
	If IsFolder Or Not ValueIsFilled(Parent) Then
		For Each AdditionalAttribute In AdditionalAttributes Do
			If AdditionalAttribute.PredefinedSetName <> PredefinedSetName Then
				AdditionalAttribute.PredefinedSetName = PredefinedSetName;
			EndIf;
		EndDo;
		
		For Each AdditionalInfoItem In AdditionalInfo Do
			If AdditionalInfoItem.PredefinedSetName <> PredefinedSetName Then
				AdditionalInfoItem.PredefinedSetName = PredefinedSetName;
			EndIf;
		EndDo;
	EndIf;
	
	If Not IsFolder Then
		// Deleting duplicates and empty rows.
		SelectedProperties = New Map;
		PropertiesToDelete = New Array;
		
		// Additional attributes.
		For each AdditionalAttribute In AdditionalAttributes Do
			
			If AdditionalAttribute.Property.IsEmpty()
			 OR SelectedProperties.Get(AdditionalAttribute.Property) <> Undefined Then
				
				PropertiesToDelete.Add(AdditionalAttribute);
			Else
				SelectedProperties.Insert(AdditionalAttribute.Property, True);
			EndIf;
		EndDo;
		
		For each PropertyToDelete In PropertiesToDelete Do
			AdditionalAttributes.Delete(PropertyToDelete);
		EndDo;
		
		SelectedProperties.Clear();
		PropertiesToDelete.Clear();
		
		// Additional info.
		For each AdditionalInfoItem In AdditionalInfo Do
			
			If AdditionalInfoItem.Property.IsEmpty()
			 OR SelectedProperties.Get(AdditionalInfoItem.Property) <> Undefined Then
				
				PropertiesToDelete.Add(AdditionalInfoItem);
			Else
				SelectedProperties.Insert(AdditionalInfoItem.Property, True);
			EndIf;
		EndDo;
		
		For each PropertyToDelete In PropertiesToDelete Do
			AdditionalInfo.Delete(PropertyToDelete);
		EndDo;
		
		// Calculating the number of properties not marked for deletion.
		AttributesCount = Format(AdditionalAttributes.FindRows(
			New Structure("DeletionMark", False)).Count(), "NG=");
		
		InfoCount   = Format(AdditionalInfo.FindRows(
			New Structure("DeletionMark", False)).Count(), "NG=");
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If NOT IsFolder Then
		// Updates content of the top group to use fields of the dynamic list and its settings (filters, ...
		// ) upon customization.
		If ValueIsFilled(Parent) Then
			PropertyManagerInternal.CheckRefreshGroupPropertiesContent(Parent);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Niedozwolone wezwanie obiektu na kliencie.';de = 'Unzulässiger Objektaufruf auf dem Client.';ro = 'Apel inadmisibil al obiectului pe client.';tr = 'İstemcide kabul edilmeyen nesne çağrısı.'; es_ES = 'Llamada no disponible del objeto en el cliente.'");
#EndIf