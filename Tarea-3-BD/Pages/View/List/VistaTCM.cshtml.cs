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
        public List<TCMmodel> listaTCM = new List<TCMmodel>();
        public ConnectSQL SQL = new ConnectSQL();
        public string Ip;

        public string SuccessMessage { get; set; }

        public void OnGet(string username)
        {
            ViewData["ShowLogoutButton"] = true;
            Ip = HttpContext.Connection.RemoteIpAddress?.ToString();
            string user = (string)HttpContext.Session.GetString("Usuario");
            Console.WriteLine(user);



            using (SQL.connection)
            {

                int resultCode = ListarTCMs();

                if (resultCode != 0)
                {
                    errorMessage = SQL.BuscarError(resultCode);
                }

            }

        }


        public int ListarTCMs ()
        {
            SQL.Open();
            SQL.LoadSP("[dbo].[ObtieneTCM]");

            SQL.OutParameter("@OutResultCode", SqlDbType.Int, 0);


            //ya habiendo cargado los posibles parametros entonces podemos llamar al SP
            using (SqlDataReader dr = SQL.command.ExecuteReader())
            {
                int resultCode = 0;

                if (dr.Read()) //primero verificamos si el resultcode es positivo
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

                dr.NextResult(); //ya que leimos el outResultCode, leeremos los datos del dataser
                listaTCM = new List<TCMmodel>();
                while (dr.Read())
                {
                    TCMmodel nTCM = new TCMmodel();
                    nTCM.IdTipoTCM = dr.GetInt32(0);
                    nTCM.IdTarjetaHabiente = dr.GetInt32(1);
                    nTCM.LimiteCredito = dr.GetInt32(2);
                    nTCM.SaldoActual = (decimal)dr.GetSqlMoney(3);
                    nTCM.SumaDeMovimientos = (decimal)dr.GetInt32(4);
                    nTCM.SaldoInteresesCorrientes = (decimal)dr.GetSqlMoney(5);
                    nTCM.SaldoInteresMoratorios = (decimal)dr.GetSqlMoney(6);
                    nTCM.SaldoPagoMinimo = (decimal)dr.GetSqlMoney(7);
                    nTCM.PagosAcumuladoDelPeriodo = (decimal)dr.GetSqlMoney(8);

                    listaTCM.Add(nTCM);
                }

                SQL.Close();
                return resultCode;
            }
        }

    }
}
