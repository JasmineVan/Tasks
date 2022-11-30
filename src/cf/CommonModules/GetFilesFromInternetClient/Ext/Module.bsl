///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Gets the file from the Internet via http(s) protocol or ftp protocol and saves it at the specified path on client
// Unavailable in web client. If you work in web client, use similar server procedures for 
// downloading files.
//
// Parameters:
//   URL - String - file URL in the following format: [Protocol://]<Server>/<Path to the file on the server>.
//   ReceivingParameters - Structure - see GetFilesFromInternetClientServer.FileReceivingParameters. 
//   WriteError - Boolean - indicates the need to write errors to event log while getting the file.
//
// Returns:
//   Structure - structure with the following properties:
//      * Status - Boolean - file getting result.
//      * Path - String - path to the file on the client. This key is used only if Status is True.
//      * ErrorMessage - String - error message if Status is False.
//      * Headers         - Map - see details of the Headers parameter of the HTTPResponse object in Syntax Assistant.
//      * StatusCode - Number - adds in case of an error.
//                                    See details of the StatusCode parameter of the HTTPResponse object in Syntax Assistant.
//
Function DownloadFileAtClient(Val URL, Val ReceivingParameters = Undefined, Val WriteError = True) Export
	
#If WebClient Then
	Raise NStr("ru = 'Скачивание файлов на клиент недоступно при работе в веб-клиенте.'; en = 'Cannot download files in the web client.'; pl = 'Pobieranie danych z klienta nie jest możliwe dla tego klienta Web.';de = 'Das Herunterladen von Dateien auf den Client ist auf dem Webclient nicht möglich.';ro = 'Descărcarea fișierelor pe client nu este disponibilă în timpul lucrului în web-client.';tr = 'Web istemcisinde çalışırken dosyalar istemciye indirilemez.'; es_ES = 'No se puede descargar los archivos al cliente en el cliente web.'");
#Else
	
	Result = NetworkDownloadInternalServerCall.DownloadFile(URL, ReceivingParameters, WriteError);
	
	If ReceivingParameters <> Undefined
		AND ReceivingParameters.PathForSaving <> Undefined Then
		
		PathForSaving = ReceivingParameters.PathForSaving;
	Else
		PathForSaving = GetTempFileName(); // APK:441 Temporary file must be deleted by the calling code.
	EndIf;
	
	If Result.Status Then
		GetFile(Result.Path, PathForSaving, False);
		Result.Path = PathForSaving;
	EndIf;
	
	Return Result;
	
#EndIf
	
EndFunction

// Opens a proxy server parameters form.
//
// Parameters:
//    FormParameters - Structure - parameters of the form being opened.
//
Procedure OpenProxyServerParametersForm(FormParameters = Undefined) Export
	
	OpenForm("CommonForm.ProxyServerParameters", FormParameters);
	
EndProcedure

#EndRegion
