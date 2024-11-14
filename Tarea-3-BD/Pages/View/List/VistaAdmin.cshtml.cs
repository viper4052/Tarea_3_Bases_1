using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Tarea_3_BD.Pages.Model;

namespace Tarea_3_BD.Pages.View.List
{
    public class VistaAdminModel : PageModel
    {
        public string errorMessage = "";
        // CAMBIAR EL TIPADO DE LA LISTA
        public List<TFModel> listaTodasTarjetas = new List<TFModel>(); // esta lista va a contener todas las Tarjetas de un usuario
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
