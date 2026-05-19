function smb-volumes {
    param(
        [string]$Command = "status"
    )

    $PauseFile = Join-Path $HOME ".config/apogee/automount-smb.paused"
    $MountScript = Join-Path $HOME ".local/bin/automount-smb-volumes.zsh"
    $LogFile = Join-Path $HOME "Library/Logs/automount-smb-volumes.log"
    $DataLibMount = Join-Path $HOME "Mounts/dataLib"
    $WhiskMount = Join-Path $HOME "Mounts/whisk"

    switch ($Command) {
        "mount" {
            Remove-Item -Force -ErrorAction SilentlyContinue $PauseFile
            & $MountScript
        }

        "unmount" {
            New-Item -ItemType File -Force -Path $PauseFile | Out-Null
            & umount $DataLibMount 2>$null
            & umount $WhiskMount 2>$null
        }

        "remount" {
            New-Item -ItemType File -Force -Path $PauseFile | Out-Null
            & umount $DataLibMount 2>$null
            & umount $WhiskMount 2>$null
            Remove-Item -Force -ErrorAction SilentlyContinue $PauseFile
            & $MountScript
        }

        "pause" {
            New-Item -ItemType File -Force -Path $PauseFile | Out-Null
            Write-Output "SMB automount paused."
        }

        "resume" {
            Remove-Item -Force -ErrorAction SilentlyContinue $PauseFile
            & $MountScript
        }

        "status" {
            Write-Output "Automount:"
            if (Test-Path $PauseFile) {
                Write-Output "  paused"
            } else {
                Write-Output "  active"
            }

            Write-Output ""
            Write-Output "Mounted SMB volumes:"
            $mounts = (& mount | Select-String -Pattern "$HOME/Mounts/(dataLib|whisk)")
            if ($mounts) {
                $mounts | ForEach-Object { $_.ToString() }
            } else {
                Write-Output "  none"
            }

            Write-Output ""
            Write-Output "Mount folders:"
            if (Test-Path $DataLibMount) {
                Get-Item $DataLibMount | Format-Table -AutoSize
            }
            if (Test-Path $WhiskMount) {
                Get-Item $WhiskMount | Format-Table -AutoSize
            }

            Write-Output ""
            Write-Output "Environment:"
            if ($env:DATALIB) {
                Write-Output "  DATALIB=$env:DATALIB"
            } else {
                Write-Output "  DATALIB=unset"
            }

            if ($env:WHISK) {
                Write-Output "  WHISK=$env:WHISK"
            } else {
                Write-Output "  WHISK=unset"
            }
        }

        "logs" {
            if (Test-Path $LogFile) {
                Get-Content $LogFile -Tail 100
            } else {
                Write-Output "No log file found: $LogFile"
            }
        }

        default {
            Write-Output "Usage: smb-volumes {mount|unmount|remount|pause|resume|status|logs}"
            return
        }
    }
}
