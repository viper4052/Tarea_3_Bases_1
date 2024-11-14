USE [tarea3BD]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
    EL STORE PROCEDURE

	Se encarga de todas las Operaciones referentes a una TCM en un dia 
	
	- primero procesa todos los movimientos del dia 
	- Luego realiza tramites de renovacion de tarjeta de ser necesario 
	- Calcula los intereses corrientes
	- Calcula los intereses moratorios 

	- Emite estados de cuenta en caso de encontrarse en la fecha de cierre 


valores que se insertaran
--  @InMovsDiarios: una tabla con todos los movimientos del dia 
--  @InNumeroTarjeta: dice que tarjeta hay que usar
--  @InFechaHoy: la fecha de operacion 
*/

ALTER PROCEDURE [dbo].[ELSTOREPROCEDURE]
    @OutResulTCode INT OUTPUT
	, @InMovsDiarios MovimientosDiarios READONLY
	, @InNumeroTarjeta BIGINT 
	, @InFechaHoy DATE
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SET @OutResulTCode = 0;

--###############################################################################################################################
--Declaracion de variables y tablas necesarias 
		
		--Tabla de a donde se insertaran los nuevos movimientos 
		DECLARE @MovimientosTCM TABLE
		(
			Id INT IDENTITY(1,1) NOT NULL
			, IdTipoDeMovimiento INT NOT NULL
			, IdEstadoDeCuenta INT NOT NULL
			, Fecha DATE NOT NULL 
			, Monto MONEY NOT NULL
			, Descripcion VARCHAR(256)
			, Referencia VARCHAR(32)
			, IdTarjetaCreditoMaestra INT NOT NULL
			, NuevoSaldo MONEY 
			, EsSus BIT DEFAULT 0
		);

		--tabla de donde se insertaran los movimientos sospechosos 
		DECLARE @MovimientosSUS TABLE
		(
			Id INT IDENTITY(1,1) NOT NULL
			, IdTipoDeMovimiento INT NOT NULL
			, Fecha DATE NOT NULL 
			, Monto MONEY NOT NULL
			, Descripcion VARCHAR(256)
			, Referencia VARCHAR(32)
			, IdTarjetaCreditoMaestra INT NOT NULL
		);

		--tabla de donde se insertara la nueva TF 
		DECLARE @NuevaTF TABLE
		(
			Id INT NOT NULL
			, IdTarjeta INT NOT NULL
			, Numero BIGINT NOT NULL
			, CCV INT NOT NULL
			, Pin INT NOT NULL 
			, FechaCreacion DATE NOT NULL
			, FechaVencimiento DATE NOT NULL
			, EsValida BIT DEFAULT 1
		);

		--Tabla de donde se sacara los movimientos por interes corrientes
		DECLARE @MovInteresesCorrientes TABLE
		(
			Id INT IDENTITY(1,1) NOT NULL
			, IdTipoDeMovimiento INT NOT NULL
			, IdEstadoDeCuenta INT NOT NULL 
			, Fecha DATE NOT NULL 
			, Monto MONEY NOT NULL
			, IdTarjetaCreditoMaestra INT NOT NULL
		);

		--Tabla de donde se sacara los movimientos por interes moratorios
		DECLARE @MovInteresesMoratorios TABLE
		(
			Id INT IDENTITY(1,1) NOT NULL
			, IdTipoDeMovimiento INT NOT NULL
			, IdEstadoDeCuenta INT NOT NULL 
			, Fecha DATE NOT NULL 
			, Monto MONEY NOT NULL
			, IdTarjetaCreditoMaestra INT NOT NULL
		);


		--Aqui se guardara el nuevo estado de cuenta en fecha de cierre 
		DECLARE @NuevoEstadoCuenta TABLE
		(
			Id INT 
			, FechaInicio DATE
			, FechaFin DATE 
			, PagoMinimoMesAnterior MONEY
			, FechaParaPagoMinimo DATE 
			, InteresesMoratorios MONEY
			, InteresesCorrientes MONEY 
			, CantidadOperacionesATM INT 
			, CantidadOperacionesVentana INT 
			, SumaDePagos MONEY
			, CantidadDePagos INT
			, SumaDeCompras MONEY
			, CantidadDeCompras INT
			, SumaDeRetiros MONEY
			, CantidadDeRetiros INT 
			, SumaDeCreditos MONEY 
			, CantidadDeCreditos INT 
			, SumaDeDebitos MONEY 
			, CantidadDeDebitos INT 
			, IdTCM INT 
			, PagoDeContado MONEY 
		);

		DECLARE @EstadosDeCuentaTCA TABLE
		(
			Id INT IDENTITY(1,1)
			, FechaInicio DATE
			, FechaFin DATE
			, CantidadOperacionesATM INT
			, CantidadOperacionesVentana INT
			, SumaDeCompras MONEY
			, CantidadDeCompras INT
			, SumaDeRetiros MONEY
			, CantidadDeRetiros INT
			, SumaDeCreditos MONEY
			, SumaDeDebitos MONEY
			, IdTCM INT
			, IdTCA InT
		); 

		--Aqui se guardara los movimientos de fecha de cierre 
		DECLARE @MovimientoCierreCuenta TABLE
		(
			Id INT IDENTITY(1,1) NOT NULL
			, IdTipoDeMovimiento INT NOT NULL
			, IdEstadoDeCuenta INT NOT NULL
			, Fecha DATE NOT NULL 
			, Monto MONEY NOT NULL
			, Descripcion VARCHAR(256)
			, Referencia VARCHAR(32)
			, IdTarjetaCreditoMaestra INT NOT NULL
			, NuevoSaldo MONEY 
		);

		--las variables necesarias 

        DECLARE @IdTCM INT
				, @IdTCA INT
				, @IdTarjeta INT
				, @IdTFisica INT 
				, @hi INT
				, @lo INT
				, @FechaMovimiento DATE
				, @FechaCreacionTF DATE
				, @FechaMuerteTF DATE
				, @IdTipoDeMovimiento INT
				, @Accion VARCHAR(8)
				, @NombreMovimiento VARCHAR(32)
				, @AcumulaVentana BIT 
				, @AcumulaATM BIT 
				, @MontoMov MONEY 
				, @IdTipoTCM INT 
				, @RecuperacionFlag BIT --dice si pidieron recuperacion 
				, @NombreRecuperacion VARCHAR(64)
				, @EsValida BIT 
				, @CCV INT
				, @Pin INT 
				--Son de la TCM 
				, @SaldoActual MONEY
				, @SumaMovimientos MONEY
				, @SaldoInteresesCorrientes MONEY
				, @SaldoInteresMoratorios MONEY
				, @PagoAcumuladosDelPeriodo MONEY  --Tambien es [SumaDePagos] del EC
				--Son del EC ;
				, @FechaPagoMinimo DATE
				, @PagoMinimoMesAnterior MONEY
				, @TCMOperacionesATM INT 
				, @TCMOperacionesVentana INT 
				, @TCMQDePagos INT
				, @TCMSumaDeCompras MONEY
				, @TCMQDeCompras INT 
				, @TCMSumaDeRetiros MONEY
				, @TCMQDeRetiros INT 
				, @TCMSumaDeDebitos MONEY
				, @TCMQDeDebitos INT
				, @TCMSumaDeCreditos MONEY
				, @TCMQDeCreditos INT
				--Son del Posible EC del TCA 
				, @TCAOperacionesATM INT
				, @TCAOperacionesVentana INT 
				, @TCASumaDeCompras MONEY
				, @TCAQDeCompras INT 
				, @TCASumaDeRetiros MONEY
				, @TCAQDeRetiros INT 
				, @TCASumaDeDebitos MONEY
				, @TCASumaDeCreditos MONEY



--Ahora Asignacion de valores 

		-- Iniciamos algunos valores en 0 
		SET @RecuperacionFlag = 0; 
		SET @SumaMovimientos = 0; --estos son los movimientos en transito 


		--Primero obtengamos el TCM asociado al TF
--#################################################################
		SELECT @IdTarjeta = TF.IdTarjeta
			   , @IdTFisica = TF.Id --este id si es unico
			   , @EsValida = TF.EsValida 
			   , @Pin = TF.Pin
			   , @CCV = TF.CCV
		FROM [dbo].[TarjetaFisica] TF
		WHERE TF.Numero = @InNumeroTarjeta  --hay que hacer eso para obtener la actual  ya que hay muchas a lo 
		AND (@InFechaHoy >= TF.FechaCreacion AND @InFechaHoy <= TF.FechaVencimiento); --largo del tiempo 

		--Si es valida queda nulo, significa que no existe tarjeta fisica valida 
		--para este periodo
		IF( @EsValida IS NULL)
		BEGIN
		--por ello buscamos la mas reciente
			SELECT TOP 1 @IdTarjeta = TF.IdTarjeta
				   , @IdTFisica = TF.Id
				   , @EsValida = TF.EsValida --va a quedar en 0
				   , @Pin = TF.Pin
				   , @CCV = TF.CCV
			FROM [dbo].[TarjetaFisica] TF
			WHERE TF.Numero = @InNumeroTarjeta
			ORDER BY TF.FechaCreacion DESC; 
		END; 
		
		
		IF EXISTS(SELECT 1 
				  FROM [dbo].[TarjetaCreditoMaestra] TM
				  WHERE TM.IdTarjeta = @IdTarjeta)
		BEGIN 
			--Si esto ocurre, implica que la tarjeta fisica 
			--es de una TCM
			SET @IdTCM = @IdTarjeta;
		END 
		ELSE
		BEGIN
			--esto significa que fue una TCA, la que lo realizo
			SELECT @IdTCM = TA.IdTCM
			FROM [dbo].[TarjetaCreditoAdicional] TA
			WHERE TA.IdTarjeta = @IdTarjeta

			SET @IdTCA = @IdTarjeta; 
		END;

		--seteamos el tipo de tcm 
		SELECT @IdTipoTCM = TM.IdTipoTCM
		FROM dbo.TarjetaCreditoMaestra TM
		WHERE TM.IdTarjeta = @IdTCM; 
		--Ahora Obtengamos los datos necesarios de la TCM con los que se trabajará
--#################################################################



--;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
/* Antes de seguir declarando variables es necesario ver si hoy es la fecha de 
cierre de la TCM o TCA, ya que en ese caso hay que cambiar algunos datos y
reiniciar y cerrar algunos otros
*/
--;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		DECLARE @PosibleFin DATE
				, @IdDePosibleFIn INT
				, @IdReglaNegocio INT
				, @QDias INT
				, @PagoDeContado MONEY 
				, @FechaDeCierre DATE;

		SELECT @PosibleFin = EC.FechaFin
			   , @IdDePosibleFIn = EC.Id
		FROM dbo.EstadoDeCuenta EC
		WHERE EC.IdTCM = @IdTCM
		AND EC.FechaFin >= @InFechaHoy
		AND EC.FechaInicio <= @InFechaHoy

		IF( @InFechaHoy = @PosibleFin)
		BEGIN --###########################################################################################

		--Aqui realizaremos los cierres de estado de cuenta 

		--Bueno primero que todo realizemos los cargos mensuales a la tarjeta 

		--#1 apliquemos el sado por el intereses corriente y moratorios
		DECLARE @SaldoAcumuladoIntCorrientes MONEY
				, @SaldoAcumuladoIntMoratorios MONEY
				, @SaldoFechaFin MONEY    --todo esto deber ser actualizado en TCM y EC en Transaccion 
				, @QCreditosFechaFin INT
				, @QDebitosFechaFin INT
				, @SumaCreditosFechaFin MONEY
				, @SumaDebitosFechaFin MONEY; 


		SET @SaldoAcumuladoIntCorrientes = 0;
		SET @SaldoAcumuladoIntMoratorios = 0;
		SET @SaldoFechaFin = 0;
		SET @QCreditosFechaFin = 0;
		SET @QDebitosFechaFin = 0;
		SET @SumaCreditosFechaFin = 0;
		SET @SumaDebitosFechaFin = 0;

		   

		SELECT @SaldoAcumuladoIntCorrientes = EC.InteresesCorrientes
			   , @SaldoAcumuladoIntMoratorios = EC.InteresesMoratorios
		FROM dbo.EstadoDeCuenta EC 
		WHERE EC.Id = @IdDePosibleFIn;


		SELECT @SaldoFechaFin = TC.SaldoActual
		FROM dbo.TarjetaCreditoMaestra TC
		WHERE TC.IdTarjeta = @IdTCM;


		SET @SaldoFechaFin = @SaldoFechaFin + @SaldoAcumuladoIntCorrientes;
		SET @SumaCreditosFechaFin += @SaldoAcumuladoIntCorrientes;
		SET @QCreditosFechaFin += 1; 

		INSERT INTO @MovimientoCierreCuenta
		(
			IdTipoDeMovimiento 
			, IdEstadoDeCuenta 
			, Fecha 
			, Monto 
			, Descripcion 
			, Referencia 
			, IdTarjetaCreditoMaestra 
			, NuevoSaldo 
		)
		VALUES
		(13, @IdDePosibleFIn, @InFechaHoy
		, @SaldoAcumuladoIntCorrientes, 'Aplicacion de saldo por interes corrientes'
		, ' ', @IdTCM, @SaldoFechaFin),
		(14, @IdDePosibleFIn, @InFechaHoy
		, @SaldoAcumuladoIntMoratorios, 'Aplicacion de saldo por interes moratorio'
		, ' ', @IdTCM, (@SaldoFechaFin-@SaldoAcumuladoIntMoratorios));

		SET @SaldoFechaFin = @SaldoFechaFin - @SaldoAcumuladoIntMoratorios;
		SET @SumaCreditosFechaFin -= @SaldoAcumuladoIntMoratorios;
		SET @QDebitosFechaFin += 1; 


		--#2 ahora los cargos de servicio por las TCM y TCA

		DECLARE @IdCargoServicio INT
				, @CargoPorServicio MONEY
				, @CargoPorTCAs MONEY; 

		SELECT @IdCargoServicio = RN.Id
		FROM dbo.ReglasDeNegocio RN
		WHERE RN.Nombre = 'Cargos Servicio Mensual TCM'
		AND RN.IdTipoDeTCM = @IdTipoTCM;

		SELECT @CargoPorServicio = RM.Valor
		FROM dbo.RNMonto RM
		WHERE RM.IdReglaNegocio = @IdCargoServicio


		SELECT @IdCargoServicio = RN.Id
		FROM dbo.ReglasDeNegocio RN
		WHERE RN.Nombre = 'Cargos Servicio Mensual TCA'
		AND RN.IdTipoDeTCM = @IdTipoTCM;


		SELECT @CargoPorTCAs = RM.Valor
		FROM dbo.RNMonto RM
		WHERE RM.IdReglaNegocio = @IdCargoServicio


		--aplicamos el cargo para todas las TCAs de la TCM
		SET @CargoPorServicio += (SELECT COUNT(*)
					             FROM [dbo].[TarjetaCreditoAdicional] TCA
								 WHERE TCA.IdTCM = @IdTCM) * @CargoPorTCAs;

		SET @SaldoFechaFin -= @CargoPorServicio;
		SET @SumaCreditosFechaFin -= @CargoPorServicio;
		SET @QDebitosFechaFin += 1; 

		INSERT INTO @MovimientoCierreCuenta
		(
			IdTipoDeMovimiento 
			, IdEstadoDeCuenta 
			, Fecha 
			, Monto 
			, Descripcion 
			, Referencia 
			, IdTarjetaCreditoMaestra 
			, NuevoSaldo 
		)
		VALUES
		(10, @IdDePosibleFIn, @InFechaHoy
		, @CargoPorServicio, 'Aplicacion de cargos por servicio de Tarjetas de Credito'
		, ' ', @IdTCM, @SaldoFechaFin)


		--#3 ahora apliquemos el seguro contra fraudes 

		DECLARE @IdSeguroFraude INT
				, @CargoPorSeguroFraude MONEY; 


		SELECT @IdCargoServicio = RN.Id
		FROM dbo.ReglasDeNegocio RN
		WHERE RN.Nombre = 'Cargo Seguro Contra Fraudes'
		AND RN.IdTipoDeTCM = @IdTipoTCM;

		SELECT @CargoPorSeguroFraude = RM.Valor
		FROM dbo.RNMonto RM
		WHERE RM.IdReglaNegocio = @IdCargoServicio


		SET @SaldoFechaFin -= @CargoPorSeguroFraude;
		SET @SumaCreditosFechaFin -= @CargoPorSeguroFraude;
		SET @QDebitosFechaFin += 1; 

		INSERT INTO @MovimientoCierreCuenta
		(
			IdTipoDeMovimiento 
			, IdEstadoDeCuenta 
			, Fecha 
			, Monto 
			, Descripcion 
			, Referencia 
			, IdTarjetaCreditoMaestra 
			, NuevoSaldo 
		)
		VALUES
		(10, @IdDePosibleFIn, @InFechaHoy
		, @CargoPorSeguroFraude, 'Aplicacion de seguro contra fraudes'
		, ' ', @IdTCM, @SaldoFechaFin)


		--#4 Finalmente revisemos si se excedio el uso de ventanilla o ATM 

		DECLARE @Qventanilla INT
				, @QATM INT 
				, @QventanillaMax INT
				, @QATMmax INT
				, @MultaATM MONEY
				, @MultaVentanilla MONEY;

		SELECT @Qventanilla = EC.CantidadOperacionesVentana
			   , @QATM = EC.CantidadOperacionesATM
		FROM dbo.EstadoDeCuenta EC
		WHERE EC.Id = @IdDePosibleFIn; 


		SELECT @IdReglaNegocio = R.Id 
		FROM dbo.ReglasDeNegocio R
		WHERE R.Nombre = 'Cantidad de operaciones en ATM'
		AND R.IdTipoDeTCM = @IdTipoTCM; 

		SELECT @QATMmax = RM.Valor
		FROM dbo.RNMonto RM
		WHERE RM.IdReglaNegocio = @IdReglaNegocio 


		--obtengamos el maximo en ventanilla 
		SELECT @IdReglaNegocio = R.Id 
		FROM dbo.ReglasDeNegocio R
		WHERE R.Nombre = 'Cantidad de operacion en Ventanilla'
		AND R.IdTipoDeTCM = @IdTipoTCM; 

		SELECT @QventanillaMax = RM.Valor
		FROM dbo.RNMonto RM
		WHERE RM.IdReglaNegocio = @IdReglaNegocio 

		IF( @QATM > @QATMmax)
		BEGIN
			--ahora obtengamos cuanto costarian las multas 

			SELECT @IdReglaNegocio = R.Id 
			FROM dbo.ReglasDeNegocio R
			WHERE R.Nombre = 'Multa exceso de operaciones ATM'
			AND R.IdTipoDeTCM = @IdTipoTCM; 

			SELECT @MultaATM = RM.Valor
			FROM dbo.RNMonto RM
			WHERE RM.IdReglaNegocio = @IdReglaNegocio 

			SET @SaldoFechaFin -= @MultaATM;
			SET @SumaCreditosFechaFin -= @MultaATM;
			SET @QDebitosFechaFin += 1; 

			INSERT INTO @MovimientoCierreCuenta
			(
				IdTipoDeMovimiento 
				, IdEstadoDeCuenta 
				, Fecha 
				, Monto 
				, Descripcion 
				, Referencia 
				, IdTarjetaCreditoMaestra 
				, NuevoSaldo 
			)
			VALUES
			(11, @IdDePosibleFIn, @InFechaHoy
			, @MultaATM, 'cargo por exceso ATM'
			, ' ', @IdTCM, @SaldoFechaFin)

		END; 

		IF( @Qventanilla > @QventanillaMax)
		BEGIN
			--ahora obtengamos cuanto costarian las multas 

			SELECT @IdReglaNegocio = R.Id 
			FROM dbo.ReglasDeNegocio R
			WHERE R.Nombre = 'Multa exceso de operaciones Ventanilla'
			AND R.IdTipoDeTCM = @IdTipoTCM; 

			SELECT @MultaVentanilla = RM.Valor
			FROM dbo.RNMonto RM
			WHERE RM.IdReglaNegocio = @IdReglaNegocio 

			
			SET @SaldoFechaFin -= @MultaVentanilla;
			SET @SumaCreditosFechaFin -= @MultaVentanilla;
			SET @QDebitosFechaFin += 1; 

			INSERT INTO @MovimientoCierreCuenta
			(
				IdTipoDeMovimiento 
				, IdEstadoDeCuenta 
				, Fecha 
				, Monto 
				, Descripcion 
				, Referencia 
				, IdTarjetaCreditoMaestra 
				, NuevoSaldo 
			)
			VALUES
			(12, @IdDePosibleFIn, @InFechaHoy
			, @MultaVentanilla, 'cargo por exceso ventanilla'
			, ' ', @IdTCM, @SaldoFechaFin)
		END; 


		--################################################################
		/*listo, ya que aplicamos los cargos finales toca calcular el nuevo 
		estado de cuenta*/


		--asi que pongamos los datos del que sera el nuevo en @NuevoEstadoCuenta

		SET @PagoDeContado = @SaldoFechaFin;

		
		--hagamos el calculo de la fecha de pago minimo 
		SELECT @IdReglaNegocio = R.Id 
		FROM dbo.ReglasDeNegocio R
		WHERE R.Nombre = 'Cantidad de dias para pago saldo de contado'
		AND R.IdTipoDeTCM = @IdTipoTCM; 

		SELECT @QDias = R.Valor
		FROM dbo.RNQDias R
		WHERE R.IdReglaNegocio = @IdReglaNegocio;

		--preprocesamos Fecha de cierre y de pago minimo
		SET @FechaDeCierre = dbo.FechaDeCierre(@InFechaHoy);

		SET @FechaPagoMinimo = DATEADD(DAY, @QDias, (SELECT EC.FechaFin   --se hace el calculo con base en la fecha fin anterior 
													FROM dbo.EstadoDeCuenta EC
													WHERE EC.Id = @IdDePosibleFIn));


		--calculemos el pago minimo del mes anterior
		DECLARE @Pagominimo MONEY
				, @CuotaMensual INT; 
		
		SELECT @IdReglaNegocio = R.Id 
		FROM dbo.ReglasDeNegocio R
		WHERE R.Nombre = 'Cantidad de cuotas para pago minimo'
		AND R.IdTipoDeTCM = @IdTipoTCM; 

		SELECT @CuotaMensual = RM.Valor
		FROM [dbo].[RNQMeses] RM
		WHERE RM.IdReglaNegocio = @IdReglaNegocio 

		SET @Pagominimo = (@PagoDeContado)/@CuotaMensual;

		--Insertamos en la tabla lo que será el estado de cuenta
		INSERT INTO @NuevoEstadoCuenta
		(
			Id
			, FechaInicio
			, FechaFin 
			, PagoMinimoMesAnterior 
			, FechaParaPagoMinimo 
			, InteresesMoratorios 
			, InteresesCorrientes  
			, CantidadOperacionesATM 
			, CantidadOperacionesVentana 
			, SumaDePagos 
			, CantidadDePagos 
			, SumaDeCompras 
			, CantidadDeCompras 
			, SumaDeRetiros 
			, CantidadDeRetiros 
			, SumaDeCreditos  
			, CantidadDeCreditos 
			, SumaDeDebitos  
			, CantidadDeDebitos 
			, IdTCM 
			, PagoDeContado 
		)
		VALUES
		(
			1 --este id realmente no se usara luego
			, @InFechaHoy
			, @FechaDeCierre
			, @Pagominimo
			, @FechaPagoMinimo
			, 0
			, 0 
			, 0
			, 0
			, 0
			, 0
			, 0
			, 0
			, 0
			, 0
			, 0
			, 0
			, 0
			, 0
			, @IdTCM
			, @PagoDeContado
		)


		--tambien creamos los nuevos estados de cuenta adicionales
		INSERT INTO @EstadosDeCuentaTCA
		(
			FechaInicio
			, FechaFin
			, CantidadOperacionesATM
			, CantidadOperacionesVentana
			, SumaDeCompras
			, CantidadDeCompras
			, SumaDeRetiros
			, CantidadDeRetiros
			, SumaDeCreditos
			, SumaDeDebitos
			, IdTCM
			, IdTCA
		)
		SELECT @InFechaHoy
			   , @FechaDeCierre
			   , 0 
			   , 0
			   , 0
			   , 0
			   , 0
			   , 0
			   , 0 
			   , 0
			   , @IdTCM
			   , TA.IdTarjeta
		FROM dbo.TarjetaCreditoAdicional TA 
		WHERE TA.IdTCM = @IdTCM; --insertamos uno para cada TCA

		END; --###########################################################################################


--;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
/*
Cierres de estados de cuenta listo. 
*/
--;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		--Obtengamos los valores referentes a la TCM
		--si es dia de cierre de estado de cuenta hay que ponerlos en 0
		SELECT @SaldoActual = TCM.SaldoActual
			   , @SaldoInteresesCorrientes = TCM.SaldoInteresesCorrientes
			   , @SaldoInteresMoratorios = TCM.SaldoInteresMoratorios
			   , @PagoAcumuladosDelPeriodo = TCM.PagoAcumuladosDelPeriodo
		FROM dbo.TarjetaCreditoMaestra TCM
		WHERE TCM.IdTarjeta = @IdTCM;

		IF( @InFechaHoy = @PosibleFin)
		BEGIN 
			SET @SaldoInteresesCorrientes = 0;
			SET @SaldoInteresMoratorios = 0;
			SET @PagoAcumuladosDelPeriodo = 0;
		END;

		--Ahora los datos para el Estado de Cuenta de la TCM
		--Tambien, si es fecha de cierre hay que poner estos datos con base
		-- en la columna que hay en @NuevoEstadoCuenta.
		
		IF( @InFechaHoy = @PosibleFin)
		BEGIN 
			
			
			SELECT @TCMOperacionesATM = EC.CantidadOperacionesATM
			   , @TCMOperacionesVentana = EC.CantidadOperacionesVentana
			   , @TCMQDePagos = EC.CantidadDePagos
			   , @TCMSumaDeCompras = EC.SumaDeCompras
			   , @TCMQDeCompras = EC.CantidadDeCompras
			   , @TCMSumaDeRetiros = EC.SumaDeRetiros
			   , @TCMQDeRetiros = EC.CantidadDeRetiros
			   , @TCMSumaDeDebitos = EC.SumaDeDebitos
			   , @TCMQDeDebitos = EC.CantidadDeDebitos
			   , @TCMSumaDeCreditos = EC.SumaDeCreditos
			   , @TCMQDeCreditos =EC.CantidadDeCreditos
			   , @FechaPagoMinimo = EC.FechaParaPagoMinimo
			   , @PagoMinimoMesAnterior = EC.PagoMinimoMesAnterior
			FROM @NuevoEstadoCuenta EC 
			WHERE EC.IdTCM = @IdTCM
			
		END
		ELSE
		BEGIN

			SELECT @TCMOperacionesATM = EC.CantidadOperacionesATM
				   , @TCMOperacionesVentana = EC.CantidadOperacionesVentana
				   , @TCMQDePagos = EC.CantidadDePagos
				   , @TCMSumaDeCompras = EC.SumaDeCompras
				   , @TCMQDeCompras = EC.CantidadDeCompras
				   , @TCMSumaDeRetiros = EC.SumaDeRetiros
				   , @TCMQDeRetiros = EC.CantidadDeRetiros
				   , @TCMSumaDeDebitos = EC.SumaDeDebitos
				   , @TCMQDeDebitos = EC.CantidadDeDebitos
				   , @TCMSumaDeCreditos = EC.SumaDeCreditos
				   , @TCMQDeCreditos =EC.CantidadDeCreditos
				   , @FechaPagoMinimo = EC.FechaParaPagoMinimo
				   , @PagoMinimoMesAnterior = EC.PagoMinimoMesAnterior
			FROM dbo.EstadoDeCuenta EC 
			WHERE EC.IdTCM = @IdTCM
			AND (@InFechaHoy >= EC.FechaInicio AND @InFechaHoy <= EC.FechaFin);
		
		END;
	

		--Ahora los datos para la posible TCA Estado de Cuenta


		IF( @IdTCA IS NOT NULL)
		BEGIN 
			
			--Nuevamente hay que ver si es dia de cierre

			IF( @InFechaHoy = @PosibleFin)
			BEGIN 
				SELECT @TCAOperacionesATM = EA.CantidadOperacionesATM
				   , @TCAOperacionesVentana = EA.CantidadOperacionesVentana
				   , @TCASumaDeCompras = EA.SumaDeCompras
				   , @TCAQDeCompras = EA.CantidadDeCompras
				   , @TCASumaDeRetiros = EA.SumaDeRetiros
				   , @TCAQDeRetiros = EA.CantidadDeRetiros
				   , @TCASumaDeDebitos = EA.SumaDeDebitos
				   , @TCASumaDeCreditos = EA.SumaDeCreditos
			FROM @EstadosDeCuentaTCA EA
			WHERE EA.IdTCA = @IdTCA
			END

			ELSE
			BEGIN			
			SELECT @TCAOperacionesATM = EA.CantidadOperacionesATM
				   , @TCAOperacionesVentana = EA.CantidadOperacionesVentana
				   , @TCASumaDeCompras = EA.SumaDeCompras
				   , @TCAQDeCompras = EA.CantidadDeCompras
				   , @TCASumaDeRetiros = EA.SumaDeRetiros
				   , @TCAQDeRetiros = EA.CantidadDeRetiros
				   , @TCASumaDeDebitos = EA.SumaDeDebitos
				   , @TCASumaDeCreditos = EA.SumaDeCreditos
			FROM dbo.EstadoDeCuentaAdicional EA
			WHERE EA.IdTCA = @IdTCA
			AND (@InFechaHoy >= EA.FechaInicio AND @InFechaHoy <= EA.FechaFin);
			END;

		END
		ELSE
		BEGIN 
			--en caso de no ser TCA ponerlos en 0 

			SET  @TCAOperacionesATM = 0
			SET @TCAOperacionesVentana = 0
			SET @TCASumaDeCompras = 0
			SET @TCAQDeCompras = 0
			SET @TCASumaDeRetiros = 0
			SET @TCAQDeRetiros = 0
			SET @TCASumaDeDebitos = 0
			SET @TCASumaDeCreditos = 0 

		END; 



--################################################################################################################
--Ya que sacamos los datos del estado de cuenta y tarjetas sigamos con asignaciones de variables


		--Saquemos las fechas de la TF
		SELECT @FechaCreacionTF = TF.FechaCreacion
		FROM dbo.TarjetaFisica TF
		WHERE TF.Id = @IdTFisica; --lo buscamos con su id unico

		SELECT @FechaMuerteTF =  TF.FechaVencimiento
		FROM dbo.TarjetaFisica TF
		WHERE TF.Id = @IdTFisica; --lo buscamos con su id unico

		--ahora saquemos los movimientos que vamos a procesar 	





--#################################################################################
--Ahora insertemos en la tabla variable los movimientos correspondientes a la fecha

--tenemos que revisar que fecha es, porque depende hay que cambiar el id del estado de cuenta
		
		DECLARE @IdEstadoDeCuenta INT


		SELECT @IdEstadoDeCuenta = EC.Id
		FROM dbo.EstadoDeCuenta EC
		WHERE (EC.IdTCM = @IdTCM) 
		AND (@InFechaHoy >= EC.FechaInicio AND @InFechaHoy <= EC.FechaFin)


		IF (@InFechaHoy = @PosibleFin) 
		BEGIN 
			--en caso de ser fecha de cierre aun no tenemos ID
			-- por lo que asignamos 1 momentaneamente
			SET @IdEstadoDeCuenta = 0;
		END; 

		INSERT INTO @MovimientosTCM 
		(
			IdTipoDeMovimiento 
			, IdEstadoDeCuenta 
			, Fecha 
			, Monto 
			, Descripcion
			, Referencia 
			, IdTarjetaCreditoMaestra 
		)
		SELECT TV.Id
			   , @IdEstadoDeCuenta
			   , MV.FechaMovimiento
			   , MV.Monto
			   , MV.Descripcion 
			   , MV.Referencia
			   , @IdTCM
		FROM @InMovsDiarios MV 
		INNER JOIN [dbo].[TiposDeMovimiento] TV ON TV.Nombre = MV.Nombre 
		WHERE MV.TarjetaFisica = @InNumeroTarjeta; 

--###############################################################################################################################	
--Ya que tenemos los movimientos en su tabla variable toca depurarlos 
--para ello se desecharan los movimientos sospechosos y tambien
--se les añadira el nuevo saldo 

	SELECT @hi = MAX(id)
	FROM @MovimientosTCM

	SET @lo = 1; 

	--Si estamos en los casos donde no hubieron movimientos ese dia 
	--entonces se saltará este while 
	WHILE (@lo <= @hi) 
	BEGIN
		
		SELECT @FechaMovimiento = T.Fecha
			   , @MontoMov = T.Monto 
			   , @NombreMovimiento = TM.Nombre
		FROM @MovimientosTCM T
		INNER JOIN dbo.TiposDeMovimiento TM ON TM.Id = T.IdTipoDeMovimiento
		WHERE T.Id = @lo;

		IF(SUBSTRING(@NombreMovimiento, 1, 12) = 'Recuperacion')
		BEGIN
		
		SET @RecuperacionFlag = 1;
		SET @NombreRecuperacion = @NombreMovimiento;

		DELETE FROM @MovimientosTCM
		WHERE Id = @lo

		END
		ELSE IF(@EsValida = 0) 
		BEGIN
			--Se marca como Sospechoso 
			UPDATE @MovimientosTCM
			SET EsSus = 1
			WHERE Id = @lo;

			INSERT INTO @MovimientosSUS 
			(
				IdTipoDeMovimiento 
				, Fecha 
				, Monto 
				, Descripcion
				, Referencia 
				, IdTarjetaCreditoMaestra 
			) 
			SELECT M.IdTipoDeMovimiento 
					, M.Fecha 
					, M.Monto 
					, M.Descripcion
					, M.Referencia 
					, M.IdTarjetaCreditoMaestra 
			FROM @MovimientosTCM M 
			WHERE M.Id = @lo 

		END
		ELSE
		BEGIN 
			--Actualizamos el Saldo en la tabla variable

			--Tenemos que ver si restamos o sumamos al @SaldoActual
			--Ademas de si ocupamos aumentar los contadores de ventana, atm, etc.

			SELECT @IdTipoDeMovimiento = MV.IdTipoDeMovimiento 
			FROM @MovimientosTCM MV
			WHERE MV.Id = @lo; 

			SELECT @Accion = TV.Accion
				   , @AcumulaATM = TV.AcumulaOperacionATM
				   , @AcumulaVentana = TV.AcumulaOperacionVentana
			FROM dbo.TiposDeMovimiento TV 
			WHERE TV.Id = @IdTipoDeMovimiento;		

			--Lo usamos mas adelante 
			DECLARE @EsCompra BIT = CASE WHEN @IdTipoDeMovimiento = 1 THEN 1 ELSE 0 END;
			DECLARE @EsRetiro BIT = CASE WHEN SUBSTRING(@NombreMovimiento, 1, 6) = 'Retiro' THEN 1 ELSE 0 END;

			--Verificar si acumula operaciones de ATM 

			
			SET @TCMOperacionesATM = CASE 
										WHEN @AcumulaATM = 1 THEN (@TCMOperacionesATM+1)
										ELSE @TCMOperacionesATM
									 END;

			SET @TCAOperacionesATM = CASE 
										WHEN @AcumulaATM = 1 AND (@IdTCA IS NOT NULL)THEN (@TCAOperacionesATM+1)
										ELSE @TCAOperacionesATM
									 END;

			--Verificar si acumula operaciones de Ventana 
			SET @TCMOperacionesVentana = CASE 
											WHEN @AcumulaVentana = 1 THEN (@TCMOperacionesVentana+1)
											ELSE @TCMOperacionesVentana
										 END;

			SET @TCAOperacionesVentana = CASE 
											WHEN @AcumulaVentana = 1 AND (@IdTCA IS NOT NULL) THEN (@TCAOperacionesVentana+1)
											ELSE @TCAOperacionesVentana
										 END;
			

			IF(@Accion = 'Credito')
			BEGIN 

				--Actualizamos el saldo actual (hay que ponerlo luego en @MovimientosTCM)
				SET @SaldoActual += @MontoMov;
				SET @SumaMovimientos +=  @MontoMov;

				--Ahora modifiquemos los que seran valores del EC del TCM 
				SET @TCMQDePagos +=1;
				SET @PagoAcumuladosDelPeriodo += @MontoMov; --Añadimos a los pagos del periodo 

				SET @TCMSumaDeCreditos += @MontoMov;
				SET @TCMQDeCreditos += 1;

				--Ahora agreguemos a TCA, en caso de SER necesario 
				SET @TCASumaDeCreditos += CASE WHEN @IdTCA IS NOT NULL THEN @MontoMov ELSE 0 END;
				
			END
			ELSE --En caso de ser debito hay que hacer otras, y mas validaciones
			BEGIN 
				
				--Definitivamente es un debito, por lo que se modificara esa variable 
				SET @TCMSumaDeDebitos += @MontoMov;
				SET @TCMQDeDebitos += 1;

				--Actualizamos el saldo actual (hay que ponerlo luego en @MovimientosTCM)
				SET @SaldoActual -= @MontoMov;
				SET @SumaMovimientos -=  @MontoMov;
				
				--Verifiquemos si añadir a compra 
				SET @TCMQDeCompras += CASE WHEN @EsCompra = 1 THEN 1 ELSE 0 END;
				SET @TCMSumaDeCompras += CASE WHEN @EsCompra = 1 THEN @MontoMov ELSE 0 END;

				--Verificamos si añadir a retiro 
				SET @TCMQDeRetiros += CASE WHEN @EsRetiro = 1 THEN 1 ELSE 0 END;
				SET @TCMSumaDeRetiros += CASE WHEN @EsRetiro = 1 THEN @MontoMov ELSE 0 END;

				IF(@IdTCA IS NOT NULL)
				BEGIN 
					SET @TCAQDeCompras += CASE WHEN @EsCompra = 1 THEN 1 ELSE 0 END;
					SET @TCASumaDeCompras += CASE WHEN @EsCompra = 1 THEN @MontoMov ELSE 0 END;

					
					SET @TCASumaDeRetiros += CASE WHEN @EsRetiro = 1 THEN @MontoMov ELSE 0 END;
					SET @TCAQDeRetiros += CASE WHEN @EsRetiro = 1 THEN 1 ELSE 0 END;

					SET @TCASumaDeCreditos += @MontoMov;
				END;

			END;
			
			--Actualizamos el saldo actual de los movimientos 
			UPDATE @MovimientosTCM
			SET NuevoSaldo = @SaldoActual
			WHERE Id = @lo;

		END; 

		SET @lo += 1;
	END;

--##############################################################################################################################

	-- Ya que preprocesamos todos los movimientos toca revisar si hace falta renovar la TF
	-- o bien si hay que expedir otra ya que se perdio

	DECLARE @NuevoVencimiento DATE
			, @IdRegla INT 
			, @IdTipoDeReposicion INT
			, @MontoRenovacion MONEY;

	--Osea, si hoy vence y no se perdio
	IF(@InFechaHoy = @FechaMuerteTF AND @EsValida = 1 AND @RecuperacionFlag = 0) 
	BEGIN 

	--Primero cerremos la actual 
	SET @EsValida = 0; 

	--revisamos las reglas de negocio en caso de ser TCA 
		IF( @IdTCA IS NOT NULL)
		BEGIN 
			SET @NuevoVencimiento = DATEADD(YEAR, 3, @FechaMuerteTF)
			--Tambien hay que generar el cargo por renovacion 

			SELECT @IdRegla = RN.Id
			FROM dbo.ReglasDeNegocio RN
			WHERE RN.Nombre = 'Cargo renovacion de TF de TCA'
			AND RN.IdTipoDeTCM = @IdTipoTCM; 

			SELECT @MontoRenovacion = RN.Valor
			FROM dbo.RNMonto RN 
			WHERE RN.IdReglaNegocio = @IdRegla;
		END
		ELSE
		BEGIN
			--ahora toca el caso de que sea TCM
			SET @NuevoVencimiento = DATEADD(YEAR, 5, @FechaMuerteTF)
			--Tambien hay que generar el cargo por renovacion 

			SELECT @IdRegla = RN.Id
			FROM dbo.ReglasDeNegocio RN
			WHERE RN.Nombre = 'Cargo renovacion de TF de TCM'
			AND RN.IdTipoDeTCM = @IdTipoTCM; 

			SELECT @MontoRenovacion = RN.Valor
			FROM dbo.RNMonto RN 
			WHERE RN.IdReglaNegocio = @IdRegla;
		END;

	--creamos la nueva TF 
	INSERT INTO @NuevaTF 
	(
		Id
		, IdTarjeta 
		, Numero 
		, CCV 
		, Pin 
		, FechaCreacion 
		, FechaVencimiento 
	)
	VALUES
	(
		(SELECT MAX(TF.Id)
		FROM dbo.TarjetaFisica TF) +1
		, @IdTarjeta
		, @InNumeroTarjeta
		, @CCV
		, @Pin
		, @InFechaHoy 
		, @NuevoVencimiento
	)

	--Creamos el movimiento 
	INSERT INTO @MovimientosTCM 
	(
		IdTipoDeMovimiento 
		, IdEstadoDeCuenta 
		, Fecha 
		, Monto 
		, Descripcion
		, Referencia 
		, IdTarjetaCreditoMaestra 
		, NuevoSaldo 
	)
	VALUES
	(
		(SELECT TM.Id
		FROM dbo.TiposDeMovimiento TM
		WHERE TM.Nombre = 'Renovacion de TF')
		, @IdEstadoDeCuenta
		, @InFechaHoy
		, @MontoRenovacion
		, 'Renovacion por vencimiento de TF'
		, ' '
		, @IdTCM 
		, (SELECT TOP 1 TM.NuevoSaldo
		  FROM @MovimientosTCM TM
		  ORDER BY TM.Id DESC) -@MontoRenovacion	
	);

	END;


	IF(@RecuperacionFlag = 1) 
	BEGIN 

	DECLARE @AnnosDeVencimiento INT;

	--Primero cerremos la actual 
	SET @EsValida = 0; 
	
	SELECT @IdRegla = RN.Id
	FROM dbo.ReglasDeNegocio RN
	WHERE RN.Nombre = 'Cantidad de Años para Vencimiento de TF'
	AND RN.IdTipoDeTCM = @IdTipoTCM; 
	
	SELECT @AnnosDeVencimiento = RN.Valor
	FROM [dbo].[RNQAños] RN 
	WHERE RN.IdReglaNegocio = @IdRegla;

	SET @NuevoVencimiento = DATEADD(YEAR, @AnnosDeVencimiento, @FechaMuerteTF)

	--revisamos las reglas de negocio en caso de ser TCA 
		IF( @IdTCA IS NOT NULL)
		BEGIN 

			SELECT @IdRegla = RN.Id
			FROM dbo.ReglasDeNegocio RN
			WHERE RN.Nombre = 'Reposicion de tarjeta de TCA'
			AND RN.IdTipoDeTCM = @IdTipoTCM; 

			SELECT @MontoRenovacion = RN.Valor
			FROM dbo.RNMonto RN 
			WHERE RN.IdReglaNegocio = @IdRegla;
		END
		ELSE
		BEGIN
		
			--Tambien hay que generar el cargo por renovacion 

			SELECT @IdRegla = RN.Id
			FROM dbo.ReglasDeNegocio RN
			WHERE RN.Nombre = 'Reposicion de tarjeta de TCM'
			AND RN.IdTipoDeTCM = @IdTipoTCM; 

			SELECT @MontoRenovacion = RN.Valor
			FROM dbo.RNMonto RN 
			WHERE RN.IdReglaNegocio = @IdRegla;
		END;

	--creamos la nueva TF 
	INSERT INTO @NuevaTF 
	(
		Id
		, IdTarjeta 
		, Numero 
		, CCV 
		, Pin 
		, FechaCreacion 
		, FechaVencimiento 
	)
	VALUES
	(
		(SELECT MAX(TF.Id)
		FROM dbo.TarjetaFisica TF) +1
		, @IdTarjeta
		, @InNumeroTarjeta
		, @CCV
		, @Pin
		, @InFechaHoy 
		, @NuevoVencimiento
	)

	--Creamos el movimiento 
	INSERT INTO @MovimientosTCM 
	(
		IdTipoDeMovimiento 
		, IdEstadoDeCuenta 
		, Fecha 
		, Monto 
		, Descripcion
		, Referencia 
		, IdTarjetaCreditoMaestra 
		, NuevoSaldo 
	)
	VALUES
	(
		(SELECT TM.Id
		FROM dbo.TiposDeMovimiento TM
		WHERE TM.Nombre = @NombreRecuperacion)
		, @IdEstadoDeCuenta
		, @InFechaHoy
		, @MontoRenovacion
		, @NombreRecuperacion
		, ' '
		, @IdTCM 
		, (SELECT TOP 1 TM.NuevoSaldo
		  FROM @MovimientosTCM TM
		  ORDER BY TM.Id DESC) - @MontoRenovacion	
	);

	END;
		
--##############################################################################################################################
	--Ahora nos encargaremos de realizar los movimientos por intereses Corrientes

	DECLARE @MontoInteresCorrientes MONEY
			, @TasaInteresCorriente REAl
			, @IdTasaInteresCorriente INT;




	IF(@SaldoActual > 0)
	BEGIN 
		
		SELECT @IdTasaInteresCorriente = RN.Id
		FROM dbo.ReglasDeNegocio RN
		WHERE RN.Nombre = 'Tasa de interes corriente'
		AND RN.IdTipoDeTCM = @IdTipoTCM; 

		SELECT @TasaInteresCorriente = RN.Valor
		FROM dbo.RNTasa RN
		WHERE RN.IdReglaNegocio = @IdTasaInteresCorriente;


		SET @MontoInteresCorrientes = ((@SaldoActual/@TasaInteresCorriente)/100)/30;

		SET @SaldoInteresesCorrientes += @MontoInteresCorrientes;

		INSERT INTO @MovInteresesCorrientes 
		(
			IdTipoDeMovimiento 
			, IdEstadoDeCuenta 
			, Fecha 
			, Monto 
			, IdTarjetaCreditoMaestra 
		)
		VALUES
		(
			(SELECT TM.Id
			FROM dbo.TiposDeMovimientoCorrientes TM 
			WHERE TM.Tipo = 'Credito Int corrientes')
			, @IdEstadoDeCuenta
			, @InFechaHoy
			, @MontoInteresCorrientes 
			, @IdTCM
		)
	END;


--##############################################################################################################################
	--Ahora nos encargaremos de aplicar los movimientos por intereses moratorios

	DECLARE @MontoInteresMoratorio MONEY
			, @MontoPagoMinimo MONEY
			, @TasaInteresMoratorio REAl
			, @IdTasaInteresMoratorio INT;

	

	IF(@InFechaHoy > @FechaPagoMinimo AND @PagoAcumuladosDelPeriodo < @PagoMinimoMesAnterior
	   AND DATEPART(DAY, @InFechaHoy) <> 7)
	BEGIN 
		
		SELECT @IdTasaInteresMoratorio = RN.Id
		FROM dbo.ReglasDeNegocio RN
		WHERE RN.Nombre = 'intereses moratorios'
		AND RN.IdTipoDeTCM = @IdTipoTCM; 

		SELECT @TasaInteresMoratorio = RN.Valor
		FROM dbo.RNTasa RN
		WHERE RN.IdReglaNegocio = @IdTasaInteresMoratorio;

		SET @MontoPagoMinimo = @PagoMinimoMesAnterior - @PagoAcumuladosDelPeriodo

		SET @MontoInteresMoratorio = ((@MontoPagoMinimo/@TasaInteresMoratorio)/100)/30

		SET @SaldoInteresMoratorios = @MontoInteresMoratorio; 

		INSERT INTO @MovInteresesMoratorios 
		(
			IdTipoDeMovimiento 
			, IdEstadoDeCuenta 
			, Fecha 
			, Monto 
			, IdTarjetaCreditoMaestra 
		)
		VALUES
		(
			(SELECT TM.Id
			FROM dbo.TiposDeMovimientoMoratorios TM 
			WHERE TM.Tipo = 'Debito Int corrientes')
			, @IdEstadoDeCuenta
			, @InFechaHoy
			, @MontoInteresCorrientes 
			, @IdTCM
		)
		
	END;
	
--##############################################################################################################################
/*   LISTO!!!

	Todo el preprocesamiento necesario acabo, es hora de hacer la transaccion 
	Para poder llevar a cabo este proceso hace falta hacer lo siguiente:


	#CIERRES DE CUENTA
	- primero vamos a insertar la tabla @NuevoEstadoCuenta, esto en caso de 
	haber cierre de cuenta, si hacemos esto, obtendremos su id mediante
	SCOPE_IDENTITY().

	- Luego insertaremos los estados de cuenta de las TCA, tendremos que extraer el id 
	de la TCA con la que estamos trabajando, el mismo proceso que con el del TCM

	- Luego hay que insertar los movimientos de cierre de cuenta, al hacer esto tambien hay que 
	modificar el Estado de cuenta que se va a cerrar, hay que modificar:
		-  @QCreditosFechaFin en EC viejo
		-  @QDebitosFechaFin en EC viejo
		-  @SumaCreditosFechaFin en EC viejo
		-  @SumaDebitosFechaFin en EC viejo

	#GENERAL
	--ya que vimos que es lo que hay que insertar y updatear primero en caso de ser cierre de 
	cuenta veamos que hay que hacer siempre.

	
	- Insertar los @MovimientosTCM en dbo.Movimientos, y tambien los @MovimientosSUS
	--tambien hay que insertar en MovsConTF

	- Insertar @MovInteresesCorrientes y @MovInteresesMoratorios

	#INVALIDACIONES

	--una tarjeta en caso de ser invalidad, hay que insertar desde
	NuevaTF


	#UPDATES
	--Ya por ultimo hay que actualizar 
	 -[dbo].[TarjetaCreditoMaestra]
	 -[dbo].[EstadoDeCuenta], el viejo tambien, si fuera necesario en fecha cierre 
	 -[dbo].[EstadoDeCuentaAdicional] (Solo si el movimiento fue desde ella)

*/
	
	--volvamos a declarar estas variable, serviran como contextp 

	--aqui almacenaremos los id de los estados de cuenta
	--en caso de ser necesario por fecha de cierre
	DECLARE @IdViejoEC INT
			, @IdNuevoEC INT
			, @IdECdeTCA INT; 

	

	IF (@IdEstadoDeCuenta = 0) 
	BEGIN 
		SET @IdViejoEC = @IdDePosibleFIn;
	END 
	ELSE 
	BEGIN 
		SET @IdNuevoEC = @IdEstadoDeCuenta; 
		SET @IdViejoEC = 0; --para que no actualize cuando se usa para filtrar 
	END



	IF( @IdTCA IS NOT NULL)
	BEGIN 
		SET @IdECdeTCA = CASE 
							WHEN @IdViejoEC = 0 THEN (SELECT EC.Id  FROM [dbo].[EstadoDeCuentaAdicional] EC
													 WHERE EC.IdTCA = @IdTCA 
													 AND EC.FechaFin > @InFechaHoy
													 AND EC.FechaInicio <= @InFechaHoy)
							ELSE 0
						 END; 
	END
	ELSE 
	BEGIN 
		SET @IdECdeTCA = 0;
	END;  


	--esta tabla agarrara los ids de los movimientos para luego poder asociarlos con  
	--movimientos con tf
	DECLARE @MovimientosIDs TABLE 
	(
		Id INT
	);


--##############################################################################################################################
	BEGIN TRANSACTION


	--########################################################################################################
	IF( @InFechaHoy = @PosibleFin)
	BEGIN 

	--empezemos primero con lo necesario en caso de cierre de cuenta 

	--#1 insertemos el EC del tcm 
	INSERT INTO dbo.EstadoDeCuenta
	(
		FechaInicio,
		FechaFin,
		PagoMinimoMesAnterior,
		FechaParaPagoMinimo,
		InteresesMoratorios,
		InteresesCorrientes,
		CantidadOperacionesATM,
		CantidadOperacionesVentana,
		SumaDePagos,
		CantidadDePagos,
		SumaDeCompras,
		CantidadDeCompras,
		SumaDeRetiros,
		CantidadDeRetiros,
		SumaDeCreditos,
		CantidadDeCreditos,
		SumaDeDebitos,
		CantidadDeDebitos,
		IdTCM,
		PagoDeContado
	)
	SELECT EC.FechaInicio
		   , EC.FechaFin 
		   , EC.PagoMinimoMesAnterior
		   , EC.FechaParaPagoMinimo
		   , EC.InteresesMoratorios
		   , EC.InteresesCorrientes
		   , EC.CantidadOperacionesATM
		   , EC.CantidadOperacionesVentana
		   , EC.SumaDePagos
		   , EC.CantidadDePagos
		   , EC.SumaDeCompras
		   , EC.CantidadDeCompras
		   , EC.SumaDeRetiros
		   , EC.CantidadDeRetiros
		   , EC.SumaDeCreditos
		   , EC.CantidadDeCreditos
		   , EC. SumaDeDebitos
		   , EC.CantidadDeDebitos
		   , EC.IdTCM
		   , EC.PagoDeContado
	FROM @NuevoEstadoCuenta EC

	--obtenemos el EC de este estado de cuenta, será nuestro nuevo EC 
	SET @IdNuevoEC = SCOPE_IDENTITY()

	--#2 Insertemos los nuevos estados de cuenta adicionales 

	INSERT INTO [dbo].[EstadoDeCuentaAdicional]
	(
		FechaInicio 
		, FechaFin 
		, CantidadOperacionesATM 
		, CantidadOperacionesVentana 
		, SumaDeCompras 
		, CantidadDeCompras 
		, SumaDeRetiros 
		, CantidadDeRetiros 
		, SumaDeCreditos 
		, SumaDeDebitos 
		, IdTCM 
		, IdTCA 
	)
	SELECT EC.FechaInicio
	       , EC.FechaFin
		   , EC.CantidadOperacionesATM
		   , EC.CantidadOperacionesVentana
		   , EC.SumaDeCompras
		   , EC.CantidadDeCompras
		   , EC.SumaDeRetiros
		   , EC.CantidadDeRetiros
		   , EC.SumaDeCreditos
		   , EC.SumaDeDebitos
		   , EC.IdTCM
		   , EC.IdTCA
	FROM @EstadosDeCuentaTCA EC

	SELECT @IdECdeTCA = EC.Id  --sacamos el Id del EC adicional 
	FROM dbo.EstadoDeCuentaAdicional EC 
	WHERE EC.IdTCA = @IdTCA
	AND EC.FechaInicio = @InFechaHoy

	--#3 ahora insertemos los movimientos de cierre 
	--estos no van asociados a dbo.MovimientosConTF

	INSERT INTO dbo.Movimientos
	(	
		IdTipoDeMovimiento
		, IdEstadoDeCuenta
		, Fecha
		, Monto
		, Descripcion
		, Referencia
		, IdTarjetaCreditoMaestra
		, NuevoSaldo
	)
	SELECT MC.IdTipoDeMovimiento 
		  , @IdViejoEC
		  , MC.Fecha
		  , MC.Monto
		  , MC.Descripcion
		  , MC.Referencia
		  , MC.IdTarjetaCreditoMaestra
		  , MC.NuevoSaldo
	FROM @MovimientoCierreCuenta MC



END;

--########################################################################################################

	--Ahora empezemos con los procesos diarios usuales


	--#1 primero insertemos los nuevos movimientos 
	
	
	INSERT INTO [dbo].[Movimientos]
	(
		IdTipoDeMovimiento
		, IdEstadoDeCuenta
		, Fecha
		, Monto
		, Descripcion
		, Referencia
		, IdTarjetaCreditoMaestra
		, NuevoSaldo
	)
	OUTPUT INSERTED.Id INTO @MovimientosIDs
	SELECT TCM.IdTipoDeMovimiento
		   , @IdNuevoEC 
		   , TCM.Fecha
		   , TCM.Monto
		   , TCM.Descripcion
		   , TCM.Referencia
		   , TCM.IdTarjetaCreditoMaestra
		   , TCM.NuevoSaldo 
	FROM @MovimientosTCM TCM
	WHERE TCM.EsSus = 0;


	--los IDs insertados quedaron en @MovimientosIDs, entonces ahora insertemos en movimientos con TF 

	

	INSERT INTO [dbo].[MovimientosConTF]
	(
		IdMovimiento
		, IdTarjetaFisica
		, Fecha
	)
	SELECT ID.Id
		   , @IdTFisica
		   , @InFechaHoy 
	FROM @MovimientosIDs ID



	--#2 ahora insertemos los movimientos sospechosos 

	INSERT INTO dbo.MovimientoSospechoso
	(
		IdTipoDeMovimiento
		, Fecha
		, Monto
		, Descripcion
		, Referencia
		, IdTarjetaCreditoMaestra
	)
	SELECT SUS.IdTipoDeMovimiento
	       , SUS.Fecha
		   , SUS.Monto
		   , SUS.Descripcion
		   , SUS.Referencia
		   , SUS.IdTarjetaCreditoMaestra
	FROM @MovimientosSUS SUS;



	--#3 ahora insertemos los movimientos por intereses (los dos)


	INSERT INTO dbo.MovimientosInteresesCorrientes
	(
	  IdTipoDeMovimientoCorriente
	  , IdEstadoDeCuenta
	  , Fecha
	  , Monto
	  , IdTarjetaCreditoMaestra
	)
	SELECT C.IdTipoDeMovimiento
	       , @IdNuevoEC 
		   , C.Fecha
		   , C.Monto
		   , C.IdTarjetaCreditoMaestra
	FROM @MovInteresesCorrientes C;  

	INSERT INTO [dbo].[MovimientosInteresesMortatorios]
	(
	  IdTipoDeMovimientoMoratorio
	  , IdEstadoDeCuenta
	  , Fecha
	  , Monto
	  , IdTarjetaCreditoMaestra
	)
	SELECT C.IdTipoDeMovimiento
	       , @IdNuevoEC 
		   , C.Fecha
		   , C.Monto
		   , C.IdTarjetaCreditoMaestra
	FROM @MovInteresesMoratorios C; 
	


	--Ahora insertemos la nueva TF, en caso de haber habido una creacion 


	
	INSERT INTO dbo.TarjetaFisica
	(
		IdTarjeta
		, Numero
		, CCV
		, Pin
		, FechaCreacion
		, FechaVencimiento
		, EsValida
	)
	SELECT TF.IdTarjeta
	       , TF.Numero 
		   , TF.CCV
		   , TF.Pin
		   , TF.FechaCreacion
		   , TF.FechaVencimiento
		   , TF.EsValida
	FROM @NuevaTF TF;

	UPDATE dbo.TarjetaFisica
	SET EsValida = CASE
						WHEN @EsValida = 0 THEN 0
						ELSE EsValida
					END;


	--#4 ahora toca hacer los updates a las ECs y TCM

	--Actualizamos la TCM, va a variar depende de si es dia de cierre de EC


	UPDATE [dbo].[TarjetaCreditoMaestra]
	SET 
		SaldoActual =  @SaldoActual
		, SumaDeMovimientosEnTransito = @SumaMovimientos
		, SaldoInteresesCorrientes =  @SaldoInteresesCorrientes
		, SaldoInteresMoratorios = @SaldoInteresMoratorios
		, PagoAcumuladosDelPeriodo = @PagoAcumuladosDelPeriodo
	WHERE 
	IdTarjeta = @IdTCM;



	--Ahora actualizemos el Nuevo EC 
	UPDATE [dbo].[EstadoDeCuenta]
	SET InteresesMoratorios = @SaldoInteresMoratorios
		, InteresesCorrientes = @SaldoInteresesCorrientes
		, CantidadOperacionesATM = @TCMOperacionesATM
		, CantidadOperacionesVentana = @TCMOperacionesVentana
		, SumaDePagos = @PagoAcumuladosDelPeriodo
		, CantidadDePagos = @TCMQDePagos
		, SumaDeCompras = @TCMSumaDeCompras
		, CantidadDeCompras = @TCMQDeCompras
		, SumaDeRetiros = @TCMSumaDeRetiros
		, CantidadDeRetiros = @TCMQDeRetiros
		, SumaDeCreditos = @TCMSumaDeCreditos
		, CantidadDeCreditos = @TCMQDeCreditos
		, SumaDeDebitos = @TCMSumaDeDebitos 
		, CantidadDeDebitos = @TCMQDeDebitos
	WHERE Id = @IdNuevoEC  


	UPDATE [dbo].[EstadoDeCuentaAdicional]
	SET CantidadOperacionesATM = @TCAOperacionesATM
	    , CantidadOperacionesVentana = @TCAOperacionesVentana
		, SumaDeCompras = @TCASumaDeCompras
		, CantidadDeCompras = @TCAQDeCompras 
		, SumaDeRetiros = @TCASumaDeRetiros
		, CantidadDeRetiros = @TCAQDeRetiros
		, SumaDeCreditos = @TCASumaDeCreditos 
		, SumaDeDebitos = @TCASumaDeDebitos 
	WHERE Id = @IdECdeTCA;


	--Tambien actualizemos el EC adicional (En caso de ser necesario)
	--Hacemos las actualizaciones necesarias al viejo EC

	UPDATE [dbo].[EstadoDeCuenta]
	SET CantidadDeCreditos =  @QCreditosFechaFin
		, SumaDeCreditos = @SumaCreditosFechaFin
		, CantidadDeDebitos = @QDebitosFechaFin
		, SumaDeDebitos = @SumaDebitosFechaFin
	WHERE Id = @IdViejoEC



	COMMIT TRANSACTION
    
    END TRY

    BEGIN CATCH

		SELECT @@TRANCOUNT as trans;
        IF(@@TRANCOUNT > 0)
        BEGIN
            ROLLBACK;
        END;


		SELECT @IdTCA laTCA; 

		SELECT *  FROM [dbo].[EstadoDeCuentaAdicional] EC
		WHERE EC.IdTCA = @IdTCA 
		AND EC.FechaFin >= @InFechaHoy
		AND EC.FechaInicio <= @InFechaHoy
        
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