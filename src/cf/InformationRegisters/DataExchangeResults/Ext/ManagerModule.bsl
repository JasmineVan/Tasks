///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

Procedure RecordIssueResolved(Source, IssueType, InfobaseNode = Undefined) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	If Source.IsNew() Then
		Return;
	EndIf;
	
	If Not Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	ObjectMetadata = Source.Metadata();
	
	If Common.IsRegister(ObjectMetadata) Then
		Return;
	EndIf;
	
	If DataExchangeCached.ObjectsToRegisterDataProblemsOnImport().Get(ObjectMetadata) = Undefined Then
		Return;
	EndIf;
	
	MetadataObjectID      = Common.MetadataObjectID(ObjectMetadata);
	IndependentRegisterFilterValues = Undefined;
	RefToSource                    = Source.Ref;
	DeletionMarkNewValue        = Source.DeletionMark;
		
	SetPrivilegedMode(True);
	
	If DataExchangeCached.ExchangePlansInUse().Count() > 0
		AND (SafeMode() = False Or Users.IsFullUser()) Then
		
		BeginTransaction();
		Try
			
			Lock = New DataLock;
		
			LockItem = Lock.Add("InformationRegister.DataExchangeResults");
			LockItem.SetValue("IssueType", IssueType);
			If ValueIsFilled(InfobaseNode) Then
				LockItem.SetValue("InfobaseNode", InfobaseNode);				
			EndIf;
			LockItem.SetValue("MetadataObject", MetadataObjectID);				
			LockItem.SetValue("ObjectWithIssue", RefToSource);
			
			Lock.Lock();
			
			ConflictRecordSet = CreateRecordSet();
			ConflictRecordSet.Filter.IssueType.Set(IssueType);
			If ValueIsFilled(InfobaseNode) Then
				ConflictRecordSet.Filter.InfobaseNode.Set(InfobaseNode);			
			EndIf;
			ConflictRecordSet.Filter.MetadataObject.Set(MetadataObjectID);
			ConflictRecordSet.Filter.ObjectWithIssue.Set(RefToSource);
			
			ConflictRecordSet.Read();
			
			If ConflictRecordSet.Count() > 0 Then
				
				If DeletionMarkNewValue <> Common.ObjectAttributeValue(RefToSource, "DeletionMark") Then
					For Each ConflictRecord In ConflictRecordSet Do
						ConflictRecord.DeletionMark = DeletionMarkNewValue;
					EndDo;
					ConflictRecordSet.Write();
				Else
					ConflictRecordSet.Clear();
					ConflictRecordSet.Write();
				EndIf;
				
			EndIf;
			
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
		
	EndIf;
	
EndProcedure

Procedure RecordDocumentCheckError(ObjectWithIssue, InfobaseNode, Reason, IssueType) Export
	
	ObjectMetadata                   = ObjectWithIssue.Metadata();
	MetadataObjectID      = Common.MetadataObjectID(ObjectMetadata);
	Ref                              = Undefined;
	IndependentRegisterFilterValues = Undefined;
	
	If Common.IsRefTypeObject(ObjectMetadata) Then
		Ref = ObjectWithIssue;
	ElsIf Common.IsRegister(ObjectMetadata) Then
		
		If Common.IsInformationRegister(ObjectMetadata)
			AND ObjectMetadata.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.Independent Then
			
			IndependentRegisterFilterValues = New Structure();
			
			For Each FilterItem In ObjectWithIssue.Filter Do
				IndependentRegisterFilterValues.Insert(FilterItem.Name, FilterItem.Value);
			EndDo;
			
		Else
			Ref = ObjectWithIssue.Filter.Recorder.Value;
		EndIf;	
	Else
		Return;
	EndIf;
	
	ConflictRecordSet = CreateRecordSet();
	ConflictRecordSet.Filter.IssueType.Set(IssueType);
	ConflictRecordSet.Filter.InfobaseNode.Set(InfobaseNode);
	ConflictRecordSet.Filter.MetadataObject.Set(MetadataObjectID);
	ConflictRecordSet.Filter.ObjectWithIssue.Set(ObjectWithIssue);
	
	SerializedFiltersValues = Undefined;
	If IndependentRegisterFilterValues <> Undefined Then
		SerializedFiltersValues = SerializeFilterValues(IndependentRegisterFilterValues, ObjectMetadata);
		ConflictRecordSet.Filter.UniqueKey.Set(
			CalculateIndependentRegisterHash(SerializedFiltersValues));
	EndIf;
	
	ConflictRecord = ConflictRecordSet.Add();
	ConflictRecord.IssueType            = IssueType;
	ConflictRecord.InfobaseNode = InfobaseNode;
	ConflictRecord.MetadataObject       = MetadataObjectID;
	ConflictRecord.ObjectWithIssue       = Ref;
	ConflictRecord.OccurrenceDate      = CurrentSessionDate();
	ConflictRecord.Reason                = TrimAll(Reason);
	ConflictRecord.ObjectPresentation   = String(ObjectWithIssue); 
	ConflictRecord.Skipped              = False;
	
	If IndependentRegisterFilterValues <> Undefined Then
		ConflictRecord.UniqueKey = CalculateIndependentRegisterHash(SerializedFiltersValues);
		ConflictRecord.IndependentRegisterFilterValues = SerializedFiltersValues;
	EndIf;
	
	If Common.IsRefTypeObject(ObjectMetadata) Then
		
		If IssueType = Enums.DataExchangeIssuesTypes.UnpostedDocument Then
			
			If Ref.Metadata().NumberLength > 0 Then
				AttributesValues = Common.ObjectAttributesValues(ObjectWithIssue, "DeletionMark, Number, Date");
				ConflictRecord.DocumentNumber = AttributesValues.Number;
			Else
				AttributesValues = Common.ObjectAttributesValues(ObjectWithIssue, "DeletionMark, Date");
			EndIf;
			
			ConflictRecord.DocumentDate   = AttributesValues.Date;
			ConflictRecord.DeletionMark = AttributesValues.DeletionMark;
			
		Else
			
			ConflictRecord.DeletionMark = Common.ObjectAttributeValue(ObjectWithIssue, "DeletionMark");
			
		EndIf;
		
	EndIf;
	
	ConflictRecordSet.Write();
	
EndProcedure

Procedure ClearIssuesOnSend(InfobaseNodes = Undefined) Export

	IssuesTypes = New Array();
	IssuesTypes.Add(Enums.DataExchangeIssuesTypes.ConvertedObjectValidationError);
	IssuesTypes.Add(Enums.DataExchangeIssuesTypes.HandlersCodeExecutionErrorOnSendData);
	
	For Each Issue In IssuesTypes Do
		
		FilterFields = RegisterFiltersParameters();
		
		If ValueIsFilled(InfobaseNodes) Then
			
			If TypeOf(InfobaseNodes) = Type("Array") Then
				For Each InfobaseNode In InfobaseNodes Do
					
					FilterFields.IssueType            = Issue;
					FilterFields.InfobaseNode = InfobaseNode;
					ClearRegisterRecords(FilterFields);
					
				EndDo;
			Else
				
				FilterFields.IssueType            = Issue;
				FilterFields.InfobaseNode = InfobaseNodes;
				ClearRegisterRecords(FilterFields);
				
			EndIf;
			
		Else	
			FilterFields.IssueType = Issue;
			ClearRegisterRecords(FilterFields);
		EndIf;
	
	EndDo;
	
EndProcedure	

Procedure ClearIssuesOnGet(InfobaseNodes = Undefined) Export

	IssuesTypes = New Array();
	IssuesTypes.Add(Enums.DataExchangeIssuesTypes.HandlersCodeExecutionErrorOnGetData);
	
	For Each Issue In IssuesTypes Do
		
		FilterFields = RegisterFiltersParameters();
		
		If ValueIsFilled(InfobaseNodes) Then
			
			If TypeOf(InfobaseNodes) = Type("Array") Then
				For Each InfobaseNode In InfobaseNodes Do
					
					FilterFields.IssueType            = Issue;
					FilterFields.InfobaseNode = InfobaseNode;
					ClearRegisterRecords(FilterFields);
					
				EndDo;
			Else
				
				FilterFields.IssueType            = Issue;
				FilterFields.InfobaseNode = InfobaseNodes;
				ClearRegisterRecords(FilterFields);
				
			EndIf;
			
		Else	
			FilterFields.IssueType = Issue;
			ClearRegisterRecords(FilterFields);
		EndIf;
	
	EndDo;

EndProcedure	

Function IssueSearchParameters() Export
	
	Parameters = New Structure;
	Parameters.Insert("IssueType",                Undefined);
	Parameters.Insert("IncludingIgnored", False);
	Parameters.Insert("Period",                     Undefined);
	Parameters.Insert("ExchangePlanNodes",            Undefined);
	Parameters.Insert("SearchString",               "");
	Parameters.Insert("ObjectWithIssue",           Undefined);	
	
	Return Parameters;
	
EndFunction

Function IssuesCount(SearchParameters = Undefined) Export
	
	Quantity = 0;
	
	If SearchParameters = Undefined Then
		SearchParameters = IssueSearchParameters();
	EndIf;
	
	Query = New Query(
	"SELECT
	|	COUNT(DataExchangeResults.ObjectWithIssue) AS IssuesCount
	|FROM
	|	InformationRegister.DataExchangeResults AS DataExchangeResults
	|WHERE
	|	TRUE
	|	[FilterBySkipped]
	|	[FilterByExchangePlanNode]
	|	[FilterByProblemType]
	|	[FilterByPeriod]
	|	[FilterByReason]
	|	[FilterByObject]");

	// Filter by ignored issues.
	FIlterRow = "";
	IncludingIgnored = Undefined;
	If Not SearchParameters.Property("IncludingIgnored", IncludingIgnored)
		Or IncludingIgnored = False Then
		FIlterRow = "AND NOT DataExchangeResults.Skipped";
	EndIf;
	Query.Text = StrReplace(Query.Text, "[FilterBySkipped]", FIlterRow);
	
	// Filter by issue type.
	FIlterRow = "";
	IssueType = Undefined;
	If SearchParameters.Property("IssueType", IssueType)
		AND ValueIsFilled(IssueType) Then
		FIlterRow = "AND DataExchangeResults.IssueType IN (&ProblemType)";
		Query.SetParameter("ProblemType", IssueType);
	EndIf;
	Query.Text = StrReplace(Query.Text, "[FilterByProblemType]", FIlterRow);
	
	// Filter by exchange plan node.
	FIlterRow = "";
	ExchangePlanNodes = Undefined;
	If SearchParameters.Property("ExchangePlanNodes", ExchangePlanNodes) 
		AND ValueIsFilled(ExchangePlanNodes) Then
		FIlterRow = "AND DataExchangeResults.InfobaseNode IN (&ExchangeNodes)";
		Query.SetParameter("ExchangeNodes", SearchParameters.ExchangePlanNodes);
	EndIf;
	Query.Text = StrReplace(Query.Text, "[FilterByExchangePlanNode]", FIlterRow);
	
	// Filter by period.
	FIlterRow = "";
	Period = Undefined;
	If SearchParameters.Property("Period", Period) 
		AND ValueIsFilled(Period) Then
		FIlterRow = "AND (DataExchangeResults.OccurrenceDate >= &StartDate
		|		AND DataExchangeResults.OccurrenceDate <= &EndDate)";
		Query.SetParameter("StartDate",    SearchParameters.Period.StartDate);
		Query.SetParameter("EndDate", SearchParameters.Period.EndDate);
	EndIf;
	Query.Text = StrReplace(Query.Text, "[FilterByPeriod]", FIlterRow);
	
	// Filter by reason.
	FIlterRow = "";
	SearchString = Undefined;
	If SearchParameters.Property("SearchString", SearchString) 
		AND ValueIsFilled(SearchString) Then
		FIlterRow = "AND DataExchangeResults.Reason LIKE &Reason";
		Query.SetParameter("Reason", "%" + SearchString + "%");
	EndIf;
	Query.Text = StrReplace(Query.Text, "[FilterByReason]", FIlterRow);
	
	// Filter by obbject.
	FIlterRow = "";
	ObjectsWithIssues = Undefined;
	If SearchParameters.Property("ObjectsWithIssues", ObjectsWithIssues)
		AND ValueIsFilled(ObjectsWithIssues) Then
		FIlterRow = "AND DataExchangeResults.ObjectWithIssue IN (&ObjectsWithIssues)";
		Query.SetParameter("ObjectsWithIssues", ObjectsWithIssues);
	EndIf;
	Query.Text = StrReplace(Query.Text, "[FilterByObject]", FIlterRow);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Quantity = Selection.IssuesCount;
	EndIf;
	
	Return Quantity;
	
EndFunction

#EndRegion

#Region Private

Function SerializeFilterValues(FilterParameters, ObjectMetadata)
	
	RecordSet = RegisterRecordSetByFilterParameters(FilterParameters, ObjectMetadata);
	
	XMLWriter = New XMLWriter;
	XMLWriter.SetString();
    WriteXML(XMLWriter, RecordSet);
	
	Return XMLWriter.Close();

EndFunction

Function CalculateIndependentRegisterHash(SerializedFilterValues)
	
	MD5FilterHash = New DataHashing(HashFunction.MD5);
	MD5FilterHash.Append(SerializedFilterValues);
	
	FilterHashsum = MD5FilterHash.HashSum;
	FilterHashsum = StrReplace(FilterHashsum, " ", "");
	
	Return FilterHashsum;

EndFunction

Function RegisterFiltersParameters()
	
	FilterFields = New Structure();
	FilterFields.Insert("IssueType",            Enums.DataExchangeIssuesTypes.EmptyRef());
	FilterFields.Insert("InfobaseNode", Undefined);
	FilterFields.Insert("MetadataObject",       Catalogs.MetadataObjectIDs.EmptyRef());
	FilterFields.Insert("ObjectWithIssue",       Undefined);
	FilterFields.Insert("UniqueKey",       "");
	
	Return FilterFields;
	
EndFunction

Procedure Ignore(Ref, IssueType, Ignore, InfobaseNode = Undefined) Export
	
	ObjectMetadata              = Ref.Metadata();
	MetadataObjectID = Common.MetadataObjectID(ObjectMetadata);
	
	ConflictRecordSet = CreateRecordSet();
	ConflictRecordSet.Filter.ObjectWithIssue.Set(Ref);
	ConflictRecordSet.Filter.IssueType.Set(IssueType);
	ConflictRecordSet.Filter.MetadataObject.Set(MetadataObjectID);	
	
	If ValueIsFilled(InfobaseNode) Then
		ConflictRecordSet.Filter.InfobaseNode.Set(InfobaseNode);	
	EndIf;
	
	ConflictRecordSet.Read();
	ConflictRecordSet[0].Skipped = Ignore;
	ConflictRecordSet.Write();
	
EndProcedure

Function RegisterRecordSetByFilterParameters(FilterParameters, ObjectMetadata)
	
	RecordSet = Common.ObjectManagerByFullName(ObjectMetadata.FullName()).CreateRecordSet();
	
	For Each FilterItem In RecordSet.Filter Do
		FilterValue = Undefined;
		If FilterParameters.Property(FilterItem.Name, FilterValue) Then
			FilterItem.Set(FilterValue);
		EndIf;
	EndDo;	
	
	Return RecordSet;
	
EndFunction

Procedure ClearRegisterRecords(FilterParameters)
	
	ConflictRecordSet = RegisterRecordSetByFilterParameters(FilterParameters, Metadata.InformationRegisters.DataExchangeResults);
	ConflictRecordSet.Write();
	
EndProcedure

#EndRegion

#EndIf