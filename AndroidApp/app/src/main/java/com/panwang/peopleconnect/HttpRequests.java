package com.panwang.peopleconnect;

import android.content.res.AssetManager;
import android.renderscript.ScriptGroup;
import android.util.Base64;

import java.io.BufferedInputStream;
import java.io.BufferedReader;
import java.io.DataOutputStream;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLConnection;
import java.net.URLEncoder;
import java.security.cert.CertificateException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import javax.net.ssl.HostnameVerifier;
import javax.net.ssl.HttpsURLConnection;

import static java.net.Proxy.Type.HTTP;
import 	javax.net.ssl.SSLContext;
import java.security.cert.Certificate;
import java.security.cert.X509Certificate;

import java.security.cert.CertificateFactory;
import 	java.security.KeyStore;

import javax.net.ssl.SSLSession;
import javax.net.ssl.SSLSocketFactory;
import 	javax.net.ssl.TrustManagerFactory;

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

    static SSLContext context;

    static void InitSSL(InputStream crtFile) throws Exception {
        // Load CAs from an InputStream
        // (could be from a resource or ByteArrayInputStream or ...)
        CertificateFactory cf = CertificateFactory.getInstance("X.509");
        // From https://www.washington.edu/itconnect/security/ca/load-der.crt
        InputStream caInput = new BufferedInputStream(crtFile);
        Certificate ca;
        try {
            ca = cf.generateCertificate(caInput);
            System.out.println("ca=" + ((X509Certificate) ca).getSubjectDN());
        } finally {
            caInput.close();
        }

        // Create a KeyStore containing our trusted CAs
        String keyStoreType = KeyStore.getDefaultType();
        KeyStore keyStore = KeyStore.getInstance(keyStoreType);
        keyStore.load(null, null);
        keyStore.setCertificateEntry("ca", ca);

        // Create a TrustManager that trusts the CAs in our KeyStore
        String tmfAlgorithm = TrustManagerFactory.getDefaultAlgorithm();
        TrustManagerFactory tmf = TrustManagerFactory.getInstance(tmfAlgorithm);
        tmf.init(keyStore);

        // Create an SSLContext that uses our TrustManager
        context = SSLContext.getInstance("TLS");
        context.init(null, tmf.getTrustManagers(), null);
    }

    static String HttpsPost(String urlString, ArrayList<String> params, ArrayList<String> values)
            throws Exception {
        // Create an HostnameVerifier that hardwires the expected hostname.
        // Note that is different than the URL's hostname:
        // example.com versus example.org
        HostnameVerifier hostnameVerifier = new HostnameVerifier() {
            @Override
            public boolean verify(String hostname, SSLSession session) {
                HostnameVerifier hv = HttpsURLConnection.getDefaultHostnameVerifier();
                return true;//hv.verify("192.168.0.103", session);
            }
        };

        URL url = new URL(urlString);
        HttpsURLConnection connection = (HttpsURLConnection) url.openConnection();

        connection.setHostnameVerifier(hostnameVerifier);
        connection.setSSLSocketFactory(context.getSocketFactory());
        //InputStream in = connection.getInputStream();
        //copyInputStreamToOutputStream(in, System.out);

        connection.setDoInput(true);
        connection.setDoOutput(true);
        connection.setRequestMethod("POST");
        connection.setUseCaches(false);
        connection.setRequestProperty("Connect-Type", "application/x-www-form-urlencoded");
        connection.setRequestProperty("Charset", "utf-8");
        connection.connect();

        DataOutputStream writer = new DataOutputStream(connection.getOutputStream());
        for (int i=0; i<params.size(); i++) {
            String data = params.get(i) + "=" + values.get(i) + ";";
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
