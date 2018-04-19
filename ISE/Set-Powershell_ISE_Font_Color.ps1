# Sublime Text 3 like
# color code : http://htmlcolorcodes.com

Function Set-Powershell_ISE_Font_Color {    

	  $psISE.Options.FontName = 'Monaco'
    $psISE.Options.FontSize = 11
    $psISE.Options.ScriptPaneBackgroundColor = '#FF272822'
    $psISE.Options.TokenColors['Command'] = '#FFA6E22E'
    $psISE.Options.TokenColors['Unknown'] = '#FFF8F8F2'
    $psISE.Options.TokenColors['Member'] = ' #66b0ce'
    $psISE.Options.TokenColors['Position'] = '#FFF8F8F2'
    $psISE.Options.TokenColors['GroupEnd'] = '#FFF8F8F2'
    $psISE.Options.TokenColors['GroupStart'] = '#FFF8F8F2'
    $psISE.Options.TokenColors['LineContinuation'] = '#FFF8F8F2'
    $psISE.Options.TokenColors['NewLine'] = '#FFF8F8F2'
    $psISE.Options.TokenColors['StatementSeparator'] = '#FFF8F8F2'
    $psISE.Options.TokenColors['Comment'] = ' #4ca660'
    $psISE.Options.TokenColors['String'] = '#FFE6DB74'
    $psISE.Options.TokenColors['Keyword'] = '#FF66D9EF'
    $psISE.Options.TokenColors['Attribute'] = '#FFF8F8F2'
    $psISE.Options.TokenColors['Type'] = '#FFA6E22E'
    $psISE.Options.TokenColors['Variable'] = '#FFF8F8F2'
    $psISE.Options.TokenColors['CommandParameter'] = '#FFFD971F'
    $psISE.Options.TokenColors['CommandArgument'] = '#FFA6E22E'
    $psISE.Options.TokenColors['Number'] = '#FFAE81FF'
    $psISE.Options.TokenColors['Operator'] = '#FFF92672'
    
} 

Set-Powershell_ISE_Font_Color
