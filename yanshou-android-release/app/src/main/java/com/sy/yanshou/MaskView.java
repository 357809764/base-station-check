package com.sy.yanshou;

import android.content.Context;
import android.os.SystemClock;
import android.support.annotation.Nullable;
import android.util.AttributeSet;
import android.view.MotionEvent;
import android.view.View;

public class MaskView extends View {
    private final static int MAX_COUNT = 5;
    private final static int ONE_INTERVAL_TIME = 300;
    private long preClickTime = 1;
    private int clickCount;
    private OnRepeatClickListener listener;

    public MaskView(Context context) {
        super(context);
    }

    public MaskView(Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
    }

    public MaskView(Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
    }

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        if (event.getAction() == MotionEvent.ACTION_DOWN) {
            // 重复点击5次，并且每次点击间隔在300ms内，则打开设置界面
            long curClickTime = SystemClock.uptimeMillis();
            if (curClickTime - preClickTime < ONE_INTERVAL_TIME) {
                clickCount += 1;
                if (clickCount >= MAX_COUNT) {
                    if (listener != null) {
                        listener.onRepeatClick();
                    }
                }
            } else {
                clickCount = 1;
            }
            preClickTime = SystemClock.uptimeMillis();
        }
        return super.onTouchEvent(event);
    }

    public void setRepeatClickListener(OnRepeatClickListener listener) {
        this.listener = listener;
    }

    public interface OnRepeatClickListener {
        void onRepeatClick();
    }
}
