///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Formula         = Parameters.Formula;
	SourceFormula = Parameters.Formula;
	
	Parameters.Property("UsesOperandTree", UsesOperandTree);
	
	Items.OperandsPagesGroup.CurrentPage = Items.NumericOperandsPage;
	Operands.Load(GetFromTempStorage(Parameters.Operands));
	For Each curRow In Operands Do
		If curRow.DeletionMark Then
			curRow.PictureIndex = 3;
		Else
			curRow.PictureIndex = 2;
		EndIf;
	EndDo;
	
	OperatorsTree = GetStandardOperatorsTree();
	ValueToFormAttribute(OperatorsTree, "Operators");
	
	If Parameters.Property("OperandsTitle") Then
		Items.OperandsGroup.Title = Parameters.OperandsTitle;
		Items.OperandsGroup.ToolTip = Parameters.OperandsTitle;
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	StandardProcessing = False;
	If Not Modified Or Not ValueIsFilled(SourceFormula) Or SourceFormula = Formula Then
		Return;
	EndIf;
	
	Cancel = True;
	If Exit Then
		Return;
	EndIf;
	
	ShowQueryBox(New NotifyDescription("BeforeCloseCompletion", ThisObject), NStr("ru='Данные были изменены. Сохранить изменения?'; en = 'The data was changed. Do you want to save the changes?'; pl = 'Dane zostały zmienione. Czy chcesz zapisać zmiany?';de = 'Daten wurden geändert. Wollen Sie die Änderungen speichern?';ro = 'Datele au fost modificate. Salvați modificările?';tr = 'Veriler değiştirildi. Değişiklikleri kaydetmek istiyor musunuz?'; es_ES = 'Datos se han cambiado. ¿Quiere guardar los cambios?'"), QuestionDialogMode.YesNoCancel);
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	Response = QuestionResult;
	If Response = DialogReturnCode.Yes Then
		If CheckFormula(Formula, Operands()) Then
			Modified = False;
			Close(Formula);
		EndIf;
	ElsIf Response = DialogReturnCode.No Then
		Modified = False;
		Close(Undefined);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SettingsComposerSettingsChoiceAvailableChoiceFieldsChoice(Item, RowSelected, Field, StandardProcessing)
	
	StringText = String(SettingsComposer.Settings.OrderAvailableFields.GetObjectByID(RowSelected).Field);
	Operand = ProcessOperandText(StringText);
	InsertTextIntoFormula(Operand);
	
EndProcedure

&AtClient
Procedure SettingsComposerStartDrag(Item, DragParameters, Perform)
	
	ItemText = String(SettingsComposer.Settings.OrderAvailableFields.GetObjectByID(Items.SettingsComposer.CurrentRow).Field);
	DragParameters.Value = ProcessOperandText(ItemText);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersOperands

&AtClient
Procedure OperandsChoice(Item, RowSelected, Field, StandardProcessing)
	
	If Field.Name = "OperandsValues" Then
		Return;
	EndIf;
	
	If Item.CurrentData.DeletionMark Then
		
		ShowQueryBox(
			New NotifyDescription("OperandsSelectCompletion", ThisObject), 
			NStr("ru = 'Выбранный элемент помечен на удаление. 
				|Продолжить?'; 
				|en = 'Selected item is marked for deletion.
				|Continue?'; 
				|pl = 'Wybrany element został zaznaczony do usunięcia. 
				|Kontynuować?';
				|de = 'Das ausgewählte Element wird zum Löschen vorgemerkt.
				|Fortfahren?';
				|ro = 'Elementul selectat este marcat la ștergere. 
				| Continuați?';
				|tr = 'Seçilmiş öğe silinmek için işaretlendi. 
				|Devam et?'; 
				|es_ES = 'Elemento seleccionado marcado para borrar. 
				|¿Continuar?'"), 
			QuestionDialogMode.YesNo);
		StandardProcessing = False;
		Return;
	EndIf;
	
	StandardProcessing = False;
	InsertOperandIntoFormula();
	
EndProcedure

&AtClient
Procedure OperandsSelectCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		InsertOperandIntoFormula();
	EndIf;

EndProcedure

&AtClient
Procedure OperandsStartDrag(Item, DragParameters, StandardProcessing)
	
	DragParameters.Value = GetOperandTextToInsert(Item.CurrentData.ID);
	
EndProcedure

&AtClient
Procedure OperandsEndDrag(Item, DragParameters, StandardProcessing)
	
	If Item.CurrentData.DeletionMark Then
		ShowQueryBox(New NotifyDescription("OperandsDragEndCompletion", ThisObject), NStr("ru = 'Выбранный элемент помечен на удаление'; en = 'Selected item is marked for deletion'; pl = 'Wybrany element został zaznaczony do usunięcia';de = 'Das ausgewählte Element wird zum Löschen vorgemerkt';ro = 'Elementul selectat este marcat la ștergere';tr = 'Seçilmiş öğe silinmek için işaretlendi'; es_ES = 'Elemento seleccionado marcado para borrar'") + Chars.LF + NStr("ru = 'Продолжить?'; en = 'Continue?'; pl = 'Kontynuować?';de = 'Fortsetzen?';ro = 'Continuați?';tr = 'Devam et?'; es_ES = '¿Continuar?'"), QuestionDialogMode.YesNo);
	EndIf;
	
EndProcedure

&AtClient
Procedure OperandsDragEndCompletion(QuestionResult, AdditionalParameters) Export
	
	Response = QuestionResult;
	
	If Response = DialogReturnCode.No Then
		
		StringBeginning  = 0;
		BeginningOfTheColumn = 0;
		EndOfLine   = 0;
		EndOfTheColumn  = 0;
		
		Items.Formula.GetTextSelectionBounds(StringBeginning, BeginningOfTheColumn, EndOfLine, EndOfTheColumn);
		Items.Formula.SelectedText = "";
		Items.Formula.SetTextSelectionBounds(StringBeginning, BeginningOfTheColumn, StringBeginning, BeginningOfTheColumn);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OperandsTreeChoice(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.OperandsTree.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	ParentRow = CurrentData.GetParent();
	If ParentRow = Undefined Then
		Return;
	EndIf;
	
	InsertTextIntoFormula(GetOperandTextToInsert(
		ParentRow.ID + "." + CurrentData.ID));
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersOperandsTree

&AtClient
Procedure OperandsTreeStartDrag(Item, DragParameters, Perform)
	
	If DragParameters.Value = Undefined Then
		Return;
	EndIf;
	
	TreeRow = OperandsTree.FindByID(DragParameters.Value);
	ParentRow = TreeRow.GetParent();
	If ParentRow = Undefined Then
		Perform = False;
		Return;
	Else
		DragParameters.Value = 
		   GetOperandTextToInsert(ParentRow.ID +"." + TreeRow.ID);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersOperators

&AtClient
Procedure OperatorsChoice(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	InsertOperatorIntoFormula();
	
EndProcedure

&AtClient
Procedure OperatorsStartDrag(Item, DragParameters, StandardProcessing)
	
	If ValueIsFilled(Item.CurrentData.Operator) Then
		DragParameters.Value = Item.CurrentData.Operator;
	Else
		StandardProcessing = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure OperatorsEndDrag(Item, DragParameters, StandardProcessing)
	
	If Item.CurrentData.Operator = "Format(,)" Then
		RowFormat = New FormatStringWizard;
		RowFormat.Show(New NotifyDescription("OperatorsEndDragCompletion", ThisObject, New Structure("RowFormat", RowFormat)));
	EndIf;
	
EndProcedure

&AtClient
Procedure OperatorsEndDragCompletion(Text, AdditionalParameters) Export
	
	RowFormat = AdditionalParameters.RowFormat;
	
	
	If ValueIsFilled(RowFormat.Text) Then
		TextForInsert = "Format( , """ + RowFormat.Text + """)";
		Items.Formula.SelectedText = TextForInsert;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure OK(Command)
	
	ClearMessages();
	
	If CheckFormula(Formula, Operands()) Then
		Close(Formula);
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckSSL(Command)
	
	ClearMessages();
	CheckFormulaInteractive(Formula, Operands());
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure InsertTextIntoFormula(TextForInsert, Offset = 0)
	
	RowStart = 0;
	RowEnd = 0;
	ColumnStart = 0;
	ColumnEnd = 0;
	
	Items.Formula.GetTextSelectionBounds(RowStart, ColumnStart, RowEnd, ColumnEnd);
	
	If (ColumnEnd = ColumnStart) AND (ColumnEnd + StrLen(TextForInsert)) > Items.Formula.Width / 8 Then
		Items.Formula.SelectedText = "";
	EndIf;
		
	Items.Formula.SelectedText = TextForInsert;
	
	If Not Offset = 0 Then
		Items.Formula.GetTextSelectionBounds(RowStart, ColumnStart, RowEnd, ColumnEnd);
		Items.Formula.SetTextSelectionBounds(RowStart, ColumnStart - Offset, RowEnd, ColumnEnd - Offset);
	EndIf;
		
	CurrentItem = Items.Formula;
	
EndProcedure

&AtClient
Procedure InsertOperandIntoFormula()
	
	InsertTextIntoFormula(GetOperandTextToInsert(Items.Operands.CurrentData.ID));
	
EndProcedure

&AtClient
Function Operands()
	
	Result = New Array();
	For Each Operand In Operands Do
		Result.Add(Operand.ID);
	EndDo;
	
	Return Result;
	
EndFunction

&AtClient
Procedure InsertOperatorIntoFormula()
	
	If Items.Operators.CurrentData.Description = "Format" Then
		RowFormat = New FormatStringWizard;
		RowFormat.Show(New NotifyDescription("InsertOperatorIntoFormulaCompletion", ThisObject, New Structure("RowFormat", RowFormat)));
		Return;
	Else	
		InsertTextIntoFormula(Items.Operators.CurrentData.Operator, Items.Operators.CurrentData.Offset);
	EndIf;
	
EndProcedure

&AtClient
Procedure InsertOperatorIntoFormulaCompletion(Text, AdditionalParameters) Export
	
	RowFormat = AdditionalParameters.RowFormat;
	
	If ValueIsFilled(RowFormat.Text) Then
		TextForInsert = "Format( , """ + RowFormat.Text + """)";
		InsertTextIntoFormula(TextForInsert, Items.Operators.CurrentData.Offset);
	Else	
		InsertTextIntoFormula(Items.Operators.CurrentData.Operator, Items.Operators.CurrentData.Offset);
	EndIf;
	
EndProcedure

&AtClient
Function ProcessOperandText(OperandText)
	
	StringText = OperandText;
	StringText = StrReplace(StringText, "[", "");
	StringText = StrReplace(StringText, "]", "");
	Operand = "[" + StrReplace(StringText, 
		?(PropertiesSet.ProductPropertiesSet, "Products.", 
			?(NOT PropertiesSet.Property("CharacteristicsPropertySet") OR PropertiesSet.CharacteristicsPropertySet, "ProductCharacteristic.", "ProductSeries.")), "") + "]";
	
	Return Operand
	
EndFunction

&AtServer
Function GetEmptyOperatorsTree()
	
	Tree = New ValueTree();
	Tree.Columns.Add("Description");
	Tree.Columns.Add("Operator");
	Tree.Columns.Add("Offset", New TypeDescription("Number"));
	
	Return Tree;
	
EndFunction

&AtServer
Function AddOperatorsGroup(Tree, Description)
	
	NewGroup = Tree.Rows.Add();
	NewGroup.Description = Description;
	
	Return NewGroup;
	
EndFunction

&AtServer
Function AddOperator(Tree, Parent, Description, Operator = Undefined, Offset = 0)
	
	NewRow = ?(Parent <> Undefined, Parent.Rows.Add(), Tree.Rows.Add());
	NewRow.Description = Description;
	NewRow.Operator = ?(ValueIsFilled(Operator), Operator, Description);
	NewRow.Offset = Offset;
	
	Return NewRow;
	
EndFunction

&AtServer
Function GetStandardOperatorsTree()
	
	Tree = GetEmptyOperatorsTree();
	
	OperatorsGroup = AddOperatorsGroup(Tree, NStr("ru='Разделители'; en = 'Separators'; pl = 'Separatory';de = 'Trennzeichen';ro = 'Separatori';tr = 'Ayırıcılar'; es_ES = 'Separadores'"));
	
	AddOperator(Tree, OperatorsGroup, "/", " + ""/"" + ");
	AddOperator(Tree, OperatorsGroup, "\", " + ""\"" + ");
	AddOperator(Tree, OperatorsGroup, "|", " + ""|"" + ");
	AddOperator(Tree, OperatorsGroup, "_", " + ""_"" + ");
	AddOperator(Tree, OperatorsGroup, ",", " + "", "" + ");
	AddOperator(Tree, OperatorsGroup, ".", " + "". "" + ");
	AddOperator(Tree, OperatorsGroup, NStr("ru='Пробел'; en = 'Whitespace'; pl = 'Spacja';de = 'Leertaste';ro = 'Spațiu';tr = 'Boşluk'; es_ES = 'Espacio'"), " + "" "" + ");
	AddOperator(Tree, OperatorsGroup, "(", " + "" ("" + ");
	AddOperator(Tree, OperatorsGroup, ")", " + "") "" + ");
	AddOperator(Tree, OperatorsGroup, """", " + """""""" + ");
	
	OperatorsGroup = AddOperatorsGroup(Tree, NStr("ru='Операторы'; en = 'Operators'; pl = 'Operatorzy';de = 'Operatoren';ro = 'Operatori';tr = 'Operatörler'; es_ES = 'Operadores'"));
	
	AddOperator(Tree, OperatorsGroup, "+", " + ");
	AddOperator(Tree, OperatorsGroup, "-", " - ");
	AddOperator(Tree, OperatorsGroup, "*", " * ");
	AddOperator(Tree, OperatorsGroup, "/", " / ");
	
	OperatorsGroup = AddOperatorsGroup(Tree, NStr("ru='Логические операторы и константы'; en = 'Logical operators and constants'; pl = 'Operatory logiczne i konstanty';de = 'Logische Operatoren und Konstanten';ro = 'Operatori logici și constante';tr = 'Mantıksal işleçler ve sabitler'; es_ES = 'Operadores lógicos y constantes'"));
	AddOperator(Tree, OperatorsGroup, "<", " < ");
	AddOperator(Tree, OperatorsGroup, ">", " > ");
	AddOperator(Tree, OperatorsGroup, "<=", " <= ");
	AddOperator(Tree, OperatorsGroup, ">=", " >= ");
	AddOperator(Tree, OperatorsGroup, "=", " = ");
	AddOperator(Tree, OperatorsGroup, "<>", " <> ");
	AddOperator(Tree, OperatorsGroup, NStr("ru='И'; en = 'AND'; pl = 'AND';de = 'UND';ro = 'ȘI';tr = 'VE'; es_ES = 'Y'"),      " " + NStr("ru='И'; en = 'AND'; pl = 'AND';de = 'UND';ro = 'ȘI';tr = 'VE'; es_ES = 'Y'")      + " ");
	AddOperator(Tree, OperatorsGroup, NStr("ru='Или'; en = 'OR'; pl = 'Lub';de = 'Oder';ro = 'Or';tr = 'Veya'; es_ES = 'O'"),    " " + NStr("ru='Или'; en = 'OR'; pl = 'Lub';de = 'Oder';ro = 'Or';tr = 'Veya'; es_ES = 'O'")    + " ");
	AddOperator(Tree, OperatorsGroup, NStr("ru='Не'; en = 'NOT'; pl = 'Nie';de = 'Nicht';ro = 'Not';tr = 'Değil'; es_ES = 'No'"),     " " + NStr("ru='Не'; en = 'NOT'; pl = 'Nie';de = 'Nicht';ro = 'Not';tr = 'Değil'; es_ES = 'No'")     + " ");
	AddOperator(Tree, OperatorsGroup, NStr("ru='ИСТИНА'; en = 'TRUE'; pl = 'TRUE';de = 'WAHR';ro = 'ADEVĂRAT';tr = 'DOĞRU'; es_ES = 'VERDADERO'"), " " + NStr("ru='ИСТИНА'; en = 'TRUE'; pl = 'TRUE';de = 'WAHR';ro = 'ADEVĂRAT';tr = 'DOĞRU'; es_ES = 'VERDADERO'") + " ");
	AddOperator(Tree, OperatorsGroup, NStr("ru='ЛОЖЬ'; en = 'FALSE'; pl = 'FALSE';de = 'FALSCH';ro = 'FALS';tr = 'YANLIŞ'; es_ES = 'FALSO'"),   " " + NStr("ru='ЛОЖЬ'; en = 'FALSE'; pl = 'FALSE';de = 'FALSCH';ro = 'FALS';tr = 'YANLIŞ'; es_ES = 'FALSO'")   + " ");
	
	OperatorsGroup = AddOperatorsGroup(Tree, NStr("ru='Числовые функции'; en = 'Numeric functions'; pl = 'Funkcje liczbowe';de = 'Numerische Funktionen';ro = 'Funcții numerice';tr = 'Rakamsal işlevler'; es_ES = 'Funciones numéricas'"));
	
	AddOperator(Tree, OperatorsGroup, NStr("ru='Максимум'; en = 'Max'; pl = 'Maksimum';de = 'Maximum';ro = 'Maxim';tr = 'Maksimum'; es_ES = 'Máximo'"),    NStr("ru='Макс(,)'; en = 'Max(,)'; pl = 'Maks(,)';de = 'Max(,)';ro = 'Макс(,)';tr = 'Maks (,)'; es_ES = 'Max(,)'"), 2);
	AddOperator(Tree, OperatorsGroup, NStr("ru='Минимум'; en = 'Min'; pl = 'Minimum';de = 'Mindestens';ro = 'Minim';tr = 'Minimum'; es_ES = 'Mínimo'"),     NStr("ru='Мин(,)'; en = 'Min(,)'; pl = 'Min(,)';de = 'Min(,)';ro = 'Мин(,)';tr = 'Min (,)'; es_ES = 'Min(,)'"),  2);
	AddOperator(Tree, OperatorsGroup, NStr("ru='Округление'; en = 'Rounding'; pl = 'Zaokrąglenie';de = 'Abrunden';ro = 'Rotunjit ';tr = 'Kapalı yuvarlak'; es_ES = 'Redondeo'"),  NStr("ru='Окр(,)'; en = 'Round(,)'; pl = 'Zaok(,)';de = 'Rundung(,)';ro = 'Окр(,)';tr = 'Yuv (,)'; es_ES = 'Round(,)'"),  2);
	AddOperator(Tree, OperatorsGroup, NStr("ru='Целая часть'; en = 'Integral part'; pl = 'Cała część';de = 'Ganze Position';ro = 'Parte întreagă';tr = 'Tamsayı parçası'; es_ES = 'Parte entera'"), NStr("ru='Цел()'; en = 'Int()'; pl = 'Cał()';de = 'Ganz()';ro = 'Цел()';tr = 'Tam()'; es_ES = 'Int()'"),   1);
	
	OperatorsGroup = AddOperatorsGroup(Tree, NStr("ru='Строковые функции'; en = 'String functions'; pl = 'Funkcje wierszy';de = 'Zeichenkette-Funktionen';ro = 'Funcțiile de rând';tr = 'Satır işlevleri'; es_ES = 'Funciones lineales'"));
	
	AddOperator(Tree, OperatorsGroup, NStr("ru='Строка'; en = 'Row'; pl = 'Wiersz';de = 'Zeichenkette';ro = 'Rândul';tr = 'Satır'; es_ES = 'Línea'"), NStr("ru='Строка()'; en = 'String()'; pl = 'Wiersz()';de = 'Zeichenkette()';ro = 'Строка()';tr = 'Satır()'; es_ES = 'String()'"));
	AddOperator(Tree, OperatorsGroup, NStr("ru='ВРег'; en = 'Upper'; pl = 'Upper';de = 'Upper';ro = 'Upper';tr = 'Upper'; es_ES = 'Upper'"), NStr("ru='ВРег()'; en = 'Upper()'; pl = 'Upper()';de = 'Upper()';ro = 'Upper()';tr = 'Upper()'; es_ES = 'Upper()'"));
	AddOperator(Tree, OperatorsGroup, NStr("ru='Лев'; en = 'Left'; pl = 'Lewo';de = 'Links';ro = 'Stânga';tr = 'Sol'; es_ES = 'Izquierda'"), NStr("ru='Лев()'; en = 'Left()'; pl = 'Lew()';de = 'Links()';ro = 'Лев()';tr = 'Sol()'; es_ES = 'Left()'"));
	AddOperator(Tree, OperatorsGroup, NStr("ru='НРег'; en = 'Lower'; pl = 'Dolna';de = 'NReg';ro = 'НРег';tr = 'Kayıtlıdeğil'; es_ES = 'Inferior'"), NStr("ru='НРег()'; en = 'Lower()'; pl = 'НРег()';de = 'NReg()';ro = 'НРег()';tr = 'Kayıtlıdeğil()'; es_ES = 'Lower()'"));
	AddOperator(Tree, OperatorsGroup, NStr("ru='Прав'; en = 'Right'; pl = 'Praw';de = 'Rechts';ro = 'Прав';tr = 'Sağ'; es_ES = 'Derecha'"), NStr("ru='Прав()'; en = 'Right()'; pl = 'Praw()';de = 'Rechts()';ro = 'Прав()';tr = 'Sağ()'; es_ES = 'Right()'"));
	AddOperator(Tree, OperatorsGroup, NStr("ru='СокрЛ'; en = 'TrimL'; pl = 'SkrL';de = 'SokrL';ro = 'СокрЛ';tr = 'KısaL'; es_ES = 'TrimL'"), NStr("ru='СокрЛ()'; en = 'TrimL()'; pl = 'SkrL()';de = 'SokrL()';ro = 'СокрЛ()';tr = 'KısaL()'; es_ES = 'TrimL()'"));
	AddOperator(Tree, OperatorsGroup, NStr("ru='СокрЛП'; en = 'TrimAll'; pl = 'SkrLP';de = 'SokrLP';ro = 'СокрЛП';tr = 'KısaLP'; es_ES = 'TrimAll'"), NStr("ru='СокрЛП()'; en = 'TrimAll()'; pl = 'SkrLP()';de = 'SokrLP()';ro = 'СокрЛП()';tr = 'KısaLP'; es_ES = 'TrimAll()'"));
	AddOperator(Tree, OperatorsGroup, NStr("ru='СокрП'; en = 'TrimR'; pl = 'TrimR';de = 'TrimR';ro = 'TrimR';tr = 'TrimR'; es_ES = 'TrimR'"), NStr("ru='СокрП()'; en = 'TrimR()'; pl = 'TrimR()';de = 'TrimR()';ro = 'TrimR()';tr = 'TrimR()'; es_ES = 'TrimR()'"));
	AddOperator(Tree, OperatorsGroup, NStr("ru='ТРег'; en = 'Title'; pl = 'Nazwa';de = 'Titel';ro = 'Titlu';tr = 'Başlık'; es_ES = 'Título'"), NStr("ru='ТРег()'; en = 'Title()'; pl = 'ТРег()';de = 'TReg()';ro = 'ТРег()';tr = 'TReg()'; es_ES = 'Title()'"));
	AddOperator(Tree, OperatorsGroup, NStr("ru='СтрЗаменить'; en = 'StrReplace'; pl = 'StrZamień';de = 'SeiteErsetzen';ro = 'СтрЗаменить';tr = 'SatDeğiştir'; es_ES = 'StrReplace'"), NStr("ru='СтрЗаменить(,,)'; en = 'StrReplace(,,)'; pl = 'StrZamień(,,)';de = 'SeiteErsetzen(,,)';ro = 'СтрЗаменить(,,)';tr = 'SatDeğiştir(,,)'; es_ES = 'StrReplace(,,)'"));
	AddOperator(Tree, OperatorsGroup, NStr("ru='СтрДлина'; en = 'StrLen'; pl = 'StrDługość';de = 'SeiteLänge';ro = 'СтрДлина';tr = 'SatUzunluk'; es_ES = 'StrLen()'"), NStr("ru='СтрДлина()'; en = 'StrLen()'; pl = 'StrDługość()';de = 'SeiteLänge()';ro = 'СтрДлина()';tr = 'SatUzunluk()'; es_ES = 'StrLen()'"));
	
	OperatorsGroup = AddOperatorsGroup(Tree, NStr("ru='Прочие функции'; en = 'Other functions'; pl = 'Inne funkcje';de = 'Weitere Funktionen';ro = 'Alte funcții';tr = 'Diğer işlevler'; es_ES = 'Otras funciones'"));
	
	AddOperator(Tree, OperatorsGroup, NStr("ru='Условие'; en = 'Condition'; pl = 'Warunek';de = 'Bedingung';ro = 'Condiție';tr = 'Koşul'; es_ES = 'Condición'"), "?(,,)", 3);
	AddOperator(Tree, OperatorsGroup, NStr("ru='Предопределенное значение'; en = 'Predefined value'; pl = 'Predefiniowana wartość';de = 'Vordefinierter Wert';ro = 'Valoarea predefinită';tr = 'Önceden belirlenmiş değer'; es_ES = 'Valor predeterminado'"), NStr("ru='ПредопределенноеЗначение()'; en = 'PredefinedValue()'; pl = 'Wartość predefiniowana()';de = 'VordefinierterWert()';ro = 'ПредопределенноеЗначение()';tr = 'ÖncedenBelirlenmişDeğer()'; es_ES = 'PredefinedValue()'"));
	AddOperator(Tree, OperatorsGroup, NStr("ru='Значение заполнено'; en = 'Value filled'; pl = 'Wartość jest wypełniona';de = 'Wert ist ausgefüllt';ro = 'Valoarea este completată';tr = 'Değer dolduruldu'; es_ES = 'Valor está rellenado'"), NStr("ru='ЗначениеЗаполнено()'; en = 'ValueIsFilled()'; pl = 'WartośćWypełniona()';de = 'WertAusgefüllt()';ro = 'ЗначениеЗаполнено()';tr = 'DeğerDolu()'; es_ES = 'ValueIsFilled)'"));
	AddOperator(Tree, OperatorsGroup, NStr("ru='Формат'; en = 'Format'; pl = 'Format';de = 'Format';ro = 'Format';tr = 'Format'; es_ES = 'Formato'"), NStr("ru='Формат(,)'; en = 'Format(,)'; pl = 'Format(,)';de = 'Format(,)';ro = 'Формат(,)';tr = 'Biçim(,)'; es_ES = 'Formato(,)'"));
	
	Return Tree;
	
EndFunction

&AtClientAtServerNoContext
Function GetOperandTextToInsert(Operand)
	
	Return "[" + Operand + "]";
	
EndFunction

&AtClient
Function CheckFormula(Formula, Operands)
	
	If Not ValueIsFilled(Formula) Then
		Return True;
	EndIf;
	
	ReplacementValue = """1""";
	
	CalculationText = Formula;
	For Each Operand In Operands Do
		CalculationText = StrReplace(CalculationText, GetOperandTextToInsert(Operand), ReplacementValue);
	EndDo;
	
	If StrStartsWith(TrimL(CalculationText), "=") Then
		CalculationText = Mid(TrimL(CalculationText), 2);
	EndIf;
	
	Try
		CalculationResult = Eval(CalculationText);
	Except
		ErrorText = NStr("ru = 'В формуле обнаружены ошибки. Проверьте формулу.
			|Формулы должны составляться по правилам написания выражений на встроенном языке 1С:Предприятия.'; 
			|en = 'Formula is invalid.
			|Formulas must comply with the sytax of 1C:Enterprise regular expressions.'; 
			|pl = 'W formule występują błędy. Sprawdź formułę.
			|Wzory powinny być kompilowane przez zasady pisania wyrażeń w języku 1C: Enterprise.';
			|de = 'Es gibt Fehler in der Formel. Überprüfen Sie die Formel.
			|Formeln sollten nach den Regeln des Schreibens von Ausdrücken in der integrierten Sprache 1C:Enterprise erstellt werden.';
			|ro = 'În formulă au fost găsite erori. Verificați formula.
			|Formulele trebuie să fie compuse conform regulilor de scriere a expresiilor în limbajul incorporat al 1C:Enterprise.';
			|tr = 'Formülde hatalar bulundu. Formülü kontrol edin.
			|Formüller, yerleşik 1C:İşletme ''de ifade yazma kurallarına göre hazırlanmalıdır.'; 
			|es_ES = 'En la fórmula se han encontrado errores. Compruebe la fórmula.
			|Las fórmulas deben componerse según las reglas de escribir las expresiones en el lenguaje integrado de 1C:Enterprise.'");
		MessageToUser(ErrorText, , "Formula");
		Return False;
	EndTry;
	
	Return True;
	
EndFunction 

&AtClient
Procedure CheckFormulaInteractive(Formula, Operands)
	
	If ValueIsFilled(Formula) Then
		If CheckFormula(Formula, Operands) Then
			ShowUserNotification(
				NStr("ru = 'В формуле ошибок не обнаружено'; en = 'Formula is valid.'; pl = 'Nie znaleziono błędów w formule';de = 'In der Formel wurden keine Fehler gefunden';ro = 'În formulă nu au fost găsite erori';tr = 'Formülde hata bulunamadı'; es_ES = 'En la fórmula no se han encontrado errores'"),
				,
				,
				Information32Picture());
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Function Information32Picture()
	If SSLVersionMatchesRequirements() Then
		Return PictureLib["Information32"];
	Else
		Return New Picture;
	EndIf;
EndFunction

&AtServer
Function SSLVersionMatchesRequirements()
	DataProcessorObject = FormAttributeToValue("Object");
	Return DataProcessorObject.SSLVersionMatchesRequirements();
EndFunction

&AtClient
Procedure MessageToUser(Val MessageToUserText, Val Field = "", Val DataPath = "")
	Message = New UserMessage;
	Message.Text = MessageToUserText;
	Message.Field = Field;
	
	If NOT IsBlankString(DataPath) Then
		Message.DataPath = DataPath;
	EndIf;
		
	Message.Message();
EndProcedure

#EndRegion
