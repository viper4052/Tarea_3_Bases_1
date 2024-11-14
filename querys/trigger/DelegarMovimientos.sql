CREATE TRIGGER trigger_DelegarMovimientos
ON [dbo].[MovimientosConTF]
AFTER INSERT
AS
BEGIN


    INSERT INTO MovimientosTCM
    (
        IdMovimiento,
        IdTarjetaCreditoMaestra,
        FechaMovimiento
    )
    SELECT I.IdMovimiento,
           TF.IdTarjeta,
           I.Fecha
    FROM inserted I
    INNER JOIN dbo.TarjetaFisica TF ON I.IdTarjetaFisica = TF.Id
    WHERE EXISTS (
        SELECT 1
        FROM dbo.TarjetaCreditoMaestra TCM
        WHERE TCM.IdTarjeta = TF.IdTarjeta
    );


    INSERT INTO MovimientosTCA
    (
        IdMovimiento,
        IdTarjetaCreditoAdicional,
        FechaMovimiento
    )
    SELECT I.IdMovimiento,
           TF.IdTarjeta,
           I.Fecha
    FROM inserted I
    INNER JOIN dbo.TarjetaFisica TF ON I.IdTarjetaFisica = TF.Id
    WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.TarjetaCreditoMaestra TCM
        WHERE TCM.IdTarjeta = TF.IdTarjeta
    );
END;
