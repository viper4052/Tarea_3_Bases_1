using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.Data;
using System.Data.SqlClient;
using System.Threading.RateLimiting;
using Tarea_3_BD.Pages.Model;

namespace Tarea_3_BD.Pages.View.List
{
    public class VistaAdminModel : PageModel
    {
        public string errorMessage = "";
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

            using (SQL.connection)
            {


                int resultCode = ListarTarjetas();

                if (resultCode != 0)
                {
                    errorMessage = SQL.BuscarError(resultCode);
                }

            }

        }


        public string ValidaT(int num)
        {
            if (num == 0)
            {
                return "Inválida";
            }
            else
            {
                return "Válida";
            }
        }


        public ActionResult OnPost()
        {
            string idTarjeta = Request.Form["IdTarjetaActual"];
            // faltan condicionales, que si la tarjeta es TCM o TCA
            // return RedirectToPage("/View/List/VistaTCA"); // si es TCA
            return RedirectToPage("/View/List/VistaTCM"); // si es TCM
        }
        
        public int ListarTCMS()
        {
            SQL.Open();
            SQL.LoadSP("[dbo].[ObtieneTCM_2]");

            SQL.OutParameter("@OutTipoUsuario", SqlDbType.Int, 0);
            SQL.OutParameter("@IdTCM", SqlDbType.Int, 0);

            SQL.InParameter("@InUsername", "", SqlDbType.VarChar); // no va a buscar ningun usuario en especifico


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
                List<TFModel> listaTodasTarjetasMaestras = new List<TFModel>();

                while (dr.Read())
                {
                    TFModel tarjeta = new TFModel();
                    tarjeta.IdTarjeta = (int)SQL.command.Parameters["@IdTCM"].Value;
                    tarjeta.Numero = dr.GetInt32(0);
                    tarjeta.EsValida = ValidaT(dr.GetInt32(1));
                    tarjeta.TipoCuenta = "TCM";
                    tarjeta.FechaVencimiento = dr.GetDateTime(2);


                    listaTodasTarjetas.Add(tarjeta);
                }   
                SQL.Close();
                return 0;
            }
                
        }


        public int ListarTCAS()
        {
            SQL.Open();
            SQL.LoadSP("[dbo].[ObtieneTCA_2]");

            SQL.OutParameter("@OutTipoUsuario", SqlDbType.Int, 0);
            SQL.OutParameter("@IdTCM", SqlDbType.Int, 0);

            SQL.InParameter("@InUsername", "", SqlDbType.VarChar); // no va a buscar ningun usuario en especifico


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

                dr.NextResult(); // ya que leimos el outResultCode, leeremos los datos del dataser
                List<TFModel> listaTodasTarjetasMaestras = new List<TFModel>();

                while (dr.Read())
                {
                    TFModel tarjeta = new TFModel();
                    //tarjeta.IdTarjeta = (int)SQL.command.Parameters["@IdTCA"].Value;
                    tarjeta.Numero = dr.GetInt32(0);
                    tarjeta.EsValida = ValidaT(dr.GetInt32(1));
                    tarjeta.TipoCuenta = "TCA";
                    tarjeta.FechaVencimiento = dr.GetDateTime(2);


                    listaTodasTarjetas.Add(tarjeta);
                }
                SQL.Close();
                return 0;
            }

        }
    

        public int ListarTarjetas()
        {
            ListarTCMS();
            ListarTCAS();
            return 0;
        }
        
    }
    
}
