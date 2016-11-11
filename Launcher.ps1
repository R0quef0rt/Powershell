## Prompt the user to send password over email or SMS
$title = "Send Method"
$message = "Will you send this message to email or SMS?"
$emailchannel = New-Object System.Management.Automation.Host.ChoiceDescription "&Email", `
    "Sends a brief message to an email address."
$smschannel = New-Object System.Management.Automation.Host.ChoiceDescription "&SMS", `
    "Sends a brief text message to a phone."
$options = [System.Management.Automation.Host.ChoiceDescription[]]($emailchannel, $smschannel)
$result = $host.ui.PromptForChoice($title, $message, $options, 0)
 
switch ($result)
    {
        0 {"The message will be sent by email."}
        1 {"The message will be sent by SMS."}
    }
