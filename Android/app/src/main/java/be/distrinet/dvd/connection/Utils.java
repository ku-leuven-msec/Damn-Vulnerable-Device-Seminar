package be.distrinet.dvd.connection;

import android.app.Application;

import java.io.IOException;
import java.io.InputStream;
import java.net.URL;
import java.security.KeyManagementException;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.UnrecoverableKeyException;
import java.security.cert.Certificate;
import java.security.cert.CertificateException;
import java.security.cert.CertificateFactory;

import javax.net.ssl.HttpsURLConnection;
import javax.net.ssl.KeyManager;
import javax.net.ssl.KeyManagerFactory;
import javax.net.ssl.SSLContext;
import javax.net.ssl.TrustManager;
import javax.net.ssl.TrustManagerFactory;

import be.distrinet.dvd.R;

public class Utils {

    public static HttpsURLConnection connect(Application app, String ip, String host, String port) throws KeyStoreException, CertificateException, NoSuchAlgorithmException, IOException, UnrecoverableKeyException, KeyManagementException {

        CertificateFactory certificateFactory = CertificateFactory.getInstance("X.509");

        InputStream trustedCertificateAsInputStream = app.getResources().openRawResource(R.raw.root);
        Certificate trustedCertificate = certificateFactory.generateCertificate(trustedCertificateAsInputStream);
        KeyStore trustStore = KeyStore.getInstance(KeyStore.getDefaultType());
        trustStore.load(null,"".toCharArray());
        trustStore.setCertificateEntry("root", trustedCertificate);

        TrustManagerFactory trustManagerFactory = TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm());
        trustManagerFactory.init(trustStore);
        TrustManager[] trustManagers = trustManagerFactory.getTrustManagers();


        KeyStore keyStore = KeyStore.getInstance("PKCS12");
        InputStream inputStream = app.getResources().openRawResource(R.raw.client);

        keyStore.load(inputStream, "".toCharArray());
        KeyManagerFactory kmf = KeyManagerFactory.getInstance("X509");
        kmf.init(keyStore, "".toCharArray());
        KeyManager[] keyManagers = kmf.getKeyManagers();
        SSLContext sslContext = SSLContext.getInstance("TLS");
        sslContext.init(keyManagers, trustManagers, null);

        URL url = new URL("https://" + ip + ":" + port);
        HttpsURLConnection urlConnection = (HttpsURLConnection) url.openConnection();
        if(urlConnection != null) {
            urlConnection.setSSLSocketFactory(sslContext.getSocketFactory());
            urlConnection.setRequestProperty("Host", host);
            urlConnection.setConnectTimeout(10000);
        }

        return urlConnection;
    }
}
