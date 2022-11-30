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

// Returns object attributes allowed to be edited using batch attribute change data processor.
// 
//
// Returns:
//  Array - a list of object attribute names.
Function AttributesToEditInBatchProcessing() Export
	
	AttributesToEdit = New Array;
	
	Return AttributesToEdit;
	
EndFunction

// End StandardSubsystems.BatchObjectsModification

#EndRegion

#EndRegion

#EndIf

#Region EventHandlers

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	Fields.Add("PredefinedSetName");
	Fields.Add("Description");
	Fields.Add("Ref");
	Fields.Add("Parent");
	
	StandardProcessing = False;
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	If CurrentLanguage() = Metadata.DefaultLanguage Then
		Return;
	EndIf;
	
	If ValueIsFilled(Data.Parent) Then
		LocalizationClientServer.PresentationGetProcessing(Data, Presentation, StandardProcessing);
		Return;
	EndIf;
	
	If ValueIsFilled(Data.PredefinedSetName) Then
		SetName = Data.PredefinedSetName;
	Else
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
		SetName = Common.ObjectAttributeValue(Data.Ref, "PredefinedDataName");
#Else
		SetName = "";
#EndIf
	EndIf;
	Presentation = UpperLevelSetPresentation(SetName, Data);
	
	StandardProcessing = False;
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Updates descriptions of predefined sets in parameters of additional attributes and info.
// 
// 
// Parameters:
//  HasChanges - Boolean (return value) - if recorded, True is set, otherwise, it is not changed.
//                  
//
Procedure RefreshPredefinedSetsDescriptionsContent(HasChanges = Undefined) Export
	
	SetPrivilegedMode(True);
	
	PredefinedSets = PredefinedPropertiesSets();
	
	BeginTransaction();
	Try
		HasCurrentChanges = False;
		PreviousValue = Undefined;
		
		StandardSubsystemsServer.UpdateApplicationParameter(
			"StandardSubsystems.Properties.AdditionalDataAndAttributePredefinedSets",
			PredefinedSets, HasCurrentChanges, PreviousValue);
		
		StandardSubsystemsServer.AddApplicationParameterChanges(
			"StandardSubsystems.Properties.AdditionalDataAndAttributePredefinedSets",
			?(HasCurrentChanges,
			  New FixedStructure("HasChanges", True),
			  New FixedStructure()) );
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	If HasCurrentChanges Then
		HasChanges = True;
	EndIf;
	
EndProcedure

Procedure ProcessPropertiesSetsForMigrationToNewVersion(Parameters) Export
	
	PredefinedPropertiesSets = PropertyManagerCached.PredefinedPropertiesSets();
	ObjectsWithIssues = 0;
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	Sets.Ref AS Ref,
		|	Sets.PredefinedDataName AS PredefinedDataName,
		|	Sets.AdditionalAttributes.(
		|		Property AS Property
		|	) AS AdditionalAttributes,
		|	Sets.AdditionalInfo.(
		|		Property AS Property
		|	) AS AdditionalInfo,
		|	Sets.Parent AS Parent,
		|	Sets.IsFolder AS IsFolder
		|FROM
		|	Catalog.AdditionalAttributesAndInfoSets AS Sets
		|WHERE
		|	Sets.Predefined = TRUE";
	Result = Query.Execute().Unload();
	
	For Each SetToUpdate In Result Do
		
		BeginTransaction();
		Try
			If Not ValueIsFilled(SetToUpdate.PredefinedDataName) Then
				RollbackTransaction();
				Continue;
			EndIf;
			If Not StrStartsWith(SetToUpdate.PredefinedDataName, "Delete") Then
				RollbackTransaction();
				Continue;
			EndIf;
			If SetToUpdate.AdditionalAttributes.Count() = 0
				AND SetToUpdate.AdditionalInfo.Count() = 0 Then
				RollbackTransaction();
				Continue;
			EndIf;
			SetName = Mid(SetToUpdate.PredefinedDataName, 8, StrLen(SetToUpdate.PredefinedDataName) - 7);
			NewSetDetails = PredefinedPropertiesSets.Get(SetName);
			If NewSetDetails = Undefined Then
				RollbackTransaction();
				Continue;
			EndIf;
			NewSet = NewSetDetails.Ref;
			
			Lock = New DataLock;
			LockItem = Lock.Add("Catalog.AdditionalAttributesAndInfoSets");
			LockItem.SetValue("Ref", NewSet);
			Lock.Lock();
			
			// Fill in a new set.
			NewSetObject = NewSet.GetObject();
			If SetToUpdate.IsFolder <> NewSetObject.IsFolder Then
				RollbackTransaction();
				Continue;
			EndIf;
			For Each StringAttribute In SetToUpdate.AdditionalAttributes Do
				NewStringAttributes = NewSetObject.AdditionalAttributes.Add();
				FillPropertyValues(NewStringAttributes, StringAttribute);
				NewStringAttributes.PredefinedSetName = NewSetObject.PredefinedSetName;
			EndDo;
			For Each StringInfo In SetToUpdate.AdditionalInfo Do
				NewStringInfo = NewSetObject.AdditionalInfo.Add();
				FillPropertyValues(NewStringInfo, StringInfo);
				NewStringInfo.PredefinedSetName = NewSetObject.PredefinedSetName;
			EndDo;
			
			// Update attributes and info.
			If Not SetToUpdate.IsFolder Then
				For Each TableRow In SetToUpdate.AdditionalAttributes Do
					ObjectAttribute = TableRow.Property.GetObject();
					If Not ValueIsFilled(ObjectAttribute.PropertiesSet) Then
						Continue;
					EndIf;
					ObjectAttribute.PropertiesSet = NewSet;
					InfobaseUpdate.WriteObject(ObjectAttribute);
				EndDo;
				
				For Each TableRow In SetToUpdate.AdditionalInfo Do
					ObjectProperty = TableRow.Property.GetObject();
					If Not ValueIsFilled(ObjectProperty.PropertiesSet) Then
						Continue;
					EndIf;
					ObjectProperty.PropertiesSet = NewSet;
					InfobaseUpdate.WriteObject(ObjectProperty);
				EndDo;
			EndIf;
			
			If Not SetToUpdate.IsFolder Then
				AttributesCount = Format(NewSetObject.AdditionalAttributes.FindRows(
					New Structure("DeletionMark", False)).Count(), "NG=");
				InfoCount   = Format(NewSetObject.AdditionalInfo.FindRows(
					New Structure("DeletionMark", False)).Count(), "NG=");
				
				NewSetObject.AttributesCount = AttributesCount;
				NewSetObject.InfoCount   = InfoCount;
			EndIf;
			
			InfobaseUpdate.WriteObject(NewSetObject);
			
			// Clear an old set.
			ObsoleteSetObject = SetToUpdate.Ref.GetObject();
			ObsoleteSetObject.AdditionalAttributes.Clear();
			ObsoleteSetObject.AdditionalInfo.Clear();
			ObsoleteSetObject.Used = False;
			
			InfobaseUpdate.WriteObject(ObsoleteSetObject);
			
			If SetToUpdate.IsFolder Then
				Query = New Query;
				Query.SetParameter("Parent", SetToUpdate.Ref);
				Query.Text = 
					"SELECT
					|	AdditionalAttributesAndInfoSets.Ref AS Ref
					|FROM
					|	Catalog.AdditionalAttributesAndInfoSets AS AdditionalAttributesAndInfoSets
					|WHERE
					|	AdditionalAttributesAndInfoSets.Parent = &Parent
					|	AND AdditionalAttributesAndInfoSets.Predefined = FALSE";
				SetsToTransfer = Query.Execute().Unload();
				For Each Row In SetsToTransfer Do
					SetObject = Row.Ref.GetObject();
					SetObject.Parent = NewSet;
					InfobaseUpdate.WriteObject(SetObject);
				EndDo;
			EndIf;
			
			CommitTransaction();
		Except
			RollbackTransaction();
			
			ObjectsWithIssues = ObjectsWithIssues + 1;
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось обработать набор свойств: %1 по причине:
					|%2'; 
					|en = 'Cannot process the %1 property set due to:
					|%2'; 
					|pl = 'Nie udało się przetworzyć zestaw właściwości: %1 z powodu:
					|%2';
					|de = 'Es war nicht möglich, den Eigenschaftssatz zu verarbeiten: %1aus diesem Grund:
					|%2';
					|ro = 'Eșec la procesarea setului de proprietăți: %1 din motivul: 
					|%2';
					|tr = 'Özellik kümesi işlenemedi:%1 nedeniyle:
					|%2'; 
					|es_ES = 'No se ha podido procesar el conjunto de propiedades: %1 a causa de:
					|%2'"), 
					SetToUpdate.Ref, DetailErrorDescription(ErrorInfo()));
			WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Warning,
				Metadata.Catalogs.AdditionalAttributesAndInfoSets, SetToUpdate.Ref, MessageText);
		EndTry;
		
	EndDo;
	
	If ObjectsWithIssues <> 0 Then
		MessageText = NStr("ru = 'Процедура ОбработатьНаборыСвойствДляПереходаНаНовуюВерсию завершилась с ошибкой. Не все наборы свойств удалось обновить.'; en = 'The ProcessPropertiesSetsForMigrationToNewVersion procedure has completed with an error. Not all property sets have been updated.'; pl = 'Procedura ОбработатьНаборыСвойствДляПереходаНаНовуюВерсию zakończyła się błędem. Nie wszystkie zestawy właściwości zostały zaktualizowane.';de = 'Die Vorgehensweise BearbeitenVonEigenschaftssätzen ZumWechselnZuEinerNeuenVersion wurde mit einem Fehler beendet. Nicht alle Eigenschaftssätze wurden aktualisiert.';ro = 'Procedura ОбработатьНаборыСвойствДляПереходаНаНовуюВерсию s-a soldat cu eroare. Nu toate seturile proprietăților au fost actualizate.';tr = 'Yeni sürüme geçiş için ayarlanan bir özelliği kullanma prosedürü bir hatayla sona erdi. Tüm özellik kümeleri güncellenmedi.'; es_ES = 'El procedimiento ОбработатьНаборыСвойствДляПереходаНаНовуюВерсию se ha terminado con error. No todos los conjuntos de propiedades se ha podido actualizar.'");
		Raise MessageText;
	EndIf;
	
	Parameters.ProcessingCompleted = True;
	
EndProcedure



#EndRegion

#EndIf

#Region Private

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Function PredefinedPropertiesSets() Export
	
	SetsTree = New ValueTree;
	SetsTree.Columns.Add("Name");
	SetsTree.Columns.Add("IsFolder", New TypeDescription("Boolean"));
	SetsTree.Columns.Add("Used");
	SetsTree.Columns.Add("ID");
	SSLSubsystemsIntegration.OnGetPredefinedPropertiesSets(SetsTree);
	PropertyManagerOverridable.OnGetPredefinedPropertiesSets(SetsTree);
	
	PropertiesSetsDescriptions = PropertyManagerInternal.PropertiesSetsDescriptions();
	Descriptions = PropertiesSetsDescriptions[CurrentLanguage().LanguageCode];
	
	PropertiesSets = New Map;
	For Each Set In SetsTree.Rows Do
		SetProperties = SetProperties(PropertiesSets, Set);
		For Each ChildSet In Set.Rows Do
			ChildSetProperties = SetProperties(PropertiesSets, ChildSet, SetProperties.Ref, Descriptions);
			SetProperties.ChildSets.Insert(ChildSet.Name, ChildSetProperties);
		EndDo;
		SetProperties.ChildSets = New FixedMap(SetProperties.ChildSets);
		PropertiesSets[SetProperties.Name] = New FixedStructure(PropertiesSets[SetProperties.Name]);
		PropertiesSets[SetProperties.Ref] = New FixedStructure(PropertiesSets[SetProperties.Ref]);
	EndDo;
	
	Return New FixedMap(PropertiesSets);
	
EndFunction

Function SetProperties(PropertiesSets, Set, Parent = Undefined, Descriptions = Undefined)
	
	ErrorTitle =
		NStr("ru = 'Ошибка в процедуре ПриСозданииПредопределенныхНаборовСвойств
		           |общего модуля УправлениеСвойствамиПереопределяемый.'; 
		           |en = 'An error occurred in the OnCreatePredefinedPropertiesSets procedure
		           | of the PropertyManagerOverridable common module.'; 
		           |pl = 'Wystąpił błąd w procedurze ПриСозданииПредопределенныхНаборовСвойств
		           | modułu ogólnego УправлениеСвойствамиПереопределяемый.';
		           |de = 'Fehler in der Vorgehensweise VordefinierteEigenschaftssätzeErstellen
		           |des allgemeinen Moduls PropertyManagementÜberschreibbar.';
		           |ro = 'Eroare în procedura ПриСозданииПредопределенныхНаборовСвойств
		           |a modulului comun УправлениеСвойствамиПереопределяемый.';
		           |tr = 'Genel özellik yönetimi modülünde ayarlanmış 
		           |önceden tanımlanmış bir özellik oluşturma prosedüründeki bir hata geçersiz kılınabilir.'; 
		           |es_ES = 'Error en el procedimiento ПриСозданииПредопределенныхНаборовСвойств
		           |del módulo común УправлениеСвойствамиПереопределяемый.'")
		+ Chars.LF
		+ Chars.LF;
	
	If Not ValueIsFilled(Set.Name) Then
		Raise ErrorTitle + NStr("ru = 'Имя набора свойств не заполнено.'; en = 'Property set name is required.'; pl = 'Nazwa zestawu właściwości nie jest wypełniona.';de = 'Der Name des Eigenschaftssatzes wird nicht ausgefüllt.';ro = 'Nu este completat numele setului de proprietăți.';tr = 'Özellik kümesi adı dolu değil.'; es_ES = 'Nombre del conjunto de propiedades no está rellenado'");
	EndIf;
	
	If PropertiesSets.Get(Set.Name) <> Undefined Then
		Raise ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Имя набора свойств ""%1"" уже определено.'; en = 'Property set name %1 is already defined.'; pl = 'Nazwa zestawu właściwości  ""%1"" jest już zdefiniowana.';de = 'Der Name des Eigenschaftssatzes ""%1"" ist bereits definiert.';ro = 'Numele setului de proprietăți ""%1"" deja este determinat.';tr = '""%1"" Özellik kümesi adı zaten tanımlanmış.'; es_ES = 'El nombre del conjunto de propiedades ""%1"" ya está determinado.'"),
			Set.Name);
	EndIf;
	
	If Not ValueIsFilled(Set.ID) Then
		Raise ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Идентификатор набора свойств ""%1"" не заполнен.'; en = 'ID of the %1 property set is required.'; pl = 'Identyfikator zestawu właściwości ""%1"" nie jest  wypełniony.';de = 'Die Kennung des Eigenschaftssatzes ""%1"" ist nicht ausgefüllt.';ro = 'Identificatorul setului de proprietăți ""%1"" nu este completat.';tr = 'Özellik kümesi kimliği ""%1"" doldurulmadı.'; es_ES = 'El identificador del conjunto de propiedades ""%1"" no está rellenado.'"),
			Set.Name);
	EndIf;
	
	If Not Common.SeparatedDataUsageAvailable() Then
		SetRef = Set.ID;
	Else
		SetRef = GetRef(Set.ID);
	EndIf;
	
	If PropertiesSets.Get(SetRef) <> Undefined Then
		Raise ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Идентификатор ""%1"" набора свойств
			           |""%2"" уже используется для набора ""%3"".'; 
			           |en = 'ID %1 of the
			           |%2 property set is already used for the %3 set.'; 
			           |pl = 'Identyfikator  ""%1"" zestawu właściwości
			           |""%2""  jest już używany dla zestawu ""%3"".';
			           |de = 'Die Kennung ""%1"" des Eigenschaftssatzes
			           |""%2 wird bereits für den Eigenschaftssatz ""%3"" verwendet.';
			           |ro = 'Identificatorul ""%1"" setului de proprietăți
			           |""%2"" deja se utilizează pentru setul ""%3"".';
			           |tr = 'Özellik %1kümesi kimliği 
			           |%2zaten set için kullanılıyor%3.'; 
			           |es_ES = 'El identificador ""%1"" del conjunto de propiedades
			           |""%2"" ya se usa para este conjunto ""%3"".'"),
			Set.ID, Set.Name, PropertiesSets.Get(SetRef).Name);
	EndIf;
	
	SetProperties = New Structure;
	SetProperties.Insert("Name", Set.Name);
	SetProperties.Insert("IsFolder", Set.IsFolder);
	SetProperties.Insert("Used", Set.Used);
	SetProperties.Insert("Ref", SetRef);
	SetProperties.Insert("Parent", Parent);
	SetProperties.Insert("ChildSets", ?(Parent = Undefined, New Map, Undefined));
	If Descriptions = Undefined Then
		SetProperties.Insert("Description", UpperLevelSetPresentation(Set.Name));
	Else
		SetProperties.Insert("Description", Descriptions[Set.Name]);
	EndIf;
	
	If Parent <> Undefined Then
		SetProperties = New FixedStructure(SetProperties);
	EndIf;
	PropertiesSets.Insert(SetProperties.Name,    SetProperties);
	PropertiesSets.Insert(SetProperties.Ref, SetProperties);
	
	Return SetProperties;
	
EndFunction

#EndIf

// APK:361-disable server code was not accessed.
Function UpperLevelSetPresentation(PredefinedItemName, SetProperties = Undefined)
	
	Presentation = "";
	Position = StrFind(PredefinedItemName, "_");
	FirstNamePart =  Left(PredefinedItemName, Position - 1);
	SecondNamePart = Right(PredefinedItemName, StrLen(PredefinedItemName) - Position);
	
	FullName = FirstNamePart + "." + SecondNamePart;
	
	MetadataObject = Metadata.FindByFullName(FullName);
	If MetadataObject = Undefined Then
		Return Presentation;
	EndIf;
	
	If ValueIsFilled(MetadataObject.ListPresentation) Then
		Presentation = MetadataObject.ListPresentation;
	ElsIf ValueIsFilled(MetadataObject.Synonym) Then
		Presentation = MetadataObject.Synonym;
	ElsIf SetProperties <> Undefined Then
		Presentation = SetProperties.Description;
	EndIf;
	
	Return Presentation;
	
EndFunction

#EndRegion