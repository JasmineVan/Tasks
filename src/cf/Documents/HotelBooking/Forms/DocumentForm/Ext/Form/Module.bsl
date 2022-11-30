#Region HuongDM

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Object.Pickup = False then
		UnvisiblePickupinfo();
	EndIf;
	//<<ThuongTV
	//Initial price when this form open for the first time
	Total = 0;
	If Not Object.DogList.Count() = 0 Then
		For Each Row In Object.DogList Do
			Row.Price = Row.Room.Price;
			Total = Total + Row.Price;
		EndDo;
	EndIf;
	//>>End ThuongTV
EndProcedure

&AtServer
Procedure UnvisiblePickupinfo()
	
	ThisForm.ThisObject.Items.AddressNumber.Visible = False;
	ThisForm.ThisObject.Items.City.Visible = False;
	ThisForm.ThisObject.Items.District.Visible = False;
	ThisForm.ThisObject.Items.Street.Visible = False;
	ThisForm.ThisObject.Items.Ward.Visible = False;

EndProcedure

&AtServer
Procedure PickupOnChangeAtServer()
	If Object.Pickup = True then
		ThisForm.ThisObject.Items.AddressNumber.Visible = True;
		ThisForm.ThisObject.Items.City.Visible = True;
		ThisForm.ThisObject.Items.District.Visible = True;
		ThisForm.ThisObject.Items.Street.Visible = True;
		ThisForm.ThisObject.Items.Ward.Visible = True;
	Else UnvisiblePickupinfo();	
	Endif;
EndProcedure

&AtClient
Procedure PickupOnChange(Item)
	PickupOnChangeAtServer();
EndProcedure

#EndRegion

#Region ThuongTV

&AtClient
Procedure DogListRoomOnChange(Item)
	Room = Items.DogList.CurrentData.Room;
	Items.DogList.CurrentData.Price = GetRoomPrice(Room);
EndProcedure

&AtServer
Function GetRoomPrice(Room)
	Price = Room.Ref.Price;
	Return Price;	
EndFunction

&AtServer
Procedure DogListOnChangeAtServer()
	Total = 0;
	If Not Object.DogList.Count() = 0 Then
		For Each Row In Object.DogList Do
			Total = Total + Row.Price;
		EndDo;
	EndIf;
EndProcedure

&AtClient
Procedure DogListOnChange(Item)
	DogListOnChangeAtServer();
EndProcedure

#EndRegion

#Region YenNN
&AtClient
Procedure DogListDogStartChoice(Item, ChoiceData, StandardProcessing)
		ChoiceList=Item.ChoiceList;
	ChoiceList.Clear();
	ListDog = GetDogOfOwner(Object.Owner);
	TabularDogList = New Array;
	For Each Line In object.DogList Do
		If ValueIsFilled(Line.Dog) Then
			TabularDogList.Add(Line.Dog); 
		EndIf; 
	EndDo; 	
	For Each Dog In ListDog  Do
		Check =True;
		For Each DogIntabular In TabularDogList Do
			If Dog =DogIntabular Then
				Check =False;
			EndIf; 
		EndDo; 
		If Check Then
			ChoiceList.Add(Dog);
		EndIf;
	EndDo;
	If Item.ChoiceList.Count()=0 Then
		If ValueIsFilled(Object.Owner) Then
			Message(String(Object.Owner)+" have no other dogs");
		Else
			Message("Please select Owner");
		EndIf; 
	EndIf;
EndProcedure

Function GetDogOfOwner(Owner)
		
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Dogs.Ref AS Ref
	|FROM
	|	Catalog.Dogs AS Dogs
	|WHERE
	|	Dogs.Owner = &Owner";
	
	Query.SetParameter("Owner", Owner);
	
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	ListDog = new Array;
	While SelectionDetailRecords.Next() Do
		ListDog.Add(SelectionDetailRecords.Ref);
	EndDo;
	
	Return ListDog;

EndFunction

&AtClient
Procedure AfterWrite(WriteParameters)
If String(WriteParameters.WriteMode)="Posting" Then
	ThisForm.items.CheckedOut.Visible = True;
EndIf; 	
EndProcedure

#EndRegion


