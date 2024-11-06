--Calcula la fecha de cierre de un EC con base en su fecha de inicio

ALTER FUNCTION FechaDeCierre
(
    @InFechaInicio DATE  
)
RETURNS DATE  
AS
BEGIN
    
    DECLARE @OutFechaFin DATE,
			@numeroDia INT,
			@NumeroMes INT;

	--primero obtenemos que dia del mes es, cuando es 30 o 31 pasan cosas
    SET @numeroDia = DAY(@InFechaInicio);
	SET @NumeroMes = MONTH(@InFechaInicio);

	--veamos que dias hay que ajustar
	SET @OutFechaFin = 
    CASE
        WHEN @numeroDia = 31 AND DAY(EOMONTH(@InFechaInicio)) = 31 THEN DATEADD(DAY, -1, @InFechaInicio)
        WHEN @numeroDia = 30 AND DAY(EOMONTH(@InFechaInicio)) = 30 THEN  DATEADD(DAY, 1, @InFechaInicio) 
		WHEN @numeroDia = 28 AND @NumeroMes = 2 THEN  DATEADD(DAY, 3, @InFechaInicio)
		WHEN @numeroDia = 29 AND @NumeroMes = 2 THEN  DATEADD(DAY, 2, @InFechaInicio)
        ELSE @InFechaInicio  
    END;


	--ya con el dia ajustado tan solo sumamos un mes 
	SET @OutFechaFin = DATEADD(MONTH, 1, @OutFechaFin)  

    RETURN @OutFechaFin;
END;
