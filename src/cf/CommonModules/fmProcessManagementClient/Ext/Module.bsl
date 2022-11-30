
// Универсальный обработчик нажатия кнопки Согласования
//
Procedure AgreementButtonClickHandler(Form, Command) Export
	
	Items = Form.Items;
	Object = Form.Object;
	
	If Items.AgreeForm.Title = NStr("en='Submit for approval';ru='Отправить на согласование'") Then
		
		If Form.Modified OR NOT Object.Posted Then
			ShowQueryBox(New NotifyDescription("AgreementKeyPressHandlerEnd", ThisObject, New Structure("Form", Form)), NStr("en='While sending for approval, the document will be posted and closed. Do you want to continue?';ru='При отправке на согласование документ будет проведен и закрыт. Продолжить?'"), QuestionDialogMode.YesNo);
		Else
			Try
				RecordParameters = New Structure("Agreement", True);
				RecordParameters.Insert("WriteMode", DocumentWriteMode.Write);
				If NOT Form.Write(RecordParameters) Then
					CommonClientServer.MessageToUser(StrTemplate(NStr("en='Failed to write a document! %1.';ru='Не удалось записать документ! %1'"), ErrorDescription()));
					Return;
				EndIf;
				Form.Close();
			Except
				CommonClientServer.MessageToUser(StrTemplate(NStr("en='Failed to write a document! %1.';ru='Не удалось записать документ! %1'"), ErrorDescription()));
				Return;
			EndTry;
		EndIf;
		
	Else
		
		If Form.Modified OR NOT Object.Posted Then
			Try
				If NOT Form.Write(New Structure("WriteMode", DocumentWriteMode.Posting)) Then
					CommonClientServer.MessageToUser(StrTemplate(NStr("en='Failed to write a document! %1.';ru='Не удалось записать документ! %1'"), ErrorDescription()));
					Return;
				EndIf;
				Form.Modified = False;
			Except
				CommonClientServer.MessageToUser(StrTemplate(NStr("en='Failed to write a document! %1.';ru='Не удалось записать документ! %1'"), ErrorDescription()));
				Return;
			EndTry;
		EndIf;
		
		If Command.Name = "AgreeWithComment" Then
			OpenForm("CommonForm.fmCommentForm", , Form, , , , New NotifyDescription("AgreeWithCommentEnd", ThisObject, New Structure("Form", Form)), FormWindowOpeningMode.LockOwnerWindow);
		Else
			fmProcessManagement.AgreeDocumentByAllPoints(Object.Ref, Object.AgreementRoute);
			Notify("fmListRefresh");
			Form.Close();
		EndIf;
		
	EndIf;
	
EndProcedure // ОбработкаНажатияКнопкиСогласования()

Procedure AgreeWithCommentEnd(Result, AddParameters) Export
	If Result = Undefined Then
		Return;
	EndIf;
	fmProcessManagement.AgreeDocumentByAllPoints(AddParameters.Form.Object.Ref, AddParameters.Form.Object.AgreementRoute, Result);
	Notify("fmListRefresh");
	AddParameters.Form.Close();
EndProcedure

Procedure AgreementKeyPressHandlerEnd(Response, AddParameters) Export
	
	If Response = DialogReturnCode.No Then
		Return;
	EndIf;
	
	Try
		RecordParameters = New Structure("Agreement", True);
		RecordParameters.Insert("WriteMode", DocumentWriteMode.Posting);
		If NOT AddParameters.Form.Write(RecordParameters) Then
			CommonClientServer.MessageToUser(StrTemplate(NStr("en='Failed to write a document! %1.';ru='Не удалось записать документ! %1'"), ErrorDescription()));
			Return;
		EndIf;
		AddParameters.Form.Modified = False;
		AddParameters.Form.Close();
	Except
		CommonClientServer.MessageToUser(StrTemplate(NStr("en='Failed to write a document! %1.';ru='Не удалось записать документ! %1'"), ErrorDescription()));
		Return;
	EndTry;
	
EndProcedure

// Универсальный обработчик нажатия кнопки Отклонения
//
Procedure RejectionButtonClickHandler(Form, Command) Export
	
	Object = Form.Object;
	
	If Form.Modified OR NOT Object.Posted Then
		Try
			If NOT Form.Write(New Structure("WriteMode", DocumentWriteMode.Posting)) Then
				CommonClientServer.MessageToUser(StrTemplate(NStr("en='Failed to write a document! %1.';ru='Не удалось записать документ! %1'"), ErrorDescription()));
				Return;
			EndIf;
			Form.Modified = False;
		Except
			CommonClientServer.MessageToUser(StrTemplate(NStr("en='Failed to write a document! %1.';ru='Не удалось записать документ! %1'"), ErrorDescription()));
			Return;
		EndTry;
	EndIf;
	
	If Command.Name = "RejectWithComment" Then
		OpenForm("CommonForm.fmCommentForm", , Form, , , , New NotifyDescription("RejectWithCommentEnd", ThisObject, New Structure("Form", Form)), FormWindowOpeningMode.LockOwnerWindow);
	Else
		fmProcessManagement.RejectDocument(Object.Ref, Object.AgreementRoute);
		Notify("fmListRefresh");
		Form.Close();
	EndIf;
	
EndProcedure // ОбработкаНажатияКнопкиОтклонения()

Procedure RejectWithCommentEnd(Result, AddParameters) Export
	If Result = Undefined Then
		Return;
	EndIf;
	fmProcessManagement.RejectDocument(AddParameters.Form.Object.Ref, AddParameters.Form.Object.AgreementRoute, Result);
	Notify("fmListRefresh");
	AddParameters.Form.Close();
EndProcedure
