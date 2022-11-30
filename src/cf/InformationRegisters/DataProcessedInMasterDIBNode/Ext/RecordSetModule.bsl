///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		// The check of DataExchange.Import is not required, because operations with this register are 
		// performed during data exchange.
		
		If Common.IsSubordinateDIBNode() Then 
			MarkDataUpdatedInMasterNode();
		EndIf;
		
		Clear();
		Return;
	EndIf;
		
	If Count() > 0
		AND (Not ValueIsFilled(SessionParameters.UpdateHandlerParameters.DeferredProcessingQueue)
			Or Common.IsSubordinateDIBNode()
			Or (SessionParameters.UpdateHandlerParameters.ExecuteInMasterNodeOnly
			      AND Not StandardSubsystemsCached.DIBUsed())
			Or (Not SessionParameters.UpdateHandlerParameters.ExecuteInMasterNodeOnly
			      AND Not StandardSubsystemsCached.DIBUsed("WithFilter"))) Then
		
		Cancel = True;
		ExceptionText = NStr("ru = 'Запись в РегистрСведений.ДанныеОбработанныеВЦентральномУзлеРИБ возможна только при отметке выполнения отложенного обработчика обновления информационной базы, который выполняется только в центральном узле.'; en = 'Data can only be saved to InformationRegister.DataProcessedInMasterDIBNode when the deferred infobase update handler running in the master node is marked completed.'; pl = 'Zapis w РегистрСведений.ДанныеОбработанныеВЦентральномУзлеРИБ możliwa tylko przy oznaczeniu wykonania odroczonego programu przetwarzania bazy informacji, która jest wykonywana tylko na węźle centralnym.';de = 'Die Aufzeichnung in den RegisterInfoDaten.DatenBearbeitetAmHauptknotenDerVerteiltenInformationsbasis"" ist nur möglich, wenn der verzögerte Datenbank-Update-Handler markiert ist, der nur im zentralen Knoten ausgeführt wird.';ro = 'Înregistrarea în РегистрСведений.ДанныеОбработанныеВЦентральномУзлеРИБ este posibilă numai cu marcajul de executare a handlerului amânat de actualizare a bazei de informații, care se execută numai în nodul central.';tr = 'BilgiKaydı.RIBMerkezÜnitesindeİşlenmişVeriler''de kayıt yalnızca merkez ünitesinde yürütülen bekleyen bir veritabanı güncelleştirme işleyicisi çalıştırıldığında mümkündür.'; es_ES = 'El registro en InformationRegister.DataProcessedInMasterDIBNode es posible solo si hay marca de realización del procesador aplazado de la actualización de la base de información que se realiza solo en el nodo central.'");
		Raise ExceptionText;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure MarkDataUpdatedInMasterNode()
	
	For Each StrTabl In ThisObject Do
		
		AdditionalParameters    = InfobaseUpdate.AdditionalProcessingMarkParameters();
		FullMetadataObjectName = Common.ObjectAttributeValue(StrTabl.MetadataObject, "FullName");
		
		If StrFind(FullMetadataObjectName, "AccumulationRegister") > 0
			Or StrFind(FullMetadataObjectName, "AccountingRegister") > 0
			Or StrFind(FullMetadataObjectName, "CalculationRegister") > 0 Then
			
			AdditionalParameters.IsRegisterRecords       = True;
			AdditionalParameters.FullRegisterName = FullMetadataObjectName;
			DataToMark                          = StrTabl.Data;
			
		ElsIf StrFind(FullMetadataObjectName, "InformationRegister") > 0 Then
			
			RegisterMetadata = Metadata.FindByFullName(FullMetadataObjectName);
			
			If RegisterMetadata.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.Independent Then
				
				RegisterManager = Common.ObjectManagerByFullName(FullMetadataObjectName);
				
				DataToMark = RegisterManager.CreateRecordSet();
				FilterValues   = StrTabl.IndependentRegisterFiltersValues.Get();
				
				For Each KeyValue In FilterValues Do
					DataToMark.Filter[KeyValue.Key].Set(KeyValue.Value);
				EndDo;
				
			Else
				
				AdditionalParameters.IsRegisterRecords = True;
				AdditionalParameters.FullRegisterName = FullMetadataObjectName;
				DataToMark = StrTabl.Data;
				
			EndIf;
			
		Else
			DataToMark = StrTabl.Data;
		EndIf;
		
		InfobaseUpdate.MarkProcessingCompletion(DataToMark, AdditionalParameters, StrTabl.Queue);	
		
		If DataExchange.Sender <> Undefined Then // not creation of the initial image
			SetToRegisterResponseToMasterNode = InformationRegisters.DataProcessedInMasterDIBNode.CreateRecordSet();
			SetToRegisterResponseToMasterNode.Filter.ExchangePlanNode.Set(StrTabl.ExchangePlanNode);
			SetToRegisterResponseToMasterNode.Filter.MetadataObject.Set(StrTabl.MetadataObject);
			SetToRegisterResponseToMasterNode.Filter.Data.Set(StrTabl.Data);
			SetToRegisterResponseToMasterNode.Filter.Queue.Set(StrTabl.Queue);
			SetToRegisterResponseToMasterNode.Filter.UniqueKey.Set(StrTabl.UniqueKey);
			
			ExchangePlans.RecordChanges(DataExchange.Sender, SetToRegisterResponseToMasterNode);
		EndIf;
		
	EndDo;

EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Niedozwolone wezwanie obiektu na kliencie.';de = 'Unzulässiger Objektaufruf auf dem Client.';ro = 'Apel inadmisibil al obiectului pe client.';tr = 'İstemcide kabul edilmeyen nesne çağrısı.'; es_ES = 'Llamada no disponible del objeto en el cliente.'");
#EndIf