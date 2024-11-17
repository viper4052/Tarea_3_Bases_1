using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.Data;
using System.Data.SqlClient;
using Tarea_3_BD.Pages.Model;

namespace Tarea_3_BD.Pages.View.List
{
    public class VistaTCAModel : PageModel
    {
        public string errorMessage = "";
        public List<EstadoDeCuentaAdicionalModel> listaEstadosDeCuenta = new List<EstadoDeCuentaAdicionalModel>();
        public ConnectSQL SQL = new ConnectSQL();

        public string SuccessMessage { get; set; }
        public void OnGet()
        {
            ViewData["ShowLogoutButton"] = true;
            string user = (string)HttpContext.Session.GetString("Username");

            using (SQL.connection)
            {


                int resultCode = ListarEstadosDeCuenta(user);

                if (resultCode != 0)
                {
                    errorMessage = SQL.BuscarError(resultCode);
                }

            }
        }

        // OnPost de prueba para ir a la vista de estado de cuenta
        public ActionResult OnPost()
        {
            return RedirectToPage("/View/List/VistaEstadoDeCuenta");
        }


        public int ListarEstadosDeCuenta(string user)
        {
            SQL.Open();
            SQL.LoadSP("[dbo].[ObtieneEstadoDeCuentaTCA]");

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

            SQL.InParameter("@InIdTCA", IdTarjeta, SqlDbType.Int);


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
                // List<TFModel> listaTodasTarjetasMaestras = new List<TFModel>();
                listaEstadosDeCuenta = new List<EstadoDeCuentaAdicionalModel>();

                while (dr.Read())
                {
                    EstadoDeCuentaAdicionalModel EC = new EstadoDeCuentaAdicionalModel();
                    EC.FechaEstadoCuenta = dr.GetDateTime(0);
                    EC.CantidadOperacionesATM = dr.GetInt32(1);
                    EC.CantidadOperacionesVentanilla = dr.GetInt32(2);
                    EC.CantidadDeCompras = dr.GetInt32(3);
                    EC.SumaDeCompras = (float)dr.GetDecimal(4);
                    EC.CantidadDeRetiros = dr.GetInt32(5);
                    EC.SumaDeRetiros = (float)dr.GetDecimal(6);
                    EC.Id = dr.GetInt32(7);

                    listaEstadosDeCuenta.Add(EC);
                }
                SQL.Close();
                return 0;
            }

        }

    }
}
