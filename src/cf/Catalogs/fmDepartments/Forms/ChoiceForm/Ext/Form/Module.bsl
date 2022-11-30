
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If NOT Parameters.Property("StructureVersion") Then
		UseDepartmentsStructures = Constants.fmDepartmentsStructuresVersions.Get();
	EndIf;
	If Parameters.Property("Key") Then
		Key = Parameters.Key;
	Else
		Key = Parameters.CurrentRow;
	EndIf;
	Catalogs.fmDepartments.ColorTreeItems(ConditionalAppearance,"List","List.DepartmentType","List.Ref");
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	If UseDepartmentsStructures Then
		Cancel = True;
		Structure = New Structure;
		Structure.Insert("Key",Key);
		OpenForm("Catalog.fmDepartments.Form.VersionChoiceForm", Structure, FormOwner);
	Else
		Items.List.CurrentRow = Key;
	EndIf;
EndProcedure
