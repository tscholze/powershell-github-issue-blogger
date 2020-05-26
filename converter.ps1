# Setup YOUR properties

$Author = "John Doe"
$Quote = "We can only see a short distance ahead, but we can see plenty there that needs to done.\n\n-Adam Touring"
$GitHubUser = "tscholze"
$GitHubRepository = "xamarin-road-to-surface-duo"
$Twitter = "tobonaut"



# Define constants
Set-Variable GeneratedPath -Option Constant -Value "docs"
Set-Variable ListFileName -Option Constant -Value "index.html"
Set-Variable ListTemplatePath -Option Constant -Value "./templates/list-template.html"
Set-Variable ListItemTemplatePath -Option Constant -Value "./templates/list-item-template.html"
Set-Variable PostTemplatePath -Option Constant -Value "./templates/detail-template.html"

function Get-FilePath {
    [CmdletBinding()]
    [OutputType("String")]
    param(
        [Parameter(
            Mandatory = $True, 
            Position = 0, 
            ValueFromPipeline = $True, 
            HelpMessage = "Gets a slug-able file-path from XML element"
        )]
        [System.Xml.XmlElement]
        $Element
    )
    process {
        $slug = ($Element.guid.InnerText -split "/")[-1]
        "$slug.html"
    }
}

function New-ListItem {
    <#
    .SYNOPSIS
        Converts a given xml element into a styled blog post list item.

    .DESCRIPTION
        Converts a given xml element into a template-based styled post list
        item content string.

        It uses the template located in `templates/list-item-template.html`.

    .PARAMETER Element
        Underlying XML Element object that will be converted
    #>
    [CmdletBinding()]
    [OutputType("String")]
    param(
        [Parameter(
            Mandatory = $True, 
            Position = 0, 
            ValueFromPipeline = $True, 
            HelpMessage = "XML object to convert into a templated list item."
        )]
        [System.Xml.XmlElement]
        $Element
    )

    process {
        # Get template
        $template = Get-Content -Path $ListItemTemplatePath

        # Update template with xml element values
        $template = $template -replace "{{ title }}", $Element.title.InnerText
        $template = $template -replace "{{ content }}", $Element.description.InnerText
        $template = $template -replace "{{ link }}", (Get-FilePath -Element $Element)

        # Return the populated template.
        $template
    }
}

function New-List {
    <#
    .SYNOPSIS
        Creates a new list html file for given XMLElement.

    .DESCRIPTION
        Converts a given xml element into a template-based styled blog post
        list content html file.

        Paths:
            - It uses the template located in `templates/list-template.html`.

    .PARAMETER Element
        Underlying XML Element object that will be converted
    #>
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $True, 
            Position = 0, 
            ValueFromPipeline = $True, 
            HelpMessage = "XML object to convert into a templated list."
        )]
        [System.Xml.XmlElement]
        $Element
    )
    process {
        # Get template
        $template = Get-Content -Path $ListTemplatePath

        # Get content (list items)
        $content = ""

        foreach ($item in $Element.item) {
            $content += New-ListItem $item
        }

        # Update template with xml element values
        $template = $template -replace "{{ author }}", $Author
        $template = $template -replace "{{ quote }}", $Quote
        $template = $template -replace "{{ github }}", $GitHubUser
        $template = $template -replace "{{ twitter }}", $Twitter
        $template = $template -replace "{{ content }}", $content

        $template | Out-File -FilePath "$GeneratedPath/index.html"
    }
}

function New-Post {
    <#
    .SYNOPSIS
        Converts a given xml element into a styled blog post html file.

    .DESCRIPTION
        Converts a given xml element into a template-based styled blog post
        content html file.

        Paths:
            - It uses the template located in `templates/detail-template.html`.
            - It stores the template using the slug-able guid of the element 
                in `./docs`

    .PARAMETER Element
        Underlying XML Element object that will be converted
    #>
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $True, 
            Position = 0, 
            ValueFromPipeline = $True, 
            HelpMessage = "XML object to convert into a templated post"
        )]
        [System.Xml.XmlElement]
        $Element
    )
    
    process {
        # Get template
        $template = Get-Content -Path $PostTemplatePath

        # Update template with xml element values
        $template = $template -replace "{{ title }}", $Element.title.InnerText
        $template = $template -replace "{{ content }}", $Element.description.InnerText

        $path = "docs/" + (Get-FilePath -Element $Element)
        $template | Out-File -FilePath $path
    }
}


# Load information from web service
$response = Invoke-WebRequest -Uri  "https://rsshub.app/github/issue/tscholze/xamarin-road-to-surface-duo/all"

# Convert it into a xml document
[xml]$xml = $response.Content 

# Create list
New-List $xml.rss.channel

# Create post pages (detail)
ForEach ($msg in $xml.rss.channel.item) {
    (New-Post $msg)
}