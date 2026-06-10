# Henter kurshistorikk fra Yahoo Finance og lagrer som data.js
# Kjør dette skriptet for å oppdatere grafene med ferske tall.

$tickers = @(
    @{ symbol = "EQNR.OL"; navn = "Equinor" },
    @{ symbol = "YAR.OL";  navn = "Yara International" },
    @{ symbol = "NHY.OL";  navn = "Norsk Hydro" }
)

$resultat = [ordered]@{}

foreach ($t in $tickers) {
    Write-Host "Henter $($t.symbol)..."
    $url = "https://query1.finance.yahoo.com/v8/finance/chart/$($t.symbol)?range=2y&interval=1d"
    $svar = Invoke-RestMethod -Uri $url -Headers @{ "User-Agent" = "Mozilla/5.0" }
    $r = $svar.chart.result[0]

    $tider = $r.timestamp
    $kurser = $r.indicators.quote[0].close

    $punkter = @()
    for ($i = 0; $i -lt $tider.Count; $i++) {
        if ($null -ne $kurser[$i]) {
            $dato = ([DateTimeOffset]::FromUnixTimeSeconds($tider[$i])).ToString("yyyy-MM-dd")
            $punkter += ,@($dato, [math]::Round($kurser[$i], 2))
        }
    }

    $resultat[$t.symbol] = [ordered]@{
        navn      = $t.navn
        valuta    = $r.meta.currency
        sisteKurs = $r.meta.regularMarketPrice
        punkter   = $punkter
    }
}

$resultat["oppdatert"] = (Get-Date).ToString("yyyy-MM-dd HH:mm")

$json = $resultat | ConvertTo-Json -Depth 10 -Compress
$filsti = Join-Path $PSScriptRoot "data.js"
[System.IO.File]::WriteAllText($filsti, "window.AKSJEDATA = $json;", (New-Object System.Text.UTF8Encoding($false)))
Write-Host "Ferdig! Data lagret i data.js"
