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
	
	If Not IsNew() Then
		
		If DeletionMark <> Common.ObjectAttributeValue(Ref, "DeletionMark") Then
			
			SetPrivilegedMode(True);
			
			SetDeletionMarkForAllAssociatedObjects(Ref, DeletionMark);
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure BeforeDelete(Cancel)
	
	// There is no DataExchange.Import property value verification as the code below implements the 
	// logic, which must be executed, including when this property is set to True (on the side of the 
	// code that attempts to record to this exchange plan).
	
	SetPrivilegedMode(True);
	Common.DeleteDataFromSecureStorage(Ref);
	SetPrivilegedMode(False);
EndProcedure

#EndRegion

#Region Private

// Sets or clears the deletion mark for all associated objects.
//
// Parameters:
//  Owner - ExchangePlanRef, CatalogRef, DocumentRef - reference to the object that is
//                    an owner of the objects to be marked for deletion.
//
//  DeletionMark - Boolean - flag that shows whether deletion marks of all subordinate objects must be set or cleared.
//
Procedure SetDeletionMarkForAllAssociatedObjects(Val Owner, Val DeletionMark)
	
	BeginTransaction();
	Try
		
		RefsList = New Array;
		RefsList.Add(Owner);
		References = FindByRef(RefsList);
		
		For Each CurrentRef In References Do
			
			If Common.RefTypeValue(CurrentRef[1]) Then
				CurrentRef[1].GetObject().SetDeletionMark(DeletionMark);
			EndIf;
			
		EndDo;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Niedozwolone wezwanie obiektu na kliencie.';de = 'Unzulässiger Objektaufruf auf dem Client.';ro = 'Apel inadmisibil al obiectului pe client.';tr = 'İstemcide kabul edilmeyen nesne çağrısı.'; es_ES = 'Llamada no disponible del objeto en el cliente.'");
#EndIf