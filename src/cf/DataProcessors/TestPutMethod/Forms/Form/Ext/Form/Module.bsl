
&AtServer
Procedure PutAtServer2()
	// Insert handler content.
	Query = New Query;
	//DogCode = Request.QueryOptions.Get("Code");
	//Dog = Catalogs.Dogs.FindByCode("0000000001");
	Query.SetParameter("Code", "0000000001");
	Query.SetParameter("EmptyValue", Null);
	
	Query.Text = "SELECT
	             |	DogTracking.Ref AS Ref,
	             |	DogTracking.Date AS Date,
	             |	DogTracking.DogOwner AS DogOwner,
	             |	DogTracking.Dog AS Dog,
	             |	DogTracking.EndTime AS EndTime,
	             |	DogTracking.StartTime AS StartTime,
	             |	DogTracking.Purpose AS Purpose,
	             |	DogTracking.Number AS Number
	             |FROM
	             |	Document.DogTracking AS DogTracking
	             |WHERE
	             |	DogTracking.Dog.Code = &Code";
	
	Result = Query.Execute();
	CheckinData = Result.Unload();
	
	For Each Row in CheckinData Do
		If ValueIsFilled(Row.StartTime) And
			Not ValueIsFilled(Row.EndTime) Then
			DocumentObject = Row.Ref.GetObject();
			DocumentObject.EndTime = CurrentDate();
			DocumentObject.Write();
		EndIf;
	EndDo;
EndProcedure

&AtServer
Function PutAtServer()
	Code = "000000002";
	
	If Catalogs.Employees.FindByCode(Code) = 
		Catalogs.Employees.EmptyRef() Then
	Else
		//Normal Flow
		Query = New Query;
		Query.Text = "SELECT
		             |	DayCare.Period AS Period,
		             |	DayCare.Dog AS Dog,
		             |	DayCare.Customer AS Customer,
		             |	DayCare.CheckIn AS CheckIn,
		             |	DayCare.CheckOut AS CheckOut,
		             |	DayCare.Staff AS Staff,
		             |	DayCare.Package AS Package,
		             |	DayCare.PackageTime AS PackageTime,
		             |	DayCare.Pickup AS Pickup
		             |FROM
		             |	InformationRegister.DayCare AS DayCare
		             |WHERE
		             |	DayCare.Staff.Code = &Code
		             |	AND DayCare.CheckIn BETWEEN BEGINOFPERIOD(&Date, DAY) AND ENDOFPERIOD(&Date, DAY)";
		
		Query.SetParameter("Code", Code);
		Query.SetParameter("Date", Date);
		
		Result = Query.Execute();
		Selection = Result.Unload();
	EndIf; 
EndFunction

&AtClient
Procedure Put(Command)
	PutAtServer();
EndProcedure

&AtServer
Procedure CheckingStatusCheckAtServer()
Query = New Query;
		
	Query.Text = 
		"SELECT TOP 1
		|	TrackingHistorySliceLast.CheckIn AS CheckIn,
		|	TrackingHistorySliceLast.Dog AS Dog,
		|	TrackingHistorySliceLast.CheckOut AS CheckOut
		|FROM
		|	InformationRegister.TrackingHistory.SliceLast AS TrackingHistorySliceLast
		|WHERE
		|	TrackingHistorySliceLast.Dog = &Dog
		|
		|ORDER BY
		|	CheckIn DESC";
	
	Dog = Catalogs.Dogs.FindByCode("0000000008");
	Query.SetParameter("Dog", Dog);
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	Data = New Structure;
	CheckIn = True;
	CheckOut=False;
	TimeCheckIn=Undefined;
	
	While Selection.Next() Do
		If ValueIsFilled(Selection.CheckOut)=False Then
		    CheckIn = False;
			CheckOut = True
			EndIf; 
		Time = String(Selection.CheckIn);
	EndDo;
	Data.Insert("CheckIn",CheckIn);
	Data.Insert("CheckOut",CheckOut);
	Data.Insert("TimeCheckIn",Time);
	//Return Data;
	// Insert handler content.
EndProcedure

&AtClient
Procedure CheckingStatusCheck(Command)
	CheckingStatusCheckAtServer();
EndProcedure

&AtServer
Procedure TestUpdateDocumentAtServer()
	// Insert handler content.
	If FullTextSearch.GetFullTextSearchMode() = FullTextSearchMode.Enable Then
		Documents.DogTracking.GetListForm("ListForm").IsOpen();	
	EndIf;
EndProcedure

&AtClient
Procedure TestUpdateDocument(Command)
	TestUpdateDocumentAtServer();
EndProcedure

&AtServer
Procedure NewWriteProcessingAtServer()
	// Insert handler content.
EndProcedure

&AtClient
Procedure NewWriteProcessing(NewObject, Source, StandardProcessing)
	NewWriteProcessingAtServer();
EndProcedure

&AtServer
Procedure TestBreedAtServer()
	Query = New Query;
	Query.Text = "SELECT
	             |	Dogs.Code AS Code,
	             |	Dogs.DogBreed AS DogBreed,
	             |	1 AS Frequency
	             |FROM
	             |	Catalog.Dogs AS Dogs";
	
	Result = Query.Execute();
	Selection = Result.Unload();
	
	FrequencyList = New ValueTable();
	FrequencyList.Columns.Add("DogBreed",,,);
	FrequencyList.Columns.Add("Frequency",,,);
	
	For Each Row In Selection Do
		If FrequencyList.Find(Row.DogBreed, "DogBreed") <> Undefined Then
			FrequencyList.Find(Row.DogBreed, "DogBreed").Frequency = 
			FrequencyList.Find(Row.DogBreed, "DogBreed").Frequency + 1;
		Else
			NewRow = FrequencyList.Add();
			NewRow.DogBreed = Row.DogBreed;
			NewRow.Frequency = 1;
		EndIf;
	EndDo;
			
EndProcedure

&AtClient
Procedure TestBreed(Command)
	TestBreedAtServer();
EndProcedure

&AtServer
Procedure TestAtServer()
	DogsRef = Catalogs.Dogs.FindByCode(DogCode);
EndProcedure

&AtClient
Procedure Test(Command)
	TestAtServer();
EndProcedure
