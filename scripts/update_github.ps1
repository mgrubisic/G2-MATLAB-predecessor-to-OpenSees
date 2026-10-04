# Publication uses the existing remote history, never the local feature branch.
[CmdletBinding()]
param(
    [switch]$Plan,
    [switch]$Publish,
    [switch]$SkipTests,
    [string]$CommitMessage = 'Update G2 MATLAB analysis, examples and documentation',
    [string]$RemoteUrl = 'https://github.com/mgrubisic/G2-MATLAB-predecessor-to-OpenSees.git'
)
$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$projectBoundary = $projectRoot.TrimEnd('\') + '\'
$temporaryClone = $null

function Invoke-Git([string[]]$GitArguments) {
    $output = & git @GitArguments
    if ($LASTEXITCODE -ne 0) { throw ('Git command failed: ' + ($GitArguments -join ' ')) }
    return $output
}
function Get-SafePath([string]$Base, [string]$Relative) {
    $boundary = $Base.TrimEnd('\') + '\'
    $path = [IO.Path]::GetFullPath((Join-Path $Base $Relative))
    if (-not $path.StartsWith($boundary,[StringComparison]::OrdinalIgnoreCase)) {
        throw ('Path outside project boundary: ' + $Relative)
    }
    return $path
}
try {
    if ($Plan -and $Publish) { throw 'Choose -Plan or -Publish, not both.' }
    if ([string]::IsNullOrWhiteSpace($CommitMessage)) { throw 'CommitMessage cannot be empty.' }
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw 'Git is required.' }
    foreach ($required in @('setup_g2.m','README.md','LICENSE.md','src/@model/model.m')) {
        if (-not (Test-Path -LiteralPath (Get-SafePath $projectRoot $required))) { throw ('Missing project file: ' + $required) }
    }
    $manifest = [Collections.Generic.List[string]]::new()
    foreach ($name in @('.gitignore','README.md','LICENSE.md','setup_g2.m')) { $manifest.Add($name) }
    foreach ($folder in @('src','EXAMPLES','docs','data','tests','scripts')) {
        $directory = Get-SafePath $projectRoot $folder
        foreach ($file in (Get-ChildItem -LiteralPath $directory -File -Recurse -Force)) {
            $relative = $file.FullName.Substring($projectBoundary.Length).Replace('\','/')
            # Include source/data, not outputs or editor/cache files.
            if ($relative -match '(^|/)(\.git|__pycache__|output|results)(/|$)' -or
                $relative -match '\.(asv|pyc|m~)$' -or $file.Name.StartsWith('._')) { continue }
            if (($file.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw ('Unsupported symbolic link: ' + $relative) }
            $manifest.Add($relative)
        }
    }
    $files = @($manifest | Sort-Object -Unique)
    Write-Host ('Project: ' + $projectRoot)
    Write-Host ('Target:  ' + $RemoteUrl)
    Write-Host ('Publication manifest: ' + $files.Count + ' files')
    if (-not $Plan -and -not $Publish) {
        $files | ForEach-Object { Write-Host ('  ' + $_) }
        Write-Host 'Use -Plan to inspect the remote diff, or -Publish to test, commit and push.'
        exit 0
    }
    if ($Publish -and -not $SkipTests) {
        if (-not (Get-Command matlab -ErrorAction SilentlyContinue)) { throw 'MATLAB is required for pre-publication tests.' }
        $matlabRoot = $projectRoot.Replace("'","''")
        & matlab -batch "cd('$matlabRoot'); setup_g2; r=runtests('tests'); assertSuccess(r);"
        if ($LASTEXITCODE -ne 0) { throw 'MATLAB tests failed; publication stopped.' }
    } elseif ($Publish -and $SkipTests) {
        Write-Host 'MATLAB tests skipped (-SkipTests).'
    }
    $head = @(Invoke-Git @('ls-remote','--symref',$RemoteUrl,'HEAD'))
    $branch = $null
    foreach ($line in $head) { if ($line -match '^ref: refs/heads/(.+)\s+HEAD$') { $branch=$Matches[1]; break } }
    if (-not $branch) { throw 'Cannot determine the remote default branch.' }
    $temporaryBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
    $temporaryClone = Join-Path $temporaryBase ('g2-publish-' + [guid]::NewGuid().ToString('N'))
    Invoke-Git @('clone','--single-branch','--branch',$branch,$RemoteUrl,$temporaryClone) | Out-Host
    $existing = @(Invoke-Git @('-C',$temporaryClone,'ls-files'))
    $published = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($file in $files) { [void]$published.Add($file) }
    # Synchronize the project. Preserve remote automation/metadata outside the
    # local source manifest (.github, .gitattributes, .editorconfig).
    foreach ($oldFile in $existing) {
        if ($oldFile -match '^\.github/' -or $oldFile -in @('.gitattributes','.editorconfig')) { continue }
        if (-not $published.Contains($oldFile)) {
            $obsolete = Get-SafePath $temporaryClone $oldFile
            if (Test-Path -LiteralPath $obsolete -PathType Leaf) { Remove-Item -LiteralPath $obsolete }
            else { throw ('Unsupported tracked directory/submodule: ' + $oldFile) }
        }
    }
    foreach ($relative in $files) {
        $source = Get-SafePath $projectRoot $relative
        $destination = Get-SafePath $temporaryClone $relative
        [void](New-Item -ItemType Directory -Force -Path (Split-Path -Parent $destination))
        Copy-Item -LiteralPath $source -Destination $destination
    }
    Invoke-Git @('-C',$temporaryClone,'add','--all') | Out-Host
    Write-Host ('Prepared changes for remote branch: ' + $branch)
    Invoke-Git @('-C',$temporaryClone,'diff','--cached','--stat') | Out-Host
    $changes = @(Invoke-Git @('-C',$temporaryClone,'diff','--cached','--name-only'))
    if ($changes.Count -eq 0) { Write-Host 'Remote already matches the publication manifest.'; exit 0 }
    if ($Plan) { Write-Host 'Plan complete. No commit or push performed.'; exit 0 }
    # Carry locally configured identity into the isolated clone if available.
    foreach ($key in @('user.name','user.email')) {
        $identity = & git -C $projectRoot config --get $key
        if ($LASTEXITCODE -eq 0 -and $identity) { Invoke-Git @('-C',$temporaryClone,'config',$key,([string]$identity)) | Out-Host }
    }
    Invoke-Git @('-C',$temporaryClone,'commit','-m',$CommitMessage) | Out-Host
    Invoke-Git @('-C',$temporaryClone,'push','origin',('HEAD:refs/heads/' + $branch)) | Out-Host
    Write-Host ('Published to ' + $RemoteUrl + ' / ' + $branch)
} catch {
    Write-Error -Message $_.Exception.Message -ErrorAction Continue
    exit 1
} finally {
    if ($temporaryClone -and (Test-Path -LiteralPath $temporaryClone)) {
        $resolved = (Resolve-Path -LiteralPath $temporaryClone).Path
        $tempBoundary = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
        if ($resolved.StartsWith($tempBoundary,[StringComparison]::OrdinalIgnoreCase) -and
            (Split-Path -Leaf $resolved) -match '^g2-publish-[0-9a-f]{32}$') {
            Remove-Item -LiteralPath $resolved -Recurse -Force
        } else { Write-Warning 'Temporary clone cleanup skipped: unexpected resolved path.' }
    }
}
