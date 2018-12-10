package com.sy.yanshou;

import android.content.Intent;
import android.content.SharedPreferences;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.SystemClock;
import android.provider.MediaStore;
import android.support.v4.content.FileProvider;
import android.text.TextUtils;
import android.util.Log;
import android.view.KeyEvent;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.CheckBox;
import android.widget.CompoundButton;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.Toast;

import com.sangfor.ssl.SangforAuthManager;
import com.sangfor.vpn.vpndemo.LoginActivity;
import com.sy.yanshou.bean.NetChangeEvent;
import com.sy.yanshou.sanming.wuxian.R;
import com.tencent.bugly.crashreport.CrashReport;

import org.greenrobot.eventbus.EventBus;
import org.greenrobot.eventbus.Subscribe;
import org.greenrobot.eventbus.ThreadMode;

import java.io.File;
import java.net.MalformedURLException;
import java.net.URL;

public class MainActivity extends LoginActivity implements RefreshWebView.WebViewListener {
    private static String TAG = MainActivity.class.getSimpleName();
    private boolean isHook = true; // false 使用demo的ui，true使用自定义ui
    private View mainView;

    private View viewVpnCfg;
    private CheckBox mEnableRefresh;
    private CheckBox mEnableVPN;
    private EditText mWebViewIpEditText;
    private EditText mVPNEditText = null;
    private EditText mUserNameEditView;
    private EditText mUserPasswordEditView;

    private RefreshWebView refreshWebView;
    private boolean isFirstLoginSuccess;
    private View viewSetting;
    private boolean isFirstLogin = true;
    private boolean isEnableVpn;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        FrameLayout frameLayout = (FrameLayout) findViewById(R.id.view_container);
        mainView = LayoutInflater.from(this).inflate(R.layout.view_main, null);
        FrameLayout.LayoutParams params = new FrameLayout.LayoutParams(-1, -1);
        frameLayout.addView(mainView, params);
        mainView.setVisibility(isHook ? View.VISIBLE : View.GONE);
        initViewAndEvent();

        CrashReport.initCrashReport(this, "6bb59cb000", false);      //Bugly初始化
        EventBus.getDefault().register(this);
        GpsManager.getInstance().enable = true;
        GpsManager.getInstance().init(this);

        getLoginInfo();
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        SangforAuthManager.getInstance().vpnLogout();
        EventBus.getDefault().unregister(this);
        if (refreshWebView != null) {
            refreshWebView.destroy();
        }
    }

    private void initViewAndEvent() {
        refreshWebView = (RefreshWebView) findViewById(R.id.refresh_webview);
        viewSetting = findViewById(R.id.view_setting);
        viewSetting.setVisibility(View.GONE);

        viewVpnCfg = findViewById(R.id.view_vpn_cfg);
        mEnableRefresh = (CheckBox) findViewById(R.id.cb_enable_refresh);
        mEnableVPN = (CheckBox)findViewById(R.id.cb_enable_vpn);
        mVPNEditText = (EditText) findViewById(R.id.et_ip);
        mUserNameEditView = (EditText) findViewById(R.id.et_username);
        mUserPasswordEditView = (EditText) findViewById(R.id.et_password);
        mWebViewIpEditText = (EditText) findViewById(R.id.et_net_ip);
        refreshWebView.setListener(this);

        //登录按钮监听
        findViewById(R.id.btn_login).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (isEnableVpn) {
                    doVPNLogin();
                } else {
                    refreshWebView.setBaseUrl(mWebViewIpEditText.getText().toString().trim());
                    doResourceRequest();
                }
            }
        });


        MaskView maskView = (MaskView) findViewById(R.id.btn_hide);
        maskView.setRepeatClickListener(new MaskView.OnRepeatClickListener() {
            @Override
            public void onRepeatClick() {
                viewSetting.setVisibility(View.VISIBLE);
            }
        });

        findViewById(R.id.btn_hide_set).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                viewSetting.setVisibility(View.GONE);
            }
        });

        mEnableRefresh.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                refreshWebView.enablePullRefresh(isChecked);
                setLoginInfo();
            }
        });

        mEnableVPN.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                if (isChecked) {

                } else {
                    SangforAuthManager.getInstance().vpnLogout();
                }
                isEnableVpn = isChecked;
                setLoginInfo();
                viewVpnCfg.setVisibility(isEnableVpn ? View.VISIBLE : View.GONE);
            }
        });

        findViewById(R.id.btn_vpn_test).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                //"http://www.zzwankun.com/test.html"
                mWebViewIpEditText.setText("http://134.129.112.108:3694/?ys_ver=i1");//http://134.129.112.108:3694/?ys_ver=i1 120.36.56.152
                mVPNEditText.setText("https://218.85.155.91:443");
                mUserNameEditView.setText("fjdx#cwwy"); //fjzhengxy
                mUserPasswordEditView.setText("fjdxDB@#qtG12");//"aqgz.#2000GXB"
            }
        });
    }

    /**
     * 进行免密登录流程
     */
    @Override
    protected void startTicketLogin() {
        if (!isHook) {
            super.startTicketLogin();
            return;
        } else {
            if (isFinishing()) {
                return;
            }
            initLoginParms();
        }
    }

    private void doVPNLogin() {
        if (!getIsEnableVpn()) {
            return;
        }

        // 开始认证前进行数据检查,如有错误直接返回，不进行登录流程
        if (!getValueFromView()) return;
        //开启登录流程
        startVPNInitAndLogin();
    }


    /**
     * 设置登录信息
     */
    private void getLoginInfo() {
        SharedPreferences sharedPreferences = getSharedPreferences("config_fyl", MODE_PRIVATE);

        String webViewIp = sharedPreferences.getString("WebViewAddress", refreshWebView.getBaseUrl());
        boolean isChecked = sharedPreferences.getBoolean("EnableRefresh", false);
        mVpnAddress = sharedPreferences.getString("VpnAddress", mVpnAddress);
        mUserName = sharedPreferences.getString("UserName", mUserName);
        mUserPassword = sharedPreferences.getString("UserPassword", mUserPassword);
        isEnableVpn = sharedPreferences.getBoolean("isEnableVpn", true);

        if (TextUtils.isEmpty(webViewIp) || TextUtils.isEmpty(mVpnAddress) || TextUtils.isEmpty(mUserName) || TextUtils.isEmpty(mUserPassword)) {
            //viewSetting.setVisibility(View.VISIBLE);
        }

        mEnableRefresh.setChecked(isChecked);
        mWebViewIpEditText.setText(webViewIp);
        mVPNEditText.setText(mVpnAddress);
        mUserNameEditView.setText(mUserName);
        mUserPasswordEditView.setText(mUserPassword);
        mEnableVPN.setChecked(isEnableVpn);
        viewVpnCfg.setVisibility(isEnableVpn ? View.VISIBLE : View.GONE);
    }

    private boolean getIsEnableVpn() {
        SharedPreferences sharedPreferences = getSharedPreferences("config_fyl", MODE_PRIVATE);
        return sharedPreferences.getBoolean("isEnableVpn", true);
    }

    /**
     * SharedPreferences保存登录信息
     */
    private void setLoginInfo() {
        SharedPreferences sharedPreferences = getSharedPreferences("config_fyl", MODE_PRIVATE);
        SharedPreferences.Editor editor = sharedPreferences.edit();
        editor.putBoolean("EnableRefresh", mEnableRefresh.isChecked());
        editor.putString("VpnAddress", mVpnAddress);
        //保存用户名和密码，真实场景请加密存储
        editor.putString("UserName", mUserName);
        editor.putString("UserPassword", mUserPassword);
        editor.putString("WebViewAddress", refreshWebView.getBaseUrl());
        editor.putBoolean("isEnableVpn", mEnableVPN.isChecked());
        editor.apply();
    }


    // 登录过程拦截demo中的登录参数
    @Override
    protected boolean getValueFromView() {
        if (!isHook) {
            return super.getValueFromView();
        }

        //mAuthMethod =  AUTH_TYPE_PASSWORD;
        try {
            mVpnAddress = mVPNEditText.getText().toString().trim();
            if (TextUtils.isEmpty(mVpnAddress)) {
                Toast.makeText(MainActivity.this, R.string.str_vpn_address_is_empty, Toast.LENGTH_SHORT).show();
                return false;
            }
            mVpnAddressURL = new URL(mVpnAddress);
        } catch (MalformedURLException e) {
            Toast.makeText(this, R.string.str_url_error, Toast.LENGTH_SHORT).show();
            return false;
        }

        refreshWebView.setBaseUrl(mWebViewIpEditText.getText().toString().trim());
        mUserName = mUserNameEditView.getText().toString().trim();
        mUserPassword = mUserPasswordEditView.getText().toString().trim();
        return true;
    }


    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        try {
            switch (requestCode) {
                case GlobalConstant.FILE_CAMERA_RESULT_CODE:
                case GlobalConstant.FILE_CHOOSER_RESULT_CODE:
                    if (refreshWebView != null) {
                        refreshWebView.onActivityResult(requestCode, resultCode, data);
                    }
                    break;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        super.onActivityResult(requestCode, resultCode, data);
    }

    @Override
    protected void doResourceRequest() {
        if (!isHook) {
            super.doResourceRequest();
            return;
        }

        refreshWebView.enablePullRefresh( mEnableRefresh.isChecked());

        setLoginInfo();
        viewSetting.setVisibility(View.GONE);
        if (!isFirstLoginSuccess) {
            isFirstLoginSuccess = true;
            refreshWebView.load();
        } else {
            //webView.reload();
            refreshWebView.load();
        }
    }

    /**
     * 回调接口：权限授权成功处理动作
     * SDK >= Android6.0需要实现该接口
     */
    @Override
    protected void permissionGrantedSuccess() {
        if (!isHook) {
            super.permissionGrantedSuccess();
            return;
        }

        autoLogin();
    }

    @Override
    protected void permissionLowLevel() {
        if (!isHook) {
            super.permissionLowLevel();
            return;
        }

        autoLogin();
    }

    private void autoLogin() {
        if (isFirstLogin) {
            isFirstLogin = false;
            doVPNLogin();
        }
    }

    @Override
    public void takeCamera(String path, int code) {
        Log.e(TAG, "takeCamera path : " + path + " code : " + code);
        Uri uri;
        File file = new File(path);
        Intent intent = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
        if (Build.VERSION.SDK_INT >= 24) {
            intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION); //添加这一句表示对目标应用临时授权该Uri所代表的文件
            uri = FileProvider.getUriForFile(MainActivity.this, "com.fyl.fileprovider2", file);
        } else {
            uri = Uri.fromFile(file);
        }
        intent.putExtra(MediaStore.EXTRA_OUTPUT, uri);
        startActivityForResult(intent, code);
    }

    private long preBackTime = 0;

    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event) {
        long curClickTime = SystemClock.uptimeMillis();
        if (curClickTime - preBackTime > 2000) {
            preBackTime = curClickTime;
            Toast.makeText(MainActivity.this, "再按一次退出" + getString(R.string.app_name), Toast.LENGTH_SHORT).show();
            return true;
        }
        return super.onKeyDown(keyCode, event);
    }

    @Subscribe(threadMode = ThreadMode.MAIN)
    public void onEvent(NetChangeEvent event) {
        //refreshWebView.reload();
        //doVPNLogin();
    }
}
