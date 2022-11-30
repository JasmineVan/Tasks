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
	
	SetUpDynamicList();
	SetConditionalAppearance();
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	List.ConditionalAppearance.Items.Clear();
	List.Group.Items.Clear();
	
	Item = List.ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FileOwner");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Parameters.FilesOwner;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("IsFolder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Visible", False);
	Item.Appearance.SetParameterValue("Show", False);
	
	GroupingItem = List.Group.Items.Add(Type("DataCompositionGroupField"));
	GroupingItem.Use = True;
	GroupingItem.Field = New DataCompositionField("FileOwner");
	
EndProcedure

&AtServer
Procedure SetUpDynamicList()
	
	FilesOwner = Parameters.FilesOwner;
	
	ErrorTitle = NStr("ru = 'Ошибка при настройке динамического списка присоединенных файлов.'; en = 'An error occurred when configuring the dynamic list of attached files.'; pl = 'Wystąpił błąd podczas konfigurowania dynamicznej listy załączonych plików.';de = 'Bei der Konfiguration der dynamischen Liste der angehängten Dateien ist ein Fehler aufgetreten.';ro = 'Eroare la configurarea listei dinamice a fișierelor atașate.';tr = 'Ekli dosyaların dinamik listesini yapılandırırken bir hata oluştu.'; es_ES = 'Ha ocurrido un error al configurar la lista dinámica de los archivos adjuntados.'");
	ErrorEnd = NStr("ru = 'В этом случае настройка динамического списка невозможна.'; en = 'Cannot configure the dynamic list.'; pl = 'W tym przypadku konfiguracja listy dynamicznej nie jest obsługiwana.';de = 'In diesem Fall wird die dynamische Listenkonfiguration nicht unterstützt.';ro = 'În acest caz, configurarea listei dinamice este imposibilă.';tr = 'Bu durumda, dinamik liste yapılandırılamaz.'; es_ES = 'En el caso la configuración de la lista dinámica no se admite.'");
	FilesStorageCatalogName = FilesOperationsInternal.FileStoringCatalogName(
		FilesOwner, "", ErrorTitle, ErrorEnd);
	
	FileCatalogType = Type("CatalogRef." + FilesStorageCatalogName);
	MetadataOfCatalogWithFiles = Metadata.FindByType(FileCatalogType);
	CanCreateFileGroups = MetadataOfCatalogWithFiles.Hierarchical;
	
	ListProperties = Common.DynamicListPropertiesStructure();
	
	QueryText = 
	"SELECT
	|	Files.Ref AS Ref,
	|	Files.DeletionMark AS DeletionMark,
	|	CASE
	|		WHEN Files.DeletionMark = TRUE
	|			THEN ISNULL(Files.PictureIndex, 2) + 1
	|		ELSE ISNULL(Files.PictureIndex, 2)
	|	END AS PictureIndex,
	|	Files.Description AS Description,
	|	&IsFolder AS IsFolder,
	|	Files.FileOwner AS FileOwner
	|FROM
	|	&CatalogName AS Files
	|WHERE
	|	Files.FileOwner = &FilesOwner
	|	AND &FilterGroups";
	
	FullCatalogName = "Catalog." + FilesStorageCatalogName;
	QueryText = StrReplace(QueryText, "&CatalogName", FullCatalogName);
	QueryText = StrReplace(QueryText, "&FilterGroups", "Files.IsFolder");
	ListProperties.QueryText = StrReplace(QueryText, "&IsFolder",
		?(CanCreateFileGroups, "Files.IsFolder", "FALSE"));
		
	ListProperties.MainTable  = FullCatalogName;
	ListProperties.DynamicDataRead = True;
	Common.SetDynamicListProperties(Items.List, ListProperties);
	List.Parameters.SetParameterValue("FilesOwner", FilesOwner);
	
EndProcedure

&AtClient
Procedure ListValueChoice(Item, Value, StandardProcessing)
	MoveFilesToGroup(Parameters.FilesToMove, Value);
	NotifyChanged(TypeOf(Parameters.FilesToMove[0]));
	Notify("Write_File", New Structure, Parameters.FilesToMove);
	Close();
EndProcedure

&AtServerNoContext
Procedure MoveFilesToGroup(Val Files, Val Folder)
	BeginTransaction();
	Try
		For Each FileRef In Files Do
			FileObject = FileRef.GetObject();
			FileObject.Parent = Folder;
			FileObject.Write();
		EndDo;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
EndProcedure

&AtClient
Procedure CreateGroup(Command)
	Parent = Undefined;
	
	CurrentData = Items.List.CurrentData;
	If CurrentData <> Undefined Then
		Parent = CurrentData.Ref;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Parent",       Parent);
	FormParameters.Insert("FileOwner",  FilesOwner);
	FormParameters.Insert("IsNewGroup", True);
	FormParameters.Insert("FilesStorageCatalogName", FilesStorageCatalogName);
	
	OpenForm("DataProcessor.FilesOperations.Form.GroupOfFiles", FormParameters, ThisObject);
EndProcedure

#EndRegion
