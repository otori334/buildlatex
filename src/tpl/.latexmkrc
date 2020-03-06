#!/usr/bin/env perl
#コメント
@default_files    = ('automatic_generated.tex');
$pdf_mode         = 3;
$latex            = 'uplatex -synctex=1 -halt-on-error';
$latex_silent     = 'uplatex -synctex=1 -halt-on-error -interaction=batchmode';
$bibtex           = 'upbibtex';
$dvipdf           = 'dvipdfmx -I 3 %O -o %D %S';
$makeindex        = 'mendex %O -o %D %S';
$max_repeat       = 5;
$pvc_view_file_via_temporary = 0;
$pdf_previewer = "open -ga /Applications/Skim.app"; 
