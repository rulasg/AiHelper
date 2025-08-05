function Get-AiMessageForCommit{
    [CmdletBinding()]
    [alias("aicm")]
    param(
        [Parameter()]$Model = "openai/gpt-4.1",
        [Parameter()]$Prompt
    )

    $gitdifff = git diff --staged

    if ([string]::IsNullOrWhiteSpace($gitdifff)) {
        Write-Host "No staged changes found. Please stage your changes before generating a commit message." -ForegroundColor Yellow
        return $null
    }

    $instructions = Get-Instructions -Type CommitMessage

    if ($null -eq $instructions) {
        Write-Verbose "No instructions found at .github/$instFileName. Using default commit message format."
    } else {
        Write-Verbose "Instructions: .github [$($instructions.Length)] characters."
    }

    $p = @()
    $p += "Follow these instructions: [ $instructions ]"
    $sysPrompt = $p -join "`n"
    
    $p = @()
    $p += "Propose a git commit message."
    $p += "Output just the message."
    $p += "Make the message a single line."
    $p += "Result of git diff --staged: [ $gitdifff ]"
    $p += "User description of the changes: [ $Prompt ]"
    $usrprompt = $p -join "`n"

    Write-Verbose "Module: $Model"
    Write-Verbose "SysPrompt: $sysPrompt"
    Write-Verbose "UsrPrompt: $usrprompt"

    $message = gh models run $Model "$usrprompt" --system-prompt $sysPrompt

    $global:message = $message | Out-String

    return $message

} Export-ModuleMember -Function Get-AiMessageForCommit -Alias aicm

function Get-Instructions{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("CommitMessage", "CodeInstructions", "PrDescription")]
        [string]$Type

    )
        switch ($Type) {
            CommitMessage    { $instFileName = "copilot-commit-message-instructions.md" ; break }
            CodeInstructions { $instFileName = "copilot-instructions.md" ; break }
            PrDescription    { $instFileName = "copilot-pull-request-description-instructions.md" ; break }
        }

        $instructionsPath = ".github" | Join-Path -ChildPath $instFileName

        if (Test-Path $instructionsPath) {
            $content = Get-Content -Path $instructionsPath -Raw
            return $content
        }
        
        return $null
}