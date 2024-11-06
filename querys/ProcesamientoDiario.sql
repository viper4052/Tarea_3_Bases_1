USE [tarea3BD]
GO
    
/* En este script primero se realizara la creacion de tarjeta habientes, tarjetas fisicas,
TCM, TCA y luego ya se hara el procesamiento de cada tcm y sus distintos movientos e 
intereses*/


--Primero la declaracion de algunas variables que se usaran a lo largo del script

	DECLARE @Hi INT
			,@Lo INT;


-- Hacemos la tabla variable, funcionara para extraer todos los datos
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

--Ya que extrajimos todos los datos ahora 
--Creemos una tabla variable en la que se separe por fechas de operacion 


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


--Con base en esta tabla variable haremos el procesamiento diario
	SELECT @hi = MAX(Id)
	FROM @FechasDeOperacion; --seleccionamos el tamaño de @@FechasDeOperacion
	        
	SET @lo = 1;




	--Declaramos la tabla donde vamos a insertar los 
	--Tarjetahabientes a procesar; 
	DECLARE @TarjetaHabientes TABLE
	(
		Id INT NOT NULL
		, Nombre VARCHAR(32) NOT NULL
		, ValorDocIdentidad VARCHAR(32) NOT NULL
		, FechaNacimiento DATE NOT NULL
		, Username VARCHAR(32)  NOT NULL
		, contraseña VARCHAR(32)  NOT NULL
	)

-- Dentro de este while se manipulara cada una de las fechas:  
	WHILE (@lo <= @hi)
	BEGIN 
	
	
	----Primero hagamos la creacion de nuevos tarjeta habientes
	INSERT INTO @TarjetaHabientes 
    SELECT 
		ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS Id
        , result.Nombre
		, result.ValorDocIdentidad
		, result.FechaNacimiento
		, result.Username
		, result.Contraseña
    FROM @FechasDeOperacion F
    CROSS APPLY 
    (
        SELECT
            Nombre = z.value('@Nombre', 'VARCHAR(32)'),
            ValorDocIdentidad = z.value('@ValorDocIdentidad', 'VARCHAR(32)'),
            FechaNacimiento = z.value('@FechaNacimiento', 'DATE'),
            Username = z.value('@NombreUsuario', 'VARCHAR(32)'),
            Contraseña = z.value('@Password', 'VARCHAR(32)')
        FROM XmlCol.nodes('fechaOperacion/NTH/NTH') AS T(z)
    ) AS result
    WHERE F.Id = @lo;
	

	--Empecemos el nuevo loop para ejecutar el SP de insercion
	DECLARE @loopI INT
			, @NombreTarjetaHabiente VARCHAR(32) 
			, @ValorDocIdentidad VARCHAR(32)
			, @FechaNacimiento DATE
			, @Username VARCHAR(32)
			, @contraseña VARCHAR(32);
	
	SET @loopI = 1; 

	WHILE (@loopI <= (SELECT MAX(ID)
					 FROM @TarjetaHabientes))
	BEGIN 
		
		SELECT @NombreTarjetaHabiente = TH.Nombre
			   , @ValorDocIdentidad = TH.ValorDocIdentidad
			   , @FechaNacimiento = TH.FechaNacimiento
			   , @Username = TH.Username 
			   , @contraseña = TH.contraseña
		FROM @TarjetaHabientes TH
		WHERE TH.Id = @loopI;

		EXEC InsertarTarjetaHabiente 0
									 , @NombreTarjetaHabiente 
									 , @ValorDocIdentidad
									 , @FechaNacimiento
									 , @Username
									 , @contraseña
		
		
		SET @loopI += 1;
	END;  

	
	
	SET @lo += 1;
	END;




