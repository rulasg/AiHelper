function Get-AiMessageForCommit{
    [CmdletBinding()]
    param(
        [Parameter()]$Model = "openai/gpt-4o-mini"
    )

    $gitdifff = git diff --staged

    $instructions = Get-Instructions -Type CommitMessage

    $prompt = @()
    $prompt += "Propose a git commit message."
    $prompt += "Output just the message."
    $prompt += "Make the message a single line."
    $prompt += "Staged changes: $gitdifff"
    $prompt += "Follow these instructions: $instructions"

    
    gh models run $Model $prompt
} Export-ModuleMember -Function Get-AiMessageForCommit

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