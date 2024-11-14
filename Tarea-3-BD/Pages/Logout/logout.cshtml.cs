using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.Data;
using Tarea_3_BD.Pages.Model;
using static System.Runtime.InteropServices.JavaScript.JSType;

namespace Tarea_3_BD.Pages.Logout
{
    public class logoutModel : PageModel
    {
        ConnectSQL SQL = new ConnectSQL();  

        public IActionResult OnGet()
        {


            using (SQL.connection)
            {
                SQL.Open();
                SQL.LoadSP("[dbo].[Logout]");
                SQL.OutParameter("@OutResultCode", SqlDbType.Int, 0);

                
                SQL.InParameter("@InUser", (string)HttpContext.Session.GetString("Usuario"), SqlDbType.VarChar);
                SQL.InParameter("@InIp", HttpContext.Connection.RemoteIpAddress?.ToString(), SqlDbType.VarChar);
                SQL.InParameter("@InPostTime", DateTime.Now , SqlDbType.DateTime);


                SQL.ExecSP();

                return RedirectToPage("/LogIn/LogIn");

            }
        }
    }
}
