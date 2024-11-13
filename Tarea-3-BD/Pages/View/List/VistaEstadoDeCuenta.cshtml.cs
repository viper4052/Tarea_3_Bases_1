using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.Data;
using Tarea_3_BD.Pages.Model;

namespace Tarea_3_BD.Pages.View.List
{
    public class VistaEstadoDeCuentaModel : PageModel
    {
        public Usuario user = new Usuario();
        public String errorMessage = "";
        public ConnectSQL SQL = new ConnectSQL();
        public String Ip;

        public void OnGet()
        {
            ViewData["ShowLogoutButton"] = true;
            Ip = HttpContext.Connection.RemoteIpAddress?.ToString();
            string user = (string)HttpContext.Session.GetString("Usuario");
            Console.WriteLine(user);
        }

    }
        
}
