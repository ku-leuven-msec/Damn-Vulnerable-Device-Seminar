package be.distrinet.dvd;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;

import android.content.Context;
import android.content.Intent;
import android.graphics.Color;
import android.net.nsd.NsdManager;
import android.net.nsd.NsdServiceInfo;
import android.os.Bundle;
import android.os.StrictMode;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.ProgressBar;
import android.widget.Spinner;
import android.widget.TextView;
import android.widget.Toast;

import java.io.IOException;
import java.io.InputStream;
import java.security.KeyManagementException;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.UnrecoverableKeyException;
import java.security.cert.CertificateException;
import java.util.ArrayList;
import java.util.Arrays;

import javax.net.ssl.HttpsURLConnection;

import be.distrinet.dvd.connection.Utils;

public class LoginActivity extends AppCompatActivity {

    private final boolean DRAFT = false;
    private final String DRAFT_IP = "192.168.0.105";
    private final boolean MDNS = false;

    private static final String SERVICE_PORT = "8443";

    private NsdHelper nsdHelper;
    private Spinner spinner;
    private ArrayAdapter<String> arrayAdapter;
    private ArrayList<String> ips;
    private Button loginButton;
    private ProgressBar loadingProgressBar;


    @Override
    protected void onStart() {
        super.onStart();
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_login);
        spinner = findViewById(R.id.spinner);
        loginButton = findViewById(R.id.login);

        loadingProgressBar = findViewById(R.id.loading);
        loadingProgressBar.setVisibility(View.INVISIBLE);


        spinner.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                loginButton.setEnabled(spinner.getSelectedItem() != null && !spinner.getSelectedItem().toString().equals(getString(R.string.select)));
            }

            @Override
            public void onNothingSelected(AdapterView<?> parent) {
                loginButton.setEnabled(false);
            }
        });

        loginButton.setOnClickListener(v -> {
            if (spinner.getSelectedItem() != null && !spinner.getSelectedItem().toString().equals(getString(R.string.select))) {
                loginButton.setVisibility(View.INVISIBLE);
                loadingProgressBar.setVisibility(View.VISIBLE);
                spinner.setEnabled(false);

                Thread sendHttpRequestThread = new Thread() {
                    @Override
                    public void run() {
                        try {

                            String ip;
                            if (DRAFT) {
                                ip = DRAFT_IP;
                            } else {
                                ip = ips.get((int) spinner.getSelectedItemId()-1);
                            }

                            String host = spinner.getSelectedItem().toString() + ".local";

                            if (DRAFT) {
                                handleSuccess(ip, host);
                            } else {
                                Log.i("Login", "ip: "+ip);
                                HttpsURLConnection urlConnection = Utils.connect(getApplication(), ip, host, SERVICE_PORT);
                                InputStream in = urlConnection.getInputStream();
                                if (urlConnection.getResponseCode() == 200)
                                    handleSuccess(ip, host);
                                else {
                                    handleError(new Exception("Could not connect"));
                                }
                                in.close();
                            }
                        } catch (IOException | KeyStoreException | NoSuchAlgorithmException | KeyManagementException | CertificateException | UnrecoverableKeyException ex) {
                            handleError(ex);
                        }
                    }
                };
                sendHttpRequestThread.start();
            }
        });

        arrayAdapter = new ArrayAdapter<String>(this,
                android.R.layout.simple_spinner_dropdown_item) {
            @Override
            public boolean isEnabled(int position) {
                return position != 0;
            }

            @Override
            public View getDropDownView(int position, View convertView,
                                        @NonNull ViewGroup parent) {
                View mView = super.getDropDownView(position, convertView, parent);
                TextView mTextView = (TextView) mView;
                if (position == 0) {
                    mTextView.setTextColor(Color.GRAY);
                } else {
                    mTextView.setTextColor(Color.BLACK);
                }
                return mView;
            }
        };

        spinner.setAdapter(arrayAdapter);
        arrayAdapter.add(getString(R.string.select));

        if (DRAFT) {
            String[] arraySpinner = new String[]{"device1", "device2", "device3"};
            arrayAdapter.addAll(arraySpinner);
        } else {


            if (MDNS) {

                //get mdns devices
                nsdHelper = new NsdHelper(this);
                nsdHelper.initializeNsd();
                StrictMode.ThreadPolicy policy = new StrictMode.ThreadPolicy.Builder()
                        .permitAll().build();
                StrictMode.setThreadPolicy(policy);

            } else {
                String[] arraySpinner = new String[]{"DVD1", "DVD2", "DVD3", "DVD4", "DVD5", "DVD6", "DVD7", "DVD8", "DVD9", "DVD10"};
                ips = new ArrayList<>(Arrays.asList("192.168.42.51", "192.168.42.52", "192.168.42.53", "192.168.42.54", "192.168.42.55", "192.168.42.56", "192.168.42.57", "192.168.42.58", "192.168.42.59", "192.168.42.60"));
                arrayAdapter.addAll(arraySpinner);
            }
        }


    }

    @Override
    protected void onPause() {
        if (nsdHelper != null) {
            nsdHelper.tearDown();
            nsdHelper = null;
        }
        super.onPause();
    }

    @Override
    protected void onResume() {
        super.onResume();

        if (nsdHelper != null) {
            try {
                Thread.sleep(1000);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
            nsdHelper.discoverServices();
        }

        loginButton.setVisibility(View.VISIBLE);
        spinner.setEnabled(true);
        loadingProgressBar.setVisibility(View.INVISIBLE);

    }

    @Override
    protected void onDestroy() {
        if (nsdHelper != null) {
            nsdHelper.tearDown();
            nsdHelper = null;
        }
        super.onDestroy();
    }


    public void listService(final NsdServiceInfo service) {
        runOnUiThread(() -> {
            arrayAdapter.add(service.getServiceName());
            ips.add(service.getHost().getHostAddress());
        });
    }

    private void handleError(Exception e) {
        runOnUiThread(() -> {
            e.printStackTrace();
            loadingProgressBar.setVisibility(View.INVISIBLE);
            spinner.setEnabled(true);
            loginButton.setVisibility(View.VISIBLE);
            Toast.makeText(getApplicationContext(), e.getMessage(), Toast.LENGTH_SHORT).show();
        });
    }

    private void handleSuccess(String ip, String host) {
        runOnUiThread(() -> {
            Intent intent = new Intent(LoginActivity.this, MainActivity.class);
            intent.putExtra("ip", ip);
            intent.putExtra("host", host);
            startActivity(intent);
        });
    }

    public class NsdHelper {

        Context mContext;

        NsdManager mNsdManager;
        NsdManager.DiscoveryListener mDiscoveryListener;

        public static final String SERVICE_TYPE = "_ssh._tcp."; //use your service type you want to use
        public static final String TAG = "NsdHelper";
        NsdServiceInfo mService;

        public NsdHelper(Context context) {
            mContext = context;
            mNsdManager = (NsdManager) context
                    .getSystemService(Context.NSD_SERVICE);
        }


        public void initializeNsd() {
            initializeDiscoveryListener();
        }

        public void initializeDiscoveryListener() {
            mDiscoveryListener = new NsdManager.DiscoveryListener() {

                @Override
                public void onDiscoveryStarted(String regType) {
                    Log.d(TAG, "Service discovery started");
                }

                @Override
                public void onServiceFound(NsdServiceInfo service) {
                    mService = service;
                    mNsdManager.resolveService(service, new NsdManager.ResolveListener() {

                        @Override
                        public void onResolveFailed(NsdServiceInfo serviceInfo,
                                                    int errorCode) {
                            Log.e(TAG, "Resolve failed" + errorCode);
                        }

                        @Override
                        public void onServiceResolved(NsdServiceInfo serviceInfo) {
                            Log.i(TAG, "host :  "
                                    + serviceInfo.getHost().getHostAddress());
                            Log.i(TAG, "Address :  "
                                    + Arrays.toString(serviceInfo.getHost().getAddress()));
                            listService(serviceInfo);
                            mService = serviceInfo;
                        }
                    });
                }

                @Override
                public void onServiceLost(NsdServiceInfo service) {
                    Log.e(TAG, "service lost" + service);
                    if (mService == service) {
                        mService = null;
                    }
                }

                @Override
                public void onDiscoveryStopped(String serviceType) {
                    Log.i(TAG, "Discovery stopped: " + serviceType);
                }

                @Override
                public void onStartDiscoveryFailed(String serviceType,
                                                   int errorCode) {
                    Log.e(TAG, "Discovery failed: Error code:" + errorCode);
                    mNsdManager.stopServiceDiscovery(this);
                }

                @Override
                public void onStopDiscoveryFailed(String serviceType,
                                                  int errorCode) {
                    Log.e(TAG, "Discovery failed: Error code:" + errorCode);
                    mNsdManager.stopServiceDiscovery(this);
                }
            };
        }


        public NsdServiceInfo discoverServices() {
            mNsdManager.discoverServices(SERVICE_TYPE,
                    NsdManager.PROTOCOL_DNS_SD, mDiscoveryListener);
            return mService;
        }

        public void stopDiscovery() {
            mNsdManager.stopServiceDiscovery(mDiscoveryListener);
        }

        public NsdServiceInfo getChosenServiceInfo() {
            return mService;
        }

        public void tearDown() {
            mNsdManager.stopServiceDiscovery(mDiscoveryListener);

        }

    }
}