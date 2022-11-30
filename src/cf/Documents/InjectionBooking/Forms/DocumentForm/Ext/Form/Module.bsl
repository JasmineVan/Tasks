
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

