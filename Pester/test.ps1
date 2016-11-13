function add {
    param(
        [int]$a,
        [int]$b
    )
    
    $sum=$a+$b
    $sum
}


function Add-Footer($path, $footer) {
    Add-Content $path -Value $footer
}

