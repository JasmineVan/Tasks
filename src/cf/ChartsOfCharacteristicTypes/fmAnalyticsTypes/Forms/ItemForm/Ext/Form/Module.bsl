
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	FormManagement(ThisForm);
	
EndProcedure

#EndRegion

#Region ServiceProceduresAdFunctions

&AtClientAtServerNoContext
Procedure FormManagement(Form)

	Items = Form.Items;
	Object   = Form.Object;

	Items.ValueType.ReadOnly = Object.Predefined;
	
EndProcedure

#EndRegion
