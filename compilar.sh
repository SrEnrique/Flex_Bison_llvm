bison -d sintactico.y && flex lexico.l && gcc lex.yy.c sintactico.tab.c -o analizador -lfl -lm
