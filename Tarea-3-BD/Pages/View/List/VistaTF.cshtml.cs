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
        // CAMBIAR EL TIPADO DE LA LISTA
        public List<TFModel> listaTarjetas = new List<TFModel>(); // esta lista va a contener todas las Tarjetas de un usuario
        public ConnectSQL SQL = new ConnectSQL();
        public string Ip;

        public string SuccessMessage { get; set; }

        public void OnGet(string username)
        {
            ViewData["ShowLogoutButton"] = true;
            Ip = HttpContext.Connection.RemoteIpAddress?.ToString();
            string user = (string)HttpContext.Session.GetString("Username");
            Console.WriteLine(user);

            Console.WriteLine("Usuario actual: " + user);

            using (SQL.connection)
            {

                int resultCode = ListarTarjetas(user);

                if (resultCode != 0)
                {
                    errorMessage = SQL.BuscarError(resultCode);
                }

            }

        }


        public ActionResult OnPost()
        {
            // faltan condicionales para decir si la tarjeta es TCM o TCA
            // el botón tiene un value de IdTarjeta entonces así puede encontrarse si es TCM o TCA
            
            return RedirectToPage("/View/List/VistaTCA"); // return de prueba para asegurarse que la consulta a movimientos es posible
            //return RedirectToPage("/View/List/VistaTCM"); // ambas páginas sirven bien, es la definición y traída de datos que no las lee bien
        }


        public int ListarTCMS(string user)
        {
            SQL.Open();
            SQL.LoadSP("[dbo].[ObtieneTCM_2]");

            SQL.OutParameter("@OutTipoUsuario", SqlDbType.Int, 0);
            SQL.OutParameter("@IdTCM", SqlDbType.Int, 0);

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

                dr.NextResult(); // ya que leimos el outResultCode, leeremos los datos del dataser
                listaTarjetas = new List<TFModel>();
                
                while (dr.Read())
                {
                    TFModel tarjeta = new TFModel();
                    //tarjeta.IdTarjeta = (int)SQL.command.Parameters["@IdTCM"].Value;
                    tarjeta.Numero = dr.GetInt32(0);
                    tarjeta.EsValida = ValidaT(dr.GetInt32(1));
                    tarjeta.TipoCuenta = "TCM";
                    tarjeta.FechaVencimiento = dr.GetDateTime(2);
                    

                    listaTarjetas.Add(tarjeta);
                }

                SQL.Close();
                return resultCode;
            }
        }



        public int ListarTCAS(string user)
        {
            SQL.Open();
            SQL.LoadSP("[dbo].[ObtieneTCA_2]");

            SQL.OutParameter("@OutTipoUsuario", SqlDbType.Int, 0);
            SQL.OutParameter("@IdTCA", SqlDbType.Int, 0);

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

                dr.NextResult(); // ya que leimos el outResultCode, leeremos los datos del dataser
                //listaTarjetas = new List<TFModel>(); // comentado para no sobreescribir los datos leídos y almacenados de antes
                
                while (dr.Read())
                {
                    TFModel tarjeta = new TFModel();
                    //tarjeta.IdTarjeta = (int)SQL.command.Parameters["@IdTCA"].Value;
                    tarjeta.Numero = dr.GetInt32(0);
                    tarjeta.EsValida = ValidaT(dr.GetInt32(1));
                    tarjeta.TipoCuenta = "TCA";
                    tarjeta.FechaVencimiento = dr.GetDateTime(2);


                    listaTarjetas.Add(tarjeta);
                }

                SQL.Close();
                return resultCode;
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


        public int ListarTarjetas(string user)
        {
            ListarTCMS(user);
            ListarTCAS(user);
            return 0;
        }

    }
}