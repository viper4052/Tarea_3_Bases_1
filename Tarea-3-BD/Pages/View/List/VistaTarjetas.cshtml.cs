using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.Data;
using System.Data.SqlClient;
using System.Threading.RateLimiting;
using Tarea_3_BD.Pages.Model;

namespace Tarea_3_BD.Pages.View.List
{
    public class VistaTarjetasModel : PageModel
    {
        public string errorMessage = "";
        public List<TFModel> listaTodasTarjetas = new List<TFModel>(); // esta lista va a contener todas las Tarjetas de un usuario
        public ConnectSQL SQL = new ConnectSQL();

        public string SuccessMessage { get; set; }


        public void OnGet()
        {
            ViewData["ShowLogoutButton"] = true;
            string user = (string)HttpContext.Session.GetString("Username");
            Console.WriteLine(user);

            using (SQL.connection)
            {


                int resultCode = ListarTFs();

                if (resultCode != 0)
                {
                    errorMessage = "Error en la traida de datos";
                }

            }

        }


        public ActionResult OnPost()
        {
            string idTarjeta = Request.Form["IdTarjetaActual"];
            string tipoDeTarjeta = Request.Form["TipoDeTarjeta"];


            HttpContext.Session.SetString("IdTarjeta", idTarjeta);


            if (tipoDeTarjeta == "TCM")
            {
                return RedirectToPage("/View/List/VistaTCM"); // si es TCM
            }
            return RedirectToPage("/View/List/VistaTCA"); // si es TCA

        }

    
        public int ListarTFs()
        {
            SQL.Open();
            SQL.LoadSP("[dbo].[ObtieneTFs]");

            
            SQL.OutParameter("@OutResultCode", SqlDbType.Int, 0);

			int tipoDeUsuario;
			tipoDeUsuario = 1;

			try
			{
				string tipoDeUsuarioSession = HttpContext.Session.GetString("tipoDeUsuario");
				if (!string.IsNullOrEmpty(tipoDeUsuarioSession))
				{
					tipoDeUsuario = Convert.ToInt32(tipoDeUsuarioSession);
				}
			}
			catch
			{
				Console.WriteLine("Error parseando a int");
			}


			SQL.InParameter("@InUsername", (string)HttpContext.Session.GetString("Username"), SqlDbType.VarChar);
			SQL.InParameter("@InTipoUsuario", tipoDeUsuario, SqlDbType.Int);



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
                    
                    tarjeta.Numero = dr.GetInt64(0);
                    tarjeta.EsValida = dr.GetString(1);
					tarjeta.FechaVencimiento = dr.GetDateTime(2);
					tarjeta.TipoCuenta = dr.GetString(3);
					tarjeta.IdTarjeta = dr.GetInt32(4);


					listaTodasTarjetas.Add(tarjeta);
                }
                SQL.Close();

                return 0;
            }

        }
   
        
    }
    
}
