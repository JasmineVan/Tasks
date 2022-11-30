
Function DownloadBudgetInformation(StorageCXML, StorageParametersStructure, Check)
	
	If Check Then
		Return NStr("en='Successfully';ru='Успешно'");
	EndIf;
	
	If TypeOf(StorageCXML) = Type("ValueStorage") Then
		UnpackedStringXML = StorageCXML.Get();
	Else
		Return NStr("en='The first parameter must be a storage value.';ru='Первым параметром должно быть ХранилищеЗначений.'");
	EndIf;
	
	If TypeOf(StorageParametersStructure) = Type("ValueStorage") Then
		
		ParametersStructure = StorageParametersStructure.Get();
		If TypeOf(ParametersStructure) <> Type("Structure") Then
			Return NStr("en='The parameter structure must be included into the second parameter.';ru='Во втором параметре должна быть упакована структура параметров.'");
		EndIf;
		
	Else
		
		Return NStr("en=""The second parameter must be the value of 'ValueStorage'"";ru='Вторым параметром должно быть ХранилищеЗначений.'");
	EndIf;
	
	If TypeOf(UnpackedStringXML) <> Type("String") Then
		
		Return NStr("en='The value storage must contain an XML row.';ru='В хранилище значений должна быть строка XML.'");
		
	ElsIf IsBlankString(UnpackedStringXML) Then
		
		Return NStr("en='An empty XML row is sent.';ru='Передана пустая строка XML.'");
	EndIf;
	
	If NOT ParametersStructure.Property("PlanningScenarioDescription") OR IsBlankString(ParametersStructure.PlanningScenarioDescription) Then
		
		Return NStr("en=' """"PlammingScenarioName"""" is not found in the parameter structure, or it is empty  ';ru='В структуре параметров не найдено """"НаименованиеСценарияПланирования"""" или оно пустое.'");
	Else
		
		ScenarioRef = Catalogs.fmBudgetingScenarios.FindByDescription(ParametersStructure.PlanningScenarioDescription, True);
		If ScenarioRef = Catalogs.fmBudgetingScenarios.EmptyRef() Then
			Return NStr("en='The planning scenario for the specified name is not found.';ru='Не найден сценарий планирования по указанному наименованию.'");
		Else
			ParametersStructure.Insert("Scenario", ScenarioRef);
			ParametersStructure.Delete("PlanningScenarioDescription");
		EndIf;
	EndIf;
	
	Try
		
		ReaderXML = New XMLReader();
		ReaderXML.SetString(UnpackedStringXML);
		
		ObjectType_DB = XDTOFactory.Type("http://www.rarus.ru/ItemEng", "DB");
		objXDTO_DB = XDTOFactory.ReadXML(ReaderXML, ObjectType_DB);
		
	Except
		
		ParametersStructure.Insert("ErrorDescription", ErrorDescription());
	EndTry;
	
	If NOT ParametersStructure.Property("ErrorDescription") Then
		
		fmDataLoadingServerCall.LoadBatchXDTOInBudget(objXDTO_DB, ParametersStructure);
	EndIf;
	
	If ParametersStructure.Property("ErrorDescription") Then
		
		If TypeOf(ParametersStructure.ErrorDescription) = Type("String") Then
			
			Return ParametersStructure.ErrorDescription;
			
		ElsIf TypeOf(ParametersStructure.ErrorDescription) = Type("Array") Then
			
			_Message = "";
			
			For Each CurrMessage In ParametersStructure["ErrorDescription"] Do
				_Message = _Message + CurrMessage + ";" + Chars.LF;
			EndDo;
			
			Return _Message;
			
		Else
			
			Return NStr("en='Unknown errors occurred while loading/';ru='Произошли неизвестные ошибки загрузки/'");
			
		EndIf;
		
	Else
		
		Return NStr("en='Import finished successfully.';ru='Загрузка прошла успешно.'");
		
	EndIf;
	
EndFunction //DownloadBudgetInformation()

