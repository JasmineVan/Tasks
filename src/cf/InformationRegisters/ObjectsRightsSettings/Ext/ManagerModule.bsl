﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Updates available rights for object rights settings and saves the content of the latest changes.
// 
// Parameters:
//  HasChanges - Boolean (return value) - if changes are found, True is set, otherwise, it is not 
//                  changed.
//
Procedure UpdateAvailableRightsForObjectsRightsSettings(HasChanges = Undefined) Export
	
	AvailableRights = AvailableRights();
	
	BeginTransaction();
	Try
		HasCurrentChanges = False;
		
		StandardSubsystemsServer.UpdateApplicationParameter(
			"StandardSubsystems.AccessManagement.RightsForObjectsRightsSettingsAvailable",
			AvailableRights, HasCurrentChanges);
		
		StandardSubsystemsServer.AddApplicationParameterChanges(
			"StandardSubsystems.AccessManagement.RightsForObjectsRightsSettingsAvailable",
			?(HasCurrentChanges,
			  New FixedStructure("HasChanges", True),
			  New FixedStructure()) );
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	If HasCurrentChanges Then
		HasChanges = True;
	EndIf;
	
EndProcedure

// Updates auxiliary register data after changing rights based on access values saved to access 
// restriction parameters.
//
Procedure UpdateAuxiliaryRegisterDataByConfigurationChanges() Export
	
	SetPrivilegedMode(True);
	
	LastChanges = StandardSubsystemsServer.ApplicationParameterChanges(
		"StandardSubsystems.AccessManagement.RightsForObjectsRightsSettingsAvailable");
		
	If LastChanges = Undefined Then
		UpdateRequired = True;
	Else
		UpdateRequired = False;
		For each ChangesPart In LastChanges Do
			
			If TypeOf(ChangesPart) = Type("FixedStructure")
			   AND ChangesPart.Property("HasChanges")
			   AND TypeOf(ChangesPart.HasChanges) = Type("Boolean") Then
				
				If ChangesPart.HasChanges Then
					UpdateRequired = True;
					Break;
				EndIf;
			Else
				UpdateRequired = True;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	If UpdateRequired Then
		UpdateAuxiliaryRegisterData();
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Returns the object right settings.
//
// Parameters:
//  ObjectRef - a reference to the object, for which reading of right settings is required.
//
// Returns:
//  Structure
//    Inherit        - Boolean - a flag of inheriting parent right settings.
//    Settings - ValueTable
//                         - SettingOwner - a reference to an object or an object parent (from the 
//                                                   object parent hierarchy).
//                         - InheritanceAllowed - Boolean - inheritance allowed.
//                         - User          - CatalogRef.Users
//                                                   CatalogRef.UserGroups
//                                                   CatalogRef.ExternalUsers
//                                                   CatalogRef.ExternalUserGroups.
//                         - <RightName1>           - Undefined, Boolean
//                                                       Undefined - the right is not configured,
//                                                       True       - the right is allowed,
//                                                       False         - the right is restricted.
//                         - <RightName2>           - ...
//
Function Read(Val ObjectRef) Export
	
	AvailableRights = AccessManagementInternalCached.RightsForObjectsRightsSettingsAvailable();
	
	RightsDetails = AvailableRights.ByTypes.Get(TypeOf(ObjectRef));
	
	If RightsDetails = Undefined Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Ошибка в процедуре РегистрыСведений.НастройкиПравОбъектов.Прочитать()
			           |
			           |Неверное значение параметра СсылкаНаОбъект ""%1"".
			           |Для объектов таблицы ""%2"" права не настраиваются.'; 
			           |en = 'An error occurred in the InformationRegisters.ObjectsRightsSettings.Read() procedure
			           |
			           |Incorrect ObjectRef parameter value ""%1"".
			           |Rights are not set for the table ""%2"" objects.'; 
			           |pl = 'Błąd procedury InformationRegisters.ObjectRightsSettings.Read()
			           |
			           |Błędna wartość atrybutu RefToObject %1.
			           |Prawa nie zostały ustawione dla obiektów tablicy %2.';
			           |de = 'Fehler in der Prozedur RegisterInformation.EinstellungRechteObjekt.Lesen()
			           |
			           |Falscher Wert des Parameters LinkfürObjekt ""%1"".
			           |Für die Tabellenobjekte ""%2"" werden keine Berechtigungen gesetzt.';
			           |ro = 'Eroare în procedura РегистрыСведений.НастройкиПравОбъектов.Прочитать()
			           |
			           |Valoare incorectă a parametrului СсылкаНаОбъект ""%1"".
			           |Pentru obiectele din tabelul ""%2"" nu se configurează drepturile.';
			           |tr = 'BilgiKayıtları prosedüründe hata oluştu. NesneHaklarıAyarları.Read ()
			           |
			           | NesneReferansı%1 parametresinin yanlış değeri. 
			           |Tablo nesneleri için haklar %2 ayarlanmamıştır.'; 
			           |es_ES = 'Error en el procedimiento InformationRegisters.ObjectsRightsSettings.Read()
			           |
			           |Valor incorrecto del parámetro ObjectRef ""%1"".
			           |Para los objetos de la tabla ""%2"" los derechos no se ajustan.'"),
			String(ObjectRef),
			ObjectRef.Metadata().FullName());
	EndIf;
	
	RightsSettings = New Structure;
	
	// Getting the inheritance setting value.
	RightsSettings.Insert("Inherit",
		InformationRegisters.ObjectRightsSettingsInheritance.SettingsInheritance(ObjectRef));
	
	// Preparing the right settings table structure.
	Settings = New ValueTable;
	Settings.Columns.Add("User");
	Settings.Columns.Add("SettingsOwner");
	Settings.Columns.Add("InheritanceIsAllowed", New TypeDescription("Boolean"));
	Settings.Columns.Add("ParentSetting",     New TypeDescription("Boolean"));
	For each RightDetails In RightsDetails Do
		Settings.Columns.Add(RightDetails.Key);
	EndDo;
	
	If AvailableRights.HierarchicalTables.Get(TypeOf(ObjectRef)) = Undefined Then
		SettingsInheritance = AccessManagementInternalCached.BlankRecordSetTable(
			Metadata.InformationRegisters.ObjectRightsSettingsInheritance.FullName()).Get();
		NewRow = SettingsInheritance.Add();
		SettingsInheritance.Columns.Add("Level", New TypeDescription("Number"));
		NewRow.Object   = ObjectRef;
		NewRow.Parent = ObjectRef;
	Else
		SettingsInheritance = InformationRegisters.ObjectRightsSettingsInheritance.ObjectParents(
			ObjectRef, , , False);
	EndIf;
	
	// Reading object settings and settings of parent objects inherited by the object.
	Query = New Query;
	Query.SetParameter("Object", ObjectRef);
	Query.SetParameter("SettingsInheritance", SettingsInheritance);
	Query.Text =
	"SELECT
	|	SettingsInheritance.Object AS Object,
	|	SettingsInheritance.Parent AS Parent,
	|	SettingsInheritance.Level AS Level
	|INTO SettingsInheritance
	|FROM
	|	&SettingsInheritance AS SettingsInheritance
	|
	|INDEX BY
	|	SettingsInheritance.Object,
	|	SettingsInheritance.Parent
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SettingsInheritance.Parent AS SettingsOwner,
	|	ObjectsRightsSettings.User AS User,
	|	ObjectsRightsSettings.Right AS Right,
	|	CASE
	|		WHEN SettingsInheritance.Parent <> &Object
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ParentSetting,
	|	ObjectsRightsSettings.RightIsProhibited AS RightIsProhibited,
	|	ObjectsRightsSettings.InheritanceIsAllowed AS InheritanceIsAllowed
	|FROM
	|	InformationRegister.ObjectsRightsSettings AS ObjectsRightsSettings
	|		INNER JOIN SettingsInheritance AS SettingsInheritance
	|		ON ObjectsRightsSettings.Object = SettingsInheritance.Parent
	|WHERE
	|	(SettingsInheritance.Parent = &Object
	|			OR ObjectsRightsSettings.InheritanceIsAllowed)
	|
	|ORDER BY
	|	ParentSetting DESC,
	|	SettingsInheritance.Level,
	|	ObjectsRightsSettings.SettingsOrder";
	Table = Query.Execute().Unload();
	
	CurrentSettingOwner = Undefined;
	CurrentUser = Undefined;
	For each Row In Table Do
		If CurrentSettingOwner <> Row.SettingsOwner
		 OR CurrentUser <> Row.User Then
			CurrentSettingOwner = Row.SettingsOwner;
			CurrentUser      = Row.User;
			Setting = Settings.Add();
			Setting.User      = Row.User;
			Setting.SettingsOwner = Row.SettingsOwner;
			Setting.ParentSetting = Row.ParentSetting;
		EndIf;
		If Settings.Columns.Find(Row.Right) = Undefined Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Ошибка в процедуре РегистрыСведений.НастройкиПравОбъектов.Прочитать()
				           |
				           |Для объектов таблицы ""%1""
				           |право ""%2"" не настраивается, однако оно записано
				           |в регистре сведений НастройкиПравОбъектов для
				           |объекта ""%3"".
				           |
				           |Возможно, обновление информационной базы
				           |не выполнено или выполнено с ошибкой.
				           |Требуется исправить данные регистра.'; 
				           |en = 'An error occurred in the InformationRegisters.ObjectsRightsSettings.Read() procedure
				           |
				           |Right ""%2"" is not set 
				           |for the ""%1"" table objects, 
				           |but it is written
				           |to the ObjectsRightsSettings information register
				           |for object ""%3"".
				           |
				           |Maybe, the infobase is not updated or there are update errors.
				           |Change the register data.'; 
				           |pl = 'Błąd procedury InformationRegisters.ObjectRightsSettings.Read()
				           |
				           |%2Prawo
				           |nie zostało ustawione dla obiektów tablicy
				           |%1, jednak jest ono
				           |zapisane w rejestrze informacji ObjectsRightsSettings dla obiektu %3.
				           |
				           |Być może aktualizacja bazy informacyjnej
				           |nie została przeprowadzona lub była wykonana z błędami.
				           |Dane rejestru wymagają korekcji.';
				           |de = 'Fehler in der Informationsregisterprozedur.ObjektrechteEinstellungen.Lesen()
				           |
				           |das %2 Recht
				           |wird nicht für Objekte der
				           |%1 Tabelle festgelegt, jedoch wird es in
				           |das Informationsregister ObjektrechteEinstellungen der %3 Objekte geschrieben.
				           |
				           |Das Infobaseupdate
				           | wurde möglicherweise nicht ausgeführt oder mit einem Fehler ausgeführt.
				           |Registerdaten müssen korrigiert werden.';
				           |ro = 'Eroare în procedura РегистрыСведений.НастройкиПравОбъектов.Прочитать()
				           |
				           |Pentru obiectele tabelului ""%1""
				           |dreptul ""%2"" nu trebuie setat, însă el este înregistrat
				           |în registrul de date НастройкиПравОбъектов pentru
				           |obiectul ""%3"".
				           |
				           |Posibil, baza de informații
				           |nu a fost actualizată sau a fost actualizată cu erori.
				           |Datele registrului trebuie corectate.';
				           |tr = 'BilgiKayıtları prosedüründe hata oluştu. NesneHaklarıAyarları. Read () 
				           |
				           |tablonun nesneleri %2  için
				           | ayarlanmayan haklar, ancak
				           |nnesne için NesneHaklarıAyarları bilgi kaydına yazılır.%1
				           | Veritabanı güncellemesi bir
				           |
				           | hata ile yürütülmüş veya yürütülmemiş olabilir %3
				           |
				           |Kayıt verileri düzeltilmek için gereklidir.'; 
				           |es_ES = 'Error en el procedimiento InformationRegisters.ObjectRightsSettings.Read()
				           |
				           |el %2 derecho
				           |no está establecido para los objetos de la
				           |%1 tabla, aunque, se ha
				           |grabado en el registro de información ObjectsRightsSettings para el %3 objeto.
				           |
				           |La actualización de la infobase
				           |puede no haberse ejecutado, o ejecutado con un error.
				           |Se requiere la corrección de los datos de registro.'"),
				ObjectRef.Metadata().FullName(),
				Row.Right,
				String(ObjectRef));
		EndIf;
		Setting.InheritanceIsAllowed = Setting.InheritanceIsAllowed OR Row.InheritanceIsAllowed;
		Setting[Row.Right] = NOT Row.RightIsProhibited;
	EndDo;
	
	RightsSettings.Insert("Settings", Settings);
	
	Return RightsSettings;
	
EndFunction

// Writes the object right settings.
//
// Parameters:
//  Inherit - Boolean - a flag of inheriting parent right settings.
//  Settings - ValueTable with a structure returned by the Read() function. Only rows whose 
//                SettingOwner = ObjectRef are saved.
//
Procedure Write(Val ObjectRef, Val Settings, Val Inherit) Export
	
	StandardSubsystemsServer.CheckApplicationVersionDynamicUpdate();
	AvailableRights = AccessManagementInternalCached.RightsForObjectsRightsSettingsAvailable();
	RightsDetails = AvailableRights.ByRefsTypes.Get(TypeOf(ObjectRef));
	
	If RightsDetails = Undefined Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Ошибка в процедуре РегистрыСведений.НастройкиПравОбъектов.Прочитать()
			           |
			           |Неверное значение параметра СсылкаНаОбъект ""%1"".
			           |Для объектов таблицы ""%2"" права не настраиваются.'; 
			           |en = 'An error occurred in the InformationRegisters.ObjectsRightsSettings.Read() procedure
			           |
			           |Incorrect ObjectRef parameter value ""%1"".
			           |Rights are not set for the table ""%2"" objects.'; 
			           |pl = 'Błąd procedury InformationRegisters.ObjectRightsSettings.Read()
			           |
			           |Błędna wartość atrybutu RefToObject %1.
			           |Prawa nie zostały ustawione dla obiektów tablicy %2.';
			           |de = 'Fehler in der Prozedur RegisterInformation.EinstellungRechteObjekt.Lesen()
			           |
			           |Falscher Wert des Parameters LinkfürObjekt ""%1"".
			           |Für die Tabellenobjekte ""%2"" werden keine Berechtigungen gesetzt.';
			           |ro = 'Eroare în procedura РегистрыСведений.НастройкиПравОбъектов.Прочитать()
			           |
			           |Valoare incorectă a parametrului СсылкаНаОбъект ""%1"".
			           |Pentru obiectele din tabelul ""%2"" nu se configurează drepturile.';
			           |tr = 'BilgiKayıtları prosedüründe hata oluştu. NesneHaklarıAyarları.Read ()
			           |
			           | NesneReferansı%1 parametresinin yanlış değeri. 
			           |Tablo nesneleri için haklar %2 ayarlanmamıştır.'; 
			           |es_ES = 'Error en el procedimiento InformationRegisters.ObjectsRightsSettings.Read()
			           |
			           |Valor incorrecto del parámetro ObjectRef ""%1"".
			           |Para los objetos de la tabla ""%2"" los derechos no se ajustan.'"),
			String(ObjectRef),
			ObjectRef.Metadata().FullName());
	EndIf;
	
	// Setting the inheritance setting flag.
	RecordSet = InformationRegisters.ObjectRightsSettingsInheritance.CreateRecordSet();
	RecordSet.Filter.Object.Set(ObjectRef);
	RecordSet.Filter.Parent.Set(ObjectRef);
	RecordSet.Read();
	
	If RecordSet.Count() = 0 Then
		ChangedInheritance = True;
		NewRecord = RecordSet.Add();
		NewRecord.Object      = ObjectRef;
		NewRecord.Parent    = ObjectRef;
		NewRecord.Inherit = Inherit;
	Else
		ChangedInheritance = RecordSet[0].Inherit <> Inherit;
		RecordSet[0].Inherit = Inherit;
	EndIf;
	
	// Preparing new settings
	NewRightsSettings = AccessManagementInternalCached.BlankRecordSetTable(
		Metadata.InformationRegisters.ObjectsRightsSettings.FullName()).Get();
	
	CommonRightsTable = Catalogs.MetadataObjectIDs.EmptyRef();
	
	Filter = New Structure("SettingsOwner", ObjectRef);
	SettingsOrder = 0;
	For each Setting In Settings.FindRows(Filter) Do
		For each RightDetails In RightsDetails Do
			If TypeOf(Setting[RightDetails.Name]) <> Type("Boolean") Then
				Continue;
			EndIf;
			SettingsOrder = SettingsOrder + 1;
			
			RightsSetting = NewRightsSettings.Add();
			RightsSetting.SettingsOrder      = SettingsOrder;
			RightsSetting.Object                = ObjectRef;
			RightsSetting.User          = Setting.User;
			RightsSetting.Right                 = RightDetails.Name;
			RightsSetting.Table               = CommonRightsTable;
			RightsSetting.RightIsProhibited        = NOT Setting[RightDetails.Name];
			RightsSetting.InheritanceIsAllowed = Setting.InheritanceIsAllowed;
			// Cache attributes
			RightsSetting.RightPermissionLevel =
				?(RightsSetting.RightIsProhibited, 0, ?(RightsSetting.InheritanceIsAllowed, 2, 1));
			RightsSetting.RightProhibitionLevel =
				?(RightsSetting.RightIsProhibited, ?(RightsSetting.InheritanceIsAllowed, 2, 1), 0);
			
			AddedIndividualTablesSettings = False;
			For each KeyAndValue In AvailableRights.SeparateTables Do
				SeparateTable = KeyAndValue.Key;
				ReadTable    = RightDetails.ReadInTables.Find(   SeparateTable) <> Undefined;
				TableChange = RightDetails.ChangeInTables.Find(SeparateTable) <> Undefined;
				If NOT ReadTable AND NOT TableChange Then
					Continue;
				EndIf;
				AddedIndividualTablesSettings = True;
				TableRightsSettings = NewRightsSettings.Add();
				FillPropertyValues(TableRightsSettings, RightsSetting);
				TableRightsSettings.Table = SeparateTable;
				If ReadTable Then
					TableRightsSettings.ReadingPermissionLevel = RightsSetting.RightPermissionLevel;
					TableRightsSettings.ReadingProhibitionLevel = RightsSetting.RightProhibitionLevel;
				EndIf;
				If TableChange Then
					TableRightsSettings.ChangingPermissionLevel = RightsSetting.RightPermissionLevel;
					TableRightsSettings.ChangingProhibitionLevel = RightsSetting.RightProhibitionLevel;
				EndIf;
			EndDo;
			
			CommonRead    = RightDetails.ReadInTables.Find(   CommonRightsTable) <> Undefined;
			CommonChange = RightDetails.ChangeInTables.Find(CommonRightsTable) <> Undefined;
			
			If NOT CommonRead AND NOT CommonChange AND AddedIndividualTablesSettings Then
				NewRightsSettings.Delete(RightsSetting);
			Else
				If CommonRead Then
					RightsSetting.ReadingPermissionLevel = RightsSetting.RightPermissionLevel;
					RightsSetting.ReadingProhibitionLevel = RightsSetting.RightProhibitionLevel;
				EndIf;
				If CommonChange Then
					RightsSetting.ChangingPermissionLevel = RightsSetting.RightPermissionLevel;
					RightsSetting.ChangingProhibitionLevel = RightsSetting.RightProhibitionLevel;
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	
	// Writing object right settings and an inheritance flag of right settings.
	BeginTransaction();
	Try
		Data = New Structure;
		Data.Insert("RecordSet",   InformationRegisters.ObjectsRightsSettings);
		Data.Insert("NewRecords",    NewRightsSettings);
		Data.Insert("FilterField",     "Object");
		Data.Insert("FilterValue", ObjectRef);
		
		HasChanges = False;
		AccessManagementInternal.UpdateRecordSet(Data, HasChanges);
		
		If HasChanges Then
			ObjectsWithChanges = New Array;
		Else
			ObjectsWithChanges = Undefined;
		EndIf;
		
		If ChangedInheritance Then
			StandardSubsystemsServer.CheckApplicationVersionDynamicUpdate();
			RecordSet.Write();
			InformationRegisters.ObjectRightsSettingsInheritance.UpdateOwnerParents(
				ObjectRef, , True, ObjectsWithChanges);
		EndIf;
		
		If ObjectsWithChanges <> Undefined Then
			AddHierarchyObjects(ObjectRef, ObjectsWithChanges);
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Updates auxiliary register data when changing the configuration.
// 
// Parameters:
//  HasChanges - Boolean (return value) - if recorded, True is set, otherwise, it is not changed.
//                  
//
Procedure UpdateAuxiliaryRegisterData(HasChanges = Undefined) Export
	
	StandardSubsystemsServer.CheckApplicationVersionDynamicUpdate();
	
	SetPrivilegedMode(True);
	
	AvailableRights = AccessManagementInternalCached.RightsForObjectsRightsSettingsAvailable();
	
	RightsTables = New ValueTable;
	RightsTables.Columns.Add("RightsOwner", Metadata.InformationRegisters.ObjectsRightsSettings.Dimensions.Object.Type);
	RightsTables.Columns.Add("Right",        Metadata.InformationRegisters.ObjectsRightsSettings.Dimensions.Right.Type);
	RightsTables.Columns.Add("Table",      Metadata.InformationRegisters.ObjectsRightsSettings.Dimensions.Table.Type);
	RightsTables.Columns.Add("Read",       New TypeDescription("Boolean"));
	RightsTables.Columns.Add("Update",    New TypeDescription("Boolean"));
	
	BlankRefsRightsOwner = AccessManagementInternalCached.BlankRefsMapToSpecifiedRefsTypes(
		"InformationRegister.ObjectsRightsSettings.Dimension.Object");
	
	Filter = New Structure;
	For each KeyAndValue In AvailableRights.ByRefsTypes Do
		RightsOwnerType = KeyAndValue.Key;
		RightsDetails     = KeyAndValue.Value;
		
		If BlankRefsRightsOwner.Get(RightsOwnerType) = Undefined Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Ошибка в процедуре ОбновитьВспомогательныеДанныеРегистра
				           |модуля менеджера регистра сведений НастройкиПравОбъектов.
				           |
				           |Тип владельцев прав ""%1"" не указан в измерении Объект.'; 
				           |en = 'An error occurred in the UpdateAuxiliaryRegisterData procedure
				           |of the manager module of the ObjectsRightsSettings information register.
				           |
				           |""%1"" rights owner type is not specified in dimension Object.'; 
				           |pl = 'Błąd
				           |procedury UpdateSubordinateRegisterData modułu menedżera rejestru informacji ObjectsRightsSettings.
				           |
				           |W wymiarze Obiekt nie określono rodzaju %1 posiadacza praw.';
				           |de = 'Fehler in
				           |der Prozedur zum AktualisierenDerUntergeordnetenRegisterdaten des Managermoduls des Informationsregisters Objektrechtseinstellungen. 
				           |
				           |Der Typ des %1 Rechteinhabers ist in der Dimension Objekt nicht angegeben.';
				           |ro = 'Eroare în procedura ОбновитьВспомогательныеДанныеРегистра
				           |a modulului managerului registrului de date НастройкиПравОбъектов.
				           |
				           |Tipul titularilor drepturilor ""%1"" nu este specificat în dimensiunea Obiect.';
				           |tr = 'NesneHaklarıAyarları
				           |  bilgi kaydının yönetici modülünün AltKayıtVeriyiGüncelle prosedüründe  hata. 
				           |
				           |Nesne boyutunda hak sahibinin türü belirtilmemiş.%1'; 
				           |es_ES = 'Error en
				           |el procedimiento UpdateSubordinateRegisterData del módulo gestor del registro de información ObjectsRightsSettings.
				           |
				           |Tipo del %1 propietario de derechos no está especificado en la dimensión Objeto.'"),
				RightsOwnerType);
		EndIf;
		
		Filter.Insert("RightsOwner", BlankRefsRightsOwner.Get(RightsOwnerType));
		For each RightDetails In RightsDetails Do
			Filter.Insert("Right", RightDetails.Name);
			
			For each Table In RightDetails.ReadInTables Do
				Row = RightsTables.Add();
				FillPropertyValues(Row, Filter);
				Row.Table = Table;
				Row.Read = True;
			EndDo;
			
			For each Table In RightDetails.ChangeInTables Do
				Filter.Insert("Table", Table);
				Rows = RightsTables.FindRows(Filter);
				If Rows.Count() = 0 Then
					Row = RightsTables.Add();
					FillPropertyValues(Row, Filter);
				Else
					Row = Rows[0];
				EndIf;
				Row.Update = True;
			EndDo;
		EndDo;
	EndDo;
	
	TemporaryTablesQueriesText =
	"SELECT
	|	RightsTables.RightsOwner,
	|	RightsTables.Right,
	|	RightsTables.Table,
	|	RightsTables.Read,
	|	RightsTables.Update
	|INTO RightsTables
	|FROM
	|	&RightsTables AS RightsTables
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RightsSettings.Object AS Object,
	|	RightsSettings.User AS User,
	|	RightsSettings.Right AS Right,
	|	MAX(RightsSettings.RightIsProhibited) AS RightIsProhibited,
	|	MAX(RightsSettings.InheritanceIsAllowed) AS InheritanceIsAllowed,
	|	MAX(RightsSettings.SettingsOrder) AS SettingsOrder
	|INTO RightsSettings
	|FROM
	|	InformationRegister.ObjectsRightsSettings AS RightsSettings
	|
	|GROUP BY
	|	RightsSettings.Object,
	|	RightsSettings.User,
	|	RightsSettings.Right
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RightsSettings.Object,
	|	RightsSettings.User,
	|	RightsSettings.Right,
	|	ISNULL(RightsTables.Table, VALUE(Catalog.MetadataObjectIDs.EmptyRef)) AS Table,
	|	RightsSettings.RightIsProhibited,
	|	RightsSettings.InheritanceIsAllowed,
	|	RightsSettings.SettingsOrder,
	|	CASE
	|		WHEN RightsSettings.RightIsProhibited
	|			THEN 0
	|		WHEN RightsSettings.InheritanceIsAllowed
	|			THEN 2
	|		ELSE 1
	|	END AS RightPermissionLevel,
	|	CASE
	|		WHEN NOT RightsSettings.RightIsProhibited
	|			THEN 0
	|		WHEN RightsSettings.InheritanceIsAllowed
	|			THEN 2
	|		ELSE 1
	|	END AS RightProhibitionLevel,
	|	CASE
	|		WHEN NOT ISNULL(RightsTables.Read, FALSE)
	|			THEN 0
	|		WHEN RightsSettings.RightIsProhibited
	|			THEN 0
	|		WHEN RightsSettings.InheritanceIsAllowed
	|			THEN 2
	|		ELSE 1
	|	END AS ReadingPermissionLevel,
	|	CASE
	|		WHEN NOT ISNULL(RightsTables.Read, FALSE)
	|			THEN 0
	|		WHEN NOT RightsSettings.RightIsProhibited
	|			THEN 0
	|		WHEN RightsSettings.InheritanceIsAllowed
	|			THEN 2
	|		ELSE 1
	|	END AS ReadingProhibitionLevel,
	|	CASE
	|		WHEN NOT ISNULL(RightsTables.Update, FALSE)
	|			THEN 0
	|		WHEN RightsSettings.RightIsProhibited
	|			THEN 0
	|		WHEN RightsSettings.InheritanceIsAllowed
	|			THEN 2
	|		ELSE 1
	|	END AS ChangingPermissionLevel,
	|	CASE
	|		WHEN NOT ISNULL(RightsTables.Update, FALSE)
	|			THEN 0
	|		WHEN NOT RightsSettings.RightIsProhibited
	|			THEN 0
	|		WHEN RightsSettings.InheritanceIsAllowed
	|			THEN 2
	|		ELSE 1
	|	END AS ChangingProhibitionLevel
	|INTO NewData
	|FROM
	|	RightsSettings AS RightsSettings
	|		LEFT JOIN RightsTables AS RightsTables
	|		ON (VALUETYPE(RightsSettings.Object) = VALUETYPE(RightsTables.RightsOwner))
	|			AND RightsSettings.Right = RightsTables.Right
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP RightsTables
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP RightsSettings";
	
	QueryText =
	"SELECT
	|	NewData.Object,
	|	NewData.User,
	|	NewData.Right,
	|	NewData.Table,
	|	NewData.RightIsProhibited,
	|	NewData.InheritanceIsAllowed,
	|	NewData.SettingsOrder,
	|	NewData.RightPermissionLevel,
	|	NewData.RightProhibitionLevel,
	|	NewData.ReadingPermissionLevel,
	|	NewData.ReadingProhibitionLevel,
	|	NewData.ChangingPermissionLevel,
	|	NewData.ChangingProhibitionLevel,
	|	&RowChangeKindFieldSubstitution
	|FROM
	|	NewData AS NewData";
	
	// Preparing the selected fields with optional filter.
	Fields = New Array;
	Fields.Add(New Structure("Object"));
	Fields.Add(New Structure("User"));
	Fields.Add(New Structure("Right"));
	Fields.Add(New Structure("Table"));
	Fields.Add(New Structure("RightIsProhibited"));
	Fields.Add(New Structure("InheritanceIsAllowed"));
	Fields.Add(New Structure("SettingsOrder"));
	Fields.Add(New Structure("RightPermissionLevel"));
	Fields.Add(New Structure("RightProhibitionLevel"));
	Fields.Add(New Structure("ReadingPermissionLevel"));
	Fields.Add(New Structure("ReadingProhibitionLevel"));
	Fields.Add(New Structure("ChangingPermissionLevel"));
	Fields.Add(New Structure("ChangingProhibitionLevel"));
	
	Query = New Query;
	Query.SetParameter("RightsTables", RightsTables);
	
	Query.Text = AccessManagementInternal.ChangesSelectionQueryText(
		QueryText, Fields, "InformationRegister.ObjectsRightsSettings", TemporaryTablesQueriesText);
	
	Lock = New DataLock;
	Lock.Add("InformationRegister.ObjectsRightsSettings");
	
	BeginTransaction();
	Try
		Lock.Lock();
		
		Data = New Structure;
		Data.Insert("RegisterManager",      InformationRegisters.ObjectsRightsSettings);
		Data.Insert("EditStringContent", Query.Execute().Unload());
		
		AccessManagementInternal.UpdateInformationRegister(Data, HasChanges);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// See InformationRegisters.ObjectsRightsSettings.AvailableRights. 
Function RightsForObjectsRightsSettingsAvailable() Export
	
	AvailableRights = StandardSubsystemsServer.ApplicationParameter(
		"StandardSubsystems.AccessManagement.RightsForObjectsRightsSettingsAvailable");
	
	If AvailableRights = Undefined Then
		UpdateAvailableRightsForObjectsRightsSettings();
	EndIf;
	
	AvailableRights = StandardSubsystemsServer.ApplicationParameter(
		"StandardSubsystems.AccessManagement.RightsForObjectsRightsSettingsAvailable");
	
	Return AvailableRights;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Updating an infobase.

Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	// Data registration is not required.
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	UpdateAuxiliaryRegisterData();
	
	Parameters.ProcessingCompleted = True;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Auxiliary procedures and functions.

Procedure AddHierarchyObjects(Ref, ObjectsArray)
	
	Query = New Query;
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("ObjectsArray", ObjectsArray);
	
	Query.Text = StrReplace(
	"SELECT
	|	TableWithHierarchy.Ref
	|FROM
	|	ObjectsTable AS TableWithHierarchy
	|WHERE
	|	TableWithHierarchy.Ref IN HIERARCHY(&Ref)
	|	AND NOT TableWithHierarchy.Ref IN (&ObjectsArray)",
	"ObjectsTable",
	Ref.Metadata().FullName());
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		ObjectsArray.Add(Selection.Ref);
	EndDo;
	
EndProcedure

// See AccessManagementOverridable.OnFillAvailableRightsForObjectsRightsSettings. 
Function AvailableRights()
	
	AvailableRights = New ValueTable();
	AvailableRights.Columns.Add("RightsOwner",        New TypeDescription("String"));
	AvailableRights.Columns.Add("Name",                 New TypeDescription("String", , New StringQualifiers(60)));
	AvailableRights.Columns.Add("Title",           New TypeDescription("String", , New StringQualifiers(60)));
	AvailableRights.Columns.Add("ToolTip",           New TypeDescription("String", , New StringQualifiers(150)));
	AvailableRights.Columns.Add("InitialValue",   New TypeDescription("Boolean,Number"));
	AvailableRights.Columns.Add("RequiredRights",      New TypeDescription("Array"));
	AvailableRights.Columns.Add("ReadInTables",     New TypeDescription("Array"));
	AvailableRights.Columns.Add("ChangeInTables",  New TypeDescription("Array"));
	
	SSLSubsystemsIntegration.OnFillAvailableRightsForObjectsRightsSettings(AvailableRights);
	AccessManagementOverridable.OnFillAvailableRightsForObjectsRightsSettings(AvailableRights);
	
	ErrorTitle =
		NStr("ru = 'Ошибка в процедуре ПриЗаполненииВозможныхПравДляНастройкиПравОбъектов
		           |общего модуля УправлениеДоступомПереопределяемый.'; 
		           |en = 'An error occurred in the OnFillAvailableRightsForObjectsRightsSettings procedure 
		           |of the AccessManagementOverridable common module.'; 
		           |pl = 'Błąd w procedurze PodczasWypełnianiaEwentualnychPrawDoUstawieniaPrawObiektów
		           |do wspólnego modułu ZarządzanieDostępemOkreślonaNaNowo.';
		           |de = 'Fehler bei der Prozedur BeimAusfüllenMöglicherRechteFürEinstellungenRechteObjekt
		           |des allgemeinen Moduls ZugriffsKontrolleNeudefinierbar.';
		           |ro = 'Eroare în procedura ПриЗаполненииВозможныхПравДляНастройкиПравОбъектов
		           |a modulului general УправлениеДоступомПереопределяемый.';
		           |tr = 'ErişimYönetimiYenidenTanımlanmış
		           | ortak modülünün NesneHaklarınAyarlanmasıİçinOlasıHaklarDoldurulduğunda prosedüründe bir hata oluştu.'; 
		           |es_ES = 'Error en el procedimiento OnFillAvailableRightsForObjectsRightsSettings
		           |del módulo común AccessManagementOverridable.'")
		+ Chars.LF
		+ Chars.LF;
	
	ByTypes              = New Map;
	ByRefsTypes        = New Map;
	ByFullNames       = New Map;
	OwnersTypes       = New Array;
	SeparateTables     = New Map;
	HierarchicalTables = New Map;
	
	TypeOfRightsOwnersToDefine  = AccessManagementInternalCached.TableFieldTypes("DefinedType.RightsSettingsOwner");
	TypeOfAccessValuesToDefine = AccessManagementInternalCached.TableFieldTypes("DefinedType.AccessValue");
	
	AccessKindsProperties = AccessManagementInternalCached.AccessKindsProperties();
	
	SubscriptionTypesUpdateRightsSettingsOwnersGroups = AccessManagementInternalCached.TableFieldTypes(
		"DefinedType.RightsSettingsOwnerObject");
	
	SubscriptionTypesWriteAccessValuesSets = AccessManagementInternalCached.ObjectsTypesInSubscriptionsToEvents(
		"WriteAccessValuesSets");
	
	SubscriptionTypesWriteDependentAccessValuesSets = AccessManagementInternalCached.ObjectsTypesInSubscriptionsToEvents(
		"WriteDependentAccessValuesSets");
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("RightsOwner");
	AdditionalParameters.Insert("CommonOwnersRights", New Map);
	AdditionalParameters.Insert("IndividualOwnersRights", New Map);
	
	OwnersRightsIndexes = New Map;
	
	For each PossibleRight In AvailableRights Do
		OwnerMetadataObject = Metadata.FindByFullName(PossibleRight.RightsOwner);
		
		If OwnerMetadataObject = Undefined Then
			Raise ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не найден владелец прав ""%1"".'; en = 'Owner of rights ""%1"" is not found.'; pl = 'Nie znaleziono posiadacza praw ""%1"".';de = 'Inhaber der Rechte ""%1"" wurde nicht gefunden.';ro = 'Proprietarul drepturilor ""%1"" nu a fost găsit.';tr = 'Hak sahibi ""%1"" bulunamadı.'; es_ES = 'Propietario de los derechos ""%1"" no encontrado.'"),
				PossibleRight.RightsOwner);
		EndIf;
		
		AdditionalParameters.RightsOwner = PossibleRight.RightsOwner;
		
		FillIDs("ReadInTables",    PossibleRight, ErrorTitle, SeparateTables, AdditionalParameters);
		FillIDs("ChangeInTables", PossibleRight, ErrorTitle, SeparateTables, AdditionalParameters);
		
		OwnerRights = ByFullNames[PossibleRight.RightsOwner];
		If OwnerRights = Undefined Then
			OwnerRights = New Map;
			OwnerRightsArray = New Array;
			
			RefType = StandardSubsystemsServer.MetadataObjectReferenceOrMetadataObjectRecordKeyType(
				OwnerMetadataObject);
			
			ObjectType = StandardSubsystemsServer.MetadataObjectOrMetadataObjectRecordSetType(
				OwnerMetadataObject);
			
			If TypeOfRightsOwnersToDefine.Get(RefType) = Undefined Then
				Raise ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Тип владельца прав ""%1""
					           |не указан в определяемом типе ""Владелец настроек прав"".'; 
					           |en = '""%1"" rights owner type 
					           |is not specified in defined type ""Rights settings owner"".'; 
					           |pl = 'Typ właściciela praw ""%1""
					           |nie jest określony w podym typie ""Właściciel ustawień praw"".';
					           |de = 'Der Typ des Rechteinhabers ""%1""
					           |ist im festgelegten Typ ""Rechteinhaber-Einstellungen"" nicht angegeben.';
					           |ro = 'Tipul titularului drepturilor
					           |%1 nu este specificat în tipul determinat ""Titularul setărilor drepturilor"".';
					           |tr = 'Hak sahibinin türü"
" %1 haklarının türü tanımlanmış türünde belirtilmemiş.'; 
					           |es_ES = 'El tipo del propietario de derechos ""%1""
					           |no se ha indicado en el tipo predeterminado ""Propietario de ajustes de derechos"".'"),
					String(RefType));
			EndIf;
			
			If (SubscriptionTypesWriteDependentAccessValuesSets.Get(ObjectType) <> Undefined
			      OR SubscriptionTypesWriteAccessValuesSets.Get(ObjectType) <> Undefined)
			    AND TypeOfAccessValuesToDefine.Get(RefType) = Undefined Then
				
				Raise ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Тип владельца прав ""%1""
					           |не указан в определяемом типе ""Значение доступа"",
					           |но используется для заполнения наборов значений доступа,
					           |т.к. указан в одной из подписок на событие:
					           |- ЗаписатьЗависимыеНаборыЗначенийДоступа*,
					           |- ЗаписатьНаборыЗначенийДоступа*.
					           |Требуется указать тип в определяемом типе ""Значение доступа""
					           |для корректного заполнения регистра НаборыЗначенийДоступа.'; 
					           |en = '""%1"" rights owner type
					           |is not specified in defined type ""Access value"" 
					           |but used to fill access value sets 
					           |as it is specified in one of subscriptions to the event:
					           |- WriteDependentAccessValuesSets*,
					           |- WriteAccessValuesSets*.
					           |Specify a type in defined type ""Access value"" 
					           |for correct filling of the AccessValuesSets register.'; 
					           |pl = 'W definiowanym typie 
					           |""Wartość dostępu"" nie określono typu
					           |%1 posiadacza praw jednak jest on używany
					           |do wypełnienia zestawów wartości dostępu, ponieważ został określony w jednej z
					           |subskrypcji
					           | zdarzeń: WriteDependentAccessValuesSet*, - WriteAccessValuesSets*.
					           |Dla prawidłowego wypełnienia rejestru AccessValuesSets należy określić typ w definiowanym typie
					           |""Wartość dostępu"".';
					           |de = 'Der Typ des 
					           |%1Rechteinhabers ist nicht im definierten Typ
					           |des Zugriffswerts  angegeben, sondern
					           |zum Füllen der Sätze von Zugriffswerten, wie in einer
					           |der Subskriptionen
					           |für das Ereignis angegeben: -  SchreibenSieAbhängigeZugriffswerte*, - SchreibenSieZugriffswertsätze *.
					           |Sie müssen den Typ des angegebenen
					           |Zugriffswerttyps angeben das korrekte Füllen des ZugriffAufWertesätze-Registers.';
					           |ro = 'Tipul titularului drepturilor ""%1""
					           |nu este indicat în tipul determinat ""Valoarea de acces"",
					           |însă se utilizează pentru completarea seturilor valorilor de acces,
					           |deoarece este indicat în una din subscrierile la evenimentul:
					           |- ЗаписатьЗависимыеНаборыЗначенийДоступа*,
					           |- ЗаписатьНаборыЗначенийДоступа*.
					           |Trebuie să indicați tipul în tipul determinat ""Valoarea de acces""
					           |pentru completarea corectă a registrului НаборыЗначенийДоступа.';
					           |tr = 'Hak  sahibinin 
					           | 
					           | türü, 
					           |Erişim değeri tanımlı türünde belirtilmemiş, 
					           |ancak  aboneliklerden birinde belirtilen erişim değer 
					           |kümelerini doldurmak için  kullanılır:
					           | - BağımlıErişimDeğerlerKümesiniYaz*, -ErişimDeğerleriKümesiYaz. 
					           |ErişimDeğeriKümeleri kaydının doğru doldurulması için belirtilen türdeki erişim değeri türünü %1 belirtmeniz gerekir.'; 
					           |es_ES = 'Tipo del
					           |%1 propietario de derechos no está especificado en
					           |el tipo definido de valores de Acceso, pero utilizado
					           |para rellenar los conjuntos de valores de acceso, como está especificado en una de
					           |las suscripciones
					           |al evento: - WriteDependentAccessValuesSet*, - WriteAccessValuesSets*.
					           |Usted necesita especificar el tipo en
					           |el tipo especificado de valores de Acceso para un relleno correcto del registro de AccessValuesSets.'"),
					String(RefType));
			EndIf;
			
			If AccessKindsProperties.ByValuesTypes.Get(RefType) <> Undefined Then
				Raise ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Тип владельца прав ""%1""
					           |не может использоваться, как тип значений доступа,
					           |но обнаружен в описании вида доступа ""%2"".'; 
					           |en = '""%1"" rights owner type
					           |cannot be used as an access value type
					           |but it is detected in description of access kind ""%2"".'; 
					           |pl = 'Typ posiadacza praw ""%1""
					           |nie może być używany, jako typ wartości dostępu,
					           |ale znajduje się w opisie typu dostępu ""%2""';
					           |de = 'Der Typ des Rechteinhabers ""%1""
					           |kann nicht als Wert für die Art des Zugriffs verwendet werden, er ist
					           |jedoch in der Beschreibung der Art des Zugriffs ""%2"" enthalten.';
					           |ro = 'Tipul titularului drepturilor ""%1""
					           |nu poate fi folosit ca tipul valorilor de acces,
					           |dar a fost depistat în descrierea tipului de acces ""%2"".';
					           |tr = 'Hak sahibinin türü, 
					           | %1 erişim değerlerinin türü olarak kullanılamaz, 
					           |ancak erişim türünün açıklamasında %2 bulunabilir.'; 
					           |es_ES = 'El tipo del propietario de derechos ""%1""
					           |no puede ser usado como el tipo de valores de acceso,
					           |pero se ha encontrado en la descripción del tipo de acceso ""%2"".'"),
					String(RefType),
					AccessKindsProperties.ByValuesTypes.Get(RefType).Name);
			EndIf;
			
			If AccessKindsProperties.ByGroupsAndValuesTypes.Get(RefType) <> Undefined Then
				Raise ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Тип владельца прав ""%1""
					           |не может использоваться, как тип групп значений доступа,
					           |но обнаружен в описании вида доступа ""%2"".'; 
					           |en = '""%1"" rights owner type
					           |cannot be used as a type of access value groups but 
					           |it is detected in description of access kind ""%2"".'; 
					           |pl = 'Typ posiadacza praw ""%1""
					           |nie może być używany, jako typ grup wartości dostępu,
					           |ale znajduje się w opisie typu dostępu ""%2""';
					           |de = 'Der Typ des Rechteinhabers ""%1""
					           |kann nicht als Typ von Zugriffswertegruppen verwendet werden,
					           |sondern ist in der Beschreibung der Zugriffsart ""%2"" zu finden.';
					           |ro = 'Tipul titularului drepturilor ""%1""
					           |nu poate fi folosit ca tipul grupurilor valorilor de acces,
					           |dar a fost depistat în descrierea tipului de acces ""%2"".';
					           |tr = 'Hak sahibinin türü, 
					           | %1 erişim değeri gruplarının türü olarak kullanılamaz, 
					           |ancak erişim türünün açıklamasında %2 bulunabilir.'; 
					           |es_ES = 'El tipo del propietario de derechos ""%1""
					           |no puede ser usado como el tipo de grupos de valores de acceso,
					           |pero se ha encontrado en el tipo de acceso ""%2"".'"),
					String(RefType),
					AccessKindsProperties.ByValuesTypes.Get(RefType).Name);
			EndIf;
			
			If SubscriptionTypesUpdateRightsSettingsOwnersGroups.Get(ObjectType) = Undefined Then
				Raise ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Тип владельца прав ""%1""
					           |не указан в определяемом типе ""Владелец настроек прав объект"".'; 
					           |en = '""%1"" rights owner type
					           |is not specified in defined type ""Owner of object rights settings"".'; 
					           |pl = 'Typ właściciela praw ""%1""
					           |nie jest określony w podym typie ""Właściciel ustawień praw obiekt"".';
					           |de = 'Der Typ des Eigentümers der Rechte ""%1""
					           |ist im bezeichneten Typ ""Eigentümer der Einstellungen der Rechte des Objekts"" nicht angegeben.';
					           |ro = 'Tipul titularului drepturilor ""%1""
					           |nu este specificat în tipul determinat ""Titularul setărilor drepturilor asupra obiectului"".';
					           |tr = 'Hak sahibinin türü"
" %1 ""Hak ayarları sahibi nesne"" tanımlanmış türünde belirtilmemiş.'; 
					           |es_ES = 'El tipo del propietario de derechos ""%1""
					           |no se ha indicado en el tipo ""Propietario de ajustes de derechos objeto"".'"),
					String(ObjectType));
			EndIf;
			
			ByFullNames.Insert(PossibleRight.RightsOwner, OwnerRights);
			ByRefsTypes.Insert(RefType,  OwnerRightsArray);
			ByTypes.Insert(RefType,  OwnerRights);
			ByTypes.Insert(ObjectType, OwnerRights);
			If HierarchicalMetadataObject(OwnerMetadataObject) Then
				HierarchicalTables.Insert(RefType,  True);
				HierarchicalTables.Insert(ObjectType, True);
			EndIf;
			
			OwnersTypes.Add(Common.ObjectManagerByFullName(
				PossibleRight.RightsOwner).EmptyRef());
				
			OwnersRightsIndexes.Insert(PossibleRight.RightsOwner, 0);
		EndIf;
		
		If OwnerRights.Get(PossibleRight.Name) <> Undefined Then
			Raise ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Для владельца прав ""%1""
				           |повторно определено право ""%2"".'; 
				           |en = 'The ""%2"" right 
				           |is defined again for the ""%1"" right owner.'; 
				           |pl = 'W przypadku właściciela praw ""%1""
				           |prawo to na nowo zdefiniowane ""%2"".';
				           |de = 'Für den Rechteinhaber ""%1""
				           |wird das Recht neu definiert ""%2"".';
				           |ro = 'Pentru titularul drepturilor ""%1""
				           | este determinat repetat dreptul ""%2"".';
				           |tr = 'Hak sahibi için %1
				           |hak yeniden %2 tanımlandı.'; 
				           |es_ES = 'Para el propietario de derechos ""%1""
				           |, el derecho ""%2"" está definido una vez más.'"),
				PossibleRight.RightsOwner,
				PossibleRight.Name);
		EndIf;
		
		// Converting the list of required rights to arrays.
		Separator = "|";
		For Index = 0 To PossibleRight.RequiredRights.Count()-1 Do
			If StrFind(PossibleRight.RequiredRights[Index], Separator) > 0 Then
				PossibleRight.RequiredRights[Index] = StrSplit(
					PossibleRight.RequiredRights[Index], Separator, False);
			EndIf;
		EndDo;
		
		PossibleRightProperties = New Structure(
			"RightsOwner,
			|Name,
			|Title,
			|ToolTip,
			|InitialValue,
			|RequiredRights,
			|ReadInTables,
			|ChangeInTables,
			|RightIndex");
		FillPropertyValues(PossibleRightProperties, PossibleRight);
		PossibleRightProperties.RightIndex = OwnersRightsIndexes[PossibleRight.RightsOwner];
		OwnersRightsIndexes[PossibleRight.RightsOwner] = PossibleRightProperties.RightIndex + 1;
		
		OwnerRights.Insert(PossibleRight.Name, PossibleRightProperties);
		OwnerRightsArray.Add(PossibleRightProperties);
	EndDo;
	
	// Adding individual tables.
	CommonTable = Catalogs.MetadataObjectIDs.EmptyRef();
	For each RightsDetails In ByFullNames Do
		SeparateRights = AdditionalParameters.IndividualOwnersRights.Get(RightsDetails.Key);
		For each RightDetails In RightsDetails.Value Do
			RightProperties = RightDetails.Value;
			If RightProperties.ChangeInTables.Find(CommonTable) <> Undefined Then
				For each KeyAndValue In SeparateTables Do
					SeparateTable = KeyAndValue.Key;
					
					If SeparateRights.ChangeInTables[SeparateTable] = Undefined
					   AND RightProperties.ChangeInTables.Find(SeparateTable) = Undefined Then
					
						RightProperties.ChangeInTables.Add(SeparateTable);
					EndIf;
				EndDo;
			EndIf;
		EndDo;
	EndDo;
	
	AvailableRights = New Structure;
	AvailableRights.Insert("ByTypes",                       ByTypes);
	AvailableRights.Insert("ByRefsTypes",                 ByRefsTypes);
	AvailableRights.Insert("ByFullNames",                ByFullNames);
	AvailableRights.Insert("OwnersTypes",                OwnersTypes);
	AvailableRights.Insert("SeparateTables",              SeparateTables);
	AvailableRights.Insert("HierarchicalTables",          HierarchicalTables);
	
	Return Common.FixedData(AvailableRights);
	
EndFunction

Procedure FillIDs(Property, PossibleRight, ErrorTitle, SeparateTables, AdditionalParameters)
	
	If AdditionalParameters.CommonOwnersRights.Get(AdditionalParameters.RightsOwner) = Undefined Then
		CommonRights     = New Structure("ReadInTables, ChangeInTables", "", "");
		SeparateRights = New Structure("ReadInTables, ChangeInTables", New Map, New Map);
		
		AdditionalParameters.CommonOwnersRights.Insert(AdditionalParameters.RightsOwner, CommonRights);
		AdditionalParameters.IndividualOwnersRights.Insert(AdditionalParameters.RightsOwner, SeparateRights);
	Else
		CommonRights     = AdditionalParameters.CommonOwnersRights.Get(AdditionalParameters.RightsOwner);
		SeparateRights = AdditionalParameters.IndividualOwnersRights.Get(AdditionalParameters.RightsOwner);
	EndIf;
	
	Array = New Array;
	
	For each Value In PossibleRight[Property] Do
		
		If Value = "*" Then
			If PossibleRight[Property].Count() <> 1 Then
				
				If Property = "ReadInTables" Then
					ErrorDescription =
						NStr("ru = 'Для владельца прав ""%1""
						           |для права ""%2"" в таблицах для чтения указан символ ""*"".
						           |В этом случае отдельных таблиц указывать не нужно.'; 
						           |en = 'An asterisk (""*"") is specified for the ""%1""
						           |right owner for the ""%2"" right in tables for reading.
						           |In this case, do not specify separate tables.'; 
						           |pl = 'Dla właściciela praw ""%1""
						           |dla prawa ""%2"" w tabelach do czytania wyświetlany jest symbol ""*"".
						           |W tym przypadku nie trzeba podawać poszczególnych tabel.';
						           |de = 'Für den Inhaber der Rechte ""%1""
						           |für das Recht ""%2"" in den Tabellen zum Lesen ist das Symbol ""*"" angegeben.
						           |In diesem Fall ist es nicht erforderlich, einzelne Tabellen anzugeben.';
						           |ro = 'Pentru titularul drepturilor ""%1""
						           |pentru dreptul ""%2"" în tabele pentru citire este indicat caracterul ""*"".
						           |În acest caz nu trebuie să indicați tabele separate.';
						           |tr = 'Okuma için tablolarda hak sahibi için ""*"" 
						           |karakteri belirtilmiştir. %1Bu durumda %2 ayrı tablolar 
						           |belirtilmemelidir.'; 
						           |es_ES = 'Para el propietario de derechos ""%1""
						           |para el derecho ""%2"" en las tablas para leer está indicado el símbolo ""*"".
						           |En este caso no hay que indicar tablas separadas.'")
				Else
					ErrorDescription =
						NStr("ru = 'Для владельца прав ""%1""
						           |для права ""%2"" в таблицах для изменения указан символ ""*"".
						           |В этом случае отдельных таблиц указывать не нужно.'; 
						           |en = 'An asterisk (""*"") is specified
						           |for the ""%1"" right owner for the ""%2"" right in tables for change.
						           |In this case, do not specify separate tables.'; 
						           |pl = 'Dla właściciela praw ""%1""
						           |dla prawa ""%2"" w tabelach do zmiany wyświetlany jest symbol ""*"".
						           |W tym przypadku nie trzeba podawać poszczególnych tabel.';
						           |de = 'Für den Inhaber der Rechte ""%1""
						           |für das Recht ""%2"" in den Tabellen zur Änderung ist das Symbol ""*"" angegeben.
						           |In diesem Fall ist es nicht erforderlich, einzelne Tabellen anzugeben.';
						           |ro = 'Pentru titularul drepturilor ""%1""
						           |pentru dreptul ""%2"" în tabele pentru modificare este indicat caracterul ""*"".
						           |În acest caz nu trebuie să indicați tabele separate.';
						           |tr = 'Değişen tablolarda %1 hak sahibi için ""*""
						           |karakteri belirtilmiştir %2 Bu durumda ayrı tablolar belirtilmemelidir
						           |'; 
						           |es_ES = 'Para el propietario de derechos ""%1""
						           |para el derecho ""%2"" en las tablas para cambiar está indicado el símbolo ""*"".
						           |En este caso no hay que indicar tablas separadas.'")
				EndIf;
				
				Raise ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
					ErrorDescription, AdditionalParameters.RightsOwner, PossibleRight.Name);
			EndIf;
			
			If ValueIsFilled(CommonRights[Property]) Then
				
				If Property = "ReadInTables" Then
					ErrorDescription =
						NStr("ru = 'Для владельца прав ""%1""
						           |для права ""%2"" в таблицах для чтения указан символ ""*"".
						           |Однако символ ""*"" уже указан в таблицах для чтения для права ""%3"".'; 
						           |en = 'An asterisk (""*"") is specified 
						           |for the ""%1"" right owner for the ""%2"" right in tables for reading.
						           |The asterisk is already specified in tables for reading for the ""%3"" right.'; 
						           |pl = 'Dla właściciela praw ""%1""
						           |dla prawa ""%2"" w tabelach do czytania wyświetlany jest symbol ""*"".
						           |W tym przypadku nie trzeba podawać w tabelach do czytania dla prawa ""%3"".';
						           |de = 'Für den Inhaber der Rechte ""%1""
						           |für das Recht """"""%2 in den Tabellen zum Lesen ist das Symbol ""*"" angegeben.
						           |Das Symbol ""*"" ist jedoch bereits in den Tabellen zum Lesen für das Recht ""%3"" angegeben.';
						           |ro = 'Pentru titularul drepturilor ""%1""
						           |pentru dreptul ""%2"" în tabele pentru citire este indicat caracterul ""*"".
						           |Însă caracterul ""*"" deja este indicat în tabele pentru citire pentru dreptul ""%3"".';
						           |tr = 'Okuma için tablolarda hak sahibi için ""*"" 
						           |karakteri belirtilmiştir. %1Ancak, * karakteri, %2 hakkı için okuma tablolarında 
						           |zaten belirtilmiştir.%3'; 
						           |es_ES = 'Para el propietario de derechos ""%1""
						           |para el derecho ""%2"" en las tablas para leer está indicado el símbolo ""*"".
						           |Pero el símbolo ""*"" ya se ha indicado en las tablas para leer para el derecho ""%3"".'")
				Else
					ErrorDescription =
						NStr("ru = 'Для владельца прав ""%1""
						           |для права ""%2"" в таблицах для изменения указан символ ""*"".
						           |Однако символ ""*"" уже указан в таблицах для изменения для права ""%3"".'; 
						           |en = 'An asterisk (""*"") is specified 
						           |for the ""%1"" right owner for the ""%2"" right in tables for change.
						           |The asterisk is already specified in tables for changes for the ""%3"" right.'; 
						           |pl = 'Dla właściciela praw ""%1""
						           |dla prawa ""%2"" w tabelach do zmian wyświetlany jest symbol ""*"".
						           |W tym przypadku nie trzeba podawać w tabelach do zmian dla prawa ""%3"".';
						           |de = 'Für den Inhaber der Rechte ""%1""
						           |für das Recht """"""%2 in den Tabellen zur Änderung ist das Symbol ""*"" angegeben.
						           |Das Symbol ""*"" ist jedoch bereits in den Tabellen zur Änderung für das Recht ""%3"" angegeben.';
						           |ro = 'Pentru titularul drepturilor ""%1""
						           |pentru dreptul ""%2"" în tabele pentru modificare este indicat caracterul ""*"".
						           |Însă caracterul ""*"" deja este indicat în tabele pentru modificare pentru dreptul ""%3"".';
						           |tr = 'Değişen tablolarda hak sahibi için ""*"" 
						           |karakteri belirtilmiştir. %1Ancak, ""*"" karakteri %2 sağa doğru değiştirmek 
						           |için tablolarda zaten belirtilmiştir.%3'; 
						           |es_ES = 'Para el propietario de derechos ""%1""
						           |para el derecho ""%2"" en las tablas para cambiar está indicado el símbolo ""*"".
						           |Pero el símbolo ""*"" ya se ha indicado en las tablas para cambiar para el derecho ""%3"".'")
				EndIf;
				
				Raise ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(ErrorDescription,
					AdditionalParameters.RightsOwner, PossibleRight.Name, CommonRights[Property]);
			Else
				CommonRights[Property] = PossibleRight.Name;
			EndIf;
			
			Array.Add(Catalogs.MetadataObjectIDs.EmptyRef());
			
		ElsIf Property = "ReadInTables" Then
			ErrorDescription =
				NStr("ru = 'Для владельца прав ""%1""
				           |для права ""%2"" указана конкретная таблица для чтения ""%3"".
				           |Однако это не имеет смысла, т.к. право Чтение может зависеть только от права Чтение.
				           |Имеет смысл использовать только символ ""*"".'; 
				           |en = 'Specific table ""%3""
				           |for reading is specified for the ""%1"" right owner for the ""%2"" right.
				           |It does not make sense, as the Read right depends only on the Read right.
				           |Only using an asterisk (""*"") makes sense.'; 
				           |pl = 'Dla posiadacza praw %1
				           | dla prawa %2 określono konkretną tablicę do odczytu %3. 
				           |Jednakże nie ma to sensu, ponieważ prawo Odczyt może zależeć wyłącznie od prawa Odczyt
				           |. Ma sens używanie tylko znaku *.';
				           |de = 'Für den %1
				           |Rechteinhaber für %2Recht wird die angegebene Tabelle zum Lesen %3 angegeben.
				           |Es macht jedoch keinen Sinn, da das Leserecht nur vom Leserecht
				           |abhängen kann. Es ist sinnvoll, nur das Zeichen ""*"" zu verwenden.';
				           |ro = 'Pentru titularul drepturilor ""%1""
				           |pentru dreptul ""%2"" este specificat tabelul concret pentru citirea ""%3"".
				           |Însă, aceasta nu are sens, deoarece dreptul de Citire poate depinde doar de dreptul de Citire.
				           |Este logic să folosiți doar caracterul ""*"".';
				           |tr = 'Hak sahibinin %1 hak sahibi için, belirtilen okuma tablosu belirtilir.
				           | Bununla  birlikte,%2 Okuma Hakkı sadece%3 Okuma hakkına bağlı olabileceğinden hiçbir  anlam ifade etmez.
				           | Sadece
				           | * karakterini kullanmak mantıklıdır.'; 
				           |es_ES = 'Para el propietario de derechos %1
				           | para el derecho %2, la tabla especificada para lectura %3 está especificada.
				           |Sin embargo, no tiene sentido como el derecho de Lectura puede depender solo del derecho de Lectura
				           |Tiene sentido utilizar solo el símbolo *.'");
				
			Raise ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(ErrorDescription,
				AdditionalParameters.RightsOwner, PossibleRight.Name, Value);
			
		ElsIf Metadata.FindByFullName(Value) = Undefined Then
			
			If Property = "ReadInTables" Then
				ErrorDescription = NStr("ru = 'Для владельца прав ""%1""
				                            |для права ""%2"" не найдена таблица для чтения ""%3"".'; 
				                            |en = 'Table for reading ""%3""
				                            |is not found for the ""%1"" right owner for the ""%2"" right.'; 
				                            |pl = 'Dla właściciela praw ""%1""
				                            |dla prawa ""%2"" tabela do czytania nie została znaleziona ""%3"".';
				                            |de = 'Für den Rechteinhaber ""%1""
				                            |für das Recht ""%2"" wurde die Tabelle zum Lesen ""%3"" nicht gefunden.';
				                            |ro = 'Pentru titularul drepturilor ""%1""
				                            |pentru dreptul ""%2"" nu a fost găsit tabelul pentru citirea ""%3"".';
				                            |tr = '%1
				                            |Hak sahibi için %2 hak için okuma tablosu %3 bulunamadı.'; 
				                            |es_ES = 'Para el propietario de derechos ""%1""
				                            |para el derecho ""%2"", la tabla de leer ""%3"" no se ha encontrado.'")
			Else
				ErrorDescription = NStr("ru = 'Для владельца прав ""%1""
				                            |для права ""%2"" не найдена таблица для изменения ""%3"".'; 
				                            |en = 'Table for change ""%3""
				                            |is not found for the ""%1"" right owner for the ""%2"" right.'; 
				                            |pl = 'Dla właściciela praw ""%1""
				                            |dla prawa ""%2"" tabela do zmian nie została znaleziona %3"".';
				                            |de = 'Für den Rechteinhaber ""%1""
				                            |für das Recht ""%2"" wurde die Tabelle zum Ändern von ""%3"" nicht gefunden.';
				                            |ro = 'Pentru titularul drepturilor ""%1""
				                            |pentru dreptul ""%2"" nu a fost găsit tabelul pentru modificarea ""%3"".';
				                            |tr = '%1
				                            |Hak sahibi için %2 hak için değişiklik tablosu %3 bulunamadı.'; 
				                            |es_ES = 'Para el propietario de derechos ""%1""
				                            |para el derecho ""%2"", la tabla de cambiar ""%3"" no se ha encontrado.'")
			EndIf;
			
			Raise ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(ErrorDescription,
				AdditionalParameters.RightsOwner, PossibleRight.Name, Value);
		Else
			TableID = Common.MetadataObjectID(Value);
			Array.Add(TableID);
			
			SeparateTables.Insert(TableID, Value);
			SeparateRights[Property].Insert(TableID, PossibleRight.Name);
		EndIf;
		
	EndDo;
	
	PossibleRight[Property] = Array;
	
EndProcedure

Function HierarchicalMetadataObject(MetadataObjectDetails)
	
	If TypeOf(MetadataObjectDetails) = Type("String") Then
		MetadataObject = Metadata.FindByFullName(MetadataObjectDetails);
	ElsIf TypeOf(MetadataObjectDetails) = Type("Type") Then
		MetadataObject = Metadata.FindByType(MetadataObjectDetails);
	Else
		MetadataObject = MetadataObjectDetails;
	EndIf;
	
	If TypeOf(MetadataObject) <> Type("MetadataObject") Then
		Return False;
	EndIf;
	
	If NOT Metadata.Catalogs.Contains(MetadataObject)
	   AND NOT Metadata.ChartsOfCharacteristicTypes.Contains(MetadataObject) Then
		
		Return False;
	EndIf;
	
	Return MetadataObject.Hierarchical;
	
EndFunction

#EndRegion

#EndIf
