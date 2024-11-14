using System.ComponentModel.DataAnnotations;
using System.ComponentModel;

namespace Tarea_3_BD.Pages.Model
{
    public class TFModel
    {
        [DisplayName("IdTarjeta")]
        public int IdTarjeta { get; set; }


        [DisplayName("Numero")]
        //[Required]
        public int Numero { get; set; }

        [DisplayName("CCV")]
        //[Required]
        public int CCV { get; set; }


        [DisplayName("Pin")]
        [Required]
        public int Pin { get; set; }

        [DisplayName("FechaCreacion")]
        [Required]
        public DateTime FechaCreacion { get; set; }


        [DisplayName("FechaVencimiento")]
        [Required]
        public DateTime FechaVencimiento { get; set; }

        [DisplayName("EsValida")]
        [Required]
        public bool EsValida { get; set; }
    }
}
