URLMAP generates a web.config file with rules that map old (relative) URLs to new ones.

Steps:
1. Update DC-URLmapping.xlsx to add new-old URLs. Just copy the formulas in the first two columns to generate a unique rulename.
2. Copy Columns B-D to urlmap.txt. Delete the header line.
3. Run urlmap.bat. (It will skip lines that have nothing in the "old" column.)
4. Edit the resulting web.config to replace [[ and ]] with < and >, respectively.
5. Copy the web.config to the _content folder of your DITA\DNN.DocCenter folder. (Or to the root of the docs folder in the staging server.)
6. Run urlmaptest.bat to open each "old" url. It opens up a new browser tab. You have to manually verify that the "new" page comes up. (BUGBUG: Verification needs to be automated.)
