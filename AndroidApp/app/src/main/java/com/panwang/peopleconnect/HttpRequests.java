package com.panwang.peopleconnect;

import android.util.Base64;

import java.io.BufferedReader;
import java.io.DataOutputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLConnection;
import java.net.URLEncoder;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import javax.net.ssl.HttpsURLConnection;

import static java.net.Proxy.Type.HTTP;

public class HttpRequests {

    static void Connect(String username, String password) throws IOException {
        URL url = new URL("http://192.168.0.103:8080/login");
        String authString = username + ":" + password;
        byte[] authEncBytes = Base64.encode(authString.getBytes("utf-8"), Base64.DEFAULT);
        URLConnection connection = url.openConnection();
        connection.setRequestProperty ("Authorization", "Basic " + authEncBytes);
        connection.setDoOutput(true);
        connection.setDoInput(true);
        connection.setRequestProperty("accept", "*/*");
        connection.setRequestProperty("connection", "Keep-Alive");
        connection.setRequestProperty("user-agent", "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1;SV1)");
        connection.connect();
        Map<String, List<String>> map = connection.getHeaderFields();
        for (String key : map.keySet()) {
            System.out.println(key + "--->" + map.get(key));
        }
        BufferedReader in = new BufferedReader(new InputStreamReader(connection.getInputStream()));
        String result = "";
        String line;
        while ((line = in.readLine()) != null) {
            result += line;
        }
        System.out.println("$$$$$ "+result);
    }

    static String HttpPost(String urlString, ArrayList<String> params, ArrayList<String> values)
            throws IOException {
        URL url = new URL(urlString);
        HttpURLConnection connection = (HttpURLConnection)url.openConnection();
        connection.setDoInput(true);
        connection.setDoOutput(true);
        connection.setRequestMethod("POST");
        connection.setUseCaches(false);
        connection.setRequestProperty("Connect-Type", "application/x-www-form-urlencoded");
        connection.setRequestProperty("Charset", "utf-8");
        connection.connect();

        DataOutputStream writer = new DataOutputStream(connection.getOutputStream());
        for (int i=0; i<params.size(); i++) {
            String data = params.get(i) + "=" + values.get(i) + " ";
            writer.writeBytes(data);
        }
        writer.flush();
        writer.close();

        BufferedReader reader = new BufferedReader(new InputStreamReader(connection.getInputStream()));
        String result = "";
        String readLine = null;
        while ((readLine = reader.readLine()) != null) {
            result += readLine;
        }
        reader.close();
        connection.disconnect();

        return result;
    }
}
