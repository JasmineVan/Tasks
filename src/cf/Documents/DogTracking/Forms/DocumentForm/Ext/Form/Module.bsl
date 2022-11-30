
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	//Huong (Fill Weight and Age)
	DoB = new ValueTable;
	DoB.Columns.Add("DateOfBirth",new TypeDescription("date"));
	NewDoB = DoB.Add();
	NewDoB.DateOfBirth = Object.Dog.DateOfBirth;
	If not object.Ref.isempty() then
		FillAge(DoB);
	Endif;
	Object.Weight = Object.Dog.Weight;
	DoB.Clear();
	//End Huong
	//Items.Dog.ListChoiceMode = True;
	Items.DogOwner.ChoiceList.Add(Object.DogOwner);
	GetImageDog();
EndProcedure

&AtServer
Procedure FillAge(Val DoB)
	
	Var DogAge, Query, QueryResult, SelectionDetailRecords;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	DoB.DateOfBirth AS DateOfBirth
	|INTO DoBvalue
	|FROM
	|	&DoB AS DoB
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DATEDIFF(DoBvalue.DateOfBirth, &currentdate, MONTH) / 12 AS Age
	|FROM
	|	DoBvalue AS DoBvalue";
	
	Query.SetParameter("currentdate", currentdate());
	Query.SetParameter("DoB", DoB);
	
	
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	
	While SelectionDetailRecords.Next() Do
		DogAge = Object.Dog.GetObject();
		DogAge.Age = SelectionDetailRecords.age;
		DogAge.Write();
	EndDo;

EndProcedure


Function  FillChoiceList()
	
	ChoiceArr = new Array();
	For each owner in object.Dog.OwnerSecondary do
		ChoiceArr.Add(Owner.Owner);
	Enddo;
	Return ChoiceArr;

EndFunction

&AtServer
Procedure DogOnChangeAtServer()
	//Huong 
	DoB = new ValueTable;
	DoB.Columns.Add("DateOfBirth",new TypeDescription("date"));
	NewDoB = DoB.Add();
	NewDoB.DateOfBirth = Object.Dog.DateOfBirth;
	If not object.Ref.isempty() then
		sth = Object.Dog;
		FillAge(DoB);
		//Object.Weight = 0;
	Endif;
	DoB.Clear();
	Object.DogOwner = Object.Dog.Owner;
	Object.Weight = Object.Dog.Weight;
	Items.DogOwner.ChoiceList.Add(Object.Dog.Owner);
	//End Huong
EndProcedure

&AtClient
Procedure DogOnChange(Item)
	DogOnChangeAtServer();
	GetImageDog();
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	// Huong (Auto set StartDate to currentdate when left empty)
	If not valueisfilled(Object.StartTime) then
		CurrentObject.StartTime = CurrentDate();
	Endif;
	//End Huong
EndProcedure

&AtServer
Procedure OnOpenAtServer()
	// Insert handler content.
	sth = ThisForm;
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	OnOpenAtServer();
EndProcedure

&AtClient
Procedure DogOwnerStartChoice(Item, ChoiceData, StandardProcessing)
	//Huong (Fill list choice of owners depends on dog)
	ChoiceList = Items.DogOwner.ChoiceList;
	ChoiceList.Clear();
	ChoiceArr = FillChoiceList();
	For each item in ChoiceArr do
		ChoiceList.Add(item);
	Enddo;
	//End Huong
EndProcedure

&AtServer
Procedure GetImageDog()
Picture=PutToTempStorage(Object.Dog.Picture.Get());	
EndProcedure

