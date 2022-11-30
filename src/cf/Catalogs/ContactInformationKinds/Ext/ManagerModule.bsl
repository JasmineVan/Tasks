///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region ForCallsFromOtherSubsystems

// StandardSubsystems.BatchObjectsModification

// Returns the object attributes that are not recommended to be edited using batch attribute 
// modification data processor.
//
// Returns:
//  Array - a list of object attribute names.
Function AttributesToSkipInBatchProcessing() Export
	
	Result = New Array;
	Result.Add("*");
	Return Result;
	
EndFunction

// End StandardSubsystems.BatchObjectsModification

// StandardSubsystems.ObjectAttributesLock

// See ObjectAttributesLock.OnDefineObjectsWithLockedAttributes. 
Function GetObjectAttributesToLock() Export
	
	AttributesToLock = New Array;
	
	AttributesToLock.Add("Type;Type");
	AttributesToLock.Add("Parent");
	
	Return AttributesToLock;
	
EndFunction

// End StandardSubsystems.ObjectAttributesLock

#EndRegion

#EndRegion

#EndIf

#Region EventHandlers

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	LocalizationClientServer.PresentationGetProcessing(Data, Presentation, StandardProcessing);
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

// Registers other contact information kinds, for which the FieldKindOther field is to be filled in, for processing.
//
Procedure FillContactInformationKindsWithOtherFieldToProcess(Parameters) Export
	
	Query = New Query;
	Query.Text = "SELECT
		|	ContactInformationKinds.Ref,
		|	ContactInformationKinds.DeleteMultilineFIeld
		|FROM
		|	Catalog.ContactInformationKinds AS ContactInformationKinds
		|WHERE
		|	ContactInformationKinds.Type = &Type";
	
	Query.SetParameter("Type", Enums.ContactInformationTypes.Other);
	QueryResult = Query.Execute().Unload();

	InfobaseUpdate.MarkForProcessing(Parameters,
		QueryResult.UnloadColumn("Ref"));
	
EndProcedure

Procedure FillContactInformationKinds(Parameters) Export
	
	ContactInformationKindRef = InfobaseUpdate.SelectRefsToProcess(Parameters.Queue, "Catalog.ContactInformationKinds");
	
	ObjectsWithIssuesCount = 0;
	ObjectsProcessed = 0;
	
	While ContactInformationKindRef.Next() Do
		Try
			ContactInformationKind = ContactInformationKindRef.Ref.GetObject();
			If ContactInformationKind.DeleteMultilineFIeld Then
				ContactInformationKind.FieldKindOther = "MultilineWide";
			Else
				ContactInformationKind.FieldKindOther = "SingleLineWide";
			EndIf;
			InfobaseUpdate.WriteData(ContactInformationKind);
			ObjectsProcessed = ObjectsProcessed + 1;
			
		Except
			// If you cannot process any kind of contact information, try again.
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось обработать вид контактной информации: %1 по причине: %2'; en = 'Failed to process contact information kind: %1. Reason: %2'; pl = 'Nie udało się przetworzyć rodzaju informacji kontaktowej: %1 z powodu: %2';de = 'Die Art der Kontaktinformationen konnte nicht verarbeitet werden: %1 aus diesem Grund: %2';ro = 'Eșec la procesarea tipului de informații de contact: %1 din motivul: %2';tr = 'İletişim bilgilerin türü işlenemedi: %1 nedeni: %2'; es_ES = 'No se ha podido el tipo de la información de contacto: %1 a causa de: %2'"),
					ContactInformationKindRef.Ref, DetailErrorDescription(ErrorInfo()));
			WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Warning,
				Metadata.Catalogs.ContactInformationKinds, ContactInformationKindRef.Ref, MessageText);
		EndTry;
	EndDo;
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, "Catalog.ContactInformationKinds");
	
	If ObjectsProcessed = 0 AND ObjectsWithIssuesCount <> 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Процедуре ЗаполнитьВидыКонтактнойИнформации не удалось обработать некоторые виды контактной информации (пропущены): %1'; en = 'The FillContactInformationKinds procedure failed to process and skipped %1 kinds of contact information.'; pl = 'Procedurze WypełnijRodzajeInformacjiKontaktowej nie udało się przetworzyć niektórych rodzajów informacji kontaktowej (pominięte): %1';de = 'Die Prozedur KontaktInformationsAnsichtenAusfüllen konnte einige Arten von Kontaktinformationen nicht verarbeiten (weggelassen): %1';ro = 'Procedura ЗаполнитьВидыКонтактнойИнформации nu a putut procesa unele tipuri de informații de contact (omise): %1';tr = 'FillContactInformationKinds işlemi iletişim bilgilerin bazı türlerini işleyemedi (atlattı): %1'; es_ES = 'El procedimiento FillContactInformationKinds no puede procesar algunos tipos de información de contacto (omitido):%1'"), 
				ObjectsWithIssuesCount);
		Raise MessageText;
	Else
		WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Information,
			Metadata.Catalogs.ContactInformationKinds,,
				StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Процедура ЗаполнитьВидыКонтактнойИнформации обработала очередную порцию видов контактной информации: %1'; en = 'The FillContactInformationKinds procedure has processed another %1 kinds of contact information.'; pl = 'Procedura WypełnijRodzajeInformacjiKontaktowej przetworzyła kolejną porcję informacji kontaktowej: %1';de = 'Die Prozedur KontaktInformationsAnsichtenAusfüllen hat eine weitere Reihe von Kontaktinformationsarten verarbeitet: %1';ro = 'Procedura ЗаполнитьВидыКонтактнойИнформации a procesat porțiunea de rând a tipurilor de informații de contact: %1';tr = 'FillContactInformationKinds işlemi sıradaki iletişim bilgilerin türlerini işledi: %1'; es_ES = 'El procedimiento FillContactInformationKinds ha procesado tipos de información de contacto: %1'"),
					ObjectsProcessed));
	EndIf;
	
EndProcedure

#EndRegion


#EndIf