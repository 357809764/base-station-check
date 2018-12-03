package com.sy.yanshou;

import android.Manifest;
import android.annotation.SuppressLint;
import android.annotation.TargetApi;
import android.app.Activity;
import android.content.ClipData;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.location.Location;
import android.net.Uri;
import android.net.http.SslError;
import android.os.Build;
import android.os.Environment;
import android.support.v4.app.ActivityCompat;
import android.text.TextUtils;
import android.util.AttributeSet;
import android.view.View;
import android.webkit.GeolocationPermissions;
import android.webkit.JavascriptInterface;
import android.webkit.SslErrorHandler;
import android.webkit.ValueCallback;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.AbsoluteLayout;
import android.widget.TextView;
import android.widget.Toast;

import com.handmark.pulltorefresh.library.PullToRefreshBase;
import com.handmark.pulltorefresh.library.PullToRefreshWebView;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.File;
import java.util.IllegalFormatCodePointException;

public class RefreshWebView extends PullToRefreshWebView {
    private WebView webView;
    private Context context;
    public TextView tvNetError;
    private ValueCallback<Uri> uploadMessage;  //5.0以下使用
    private ValueCallback<Uri[]> uploadMessageAboveL;   // 5.0及以上使用
    private String cameraFilePath = Environment.getExternalStorageDirectory() + "/upload.jpg";//拍照图片路径
    private String baseUrl;

    public RefreshWebView(Context context) {
        super(context);
        initView(context);
    }

    public RefreshWebView(Context context, AttributeSet attrs) {
        super(context, attrs);
        initView(context);
    }

    public RefreshWebView(Context context, Mode mode) {
        super(context, mode);
        initView(context);
    }

    public RefreshWebView(Context context, Mode mode, AnimationStyle style) {
        super(context, mode, style);
        initView(context);
    }

    @SuppressLint("SetJavaScriptEnabled")
    private void initView(Context context) {
        webView = getRefreshableView();
        this.context = context;
        webView.addJavascriptInterface(jsInterface, "YanShouInterface");

        tvNetError = new TextView(context);
        AbsoluteLayout.LayoutParams layoutParams = new AbsoluteLayout.LayoutParams(-1, -1, 15, 15);
        webView.addView(tvNetError, layoutParams);
        tvNetError.setText("服务器异常请联系管理员~");
        tvNetError.setVisibility(GONE);

        //setLayerType(View.LAYER_TYPE_SOFTWARE, null);
        webView.setWebViewClient(new MyWebViewClient());
        webView.setWebChromeClient(new MyWebChromeClient());
        setLongClickable(true);
        setScrollbarFadingEnabled(true);
        setScrollBarStyle(View.SCROLLBARS_INSIDE_OVERLAY);
        setDrawingCacheEnabled(true);
        setVerticalScrollBarEnabled(false);

        WebSettings settings = webView.getSettings();
        settings.setJavaScriptEnabled(true); // 网页中包含JavaScript内容需调用以下方法，参数为true
        settings.setJavaScriptCanOpenWindowsAutomatically(true);
        settings.setGeolocationEnabled(true);
        settings.setAppCacheEnabled(true);
        settings.setDatabaseEnabled(true);  // 开启 database storage API 功能
        settings.setDomStorageEnabled(true); // 开启 DOM storage API 功能
        settings.setLoadWithOverviewMode(true);     // 设置默认加载的可视范围是大视野范围
        settings.setUseWideViewPort(true);        // 设置可在大视野范围内上下左右拖动，并且可以任意比例缩放
        settings.setLoadsImagesAutomatically(true);    //支持自动加载图片
        settings.setSaveFormData(true);    //设置webview保存表单数据
        settings.setSupportZoom(true);    //支持缩放
        settings.setSupportMultipleWindows(true);
        settings.setAllowFileAccess(true);// 设置可以访问文件
        settings.setLayoutAlgorithm(WebSettings.LayoutAlgorithm.SINGLE_COLUMN);//不支持放大缩小
        settings.setDisplayZoomControls(false);//不支持放大缩小
        settings.setGeolocationDatabasePath(((Activity) getContext()).getFilesDir().getPath());


        if (Build.VERSION.SDK_INT >= 23) {
            // Marshmallow+ Permission APIs
            // fuckMarshMallow();
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            if (0 != (getContext().getApplicationInfo().flags & ApplicationInfo.FLAG_DEBUGGABLE)) {
                webView.setWebContentsDebuggingEnabled(true);
            }
        }

        settings.setCacheMode(WebSettings.LOAD_CACHE_ELSE_NETWORK); // 不使用缓存，只从网络获取数据。
        settings.setBuiltInZoomControls(true); // 设置出现缩放工具

        setOnRefreshListener(new PullToRefreshBase.OnRefreshListener<WebView>() {
            @Override
            public void onRefresh(PullToRefreshBase<WebView> refreshView) {
                reload();
            }
        });
    }


    /**
     * WebView的回收销毁，防止内存泄漏
     */
    public void destroy() {
        webView.clearHistory();
        webView.clearCache(true);
        webView.loadUrl("about:blank");
        webView.freeMemory();
        webView.pauseTimers();
    }

    public void setBaseUrl(String url) {
        this.baseUrl = url;
    }

    public String getBaseUrl() {
        return baseUrl;
    }

    public void enablePullRefresh(boolean enable) {
        if (enable) {
            setMode(Mode.PULL_FROM_START);
        } else {
            setMode(Mode.DISABLED);
        }
    }

    public void load() {
        if (baseUrl == null || baseUrl.equals("")) {
            //Log.info(TAG, "load url is wrong!");
            return;
        }
        if (!baseUrl.contains("http")) {
            baseUrl = "http://" + baseUrl;
        }
        webView.loadUrl(baseUrl);
    }

    public void reload() {
        String url = webView.getUrl();
        if ((TextUtils.isEmpty(url) || url.equals("about:blank")) ||
                (tvNetError != null && tvNetError.getVisibility() == VISIBLE)) {
            load();
        } else {
            webView.reload();
        }
    }

    private WebViewListener listener;

    public void setListener(WebViewListener listener) {
        this.listener = listener;
    }

    private class MyWebViewClient extends WebViewClient {
        private boolean isError;

        public MyWebViewClient() {
        }

        // 覆盖WebView默认使用第三方或系统默认浏览器打开网页的行为，使网页用WebView打开
        @Override
        public boolean shouldOverrideUrlLoading(WebView view, String url) {
            view.loadUrl(url);
            return true;// 返回值是true的时候控制去WebView打开，为false调用系统浏览器或第三方浏览器
        }

        @Override
        public void onReceivedError(WebView view, int errorCode, String description, String failingUrl) {
            super.onReceivedError(view, errorCode, description, failingUrl);
            view.loadUrl("about:blank");
            if (tvNetError != null) {
                tvNetError.setVisibility(VISIBLE);
            }
            android.util.Log.e("yanshoutag", "onReceivedError " + description);
            isError = true;
        }


        @Override
        public void onPageStarted(WebView view, String url, Bitmap favicon) {
            super.onPageStarted(view, url, favicon);
            if (tvNetError != null) {
                tvNetError.setVisibility(GONE);
            }
            //view.addJavascriptInterface(jsInterface, "YanShouInterface");
            android.util.Log.e("yanshoutag", "onPageStarted url = " + url);
        }

        @Override
        public void onPageFinished(WebView view, String url) {
            //清除缓存
            view.clearCache(true);
            view.clearHistory();
            super.onPageFinished(view, url);
            //view.addJavascriptInterface(jsInterface, "YanShouInterface");
            android.util.Log.e("yanshoutag", "onPageFinished url = " + url);

            if (!isError && tvNetError != null) {
                tvNetError.setVisibility(GONE);
            }
        }

        @Override
        public void onReceivedSslError(WebView view, SslErrorHandler handler, SslError error) {
            handler.proceed();// 忽略证书错误
            android.util.Log.e("yanshoutag", "onReceivedSslError error = " + error);
        }

    }

    private class MyWebChromeClient extends WebChromeClient {
        // 定位需要
        public void onGeolocationPermissionsShowPrompt(String origin, GeolocationPermissions.Callback callback) {
            callback.invoke(origin, true, false);
            super.onGeolocationPermissionsShowPrompt(origin, callback);
        }

        // For Android < 3.0
        public void openFileChooser(ValueCallback<Uri> valueCallback) {
            uploadMessage = valueCallback;
            openImageChooserActivity();
        }

        // For Android  >= 3.0
        public void openFileChooser(ValueCallback valueCallback, String acceptType) {
            uploadMessage = valueCallback;
            openImageChooserActivity();
        }

        //For Android  >= 4.1
        public void openFileChooser(ValueCallback<Uri> valueCallback, String acceptType, String capture) {
            uploadMessage = valueCallback;
            openImageChooserActivity();
        }

        // For Android >= 5.0
        @Override
        public boolean onShowFileChooser(WebView webView, ValueCallback<Uri[]> filePathCallback, WebChromeClient.FileChooserParams fileChooserParams) {
            uploadMessageAboveL = filePathCallback;
            openImageChooserActivity();
            return true;
        }

        public void onProgressChanged(WebView view, int newProgress) {
            if (newProgress >= 100) {
                onRefreshComplete();
            }
        }
    }

    private void openImageChooserActivity() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && ActivityCompat.checkSelfPermission(getContext(), Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
            Toast.makeText(getContext(), "没有权限,请手动开启相机权限", Toast.LENGTH_SHORT).show();
            if (uploadMessageAboveL != null) {
                uploadMessageAboveL.onReceiveValue(null);
                uploadMessageAboveL = null;
            }
            if (uploadMessage != null) {
                uploadMessage.onReceiveValue(null);
                uploadMessage = null;
            }
            return;
        }

        if (listener != null) {
            listener.takeCamera(cameraFilePath, GlobalConstant.FILE_CAMERA_RESULT_CODE);
        }
    }

    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        if (null == uploadMessage && null == uploadMessageAboveL) return;
        if (resultCode != Activity.RESULT_OK) {//同上所说需要回调onReceiveValue方法防止下次无法响应js方法
            if (uploadMessageAboveL != null) {
                uploadMessageAboveL.onReceiveValue(null);
                uploadMessageAboveL = null;
            }
            if (uploadMessage != null) {
                uploadMessage.onReceiveValue(null);
                uploadMessage = null;
            }
            return;
        }
        Uri result = null;
        if (requestCode == GlobalConstant.FILE_CAMERA_RESULT_CODE) {
            if (null != data && null != data.getData()) {
                result = data.getData();
            }
            if (result == null && hasFile(cameraFilePath)) {
                result = Uri.fromFile(new File(cameraFilePath));
            }
            if (uploadMessageAboveL != null) {
                uploadMessageAboveL.onReceiveValue(new Uri[]{result});
                uploadMessageAboveL = null;
            } else if (uploadMessage != null) {
                uploadMessage.onReceiveValue(result);
                uploadMessage = null;
            }
        } else if (requestCode == GlobalConstant.FILE_CHOOSER_RESULT_CODE) {
            if (data != null) {
                result = data.getData();
            }
            if (uploadMessageAboveL != null) {
                onActivityResultAboveL(data);
            } else if (uploadMessage != null) {
                uploadMessage.onReceiveValue(result);
                uploadMessage = null;
            }
        }
    }

    /**
     * 判断文件是否存在
     */
    public static boolean hasFile(String path) {
        try {
            File f = new File(path);
            if (!f.exists()) {
                return false;
            }
        } catch (Exception e) {
            return false;
        }
        return true;
    }

    @TargetApi(Build.VERSION_CODES.LOLLIPOP)
    private void onActivityResultAboveL(Intent intent) {
        Uri[] results = null;
        if (intent != null) {
            String dataString = intent.getDataString();
            ClipData clipData = intent.getClipData();
            if (clipData != null) {
                results = new Uri[clipData.getItemCount()];
                for (int i = 0; i < clipData.getItemCount(); i++) {
                    ClipData.Item item = clipData.getItemAt(i);
                    results[i] = item.getUri();
                }
            }
            if (dataString != null)
                results = new Uri[]{Uri.parse(dataString)};
        }
        uploadMessageAboveL.onReceiveValue(results);
        uploadMessageAboveL = null;
    }

    public interface WebViewListener {
        void takeCamera(String path, int code);
    }

    private JSInterface jsInterface = new JSInterface();

    private final class JSInterface {
        /**
         * 注意这里的@JavascriptInterface注解， target是4.2以上都需要添加这个注解，否则无法调用
         */
        @JavascriptInterface
        public String getLocation() {
            JSONObject jsonObject = new JSONObject();
            Location location = GpsManager.getInstance().getLocation(getContext());
            if (location != null) {
                try {
                    jsonObject.put("latitude", location.getLatitude());
                    jsonObject.put("longitude", location.getLongitude());
                } catch (JSONException e) {
                    e.printStackTrace();
                }
            }
            return jsonObject.toString();
        }
    }


}
