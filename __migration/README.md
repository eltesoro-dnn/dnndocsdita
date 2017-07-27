

Prereq: A clean site



# Create the settings file.
    ## Create a new API key with RW access to both content types and content items.
    ## Create a new settings-doccenter-%bldsite%.json file with the new API key. (Template: json\settings.json)
    ## Update dnnps.bat with the new value of %bldsite%.

# Content types
    ## dnnps listall-contenttypes
    ## createcontenttypes.bat
    ## Verify that contenttypeids list is updated in settings-doccenter-*.json
    ## (Maintenance) To add a new content type or update an existing one:
        ### In the green-room site, manually add a new content type or update an existing one.
        ### dnnps listall-contenttypes (to generate raw.out)
        ### contenttypes-raw2body.bat (to update jobs-contenttypes.json )
        ### Update createcontenttypes.bat with the new content type, if any.
        ### dnnps add-contenttype-nameofnewtype
        ### dnnps update-contenttype-nameoftypetoupdate
        ### dnnps listall-contenttypes



PERSONS
# Create the content items for contributors.
    dnnps add-persons-contributors
    dnnps listall-persons



PERSONA BAR AND TABS

# Upload the image files to Assets.
    ## In Evoq, create a "Persona Bar menus" folder under the home folder of the site.
    ## Upload the following:
        scr-pbar-*png
        scr-pbtabs-*png

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

# Create the content items.
    dnnps add-images-logos
    dnnps listall-images

    dnnps add-products-v85-v91
    :. dnnps add-products-v92
    dnnps listall-products



OTHER CONTENT

# Upload the image files to Assets.
    ## Upload the remaining images.

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

