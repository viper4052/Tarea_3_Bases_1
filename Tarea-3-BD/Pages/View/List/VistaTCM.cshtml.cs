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
        public string SuccessMessage { get; set; }

        public void OnGet()
        {

            ViewData["ShowLogoutButton"] = true;

            using (SQL.connection)
            {
                int resultCode = ListarEstadosDeCuenta((string)HttpContext.Session.GetString("Username"));

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
            return RedirectToPage("/View/List/MovimientosTCM");
        }


        public int ListarEstadosDeCuenta(string user)
        {
            SQL.Open();
            SQL.LoadSP("[dbo].[ObtieneEstadoDeCuentaTCM]");

            SQL.OutParameter("@OutResultCode", SqlDbType.Int, 0);

            int IdTarjeta;
            IdTarjeta = 1;

            try
            {
                string IdTarjetaSession = HttpContext.Session.GetString("IdTarjeta");
                if (!string.IsNullOrEmpty(IdTarjetaSession))
                {
                    IdTarjeta = Convert.ToInt32(IdTarjetaSession);
                }
            }
            catch
            {
                Console.WriteLine("Error parseando a int");
            }

            SQL.InParameter("@InIdTCM", IdTarjeta, SqlDbType.Int);



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

                listaEstadosDeCuenta = new List<EstadoDeCuentaModel>();

                while (dr.Read())
                {
                    EstadoDeCuentaModel EC = new EstadoDeCuentaModel();
                    EC.FechaEstadoCuenta = dr.GetDateTime(0);
                    EC.PagoMinimo = (float)dr.GetDecimal(1);
                    EC.PagoContado = (float)dr.GetDecimal(2);
                    EC.InteresesCorrientes = (float)dr.GetDecimal(3);
                    EC.InteresesMoratorios = (float)dr.GetDecimal(4);
                    EC.CantidadOperacionesATM = dr.GetInt32(5);
                    EC.CantidadOperacionesVentanilla = dr.GetInt32(6);
                    EC.Id = dr.GetInt32(7);

                    listaEstadosDeCuenta.Add(EC);
                }
                SQL.Close();
                return 0;
            }

        }

    }
}