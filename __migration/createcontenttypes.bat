@echo off
    call dnnps.bat listall-contenttypes


call dnnps.bat add-contenttype-Image
call dnnps.bat add-contenttype-Note
call dnnps.bat add-contenttype-Product
call dnnps.bat add-contenttype-Requisite
call dnnps.bat add-contenttype-TermDesc
call dnnps.bat add-contenttype-WebApiField
    call dnnps.bat listall-contenttypes


:. Requires Image
call dnnps.bat add-contenttype-Choice
call dnnps.bat add-contenttype-Substep
    call dnnps.bat listall-contenttypes


:. Requires Requisite, Choice, Substep
call dnnps.bat add-contenttype-Solution
    call dnnps.bat listall-contenttypes


:. Requires Image, Choice, Substep
call dnnps.bat add-contenttype-Step
    call dnnps.bat listall-contenttypes


:. Requires Image, Step
call dnnps.bat add-contenttype-Passage
    call dnnps.bat listall-contenttypes


:. Requires Passage
call dnnps.bat add-contenttype-Section
    call dnnps.bat listall-contenttypes


:. Requires Product, Person, Section
call dnnps.bat add-contenttype-Conceptual
    call dnnps.bat listall-contenttypes


:. Requires TermDesc
call dnnps.bat add-contenttype-TableTermDesc
    call dnnps.bat listall-contenttypes


:. Requires Product, Person, Section, Passage, TableTermDesc, TermDesc
call dnnps.bat add-contenttype-Reference
    call dnnps.bat listall-contenttypes


:. Requires Product, Person, Requisite, Choice, Step
call dnnps.bat add-contenttype-Task
    call dnnps.bat listall-contenttypes


:. Requires Product, Person, Solution
call dnnps.bat add-contenttype-Troubleshooting
    call dnnps.bat listall-contenttypes


:. Requires WebApiField
call dnnps.bat add-contenttype-WebApiDto
    call dnnps.bat listall-contenttypes


:. Requires WebApiField, WebApiDto
call dnnps.bat add-contenttype-WebApiParam
    call dnnps.bat listall-contenttypes


:. Requires WebApiParam
call dnnps.bat add-contenttype-WebApiSection
    call dnnps.bat listall-contenttypes


:. Requires WebApiSection, Passage
call dnnps.bat add-contenttype-WebApiMethod
    call dnnps.bat listall-contenttypes

