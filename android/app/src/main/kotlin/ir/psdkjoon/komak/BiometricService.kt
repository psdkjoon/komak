package ir.psdkjoon.komak

import android.app.KeyguardManager
import android.content.Context
import android.hardware.biometrics.BiometricManager
import android.hardware.biometrics.BiometricPrompt
import android.os.Build
import android.os.CancellationSignal

enum class BiometricResult { Success, Failed, Cancelled, Unavailable }

object BiometricService {
    private val cancelCodes = setOf(5, 10, 13)
    private val unavailableCodes = setOf(1, 11, 12, 14)

    fun isAvailable(context: Context): Boolean = when {
        Build.VERSION.SDK_INT >= 30 ->
            context.getSystemService(BiometricManager::class.java)?.canAuthenticate(
                BiometricManager.Authenticators.BIOMETRIC_STRONG or
                    BiometricManager.Authenticators.DEVICE_CREDENTIAL,
            ) == BiometricManager.BIOMETRIC_SUCCESS
        Build.VERSION.SDK_INT >= 28 ->
            context.getSystemService(KeyguardManager::class.java)?.isDeviceSecure == true
        else -> false
    }

    @Suppress("DEPRECATION")
    fun authenticate(context: Context, title: String, callback: (BiometricResult) -> Unit) {
        if (Build.VERSION.SDK_INT < 28) {
            callback(BiometricResult.Unavailable)
            return
        }
        val host: Context = EngineHolder.activity ?: context
        var finished = false
        val finish = { result: BiometricResult ->
            if (!finished) {
                finished = true
                callback(result)
            }
        }
        val builder = BiometricPrompt.Builder(host).setTitle(title)
        when {
            Build.VERSION.SDK_INT >= 30 -> builder.setAllowedAuthenticators(
                BiometricManager.Authenticators.BIOMETRIC_STRONG or
                    BiometricManager.Authenticators.DEVICE_CREDENTIAL,
            )
            Build.VERSION.SDK_INT >= 29 -> builder.setDeviceCredentialAllowed(true)
            else -> builder.setNegativeButton(
                host.getString(R.string.biometric_cancel),
                host.mainExecutor,
            ) { _, _ -> finish(BiometricResult.Cancelled) }
        }
        val authenticationCallback = object : BiometricPrompt.AuthenticationCallback() {
            override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult?) {
                finish(BiometricResult.Success)
            }

            override fun onAuthenticationError(errorCode: Int, errString: CharSequence?) {
                finish(
                    when (errorCode) {
                        in cancelCodes -> BiometricResult.Cancelled
                        in unavailableCodes -> BiometricResult.Unavailable
                        else -> BiometricResult.Failed
                    },
                )
            }
        }
        try {
            builder.build().authenticate(CancellationSignal(), host.mainExecutor, authenticationCallback)
        } catch (_: Exception) {
            finish(BiometricResult.Unavailable)
        }
    }
}
