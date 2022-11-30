
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	// Insert handler content 
	Query = New Query;
	Query.Text = "SELECT
	|	Activities.Ref AS Activity
	|FROM
	|	Catalog.Activities AS Activities";
	
	//Query.SetParameter("", );
	
	Result = Query.Execute();
	Selection = Result.Choose();
	
	While Selection.Next() Do
		NewLine = ActivitiesList.Add();
		NewLine.Activity = Selection.Activity;
		If Selection.Activity.Package = Catalogs.Packages.Basic Then
			NewLine.Basic = True;
		ElsIf Selection.Activity.Package = Catalogs.Packages.Advance Then
			NewLine.Advanced = True;
		Else 
			NewLine.Pro = True;
		EndIf;
	EndDo;
EndProcedure
