USE [tarea3BD]
GO
    
/* En este script primero se realizara la creacion de tarjeta habientes, tarjetas fisicas,
TCM, TCA y luego ya se hara el procesamiento de cada tcm y sus distintos movientos e 
intereses*/


--Primero la declaracion de algunas variables que se usaran a lo largo del script

	DECLARE @Hi INT
			,@Lo INT
			, @ResultCode INT;


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



	DECLARE @FechaHoy DATE;
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


	DECLARE @NuevosTCM TABLE
	(
		Id INT NOT NULL
		, Codigo INT NOT NULL
		, TipoTCM VARCHAR(32)
		, LimiteDeCredito VARCHAR(16) NOT NULL 
		, TarjetaHabiente VARCHAR(32)
	)


	DECLARE @NuevosTCA TABLE
	(
		Id INT NOT NULL
		, CodigoTCM INT NOT NULL
		, CodigoTCA INT NOT NULL
		, TarjetaHabiente VARCHAR(32)
	)

	DECLARE @NuevosTF TABLE
	(
		Id INT NOT NULL
		, FechaVencimiento VARCHAR(8) NOT NULL
		, CCV INT NOT NULL
		, NumeroTarjeta BIGINT NOT NULL
		, CodigoTCA INT NOT NULL

	)

	--Es la tabla de parametros 
	DECLARE @MovsDiarios MovimientosDiarios; 
	

-- Dentro de este while se manipulara cada una de las fechas:  
--############################################################################################################
	WHILE (@lo <= @hi)
	BEGIN 
	
	--primero tengamos guardada la fecha de operacion
	SELECT @FechaHoy = F.FechaOperacion 
	FROM @FechasDeOperacion F
	WHERE @lo = F.id; 

	----Primero hagamos la creacion de nuevos tarjeta habientes
	--############################################################################################################

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
	--############################################################################################################


	--############################################################################################################
	----ahora hagamos la creacion de nuevos TCM
	INSERT INTO @NuevosTCM 
    SELECT 
		ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS Id
        , result.Codigo
		, result.TipoTCM
		, result.LimiteDeCredito
		, result.TarjetaHabiente
    FROM @FechasDeOperacion F
    CROSS APPLY 
    (
        SELECT
            Codigo = z.value('@Codigo', 'INT'),
			TipoTCM = z.value('@TipoTCM', 'VARCHAR(32)'),
            LimiteDeCredito = z.value('@LimiteCredito', 'VARCHAR(16)'),
            TarjetaHabiente = z.value('@TH', 'VARCHAR(32)')
        FROM XmlCol.nodes('fechaOperacion/NTCM/NTCM') AS T(z)
    ) AS result
    WHERE F.Id = @lo;

	--ahora el ciclo para insertarlos

	DECLARE @Codigo INT  
			, @LimiteDeCredito VARCHAR(16)
			, @TipoTCM VARCHAR(32)
			, @TarjetaHabiente VARCHAR(32)

	
	SET @loopI = 1; 
	
	
	WHILE (@loopI <= (SELECT MAX(ID)
					 FROM @NuevosTCM))
	BEGIN 
		SET @ResultCode = 0
		SELECT @TarjetaHabiente = TM.TarjetaHabiente
			   , @Codigo = TM.Codigo
			   , @LimiteDeCredito = TM.LimiteDeCredito
			   , @TipoTCM = TM.TipoTCM 
		FROM @NuevosTCM TM
		WHERE TM.Id = @loopI;

		EXEC CrearTCM @ResultCode
					   , @Codigo 
					   , @TipoTCM
					   , @LimiteDeCredito
					   , @TarjetaHabiente
					   , @FechaHoy


		SET @loopI += 1;
	END;
	--############################################################################################################


	--############################################################################################################
	----ahora hagamos la creacion de nuevos TCA
	INSERT INTO @NuevosTCA
    SELECT 
		ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS Id
        , result.CodigoTCM
		, result.CodigoTCA
		, result.TarjetaHabiente
    FROM @FechasDeOperacion F
    CROSS APPLY 
    (
        SELECT
            CodigoTCM = z.value('@CodigoTCM', 'INT'),
			CodigoTCA = z.value('@CodigoTCA', 'VARCHAR(32)'),
            TarjetaHabiente = z.value('@TH', 'VARCHAR(32)')
        FROM XmlCol.nodes('fechaOperacion/NTCA/NTCA') AS T(z)
    ) AS result
    WHERE F.Id = @lo;

	--ahora el ciclo para insertarlos

	DECLARE @CodigoTCM INT  
			, @CodigoTCA INT;

	SET @ResultCode = 0;
	SET @loopI = 1; 

	WHILE (@loopI <= (SELECT MAX(ID)
					 FROM @NuevosTCA))
	BEGIN 

		SET @ResultCode = 0
		SELECT @CodigoTCA = TA.CodigoTCA
			   , @CodigoTCM = TA.CodigoTCM
			   , @TarjetaHabiente = TA.TarjetaHabiente
		FROM @NuevosTCA TA
		WHERE TA.Id = @loopI;

		EXEC CrearTCA @ResultCode
					   , @CodigoTCA 
					   , @CodigoTCM
					   , @TarjetaHabiente
					   , @FechaHoy


		SET @loopI += 1;
	END;


	--############################################################################################################


	--############################################################################################################
	----ahora hagamos la creacion de nuevos TCA
	----ahora hagamos la creacion de nuevos TCA
	INSERT INTO @NuevosTF
    SELECT 
		ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS Id
        , result.FechaVencimiento
		, result.CCV
		, result.NumeroTarjeta
		, result.CodigoTCA
    FROM @FechasDeOperacion F
    CROSS APPLY 
    (
        SELECT
			NumeroTarjeta = z.value('@Codigo', 'BIGINT'),
			CodigoTCA = z.value('@TCAsociada', 'VARCHAR(32)'),
            FechaVencimiento = z.value('@FechaVencimiento', 'VARCHAR(8)'),
			CCV = z.value('@CCV', 'VARCHAR(32)')
        FROM XmlCol.nodes('fechaOperacion/NTF/NTF') AS T(z)
    ) AS result
    WHERE F.Id = @lo;

	--ahora el ciclo para insertarlos

	DECLARE @CCV INT  
			, @NumeroTarjeta BIGINT
			, @FechaVencimiento VARCHAR(8);

	SET @ResultCode = 0;
	SET @loopI = 1; 

	WHILE (@loopI <= (SELECT MAX(ID)
					 FROM @NuevosTF))
	BEGIN 
		
		SET @ResultCode = 0

		SELECT @CodigoTCA = TF.CodigoTCA
			   , @CCV = TF.CCV
			   , @FechaVencimiento = TF.FechaVencimiento
			   , @NumeroTarjeta = TF.NumeroTarjeta
		FROM @NuevosTF TF
		WHERE TF.Id = @loopI;

		EXEC CrearTF @ResultCode
					   , @CodigoTCA 
					   , @NumeroTarjeta
					   , @CCV
					   , @FechaVencimiento
					   , @FechaHoy


		SET @loopI += 1;
	END;
	
	--############################################################################################################


	--############################################################################################################


	--Ya que procesamos todas las tarjetas ahora toca hacer el procesamiento de los movimientos
	--lo que vamos a hacer es insertar en una tabla de parametro que lleva los movimientos diarios 

/*
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
    WHERE F.Id = @lo;


	-- Ya que tenemos lista nuestra tabla parametro/variable
	-- Toca hacer un while en el que se procesen los movimientos de cada TF 

	DECLARE @MovimientosAProcesar INT --se encarga de ver en cuento hay que decrementa --el indice del while
			, @Nombre VARCHAR(64)
			, @FechaMov DATE
			, @Monto MONEY
			, @Descripcion VARCHAR(256)
			, @Referencia VARCHAR(32);
									   
	SET @ResultCode = 0;
	SET @loopI = 1; 

	WHILE (@loopI <= (SELECT MAX(ID)
					 FROM @NuevosTCA))
	BEGIN 
		
		SET @ResultCode = 0

		--Seleccionamos La primera Tarjeta Fisica 
		SELECT TOP 1 @NumeroTarjeta = M.TarjetaFisica
		FROM @MovsDiarios M;

		
		SELECT @MovimientosAProcesar = COUNT(TarjetaFisica)
		FROM @MovsDiarios M
		WHERE M.TarjetaFisica = @NumeroTarjeta;

		EXEC ELSTOREPROCEDURE @ResultCode --este es el SP que se encarga de todo lo referente a la TCM
					   , @MovsDiarios  
					   , @NumeroTarjeta 
					   , @FechaHoy

		IF(@ResultCode = 0) 
		BEGIN 

			SET @loopI -= (@MovimientosAProcesar-1); 
			SET @MovimientosAProcesar = 0; 

			DELETE FROM @MovsDiarios
			WHERE [TarjetaFisica] = @NumeroTarjeta; 

		END; 
		SET @loopI += 1;
	END;

	SELECT * FROM @MovsDiarios; */

	DELETE FROM @TarjetaHabientes;
	DELETE FROM @NuevosTCM; 
	DELETE FROM @NuevosTCA;
	DELETE FROM @NuevosTF;
	DELETE FROM @MovsDiarios;

	SET @lo += 1;
	END;




