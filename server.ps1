# Servidor HTTP estático en PowerShell para Encanto Travels
# No requiere instalación - usa .NET HttpListener nativo

$port = 8000
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()

$rootPath = (Get-Location).Path
Write-Host "Servidor activo en http://localhost:$port/" -ForegroundColor Green
Write-Host "Sirviendo desde: $rootPath" -ForegroundColor Cyan
Write-Host "Presiona Ctrl+C para detener" -ForegroundColor Yellow

$mimeTypes = @{
    ".html"  = "text/html; charset=utf-8"
    ".htm"   = "text/html; charset=utf-8"
    ".css"   = "text/css; charset=utf-8"
    ".js"    = "application/javascript; charset=utf-8"
    ".json"  = "application/json; charset=utf-8"
    ".jpg"   = "image/jpeg"
    ".jpeg"  = "image/jpeg"
    ".png"   = "image/png"
    ".gif"   = "image/gif"
    ".svg"   = "image/svg+xml"
    ".webp"  = "image/webp"
    ".ico"   = "image/x-icon"
    ".woff"  = "font/woff"
    ".woff2" = "font/woff2"
    ".ttf"   = "font/ttf"
    ".txt"   = "text/plain; charset=utf-8"
    ".pdf"   = "application/pdf"
}

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        try {
            $localPath = [uri]::UnescapeDataString($request.Url.LocalPath)
            if ($localPath -eq "/" -or [string]::IsNullOrEmpty($localPath)) {
                $localPath = "/index.html"
            }

            $relativePath = $localPath.TrimStart('/').Replace('/', [System.IO.Path]::DirectorySeparatorChar)
            $filePath = Join-Path $rootPath $relativePath

            if (Test-Path $filePath -PathType Leaf) {
                $content = [System.IO.File]::ReadAllBytes($filePath)
                $ext = [System.IO.Path]::GetExtension($filePath).ToLower()

                if ($mimeTypes.ContainsKey($ext)) {
                    $response.ContentType = $mimeTypes[$ext]
                } else {
                    $response.ContentType = "application/octet-stream"
                }

                $response.Headers.Add("Cache-Control", "no-cache")
                $response.ContentLength64 = $content.Length
                $response.OutputStream.Write($content, 0, $content.Length)
                Write-Host "200 $localPath" -ForegroundColor Gray
            } else {
                $response.StatusCode = 404
                $notFound = [System.Text.Encoding]::UTF8.GetBytes("404 - Archivo no encontrado: $localPath")
                $response.ContentType = "text/plain; charset=utf-8"
                $response.OutputStream.Write($notFound, 0, $notFound.Length)
                Write-Host "404 $localPath" -ForegroundColor Red
            }
        } catch {
            try { $response.StatusCode = 500 } catch {}
            Write-Host "Error: $_" -ForegroundColor Red
        } finally {
            try { $response.Close() } catch {}
        }
    }
} finally {
    $listener.Stop()
    $listener.Close()
}
