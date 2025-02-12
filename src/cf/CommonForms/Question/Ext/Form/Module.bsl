﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Placing the title.
	If Not IsBlankString(Parameters.Title) Then
		Title = Parameters.Title;
		TitleWidth = 1.3 * StrLen(Title);
		If TitleWidth > 40 AND TitleWidth < 80 Then
			Width = TitleWidth;
		ElsIf TitleWidth >= 80 Then
			Width = 80;
		EndIf;
	EndIf;
	
	If Parameters.LockWholeInterface Then
		WindowOpeningMode = FormWindowOpeningMode.LockWholeInterface;
	EndIf;
	
	// Picture.
	If Parameters.Picture.Type <> PictureType.Empty Then
		Items.Warning.Picture = Parameters.Picture;
	Else
		// In this case, the picture can be hidden.
		// However, the ShowPicture parameter is implemented for backward compatibility.
		// For example, someone of consumers could open directly with parameters, bypassing the BF API, 
		// particularly  StandardSubsystemsClient.ShowQuestionToUser.
		ShowPicture = CommonClientServer.StructureProperty(Parameters, "ShowPicture", True);
		If Not ShowPicture Then
			Items.Warning.Visible = False;
		EndIf;
	EndIf;
	
	// Placing text.
	MessageText = Parameters.MessageText;
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.MultilineMessageText.BorderColor = New Color; // For platform (white outline is displayed when changing the border color).
	EndIf;
	MinMarginWidth = 50;
	ApproximateMarginHeight = StringsCount(Parameters.MessageText, MinMarginWidth);
	Items.MultilineMessageText.Width = MinMarginWidth;
	Items.MultilineMessageText.Height = Min(ApproximateMarginHeight, 10);
	
	// Placing check box.
	If ValueIsFilled(Parameters.CheckBoxText) Then
		Items.DoNotAskAgain.Title = Parameters.CheckBoxText;
	ElsIf NOT AccessRight("SaveUserData", Metadata) OR NOT Parameters.SuggestDontAskAgain Then
		Items.DoNotAskAgain.Visible = False;
	EndIf;
	
	// Placing buttons.
	AddCommandsAndButtonsToForm(Parameters.Buttons);
	
	// Setting the default button.
	HighlightDefaultButton = CommonClientServer.StructureProperty(Parameters, "HighlightDefaultButton", True);
	SetDefaultButton(Parameters.DefaultButton, HighlightDefaultButton);
	
	// Setting the countdown button.
	SetTimeoutButton(Parameters.TimeoutButton);
	
	// Setting the countdown timer.
	TimeoutCounter = Parameters.Timeout;
	
	// Resetting the form window size and position.
	ResetWindowLocationAndSize();
	
	If Common.IsMobileClient() Then
		Items.Move(Items.DoNotAskAgain, ThisObject);
		CommandBarLocation = FormCommandBarLabelLocation.Top;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	// Starting countdown.
	If TimeoutCounter >= 1 Then
		TimeoutCounter = TimeoutCounter + 1;
		ContinueCountdown();
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure Attachable_CommandHandler(Command)
	SelectedValue = ButtonAndReturnValueMap.Get(Command.Name);
	
	SelectionResult = New Structure;
	SelectionResult.Insert("DoNotAskAgain", DoNotAskAgain);
	SelectionResult.Insert("Value", DialogReturnCodeByValue(SelectedValue));
	
	Close(SelectionResult);
EndProcedure

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Client

&AtClient
Procedure ContinueCountdown()
	TimeoutCounter = TimeoutCounter - 1;
	If TimeoutCounter <= 0 Then
		Close(New Structure("DoNotAskAgain, Value", False, DialogReturnCode.Timeout));
	Else
		If TimeoutButtonName <> "" Then
			NewTitle = (
				TimeoutButtonTitle
				+ " ("
				+ StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'осталось %1 сек.'; en = '%1 seconds left'; pl = 'zostało %1 sekund';de = '%1 verbleibende Sekunden';ro = 'au rămas %1 sec.';tr = '%1 saniye kaldı'; es_ES = '%1 segundos faltan'"), String(TimeoutCounter))
				+ ")");
				
			Items[TimeoutButtonName].Title = NewTitle;
		EndIf;
		AttachIdleHandler("ContinueCountdown", 1, True);
	EndIf;
EndProcedure

&AtClient
Function DialogReturnCodeByValue(Value)
	If TypeOf(Value) <> Type("String") Then
		Return Value;
	EndIf;
	
	If Value = "DialogReturnCode.Yes" Then
		Result = DialogReturnCode.Yes;
	ElsIf Value = "DialogReturnCode.No" Then
		Result = DialogReturnCode.No;
	ElsIf Value = "DialogReturnCode.OK" Then
		Result = DialogReturnCode.OK;
	ElsIf Value = "DialogReturnCode.Cancel" Then
		Result = DialogReturnCode.Cancel;
	ElsIf Value = "DialogReturnCode.Retry" Then
		Result = DialogReturnCode.Retry;
	ElsIf Value = "DialogReturnCode.Abort" Then
		Result = DialogReturnCode.Abort;
	ElsIf Value = "DialogReturnCode.Ignore" Then
		Result = DialogReturnCode.Ignore;
	Else
		Result = Value;
	EndIf;
	
	Return Result;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Server

&AtServer
Procedure AddCommandsAndButtonsToForm(Buttons)
	// Adds commands and corresponding buttons to the form.
	//
	// Parameters:
	//  Buttons - String / ValueList - a set of buttons. If String, the format is "QuestionDialogMode.
	//		   <one of the QuestionDialogMode values>". For example, "QuestionDialogMode.YesNo".
	//		   
	//		   If ValueList, each record contains:
	//		   Value - the value the form returns when the button is clicked.
	//		   Presentation - the button text.
	
	If TypeOf(Buttons) = Type("String") Then
		ButtonsValueList = StandardSet(Buttons);
	Else
		ButtonsValueList = Buttons;
	EndIf;
	
	ButtonToValueMap = New Map;
	
	Index = 0;
	
	For Each ButtonInfoItem In ButtonsValueList Do
		Index = Index + 1;
		CommandName = "Command" + String(Index);
		Command = Commands.Add(CommandName);
		Command.Action  = "Attachable_CommandHandler";
		Command.Title = ButtonInfoItem.Presentation;
		Command.ModifiesStoredData = False;
		
		Button= Items.Add(CommandName, Type("FormButton"), CommandBar);
		Button.OnlyInAllActions = False;
		Button.CommandName = CommandName;
		
		ButtonToValueMap.Insert(CommandName, ButtonInfoItem.Value);
	EndDo;
	
	ButtonAndReturnValueMap = New FixedMap(ButtonToValueMap);
EndProcedure

&AtServer
Procedure SetDefaultButton(DefaultButton, HighlightDefaultButton)
	If ButtonAndReturnValueMap.Count() = 0 Then
		Return;
	EndIf;
	
	Button = Undefined;
	For Each Item In ButtonAndReturnValueMap Do
		If Item.Value = DefaultButton Then
			Button = Items[Item.Key];
			Break;
		EndIf;
	EndDo;
	
	If Button = Undefined Then
		Button = CommandBar.ChildItems[0];
	EndIf;
	
	If HighlightDefaultButton Then
		Button.DefaultButton = True;
	EndIf;
	CurrentItem = Button;
EndProcedure

&AtServer
Procedure SetTimeoutButton(TimeoutButtonValue)
	If ButtonAndReturnValueMap.Count() = 0 Then
		Return;
	EndIf;
	
	For Each Item In ButtonAndReturnValueMap Do
		If Item.Value = TimeoutButtonValue Then
			TimeoutButtonName = Item.Key;
			TimeoutButtonTitle = Commands[TimeoutButtonName].Title;
			Return;
		EndIf;
	EndDo;
EndProcedure

&AtServer
Procedure ResetWindowLocationAndSize()
	Username = InfoBaseUsers.CurrentUser().Name;
	If AccessRight("SaveUserData", Metadata) Then
		SystemSettingsStorage.Delete("CommonForm.Question", "", Username);
	EndIf;
	WindowOptionsKey = String(New UUID);
EndProcedure

&AtServerNoContext
Function StandardSet(Buttons)
	Result = New ValueList;
	
	If Buttons = "QuestionDialogMode.YesNo" Then
		Result.Add("DialogReturnCode.Yes",  NStr("ru = 'Да'; en = 'Yes'; pl = 'Tak';de = 'Ja';ro = 'Da';tr = 'Evet'; es_ES = 'Sí'"));
		Result.Add("DialogReturnCode.No", NStr("ru = 'Нет'; en = 'No'; pl = 'Nie';de = 'Nr.';ro = 'Nu';tr = 'No'; es_ES = 'No'"));
	ElsIf Buttons = "QuestionDialogMode.YesNoCancel" Then
		Result.Add("DialogReturnCode.Yes",     NStr("ru = 'Да'; en = 'Yes'; pl = 'Tak';de = 'Ja';ro = 'Da';tr = 'Evet'; es_ES = 'Sí'"));
		Result.Add("DialogReturnCode.No",    NStr("ru = 'Нет'; en = 'No'; pl = 'Nie';de = 'Nr.';ro = 'Nu';tr = 'No'; es_ES = 'No'"));
		Result.Add("DialogReturnCode.Cancel", NStr("ru = 'Отмена'; en = 'Cancel'; pl = 'Anuluj';de = 'Abbrechen';ro = 'Revocare';tr = 'İptal'; es_ES = 'Cancelar'"));
	ElsIf Buttons = "QuestionDialogMode.OK" Then
		Result.Add("DialogReturnCode.OK", NStr("ru = 'ОК'; en = 'OK'; pl = 'OK';de = 'OK';ro = 'OK';tr = 'OK'; es_ES = 'OK'"));
	ElsIf Buttons = "QuestionDialogMode.OKCancel" Then
		Result.Add("DialogReturnCode.OK",     NStr("ru = 'ОК'; en = 'OK'; pl = 'OK';de = 'OK';ro = 'OK';tr = 'OK'; es_ES = 'OK'"));
		Result.Add("DialogReturnCode.Cancel", NStr("ru = 'Отмена'; en = 'Cancel'; pl = 'Anuluj';de = 'Abbrechen';ro = 'Revocare';tr = 'İptal'; es_ES = 'Cancelar'"));
	ElsIf Buttons = "QuestionDialogMode.RetryCancel" Then
		Result.Add("DialogReturnCode.Retry", NStr("ru = 'Повторить'; en = 'Retry'; pl = 'Powtórz';de = 'Wiederholen';ro = 'Repetare';tr = 'Tekrarla'; es_ES = 'Repetir'"));
		Result.Add("DialogReturnCode.Cancel",    NStr("ru = 'Отмена'; en = 'Cancel'; pl = 'Anuluj';de = 'Abbrechen';ro = 'Revocare';tr = 'İptal'; es_ES = 'Cancelar'"));
	ElsIf Buttons = "QuestionDialogMode.AbortRetryIgnore" Then
		Result.Add("DialogReturnCode.Abort",   NStr("ru = 'Прервать'; en = 'Abort'; pl = 'Przerwij';de = 'Abbrechen';ro = 'Renunțați';tr = 'Durdur'; es_ES = 'Anular'"));
		Result.Add("DialogReturnCode.Retry",  NStr("ru = 'Повторить'; en = 'Retry'; pl = 'Powtórz';de = 'Wiederholen';ro = 'Repetare';tr = 'Tekrarla'; es_ES = 'Repetir'"));
		Result.Add("DialogReturnCode.Ignore", NStr("ru = 'Пропустить'; en = 'Ignore'; pl = 'Omiń';de = 'Ignorieren';ro = 'Ignorați';tr = 'Yok say'; es_ES = 'Ignorar'"));
	EndIf;
	
	Return Result;
EndFunction

// Determines the approximate number of lines including hyphenated lines.
&AtServerNoContext
Function StringsCount(Text, CutoffByWidth, BringToFormItemSize = True)
	StringsCount = StrLineCount(Text);
	HyphenationCount = 0;
	For RowNumber = 1 To StringsCount Do
		Row = StrGetLine(Text, RowNumber);
		HyphenationCount = HyphenationCount + Int(StrLen(Row)/CutoffByWidth);
	EndDo;
	EstimatedLineCount = StringsCount + HyphenationCount;
	If BringToFormItemSize Then
		If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
			Coefficient = 4/5; // In version 8.2, approximately 5 text lines fit a block of height 4.
		Else
			Coefficient = 2/3; // In Taxi, approximately 3 text lines fit a block of height 2.
		EndIf;
		EstimatedLineCount = Int((EstimatedLineCount+1)*Coefficient);
	EndIf;
	If ClientApplication.CurrentInterfaceVariant() <> ClientApplicationInterfaceVariant.Version8_2 AND EstimatedLineCount = 2 Then
		EstimatedLineCount = 3;
	EndIf;
	Return EstimatedLineCount;
EndFunction

#EndRegion
