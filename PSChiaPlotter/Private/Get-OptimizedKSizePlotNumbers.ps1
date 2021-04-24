function Get-OptimizedKSizePlotNumbers {
    [CmdletBinding()]
    param(
        [MaximizedKSize[]]$MaximizedKSize
    )

    foreach ($size in $MaximizedKSize){
        switch ($size.KSize){
            "K32" {
                [OptimizedKPlots]::new(0,0,0,$Size.TotalBytes)
            }

            "K33" {
                for ($K33Count = 1; $K33Count -le $size.MaxPlots; $K33Count++){
                    [OptimizedKPlots]::new(0,0,$K33Count,$Size.TotalBytes)
                } #for
            }
            "K34" {
                for ($K34Count = 1; $K34Count -le $size.maxplots; $K34Count++){
                    [OptimizedKPlots]::new(0,$K34Count,0,$Size.TotalBytes)

                    $k34sizeremaining = $Size.TotalBytes - ($K34Count * $size.KSizeBytes)
                    $K33Max = Get-MaxKSize -TotalBytes $k34sizeremaining -KSize "K33"
                    for ($k33 = 1; $k33 -le $k33max.MaxPlots; $k33++){
                        [OptimizedKPlots]::new(0,$K34Count,$k33,$Size.TotalBytes)
                    } #for 33
                } #for 34
            } #34

            "K35" {
                for ($k35count = 1; $k35count -le $size.maxplots; $k35count++){

                    [OptimizedKPlots]::new($k35count,0,0,$Size.TotalBytes)

                    $k35sizeremaining = $Size.TotalBytes - ($k35count * $size.KSizeBytes)
                    $k33max = Get-MaxKSize -Totalbytes $k35sizeremaining -KSize "K33"

                    for ($k33 = 1; $k33 -le $k33max.MaxPlots; $k33++){
                        [OptimizedKPlots]::new($k35count,0,$k33,$Size.TotalBytes)
                    } #for 33

                    $k34max = Get-MaxKSize -Totalbytes $k35sizeremaining -KSize "K34"
                    for ($k34 = 1; $k34 -le $k34max.maxplots; $k34++){
                        [OptimizedKPlots]::new($k35count,$k34,0,$Size.TotalBytes)

                        $sizeremaining = $Size.TotalBytes - (($k35count * $size.KSizeBytes) + ($k34 * $k34max.KSizeBytes))
                        $K33max = Get-MaxKSize -TotalBytes $sizeremaining -KSize "K33"

                        for ($k33 = 1;$k33 -le $k33max.maxplots; $k33++){
                            [OptimizedKPlots]::new($k35count,$k34,$k33,$Size.TotalBytes)
                        }
                    }
                }
            }
        } #switch
    } #foreach
}