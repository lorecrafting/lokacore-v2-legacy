package expo.modules.lokamemory

import android.app.ActivityManager
import android.content.Context
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition

// OS-visible physical memory in bytes; below the installed RAM size.
class LokaMemoryModule : Module() {
  override fun definition() = ModuleDefinition {
    Name("LokaMemory")
    Function("physicalMemory") {
      val am = appContext.reactContext!!.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
      val info = ActivityManager.MemoryInfo()
      am.getMemoryInfo(info)
      mapOf("api" to "ActivityManager.MemoryInfo.totalMem", "bytes" to info.totalMem.toString())
    }
  }
}
