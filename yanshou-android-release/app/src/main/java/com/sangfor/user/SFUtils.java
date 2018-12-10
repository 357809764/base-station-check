package com.sangfor.user;

import com.sangfor.ssl.IConstants;
import com.sy.yanshou.sanming.wuxian.R;

public class SFUtils implements IConstants {

    /**
     * 对话框标题
     *
     * @param authType 认证类型
     * @return 对话框标题
     */
    public static String getDialogTitle(int authType) {
        switch (authType) {
            case AUTH_TYPE_PASSWORD:
                return "密码认证";
            case AUTH_TYPE_SMS:
                return "短信认证";
            case AUTH_TYPE_RADIUS:
                return "挑战认证";
            case AUTH_TYPE_CERTIFICATE:
                return "证书认证";
            case AUTH_TYPE_TOKEN:
                return "令牌认证";
            case AUTH_TYPE_RAND_CODE:
                return "图形校验码";
            case AUTH_TYPE_RENEW_PASSWORD:
            case AUTH_TYPE_RENEW_PASSWORD_WITH_OLDPASSWORD:
                return "修改密码";
            default:
                return "VPN认证";
        }
    }

    public static int getAuthDialogViewId(int authType) {
        switch (authType) {
            case AUTH_TYPE_PASSWORD:
                return R.layout.dialog_pwd;
            case AUTH_TYPE_SMS:
                return R.layout.dialog_sms;
            case AUTH_TYPE_RADIUS:
                return R.layout.dialog_challenge;
            case AUTH_TYPE_CERTIFICATE:
                return R.layout.dialog_certificate;
            case AUTH_TYPE_TOKEN:
                return R.layout.dialog_token;
            case AUTH_TYPE_RAND_CODE:
                return R.layout.dialog_graph_check;
            case AUTH_TYPE_RENEW_PASSWORD:
                return R.layout.dialog_force_update_pwd;
            case AUTH_TYPE_RENEW_PASSWORD_WITH_OLDPASSWORD:
                return R.layout.dialog_force_update_pwd_with_old_pwd;
            default:
                return R.layout.dialog_update_pwd;
        }
    }
    /**
     * 对话框内容
     *
     * @param authType 认证类型
     * @return 认证类型描述
     */
    public static String getAuthTypeDescription(int authType) {
        switch (authType) {
            case AUTH_TYPE_PASSWORD:
                return "密码认证";
            case AUTH_TYPE_SMS:
                return "短信认证";
            case AUTH_TYPE_RADIUS:
                return "挑战认证";
            case AUTH_TYPE_CERTIFICATE:
                return "证书认证";
            case AUTH_TYPE_TOKEN:
                return "令牌认证";
            case AUTH_TYPE_RAND_CODE:
                return "图形校验码";
            case AUTH_TYPE_RENEW_PASSWORD:
            case AUTH_TYPE_RENEW_PASSWORD_WITH_OLDPASSWORD:
                return "修改密码";
            default:
                return "VPN认证";
        }
    }

}
