
#Region ProceduresAndFunctionsOfCommonUse

&AtClient
Procedure ChooseValue()
	CurValue = Items.InfoStructuresList.CurrentData;
	If NOT CurValue = Undefined Then
		Close(CurValue.InfoStructure);
	EndIf;
EndProcedure //ВыбратьЗначение()

#EndRegion

#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Получим значения структур сведений.
	Query = New Query();
	Query.Text = "SELECT
	|	fmBindingInfoStructuresToDepartments.InfoStructure,
	|	fmBindingInfoStructuresToDepartments.ApplyByDefault AS ApplyByDefault
	|FROM
	|	InformationRegister.fmBindingInfoStructuresToDepartments AS fmBindingInfoStructuresToDepartments
	|WHERE
	|	fmBindingInfoStructuresToDepartments.Department = &Department
	|	AND fmBindingInfoStructuresToDepartments.InfoStructure.StructureType = &StructureType
	|
	|ORDER BY
	|	ApplyByDefault DESC";
	Query.SetParameter("Department", Parameters.Department);
	Query.SetParameter("StructureType", Parameters.StructureType);
	InfoStructuresList.Load(Query.Execute().Unload());
	
	// Установим текстроку при возможности.
	If Parameters.Property("Key") AND ValueIsFilled(Parameters.Key) Then
		For Each CurRow In InfoStructuresList Do
			If CurRow.InfoStructure=Parameters.Key Then
				Items.InfoStructuresList.CurrentRow = CurRow.GetID();
				Break;
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormItemsEventsHandlers

&AtClient
Procedure SELECT(Command)
	ChooseValue();
EndProcedure //Выбрать()

&AtClient
Procedure WithoutStructure(Command)
	Close(PredefinedValue("Catalog.fmInfoStructures.EmptyRef"));
EndProcedure //БезСтруктуры()

&AtClient
Procedure InfoStructureListChoice(Item, SelectedRow, Field, StandardProcessing)
	ChooseValue();
EndProcedure //СписокСтруктурСведенийВыбор()

&AtClient
Procedure OpenStructure(Command)
	CurValue = Items.InfoStructuresList.CurrentData;
	If NOT CurValue = Undefined Then
		ShowValue(,CurValue.InfoStructure);
	Else
		CommonClientServer.MessageToUser(NStr("en='You should select a structure.';ru='Необходимо выбрать структуру'"));
	EndIf;
EndProcedure

#EndRegion

