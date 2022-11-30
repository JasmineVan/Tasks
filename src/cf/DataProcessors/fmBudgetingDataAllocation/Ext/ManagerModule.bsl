
Procedure FillDistributionBase(DocumentObject, BaseQueryParameter) Export
	
	DocumentObject.Bases.Clear();
	StepObject = DocumentObject.BudgetDistributionStep.GetObject();
	
	Query = New Query;
	Query.Text = StepObject.BaseAssembleAlgorithm;
	
	// Добавим "Стандартные" параметры.
	For Each ParameterStr In BaseQueryParameter Do
		Query.SetParameter(ParameterStr.Key, ParameterStr.Value);
	EndDo;
	// А также, определенные в шаге.
	For Each ParameterStr In StepObject.BaseAssembleQueryParameters Do
		Query.SetParameter(ParameterStr.ParameterName, ParameterStr.ParameterValue);
	EndDo;
	
	BaseVT = Query.Execute().Unload();
	If BaseVT.Columns.Find("Active") = Undefined Then
		BaseVT.Columns.Add("Active");
		BaseVT.FillValues(True, "Active");
	EndIf;
	DocumentObject.Bases.Load(BaseVT);
	
EndProcedure // ЗаполнитьБазуРаспределения()
