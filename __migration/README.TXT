

Prereq: A clean site

# Create the settings file.
    ## Create a new API key with RW access to both content types and content items.
    ## Create a new settings-doccenter-%bldsite%.json file with the new API key. (Template: json\settings.json)
    ## Update dnnps.bat with the new value of %bldsite%.

# Create the content types.
    ## Run contenttypes-raw2body.bat
    ## Run newcontenttypes.bat
    ## Verify that contenttypeids list is updated in settings-doccenter-*.json



PERSONA BAR AND TABS

# Upload the image files to Assets.
    ## In Evoq, create a "Persona Bar menus" folder under the home folder of the site.
    ## Upload the following:
        * scr-pbar-*png
        * scr-pbtabs-*png
# Create the content items for the images.
    * dnnps add-images-pbar-host
    * dnnps add-images-pbar-adm
    * dnnps add-images-pbar-all
    * dnnps add-images-pbar-cmg
    * dnnps add-images-pbar-mod
    * dnnps add-images-pbtabs
    * dnnps list-all-type-images
# Create the content items for the steps.
