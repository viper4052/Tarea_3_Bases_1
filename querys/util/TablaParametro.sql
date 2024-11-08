--Tabla que se pasa de parametro al SP de movimientos
CREATE TYPE MovimientosDiarios
AS TABLE
      ( 
	  Id INT NOT NULL
	  , Nombre VARCHAR(64) NOT NULL
      , TarjetaFisica BIGINT NOT NULL
	  , FechaMovimiento DATE NOT NULL
	  , Monto MONEY NOT NULL
	  , Descripcion VARCHAR(256) NOT NULL
	  , Referencia VARCHAR(32) NOT NULL
	  ) ;