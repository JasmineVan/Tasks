
#If Server OR ThickClientOrdinaryApplication OR ExternalConnection Then

Procedure Posting(Cancel, PostingMode)
	
	RegisterManager = RegisterRecords.fmItemsDependencies;
	RegisterManager.Write = True;
	For Each TSRow In DependentItems Do
		
		RegisterRecord = RegisterManager.Add();
		
		// Измерения
		RegisterRecord.Item = Item;
		RegisterRecord.Scenario = Scenario;
		RegisterRecord.Department = Department;
		RegisterRecord.BalanceUnit = BalanceUnit;
		RegisterRecord.OperationType = OperationType;
		RegisterRecord.Analytics1 = Analytics1;
		RegisterRecord.Analytics2 = Analytics2;
		RegisterRecord.Analytics3 = Analytics3;
		RegisterRecord.DependentItem = TSRow.Item;
		RegisterRecord.DependentAnalytics1 = TSRow.Analytics1;
		RegisterRecord.DependentAnalytics2 = TSRow.Analytics2;
		RegisterRecord.DependentAnalytics3 = TSRow.Analytics3;
		RegisterRecord.DependentAnalyticsFillingVariant1 = TSRow.DependentAnalyticsFillingVariant1;
		RegisterRecord.DependentAnalyticsFillingVariant2 = TSRow.DependentAnalyticsFillingVariant2;
		RegisterRecord.DependentAnalyticsFillingVariant3 = TSRow.DependentAnalyticsFillingVariant3;
		RegisterRecord.RecordType = TSRow.MovementOperationType;
		// Ресурсы
		RegisterRecord.Percent = TSRow.Percent;
		RegisterRecord.AlloctionByPeriodsProfile = TSRow.AlloctionByPeriodsProfile;
		
	EndDo;
	
EndProcedure

Procedure Filling(FillingData, FillingText, StandardProcessing)
	// en script begin
	//ЗаполнениеДокументов.Заполнить(ЭтотОбъект, ДанныеЗаполнения);
	// en script end
EndProcedure

#EndIf
