## This script exports AD Users to CSV

Get-ADUser -Filter "company -like 'Company Name*'" -Properties DisplayName, Givenname, Surname, EmailAddress, Title, Department, City, st, mobile, telephoneNumber, facsimileTelephoneNumber, enabled | select DisplayName, Givenname, Surname, EmailAddress, Title, Department, City, st, mobile, telephoneNumber, facsimileTelephoneNumber, enabled | Export-CSV ".\Reports\Users.csv"
