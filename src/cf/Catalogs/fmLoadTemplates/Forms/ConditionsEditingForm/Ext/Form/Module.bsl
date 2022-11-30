
&AtClient
Procedure CheckColumnNumber(ColumnNum)
	
	If NOT ValueIsFilled(ColumnNum) Then Return EndIf;
	
	OnlyNumber = ?(ReadMethod = PredefinedValue("Enum.fmReadMethods.Column"), True, False);
	
	LetterArray = New Array();
	LetterArray.Add("A");
	LetterArray.Add("B");
	LetterArray.Add("C");
	LetterArray.Add("D");
	LetterArray.Add("E");
	LetterArray.Add("F");
	LetterArray.Add("G");
	LetterArray.Add("H");
	LetterArray.Add("I");
	LetterArray.Add("J");
	LetterArray.Add("K");
	LetterArray.Add("L");
	LetterArray.Add("M");
	LetterArray.Add("N");
	LetterArray.Add("O");
	LetterArray.Add("P");
	LetterArray.Add("Q");
	LetterArray.Add("R");
	LetterArray.Add("S");
	LetterArray.Add("T");
	LetterArray.Add("U");
	LetterArray.Add("V");
	LetterArray.Add("W");
	LetterArray.Add("X");
	LetterArray.Add("Y");
	LetterArray.Add("Z");
	
	// Приведем к верхнему регистру для проверки.
	ColumnNum = Upper(ColumnNum);
	Try
		Number = Number(ColumnNum);
	Except
		If OnlyNumber Then
			CommonClientServer.MessageToUser(NStr("en='The column name must be numerical.';ru='Обозначение колонки может быть только числовым!'"));
			ColumnNum = "";
		Else
			Num = 1;
			While Num <= StrLen(ColumnNum) Do
				If LetterArray.Find(Mid(ColumnNum, Num, 1)) = Undefined Then
					CommonClientServer.MessageToUser(NStr("en='The row (of the column) must be literal or numerical.';ru='Обозначение строки(колонки) может быть или буквенным или числовым!'"));
					ColumnNum = "";
					Return;
				EndIf;
				Num = Num + 1;
			EndDo;
		EndIf;
	EndTry;
	
EndProcedure // ПроверитьНомерКолонки()

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.BeginConditions Then
		Title = NStr("en='Start-of-import routine condition (according to the ""or"" principle)';ru='Условия начала считывания (по принципу ""или"")'");
	Else
		Title = NStr("en='End-of-import routine conditions (according to the ""or"" principle)';ru='Условия окончания считывания (по принципу ""или"")'");
	EndIf;
	BoldCondition = Parameters.BoldCondition;
	ItalicCondition = Parameters.ItalicCondition;
	ConditionByIndent = Parameters.ConditionByIndent;
	ConditionByTextColor = Parameters.ConditionByTextColor;
	ConditionByBackColor = Parameters.ConditionByBackColor;
	ConditionByFont = Parameters.ConditionByFont;
	IndentCondition = Parameters.IndentCondition;
	UnderlinedCondition = Parameters.UnderlinedCondition;
	SizeCondition = Parameters.SizeCondition;
	TextColorNotEqualCondition = Parameters.TextColorNotEqualCondition;
	BackColorNotEqualCondition = Parameters.BackColorNotEqualCondition;
	FontCondition = Parameters.FontCondition;
	FontNotEqualCondition = Parameters.FontNotEqualCondition;
	ConditionByValue = Parameters.ConditionByValue;
	ValueNotEqualCondition = Parameters.ValueNotEqualCondition;
	ValueCondition = Parameters.ValueCondition;
	ReadMethod = Parameters.ReadMethod;
	RowCountConditionByBackColor = Parameters.RowCountConditionByBackColor;
	RowCountConditionByTextColor = Parameters.RowCountConditionByTextColor;
	RowCountConditionByIndent = Parameters.RowCountConditionByIndent;
	RowCountConditionByFont = Parameters.RowCountConditionByFont;
	RowCountValueByCondition = Parameters.RowCountValueByCondition;
	// Разберем цвет на составляющий.
	// Цвет фона
	BackColorConditionRed = Parameters.BackColorCondition%256;
	BackColorConditionGreen = (Parameters.BackColorCondition%65536-BackColorConditionRed)/256;
	BackColorConditionBlue = (Parameters.BackColorCondition-BackColorConditionGreen*256-BackColorConditionRed)/256/256;
	// Цвет текста
	TextColorConditionRed = Parameters.TextColorCondition%256;
	TextColorConditionGreen = (Parameters.TextColorCondition%65536-TextColorConditionRed)/256;
	TextColorConditionBlue = (Parameters.TextColorCondition-TextColorConditionGreen*256-TextColorConditionRed)/65536;
EndProcedure

&AtClient
Procedure OK(Command)
	ResultStructure = New Structure("FontCondition, SizeCondition, BoldCondition, ItalicCondition, UnderlinedCondition, 
	|ConditionByFont, FontNotEqualCondition, ConditionByBackColor, BackColorCondition, BackColorNotEqualCondition, ConditionByTextColor, 
	|TextColorCondition, TextColorNotEqualCondition, ConditionByIndent, IndentCondition, ConditionByValue, ValueNotEqualCondition, 
	|ValueCondition, RowCountConditionByBackColor, RowCountConditionByTextColor, RowCountConditionByIndent, RowCountConditionByFont, RowCountValueByCondition");
	FillPropertyValues(ResultStructure, ThisForm);
	ResultStructure.BackColorCondition = BackColorConditionRed + BackColorConditionGreen*256 + BackColorConditionBlue*256*256;
	ResultStructure.TextColorCondition = TextColorConditionRed + TextColorConditionGreen*256 + TextColorConditionBlue*256*256;
	Close(ResultStructure);
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	SetEnable();
EndProcedure

&AtClient
Procedure SetEnable()
	Items.GroupBackColorCondition.Enabled = ConditionByBackColor;
	Items.BackColorNotEqual.Enabled = ConditionByBackColor;
	Items.RowCountConditionByBackColor.Enabled = ConditionByBackColor;
	Items.GoupTextColorCondition.Enabled = ConditionByTextColor;
	Items.TextColorNotEqual.Enabled = ConditionByTextColor;
	Items.RowCountConditionByTextColor.Enabled = ConditionByTextColor;
	Items.Indent.Enabled = ConditionByIndent;
	Items.RowCountConditionByIndent.Enabled = ConditionByIndent;
	Items.Font.Enabled = ConditionByFont;
	Items.FontNotEqual.Enabled = ConditionByFont;
	Items.Bold.Enabled = ConditionByFont;
	Items.Italic.Enabled = ConditionByFont;
	Items.Underlined.Enabled = ConditionByFont;
	Items.Size.Enabled = ConditionByFont;
	Items.RowCountConditionByFont.Enabled = ConditionByFont;
	Items.Value.Enabled = ConditionByValue;
	Items.ValueNotEqual.Enabled = ConditionByValue;
	Items.RowCountValueByCondition.Enabled = ConditionByValue;
EndProcedure

&AtClient
Procedure ConditionByBackColorOnChange(Item)
	SetEnable();
EndProcedure

&AtClient
Procedure ConditionByTextColorOnChange(Item)
	SetEnable();
EndProcedure

&AtClient
Procedure ConditionByFontOnChange(Item)
	SetEnable();
EndProcedure

&AtClient
Procedure ConditionByIndentOnChange(Item)
	SetEnable();
EndProcedure

&AtClient
Procedure ConditionByValueOnChange(Item)
	SetEnable();
EndProcedure

&AtClient
Procedure RowCountValueByConditionOnChange(Item)
	CheckColumnNumber(RowCountValueByCondition);
EndProcedure

&AtClient
Procedure RowCountConditionByIndentOnChange(Item)
	CheckColumnNumber(RowCountConditionByIndent);
EndProcedure

&AtClient
Procedure RowCountConditionByTextColorOnChange(Item)
	CheckColumnNumber(RowCountConditionByTextColor);
EndProcedure

&AtClient
Procedure RowCountConditionByFontOnChange(Item)
	CheckColumnNumber(RowCountConditionByFont);
EndProcedure

&AtClient
Procedure RowCountConditionByBackColorOnChange(Item)
	CheckColumnNumber(RowCountConditionByBackColor);
EndProcedure



