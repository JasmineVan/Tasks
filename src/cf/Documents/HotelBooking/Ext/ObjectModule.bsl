
Procedure Posting(Cancel, Mode)
	RegisterRecords.HotelBookingHistory.Write = True;
	For Each CurRowDogList In DogList Do
		Record = RegisterRecords.HotelBookingHistory.Add();
		Record.Period = Date;
		Record.DogOwner = Owner;
		Record.Dog = CurRowDogList.Dog;
		Record.Room = CurRowDogList.Room;		
		
		Record.Veterinarian = Employee;
		Record.EndTime = EndTime;
		Record.StartTime = StartTime;
		Record.Duration = Duration;
	EndDo;
EndProcedure


