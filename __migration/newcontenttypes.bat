@echo off

call dnnps.bat add-contenttype-Image

call dnnps.bat add-contenttype-Requisite

call dnnps.bat add-contenttype-Product

call dnnps.bat add-contenttype-TermDesc

:. Refresh settings*.json.
call dnnps.bat list-all-contenttypes

:. Requires Image
call dnnps.bat add-contenttype-Choice

:. Requires Image
call dnnps.bat add-contenttype-Substep

:. Refresh settings*.json.
call dnnps.bat list-all-contenttypes

:. Requires Choice, Substep
call dnnps.bat add-contenttype-Step

:. Refresh settings*.json.
call dnnps.bat list-all-contenttypes

:. Requires Image, Step
call dnnps.bat add-contenttype-SubSection

:. Refresh settings*.json.
call dnnps.bat list-all-contenttypes

:. Requires SubSection
call dnnps.bat add-contenttype-Section

:. Requires Requisite, Choice, Step
call dnnps.bat add-contenttype-Solution

:. Refresh settings*.json.
call dnnps.bat list-all-contenttypes

:. Requires Product, Person, Section
call dnnps.bat add-contenttype-Conceptual

:. Requires Product and Person
call dnnps.bat add-contenttype-Reference

:. Requires Choice, Step
call dnnps.bat add-contenttype-Task

:. Requires Person, Product, Solution
call dnnps.bat add-contenttype-Troubleshooting

:. Refresh settings*.json.
call dnnps.bat list-all-contenttypes

:. Archive
echo Copying to out\contenttypes*.out . . . .
for %%v in ( raw processed ) do copy /v /y %%v.out out\contenttypes-%%v.out
