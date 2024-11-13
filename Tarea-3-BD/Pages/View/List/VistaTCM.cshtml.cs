using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.Data.SqlClient;
using System.Data;
using Tarea_3_BD.Pages.Model;

namespace Tarea_3_BD.Pages.View.List
{
    public class VistaTCMModel : PageModel
    {
        public Usuario user = new Usuario();
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

        public int ObtieneTipoUsuario() // asigna el tipo de usuario para esta vista
        {
			SQL.Open();
			SQL.LoadSP("[dbo].[VerificaUsuario]");

			SQL.InParameter("@InUsername", user.Username, SqlDbType.VarChar);

			SQL.ExecSP();
			SQL.Close();

            tipoDeUsuario = (int)SQL.command.Parameters["@TipoDeUsuario"].Value;

			return 0;

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
                    HttpContext.Session.SetString("Username", user.Username);

                    return RedirectToPage("/View/List/VistaEstadoDeCuenta");
                }

            }
        }


        public int ListarTCMs ()
        {
            SQL.Open();
            SQL.LoadSP("[dbo].[ObtieneTCM]");

            SQL.OutParameter("@OutResultCode", SqlDbType.Int, 0);


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
