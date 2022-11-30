
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
		SpaRoom.GetItems().Clear();
		Query = New Query;
		Query.Text = 
		"SELECT
		|	COUNT(DISTINCT SpaRooms.Description) AS Description,
		|	SpaBookingHistory.Room AS Room,
		|	SpaBookingHistory.StartTime AS StartTime,
		|	SpaBookingHistory.EndTime AS EndTime,
		|	COUNT(SpaBookingHistory.Service) AS ServiceCount,
		|	SpaBookingHistory.Service AS Service,
		|	SpaRooms.Price AS Price
		|FROM
		|	InformationRegister.SpaBookingHistory AS SpaBookingHistory
		|		LEFT JOIN Catalog.SpaRooms AS SpaRooms
		|		ON SpaBookingHistory.Room = SpaRooms.Ref
		|WHERE
		|	(&StartDate BETWEEN SpaBookingHistory.StartTime AND SpaBookingHistory.EndTime
		|				AND (&EndDate BETWEEN SpaBookingHistory.StartTime AND SpaBookingHistory.EndTime)
		|			OR SpaBookingHistory.StartTime = &StartDate
		|			OR SpaBookingHistory.EndTime = &EndDate
		|			OR SpaBookingHistory.EndTime BETWEEN &StartDate AND &EndDate)
		|
		|GROUP BY
		|	SpaBookingHistory.Room,
		|	SpaBookingHistory.StartTime,
		|	SpaBookingHistory.EndTime,
		|	SpaBookingHistory.Service,
		|	SpaRooms.Price";
		
		Query.SetParameter("StartDate", StartDate);
		Query.SetParameter("EndDate", EndDate);
		
		QueryResult = Query.Execute();
		
		SelectionDetailRecords = QueryResult.Select();
		PendingServices = 0;
		PendingArr = new Array();
		Pending = SpaRoom.GetItems().Add();
		Pending.ServiceKinds = "Pending services";
		While SelectionDetailRecords.Next() Do
			If PendingArr.Find(SelectionDetailRecords.Service)=undefined then
				PendingServices = PendingServices + SelectionDetailRecords.ServiceCount;
				PendingArr.Add(SelectionDetailRecords.Service);
				ReservedService = Pending.GetItems().Add();
				ReservedService.ServiceKinds = SelectionDetailRecords.Service;
				ReservedService.Price = SelectionDetailRecords.Service.Price;
				ReservedService.Quantity = SelectionDetailRecords.ServiceCount;
			Endif;
		EndDo;
		Pending.quantity = PendingServices;
	Else 
		Message("Start date can not be empty! ",MessageStatus.VeryImportant);
	EndIf;
EndProcedure
