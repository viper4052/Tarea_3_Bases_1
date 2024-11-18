using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace Tarea_3_BD.Pages.View.List
{
    public class MovimientosTCMModel : PageModel
    {
        public void OnGet()
        {
            ViewData["ShowLogoutButton"] = true;
        }
    }
}
