Clear-Host

Find-Module *Azure* | Where-Object {($_.publisheddate -ge (get-date).addyears(-3)) -and ([int]($_.additionalmetadata.downloadcount) -ge 100000) -and ($_.tags.split() -contains "ActiveDirectory")}

install-module azuread -scope CurrentUser

