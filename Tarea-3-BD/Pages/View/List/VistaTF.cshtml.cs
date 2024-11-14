using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.Data.SqlClient;
using System.Data;
using Tarea_3_BD.Pages.Model;

namespace Tarea_3_BD.Pages.View.List
{
    public class VistaTFModel : PageModel
    {

        public string errorMessage = "";
        public List<TFModel> listaTF = new List<TFModel>();
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

                int resultCode = ListarTFs();

                if (resultCode != 0)
                {
                    errorMessage = SQL.BuscarError(resultCode);
                }

            }
        }


        public ActionResult OnPost()
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
                    //HttpContext.Session.SetString("Username", username);

                    return RedirectToPage("/View/List/VistaTCM");
                }

            }
        }
        public int ListarTFs()
        {
            string username = (string)HttpContext.Session.GetString("Username");

            SQL.Open();
            SQL.LoadSP("[dbo].[ObtieneTCM]");
            SQL.OutParameter("@OutTipoUsuario", SqlDbType.Int, 0);

            Console.WriteLine("Usuario actual: " + username);
            SQL.InParameter("@InUsername", username, SqlDbType.VarChar); // el error esta en el segundo parametro


            // habiendo ya cargado los posibles parametros entonces podemos llamar al SP
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
                listaTF = new List<TFModel>();
                while (dr.Read())
                {
                    TFModel nTF = new TFModel();
                    nTF.IdTarjeta = dr.GetInt32(0);
                    nTF.Numero = dr.GetInt32(1);
                    nTF.EsValida = dr.GetBoolean(2);
                    nTF.FechaVencimiento = dr.GetDateTime(3);
                   
                    listaTF.Add(nTF);
                }

                SQL.Close();
                return resultCode;
            }
        }

    }
}