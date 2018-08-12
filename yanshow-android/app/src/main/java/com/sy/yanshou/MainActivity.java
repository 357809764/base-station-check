package com.sy.yanshou;

import android.Manifest;
import android.app.AlertDialog;
import android.app.ProgressDialog;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.Color;
import android.graphics.drawable.Drawable;
import android.os.AsyncTask;
import android.os.Bundle;
import android.os.CountDownTimer;
import android.os.Handler;
import android.os.SystemClock;
import android.text.TextUtils;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import com.sangfor.bugreport.logger.Log;
import com.sangfor.ssl.BaseMessage;
import com.sangfor.ssl.ChallengeMessage;
import com.sangfor.ssl.ChangePswMessage;
import com.sangfor.ssl.IConstants;
import com.sangfor.ssl.IVpnDelegate;
import com.sangfor.ssl.LoginResultListener;
import com.sangfor.ssl.OnStatusChangedListener;
import com.sangfor.ssl.RandCodeListener;
import com.sangfor.ssl.SFException;
import com.sangfor.ssl.SangforAuthManager;
import com.sangfor.ssl.SmsMessage;
import com.sangfor.ssl.StatusChangedReason;
import com.sangfor.ssl.common.ErrorCode;
import com.sangfor.user.SFUtils;
import com.sangfor.user.SangforAuthDialog;

import java.net.MalformedURLException;
import java.net.URL;

public class MainActivity extends BaseCheckPermissionActivity implements LoginResultListener, RandCodeListener {
    //需要用到的权限列表，WRITE_EXTERNAL_STORAGE权限在android6.0设备上需要动态申请
    private static final String[] ALL_PERMISSIONS_NEED = {
            Manifest.permission.INTERNET, Manifest.permission.READ_PHONE_STATE,
            Manifest.permission.ACCESS_WIFI_STATE,
            Manifest.permission.ACCESS_NETWORK_STATE,
            Manifest.permission.WRITE_EXTERNAL_STORAGE,
            Manifest.permission.CAMERA
    };

    private static final String TAG = "LoginActivity";
    private static final int CERTFILE_REQUESTCODE = 33;        //主界面中证书选择器请求码
    private static final int DIALOG_CERTFILE_REQUESTCODE = 34; //对话框中选择器的请求码
    private static final int DEFAULT_SMS_COUNTDOWN = 30;       //短信验证码默认倒计时时间

    private VPNWebView webView;
    private View viewSetting;
    private boolean isFirstLogin = true;

    private SangforAuthManager mSFManager = null;
    private VPNMode mVpnMode = VPNMode.L3VPN;            //默认开启L3VPN模式
    //暂时只支持https协议，不提供端口号时，使用默认443端口
    private URL mVpnAddressURL = null;
    private String mVpnAddress = "https://218.85.155.91:443";
    private String mUserName = "fjzhengxy";
    private String mUserPassword = "aqgz.#2000GXB";
    private boolean isClickedLogout;

    //主认证默认采用用户名+密码方式
    private int mAuthMethod = AUTH_TYPE_PASSWORD;
    private int mSmsRefreshTime = 30;                    //短信倒计时默认时间

    // View
    private AlertDialog mDialog = null;
    private EditText mIPEditText = null;
    private EditText mUserNameEditView = null;
    private EditText mUserPasswordEditView = null;
    private ImageView mRandCodeView = null;
    private ProgressDialog mProgressDialog = null; // 对话框对象

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        initLoginParms();
        //判断是否开启免密，如果免密直接进行一次登录，如果无法免密或免密登录失败，走正常流程
        if (mSFManager.ticketAuthAvailable(this)) { //允许免密，直接走免密流程
            try {
                //开启登录进度框
                createWaitingProgressDialog();
                mSFManager.startTicketAuthLogin(getApplication(), MainActivity.this, mVpnMode);
            } catch (SFException e) {
                //关闭登录进度框
                cancelWaitingProgressDialog();
                Log.info(TAG, "SFException:%s", e);
            }
        }

        initView();
        initClickEvents();
        setLoginInfo();
    }

    /**
     * 初始化界面元素
     */
    private void initView() {

        webView = (VPNWebView) findViewById(R.id.view_vnp);
        viewSetting = findViewById(R.id.view_setting);

        mIPEditText = (EditText) findViewById(R.id.et_ip);
        mUserNameEditView = (EditText) findViewById(R.id.et_username);
        mUserPasswordEditView = (EditText) findViewById(R.id.et_password);
    }

    /**
     * 注册监听事件
     */
    private void initClickEvents() {

        //登录按钮监听
        findViewById(R.id.btn_login).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                isClickedLogout = false;

                SangforAuthManager.getInstance().vpnLogout();

                doVPNLogin();
            }
        });


        MaskView maskView = (MaskView) findViewById(R.id.btn_hide);
        maskView.setRepeatClickListener(new MaskView.OnRepeatClickListener() {
            @Override
            public void onRepeatClick() {
                viewSetting.setVisibility(View.VISIBLE);
            }
        });
    }

    private void doVPNLogin() {
        // 开始认证前进行数据检查,如有错误直接返回，不进行登录流程
        if (!getValueFromView()) return;
        //开启登录流程
        startVPNInitAndLogin();
    }

    /**
     * 注销流程
     */
    private void doVPNLogout() {
        // 注销VPN登录.
        SangforAuthManager.getInstance().vpnLogout();
        Toast.makeText(this, R.string.str_vpn_logout, Toast.LENGTH_SHORT).show();
    }

    /**
     * 注册vpn状态监听器，可在多处进行注册
     */
    private void addStatusChangedListener() throws SFException {
        mSFManager.addStatusChangedListener(onStatusChangedListener);
    }

    private OnStatusChangedListener onStatusChangedListener = new OnStatusChangedListener() {
        @Override
        public void onStatusCallback(VPNStatus vpnStatus, StatusChangedReason statusChangedReason) {
            //对回调结果进行处理，这里只是简单的显示，可根据业务需求自行扩展
            String status = (vpnStatus == IVpnDelegate.VPNStatus.VPNONLINE) ? getString(R.string.str_vpn_online) : getString(R.string.str_vpn_offline);
            Toast.makeText(MainActivity.this, status, Toast.LENGTH_SHORT).show();

            // 离线3s后重连
            if (vpnStatus != IVpnDelegate.VPNStatus.VPNONLINE && !isClickedLogout) {
                new Handler().postDelayed(new Runnable() {
                    @Override
                    public void run() {
                        doVPNLogin();
                    }
                }, 3000);
            }
        }
    };

    /**
     * 设置登录信息
     */
    private void setLoginInfo() {
        SharedPreferences sharedPreferences = getSharedPreferences("config", MODE_PRIVATE);

        mVpnAddress = sharedPreferences.getString("VpnAddress", mVpnAddress);
        String userName = sharedPreferences.getString("UserName", mUserName);
        String userPassword = sharedPreferences.getString("UserPassword", mUserPassword);

        if (!TextUtils.isEmpty(userName)) {
            mUserName = userName;
        } else {
            viewSetting.setVisibility(View.VISIBLE);
        }

        if (!TextUtils.isEmpty(userPassword)) {
            mUserPassword = userPassword;
        } else {
            viewSetting.setVisibility(View.VISIBLE);
        }

        mIPEditText.setText(mVpnAddress.trim());
        mUserNameEditView.setText(mUserName);
        mUserPasswordEditView.setText(mUserPassword);
    }

    /**
     * 获取登录页面属性值，并进行校验
     */
    private boolean getValueFromView() {
        mAuthMethod = AUTH_TYPE_PASSWORD; //authMethod.equals(getString(R.string.str_tab_password)) ? AUTH_TYPE_PASSWORD : AUTH_TYPE_CERTIFICATE;

        mVpnAddress = mIPEditText.getText().toString().trim();
        if (TextUtils.isEmpty(mVpnAddress)) {
            Toast.makeText(MainActivity.this, R.string.str_vpn_address_is_empty, Toast.LENGTH_SHORT).show();
            return false;
        }

        try {
            if (!mVpnAddress.startsWith("https://")) { //vpn地址是否是以https开头，不以https开头时，为其添加https
                int index = mVpnAddress.indexOf("//");
                if (index == -1) {//没有协议头的情况下添加https协议头
                    mVpnAddress = "https://" + mVpnAddress;
                } else {
                    //其它协议头提示用户错误
                    Toast.makeText(MainActivity.this, R.string.str_url_protocol_error, Toast.LENGTH_SHORT).show();
                    return false;
                }
            }
            //将地址字符串封装成url
            mVpnAddressURL = new URL(mVpnAddress);
        } catch (MalformedURLException e) {
            Toast.makeText(MainActivity.this, R.string.str_url_error, Toast.LENGTH_SHORT).show();
            return false;
        }

        switch (mAuthMethod) {
            case AUTH_TYPE_PASSWORD:
                mUserName = mUserNameEditView.getText().toString().trim();
                mUserPassword = mUserPasswordEditView.getText().toString().trim();
                if (TextUtils.isEmpty(mUserName)) {
                    Toast.makeText(this, R.string.str_username_is_empty, Toast.LENGTH_SHORT).show();
                    return false;
                }
                break;

            case AUTH_TYPE_CERTIFICATE:
                Toast.makeText(this, R.string.str_cert_path_is_empty, Toast.LENGTH_SHORT).show();
                break;
            default:
                break;
        }
        return true;
    }

    /**
     * 初始登录统一接口
     */
    private void startVPNInitAndLogin() {
        if (isFinishing()) {
            return;
        }
        initLoginParms();

        //开启登录进度框
        createWaitingProgressDialog();

        try {
            addStatusChangedListener(); //添加vpn状态变化监听器
            //依据登录方式调用相应的登录接口
            switch (mAuthMethod) {
                case AUTH_TYPE_PASSWORD:
                    //该接口做了两件事：1.vpn初始化；2.用户名/密码主认证过程
                    mSFManager.startPasswordAuthLogin(getApplication(), MainActivity.this, mVpnMode,
                            mVpnAddressURL, mUserName, mUserPassword);
                    break;
                case AUTH_TYPE_CERTIFICATE:
                    //该接口做了两件事：1.vpn初始化；2.证书主认证过程
                    //mSFManager.startCertificateAuthLogin(getApplication(), MainActivity.this, mVpnMode, mVpnAddressURL, mCertPath, mCertPassword);
                    break;
                default:
                    Toast.makeText(MainActivity.this, R.string.str_auth_type_error, Toast.LENGTH_SHORT).show();
                    break;
            }
        } catch (SFException e) {
            //关闭登录进度框
            cancelWaitingProgressDialog();
            Log.info(TAG, "SFException:%s", e);
        }
    }

    /**
     * 初始化登录参数
     */
    private void initLoginParms() {
        // 1.构建SangforAuthManager对象
        mSFManager = SangforAuthManager.getInstance();

        // 2.设置VPN认证结果回调
        try {
            mSFManager.setLoginResultListener(this);
        } catch (SFException e) {
            Log.info(TAG, "SFException:%s", e);
        }

        //3.设置登录超时时间，单位为秒
        mSFManager.setAuthConnectTimeOut(3);
    }

    /**
     * 登录失败回调接口
     *
     * @param errorCode 错误码
     * @param errorStr  错误信息
     */
    @Override
    public void onLoginFailed(ErrorCode errorCode, String errorStr) {
        //停止登录进度框
        cancelWaitingProgressDialog();
        //关闭认证窗口
        closeDialog();
        if (!TextUtils.isEmpty(errorStr)) {
            Toast.makeText(this, getString(R.string.str_login_failed) + errorStr, Toast.LENGTH_SHORT).show();

        } else {
            Toast.makeText(this, R.string.str_login_failed, Toast.LENGTH_SHORT).show();
        }
        viewSetting.setVisibility(View.VISIBLE);
    }

    /**
     * 登录进行中回调接口
     *
     * @param nextAuthType 下次认证类型
     *                     组合认证时必须实现该接口
     */
    @Override
    public void onLoginProcess(int nextAuthType, BaseMessage message) {
        //停止登录进度框
        cancelWaitingProgressDialog();
        // 存在多认证, 需要进行下一次认证
        Toast.makeText(this, getString(R.string.str_next_auth) +
                SFUtils.getAuthTypeDescription(nextAuthType), Toast.LENGTH_SHORT).show();
        SangforAuthDialog sfAuthDialog = new SangforAuthDialog(this);
        createAuthDialog(sfAuthDialog, nextAuthType, message);
        mDialog.show();
    }

    /**
     * 登录成功回调
     */
    @Override
    public void onLoginSuccess() {
        //停止登录进度框
        cancelWaitingProgressDialog();
        //保存登录信息
        saveLoginInfo();
        // 认证成功后即可开始访问资源
        doResourceRequest();
    }

    /**
     * 图形校验码结果回调接口
     */
    @Override
    public void onShowRandCode(Drawable drawable) {
        mRandCodeView.setImageDrawable(drawable);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {

        switch (requestCode) {
            case CERTFILE_REQUESTCODE:
                //获取证书选择器结果
                //mCertPathEditView.setText((resultCode == Activity.RESULT_OK) ? data.getData().getPath().toString().trim() : "");
                break;
            case DIALOG_CERTFILE_REQUESTCODE:
                //当证书认证是辅助认证时获取证书选择器结果
                //mCertPathDialogEditView.setText((resultCode == Activity.RESULT_OK) ? data.getData().getPath().toString().trim() : "");
                break;
            case IVpnDelegate.REQUEST_L3VPNSERVICE:
                /* L3VPN模式下下必须回调此方法
                 * 注意：当前Activity的launchMode不能设置为 singleInstance，否则L3VPN服务启动会失败。
                 */
                mSFManager.onActivityResult(requestCode, resultCode);
                break;
        }
        super.onActivityResult(requestCode, resultCode, data);
    }

    /**
     * 创建认证对话框，初始化点击事件
     *
     * @param sfaDialog 对话框实例
     * @param authType  认证类型
     * @param message   认证附加信息
     */
    public void createAuthDialog(final SangforAuthDialog sfaDialog, final int authType, final BaseMessage message) {
        closeDialog();
        String title = SFUtils.getDialogTitle(authType);
        int viewLayoutId = SFUtils.getAuthDialogViewId(authType);
        final View dialogView = createDialogView(authType, viewLayoutId, message);
        sfaDialog.createDialog(title, dialogView);
        sfaDialog.setPositiveButton(R.string.str_commit, new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                closeDialog();
                commitAdditional(authType, dialogView);
            }
        });
        sfaDialog.setNegativeButton(R.string.str_cancel, new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                closeDialog();
            }
        });
        mDialog = sfaDialog.create();

    }

    /**
     * 开启对话框认证流程
     *
     * @param authType   认证类型
     * @param dialogView 对话框视图
     */
    public void commitAdditional(int authType, View dialogView) {
        //开启认证进度框
        createWaitingProgressDialog();

        try {
            switch (authType) {
                case AUTH_TYPE_PASSWORD:
                    EditText etUserName = (EditText) dialogView.findViewById(R.id.et_username);
                    EditText etPwd = (EditText) dialogView.findViewById(R.id.et_password);
                    mSFManager.doPasswordAuth(etUserName.getText().toString(), etPwd.getText().toString());
                    break;
                case AUTH_TYPE_SMS:
                    EditText etVerfCode = (EditText) dialogView.findViewById(R.id.et_verficationCode);
                    mSFManager.doSMSAuth(etVerfCode.getText().toString());
                    break;
                case AUTH_TYPE_RADIUS:
                    EditText etAuthAnswer = (EditText) dialogView.findViewById(R.id.et_authAnswer);
                    mSFManager.doRadiusAuth(etAuthAnswer.getText().toString());
                    break;
                case AUTH_TYPE_CERTIFICATE:
                    EditText etCertPwd = (EditText) dialogView.findViewById(R.id.et_certPwd);
                    //mSFManager.doCertificateAuth(mCertPathDialogEditView.getText().toString(), etCertPwd.getText().toString());
                    break;
                case AUTH_TYPE_TOKEN:
                    EditText etDynamicToken = (EditText) dialogView.findViewById(R.id.et_dynamicToken);
                    mSFManager.doTokenAuth(etDynamicToken.getText().toString());
                    break;
                case AUTH_TYPE_RAND_CODE:
                    EditText etGraphCode = (EditText) dialogView.findViewById(R.id.et_graphCode);
                    String graphCodeStr = etGraphCode.getText().toString();
                    mSFManager.doRandCodeAuth(graphCodeStr);
                    break;
                case AUTH_TYPE_RENEW_PASSWORD:
                    EditText etNewPwd = (EditText) dialogView.findViewById(R.id.et_newpwd);
                    EditText etReNewPwd = (EditText) dialogView.findViewById(R.id.et_renewpwd);
                    String newPwd = etNewPwd.getText().toString();
                    String reNewPwd = etReNewPwd.getText().toString();
                    if (newPwd.equals(reNewPwd)) {
                        mSFManager.doRenewPasswordAuth(newPwd);
                    } else {
                        cancelWaitingProgressDialog();
                        Toast.makeText(MainActivity.this, R.string.str_password_not_same, Toast.LENGTH_SHORT).show();
                        return;
                    }
                    break;
                case AUTH_TYPE_RENEW_PASSWORD_WITH_OLDPASSWORD:
                    EditText etOldPwd = (EditText) dialogView.findViewById(R.id.et_oldpwd);
                    EditText etNewPwd2 = (EditText) dialogView.findViewById(R.id.et_newpwd);
                    EditText etReNewPwd2 = (EditText) dialogView.findViewById(R.id.et_renewpwd);
                    String oldPwd = etOldPwd.getText().toString();
                    String newPwd2 = etNewPwd2.getText().toString();
                    String reNewPwd2 = etReNewPwd2.getText().toString();
                    if (newPwd2.equals(reNewPwd2)) {
                        mSFManager.doRenewPasswordAuth(oldPwd, newPwd2);
                    } else {
                        cancelWaitingProgressDialog();
                        Toast.makeText(MainActivity.this, R.string.str_password_not_same, Toast.LENGTH_SHORT).show();
                        return;
                    }
                    break;
                default:
                    break;
            }
        } catch (SFException e) {
            Log.info(TAG, "SFException:%s", e);
        }
    }

    /**
     * 创建认证对话框中间显示的视图
     *
     * @param aythtype 认证类型
     * @param layoutId 要加载的视图的布局ID
     * @param message  认证附加信息
     * @return 认证对话框视图
     */
    public View createDialogView(int aythtype, int layoutId, BaseMessage message) {
        LayoutInflater inflater = getLayoutInflater();
        View dialogView = inflater.inflate(layoutId, null);
        switch (aythtype) {
            case AUTH_TYPE_SMS:
                TextView tvTel = (TextView) dialogView.findViewById(R.id.tv_tel);
                final Button btnGetVerficationCode = (Button) dialogView.findViewById(R.id.bt_getVerficationCode);
                String smsPhoneNum = "";
                //获取手机号码
                if (message instanceof SmsMessage) {
                    smsPhoneNum = ((SmsMessage) message).getPhoneNum();
                }
                if (TextUtils.isEmpty(smsPhoneNum)) {
                    tvTel.setText(R.string.str_not_get_phone_number);
                } else {
                    tvTel.setText(getString(R.string.str_phone_number) + smsPhoneNum);
                }

                //开启短信码倒计时
                smsCountDownTimer(btnGetVerficationCode, ((SmsMessage) message).getCountDown());
                btnGetVerficationCode.setOnClickListener(new View.OnClickListener() {
                    @Override
                    public void onClick(View v) { //重新获取验证码，阻塞方法，需要自己实现异步
                        new AsyncTask<Void, Void, SmsMessage>() {
                            @Override
                            protected SmsMessage doInBackground(Void... params) {
                                return mSFManager.reacquireSmsCode();
                            }

                            @Override
                            protected void onPostExecute(SmsMessage smsMessage) {
                                if (smsMessage != null) {
                                    //开启短信验证码倒计时
                                    smsCountDownTimer(btnGetVerficationCode, smsMessage.getCountDown());
                                }
                            }
                        }.execute();
                    }
                });
                break;
            case AUTH_TYPE_RADIUS:
                TextView tvReminder = (TextView) dialogView.findViewById(R.id.tv_reminder);
                String challengeReply = "";
                //获取挑战提示信息
                if (message instanceof ChallengeMessage) {
                    challengeReply = ((ChallengeMessage) message).getChallengeMsg();
                }
                if (TextUtils.isEmpty(challengeReply)) {
                    tvReminder.setText(R.string.str_no_hint);
                } else {
                    tvReminder.setText(getString(R.string.str_hint) + challengeReply);
                }
                break;
            case AUTH_TYPE_CERTIFICATE:
                //mCertPathDialogEditView = (EditText) dialogView.findViewById(R.id.et_certPath);
                TextView tvCertPath = (TextView) dialogView.findViewById(R.id.tv_certPath);
                tvCertPath.setOnClickListener(new View.OnClickListener() {
                    @Override
                    public void onClick(View v) {
                        openSystemFile(DIALOG_CERTFILE_REQUESTCODE);
                    }
                });

                break;
            case AUTH_TYPE_RENEW_PASSWORD:
            case AUTH_TYPE_RENEW_PASSWORD_WITH_OLDPASSWORD:
                TextView tvPolicy = (TextView) dialogView.findViewById(R.id.tv_policy);
                String policy = "";
                //获取密码策略
                if (message instanceof ChangePswMessage) {
                    policy = ((ChangePswMessage) message).getPolicyMsg();
                }
                if (TextUtils.isEmpty(policy)) {
                    tvPolicy.setText(R.string.str_no_policy);
                } else {
                    tvPolicy.setText(getString(R.string.str_policy_hint) + "\n" + policy);
                }
                break;
            case AUTH_TYPE_RAND_CODE:
                mRandCodeView = (ImageView) dialogView.findViewById(R.id.iv_graphCode);
                try {
                    mSFManager.setRandCodeListener(MainActivity.this);
                } catch (SFException e) {
                    Log.info(TAG, "SFException:%s", e);
                }
                mSFManager.reacquireRandCode();

                mRandCodeView.setOnClickListener(new View.OnClickListener() {
                    @Override
                    public void onClick(View v) {
                        mSFManager.reacquireRandCode();
                    }
                });
                break;
            default:
                break;

        }
        return dialogView;
    }

    /**
     * 短信验证码倒计时器
     *
     * @param button 显示计时的按钮控件
     */
    private void smsCountDownTimer(final Button button, final int countDown) {
        mSmsRefreshTime = countDown < 0 ? DEFAULT_SMS_COUNTDOWN : countDown;
        //开启短信验证码倒计时，第一个参数为倒计时时间（毫秒），第二个为时间间隔
        CountDownTimer countDownTimer = new CountDownTimer(mSmsRefreshTime * 1000, 1000) {
            @Override
            public void onTick(long millisUntilFinished) {
                button.setText(millisUntilFinished / 1000 + getString(R.string.str_after_time_resend));
                button.setTextColor(Color.parseColor("#708090"));
                button.setClickable(false);
            }

            @Override
            public void onFinish() {
                button.setText(R.string.str_resend);
                button.setTextColor(Color.parseColor("#000000"));
                button.setClickable(true);
            }
        }.start();
    }

    /**
     * 调用系统自带的文件选择器
     *
     * @param requestCode 请求码
     */
    private void openSystemFile(int requestCode) {
        Intent intent = new Intent(Intent.ACTION_GET_CONTENT);
        intent.setType("*/*");
        intent.addCategory(Intent.CATEGORY_OPENABLE);
        startActivityForResult(intent, requestCode);
    }

    /**
     * SharedPreferences保存登录信息
     */
    private void saveLoginInfo() {
        SharedPreferences sharedPreferences = getSharedPreferences("config", MODE_PRIVATE);
        SharedPreferences.Editor editor = sharedPreferences.edit();
        editor.putString("VpnAddress", mVpnAddress);
        //保存用户名和密码，真实场景请加密存储
        editor.putString("UserName", mUserName);
        editor.putString("UserPassword", mUserPassword);
        editor.apply();
    }

    /**
     * 可以开始访问资源。
     */
    private void doResourceRequest() {
        viewSetting.setVisibility(View.GONE);
        webView.reload();
    }


    /**
     * 关闭对话框
     */
    private void closeDialog() {
        if (mDialog != null && mDialog.isShowing()) {
            mDialog.dismiss();
            mDialog = null;
        }
    }

    /**
     * 创建登录进度框
     */
    protected void createWaitingProgressDialog() {
        if (mProgressDialog == null || !mProgressDialog.isShowing()) {
            mProgressDialog = new ProgressDialog(MainActivity.this);
            mProgressDialog.setProgressStyle(ProgressDialog.STYLE_SPINNER);
            mProgressDialog.setTitle("");
            mProgressDialog.setMessage(getString(R.string.str_waiting));
            mProgressDialog.setCancelable(false);
            mProgressDialog.show();
        }
    }

    /**
     * 取消登录进度框
     */
    protected void cancelWaitingProgressDialog() {
        if (mProgressDialog != null && mProgressDialog.isShowing()) {
            mProgressDialog.dismiss();
            mProgressDialog = null;
        }
    }

    /**
     * 回调接口：获取权限列表
     * SDK >= Android6.0需要实现该接口
     *
     * @return
     */
    @Override
    protected String[] getNeedPermissions() {
        return ALL_PERMISSIONS_NEED;
    }

    /**
     * 回调接口：权限授权成功处理动作
     * SDK >= Android6.0需要实现该接口
     */
    @Override
    protected void permissionGrantedSuccess() {
        if (isFirstLogin) {
            isFirstLogin = false;
            doVPNLogin();
        }
    }

    /**
     * 回调接口：权限授权失败处理动作
     * SDK >= Android6.0需要实现该接口
     */
    @Override
    protected void permissionGrantedFail() {
        Toast.makeText(MainActivity.this, R.string.str_permission_not_all_pass, Toast.LENGTH_SHORT).show();
    }
}
