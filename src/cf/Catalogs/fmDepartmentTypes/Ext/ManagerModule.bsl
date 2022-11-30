
#If Server OR ThickClientOrdinaryApplication OR ExternalConnection Then
Function GetSettings() Export
	
	Query = New Query("SELECT
	                      |	fmDepartmentTypes.Ref AS DepartmentType,
	                      |	fmDepartmentTypes.Color AS TextColorXDTO
	                      |FROM
	                      |	Catalog.fmDepartmentTypes AS fmDepartmentTypes");
	
	XMLReader = New XMLReader;
	XDTOObjectType	= XDTOFactory.Type("http://v8.1c.ru/8.1/data/ui","Color");
	
	SettingsRow = Query.Execute().Select();
	Settings = New ValueTable();
	Settings.Columns.Add("DepartmentType");
	Settings.Columns.Add("Color");
	While SettingsRow.Next() Do
		If NOT IsBlankString(SettingsRow.TextColorXDTO) Then
			XMLReader.SetString(SettingsRow.TextColorXDTO);
			XDTOObject		=	XDTOFactory.ReadXML(XMLReader, XDTOObjectType);
			Serializer		= New XDTOSerializer(XDTOFactory);
			NewLine = Settings.Add();
			NewLine.Color = Serializer.ReadXDTO(XDTOObject);
			NewLine.DepartmentType = SettingsRow.DepartmentType;
		EndIf;
	EndDo;
	
	Return Settings;
	
EndFunction
#EndIf


