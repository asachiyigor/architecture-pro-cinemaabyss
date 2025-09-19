# Circuit Breaker Statistics Dashboard
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "=== ENVOY CIRCUIT BREAKER STATISTICS ===" -ForegroundColor Green
Write-Host "Date: $(Get-Date)" -ForegroundColor Gray
Write-Host ""

$ENVOY_STATS_URL = "http://localhost:15000/stats"

Write-Host "Connection Pool Status:" -ForegroundColor Yellow
Write-Host "   Max Connections Limit: 10" -ForegroundColor White

try {
    $stats = Invoke-RestMethod -Uri $ENVOY_STATS_URL -Method Get
    $remaining_cx = ($stats -split "`n" | Where-Object { $_ -match "remaining_cx:" }).Split(":")[1].Trim()
    $cx_open = ($stats -split "`n" | Where-Object { $_ -match "cx_open:" }).Split(":")[1].Trim()

    Write-Host "   Remaining Connections: $remaining_cx" -ForegroundColor White
    if ($cx_open -eq "1") {
        Write-Host "   Circuit Breaker Open: YES - ACTIVATED" -ForegroundColor Red
    } else {
        Write-Host "   Circuit Breaker Open: NO" -ForegroundColor Green
    }
} catch {
    Write-Host "   Error connecting to Envoy admin interface" -ForegroundColor Red
}

Write-Host ""
Write-Host "Request Queue Status:" -ForegroundColor Yellow
try {
    $remaining_pending = ($stats -split "`n" | Where-Object { $_ -match "remaining_pending:" }).Split(":")[1].Trim()
    $pending_active = ($stats -split "`n" | Where-Object { $_ -match "pending_active:" }).Split(":")[1].Trim()

    Write-Host "   Max Pending Requests Limit: 10" -ForegroundColor White
    Write-Host "   Remaining Pending Slots: $remaining_pending" -ForegroundColor White
    Write-Host "   Currently Pending: $pending_active" -ForegroundColor White
} catch {
    Write-Host "   Error reading pending stats" -ForegroundColor Red
}

Write-Host ""
Write-Host "Circuit Breaker Activation Metrics:" -ForegroundColor Red
try {
    $pending_overflow = ($stats -split "`n" | Where-Object { $_ -match "pending_overflow:" }).Split(":")[1].Trim()
    $pending_total = ($stats -split "`n" | Where-Object { $_ -match "pending_total:" }).Split(":")[1].Trim()

    Write-Host "   Times Circuit Breaker Activated: $pending_overflow" -ForegroundColor Red
    Write-Host "   Total Pending Requests Ever: $pending_total" -ForegroundColor White
} catch {
    Write-Host "   Error reading activation metrics" -ForegroundColor Red
}

Write-Host ""
Write-Host "Request Success/Failure Ratio:" -ForegroundColor Cyan
try {
    $total_requests = ($stats -split "`n" | Where-Object { $_ -match "upstream_rq_total:" }).Split(":")[1].Trim()
    $successful_200 = ($stats -split "`n" | Where-Object { $_ -match "upstream_rq_200:" }).Split(":")[1].Trim()
    $rejected_503 = ($stats -split "`n" | Where-Object { $_ -match "upstream_rq_503:" }).Split(":")[1].Trim()

    Write-Host "   Total Requests: $total_requests" -ForegroundColor White
    Write-Host "   Successful (200): $successful_200" -ForegroundColor Green
    Write-Host "   Circuit Breaker Rejected (503): $rejected_503" -ForegroundColor Red
} catch {
    Write-Host "   Error reading request stats" -ForegroundColor Red
}

Write-Host ""
Write-Host "Protection Status:" -ForegroundColor Magenta
try {
    if ([int]$pending_overflow -gt 0) {
        $percentage = [math]::Round(([int]$rejected_503 * 100 / [int]$total_requests), 2)
        Write-Host "   CIRCUIT BREAKER ACTIVE" -ForegroundColor Red
        Write-Host "   Rejected $rejected_503 out of $total_requests requests ($percentage percent)" -ForegroundColor Red
        Write-Host "   System protected from overload" -ForegroundColor Green
    } else {
        Write-Host "   Circuit Breaker Standby (no overload detected)" -ForegroundColor Green
    }
} catch {
    Write-Host "   Error calculating protection status" -ForegroundColor Red
}

Write-Host ""
Write-Host "Quick Commands:" -ForegroundColor Blue
Write-Host "   kubectl exec -n cinemaabyss fortio-xxx -c fortio --" -ForegroundColor Gray
Write-Host "     fortio load -c 50 -n 500 http://envoy-proxy:8081/api/movies" -ForegroundColor Gray
Write-Host ""
Write-Host "=== END OF CIRCUIT BREAKER DASHBOARD ===" -ForegroundColor Green