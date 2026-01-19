<#
.SYNOPSIS
    Bumps the version, creates a git tag, and pushes to trigger a release build.

.PARAMETER Version
    Optional. Specify a custom version (e.g., "1.0.0"). If omitted, bumps the patch version.

.PARAMETER BuildNumber
    Optional. Specify a custom build number. If omitted, increments the current build number.

.EXAMPLE
    .\push-release.ps1
    # Bumps patch version (0.0.4 -> 0.0.5) and increments build number

.EXAMPLE
    .\push-release.ps1 -Version "1.0.0"
    # Sets version to 1.0.0 with incremented build number

.EXAMPLE
    .\push-release.ps1 -Version "1.0.0" -BuildNumber 0
    # Sets version to 1.0.0+0
#>

param(
    [string]$Version,
    [int]$BuildNumber = -1
)

$ErrorActionPreference = "Stop"

# Ensure we're in the repo root (where pubspec.yaml is)
$repoRoot = Split-Path -Parent $PSScriptRoot
Push-Location $repoRoot

try {
    # Check if on main branch
    $currentBranch = git branch --show-current
    if ($currentBranch -ne "main") {
        Write-Error "You must be on the 'main' branch to push a release. Currently on: $currentBranch"
        exit 1
    }

    # Check for uncommitted changes (excluding pubspec.yaml which we'll modify)
    $status = git status --porcelain | Where-Object { $_ -notmatch "pubspec.yaml" }
    if ($status) {
        Write-Error "You have uncommitted changes. Please commit or stash them first."
        git status --short
        exit 1
    }

    # Read current version from pubspec.yaml
    $pubspecPath = "pubspec.yaml"
    $pubspecContent = Get-Content $pubspecPath -Raw

    if ($pubspecContent -match 'version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)') {
        $major = [int]$Matches[1]
        $minor = [int]$Matches[2]
        $patch = [int]$Matches[3]
        $currentBuild = [int]$Matches[4]
        $currentVersion = "$major.$minor.$patch"
        Write-Host "Current version: $currentVersion+$currentBuild" -ForegroundColor Cyan
    } else {
        Write-Error "Could not parse version from pubspec.yaml"
        exit 1
    }

    # Determine new version
    if ($Version) {
        # Validate custom version format
        if ($Version -notmatch '^\d+\.\d+\.\d+$') {
            Write-Error "Invalid version format. Use semantic versioning (e.g., 1.0.0)"
            exit 1
        }
        $newVersion = $Version
    } else {
        # Bump patch version
        $newVersion = "$major.$minor.$($patch + 1)"
    }

    # Determine new build number
    if ($BuildNumber -ge 0) {
        $newBuild = $BuildNumber
    } else {
        $newBuild = $currentBuild + 1
    }

    $fullVersion = "$newVersion+$newBuild"
    $tagName = "v$newVersion"

    Write-Host "New version: $fullVersion" -ForegroundColor Green
    Write-Host "Tag: $tagName" -ForegroundColor Green

    # Check if tag already exists
    $existingTag = git tag -l $tagName
    if ($existingTag) {
        Write-Error "Tag '$tagName' already exists. Use a different version."
        exit 1
    }

    # Confirm with user
    Write-Host ""
    $confirm = Read-Host "Proceed with release? (y/N)"
    if ($confirm -ne "y" -and $confirm -ne "Y") {
        Write-Host "Aborted." -ForegroundColor Yellow
        exit 0
    }

    # Update pubspec.yaml
    $pubspecContent = $pubspecContent -replace 'version:\s*\d+\.\d+\.\d+\+\d+', "version: $fullVersion"
    Set-Content $pubspecPath $pubspecContent -NoNewline

    Write-Host "Updated pubspec.yaml" -ForegroundColor Green

    # Commit the version bump
    git add pubspec.yaml
    git commit -m "Bump version to $fullVersion"
    Write-Host "Committed version bump" -ForegroundColor Green

    # Create tag
    git tag $tagName
    Write-Host "Created tag $tagName" -ForegroundColor Green

    # Push commit and tag
    Write-Host "Pushing to origin..." -ForegroundColor Cyan
    git push origin main
    git push origin $tagName

    Write-Host ""
    Write-Host "Release $tagName pushed successfully!" -ForegroundColor Green
    Write-Host "GitHub Actions will now build and create the release." -ForegroundColor Cyan
    $repoUrl = (git remote get-url origin) -replace '.*github.com[:/]', '' -replace '\.git$', ''
    Write-Host "Watch progress at: https://github.com/$repoUrl/actions" -ForegroundColor Cyan

} finally {
    Pop-Location
}
