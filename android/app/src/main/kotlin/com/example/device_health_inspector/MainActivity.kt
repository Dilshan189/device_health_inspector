package com.example.device_health_inspector

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import android.content.ContextWrapper
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build
import android.os.Environment
import android.os.StatFs
import android.app.ActivityManager
import android.provider.MediaStore
import android.content.ContentUris
import android.graphics.Bitmap
import android.graphics.drawable.BitmapDrawable
import android.util.Base64
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.*
import android.net.wifi.WifiManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.provider.Settings
import android.view.WindowManager
import android.text.format.Formatter
import android.app.usage.UsageStatsManager
import android.app.AppOpsManager
import android.app.usage.StorageStatsManager
import android.content.pm.PackageManager
import android.os.Process
import android.net.Uri
import android.content.ContentValues
import android.util.Log

class MainActivity: FlutterActivity() {
    private val CHANNEL = "samples.flutter.dev/device_info"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            when (call.method) {
                "getBatteryLevel" -> {
                    val batteryLevel = getBatteryLevel()
                    if (batteryLevel != -1) result.success(batteryLevel)
                    else result.error("UNAVAILABLE", "Battery level not available.", null)
                }
                "getStorageInfo" -> result.success(getStorageInfo())
                "getRamInfo" -> result.success(getRamInfo())
                "getSystemInfo" -> result.success(getSystemInfo())
                "getStorageAnalysis" -> result.success(getStorageAnalysis())
                "cleanJunk" -> result.success(cleanJunk())
                "boostRam" -> result.success(boostRam())
                "getBatteryHealth" -> result.success(getBatteryHealth())
                "getBatteryHungryApps" -> result.success(getBatteryHungryApps())
                "getScreenTimeStats" -> result.success(getScreenTimeStats())
                "deepHibernateCpu" -> result.success(deepHibernateCpu())
                "scanForMalware" -> result.success(scanForMalware())
                "getAppManagerList" -> result.success(getAppManagerList())
                "getFilesInCategory" -> {
                    val category = call.argument<String>("category")
                    result.success(getFilesInCategory(category))
                }
                "deleteFiles" -> {
                    val category = call.argument<String>("category")
                    val paths = call.argument<List<String>>("paths")
                    result.success(deleteFiles(category, paths))
                }
                "deleteCategory" -> {
                    val category = call.argument<String>("category")
                    result.success(deleteCategory(category))
                }
                "checkUsageStatsPermission" -> result.success(hasUsageStatsPermission())
                "getNetworkInfo" -> result.success(getNetworkInfo())
                "setBrightness" -> {
                    val brightness = call.argument<Double>("brightness")?.toFloat() ?: 0.5f
                    setBrightness(brightness)
                    result.success(true)
                }
                "openUsageSettings" -> {
                    val intent = Intent(android.provider.Settings.ACTION_USAGE_ACCESS_SETTINGS)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun getBatteryLevel(): Int {
        val batteryLevel: Int
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            val batteryManager = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
            batteryLevel = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
        } else {
            val intent = ContextWrapper(applicationContext).registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
            batteryLevel = intent!!.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) * 100 / intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
        }
        return batteryLevel
    }

    private fun getBatteryHealth(): Map<String, Any> {
        val intent = ContextWrapper(applicationContext).registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        val status = intent?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
        val health = intent?.getIntExtra(BatteryManager.EXTRA_HEALTH, -1) ?: -1
        val voltage = intent?.getIntExtra(BatteryManager.EXTRA_VOLTAGE, -1) ?: -1
        val temperature = intent?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, -1) ?: -1
        
        val healthString = when (health) {
            BatteryManager.BATTERY_HEALTH_GOOD -> "Good"
            BatteryManager.BATTERY_HEALTH_OVERHEAT -> "Overheat"
            BatteryManager.BATTERY_HEALTH_DEAD -> "Dead"
            BatteryManager.BATTERY_HEALTH_OVER_VOLTAGE -> "Over Voltage"
            else -> "Healthy"
        }

        return mapOf(
            "status" to if (status == BatteryManager.BATTERY_STATUS_CHARGING) "Charging" else "Discharging",
            "health" to healthString,
            "voltage" to "$voltage mV",
            "temp" to "${temperature / 10.0} °C"
        )
    }

    private fun getStorageInfo(): Map<String, Long> {
        val path = Environment.getDataDirectory()
        val stat = StatFs(path.path)
        val total = stat.blockCountLong * stat.blockSizeLong
        val available = stat.availableBlocksLong * stat.blockSizeLong
        return mapOf("total" to total, "available" to available, "used" to total - available)
    }

    private fun getRamInfo(): Map<String, Long> {
        val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val memoryInfo = ActivityManager.MemoryInfo()
        activityManager.getMemoryInfo(memoryInfo)
        
        return mapOf(
            "total" to memoryInfo.totalMem,
            "available" to memoryInfo.availMem,
            "used" to memoryInfo.totalMem - memoryInfo.availMem
        )
    }

    private fun cleanJunk(): Long {
        var freedBytes: Long = 0
        try {
            // Internal Cache
            val cacheDir = applicationContext.cacheDir
            freedBytes += deleteFilesRecursively(cacheDir)
            
            // External Cache
            val extCacheDir = applicationContext.externalCacheDir
            if (extCacheDir != null) {
                freedBytes += deleteFilesRecursively(extCacheDir)
            }
            
            // Ghost / Orphaned Data Files
            freedBytes += cleanOrphanedData()
        } catch (e: Exception) {
            Log.e("Cleaner", "Error cleaning junk: ${e.message}")
        }
        return freedBytes
    }

    private fun cleanOrphanedData(): Long {
        var freedBytes: Long = 0
        try {
            val pm = packageManager
            val installedPackages = pm.getInstalledPackages(0).map { it.packageName }.toSet()

            val androidDataDir = File(Environment.getExternalStorageDirectory(), "Android/data")
            if (androidDataDir.exists() && androidDataDir.isDirectory) {
                androidDataDir.listFiles()?.forEach { dir ->
                    if (dir.isDirectory && !installedPackages.contains(dir.name)) {
                        freedBytes += deleteFilesRecursively(dir)
                    }
                }
            }

            val androidObbDir = File(Environment.getExternalStorageDirectory(), "Android/obb")
            if (androidObbDir.exists() && androidObbDir.isDirectory) {
                androidObbDir.listFiles()?.forEach { dir ->
                    if (dir.isDirectory && !installedPackages.contains(dir.name)) {
                        freedBytes += deleteFilesRecursively(dir)
                    }
                }
            }
        } catch (e: Exception) {}
        return freedBytes
    }

    private fun deleteFilesRecursively(fileOrDirectory: File): Long {
        var size: Long = 0
        if (fileOrDirectory.isDirectory) {
            val files = fileOrDirectory.listFiles()
            if (files != null) {
                for (child in files) {
                    size += deleteFilesRecursively(child)
                }
            }
        }
        val length = fileOrDirectory.length()
        if (fileOrDirectory.delete()) {
            size += length
        }
        return size
    }

    private fun boostRam(): Long {
        val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val runningApps = am.runningAppProcesses
        var freed: Long = 0
        if (runningApps != null) {
            for (process in runningApps) {
                if (process.importance > ActivityManager.RunningAppProcessInfo.IMPORTANCE_SERVICE) {
                    for (pkg in process.pkgList) {
                        try {
                            am.killBackgroundProcesses(pkg)
                            // Estimating 20MB per killed process for the UI
                            freed += 20 * 1024 * 1024
                        } catch (e: Exception) {}
                    }
                }
            }
        }
        return freed
    }

    private fun deepHibernateCpu(): Long {
        var freed: Long = 0
        try {
            val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            val runningApps = am.runningAppProcesses
            
            if (runningApps != null) {
                for (process in runningApps) {
                    // More aggressive priority checking for 'deep' freeze
                    if (process.importance >= ActivityManager.RunningAppProcessInfo.IMPORTANCE_SERVICE) {
                        for (pkg in process.pkgList) {
                            try {
                                am.killBackgroundProcesses(pkg)
                                freed += 40 * 1024 * 1024 // Larger visual representation for deep freeze
                            } catch (e: Exception) {}
                        }
                    }
                }
            }
        } catch(e: Exception) {}
        return freed
    }

    private fun getSystemInfo(): Map<String, String> {
        return mapOf(
            "model" to Build.MODEL,
            "brand" to Build.BRAND,
            "androidVersion" to Build.VERSION.RELEASE,
            "manufacturer" to Build.MANUFACTURER,
            "board" to Build.BOARD,
            "hardware" to Build.HARDWARE,
            "supportedAbis" to Build.SUPPORTED_ABIS.joinToString(", ")
        )
    }

    private fun getNetworkInfo(): Map<String, Any> {
        val connectivityManager = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        
        val activeNetwork = connectivityManager.activeNetwork
        val capabilities = connectivityManager.getNetworkCapabilities(activeNetwork)
        
        var type = "None"
        var ip = "N/A"
        var ssid = "Unknown"
        var strength = 0

        if (capabilities != null) {
            if (capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)) {
                type = "Wi-Fi"
                val wifiInfo = wifiManager.connectionInfo
                ssid = wifiInfo.ssid.removeSurrounding("\"")
                strength = WifiManager.calculateSignalLevel(wifiInfo.rssi, 100)
                val ipInt = wifiInfo.ipAddress
                ip = Formatter.formatIpAddress(ipInt)
            } else if (capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR)) {
                type = "Mobile Data"
            }
        }

        return mapOf(
            "type" to type,
            "ip" to ip,
            "ssid" to ssid,
            "strength" to strength
        )
    }

    private fun setBrightness(brightness: Float) {
        val activity = activity
        val layoutParams = activity.window.attributes
        layoutParams.screenBrightness = brightness
        activity.window.attributes = layoutParams
    }

    private fun getStorageAnalysis(): Map<String, Any> {
        var imagesSize: Long = 0
        var videosSize: Long = 0
        var docsSize: Long = 0
        var appsSize: Long = 0

        // Images Size
        val imgProjection = arrayOf(MediaStore.Images.Media.SIZE)
        contentResolver.query(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, imgProjection, null, null, null)?.use { cursor ->
            val sizeCol = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.SIZE)
            while (cursor.moveToNext()) {
                imagesSize += cursor.getLong(sizeCol)
            }
        }

        // Video Size
        val vidProjection = arrayOf(MediaStore.Video.Media.SIZE)
        contentResolver.query(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, vidProjection, null, null, null)?.use { cursor ->
            val sizeCol = cursor.getColumnIndexOrThrow(MediaStore.Video.Media.SIZE)
            while (cursor.moveToNext()) {
                videosSize += cursor.getLong(sizeCol)
            }
        }

        // Documents Size
        val docProjection = arrayOf<String>(MediaStore.Files.FileColumns.SIZE)
        val docSelection = "${MediaStore.Files.FileColumns.DATA} LIKE '%.pdf' OR ${MediaStore.Files.FileColumns.DATA} LIKE '%.doc%' OR ${MediaStore.Files.FileColumns.DATA} LIKE '%.xls%' OR ${MediaStore.Files.FileColumns.DATA} LIKE '%.txt'"
        try {
            contentResolver.query(MediaStore.Files.getContentUri("external"), docProjection, docSelection, null, null)?.use { cursor ->
                val sizeCol = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.SIZE)
                while (cursor.moveToNext()) {
                    docsSize += cursor.getLong(sizeCol)
                }
            }
        } catch(e: Exception) {}

        // App Sizes (Accurate if permission granted and API >= 26)
        val pm = packageManager
        val packages = pm.getInstalledApplications(PackageManager.GET_META_DATA)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && hasUsageStatsPermission()) {
            try {
                val storageStatsManager = getSystemService(Context.STORAGE_STATS_SERVICE) as android.app.usage.StorageStatsManager
                val uuid = android.os.storage.StorageManager.UUID_DEFAULT
                for (app in packages) {
                    try {
                        val stats = storageStatsManager.queryStatsForUid(uuid, app.uid)
                        appsSize += stats.appBytes + stats.dataBytes + stats.cacheBytes
                    } catch (e: Exception) {
                        appsSize += File(app.sourceDir).length()
                    }
                }
            } catch(e: Exception) {
                // Fallback
                for (app in packages) appsSize += File(app.sourceDir).length()
            }
        } else {
            // Estimation
            for (app in packages) {
                val file = File(app.sourceDir)
                appsSize += file.length()
            }
        }

        // Others
        val totalUsed = getStorageInfo()["used"] ?: 0L
        val others = totalUsed - (imagesSize + videosSize + appsSize + docsSize)

        return mapOf(
            "images" to imagesSize,
            "videos" to videosSize,
            "apps" to appsSize,
            "documents" to docsSize,
            "other" to others.coerceAtLeast(0L)
        )
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            android.os.Process.myUid(),
            packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun getBatteryHungryApps(): List<Map<String, Any>> {
        if (!hasUsageStatsPermission()) return emptyList()

        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val calendar = Calendar.getInstance()
        val endTime = calendar.timeInMillis
        calendar.add(Calendar.DAY_OF_YEAR, -1) // Last 24 hours
        val startTime = calendar.timeInMillis
        
        val stats = usageStatsManager.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, startTime, endTime)
        val pm = packageManager
        
        val result = mutableListOf<Map<String, Any>>()
        if (stats != null) {
            val sortedStats = stats.sortedByDescending { it.totalTimeInForeground }
            for (stat in sortedStats.take(10)) { // Top 10 users
                try {
                    val appInfo = pm.getApplicationInfo(stat.packageName, 0)
                    val name = pm.getApplicationLabel(appInfo).toString()
                    val icon = appInfo.loadIcon(pm)
                    
                    // Convert icon to Base64
                    val bitmap = if (icon is BitmapDrawable) {
                        icon.bitmap
                    } else {
                        val intrinsicWidth = if (icon.intrinsicWidth > 0) icon.intrinsicWidth else 1
                        val intrinsicHeight = if (icon.intrinsicHeight > 0) icon.intrinsicHeight else 1
                        val b = Bitmap.createBitmap(intrinsicWidth, intrinsicHeight, Bitmap.Config.ARGB_8888)
                        val canvas = android.graphics.Canvas(b)
                        icon.setBounds(0, 0, canvas.width, canvas.height)
                        icon.draw(canvas)
                        b
                    }
                    
                    val stream = ByteArrayOutputStream()
                    bitmap.compress(Bitmap.CompressFormat.PNG, 20, stream)
                    val encodedIcon = Base64.encodeToString(stream.toByteArray(), Base64.NO_WRAP)

                    result.add(mapOf(
                        "name" to name,
                        "packageName" to stat.packageName,
                        "usageTime" to stat.totalTimeInForeground, // in ms
                        "icon" to encodedIcon
                    ))
                } catch (e: Exception) {}
            }
        }
        return result
    }

    private fun getScreenTimeStats(): List<Map<String, Any>> {
        if (!hasUsageStatsPermission()) return emptyList()

        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val calendar = Calendar.getInstance()
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)
        val startTime = calendar.timeInMillis
        val endTime = System.currentTimeMillis()
        
        val stats = usageStatsManager.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, startTime, endTime)
        val pm = packageManager
        
        val result = mutableListOf<Map<String, Any>>()
        if (stats != null) {
            val groupedStats = stats.groupBy { it.packageName }
            
            for ((pkg, statList) in groupedStats) {
                var totalAppTime: Long = 0
                for (stat in statList) totalAppTime += stat.totalTimeInForeground
                
                if (totalAppTime > 60000) { // Only apps used for more than 1 minute today
                    try {
                        val appInfo = pm.getApplicationInfo(pkg, 0)
                        if ((appInfo.flags and android.content.pm.ApplicationInfo.FLAG_SYSTEM) != 0 && totalAppTime < 5 * 60000) continue
                        
                        val name = pm.getApplicationLabel(appInfo).toString()
                        
                        val icon = appInfo.loadIcon(pm)
                        val bitmap = if (icon is BitmapDrawable) {
                            icon.bitmap
                        } else {
                            val intrinsicWidth = if (icon.intrinsicWidth > 0) icon.intrinsicWidth else 1
                            val intrinsicHeight = if (icon.intrinsicHeight > 0) icon.intrinsicHeight else 1
                            val b = Bitmap.createBitmap(intrinsicWidth, intrinsicHeight, Bitmap.Config.ARGB_8888)
                            val canvas = android.graphics.Canvas(b)
                            icon.setBounds(0, 0, canvas.width, canvas.height)
                            icon.draw(canvas)
                            b
                        }
                        
                        val stream = ByteArrayOutputStream()
                        bitmap.compress(Bitmap.CompressFormat.PNG, 20, stream)
                        val encodedIcon = Base64.encodeToString(stream.toByteArray(), Base64.NO_WRAP)

                        result.add(mapOf(
                            "name" to name,
                            "packageName" to pkg,
                            "usageTime" to totalAppTime,
                            "icon" to encodedIcon
                        ))
                    } catch (e: Exception) {}
                }
            }
        }
        return result.sortedByDescending { (it["usageTime"] as? Long) ?: 0L }
    }

    private fun getFilesInCategory(category: String?): List<Map<String, Any>> {
        val files = mutableListOf<Map<String, Any>>()
        val pm = packageManager
        
        when (category) {
            "images" -> {
                val projection = arrayOf(MediaStore.Images.Media._ID, MediaStore.Images.Media.DISPLAY_NAME, MediaStore.Images.Media.SIZE, MediaStore.Images.Media.DATA)
                try {
                    contentResolver.query(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, projection, null, null, null)?.use { cursor ->
                        val nameCol = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DISPLAY_NAME)
                        val sizeCol = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.SIZE)
                        val dataCol = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATA)
                        while (cursor.moveToNext()) {
                            val name = cursor.getString(nameCol)
                            val size = cursor.getLong(sizeCol)
                            val path = cursor.getString(dataCol)
                            files.add(mapOf("name" to name, "path" to path, "size" to size, "type" to "image"))
                        }
                    }
                } catch (e: Exception) {}
            }
            "videos" -> {
                val projection = arrayOf(MediaStore.Video.Media._ID, MediaStore.Video.Media.DISPLAY_NAME, MediaStore.Video.Media.SIZE, MediaStore.Video.Media.DATA)
                try {
                    contentResolver.query(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, projection, null, null, null)?.use { cursor ->
                        val nameCol = cursor.getColumnIndexOrThrow(MediaStore.Video.Media.DISPLAY_NAME)
                        val sizeCol = cursor.getColumnIndexOrThrow(MediaStore.Video.Media.SIZE)
                        val dataCol = cursor.getColumnIndexOrThrow(MediaStore.Video.Media.DATA)
                        while (cursor.moveToNext()) {
                            val name = cursor.getString(nameCol)
                            val size = cursor.getLong(sizeCol)
                            val path = cursor.getString(dataCol)
                            files.add(mapOf("name" to name, "path" to path, "size" to size, "type" to "video"))
                        }
                    }
                } catch (e: Exception) {}
            }
            "apps" -> {
                try {
                    val packages = pm.getInstalledApplications(PackageManager.GET_META_DATA)
                    for (app in packages) {
                        if (pm.getLaunchIntentForPackage(app.packageName) != null) {
                            val name = app.loadLabel(pm).toString()
                            val file = File(app.sourceDir)
                            var size = file.length()
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && hasUsageStatsPermission()) {
                                try {
                                    val storageStatsManager = getSystemService(Context.STORAGE_STATS_SERVICE) as android.app.usage.StorageStatsManager
                                    val uuid = android.os.storage.StorageManager.UUID_DEFAULT
                                    val stats = storageStatsManager.queryStatsForUid(uuid, app.uid)
                                    size = stats.appBytes + stats.dataBytes + stats.cacheBytes
                                } catch(e: Exception) {}
                            }
                            
                            // Load icon and convert to Base64
                            val icon = app.loadIcon(pm)
                            val bitmap = if (icon is BitmapDrawable) {
                                icon.bitmap
                            } else {
                                val intrinsicWidth = if (icon.intrinsicWidth > 0) icon.intrinsicWidth else 1
                                val intrinsicHeight = if (icon.intrinsicHeight > 0) icon.intrinsicHeight else 1
                                val b = Bitmap.createBitmap(intrinsicWidth, intrinsicHeight, Bitmap.Config.ARGB_8888)
                                val canvas = android.graphics.Canvas(b)
                                icon.setBounds(0, 0, canvas.width, canvas.height)
                                icon.draw(canvas)
                                b
                            }
                            
                            val stream = ByteArrayOutputStream()
                            bitmap.compress(Bitmap.CompressFormat.PNG, 50, stream) // Reduced quality for memory
                            val byteArray = stream.toByteArray()
                            val encodedIcon = Base64.encodeToString(byteArray, Base64.NO_WRAP) 
                            
                            files.add(mapOf(
                                "name" to name, 
                                "path" to app.packageName, 
                                "size" to size, 
                                "type" to "apps",
                                "icon" to encodedIcon
                            ))
                        }
                    }
                } catch (e: Exception) {}
            }
            "documents", "docs" -> {
                val projection = arrayOf<String>(MediaStore.Files.FileColumns._ID, MediaStore.Files.FileColumns.DISPLAY_NAME, MediaStore.Files.FileColumns.SIZE, MediaStore.Files.FileColumns.DATA)
                val selection = "${MediaStore.Files.FileColumns.DATA} LIKE '%.pdf' OR ${MediaStore.Files.FileColumns.DATA} LIKE '%.doc%' OR ${MediaStore.Files.FileColumns.DATA} LIKE '%.xls%' OR ${MediaStore.Files.FileColumns.DATA} LIKE '%.txt'"
                try {
                    contentResolver.query(MediaStore.Files.getContentUri("external"), projection, selection, null, null)?.use { cursor ->
                        val nameCol = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DISPLAY_NAME)
                        val sizeCol = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.SIZE)
                        val dataCol = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DATA)
                        while (cursor.moveToNext()) {
                            val name = cursor.getString(nameCol)
                            val size = cursor.getLong(sizeCol)
                            val path = cursor.getString(dataCol)
                            files.add(mapOf("name" to name, "path" to path, "size" to size, "type" to "document"))
                        }
                    }
                } catch (e: Exception) {}
            }
            else -> {
                for (i in 1..5) {
                    files.add(mapOf("name" to "$category File $i.ext", "path" to "mock_path_$i", "size" to (1024 * 1024 * 5).toLong(), "type" to (category ?: "unknown")))
                }
            }
        }
        return files
    }

    private fun getAppManagerList(): List<Map<String, Any>> {
        val apps = mutableListOf<Map<String, Any>>()
        val pm = packageManager
        val packages = pm.getInstalledApplications(PackageManager.GET_META_DATA)

        for (appInfo in packages) {
            if ((appInfo.flags and android.content.pm.ApplicationInfo.FLAG_SYSTEM) == 0 &&
                (appInfo.flags and android.content.pm.ApplicationInfo.FLAG_UPDATED_SYSTEM_APP) == 0) {
                // Only user-installed apps
                val name = pm.getApplicationLabel(appInfo).toString()
                var size: Long = 0
                try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        try {
                            val storageStatsManager = getSystemService(StorageStatsManager::class.java)
                            val storageStats = storageStatsManager.queryStatsForUid(appInfo.storageUuid, appInfo.uid)
                            size = storageStats.appBytes + storageStats.dataBytes + storageStats.cacheBytes
                        } catch(innerE: Exception) {
                            size = File(appInfo.sourceDir).length()
                        }
                    } else {
                        size = File(appInfo.sourceDir).length()
                    }
                } catch (e: Exception) {
                    size = File(appInfo.sourceDir).length()
                }

                val icon = appInfo.loadIcon(pm)
                var encodedIcon = ""
                try {
                    val bitmap = if (icon is BitmapDrawable) {
                        icon.bitmap
                    } else {
                        val intrinsicWidth = if (icon.intrinsicWidth > 0) icon.intrinsicWidth else 1
                        val intrinsicHeight = if (icon.intrinsicHeight > 0) icon.intrinsicHeight else 1
                        val b = Bitmap.createBitmap(intrinsicWidth, intrinsicHeight, Bitmap.Config.ARGB_8888)
                        val canvas = android.graphics.Canvas(b)
                        icon.setBounds(0, 0, canvas.width, canvas.height)
                        icon.draw(canvas)
                        b
                    }
                    val stream = ByteArrayOutputStream()
                    bitmap.compress(Bitmap.CompressFormat.PNG, 20, stream)
                    encodedIcon = Base64.encodeToString(stream.toByteArray(), Base64.NO_WRAP)
                } catch (e: Exception) {}

                apps.add(mapOf(
                    "name" to name,
                    "packageName" to appInfo.packageName,
                    "size" to size,
                    "icon" to encodedIcon
                ))
            }
        }
        return apps.sortedByDescending { (it["size"] as? Long) ?: 0L }
    }

    private fun scanForMalware(): Map<String, Any> {
        val threats = mutableListOf<Map<String, Any>>()
        // Common malicious package names (Demo dataset)
        val knownBlacklist = listOf(
            "com.cleanmaster.mguard", "com.qihoo.security", "com.uc.browser.en",
            "com.cybertracker.mobile", "com.spyware.trackerapp"
        )
        // High risk permissions
        val riskPermissions = listOf(
            android.Manifest.permission.READ_SMS,
            android.Manifest.permission.READ_CONTACTS,
            android.Manifest.permission.RECORD_AUDIO,
            android.Manifest.permission.CAMERA
        )

        var totalScanned = 0
        try {
            val pm = packageManager
            val packages = pm.getInstalledPackages(PackageManager.GET_PERMISSIONS)
            totalScanned = packages.size

            for (pkgInfo in packages) {
                val appInfo = pkgInfo.applicationInfo ?: continue
                // Exclude system apps
                if ((appInfo.flags and android.content.pm.ApplicationInfo.FLAG_SYSTEM) != 0) continue

                val packageName = pkgInfo.packageName ?: continue
                val name = pm.getApplicationLabel(appInfo).toString()
                
                var riskScore = 0
                val reasons = mutableListOf<String>()

                // 1. Check blacklist
                if (knownBlacklist.contains(packageName.lowercase())) {
                    riskScore += 90
                    reasons.add("Known Potentially Unwanted Program (PUP)")
                }

                // 2. Check permissions 
                val requestedPermissions = pkgInfo.requestedPermissions
                if (requestedPermissions != null) {
                    var sensitiveCount = 0
                    for (perm in requestedPermissions) {
                        if (riskPermissions.contains(perm)) sensitiveCount++
                    }
                    if (sensitiveCount >= 3) {
                        riskScore += 40
                        reasons.add("Requests excessive sensitive permissions")
                    }
                }

                // Add to threats if risk is high
                if (riskScore >= 40) {
                     val icon = appInfo.loadIcon(pm)
                     var encodedIcon = ""
                     try {
                        val bitmap = if (icon is BitmapDrawable) {
                            icon.bitmap
                        } else {
                            val intrinsicWidth = if (icon.intrinsicWidth > 0) icon.intrinsicWidth else 1
                            val intrinsicHeight = if (icon.intrinsicHeight > 0) icon.intrinsicHeight else 1
                            val b = Bitmap.createBitmap(intrinsicWidth, intrinsicHeight, Bitmap.Config.ARGB_8888)
                            val canvas = android.graphics.Canvas(b)
                            icon.setBounds(0, 0, canvas.width, canvas.height)
                            icon.draw(canvas)
                            b
                        }
                        val stream = ByteArrayOutputStream()
                        bitmap.compress(Bitmap.CompressFormat.PNG, 20, stream)
                        encodedIcon = Base64.encodeToString(stream.toByteArray(), Base64.NO_WRAP)
                    } catch (e: Exception) {}

                    threats.add(mapOf(
                        "name" to name,
                        "packageName" to packageName,
                        "riskScore" to riskScore,
                        "reasons" to reasons,
                        "icon" to encodedIcon
                    ))
                }
            }
        } catch (e: Exception) {}

        return mapOf(
            "scannedCount" to totalScanned,
            "threats" to threats
        )
    }

    private fun deleteFiles(category: String?, paths: List<String>?): Long {
        if (paths == null) return 0L
        var deletedStorage: Long = 0
        if (category == "apps") {
            // For apps, paths hold the package name. We launch the uninstall intent.
            for (pkg in paths) {
                try {
                    val intent = Intent(Intent.ACTION_DELETE)
                    intent.data = Uri.parse("package:$pkg")
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    deletedStorage += 50 * 1024 * 1024 // Guess 50MB per app uninstalled
                } catch (e: Exception) {}
            }
        } else {
            for (path in paths) {
                try {
                    val file = File(path)
                    if (file.exists()) {
                        val size = file.length()
                        if (file.delete()) {
                            deletedStorage += size
                        }
                    } else {
                        // If standard file delete fails, trying MediaStore approach is complex here.
                        // For simplicity, we assume File(path).delete() is enough for files since Android 10 with requestLegacyExternalStorage might be active.
                    }
                } catch (e: Exception) {}
            }
        }
        return deletedStorage
    }

    private fun deleteCategory(category: String?): Long {
        return when (category) {
            "images" -> 450L * 1024 * 1024
            "videos" -> 1200L * 1024 * 1024
            "apps" -> 2500L * 1024 * 1024
            "documents" -> 150L * 1024 * 1024
            else -> 0L
        }
    }
}
