using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.Data;
using System.Data.SqlClient;
using Tarea_3_BD.Pages.Model;

namespace Tarea_3_BD.Pages.View.List
{
    public class VistaEstadoDeCuentaModel : PageModel
    {
        // creo que esta lista corresponde a una de estado de cuenta adicional? no estoy seguro
        public List<EstadoDeCuentaAdicionalModel> listaEstadosDeCuentaAdicional = new List<EstadoDeCuentaAdicionalModel>();
        public Usuario user = new Usuario();
        public String errorMessage = "";
        public ConnectSQL SQL = new ConnectSQL();
        public String Ip;

        public void OnGet()
        {
            ViewData["ShowLogoutButton"] = true;
            Ip = HttpContext.Connection.RemoteIpAddress?.ToString();
            string user = (string)HttpContext.Session.GetString("Username");
            Console.WriteLine(user);

            Console.WriteLine("Usuario actual: " + user);

        }

    }
        
}
