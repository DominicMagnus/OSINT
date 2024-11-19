# Check if any keys exist in the registry path
$registryPath = "HKCU:\Software\OpenVPN-GUI\configs"
if (!(Test-Path $registryPath)) {
    Write-Host "No registry keys found at $registryPath."
    return
}

# Retrieve the keys
$keys = Get-ChildItem $registryPath
if (-not $keys) {
    Write-Host "No values found in the registry path $registryPath."
    return
}

# Process each key
$items = $keys | ForEach-Object { Get-ItemProperty $_.PsPath }
foreach ($item in $items) {
    try {
        # Display the item name
        Write-Host "Configuration Name: $($item.'PSChildName')"

        # Retrieve and decode the username
        $username = $item.'username'
        if ($username) {
            Write-Host "Username: " ([System.Text.Encoding]::Unicode.GetString($username))
        } else {
            Write-Host "Username: Not found"
        }

        # Retrieve and decrypt the auth-data
        $encryptedBytes = $item.'auth-data'
        $entropy = $item.'entropy'

        if ($encryptedBytes -and $entropy) {
            $entropy = $entropy[0..(($entropy.Length) - 2)]
            $decryptedBytes = [System.Security.Cryptography.ProtectedData]::Unprotect(
                $encryptedBytes,
                $entropy,
                [System.Security.Cryptography.DataProtectionScope]::CurrentUser
            )

            Write-Host "Password: " ([System.Text.Encoding]::Unicode.GetString($decryptedBytes))
        } else {
            Write-Host "Password: Not found"
        }

        Write-Host "-------------------------------------------"
    } catch {
        Write-Host "An error occurred while processing item $($item.'PSChildName'): $_"
    }
}
