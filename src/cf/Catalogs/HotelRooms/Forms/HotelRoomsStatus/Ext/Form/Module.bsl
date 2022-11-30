
&AtClient
Procedure Generate(Command)
	GenerateAtServer();
EndProcedure

&AtServer
Procedure GenerateAtServer()
	If ValueIsFilled(StartDate) then
		If not ValueIsFilled(EndDate) then
			EndDate = StartDate;
		Endif;
		Room.GetItems().Clear();
		Query = New Query;
		Query.Text = 
		"SELECT
		|	HotelBookingHistory.StartTime AS StartTime,
		|	HotelBookingHistory.EndTime AS EndTime,
		|	HotelBookingHistory.Room AS Room,
		|	COUNT(DISTINCT HotelRooms.Description) AS Description
		|FROM
		|	InformationRegister.HotelBookingHistory AS HotelBookingHistory
		|		LEFT JOIN Catalog.HotelRooms AS HotelRooms
		|		ON HotelBookingHistory.Room = HotelRooms.Ref
		|WHERE
		|	(&StartDate BETWEEN HotelBookingHistory.StartTime AND HotelBookingHistory.EndTime
		|				AND (&EndDate BETWEEN HotelBookingHistory.StartTime AND HotelBookingHistory.EndTime)
		|			OR HotelBookingHistory.StartTime = &StartDate
		|			OR HotelBookingHistory.EndTime = &EndDate)
		|	OR HotelBookingHistory.EndTime BETWEEN &StartDate AND &EndDate
		|
		|GROUP BY
		|	HotelBookingHistory.StartTime,
		|	HotelBookingHistory.EndTime,
		|	HotelBookingHistory.Room";
		
		Query.SetParameter("StartDate", StartDate);
		Query.SetParameter("EndDate", EndDate);
		
		QueryResult = Query.Execute();
		
		SelectionDetailRecords = QueryResult.Select();
		PendingRoomCount = 0;
		PendingArr = new Array();
		Pending = Room.GetItems().Add();
		Pending.RoomKinds = "Pending rooms";
		While SelectionDetailRecords.Next() Do
			If PendingArr.Find(SelectionDetailRecords.Room)=undefined then
				PendingRoom = Pending.GetItems().Add();
				PendingRoom.RoomKinds = SelectionDetailRecords.Room;
				PendingRoom.Type = SelectionDetailRecords.Room.Type;
				PendingRoom.Price = SelectionDetailRecords.Room.Price;
				PendingRoomCount = PendingRoomCount+1;
				PendingArr.Add(SelectionDetailRecords.Room);
			Endif;
		EndDo;
		
		Pending.quantity = PendingRoomCount;
		
		Query = New Query;
		Query.Text = 
		"SELECT
		|	COUNT(DISTINCT HotelRooms.Ref) AS Ref,
		|	HotelRooms.Ref AS Ref1
		|FROM
		|	Catalog.HotelRooms AS HotelRooms
		|
		|GROUP BY
		|	HotelRooms.Ref";
		
		QueryResult = Query.Execute();
		
		SelectionDetailRecords = QueryResult.Select();
		Available = 0;
		AvailableRow = Room.GetItems().Add();
		AvailableRow.Roomkinds = "Available rooms";
		While SelectionDetailRecords.Next() Do
			Available = Available+1;
			If PendingArr.Find(SelectionDetailRecords.Ref1)=undefined then
				AvailableRoom = AvailableRow.GetItems().Add();
				AvailableRoom.RoomKinds = SelectionDetailRecords.Ref1;
				AvailableRoom.Type = SelectionDetailRecords.Ref1.Type;
				AvailableRoom.Price = SelectionDetailRecords.Ref1.Price;
				
				AvailableRoom.Quantity = "";
			Endif;
		EndDo;
		AvailableRow.Quantity = Available -PendingRoomCount; 
	Else 
		Message("Start date can not be empty! ",MessageStatus.VeryImportant);
	EndIf;
EndProcedure
