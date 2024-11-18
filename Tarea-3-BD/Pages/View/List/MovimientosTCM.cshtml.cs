using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Tarea_3_BD.Pages.Model;

namespace Tarea_3_BD.Pages.View.List
{
    public class MovimientosTCMModel : PageModel
    {
        public List<Movimiento> Movimientos = new List<Movimiento>();
        public void OnGet()
        {
            ViewData["ShowLogoutButton"] = true;
        }
    }
}
