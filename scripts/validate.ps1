$repo = Join-Path $PSScriptRoot "../src"
$errors = 0

function Write-Fail($message) {
    Write-Host "FAIL: $message" -ForegroundColor Red
    $script:errors++
}

# Check Maven metadata
$metadataFiles = @(Get-ChildItem $repo -Recurse -Filter "maven-metadata.xml" -File)

if ($metadataFiles.Count -eq 0) {
    Write-Fail "No Maven metadata found"
}

foreach ($file in $metadataFiles) {
    # Validate XML Content is well-formed
    try {
        [xml]$xml = Get-Content $file.FullName -Raw
    }
    catch {
        Write-Fail "Invalid XML: $($file.FullName)"
        continue
    }

    $artifact = [string]$xml.metadata.artifactId
    $versions = @($xml.metadata.versioning.versions.version)

    foreach ($version in $versions) {
        $folder = Join-Path $file.DirectoryName $version

        if (!(Test-Path $folder -PathType Container)) {
            Write-Fail "Missing version folder: $folder"
            continue
        }

        foreach ($ext in @("pom", "jar")) {
            $path = Join-Path $folder "$artifact-$version.$ext"

            if (!(Test-Path $path -PathType Leaf)) {
                Write-Fail "Missing artifact: $path"
            }
        }
    }
}

# Check existing MD5 / SHA1 checksums
Get-ChildItem $repo -Recurse -File | Where-Object { $_.Extension -in @(".md5", ".sha1") } | ForEach-Object {
        $target = $_.FullName.Substring(0, $_.FullName.Length - $_.Extension.Length)

        if (!(Test-Path $target -PathType Leaf)) {
            Write-Fail "Missing checksum target: $target"
            return
        }

        $algorithm = if ($_.Extension -eq ".md5") { "MD5" } else { "SHA1" }
        $expected = (Get-Content $_.FullName -Raw).Trim()
        $actual = (Get-FileHash $target -Algorithm $algorithm).Hash

        if ($expected -ine $actual) {
            Write-Fail "Checksum mismatch: $target"
        }
    }

# Result
if ($errors -gt 0) {
    Write-Host "`nValidation failed: $errors error(s)" -ForegroundColor Red
    exit 1
}

Write-Host "`n✅ Maven repository is valid!" -ForegroundColor Green
exit 0
