package com.sy.yanshou;

import android.Manifest;
import android.content.Context;
import android.content.pm.PackageManager;
import android.location.Location;
import android.location.LocationListener;
import android.location.LocationManager;
import android.location.LocationProvider;
import android.os.Build;
import android.os.Bundle;
import android.support.v4.app.ActivityCompat;
import android.text.TextUtils;
import android.util.Log;
import android.widget.Toast;

import java.util.List;

public class GpsManager {
    private static GpsManager instance = new GpsManager();
    //定位都要通过LocationManager这个类实现
    private LocationManager locationManager;
    private String provider;
    private Context context;
    private Location location; //latitude, longitude;

    public boolean enable;

    private GpsManager() {

    }

    public static GpsManager getInstance() {
        return instance;
    }

    public void init(Context context) {
        if (!enable) {
            return;
        }

        try {
            initGps(context);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void initGps(Context context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (ActivityCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED &&
                    ActivityCompat.checkSelfPermission(context, Manifest.permission.ACCESS_COARSE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
                Toast.makeText(context, "请检查网络或GPS是否打开", Toast.LENGTH_LONG).show();
                return;
            }
        }

        //获取定位服务
        this.locationManager = (LocationManager) context.getSystemService(Context.LOCATION_SERVICE);

        //获取当前可用的位置控制器
        List<String> list = locationManager.getProviders(true);
        do {
            if (list.contains(LocationManager.GPS_PROVIDER)) {
                provider = LocationManager.GPS_PROVIDER;
                this.location = locationManager.getLastKnownLocation(provider);
                if (location != null) {
                    break;
                }
            }

            if (list.contains(LocationManager.NETWORK_PROVIDER)) {
                provider = LocationManager.NETWORK_PROVIDER;
                this.location = locationManager.getLastKnownLocation(provider);
                if (location != null) {
                    break;
                }
            }

            if (list.contains(LocationManager.PASSIVE_PROVIDER)) {
                provider = LocationManager.PASSIVE_PROVIDER;
                this.location = locationManager.getLastKnownLocation(provider);
                if (location != null) {
                    break;
                }
            }
        } while (false);

        if (TextUtils.isEmpty(provider)) {
            Toast.makeText(context, "请检查网络或GPS是否打开", Toast.LENGTH_LONG).show();
            return;
        }

        //绑定定位事件，监听位置是否改变
        //第一个参数为控制器类型第二个参数为监听位置变化的时间间隔（单位：毫秒）
        //第三个参数为位置变化的间隔（单位：米）第四个参数为位置监听器
        try {
            locationManager.requestLocationUpdates(LocationManager.GPS_PROVIDER, 2000, 2, locationListener);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public Location getLocation(Context context) {
        if (!enable) {
            return null;
        }
        if (location == null) {
            init(context);
        }
        return location;
    }

    LocationListener locationListener = new LocationListener() {

        @Override
        public void onStatusChanged(String provider, int status, Bundle extras) {
            switch (status) {
                //GPS状态为可见时
                case LocationProvider.AVAILABLE:
                   // Log.i("Gps", "当前GPS状态为可见状态");
                    break;
                //GPS状态为服务区外时
                case LocationProvider.OUT_OF_SERVICE:
                    Log.i("Gps", "当前GPS状态为服务区外状态");
                    break;
                //GPS状态为暂停服务时
                case LocationProvider.TEMPORARILY_UNAVAILABLE:
                    Log.i("Gps", "当前GPS状态为暂停服务状态");
                    break;
            }
        }

        @Override
        public void onProviderEnabled(String arg0) {
            Log.i("Gps", "onProviderEnabled");
        }

        @Override
        public void onProviderDisabled(String arg0) {
            Log.i("Gps", "onProviderDisabled");
        }

        @Override
        public void onLocationChanged(Location l) {
            if (location != null) {
                if (location == null) {
                    location = new Location(l);
                } else {
                    location.set(l);
                }
            }
        }
    };
}
