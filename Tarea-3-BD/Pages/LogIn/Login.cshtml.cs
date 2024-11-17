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
        public int tipoDeUsuarioRedireccion;


        public void OnGet()
        {
            ViewData["ShowLogoutButton"] = false;
            string user = (string)HttpContext.Session.GetString("Usuario");
        }


        public int BuscarUsuario() //devuelve el tipo de error (Si hubo)
        {
            SQL.Open();
            SQL.LoadSP("[dbo].[Login]");

            SQL.InParameter("@InUsername", user.Username, SqlDbType.VarChar);
            SQL.InParameter("@InPassword", user.Pass, SqlDbType.VarChar);

            SQL.OutParameter("@OutResultCode", SqlDbType.Int, 0);
            SQL.OutParameter("@OutTipoUsuario", SqlDbType.Int, 1);

            SQL.ExecSP();
            SQL.Close();

            tipoDeUsuarioRedireccion = (int)SQL.command.Parameters["@OutTipoUsuario"].Value; // asigno el tipo de usuario

               
			return (int)SQL.command.Parameters["@OutResultCode"].Value;
        }

        

        public ActionResult OnPost()
        {
            ViewData["ShowLogoutButton"] = false;


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
                int outResultCode = BuscarUsuario();


                if (outResultCode != 0)
                {

                    errorMessage = "Usuario o Contraseña incorrectos";

                    return Page();
                }
                else
                {
                    HttpContext.Session.SetString("Username", user.Username);
					HttpContext.Session.SetString("tipoDeUsuario", tipoDeUsuarioRedireccion.ToString());

                    return RedirectToPage("/View/List/VistaTarjetas");
                }

            }


        }

    }



}