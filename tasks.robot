*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium
Library             RPA.HTTP
Library             RPA.Excel.Files
Library             RPA.PDF
Library             RPA.Tables
Library             RPA.Archive


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    [Setup]    Open the robot order website
    ${orders}=    Get Orders

    FOR    ${order}    IN    @{orders}
        Log To Console    ${order}
        Click Button    class:btn-dark
        Fill The Form    ${order}
        Click Button    id:preview
        ${screenshot}=    Take a screenshot of the robot    ${order}[Order number]
        Click Button    id:order
        ${status}=    Run Keyword And Return Status    Wait Until Element Is Visible    id:receipt
        WHILE    ${status} == False
            Reload Page
            Click Button    class:btn-dark
            Fill The Form    ${order}
            Click Button    id:preview
            ${screenshot}=    Take a screenshot of the robot    ${order}[Order number]
            Click Button    id:order
            ${status}=    Run Keyword And Return Status    Wait Until Element Is Visible    id:receipt
        END

        ${pdf}=    Store the receipt as a PDF file    ${order}[Order number]

        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Click Button    id:order-another
    END
    Create ZIP package from PDF files
    [Teardown]    Close Browser


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Get Orders
    Download    https://robotsparebinindustries.com/orders.csv
    ${table}=    Read table from CSV    orders.csv
    Log    Found columns: ${table.columns}
    RETURN    ${table}

Fill The Form
    [Arguments]    ${order_row}
    Select From List By Value    head    ${order_row}[Head]
    Click Element    //input[@name="body" and @value="${order_row}[Body]"]
    Input Text    //input[@placeholder="Enter the part number for the legs"]    ${order_row}[Legs]
    Input Text    id:address    ${order_row}[Address]

Store the receipt as a PDF file
    [Arguments]    ${id_order}
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    ${pdf_file}=    Set Variable    ${OUTPUT_DIR}${/}receipts${/}receipt_${id_order}.pdf
    Html To Pdf    ${receipt_html}    ${pdf_file}
    RETURN    ${pdf_file}

Take a screenshot of the robot
    [Arguments]    ${id_order}
    ${image}=    Set Variable    ${OUTPUT_DIR}${/}screenshots${/}robot_${id_order}.png
    Screenshot    id:robot-preview-image    ${image}
    RETURN    ${image}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${print}    ${file}
    Open PDF    ${file}
    ${image_file}=    Create List    ${print}:align=center
    Add Files To PDF    ${image_file}    ${file}    append=True
    Close Pdf    ${file}

Create ZIP package from PDF files
    Archive Folder With Zip    ${OUTPUT_DIR}${/}receipts    ${OUTPUT_DIR}/PDFs.zip
