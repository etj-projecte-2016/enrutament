# Generar presentació

Només cal executar:

    pandoc -t html5 --template=template-revealjs.html --standalone --section-divs  --variable theme="black" --variable transition="linear" presentacio.md -o presentacio.html

Cal dir que presentacio.md està dins del directori reveal.js
