using System.ComponentModel.DataAnnotations;
using System.ComponentModel;

namespace Tarea_3_BD.Pages.Model
{
	public class TCMmodel
	{
		[DisplayName("IdTarjetaHabiente")]
		public int IdTarjetaHabiente { get; set; }

		
		[DisplayName("IdTipoTCM")]
		[Required]
		public int IdTipoTCM { get; set; }

		
		[DisplayName("LimiteCredito")]
		[Required]
		public int LimiteCredito { get; set; }

		[DisplayName("SaldoActual")]
		[Required]
		public decimal SaldoActual { get; set; }


		[DisplayName("SumaDeMovimientos")]
		[Required]
		public decimal SumaDeMovimientos { get; set; }

		[DisplayName("SaldoInteresesCorrientes")]
		[Required]
		public decimal SaldoInteresesCorrientes { get; set; }


		[DisplayName("SaldoInteresMoratorios")]
		[Required]
		public decimal SaldoInteresMoratorios { get; set; }


		[DisplayName("SaldoPagoMinimo")]
		[Required]
		public decimal SaldoPagoMinimo { get; set; }

		[DisplayName("PagosAcumuladoDelPeriodo")]
		[Required]
		public decimal PagosAcumuladoDelPeriodo { get; set; }

	}
}
