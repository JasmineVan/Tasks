///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region ForCallsFromOtherSubsystems

// SaaSTechnology.ExportImportData

// Returns the catalog attributes that naturally form a catalog item key.
//
// Returns:
//  Array (String) - an array of attribute names that form a natural key.
//
Function NaturalKeyFields() Export
	
	Result = New Array;
	Result.Add("Description");
	
	Return Result;
	
EndFunction

// End SaaSTechnology.ExportImportData

#EndRegion

#EndRegion

#Region Private

Function ClosingDatesSectionsProperties() Export
	
	Sections = New ValueTable;
	Sections.Columns.Add("Name",           New TypeDescription("String",,,, New StringQualifiers(150)));
	Sections.Columns.Add("ID", New TypeDescription("UUID"));
	Sections.Columns.Add("Presentation", New TypeDescription("String"));
	Sections.Columns.Add("ObjectsTypes",  New TypeDescription("Array"));
	
	SSLSubsystemsIntegration.OnFillPeriodClosingDatesSections(Sections);
	PeriodClosingDatesOverridable.OnFillPeriodClosingDatesSections(Sections);
	
	ErrorTitle =
		NStr("ru = 'Ошибка в процедуре ПриЗаполненииРазделовДатЗапретаИзменения
		           |общего модуля ДатыЗапретаИзмененияПереопределяемый.'; 
		           |en = 'Error occurred in OnFillPeriodClosingDatesSections procedure,
		           |PeriodClosingDatesOverridable common module.'; 
		           |pl = 'Błąd w procedurze PpdczasWypełnianiaRozdziałówDatZakazuZmian
		           |wspólnego modułu DatyZakazuZmianPredefiniowany.';
		           |de = 'Fehler in der Prozedur BeimAusfüllenDerBereicheVerbotsdatumÄnderung
		           |des allgemeinen Moduls von VerbotsdatumÄnderungNeudefinierbar.';
		           |ro = 'Eroare în procedura ПриЗаполненииРазделовДатЗапретаИзменения
		           |a modulului comun ПриЗаполненииРазделовДатЗапретаИзменения.';
		           |tr = 'Prosedür hatası Genel modülün
		           |OnFillPeriodClosingDatesSections PeriodClosingDatesOverridable .'; 
		           |es_ES = 'Error en el procedimiento OnFillPeriodClosingDatesSections
		           |del módulo común PeriodClosingDatesOverridable.'")
		+ Chars.LF
		+ Chars.LF;
	
	ClosingDatesSections     = New Map;
	SectionsWithoutObjects    = New Array;
	AllSectionsWithoutObjects = True;
	
	ClosingDatesObjectsTypes = New Map;
	Types = Metadata.ChartsOfCharacteristicTypes.PeriodClosingDatesSections.Type.Types();
	For Each Type In Types Do
		If Type = Type("EnumRef.PeriodClosingDatesPurposeTypes")
		 Or Type = Type("ChartOfCharacteristicTypesRef.PeriodClosingDatesSections")
		 Or Not Common.IsReference(Type) Then
			Continue;
		EndIf;
		ClosingDatesObjectsTypes.Insert(Type, True);
	EndDo;
	
	For Each Section In Sections Do
		If Not ValueIsFilled(Section.Name) Then
			Raise ErrorTitle + NStr("ru = 'Имя раздела дат запрета не заполнено.'; en = 'Name is required for the period-end closing date section.'; pl = 'Nie wypełniono rozdziału dat zakazu.';de = 'Der Name des Verbotsdatumsbereichs wird nicht ausgefüllt.';ro = 'Numele compartimentului datelor de interdicție nu este completat.';tr = 'Yasak tarihleri bölüm adı doldurulmadı.'; es_ES = 'El nombre de la división de las fechas de restricción no está rellenado.'");
		EndIf;
		
		If ClosingDatesSections.Get(Section.Name) <> Undefined Then
			Raise ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Имя раздела дат запрета ""%1"" уже определено.'; en = '""%1"" period-end closing date section already has a name.'; pl = 'Nazwa rozdziału dat zakazu ""%1"" jest już określona.';de = 'Der Name des Verbotsdatums ""%1"" wurde bereits definiert.';ro = 'Numele compartimentului datelor de interdicție ""%1"" deja este definit.';tr = '""%1"" yasak tarihi bölümünün adı zaten belirlenmiştir.'; es_ES = 'El nombre de la división de las fechas de restricción ""%1"" está predeterminado.'"),
				Section.Name);
		EndIf;
		
		If Not ValueIsFilled(Section.ID) AND Section.Name <> "SingleDate" Then
			Raise ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Идентификатор раздела дат запрета ""%1"" не заполнен.'; en = 'ID is required for ""%1"" period-end closing date section.'; pl = 'Nie wypełniono rozdziału dat zakazu ""%1"".';de = 'Die Verbotsdatumskennung ""%1"" wird nicht ausgefüllt.';ro = 'Identificatorul compartimentului datelor de interdicție ""%1"" nu este completat.';tr = '""%1"" yasak tarihi bölümünün tanımlayıcısı doldurulmadı.'; es_ES = 'El identificador de la división de las fechas de restricción ""%1"" no está rellenado.'"),
				Section.Name);
		EndIf;
		
		SectionRef = GetRef(Section.ID);
		
		If ClosingDatesSections.Get(SectionRef) <> Undefined Then
			Raise ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Идентификатор ""%1"" раздела дат запрета
				           |""%2"" уже используется для раздела ""%3"".'; 
				           |en = 'ID ""%1"" of ""%2"" period-end closing date section
				           |has already been assigned to ""%3"" section.'; 
				           |pl = 'Identyfikator ""%1"" rozdziału dat zakazu
				           |""%2"" jest już używana do rozdziału ""%3"".';
				           |de = 'Die Kennung ""%1"" des Verbotsdatumsabschnitts
				           |""%2"" wird bereits für den Abschnitt ""%3"" verwendet.';
				           |ro = 'Identificatorul ""%1"" compartimentului datelor de interdicție
				           |""%2"" deja se utilizează pentru compartimentul ""%3"".';
				           |tr = '""%1"" yasağı tarihi bölümünün "
" tanımlayıcısı zaten ""%2"" bölümü için %3kullanılmaktadır.'; 
				           |es_ES = 'El identificador ""%1"" de la división de las fechas de restricción
				           |""%2"" ya se usa para dividir ""%3"".'"),
				Section.ID, Section.Name, ClosingDatesSections.Get(SectionRef).Name);
		EndIf;
		
		ObjectsTypes = New Array;
		For Each Type In Section.ObjectsTypes Do
			AllSectionsWithoutObjects = False;
			If Not Common.IsReference(Type) Then
				Raise ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Тип ""%1"" указан, как тип объектов для раздела дат запрета ""%2"".
					           |Однако это не тип ссылки.'; 
					           |en = 'Object type for ""%2"" period-end closing date section is defined as ""%1"". 
					           |But it is not a reference type.'; 
					           |pl = 'Typ ""%1"" został określony jako typ obiektów dla rozdziału dat zakazu ""%2"".
					           |Jednak nie jest to typ linku.';
					           |de = 'Als Objekttyp für den Abschnitt ""%1"" für das Verbotsdatum wird der Typ ""%2"" angegeben.
					           |Dies ist jedoch keine Referenzart.';
					           |ro = 'Tipul ""%1"" este indicat ca tip al obiectelor pentru compartimentul datelor de interdicție ""%2"".
					           |Însă acesta nu este tip de referință.';
					           |tr = '""%1"" türü, ""%2"" yasak tarihleri bölümü için nesne türü olarak belirlendi.  
					           |Ancak bu referans türü değil.'; 
					           |es_ES = 'El tipo ""%1"" está indicado como el tipo de objetos para dividir las fechas de restricción ""%2"".
					           |Pero no es el tipo de referencia.'"),
					String(Type), Section.Name);
			EndIf;
			If ClosingDatesObjectsTypes.Get(Type) = Undefined Then
				Raise ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Тип объектов ""%1"" раздела дат запрета ""%2""
					           |не указан в свойстве ""Тип"" плана видов характеристик ""Разделы дат запрета изменения"".'; 
					           |en = 'Property ""Type"" in chart of characteristic types ""Period-end closing dates sections""
					           |requires ""%1"" object type of ""%2"" period-end closing dates section.'; 
					           |pl = 'Typ obiektów ""%1"" rozdziału dat zakazu ""%2""
					           | nie został określony we właściwości ""Typ"" planu rodzajów charakterystyk ""Rozdziały dat zakazu zmian"".';
					           |de = 'Der Objekttyp ""%1"" des Verbotsdatumsabschnitts ""%2""
					           |ist in der Eigenschaft ""Typ"" vom Merkmalsplan ""Verbotsdatumsabschnitte ändern"" nicht angegeben.';
					           |ro = 'Tipul obiectelor ""%1"" compartimentului datelor de interdicție ""%2""
					           |nu este indicat în proprietatea ""Tipul"" a planului tipurilor caracteristicilor ""Compartimentele datelor de interdicție a modificării"".';
					           |tr = '""%1"" yasak tarihleri ""%2"" bölümünün nesne türü 
					           | ""Değişiklik yasağı tarihlerinin bölümleri"" özellik türleri planının ""Tür"" özelliğinde belirtilmedi.'; 
					           |es_ES = 'El tipo de los objetos ""%1"" de la división de las fechas de restricción ""%2""
					           |no está indicado en la propiedad ""Tipo"" del plan de los tipos de características ""Divisiones de las fechas de restricción del cambio"".'"),
					String(Type), Section.Name);
			EndIf;
			TypeMetadata = Metadata.FindByType(Type);
			FullName = TypeMetadata.FullName();
			ObjectManager = Common.ObjectManagerByFullName(FullName);
			TypeProperties = New Structure;
			TypeProperties.Insert("EmptyRef",  ObjectManager.EmptyRef());
			TypeProperties.Insert("FullName",     FullName);
			TypeProperties.Insert("Presentation", String(Type));
			ObjectsTypes.Add(New FixedStructure(TypeProperties));
		EndDo;
		
		SectionProperties = New Structure;
		SectionProperties.Insert("Name",           Section.Name);
		SectionProperties.Insert("Ref",        SectionRef);
		SectionProperties.Insert("Presentation", Section.Presentation);
		SectionProperties.Insert("ObjectsTypes",  New FixedArray(ObjectsTypes));
		SectionProperties = New FixedStructure(SectionProperties);
		ClosingDatesSections.Insert(SectionProperties.Name,    SectionProperties);
		ClosingDatesSections.Insert(SectionProperties.Ref, SectionProperties);
		
		If ObjectsTypes.Count() = 0 Then
			SectionsWithoutObjects.Add(Section.Name);
		EndIf;
	EndDo;
	
	// Adding a blank section (a single date).
	SectionProperties = New Structure;
	SectionProperties.Insert("Name", "");
	SectionProperties.Insert("Ref", EmptyRef());
	SectionProperties.Insert("Presentation", NStr("ru = 'Общая дата'; en = 'Single date'; pl = 'Wspólna data';de = 'Gemeinsame Datum';ro = 'Data comună';tr = 'Ortak tarih'; es_ES = 'Fecha común'"));
	SectionProperties.Insert("ObjectsTypes",  New FixedArray(New Array));
	SectionProperties = New FixedStructure(SectionProperties);
	ClosingDatesSections.Insert(SectionProperties.Name,    SectionProperties);
	ClosingDatesSections.Insert(SectionProperties.Ref, SectionProperties);
	
	Properties = New Structure;
	Properties.Insert("Sections",               New FixedMap(ClosingDatesSections));
	Properties.Insert("SectionsWithoutObjects",    New FixedArray(SectionsWithoutObjects));
	Properties.Insert("AllSectionsWithoutObjects", AllSectionsWithoutObjects);
	Properties.Insert("NoSectionsAndObjects",  Sections.Count() = 0);
	Properties.Insert("SingleSection",    ?(Sections.Count() = 1,
	                                             ClosingDatesSections[Sections[0].Name].Ref,
	                                             EmptyRef()));
	Properties.Insert("ShowSections",     Properties.AllSectionsWithoutObjects
	                                           Or Not ValueIsFilled(Properties.SingleSection));
	
	Return New FixedStructure(Properties);
	
EndFunction

#EndRegion

#EndIf