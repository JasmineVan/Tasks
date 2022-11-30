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
	CommonParameters = Common.CommonCoreParameters();
	RecommendedSize = CommonParameters.RecommendedRAM;
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	Cancel = True;
	
	SystemInfo = New SystemInfo;
	AvailableMemorySize = Round(SystemInfo.RAM / 1024, 1);
	
	If AvailableMemorySize >= RecommendedSize Then
		Return;
	EndIf;
	
	MessageText = NStr("ru = 'На компьютере установлено %1 Гб оперативной памяти.
		|Для того чтобы программа работала быстрее, 
		|рекомендуется увеличить объем памяти до %2 Гб.'; 
		|en = 'The computer has %1 GB of RAM.
		|For better application performance,
		|it is recommended that you increase the RAM size to %2 GB.'; 
		|pl = 'Na komputerze ustawiono %1 GB pamięci operacyjnej. 
		|Aby program pracował szybciej, 
		|zaleca się zwiększyć pojemność pamięci do %2 GB.';
		|de = 'Ein %1 GB RAM ist auf dem Computer installiert.
		|Um die Arbeit des Programms zu beschleunigen, 
		|wird empfohlen, den Speicherplatz auf bis zu %2 GB zu erhöhen.';
		|ro = 'Pe computer sunt instalate %1 Gb de memorie operativă.
		|Pentru ca programul să lucreze mai repede 
		|recomandăm să majorați volumul de memorie până la %2 Gb.';
		|tr = 'Bilgisayarda %1GB RAM yüklü. %2Programın daha hızlı çalışmasını sağlamak için 
		|bellek miktarını 
		|GB''ye yükseltmeniz önerilir.'; 
		|es_ES = 'En el ordenador está instalado %1 GB de la memoria operativa.
		|Para que el programa funcione más rápido 
		|se recomienda aumentar el volumen de la memoria hasta %2 GB.'");
	
	MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText, AvailableMemorySize, RecommendedSize);
	
	MessageTitle = NStr("ru = 'Рекомендация по повышению скорости работы'; en = 'Speedup recommendation'; pl = 'Zalecenie odnośnie zwiększenia szybkości pracy';de = 'Empfehlung zur Erhöhung der Arbeitsgeschwindigkeit';ro = 'Recomandări pentru mărirea vitezei de lucru';tr = 'Çalışma hızının arttırılması ile ilgili öneri'; es_ES = 'Recomendación de superar la velocidad del trabajo'");
	
	QuestionParameters = StandardSubsystemsClient.QuestionToUserParameters();
	QuestionParameters.Title = MessageTitle;
	QuestionParameters.Picture = PictureLib.Warning32;
	QuestionParameters.Insert("CheckBoxText", NStr("ru = 'Не показывать в течение двух месяцев'; en = 'Remind in two months'; pl = 'Nie pokazuj w ciągu dwóch miesięcy';de = 'Zwei Monate lang nicht vorzeigen';ro = 'Nu afișa timp de două luni';tr = 'İki ay içinde gösterme'; es_ES = 'No mostrar durante dos meses'"));
	
	Buttons = New ValueList;
	Buttons.Add("ContinueWork", NStr("ru = 'Продолжить работу'; en = 'Continue'; pl = 'Kontynuuj';de = 'Weiter';ro = 'Continuare lucrul';tr = 'Devam'; es_ES = 'Continuar'"));
	
	NotifyDescription = New NotifyDescription("AfterShowRecommendation", ThisObject);
	StandardSubsystemsClient.ShowQuestionToUser(NotifyDescription, MessageText, Buttons, QuestionParameters);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure AfterShowRecommendation(Result, AdditionalParameters) Export
	If Result = Undefined Then
		Return;
	EndIf;
	
	RAMRecommendation = New Structure;
	RAMRecommendation.Insert("Show", Not Result.DoNotAskAgain);
	RAMRecommendation.Insert("PreviousShowDate", CommonClient.SessionDate());
	
	CommonServerCall.CommonSettingsStorageSave("UserCommonSettings",
		"RAMRecommendation", RAMRecommendation);
EndProcedure

#EndRegion
