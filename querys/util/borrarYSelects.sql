USE [tarea3BD]


-- SELECT statements
SELECT * FROM dbo.DBError;

SELECT * FROM [dbo].[EstadoDeCuenta];
SELECT * FROM dbo.EstadoDeCuentaAdicional
SELECT * FROM [dbo].[MotivoInvalidacionTarjeta];
SELECT * FROM [dbo].[Movimientos];
SELECT * FROM [dbo].[MovimientosConTF];
SELECT * FROM [dbo].[MovimientosInteresesCorrientes];
SELECT * FROM [dbo].[MovimientosInteresesMortatorios];
SELECT * FROM [dbo].[MovimientoSospechoso];
SELECT * FROM [dbo].[MovimientosTCA];
SELECT * FROM [dbo].[MovimientosTCM];
SELECT * FROM [dbo].[ReglasDeNegocio];
SELECT * FROM [dbo].[RNMonto];
SELECT * FROM [dbo].[RNQDias];
SELECT * FROM [dbo].[RNQAños];
SELECT * FROM [dbo].[RNQMeses];
SELECT * FROM [dbo].[RNQOperaciones];
SELECT * FROM [dbo].[RNTasa];
SELECT * FROM [dbo].[TarjetaCredito];
SELECT * FROM [dbo].[TarjetaCreditoAdicional];
SELECT * FROM [dbo].[TarjetaCreditoMaestra];
SELECT * FROM [dbo].[TarjetaFisica];
SELECT * FROM [dbo].[TarjetaHabiente];
SELECT * FROM [dbo].[TipoDeReglas];
SELECT * FROM [dbo].[TipoDeUsuario];
SELECT * FROM [dbo].[TipoDocumentoIdentidad];
SELECT * FROM [dbo].[TiposDeMovimiento];
SELECT * FROM [dbo].[TiposDeMovimientoCorrientes];
SELECT * FROM [dbo].[TiposDeMovimientoMoratorios];
SELECT * FROM [dbo].[TipoTarjetaCreditoMaestra];
SELECT * FROM [dbo].[Usuarios];

DELETE FROM dbo.DBError; 
DELETE FROM [dbo].[EstadoDeCuenta];
DELETE FROM [dbo].[EstadoDeCuentaAdicional];
DELETE FROM [dbo].[MotivoInvalidacionTarjeta];
DELETE FROM [dbo].[Movimientos];
DELETE FROM [dbo].[MovimientosConTF];
DELETE FROM [dbo].[MovimientosInteresesCorrientes];
DELETE FROM [dbo].[MovimientosInteresesMortatorios];
DELETE FROM [dbo].[MovimientoSospechoso];
DELETE FROM [dbo].[MovimientosTCA];
DELETE FROM [dbo].[MovimientosTCM];
DELETE FROM [dbo].[RNMonto];
DELETE FROM [dbo].[RNQDias];
DELETE FROM [dbo].[RNQMeses];
DELETE FROM [dbo].[RNQAños]
DELETE FROM [dbo].[RNQOperaciones];
DELETE FROM [dbo].[RNTasa];
DELETE FROM [dbo].[TipoTarjetaCreditoMaestra];
DELETE FROM [dbo].[ReglasDeNegocio];
DELETE FROM [dbo].[TarjetaFisica];
DELETE FROM [dbo].[TarjetaCreditoAdicional];
DELETE FROM [dbo].[TarjetaCreditoMaestra];
DELETE FROM [dbo].[TarjetaCredito];
DELETE FROM [dbo].[TarjetaHabiente];
DELETE FROM [dbo].[TipoDeReglas];
DELETE FROM [dbo].[Usuarios];
DELETE FROM [dbo].[TipoDeUsuario];
DELETE FROM [dbo].[TipoDocumentoIdentidad];
DELETE FROM [dbo].[TiposDeMovimiento];
DELETE FROM [dbo].[TiposDeMovimientoCorrientes];
DELETE FROM [dbo].[TiposDeMovimientoMoratorios];

DBCC CHECKIDENT ('DBError', RESEED, 0);
DBCC CHECKIDENT ('EstadoDeCuenta', RESEED, 0);
DBCC CHECKIDENT ('EstadoDeCuentaAdicional', RESEED, 0);
DBCC CHECKIDENT ('MotivoInvalidacionTarjeta', RESEED, 0);
DBCC CHECKIDENT ('Movimientos', RESEED, 0);
DBCC CHECKIDENT ('MovimientosInteresesCorrientes', RESEED, 0);
DBCC CHECKIDENT ('MovimientosInteresesMortatorios', RESEED, 0);
DBCC CHECKIDENT ('MovimientoSospechoso', RESEED, 0);
DBCC CHECKIDENT ('ReglasDeNegocio', RESEED, 0);
DBCC CHECKIDENT ('TarjetaCredito', RESEED, 0);
DBCC CHECKIDENT ('TarjetaFisica', RESEED, 0);
DBCC CHECKIDENT ('TarjetaHabiente', RESEED, 0);
DBCC CHECKIDENT ('TipoDeReglas', RESEED, 0);
DBCC CHECKIDENT ('TipoDeUsuario', RESEED, 0);
DBCC CHECKIDENT ('TipoDocumentoIdentidad', RESEED, 0);
DBCC CHECKIDENT ('TiposDeMovimiento', RESEED, 0);
DBCC CHECKIDENT ('TiposDeMovimientoCorrientes', RESEED, 0);
DBCC CHECKIDENT ('TiposDeMovimientoMoratorios', RESEED, 0);
DBCC CHECKIDENT ('TipoTarjetaCreditoMaestra', RESEED, 0);
DBCC CHECKIDENT ('Usuarios', RESEED, 0);




SELECT TM.Nombre, * FROM [dbo].[Movimientos] M
INNER JOIN dbo.TiposDeMovimiento  TM ON M.IdTipoDeMovimiento = TM.Id;



SELECT * FROM [dbo].[EstadoDeCuenta]
WHERE IdTCM = 3;
SELECT * FROM dbo.TarjetaCreditoMaestra
WHERE IdTarjeta =3;

UPDATE EstadoDeCuenta 
SET InteresesCorrientes = 0
, CantidadOperacionesATM = 0 
, CantidadOperacionesVentana = 0
, SumaDePagos = 0 
, CantidadDePagos = 0 
, SumaDeRetiros = 0 
, SumaDeCreditos = 0
, CantidadDeRetiros = 0
,CantidadDeCreditos= 0 
, SumaDeDebitos = 0
, CantidadDeDebitos = 0 
WHERE id = 3


UPDATE dbo.TarjetaCreditoMaestra
SET SaldoActual = 0
, SumaDeMovimientosEnTransito = 0
, SaldoInteresesCorrientes = 0, 
SaldoInteresMoratorios  = 0
, PagoAcumuladosDelPeriodo = 0
WHERE IdTarjeta = 3
