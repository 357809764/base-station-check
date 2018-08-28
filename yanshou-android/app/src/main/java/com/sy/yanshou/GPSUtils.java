package com.sy.yanshou;

import android.Manifest;
import android.content.Context;
import android.content.pm.PackageManager;
import android.location.Location;
import android.location.LocationListener;
import android.location.LocationManager;
import android.os.Bundle;
import android.support.v4.app.ActivityCompat;
import android.util.Log;
import android.widget.Toast;

import java.util.List;

public class GPSUtils {
    //定位都要通过LocationManager这个类实现
    private LocationManager locationManager;
    private String provider;
    private Context context;

    public void init(Context context) {
        this.context = context;
        //获取定位服务
        if (locationManager == null) {
            locationManager = (LocationManager) context.getSystemService(Context.LOCATION_SERVICE);
        }
        //获取当前可用的位置控制器
        List<String> list = locationManager.getProviders(true);

        if (list.contains(LocationManager.GPS_PROVIDER)) {
            //是否为GPS位置控制器
            provider = LocationManager.GPS_PROVIDER;
        } else if (list.contains(LocationManager.NETWORK_PROVIDER)) {
            //是否为网络位置控制器
            provider = LocationManager.NETWORK_PROVIDER;

        } else {
            Toast.makeText(context, "请检查网络或GPS是否打开", Toast.LENGTH_LONG).show();
            return;
        }
        if (ActivityCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED &&
                ActivityCompat.checkSelfPermission(context, Manifest.permission.ACCESS_COARSE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
            Toast.makeText(context, "请检查网络或GPS是否打开", Toast.LENGTH_LONG).show();
            return;
        }
        Location location = locationManager.getLastKnownLocation(provider);
        if (location != null) {
            //获取当前位置，这里只用到了经纬度
            String string = "纬度为：" + location.getLatitude() + ",经度为：" + location.getLongitude();
            Toast.makeText(context, string, Toast.LENGTH_LONG).show();
        } else {

            //绑定定位事件，监听位置是否改变
            //第一个参数为控制器类型第二个参数为监听位置变化的时间间隔（单位：毫秒）
            //第三个参数为位置变化的间隔（单位：米）第四个参数为位置监听器
            locationManager.requestLocationUpdates(provider, 2000, 2, locationListener);
        }
    }


    LocationListener locationListener = new LocationListener() {

        @Override
        public void onStatusChanged(String arg0, int arg1, Bundle arg2) {
            // TODO Auto-generated method stub

        }

        @Override
        public void onProviderEnabled(String arg0) {
            // TODO Auto-generated method stub

        }

        @Override
        public void onProviderDisabled(String arg0) {
            // TODO Auto-generated method stub

        }

        @Override
        public void onLocationChanged(Location location) {
            // TODO Auto-generated method stub
            // 更新当前经纬度
            if (location != null) {
                String string = "纬度为：" + location.getLatitude() + ",经度为：" + location.getLongitude();
                Toast.makeText(context, string, Toast.LENGTH_LONG).show();
            }
        }
    };
}
