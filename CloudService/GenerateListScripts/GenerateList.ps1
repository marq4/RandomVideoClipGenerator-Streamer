param (
    [string]$custom_subfolder
)


$working_dir = $PWD


Set-Variable -Name 'videos_subfolder' -Value $null

#Write-Host "Custom subfolder name is: $custom_subfolder "

if (-not $PSBoundParameters.ContainsKey('custom_subfolder') ) {
    #Write-Output "Custom subfolder name was not specified. "
    Set-Variable -Name 'videos_subfolder' -Value 'videos'
} else {
    Set-Variable -Name 'videos_subfolder' -Value $custom_subfolder
}


cd $working_dir

if (Test-Path -Path $videos_subfolder -PathType Container) {
    #Write-Output "Subdir exists!"
    ;
} else {
    Write-Output "Subfolder for videos does not exist. Default name is videos, or please specify a name. "
    Exit 1
}

# Check if ffmpeg is installed: 
$found = [bool] (Get-Command -ErrorAction Ignore -Type Application ffmpeg)

if (-not $found) {
    Write-Output "Essential program FFMPEG not found on this system. Please install it and try again. "
    Exit 2
}

$list_file = "list_" + $videos_subfolder + ".txt"

# Remove file if exists:
if (Test-Path -Path $list_file -PathType Leaf) {
    Remove-Item -Path $list_file
}

# Get all MP4 files under subdir:
Set-Variable -Name 'Full_Path' -Value $null
$Full_Path = "$working_dir\" + "$videos_subfolder"
$Collection = @()
$Collection = Get-ChildItem $Full_Path -Filter "*.mp4" -Recurse | Select-Object -ExpandProperty FullName

# Create file:
$ignore_output = New-Item -Path $list_file -ItemType File

# Append video path and duration to list file:
foreach ($item in $Collection) {
    $duration = ffprobe -v error -select_streams v:0 -show_entries stream=duration -of default=noprint_wrappers=1:nokey=1 $item
    $value = "$item ::: $duration" + [System.Environment]::NewLine
    Add-Content -Path $list_file -Value $value -Encoding UTF8
}

Write-Output "Script complete. Please check the list file: $list_file before uploading. "
