
#Region StandardProceduresAndFunctions

// Обработчик перед записью
//
Procedure BeforeWrite(Cancel, Replacement)
	
	If Cancel Then
		Return;
	EndIf;
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	ComplexExtDimensionTypes = New Map;
	For Each Entry In ThisObject Do
		// Приведение пустых значений субконто составного типа.
		For Each ExtDimension In Entry.ExtDimensionsDr Do
			Complex = ComplexExtDimensionTypes.Get(ExtDimension.Key);          //
			If Complex=Undefined Then                                   //  
				Complex = ExtDimension.Key.ValueType.Types().Count() > 1;  // Кэширование: вид субконто + признак Составной
				ComplexExtDimensionTypes.Insert(ExtDimension.Key,Complex);        //
			EndIf;                                                          //
			If Complex
				AND NOT ValueIsFilled(ExtDimension.Value) 
				AND NOT (ExtDimension.Value = Undefined) Then
				Entry.ExtDimensionDr.Insert(ExtDimension.Key, Undefined);
			EndIf;
		EndDo;
		
		For Each ExtDimension In Entry.ExtDimensionsCr Do
			Complex = ComplexExtDimensionTypes.Get(ExtDimension.Key);          //
			If Complex=Undefined Then                                   //  
				Complex = ExtDimension.Key.ValueType.Types().Count() > 1;  // Кэширование: вид субконто + признак Составной
				ComplexExtDimensionTypes.Insert(ExtDimension.Key,Complex);        //
			EndIf;                                                          //
			If Complex
				AND NOT ValueIsFilled(ExtDimension.Value) 
				AND NOT (ExtDimension.Value = Undefined) Then
				Entry.ExtDimensionCr.Insert(ExtDimension.Key, Undefined);
			EndIf;
		EndDo;
		
	EndDo;

EndProcedure

#EndRegion
