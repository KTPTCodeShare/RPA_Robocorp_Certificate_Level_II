*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.Dialogs
Library             RPA.Robocorp.Vault


*** Tasks ***
Orders robots from RobotSpareBin Industries Inc.
    ${csvurl}=    Get The CSV URL
    #https://robotsparebinindustries.com/orders.csv

    Open the robot order website
    Download csv file    ${csvurl}
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Wait Until Keyword Succeeds    10x    2s    Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts

    Close The Browser
    Get The Developer Name From The Vault


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Download csv file
    [Arguments]    ${url}
    #Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    Download    ${url}    overwrite=True

Get orders
    ${table}=    Read table from CSV    orders.csv
    RETURN    ${table}

Close the annoying modal
    Wait And Click Button    css:#root > div > div.modal > div > div > div > div > div > button.btn.btn-warning

Fill the form
    [Arguments]    ${row}
    Wait Until Element Is Enabled    //*[@id="head"]
    Select From List By Value    head    ${row}[Head]
    Wait Until Element Is Enabled    body
    Select Radio Button    body    ${row}[Body]
    Wait Until Element Is Enabled    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input
    Input Text    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${row}[Legs]
    Wait Until Element Is Enabled    //*[@id="address"]
    Input Text    address    ${row}[Address]

Preview the robot
    Click Button    preview
    Wait Until Element Is Visible    //*[@id="robot-preview-image"]

Submit the order
    Click Button    //*[@id="order"]
    Page Should Contain Element    //*[@id="receipt"]

Store the receipt as a PDF file
    [Arguments]    ${ordernumber}
    Wait Until Element Is Visible    //*[@id="receipt"]
    ${order_receipt_html}=    Get Element Attribute    //*[@id="receipt"]    outerHTML
    Set Local Variable    ${FinalPDF}    ${CURDIR}${/}pdf_files${/}${ORDER_NUMBER}.pdf
    Html To Pdf    content=${order_receipt_html}    output_path=${FinalPDF}
    RETURN    ${FinalPDF}

Take a screenshot of the robot
    [Arguments]    ${ordernumber}
    Wait Until Element Is Visible    //*[@id="robot-preview-image"]
    #Wait Until Element Is Visible    xpath://html/body/div/div/div[1]/div/div[1]/div/div/p[1]
    #${orderid}=    Get Text    //*[@id="receipt"]/p[1]
    #Set Local Variable    ${TempIMG}    ${OUTPUT_DIR}${/}${orderid}.png
    Set Local Variable    ${TempIMG}    ${CURDIR}${/}image_files${/}${ordernumber}.png
    #Sleep    3sec
    Capture Element Screenshot    //*[@id="robot-preview-image"]    ${TempIMG}
    RETURN    ${TempIMG}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${IMG_FILE}    ${PDF_FILE}
    ${APDFOrder}=    Open PDF    ${PDF_FILE}
    @{myfiles}=    Create List    ${IMG_FILE}:align=center
    Add Files To PDF    ${myfiles}    ${PDF_FILE}    ${True}
    Close PDF    ${APDFOrder}

Go to order another robot
    Click Button When Visible    //*[@id="order-another"]

Create a ZIP file of the receipts
    #${zip_file_name}=    Set Variable    ${OUTPUT_DIR}${/}all_receipts.zip
    #Archive Folder With Zip    ${OUTPUT_DIR}${/}receipts    ${zip_file_name}
    Archive Folder With ZIP
    ...    ${CURDIR}${/}pdf_files
    ...    ${OUTPUT_DIR}${/}pdf_archive.zip
    ...    recursive=True
    ...    include=*.pdf

Get The CSV URL
    Add heading
    ...    Please provide a link to your csv file. Hint: Copy and Paste: https://robotsparebinindustries.com/orders.csv
    Add text input    mycsvfileurl
    ${result}=    Run dialog
    RETURN    ${result.mycsvfileurl}

Get The Developer Name From The Vault
    ${secret}=    Get Secret    credentials
    # Note: In real robots, you should not print secrets to the log.
    # This is just for demonstration purposes. :)
    Log    ${secret}[DeveloperName]

Close The Browser
    Close Browser
