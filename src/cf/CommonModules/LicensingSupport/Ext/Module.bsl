

// Эта Function возвращает список защищенных решений, которые были объединены в одну конфигурацию.
// Список состоит In имени защищенной DataProcessors и имени конфигурации, For которой она предназначена.
// Name конфигурации используется For показа информации о лицензировании.
// Name DataProcessors состоит In трех частей, разделенных точкой.
// XXX.YYY.ZZZ где:
// XXX - Name общего макета, в котором храниться DataProcessor
// YYY - Name общего макета, в котором хранятся параметры лицензирования
// ZZZ - собственно Name защищенной DataProcessors
// Количество объединенных решений не ограничено.

Function GetProductList() Export
	List = New Map;
	
	DataProcessorName = "ProtectedDataProcessorStorage.LicensingParameters.ProtectedDataProcessor";
	ProductName = NStr("ru = '1С-Рарус: Финансовый менеджмент 3'; en = '1C-Rarus: Financial Management 3'");
	List.Insert(DataProcessorName, ProductName);
	
	Return List;
EndFunction
