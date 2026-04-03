Add-Type -AssemblyName System.Drawing
$inFile = 'C:\Users\audwn\.gemini\antigravity\brain\3b70f103-4858-4465-bc6e-774235924ba0\florence_bg_better_1775105412465.png'
$img = [System.Drawing.Image]::FromFile($inFile)
$bmp = New-Object System.Drawing.Bitmap(1024, 500)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.Clear([System.Drawing.Color]::FromArgb(255, 128, 0, 32))

$scale = [math]::Max(1024.0 / $img.Width, 500.0 / $img.Height)
$newWidth = $img.Width * $scale
$newHeight = $img.Height * $scale
$x = (1024.0 - $newWidth) / 2
$y = (500.0 - $newHeight) / 2
$destRect = New-Object System.Drawing.RectangleF($x, $y, $newWidth, $newHeight)
$srcRect = New-Object System.Drawing.RectangleF(0, 0, $img.Width, $img.Height)
$g.DrawImage($img, $destRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)

$artifactsDir = 'C:\Users\audwn\.gemini\antigravity\brain\3b70f103-4858-4465-bc6e-774235924ba0\artifacts'
if (!(Test-Path -Path $artifactsDir)) { New-Item -ItemType Directory -Path $artifactsDir }
$outFile = Join-Path -Path $artifactsDir -ChildPath 'final_feature_graphic.png'
$bmp.Save($outFile, [System.Drawing.Imaging.ImageFormat]::Png)

$g.Dispose()
$bmp.Dispose()
$img.Dispose()
Write-Host "Resize Done"
