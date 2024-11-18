using System.ComponentModel.DataAnnotations;
using System.ComponentModel;

namespace Tarea_3_BD.Pages.Model
{
    public class EstadoDeCuentaModel
    {
        [DisplayName("Id")]
        //[Required]
        public int Id { get; set; }

        [DisplayName("FechaEstadoCuenta")]
        public DateOnly FechaEstadoCuenta { get; set; }


        [DisplayName("PagoMinimo")]
        //[Required]
        public float PagoMinimo { get; set; }

        [DisplayName("PagoContado")]
        //[Required]
        public float PagoContado { get; set; }


        [DisplayName("InteresesCorrientes")]
        [Required]
        public float InteresesCorrientes { get; set; }


        [DisplayName("InteresesMoratorios")]
        [Required]
        public float InteresesMoratorios { get; set; }


        [DisplayName("CantidadOperacionesATM")]
        [Required]
        public int CantidadOperacionesATM { get; set; }


        [DisplayName("CantidadOperacionesVentanilla")]
        [Required]
        public int CantidadOperacionesVentanilla { get; set; }


    }
}
