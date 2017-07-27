@echo off

:. Refresh settings*.json to provide the IDs for referenced content types.
    call dnnps.bat listall-contenttypes


call dnnps.bat add-contenttype-Image

call dnnps.bat add-contenttype-Note

call dnnps.bat add-contenttype-Requisite

call dnnps.bat add-contenttype-Product

call dnnps.bat add-contenttype-TermDesc


    call dnnps.bat listall-contenttypes


:. Requires Image
call dnnps.bat add-contenttype-Choice
:. Requires Image
call dnnps.bat add-contenttype-Substep
:. Requires TermDesc
call dnnps.bat add-contenttype-TableTermDesc


    call dnnps.bat listall-contenttypes


:. Requires Choice, Substep
call dnnps.bat add-contenttype-Step


    call dnnps.bat listall-contenttypes


:. Requires Image, Step
call dnnps.bat add-contenttype-Passage


    call dnnps.bat listall-contenttypes


:. Requires Passage
call dnnps.bat add-contenttype-Section
:. Requires Requisite, Choice, Step
call dnnps.bat add-contenttype-Solution


    call dnnps.bat listall-contenttypes


:. Requires Product, Person, Section
call dnnps.bat add-contenttype-Conceptual
:. Requires Product and Person
call dnnps.bat add-contenttype-Reference
:. Requires Choice, Step
call dnnps.bat add-contenttype-Task
:. Requires Person, Product, Solution
call dnnps.bat add-contenttype-Troubleshooting


    call dnnps.bat listall-contenttypes
