param(
    [Parameter(Mandatory = $true, Position = 0, 
        HelpMessage = "Brightness value between 1.0 and 9.0 or '+'/'minus' to adjust brightness")]
    [string]$brightnessOrAdjustment
)

# Define registry key to store brightness
$regKeyPath = "HKCU:\Software\MyScript"
$regValueName = "Brightness"

# Function to get current brightness (simulating for this example)
function GetCurrentBrightness {
    # Try reading the brightness value from the registry if it exists
    try {
        if (Test-Path $regKeyPath) {
            $storedBrightness = Get-ItemProperty -Path $regKeyPath -Name $regValueName
            Write-Host "Current brightness from registry: $($storedBrightness.Brightness)"
            return [double]$storedBrightness.Brightness
        } else {
            Write-Host "No stored brightness in the registry. Using default value."
            return 3.0  # Default to 3.0 if no value found
        }
    } catch {
        Write-Host "Error reading from registry. Using default brightness."
        return 3.0  # Return default value if registry access fails
    }
}

# Function to adjust brightness by 0.5 depending on "+" or "-"
function AdjustBrightness {
    param (
        [double]$currentBrightness,
        [string]$adjustment
    )

    # Adjust brightness by 0.5
    if ($adjustment -eq "+") {
        $newBrightness = [math]::Min($currentBrightness + 1, 9.0)  # Prevent exceeding upper bound
    }
    elseif ($adjustment -eq "minus") {
        $newBrightness = [math]::Max($currentBrightness - 1, 1.5)  # Prevent going below lower bound
    }
    return $newBrightness
}

# Error Handling
try {
    # If the input is "+" or "-", adjust brightness by 0.1
    if ($brightnessOrAdjustment -eq "+" -or $brightnessOrAdjustment -eq "minus") {
        # Get the current brightness value, then adjust
        $currentBrightness = GetCurrentBrightness
        $adjustedBrightness = AdjustBrightness $currentBrightness $brightnessOrAdjustment
        $brightness = $adjustedBrightness
    } 
    # If a numeric value is passed, directly use it
    elseif ([double]$brightnessOrAdjustment -and $brightnessOrAdjustment -ge 1 -and $brightnessOrAdjustment -le 9.0) {
        Write-Host "Setting brightness to $brightnessOrAdjustment"
        $brightness = [double]$brightnessOrAdjustment
    }
    else {
        throw "Error: Invalid input. Use a number between 1.0 and 9.0, or '+' or 'minus' to adjust."
    }

# Add C# code to interact with native Windows API for monitor brightness
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class ScreenBrightnessSetter
{
    [DllImport("user32.dll")]
    public static extern IntPtr MonitorFromWindow(IntPtr hwnd, uint dwFlags);
    [DllImport("kernel32", CharSet = CharSet.Unicode)]
    public static extern IntPtr LoadLibrary(string lpFileName);
    [DllImport("kernel32", CharSet = CharSet.Ansi, ExactSpelling = true,
        SetLastError = true)]
    public static extern IntPtr GetProcAddress(IntPtr hModule, int address);

    public delegate void DwmpSDRToHDRBoostPtr(IntPtr monitor,
        double brightness);
}
"@

    # Retrieve the primary monitor handle
    $primaryMonitor = [ScreenBrightnessSetter]::MonitorFromWindow([IntPtr]::Zero, 1)

    # Load DWM API (Desktop Window Manager)
    $hmodule_dwmapi = [ScreenBrightnessSetter]::LoadLibrary("dwmapi.dll")

    if ($hmodule_dwmapi -eq [IntPtr]::Zero) {
        throw "Error: Unable to load dwmapi.dll"
    }

    # Fetch the function pointer for setting the brightness
    $procAddress = [ScreenBrightnessSetter]::GetProcAddress($hmodule_dwmapi, 171)
    if ($procAddress -eq [IntPtr]::Zero) {
        throw "Error: Unable to find the required function in dwmapi.dll"
    }

    # Prepare the delegate to invoke the brightness setting method
    $changeBrightness = (
        [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer(
            $procAddress, [ScreenBrightnessSetter+DwmpSDRToHDRBoostPtr])
    )

    # Set the brightness to the final value
    $changeBrightness.Invoke($primaryMonitor, $brightness)

    # Store the new brightness in the registry
    if (-not (Test-Path $regKeyPath)) {
        New-Item -Path $regKeyPath -Force | Out-Null
    }
    Set-ItemProperty -Path $regKeyPath -Name $regValueName -Value $brightness

    Write-Host "Brightness successfully set to $brightness"

} catch {
    Write-Error "Error: $_"
}
