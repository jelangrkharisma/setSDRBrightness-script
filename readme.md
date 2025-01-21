This script stores and modify SDR Brightness Slider value to `HKCU:\Software\MyScript` registry.

## Usage

use `+` to increase brightness and `minus` to decrease brightness by 0.5 point.

```powershell
.\SetBrightnessWithAdjustment.ps1 +
.\SetBrightnessWithAdjustment.ps1 minus
```

use 1.0 to 9.0 to set brightness directly.

```powershell
.\SetBrightnessWithAdjustment.ps1 1
.\SetBrightnessWithAdjustment.ps1 4.25
```

## Note

or doubleclick the VBS files to quickly set the corresponding brightness.
