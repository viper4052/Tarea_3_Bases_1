USE [tarea3BD]
DECLARE  @MainXml TABLE
	(
		XmlCol XML
	);

	--Metemos el  XML a la tabla variable 
	INSERT INTO @MainXml(XmlCol)
	SELECT BulkColumn
	FROM OPENROWSET
	(
		BULK 'C:\prueba\tb3\Operaciones.xml'
		, SINGLE_BLOB
	)
	AS x;


DECLARE @FechasDeOperacion TABLE
	(
		Id INT IDENTITY(1,1) NOT NULL
		, FechaOperacion DATE NOT NULL
		, XmlCol XML NOT NULL
	
	)

	INSERT INTO @FechasDeOperacion (FechaOperacion, XmlCol)
	SELECT 
		result.FechaOperacion,
		result.XmlFragment
	FROM @MainXml
	CROSS APPLY 
	(
		SELECT
			FechaOperacion = operacion.value('@Fecha', 'DATE'),
			XmlFragment = operacion.query('.')
		FROM XmlCol.nodes('root/fechaOperacion') AS T(operacion)
	) AS result;


DECLARE @MovsDiarios MovimientosDiarios;

INSERT INTO @MovsDiarios
    SELECT 
		ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS Id
        , result.Nombre
		, result.TarjetaFisica
		, result.FechaMovimiento
		, result.Monto
		, result.Descripcion
		, result.Referencia
    FROM @FechasDeOperacion F
    CROSS APPLY 
    (
        SELECT
            Nombre = z.value('@Nombre', 'VARCHAR(64)'),
			TarjetaFisica = z.value('@TF', 'BIGINT'),
			FechaMovimiento = z.value('@FechaMovimiento', 'DATE'),
            Monto = z.value('@Monto', 'MONEY'),
			Descripcion = z.value('@Descripcion', 'VARCHAR(256)'),
			Referencia = z.value('@Referencia', 'VARCHAR(32)')			
        FROM XmlCol.nodes('fechaOperacion/Movimiento/Movimiento') AS T(z)
    ) AS result
    WHERE F.Id = 7

	DECLARE @ResultCode INT 
			, @NumeroTarjeta BIGINT
			, @FechaHoy DATE;

	SET @NumeroTarjeta = 9544162405780883; 
	SET @FechaHoy = '2024-01-15';


EXEC ELSTOREPROCEDURE @ResultCode --este es el SP que se encarga de todo lo referente a la TCM
					   , @MovsDiarios  
					   , @NumeroTarjeta 
					   , @FechaHoy


/*

	DECLARE @Rotulo VARCHAR(128);


	SET @Rotulo ='SIGAMOS CON EL SIGUIENTE'
	SET @FechaHoy = '2024-01-08';

	SELECT @Rotulo;


EXEC ELSTOREPROCEDURE @ResultCode --este es el SP que se encarga de todo lo referente a la TCM
					   , @MovsDiarios2  
					   , @NumeroTarjeta 
					   , @FechaHoy


*/