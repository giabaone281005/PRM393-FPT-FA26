Add-Type -AssemblyName System.Drawing

$srcPath = "C:\Users\kzrok\.gemini\antigravity-ide\brain\5e183008-a40d-4c84-bfaf-54f23459f90c\.user_uploaded\media_1792072823112.jpg"
$assetDest = "d:\DEMO\PRM391\assets\images"
New-Item -ItemType Directory -Force -Path $assetDest | Out-Null
Copy-Item $srcPath (Join-Path $assetDest "owl_mascot.jpg")

function Resize-Img {
    param([string]$source, [string]$destination, [int]$width, [int]$height)
    $src = [System.Drawing.Image]::FromFile($source)
    $bmp = New-Object System.Drawing.Bitmap($width, $height)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.DrawImage($src, 0, 0, $width, $height)
    $bmp.Save($destination, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose()
    $bmp.Dispose()
    $src.Dispose()
}

$targets = @(
    @{ Path = "d:\DEMO\PRM391\android\app\src\main\res\mipmap-mdpi\ic_launcher.png"; Size = 48 },
    @{ Path = "d:\DEMO\PRM391\android\app\src\main\res\mipmap-hdpi\ic_launcher.png"; Size = 72 },
    @{ Path = "d:\DEMO\PRM391\android\app\src\main\res\mipmap-xhdpi\ic_launcher.png"; Size = 96 },
    @{ Path = "d:\DEMO\PRM391\android\app\src\main\res\mipmap-xxhdpi\ic_launcher.png"; Size = 144 },
    @{ Path = "d:\DEMO\PRM391\android\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png"; Size = 192 }
)

foreach ($t in $targets) {
    Resize-Img -source $srcPath -destination $t.Path -width $t.Size -height $t.Size
    Write-Output "Generated $($t.Path)"
}
