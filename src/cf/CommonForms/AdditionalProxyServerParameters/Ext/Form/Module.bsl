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
	
	// Fill out the form
	Server      = Parameters.Server;
	Port        = Parameters.Port;
	
	HTTPServer  = Parameters.HTTPServer;
	HTTPPort    = Parameters.HTTPPort;
	
	HTTPSServer = Parameters.HTTPSServer;
	HTTPSPort   = Parameters.HTTPSPort;
	
	FTPServer   = Parameters.FTPServer;
	FTPPort     = Parameters.FTPPort;
	
	AllProtocolsThroughSingleProxy = Parameters.AllProtocolsThroughSingleProxy;
	
	InitializeFormItems(ThisObject);
	
	For each ExceptionListItem In Parameters.BypassProxyOnAddresses Do
		ExceptionStr = ExceptionsAddresses.Add();
		ExceptionStr.ServerAddress = ExceptionListItem.Value;
	EndDo;
	
	StandardSubsystemsServer.SetGroupTitleRepresentation(ThisObject);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OneProxyForAllProtocolsOnChange(Item)
	
	InitializeFormItems(ThisObject);
	
EndProcedure

&AtClient
Procedure HTTPServerOnChange(Item)
	
	// If the server is not specified, then reset the corresponding port.
	If IsBlankString(ThisObject[Item.Name]) Then
		ThisObject[StrReplace(Item.Name, "Server", "Port")] = 0;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure OKButton(Command)
	
	If Not Modified Then
		// If the form data were not changed, they need not be returned.
		// 
		NotifyChoice(Undefined);
		Return;
	EndIf;
	
	If Not ValidateExceptionServerAddresses() Then
		Return;
	EndIf;
	
	// If the form is successfully validated, then the additional proxy server settings are returned to 
	// the structure.
	ReturnValueStructure = New Structure;
	
	ReturnValueStructure.Insert("AllProtocolsThroughSingleProxy", AllProtocolsThroughSingleProxy);
	
	ReturnValueStructure.Insert("HTTPServer" , HTTPServer);
	ReturnValueStructure.Insert("HTTPPort"   , HTTPPort);
	ReturnValueStructure.Insert("HTTPSServer", HTTPSServer);
	ReturnValueStructure.Insert("HTTPSPort"  , HTTPSPort);
	ReturnValueStructure.Insert("FTPServer"  , FTPServer);
	ReturnValueStructure.Insert("FTPPort"    , FTPPort);
	
	ExceptionsList = New ValueList;
	
	For each AddressStr In ExceptionsAddresses Do
		If NOT IsBlankString(AddressStr.ServerAddress) Then
			ExceptionsList.Add(AddressStr.ServerAddress);
		EndIf;
	EndDo;
	
	ReturnValueStructure.Insert("BypassProxyOnAddresses", ExceptionsList);
	
	NotifyChoice(ReturnValueStructure);
	
EndProcedure

#EndRegion

#Region Private

// Generates form items in accordance with the proxy server settings.
// 
//
&AtClientAtServerNoContext
Procedure InitializeFormItems(Form)
	
	Form.Items.ProxyServersGroup.Enabled = NOT Form.AllProtocolsThroughSingleProxy;
	If Form.AllProtocolsThroughSingleProxy Then
		
		Form.HTTPServer  = Form.Server;
		Form.HTTPPort    = Form.Port;
		
		Form.HTTPSServer = Form.Server;
		Form.HTTPSPort   = Form.Port;
		
		Form.FTPServer   = Form.Server;
		Form.FTPPort     = Form.Port;
		
	EndIf;
	
EndProcedure

// Validates the correctness of exception server addresses.
// It also informs users on incorrectly filled addresses.
//
// Returns: Boolean - True if addresses are correct,
//						  otherwise False.
//
&AtClient
Function ValidateExceptionServerAddresses()
	
	AddressesAreCorrect = True;
	For each StrAddress In ExceptionsAddresses Do
		If NOT IsBlankString(StrAddress.ServerAddress) Then
			InvalidChars = ProhibitedCharsInString(StrAddress.ServerAddress,
				"0123456789aAbBcCdDeEfFgGhHiIjJkKlLmMnNoOpPqQrRsStTuUvVwWxXyYzZ_-.:*?");
			
			If NOT IsBlankString(InvalidChars) Then
				
				MessageText = StrReplace(NStr("ru = 'В адресе найдены недопустимые символы: %1'; en = 'The address contains prohibited characters: %1'; pl = 'Adres zawiera nieprawidłowe znaki: %1';de = 'Adresse enthält ungültige Zeichen: %1';ro = 'Adresa conține caractere inadmisibile: %1';tr = 'Adres geçersiz karakterler içeriyor:%1'; es_ES = 'Dirección contiene símbolos inválidos: %1'"),
					"%1",
					InvalidChars);
				
				IndexAsString = StrReplace(String(ExceptionsAddresses.IndexOf(StrAddress)), Char(160), "");
				
				CommonClient.MessageToUser(MessageText,
					,
					"ExceptionsAddresses[" + IndexAsString + "].ServerAddress");
				AddressesAreCorrect = False;
				
			EndIf;
		EndIf;
	EndDo;
	
	Return AddressesAreCorrect;
	
EndFunction

// Finds and returns comma-separated strings of prohibited characters.
//
// Parameters:
//	StringToValidate (String) - string being checked for invalid characters.
//								 
//	AllowedChars (String) - string containing valid characters.
//
// Returns: String - string containing invalid characters. Empty string, if the string under 
//						  validation contains no prohibited characters.
//
&AtClient
Function ProhibitedCharsInString(RowToValidate, AllowedChars)
	
	ProhibitedCharList = New ValueList;
	
	StringLength = StrLen(RowToValidate);
	For Iterator = 1 To StringLength Do
		CurrentChar = Mid(RowToValidate, Iterator, 1);
		If StrFind(AllowedChars, CurrentChar) = 0 Then
			If ProhibitedCharList.FindByValue(CurrentChar) = Undefined Then
				ProhibitedCharList.Add(CurrentChar);
			EndIf;
		EndIf;
	EndDo;
	
	ProhibitedCharString = "";
	Comma                    = False;
	
	For each ProhibitedCharItem In ProhibitedCharList Do
		
		ProhibitedCharString = ProhibitedCharString
			+ ?(Comma, ",", "")
			+ """"
			+ ProhibitedCharItem.Value
			+ """";
		Comma = True;
		
	EndDo;
	
	Return ProhibitedCharString;
	
EndFunction

#EndRegion
