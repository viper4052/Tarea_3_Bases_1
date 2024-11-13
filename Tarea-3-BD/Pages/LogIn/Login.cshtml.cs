using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Tarea_3_BD.Pages.Model;
using System.Data.SqlClient;
using System.Data;
using System.Net;
using System.Runtime.InteropServices;
using Microsoft.AspNetCore.Mvc.Infrastructure;
using Microsoft.AspNetCore.Http;



namespace Tarea_3_BD.Pages.LogIn
{
    public class LoginModel : PageModel
    {


        public Usuario user = new Usuario();
        public String errorMessage = "";
        public ConnectSQL SQL = new ConnectSQL();
        public String Ip;


        public void OnGet()
        {
            ViewData["ShowLogoutButton"] = false;
            Ip = HttpContext.Connection.RemoteIpAddress?.ToString();
            string user = (string)HttpContext.Session.GetString("Usuario");
            Console.WriteLine(user);
        }


        public int BuscarUsuario(String IP, DateTime date) //devuelve el tipo de error (Si hubo)
        {
            SQL.Open();
            SQL.LoadSP("[dbo].[Login]");

            SQL.InParameter("@InUsername", user.Username, SqlDbType.VarChar);
            SQL.InParameter("@InPassword", user.Pass, SqlDbType.VarChar);
            SQL.InParameter("@InPostInIP", IP, SqlDbType.VarChar);
            SQL.InParameter("@InPostTime", date, SqlDbType.DateTime);

            SQL.OutParameter("@OutResultCode", SqlDbType.Int, 0);

            SQL.ExecSP();
            SQL.Close();

            //intentos = (int)SQL.command.Parameters["@OutIntentos"].Value;


            return (int)SQL.command.Parameters["@OutResultCode"].Value;
        }

        

        public ActionResult OnPost()
        {
            ViewData["ShowLogoutButton"] = false;
            Ip = HttpContext.Connection.RemoteIpAddress?.ToString();

            DateTime dateNow = DateTime.Now;

            String Username = Request.Form["Nombre"];


            bool esSoloAlfabeticoYGuionBajo = Username.All(c => char.IsLetter(c) || c == '_' || c == ' ');

            String Password = Request.Form["Contraseña"];


            //verifica que los campos no esten vacios
            if (String.IsNullOrEmpty(Username) || String.IsNullOrEmpty(Password))
            {
                errorMessage = "Los espacios no pueden ir vacios";
                return Page();
            }

            //asignamos la password 
            user.Pass = Password;

            //verifica que el usuario no haya ingresado caracteres no validos 
            if (esSoloAlfabeticoYGuionBajo)
            {
                user.Username = Username;
            }
            else
            {
                errorMessage = "El nombre solo puede tener caracteres del alfabeto o guiones";
                return Page();
            }

            //Ahora revisemos si el usuario esta en la BD


            using (SQL.connection)
            {
                int outResultCode = BuscarUsuario(Ip, dateNow);


                if (outResultCode != 0)
                {

                    errorMessage = SQL.BuscarError(outResultCode);

                    return Page();
                }
                else
                {
                    HttpContext.Session.SetString("Username", user.Username);

                    return RedirectToPage("/View/List/VistaTCM");
                }

            }


        }

    }



}