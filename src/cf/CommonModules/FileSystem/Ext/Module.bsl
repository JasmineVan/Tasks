///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

#Region TemporaryFiles

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions to manage temporary files.

// Creates a temporary directory. If a temporary directory is not required anymore, deleted it with 
// the FileSystem.DeleteTemporaryDirectory procedure.
//
// Parameters:
//   Extension - String - the temporary directory extension that contains the directory designation 
//                         and its subsystem.
//                         It is recommended that you use only Latin characters in this parameter.
//
// Returns:
//   String - full path to the directory, including path separators.
//
Function CreateTemporaryDirectory(Val Extension = "") Export
	
	PathToDirectory = CommonClientServer.AddLastPathSeparator(GetTempFileName(Extension));
	CreateDirectory(PathToDirectory);
	Return PathToDirectory;
	
EndFunction

// Deletes the temporary directory and its content if possible.
// If a temporary directory cannot be deleted (for example, if it is busy), the procedure is 
// completed and the warning is added to the event log.
//
// This procedure is for using with the FileSysyem.CreateTemporaryDirectory procedure after a 
// temporary directory is not required anymore.
//
// Parameters:
//   Path - String - a full path to a temporary directory.
//
Procedure DeleteTemporaryDirectory(Val Path) Export
	
	If IsTempFileName(Path) Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Неверное значение параметра Путь в ФайловаяСистема.УдалитьВременныйКаталог:
				       |Каталог не является временным ""%1""'; 
				       |en = 'Invalid value of the Path parameter in FileSystem.DeleteTemporaryDirectory:
				       |The directory is not temporary: %1'; 
				       |pl = 'Błędna wartość parametrów Ścieżka w FileSystem.DeleteTemporaryDirectory:
				       |Katalog nie jest tymczasowy ""%1""';
				       |de = 'Ungültiger Wert für Pfad zum FileSystem.DeleteTemporaryDirectory: 
				       |Verzeichnis ist kein temporäres Verzeichnis ""%1""';
				       |ro = 'Valoare incorectă a parametrului Calea în FileSystem.DeleteTemporaryDirectory:
				       |Catalogul nu este temporar ""%1""';
				       |tr = 'FileSystem.DeleteTemporaryDirectory ''de DizinYolu parametresinin değeri yanlıştır: 
				       | Dizin geçici ""%1"" değildir '; 
				       |es_ES = 'Valor incorrecto del parámetro Ruta en FileSystem.DeleteTemporaryDirectory:
				       |El catálogo no es temporal ""%1""'"), 
			Path);
	EndIf;
	
	DeleteTempFiles(Path);
	
EndProcedure

// Deletes a temporary file.
// If a temporary file cannot be deleted (for example, if it is busy), the procedure is completed 
// and the warning is added to the event log.
//
// This procedure is for using with the GetTempFileName method after a temporary file is not 
// required anymore.
//
// Parameters:
//   Path - String - a full path to a temporary file.
//
Procedure DeleteTempFile(Val Path) Export
	
	If IsTempFileName(Path) Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Неверное значение параметра Путь в ФайловаяСистема.УдалитьВременныйФайл:
				       |Файл не является временным ""%1""'; 
				       |en = 'Incorrect value of the Path parameter in FileSystem.DeleteTemporaryFile:
				       |The file is not temporary: %1'; 
				       |pl = 'Błędna wartość parametrów Ścieżka w FileSystem.DeleteTemporaryFile:
				       |Katalog nie jest tymczasowy ""%1""';
				       |de = 'Ungültiger Wert für Pfad zum FileSystem.DeleteTemporaryFile:
				       |Datei ist nicht temporär ""%1""';
				       |ro = 'Valoare incorectă a parametrului Calea în FileSystem.DeleteTemporaryFile:
				       |Fișierul nu este temporar ""%1""';
				       |tr = 'FileSystem.DeleteTemporaryFile ''de DizinYolu parametresinin değeri yanlıştır: 
				       | Dizin geçici ""%1"" değildir '; 
				       |es_ES = 'Valor incorrecto del parámetro Ruta en FileSystem.DeleteTemporaryFile:
				       |El archivo no es temporal ""%1""'"), 
			Path);
	EndIf;
	
	DeleteTempFiles(Path);
	
EndProcedure

#EndRegion

#Region RunExternalApplications

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions for managing external applications.

// Returns:
//  Structure - where:
//    * CurrentDirectory - String - sets the current directory of the application being started up.
//    * WaitForCompletion - Boolean - False - wait for the running application to end before 
//         proceeding.
//    * GetOutputStream - Boolean - False - result is passed to stdout. Ignored if WaitForCompletion 
//         is not specified.
//    * GetErrorStream - Boolean - False - errors are passed to stderr stream. Ignored if 
//         WaitForCompletion is not specified.
//    * ThreadsEncoding - TextEncoding, String - an encoding used to read stdout и stderr.
//         It is used by default for Windows OEM (cp437), others are TextEncoding.System.
//    * ExecutionEncoding - String, Number - an encoding set in Windows using the chcp command.
//         Ignored under Linux or MacOS. Possible values are: OEM, CP866, UTF8 or code page number.
//
Function ApplicationStartupParameters() Export
	
	Parameters = New Structure;
	Parameters.Insert("CurrentDirectory", "");
	Parameters.Insert("WaitForCompletion", False);
	Parameters.Insert("GetOutputStream", False);
	Parameters.Insert("GetErrorStream", False);
	Parameters.Insert("ThreadsEncoding", Undefined);
	Parameters.Insert("ExecutionEncoding", Undefined);
	
	Return Parameters;
	
EndFunction

// Runs an external application using the startup parameters.
//
// Parameters:
//  StartupCommand - String - application startup command line.
//                 - Array - the first element is the path to the application, the rest of the 
//                            elements are its startup parameters. The procedure generates an argv 
//                            string from the array.
//  ApplicationStartupParameters - - Structure - see FileSystem.ApplicationStartupParameters 
//
// Returns:
//  Structure - where:
//    * ReturnCode - Number - the application return code.
//    * OutputStream - String - the application result passed to stdout.
//    * ErrorStream - String - the application errors passed to stderr.
//
// Example:
//	// Simple start
//	FileSystem.StartApplication("calc");
//	
//	// Starting with waiting for completion
//	ApplicationStartupParameters = FileSystem.ApplicationStartupParameters();
//	ApplicationStartupParameters.WaitForCompletion = True;
//	FileSystem.StartApplication("C:\Program Files\1cv8\common\1cestart.exe", 
//		FileSystem.ApplicationStartupParameters);
//	
//	// Starting with waiting for completion and getting output thread
//	ApplicationStartupParameters = FileSystem.ApplicationStartupParameters();
//	ApplicationStartupParameters.WaitForCompletion = True;
//	ApplicationStartupParameters.GetOutputStream = True;
//	Result = FileSystem("ping 127.0.0.1 -n 5", ApplicationStartupParameters);
//	Common.InformUser(Result.OutputStream);
//
//	// Starting with waiting for completion and getting output thread, and with start command concatenation
//	ApplicationStartupParameters = FileSystem.ApplicationStartupParameters();
//	ApplicationStartupParameters.WaitForCompletion = True;
//	ApplicationStartupParameters.GetOutputStream = True;
//	StartupCommand = New Array;
//	StartupCommand.Add("ping");
//	StartupCommand.Add("127.0.0.1");
//	StartupCommand.Add("-n");
//	StartupCommand.Add(5);
//	Result = FileSystem.StartApplication(StartupCommand, ApplicationStartupParameters);
//	Common.InformUser(Result.OutputStream);
//
Function StartApplication(Val StartupCommand, ApplicationStartupParameters = Undefined) Export 
	
	// CAC:534-off safe start methods are provided with this function
	
	CommandRow = CommonInternalClientServer.SafeCommandString(StartupCommand);
	
	If ApplicationStartupParameters = Undefined Then 
		ApplicationStartupParameters = ApplicationStartupParameters();
	EndIf;
	
	CurrentDirectory = ApplicationStartupParameters.CurrentDirectory;
	WaitForCompletion = ApplicationStartupParameters.WaitForCompletion;
	GetOutputStream = ApplicationStartupParameters.GetOutputStream;
	GetErrorStream = ApplicationStartupParameters.GetErrorStream;
	ThreadsEncoding = ApplicationStartupParameters.ThreadsEncoding;
	ExecutionEncoding = ApplicationStartupParameters.ExecutionEncoding;
	
	CheckCurrentDirectory(CommandRow, CurrentDirectory);
	
	If WaitForCompletion Then 
		If GetOutputStream Then 
			OutputThreadFileName = GetTempFileName("stdout.tmp");
			CommandRow = CommandRow + " > """ + OutputThreadFileName + """";
		EndIf;
		
		If GetErrorStream Then 
			ErrorsThreadFileName = GetTempFileName("stderr.tmp");
			CommandRow = CommandRow + " 2>""" + ErrorsThreadFileName + """";
		EndIf;
	EndIf;
	
	If ThreadsEncoding = Undefined Then 
		ThreadsEncoding = StandardStreamEncoding();
	EndIf;
	
	ReturnCode = Undefined;
	
	If Common.IsWindowsServer() Then
		
		CommandFileName = GetTempFileName("run.bat");
		TextDocument = CommonInternalClientServer.NewWindowsCommandStartFile(
			CommandRow, CurrentDirectory, WaitForCompletion, ExecutionEncoding);
		TextDocument.Write(CommandFileName, ThreadsEncoding);
		
		If Common.FileInfobase() Then
			// In a file infobase, the console window must be hidden in the server context as well.
			Shell = New COMObject("Wscript.Shell");
			ReturnCode = Shell.Run(CommandFileName, 0, WaitForCompletion);
			Shell = Undefined;
		Else 
			RunApp(CommandFileName,, WaitForCompletion, ReturnCode);
		EndIf;
		
		If WaitForCompletion Then
			// Authomatic deletion is enabled only if you do not wait for completion as return code is not interesting there.
			// When the correct return code is required, there is no automatic deletion, that is why you need to delete file here.
			DeleteTempFile(CommandFileName);
		EndIf;
	Else
		RunApp(CommandRow, CurrentDirectory, WaitForCompletion, ReturnCode);
	EndIf;
	
	OutputStream = "";
	ErrorStream = "";
	
	If WaitForCompletion Then 
		If GetOutputStream Then
			OutputStream = ReadFileIfExists(OutputThreadFileName, ThreadsEncoding);
			DeleteTempFile(OutputThreadFileName);
		EndIf;
		
		If GetErrorStream Then 
			ErrorStream = ReadFileIfExists(ErrorsThreadFileName, ThreadsEncoding);
			DeleteTempFile(ErrorsThreadFileName);
		EndIf;
	EndIf;
	
	Result = New Structure;
	Result.Insert("ReturnCode", ReturnCode);
	Result.Insert("OutputStream", OutputStream);
	Result.Insert("ErrorStream", ErrorStream);
	
	Return Result;
	
	// CAC:534-enable
	
EndFunction

#EndRegion

#EndRegion

#Region Private

Procedure DeleteTempFiles(Val Path)
	
	Try
		DeleteFiles(Path);
	Except
		WriteLogEvent(
			NStr("ru = 'Стандартные подсистемы'; en = 'Standard subsystems'; pl = 'Standardowe podsystemy';de = 'Standard-Subsysteme';ro = 'Subsisteme standard';tr = 'Standart alt sistemler'; es_ES = 'Subsistemas estándar'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось удалить временный файл ""%1"" по причине:
					|%2'; 
					|en = 'Cannot delete temporary file %1. Reason:
					|%2'; 
					|pl = 'Nie udało się usunąć tymczasowy plik ""%1"" z powodu:
					|%2';
					|de = 'Die temporäre Datei ""%1"" konnte aus diesem Grund nicht gelöscht werden:
					|%2';
					|ro = 'Eșec la ștergerea fișierului temporar ""%1"" din motivul:
					|%2';
					|tr = '""%1"" geçici dizin 
					|%2 nedeniyle silinemedi'; 
					|es_ES = 'No se ha podido eliminar archivo temporal ""%1"" a causa de:
					|%2'"),
				Path,
				DetailErrorDescription(ErrorInfo())));
	EndTry;
	
EndProcedure

Function IsTempFileName(Path)
	
	// The Path is expected to have been obtained with the GetTempFileName() method.
	// Before the check, slashes are converted into backslashes.
	Return Not StrStartsWith(StrReplace(Path, "/", "\"), StrReplace(TempFilesDir(), "/", "\"));
	
EndFunction

#Region StartApplication

Procedure CheckCurrentDirectory(CommandRow, CurrentDirectory)
	
	If Not IsBlankString(CurrentDirectory) Then 
		
		FileInfo = New File(CurrentDirectory);
		
		If Not FileInfo.Exist() Then 
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось запустить программу
				           |%1
				           |по причине:
				           |Не существует каталог, указанный как ТекущийКаталог
				           |%2'; 
				           |en = 'Cannot start the application
				           |%1.
				           |Reason:
				           |The catalog that is specified as CurrentDirectory does not exist:
				           |%2'; 
				           |pl = 'Nie można uruchomić programu
				           |%1
				           |z powodu:
				           |Brak katalogu określonego, jako CurrentDirectory
				           |%2';
				           |de = 'Das Programm
				           |%1
				           |konnte nicht gestartet werden, weil:
				           |Es ist kein Verzeichnis als CurrentDirectory angegeben
				           |%2';
				           |ro = 'Eșec la lansarea aplicației
				           |%1
				           |din motivul:
				           |Nu există catalogul indicat ca CurrentDirectory
				           |%2';
				           |tr = 'Program aşağıdaki nedenle başlatılamadı
				           |%1
				           |:
				           |CurrentDirectory olarak belirtilen dizin mevcut değil
				           |%2'; 
				           |es_ES = 'No se ha podido lanzar el programa
				           |%1
				           |a causa de:
				           |No existe catálogo indicado como CurrentDirectory
				           |%2'"),
				CommandRow,
				CurrentDirectory);
		EndIf;
		
		If Not FileInfo.IsDirectory() Then 
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось запустить программу
				           |%1
				           |по причине:
				           |ТекущийКаталог не является каталогом %2'; 
				           |en = 'Cannot start the application
				           |%1.
				           |Reason:
				           |CurrentDirectory is not a directory: %2'; 
				           |pl = 'Nie można uruchomić programu
				           |%1
				           |z powodu:
				           |CurrentDirectory nie jest katalogiem %2';
				           |de = 'Das Programm
				           |%1
				           |konnte nicht gestartet werden, weil:
				           |Das CurrentDirectory ist kein Verzeichnis %2';
				           |ro = 'Eșec la lansarea programului
				           |%1
				           |fin motivul:
				           |CurrentDirectory nu este catalog %2';
				           |tr = 'Program aşağıdaki nedenle başlatılamadı
				           |%1
				           |:
				           |CurrentDirectory bir dizin değildir%2'; 
				           |es_ES = 'No se ha podido lanzar el programa
				           |%1
				           |a causa de:
				           |CurrentDirectory no es catálogo %2'"),
				CommandRow,
				CurrentDirectory);
		EndIf;
		
	EndIf;
	
EndProcedure

Function ReadFileIfExists(Path, Encoding)
	
	Result = Undefined;
	
	FileInfo = New File(Path);
	
	If FileInfo.Exist() Then 
		
		ErrorStreamReader = New TextReader(Path, Encoding);
		Result = ErrorStreamReader.Read();
		ErrorStreamReader.Close();
		
	EndIf;
	
	If Result = Undefined Then 
		Result = "";
	EndIf;
	
	Return Result;
	
EndFunction

// Returns encoding of standard output and error threads for the current operating system.
//
// Returns:
//  TextEncoding - encoding of standard output and error threads.
//
Function StandardStreamEncoding()
	
	If Common.IsWindowsServer() Then
		Encoding = TextEncoding.OEM;
	Else
		Encoding = TextEncoding.System;
	EndIf;
	
	Return Encoding;
	
EndFunction

#EndRegion

#EndRegion