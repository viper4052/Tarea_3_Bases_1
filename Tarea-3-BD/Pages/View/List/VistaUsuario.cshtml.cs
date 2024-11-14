using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.Data.SqlClient;
using System.Data;
using Tarea_3_BD.Pages.Model;

namespace Tarea_3_BD.Pages.View.List
{
    public class VistaUsuarioModel : PageModel
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


            using (SQL.connection)
            {

                int resultCode = ListarTCMs();
                resultCode = ListarIdTCMs();

                if (resultCode != 0)
                {
                    errorMessage = SQL.BuscarError(resultCode);
                }

            }

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
                    //HttpContext.Session.SetString("Username", username);

                    return RedirectToPage("/View/List/VistaEstadoDeCuenta");
                }

            }
        }


        public int ListarTCMs()
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
                listaTCM = new List<int>();
                while (dr.Read())
                {
                    TCMmodel nTCM = new TCMmodel();
                    int var = dr.GetInt32(0);
                    
                    Console.WriteLine("idtarjeta: " + nTCM.IdTarjeta.ToString());

                    listaTCM.Add(var);
                }

                SQL.Close();
                return resultCode;
            }


            /*
            //SQL.Open();
            SQL.LoadSP("[dbo].[ObtieneEstadoDeCuenta]");
            SQL.OutParameter("@OutResultCode", SqlDbType.Int, 0);

            foreach (int id in listaTCM)
            {
                Console.WriteLine("Usuario actual: " + username);
                SQL.InParameter("@InIdTCM", id, SqlDbType.Int); // el error esta en el segundo parametro


                using (SqlDataReader dr = SQL.command.ExecuteReader())
                {
                    int resultCode = 0;



                    dr.NextResult(); // ya que leimos el outResultCode, leeremos los datos del dataset
                    listaEstadosDeCuenta = new List<EstadoDeCuentaModel>();
                    while (dr.Read())
                    {
                        EstadoDeCuentaModel nED = new EstadoDeCuentaModel();
                        nED.FechaEstadoCuenta = dr.GetDateTime(1);
                        nED.PagoMinimo = (decimal)dr.GetSqlMoney(2);
                        nED.PagoContado = (decimal)dr.GetSqlMoney(3);
                        nED.InteresesCorrientes = (decimal)dr.GetSqlMoney(4);
                        nED.InteresesMoratorios = (decimal)dr.GetSqlMoney(5);
                        nED.CantidadOperacionesATM = dr.GetInt32(6);
                        nED.CantidadOperacionesATM = dr.GetInt32(7);
                        nED.CantidadOperacionesVentanilla = dr.GetInt32(8);

                        listaEstadosDeCuenta.Add(nED);
                    }

                    SQL.Close();

                }
            }



            return 0;
            */
        }

        public int ListarIdTCMs()
        {
            string username = (string)HttpContext.Session.GetString("Username");

            SQL.Open();
            SQL.LoadSP("[dbo].[ObtieneEstadoDeCuenta]");
            SQL.OutParameter("@OutResultCode", SqlDbType.Int, 0);

            foreach (int id in listaTCM)
            {
                Console.WriteLine("Usuario actual: " + username);
                SQL.InParameter("@InIdTCM", id, SqlDbType.Int); // el error esta en el segundo parametro


                using (SqlDataReader dr = SQL.command.ExecuteReader())
                {
                    int resultCode = 0;



                    dr.NextResult(); // ya que leimos el outResultCode, leeremos los datos del dataset
                    listaEstadosDeCuenta = new List<EstadoDeCuentaModel>();
                    while (dr.Read())
                    {
                        EstadoDeCuentaModel nED = new EstadoDeCuentaModel();
                        nED.FechaEstadoCuenta = dr.GetDateTime(1);
                        nED.PagoMinimo = (decimal)dr.GetSqlMoney(2);
                        nED.PagoContado = (decimal)dr.GetSqlMoney(3);
                        nED.InteresesCorrientes = (decimal)dr.GetSqlMoney(4);
                        nED.InteresesMoratorios = (decimal)dr.GetSqlMoney(5);
                        nED.CantidadOperacionesATM = dr.GetInt32(6);
                        nED.CantidadOperacionesATM = dr.GetInt32(7);
                        nED.CantidadOperacionesVentanilla = dr.GetInt32(8);

                        listaEstadosDeCuenta.Add(nED);
                    }
                    SQL.Close();
                    return resultCode;
                }
            }
            return 0;
            
        }
    }
}
