using System.ComponentModel.DataAnnotations;
using System.ComponentModel;
using System.Globalization;

namespace Tarea_3_BD.Pages.Model
{
    public class Movimiento
    {
        [DisplayName("TipoDeMovimiento")]
        [Required]
        public string tipoMovimiento { get; set; }
        
        [DisplayName("Fecha")]
        [Required]
        public DateTime Fecha { get; set; }

        [DisplayName("EstampaDeTiempo")]
        [Required]
        public TimeOnly Estampa{ get; set; }

        [DisplayName("Monto")]
        [Required]
        public decimal Monto { get; set; }

        [DisplayName("Saldo")]
        [Required]
        public decimal NuevoSaldo { get; set; }

        [DisplayName("Usuario")]
        [Required]
        public string NombreUsuario { get; set; }
        
        [DisplayName("Ip")]
        [Required]
        public string ipAdress { get; set; }

    }
}
