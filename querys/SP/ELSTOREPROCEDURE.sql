USE [tarea3BD]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
    EL STORE PROCEDURE

	Se encarga de todas las Operaciones referentes a una TCM en un dia 
	
	- primero procesa todos los movimientos del dia 
	- Luego realiza tramites de renovacion de tarjeta de ser necesario 
	- Calcula los intereses corrientes
	- Calcula los intereses moratorios 

	- Emite estados de cuenta en caso de encontrarse en la fecha de cierre 


valores que se insertaran
--  @InMovsDiarios: una tabla con todos los movimientos del dia 
--  @InNumeroTarjeta: dice que tarjeta hay que usar
--  @InFechaHoy: la fecha de operacion 
*/

ALTER PROCEDURE [dbo].[ELSTOREPROCEDURE]
    @OutResulTCode INT OUTPUT
	, @InMovsDiarios MovimientosDiarios READONLY
	, @InNumeroTarjeta BIGINT 
	, @InFechaHoy DATE
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SET @OutResulTCode = 0;

--###############################################################################################################################
--Declaracion de variables y tablas necesarias 
		
		--Tabla de a donde se insertaran los nuevos movimientos 
		DECLARE @MovimientosTCM TABLE
		(
			Id INT IDENTITY(1,1) NOT NULL
			, IdTipoDeMovimiento INT NOT NULL
			, IdEstadoDeCuenta INT NOT NULL
			, Fecha DATE NOT NULL 
			, Monto MONEY NOT NULL
			, Descripcion VARCHAR(256)
			, Referencia VARCHAR(32)
			, IdTarjetaCreditoMaestra INT NOT NULL
			, NuevoSaldo MONEY 
			, EsSus BIT DEFAULT 0
		);

		--tabla de donde se insertaran los movimientos sospechosos 
		DECLARE @MovimientosSUS TABLE
		(
			Id INT IDENTITY(1,1) NOT NULL
			, IdTipoDeMovimiento INT NOT NULL
			, Fecha DATE NOT NULL 
			, Monto MONEY NOT NULL
			, Descripcion VARCHAR(256)
			, Referencia VARCHAR(32)
			, IdTarjetaCreditoMaestra INT NOT NULL
		);

		--tabla de donde se insertara la nueva TF 
		DECLARE @NuevaTF TABLE
		(
			Id INT NOT NULL
			, IdTarjeta INT NOT NULL
			, Numero BIGINT NOT NULL
			, CCV INT NOT NULL
			, Pin INT NOT NULL 
			, FechaCreacion DATE NOT NULL
			, FechaVencimiento DATE NOT NULL
			, EsValida BIT DEFAULT 1
		);

		--Tabla de donde se sacara los movimientos por interes corrientes
		DECLARE @MovInteresesCorrientes TABLE
		(
			Id INT IDENTITY(1,1) NOT NULL
			, IdTipoDeMovimiento INT NOT NULL
			, IdEstadoDeCuenta INT NOT NULL 
			, Fecha DATE NOT NULL 
			, Monto MONEY NOT NULL
			, IdTarjetaCreditoMaestra INT NOT NULL
		);

		--Tabla de donde se sacara los movimientos por interes moratorios
		DECLARE @MovInteresesMoratorios TABLE
		(
			Id INT IDENTITY(1,1) NOT NULL
			, IdTipoDeMovimiento INT NOT NULL
			, IdEstadoDeCuenta INT NOT NULL 
			, Fecha DATE NOT NULL 
			, Monto MONEY NOT NULL
			, IdTarjetaCreditoMaestra INT NOT NULL
		);

		--las variables necesarias 

        DECLARE @IdTCM INT
				, @IdTCA INT
				, @IdTarjeta INT
				, @IdTFisica INT 
				, @hi INT
				, @lo INT
				, @FechaMovimiento DATE
				, @FechaCreacionTF DATE
				, @FechaMuerteTF DATE
				, @IdTipoDeMovimiento INT
				, @Accion VARCHAR(8)
				, @NombreMovimiento VARCHAR(32)
				, @AcumulaVentana BIT 
				, @AcumulaATM BIT 
				, @MontoMov MONEY 
				, @IdTipoTCM INT 
				, @RecuperacionFlag BIT --dice si pidieron recuperacion 
				, @NombreRecuperacion VARCHAR(64)
				, @EsValida BIT 
				, @CCV INT
				, @Pin INT 
				--Son de la TCM 
				, @SaldoActual MONEY
				, @SumaMovimientos MONEY
				, @SaldoInteresesCorrientes MONEY
				, @SaldoInteresMoratorios MONEY
				, @PagoAcumuladosDelPeriodo MONEY  --Tambien es [SumaDePagos] del EC
				--Son del EC ;
				, @FechaPagoMinimo DATE
				, @PagoMinimoMesAnterior MONEY
				, @TCMOperacionesATM INT 
				, @TCMOperacionesVentana INT 
				, @TCMQDePagos INT
				, @TCMSumaDeCompras MONEY
				, @TCMQDeCompras INT 
				, @TCMSumaDeRetiros MONEY
				, @TCMQDeRetiros INT 
				, @TCMSumaDeDebitos MONEY
				, @TCMQDeDebitos INT
				, @TCMSumaDeCreditos MONEY
				, @TCMQDeCreditos INT
				--Son del Posible EC del TCA 
				, @TCAOperacionesATM INT
				, @TCAOperacionesVentana INT 
				, @TCASumaDeCompras MONEY
				, @TCAQDeCompras INT 
				, @TCASumaDeRetiros MONEY
				, @TCAQDeRetiros INT 
				, @TCASumaDeDebitos MONEY
				, @TCASumaDeCreditos MONEY



--Ahora Asignacion de valores 

		-- le ponemos un default de 0 
		SET @RecuperacionFlag = 0; 

		--Primero obtengamos el TCM asociado al TF
		SELECT @IdTarjeta = TF.IdTarjeta
			   , @IdTFisica = TF.Id --este id si es unico
			   , @EsValida = TF.EsValida 
			   , @Pin = TF.Pin
			   , @CCV = TF.CCV
		FROM [dbo].[TarjetaFisica] TF
		WHERE TF.Numero = @InNumeroTarjeta  --hay que hacer eso para obtener la actual  ya que hay muchas a lo 
		AND (@InFechaHoy >= TF.FechaCreacion AND @InFechaHoy <= TF.FechaVencimiento); --largo del tiempo 

		--Si es valida queda nulo, significa que no existe tarjeta fisica valida 
		--para este periodo
		IF( @EsValida IS NULL)
		BEGIN
		--por ello buscamos la mas reciente
			SELECT TOP 1 @IdTarjeta = TF.IdTarjeta
				   , @IdTFisica = TF.Id
				   , @EsValida = TF.EsValida --va a quedar en 0
				   , @Pin = TF.Pin
				   , @CCV = TF.CCV
			FROM [dbo].[TarjetaFisica] TF
			WHERE TF.Numero = @InNumeroTarjeta
			ORDER BY TF.FechaCreacion DESC; 
		END; 
		
		
		IF EXISTS(SELECT 1 
				  FROM [dbo].[TarjetaCreditoMaestra] TM
				  WHERE TM.IdTarjeta = @IdTarjeta)
		BEGIN 
			--Si esto ocurre, implica que la tarjeta fisica 
			--es de una TCM
			SET @IdTCM = @IdTarjeta;
		END 
		ELSE
		BEGIN
			--esto significa que fue una TCA, la que lo realizo
			SELECT @IdTCM = TA.IdTCM
			FROM [dbo].[TarjetaCreditoAdicional] TA
			WHERE TA.IdTarjeta = @IdTarjeta

			SET @IdTCA = @IdTarjeta; 
		END;

		--seteamos el tipo de tcm 
		SELECT @IdTipoTCM = TM.IdTipoTCM
		FROM dbo.TarjetaCreditoMaestra TM
		WHERE TM.IdTarjeta = @IdTCM; 
		--Ahora Obtengamos los datos necesarios de la TCM con los que se trabajará
		
		SET @SumaMovimientos = 0; --estos son los movimientos en transito 


--;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
/* Antes de seguir declarando variables es necesario ver si hoy es la fecha de 
cierre de la TCM o TCA, ya que en ese caso hay que cambiar algunos datos y
reiniciar y cerrar algunos otros
*/
--;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		DECLARE @PosibleFin DATE
				, @IdDePosibleFIn INT;

		SELECT @PosibleFin = EC.FechaFin
			   , @IdDePosibleFIn = EC.Id
		FROM dbo.EstadoDeCuenta EC
		WHERE EC.IdTCM = @IdTCM
		AND EC.FechaFin <= @InFechaHoy
		AND EC.FechaInicio >= @InFechaHoy

		IF( @InFechaHoy = @PosibleFin)
		BEGIN 
		--Aqui realizaremos los cierres de estado de cuenta 
			SELECT * FROM @MovimientosSUS; 
		END; 


--;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
/*
Cierres de estados de cuenta listo. 
*/
--;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		SELECT @SaldoActual = TCM.SaldoActual
			   , @SaldoInteresesCorrientes = TCM.SaldoInteresesCorrientes
			   , @SaldoInteresMoratorios = TCM.SaldoInteresMoratorios
			   , @PagoAcumuladosDelPeriodo = TCM.PagoAcumuladosDelPeriodo
		FROM dbo.TarjetaCreditoMaestra TCM
		WHERE TCM.IdTarjeta = @IdTCM;

		--Ahora los datos para el Estado de Cuenta de la TCM
		
		SELECT @TCMOperacionesATM = EC.CantidadOperacionesATM
			   , @TCMOperacionesVentana = EC.CantidadOperacionesVentana
			   , @TCMQDePagos = EC.CantidadDePagos
			   , @TCMSumaDeCompras = EC.SumaDeCompras
			   , @TCMQDeCompras = EC.CantidadDeCompras
			   , @TCMSumaDeRetiros = EC.SumaDeRetiros
			   , @TCMQDeRetiros = EC.CantidadDeRetiros
			   , @TCMSumaDeDebitos = EC.SumaDeDebitos
			   , @TCMQDeDebitos = EC.CantidadDeDebitos
			   , @TCMSumaDeCreditos = EC.SumaDeCreditos
			   , @TCMQDeCreditos =EC.CantidadDeCreditos
			   , @FechaPagoMinimo = EC.FechaParaPagoMinimo
			   , @PagoMinimoMesAnterior = EC.PagoMinimoMesAnterior
		FROM dbo.EstadoDeCuenta EC 
		WHERE EC.IdTCM = @IdTCM
		AND (@InFechaHoy >= EC.FechaInicio AND @InFechaHoy <= EC.FechaFin);

		--Ahora los datos para la posible TCA Estado de Cuenta


		IF( @IdTCA IS NOT NULL)
		BEGIN 
			SELECT @TCAOperacionesATM = EA.CantidadOperacionesATM
				   , @TCAOperacionesVentana = EA.CantidadOperacionesVentana
				   , @TCASumaDeCompras = EA.SumaDeCompras
				   , @TCAQDeCompras = EA.CantidadDeCompras
				   , @TCASumaDeRetiros = EA.SumaDeRetiros
				   , @TCAQDeRetiros = EA.CantidadDeRetiros
				   , @TCASumaDeDebitos = EA.SumaDeDebitos
				   , @TCASumaDeCreditos = EA.SumaDeCreditos
			FROM dbo.EstadoDeCuentaAdicional EA
			WHERE EA.IdTCA = @IdTCA
			AND (@InFechaHoy >= EA.FechaInicio AND @InFechaHoy <= EA.FechaFin);
		END; 

		--Saquemos las fechas de la TF
		SELECT @FechaCreacionTF = TF.FechaCreacion
		FROM dbo.TarjetaFisica TF
		WHERE TF.Id = @IdTFisica; --lo buscamos con su id unico

		SELECT @FechaMuerteTF =  TF.FechaVencimiento
		FROM dbo.TarjetaFisica TF
		WHERE TF.Id = @IdTFisica; --lo buscamos con su id unico

		--ahora saquemos los movimientos que vamos a procesar 	

		INSERT INTO @MovimientosTCM 
		(
			IdTipoDeMovimiento 
			, IdEstadoDeCuenta 
			, Fecha 
			, Monto 
			, Descripcion
			, Referencia 
			, IdTarjetaCreditoMaestra 
		)
		SELECT TV.Id
			   , EC.Id
			   , MV.FechaMovimiento
			   , MV.Monto
			   , MV.Descripcion 
			   , MV.Referencia
			   , @IdTCM
		FROM @InMovsDiarios MV 
		INNER JOIN [dbo].[TiposDeMovimiento] TV ON TV.Nombre = MV.Nombre 
		INNER JOIN [dbo].[EstadoDeCuenta] EC ON (EC.IdTCM = @IdTCM) 
												AND (@InFechaHoy >= EC.FechaInicio AND @InFechaHoy <= EC.FechaFin)
		WHERE MV.TarjetaFisica = @InNumeroTarjeta; 

--###############################################################################################################################	
--Ya que tenemos los movimientos en su tabla variable toca depurarlos 
--para ello se desecharan los movimientos sospechosos y tambien
--se les añadira el nuevo saldo 

	SELECT @hi = MAX(id)
	FROM @MovimientosTCM

	SET @lo = 1; 

	WHILE (@lo <= @hi) 
	BEGIN
		
		SELECT @FechaMovimiento = T.Fecha
			   , @MontoMov = T.Monto 
			   , @NombreMovimiento = TM.Nombre
		FROM @MovimientosTCM T
		INNER JOIN dbo.TiposDeMovimiento TM ON TM.Id = T.IdTipoDeMovimiento
		WHERE T.Id = @lo;

		IF(SUBSTRING(@NombreMovimiento, 1, 12) = 'Recuperacion')
		BEGIN
		
		SET @RecuperacionFlag = 1;
		SET @NombreRecuperacion = @NombreMovimiento;

		DELETE FROM @MovimientosTCM
		WHERE Id = @lo

		END
		ELSE IF(@EsValida = 0) 
		BEGIN
			--Se marca como Sospechoso 
			UPDATE @MovimientosTCM
			SET EsSus = 1
			WHERE Id = @lo;

			INSERT INTO @MovimientosSUS 
			(
				IdTipoDeMovimiento 
				, Fecha 
				, Monto 
				, Descripcion
				, Referencia 
				, IdTarjetaCreditoMaestra 
			) 
			SELECT M.IdTipoDeMovimiento 
					, M.Fecha 
					, M.Monto 
					, M.Descripcion
					, M.Referencia 
					, M.IdTarjetaCreditoMaestra 
			FROM @MovimientosTCM M 
			WHERE M.Id = @lo 

		END
		ELSE
		BEGIN 
			--Actualizamos el Saldo en la tabla variable

			--Tenemos que ver si restamos o sumamos al @SaldoActual
			--Ademas de si ocupamos aumentar los contadores de ventana, atm, etc.

			SELECT @IdTipoDeMovimiento = MV.IdTipoDeMovimiento 
			FROM @MovimientosTCM MV
			WHERE MV.Id = @lo; 

			SELECT @Accion = TV.Accion
				   , @AcumulaATM = TV.AcumulaOperacionATM
				   , @AcumulaVentana = TV.AcumulaOperacionVentana
			FROM dbo.TiposDeMovimiento TV 
			WHERE TV.Id = @IdTipoDeMovimiento;		

			--Lo usamos mas adelante 
			DECLARE @EsCompra BIT = CASE WHEN @IdTipoDeMovimiento = 1 THEN 1 ELSE 0 END;
			DECLARE @EsRetiro BIT = CASE WHEN SUBSTRING(@NombreMovimiento, 1, 6) = 'Retiro' THEN 1 ELSE 0 END;

			--Verificar si acumula operaciones de ATM 

			
			SET @TCMOperacionesATM = CASE 
										WHEN @AcumulaATM = 1 THEN (@TCMOperacionesATM+1)
										ELSE @TCMOperacionesATM
									 END;

			SET @TCAOperacionesATM = CASE 
										WHEN @AcumulaATM = 1 AND (@IdTCA IS NOT NULL)THEN (@TCAOperacionesATM+1)
										ELSE @TCAOperacionesATM
									 END;

			--Verificar si acumula operaciones de Ventana 
			SET @TCMOperacionesVentana = CASE 
											WHEN @AcumulaVentana = 1 THEN (@TCMOperacionesVentana+1)
											ELSE @TCMOperacionesVentana
										 END;

			SET @TCAOperacionesVentana = CASE 
											WHEN @AcumulaVentana = 1 AND (@IdTCA IS NOT NULL) THEN (@TCAOperacionesVentana+1)
											ELSE @TCAOperacionesVentana
										 END;
			

			IF(@Accion = 'Credito')
			BEGIN 

				--Actualizamos el saldo actual (hay que ponerlo luego en @MovimientosTCM)
				SET @SaldoActual += @MontoMov;
				SET @SumaMovimientos +=  @MontoMov;

				--Ahora modifiquemos los que seran valores del EC del TCM 
				SET @TCMQDePagos +=1;
				SET @PagoAcumuladosDelPeriodo += @MontoMov; --Añadimos a los pagos del periodo 

				SET @TCMSumaDeCreditos += @MontoMov;
				SET @TCMQDeCreditos += 1;

				--Ahora agreguemos a TCA, en caso de SER necesario 
				SET @TCASumaDeCreditos += CASE WHEN @IdTCA IS NOT NULL THEN @MontoMov ELSE 0 END;
				
			END
			ELSE --En caso de ser debito hay que hacer otras, y mas validaciones
			BEGIN 
				
				--Definitivamente es un debito, por lo que se modificara esa variable 
				SET @TCMSumaDeDebitos += @MontoMov;
				SET @TCMQDeDebitos += 1;

				--Actualizamos el saldo actual (hay que ponerlo luego en @MovimientosTCM)
				SET @SaldoActual -= @MontoMov;
				SET @SumaMovimientos -=  @MontoMov;
				
				--Verifiquemos si añadir a compra 
				SET @TCMQDeCompras += CASE WHEN @EsCompra = 1 THEN 1 ELSE 0 END;
				SET @TCMSumaDeCompras += CASE WHEN @EsCompra = 1 THEN @MontoMov ELSE 0 END;

				--Verificamos si añadir a retiro 
				SET @TCMQDeRetiros += CASE WHEN @EsRetiro = 1 THEN 1 ELSE 0 END;
				SET @TCMSumaDeRetiros += CASE WHEN @EsRetiro = 1 THEN @MontoMov ELSE 0 END;

				IF(@IdTCA IS NOT NULL)
				BEGIN 
					SET @TCAQDeCompras += CASE WHEN @EsCompra = 1 THEN 1 ELSE 0 END;
					SET @TCASumaDeCompras += CASE WHEN @EsCompra = 1 THEN @MontoMov ELSE 0 END;

					
					SET @TCASumaDeRetiros += CASE WHEN @EsRetiro = 1 THEN @MontoMov ELSE 0 END;
					SET @TCAQDeRetiros += CASE WHEN @EsRetiro = 1 THEN 1 ELSE 0 END;

					SET @TCASumaDeCreditos += @MontoMov;
				END;

			END;
			
			--Actualizamos el saldo actual de los movimientos 
			UPDATE @MovimientosTCM
			SET NuevoSaldo = @SaldoActual
			WHERE Id = @lo;

		END; 

		SET @lo += 1;
	END;

--##############################################################################################################################

	-- Ya que preprocesamos todos los movimientos toca revisar si hace falta renovar la TF
	-- o bien si hay que expedir otra ya que se perdio

	DECLARE @NuevoVencimiento DATE
			, @IdRegla INT 
			, @IdTipoDeReposicion INT
			, @MontoRenovacion MONEY;

	--Osea, si hoy vence y no se perdio
	IF(@InFechaHoy = @FechaMuerteTF AND @EsValida = 1 AND @RecuperacionFlag = 0) 
	BEGIN 

	--Primero cerremos la actual 
	SET @EsValida = 0; 

	--revisamos las reglas de negocio en caso de ser TCA 
		IF( @IdTCA IS NOT NULL)
		BEGIN 
			SET @NuevoVencimiento = DATEADD(YEAR, 3, @FechaMuerteTF)
			--Tambien hay que generar el cargo por renovacion 

			SELECT @IdRegla = RN.Id
			FROM dbo.ReglasDeNegocio RN
			WHERE RN.Nombre = 'Cargo renovacion de TF de TCA'
			AND RN.IdTipoDeTCM = @IdTipoTCM; 

			SELECT @MontoRenovacion = RN.Valor
			FROM dbo.RNMonto RN 
			WHERE RN.IdReglaNegocio = @IdRegla;
		END
		ELSE
		BEGIN
			--ahora toca el caso de que sea TCM
			SET @NuevoVencimiento = DATEADD(YEAR, 5, @FechaMuerteTF)
			--Tambien hay que generar el cargo por renovacion 

			SELECT @IdRegla = RN.Id
			FROM dbo.ReglasDeNegocio RN
			WHERE RN.Nombre = 'Cargo renovacion de TF de TCM'
			AND RN.IdTipoDeTCM = @IdTipoTCM; 

			SELECT @MontoRenovacion = RN.Valor
			FROM dbo.RNMonto RN 
			WHERE RN.IdReglaNegocio = @IdRegla;
		END;

	--creamos la nueva TF 
	INSERT INTO @NuevaTF 
	(
		Id
		, IdTarjeta 
		, Numero 
		, CCV 
		, Pin 
		, FechaCreacion 
		, FechaVencimiento 
	)
	VALUES
	(
		(SELECT MAX(TF.Id)
		FROM dbo.TarjetaFisica TF) +1
		, @IdTarjeta
		, @InNumeroTarjeta
		, @CCV
		, @Pin
		, @InFechaHoy 
		, @NuevoVencimiento
	)

	--Creamos el movimiento 
	INSERT INTO @MovimientosTCM 
	(
		IdTipoDeMovimiento 
		, IdEstadoDeCuenta 
		, Fecha 
		, Monto 
		, Descripcion
		, Referencia 
		, IdTarjetaCreditoMaestra 
		, NuevoSaldo 
	)
	VALUES
	(
		(SELECT TM.Id
		FROM dbo.TiposDeMovimiento TM
		WHERE TM.Nombre = 'Renovacion de TF')
		, (SELECT TOP 1 TM.IdEstadoDeCuenta
		  FROM @MovimientosTCM TM)
		, @InFechaHoy
		, @MontoRenovacion
		, 'Renovacion por vencimiento de TF'
		, ' '
		, @IdTCM 
		, (SELECT TOP 1 TM.NuevoSaldo
		  FROM @MovimientosTCM TM
		  ORDER BY TM.Id DESC) -@MontoRenovacion	
	);

	END;


	IF(@RecuperacionFlag = 1) 
	BEGIN 

	--Primero cerremos la actual 
	SET @EsValida = 0; 

	--revisamos las reglas de negocio en caso de ser TCA 
		IF( @IdTCA IS NOT NULL)
		BEGIN 
			SET @NuevoVencimiento = DATEADD(YEAR, 3, @FechaMuerteTF)
			--Tambien hay que generar el cargo por renovacion 

			SELECT @IdRegla = RN.Id
			FROM dbo.ReglasDeNegocio RN
			WHERE RN.Nombre = 'Reposicion de tarjeta de TCA'
			AND RN.IdTipoDeTCM = @IdTipoTCM; 

			SELECT @MontoRenovacion = RN.Valor
			FROM dbo.RNMonto RN 
			WHERE RN.IdReglaNegocio = @IdRegla;
		END
		ELSE
		BEGIN
			--ahora toca el caso de que sea TCM
			SET @NuevoVencimiento = DATEADD(YEAR, 5, @FechaMuerteTF)
			--Tambien hay que generar el cargo por renovacion 

			SELECT @IdRegla = RN.Id
			FROM dbo.ReglasDeNegocio RN
			WHERE RN.Nombre = 'Reposicion de tarjeta de TCM'
			AND RN.IdTipoDeTCM = @IdTipoTCM; 

			SELECT @MontoRenovacion = RN.Valor
			FROM dbo.RNMonto RN 
			WHERE RN.IdReglaNegocio = @IdRegla;
		END;

	--creamos la nueva TF 
	INSERT INTO @NuevaTF 
	(
		Id
		, IdTarjeta 
		, Numero 
		, CCV 
		, Pin 
		, FechaCreacion 
		, FechaVencimiento 
	)
	VALUES
	(
		(SELECT MAX(TF.Id)
		FROM dbo.TarjetaFisica TF) +1
		, @IdTarjeta
		, @InNumeroTarjeta
		, @CCV
		, @Pin
		, @InFechaHoy 
		, @NuevoVencimiento
	)

	--Creamos el movimiento 
	INSERT INTO @MovimientosTCM 
	(
		IdTipoDeMovimiento 
		, IdEstadoDeCuenta 
		, Fecha 
		, Monto 
		, Descripcion
		, Referencia 
		, IdTarjetaCreditoMaestra 
		, NuevoSaldo 
	)
	VALUES
	(
		(SELECT TM.Id
		FROM dbo.TiposDeMovimiento TM
		WHERE TM.Nombre = @NombreRecuperacion)
		, (SELECT TOP 1 TM.IdEstadoDeCuenta
		  FROM @MovimientosTCM TM)
		, @InFechaHoy
		, @MontoRenovacion
		, @NombreRecuperacion
		, ' '
		, @IdTCM 
		, (SELECT TOP 1 TM.NuevoSaldo
		  FROM @MovimientosTCM TM
		  ORDER BY TM.Id DESC) - @MontoRenovacion	
	);

	END;
		
--##############################################################################################################################
	--Ahora nos encargaremos de realizar los movimientos por intereses Corrientes

	DECLARE @MontoInteresCorrientes MONEY
			, @TasaInteresCorriente REAl
			, @IdTasaInteresCorriente INT;

	
	IF(@SaldoActual > 0)
	BEGIN 
		
		SELECT @IdTasaInteresCorriente = RN.Id
		FROM dbo.ReglasDeNegocio RN
		WHERE RN.Nombre = 'Tasa de interes corriente'
		AND RN.IdTipoDeTCM = @IdTipoTCM; 

		SELECT @TasaInteresCorriente = RN.Valor
		FROM dbo.RNTasa RN
		WHERE RN.IdReglaNegocio = @IdTasaInteresCorriente;


		SET @MontoInteresCorrientes = ((@SaldoActual/@TasaInteresCorriente)/100)/30;

		SET @SaldoInteresesCorrientes += @MontoInteresCorrientes;

		INSERT INTO @MovInteresesCorrientes 
		(
			IdTipoDeMovimiento 
			, IdEstadoDeCuenta 
			, Fecha 
			, Monto 
			, IdTarjetaCreditoMaestra 
		)
		VALUES
		(
			(SELECT TM.Id
			FROM dbo.TiposDeMovimiento TM 
			WHERE TM.Nombre = 'Intereses Corrientes sobre Saldo')
			, (SELECT TOP 1 TM.IdEstadoDeCuenta
			  FROM @MovimientosTCM TM)
			, @InFechaHoy
			, @MontoInteresCorrientes 
			, @IdTCM
		)
	END;


--##############################################################################################################################
	--Ahora nos encargaremos de aplicar los movimientos por intereses moratorios

	DECLARE @MontoInteresMoratorio MONEY
			, @MontoPagoMinimo MONEY
			, @TasaInteresMoratorio REAl
			, @IdTasaInteresMoratorio INT;

	
	IF(@InFechaHoy > @FechaPagoMinimo AND @PagoAcumuladosDelPeriodo < @PagoMinimoMesAnterior)
	BEGIN 
		
		SELECT @IdTasaInteresMoratorio = RN.Id
		FROM dbo.ReglasDeNegocio RN
		WHERE RN.Nombre = 'intereses moratorios'
		AND RN.IdTipoDeTCM = @IdTipoTCM; 

		SELECT @TasaInteresMoratorio = RN.Valor
		FROM dbo.RNTasa RN
		WHERE RN.IdReglaNegocio = @IdTasaInteresMoratorio;

		SET @MontoPagoMinimo = @PagoMinimoMesAnterior - @PagoAcumuladosDelPeriodo

		SET @MontoInteresMoratorio = ((@MontoPagoMinimo/@TasaInteresMoratorio)/100)/30

		SET @SaldoInteresMoratorios = @MontoInteresMoratorio; 

		INSERT INTO @MovInteresesMoratorios 
		(
			IdTipoDeMovimiento 
			, IdEstadoDeCuenta 
			, Fecha 
			, Monto 
			, IdTarjetaCreditoMaestra 
		)
		VALUES
		(
			(SELECT TM.Id
			FROM dbo.TiposDeMovimiento TM 
			WHERE TM.Nombre = 'Intereses Moratorios Pago no Realizado')
			, (SELECT TOP 1 TM.IdEstadoDeCuenta
			  FROM @MovimientosTCM TM)
			, @InFechaHoy
			, @MontoInteresCorrientes 
			, @IdTCM
		)
		
	END;
	
--##############################################################################################################################



	SELECT V.Nombre, * FROM @MovimientosTCM M
	INNER JOIN dbo.TiposDeMovimiento V ON M.IdTipoDeMovimiento = V.Id
	SELECT @PagoAcumuladosDelPeriodo as pagos; 

	 SELECT @TCMOperacionesATM as TCMatm; 
	 SELECT @TCMOperacionesVentana as TCMVentana;
	 SELECT @TCMQDePagos as TCMpagos;
	SELECT @TCMSumaDeCompras as TCMCompras;
	SELECT @TCMQDeCompras as TCMCOMPRAS; 
	SELECT @TCMSumaDeRetiros astcmRetiros;
	SELECT @TCMQDeRetiros as RETIROS;
	SELECT @TCMSumaDeDebitos as tcmdebitos;
	SELECT @TCMQDeDebitos as TCMDBEITOs;
	SELECT @TCMSumaDeCreditos AS tcmCreditos;
	SELECT @TCMQDeCreditos as TCMCREDITOS;
				--Son del Posible EC del TCA 
	SELECT @TCAOperacionesATM as TCAATM;
	SELECT @TCAOperacionesVentana as TCAVENT;
	SELECT @TCASumaDeCompras as tcacompras
	SELECT @TCAQDeCompras as TCACOMPRRASq;
	SELECT @TCASumaDeRetiros as sumaRet; 
	SELECT @TCAQDeRetiros as qretiro;
	SELECT @TCASumaDeDebitos as qdebito;
	SELECT @TCASumaDeCreditos as qcredito;
	
	SELECT * FROM @NuevaTF AS NUEVAS;
	
        

    END TRY
    BEGIN CATCH
        IF(@@TRANCOUNT > 0)
        BEGIN
            ROLLBACK;
        END;
        INSERT INTO dbo.DBError VALUES 
        (
            SUSER_SNAME(),
            ERROR_NUMBER(),
            ERROR_STATE(),
            ERROR_SEVERITY(),
            ERROR_LINE(),
            ERROR_PROCEDURE(),
            ERROR_MESSAGE(),
            GETDATE()
        );
        SET @OutResulTCode = 50008;
               
    END CATCH;
    RETURN;
END;