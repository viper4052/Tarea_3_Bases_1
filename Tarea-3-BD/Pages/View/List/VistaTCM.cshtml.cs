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

            using (SQL.connection)
            {

                int resultCode = ListarEstadosDeCuenta(user);

                if (resultCode != 0)
                {
                    errorMessage = SQL.BuscarError(resultCode);
                }

            }

        }

        // OnPost de prueba para ir a la vista de estado de cuenta
        public ActionResult OnPost()
        {
            // faltan asegurarse de traer el estado de cuenta de la TCM o TCA
            return RedirectToPage("/View/List/VistaEstadoDeCuenta");
        }



        public ActionResult OnPost(string username)
        {
            using (SQL.connection)
            {
                int outResultCode = 0;

                if (outResultCode != 0)
                {

                    errorMessage = SQL.BuscarError(outResultCode);

                    return Page();
                }
                else
                {
                    HttpContext.Session.SetString("Username", username);

                    return RedirectToPage("/View/List/VistaEstadoDeCuenta");
                }

            }
        }

        public int ListarEstadosDeCuenta(string user)
        {
            SQL.Open();
            SQL.LoadSP("[dbo].[ObtieneEstadoDeCuentaTCM_2]");

            SQL.OutParameter("@OutTipoUsuario", SqlDbType.Int, 0);

            SQL.InParameter("@InUsername", user, SqlDbType.VarChar);
            using (SqlDataReader dr = SQL.command.ExecuteReader())
            {
                int resultCode = 0;

                if (dr.Read()) // primero verificamos si el resultcode es positivo
                {
                    resultCode = dr.GetInt32(0);

                    if (resultCode == 0)
                    {
                        Console.WriteLine("Traida de datos exitosa");
                    }
                    else
                    {
                        SQL.Close();
                        return resultCode;
                    }

                }

                dr.NextResult(); // ya que leimos el outResultCode, leeremos los datos del dataset
                //List<TFModel> listaTodasTarjetasMaestras = new List<TFModel>();
                listaEstadosDeCuenta = new List<EstadoDeCuentaModel>();

                while (dr.Read())
                {
                    EstadoDeCuentaModel EC = new EstadoDeCuentaModel();
                    EC.FechaEstadoCuenta = dr.GetDateTime(0);
                    EC.PagoMinimo = dr.GetInt32(1);
                    EC.PagoContado = dr.GetInt32(2);
                    EC.InteresesCorrientes = dr.GetInt32(3);
                    EC.InteresesMoratorios = dr.GetInt32(4);
                    EC.CantidadOperacionesATM = dr.GetInt32(5);
                    EC.CantidadOperacionesVentanilla = dr.GetInt32(6);

                    listaEstadosDeCuenta.Add(EC);
                }
                SQL.Close();
                return 0;
            }

        }

    }
}