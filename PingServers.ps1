Function PingIndicator {

    param(
        [parameter(mandatory=$true)][int]$ping
    )

    $pingMax = 500
    $pingTemp = $ping
    $indicator = $null
    $mod = 100

    for($i = 1; $i -lt $ping; $i++){
    
        if($i%$mod -eq 0 -and $pingTemp -ne 0){
            $indicator += "█"
            $pingTemp -= $mod
        } elseif($pingTemp -lt 100 -and $pingTemp -ne 0){

            if($pingTemp -in 0..25){
                $indicator += "_"
            } elseif($pingTemp -in 26..50){
                $indicator += "░"
            } elseif($pingTemp -in 51..75){
                $indicator += "▒"
            } elseif($pingTemp -in 76..100){
                $indicator += "▓"
            }
            $pingTemp = 0
        }
    }

    return $indicator
}

Function DisplayPingTable {

    param(
        [parameter(mandatory=$true)][array]$data,
        [switch]$ShowHeaders
    )


    $padding = 2
    $colWidths = ,0*$data[0].Keys.Count

    $i = 0
    foreach($key in $data[0].Keys){
        $colWidths[$i] = $key.Length
        $i++
    }

    foreach($row in $data){
        $i = 0
        foreach($value in $row.Values){
            if($value.Length -gt $colWidths[$i]){
                $colWidths[$i] = $value.Length
            }
            $i++
        }
    }

    $totalWidth = $($colWidths | Measure-Object -Sum).Sum

    if($ShowHeaders){
        $headers = $null
        $i = 0
        foreach($key in $data[0].Keys){
            $headers += $key+(" "*($colWidths[$i]-$key.Length+$padding))
            $i++
        }
        $headers

        $headers = $null
        $i = 0
        foreach($key in $data[0].Keys){
            $headers += "-"*$key.Length+(" "*($colWidths[$i]-$key.Length+$padding))
            $i++
        }
        $headers
    }

    foreach($item in $data){
        $row = $null
        $i = 0
        foreach($value in $item.Values){

            $row += $value+(" "*($colWidths[$i]-$value.Length+$padding))

            $i++
        }

        if($item.Ping.GetType().Name -eq [string])  {
            Write-Host $row -ForegroundColor White -BackgroundColor Red
        } elseif($item.Ping -in 0..100){
            Write-Host $row -ForegroundColor Green
        } elseif($item.Ping -in 101..150){
            Write-Host $row -ForegroundColor DarkGreen
        } elseif($item.Ping -in 151..199){
            Write-Host $row -ForegroundColor Yellow
        } elseif($item.Ping -in 200..299){
            Write-Host $row -ForegroundColor DarkYellow
        } elseif($item.Ping -in 300..399){
            Write-Host $row -ForegroundColor Red
        } elseif($item.Ping -ge 400) {
            Write-Host $row -ForegroundColor DarkRed
        }
    }
}

Function PingServers {

    param(
        [parameter(mandatory=$true)][System.Object[]]$ServerList
    )

    $pingtest = $serverList | ForEach-Object {
        Write-Host "Pinging $($_[0].'IP Address'.Trim())..." -ForegroundColor Gray
        Test-Connection -ComputerName $($_[0].'IP Address'.Trim()) -Count 1 -ErrorAction SilentlyContinue
    }

    [array]$dataTable = @()

    foreach($server in $serverList){

        $serverFound = $false
        $serverData = $null

        foreach($result in $pingtest){
            if($result.Address -eq $server.'IP Address'.Trim()){
                $serverFound = $true
                $serverData = $result
                break
            }
        }

        if($serverFound -eq $true){
            $tableRow = New-Object PSObject @{
                Server = $($server.Description.Trim())
                Ping = $($serverData.ResponseTime)
                Indicator = $(PingIndicator $($serverData.ResponseTime))
            }
        } else {
            $tableRow = New-Object PSObject @{
                Server = $($server.Description.Trim())
                Ping = "Ping Failed"
                Indicator = $null
            }
        }
        $dataTable += $tableRow
    }

    Write-Host "Ping Complete`n" -ForegroundColor Green

    return $dataTable

}

$servers = Import-Csv .\serverList.csv
DisplayPingTable $(PingServers $servers)