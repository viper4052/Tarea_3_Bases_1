using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Tarea_3_BD.Pages.Model;

namespace Tarea_3_BD.Pages.View.List
{
    public class VistaTCAModel : PageModel
    {
        public string errorMessage = "";
        public List<int> listaTCM = new List<int>();
        public List<EstadoDeCuentaModel> listaEstadosDeCuenta = new List<EstadoDeCuentaModel>();
        public ConnectSQL SQL = new ConnectSQL();
        public string Ip;

        public string SuccessMessage { get; set; }
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
