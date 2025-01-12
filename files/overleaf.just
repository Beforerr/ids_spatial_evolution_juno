overleaf_repo := x'https://git@git.overleaf.com/$OVERLEAF_ID'

[private]
clone-overleaf:
    [ -d overleaf ] || git clone {{overleaf_repo}} overleaf

update-overleaf: sync-overleaf
    cd overleaf; git add .; git commit -am "update"; git push

sync-overleaf: tex-render tex-clean

sync-bib: 
    cp overleaf/files/bibliography/full_anton.bib files/bibliography/full_anton.bib

tex-render:
    #!/usr/bin/env bash
    touch files/bibexport.bib
    quarto render --profile man --to $OVERLEAF_FMT
    rsync _manuscript/_tex/ overleaf/ -rcL
    rsync article_files overleaf -a --size-only || true

[private]
tex-clean:
    -rm article.{aux,bbl,blg,log,tex}
    -rm trackchanges.sty *.cls

update-agu-format file:
    #!/usr/bin/env bash
    sed -i '' '/\\usepackage\[[^]]*\]{natbib}/d; /\\bibliographystyle{plainnat}/d' {{ file }}
    sed -E -i '' 's/\\citep\[([^]]*)\]\[([^]]*)\]\{([^}]*)\}/\\cite<\1>[\2]{\3}/g' {{ file }}
    sed -i '' 's/\\citep/\\cite/g' {{ file }}
    sed -i '' 's/\\citet/\\citeA/g' {{ file }}