overleaf_repo := x'https://git@git.overleaf.com/$OVERLEAF_ID'

[private]
clone-overleaf:
  [ -d overleaf ] || git clone {{overleaf_repo}} overleaf

update-overleaf: sync-overleaf
  cd overleaf; git add .; git commit -am "update"; git push

sync-overleaf: tex-render tex-clean

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