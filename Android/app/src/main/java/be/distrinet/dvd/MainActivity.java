package be.distrinet.dvd;

import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;

import android.content.DialogInterface;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Bundle;
import android.util.Base64;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;

import java.io.IOException;
import java.io.InputStream;
import java.security.KeyManagementException;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.UnrecoverableKeyException;
import java.security.cert.Certificate;
import java.security.cert.CertificateException;
import java.security.cert.CertificateFactory;

import javax.net.ssl.KeyManager;
import javax.net.ssl.KeyManagerFactory;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLSocketFactory;
import javax.net.ssl.TrustManager;
import javax.net.ssl.TrustManagerFactory;
import javax.net.ssl.X509TrustManager;

import be.distrinet.dvd.connection.RestModel;
import be.distrinet.dvd.connection.RestService;
import io.reactivex.android.schedulers.AndroidSchedulers;
import io.reactivex.disposables.CompositeDisposable;
import io.reactivex.disposables.Disposable;
import io.reactivex.schedulers.Schedulers;
import okhttp3.OkHttpClient;
import retrofit2.Retrofit;
import retrofit2.adapter.rxjava2.RxJava2CallAdapterFactory;
import retrofit2.converter.gson.GsonConverterFactory;

public class MainActivity extends AppCompatActivity {

    private LinearLayout parentLayout;

    private String ip;
    private static final String SERVICE_PORT = "8443";

    CompositeDisposable compositeDisposable;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        parentLayout = findViewById(R.id.outerLayout);

        ip = getIntent().getStringExtra("ip");


        String url = "https://" + ip + ":" + SERVICE_PORT;

        try {

            CertificateFactory certificateFactory = CertificateFactory.getInstance("X.509");

            InputStream trustedCertificateAsInputStream = getResources().openRawResource(R.raw.root);
            Certificate trustedCertificate = certificateFactory.generateCertificate(trustedCertificateAsInputStream);
            KeyStore trustStore = createEmptyKeyStore("secret".toCharArray());
            trustStore.setCertificateEntry("root", trustedCertificate);

            TrustManagerFactory trustManagerFactory = TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm());
            trustManagerFactory.init(trustStore);
            TrustManager[] trustManagers = trustManagerFactory.getTrustManagers();

            InputStream inputStream = getResources().openRawResource(R.raw.client);
            KeyStore keyStore = KeyStore.getInstance("PKCS12");
            keyStore.load(inputStream, "".toCharArray());

            KeyManagerFactory kmf = KeyManagerFactory.getInstance("X509");
            kmf.init(keyStore, "".toCharArray());
            KeyManager[] keyManagers = kmf.getKeyManagers();

            SSLContext sslContext = SSLContext.getInstance("TLS");


            sslContext.init(keyManagers, trustManagers, null);

            SSLSocketFactory socketFactory = sslContext.getSocketFactory();

            OkHttpClient okHttpClient = new OkHttpClient.Builder()
                    .sslSocketFactory(socketFactory, (X509TrustManager) trustManagers[0])
                    .build();


            ProgressBar progressBar = findViewById(R.id.progressBar);


            compositeDisposable = new CompositeDisposable();

            Disposable disposable = new Retrofit.Builder()
                    .baseUrl(url)
                    .addConverterFactory(GsonConverterFactory.create())
                    .addCallAdapterFactory(RxJava2CallAdapterFactory.create())
                    .client(okHttpClient)
                    .build()
                    .create(RestService.class).getData().subscribeOn(Schedulers.io())
                    .observeOn(AndroidSchedulers.mainThread())
                    .subscribe(res -> {
                        RestModel.ContentObject[] records = res.getRecords();
                        for (RestModel.ContentObject object : records) {
                            addDataToScreen(object.getTitle(), object.getDescription(), object.getAuthor(), object.getImage());
                        }
                        progressBar.setVisibility(View.GONE);
                    }, e -> {
                        e.printStackTrace();
                        Toast.makeText(getApplicationContext(), e.getMessage(), Toast.LENGTH_LONG).show();
                    });

            compositeDisposable.add(disposable);

        } catch (CertificateException | IOException | NoSuchAlgorithmException | UnrecoverableKeyException | KeyStoreException | KeyManagementException e) {
            e.printStackTrace();
        }

    }

    public static KeyStore createEmptyKeyStore(char[] keyStorePassword) throws CertificateException, NoSuchAlgorithmException, IOException, KeyStoreException {
        KeyStore keyStore = KeyStore.getInstance(KeyStore.getDefaultType());
        keyStore.load(null, keyStorePassword);
        return keyStore;
    }

    private void addDataToScreen(String titletext, String descriptiontext, String authortext, String base64image) {
        LayoutInflater inflater = getLayoutInflater();
        View content = inflater.inflate(R.layout.content_main, parentLayout, false);

        final TextView title =  content.findViewById(R.id.title);
        final TextView author =  content.findViewById(R.id.author);
        final TextView description =  content.findViewById(R.id.description);
        final ImageView image =  content.findViewById(R.id.image);

        byte[] decodedString = Base64.decode(base64image, Base64.DEFAULT);
        Bitmap imageContent = BitmapFactory.decodeByteArray(decodedString, 0, decodedString.length);

        image.setImageBitmap(imageContent);
        title.setText(titletext);
        author.setText(authortext);
        description.setText(descriptiontext);

        parentLayout.addView(content);

        image.setOnClickListener(view -> {
            AlertDialog.Builder builder = new AlertDialog.Builder(MainActivity.this);

            builder.setPositiveButton("CLOSE", (dialog, which) -> dialog.dismiss());

            LayoutInflater inflater1 = getLayoutInflater();
            View dialoglayout = inflater1.inflate(R.layout.imagedialog, null);
            ImageView imageView = dialoglayout.findViewById(R.id.image);
            imageView.setImageBitmap(imageContent);

            builder.setView(dialoglayout);
            builder.show();
        });
    }

    @Override
    protected void onDestroy() {

        compositeDisposable.dispose();

        super.onDestroy();
    }
}