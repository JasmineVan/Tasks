
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)	
	SetRowsColoring();
EndProcedure

#EndRegion

#Region  CommandHandlers

&AtClient
Procedure RefreshColorOnForm(Command)
	SetRowsColoring();
EndProcedure

#EndRegion

#Region  ProceduresAndFunctionsOfCommonUse

&AtServer
Procedure SetRowsColoring()
	TypesSettings = Catalogs.fmDepartmentTypes.GetSettings();
	List.ConditionalAppearance.Items.Clear();
	For Each Item In TypesSettings Do
		fmCommonUseClientServer.AddConditionalAppearanceItem(,List.ConditionalAppearance,"Ref",, Item.DepartmentType, Item.Color, "BackColor");
	EndDo;
EndProcedure

#EndRegion




