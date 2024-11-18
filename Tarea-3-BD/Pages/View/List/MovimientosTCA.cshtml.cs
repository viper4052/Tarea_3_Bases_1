using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.Data.SqlClient;
using System.Data;
using Tarea_3_BD.Pages.Model;

namespace Tarea_3_BD.Pages.View.List
{
    public class MovimientosTCAModel : PageModel
    {
        public List<Movimiento> Movimientos = new List<Movimiento>();
        public ConnectSQL SQL = new ConnectSQL();

        public void OnGet()
        {
            ViewData["ShowLogoutButton"] = true;

            using (SQL.connection)
            {
                int resultCode = ListarMovimientos((string)HttpContext.Session.GetString("IdEstadoDeCuentaAD"));

                if (resultCode != 0)
                {
                    Console.WriteLine("Hubo un error");
                }

            }

        }


        public int ListarMovimientos(string IdEC)
        {
            SQL.Open();
            SQL.LoadSP("[dbo].[GetMovimientosTCA]");

            SQL.OutParameter("@OutResultCode", SqlDbType.Int, 0);

            int IdEstadoCuenta;
            IdEstadoCuenta = 1;
            try
            {
                if (!string.IsNullOrEmpty(IdEC))
                {
                    IdEstadoCuenta = Convert.ToInt32(IdEC);
                }
            }
            catch
            {
                Console.WriteLine("Error parseando a int");
            }

            SQL.InParameter("@InIdEC", IdEstadoCuenta, SqlDbType.Int);



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

                Movimientos = new List<Movimiento>();

                while (dr.Read())
                {
                    Movimiento Mov = new Movimiento();

                    Mov.Fecha = DateOnly.FromDateTime(dr.GetDateTime(0));
                    Mov.TipoMovimiento = dr.GetString(1);
                    Mov.Descripcion = dr.GetString(2);
                    Mov.Referencia = dr.GetString(3);
                    Mov.Monto = dr.GetDecimal(4);
                    Mov.NuevoSaldo = (float)dr.GetDecimal(5);

                    Movimientos.Add(Mov);
                }
                SQL.Close();
                return 0;
            }
        }

    }
}
