
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	fmCommonUseServer.SetFilterByMainBalanceUnit(ThisForm);
EndProcedure

&AtServer
Procedure ListBeforeLoadUserSettingsAtServer(Item, Settings)
	fmCommonUseServer.RestoreListFilter(List, Settings, "BalanceUnit");
EndProcedure
