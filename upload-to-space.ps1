param([string]$Message = 'Update project from VS Code')

$ErrorActionPreference = 'Stop'
if (-not (Get-Command hf -ErrorAction SilentlyContinue)) {
    throw 'Hugging Face CLI (hf) is required. Install it and run hf auth login first.'
}

$uploadArgs = @(
    'upload', 'ed3000/game001', $PSScriptRoot, '.',
    '--repo-type', 'space', '--revision', 'main',
    '--commit-message', $Message
)
foreach ($pattern in @('.git/*', '.cache/*', '.venv/*', 'venv/*', 'node_modules/*', '**/__pycache__/*', '*.pyc', '.env', '.env.*', 'upload-to-space.ps1')) {
    # Keep the pattern attached to the option so the Windows CLI launcher
    # does not expand it into local filenames before parsing arguments.
    $uploadArgs += "--exclude=$pattern"
}

& hf @uploadArgs
if ($LASTEXITCODE -ne 0) {
    throw "Upload failed (exit code $LASTEXITCODE). See the Hugging Face error above for the cause."
}
Write-Host 'Uploaded to https://huggingface.co/spaces/ed3000/game001'
