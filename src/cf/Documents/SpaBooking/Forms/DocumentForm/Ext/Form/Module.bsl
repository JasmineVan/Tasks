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

#EndRegion

#Region ThuongTV

&AtClient
Procedure DogListServiceOnChange(Item)
	//Update service price when service was choosed
	Service = Items.DogList.CurrentData.Service;
	Items.DogList.CurrentData.Price = GetServicePrice(Service); 
EndProcedure

&AtServer
Function GetServicePrice(Service)
	Price = Service.Ref.Price;
	Return Price;	
EndFunction

&AtServer
Procedure DogListOnChangeAtServer()
	TotalPrice = 0;
	If Not Object.DogList.Count() = 0 Then
		For Each Row In Object.DogList Do
			TotalPrice = TotalPrice + Row.Price;
		EndDo;
	EndIf;
EndProcedure

&AtClient
Procedure DogListOnChange(Item)
	//Update total value every single changed
	DogListOnChangeAtServer();
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	//Initial price when this form open for the first time
	TotalPrice = 0;
	If Not Object.DogList.Count() = 0 Then
		For Each Row In Object.DogList Do
			Row.Price = Row.Service.Price;
			TotalPrice = TotalPrice + Row.Price;
		EndDo;
	EndIf;
EndProcedure

#EndRegion
