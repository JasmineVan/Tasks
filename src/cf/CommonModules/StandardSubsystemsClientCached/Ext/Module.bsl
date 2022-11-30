///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// See StandardSubsystemsClient.ClientParametersOnStart(). 
Function ClientParametersOnStart() Export
	
	CheckStartProcedureBeforeStart();
	
	ApplicationStartParameters = ApplicationParameters["StandardSubsystems.ApplicationRunParameters"];
	
	Parameters = New Structure;
	Parameters.Insert("RetrievedClientParameters", Undefined);
	
	If ApplicationStartParameters.Property("RetrievedClientParameters")
		AND TypeOf(ApplicationStartParameters.RetrievedClientParameters) = Type("Structure") Then
		
		Parameters.Insert("RetrievedClientParameters", CommonClientServer.CopyStructure(
			ApplicationStartParameters.RetrievedClientParameters));
	EndIf;
	
	If ApplicationStartParameters.Property("SkipClearingDesktopHiding") Then
		Parameters.Insert("SkipClearingDesktopHiding");
	EndIf;
	
	Parameters.Insert("LaunchParameter", LaunchParameter);
	Parameters.Insert("InfobaseConnectionString", InfoBaseConnectionString());
	Parameters.Insert("IsWebClient", IsWebClient());
	Parameters.Insert("IsLinuxClient", CommonClient.IsLinuxClient());
	Parameters.Insert("IsOSXClient", CommonClient.IsOSXClient());
	Parameters.Insert("IsWindowsClient", CommonClient.IsWindowsClient());
	Parameters.Insert("IsMobileClient", IsMobileClient());
	Parameters.Insert("ClientUsed", ClientUsed());
	Parameters.Insert("ApplicationDirectory", CurrentAppllicationDirectory());
	Parameters.Insert("ClientID", ClientID());
	Parameters.Insert("HideDesktopOnStart", False);
	Parameters.Insert("RAM", CommonClient.RAMAvailableForClientApplication());
	Parameters.Insert("MainDisplayResolution", MainDisplayResolution());
	
	// Setting client's date before the call, in order to reduce the error limit.
	Parameters.Insert("CurrentDateOnClient", CurrentDate()); // To calculate SessionTimeOffset.
	Parameters.Insert("CurrentUniversalDateInMillisecondsOnClient", CurrentUniversalDateInMilliseconds());
	
	If ApplicationStartParameters.Property("InterfaceOptions")
	   AND TypeOf(Parameters.RetrievedClientParameters) = Type("Structure") Then
		
		Parameters.RetrievedClientParameters.Insert("InterfaceOptions");
	EndIf;
	
	ClientParameters = StandardSubsystemsServerCall.ClientParametersOnStart(Parameters);
	
	If ApplicationStartParameters.Property("RetrievedClientParameters")
		AND ApplicationStartParameters.RetrievedClientParameters <> Undefined
		AND Not ApplicationStartParameters.Property("InterfaceOptions") Then
		
		ApplicationStartParameters.Insert("InterfaceOptions", ClientParameters.InterfaceOptions);
	EndIf;
	
	StandardSubsystemsClient.FillClientParameters(ClientParameters);
	
	// Updating the desktop hiding status on client by the state on server.
	StandardSubsystemsClient.HideDesktopOnStart(
		Parameters.HideDesktopOnStart, True);
	
	Return ClientParameters;
	
EndFunction

// See StandardSubsystemsClient.ClientRunParameters(). 
Function ClientRunParameters() Export
	
	CheckStartProcedureBeforeStart();
	CheckStartProcedureOnStart();
	
	ClientProperties = New Structure;
	
	// Setting client's date before the call, in order to reduce the error limit.
	ClientProperties.Insert("CurrentDateOnClient", CurrentDate()); // To calculate SessionTimeOffset.
	ClientProperties.Insert("CurrentUniversalDateInMillisecondsOnClient",
		CurrentUniversalDateInMilliseconds());
	
	Return StandardSubsystemsServerCall.ClientRunParameters(ClientProperties);
	
EndFunction

#Region PredefinedItem

// See StandardSubsystemsCached.RefsByPredefinedItemsNames 
Function RefsByPredefinedItemsNames(FullMetadataObjectName) Export
	
	Return StandardSubsystemsServerCall.RefsByPredefinedItemsNames(FullMetadataObjectName);
	
EndFunction

#EndRegion

Procedure CheckStartProcedureBeforeStart()
	
	ParameterName = "StandardSubsystems.ApplicationStartCompleted";
	If ApplicationParameters[ParameterName] = Undefined Then
		Raise
			NStr("ru = 'Ошибка порядка запуска программы.
			           |Первой процедурой, которая вызывается из обработчика события ПередНачаломРаботыСистемы
			           |должна быть процедура БСП СтандартныеПодсистемыКлиент.ПередНачаломРаботыСистемы.'; 
			           |en = 'Application startup sequence error.
			           |The BeforeStart event handler must call the
			           |StandardSubsystemsClient.BeforeStart procedure first.'; 
			           |pl = 'Błąd kolejności uruchamiania programu. 
			           |pierwszą procedurą, która zgłasza się z modułu obsługi zdarzeń PrzedPoczątkiemPracySystemu
			           |powinna być procedura BSP StandardowePodsystemyKlient.PrzedPoczątkiemPracySystemu.';
			           |de = 'Fehler bei der Programmstartreihenfolge.
			           |Die erste Prozedur, die aus dem Eventhandler VorDemSystemstart aufgerufen wird,
			           |sollte die Prozedur BSP StandardSubsystemClient.VorDemSystemstart';
			           |ro = 'Eroare a ordinii de lansare a aplicației.
			           |Prima procedură care se solicită din handlerul evenimentului ПередНачаломРаботыСистемы
			           |trebuie să fie procedura LSS СтандартныеПодсистемыКлиент.ПередНачаломРаботыСистемы.';
			           |tr = 'Uygulama başlatma düzeninin hatası. 
			           |SistemÇalışmayaBaşlamadanÖnce olay işleyicisinden çağrılan ilk prosedür, StandartAltSistemlerİstemci.SistemÇalışmayaBaşlamadanÖnce BSP prosedürü 
			           |olmalıdır.'; 
			           |es_ES = 'Error de orden de lanzar el programa.
			           |El primer procedimiento que se llama del procesador del evento BeforeStart
			           | debe ser el procedimiento StandardSubsystemsClient.BeforeStart.'");
	EndIf;
	
EndProcedure

Procedure CheckStartProcedureOnStart()
	
	If Not StandardSubsystemsClient.ApplicationStartCompleted() Then
		Raise
			NStr("ru = 'Ошибка порядка запуска программы.
			           |Перед получением параметров работы клиента запуск программы должен быть завершен.'; 
			           |en = 'Application startup sequence error.
			           |Application startup must be completed before getting the client parameters.'; 
			           |pl = 'Błąd kolejności uruchamiania programu. 
			           |Przed uzyskaniem parametrów pracy klienta uruchomienie programu powinno być zakończone.';
			           |de = 'Fehler beim Programmstartreihenfolge.
			           |Bevor Sie die Client-Betriebsparameter empfangen, muss der Programmstart abgeschlossen sein.';
			           |ro = 'Eroare a ordinii de lansare a aplicației.
			           |Înainte de obținerea parametrilor de lucru ai clientului trebuie să finalizați lansarea aplicației.';
			           |tr = 'Uygulama başlatma düzeninin hatası. 
			           |İstemci çalışma ayarlarını almadan önce, programın çalıştırılması tamamlanmalıdır.'; 
			           |es_ES = 'Error de orden de lanzar el programa.
			           |Antes de recibir los parámetros del funcionamiento del cliente el lanzamiento del programa debe ser terminado.'");
	EndIf;
	
EndProcedure

#Region ClientRunParametersOnStart

Function ClientUsed()
	
	ClientUsed = "";
	#If ThinClient Then
		ClientUsed = "ThinClient";
	#ElsIf ThickClientManagedApplication Then
		ClientUsed = "ThickClientManagedApplication";
	#ElsIf ThickClientOrdinaryApplication Then
		ClientUsed = "ThickClientOrdinaryApplication";
	#ElsIf WebClient Then
		BrowserDetails = CurrentBrowser();
		If IsBlankString(BrowserDetails.Version) Then
			ClientUsed = StringFunctionsClientServer.SubstituteParametersToString("WebClient.%1", BrowserDetails.Name);
		Else
			ClientUsed = StringFunctionsClientServer.SubstituteParametersToString("WebClient.%1.%2", BrowserDetails.Name, StrSplit(BrowserDetails.Version, ".")[0]);
		EndIf;
	#EndIf
	
	Return ClientUsed;
	
EndFunction

Function CurrentBrowser()
	
	Result = New Structure("Name,Version", "Other", "");
	
	SystemInfo = New SystemInfo;
	Row = SystemInfo.UserAgentInformation;
	Row = StrReplace(Row, ",", ";");

	// Opera
	ID = "Opera";
	Position = StrFind(Row, ID, SearchDirection.FromEnd);
	If Position > 0 Then
		Row = Mid(Row, Position + StrLen(ID));
		Result.Name = "Opera";
		ID = "Version/";
		Position = StrFind(Row, ID);
		If Position > 0 Then
			Row = Mid(Row, Position + StrLen(ID));
			Result.Version = TrimAll(Row);
		Else
			Row = TrimAll(Row);
			If StrStartsWith(Row, "/") Then
				Row = Mid(Row, 2);
			EndIf;
			Result.Version = TrimL(Row);
		EndIf;
		Return Result;
	EndIf;

	// IE
	ID = "MSIE"; // v11-
	Position = StrFind(Row, ID);
	If Position > 0 Then
		Result.Name = "IE";
		Row = Mid(Row, Position + StrLen(ID));
		Position = StrFind(Row, ";");
		If Position > 0 Then
			Row = TrimL(Left(Row, Position - 1));
			Result.Version = Row;
		EndIf;
		Return Result;
	EndIf;

	ID = "Trident"; // v11+
	Position = StrFind(Row, ID);
	If Position > 0 Then
		Result.Name = "IE";
		Row = Mid(Row, Position + StrLen(ID));
		
		ID = "rv:";
		Position = StrFind(Row, ID);
		If Position > 0 Then
			Row = Mid(Row, Position + StrLen(ID));
			Position = StrFind(Row, ")");
			If Position > 0 Then
				Row = TrimL(Left(Row, Position - 1));
				Result.Version = Row;
			EndIf;
		EndIf;
		Return Result;
	EndIf;

	// Chrome
	ID = "Chrome/";
	Position = StrFind(Row, ID);
	If Position > 0 Then
		Result.Name = "Chrome";
		Row = Mid(Row, Position + StrLen(ID));
		Position = StrFind(Row, " ");
		If Position > 0 Then
			Row = TrimL(Left(Row, Position - 1));
			Result.Version = Row;
		EndIf;
		Return Result;
	EndIf;

	// Safari
	ID = "Safari/";
	If StrFind(Row, ID) > 0 Then
		Result.Name = "Safari";
		ID = "Version/";
		Position = StrFind(Row, ID);
		If Position > 0 Then
			Row = Mid(Row, Position + StrLen(ID));
			Position = StrFind(Row, " ");
			If Position > 0 Then
				Result.Version = TrimAll(Left(Row, Position - 1));
			EndIf;
		EndIf;
		Return Result;
	EndIf;

	// Firefox
	ID = "Firefox/";
	Position = StrFind(Row, ID);
	If Position > 0 Then
		Result.Name = "Firefox";
		Row = Mid(Row, Position + StrLen(ID));
		If Not IsBlankString(Row) Then
			Result.Version = TrimAll(Row);
		EndIf;
		Return Result;
	EndIf;
	
	Return Result;
	
EndFunction

Function CurrentAppllicationDirectory()
	
	#If WebClient Or MobileClient Then
		ApplicationDirectory = "";
	#Else
		ApplicationDirectory = BinDir();
	#EndIf
	
	Return ApplicationDirectory;
	
EndFunction

Function MainDisplayResolution()
	
	ClientDisplaysInformation = GetClientDisplaysInformation();
	If ClientDisplaysInformation.Count() > 0 Then
		DPI = ClientDisplaysInformation[0].DPI;
		MainDisplayResolution = ?(DPI = 0, 72, DPI);
	Else
		MainDisplayResolution = 72;
	EndIf;
	
	Return MainDisplayResolution;
	
EndFunction

Function ClientID()
	
	SystemInformation = New SystemInfo;
	Return SystemInformation.ClientID;
	
EndFunction

Function IsWebClient() Export
	
#If WebClient Then
	Return True;
#Else
	Return False;
#EndIf
	
EndFunction

Function IsMobileClient() Export
	
#If MobileClient Then
	Return True;
#Else
	Return False;
#EndIf
	
EndFunction

#EndRegion

#EndRegion
