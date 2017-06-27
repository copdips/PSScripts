1..10|Start-RSJob {
    if (1 -BAND $_){
        Write-Host $(1 -BAND $_)
        "First ($_ , $(1 -BAND $_))"
    }Else{
        Start-sleep -seconds 2
        "Last ($_)"
    }   dsff
}|Wait-RSJob|Receive-RSJob|ForEach{"I am $($_)"}
