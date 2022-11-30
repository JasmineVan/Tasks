
&AtServer
Procedure ListOnChangeAtServer()
	// Insert handler content.
EndProcedure

&AtClient
Procedure ListOnChange(Item)
	ListOnChangeAtServer();
EndProcedure


&AtClient
Procedure Refresh()
	items.List.Refresh();
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	AttachIdleHandler("Refresh",2);
EndProcedure
