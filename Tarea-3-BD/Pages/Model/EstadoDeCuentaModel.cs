using System.ComponentModel.DataAnnotations;
using System.ComponentModel;

namespace Tarea_3_BD.Pages.Model
{
    public class EstadoDeCuentaModel
    {
        [DisplayName("FechaEstadoCuenta")]
        public DateTime FechaEstadoCuenta { get; set; }


        [DisplayName("PagoMinimo")]
        //[Required]
        public decimal PagoMinimo { get; set; }

        [DisplayName("PagoContado")]
        //[Required]
        public decimal PagoContado { get; set; }


        [DisplayName("InteresesCorrientes")]
        [Required]
        public decimal InteresesCorrientes { get; set; }

        [DisplayName("InteresesMoratorios")]
        [Required]
        public decimal InteresesMoratorios { get; set; }


        [DisplayName("CantidadOperacionesATM")]
        [Required]
        public int CantidadOperacionesATM { get; set; }


        [DisplayName("CantidadOperacionesVentanilla")]
        [Required]
        public int CantidadOperacionesVentanilla { get; set; }
    }
}
