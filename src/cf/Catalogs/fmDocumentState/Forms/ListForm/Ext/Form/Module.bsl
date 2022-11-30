
////////////////////////////////////////////////////////////////////////////////
// ПРОЦЕДУРЫ - ОБРАБОТЧИКИ СОБЫТИЙ ФОРМЫ

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	StatesColoring = Catalogs.fmDocumentState.GetSettings();
	For Each Item In StatesColoring Do
		fmCommonUseClientServer.AddConditionalAppearanceItem("List", ConditionalAppearance, "List.Ref",, Item.Ref, Item.Color, "TextColor");
	EndDo;
EndProcedure
