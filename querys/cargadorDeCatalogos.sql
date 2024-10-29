USE [tarea3BD]
GO
                                          --Primero llenaremos tablas catalogo que no vienen en el XML 


BEGIN TRY 
BEGIN TRANSACTION 
--Tipo de usuairo 

INSERT INTO [dbo].[TipoDeUsuario]
(
	Nombre
)
VALUES
('Administrador')
,('Tarjeta Habiente');



                                         --Ahora si empecemos con el XML de catalogos 


-- Hacemos la tabla variable, funcionara para extraer todos los datos
DECLARE  @XmlTable TABLE
(
	XmlCol XML
);

--Metemos el  XML a la tabla variable 
INSERT INTO @XmlTable(XmlCol)
SELECT BulkColumn
FROM OPENROWSET
(
    BULK 'C:\prueba\tb3\datos.xml'
	, SINGLE_BLOB
)
AS x;


                         --AHORA CARGUEMOS LOS DATOS DE PUESTO

--Tipos de documento Identidad 
INSERT INTO [dbo].[TipoDocumentoIdentidad]
SELECT result.Nombre, result.Formato
FROM @XmlTable
CROSS APPLY 
(
    SELECT
        Nombre = z.value('@nombre', 'VARCHAR(32)')
		, Formato = z.value('@formato', 'VARCHAR(32)')
    FROM XmlCol.nodes('root/TiposDeDocumentoIdentidad/TDI') AS T(z)
) AS result;


--Tipos de Tarjeta Maestra 
INSERT INTO [dbo].[TipoTarjetaCreditoMaestra]
SELECT result.Nombre
FROM @XmlTable
CROSS APPLY 
(
    SELECT
        Nombre = z.value('@Nombre', 'VARCHAR(32)')
    FROM XmlCol.nodes('root/TTCM/TTCM') AS T(z)
) AS result;


--Tipos de Reglas
INSERT INTO [dbo].[TipoDeReglas]
SELECT result.Nombre, result.tipo
FROM @XmlTable
CROSS APPLY 
(
    SELECT
        Nombre = z.value('@Nombre', 'VARCHAR(32)')
		, tipo = z.value('@tipo', 'VARCHAR(32)')
    FROM XmlCol.nodes('root/TRN/TRN') AS T(z)
) AS result;



-----Ahora toca cargar las reglas de negocio, que ocupan un proceso un poco mas trabajado 

DECLARE @ReglasDeNegocio TABLE 
(
	Id INT IDENTITY(1,1) NOT NULL
	, NombreRegla VARCHAR(64) NOT NULL
	, TipoDeTCM VARCHAR(16) NOT NULL
	, TipoRN VARCHAR(32) NOT NULL
	, Valor VARCHAR(32) NOT NULL
)

INSERT INTO @ReglasDeNegocio
SELECT result.NombreRegla, result.TipoDeTCM, result.TipoRN, result.Valor
FROM @XmlTable
CROSS APPLY 
(
    SELECT
        NombreRegla = z.value('@Nombre', 'VARCHAR(32)')
		, TipoDeTCM = z.value('@TTCM', 'VARCHAR(32)')
		, TipoRN = z.value('@TipoRN', 'VARCHAR(32)')
		, Valor = z.value('@Valor', 'VARCHAR(32)')
    FROM XmlCol.nodes('root/RN/RN') AS T(z)
) AS result;

--Primero insertamos en reglas de negocio principal 
	INSERT INTO dbo.ReglasDeNegocio 
	(
		Nombre
		, IdTipoDeTCM
		, IdTipoDeRegla
	)
	SELECT RN.NombreRegla
		   , TCM.Id
		   , TR.Id		    	
	FROM @ReglasDeNegocio RN
	INNER JOIN dbo.TipoTarjetaCreditoMaestra TCM ON RN.TipoDeTCM = TCM.Nombre
	INNER JOIN dbo.TipoDeReglas TR ON RN.TipoRN = TR.Nombre
			
	--Declaramos Variables para el while
	DECLARE @lo INT
			, @hi INT
			, @TipoRN VARCHAR(32)
			, @Valor VARCHAR(32);

	SELECT @hi = MAX(Id)
	FROM @ReglasDeNegocio; --seleccionamos el tamaño de @ReglasDeNegocio
	        
	SET @lo = 1;

-- ahora insertamos los valores en las tablas dedicadas a traves de un SP 
WHILE (@lo <= @hi)
	BEGIN 

		SELECT @TipoRN = RN.TipoRN
			   , @Valor = RN.Valor
		FROM @ReglasDeNegocio RN
		WHERE @lo = RN.Id; 


		EXEC DelegarTipoRN 0, @lo, @TipoRN, @Valor;
		
		SET @lo += 1;
	END;




---Ya habiendo insertado las Reglas de Negocio toca insertar En motivos de invalidacion 


INSERT INTO [dbo].[MotivoInvalidacionTarjeta]
SELECT result.Nombre
FROM @XmlTable
CROSS APPLY 
(
    SELECT
        Nombre = z.value('@Nombre', 'VARCHAR(32)')
    FROM XmlCol.nodes('root/MIT/MIT') AS T(z)
) AS result;



--Ahora insertemos en tipo de movimiento 



INSERT INTO [dbo].[TiposDeMovimiento]
SELECT result.Nombre
	   , result.Accion
	   , CASE 
		 WHEN result.AcumulaOperacionATM = 'SI' THEN 1
		 ELSE 0
		 END AS AcumulaOperacionATM
	   , CASE 
         WHEN result.AcumulaOperacionVentana = 'SI' THEN 1
         ELSE 0
		 END AS AcumulaOperacionVentana
FROM @XmlTable
CROSS APPLY 
(
    SELECT
        Nombre = z.value('@Nombre', 'VARCHAR(64)')
		, Accion = z.value('@Accion', 'VARCHAR(8)')
		, AcumulaOperacionATM = z.value('@Acumula_Operacion_ATM', 'VARCHAR(4)')
		, AcumulaOperacionVentana = z.value('@Acumula_Operacion_Ventana', 'VARCHAR(4)')
		FROM XmlCol.nodes('root/TM/TM') AS T(z)
) AS result;



--Ahora insertemos los usuarios admin 

INSERT INTO [dbo].[Usuarios]
(
	IdTipoDeUsuario
	, Nombre
	, Contraseña
)
SELECT 1
	   , result.Nombre
	   , result.Contraseña
FROM @XmlTable
CROSS APPLY 
(
    SELECT
        Nombre = z.value('@Nombre', 'VARCHAR(16)')
		, Contraseña = z.value('@Password', 'VARCHAR(16)')
		FROM XmlCol.nodes('root/UA/Usuario') AS T(z)
) AS result;



--Ahora insertemos los tipo de movimientos corrientes

INSERT INTO [dbo].[TiposDeMovimientoCorrientes]
SELECT result.nombre
FROM @XmlTable
CROSS APPLY 
(
    SELECT
        nombre = z.value('@nombre', 'VARCHAR(32)')
		FROM XmlCol.nodes('root/TMIC/TMIC') AS T(z)
) AS result;



--Ahora insertemos los tipo de movimientos moratorios

INSERT INTO [dbo].[TiposDeMovimientoMoratorios]
SELECT result.nombre
FROM @XmlTable
CROSS APPLY 
(
    SELECT
        nombre = z.value('@nombre', 'VARCHAR(32)')
		FROM XmlCol.nodes('root/TMIM/TMIM') AS T(z)
) AS result;


COMMIT TRANSACTION
END TRY

BEGIN CATCH
	
	IF @@TRANCOUNT > 0
	BEGIN 
		ROLLBACK;
	END; 


	INSERT INTO [dbo].[DBError] VALUES 
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

END CATCH