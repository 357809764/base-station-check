package com.sangfor.user;

import android.app.AlertDialog;
import android.content.Context;
import android.view.View;

/**
 * Created by henugao on 17-8-4.
 */

public class SangforAuthDialog extends AlertDialog.Builder {

    public SangforAuthDialog(Context context) {
        super(context);
    }

    public void createDialog(CharSequence title, View view) {
        setTitle(title);
        setView(view);
    }

}
