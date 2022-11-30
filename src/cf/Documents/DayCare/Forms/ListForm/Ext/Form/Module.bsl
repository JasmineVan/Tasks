
&AtClient
Procedure AutoRefresh()
	items.List.Refresh();
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	AttachIdleHandler("AutoRefresh",2);
EndProcedure
