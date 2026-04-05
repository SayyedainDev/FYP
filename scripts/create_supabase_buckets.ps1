$SUPABASE_URL = "https://trectmuwolzkdalsrmud.supabase.co"
$SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRyZWN0bXV3b2x6a2RhbHNybXVkIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NTQxMjcxMywiZXhwIjoyMDkwOTg4NzEzfQ.0R-pKeGYgbMJndy8GJ0oFJfBjRsahdj11ohiiWnSJNY"
$headers = @{ Authorization = "Bearer $SERVICE_ROLE_KEY"; 'Content-Type' = 'application/json' }
$buckets = @('lecture-notes','scans','cases','quizzes','uploads','profile_photos','health_checks')

foreach ($b in $buckets) {
  Write-Output "Creating bucket: $b"
  $body = @{ name = $b; public = $true } | ConvertTo-Json
  try {
    $res = Invoke-RestMethod -Method Post -Uri "$SUPABASE_URL/storage/v1/buckets" -Headers $headers -Body $body
    Write-Output ("Created: " + $res.name)
  } catch {
    Write-Output ("Error creating {0}: {1}" -f $b, $_.Exception.Message)
  }
}

Write-Output "`nListing buckets:"
try {
  $list = Invoke-RestMethod -Method Get -Uri "$SUPABASE_URL/storage/v1/buckets" -Headers $headers
  $list | ConvertTo-Json -Depth 5 | Out-String | Write-Output
} catch {
  Write-Output ("Error listing buckets: {0}" -f $_.Exception.Message)
}
