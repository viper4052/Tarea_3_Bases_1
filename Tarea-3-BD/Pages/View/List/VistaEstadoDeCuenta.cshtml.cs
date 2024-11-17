using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.Data;
using System.Data.SqlClient;
using Tarea_3_BD.Pages.Model;

namespace Tarea_3_BD.Pages.View.List
{
    public class VistaEstadoDeCuentaModel : PageModel
    {
        // creo que esta lista corresponde a una de estado de cuenta adicional? no estoy seguro
        public List<EstadoDeCuentaAdicionalModel> listaEstadosDeCuentaAdicional = new List<EstadoDeCuentaAdicionalModel>();
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


                int resultCode = ListarEstadosDeCuentaAdicionales(user);

                if (resultCode != 0)
                {
                    errorMessage = SQL.BuscarError(resultCode);
                }

            }

        }


        public int ListarEstadosDeCuentaAdicionales(string user)
        {
            SQL.Open();
            SQL.LoadSP("[dbo].[ObtieneEstadoDeCuentaAdicional_2]");

            SQL.OutParameter("@OutTipoUsuario", SqlDbType.Int, 0);

            SQL.InParameter("@InUsername", "", SqlDbType.VarChar);

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
                listaEstadosDeCuentaAdicional = new List<EstadoDeCuentaAdicionalModel>();

                while (dr.Read())
                {
                    EstadoDeCuentaAdicionalModel ECD = new EstadoDeCuentaAdicionalModel();
                    ECD.FechaDeOperacion = dr.GetDateTime(0);
                    ECD.NombreTipoDeMovimiento = dr.GetString(1);
                    ECD.Descripcion = dr.GetString(2);
                    ECD.Referencia = dr.GetString(3);
                    ECD.Monto = dr.GetInt32(4);
                    ECD.NuevoSaldo = dr.GetInt32(5);

                    listaEstadosDeCuentaAdicional.Add(ECD);
                }
                SQL.Close();
                return 0;
            }
        }

    }
        
}
