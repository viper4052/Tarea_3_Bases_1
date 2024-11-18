using System.ComponentModel.DataAnnotations;
using System.ComponentModel;
using System.Globalization;

namespace Tarea_3_BD.Pages.Model
{
    public class Movimiento
    {
        [DisplayName("TipoDeMovimiento")]
        [Required]
        public string TipoMovimiento { get; set; }
        
        [DisplayName("Fecha")]
        [Required]
        public DateOnly Fecha { get; set; }

        [DisplayName("Monto")]
        [Required]
        public decimal Monto { get; set; }

        [DisplayName("Saldo")]
        [Required]
        public float NuevoSaldo { get; set; }

        [DisplayName("Descripcion")]
        [Required]
        public string Descripcion { get; set; }

        [DisplayName("Referencia")]
        [Required]
        public string Referencia { get; set; }

    }
}
