# detection method
Get-WmiObject -Class Win32_QuickFixEngineering | Where-Object { $_.HotFixId -eq 'KB1234567' }
