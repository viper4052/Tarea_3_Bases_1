USE [tarea3BD]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
    Se encarga de crear una nuev TCM 
	crea tambien un nuevo TC asociado a ella junto con su primer estado de cuenta
--  Descripcion de parametros: 
--  @outResultCode: codigo de resultado de ejecucion. 0 Corrio sin errores, 
valores que se insertaran
--  @InCodigo
--  @InTipoTCM
--  @InLimiteCredito
--  @InTarjetaHabiente
--  @contraseña
*/

ALTER PROCEDURE [dbo].[CrearTCM]
    @OutResulTCode INT OUTPUT
    , @InCodigo INT
    , @InTipoTCM VARCHAR(16)
    , @InLimiteCredito VARCHAR(16)
    , @InTarjetaHabiente VARCHAR(32)
	, @InFecha DATE 
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SET @OutResulTCode = 0;
        -- Variables de inserción 
        DECLARE @IdTarjeta INT
				, @IdTipoTCM INT
				, @IdTarjetaHabiente INT
				, @IdTCM INT
				, @FechaPagoMinimo DATE
				, @FechaDeCierre DATE
				, @IdReglaDeNegocio INT
				, @QDias INT;

		
        
		--preprocesamos el tipo de TCM
		SELECT @IdTipoTCM = T.Id
		FROM dbo.TipoTarjetaCreditoMaestra T
		WHERE T.Nombre = @InTipoTCM

		--preprocesamos el tipo id del TH
		SELECT @IdTarjetaHabiente = T.Id
		FROM dbo.TarjetaHabiente T
		WHERE T.ValorDocumentoIdentidad = @InTarjetaHabiente
		@IdTarjetaHabiente
		--Preprocesamos cantidad de dias para pago minimo

		SELECT @IdReglaDeNegocio = R.Id 
		FROM dbo.ReglasDeNegocio R
		WHERE R.Nombre = 'Cantidad de dias para pago saldo'
		AND R.IdTipoDeTCM = @IdTipoTCM; 

		SET @QDias = (SELECT R.Valor
					  FROM dbo.RNQDias R
					  WHERE R.IdReglaNegocio = @IdReglaDeNegocio);

		--preprocesamos Fecha de cierre y de pago minimo
		SET @FechaDeCierre = dbo.FechaDeCierre(@InFecha);
		SET @FechaPagoMinimo = DATEADD(DAY, @QDias, @FechaDeCierre);

		

        BEGIN TRANSACTION
        INSERT INTO [dbo].[TarjetaCredito]
        (
			FechaCreacion
			, Codigo
        )
        VALUES
        (
            @InFecha
			, @InCodigo
        )
        
        SET @IdTarjeta = SCOPE_IDENTITY();
        INSERT INTO [dbo].[TarjetaCreditoMaestra]
        (
            IdTarjeta
			, IdTarjetaHabiente
			, IdTipoTCM
			, LimiteCredito
			, SaldoActual
			, SumaDeMovimientosEnTransito
			, SaldoInteresesCorrientes
			, SaldoInteresMoratorios
			, SaldoPagoMinimo
			, PagoAcumuladosDelPeriodo
        )
        VALUES
        (
            @IdTarjeta
            , @IdTarjetaHabiente
            , @IdTipoTCM
            , CONVERT(MONEY, @InLimiteCredito)
            , 0
			, 0
			, 0
			, 0
			, 0
			, 0
        )

		SET @IdTCM = SCOPE_IDENTITY();
		--Ya que creamos las TCM, generemos su primer inicio de estado de cuenta 

		INSERT INTO [dbo].[EstadoDeCuenta]
        (
            FechaInicio
			, FechaFin
			, PagoMinimoMesAnterior
			, FechaParaPagoMinimo
			, InteresesMoratorios
			, InteresesCorrientes
			, CantidadOperacionesATM
			, CantidadOperacionesVentana
			, SumaDePagos
			, CantidadDePagos
			, SumaDeCompras
			, CantidadDeCompras
			, SumaDeRetiros
			, CantidadDeRetiros
			, SumaDeCreditos
			, CantidadDeCreditos
			, SumaDeDebitos
			, CantidadDeDebitos
			, IdTCM
			, PagoDeContado
        )
        VALUES
        (
            @InFecha
            , @FechaDeCierre
            , 0
            , @FechaPagoMinimo
            , 0
			, 0
			, 0
			, 0
			, 0
			, 0
			, 0
			, 0
			, 0
			, 0
			, 0
			, 0
			, 0
			, 0
			, @IdTCM
			, 0
        )
        COMMIT TRANSACTION;
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