function choose-carrier {

    Write-Host "Configuring SMS gateway..."

    $carriertitle = "SMS Carrier"

    $carriermessage = "Which carrier will you send this SMS message to?"

    $verizon = New-Object System.Management.Automation.Host.ChoiceDescription "&Verizon", `
        "Sends a message to a Verizon phone."

    $ATT = New-Object System.Management.Automation.Host.ChoiceDescription "&ATT", `
        "Sends a message to a AT&T phone."

    $tmobile = New-Object System.Management.Automation.Host.ChoiceDescription "&T-Mobile", `
        "Sends a message to a T-Mobile phone."

    $sprint = New-Object System.Management.Automation.Host.ChoiceDescription "&Sprint", `
        "Sends a message to a Sprint phone."

    $other = New-Object System.Management.Automation.Host.ChoiceDescription "&Other", `
        "Sends a message to a different carrier."

    $carrieroptions = [System.Management.Automation.Host.ChoiceDescription[]]($verizon, $ATT, $tmobile, $sprint, $other)

    $carrierresult = $host.ui.PromptForChoice($carriertitle, $carriermessage, $carrieroptions, 0) 

    switch ($carrierresult)
        {
            0 {$SMSSuffix = "vtext.com"}
            1 {$SMSSuffix = "txt.att.net"}
            2 {$SMSSuffix = "tmomail.net"}
            3 {$SMSSuffix = "messaging.sprintpcs.com"}
            4 {$SMSSuffix = Read-Host -Prompt "Set the SMS gateway manually"}
        }
}
