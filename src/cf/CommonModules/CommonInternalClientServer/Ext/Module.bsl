///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

#Region RunExternalApplications

Function SafeCommandString(StartupCommand) Export
	
	Result = "";
	
	If TypeOf(StartupCommand) = Type("String") Then 
		
		If ContainsUnsafeActions(StartupCommand) Then 
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось запустить программу
				           |по причине:
				           |Недопустимая строка команды
				           |%1
				           |по причине:
				           |Строка команды не должна содержать символы: ""$"", ""`"", ""|"", "";"", ""&"".'; 
				           |en = 'Application start failed.
				           |Reason:
				           |Invalid command line
				           |%1
				           |Details:
				           |Command line contains illegal characters: $ ` | ; &.'; 
				           |pl = 'Nie można uruchomić programu
				           |z powodu:
				           |Nieprawidłowy wiersz polecenia
				           |%1
				           |z powodu:
				           |Wiersz poleceń nie powinien zawierać znaków: ""$"", ""`"", ""|"", "";"", ""&"".';
				           |de = 'Es war nicht möglich, das Programm zu starten
				           |,weil:
				           |Ungültige Befehlszeile
				           |%1
				           |weil:
				           |Befehlszeile keine Symbole enthalten sollte: ""$"", ""`"", ""|"", "";"", ""&"".';
				           |ro = 'Eșec la lansarea aplicației
				           |din motivul:
				           |Linie de comandă inadmisibilă
				           |%1
				           |din motivul:
				           |Linia de comandă nu trebuie să conțină simbolurile: ""$"", ""`"", ""|"", "";"", ""&"".';
				           |tr = 'Program aşağıdaki nedenle başlatılamadı
				           |:
				           |İzin verilmeyen komut satırı
				           |%1
				           |nedeni:
				           |Komut satırı aşağıdaki sembolleri içermemelidir: ""$"", ""`"", ""|"", "";"", ""&"".'; 
				           |es_ES = 'No se ha podido lanzar el programa
				           |a causa de: 
				           |Línea no admitida del comando
				           |%1
				           |a causa de:
				           |Línea del comando no debe contener símbolos: ""$"", ""`"", ""|"", "";"", ""&"".'"),
				StartupCommand);
		EndIf;
		
		Result = StartupCommand;
		
	ElsIf TypeOf(StartupCommand) = Type("Array") Then
		
		If StartupCommand.Count() > 0 Then 
			
			If ContainsUnsafeActions(StartupCommand[0]) Then
				Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось запустить программу
				           |по причине:
				           |Недопустимая команда или путь к исполняемому файлу
				           |%1
				           |по причине:
				           |Команды не должна содержать символы: ""$"", ""`"", ""|"", "";"", ""&"".'; 
				           |en = 'Application start failed.
				           |Reason:
				           |Invalid command or path the executable file
				           |%1
				           |Details:
				           |Command contains illegal characters: $ ` | ; &.'; 
				           |pl = 'Nie można uruchomić programu
				           |z powodu:
				           |Nieprawidłowe polecenie lub ścieżka do pliku wykonywalnego
				           |%1
				           |z powodu:
				           |Polecenia nie mogą zawierać znaków: ""$"", ""`"", ""|"", "";"", ""&"".';
				           |de = 'Es war nicht möglich, das Programm zu starten
				           |, weil:
				           |Ungültiger Befehl oder Pfad zur ausführbaren Datei
				           |%1
				           |, weil:
				           |Befehle keine Symbole enthalten sollten: ""$"", ""`"", ""|"", "";"", ""&"".';
				           |ro = 'Eșec la lansarea aplicației
				           |din motivul:
				           |Comandă sau cale inadmisibilă spre fișierul executat
				           |%1
				           |din motivul:
				           |Comanda nu trebuie să conțină simbolurile: ""$"", ""`"", ""|"", "";"", ""&"".';
				           |tr = 'Program aşağıdaki nedenle başlatılamadı
				           |:
				           |İzin verilmeyen komut yada yürütülen dosyanın kısayolu
				           |%1
				           |nedeni:
				           |Komut satırı aşağıdaki sembolleri içermemelidir: ""$"", ""`"", ""|"", "";"", ""&"".'; 
				           |es_ES = 'No se ha podido lanzar el programa
				           |a causa de: 
				           |Comando o ruta al archivo ejecutivo no admitidos
				           |%1
				           |a causa de:
				           |El comando no debe contener símbolos: ""$"", ""`"", ""|"", "";"", ""&"".'"),
				StartupCommand[0]);
			EndIf;
			
			Result = ArrayToCommandString(StartupCommand);
			
		Else
			Raise
				NStr("ru = 'Ожидалось, что первый элемент массива КомандаЗапуска будет командой или путем к исполняемому файлу.'; en = 'The first element of the StartupCommand array must be a command or the path to an executable file.'; pl = 'Było oczekiwano, że pierwszy element tablicy КомандаЗапуска będzie poleceniem lub drogą do wykonywanego pliku.';de = 'Das erste Element des Arrays StartBefehl sollte ein Befehl oder Pfad zur ausführbaren Datei sein.';ro = 'Se aștepta că primul element al mulțimii КомандаЗапуска va fi comandă sau cale la fișierul executat.';tr = 'BaşlatmaKomutu ilk öğenin bir komut veya yürütülenr dosyanın kısayolu olması bekleniyordu.'; es_ES = 'Se esperaba que el primer elemento de matriz КомандаЗапуска será comando o ruta al archivo ejecutivo.'");
		EndIf;
		
	Else 
		Raise 
			NStr("ru = 'Ожидалось, что значение КомандаЗапуска будет <Строка> или <Массив>'; en = 'StartupCommand value must be of the String or Array type.'; pl = 'Było oczekiwano, że wartość КомандаЗапуска będzie <Wiersz> lub <Tablica>';de = 'Es wurde erwartet, dass der Startbefehl <String> oder <Array> lautet';ro = 'Se aștepta că valoarea КомандаЗапуска va fi <Строка> sau <Массив>';tr = 'BaşlatmaKomutu değerinin <Satır> veya <Masif> olması bekleniyordu'; es_ES = 'Se esperaba que el valor КомандаЗапуска será <Línea> o <Matriz>'");
	EndIf;
		
	Return Result
	
EndFunction

#EndRegion

#Region SpreadsheetDocument

////////////////////////////////////////////////////////////////////////////////
// Spreadsheet document functions.

// Calculates indicators of numeric cells in a spreadsheet document.
//
// Parameters:
//   CalculationParameters - Structure - see also: CommonInternalClient.CellsIndicatorsCalculationParameters.
//
// Returns:
//   Structure - results of selected cell calculation.
//       * Count - Number - selected cells count.
//       * NumericCellsCount - Number - numeric cells count.
//       * Sum - Number - a sum of the selected cells with numbers.
//       * Average - Number - a sum of the selected cells with numbers.
//       * Minimum - Number - a sum of the selected cells with numbers.
//       * Maximum - Number - a sum of the selected cells with numbers.
//
Function CalculationCellsIndicators(Val SpreadsheetDocument, SelectedAreas) Export 
	CalculationIndicators = New Structure;
	CalculationIndicators.Insert("Count", 0);
	CalculationIndicators.Insert("FilledCellsCount", 0);
	CalculationIndicators.Insert("NumericCellsCount", 0);
	CalculationIndicators.Insert("Sum", 0);
	CalculationIndicators.Insert("Mean", 0);
	CalculationIndicators.Insert("Minimum", 0);
	CalculationIndicators.Insert("Maximum", 0);
	
	If SelectedAreas = Undefined Then
		SelectedAreas = SpreadsheetDocument.SelectedAreas;
	EndIf;
	
	CheckedCells = New Map;
	
	For Each SelectedArea In SelectedAreas Do
		If TypeOf(SelectedArea) <> Type("SpreadsheetDocumentRange")
			AND TypeOf(SelectedArea) <> Type("Structure") Then
			Continue;
		EndIf;
		
		SelectedAreaTop  = SelectedArea.Top;
		SelectedAreaBottom   = SelectedArea.Bottom;
		SelectedAreaLeft  = SelectedArea.Left;
		SelectedAreaRight = SelectedArea.Right;
		
		If SelectedAreaTop = 0 Then
			SelectedAreaTop = 1;
		EndIf;
		
		If SelectedAreaBottom = 0 Then
			SelectedAreaBottom = SpreadsheetDocument.TableHeight;
		EndIf;
		
		If SelectedAreaLeft = 0 Then
			SelectedAreaLeft = 1;
		EndIf;
		
		If SelectedAreaRight = 0 Then
			SelectedAreaRight = SpreadsheetDocument.TableWidth;
		EndIf;
		
		If SelectedArea.AreaType = SpreadsheetDocumentCellAreaType.Columns Then
			SelectedAreaTop = SelectedArea.Bottom;
			SelectedAreaBottom = SpreadsheetDocument.TableHeight;
		EndIf;
		
		SelectedAreaHeight = SelectedAreaBottom   - SelectedAreaTop + 1;
		SelectedAreaWidth = SelectedAreaRight - SelectedAreaLeft + 1;
		
		CalculationIndicators.Count = CalculationIndicators.Count + SelectedAreaWidth * SelectedAreaHeight;
		
		For ColumnNumber = SelectedAreaLeft To SelectedAreaRight Do
			For RowNumber = SelectedAreaTop To SelectedAreaBottom Do
				Cell = SpreadsheetDocument.Area(RowNumber, ColumnNumber, RowNumber, ColumnNumber);
				If CheckedCells.Get(Cell.Name) = Undefined Then
					CheckedCells.Insert(Cell.Name, True);
				Else
					Continue;
				EndIf;
				
				If Cell.Visible = True Then
					If Cell.AreaType <> SpreadsheetDocumentCellAreaType.Columns
						AND Cell.ContainsValue AND TypeOf(Cell.Value) = Type("Number") Then
						Number = Cell.Value;
					ElsIf ValueIsFilled(Cell.Text) Then
						TypeDescriptionNumber = New TypeDescription("Number");
						
						CellText = Cell.Text;
						If StrStartsWith(CellText, "(")
							AND StrEndsWith(CellText, ")") Then 
							
							CellText = StrReplace(CellText, "(", "");
							CellText = StrReplace(CellText, ")", "");
							
							Number = TypeDescriptionNumber.AdjustValue(CellText);
							If Number > 0 Then 
								Number = -Number;
							EndIf;
						Else
							Number = TypeDescriptionNumber.AdjustValue(CellText);
						EndIf;
					Else
						Continue;
					EndIf;
					
					CalculationIndicators.FilledCellsCount = CalculationIndicators.FilledCellsCount + 1;
					If TypeOf(Number) = Type("Number") Then
						CalculationIndicators.NumericCellsCount = CalculationIndicators.NumericCellsCount + 1;
						CalculationIndicators.Sum = CalculationIndicators.Sum + Number;
						If CalculationIndicators.NumericCellsCount = 1 Then
							CalculationIndicators.Minimum  = Number;
							CalculationIndicators.Maximum = Number;
						Else
							CalculationIndicators.Minimum  = Min(Number,  CalculationIndicators.Minimum);
							CalculationIndicators.Maximum = Max(Number, CalculationIndicators.Maximum);
						EndIf;
					EndIf;
				EndIf;
			EndDo;
		EndDo;
	EndDo;
	
	If CalculationIndicators.NumericCellsCount > 0 Then
		CalculationIndicators.Mean = CalculationIndicators.Sum / CalculationIndicators.NumericCellsCount;
	EndIf;
	
	Return CalculationIndicators;
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region UserNotification

Procedure MessageToUser(
		Val MessageToUserText,
		Val DataKey,
		Val Field,
		Val DataPath = "",
		Cancel = False,
		IsObject = False) Export
	
	Message = New UserMessage;
	Message.Text = MessageToUserText;
	Message.Field = Field;
	
	If IsObject Then
		Message.SetData(DataKey);
	Else
		Message.DataKey = DataKey;
	EndIf;
	
	If NOT IsBlankString(DataPath) Then
		Message.DataPath = DataPath;
	EndIf;
	
	Message.Message();
	
	Cancel = True;
	
EndProcedure

#EndRegion

#Region InfobaseData

#Region PredefinedItem

Function UseStandardGettingPredefinedItemFunction(PredefinedItemFullName) Export
	
	// Using a standard function to get:
	//  - blank references
	//  - enumeration values
	//  - business process route points
	
	Return ".EMPTYREF" = Upper(Right(PredefinedItemFullName, 13))
		Or "ENUM." = Upper(Left(PredefinedItemFullName, 13))
		Or "BUSINESSPROCESS." = Upper(Left(PredefinedItemFullName, 14));
	
EndFunction

Function PredefinedItemNameByFields(PredefinedItemFullName) Export
	
	FullNameParts = StrSplit(PredefinedItemFullName, ".");
	If FullNameParts.Count() <> 3 Then 
		Raise PredefinedValueNotFoundErrorText(PredefinedItemFullName);
	EndIf;
	
	FullMetadataObjectName = Upper(FullNameParts[0] + "." + FullNameParts[1]);
	PredefinedItemName = FullNameParts[2];
	
	Result = New Structure;
	Result.Insert("FullMetadataObjectName", FullMetadataObjectName);
	Result.Insert("PredefinedItemName", PredefinedItemName);
	
	Return Result;
	
EndFunction

Function PredefinedItem(PredefinedItemFullName, PredefinedItemFields, PredefinedValues) Export
	
	// In case of error in metadata name.
	If PredefinedValues = Undefined Then 
		Raise PredefinedValueNotFoundErrorText(PredefinedItemFullName);
	EndIf;
	
	// Getting result from cache.
	Result = PredefinedValues.Get(PredefinedItemFields.PredefinedItemName);
	
	// If the predefined item does not exist in metadata.
	If Result = Undefined Then 
		Raise PredefinedValueNotFoundErrorText(PredefinedItemFullName);
	EndIf;
	
	// If the predefined item exists in metadata but not in the infobase.
	If Result = Null Then 
		Return Undefined;
	EndIf;
	
	Return Result;
	
EndFunction

Function PredefinedValueNotFoundErrorText(PredefinedItemFullName) Export
	
	Return StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Предопределенное значение ""%1"" не найдено.'; en = 'Predefined value ""%1"" is not found.'; pl = 'Predefiniowaną wartość ""%1"" nie znaleziono.';de = 'Vordefinierter Wert ""%1"" wurde nicht gefunden.';ro = 'Valoarea predefinită ""%1"" nu a fost găsită.';tr = 'Önceden tanımlanmış ""%1"" değeri bulunamadı.'; es_ES = 'Valor predeterminado ""%1"" no encontrado.'"), PredefinedItemFullName);
	
EndFunction

#EndRegion

#EndRegion

#Region Dates

Function LocalDatePresentationWithOffset(LocalDate, Offset) Export
	
	OffsetPresentation = "Z";
	
	If Offset > 0 Then
		OffsetPresentation = "+";
	ElsIf Offset < 0 Then
		OffsetPresentation = "-";
		Offset = -Offset;
	EndIf;
	
	If Offset <> 0 Then
		OffsetPresentation = OffsetPresentation + Format('00010101' + Offset, "DF=HH:mm");
	EndIf;
	
	Return Format(LocalDate, "DF=yyyy-MM-ddTHH:mm:ss; DE=0001-01-01T00:00:00") + OffsetPresentation;
	
EndFunction

#EndRegion

#Region ExternalConnection

Function EstablishExternalConnectionWithInfobase(Parameters, ConnectionUnavailable, BriefErrorDescription) Export
	
	Result = New Structure;
	Result.Insert("Connection");
	Result.Insert("BriefErrorDescription", "");
	Result.Insert("DetailedErrorDescription", "");
	Result.Insert("AddInAttachmentError", False);
	
#If MobileClient Then
	
	ErrorMessageString = NStr("ru = 'Подключение к другой программе не доступно в мобильном клиенте.'; en = 'Mobile client does not support connecting other applications.'; pl = 'Połączenie z innym programem nie jest dostępne w kliencie mobilnym.';de = 'Die Verbindung zu einem anderen Programm ist im mobilen Client nicht verfügbar.';ro = 'Conectarea la alt program nu este disponibilă în clientul mobil.';tr = 'Mobil istemcide başka programa bağlantıya izin verilmez.'; es_ES = 'La conexión a otro programa no está disponible en el cliente móvil.'");
	
	Result.AddInAttachmentError = True;
	Result.DetailedErrorDescription = ErrorMessageString;
	Result.BriefErrorDescription = ErrorMessageString;
	
	Return Result;
	
#Else
	
	If ConnectionUnavailable Then
		Result.Connection = Undefined;
		Result.BriefErrorDescription = BriefErrorDescription;
		Result.DetailedErrorDescription = BriefErrorDescription;
		Return Result;
	EndIf;
	
	Try
		COMConnector = New COMObject(CommonClientServer.COMConnectorName()); // "V83.COMConnector"
	Except
		Information = ErrorInfo();
		ErrorMessageString = NStr("ru = 'Не удалось подключится к другой программе: %1'; en = 'Failed to connect to another application: %1'; pl = 'Nie można połączyć się z inną aplikacją: %1';de = 'Kann keine Verbindung zu einer anderen Anwendung herstellen: %1';ro = 'Nu se poate conecta la o altă aplicație: %1';tr = 'Başka bir uygulamaya bağlanılamıyor: %1'; es_ES = 'No se puede conectar a otra aplicación: %1'");
		
		Result.AddInAttachmentError = True;
		Result.DetailedErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(ErrorMessageString, DetailErrorDescription(Information));
		Result.BriefErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(ErrorMessageString, BriefErrorDescription(Information));
		
		Return Result;
	EndTry;
	
	FileRunMode = Parameters.InfobaseOperatingMode = 0;
	
	// Checking parameter correctness.
	FillingCheckError = False;
	If FileRunMode Then
		
		If IsBlankString(Parameters.InfobaseDirectory) Then
			ErrorMessageString = NStr("ru = 'Не задано месторасположение каталога информационной базы.'; en = 'The infobase directory is not specified.'; pl = 'Lokalizacja katalogu bazy informacyjnej nie jest określona.';de = 'Der Speicherort des Infobase-Verzeichnisses ist nicht angegeben.';ro = 'Locația directorului bazei de date nu este specificată.';tr = 'Veritabanın dizininin yeri belirlenmemiştir.'; es_ES = 'Ubicación del directorio de la infobase no está especificada.'");
			FillingCheckError = True;
		EndIf;
		
	Else
		
		If IsBlankString(Parameters.NameOf1CEnterpriseServer) Or IsBlankString(Parameters.NameOfInfobaseOn1CEnterpriseServer) Then
			ErrorMessageString = NStr("ru = 'Не заданы обязательные параметры подключения: ""Имя сервера""; ""Имя информационной базы на сервере"".'; en = 'Required connection parameters are not specified: server name and infobase name.'; pl = 'Wymagane parametry połączenia nie są określone: ""Nazwa serwera""; ""Nazwa bazy informacyjnej na serwerze"".';de = 'Erforderliche Verbindungsparameter sind nicht angegeben: ""Servername""; ""Name der Infobase auf dem Server"".';ro = 'Parametrii obligatorii de conectare: ""Numele serverului""; ""Numele bazei de date pe server"" - nu sunt specificați.';tr = 'Gerekli bağlantı parametreleri belirlenmemiş: ""Sunucu adı"";  ""Sunucudaki veritabanın adı"".'; es_ES = 'Parámetros de conexión requeridos no están especificados: ""Nombre del servidor""; ""Nombre de la infobase en el servidor"".'");
			FillingCheckError = True;
		EndIf;
		
	EndIf;
	
	If FillingCheckError Then
		
		Result.DetailedErrorDescription = ErrorMessageString;
		Result.BriefErrorDescription   = ErrorMessageString;
		Return Result;
		
	EndIf;
	
	// Generating the connection string.
	ConnectionStringPattern = "[InfobaseString][AuthenticationString]";
	
	If FileRunMode Then
		InfobaseString = "File = ""&InfobaseDirectory""";
		InfobaseString = StrReplace(InfobaseString, "&InfobaseDirectory", Parameters.InfobaseDirectory);
	Else
		InfobaseString = "Srvr = ""&NameOf1CEnterpriseServer""; Ref = ""&NameOfInfobaseOn1CEnterpriseServer""";
		InfobaseString = StrReplace(InfobaseString, "&NameOf1CEnterpriseServer",                     Parameters.NameOf1CEnterpriseServer);
		InfobaseString = StrReplace(InfobaseString, "&NameOfInfobaseOn1CEnterpriseServer", Parameters.NameOfInfobaseOn1CEnterpriseServer);
	EndIf;
	
	If Parameters.OperatingSystemAuthentication Then
		AuthenticationString = "";
	Else
		
		If StrFind(Parameters.UserName, """") Then
			Parameters.UserName = StrReplace(Parameters.UserName, """", """""");
		EndIf;
		
		If StrFind(Parameters.UserPassword, """") Then
			Parameters.UserPassword = StrReplace(Parameters.UserPassword, """", """""");
		EndIf;
		
		AuthenticationString = "; Usr = ""&UserName""; Pwd = ""&UserPassword""";
		AuthenticationString = StrReplace(AuthenticationString, "&UserName",    Parameters.UserName);
		AuthenticationString = StrReplace(AuthenticationString, "&UserPassword", Parameters.UserPassword);
	EndIf;
	
	ConnectionString = StrReplace(ConnectionStringPattern, "[InfobaseString]", InfobaseString);
	ConnectionString = StrReplace(ConnectionString, "[AuthenticationString]", AuthenticationString);
	
	Try
		Result.Connection = COMConnector.Connect(ConnectionString);
	Except
		Information = ErrorInfo();
		ErrorMessageString = NStr("ru = 'Не удалось подключиться к другой программе: %1'; en = 'Failed to connect to another application: %1'; pl = 'Nie można połączyć się z inną aplikacją: %1';de = 'Kann keine Verbindung zu einer anderen Anwendung herstellen: %1';ro = 'Eșec de conectare la alt program: %1';tr = 'Başka bir uygulamaya bağlanılamıyor: %1'; es_ES = 'No se puede conectar a otra aplicación: %1'");
		
		Result.AddInAttachmentError = True;
		Result.DetailedErrorDescription     = StringFunctionsClientServer.SubstituteParametersToString(ErrorMessageString, DetailErrorDescription(Information));
		Result.BriefErrorDescription       = StringFunctionsClientServer.SubstituteParametersToString(ErrorMessageString, BriefErrorDescription(Information));
	EndTry;
	
	Return Result;
	
#EndIf
	
EndFunction

#EndRegion

#Region RunExternalApplications

#Region SafeCommandString

Function ContainsUnsafeActions(Val CommandRow)
	
	Return StrFind(CommandRow, "$") <> 0
		Or StrFind(CommandRow, "`") <> 0
		Or StrFind(CommandRow, "|") <> 0
		Or StrFind(CommandRow, ";") <> 0
		Or StrFind(CommandRow, "&") <> 0;
	
EndFunction

Function ArrayToCommandString(StartupCommand)
	
	Result = New Array;
	QuotesRequired = False;
	For Each Argument In StartupCommand Do
		
		If Result.Count() > 0 Then 
			Result.Add(" ")
		EndIf;
		
		QuotesRequired = Argument = Undefined
			Or IsBlankString(Argument)
			Or StrFind(Argument, " ")
			Or StrFind(Argument, Chars.Tab)
			Or StrFind(Argument, "&")
			Or StrFind(Argument, "(")
			Or StrFind(Argument, ")")
			Or StrFind(Argument, "[")
			Or StrFind(Argument, "]")
			Or StrFind(Argument, "{")
			Or StrFind(Argument, "}")
			Or StrFind(Argument, "^")
			Or StrFind(Argument, "=")
			Or StrFind(Argument, ";")
			Or StrFind(Argument, "!")
			Or StrFind(Argument, "'")
			Or StrFind(Argument, "+")
			Or StrFind(Argument, ",")
			Or StrFind(Argument, "`")
			Or StrFind(Argument, "~")
			Or StrFind(Argument, "$")
			Or StrFind(Argument, "|");
		
		If QuotesRequired Then 
			Result.Add("""");
		EndIf;
		
		Result.Add(StrReplace(Argument, """", """"""));
		
		If QuotesRequired Then 
			Result.Add("""");
		EndIf;
		
	EndDo;
	
	Return StrConcat(Result);
	
EndFunction

#EndRegion

Function NewWindowsCommandStartFile(CommandRow, CurrentDirectory, WaitForCompletion, ExecutionEncoding) Export
	
	TextDocument = New TextDocument;
	TextDocument.AddLine("@echo off");
	
	If ValueIsFilled(ExecutionEncoding) Then 
		
		If ExecutionEncoding = "OEM" Then
			ExecutionEncoding = 437;
		ElsIf ExecutionEncoding = "CP866" Then
			ExecutionEncoding = 866;
		ElsIf ExecutionEncoding = "UTF8" Then
			ExecutionEncoding = 65001;
		EndIf;
		
		TextDocument.AddLine("chcp " + Format(ExecutionEncoding, "NG="));
		
	EndIf;
	
	If Not IsBlankString(CurrentDirectory) Then 
		TextDocument.AddLine("cd /D """ + CurrentDirectory + """");
	EndIf;
	TextDocument.AddLine("cmd /S /C "" " + CommandRow + " """);
	
	Return TextDocument;
	
EndFunction

#EndRegion

#EndRegion
