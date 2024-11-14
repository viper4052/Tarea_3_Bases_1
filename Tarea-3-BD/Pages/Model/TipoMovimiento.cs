using System.ComponentModel.DataAnnotations;
using System.ComponentModel;

namespace Tarea_3_BD.Pages.Model
{
	public class TipoMovimiento
	{
		[DisplayName("Nombre")]
		[Required]
		public string Nombre { get; set; }

		[DisplayName("accion")]
		[Required]
		public string Accion { get; set; }
	}
}
