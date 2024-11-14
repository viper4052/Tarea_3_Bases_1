CREATE PROCEDURE [dbo].[ObtieneEstadoDeCuenta]
	@OutResultCode INT OUTPUT
	, @InUsername VARCHAR(128)
AS
BEGIN
	SET NOCOUNT ON;
	SET @OutResultCode = 0;
	SELECT @OutResultCode AS OutResultCode;

	BEGIN
		SELECT * FROM [dbo].[VistaEstadoDeCuenta] E
		INNER JOIN [dbo].[TarjetaCreditoMaestra] M
		ON E.IdTCM = M.IdTarjeta
	END

	SET NOCOUNT OFF;
END
RETURN 0
