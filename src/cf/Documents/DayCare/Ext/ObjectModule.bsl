
Procedure Posting(Cancel, Mode)
	//{{__REGISTER_REGISTERRECORDS_WIZARD
	// This fragment was built by the wizard.
	// Warning! All manually made changes will be lost next time you use the wizard.

	// register DayCare
	RegisterRecords.DayCare.Write = True;
	Record = RegisterRecords.DayCare.Add();
	Record.Period = Date;
	Record.Dog = Dog;
	Record.Customer = Owner;
	Record.CheckIn = StartTime;
	Record.CheckOut = EndTime;
	Record.Driver = Driver;
	Record.DogSize = DogSize;
	Record.Staff = Employees;
	Record.Package = Package;
	Record.PackageTime = PackageTime;
	Record.Pickup = PickUp;
	Record.City = City;
	Record.District = District;
	Record.Ward = Ward;
	Record.Street = Street;
	Record.AddressNumber = AddressNumber;
	Record.PickupTime = TimePickup;
	Record.Price = Price;

	//}}__REGISTER_REGISTERRECORDS_WIZARD
EndProcedure
