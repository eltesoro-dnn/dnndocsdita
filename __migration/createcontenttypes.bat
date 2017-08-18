@echo off

:. Refresh settings*.json to provide the IDs for referenced content types.
    call dnnps.bat listall-contenttypes %1


call dnnps.bat add-contenttype-Image %1

call dnnps.bat add-contenttype-Note %1

call dnnps.bat add-contenttype-Requisite %1

call dnnps.bat add-contenttype-Product %1

call dnnps.bat add-contenttype-TermDesc %1

:. APIs
call dnnps.bat add-contenttype-WebApiField %1
    call dnnps.bat listall-contenttypes %1
call dnnps.bat add-contenttype-WebApiDto %1
    call dnnps.bat listall-contenttypes %1
call dnnps.bat add-contenttype-WebApiParam %1
    call dnnps.bat listall-contenttypes %1
call dnnps.bat add-contenttype-WebApiSection %1
    call dnnps.bat listall-contenttypes %1
call dnnps.bat add-contenttype-WebApiMethod %1


    call dnnps.bat listall-contenttypes %1


:. Requires Image
call dnnps.bat add-contenttype-Choice %1
:. Requires Image
call dnnps.bat add-contenttype-Substep %1
:. Requires TermDesc
call dnnps.bat add-contenttype-TableTermDesc %1


    call dnnps.bat listall-contenttypes %1


:. Requires Choice, Substep
call dnnps.bat add-contenttype-Step %1


    call dnnps.bat listall-contenttypes %1


:. Requires Image, Step
call dnnps.bat add-contenttype-Passage %1


    call dnnps.bat listall-contenttypes %1


:. Requires Passage
call dnnps.bat add-contenttype-Section %1
:. Requires Requisite, Choice, Step
call dnnps.bat add-contenttype-Solution %1


    call dnnps.bat listall-contenttypes %1


:. Requires Product, Person, Section
call dnnps.bat add-contenttype-Conceptual %1
:. Requires Product and Person
call dnnps.bat add-contenttype-Reference %1
:. Requires Choice, Step
call dnnps.bat add-contenttype-Task %1
:. Requires Person, Product, Solution
call dnnps.bat add-contenttype-Troubleshooting %1


    call dnnps.bat listall-contenttypes %1
