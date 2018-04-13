USE [BQInt]
GO
/****** Object:  StoredProcedure [dbo].[processingTheParticipant]    Script Date: 4/13/2018 7:00:19 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[processingTheParticipant]
	@ContactID bigint
	,@JsonString nvarchar(max)
AS
BEGIN

	BEGIN TRY
		
		--up contact status to Processing
		UPDATE Contacts
		SET Status = 'Processing'
		WHERE Id = @ContactID AND Status <> 'Processing'
		
		BEGIN TRANSACTION;

		DECLARE @StrSQL nvarchar(max)
		DECLARE @Companies nvarchar(60)
		DECLARE @Modules nvarchar(12)
		DECLARE @ListOfCompanies TABLE(Company nvarchar(60))
		DECLARE @ListCompany VARCHAR(50)
		DECLARE @ItemCompany VARCHAR(5)
		DECLARE @ListOfModules TABLE(Module nvarchar(60))
		DECLARE @ListModule VARCHAR(50)
		DECLARE @ItemModule VARCHAR(5)
		DECLARE @SageCompany VARCHAR(60)
		DECLARE @IDGRP VARCHAR(60)
		DECLARE @rowcnt int
		DECLARE @IDNATACCT VARCHAR(60)
		DECLARE	@CRM_PERSON_ID nvarchar(12)
		DECLARE	@CabinetAction int --0 if not cabinet,1 is insert, 2 is update
		DECLARE @Statut int
		DECLARE @GroupTax nvarchar(12)

		--Assign value for necessary variables
		Select @IDGRP = IDGRP, @IDNATACCT = IDNATACCT, @CRM_PERSON_ID = CRM_PERSON_ID, @Modules = MODULE, @Companies = CODE_COMPAGNIE, @Statut = Statut, @GroupTax = CODETAXGRP
		From Contacts Where Id = @ContactID
		
		IF @Statut <> 1 or IF @Statut <> 0
		BEGIN
			UPDATE  Contacts
			SET IDGRP = 'MEMBRE'
			Where Id = @ContactID
		END
		
		SET @ListCompany = @Companies + ','

		--begin loop Company
		WHILE LEN(@ListCompany) > 1
		BEGIN
			SET @ItemCompany = SUBSTRING(@ListCompany, 0, CHARINDEX(',', @ListCompany));
					
					SELECT @SageCompany = SAGE_CODE FROm Companies where CRM_CODE = @ItemCompany
					SET @ListModule = @Modules + ','
					
					--begin loop Module
					WHILE LEN(@ListModule) > 1
					BEGIN
						SET @ItemModule = SUBSTRING(@ListModule, 0, CHARINDEX(',', @ListModule));
						
						--If IDGRP is empty, default it to ‘MEMBRE’
						IF @IDGRP is null or @IDGRP = ''
						BEGIN
							UPDATE  Contacts
							SET IDGRP = 'MEMBRE'
							Where Id = @ContactID
						END
						ELSE
						BEGIN

							--Otherwise verify IDGRP that it exists 
							IF (@ItemModule = 'AR')
							BEGIN
								SET @StrSQL = N'SELECT @C = COUNT(*)
												FROM ['+@SageCompany+'].dbo.ARGRO
												WHERE IDGRP = '''+ @IDGRP +''''
							END

							IF (@ItemModule = 'AP')
							BEGIN
								SET @StrSQL = N'SELECT @C = COUNT(*)
												FROM ['+@SageCompany+'].dbo.APVGR
												WHERE GROUPID = '''+ @IDGRP +''''
							END

							EXEC sp_executesql @StrSQL, N'@C INT OUTPUT', @C=@Rowcnt OUTPUT	
							
							--Write the error and return if IDGRP not exists
							IF @rowcnt < 1
							BEGIN								
								ROLLBACK TRANSACTION;
								Select -1 AS ErrorNumber, 'Group does not exist' AS ErrorMessage

								UPDATE Contacts
								SET Status = 'Error'
									,ErrorLog = 'Group does not exist'
									,JSON_TO_SEND = REPLACE (@JsonString,'}', ',"STATUS":"Error","ERRORLOG":"Group does not exist"}')
								WHERE Id = @ContactID
								RETURN
							END				
							
						END

							SET @CabinetAction = 0 

							IF (@IDNATACCT is not null AND LTRIM(RTRIM(@IDNATACCT)) <> '')
							BEGIN
								SET @StrSQL = N'SELECT @C = COUNT(*)
												FROM ['+@SageCompany+'].dbo.ARNAT
												WHERE IDNATACCT = '''+ @IDNATACCT +''''

								EXEC sp_executesql @StrSQL, N'@C INT OUTPUT', @C=@Rowcnt OUTPUT
					
								--if IDNATACCT not exists
								IF @rowcnt < 1
								BEGIN
									--Write the error and return 
									IF (@IDNATACCT <> @CRM_PERSON_ID AND @ItemModule = 'AR')
									BEGIN
										ROLLBACK TRANSACTION;
										Select -1 AS ErrorNumber, 'Cabinet does not exist' AS ErrorMessage

										UPDATE Contacts
										SET Status = 'Error'
											,ErrorLog = 'Cabinet does not exist'
											,JSON_TO_SEND = REPLACE (@JsonString,'}', ',"STATUS":"Error","ERRORLOG":"Cabinet does not exist"}') 
										WHERE Id = @ContactID
										RETURN
									END
									--In this case, the participant is a cabinet, insert new cabinet 
									IF (@IDNATACCT = @CRM_PERSON_ID AND @ItemModule = 'AR')
									BEGIN
										SET @CabinetAction = 1
									END
								END
								ELSE
								BEGIN
									--In this case, the participant is a cabinet, update the cabinet 
									IF (@IDNATACCT = @CRM_PERSON_ID AND @ItemModule = 'AR')
									BEGIN
										SET @CabinetAction = 2
									END
								END
							END
		
							IF(@ItemModule = 'AR')
							BEGIN
								--Verify that the ID of the client or supplier exists in the Sage database for the company
								SET @StrSQL = N'SELECT @C = COUNT(*)
												FROM ['+@SageCompany+'].dbo.ARCUS
												WHERE IDCUST  = '''+ @CRM_PERSON_ID +''''

								EXEC sp_executesql @StrSQL, N'@C INT OUTPUT', @C=@Rowcnt OUTPUT
								
								-- if the client exists, update the client
								IF @rowcnt > 0
								BEGIN
									SET @StrSQL = N'UPDATE ['+@SageCompany+'].[dbo].[ARCUS]
													   SET [IDGRP] = c.IDGRP
														  ,[IDNATACCT] = COALESCE(c.IDNATACCT,'''')
														  ,[SWACTV] = COALESCE(c.SWACTV,1)
														  ,[SWHOLD] = COALESCE(c.SWHOLD,0)
														  ,[NAMECUST] = COALESCE(c.NAME,'''')
														  ,[TEXTSTRE1] = COALESCE(c.TEXTSTRE1,'''')
														  ,[TEXTSTRE2] = COALESCE(c.TEXTSTRE2,'''')
														  ,[TEXTSTRE3] = COALESCE(c.TEXTSTRE3,'''')
														  ,[TEXTSTRE4] = COALESCE(c.TEXTSTRE4,'''')
														  ,[NAMECITY] = COALESCE(c.NAMECITY,'''')
														  ,[CODESTTE] = COALESCE(c.CODESTTE,'''')
														  ,[CODEPSTL] = COALESCE(c.CODEPSTL,'''')
														  ,[CODECTRY] = COALESCE(c.CODECTRY,'''')
														  ,[NAMECTAC] = COALESCE(c.NAMECTAC,'''')
														  ,[TEXTPHON1] = COALESCE(c.TEXTPHON1,'''')
														  ,[TEXTPHON2] = COALESCE(c.TEXTPHON2,'''')
														  ,[CODETERR] = COALESCE(c.CODETERR,'''')
														  ,[CODETAXGRP] = COALESCE(c.CODETAXGRP,'''')
														  ,[EMAIL1] = COALESCE(c.EMAIL1,'''')
														  ,[WEBSITE] = COALESCE(c.WEBSITE,'''')
														  ,[CTACPHONE] = COALESCE(c.CTACPHONE,'''')
														  ,[CTACFAX] = COALESCE(c.CTACFAX,'''')
														  ,[CODECHECK] = COALESCE(c.CODECHECK,'''')
													 FROM(SELECT *
														  FROM Contacts
														  WHERE Id = '+ Convert(Varchar,@ContactID ) + ') c
													 WHERE IDCUST = c.CRM_PERSON_ID'
									EXEC sp_executesql @StrSQL
									--Update ARNAT table with same data if client is cabinet
								END
								--Otherwise insert new client
								ELSE
								BEGIN
									SET @StrSQL = N'INSERT INTO ['+@SageCompany+'].[dbo].[ARCUS] '
														   --([IDCUST],[AUDTDATE],[AUDTTIME],[AUDTUSER]
														   --,[AUDTORG],[TEXTSNAM],[IDGRP],[IDNATACCT]
														   --,[SWACTV],[DATEINAC],[DATELASTMN],[SWHOLD]
														   --,[DATESTART],[IDPPNT],[CODEDAB],[CODEDABRTG]
														   --,[DATEDAB],[NAMECUST],[TEXTSTRE1],[TEXTSTRE2]
														   --,[TEXTSTRE3],[TEXTSTRE4],[NAMECITY],[CODESTTE]
														   --,[CODEPSTL],[CODECTRY],[NAMECTAC],[TEXTPHON1]
														   --,[TEXTPHON2],[CODETERR],[IDACCTSET],[IDAUTOCASH]
														   --,[IDBILLCYCL],[IDSVCCHRG],[IDDLNQ],[CODECURN]
														   --,[SWPRTSTMT],[SWPRTDLNQ],[SWBALFWD],[CODETERM]
														   --,[IDRATETYPE],[CODETAXGRP],[IDTAXREGI1],[IDTAXREGI2]
														   --,[IDTAXREGI3],[IDTAXREGI4],[IDTAXREGI5],[TAXSTTS1]
														   --,[TAXSTTS2],[TAXSTTS3] ,[TAXSTTS4] ,[TAXSTTS5]
														   --,[AMTCRLIMT],[AMTBALDUET],[AMTBALDUEH],[DATELASTST]
														   --,[AMTLASTSTT],[AMTLASTSTH],[DTBEGBALFW],[AMTBALFWDT]
														   --,[AMTBALFWDH],[DTLASTRVAL],[AMTBALLARV],[CNTOPENINV]
														   --,[CNTINVPAID],[DAYSTOPAY],[DATEINVCHI],[DATEBALHI]
														   --,[DATEINVHIL],[DATEBALHIL],[DATELASTAC],[DATELASTIV]
														   --,[DATELASTCR],[DATELASTDR],[DATELASTPA],[DATELASTDI]
														   --,[DATELASTAD],[DATELASTWR],[DATELASTRI],[DATELASTIN]
														   --,[DATELASTDQ],[IDINVCHI],[IDINVCHILY],[AMTINVHIT]
														   --,[AMTBALHIT],[AMTINVHILT],[AMTBALHILT],[AMTLASTIVT]
														   --,[AMTLASTCRT],[AMTLASTDRT],[AMTLASTPYT],[AMTLASTDIT]
														   --,[AMTLASTADT],[AMTLASTWRT],[AMTLASTRIT],[AMTLASTINT]
														   --,[AMTINVHIH],[AMTBALHIH],[AMTINVHILH],[AMTBALHILH]
														   --,[AMTLASTIVH],[AMTLASTCRH],[AMTLASTDRH],[AMTLASTPYH]
														   --,[AMTLASTDIH],[AMTLASTADH],[AMTLASTWRH],[AMTLASTRIH]
														   --,[AMTLASTINH],[CODESLSP1],[CODESLSP2],[CODESLSP3]
														   --,[CODESLSP4],[CODESLSP5],[PCTSASPLT1],[PCTSASPLT2]
														   --,[PCTSASPLT3],[PCTSASPLT4],[PCTSASPLT5],[PRICLIST]
														   --,[CUSTTYPE],[AMTPDUE],[EMAIL1],[EMAIL2]
														   --,[WEBSITE],[BILLMETHOD],[PAYMCODE],[FOB]
														   --,[SHPVIACODE],[SHPVIADESC],[DELMETHOD],[PRIMSHIPTO]
														   --,[CTACPHONE],[CTACFAX],[SWPARTSHIP],[SWWEBSHOP]
														   --,[RTGPERCENT],[RTGDAYS],[RTGTERMS],[RTGAMTTC]
														   --,[RTGAMTHC],[VALUES],[CNTPPDINVC],[AMTPPDINVT]
														   --,[AMTPPDINVH],[DATELASTRF],[AMTLASTRFT],[AMTLASTRFH]
														   --,[CODECHECK],[NEXTCUID],[LOCATION],[SWCHKLIMIT]
														   --,[SWCHKOVER],[OVERDAYS],[OVERAMT],[SWBACKORDR]
														   --,[SWCHKDUPPO],[CATEGORY],[BRN])
										SET @StrSQL = @StrSQL + 'SELECT
														   CRM_PERSON_ID,0,0,''''
														   ,'''','''',IDGRP,COALESCE(IDNATACCT,'''')
														   ,COALESCE(SWACTV,1),0,0,COALESCE(SWHOLD,0)
														   ,0,'''','''',''''
														   ,0,COALESCE(NAME,''''),COALESCE(TEXTSTRE1,''''),COALESCE(TEXTSTRE2,'''')
														   ,COALESCE(TEXTSTRE3,''''),COALESCE(TEXTSTRE4,''''),COALESCE(NAMECITY,''''),COALESCE(CODESTTE,'''')
														   ,COALESCE(CODEPSTL,''''),COALESCE(CODECTRY,''''),COALESCE(NAMECTAC,''''),COALESCE(TEXTPHON1,'''')
														   ,COALESCE(TEXTPHON2,''''),COALESCE(CODETERR,''''),'''',''''
														   ,'''','''','''',''''
														   ,0,0,0,0
														   ,'''',COALESCE(CODETAXGRP,''''),'''',''''
														   ,'''','''','''',0
														   ,0,0,0,0
														   ,0,0,0,0
														   ,0,0,0,0
														   ,0,0,0,0
														   ,0,0,0,0
														   ,0,0,0,0
														   ,0,0,0,0
														   ,0,0,0,0
														   ,0,'''','''',0
														   ,0,0,0,0
														   ,0,0,0,0
														   ,0,0,0,0
														   ,0,0,0,0
														   ,0,0,0,0
														   ,0,0,0,0
														   ,0,'''','''',''''
														   ,'''','''',0,0
														   ,0,0,0,''''
														   ,0,0,COALESCE(EMAIL1,''''),''''
														   ,COALESCE(WEBSITE,''''),0,'''',''''
														   ,'''','''',0,''''
														   ,COALESCE(CTACPHONE,''''),COALESCE(CTACFAX,''''),0,0
														   ,0,0,'''',0
														   ,0,0,0,0
														   ,0,0,0,0
														   ,COALESCE(CODECHECK,''''),0,'''',0
														   ,0,0,0,0
														   ,0,0,''''
													  FROM Contacts
													  WHERE Id = '+ Convert(Varchar,@ContactID ) + ''
									EXEC sp_executesql @StrSQL
									END
								END	
								
									--Insert ARNAT table with same data if client is cabinet
									IF(@CabinetAction = 1)
									BEGIN
									SET @StrSQL = N'INSERT INTO ['+@SageCompany+'].[dbo].[ARNAT] '
															--([IDNATACCT],[AUDTDATE],[AUDTTIME],[AUDTUSER]
														 --  ,[AUDTORG],[IDGRP],[SWACTV],[DATEINAC]
														 --  ,[DATELSTMTN],[SWHOLD],[CODEDAB],[DABRTG]
														 --  ,[DATEDAB],[NAMEACCT],[TEXTSTRE1],[TEXTSTRE2]
														 --  ,[TEXTSTRE3],[TEXTSTRE4],[NAMECITY],[CODESTATE]
														 --  ,[CODEPOST],[CODECTRY],[NAMECTAC],[TEXTPHON1]
														 --  ,[TEXTPHON2],[IDACCTSET],[IDAUTOCASH],[IDBILLCYCL]
														 --  ,[IDSVCCHRG],[IDDLNQ],[CODECURN],[SWPRTSTMT]
														 --  ,[SWPRTDLNQ],[SWBALFWD],[IDRATETYPE],[AMTCRLIMIT]
														 --  ,[AMTBALDUTC],[AMTBALDUHC],[DATELSTSTM],[AMTLSTSTTC]
														 --  ,[AMTLSTSTHC],[DATEBALFWD],[AMTBLFWDTC],[AMTBLFWDHC]
														 --  ,[DATERVAL],[AMTLSTRVAL],[CNTOPENINV],[CNTINVPAID]
														 --  ,[CNTDAYSPAY],[DATEINVCHI],[DATEBALHI],[DATEINVHIL]
														 --  ,[DATEBALHIL],[DATELASTAC],[DATELASTIN],[DATELASTCR]
														 --  ,[DATELASTDR],[DATELASTPA],[DATELASTDI],[DATELASTAD]
														 --  ,[DATELASTWR],[DATELASTRI],[DATELSTINT],[DATELASTDL]
														 --  ,[IDINVCHIGH],[IDINVCHILY],[AMTINVHITC],[AMTBALHITC]
														 --  ,[AMTINVHLIT],[AMTBALHILT],[AMTINVTC],[AMTCRTC]
														 --  ,[AMTDRTC],[AMTPAYMTC],[AMTDISCTC],[AMTADJTC]
														 --  ,[AMTWROFTC],[AMTRIFTC],[AMTINTTTC],[AMTINVHIHC]
														 --  ,[AMTBALHIHC],[AMTINVHILH],[AMTBALHILH],[AMTINVHC]
														 --  ,[AMTCRHC],[AMTDRHC],[AMTPAYMHC],[AMTDISCHC]
														 --  ,[AMTADJHC],[AMTWROFHC],[AMTRIFHC],[AMTINTTHC]
														 --  ,[EMAIL],[WEBSITE],[CTACPHONE],[CTACFAX]
														 --  ,[CTACEMAIL],[DELMETHOD],[RTGAMTTC],[RTGAMTHC]
														 --  ,[VALUES],[DATELASTRF],[AMTLASTRFT],[AMTLASTRFH]
														 --  ,[SWCHKLIMIT],[SWCHKOVER],[OVERDAYS],[OVERAMT])
											SET @StrSQL = @StrSQL + 'SELECT
														   IDNATACCT,0,0,''''
														   ,'''',IDGRP,COALESCE(SWACTV,0),0
														   ,0,COALESCE(SWHOLD,0),0,0
														   ,0,COALESCE(NAME,''''),COALESCE(TEXTSTRE1,''''),COALESCE(TEXTSTRE2,'''')
														   ,COALESCE(TEXTSTRE3,''''),COALESCE(TEXTSTRE4,''''),COALESCE(NAMECITY,''''),COALESCE(CODESTTE,'''')
														   ,COALESCE(CODEPSTL,''''),COALESCE(CODECTRY,''''),COALESCE(NAMECTAC,''''),COALESCE(TEXTPHON1,'''')
														   ,COALESCE(TEXTPHON2,''''),'''','''',''''
														   ,'''','''','''',''''
														   ,'''','''','''',0
														   ,0,0,0,0
														   ,0,0,0,0
														   ,0,0,0,0
														   ,0,0,0,0
														   ,0,0,0,0
														   ,0,0,0,0
														   ,0,0,0,0
														   ,0,0,0,0
														   ,0,0,0,0
														   ,0,0,0,0
														   ,0,0,0,0
														   ,0,0,0,0
														   ,0,0,0,0
														   ,0,0,0,0
														   ,COALESCE(EMAIL1,''''),COALESCE(WEBSITE,''''),COALESCE(CTACPHONE,''''),COALESCE(CTACFAX,'''')
														   ,'''',0,0,0
														   ,0,0,0,0
														   ,0,0,0,0
														FROM Contacts
														WHERE Id = '+ Convert(Varchar,@ContactID ) + ''
										EXEC sp_executesql @StrSQL
										
									IF(@CabinetAction = 2)
									BEGIN
										SET @StrSQL = N'UPDATE ['+@SageCompany+'].[dbo].[ARNAT]
															   SET [IDGRP] = c.IDGRP
																  ,[SWACTV] = COALESCE(c.SWACTV,1)
																  ,[SWHOLD] = COALESCE(c.SWHOLD,0)
																  ,[NAMEACCT] = COALESCE(c.NAME,'''')
																  ,[TEXTSTRE1] = COALESCE(c.TEXTSTRE1,'''')
																  ,[TEXTSTRE2] = COALESCE(c.TEXTSTRE2,'''')
																  ,[TEXTSTRE3] = COALESCE(c.TEXTSTRE3,'''')
																  ,[TEXTSTRE4] = COALESCE(c.TEXTSTRE4,'''')
																  ,[NAMECITY] = COALESCE(c.NAMECITY,'''')
																  ,[CODESTATE] = COALESCE(c.CODESTTE,'''')
																  ,[CODEPOST] = COALESCE(c.CODEPSTL,'''')
																  ,[CODECTRY] = COALESCE(c.CODECTRY,'''')
																  ,[NAMECTAC] = COALESCE(c.NAMECTAC,'''')
																  ,[TEXTPHON1] = COALESCE(c.TEXTPHON1,'''')
																  ,[TEXTPHON2] = COALESCE(c.TEXTPHON2,'''')
																  ,[EMAIL] = COALESCE(c.EMAIL1,'''')
																  ,[WEBSITE] = COALESCE(c.WEBSITE,'''')
																  ,[CTACPHONE] = COALESCE(c.CTACPHONE,'''')
																  ,[CTACFAX] = COALESCE(c.CTACFAX,'''')
															FROM(SELECT *
																FROM Contacts
																WHERE Id = '+ Convert(Varchar,@ContactID ) + ') c
															WHERE ['+@SageCompany+'].[dbo].[ARNAT].IDNATACCT = c.IDNATACCT'
										EXEC sp_executesql @StrSQL
									END
							END	

							IF(@ItemModule = 'AP')
							BEGIN
								SET @StrSQL = N'SELECT @C = COUNT(*)
												FROM ['+@SageCompany+'].dbo.APVEN
												WHERE VENDORID = '''+ @CRM_PERSON_ID +''''

								EXEC sp_executesql @StrSQL, N'@C INT OUTPUT', @C=@Rowcnt OUTPUT
								
								IF @rowcnt > 0
								BEGIN
										SET @StrSQL = N'UPDATE ['+@SageCompany+'].[dbo].[APVEN]
														   SET [IDGRP] = c.IDGRP
															  ,[SWACTV] = COALESCE(c.SWACTV,1)
															  ,[SWHOLD] = COALESCE(c.SWHOLD,0)
															  ,[VENDNAME] = COALESCE(c.NAME,'''')
															  ,[TEXTSTRE1] = COALESCE(c.TEXTSTRE1,'''')
															  ,[TEXTSTRE2] = COALESCE(c.TEXTSTRE2,'''')
															  ,[TEXTSTRE3] = COALESCE(c.TEXTSTRE3,'''')
															  ,[TEXTSTRE4] = COALESCE(c.TEXTSTRE4,'''')
															  ,[NAMECITY] = COALESCE(c.NAMECITY,'''')
															  ,[CODESTTE] = COALESCE(c.CODESTTE,'''')
															  ,[CODEPSTL] = COALESCE(c.CODEPSTL,'''')
															  ,[CODECTRY] = COALESCE(c.CODECTRY,'''')
															  ,[NAMECTAC] = COALESCE(c.NAMECTAC,'''')
															  ,[TEXTPHON1] = COALESCE(c.TEXTPHON1,'''')
															  ,[TEXTPHON2] = COALESCE(c.TEXTPHON2,'''')
															  ,[CODETAXGRP] = COALESCE(c.CODETAXGRP,'''')
															  ,[CODECHECK] = COALESCE(c.CODECHECK,'''')
															  ,[EMAIL1] = COALESCE(c.EMAIL1,'''')
															  ,[WEBSITE] = COALESCE(c.WEBSITE,'''')
															  ,[CTACPHONE] = COALESCE(c.CTACPHONE,'''')
															  ,[CTACFAX] = COALESCE(c.CTACFAX,'''')
														 FROM(SELECT *
																FROM Contacts
																WHERE Id = ' + Convert(Varchar,@ContactID ) +') c
														 WHERE VENDORID = c.CRM_PERSON_ID'
										EXEC sp_executesql @StrSQL
								END
								ELSE
								BEGIN
										SET @StrSQL = N'INSERT INTO ['+@SageCompany+'].[dbo].[APVEN] '
															   --([VENDORID],[AUDTDATE],[AUDTTIME],[AUDTUSER]
															   --,[AUDTORG],[SHORTNAME],[IDGRP],[SWACTV]
															   --,[DATEINAC],[DATELASTMN],[SWHOLD],[DATESTART]
															   --,[IDPPNT],[VENDNAME],[TEXTSTRE1],[TEXTSTRE2]
															   --,[TEXTSTRE3],[TEXTSTRE4],[NAMECITY],[CODESTTE]
															   --,[CODEPSTL],[CODECTRY],[NAMECTAC],[TEXTPHON1]
															   --,[TEXTPHON2],[PRIMRMIT],[IDACCTSET],[CURNCODE]
															   --,[RATETYPE],[BANKID],[PRTSEPCHKS],[DISTSETID]
															   --,[DISTCODE],[GLACCNT],[TERMSCODE],[DUPINVCCD]
															   --,[DUPAMTCODE],[DUPDATECD],[CODETAXGRP],[TAXCLASS1]
															   --,[TAXCLASS2],[TAXCLASS3],[TAXCLASS4],[TAXCLASS5]
															   --,[TAXRPTSW],[SUBJTOWTHH],[TAXNBR],[TAXIDTYPE]
															   --,[TAXNOTE2SW],[CLASID],[AMTCRLIMT],[AMTBALDUET]
															   --,[AMTBALDUEH],[AMTPPDINVT],[AMTPPDINVH],[DTLASTRVAL]
															   --,[AMTBALLARV],[CNTOPENINV],[CNTPPDINVC],[CNTINVPAID]
															   --,[DAYSTOPAY],[DATEINVCHI],[DATEBALHI],[DATEINVHIL]
															   --,[DATEBALHIL],[DATELASTAC],[DATELASTIV],[DATELASTCR]
															   --,[DATELASTDR],[DATELASTPA],[DATELASTDI],[DATELSTADJ]
															   --,[IDINVCHI],[IDINVCHILY],[AMTINVHIT],[AMTBALHIT]
															   --,[AMTWTHTCUR],[AMTINVHILT],[AMTBALHILT],[AMTWTHLYTC]
															   --,[AMTLASTIVT],[AMTLASTCRT],[AMTLASTDRT],[AMTLASTPYT]
															   --,[AMTLASTDIT],[AMTLASTADT],[AMTINVHIH],[AMTBALHIH]
															   --,[AMTWTHHCUR],[AMTINVHILH],[AMTBALHILH],[AMTWTHLYHC]
															   --,[AMTLASTIVH],[AMTLASTCRH],[AMTLASTDRH],[AMTLASTPYH]
															   --,[AMTLASTDIH],[AMTLASTADH],[PAYMCODE],[IDTAXREGI1]
															   --,[IDTAXREGI2],[IDTAXREGI3],[IDTAXREGI4],[IDTAXREGI5]
															   --,[SWDISTBY],[CODECHECK],[AVGDAYSPAY],[AVGPAYMENT]
															   --,[AMTINVPDHC],[AMTINVPDTC],[CNTNBRCHKS],[SWTXINC1]
															   --,[SWTXINC2],[SWTXINC3],[SWTXINC4],[SWTXINC5]
															   --,[EMAIL1],[EMAIL2],[WEBSITE],[CTACPHONE]
															   --,[CTACFAX],[DELMETHOD],[RTGPERCENT],[RTGDAYS]
															   --,[RTGTERMS],[RTGAMTTC],[RTGAMTHC],[VALUES]
															   --,[NEXTCUID],[LEGALNAME],[CHK1099AMT],[IDCUST]
															   --,[BRN])
											SET @StrSQL = @StrSQL + 'SELECT
															   CRM_PERSON_ID,0,0,''''
															   ,'''','''',IDGRP,COALESCE(SWACTV,1)
															   ,0,0,COALESCE(SWHOLD,0),0
															   ,'''',COALESCE(NAME,''''),COALESCE(TEXTSTRE1,''''),COALESCE(TEXTSTRE2,'''')
															   ,COALESCE(TEXTSTRE3,''''),COALESCE(TEXTSTRE4,''''),COALESCE(NAMECITY,''''),COALESCE(CODESTTE,'''')
															   ,COALESCE(CODEPSTL,''''),COALESCE(CODECTRY,''''),COALESCE(NAMECTAC,''''),COALESCE(TEXTPHON1,'''')
															   ,COALESCE(TEXTPHON2,''''),'''','''',''''
															   ,'''','''',0,''''
															   ,'''','''','''',0
															   ,0,0,COALESCE(CODETAXGRP,''''),0
															   ,0,0,0,0
															   ,0,0,'''',0
															   ,0,'''',0,0
															   ,0,0,0,0
															   ,0,0,0,0
															   ,0,0,0,0
															   ,0,0,0,0
															   ,0,0,0,0
															   ,'''','''',0,0
															   ,0,0,0,0
															   ,0,0,0,0
															   ,0,0,0,0
															   ,0,0,0,0
															   ,0,0,0,0
															   ,0,0,'''',''''
															   ,'''','''','''',''''
															   ,0,COALESCE(CODECHECK,''''),0,0
															   ,0,0,0,0
															   ,0,0,0,0
															   ,COALESCE(EMAIL1,''''),'''',COALESCE(WEBSITE,''''),COALESCE(CTACPHONE,'''')
															   ,COALESCE(CTACFAX,''''),0,0,0
															   ,'''',0,0,0
															   ,0,'''',0,''''
															   ,''''
														 FROM Contacts
														 WHERE Id = '+ Convert(Varchar,@ContactID ) + ''
										EXEC sp_executesql @StrSQL
								END
							END
	
						SET @ListModule = REPLACE(',' + @ListModule, ',' + @ItemModule + ',', '')
						--End loop Module
					END
	
			SET @ListCompany = REPLACE(',' + @ListCompany, ',' + @ItemCompany + ',', '')
			--End loop Company
		END
		
		--If everything goes fine, mark it as completed 
		UPDATE Contacts
		SET Status = 'TransferPending'
			,ErrorLog = ''
			,JSON_TO_SEND = REPLACE (@JsonString,'}', ',"STATUS":"Completed","ERRORLOG":"' + COALESCE(ERROR_MESSAGE(),'') + '"}') 
		WHERE Id = @ContactID
		
		--Return 0 AS ErrorNumber,null AS ErrorMessage if no error
		Select @@Error AS ErrorNumber, ERROR_MESSAGE() AS ErrorMessage
		COMMIT TRANSACTION;

	END TRY
	BEGIN CATCH	
		
		--If any error, rollback TRANSACTION and mark it error
		Select @@Error AS ErrorNumber, ERROR_MESSAGE() AS ErrorMessage
		ROLLBACK TRANSACTION;
		UPDATE Contacts
		SET Status = 'Error'
			,ErrorLog = ERROR_MESSAGE()
			,JSON_TO_SEND = REPLACE (@JsonString,'}', ',"STATUS":"Error","ERRORLOG":"' + COALESCE(ERROR_MESSAGE(),'') + '"}') 
		WHERE Id = @ContactID
	
	END CATCH
	
END
