function Get-ChiaTempSize{
    [CmdletBinding()]
    param(
        $DirectoryPath,
        $PlotId
    )
    try{
        if ($PlotId -ne $null){
            try{
                #this will actually get the size on disk
                $tepmSize = (Get-ChildItem -Path $DirectoryPath -Filter "*$plotid*.tmp" | foreach {[Disk.Size]::SizeOnDisk($_.FullName)} | measure -Sum).Sum
                return [math]::Round($tepmSize / 1gb)
            }
            catch{
                $tepmSize = (Get-ChildItem -Path $DirectoryPath -Filter "*$plotid*.tmp" | Measure-Object -Property Length -Sum).Sum
                return [math]::Round($tepmSize / 1gb)
            }
        }
        else{
            return 0
        }
    }
    catch{
        return 0
    }
}