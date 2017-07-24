

Prereq: A clean site



# Create the settings file.
    ## Create a new API key with RW access to both content types and content items.
    ## Create a new settings-doccenter-%bldsite%.json file with the new API key. (Template: json\settings.json)
    ## Update dnnps.bat with the new value of %bldsite%.

# Content types
    ## To create content types in the new site, run newcontenttypes.bat.
    ## Verify that contenttypeids list is updated in settings-doccenter-*.json
    ## To add a new content type or update an existing one:
        ### In the green-room site, manually add a new content type or update an existing one.
        ### dnnps list-contenttypes
        ### contenttypes-raw2body.bat



PERSONS
# Create the content items for persons.
    dnnps add-persons



PERSONA BAR AND TABS

# Upload the image files to Assets.
    ## In Evoq, create a "Persona Bar menus" folder under the home folder of the site.
    ## Upload the following:
        scr-pbar-*png
        scr-pbtabs-*png

# Create the content items.
    dnnps add-images-pbar
    dnnps add-images-pbtabs
    dnnps list-all-type-images

    dnnps add-steps-pbar-menu
    dnnps add-steps-pbtabs
    dnnps list-all-type-steps



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

# Create the content items.
    dnnps add-images-logos
    dnnps list-all-type-images

    dnnps add-products-v85-v91
    dnnps add-products-v92
    dnnps list-all-type-products



OTHER CONTENT

# Upload the image files to Assets.
    ## Upload the remaining images.

# Create the content items.
    dnnps add-images-...
    dnnps list-all-type-images

    dnnps add-requisites-bptextdita
    dnnps list-all-type-requisites

    dnnps add-notes-bptextdita
    dnnps list-all-type-notes

    dnnps add-passages-bptextdita
    dnnps add-passages-bptextpbtabsdita
    dnnps list-all-type-passages




