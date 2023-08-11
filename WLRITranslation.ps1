function DownloadAndExtractFiles($file, $filesToDownload, $destinationFolder) {
    # Create the destination folder if it doesn't exist
    if (!(Test-Path $destinationFolder)) {
        New-Item -ItemType Directory -Path $destinationFolder | Out-Null
    }
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $webClient = New-Object System.Net.WebClient

    # Download each file in the list
    foreach ($url in $filesToDownload) {
        $fileName = Split-Path $url -Leaf
        $downloadPath = Join-Path $destinationFolder $fileName

        Write-Host -ForegroundColor Green "Downloading $fileName..."
        $webClient.DownloadFile($url, $downloadPath)

        if ($fileName -like "*.zip") {
        Write-Host -ForegroundColor Blue "Extracting $fileName..."
        Expand-Archive -Path $downloadPath -DestinationPath $destinationFolder -Force
        }

        # Remove the downloaded zip file
        Remove-Item $downloadPath -ErrorAction SilentlyContinue
    }

    $webClient.Dispose()

    # Write a message to show that all files have been downloaded and extracted
    Write-Host -ForegroundColor Yellow "All files downloaded and extracted successfully."
}

# Get the current script's directory as the working directory
$workingDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path

# Define URLs for files to check and download
$versionURL = "https://github.com/RegistryAlive/4444/raw/main/md5/Version.txt"
$dataURL = "https://github.com/RegistryAlive/4444/raw/main/md5/Data.txt"

$versionFilesToDownload = @(
    "https://f004.backblazeb2.com/file/WONDERLANDONLINE/jma.zip",
    "https://f004.backblazeb2.com/file/WONDERLANDONLINE/sty.zip",
    "https://f004.backblazeb2.com/file/WONDERLANDONLINE/pic.zip"
)

$dataFilesToDownload = @(
    "https://github.com/RegistryAlive/4444/raw/main/data.zip",
    "https://cdn.discordapp.com/attachments/758103145208479795/1051957594975121538/menu.zip",
    "https://github.com/RegistryAlive/4444/raw/main/SERVER.INI",
    "https://github.com/RegistryAlive/4444/raw/main/aLogin.exe",
    "https://github.com/RegistryAlive/4444/raw/main/aLoginModified.exe"
)

# Change to the script's directory
Set-Location -Path $workingDirectory

# Download and check the MD5 hash of Version.txt
$versionFile = Join-Path $workingDirectory "Version.txt"
$versionTempFile = Join-Path $workingDirectory "Version_temp.txt"

Write-Host -ForegroundColor Green "Downloading Version.txt..."
Invoke-WebRequest $versionURL -OutFile $versionTempFile

$expectedVersionMD5 = Get-FileHash $versionFile -Algorithm MD5
$downloadedVersionMD5 = Get-FileHash $versionTempFile -Algorithm MD5

# Check if Version.txt is missing or different
if (-not (Test-Path $versionFile) -or $downloadedVersionMD5.Hash -ne $expectedVersionMD5.Hash) {
    # Move the downloaded file to replace the old one
    Move-Item -Path $versionTempFile -Destination $versionFile -Force

    Write-Host -ForegroundColor Red "Version.txt is missing or different. Downloading additional files..."
    DownloadAndExtractFiles $versionFile $versionFilesToDownload $workingDirectory
}
else {
    # Remove the temporary downloaded file
    Remove-Item $versionTempFile -Force
    Write-Host -ForegroundColor Yellow "You have the updated Version.txt."
}

# Download and check the MD5 hash of Data.txt
$dataFile = Join-Path $workingDirectory "Data.txt"
$dataTempFile = Join-Path $workingDirectory "Data_temp.txt"

Write-Host -ForegroundColor Green "Downloading Data.txt..."
Invoke-WebRequest $dataURL -OutFile $dataTempFile

$expectedDataMD5 = Get-FileHash $dataFile -Algorithm MD5
$downloadedDataMD5 = Get-FileHash $dataTempFile -Algorithm MD5

# Check if Data.txt is missing or different
if (-not (Test-Path $dataFile) -or (Get-FileHash -Path $dataFile -Algorithm MD5).Hash -ne $expectedDataMD5.Hash) {
    # Move the downloaded file to replace the old one if it exists
    if (Test-Path $dataTempFile) {
        Move-Item -Path $dataTempFile -Destination $dataFile -Force
    }

    Write-Host "Data.txt is missing or different. Downloading additional files..."
    DownloadAndExtractFiles $dataFile $dataFilesToDownload $workingDirectory
}
else {
    # Remove the temporary downloaded file
    Remove-Item $dataTempFile -Force
    Write-Host -ForegroundColor Yellow "You have the updated Data.txt."
}

# All done!
$scriptToRemove = Join-Path $workingDirectory "WLRITranslation.ps1"
if (Test-Path $scriptToRemove) {
    Write-Host "Removing WLRITranslation.ps1..."
    Remove-Item $scriptToRemove -Force
}

Write-Host -ForegroundColor Blue "Script completed successfully, you may now launch your game."
