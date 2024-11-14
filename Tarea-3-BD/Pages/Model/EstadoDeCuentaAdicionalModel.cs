using System.ComponentModel.DataAnnotations;
using System.ComponentModel;

namespace Tarea_3_BD.Pages.Model
{
	public class EstadoDeCuentaAdicionalModel
	{
        [DisplayName("FechaDeOperacion")]
        public DateTime FechaDeOperacion { get; set; }


        [DisplayName("NombreTipoDeMovimiento")]
        [Required]
        public string NombreTipoDeMovimiento { get; set; }

        [DisplayName("Descripcion")]
        [Required]
        public string Descripcion { get; set; }


        [DisplayName("Referencia")]
        [Required]
        public string Referencia { get; set; }

        [DisplayName("Monto")]
        [Required]
        public decimal Monto { get; set; }


        [DisplayName("NuevoSaldo")]
        [Required]
        public decimal NuevoSaldo { get; set; }

    }
}
