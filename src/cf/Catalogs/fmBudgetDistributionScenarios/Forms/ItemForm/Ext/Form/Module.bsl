
#Region FormEventsHandler

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	// проверка на копирование.
	CopyingValue = Parameters.CopyingValue;
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, RecordParameters)

	// обработка в случае копирования
	If ValueIsFilled(CopyingValue) Then
		
		Child = Catalogs.fmBudgetDistributionSteps.SELECT(, CopyingValue);
		ProcessedBlocks = New Map;	// Ключ - старый блок, значение - новый созданный блок.
		BeginTransaction();
		
		Try
			// перебор подчинённых элементов источника копирования их копирование и запись.
			While Child.Next() Do

				If Child.DeletionMark Then

					Continue;
				EndIf;

				// Сначала получим (если не копировали, скопируем) блок
				CreatedBlockParent = Undefined;
				If ValueIsFilled(Child.Parent) Then

					CreatedBlockParent = ProcessedBlocks.Get(Child.Parent);

					If CreatedBlockParent = Undefined Then

						NewBlock = Child.Parent.Copy();
						NewBlock.Owner = CurrentObject.Ref;
						NewBlock.DataExchange.Load = True;
						NewBlock.Write();

						CreatedBlockParent = NewBlock.Ref;

						ProcessedBlocks.Insert(Child.Parent, CreatedBlockParent);
					EndIf;
				EndIf;

				CreatedBlock = ProcessedBlocks.Get(Child.Ref);
				If CreatedBlock = Undefined Then

					Child = Child.Ref;

					NewCloseOrder = Child.Copy();
					NewCloseOrder.Owner = CurrentObject.Ref;
					NewCloseOrder.Parent = CreatedBlockParent;
					NewCloseOrder.DataExchange.Load = True;

					NewCloseOrder.Write();

					ProcessedBlocks.Insert(Child.Ref, NewCloseOrder.Ref);
				EndIf;

			EndDo;
			
			CopyingValue = Catalogs.fmBudgetDistributionScenarios.EmptyRef();
			
			CommitTransaction();
			
		Except
			Message(ErrorDescription());
			RollbackTransaction();
		EndTry;
	EndIf;

EndProcedure // ПослеЗаписиНаСервере()

#EndRegion


