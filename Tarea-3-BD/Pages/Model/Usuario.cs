using System.ComponentModel.DataAnnotations;
using System.ComponentModel;

namespace Tarea_3_BD.Pages.Model
{
    public class Usuario
    {
        [Key]
        public int Id { get; set; }

        [DisplayName("Nombre")]
        [Required] 
        public String Username { get; set; }

        [DisplayName("Password")]
        [Required]
        public String Pass { get; set; }
    }
}
