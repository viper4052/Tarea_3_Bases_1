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
			, IdEstadoDeCuenta INT NOT NULL
			, Fecha DATE NOT NULL 
			, Monto MONEY NOT NULL
			, Descripcion VARCHAR(256)
			, Referencia VARCHAR(32)
			, IdTarjetaCreditoMaestra INT NOT NULL
		);

        DECLARE @IdTCM INT
				, @IdTCA INT
				, @IdTarjeta INT
				, @hi INT
				, @lo INT
				, @FechaMovimiento DATE
				, @FechaCreacionTF DATE
				, @FechaMuerteTF DATE
				, @SaldoActual MONEY;

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


		--Primero saquemos los movimientos que vamos a procesar 	

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
	
	
--Ya que tenemos los movimientos en su tabla variable toca depurarlos 
--para ello se desecharan los movimientos sospechosos y tambien
--se les añadira el nuevo saldo 

	--Primero Obtengamos el Saldo Actual: 

	SELECT @SaldoActual = TM.SaldoActual
	FROM dbo.TarjetaCreditoMaestra TM
	WHERE TM.IdTarjeta = @IdTCM;
	
	SELECT @hi = MAX(id)
	FROM @MovimientosTCM

	SET @lo = 1; 


	SELECT @FechaCreacionTF = TF.FechaCreacion
	FROM dbo.TarjetaFisica TF
	WHERE TF.Numero = @InNumeroTarjeta

	--la funcion COALESCE elige el primer no nulo de los dos
	SELECT @FechaMuerteTF = COALESCE(TF.FechaInvalidacion, TF.FechaVencimiento)
	FROM dbo.TarjetaFisica TF
	WHERE TF.Numero = @InNumeroTarjeta;


	WHILE (@lo <= @hi) 
	BEGIN
		
		SELECT @FechaMovimiento = T.Fecha
		FROM @MovimientosTCM T
		WHERE T.Id = @lo;

		IF(@FechaMovimiento <= @FechaCreacionTF OR @FechaMovimiento >= @FechaMuerteTF)
		BEGIN
			--Se marca como Sospechoso 
			UPDATE @MovimientosTCM
			SET EsSus = 1
			WHERE Id = @lo;
		END
		ELSE
		BEGIN 
			--Actualizamos el Saldo en la tabla variable
			SELECT @SaldoActual = (M.Monto + @SaldoActual)
			FROM @MovimientosTCM M
			WHERE M.Id = @lo;

			UPDATE @MovimientosTCM
			SET NuevoSaldo = @SaldoActual
			WHERE Id = @lo;
		END; 
	END;
	
	
	SELECT * FROM @MovimientosTCM; 

        

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