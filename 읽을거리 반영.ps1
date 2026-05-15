$ErrorActionPreference = 'Stop'
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
[Console]::InputEncoding = $utf8NoBom
[Console]::OutputEncoding = $utf8NoBom
$OutputEncoding = $utf8NoBom

Set-Location -LiteralPath $PSScriptRoot
$scriptRootPath = $PSScriptRoot

function Get-Text {
    param([string]$Base64Value)
    return [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($Base64Value))
}

function Read-Utf8File {
    param([string]$Path)
    return [System.IO.File]::ReadAllText($Path, [System.Text.UTF8Encoding]::new($true))
}

function Write-Utf8File {
    param(
        [string]$Path,
        [string]$Content
    )
    [System.IO.File]::WriteAllText($Path, $Content, [System.Text.UTF8Encoding]::new($false))
}

$TXT_MONDAY = Get-Text '7JuU7JqU7J28'
$TXT_TUESDAY = Get-Text '7ZmU7JqU7J28'
$TXT_WEDNESDAY = Get-Text '7IiY7JqU7J28'
$TXT_THURSDAY = Get-Text '66qp7JqU7J28'
$TXT_FRIDAY = Get-Text '6riI7JqU7J28'
$TXT_SATURDAY = Get-Text '7Yag7JqU7J28'
$TXT_SUNDAY = Get-Text '7J287JqU7J28'
$TXT_AGENCY = Get-Text '6riw6rSA'
$TXT_TITLE = Get-Text '7KCc66qp'
$TXT_DETAILS = Get-Text '7KO87JqUIOuCtOyaqQ=='
$TXT_ATTACHMENT = Get-Text '7LKo67aA'
$TXT_LINK = Get-Text '66eB7YGs'
$TXT_NONE = Get-Text '7JeG7J2M'
$TXT_DATE_HEADER = Get-Text 'IyDrgqDsp5w6'
$TXT_DATA_MARKER = Get-Text 'IyMgOC4g7J2067KIIOuwmOyYgSDrjbDsnbTthLA='
$TXT_AGENT_NAME = Get-Text '7KCV7ZuI'
$TXT_AM = Get-Text '7Jik7KCE'
$TXT_DAY = Get-Text '7J28'
$TXT_YEAR = Get-Text '64WE'
$TXT_MONTH = Get-Text '7JuU'
$TXT_MESSAGE_SUFFIX = Get-Text '7J297J2E6rGw66asOiDso7zsmpQg7KCV67aA67aA7LKYIOuwjyDsmbjrtoAg7Jew6rWs6riw6rSAIOuwnOqwhOyekOujjA=='
$MARKDOWN_NAME = Get-Text '7J297J2E6rGw66asIOyXheuNsOydtO2KuC5tZA=='
$FIELD_PATTERN = '^- ({0}|{1}|{2}|{3}|{4}):\s*(.*)$' -f [regex]::Escape($TXT_AGENCY), [regex]::Escape($TXT_TITLE), [regex]::Escape($TXT_DETAILS), [regex]::Escape($TXT_ATTACHMENT), [regex]::Escape($TXT_LINK)
$DATE_PATTERN = '^{0}\s*(\d{{4}}){1}\s*(\d{{1,2}}){2}\s*(\d{{1,2}}){3}\s*$' -f [regex]::Escape($TXT_DATE_HEADER), [regex]::Escape($TXT_YEAR), [regex]::Escape($TXT_MONTH), [regex]::Escape($TXT_DAY)

function Get-WeekdayKorean {
    param([datetime]$Date)

    switch ($Date.DayOfWeek) {
        'Monday' { $TXT_MONDAY }
        'Tuesday' { $TXT_TUESDAY }
        'Wednesday' { $TXT_WEDNESDAY }
        'Thursday' { $TXT_THURSDAY }
        'Friday' { $TXT_FRIDAY }
        'Saturday' { $TXT_SATURDAY }
        default { $TXT_SUNDAY }
    }
}

function Get-NormalizedAgency {
    param([string]$Value)

    $cleaned = (($Value -replace '\[|\]', '') -replace '\s+', ' ').Trim()
    $aliases = @{
        'KIEP' = Get-Text '64yA7Jm46rK97KCc7KCV7LGF7Jew6rWs7JuQ'
        (Get-Text '64yA7Jm46rK97KCc7KCV7LGF7Jew6rWs7JuQ') = Get-Text '64yA7Jm46rK97KCc7KCV7LGF7Jew6rWs7JuQ'
        (Get-Text '7Ya16rOE7LKt') = Get-Text '6rWt6rCA642w7J207YSw7LKY'
        (Get-Text '6rWt6rCA642w7J207YSw7LKY') = Get-Text '6rWt6rCA642w7J207YSw7LKY'
        (Get-Text '7ZWY64KY6riI7Jy16rK97JiB7Jew6rWs7IaM') = Get-Text '7ZWY64KY6riI7Jy16rK97JiB7Jew6rWs7IaM'
        ((Get-Text '7ZWc6rWt6riI7Jy17Jew6rWs7JuQ') + ']') = Get-Text '7ZWc6rWt6riI7Jy17Jew6rWs7JuQ'
        (Get-Text '7ZWc6rWt6riI7Jy17Jew6rWs7JuQ') = Get-Text '7ZWc6rWt6riI7Jy17Jew6rWs7JuQ'
        'KITA' = Get-Text '7ZWc6rWt66y07Jet7ZiR7ZqM'
        (Get-Text '7ZWc6rWt66y07Jet7ZiR7ZqM') = Get-Text '7ZWc6rWt66y07Jet7ZiR7ZqM'
        'KDI' = Get-Text '7ZWc6rWt6rCc67Cc7Jew6rWs7JuQ'
        (Get-Text '7ZWc6rWt6rCc67Cc7Jew6rWs7JuQ') = Get-Text '7ZWc6rWt6rCc67Cc7Jew6rWs7JuQ'
        (Get-Text '64m07IqkIOq4sOyCrA==') = Get-Text '7Ja466Gg6riw7IKs'
        (Get-Text '7KSR7IaM6riw7JeF7KSR7JWZ7ZqM') = Get-Text '7KSR6riw7KSR7JWZ7ZqM'
        (Get-Text '7KSR6riw7KSR7JWZ7ZqM') = Get-Text '7KSR6riw7KSR7JWZ7ZqM'
        (Get-Text '6riw7ZqN7J6s7KCV67aA') = Get-Text '7J6s7KCV6rK97KCc67aA'
        (Get-Text '7J6s7KCV6rK97KCc67aA') = Get-Text '7J6s7KCV6rK97KCc67aA'
    }

    if ($aliases.ContainsKey($cleaned)) {
        return $aliases[$cleaned]
    }

    return $cleaned
}

function Parse-Attachments {
    param(
        [string]$RawValue,
        [string]$FallbackUrl
    )

    $trimmed = $RawValue.Trim()
    if (-not $trimmed -or $trimmed -eq $TXT_NONE) {
        return @()
    }

    $items = New-Object System.Collections.Generic.List[object]
    foreach ($piece in ($trimmed -split '\s+\|\s+')) {
        $chunk = $piece.Trim()
        if ($chunk.StartsWith('* ')) {
            $chunk = $chunk.Substring(2).Trim()
        }

        $match = [regex]::Match($chunk, '^(?<label>.+?)\((?<url>https?://[^\s)]+)\)\s*$')
        if ($match.Success) {
            $items.Add([pscustomobject]@{
                    Label = $match.Groups['label'].Value.Trim()
                    Url = $match.Groups['url'].Value.Trim()
                    Linked = $true
                })
            continue
        }

        $items.Add([pscustomobject]@{
                Label = $chunk
                Url = $FallbackUrl
                Linked = $false
            })
    }

    return $items
}

function Finalize-Entry {
    param(
        [hashtable]$Entry,
        [System.Collections.Generic.List[object]]$TargetList
    )

    if (-not $Entry) {
        return
    }

    foreach ($field in @($TXT_AGENCY, $TXT_TITLE, $TXT_DETAILS, $TXT_ATTACHMENT, $TXT_LINK)) {
        if (-not $Entry.ContainsKey($field)) {
            throw "Required field is missing: $field"
        }
    }

    $details = @()
    foreach ($item in $Entry[$TXT_DETAILS]) {
        $text = [string]$item
        if ($text.Trim() -and $text.Trim() -ne $TXT_NONE) {
            $details += $text.Trim()
        }
    }

    $link = ([string]$Entry[$TXT_LINK]).Trim()
    if (-not $link -or $link -eq $TXT_NONE) {
        throw "Link is required: $($Entry[$TXT_TITLE])"
    }

    $TargetList.Add([pscustomobject]@{
            Agency = Get-NormalizedAgency ([string]$Entry[$TXT_AGENCY])
            Title = ([string]$Entry[$TXT_TITLE]).Trim()
            Details = $details
            Attachments = Parse-Attachments -RawValue ([string]$Entry[$TXT_ATTACHMENT]) -FallbackUrl $link
            Link = $link
        })
}

function Parse-ReadingMarkdown {
    param([string]$MarkdownPath)

    $text = Read-Utf8File $MarkdownPath
    $normalized = $text.Replace("`r`n", "`n").Replace("`r", "`n")
    $parts = $normalized -split [regex]::Escape($TXT_DATA_MARKER), 2
    if ($parts.Count -lt 2) {
        throw 'Could not find the expected readings data section.'
    }

    $lines = $parts[1] -split "`n"
    $sections = New-Object System.Collections.Generic.List[object]
    $currentSection = $null
    $currentEntry = $null
    $activeField = $null

    foreach ($rawLine in $lines) {
        $line = $rawLine.TrimEnd()
        $trimmed = $line.Trim()

        if (-not $trimmed) {
            continue
        }

        $dateMatch = [regex]::Match($trimmed, $DATE_PATTERN)
        if ($dateMatch.Success) {
            if ($currentEntry) {
                Finalize-Entry -Entry $currentEntry -TargetList $currentSection.Entries
                $currentEntry = $null
            }

            if ($currentSection) {
                if ($currentSection.Entries.Count -eq 0) {
                    throw "A date section has no entries: $($currentSection.Label)"
                }
                $sections.Add($currentSection)
            }

            $date = Get-Date -Year ([int]$dateMatch.Groups[1].Value) -Month ([int]$dateMatch.Groups[2].Value) -Day ([int]$dateMatch.Groups[3].Value)
            $currentSection = [pscustomobject]@{
                Date = $date
                Label = "{0}{1} {2}{3} {4}{5}" -f $date.Year, $TXT_YEAR, $date.Month, $TXT_MONTH, $date.Day, $TXT_DAY
                Entries = New-Object System.Collections.Generic.List[object]
            }
            $activeField = $null
            continue
        }

        if ($trimmed -eq '---') {
            if (-not $currentSection) {
                throw 'Entry separator found before any date header.'
            }

            if ($currentEntry) {
                Finalize-Entry -Entry $currentEntry -TargetList $currentSection.Entries
                $currentEntry = $null
            }

            $activeField = $null
            continue
        }

        $fieldMatch = [regex]::Match($trimmed, $FIELD_PATTERN)
        if ($fieldMatch.Success) {
            if (-not $currentEntry) {
                $currentEntry = @{
                    $TXT_DETAILS = New-Object System.Collections.Generic.List[string]
                }
            }

            $fieldName = $fieldMatch.Groups[1].Value
            $fieldValue = $fieldMatch.Groups[2].Value.Trim()

            if ($fieldName -eq $TXT_DETAILS) {
                $list = New-Object System.Collections.Generic.List[string]
                if ($fieldValue) {
                    $list.Add($fieldValue)
                }
                else {
                    $list.Add($TXT_NONE)
                }
                $currentEntry[$fieldName] = $list
            }
            else {
                $currentEntry[$fieldName] = if ($fieldValue) { $fieldValue } else { $TXT_NONE }
            }

            $activeField = $fieldName
            continue
        }

        if (-not $currentEntry) {
            continue
        }

        $detailMatch = [regex]::Match($line, '^\s{2}-\s+(.+)$')
        if ($detailMatch.Success -and $activeField -eq $TXT_DETAILS) {
            $detailText = $detailMatch.Groups[1].Value.Trim()
            if ($currentEntry[$TXT_DETAILS].Count -eq 1 -and $currentEntry[$TXT_DETAILS][0] -eq $TXT_NONE) {
                $currentEntry[$TXT_DETAILS].Clear()
            }
            $currentEntry[$TXT_DETAILS].Add($detailText)
            continue
        }

        if (-not $activeField) {
            continue
        }

        if ($activeField -eq $TXT_DETAILS) {
            if ($currentEntry[$TXT_DETAILS].Count -eq 0) {
                $currentEntry[$TXT_DETAILS].Add($trimmed)
            }
            elseif ($currentEntry[$TXT_DETAILS].Count -eq 1 -and $currentEntry[$TXT_DETAILS][0] -eq $TXT_NONE) {
                $currentEntry[$TXT_DETAILS][0] = $trimmed
            }
            else {
                $lastIndex = $currentEntry[$TXT_DETAILS].Count - 1
                $currentEntry[$TXT_DETAILS][$lastIndex] = ($currentEntry[$TXT_DETAILS][$lastIndex] + ' ' + $trimmed).Trim()
            }
        }
        else {
            $currentEntry[$activeField] = (([string]$currentEntry[$activeField]) + ' ' + $trimmed).Trim()
        }
    }

    if ($currentEntry) {
        Finalize-Entry -Entry $currentEntry -TargetList $currentSection.Entries
    }

    if ($currentSection) {
        if ($currentSection.Entries.Count -eq 0) {
            throw "A date section has no entries: $($currentSection.Label)"
        }
        $sections.Add($currentSection)
    }

    if ($sections.Count -eq 0) {
        throw 'No readings data was found to apply.'
    }

    return $sections
}

function Get-ExistingReadingSectionSpans {
    param([string]$RawText)

    $pattern = '(?m)^---------------\s+(\d{4}' + [regex]::Escape($TXT_YEAR) + '\s+\d{1,2}' + [regex]::Escape($TXT_MONTH) + '\s+\d{1,2}' + [regex]::Escape($TXT_DAY) + ')(?:\s+\S+)?\s+---------------'
    $matches = [regex]::Matches($RawText, $pattern)
    $spans = New-Object System.Collections.Generic.List[object]

    for ($i = 0; $i -lt $matches.Count; $i++) {
        $start = $matches[$i].Index
        $end = if ($i -lt ($matches.Count - 1)) { $matches[$i + 1].Index } else { $RawText.Length }
        $spans.Add([pscustomobject]@{
                Label = $matches[$i].Groups[1].Value
                Start = $start
                End = $end
            })
    }

    return $spans
}

function Build-ReadingSectionBlock {
    param([pscustomobject]$Section)

    $weekday = Get-WeekdayKorean $Section.Date
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("--------------- $($Section.Label) $weekday ---------------")
    $lines.Add(("[{0}] [{1} 9:00] <{2}.{3}{4} {5} >" -f $TXT_AGENT_NAME, $TXT_AM, $Section.Date.Month, $Section.Date.Day, $TXT_DAY, $TXT_MESSAGE_SUFFIX))
    $lines.Add('')

    for ($i = 0; $i -lt $Section.Entries.Count; $i++) {
        $entry = $Section.Entries[$i]
        $lines.Add(("[{0}]" -f $entry.Agency))
        $lines.Add($entry.Title)

        foreach ($detail in $entry.Details) {
            $lines.Add("- $detail")
        }

        foreach ($attachment in $entry.Attachments) {
            if ($attachment.Linked -and $attachment.Url) {
                $lines.Add(("* [{0}: {1}]({2})" -f $TXT_ATTACHMENT, $attachment.Label, $attachment.Url))
            }
            elseif ($attachment.Label) {
                $lines.Add(("* {0}: {1}" -f $TXT_ATTACHMENT, $attachment.Label))
            }
        }

        $lines.Add(("({0})" -f $entry.Link))
        if ($i -lt $Section.Entries.Count - 1) {
            $lines.Add('')
        }
    }

    return ($lines -join "`r`n").TrimEnd()
}

function Update-IndexHtmlFromMarkdown {
    param(
        [string]$MarkdownPath,
        [string]$HtmlPath
    )

    $sections = Parse-ReadingMarkdown -MarkdownPath $MarkdownPath
    $html = Read-Utf8File $HtmlPath
    $base64Match = [regex]::Match($html, "const RAW_TEXT_BASE64 = '([^']+)';")
    if (-not $base64Match.Success) {
        throw 'RAW_TEXT_BASE64 was not found in index.html.'
    }

    $rawText = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($base64Match.Groups[1].Value))
    $existingSectionMap = @{}
    foreach ($span in Get-ExistingReadingSectionSpans -RawText $rawText) {
        if (-not $existingSectionMap.ContainsKey($span.Label)) {
            $existingSectionMap[$span.Label] = $span
        }
    }

    $replacementItems = New-Object System.Collections.Generic.List[object]
    $newBlocks = New-Object System.Collections.Generic.List[string]
    $addedSummaries = New-Object System.Collections.Generic.List[string]
    $updatedSummaries = New-Object System.Collections.Generic.List[string]

    foreach ($section in $sections) {
        $block = Build-ReadingSectionBlock -Section $section
        if ($existingSectionMap.ContainsKey($section.Label)) {
            $existingSpan = $existingSectionMap[$section.Label]
            $replacementItems.Add([pscustomobject]@{
                    Start = [int]$existingSpan.Start
                    End = [int]$existingSpan.End
                    IsFinal = ([int]$existingSpan.End -eq $rawText.Length)
                    Block = $block
                })
            $updatedSummaries.Add("- Updated: $($section.Label) / $($section.Entries.Count) entries")
        }
        else {
            $newBlocks.Add($block)
            $addedSummaries.Add("- Added: $($section.Label) / $($section.Entries.Count) entries")
        }
    }

    if (($replacementItems.Count + $newBlocks.Count) -eq 0) {
        Write-Host 'No changes were required for index.html.'
        return
    }

    $updatedRawText = $rawText
    foreach ($item in ($replacementItems | Sort-Object Start -Descending)) {
        $replacementText = $item.Block.TrimEnd()
        if (-not $item.IsFinal) {
            $replacementText += "`r`n`r`n"
        }
        $updatedRawText = $updatedRawText.Remove($item.Start, $item.End - $item.Start).Insert($item.Start, $replacementText)
    }

    $updatedRawText = $updatedRawText.TrimEnd()
    if ($newBlocks.Count -gt 0) {
        if ($updatedRawText) {
            $updatedRawText += "`r`n`r`n"
        }
        $updatedRawText += ($newBlocks -join "`r`n`r`n")
    }
    $updatedRawText += "`r`n"

    $backupDir = Join-Path $scriptRootPath 'backup\index_backups'
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    $backupPath = Join-Path $backupDir ('index_{0}.html' -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
    Write-Utf8File -Path $backupPath -Content $html

    $newBase64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($updatedRawText))
    $updatedHtml = [regex]::Replace($html, "const RAW_TEXT_BASE64 = '([^']+)';", "const RAW_TEXT_BASE64 = '$newBase64';", 1)
    Write-Utf8File -Path $HtmlPath -Content $updatedHtml

    Write-Host 'index.html update finished.'
    Write-Host ('Backup created: ' + $backupPath)
    foreach ($summary in $updatedSummaries) {
        Write-Host $summary
    }
    foreach ($summary in $addedSummaries) {
        Write-Host $summary
    }
}

try {
    Write-Host 'Starting index.html update...'
    Write-Host ''

    $markdownPath = Join-Path $scriptRootPath $MARKDOWN_NAME
    $htmlPath = Join-Path $scriptRootPath 'index.html'

    if (-not (Test-Path -LiteralPath $markdownPath)) {
        throw ('Markdown file not found: ' + $markdownPath)
    }
    if (-not (Test-Path -LiteralPath $htmlPath)) {
        throw ('HTML file not found: ' + $htmlPath)
    }

    $markdownText = Read-Utf8File $markdownPath
    if (-not $markdownText.Contains($TXT_DATA_MARKER)) {
        throw 'The readings markdown file does not contain the expected data section.'
    }

    Update-IndexHtmlFromMarkdown -MarkdownPath $markdownPath -HtmlPath $htmlPath

    Write-Host ''
    Read-Host 'Press Enter to exit'
    exit 0
}
catch {
    Write-Host ''
    Write-Host ('Update failed: ' + $_.Exception.Message)
    Write-Host ''
    Read-Host 'Press Enter to exit'
    exit 1
}
