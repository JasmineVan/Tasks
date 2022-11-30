Procedure Posting(Cancel, Mode)
	//{{__REGISTER_REGISTERRECORDS_WIZARD
	// This fragment was built by the wizard.
	// Warning! All manually made changes will be lost next time you use the wizard.

	// register InjectionHistory
	RegisterRecords.InjectionHistory.Write = True;
	For Each CurRowInjectionHistory In InjectionHistory Do
		Record = RegisterRecords.InjectionHistory.Add();
		Record.Period = Date;
		Record.Dog = Dog;
		Record.Owner = DogOwner;
		Record.Veterinarian = CurRowInjectionHistory.Veterinarian;
		Record.Date = Date;
		Record.VaccineLabel = CurRowInjectionHistory.Vaccine;
		Record.Weight = Weight;
		Record.Disease = CurRowInjectionHistory.Disease;
		Record.NextVaccination = CurRowInjectionHistory.NextVaccination;
	EndDo;

	// register HealthStatuses
	RegisterRecords.HealthStatuses.Write = True;
	For Each CurRowHealthStatus In HealthStatus Do
		Record = RegisterRecords.HealthStatuses.Add();
		Record.Period = Date;
		Record.Dog = Dog;
		Record.Date = Date;
		Record.Owner = DogOwner;
		Record.StartTime = StartTime;
		Record.EndTime = EndTime;
		Record.Veterinarian = CurRowHealthStatus.Veterinarian;
		Record.Disease = CurRowHealthStatus.Disease;
		Record.Weight = Weight;
		Record.IsCured = CurRowHealthStatus.IsCured;
		Record.Purpose = Purpose;
	EndDo;

	// register LouseDogTreatment
	RegisterRecords.LouseDogTreatment.Write = True;
	For Each CurRowLouseDogTreatment In LouseDogTreatment Do
		Record = RegisterRecords.LouseDogTreatment.Add();
		Record.Period = Date;
		Record.Dog = Dog;
		Record.Owner = DogOwner;
		Record.Veterinarian = CurRowLouseDogTreatment.Veterinarian;
		Record.Date = Date;
		Record.Quantity = CurRowLouseDogTreatment.Quantity;
		Record.Product = CurRowLouseDogTreatment.Product;
	EndDo;

	// register InformationDog
	RegisterRecords.InformationDog.Write = True;
	Record = RegisterRecords.InformationDog.Add();
	Record.Period = Date;
	Record.Dog = Dog;
	Record.Date = Date;
	Record.Weight = Weight;

	// register TrackingHistory
	RegisterRecords.TrackingHistory.Write = True;
	Record = RegisterRecords.TrackingHistory.Add();
	Record.Period = Date;
	Record.Dog = Dog;
	Record.CheckIn = StartTime;
	Record.CheckOut = EndTime;
	Record.Zone = Zone;
	Record.Purpose = Purpose;

	//}}__REGISTER_REGISTERRECORDS_WIZARD
EndProcedure


//YenNN Get last weight from doc.tracking into catalogs dog	
Procedure GetLastWeight()
	
		
	Query = New Query;
	Query.Text = 
		"SELECT TOP 1
		|	InformationDogSliceLast.Dog AS Dog,
		|	InformationDogSliceLast.Date AS Date,
		|	InformationDogSliceLast.Weight AS Weight
		|FROM
		|	InformationRegister.InformationDog.SliceLast AS InformationDogSliceLast
		|WHERE
		|	InformationDogSliceLast.Dog = &Dog
		|
		|ORDER BY
		|	Date DESC";
	
	Query.SetParameter("Dog", Dog);
	
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	
	While SelectionDetailRecords.Next() Do
		DogObj=Dog.GetObject() ;
		DogObj.Weight = SelectionDetailRecords.Weight;
		DogObj.Write();
	EndDo;
EndProcedure
