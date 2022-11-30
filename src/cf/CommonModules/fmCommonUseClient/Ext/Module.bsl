
#Region ServiceProgramInterface

// Обработчики событий поля ввода.

Procedure MonthInputOnChange(EditedObject, AttributePath, AttributePathPresentation, Modified = False) Export
	
	PresentationValue = CommonClientServer.GetFormAttributeByPath(EditedObject, AttributePathPresentation);
	Value              = CommonClientServer.GetFormAttributeByPath(EditedObject, AttributePath);
	
	DateAsMonthChooseDateByText(PresentationValue, Value);
	
	CommonClientServer.SetFormAttributeByPath(EditedObject, AttributePathPresentation, GetMonthPresentation(Value));
	CommonClientServer.SetFormAttributeByPath(EditedObject, AttributePath, Value);
	
	Modified = True;
	
EndProcedure 

Procedure MonthInputTextAutoComplete(Text, ChoiceData, StandardProcessing) Export
	
	If NOT IsBlankString(Text) Then
		ChoiceData = DateAsMonthChooseDateByText(Text);
		StandardProcessing = False;
	EndIf;
	
EndProcedure

Procedure MonthInputTextEditEnd(Text, ChoiceData, StandardProcessing) Export
	
	If Text <> "" Then
		ChoiceData = DateAsMonthChooseDateByText(Text);
		StandardProcessing = False;
	EndIf;
	
EndProcedure

Procedure MonthInputStartChoice(Form, EditedObject, AttributePath, AttributePathPresentation, ChangeModifiedState = True, EndNotification = Undefined, MonthValueByDefault = Undefined) Export
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Form", Form);
	AdditionalParameters.Insert("EditedObject", EditedObject);
	AdditionalParameters.Insert("AttributePath", AttributePath);
	AdditionalParameters.Insert("AttributePathPresentation", AttributePathPresentation);
	AdditionalParameters.Insert("ChangeModifiedState", ChangeModifiedState);
	AdditionalParameters.Insert("EndNotification", EndNotification);
	
	Value = CommonClientServer.GetFormAttributeByPath(EditedObject, AttributePath);
	If Value <= '19000101' Then
		
		If MonthValueByDefault = Undefined Then
			Value = BegOfMonth(CommonClient.SessionDate());
		Else
			Value = BegOfMonth(MonthValueByDefault);
		EndIf;
		
	EndIf; 
	
	Notification = New NotifyDescription("MonthInputStartChoiceEnd", ThisObject, AdditionalParameters);
	
	OpenForm("CommonForm.fmPeriodChoice", 
		New Structure("Value,PeriodChoiceMode,RequestPeriodChoiceModeFromOwner", Value, "Month", False),
		Form, , , , Notification, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

Procedure MonthInputStartChoiceEnd(ChosenValue, AdditionalParameters) Export

	Form = AdditionalParameters.Form;
	EditedObject = AdditionalParameters.EditedObject;
	AttributePath = AdditionalParameters.AttributePath;
	AttributePathPresentation = AdditionalParameters.AttributePathPresentation;
	ChangeModifiedState = AdditionalParameters.ChangeModifiedState;
	EndNotification = AdditionalParameters.EndNotification;
	
	If ChosenValue = Undefined Then
		
		If EndNotification <> Undefined Then
			ExecuteNotifyProcessing(EndNotification, False);
		EndIf;
		
	Else
		
		Value = ChosenValue;
		
		CommonClientServer.SetFormAttributeByPath(EditedObject, AttributePath, Value);
		Presentation = GetMonthPresentation(Value);
		CommonClientServer.SetFormAttributeByPath(EditedObject, AttributePathPresentation, Presentation);
		
		If ChangeModifiedState Then 
			Form.Modified = True;
		EndIf;
		
		If EndNotification <> Undefined Then
			ExecuteNotifyProcessing(EndNotification, True);
		EndIf;
		
	EndIf;
	
	If EndNotification = Undefined Then
		Form.RefreshDataRepresentation();
	EndIf;
	
EndProcedure

Procedure MonthInputTuning(EditedObject, AttributePath, AttributePathPresentation, Direction, Modified = False, MonthValueByDefault = Undefined) Export
	
	Value = CommonClientServer.GetFormAttributeByPath(EditedObject, AttributePath);
	
	If Value <= '19000101' Then
		
		If MonthValueByDefault = Undefined Then
			Value = BegOfMonth(CommonClient.SessionDate());
		Else
			Value = BegOfMonth(MonthValueByDefault);
		EndIf;
		
		NewValue = Value;
		
	Else
		NewValue = AddMonth(Value, Direction);
	EndIf; 
	
	If NewValue >= '00010101' Then
		
		Value = NewValue;
		
		CommonClientServer.SetFormAttributeByPath(EditedObject, AttributePath, Value);
		CommonClientServer.SetFormAttributeByPath(EditedObject, AttributePathPresentation, GetMonthPresentation(Value));
		
		Modified = True;
	 	
	EndIf;
	
EndProcedure 

Function DateAsMonthChooseDateByText(Text, DateByText = Undefined)
	
	ReturnList = New ValueList;
	CurrentYear = Year(CommonClient.SessionDate());
	
	If IsBlankString(Text) Then
		DateByText = DATE(1, 1, 1);
		Return ReturnList;
	EndIf;
	
	If StrFind(Text, ".") <> 0 Then
		SubStrings = StringFunctionsClientServer.SplitStringIntoSubstringsArray(Text, ".");
	ElsIf StrFind(Text, ",") <> 0 Then
		SubStrings = StringFunctionsClientServer.SplitStringIntoSubstringsArray(Text, ",");
	ElsIf StrFind(Text, "-") <> 0 Then
		SubStrings = StringFunctionsClientServer.SplitStringIntoSubstringsArray(Text, "-");
	ElsIf StrFind(Text, "/") <> 0 Then
		SubStrings = StringFunctionsClientServer.SplitStringIntoSubstringsArray(Text, "/");
	ElsIf StrFind(Text, "\") <> 0 Then
		SubStrings = StringFunctionsClientServer.SplitStringIntoSubstringsArray(Text, "\");
	Else
		SubStrings = StringFunctionsClientServer.SplitStringIntoSubstringsArray(Text, " ");
	EndIf;
	
	If SubStrings.Count() = 1 Then
		If StringFunctionsClientServer.OnlyDigitsInString(Text) Then
			MonthByNumber = Number(Text);
			If MonthByNumber >= 1 AND MonthByNumber <=12 Then
				DateByText = DATE(CurrentYear, MonthByNumber, 1);
				If StrLen(Text) = 1 Then
					ReturnList.Add(Format(DateByText, "DF='m/yy'"));
				Else
					ReturnList.Add(Format(DateByText, "DF='mm/yy'"));
				EndIf;
			Else
				Return ReturnList;
			EndIf;                
		Else
			MonthList = MonthListInString(Text);
			For Each Month In MonthList Do
				DateByText = DATE(CurrentYear, Month, 1);
				ReturnList.Add(Format(DateByText, "DF='MMMM yyyy'"));
			EndDo;
		EndIf;
		
	ElsIf SubStrings.Count() = 2 Then
		
		If StringFunctionsClientServer.OnlyDigitsInString(SubStrings[1]) Then
			
			If IsBlankString(SubStrings[1]) Then
				YearAsNumber = 0;
				SubStrings[1] = "0";
				ReturnText = Text + "0";
			Else
				YearAsNumber = Number(SubStrings[1]);
				ReturnText = "";
			EndIf;
			
			If YearAsNumber > 3000 Then
				Return ReturnList;
			EndIf;
			
			If StrLen(SubStrings[1]) <= 1 Then
				YearAsNumber = Number(Left(Format(CurrentYear, "NG="), 3) + SubStrings[1]);
			ElsIf StrLen(SubStrings[1]) = 2 Then
				YearAsNumber = Number(Left(Format(CurrentYear, "NG="), 2) + SubStrings[1]);
			ElsIf StrLen(SubStrings[1]) = 3 Then
				YearAsNumber = Number(Left(Format(CurrentYear, "NG="), 1) + SubStrings[1]);
			ElsIf StrLen(SubStrings[1]) = 4 Then
				YearAsNumber = Number(SubStrings[1]);
			EndIf;                    
			
		Else
			
			Return ReturnList;
			
		EndIf;                
		If ValueIsFilled(SubStrings[0]) AND StringFunctionsClientServer.OnlyDigitsInString(SubStrings[0]) Then
			
			MonthByNumber = Number(SubStrings[0]);
			If MonthByNumber >= 1 AND MonthByNumber <= 12 Then
				DateByText = DATE(YearAsNumber, MonthByNumber, 1);
				ReturnList.Add(Format(DateByText, "DF='MMMM yyyy'"));
			Else
				Return ReturnList;
			EndIf;                
			
		Else
			
			MonthList = MonthListInString(SubStrings[0]);
			
			If MonthList.Count() = 1 Then
				DateByText = DATE(YearAsNumber, MonthList[0], 1);
				ReturnList.Add(Format(DateByText, "DF='MMMM yyyy'"));
			Else
				For Each Month In MonthList Do
					DateByText = DATE(YearAsNumber, Month, 1);
					ReturnList.Add(Format(DATE(YearAsNumber, Month, 1), "DF='MMMM yyyy'"));
				EndDo;
			EndIf;
			
		EndIf;
	EndIf;
	
	Return ReturnList;
	
EndFunction

// Возвращает представление месяца по переданной дате.
//
// Параметры:
//		ДатаНачалаМесяца
//
// Возвращаемое значение;
//		Строка
//
Function GetMonthPresentation(BegOfMonthDate) Export
	
	Return Format(BegOfMonthDate, "L=en; DF='MMMM yyyy'");
	
EndFunction

// Подбирает массив номеров месяцев, соответствующих переданной строке
// например, для строки "ма" это будут 3 и 5, для "а" - 4 и 8
// используется в ПодобратьДатуПоТексту.
//
Function MonthListInString(Text)
	
	MonthList  = New ValueList;
	Monthes         = New Map;
	ReturnMonthes = New Array;
	
	For Counter = 1 To 12 Do
		Presentation = Format(DATE(2000, Counter, 1), "DF='MMMM'");
		MonthList.Add(Counter, Presentation);
		Presentation = Format(DATE(2000, Counter, 1), "DF='mmm'");
		MonthList.Add(Counter, Presentation);
	EndDo;
	
	For Each ListItem In MonthList Do
		If Upper(Text) = Upper(Left(ListItem.Presentation, StrLen(Text))) Then
			Monthes[ListItem.Value] = 0;
		EndIf;
	EndDo;
	
	For Each Item In Monthes Do
		ReturnMonthes.Add(Item.Key);
	EndDo;
	
	Return ReturnMonthes;
	
EndFunction

#EndRegion


