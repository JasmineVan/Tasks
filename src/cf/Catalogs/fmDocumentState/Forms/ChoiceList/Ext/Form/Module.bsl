
////////////////////////////////////////////////////////////////////////////////
// ПРОЦЕДУРЫ - ОБРАБОТЧИКИ СОБЫТИЙ ФОРМЫ

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	StatesColoring = Catalogs.fmDocumentState.GetSettings();
	For Each Item In StatesColoring Do
		fmCommonUseClientServer.AddConditionalAppearanceItem("List", ConditionalAppearance, "List.Ref",, Item.Ref, Item.Color, "TextColor");
	EndDo;
	If Parameters.Property("Key") AND ValueIsFilled(Parameters.Key) Then
		Items.List.CurrentRow = Parameters.Key;
	EndIf;
EndProcedure
