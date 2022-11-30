
#If Server OR ThickClientOrdinaryApplication OR ExternalConnection Then
	
Procedure FillPredefinedValues() Export
	StandardVersion = Catalogs.fmDepartmentsStructuresVersions.DefaultVersion.GetObject();
	StandardVersion.ApprovalDate = BegOfYear(CurrentSessionDate());
	StandardVersion.Description = NStr("en='Valid from ';ru='Действительна с '") + Format(StandardVersion.ApprovalDate, "L=en; DF='MMMM yyyy'");
	StandardVersion.Write();
EndProcedure
	
#EndIf
