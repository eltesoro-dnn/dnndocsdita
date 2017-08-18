

Prereq: A clean site



# Create the settings file.
    ## Create a new API key with RW access to both content types and content items.
    ## Create a new settings-doccenter-%bldsite%.json file with the new API key. (Template: json\settings.json)
    ## Update dnnps.bat with the new default value of %bldsite%. Or, at the command prompt, set bldsite=E911-133-XX

# Content types
    ## dnnps listall-contenttypes
    ## createcontenttypes.bat %bldsite%
    ## Verify that contenttypeids list is updated in settings-doccenter-%bldsite%.json
    ## (Maintenance) To add a new content type or update an existing one: refreshcontenttypes.bat


PERSONS
# Create the content items for contributors.
    dnnps add-persons-contributors
    dnnps listall-persons



PERSONA BAR AND TABS

# Upload the image files to Assets.
    ## In Evoq, create a "Persona Bar menus" folder under the home folder of the site.
    ## Upload the following:
        scr-pbar-*E91.png (27)
        scr-pbtabs-*.png
    ## Create a new assets-%bldsite%.txt and copy the URLs of each uploaded image (one per line) from the UI.

# Create the content items.
    dnnps add-images-pbar
    dnnps add-images-pbtabs
    dnnps listall-images

    dnnps add-steps-pbar-menu
    dnnps add-steps-pbtabs
    dnnps listall-steps



PRODUCT LOGOS

# Upload the image files to Assets.
    ## Upload the logo files:
        logo-DNN-platform.png
        logo-evoq-basic.png
        logo-evoq-basic.svg
        logo-evoq-content.png
        logo-evoq-content.svg
        logo-evoq-engage.png
        logo-evoq-engage.svg
    ## Copy the URLs of each uploaded image (one per line) from the UI to assets-%bldsite%.txt.

# Create the content items.
    dnnps add-images-logos
    dnnps listall-images

    dnnps add-products-v85-v91
    :. dnnps add-products-v92
    dnnps listall-products



LIQUID CONTENT APIS

# To create the content types (Note: The order is important.):
    webapi.bat ct add

# To create the content items (Note: The order is important.):
    webapi.bat ci add

# (Maintenance) To add additional APIs,
    ## Update _tools\mkapi\mkapimigration.ps1 and .bat. (See the $apitypes array to add other APIs and update GetAPIGroup().)
    ## Update jobs*.json to create a separate job for the new types and items.
    ## Run dnnps.bat to add the new content types and content items.



OTHER IMAGES

# Upload the image files to Assets.
    ## Upload the remaining images.
    ## Copy the URLs of each uploaded image (one per line) from the UI to assets-%bldsite%.txt.

# Create the content items.
    dnnps add-images-...
    dnnps listall-images



OTHER CONTENT

# Create the content items.

    dnnps add-requisites-bptextdita
    dnnps listall-requisites

    dnnps add-notes-bptextdita
    dnnps listall-notes

    dnnps add-passages-bptextdita
    dnnps add-passages-bptextpbtabsdita
    dnnps listall-passages



VISUALIZERS
# Import the visualizers (visualizers\Vis*.zip)
