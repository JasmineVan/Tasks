
#Region CommandHandlers

&AtClient
Procedure ChangeWithChildren(Command)
	ReturnStr = New Structure;
	ReturnStr.Insert("WithChildren", True);
	ReturnStr.Insert("SetType", DepartmentType);
	ReturnStr.Insert("CurDepartment", CurDepartment);
	NotifyChoice(ReturnStr);
EndProcedure

&AtClient
Procedure ChangeOnlyCurrent(Command)
	ReturnStr = New Structure;
	ReturnStr.Insert("WithChildren", False);
	ReturnStr.Insert("SetType", DepartmentType);
	ReturnStr.Insert("CurDepartment", CurDepartment);
	NotifyChoice(ReturnStr);
EndProcedure

&AtClient
Procedure CancelAction(Command)
	ThisForm.Close();
EndProcedure

#EndRegion

#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("CurDepartment") Then
		CurDepartment = Parameters.CurDepartment;
	EndIf;
	Items.Decoration1.Title = StrReplace(Items.Decoration1.Title, "%1%", String(CurDepartment));
EndProcedure

#EndRegion
