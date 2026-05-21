param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("build", "shell", "prepare", "train", "smoke", "gpu-check", "down")]
    [string]$Command
)

$ErrorActionPreference = "Stop"

function Ensure-Docker {
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        throw "Docker CLI is not on PATH. Install Docker Desktop and restart the terminal."
    }
}

function Run-Compose {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Args
    )

    $hadNativePref = $null -ne (Get-Variable -Name PSNativeCommandUseErrorActionPreference -Scope Global -ErrorAction SilentlyContinue)
    if ($hadNativePref) {
        $oldNativePref = $Global:PSNativeCommandUseErrorActionPreference
        $Global:PSNativeCommandUseErrorActionPreference = $false
    }

    try {
        & docker compose @Args
        if ($LASTEXITCODE -ne 0) {
            throw "docker compose failed with exit code $LASTEXITCODE"
        }
    }
    finally {
        if ($hadNativePref) {
            $Global:PSNativeCommandUseErrorActionPreference = $oldNativePref
        }
    }
}

Ensure-Docker

switch ($Command) {
    "build" { Run-Compose build }
    "shell" { Run-Compose run --rm autoresearch }
    "prepare" { Run-Compose run --rm autoresearch uv run prepare.py }
    "train" { Run-Compose run --rm autoresearch uv run train.py }
    "smoke" { Run-Compose run --rm autoresearch uv run train.py --smoke-test }
    "gpu-check" {
        Run-Compose run --rm autoresearch uv run python -c "import torch; print(torch.cuda.is_available(), torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'no-gpu')"
    }
    "down" { Run-Compose down }
}
