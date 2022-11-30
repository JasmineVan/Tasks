///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnCopy(CopiedObject)
	
	Title = "";
	Name       = "";
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	// Dependencies are cleared for common attributes.
	If Not IsAdditionalInfo
		AND Not ValueIsFilled(PropertiesSet)
		AND AdditionalAttributesDependencies.Count() > 0 Then
		AdditionalAttributesDependencies.Clear();
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If PropertyManagerInternal.ValueTypeContainsPropertyValues(ValueType) Then
		
		Query = New Query;
		Query.SetParameter("ValuesOwner", Ref);
		Query.Text =
		"SELECT
		|	Properties.Ref AS Ref,
		|	Properties.ValueType AS ValueType
		|FROM
		|	ChartOfCharacteristicTypes.AdditionalAttributesAndInfo AS Properties
		|WHERE
		|	Properties.AdditionalValuesOwner = &ValuesOwner";
		Selection = Query.Execute().Select();
		
		While Selection.Next() Do
			NewValueType = Undefined;
			
			If ValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValues"))
			   AND NOT Selection.ValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValues")) Then
				
				NewValueType = New TypeDescription(
					Selection.ValueType,
					"CatalogRef.ObjectsPropertiesValues",
					"CatalogRef.ObjectPropertyValueHierarchy");
				
			ElsIf ValueType.ContainsType(Type("CatalogRef.ObjectPropertyValueHierarchy"))
			        AND NOT Selection.ValueType.ContainsType(Type("CatalogRef.ObjectPropertyValueHierarchy")) Then
				
				NewValueType = New TypeDescription(
					Selection.ValueType,
					"CatalogRef.ObjectPropertyValueHierarchy",
					"CatalogRef.ObjectsPropertiesValues");
				
			EndIf;
			
			If NewValueType <> Undefined Then
				CurrentObject = Selection.Ref.GetObject();
				CurrentObject.ValueType = NewValueType;
				CurrentObject.DataExchange.Load = True;
				CurrentObject.Write();
			EndIf;
		EndDo;
	EndIf;
	
	// Check that deletion mark is changed not from the list.
	// Sets of additional attributes and info.
	ObjectProperties = Common.ObjectAttributesValues(Ref, "DeletionMark");
	Query = New Query;
	Query.Text =
		"SELECT
		|	Sets.Ref AS Ref
		|FROM
		|	%1 AS Properties
		|		LEFT JOIN Catalog.AdditionalAttributesAndInfoSets AS Sets
		|		ON (Properties.Ref = Sets.Ref)
		|WHERE
		|	Properties.Property = &Property
		|	AND Properties.DeletionMark <> &DeletionMark";
	If IsAdditionalInfo Then
		TableName = "Catalog.AdditionalAttributesAndInfoSets.AdditionalInfo";
	Else
		TableName = "Catalog.AdditionalAttributesAndInfoSets.AdditionalAttributes";
	EndIf;
	Query.Text = StringFunctionsClientServer.SubstituteParametersToString(Query.Text, TableName);
	Query.SetParameter("Property", Ref);
	Query.SetParameter("DeletionMark", ObjectProperties.DeletionMark);
	
	Result = Query.Execute().Unload();
	
	For Each ResultString In Result Do
		PropertySetObject = ResultString.Ref.GetObject();
		If IsAdditionalInfo Then
			FillPropertyValues(PropertySetObject.AdditionalInfo.Find(Ref, "Property"), ObjectProperties);
		Else
			FillPropertyValues(PropertySetObject.AdditionalAttributes.Find(Ref, "Property"), ObjectProperties);
		EndIf;
		
		PropertySetObject.Write();
	EndDo;
	
EndProcedure

Procedure BeforeDelete(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("Property", Ref);
	Query.Text =
	"SELECT
	|	PropertiesSets.Ref AS Ref
	|FROM
	|	Catalog.AdditionalAttributesAndInfoSets.AdditionalAttributes AS PropertiesSets
	|WHERE
	|	PropertiesSets.Property = &Property
	|
	|UNION ALL
	|
	|SELECT
	|	PropertiesSets.Ref
	|FROM
	|	Catalog.AdditionalAttributesAndInfoSets.AdditionalInfo AS PropertiesSets
	|WHERE
	|	PropertiesSets.Property = &Property";
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		CurrentObject = Selection.Ref.GetObject();
		// Deleting additional attributes.
		Index = CurrentObject.AdditionalAttributes.Count()-1;
		While Index >= 0 Do
			If CurrentObject.AdditionalAttributes[Index].Property = Ref Then
				CurrentObject.AdditionalAttributes.Delete(Index);
			EndIf;
			Index = Index - 1;
		EndDo;
		// Deleting additional info.
		Index = CurrentObject.AdditionalInfo.Count()-1;
		While Index >= 0 Do
			If CurrentObject.AdditionalInfo[Index].Property = Ref Then
				CurrentObject.AdditionalInfo.Delete(Index);
			EndIf;
			Index = Index - 1;
		EndDo;
		If CurrentObject.Modified() Then
			CurrentObject.DataExchange.Load = True;
			CurrentObject.Write();
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region Internal

Procedure OnReadPresentationsAtServer() Export
	LocalizationServer.OnReadPresentationsAtServer(ThisObject);
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.'; en = 'Invalid object call on the client.'; pl = 'Niedozwolone wezwanie obiektu na kliencie.';de = 'Unzulässiger Objektaufruf auf dem Client.';ro = 'Apel inadmisibil al obiectului pe client.';tr = 'İstemcide kabul edilmeyen nesne çağrısı.'; es_ES = 'Llamada no disponible del objeto en el cliente.'");
#EndIf