
&AtClient
Procedure CapacityOnChange(Item)
	If Object.Capacity < Object.Used Then
		Message("Cant not change because capacity large than hotel used");
		Object.Capacity = Object.Used;
	EndIf;	
	Object.CapacityShow = String(Object.Used)+"/" +Object.Capacity;
EndProcedure
