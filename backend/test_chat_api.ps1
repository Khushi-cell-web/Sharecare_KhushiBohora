param(
  [Parameter(Mandatory = $true)]
  [string]$Token,
  [Parameter(Mandatory = $true)]
  [int]$OtherUserId,
  [string]$BaseUrl = "http://127.0.0.1:8000",
  [string]$MessageText = "Hello from ShareCare chat test"
)

$ErrorActionPreference = "Stop"
$headers = @{
  "Authorization" = "Bearer $Token"
  "Content-Type"  = "application/json"
}

function Invoke-Api($Method, $Path, $BodyObj = $null) {
  $uri = "$BaseUrl$Path"
  if ($null -eq $BodyObj) {
    return Invoke-RestMethod -Method $Method -Uri $uri -Headers $headers
  }
  $json = $BodyObj | ConvertTo-Json -Depth 10
  return Invoke-RestMethod -Method $Method -Uri $uri -Headers $headers -Body $json
}

Write-Host "1) Create/Get room..." -ForegroundColor Cyan
$room = Invoke-Api "POST" "/api/chat/room/" @{ other_user_id = $OtherUserId }
$roomId = [int]$room.id
Write-Host "   room id: $roomId"

Write-Host "2) Send message..." -ForegroundColor Cyan
$sent = Invoke-Api "POST" "/api/chat/send/" @{ room_id = $roomId; text = $MessageText }
Write-Host "   message id: $($sent.id)"

Write-Host "3) Get messages..." -ForegroundColor Cyan
$messages = Invoke-Api "GET" "/api/chat/messages/$roomId/"
Write-Host "   total messages: $($messages.Count)"

Write-Host "4) Mark read..." -ForegroundColor Cyan
$read = Invoke-Api "POST" "/api/chat/read/" @{ room_id = $roomId }
Write-Host "   status: $($read.status)"

Write-Host "5) Get rooms..." -ForegroundColor Cyan
$rooms = Invoke-Api "GET" "/api/chat/rooms/"
Write-Host "   total rooms: $($rooms.Count)"

Write-Host ""
Write-Host "Chat API flow completed successfully." -ForegroundColor Green
