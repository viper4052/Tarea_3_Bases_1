USE [tarea3BD]


BEGIN TRY 
BEGIN TRANSACTION 

CREATE TABLE TipoDocumentoIdentidad(
    Id INT PRIMARY KEY IDENTITY(1,1) NOT NULL
	, Nombre VARCHAR(128)NOT NULL 
	, Formato VARCHAR(32) NOT NULL
);

CREATE TABLE MotivoInvalidacionTarjeta(
    Id INT PRIMARY KEY IDENTITY(1,1) NOT NULL
	, Nombre VARCHAR(32)NOT NULL 
);

CREATE TABLE TipoTarjetaCreditoMaestra(
    Id INT PRIMARY KEY IDENTITY(1,1) NOT NULL
	, Nombre VARCHAR(32)NOT NULL 
);


CREATE TABLE TipoDeUsuario(
    Id INT PRIMARY KEY IDENTITY(1,1) NOT NULL
	, Nombre VARCHAR(32)NOT NULL 
);


CREATE TABLE Usuarios (
	Id INT PRIMARY KEY IDENTITY(1,1) NOT NULL
	, IdTipoDeUsuario INT NOT NULL
	, Nombre VARCHAR(128) NOT NULL UNIQUE 
	, Contraseña VARCHAR(128) NOT NULL
	, CONSTRAINT FK_Usuarios_IdTipoDeUsuario FOREIGN KEY (IdTipoDeUsuario) REFERENCES TipoDeUsuario(Id)
);



CREATE TABLE TarjetaHabiente(
    Id INT PRIMARY KEY IDENTITY(1,1) NOT NULL
	, IdUsuario INT NOT NULL 
	, IdTipoDocumentoIdentidad INT NOT NULL 
	, Nombre VARCHAR(128) NOT NULL UNIQUE 
	, FechaNacimiento DATE NOT NULL
	, ValorDocumentoIdentidad INT NOT NULL UNIQUE 
	, CONSTRAINT FK_TarjetaHabiente_IdTipoDocumentoIdentidad FOREIGN KEY (IdTipoDocumentoIdentidad) REFERENCES TipoDocumentoIdentidad(Id)
	, CONSTRAINT FK_TarjetaHabiente_IdUsuario FOREIGN KEY (IdUsuario) REFERENCES Usuarios(Id)
);






CREATE TABLE TarjetaCredito(
    Id INT PRIMARY KEY IDENTITY(1,1) NOT NULL
	, FechaCreacion DATE NOT NULL 
	, Codigo INT NOT NULL UNIQUE 
);
CREATE INDEX idx_TarjetaCredito_Codigo ON TarjetaCredito (Codigo);



CREATE TABLE TarjetaCreditoMaestra(
    IdTarjeta INT PRIMARY KEY NOT NULL
	, IdTarjetaHabiente INT NOT NULL
	, IdTipoTCM INT NOT NULL
	, LimiteCredito MONEY NOT NULL 
	, SaldoActual MONEY NOT NULL DEFAULT 0.0
	, SumaDeMovimientosEnTransito MONEY NOT NULL DEFAULT 0.0
	, SaldoInteresesCorrientes MONEY NOT NULL DEFAULT 0.0
	, SaldoInteresMoratorios MONEY NOT NULL DEFAULT 0.0
	, SaldoPagoMinimo MONEY NOT NULL DEFAULT 0.0
	, PagoAcumuladosDelPeriodo MONEY NOT NULL DEFAULT 0.0

	, CONSTRAINT FK_TarjetaCreditoMaestra_IdTipoTCM FOREIGN KEY (IdTipoTCM) REFERENCES TipoTarjetaCreditoMaestra(Id)
	, CONSTRAINT FK_TarjetaCreditoMaestra_IdTarjeta FOREIGN KEY (IdTarjeta) REFERENCES TarjetaCredito(Id)
	, CONSTRAINT FK_TarjetaCreditoMaestra_IdTarjetaHabiente FOREIGN KEY (IdTarjetaHabiente) REFERENCES TarjetaHabiente(Id)
);



CREATE TABLE TarjetaCreditoAdicional(
    IdTarjeta INT PRIMARY KEY NOT NULL
	, IdTarjetaHabiente INT NOT NULL
	, IdTCM INT NOT NULL

	, CONSTRAINT FK_TarjetaCreditoAdicional_IdTCM FOREIGN KEY (IdTCM) REFERENCES TarjetaCreditoMaestra(IdTarjeta)
	, CONSTRAINT FK_TarjetaCreditoAdicional_IdTarjeta FOREIGN KEY (IdTarjeta) REFERENCES TarjetaCredito(Id)
	, CONSTRAINT FK_TarjetaCreditoAdicional_IdTarjetaHabiente FOREIGN KEY (IdTarjetaHabiente) REFERENCES TarjetaHabiente(Id)
);


CREATE TABLE TarjetaFisica(
    Id INT PRIMARY KEY IDENTITY(1,1)  NOT NULL
	, IdMotivoInvalidacion INT NOT NULL
	, IdTarjeta INT NOT NULL
	, Numero INT NOT NULL 
	, CVV INT NOT NULL
	, Pin INT NOT NULL 
	, FechaCreacion DATE NOT NULL
	, FechaVencimiento DATE NOT NULL
	, EsValida BIT DEFAULT 1

	, CONSTRAINT FK_TarjetaFisica_IdMotivoInvalidacion FOREIGN KEY (IdMotivoInvalidacion) REFERENCES MotivoInvalidacionTarjeta(Id)
	, CONSTRAINT FK_TarjetaFisica_IdTarjeta FOREIGN KEY (IdTarjeta) REFERENCES TarjetaCredito(Id)
);

CREATE TABLE TipoDeReglas(
    Id INT PRIMARY KEY IDENTITY(1,1) NOT NULL
	, Nombre VARCHAR(128)NOT NULL 
	, tipo VARCHAR(32) NOT NULL
);



CREATE TABLE ReglasDeNegocio(
    Id INT PRIMARY KEY IDENTITY(1,1) NOT NULL
	, IdTipoDeRegla INT NOT NULL
	, IdTipoDeTCM INT NOT NULL
	, Nombre VARCHAR(128)NOT NULL
);


CREATE TABLE RNTasa(
    IdReglaNegocio INT PRIMARY KEY NOT NULL
	, Valor REAL NOT NULL

	, CONSTRAINT FK_RNTasa_IdReglaNegocio FOREIGN KEY (IdReglaNegocio) REFERENCES ReglasDeNegocio(Id)
);


CREATE TABLE RNQMeses(
    IdReglaNegocio INT PRIMARY KEY NOT NULL
	, Valor INT NOT NULL

	, CONSTRAINT FK_RNQMeses_IdReglaNegocio FOREIGN KEY (IdReglaNegocio) REFERENCES ReglasDeNegocio(Id)
);


CREATE TABLE RNQDias(
    IdReglaNegocio INT PRIMARY KEY NOT NULL
	, Valor INT NOT NULL

	, CONSTRAINT FK_RNQDias_IdReglaNegocio FOREIGN KEY (IdReglaNegocio) REFERENCES ReglasDeNegocio(Id)
);

CREATE TABLE RNQOperaciones(
    IdReglaNegocio INT PRIMARY KEY NOT NULL
	, Valor INT NOT NULL

	, CONSTRAINT FK_RNQOperaciones_IdReglaNegocio FOREIGN KEY (IdReglaNegocio) REFERENCES ReglasDeNegocio(Id)
);


CREATE TABLE RNMonto(
    IdReglaNegocio INT PRIMARY KEY NOT NULL
	, Valor MONEY NOT NULL

	, CONSTRAINT FK_RNMonto_IdReglaNegocio FOREIGN KEY (IdReglaNegocio) REFERENCES ReglasDeNegocio(Id)
);




--AHORA LAS TABLAS REFERENTES A MOVIMIENTOS Y ESTADOS DE CUENTA
CREATE TABLE EstadoDeCuenta(
    Id INT PRIMARY KEY IDENTITY(1,1) NOT NULL
	, FechaInicio DATE NOT NULL
	, FechaFin DATE NOT NULL
	, SaldoActual MONEY NOT NULL
	, PagoMinimoMesAnterior MONEY NOT NULL
	, FechaParaPagoMinimo DATE NOT NULL
	, InteresesMoratorios MONEY NOT NULL
	, InteresesCorrientes MONEY NOT NULL
	, CantidadOperacionesATM INT NOT NULL
	, CantidadOperacionesVentana INT NOT NULL
	, SumaDePagos MONEY NOT NULL
	, CantidadDePagos Int NOT NULL
	, SumaDeCompras MONEY NOT NULL
	, CantidadDeCompras INT NOT NULL
	, SumaDeRetiros MONEY NOT NULL
	, CantidadDeRetiros INT NOT NULL
	, SumaDeCreditos MONEY NOT NULL
	, CantidadDeCreditos INT NOT NULL
	, SumaDeDebitos MONEY NOT NULL
	, CantidadDeDebitos INT NOT NULL
);



CREATE TABLE TiposDeMovimiento(
    Id INT PRIMARY KEY IDENTITY(1,1) NOT NULL
	, Nombre VARCHAR(32)NOT NULL
	, Accion VARCHAR(32)NOT NULL
	, AcumulaOperacionATM BIT NOT NULL
	, AcumulaOperacionVentana BIT NOT NULL
);

CREATE TABLE Movimientos(
    Id INT PRIMARY KEY IDENTITY(1,1) NOT NULL
	, IdTipoDeMovimiento INT NOT NULL
	, IdEstadoDeCuenta INT NOT NULL
	, Fecha DATETIME NOT NULL
	, Monto MONEY NOT NULL
	, Descripcion VARCHAR(256) NOT NULL 
	, Referencia VARCHAR(32)NOT NULL

	
	, CONSTRAINT FK_Movimientos_IdTipoDeMovimiento FOREIGN KEY (IdTipoDeMovimiento) REFERENCES TiposDeMovimiento(Id)
	, CONSTRAINT FK_Movimientos_IdEstadoDeCuenta FOREIGN KEY (IdEstadoDeCuenta) REFERENCES EstadoDeCuenta(Id)
);



CREATE TABLE MovimientosConTF(
    IdMovimiento INT PRIMARY KEY NOT NULL
	, IdTarjetaFisica INT NOT NULL

	, CONSTRAINT FK_MovimientosConTF_IdMovimiento FOREIGN KEY (IdMovimiento) REFERENCES Movimientos(Id)
	, CONSTRAINT FK_MovimientosConTF_IdTarjetaFisica FOREIGN KEY (IdTarjetaFisica) REFERENCES TarjetaFisica(Id)
);

CREATE TABLE MovimientoSospechoso(
    Id INT PRIMARY KEY IDENTITY(1,1) NOT NULL
	, IdTipoDeMovimiento INT NOT NULL
	, Fecha DATETIME NOT NULL
	, Monto MONEY NOT NULL
	, Descripcion VARCHAR(256) NOT NULL 
	, Referencia VARCHAR(32)NOT NULL

	
	, CONSTRAINT FK_MovimientoSospechoso_IdTipoDeMovimiento FOREIGN KEY (IdTipoDeMovimiento) REFERENCES TiposDeMovimiento(Id)
);


CREATE TABLE MovimientosTCM(
    IdMovimiento INT PRIMARY KEY NOT NULL
	, IdTarjetaCreditoMaestra INT NOT NULL

	, CONSTRAINT FK_MovimientosTCM_IdMovimiento FOREIGN KEY (IdMovimiento) REFERENCES Movimientos(Id)
	, CONSTRAINT FK_MovimientosTCM_IdTarjetaFisica FOREIGN KEY (IdTarjetaCreditoMaestra) REFERENCES TarjetaCreditoMaestra(IdTarjeta)
);


CREATE TABLE MovimientosTCA(
    IdMovimiento INT PRIMARY KEY NOT NULL
	, IdTarjetaCreditoAdicional INT NOT NULL

	, CONSTRAINT FK_MovimientosTCA_IdMovimiento FOREIGN KEY (IdMovimiento) REFERENCES Movimientos(Id)
	, CONSTRAINT FK_MovimientosTCA_IdTarjetaCreditoAdicional FOREIGN KEY (IdTarjetaCreditoAdicional) REFERENCES TarjetaCreditoAdicional(IdTarjeta)
);



CREATE TABLE TiposDeMovimientoCorrientes(
    Id INT PRIMARY KEY IDENTITY(1,1) NOT NULL
	, Tipo VARCHAR(32)NOT NULL
);


CREATE TABLE MovimientosInteresesCorrientes(
    Id INT PRIMARY KEY IDENTITY(1,1) NOT NULL
	, IdTipoDeMovimientoCorriente INT NOT NULL
	, IdEstadoDeCuenta INT NOT NULL
	, Fecha DATETIME NOT NULL
	, Monto MONEY NOT NULL

	, CONSTRAINT FK_MovimientosInteresesCorrientes_IdEstadoDeCuenta FOREIGN KEY (IdEstadoDeCuenta) REFERENCES EstadoDeCuenta(Id)
	, CONSTRAINT FK_MovimientosInteresesCorrientes_IdTipoDeMovimiento FOREIGN KEY (IdTipoDeMovimientoCorriente) REFERENCES TiposDeMovimientoCorrientes(Id)
);




CREATE TABLE TiposDeMovimientoMoratorios(
    Id INT PRIMARY KEY IDENTITY(1,1) NOT NULL
	, Tipo VARCHAR(32)NOT NULL
);


CREATE TABLE MovimientosInteresesMortatorios(
    Id INT PRIMARY KEY IDENTITY(1,1) NOT NULL
	, IdTipoDeMovimientoMoratorio INT NOT NULL
	, IdEstadoDeCuenta INT NOT NULL
	, Fecha DATETIME NOT NULL
	, Monto MONEY NOT NULL

	, CONSTRAINT FK_MovimientosInteresesMortatorios_IdEstadoDeCuenta FOREIGN KEY (IdEstadoDeCuenta) REFERENCES EstadoDeCuenta(Id)
	, CONSTRAINT FK_MovimientosInteresesMortatorios_IdTipoDeMovimientoMoratorio FOREIGN KEY (IdTipoDeMovimientoMoratorio) REFERENCES TiposDeMovimientoMoratorios(Id)
);


COMMIT TRANSACTION
END TRY 

BEGIN CATCH
	IF @@TRANCOUNT >0
	BEGIN 
		ROLLBACK;
	END

	DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;
    DECLARE @ErrorLine INT;

    SELECT 
        @ErrorMessage = ERROR_MESSAGE(),
        @ErrorSeverity = ERROR_SEVERITY(),
        @ErrorState = ERROR_STATE(),
        @ErrorLine = ERROR_LINE();  -- Captura el número de línea

    -- Muestra el mensaje de error
    PRINT 'Error: ' + @ErrorMessage;
    PRINT 'Severity: ' + CAST(@ErrorSeverity AS NVARCHAR(10));
    PRINT 'State: ' + CAST(@ErrorState AS NVARCHAR(10));
    PRINT 'Line: ' + CAST(@ErrorLine AS NVARCHAR(10));  -- Muestra 



END CATCH 