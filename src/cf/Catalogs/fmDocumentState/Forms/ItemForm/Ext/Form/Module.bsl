
#Region ProceduresAndFunctionsOfCommonUse

Function GetColorFromStringXML(StringXML)
	XMLReader = New XMLReader;
	ObjectTypeXDTO	= XDTOFactory.Type("http://v8.1c.ru/8.1/data/ui","Color");
	XMLReader.SetString(StringXML);
	ObjectXDTO = XDTOFactory.ReadXML(XMLReader, ObjectTypeXDTO);
	Serializer = New XDTOSerializer(XDTOFactory);
	Return Serializer.ReadXDTO(ObjectXDTO);
EndFunction

#EndRegion

#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If NOT Object.Color = "" Then
		Color = GetColorFromStringXML(Object.Color);
	Else
		Color = New Color(0, 0, 0);
	EndIf;
EndProcedure

#EndRegion

#Region CommandHandlers

&AtClient
Procedure ColorOnChange(Item)
	ColorOnChangeAtServer();
EndProcedure

&AtServer
Procedure ColorOnChangeAtServer()
	Serializer = New XDTOSerializer(XDTOFactory);
	ObjectXDTO = Serializer.WriteXDTO(Color);
	RecordXML = New XMLWriter;
	RecordXML.SetString();
	XDTOFactory.WriteXML(RecordXML, ObjectXDTO);
	Object.Color = RecordXML.Close();
EndProcedure

#EndRegion

