package expo.modules.lokamemory

import android.app.ActivityManager
import android.content.Context
import android.util.Base64
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import java.io.File

// A2 local module: OS-visible physical memory, evidence files the M1 pulls, and real process death.
class LokaMemoryModule : Module() {
  override fun definition() = ModuleDefinition {
    Name("LokaMemory")
    Function("physicalMemory") {
      val am = appContext.reactContext!!.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
      val info = ActivityManager.MemoryInfo()
      am.getMemoryInfo(info)
      mapOf("api" to "ActivityManager.MemoryInfo.totalMem", "bytes" to info.totalMem.toString())
    }
    // App-specific external storage (/sdcard/Android/data/<package>/files): `adb pull` reads it
    // without run-as, which a non-debuggable release build does not allow.
    Function("writeFile") { name: String, base64: String ->
      val dir = appContext.reactContext!!.getExternalFilesDir(null)!!
      val tmp = File(dir, "$name.tmp")
      tmp.writeBytes(Base64.decode(base64, Base64.NO_WRAP))
      check(tmp.renameTo(File(dir, name))) { "rename failed: $name" }
    }
    // SIGKILL to this process: no handlers run, as when the OS kills the app.
    Function("kill") { android.os.Process.killProcess(android.os.Process.myPid()) }
  }
}
