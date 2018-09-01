package com.sangfor.vpn.vpndemo;

import android.annotation.SuppressLint;
import android.content.Intent;
import android.graphics.Bitmap;
import android.net.http.SslError;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.view.View;
import android.view.Window;
import android.webkit.SslErrorHandler;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.ArrayAdapter;
import android.widget.AutoCompleteTextView;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.RadioButton;
import android.widget.RadioGroup;
import android.widget.Toast;

import com.sangfor.ssl.SangforAuthManager;
import com.sangfor.ssl.service.utils.logger.Log;
import java.io.BufferedReader;
import java.io.DataOutputStream;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.InetAddress;
import java.net.URL;
import java.net.UnknownHostException;
import java.security.cert.X509Certificate;

import javax.net.ssl.HostnameVerifier;
import javax.net.ssl.HttpsURLConnection;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLSession;
import javax.net.ssl.TrustManager;
import javax.net.ssl.X509TrustManager;

public class AuthSuccessActivity extends AppCompatActivity implements View.OnClickListener {

    private static final String TAG = "AuthSuccessActivity";
    private static String sTestURL = "http://134.129.112.108:3694/?ys_ver=i1";
    private final int TEST_URL_TIMEOUT_MILLIS = 8 * 1000;// 测试vpn资源的超时时间

    private EditText    mEtUrl;
    private FrameLayout mWebViewContainer = null;
    private WebView     mWebView = null;
    private RadioGroup  mRadioGroup_authMethod = null;
    private RadioButton mRadioButton_selected_authMethod = null;
    private AutoCompleteTextView mAutoCompleteTextView = null;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        setContentView(R.layout.activity_auth_success);

        initView();
        initClickEvents();
    }

    private void initView() {
        mEtUrl = (EditText) findViewById(R.id.et_url);
        mRadioGroup_authMethod = (RadioGroup) findViewById(R.id.svpn_resource_tabheader);
        mAutoCompleteTextView = (AutoCompleteTextView) findViewById(R.id.autoComTextView_url);
        mWebViewContainer = (FrameLayout) findViewById(R.id.web_view_container);
        mWebView = new WebView(getApplicationContext());
        mWebViewContainer.addView(mWebView);
        setWebViewSettings();  //设置webview配置参数

        String[] str_extraResource_url = getResources().getStringArray(R.array.extra_resource_url);
        ArrayAdapter<String> arrayAdapter = new ArrayAdapter<String>(AuthSuccessActivity.this,
                R.layout.support_simple_spinner_dropdown_item, str_extraResource_url);
        mAutoCompleteTextView.setAdapter(arrayAdapter);

        mEtUrl.setText(sTestURL);
    }

    //注册监听事件
    private void initClickEvents() {

        //资源展示按钮变动监听
        mRadioGroup_authMethod.setOnCheckedChangeListener(new RadioGroup.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(RadioGroup group, int checkedId) {
                //监听认证按钮，动态改变布局显示
                switch (mRadioGroup_authMethod.getCheckedRadioButtonId()) {
                    case R.id.svpn_intraResource_tabheader:
                        findViewById(R.id.et_url).setVisibility(View.VISIBLE);
                        findViewById(R.id.autoComTextView_url).setVisibility(View.GONE);
                        break;
                    case R.id.svpn_extraResource_tabheader:
                        findViewById(R.id.et_url).setVisibility(View.GONE);
                        findViewById(R.id.autoComTextView_url).setVisibility(View.VISIBLE);
                        break;
                    default:
                        break;
                }

            }
        });

        //AutoCompleteTextView控件获取焦点时，展示提示资源
        mAutoCompleteTextView.setOnFocusChangeListener(new View.OnFocusChangeListener() {
            @Override
            public void onFocusChange(View v, boolean hasFocus) {

                if (hasFocus) {
                    ((AutoCompleteTextView) v).showDropDown();
                }

            }
        });
    }

    @Override
    public void onClick(View v) {
        switch (v.getId()) {
            case R.id.btn_test_res:
                doTestResource();
                break;

            case R.id.btn_logout:
                doVPNLogout();
                break;
        }
    }

    /**
     * 测试资源
     */
    private void doTestResource() {
        //获取选定的认证方式
        mRadioButton_selected_authMethod = (RadioButton) findViewById(mRadioGroup_authMethod.getCheckedRadioButtonId());
        String resourceType = mRadioButton_selected_authMethod.getText().toString().trim();
        EditText editText = resourceType.equals(getString(R.string.str_intranet_resource)) ? mEtUrl : mAutoCompleteTextView;
        // 通过直接http请求测试网络，将测试结果写到logcat，便于分析
//        new TestThread(editText.getText().toString()).start();

        // 将测试结果展示到界面上，直观展示
        LoadPageByWebView(editText.getText().toString());
    }

    /**
     * 注销流程
     */
    private void doVPNLogout() {
        // 注销VPN登录.
        SangforAuthManager.getInstance().vpnLogout();
        Toast.makeText(AuthSuccessActivity.this, R.string.str_vpn_logout, Toast.LENGTH_SHORT).show();
        startActivity(new Intent(AuthSuccessActivity.this, LoginActivity.class));
        finish();
    }

    @SuppressLint("SetJavaScriptEnabled")
    public void LoadPageByWebView(String url) {
        if (url == null || url.equals("")) {
            Log.info(TAG, "LoadPageByWebView url is wrong!");
            return;
        }
        if (!url.contains("http")) {
            url = "http://" + url;
        }

        mWebView.loadUrl(url);
    }

    private void setWebViewSettings() {
        mWebView.setWebViewClient(new MyWebViewClient());

        WebSettings webSettings = mWebView.getSettings();
        // 不使用缓存，只从网络获取数据。
        webSettings.setCacheMode(WebSettings.LOAD_NO_CACHE);
        // 开启 DOM storage API 功能
        webSettings.setDomStorageEnabled(false);
        // 开启 database storage API 功能
        webSettings.setDatabaseEnabled(false);
        // 设置可以支持缩放
        webSettings.setSupportZoom(true);
        // 设置出现缩放工具
        webSettings.setBuiltInZoomControls(true);
        // 设置可在大视野范围内上下左右拖动，并且可以任意比例缩放
        webSettings.setUseWideViewPort(true);
        // 设置默认加载的可视范围是大视野范围
        webSettings.setLoadWithOverviewMode(true);
        // 网页中包含JavaScript内容需调用以下方法，参数为true
        webSettings.setJavaScriptEnabled(true);
    }

    private class MyWebViewClient extends WebViewClient {

        public MyWebViewClient() {
        }

        @Override
        // 覆盖WebView默认使用第三方或系统默认浏览器打开网页的行为，使网页用WebView打开
        public boolean shouldOverrideUrlLoading(WebView view, String url) {
            view.loadUrl(url);
            return true;// 返回值是true的时候控制去WebView打开，为false调用系统浏览器或第三方浏览器
        }

        @Override
        public void onPageStarted(WebView view, String url, Bitmap favicon) {
            super.onPageStarted(view, url, favicon);
            Log.info(TAG, "onPageStarted url = " + url);

        }

        @Override
        public void onPageFinished(WebView view, String url) {
            //清除缓存
            mWebView.clearCache(true);
            mWebView.clearHistory();
            super.onPageFinished(view, url);
        }

        @Override
        public void onReceivedSslError(WebView view, SslErrorHandler handler, SslError error) {
            handler.proceed();// 忽略证书错误
        }
    }

    /**
     * WebView的回收销毁，防止内存泄漏
     */
    private void destroyWebView() {
        mWebViewContainer.removeAllViews();
        if (mWebView != null) {
            mWebView.clearHistory();
            mWebView.clearCache(true);
            mWebView.loadUrl("about:blank");
            mWebView.freeMemory();
            mWebView.pauseTimers();
            mWebView.destroy();
        }
    }

    @Override
    protected void onDestroy() {
        destroyWebView();
        super.onDestroy();
    }

    /**
     * 测试HTTP/HTTPS资源
     */
    private class TestThread extends Thread {
        private String testUrl = "";
        public TestThread(String url) {
            testUrl = url;
        }

        @Override
        public void run() {
            SangforAuthManager sangforAuthManager = SangforAuthManager.getInstance();
            Log.info(TAG, "vpn status ===================== " + sangforAuthManager.queryStatus());

            Log.info(TAG, "url =======" + testUrl);

            try {
                if (!testUrl.isEmpty()) {
                    SentHttpAndHttpsPost(testUrl);
                } else {
                    Log.info(TAG, "url is empty!");
                }

            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    private void SentHttpAndHttpsPost(final String url) {
        if (url == null || url.isEmpty()) {
            Log.error(TAG, "SentHttpAndHttpsPost url param error");
            return;
        }

        try {
            if (!getHostByName(url)) {
                return;
            }
            Log.info(TAG, "test url= " + url);
            if (url.toLowerCase().contains("https://".toLowerCase())) {
                sendHttpsPost(url);
            } else {
                sendHttpPost(url);
            }
        } catch (Exception e) {
            Log.info(TAG, "sendHttpsPost throw exception");
            e.printStackTrace();
        }
        return;
    }

    // 设置dns解析超时方法
    public boolean getHostByName(String urlStr) throws Exception {
        if (urlStr == null || urlStr.isEmpty()) {
            return false;
        }
        URL url = new URL(urlStr);
        String ipAddress = url.getHost();

        DNSLookupThread dnsThread = new DNSLookupThread(ipAddress);
        dnsThread.start();
        dnsThread.join(TEST_URL_TIMEOUT_MILLIS);
        String ipStr = dnsThread.getIP();
        if (ipStr == null) {
            Log.error(TAG, "host=" + ipAddress + " DNSLookup failed!");
            return false;
        } else {
            Log.info(TAG, "host=" + ipAddress + " ip=" + ipStr);
            return true;
        }
    }

    // 测试dns解析
    public class DNSLookupThread extends Thread {
        private InetAddress addr;
        private String hostname;

        public DNSLookupThread(String hostname) {
            this.hostname = hostname;
        }

        public void run() {
            try {
                InetAddress add = InetAddress.getByName(hostname);
                addr = add;
            } catch (UnknownHostException e) {
                e.printStackTrace();
            }
        }

        public synchronized String getIP() {
            if (null != this.addr) {
                return addr.getHostAddress();
            }
            return null;
        }
    }

    @SuppressLint("TrulyRandom")
    private void sendHttpsPost(String url) throws Exception {
        // Create a trust manager that does not validate certificate chains
        if (url == null || url.isEmpty()) {
            Log.error(TAG, "sendHttpsPost url is wrong");
            return;
        }
        TrustManager[] trustAllCerts = new TrustManager[]{new MyX509TrustManager()};
        // Install the all-trusting trust manager
        SSLContext sc = SSLContext.getInstance("SSL");
        sc.init(null, trustAllCerts, new java.security.SecureRandom());
        HttpsURLConnection.setDefaultSSLSocketFactory(sc.getSocketFactory());
        // Create all-trusting host name verifier
        HostnameVerifier allHostsValid = new MyHostnameVerifier();
        HttpsURLConnection.setDefaultHostnameVerifier(allHostsValid);

        URL obj = new URL(url);
        HttpsURLConnection conn = (HttpsURLConnection) obj.openConnection();
        conn.setRequestMethod("POST");
        conn.setConnectTimeout(TEST_URL_TIMEOUT_MILLIS); // set timeout to 5
        // seconds
        conn.setReadTimeout(TEST_URL_TIMEOUT_MILLIS);
        conn.setRequestProperty("Content-type", "application/x-java-serialized-object");
        conn.setUseCaches(false);
        conn.setDoInput(true);
        conn.setDoOutput(true);

        String urlParameters = obj.getQuery();
        if (urlParameters == null) {
            urlParameters = "";
        }
        DataOutputStream wr = new DataOutputStream(conn.getOutputStream());
        wr.writeBytes(urlParameters);
        wr.flush();
        wr.close();

        int responseCode = conn.getResponseCode();
        Log.info(TAG, "Sending 'POST' request to URL : " + url);
        Log.info(TAG, url + " Post parameters = " + urlParameters);
        Log.info(TAG, url + " Response Code = " + responseCode);

        BufferedReader in = new BufferedReader(new InputStreamReader(conn.getInputStream()));
        String inputLine;
        StringBuffer response = new StringBuffer();

        while ((inputLine = in.readLine()) != null) {
            response.append(inputLine);
        }
        in.close();

        String result = response.toString();
        Log.info(TAG, url + " response = " + result);
    }

    class MyX509TrustManager implements X509TrustManager {
        public X509Certificate[] getAcceptedIssuers() {
            return null;
        }

        public void checkClientTrusted(X509Certificate[] certs, String authType) {
            // No need to implement.
        }

        public void checkServerTrusted(X509Certificate[] certs, String authType) {
            // No need to implement.
        }
    }

    class MyHostnameVerifier implements HostnameVerifier {
        public boolean verify(String hostname, SSLSession session) {
            return true;
        }
    }

    private void sendHttpPost(String url) throws Exception {
        if (url == null || url.isEmpty()) {
            Log.info(TAG, "sendHttpPost url is wrong");
            return;
        }

        URL obj = new URL(url);
        HttpURLConnection conn = (HttpURLConnection) obj.openConnection();
        conn.setRequestMethod("POST");
        conn.setConnectTimeout(TEST_URL_TIMEOUT_MILLIS);
        conn.setReadTimeout(TEST_URL_TIMEOUT_MILLIS);
        conn.setRequestProperty("Content-type", "application/x-java-serialized-object");
        conn.setUseCaches(false);
        conn.setDoInput(true);
        conn.setDoOutput(true);
        String urlParameters = obj.getQuery();
        if (urlParameters == null) {
            urlParameters = "";
        }

        DataOutputStream wr = new DataOutputStream(conn.getOutputStream());
        wr.writeBytes(urlParameters);
        wr.flush();
        wr.close();

        int responseCode = conn.getResponseCode();
        Log.info(TAG, "Sending 'POST' request to URL : " + url);
        Log.info(TAG, url + " Post parameters = " + urlParameters);
        Log.info(TAG, url + " Response Code = " + responseCode);

        BufferedReader in = new BufferedReader(new InputStreamReader(conn.getInputStream()));
        String inputLine;
        StringBuffer response = new StringBuffer();

        while ((inputLine = in.readLine()) != null) {
            response.append(inputLine);
        }
        in.close();

        String result = response.toString();
        Log.info(TAG, url + " response = " + result);
    }
}
