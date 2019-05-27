using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using WebSocketSharp;
using SmartHunter.Core;
using Newtonsoft.Json;
using System.IO;
using Newtonsoft.Json.Linq;
using System.Threading;

namespace SmartHunter.Ui.Remote
{
    class OverlayDisplayClient
    {
        private static OverlayDisplayClient instance;
        private readonly WebSocket ws;
        private bool connected = false;

        public static OverlayDisplayClient GetInstance()
        {
            if (instance == null)
            {
                instance = new OverlayDisplayClient("ws://127.0.0.1:12345");
            }
            return instance;
        }

        private OverlayDisplayClient(string serverURI)
        {
            ws = new WebSocket(serverURI);
            ws.OnOpen += (sender, e) =>
            {
                Log.WriteLine("Connected to OverlayDisplayServer.");
                connected = true;
                InitView();
            };
            ws.OnClose += (sender, e) =>
            {
                connected = false;
                Thread.Sleep(5000);
                Connect();
            };
            ws.OnError += (sender, e) =>
            {
                Log.WriteLine(e.ToString());
            };
            ws.OnMessage += OnMessage;
        }

        public void Connect() {
            Log.WriteLine("Connecting to OverlayDisplayServer...");
            ws.ConnectAsync();
        }

        private void InitView() {
            string baseDir = System.Environment.CurrentDirectory.Replace('\\', '/').Replace("'", "\\'");
            SendLuaFile("smarthunter", baseDir + "/locale.lua");
            SendLuaFile("smarthunter", baseDir + "/render.lua");
            SetRender("smarthunter", "Render()");
        }

        public void DestoryView()
        {
            RemoveWidget("smarthunter");
        }

        private void OnMessage(Object sender, MessageEventArgs e)
        {
            JObject response = JObject.Parse(e.Data);
            string lastError = (string)response.SelectToken("last_error");
            string errorMessage = (string)response.SelectToken("error.message");
            if ((lastError != null && lastError.Length > 0) || (errorMessage != null && errorMessage.Length > 0))
            {
                Log.WriteLine("Error from OverlayDisplayServer: " + e.Data);
            }

        }

        public void SendText(string text)
        {
            if (!connected)
            {
                return;
            }

            try
            {
                //Log.WriteLine("SendText: " + text);
                ws.Send(text);
            }
            catch (Exception ex)
            {
                Log.WriteException(ex);
            }
        }

        public void SendLuaFile(string widget, string filePath) {
            string script = File.ReadAllText(filePath, Encoding.UTF8);
            UpdateView(widget, script);
        }

        public void SetRender(string widget, string script)
        {
            var obj = new Dictionary<string, string>
            {
                { "id", "set"},
                { "command", "set_render"},
                { "widget", widget},
                { "script", script},
            };
            SendText(JsonConvert.SerializeObject(obj));
        }

        public void UpdateView(string widget, string script)
        {

            var obj = new Dictionary<string, string>
            {
                { "id", "upd"},
                { "command", "update_view"},
                { "widget", widget},
                { "script", script},
            };
            SendText(JsonConvert.SerializeObject(obj));
        }

        public void GetResponse(string widget, string script)
        {
            var obj = new Dictionary<string, string>
            {
                { "id", "get"},
                { "command", "get_response"},
                { "widget", widget},
                { "script", script},
            };
            SendText(JsonConvert.SerializeObject(obj));
        }

        public void RemoveWidget(string widget)
        {
            var obj = new Dictionary<string, string>
            {
                { "id", "rm"},
                { "command", "remove_widget"},
                { "widget", widget},
            };
            SendText(JsonConvert.SerializeObject(obj));
        }
    }
}
