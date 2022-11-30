
Procedure Posting(Cancel, Mode)
	//{{__REGISTER_REGISTERRECORDS_WIZARD
	// This fragment was built by the wizard.
	// Warning! All manually made changes will be lost next time you use the wizard.

	// register SpaBookingHistory
	RegisterRecords.SpaBookingHistory.Write = True;
	For Each CurRowDogList In DogList Do
		Record = RegisterRecords.SpaBookingHistory.Add();
		Record.Period = Date;
		Record.DogOwner = Owner;
		Record.Dog = CurRowDogList.Dog;
		Record.Room = CurRowDogList.Room;
		Record.Veterinarian = Employee;
		Record.Service = CurRowDogList.Service;
		Record.EndTime = EndTime;
		Record.StartTime = StartTime;
		Record.Duration = Duration;
	EndDo;

	//}}__REGISTER_REGISTERRECORDS_WIZARD
EndProcedure
