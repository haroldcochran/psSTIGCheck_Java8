# psSTIGCheck_Java8
A PowerShell script to check a Java 8 deployment against DoD STIGs

Defaults to an unclassified scan.
Skip N/A items for classified systems with the -ClassifiedNetwork switch.
Example: jre8_STIG.ps1 -ClassifiedNetwork $True
