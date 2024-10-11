<#
.SYNOPSIS
This script contains various functions for PowerShell profile customization.

.DESCRIPTION
The PowerShell profile script contains the following functions:
- cbt: Cleans, builds, and tests .NET solutions.
- gprune: Fetches and prunes Git branches, and deletes branches that have been deleted on the remote repository.
- gpr: Grade a PR using change-summary.sh, exclude tests by default. 
- gprt: Grade a PR using change-summary.sh, include tests.
- ggraph: Displays a graph of the Git commit history.
- glog: Displays commits in a target branch that are not in a base branch.

.NOTES

#>
function cbt {
  $sln = Get-ChildItem -Path .\ -Filter *.sln -Recurse -File -Name
  dotnet clean $sln;
  dotnet build $sln;
  dotnet test $sln -p:CollectCoverage=true -e:CoverletOutputFormat=lcov -e:CoverletOutput=./lcov.info;
}
  
function gprune {
  param
  (
    [switch]$f
  )
  
  # Git fetch with prune
  git fetch --prune
  
  # Get the list of branches and their tracking status
  $branches = git branch -vv
      
  # Filter out branches that have been deleted on the remote repository
  $deletedBranches = $branches | Select-String ': gone]' | Select-Object -ExpandProperty Line
      
  # Filter out the current branch
  $filteredBranches = $deletedBranches | Select-String -Pattern '^\*' -NotMatch | Select-Object -ExpandProperty Line
      
  # Extract the branch names
  $branchNames = $filteredBranches | ForEach-Object { ($_ -split ' ')[2] }
      
  # Delete the branches
  if ($f) {
    Write-Output "Force deleting git branches: $branchNames"
    $branchNames | ForEach-Object { git branch -D $_ }
  }
  else {
    Write-Output "Deleting git branches: $branchNames"
    $branchNames | ForEach-Object { git branch -d $_ }
  }
}
  
function gpr {
  $BRANCH = $args[0]
  bash ("/mnt/" + (get-item $profile).Directory.FullName.Replace("C:", "c").Replace("\", "/") + "/change-summary.sh") $BRANCH
}
  
function gprt {
  bash ("/mnt/" + (get-item $profile).Directory.FullName.Replace("C:", "c").Replace("\", "/") + '/change-summary.sh') "test"
}
  
function ggraph {
  git log --graph --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%an%C(reset)%C(bold yellow)%d%C(reset) %C(dim white)- %s%C(reset)' --all
}
  
function glog([string]$base, [string]$target) {
  if ([string]::IsNullOrEmpty($base)) {
    Write-Host "Please provide a value for the base branch."
    return
  }
  if ([string]::IsNullOrEmpty($target)) {
    Write-Host "Please provide a value for the target branch."
    return
  }
  
  $cmd = "git log --pretty=oneline $base..$target --merges --grep='Merge pull'"
  
  Write-Host "Commits in $target that are not in $base :"
  Invoke-Expression "& $cmd"
}

<#
Launches the Brave browser with CORS disabled.

.DESCRIPTION
This function starts the Brave browser with a specified URL and disables web security to bypass CORS restrictions. 
If no URL is provided, it defaults to "https://localhost:8080".

.PARAMETER url
The URL to open in the Brave browser. If not specified, defaults to "https://localhost:8080".

.EXAMPLE
brave_no_cors "https://example.com"
This will open the Brave browser with CORS disabled and navigate to "https://example.com".

.EXAMPLE
brave_no_cors
This will open the Brave browser with CORS disabled and navigate to "https://localhost:8080".
#>
function brave_no_cors([string] $url) {
  if ($url -eq $null -or $url -eq "") {
    $url = "https://localhost:8080"
  }
  $argList = '--user-data-dir="c://Chrome dev session" --disable-web-security "{0}"' -f $url

  Start-Process brave -ArgumentList $argList
}
  
#oh-my-posh: Initializes oh-my-posh with a specific shell and configuration.
# --- https://ohmyposh.dev/docs/installation/windows ---
# update the configuration file path to match the location of your configuration file, reference here to hanselman as an example
oh-my-posh --init --shell pwsh --config "hanselman.json" | Invoke-Expression
  
# Import the Terminal-Icons module to enable icons in the terminal.
Import-Module -Name Terminal-Icons
  
# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}
  
  
# PowerShell parameter completion shim for the dotnet CLI
Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
  param($commandName, $wordToComplete, $cursorPosition)
  dotnet complete --position $cursorPosition "$wordToComplete" | ForEach-Object {
    [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
  }
}
  
# Import the Posh-Git module 
Import-Module Posh-Git
  
# Import the DockerCompletion module
Import-Module DockerCompletion
  
$env:PYTHONIOENCODING = 'utf-8' 
#iex: Executes the alias for the `thefuck` command.
# --- https://github.com/nvbn/thefuck ---
iex "$(thefuck --alias)"
  