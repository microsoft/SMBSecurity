# This script will update the SMBSecurity Wiki using the PlatyPS generated MD files in SMBSecurity\docs
# Minor processing is performed to cleanup some of the PlatyPS formatting.


# code repo
$repo = 'https://github.com/microsoft/SMBSecurity.git'
$repoName = 'SMBSecurity'

# wiki repo
$wikiRepo = 'https://github.com/microsoft/SMBSecurity.wiki.git'

# the repo path where the PatyPS MD files will be
$mdPath = "docs"


# where the repos will be cloned
$clonePath = "D:\GitWikiClone"

$null = mkdir "$clonePath" -Force

## Do the work ##

# clone the repos
Push-Location "$clonePath"
git clone $repo
git clone $wikiRepo
Pop-Location



# get all the code cmdlet md files from PlayPS
$repoMdFiles = Get-ChildItem "$clonePath\$repoName\$mdPath" -Filter "*.md"

# get the matching MD files from the wiki
# Using [char]8208 is a workaround with Github Wiki pages to put a hyphen in the title as [char]45 does not appear in the title. So the comparison needs to compensate.
$wikiMdFiles = Get-ChildItem "$clonePath\$repoName.wiki\" -Filter "*.md" | Where-Object { ($_.Name.Replace([char]8208, [char]45)) -in $repoMdFiles.Name }

foreach ($wFile in $wikiMdFiles)
{
    $rFile = $repoMdFiles |  Where-Object { $_.Name -eq ($wFile.Name.Replace([char]8208, [char]45)) }

    if ($rFile)
    {
        Write-Host "Processing: $($wfile.Name)"
        
        # get the repo file contents
        $contents = Get-Content $rFile
        
        ## process the file
        # the first 7 lines are used by PlatyPS and not needed in the wiki
        $lines = $contents.Count - 7


        # get the content again, but only the needed lines
        # process the file, too
        $contents = Get-Content $rFile -Tail $lines | & {process {
            # remove "{{" and "}}"
            $tmp = ($_.replace('{{ ','')).replace(' }}','')

            $tmp
        }}

        # now add the modifies contents to the wiki page
        Set-Content -Path $wFile -Value $contents -Force

        Remove-Variable contents, lines, tmp -EA SilentlyContinue
    }

    Remove-Variable rFile -EA SilentlyContinue
}


# commit the changes
Push-Location "$clonePath\$repoName.wiki"
git commit -a -m "Docs Sync $((Get-Date).ToShortDateString())"
git push
Pop-Location

# cleanup the directories
$null = Remove-Item "$clonePath\$repoName.wiki" -Recurse -Force
$null = Remove-Item "$clonePath\$repoName" -Recurse -Force