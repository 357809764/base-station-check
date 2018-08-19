package com.sy.yanshou;

import android.app.Service;
import android.bluetooth.BluetoothAdapter;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.os.IBinder;
import android.support.annotation.Nullable;
import android.text.TextUtils;
import android.util.Log;

import com.sy.yanshou.bean.NetChangeEvent;

import org.greenrobot.eventbus.EventBus;


public class NetMonitorServer extends Service {
    private final String TAG = NetMonitorServer.class.getSimpleName();
    private NetChangeReceiver receiver = new NetChangeReceiver();
    private IntentFilter filter;

    public static void startServer(Context context) {
        Intent intent = new Intent(context, NetMonitorServer.class);
        intent.setAction("NetServer");
        context.startService(intent);
    }

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    @Override
    public void onCreate() {
        super.onCreate();
        filter = new IntentFilter();
        filter.addAction(ConnectivityManager.CONNECTIVITY_ACTION);
        filter.addAction(BluetoothAdapter.ACTION_STATE_CHANGED);
        registerReceiver(receiver, filter);
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        return START_NOT_STICKY;
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        unregisterReceiver(receiver);
    }

    class NetChangeReceiver extends BroadcastReceiver {
        private boolean isFirstChangeNetwork = true;

        @Override
        public void onReceive(Context context, Intent intent) {
            String action = intent.getAction();
            if (TextUtils.isEmpty(action)) {
                return;
            }
            switch (action) {
                case ConnectivityManager.CONNECTIVITY_ACTION: {
                    NetworkInfo networkInfo = intent.getParcelableExtra(ConnectivityManager.EXTRA_NETWORK_INFO);
                    if (intent.getBooleanExtra(ConnectivityManager.EXTRA_NO_CONNECTIVITY, false)) {
                        ConstantUtils.IS_NETWORK_AVAILABLE = false;
                    } else {
                        NetworkInfo.State state = networkInfo != null ? networkInfo.getState() : null;
                        if (networkInfo != null && state == NetworkInfo.State.CONNECTED) {
                            ConstantUtils.IS_NETWORK_AVAILABLE = true;
                            Log.w(TAG, "IS_NETWORK_AVAILABLE = true");
                            switch (networkInfo.getType()) {
                                case ConnectivityManager.TYPE_WIFI:
                                    ConstantUtils.IS_WIFI_AVAILABLE = true;
                                    if (!isFirstChangeNetwork) {
                                        EventBus.getDefault().post(new NetChangeEvent(true));
                                    }
                                    break;
                                case ConnectivityManager.TYPE_MOBILE:
                                    ConstantUtils.IS_WIFI_AVAILABLE = false;
                                    if (!isFirstChangeNetwork) {
                                        EventBus.getDefault().post(new NetChangeEvent(true));
                                    }
                                    break;
                                default:
                                    ConstantUtils.IS_WIFI_AVAILABLE = false;
                                    break;
                            }
                        } else {
                            ConstantUtils.IS_NETWORK_AVAILABLE = false;
                        }
                    }
                    Log.i(TAG, "网络状态更改");
                    isFirstChangeNetwork = false;
                }
            }
        }
    }
}
