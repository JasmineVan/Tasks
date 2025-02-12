﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

// The infobase update handler.
Function MoveDataToNewRegister() Export
	
	QueryOfHavingData = New Query;
	QueryOfHavingData.Text =
	"SELECT TOP 1
	|	TRUE AS TrueValue
	|FROM
	|	InformationRegister.DeleteAccessValuesSets AS DeleteAccessValuesSets";
	
	If QueryOfHavingData.Execute().IsEmpty() Then
		Return True;
	EndIf;
	
	If NOT AccessManagement.LimitAccessAtRecordLevel() Then
		RecordSet = CreateRecordSet();
		RecordSet.Write();
	EndIf;
	
	ObjectsTypes = AccessManagementInternalCached.ObjectsTypesInSubscriptionsToEvents(
		"WriteAccessValuesSets", True);
	
	Query = New Query;
	Query.Parameters.Insert("ObjectsTypes", ObjectsTypes);
	Query.Text =
	"SELECT DISTINCT TOP 10000
	|	DeleteAccessValuesSets.Object
	|FROM
	|	InformationRegister.DeleteAccessValuesSets AS DeleteAccessValuesSets
	|		INNER JOIN Catalog.MetadataObjectIDs AS IDs
	|		ON (VALUETYPE(DeleteAccessValuesSets.Object) = VALUETYPE(IDs.EmptyRefValue))
	|			AND (IDs.EmptyRefValue IN (&ObjectsTypes))";
	
	Selection = Query.Execute().Select();
	OldRecordsSet = CreateRecordSet();
	NewRecordsSet = InformationRegisters.AccessValuesSets.CreateRecordSet();
	
	CheckQuery = New Query;
	CheckQuery.Text =
	"SELECT TOP 1
	|	TRUE AS TrueValue
	|FROM
	|	InformationRegister.AccessValuesSets AS AccessValuesSets
	|WHERE
	|	AccessValuesSets.Object = &Object";
	
	While Selection.Next() Do
		OldRecordsSet.Filter.Object.Set(Selection.Object);
		NewRecordsSet.Filter.Object.Set(Selection.Object);
		CheckQuery.SetParameter("Object", Selection.Object);
		NewRecordsSet.Clear();
		NewSets = AccessManagement.AccessValuesSetsTable();
		
		ObjectMetadata = Selection.Object.Metadata();
		ObjectWithSets = ObjectMetadata.TabularSections.Find("AccessValuesSets") <> Undefined;
		
		Lock = New DataLock;
		LockItem = Lock.Add("InformationRegister.AccessValuesSets");
		LockItem.SetValue("Object", Selection.Object);
		If ObjectWithSets Then
			LockItem = Lock.Add(ObjectMetadata.FullName());
			LockItem.SetValue("Ref", Selection.Object);
		EndIf;
		
		BeginTransaction();
		Try
			Lock.Lock();
			If CheckQuery.Execute().IsEmpty() Then
				OldRecordsSet.Read();
				ClarificationFilled = False;
				FillNewObjectSets(OldRecordsSet, NewSets, ClarificationFilled);
				If ClarificationFilled AND ObjectWithSets Then
					Object = Selection.Object.GetObject();
					Object.AccessValuesSets.Load(NewSets);
					InfobaseUpdate.WriteData(Object);
				EndIf;
				AccessManagementInternal.PrepareAccessValuesSetsForWrite(
					Selection.Object, NewSets, True);
				NewRecordsSet.Load(NewSets);
				NewRecordsSet.Write();
			EndIf;
			OldRecordsSet.Clear();
			OldRecordsSet.Write();
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	EndDo;
	
	If Selection.Count() < 10000 Then
		
		If NOT QueryOfHavingData.Execute().IsEmpty() Then
			RecordSet = CreateRecordSet();
			RecordSet.Write();
		EndIf;
		
		WriteLogEvent(
			NStr("ru = 'Управление доступом.Заполнение данных для ограничения доступа'; en = 'Access management.Populate access restrictions data'; pl = 'Zarządzanie dostępem. Wprowadzenie danych w celu ograniczenia dostępu';de = 'Zugriffsverwaltung. Datenausfüllung für Zugriffsbeschränkung';ro = 'Administrarea accesului.Completarea datelor pentru restricționarea accesului';tr = 'Erişim yönetimi. Erişim kısıtlaması için veri doldurulması'; es_ES = 'Gestión de acceso.Población de datos para la restricción de acceso'",
				 Common.DefaultLanguageCode()),
			EventLogLevel.Information,
			,
			,
			NStr("ru = 'Завершен перенос данных из регистра УдалитьНаборыЗначенийДоступа.'; en = 'Data transfer from the DeleteAccessValuesSets register is complete.'; pl = 'Zakończono przenoszenie danych z rejestru  УдалитьНаборыЗначенийДоступа.';de = 'Die Übertragung der Daten aus dem Register LöschenSetZugriffsWerte ist abgeschlossen.';ro = 'Transferul de date din registrul УдалитьНаборыЗначенийДоступа este finalizat.';tr = 'Verilerin ErişimDeğeriKümeleriniKaldır kayıt defterinden transferi tamamlanmıştır.'; es_ES = 'Se han trasladado los datos del registro DeleteAccessValuesSets.'"),
			EventLogEntryTransactionMode.Transactional);
	Else
		WriteLogEvent(
			NStr("ru = 'Управление доступом.Заполнение данных для ограничения доступа'; en = 'Access management.Populate access restrictions data'; pl = 'Zarządzanie dostępem. Wprowadzenie danych w celu ograniczenia dostępu';de = 'Zugriffsverwaltung. Datenausfüllung für Zugriffsbeschränkung';ro = 'Administrarea accesului.Completarea datelor pentru restricționarea accesului';tr = 'Erişim yönetimi. Erişim kısıtlaması için veri doldurulması'; es_ES = 'Gestión de acceso.Población de datos para la restricción de acceso'",
				 Common.DefaultLanguageCode()),
			EventLogLevel.Information,
			,
			,
			NStr("ru = 'Выполнен шаг переноса данных из регистра УдалитьНаборыЗначенийДоступа.'; en = 'Step of data transfer from the DeleteAccessValuesSets register is performed.'; pl = 'Krok przesyłania danych z rejestru jest zakończony  УдалитьНаборыЗначенийДоступа.';de = 'Der Schritt der Datenübernahme aus dem Register LöschenSetZugriffsWerte wird ausgeführt.';ro = 'Pasul de transferare a datelor din registrul УдалитьНаборыЗначенийДоступа este executat.';tr = 'Verilerin ErişimDeğeriKümeleriniKaldır kayıt defterinden transfer adımı tamamlanmıştır.'; es_ES = 'Se ha realizado una etapa de traslado de los datos del registro DeleteAccessValuesSets.'"),
			EventLogEntryTransactionMode.Transactional);
	EndIf;
	
	Return False;
	
EndFunction

Procedure FillNewObjectSets(OldRecords, NewSets, ClarificationFilled)
	
	ActiveSets = New Map;
	
	For each OldRow In OldRecords Do
		If OldRow.Read Or OldRow.Update Then
			ActiveSets.Insert(OldRow.SetNumber, True);
		EndIf;
	EndDo;
	
	AvailableRights = AccessManagementInternalCached.RightsForObjectsRightsSettingsAvailable();
	RightsSettingsOwnersTypes = AvailableRights.ByRefsTypes;
	
	For each OldRow In OldRecords Do
		If ActiveSets.Get(OldRow.SetNumber) = Undefined Then
			Continue;
		EndIf;
		NewRow = NewSets.Add();
		FillPropertyValues(NewRow, OldRow, "SetNumber, AccessValue, Read, Update");
		
		If OldRow.AccessKind = ChartsOfCharacteristicTypes.DeleteAccessKinds.EmptyRef() Then
			If OldRow.AccessValue = Undefined Then
				NewRow.AccessValue = Enums.AdditionalAccessValues.AccessDenied;
			Else
				NewRow.AccessValue = Enums.AdditionalAccessValues.AccessAllowed;
			EndIf;
		
		ElsIf OldRow.AccessKind = ChartsOfCharacteristicTypes.DeleteAccessKinds.ReadRight
		      OR OldRow.AccessKind = ChartsOfCharacteristicTypes.DeleteAccessKinds.EditRight
		      OR OldRow.AccessKind = ChartsOfCharacteristicTypes.DeleteAccessKinds.InsertRight Then
			
			If TypeOf(OldRow.AccessValue) <> Type("CatalogRef.MetadataObjectIDs") Then
				If Metadata.FindByType(TypeOf(OldRow.AccessValue)) = Undefined Then
					NewRow.AccessValue = Catalogs.MetadataObjectIDs.EmptyRef();
				Else
					NewRow.AccessValue =
						Common.MetadataObjectID(TypeOf(OldRow.AccessValue));
				EndIf;
			EndIf;
			
			If OldRow.AccessKind = ChartsOfCharacteristicTypes.DeleteAccessKinds.ReadRight Then
				NewRow.Clarification = Catalogs.MetadataObjectIDs.EmptyRef();
			Else
				NewRow.Clarification = NewRow.AccessValue;
			EndIf;
			
		ElsIf RightsSettingsOwnersTypes.Get(TypeOf(OldRow.AccessValue)) <> Undefined Then
			
			NewRow.Clarification = Common.MetadataObjectID(TypeOf(OldRow.Object));
		EndIf;
		
		If ValueIsFilled(NewRow.Clarification) Then
			ClarificationFilled = True;
		EndIf;
	EndDo;
	
	AccessManagement.AddAccessValuesSets(
		NewSets, AccessManagement.AccessValuesSetsTable(), False, True);
	
EndProcedure

#EndRegion

#EndIf