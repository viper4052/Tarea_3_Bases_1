USE [tarea3BD]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
    Con base en datos para crear un tarjeta habiente tambien se creara 
    su usuario pertinente este sera de tipo tarjeta habiente 
--  Descripcion de parametros: 
--  @outResultCode: codigo de resultado de ejecucion. 0 Corrio sin errores, 
valores que se insertaran
--  @NombreTarjetaHabiente
--  @ValorDocIdentidad
--  @FechaNacimiento
--  @Username
--  @contraseña
*/

ALTER PROCEDURE [dbo].[InsertarTarjetaHabiente]
    @OutResulTCode INT OUTPUT
    , @InNombreTarjetaHabiente VARCHAR(32)
    , @InValorDocIdentidad VARCHAR(32)
    , @InFechaNacimiento DATE
    , @InUsername VARCHAR(32)
    , @InContraseña VARCHAR(32)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SET @OutResulTCode = 0;
        -- Variables de inserción 
        DECLARE @IdUser INT
        
        BEGIN TRANSACTION
        INSERT INTO dbo.Usuarios
        (
            IdTipoDeUsuario
            , Nombre
            , Contraseña
        )
        VALUES
        (
            2   --este es el id de los tarjeta habientes 
            , @InUsername
            , @Incontraseña
        )
        
        SET @IdUser = SCOPE_IDENTITY();
        INSERT INTO [dbo].[TarjetaHabiente]
        (
            IdUsuario
            , IdTipoDocumentoIdentidad
            , Nombre
            , FechaNacimiento
            , ValorDocumentoIdentidad
        )
        VALUES
        (
            @IdUser
            , 1
            , @InNombreTarjetaHabiente
            , @InFechaNacimiento
            , @InValorDocIdentidad
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