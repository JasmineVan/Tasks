///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

&AtClient
Var AdministrationParameters, PromptForIBAdministrationParameters;

#EndRegion

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	Parameters.Property("NotifyOnClose", NotifyOnClose);
	
	InfobaseSessionNumber = InfoBaseSessionNumber();
	ConditionalAppearance.Items[0].Filter.Items[0].RightValue = InfobaseSessionNumber;
	
	If Common.SubsystemExists("StandardSubsystems.SaaS") Then
		ModuleSaaS = Common.CommonModule("SaaS");
		SessionWithoutSeparators = ModuleSaaS.SessionWithoutSeparators();
	Else
		SessionWithoutSeparators = True;
	EndIf;
	
	If Common.FileInfobase()
		Or Not ((Not SessionWithoutSeparators AND Users.IsFullUser())
		Or Users.IsFullUser(, True)) Then
		
		Items.TerminateSession.Visible = False;
		Items.TerminateSessionContext.Visible = False;
		
	EndIf;
	
	If Common.SeparatedDataUsageAvailable() Then
		Items.UserListDataSeparation.Visible = False;
	EndIf;
	
	SortColumnName = "WorkStart";
	SortDirection = "Asc";
	
	FillConnectionFilterSelectionList();
	If Parameters.Property("ApplicationNameFilter") Then
		If Items.ApplicationNameFilter.ChoiceList.FindByValue(Parameters.ApplicationNameFilter) <> Undefined Then
			ApplicationNameFilter = Parameters.ApplicationNameFilter;
		EndIf;
	EndIf;
	
	FillUserList();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	PromptForIBAdministrationParameters = True;
EndProcedure

&AtClient
Procedure OnClose(Exit)
	If Exit Then
		Return;
	EndIf;
	If NotifyOnClose Then
		NotifyOnClose = False;
		NotifyChoice(Undefined);
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ApplicationNameFilterOnChange(Item)
	FillList();
EndProcedure

#EndRegion

#Region UserListFormTableItemsEventHandlers

&AtClient
Procedure UserListChoice(Item, RowSelected, Field, StandardProcessing)
	OpenUserFromList();
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure TerminateSession(Command)
	
	SelectedLinesNumber = Items.UsersList.SelectedRows.Count();
	
	If SelectedLinesNumber = 0 Then
		ShowMessageBox(,NStr("ru = 'Не выбраны пользователи для завершения сеансов.'; en = 'Please select users.'; pl = 'Użytkownicy do zakończenia sesji nie są wybrani.';de = 'Benutzer zum Beenden von Sitzungen sind nicht ausgewählt.';ro = 'Selectați utilizatorii pentru a vizualiza jurnalul de evenimente.';tr = 'Oturumları sonlandırmak için kullanıcılar seçilmez.'; es_ES = 'Usuarios para sesiones finales no se han seleccionado.'"));
		Return;
	ElsIf SelectedLinesNumber = 1 Then
		If Items.UsersList.CurrentData.Session = InfobaseSessionNumber Then
			ShowMessageBox(,NStr("ru = 'Невозможно завершить текущий сеанс. Для выхода из программы можно закрыть главное окно программы.'; en = 'Cannot close the current session. To exit the application, close its main window.'; pl = 'Nie można zakończyć bieżącej sesji. Aby zamknąć aplikację, zamknij główne okno aplikacji.';de = 'Es ist unmöglich, die aktuelle Sitzung zu beenden. Schließen Sie das Hauptanwendungsfenster, um die Anwendung zu beenden.';ro = 'Sesiunea curentă nu poate fi finalizată. Pentru a părăsi aplicația închideți fereastra principală a programului.';tr = 'Mevcut oturumu sonlandırılamıyor. Uygulamadan çıkmak için ana uygulama penceresini kapatın.'; es_ES = 'Es imposible finalizar la sesión actual. Para salir de la aplicación, cerrar la ventana principal de la aplicación.'"));
			Return;
		EndIf;
	EndIf;
	
	SessionNumbers = New Array;
	For Each RowID In Items.UsersList.SelectedRows Do
		SessionNumber = UsersList.FindByID(RowID).Session;
		If SessionNumber = InfobaseSessionNumber Then
			Continue;
		EndIf;
		SessionNumbers.Add(SessionNumber);
	EndDo;
	
	ClientRunParameters = StandardSubsystemsClient.ClientParametersOnStart();
	If ClientRunParameters.DataSeparationEnabled AND ClientRunParameters.SeparatedDataUsageAvailable Then
		
		StandardProcessing = True;
		NotificationAfterSessionTermination = New NotifyDescription(
			"AfterSessionTermination", ThisObject, New Structure("SessionNumbers", SessionNumbers));
		SaaSIntegrationClient.OnEndSessions(ThisObject, SessionNumbers, StandardProcessing, NotificationAfterSessionTermination);
		
	Else
		If PromptForIBAdministrationParameters Then
			NotifyDescription = New NotifyDescription("TerminateSessionContinuation", ThisObject, SessionNumbers);
			FormHeader = NStr("ru = 'Завершение сеанса'; en = 'Close session'; pl = 'Zakończenie sesji';de = 'Ende der Sitzung';ro = 'Finalizarea sesiunii';tr = 'Oturumu sonlandır'; es_ES = 'Terminar la sesión'");
			NoteLabel = NStr("ru = 'Для завершения сеанса необходимо ввести параметры
				|администрирования кластера серверов'; 
				|en = 'To close the session, please enter
				|the server cluster administration parameters.'; 
				|pl = 'Aby zakończyć sesję, należy wprowadzić ustawienia
				|administrowania klastrem serwera';
				|de = 'Um die Sitzung abzuschließen, müssen Sie die 
				|Administrationsparameter des Server-Clusters eingeben';
				|ro = 'Pentru finalizarea sesiunii este necesar să introduceți parametrii
				|de administrare a clusterului serverelor';
				|tr = 'Oturumu sonlandırmak için 
				|sunucu kümesinin yönetim parametreleri girilmelidir'; 
				|es_ES = 'Para finalizar la sesión, es necesario introducir los parámetros
				|de administración del clúster del servidor'");
			IBConnectionsClient.ShowAdministrationParameters(NotifyDescription, False, True, AdministrationParameters, FormHeader, NoteLabel);
		Else
			TerminateSessionContinuation(AdministrationParameters, SessionNumbers);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure RefreshExecute()
	
	FillList();
	
EndProcedure

&AtClient
Procedure OpenEventLog()
	
	SelectedRows = Items.UsersList.SelectedRows;
	If SelectedRows.Count() = 0 Then
		ShowMessageBox(,NStr("ru = 'Выберите пользователей для просмотра журнала регистрации.'; en = 'Select users to view their event log records.'; pl = 'Wybierz użytkowników, aby wyświetlić dziennik zdarzeń.';de = 'Wählen Sie Benutzer aus, um das Ereignisprotokoll anzuzeigen.';ro = 'Selectați utilizatorii pentru a vizualiza jurnalul de evenimente.';tr = 'Olay günlüğünü görüntülemek için kullanıcıları seçin.'; es_ES = 'Seleccionar los usuarios para ver el registro de eventos.'"));
		Return;
	EndIf;
	
	FilterByUsers = New ValueList;
	For Each RowID In SelectedRows Do
		UserRow = UsersList.FindByID(RowID);
		Username = UserRow.UserName;
		If FilterByUsers.FindByValue(Username) = Undefined Then
			FilterByUsers.Add(UserRow.UserName, UserRow.UserName);
		EndIf;
	EndDo;
	
	OpenForm("DataProcessor.EventLog.Form", New Structure("User", FilterByUsers));
	
EndProcedure

&AtClient
Procedure SortAsc()
	
	SortByColumn("Asc");
	
EndProcedure

&AtClient
Procedure SortDesc()
	
	SortByColumn("Desc");
	
EndProcedure

&AtClient
Procedure OpenUser(Command)
	OpenUserFromList();
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UsersList.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UsersList.Session");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("Font", New Font(,, True));

EndProcedure

&AtClient
Procedure FillList()
	
	// Saving the current session data that will be used to restore the row position.
	CurrentSession = Undefined;
	CurrentData = Items.UsersList.CurrentData;
	
	If CurrentData <> Undefined Then
		CurrentSession = CurrentData.Session;
	EndIf;
	
	FillUserList();
	
	// Restoring the current row position based on the saved session data.
	If CurrentSession <> Undefined Then
		SearchStructure = New Structure;
		SearchStructure.Insert("Session", CurrentSession);
		FoundSessions = UsersList.FindRows(SearchStructure);
		If FoundSessions.Count() = 1 Then
			Items.UsersList.CurrentRow = FoundSessions[0].GetID();
			Items.UsersList.SelectedRows.Clear();
			Items.UsersList.SelectedRows.Add(Items.UsersList.CurrentRow);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure SortByColumn(Direction)
	
	Column = Items.UsersList.CurrentItem;
	If Column = Undefined Then
		Return;
	EndIf;
	
	SortColumnName = Column.Name;
	SortDirection = Direction;
	
	FillList();
	
EndProcedure

&AtServer
Procedure FillConnectionFilterSelectionList()
	ApplicationNames = New Array;
	ApplicationNames.Add("1CV8");
	ApplicationNames.Add("1CV8C");
	ApplicationNames.Add("WebClient");
	ApplicationNames.Add("Designer");
	ApplicationNames.Add("COMConnection");
	ApplicationNames.Add("WSConnection");
	ApplicationNames.Add("BackgroundJob");
	ApplicationNames.Add("SystemBackgroundJob");
	ApplicationNames.Add("SrvrConsole");
	ApplicationNames.Add("COMConsole");
	ApplicationNames.Add("JobScheduler");
	ApplicationNames.Add("Debugger");
	ApplicationNames.Add("OpenIDProvider");
	ApplicationNames.Add("RAS");
	
	ChoiceList = Items.ApplicationNameFilter.ChoiceList;
	For Each ApplicationName In ApplicationNames Do
		ChoiceList.Add(ApplicationName, ApplicationPresentation(ApplicationName));
	EndDo;
EndProcedure

&AtServer
Procedure FillUserList()
	
	UsersList.Clear();
	
	If NOT Common.DataSeparationEnabled()
	 OR Common.SeparatedDataUsageAvailable() Then
		
		Users.FindAmbiguousIBUsers(Undefined);
	EndIf;
	
	InfobaseSessions = GetInfoBaseSessions();
	ActiveUserCount = InfobaseSessions.Count();
	
	FilterApplicationNames = ValueIsFilled(ApplicationNameFilter);
	If FilterApplicationNames Then
		ApplicationNames = StrSplit(ApplicationNameFilter, ",");
	EndIf;
	
	For Each IBSession In InfobaseSessions Do
		If FilterApplicationNames
			AND ApplicationNames.Find(IBSession.ApplicationName) = Undefined Then
			ActiveUserCount = ActiveUserCount - 1;
			Continue;
		EndIf;
		
		UserLine = UsersList.Add();
		
		UserLine.Application   = ApplicationPresentation(IBSession.ApplicationName);
		UserLine.WorkStart = IBSession.SessionStarted;
		UserLine.Computer    = IBSession.ComputerName;
		UserLine.Session        = IBSession.SessionNumber;
		UserLine.Connection   = IBSession.ConnectionNumber;
		
		If TypeOf(IBSession.User) = Type("InfoBaseUser")
		   AND ValueIsFilled(IBSession.User.Name) Then
			
			UserLine.User        = IBSession.User.Name;
			UserLine.UserName     = IBSession.User.Name;
			UserLine.UserRef  = FindRefByUserID(
				IBSession.User.UUID);
			
			If Common.DataSeparationEnabled() 
				AND Users.IsFullUser(, True) Then
				
				UserLine.DataSeparation = DataSeparationValuesToString(
					IBSession.User.DataSeparation);
			EndIf;
			
		ElsIf Common.DataSeparationEnabled()
		        AND Not Common.SeparatedDataUsageAvailable() Then
			
			UserLine.User       = Users.UnspecifiedUserFullName();
			UserLine.UserName    = "";
			UserLine.UserRef = Undefined;
		Else
			UnspecifiedProperties = UsersInternal.UnspecifiedUserProperties();
			UserLine.User       = UnspecifiedProperties.FullName;
			UserLine.UserName    = "";
			UserLine.UserRef = UnspecifiedProperties.Ref;
		EndIf;

		If IBSession.SessionNumber = InfobaseSessionNumber Then
			UserLine.UserPictureNumber = 0;
		Else
			UserLine.UserPictureNumber = 1;
		EndIf;
		
	EndDo;
	
	UsersList.Sort(SortColumnName + " " + SortDirection);
	
EndProcedure

&AtServer
Function DataSeparationValuesToString(DataSeparation)
	
	Result = "";
	Value = "";
	If DataSeparation.Property("DataArea", Value) Then
		Result = String(Value);
	EndIf;
	
	HasOtherSeparators = False;
	For each Separator In DataSeparation Do
		If Separator.Key = "DataArea" Then
			Continue;
		EndIf;
		If Not HasOtherSeparators Then
			If Not IsBlankString(Result) Then
				Result = Result + " ";
			EndIf;
			Result = Result + "(";
		EndIf;
		Result = Result + String(Separator.Value);
		HasOtherSeparators = True;
	EndDo;
	If HasOtherSeparators Then
		Result = Result + ")";
	EndIf;
	Return Result;
		
EndFunction

&AtServer
Function FindRefByUserID(ID)
	
	// Cannot access the separated catalog from a shared session.
	If Common.DataSeparationEnabled() 
		AND Not Common.SeparatedDataUsageAvailable() Then
		Return Undefined;
	EndIf;
	
	Query = New Query;
	
	QueryTextTemplate = "SELECT
					|	Ref AS Ref
					|FROM
					|	%1
					|WHERE
					|	IBUserID = &ID";
					
	QueryByUsersText = StringFunctionsClientServer.SubstituteParametersToString(QueryTextTemplate, Metadata.Catalogs.Users.FullName());
	
	ExternalUserQueryText = StringFunctionsClientServer.SubstituteParametersToString(QueryTextTemplate, Metadata.Catalogs.ExternalUsers.FullName());
	
	Query.Text = QueryByUsersText;
	Query.Parameters.Insert("ID", ID);
	Result = Query.Execute();
	
	If NOT Result.IsEmpty() Then
		Selection = Result.Select();
		Selection.Next();
		Return Selection.Ref;
	EndIf;
	
	Query.Text = ExternalUserQueryText;
	Result = Query.Execute();
	
	If NOT Result.IsEmpty() Then
		Selection = Result.Select();
		Selection.Next();
		Return Selection.Ref;
	EndIf;
	
	Return Catalogs.Users.EmptyRef();
	
EndFunction

&AtClient
Procedure OpenUserFromList()
	
	CurrentData = Items.UsersList.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	User = CurrentData.UserRef;
	If ValueIsFilled(User) Then
		OpeningParameters = New Structure("Key", User);
		If TypeOf(User) = Type("CatalogRef.Users") Then
			OpenForm("Catalog.Users.Form.ItemForm", OpeningParameters);
		ElsIf TypeOf(User) = Type("CatalogRef.ExternalUsers") Then
			OpenForm("Catalog.ExternalUsers.Form.ItemForm", OpeningParameters);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure TerminateSessionContinuation(Result, SessionsArray) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	AdministrationParameters = Result;
	
	SessionStructure = New Structure;
	SessionStructure.Insert("Property", "Number");
	SessionStructure.Insert("ComparisonType", ComparisonType.InList);
	SessionStructure.Insert("Value", SessionsArray);
	Filter = CommonClientServer.ValueInArray(SessionStructure);
	
	Try
		DeleteInfobaseSessionsAtServer(AdministrationParameters, Filter)
	Except
		PromptForIBAdministrationParameters = True;
		Raise;
	EndTry;
	
	PromptForIBAdministrationParameters = False;
	
	AfterSessionTermination(DialogReturnCode.OK, New Structure("SessionNumbers", SessionsArray));
	
EndProcedure

&AtClient
Procedure AfterSessionTermination(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.OK Then
		
		If AdditionalParameters.SessionNumbers.Count() > 1 Then
			
			NotificationText = NStr("ru = 'Сеансы %1 завершены.'; en = 'Sessions %1 are closed.'; pl = 'Sesje %1 są zakończone.';de = 'Sitzungen %1 sind beendet.';ro = 'Sesiunile %1 sunt terminate.';tr = 'Oturumlar %1 sonlandırıldı.'; es_ES = 'Sesiones %1 se han finalizado.'");
			SessionNumbers = StrConcat(AdditionalParameters.SessionNumbers, ",");
			NotificationText = StringFunctionsClientServer.SubstituteParametersToString(NotificationText, SessionNumbers);
			ShowUserNotification(NStr("ru = 'Завершение сеансов'; en = 'Sessions closed'; pl = 'Zakończenie sesji';de = 'Sitzungen beenden';ro = 'Finalizarea sesiunilor';tr = 'Oturumları sonlandır'; es_ES = 'Finalizar las sesiones'"),, NotificationText);
			
		Else
			
			NotificationText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Сеанс %1 завершен.'; en = 'Session %1 is closed.'; pl = 'Sesja %1 zakończona.';de = 'Sitzung %1 ist beendet.';ro = 'Sesiunea %1 este finalizată.';tr = 'Oturum  %1 sonlandırıldı.'; es_ES = 'Sesión %1 se ha finalizado.'"), AdditionalParameters.SessionNumbers[0]);
			ShowUserNotification(NStr("ru = 'Завершение сеанса'; en = 'Session closed'; pl = 'Zakończenie sesji';de = 'Ende der Sitzung';ro = 'Finalizarea sesiunii';tr = 'Oturumu sonlandır'; es_ES = 'Terminar la sesión'"),, NotificationText);
			
		EndIf;
		
		FillList();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure DeleteInfobaseSessionsAtServer(AdministrationParameters, Filter)
	
	ClusterAdministration.DeleteInfobaseSessions(AdministrationParameters,, Filter);
	
EndProcedure

#EndRegion
