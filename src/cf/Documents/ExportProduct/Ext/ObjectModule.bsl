
Procedure Posting(Cancel, Mode)
	//{{__REGISTER_REGISTERRECORDS_WIZARD
	// This fragment was built by the wizard.
	// Warning! All manually made changes will be lost next time you use the wizard.

	// register BalanceOfProducts Expense
	RegisterRecords.BalanceOfProducts.Write = True;
	For Each CurRowListProduct In ListProduct Do
		Record = RegisterRecords.BalanceOfProducts.Add();
		Record.RecordType = AccumulationRecordType.Expense;
		Record.Period = Date;
		Record.Product = CurRowListProduct.Product;
		Record.Warehouse = Warehouse;
		Record.Quantity = CurRowListProduct.Quantity;
	EndDo;

	//}}__REGISTER_REGISTERRECORDS_WIZARD
EndProcedure
