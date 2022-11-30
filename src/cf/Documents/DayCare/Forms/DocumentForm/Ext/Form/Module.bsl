&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	//YenNN
	PickUpForm();
	GetImage();
	Items.Owner.ChoiceList.Add(Object.Owner);
	//ThuongTV
	If Not Object.IsFillActivity Then
		Object.Package = Constants.DayCareDefaultPackage.Get();
		Object.PackageTime = Catalogs.PackageTimes.Fullday;
		GetActivity();
	Else
		If Object.ListActivityBackup.Count() <> 0 Then
			//If ListActivityBackup Has data, fill priority
			Object.ListActivity.Clear();
			For Each Activity In Object.ListActivityBackup Do
				NewLine = Object.ListActivity.Add();	
				NewLine.Activities = Activity.Activities.Ref;
				NewLine.Check = Activity.Check;
				NewLine.Price = Activity.Price;
				NewLine.Status = Activity.Status;
				NewLine.MarkAsDone = Activity.MarkAsDone;
			EndDo;
		EndIf; 
	EndIf;
	GetDogSize();
	//Set up CCTV                                                                                         
	TwoWayLiveFeedObject = Catalogs.Activities.TwoWayLiveFeed.GetObject();
	TwoWayLiveFeedObject.AdditionalInformation = Constants.DayCareDefaultCCTVForFeeding.Get();
	TwoWayLiveFeedObject.Write();
EndProcedure

Procedure GetImage()
	Object.PictureAddress = PutToTempStorage(Object.Dog.Picture.Get());	
EndProcedure

//<<Thuong TV
&AtServer
Procedure GetActivity() 
	//05 10 2022 - ThuongTV add new Feature: Customize Package's activities
	//Function Objective:
	//This function is used to fill ActivityList for the first time this document created
	//Clear List
	Object.ListActivity.Clear();
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Activities.Ref AS Ref,
	|	Activities.Code AS Code,
	|	Activities.Description AS Description,
	|	Activities.Price AS Price,
	|	Activities.Basic AS Basic,
	|	Activities.Advance AS Advance,
	|	Activities.Pro AS Pro
	|FROM
	|	Catalog.Activities AS Activities";
	
	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	
	Object.IsFillActivity = True;
	While Selection.Next() Do
		NewLine = Object.ListActivity.Add();
		NewLine.Activities = Selection.Ref;
		NewLine.Price = Selection.Price;
		If Object.Package = Catalogs.Packages.Pro Then
			If Selection.Pro Then
				NewLine.Check = True;
			EndIf;
		ElsIf Object.Package = Catalogs.Packages.Advance Then
			If Selection.Advance Then
				NewLine.Check = True;
			EndIf;
		ElsIf Object.Package = Catalogs.Packages.Basic Then
			If Selection.Basic Then
				NewLine.Check = True;
			EndIf;
		EndIf;
		//ThuongTV add status to activity list
		NewLine.Status = Enums.ActivityStatus.Available;
		//Sort Activity List
		Object.ListActivity.Sort("Activities Asc");
	EndDo;	
EndProcedure
//>>End ThuongTV

&AtServer
Procedure PickUpForm()
	
	If Object.PickUp = false then
		ThisForm.ThisObject.Items.City.Visible = False;
		ThisForm.ThisObject.Items.District.Visible = False;
		ThisForm.ThisObject.Items.Ward.Visible = False;
		ThisForm.ThisObject.Items.AddressNumber.Visible = False;
		ThisForm.ThisObject.Items.Street.Visible = False;
		ThisForm.ThisObject.Items.Driver.Visible = False;
		ThisForm.ThisObject.Items.TimePickup.Visible = False;

	Else 
		ThisForm.ThisObject.Items.City.Visible = True;
		ThisForm.ThisObject.Items.District.Visible = True;
		ThisForm.ThisObject.Items.Ward.Visible = True;
		ThisForm.ThisObject.Items.AddressNumber.Visible = True;
		ThisForm.ThisObject.Items.Street.Visible = True;
		ThisForm.ThisObject.Items.Driver.Visible =True;
		ThisForm.ThisObject.Items.TimePickup.Visible =True;

	EndIf;
	GetImage();
	
EndProcedure

&AtClient
Procedure PickUpOnChange(Item)
	PickUpForm();
EndProcedure

&AtClient
Procedure PackageOnChange(Item)
	//ThuongTV
	GetActivity();
	UpdateTotalPrice();
EndProcedure

Function  FillChoiceList()
	
	ChoiceArr = new Array();
	For each owner in object.Dog.OwnerSecondary do
		ChoiceArr.Add(Owner.Owner);
	Enddo;
	Return ChoiceArr;

EndFunction

&AtClient
Procedure DogOnChange(Item)
	  GetDogSize();
	  GetImage();
	  FillOwner();
EndProcedure

Function  GetDogSize()
	//Thuong TV modified 07092022 (Enums -> Catalogs)
	Object.Weight = Object.Dog.Weight;
	If Object.Weight >= Catalogs.DogSizes.Small.FromWeight And
		Object.Weight <= Catalogs.DogSizes.Small.ToWeight Then
		Object.DogSize = Catalogs.DogSizes.Small;
	ElsIf  Object.Weight > Catalogs.DogSizes.Medium.FromWeight And 
		Object.Weight <= Catalogs.DogSizes.Medium.ToWeight Then
		Object.DogSize = Catalogs.DogSizes.Medium;
	Else
		Object.DogSize = Catalogs.DogSizes.Big;
	EndIf; 
	
EndFunction

&AtClient
Procedure PackageTimeOnChange(Item)
	GetActivity();
	UpdateTotalPrice();
EndProcedure

//<<Thuong TV
&AtServer
Function UpdateTotalPrice()
	
	Total = 0;
	Object.Price = 0;
	If ValueIsFilled(Object.Package.Price) Then
		PackagePrice = Object.Package.Price;
	Else
		PackagePrice = 0;
	EndIf;
	
	If ValueIsFilled(Object.PackageTime) Then
		//Package Time Price: Full day + 0 VND, Else -20% of Package Price
		PackageTimePrice = Object.PackageTime.Percentage/100;
	Else 
		PackageTimePrice = 0;
	EndIf;
	
	If ValueIsFilled(Object.DogSize) Then
		//Size scale is scalled by current package
		SizePrice = Object.DogSize.Percentage/100; 	
	Else
		SizePrice = 0;
	EndIf;
	
	//Calculated total price
	Total = PackagePrice*(1 + PackageTimePrice + SizePrice);
	Object.Price = PackagePrice*(1 + PackageTimePrice + SizePrice);
EndFunction
//>>End Thuong TV

&AtClient
Procedure DogSizeOnChange(Item)
	// ThuongTV
	UpdateTotalPrice();	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	UpdateTotalPrice();
	//GetActivityOnOpenHandle();           
EndProcedure

&AtServer
Procedure GetActivityOnOpenHandle()
	If Object.ListActivityBackup.Count() <> 0 Then
		//If ListActivityBackup Has data, fill priority
		Object.ListActivity.Clear();
		For Each Activity In Object.ListActivityBackup Do
			NewLine = Object.ListActivity.Add();	
			NewLine.Activities = Activity.Activities;
			NewLine.Check = Activity.Check;
			NewLine.Price = Activity.Price;
		EndDo;
	Else
		GetActivity();
	EndIf;	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	//If Not IsBlankString(Object.PictureAddress) Then
	//	Picture = GetFromTempStorage(Object.PictureAddress);
	//	Object.PictureAddress =Object.PictureAddress;
	//	IF Picture <> Undefined Then       
	//		CurrentObject.Picture = New ValueStorage(Picture);
	//		CurrentObject.Write();    
	//	EndIf;
	//EndIf;

EndProcedure

&AtClient
Procedure OwnerStartChoice(Item, ChoiceData, StandardProcessing)
	//Huong (Fill list choice of owners depends on dog)
	ChoiceList = Items.Owner.ChoiceList;
	ChoiceList.Clear();
	ChoiceArr = FillChoiceList();
	For each item in ChoiceArr do
		ChoiceList.Add(item);
	Enddo;
	//End Huong
EndProcedure

Procedure FillOwner()
	Object.Owner = Object.Dog.Owner;
	Items.Owner.ChoiceList.Add(Object.Dog.Owner);
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	If Object.StartTime > Object.EndTime Then
		Message("EndTime is invalid");
	    Cancel = True;
	EndIf;
	If not Object.PickUp = False then
		If not ValueIsFilled(Object.AddressNumber) or not ValueIsFilled(Object.City) or not ValueIsFilled(Object.District) or not ValueIsFilled(Object.Street) or not ValueIsFilled(Object.Ward) or not ValueIsFilled(Object.TimePickup) then
			Message("Pick up informations is invalid");
	    	Cancel = True;
		EndIf;
	EndIf;
EndProcedure

//<<Thuong TV
&AtClient
Procedure ListActivityOnChange(Item)
	sth = Item.CurrentData;
	If Item.CurrentData.Check Then
		If isInDifferentPackage(Item.CurrentData.Activities) Then
			//Addition fee
			Total = Total + Item.CurrentData.Price;
			Object.Price = Object.Price + Item.CurrentData.Price;
		EndIf;
	ElsIf Item.CurrentData.Check = False Then
		If isInDifferentPackage(Item.CurrentData.Activities) Then
			//Subtraction fee
			Total = Total - Item.CurrentData.Price;
			Object.Price = Object.Price - Item.CurrentData.Price;
		EndIf;
	EndIf;
	
EndProcedure

 Function isInDifferentPackage(ActivityName) Export 
	//Check Activity Param and Package are the same or not by Description
	Activity = Catalogs.Activities.FindByDescription(TrimAll(ActivityName));
	If Not Activity[String(TrimAll(Object.Package))] Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction

 Function isInDifferentPackage2(ActivityCode) Export 
	//Check Activity Param and Package are the same or not by Code
	Activity = Catalogs.Activities.FindByCode(TrimAll(ActivityCode));
	If Not Activity[String(TrimAll(Object.Package))] Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction

&AtServer
Procedure OnCloseAtServer()
	// Write total price
	ThisObject.Write();
	//Backup Activity List
	Object.ListActivityBackup.Clear();	
	
	For Each Activity In Object.ListActivity Do
		NewRow = Object.ListActivityBackup.Add();
		NewRow.Activities = Activity.Activities;
		NewRow.Check = Activity.Check;
		NewRow.Price = Activity.Price;
		NewRow.Status = Activity.Status;
		NewRow.MarkAsDone = Activity.MarkAsDone;
	EndDo;
EndProcedure

&AtClient
Procedure OnClose(Exit)
	OnCloseAtServer();
EndProcedure

#Region ActionButton
&AtClient
Procedure Start(Command)
	ChangeState("Start");
EndProcedure

&AtClient
Procedure Finish(Command)
	ChangeState("Finish");
EndProcedure

&AtClient
Procedure Canceled(Command)
	ChangeState("Canceled");
EndProcedure

&AtClient
Procedure Restart(Command)
	ChangeState("Restart");
EndProcedure

&AtServer
Procedure ChangeState(CommandCode)
	If StrCompare(CommandCode, "Start") = 0 Then
		//Picture
		GetImage();
		//Read only Check column
		ThisForm.ThisForm.Items.ListActivity.ReadOnly = True;
		For Each Activity In Object.ListActivity Do
			If Activity.Check Then
				Activity.Status = Enums.ActivityStatus.Pending;
			Else
				Activity.Status = Enums.ActivityStatus.None;
			EndIf;
		EndDo;
	ElsIf StrCompare(CommandCode, "Finish") = 0 Then
		//Picture
		GetImage();
		//Read only Check column
		ThisForm.ThisForm.Items.ListActivity.ReadOnly = True;
		For Each Activity In Object.ListActivity Do
			If Activity.Check Then
				Activity.Status = Enums.ActivityStatus.Done;
				Activity.MarkAsDone = True;
			Else
				Activity.Status = Enums.ActivityStatus.None;
			EndIf;
		EndDo;
	ElsIf StrCompare(CommandCode, "Canceled") = 0 Then
		//Picture
		GetImage();
		//Read only Check column
		ThisForm.ThisForm.Items.ListActivity.ReadOnly = True;
		For Each Activity In Object.ListActivity Do
			If Activity.Check Then
				Activity.Status = Enums.ActivityStatus.Canceled;
				Activity.MarkAsDone = Undefined;
			Else
				Activity.Status = Enums.ActivityStatus.None;
			EndIf;
		EndDo;
	ElsIf StrCompare(CommandCode, "Restart") = 0 Then
		//Picture
		GetImage();
		//Remove Read only Check column
		ThisForm.ThisForm.Items.ListActivity.ReadOnly = False;
		For Each Activity In Object.ListActivity Do
			Activity.Status = Enums.ActivityStatus.Available;
			Activity.MarkAsDone = False;
		EndDo;
	EndIf;
EndProcedure

&AtServer
Procedure ListActivitySelectionAtServer(SelectedRow)
	Try
		CurrentSelectedRow = Object.ListActivity.Get(SelectedRow);
		If CurrentSelectedRow.Check Then
			//Change State
			CurrentSelectedRow.MarkAsDone = Not CurrentSelectedRow.MarkAsDone;
			If CurrentSelectedRow.MarkAsDone Then
				CurrentSelectedRow.Status = Enums.ActivityStatus.Done;
			Else
				CurrentSelectedRow.Status = Enums.ActivityStatus.Pending;
			EndIf;
		EndIf;
	Except
		Message("Error occur while reading data.");		
	EndTry;
	
EndProcedure

&AtClient
Procedure ListActivitySelection(Item, SelectedRow, Field, StandardProcessing)
	ListActivitySelectionAtServer(SelectedRow);
EndProcedure

&AtServer
Procedure SignatureGeneratorAtServer()
	
EndProcedure

&AtClient
Procedure SignatureGenerator(Command)
	SignatureGeneratorAtServer();
EndProcedure
#EndRegion

//>>End Thuong TV


