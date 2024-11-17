using System.ComponentModel.DataAnnotations;
using System.ComponentModel;

namespace Tarea_3_BD.Pages.Model
{
	public class EstadoDeCuentaAdicionalModel
	{
        [DisplayName("Id")]
        //[Required]
        public int Id { get; set; }

        [DisplayName("FechaEstadoCuenta")]
        public DateTime FechaEstadoCuenta { get; set; }

        [DisplayName("CantidadDeCompras")]
        //[Required]
        public int CantidadDeCompras { get; set; }

        [DisplayName("SumaDeCompras")]
        //[Required]
        public float SumaDeCompras { get; set; }


        [DisplayName("CantidadDeRetiros")]
        [Required]
        public int CantidadDeRetiros { get; set; }


        [DisplayName("SumaDeRetiros")]
        [Required]
        public float SumaDeRetiros { get; set; }


        [DisplayName("CantidadOperacionesATM")]
        [Required]
        public int CantidadOperacionesATM { get; set; }


        [DisplayName("CantidadOperacionesVentanilla")]
        [Required]
        public int CantidadOperacionesVentanilla { get; set; }

    }
}
