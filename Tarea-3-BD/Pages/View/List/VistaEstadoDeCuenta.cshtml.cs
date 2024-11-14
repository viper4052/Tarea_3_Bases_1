using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.Data;
using System.Data.SqlClient;
using Tarea_3_BD.Pages.Model;

namespace Tarea_3_BD.Pages.View.List
{
    public class VistaEstadoDeCuentaModel : PageModel
    {
        public List<EstadoDeCuentaModel> listaEstadoDeCuenta = new List<EstadoDeCuentaModel>();
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

            using (SQL.connection)
            {

                int resultCode = ListarEstadoDeCuenta();

                if (resultCode != 0)
                {
                    errorMessage = SQL.BuscarError(resultCode);
                }

            }
        }

        public int ListarEstadoDeCuenta()
        {
            string username = (string)HttpContext.Session.GetString("Username");

            SQL.Open();
            SQL.LoadSP("[dbo].[ObtieneEstadoDeCuenta]");
            SQL.OutParameter("@OutResultCode", SqlDbType.Int, 0);

            Console.WriteLine("Usuario actual: " + username);
            SQL.InParameter("@InIdTCM", 7, SqlDbType.Int); // el error esta en el segundo parametro


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
                listaEstadoDeCuenta = new List<EstadoDeCuentaModel>();
                while (dr.Read())
                {
                    EstadoDeCuentaModel nED = new EstadoDeCuentaModel();

                    nED.FechaEstadoCuenta = dr.GetDateTime(1);
                    nED.PagoMinimo = (decimal)dr.GetSqlMoney(2);
                    nED.PagoContado = (decimal)dr.GetSqlMoney(3);
                    nED.InteresesCorrientes = (decimal)dr.GetSqlMoney(4);
                    nED.InteresesMoratorios = (decimal)dr.GetSqlMoney(5);
                    nED.CantidadOperacionesATM = dr.GetInt32(6);
                    nED.CantidadOperacionesVentanilla = dr.GetInt32(7);

                    listaEstadoDeCuenta.Add(nED);
                }

                SQL.Close();
                return resultCode;
            }
        }
    }
        
}
