class OptimizedKPlots {
    [int]$K35
    [int]$K34
    [int]$K33
    [int]$K32
    [decimal]$RemainingBytes
    [double]$RemainingGB

    OptimizedKPlots (
        [int]$K35,
        [int]$K34,
        [int]$K33,
        [int64]$Totalbytes
    ){
        $sizeremaining = $TotalBytes - (($K35 * [MaximizedKSize]::K35) + ($K34 * [MaximizedKSize]::K34) + ($K33 * [MaximizedKSize]::K33))
        $k32max = Get-MaxKSize -Totalbytes $sizeremaining -KSize "K32"
        $this.K35 = $K35
        $this.K34 = $K34
        $this.K33 = $K33
        $this.K32 = $k32max.MaxPlots
        $this.RemainingBytes = $k32max.RemainingBytes
        $this.RemainingGB = [math]::Round($k32max.RemainingBytes / 1gb,2)
    }
}