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
        public int tipoDeUsuario = 0;

        public string SuccessMessage { get; set; }

        public void OnGet(string username)
        {
            ViewData["ShowLogoutButton"] = true;
            Ip = HttpContext.Connection.RemoteIpAddress?.ToString();
            string user = (string)HttpContext.Session.GetString("Username");
            Console.WriteLine(user);

            Console.WriteLine("Usuario actual: " + username);


            using (SQL.connection)
            {

                int resultCode = ListarTCMs(); 

                if (resultCode != 0)
                {
                    errorMessage = SQL.BuscarError(resultCode);
                }

            }

        }

        public int ObtieneTipoUsuario(string username) // asigna el tipo de usuario para esta vista
        {
			SQL.Open();
			SQL.LoadSP("[dbo].[VerificaUsuario]");
            SQL.OutParameter("@OutTipoUsuario", SqlDbType.Int, 0);
			
            SQL.InParameter("@InUsername", username, SqlDbType.VarChar);

			SQL.ExecSP();

            tipoDeUsuario = (int)SQL.command.Parameters["@OutTipoUsuario"].Value;
            SQL.Close();

            return 0;

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


        public int ListarTCMs ()
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
                listaTCM = new List<TCMmodel>();
                while (dr.Read())
                {
                    TCMmodel nTCM = new TCMmodel();
                    nTCM.IdTipoTCM = dr.GetInt32(0);
                    nTCM.IdTarjetaHabiente = dr.GetInt32(1);
                    nTCM.LimiteCredito = dr.GetInt32(2);
                    nTCM.SaldoActual = (decimal)dr.GetSqlMoney(3);
                    nTCM.SumaDeMovimientos = (decimal)dr.GetSqlMoney(4);
                    nTCM.SaldoInteresesCorrientes = (decimal)dr.GetSqlMoney(5);
                    nTCM.SaldoInteresMoratorios = (decimal)dr.GetSqlMoney(6);
                    nTCM.SaldoPagoMinimo = (decimal)dr.GetSqlMoney(7);
                    nTCM.PagosAcumuladoDelPeriodo = (decimal)dr.GetSqlMoney(8);

					// ---------------------- SI ES TCM
					// fecha estado de cuenta
					// pago minimo
					// pago de contado
					// intereses corrientes
					// intereses moratorios
					// cantidad operaciones atm
					// cantidad operaciones en ventanilla

					// ---------------------- SI ES TCA
                    // fecha estado de cuenta
                    // cantidad operaciones ATM
                    // cantidad operaciones en Ventanilla
                    // cantidad de compras
                    // suma de compras
                    // cantidad de retiros
                    // suma de los retiros

					listaTCM.Add(nTCM);
                }

                SQL.Close();
                return resultCode;
            }
        }

    }
}
