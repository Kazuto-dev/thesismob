// Generated file.
//
// If you wish to remove Flutter's multidex support, delete this entire file.
//
// Modifications to this file should be done in a copy under a different name
// as this file may be regenerated.

package io.flutter.app;

import android.app.Application;
import android.content.Context;
import androidx.annotation.CallSuper;
import androidx.multidex.MultiDex;
import androidx.multidex.MultiDexApplication;

public class FlutterMultiDexApplication extends
 
MultiDexApplication
 
{
  @Override

  
protected
 
void
 
attachBaseContext(Context base)
 
{
    super.attachBaseContext(base);
    MultiDex.install(this); // This line should now work
  }
}