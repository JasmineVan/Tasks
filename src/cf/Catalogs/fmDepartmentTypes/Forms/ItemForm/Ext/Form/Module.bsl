
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
		FieldTextColor = GetColorFromStringXML(Object.Color);
	Else
		FieldTextColor = New Color(0, 0, 0);
	EndIf;
EndProcedure

#EndRegion

#Region CommandHandlers

&AtClient
Procedure ColorOnChange(Item)
	ColorOnChangeServer();
EndProcedure

&AtServer
Procedure ColorOnChangeServer()
	Serializer = New XDTOSerializer(XDTOFactory);
	ObjectXDTO = Serializer.WriteXDTO(FieldTextColor);
	XMLWriter = New XMLWriter;
	XMLWriter.SetString();
	XDTOFactory.WriteXML(XMLWriter, ObjectXDTO);
	Object.Color = XMLWriter.Close();
EndProcedure

#EndRegion




