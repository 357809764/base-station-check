package com.sy.yanshou;

import android.annotation.SuppressLint;
import android.content.Context;
import android.graphics.Bitmap;
import android.net.http.SslError;
import android.util.AttributeSet;
import android.webkit.SslErrorHandler;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Toast;

import com.sangfor.ssl.SangforAuthManager;
import com.sangfor.ssl.service.utils.logger.Log;

import com.nd.ppt.pad.prometheus.R;

public class VPNWebView extends WebView {
    private static final String TAG = "AuthSuccessActivity";
    private final int TEST_URL_TIMEOUT_MILLIS = 8 * 1000;// 测试vpn资源的超时时间
    private String url = "http://134.129.112.108:3694/?ys_ver=i1";//"http://120.36.56.152:3694/?ys_ver=i1";
    private Context context;

    public VPNWebView(Context context) {
        super(context);
        initView(context);
    }

    public VPNWebView(Context context, AttributeSet attrs) {
        super(context, attrs);
        initView(context);
    }

    public VPNWebView(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        initView(context);
    }


    private void initView(Context context) {
        this.context = context;
        setWebViewSettings();  //设置webview配置参数
    }


    /**
     * WebView的回收销毁，防止内存泄漏
     */
    public void destroy() {
        clearHistory();
        clearCache(true);
        loadUrl("about:blank");
        freeMemory();
        pauseTimers();
        destroy();
    }

    /**
     * 注销流程
     */
    private void doVPNLogout() {
        // 注销VPN登录.
        SangforAuthManager.getInstance().vpnLogout();
        Toast.makeText(getContext(), R.string.str_vpn_logout, Toast.LENGTH_SHORT).show();
        setVisibility(GONE);
    }

    public void load() {
        LoadPageByWebView(url);
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
        loadUrl(url);
    }

    private void setWebViewSettings() {
        setWebViewClient(new MyWebViewClient());

        WebSettings webSettings = getSettings();
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

        // 覆盖WebView默认使用第三方或系统默认浏览器打开网页的行为，使网页用WebView打开
        @Override
        public boolean shouldOverrideUrlLoading(WebView view, String url) {
            view.loadUrl(url);
            return false;// 返回值是true的时候控制去WebView打开，为false调用系统浏览器或第三方浏览器
        }

        @Override
        public void onPageStarted(WebView view, String url, Bitmap favicon) {
            super.onPageStarted(view, url, favicon);
            Log.info(TAG, "onPageStarted url = " + url);

        }

        @Override
        public void onPageFinished(WebView view, String url) {
            //Toast.makeText(context, R.string.str_webview_load_error, Toast.LENGTH_SHORT).show();
            //清除缓存
            clearCache(true);
            clearHistory();
            super.onPageFinished(view, url);
        }

        @Override
        public void onReceivedSslError(WebView view, SslErrorHandler handler, SslError error) {
            handler.proceed();// 忽略证书错误
        }
    }

}
