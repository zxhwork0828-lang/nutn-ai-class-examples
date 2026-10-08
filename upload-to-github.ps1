param([string]$Message = 'Update project from VS Code')

$ErrorActionPreference = 'Stop'
$gitCommand = Get-Command git -ErrorAction SilentlyContinue
$gitExecutable = if ($gitCommand) { $gitCommand.Source } else { $null }
if (-not $gitExecutable) {
    foreach ($candidate in @(
        "$env:ProgramFiles\Git\cmd\git.exe",
        "$env:LOCALAPPDATA\Programs\Git\cmd\git.exe"
    )) {
        if (Test-Path -LiteralPath $candidate) { $gitExecutable = $candidate; break }
    }
}
if (-not $gitExecutable) {
    throw 'Install Git for Windows from https://git-scm.com/download/win, restart VS Code, then run this script again.'
}

function Invoke-ProjectGit {
    param([string[]]$GitArguments)
    & $gitExecutable -C $PSScriptRoot @GitArguments
    if ($LASTEXITCODE -ne 0) {
        throw "Git failed (exit code $LASTEXITCODE). See the error above."
    }
}

$expectedRemote = 'https://github.com/zxhwork0828-lang/nutn-ai-class-examples.git'
$actualRemote = Invoke-ProjectGit @('remote', 'get-url', 'github')
if ($actualRemote -ne $expectedRemote) {
    throw "The github remote must point to $expectedRemote. Current value: $actualRemote"
}
$branch = Invoke-ProjectGit @('branch', '--show-current')
if ($branch -ne 'main') { throw 'Switch to the main branch before uploading.' }
foreach ($setting in @('user.name', 'user.email')) {
    $value = & $gitExecutable -C $PSScriptRoot config --get $setting
    if (-not $value) {
        throw "Set your commit identity first: git config $setting YOUR_VALUE"
    }
}

Invoke-ProjectGit @('add', '--all')
& $gitExecutable -C $PSScriptRoot diff --cached --quiet
$diffResult = $LASTEXITCODE
if ($diffResult -eq 1) {
    Invoke-ProjectGit @('commit', '-m', $Message)
} elseif ($diffResult -ne 0) {
    throw 'Could not check staged changes.'
} else {
    Write-Host 'No new changes to commit. Checking whether existing commits need uploading.'
}

Write-Host 'Uploading to GitHub. Complete the GitHub sign-in prompt if shown.'
& $gitExecutable -C $PSScriptRoot push github main
if ($LASTEXITCODE -ne 0) {
    throw 'GitHub upload failed. Check the error above. Sign in with write access if requested. If Git rejects conflicting remote history, reconcile it before retrying; this script never force-pushes.'
}
Write-Host "Uploaded to $expectedRemote"
