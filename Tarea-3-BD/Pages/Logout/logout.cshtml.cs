using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.Data;
using Tarea_3_BD.Pages.Model;
using static System.Runtime.InteropServices.JavaScript.JSType;

namespace Tarea_3_BD.Pages.Logout
{
    public class logoutModel : PageModel
    {
        ConnectSQL SQL = new ConnectSQL();  

        public IActionResult OnGet()
        {

                return RedirectToPage("/LogIn/LogIn");
        }
    }
}
