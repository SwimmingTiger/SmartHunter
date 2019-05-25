﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using WebSocketSharp;
using SmartHunter.Core;
using Newtonsoft.Json;
using System.IO;

namespace SmartHunter.Ui.Remote
{
    class OverlayDisplayClient
    {
        private static OverlayDisplayClient instance;
        private WebSocket ws;

        public static OverlayDisplayClient GetInstance()
        {
            if (instance == null)
            {
                instance = new OverlayDisplayClient("ws://localhost:12345");
            }
            return instance;
        }

        private OverlayDisplayClient(string serverURI)
        {
            ws = new WebSocket(serverURI);
            ws.OnMessage += OnMessage;
            ws.Connect();
        }

        public void InitView() {
            string baseDir = System.Environment.CurrentDirectory.Replace('\\', '/').Replace("'", "\\'");
            SendLuaFile("monster", baseDir + "/monster.lua");
            SetRender("monster", "Render()");
        }

        public void DestoryView() {
            RemoveWidget("monster");
        }

        private void OnMessage(Object sender, MessageEventArgs e)
        {
            Log.WriteLine(e.Data);
        }

        public void SendText(string text)
        {
            ws.Send(text);
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