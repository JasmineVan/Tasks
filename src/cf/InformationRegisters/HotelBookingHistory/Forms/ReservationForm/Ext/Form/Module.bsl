
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	CheckinDate = CurrentDate();
	FillReservationForm();
EndProcedure

&AtServer
Procedure FillReservationForm()
	
	Var NewRow, Query, QueryResult, SelectionDetailRecords;
	ReservedRooms.Clear();
	Query = New Query;
	Query.Text = 
	"SELECT
	|	HotelBookingHistory.Room AS Room,
	|	HotelBookingHistory.StartTime AS StartTime,
	|	HotelBookingHistory.EndTime AS EndTime,
	|	HotelBookingHistory.DogOwner AS DogOwner,
	|	HotelBookingHistory.Dog AS Dog
	|FROM
	|	InformationRegister.HotelBookingHistory AS HotelBookingHistory";
	
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	
	While SelectionDetailRecords.Next() Do
		NewRow = ReservedRooms.Add();
		NewRow.Room = SelectionDetailRecords.Room;
		NewRow.Customer = SelectionDetailRecords.DogOwner;
		NewRow.Dog = SelectionDetailRecords.Dog;
		NewRow.Checkin = SelectionDetailRecords.StartTime;
		NewRow.CheckOut = SelectionDetailRecords.EndTime;
	EndDo;

EndProcedure

&AtClient
Procedure Check(Command)
	CheckAtServer();
EndProcedure

&AtServer
Procedure CheckAtServer()
	ReservedRooms.Clear();
	If ValueIsFilled(CheckinDate) and ValueIsFilled(Room) then
		
		Query = New Query;
		Query.Text = 
		"SELECT
		|	HotelBookingHistory.Room AS Room,
		|	HotelBookingHistory.Dog AS Dog,
		|	HotelBookingHistory.DogOwner AS DogOwner,
		|	HotelBookingHistory.EndTime AS EndTime,
		|	HotelBookingHistory.StartTime AS StartTime
		|FROM
		|	InformationRegister.HotelBookingHistory AS HotelBookingHistory
		|WHERE
		|	HotelBookingHistory.Room = &Room
		|	AND &CheckinDate BETWEEN HotelBookingHistory.StartTime AND HotelBookingHistory.EndTime";
		
		Query.SetParameter("CheckinDate", CheckinDate);
		Query.SetParameter("Room", Room);
		QueryResult = Query.Execute();
		
		SelectionDetailRecords = QueryResult.Select();
		
		While SelectionDetailRecords.Next() Do
			NewRow = ReservedRooms.Add();
			NewRow.Room = SelectionDetailRecords.Room;
			NewRow.Customer = SelectionDetailRecords.DogOwner;
			NewRow.Dog = SelectionDetailRecords.Dog;
			NewRow.Checkin = SelectionDetailRecords.StartTime;
			NewRow.CheckOut = SelectionDetailRecords.EndTime;
		EndDo;
	Elsif ValueIsFilled(CheckinDate) then
		 	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	HotelBookingHistory.Dog AS Dog,
		|	HotelBookingHistory.DogOwner AS DogOwner,
		|	HotelBookingHistory.Room AS Room,
		|	HotelBookingHistory.StartTime AS StartTime,
		|	HotelBookingHistory.EndTime AS EndTime
		|FROM
		|	InformationRegister.HotelBookingHistory AS HotelBookingHistory
		|WHERE
		|	&CheckinDate BETWEEN HotelBookingHistory.StartTime AND HotelBookingHistory.EndTime";
	
	Query.SetParameter("CheckinDate", CheckinDate);
	
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	
	While SelectionDetailRecords.Next() Do
		NewRow = ReservedRooms.Add();
		NewRow.Room = SelectionDetailRecords.Room;
		NewRow.Customer = SelectionDetailRecords.DogOwner;
		NewRow.Dog = SelectionDetailRecords.Dog;
		NewRow.Checkin = SelectionDetailRecords.StartTime;
		NewRow.CheckOut = SelectionDetailRecords.EndTime;
	EndDo;
Elsif ValueIsFilled(Room) then
	Query = New Query;
	Query.Text = 
		"SELECT
		|	HotelBookingHistory.Dog AS Dog,
		|	HotelBookingHistory.DogOwner AS DogOwner,
		|	HotelBookingHistory.Room AS Room,
		|	HotelBookingHistory.EndTime AS EndTime,
		|	HotelBookingHistory.StartTime AS StartTime
		|FROM
		|	InformationRegister.HotelBookingHistory AS HotelBookingHistory
		|WHERE
		|	HotelBookingHistory.Room = &Room";
	
	Query.SetParameter("Room", Room);
	
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	
	While SelectionDetailRecords.Next() Do
		NewRow = ReservedRooms.Add();
		NewRow.Room = SelectionDetailRecords.Room;
		NewRow.Customer = SelectionDetailRecords.DogOwner;
		NewRow.Dog = SelectionDetailRecords.Dog;
		NewRow.Checkin = SelectionDetailRecords.StartTime;
		NewRow.CheckOut = SelectionDetailRecords.EndTime;
	EndDo;
	
	Else FillReservationForm();	
	Endif;
EndProcedure
