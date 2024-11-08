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
			, EsSus BIT
		);

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

		--las variables necesarias 

        DECLARE @IdTCM INT
				, @IdTCA INT
				, @IdTarjeta INT
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
				--Son de la TCM 
				, @SaldoActual MONEY
				, @SumaMovimientos MONEY
				, @SaldoInteresesCorrientes MONEY
				, @SaldoInteresMoratorios MONEY
				, @PagoAcumuladosDelPeriodo MONEY  --Tambien es [SumaDePagos] del EC
				--Son del EC ;
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

		--Primero obtengamos el TCM asociado al TF
		SELECT @IdTarjeta = TF.IdTarjeta
		FROM [dbo].[TarjetaFisica] TF
		WHERE TF.Numero = @InNumeroTarjeta;
		
		
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



		--Ahora Obtengamos los datos necesarios de la TCM con los que se trabajará
		
		SET @SumaMovimientos = 0; --estos son los movimientos en transito 

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
			   ,@TCMQDeCreditos =EC.CantidadDeCreditos
		FROM dbo.EstadoDeCuenta EC 
		WHERE EC.IdTCM = @IdTCM;

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
			WHERE EA.IdTCA = @IdTCA;
		END; 

		--Saquemos las fechas de la TF
		SELECT @FechaCreacionTF = TF.FechaCreacion
		FROM dbo.TarjetaFisica TF
		WHERE TF.Numero = @InNumeroTarjeta

		--la funcion COALESCE elige el primer no nulo de los dos
		SELECT @FechaMuerteTF = COALESCE(TF.FechaInvalidacion, TF.FechaVencimiento)
		FROM dbo.TarjetaFisica TF
		WHERE TF.Numero = @InNumeroTarjeta;

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
		INNER JOIN [dbo].[EstadoDeCuenta] EC ON EC.IdTCM = @IdTCM
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
		FROM @MovimientosTCM T
		WHERE T.Id = @lo;


		IF(@FechaMovimiento < @FechaCreacionTF OR @FechaMovimiento > @FechaMuerteTF)
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
				   , @NombreMovimiento = TV.Nombre
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