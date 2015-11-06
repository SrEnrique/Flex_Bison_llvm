%{
  #include <stdio.h>
  #include <stdlib.h>
  #include <string.h>
  #include "sintactico.wrap.tab.h"
  int linea_actual = 1;
%}
%START COMENT
%%
^[\t]*"*" { BEGIN COMENT; } //"

<COMENT>.+ { ; }
<COMENT>\n { BEGIN 0; linea_actual++; }

":="     { return ASIG; }
">="     { return MAI; }
"<="     { return MEI; }
"<>"     { return DIF; }
CASE     { return CASE; }
DE       { return DE; }
CASO     { return CASO; }
SINO     { return SINO; }
REPETIR  { return REPETIR; }
HASTA    { return HASTA; }
SI       { return SI; }
ENTONCES { return ENTONCES; }
MIENTRAS { return MIENTRAS; }
HACER    { return HACER; }
AND      { return AND; }
OR       { return OR; }
NOT      { return NOT; }
INICIO   { return INICIO; }
FIN      { return FIN; }

[0-9]+ { 
  strcpy(yylval.numero, yytext);
  return(NUMERO);
}
[A-Za-z_][A-Za-z0-9_]* {
  strcpy(yylval.variable_aux, yytext);
  return ID;
}
[\t]+ { ; }
" "+  {}
\n { linea_actual++; }
. { return yytext[0]; }

%%