using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Net;
using System.Net.Mail;
using System.Net.Security;
using System.Security.Cryptography.X509Certificates;
using System.Text;
using System.Threading.Tasks;

namespace Bq.Service.Email
{
    public class EmailSender
    {

        public static bool SendMail(string subject, string body)
        {
            try
            {
                string accountAdminiServer = ConfigurationManager.AppSettings["EmailServerAccount"];
                string accountServerDisplayName = ConfigurationManager.AppSettings["EmailServerDisplayName"];
                string passwordAdminServer = ConfigurationManager.AppSettings["EmailServerPassword"];
                string accountEmailBQGenatec = ConfigurationManager.AppSettings["EmailBQGenatecAccount"];
                string accountEmailBQGenatecDisplayName = ConfigurationManager.AppSettings["EmailBQGenatecDisplayName"];
                string serverPort = ConfigurationManager.AppSettings["EmailServerPort"];
                string serverHost = ConfigurationManager.AppSettings["EmailServerHost"];
                bool enableSsl = Boolean.Parse(ConfigurationManager.AppSettings["SmtpEnableSsl"]);
                bool useDefaultCredentials = Boolean.Parse(ConfigurationManager.AppSettings["SmtpUseDefaultCredentials"]);
                int timeout = Int32.Parse(ConfigurationManager.AppSettings["SmtpTimeout"]);

                MailAddress fromAddress = new MailAddress(accountAdminiServer, accountServerDisplayName);
                MailAddress toAddress = new MailAddress(accountEmailBQGenatec, accountEmailBQGenatecDisplayName);
                string fromPassword = passwordAdminServer;
                subject = "[CareTech iCareOnline] OTP";
                body = "<html><head><title></title></head><body><p>Hi,</p>" + "<p>Your OTP is " + body + ".</p><p>" + "Yours sincerely" + " </body></html>";
                //string body = "<html><head><title></title></head><body><p>Hi, </p><p>&nbsp;</p><p>" + Resources.Resource.Remind_Password + ":</p>";
                //body += GetListCredentials(users);
                //body += "<p>&nbsp;</p><p>" + Resources.Resource.Yours_sincerely + "</p><p>" + Resources.Resource.iCare_Administrator + "</p></body></html>";
                var smtp = new SmtpClient
                {
                    Host = serverHost,
                    Port = Int32.Parse(serverPort),
                    EnableSsl = enableSsl,
                    DeliveryMethod = SmtpDeliveryMethod.Network,
                    UseDefaultCredentials = useDefaultCredentials,
                    Credentials = new NetworkCredential(fromAddress.Address, fromPassword)
                };
                using (var message = new MailMessage(fromAddress, toAddress)
                {
                    Subject = subject,
                    Body = body,
                    IsBodyHtml = true
                })
                {
                    ServicePointManager.ServerCertificateValidationCallback = delegate (object s, X509Certificate certificate, X509Chain chain, SslPolicyErrors sslPolicyErrors) { return true; };
                    smtp.Send(message);
                }
            }
            catch (Exception e)
            {

                return false;
            }
            return true;
        }

    }
}
