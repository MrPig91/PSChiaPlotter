enum KSize{
    K32 = 32
    K33 = 33
    K34 = 34
    K35 = 35
    K30 = 30
}

class MaximizedKSize {
    [KSize]$KSize
    [int]$MaxPlots
    [Decimal]$RemainingBytes
    [Decimal]$KSizeBytes
    [int64]$TotalBytes

    static [Decimal]$K35 = 884.1 * 1gb
    static [Decimal]$K34 = 429.8 * 1gb
    static [Decimal]$K33 = 208.8 * 1gb
    static [Decimal]$K32 = 101.4 * 1gb
    static [Decimal]$K30 = 23.9 * 1gb

    MaximizedKSize(
        [KSize]$KSize,
        [int64]$TotalBytes
    ){
        $this.KSize = $Ksize
        $this.TotalBytes = $TotalBytes

        $this.KSizeBytes = switch ($this.KSize){
            "K35" {[MaximizedKSize]::K35}
            "K34" {[MaximizedKSize]::K34}
            "K33" {[MaximizedKSize]::K33}
            "K32" {[MaximizedKSize]::K32}
            "K30" {[MaximizedKSize]::K30}
        }
        $this.MaxPlots = [math]::Floor([decimal]($this.TotalBytes / $this.KSizeBytes))
        $this.RemainingBytes = $Totalbytes - (([math]::Floor([decimal]($this.TotalBytes / $this.KSizeBytes))) * $this.KSizeBytes)
    }
}
