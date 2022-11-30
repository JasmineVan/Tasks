
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	Bold = Parameters.Bold;
	Italic = Parameters.Italic;
	FilterByIndent = Parameters.FilterByIndent;
	TextColorFilter = Parameters.TextColorFilter;
	BackColorFilter = Parameters.BackColorFilter;
	FontFilter = Parameters.FontFilter;
	Indent = Parameters.Indent;
	Underlined = Parameters.Underlined;
	Size = Parameters.Size;
	TextColorNotEqual = Parameters.TextColorNotEqual;
	BackColorNotEqual = Parameters.BackColorNotEqual;
	Font = Parameters.Font;
	FontNotEqual = Parameters.FontNotEqual;
	FilterByValue = Parameters.FilterByValue;
	ValueNotEqual = Parameters.ValueNotEqual;
	Value = Parameters.Value;
	// Разберем цвет на составляющий.
	// Цвет фона
	BackColorRed = Parameters.BackColor%256;
	BackColorGreen = (Parameters.BackColor%65536-BackColorRed)/256;
	BackColorBlue = (Parameters.BackColor-BackColorGreen*256-BackColorRed)/256/256;
	// Цвет текста
	TextColorRed = Parameters.TextColor%256;
	TextColorGreen = (Parameters.TextColor%65536-TextColorRed)/256;
	TextColorBlue = (Parameters.TextColor-TextColorGreen*256-TextColorRed)/65536;
EndProcedure

&AtClient
Procedure OK(Command)
	ResultStructure = New Structure("Font, Size, Bold, Italic, Underlined, FontFilter, FontNotEqual, 
	|BackColorFilter, BackColor, BackColorNotEqual, TextColorFilter, TextColor, TextColorNotEqual, FilterByIndent, Indent,
	|FilterByValue, ValueNotEqual, Value");
	FillPropertyValues(ResultStructure, ThisForm);
	ResultStructure.BackColor = BackColorRed + BackColorGreen*256 + BackColorBlue*256*256;
	ResultStructure.TextColor = TextColorRed + TextColorGreen*256 + TextColorBlue*256*256;
	Close(ResultStructure);
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	SetEnable();
EndProcedure

&AtClient
Procedure SetEnable()
	Items.GroupBackColor.Enabled = BackColorFilter;
	Items.BackColorNotEqual.Enabled = BackColorFilter;
	Items.GroupTextColor.Enabled = TextColorFilter;
	Items.TextColorNotEqual.Enabled = TextColorFilter;
	Items.Indent.Enabled = FilterByIndent;
	Items.Font.Enabled = FontFilter;
	Items.FontNotEqual.Enabled = FontFilter;
	Items.Bold.Enabled = FontFilter;
	Items.Italic.Enabled = FontFilter;
	Items.Underlined.Enabled = FontFilter;
	Items.Size.Enabled = FontFilter;
	Items.Value.Enabled = FilterByValue;
	Items.ValueNotEqual.Enabled = FilterByValue;
EndProcedure

&AtClient
Procedure BackColorFilterOnChange(Item)
	SetEnable();
EndProcedure

&AtClient
Procedure TextColorFilterOnChange(Item)
	SetEnable();
EndProcedure

&AtClient
Procedure FontFilterOnChange(Item)
	SetEnable();
EndProcedure

&AtClient
Procedure IndentFilterOnChange(Item)
	SetEnable();
EndProcedure

&AtClient
Procedure ValueFilterOnChange(Item)
	SetEnable();
EndProcedure





