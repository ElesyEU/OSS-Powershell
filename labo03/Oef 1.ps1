clear-host
Find-Module *azure* -Tag 'ActiveDirectory' | Where-Object {$_.publisheddate -ge (get-date).addyears(-3) -and ([int]$_.additionalmetadata.downloadcount -ge 100000 )}