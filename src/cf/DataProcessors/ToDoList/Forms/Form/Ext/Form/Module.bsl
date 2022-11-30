#Region Yennn 
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	Object.Date =  CurrentDate();
	RunToDoList();
EndProcedure

Procedure RunToDoList()
	GetDataInjection();
	GetDataLouseDogTreatment();
	GetDataHealStatus();
	GetDataHoltelBooking();
	GetDataSpaBooking();
	GetDataDayCare();
	
	Object.List.Sort("Time Asc");
	
EndProcedure

Procedure GetDataInjection()
	
	Date = Object.Date;
	Veterinarian = Object.Veterinarian;	
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	InjectionHistory.Dog AS Dog,
		|	InjectionHistory.Owner AS Owner,
		|	InjectionHistory.Veterinarian AS Veterinarian,
		|	InjectionHistory.Date AS Date
		|FROM
		|	InformationRegister.InjectionHistory AS InjectionHistory
		|WHERE
		|	InjectionHistory.Date BETWEEN BEGINOFPERIOD(&Date, DAY) AND ENDOFPERIOD(&Date, DAY)
		|	AND CASE
		|			WHEN &Veterinarian = &EmptyValue OR &Veterinarian = &EmptyRefVer OR &Veterinarian = &EmptyRefEmployee
		|				THEN TRUE
		|			ELSE InjectionHistory.Veterinarian = &Veterinarian
		|		END";
	
	Query.SetParameter("Date", Date);
	Query.SetParameter("EmptyRefVer", Catalogs.Veterinarians.EmptyRef());
	Query.SetParameter("EmptyRefEmployee", Catalogs.Employees.EmptyRef());
	Query.SetParameter("Veterinarian", Veterinarian);
	Query.SetParameter("EmptyValue", Undefined);
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		NewLine = Object.List.Add();
		NewLine.Time = Selection.Date;
		NewLine.Work ="Injection";
		NewLine.Veterinarian = Selection.Veterinarian;
		NewLine.Dog = Selection.Dog;
		NewLine.Owner = Selection.Owner;
	EndDo;
	
EndProcedure

Procedure GetDataLouseDogTreatment()
	Date = Object.Date;
	Veterinarian = Object.Veterinarian;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	LouseDogTreatment.Dog AS Dog,
	|	LouseDogTreatment.Owner AS Owner,
	|	LouseDogTreatment.Veterinarian AS Veterinarian,
	|	LouseDogTreatment.Date AS Date
	|FROM
	|	InformationRegister.LouseDogTreatment AS LouseDogTreatment
	|WHERE
	|	LouseDogTreatment.Date BETWEEN BEGINOFPERIOD(&Date, DAY) AND ENDOFPERIOD(&Date, DAY)
	|	AND CASE
	|			WHEN &Veterinarian = &EmptyValue OR &Veterinarian = &EmptyRefVer OR &Veterinarian = &EmptyRefEmployee
	|				THEN TRUE
	|			ELSE LouseDogTreatment.Veterinarian = &Veterinarian
	|		END";
	
	
	Query.SetParameter("Date", Date);
	Query.SetParameter("EmptyRefVer", Catalogs.Veterinarians.EmptyRef());
	Query.SetParameter("EmptyRefEmployee", Catalogs.Employees.EmptyRef());
	Query.SetParameter("Veterinarian", Veterinarian);
	Query.SetParameter("EmptyValue", Undefined);
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		NewLine = Object.List.Add();
		NewLine.Time = Selection.Date;
		NewLine.Work ="Louse dog treatment";
		NewLine.Veterinarian = Selection.Veterinarian;
		NewLine.Dog = Selection.Dog;
		NewLine.Owner = Selection.Owner;

	EndDo;

	
EndProcedure

Procedure GetDataHealStatus()
	Date = Object.Date;
	Veterinarian = Object.Veterinarian;	
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	HealthStatuses.Dog AS Dog,
	|	HealthStatuses.Owner AS Owner,
	|	HealthStatuses.Veterinarian AS Veterinarian,
	|	HealthStatuses.StartTime AS StartTime
	|FROM
	|	InformationRegister.HealthStatuses AS HealthStatuses
	|WHERE
	|	HealthStatuses.StartTime BETWEEN BEGINOFPERIOD(&Date, DAY) AND ENDOFPERIOD(&Date, DAY)
	|	AND CASE
	|		WHEN &Veterinarian = &EmptyValue OR &Veterinarian = &EmptyRefVer OR &Veterinarian = &EmptyRefEmployee
	|				THEN TRUE
	|			ELSE HealthStatuses.Veterinarian = &Veterinarian
	|		END";
	
	Query.SetParameter("Date", Date);
	Query.SetParameter("EmptyRefVer", Catalogs.Veterinarians.EmptyRef());
	Query.SetParameter("EmptyRefEmployee", Catalogs.Employees.EmptyRef());
	Query.SetParameter("Veterinarian", Veterinarian);
	Query.SetParameter("EmptyValue", Undefined);
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		NewLine = Object.List.Add();
		NewLine.Time = Selection.StartTime;
		NewLine.Work ="Dog health care";
		NewLine.Veterinarian = Selection.Veterinarian;
		NewLine.Dog = Selection.Dog;
		NewLine.Owner = Selection.Owner;
		
	EndDo;
	
EndProcedure

Procedure GetDataHoltelBooking()
	Date = Object.Date;
	Veterinarian = Object.Veterinarian;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	HotelBookingHistory.Dog AS Dog,
	|	HotelBookingHistory.DogOwner AS DogOwner,
	|	HotelBookingHistory.Veterinarian AS Veterinarian,
	|	HotelBookingHistory.StartTime AS StartTime
	|FROM
	|	InformationRegister.HotelBookingHistory AS HotelBookingHistory
	|WHERE
	|	HotelBookingHistory.StartTime BETWEEN BEGINOFPERIOD(&Date, DAY) AND ENDOFPERIOD(&Date, DAY)
	|	AND CASE
	|			WHEN &Veterinarian = &EmptyValue OR &Veterinarian = &EmptyRefVer OR &Veterinarian = &EmptyRefEmployee
	|				THEN TRUE
	|			ELSE HotelBookingHistory.Veterinarian = &Veterinarian
	|		END";
	
	Query.SetParameter("Date", Date);
	Query.SetParameter("EmptyRefVer", Catalogs.Veterinarians.EmptyRef());
	Query.SetParameter("EmptyRefEmployee", Catalogs.Employees.EmptyRef());
	Query.SetParameter("Veterinarian", Veterinarian);
	Query.SetParameter("EmptyValue",Undefined);
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		NewLine = Object.List.Add();
		NewLine.Time = Selection.StartTime;
		NewLine.Work ="Hotel service";
		NewLine.Veterinarian = Selection.Veterinarian;
		NewLine.Dog = Selection.Dog;
		NewLine.Owner = Selection.DogOwner;
	EndDo;
		
EndProcedure

Procedure GetDataSpaBooking()
	Date = Object.Date;
	Veterinarian = Object.Veterinarian;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	SpaBookingHistory.Dog AS Dog,
	|	SpaBookingHistory.DogOwner AS DogOwner,
	|	SpaBookingHistory.Veterinarian AS Veterinarian,
	|	SpaBookingHistory.StartTime AS StartTime
	|FROM
	|	InformationRegister.SpaBookingHistory AS SpaBookingHistory
	|WHERE
	|	SpaBookingHistory.StartTime BETWEEN BEGINOFPERIOD(&Date, DAY) AND ENDOFPERIOD(&Date, DAY)
	|	AND CASE
	|			WHEN &Veterinarian = &EmptyValue OR &Veterinarian = &EmptyRefVer OR &Veterinarian = &EmptyRefEmployee
	|				THEN TRUE
	|			ELSE SpaBookingHistory.Veterinarian = &Veterinarian
	|		END";
	
	Query.SetParameter("Date", Date);
	Query.SetParameter("EmptyRefVer", Catalogs.Veterinarians.EmptyRef());
	Query.SetParameter("EmptyRefEmployee", Catalogs.Employees.EmptyRef());
	Query.SetParameter("Veterinarian", Veterinarian);
	Query.SetParameter("EmptyValue",Undefined);
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		NewLine = Object.List.Add();
		NewLine.Time = Selection.StartTime;
		NewLine.Work ="Spa service";
		NewLine.Veterinarian = Selection.Veterinarian;
		NewLine.Dog = Selection.Dog;
		NewLine.Owner = Selection.DogOwner;
		
	EndDo;
	
EndProcedure

Procedure GetDataDayCare()
	Date = Object.Date;
	Veterinarian = Object.Veterinarian;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	DayCare.Dog AS Dog,
	|	DayCare.Customer AS Customer,
	|	DayCare.Staff AS Staff,
	|	DayCare.Period AS Period
	|FROM
	|	InformationRegister.DayCare AS DayCare
	|WHERE
	|	DayCare.Period BETWEEN BEGINOFPERIOD(&Date, DAY) AND ENDOFPERIOD(&Date, DAY)
	|	AND CASE
	|			WHEN &Veterinarian = &EmptyValue OR &Veterinarian = &EmptyRefVer OR &Veterinarian = &EmptyRefEmployee
	|				THEN TRUE
	|			ELSE DayCare.Staff = &Veterinarian
	|		END";

	Query.SetParameter("Date", Date);
	Query.SetParameter("EmptyRefVer", Catalogs.Veterinarians.EmptyRef());
	Query.SetParameter("EmptyRefEmployee", Catalogs.Employees.EmptyRef());
	Query.SetParameter("Veterinarian", Veterinarian);
	Query.SetParameter("EmptyValue",Undefined);

	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		NewLine = Object.List.Add();
		NewLine.Time = Selection.Period;
		NewLine.Work ="Day Care Service";
		NewLine.Veterinarian = Selection.Staff;
		NewLine.Dog = Selection.Dog;
		NewLine.Owner = Selection.Customer;
	EndDo;
	
	//}}QUERY_BUILDER_WITH_RESULT_PROCESSING

EndProcedure

&AtClient
Procedure Reload(Command)
	Object.List.Clear();
	RunToDoList();
EndProcedure
#EndRegion