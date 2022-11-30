
&AtClient
Procedure StatusRoom(Command)
	OpenForm("Catalog.HotelRooms.Form.HotelRoomsStatus");
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	SetCapacityShow();
	GetCapacity();
EndProcedure

Procedure SetCapacityShow()
	Hotel = Catalogs.HotelRooms.Select(); 
	While Hotel.Next() Do
		HotelObj = Hotel.GetObject();
		HotelObj.CapacityShow = String(HotelObj.Used) + "/"+String(HotelObj.Capacity); 
		HotelObj.Write();
	EndDo
EndProcedure

Procedure GetCapacity()
	Hotel = Catalogs.HotelRooms.Select(); 
	While Hotel.Next() Do
		HotelObj = Hotel.GetObject();
		HotelObj.Used = 0;
		HotelObj.CapacityShow = String(HotelObj.Used) + "/"+String(HotelObj.Capacity);
		HotelObj.Status = Enums.RoomStatus.Available;
		HotelObj.Write();
	EndDo;
	
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	COUNT(HotelBookingHistory.Room) AS Quantity,
	|	HotelBookingHistory.Room AS NameRoom
	|FROM
	|	InformationRegister.HotelBookingHistory AS HotelBookingHistory
	|WHERE
	|	HotelBookingHistory.EndTime >= &CurrentDate
	|
	|GROUP BY
	|	HotelBookingHistory.Room";
	
	Query.SetParameter("CurrentDate", CurrentDate());
	
	Result = Query.Execute();
	
	Selection = Result.Select();
	
	While Selection.Next() Do
		ObjRoom = Selection.NameRoom.GetObject();
		If Selection.Quantity = ObjRoom.Capacity Then
			ObjRoom.Status = Enums.RoomStatus.Full;
		Else
			ObjRoom.Status = Enums.RoomStatus.InUsed;
		EndIf;
		ObjRoom.Used = Selection.Quantity;
		ObjRoom.CapacityShow = String(ObjRoom.Used)+"/"+String(ObjRoom.Capacity);
		ObjRoom.Write();	
	EndDo;
EndProcedure

&AtClient
Procedure CapacityOnChange(Item)
EndProcedure

&AtClient
Procedure Reload(Command)
	SetCapacityShow();
	GetCapacity();

EndProcedure
