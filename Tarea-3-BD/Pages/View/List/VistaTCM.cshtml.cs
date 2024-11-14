using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.Data.SqlClient;
using System.Data;
using Tarea_3_BD.Pages.Model;

namespace Tarea_3_BD.Pages.View.List
{
    public class VistaTCMModel : PageModel
    {
        public string errorMessage = "";
        public List<EstadoDeCuentaModel> listaTCM = new List<EstadoDeCuentaModel>();
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

            //using (SQL.connection)
            //{

            //    int resultCode = ListarTCMs();
             
            //    if (resultCode != 0)
            //    {
            //        errorMessage = SQL.BuscarError(resultCode);
            //    }

            //}

        }

        // OnPost de prueba para ir a la vista de estado de cuenta
        public ActionResult OnPost()
        {
            // faltan asegurarse de traer el estado de cuenta de la TCM o TCA
            return RedirectToPage("/View/List/VistaEstadoDeCuenta");
        }



        //public ActionResult OnPost(string username)
        //{
        //    using (SQL.connection)
        //    {
        //        int outResultCode = 0;

        //        if (outResultCode != 0)
        //        {

        //            errorMessage = SQL.BuscarError(outResultCode);

        //            return Page();
        //        }
        //        else
        //        {
        //            HttpContext.Session.SetString("Username", username);

        //            return RedirectToPage("/View/List/VistaEstadoDeCuenta");
        //        }

        //    }
        //}
    }
}
