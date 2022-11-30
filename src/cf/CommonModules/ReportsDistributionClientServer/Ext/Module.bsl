///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Fills a template from the parameters structure, supports formatting, can leave templates borders.
//   Restriction: the left and right items of borders are to be.
//
// Parameters:
//   Template - String - an initial template. For instance Welcome, [Full name].
//   Parameters - Structure - a set of parameters that you need to substitute into the template.
//      * Key - a parameter name. For instance Full name.
//      * Value - a substitution string. For instance John Smith.
//
// Returns:
//   String - a template with filled parameters.
//
Function FillTemplate(Template, Parameters) Export
	Left = "["; // Parameter borders start.
	Right = "]"; // Parameter borders end.
	LeftFormat = "("; // Format borders start.
	RightFormat = ")"; // Format borders end.
	CutBorders = True; // True means that the parameter borders will be removed from the result.
	
	Result = Template;
	For Each KeyAndValue In Parameters Do
		// Replace [key] to value.
		Result = StrReplace(
			Result,
			Left + KeyAndValue.Key + Right, 
			?(CutBorders, "", Left) + KeyAndValue.Value + ?(CutBorders, "", Right));
		LengthLeftFormat = StrLen(Left + KeyAndValue.Key + LeftFormat);
		// Replace [key(format)] to value in the format.
		Pos1 = StrFind(Result, Left + KeyAndValue.Key + LeftFormat);
		While Pos1 > 0 Do
			Pos2 = StrFind(Result, RightFormat + Right);
			If Pos2 = 0 Then
				Break;
			EndIf;
			FormatString = Mid(Result, Pos1 + LengthLeftFormat, Pos2 - Pos1 - LengthLeftFormat);
			Try
				WhatToReplace = ?(CutBorders, "", Left) + Format(KeyAndValue.Value, FormatString) + ?(CutBorders, "", Right);
			Except
				WhatToReplace = ?(CutBorders, "", Left) + KeyAndValue.Value + ?(CutBorders, "", Right);
			EndTry;
			Result = StrReplace(
				Result,
				Left + KeyAndValue.Key + LeftFormat + FormatString + RightFormat + Right, 
				WhatToReplace);
			Pos1 = StrFind(Result, Left + KeyAndValue.Key + LeftFormat);
		EndDo;
	EndDo;
	Return Result;
EndFunction

// Generates the delivery methods presentation according to delivery parameters.
//
// Parameters:
//   DeliveryParameters - Structure - see ExecuteMailing(), the DeliveryParameters parameter. 
//
// Returns:
//   String - a delivery methods presentation.
//
Function DeliveryMethodsPresentation(DeliveryParameters) Export
	Prefix = NStr("ru = 'Результат'; en = 'Result'; pl = 'Result';de = 'Result';ro = 'Result';tr = 'Result'; es_ES = 'Result'");
	PresentationText = "";
	Suffix = "";
	
	If Not DeliveryParameters.NotifyOnly Then
		
		PresentationText = PresentationText 
		+ ?(PresentationText = "", Prefix, " " + NStr("ru = 'и'; en = 'and'; pl = 'and';de = 'and';ro = 'and';tr = 'and'; es_ES = 'and'")) 
		+ " "
		+ NStr("ru = 'отправлен по почте (см. вложения)'; en = 'sent by email (see attachments)'; pl = 'sent by email (see attachments)';de = 'sent by email (see attachments)';ro = 'sent by email (see attachments)';tr = 'sent by email (see attachments)'; es_ES = 'sent by email (see attachments)'");
		
	EndIf;
	
	If DeliveryParameters.ExecutedToFolder Then
		
		PresentationText = PresentationText 
		+ ?(PresentationText = "", Prefix, " " + NStr("ru = 'и'; en = 'and'; pl = 'and';de = 'and';ro = 'and';tr = 'and'; es_ES = 'and'")) 
		+ " "
		+ NStr("ru = 'доставлен в папку'; en = 'delivered to folder'; pl = 'delivered to folder';de = 'delivered to folder';ro = 'delivered to folder';tr = 'delivered to folder'; es_ES = 'delivered to folder'")
		+ " ";
		
		Ref = GetInfoBaseURL() +"#"+ GetURL(DeliveryParameters.Folder);
		
		If DeliveryParameters.HTMLFormatEmail Then
			PresentationText = PresentationText 
			+ "<a href = '"
			+ Ref
			+ "'>" 
			+ String(DeliveryParameters.Folder)
			+ "</a>";
		Else
			PresentationText = PresentationText 
			+ """"
			+ String(DeliveryParameters.Folder)
			+ """";
			Suffix = Suffix + ":" + Chars.LF + "<" + Ref + ">";
		EndIf;
		
	EndIf;
	
	If DeliveryParameters.ExecutedToNetworkDirectory Then
		
		PresentationText = PresentationText 
		+ ?(PresentationText = "", Prefix, " " + NStr("ru = 'и'; en = 'and'; pl = 'and';de = 'and';ro = 'and';tr = 'and'; es_ES = 'and'")) 
		+ " "
		+ NStr("ru = 'доставлен в сетевой каталог'; en = 'delivered to network directory'; pl = 'delivered to network directory';de = 'delivered to network directory';ro = 'delivered to network directory';tr = 'delivered to network directory'; es_ES = 'delivered to network directory'")
		+ " ";
		
		If DeliveryParameters.HTMLFormatEmail Then
			PresentationText = PresentationText 
			+ "<a href = '"
			+ DeliveryParameters.NetworkDirectoryWindows
			+ "'>" 
			+ DeliveryParameters.NetworkDirectoryWindows
			+ "</a>";
		Else
			PresentationText = PresentationText 
			+ "<"
			+ DeliveryParameters.NetworkDirectoryWindows
			+ ">";
		EndIf;
		
	EndIf;
	
	If DeliveryParameters.ExecutedAtFTP Then
		
		PresentationText = PresentationText 
		+ ?(PresentationText = "", Prefix, " " + NStr("ru = 'и'; en = 'and'; pl = 'and';de = 'and';ro = 'and';tr = 'and'; es_ES = 'and'")) 
		+ " "
		+ NStr("ru = 'доставлен на FTP ресурс'; en = 'delivered to FTP resource'; pl = 'delivered to FTP resource';de = 'delivered to FTP resource';ro = 'delivered to FTP resource';tr = 'delivered to FTP resource'; es_ES = 'delivered to FTP resource'")
		+ " ";
		
		Ref = "ftp://"
		+ DeliveryParameters.Server 
		+ ":"
		+ Format(DeliveryParameters.Port, "NZ=0; NG=0") 
		+ DeliveryParameters.Directory;
		
		If DeliveryParameters.HTMLFormatEmail Then
			PresentationText = PresentationText 
			+ "<a href = '"
			+ Ref
			+ "'>" 
			+ Ref
			+ "</a>";
		Else
			PresentationText = PresentationText 
			+ "<"
			+ Ref
			+ ">";
		EndIf;
		
	EndIf;
	
	PresentationText = PresentationText + ?(Suffix = "", ".", Suffix);
	
	Return PresentationText;
EndFunction

Function ListPresentation(Collection, ColumnName = "", MaxChars = 60) Export
	Result = New Structure;
	Result.Insert("Total", 0);
	Result.Insert("LengthOfFull", 0);
	Result.Insert("LengthOfShort", 0);
	Result.Insert("Short", "");
	Result.Insert("Full", "");
	Result.Insert("MaximumExceeded", False);
	For Each Object In Collection Do
		ValuePresentation = String(?(ColumnName = "", Object, Object[ColumnName]));
		If IsBlankString(ValuePresentation) Then
			Continue;
		EndIf;
		If Result.Total = 0 Then
			Result.Total        = 1;
			Result.Full       = ValuePresentation;
			Result.LengthOfFull = StrLen(ValuePresentation);
		Else
			Full       = Result.Full + ", " + ValuePresentation;
			LengthOfFull = Result.LengthOfFull + 2 + StrLen(ValuePresentation);
			If Not Result.MaximumExceeded AND LengthOfFull > MaxChars Then
				Result.Short          = Result.Full;
				Result.LengthOfShort    = Result.LengthOfFull;
				Result.MaximumExceeded = True;
			EndIf;
			Result.Total        = Result.Total + 1;
			Result.Full       = Full;
			Result.LengthOfFull = LengthOfFull;
		EndIf;
	EndDo;
	If Result.Total > 0 AND Not Result.MaximumExceeded Then
		Result.Short       = Result.Full;
		Result.LengthOfShort = Result.LengthOfFull;
		Result.MaximumExceeded = Result.LengthOfFull > MaxChars;
	EndIf;
	Return Result;
EndFunction

#EndRegion
