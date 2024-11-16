using System.ComponentModel.DataAnnotations;
using System.ComponentModel;

namespace Tarea_3_BD.Pages.Model
{
    public class TFModel // modelo de tarjeta general para display de admin y usuario
    {
        [DisplayName("IdTarjeta")]
        public int IdTarjeta { get; set; }


        [DisplayName("Numero")]
        //[Required]
        public int Numero { get; set; }

        
        [DisplayName("EsValida")]
        [Required]
        public string EsValida { get; set; }

        
        [DisplayName("TipoCuenta")]
        [Required]
        public string TipoCuenta { get; set; }

        
        [DisplayName("FechaVencimiento")]
        [Required]
        public DateTime FechaVencimiento { get; set; }

        
    }
}
