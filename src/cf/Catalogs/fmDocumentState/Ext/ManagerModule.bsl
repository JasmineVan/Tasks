
#If Server OR ThickClientOrdinaryApplication OR ExternalConnection Then
Function GetSettings() Export
	
	Query = New Query("SELECT
	                      |	fmDocumentState.Ref AS Ref,
	                      |	fmDocumentState.Color AS TextColorXDTO
	                      |FROM
	                      |	Catalog.fmDocumentState AS fmDocumentState");
	
	XMLReader = New XMLReader;
	ObjectTypeXDTO	= XDTOFactory.Type("http://v8.1c.ru/8.1/data/ui","Color");
	
	SettingsRow = Query.Execute().SELECT();
	Settings = New ValueTable();
	Settings.Columns.Add("Ref");
	Settings.Columns.Add("Color");
	While SettingsRow.Next() Do
		If NOT IsBlankString(SettingsRow.TextColorXDTO) Then
			XMLReader.SetString(SettingsRow.TextColorXDTO);
			ObjectXDTO			=	XDTOFactory.ReadXML(XMLReader, ObjectTypeXDTO);
			Serializer		= New XDTOSerializer(XDTOFactory);
			NewLine = Settings.Add();
			NewLine.Color = Serializer.ReadXDTO(ObjectXDTO);
			NewLine.Ref = SettingsRow.Ref;
		EndIf;
	EndDo;
	
	Return Settings;
	
EndFunction
#EndIf
