/* Declaraciones de apoyo */
%{
  #include <stdio.h>
  #include <stdlib.h>
  #include <string.h>
  #include "sintactico.wrap.tab.h"
  extern int linea_actual;
  extern FILE *yyin;
  void yyerror(char *s);
  void nuevaTmp(char *s);
  void nuevaEtq(char *s);
  void generarTerceto(char *terceto, char *Lvalor, char *Rvalor1, char *Rvalor2);
  void generarCondicion(char *Rvalor1, char *condicion, char *Rvalor2, doble_cond *etqs);
%}
/* Declaracion de atributos */
%union {
  char numero[50];
  char variable_aux[50];
  char etiqueta_aux[50];
  char etiqueta_siguiente[50];
  doble_cond bloque_cond;
  datos_case bloque_case;
}
/* Declaracion de tokens y sus atributos */
%token <numero> NUMERO
%token <variable_aux> ID
%token <etiqueta_aux> SI MIENTRAS REPETIR
%token <etiqueta_siguiente> CASO
%token ASIG ENTONCES INICIO FIN HACER HASTA CASE DE SINO
%token MAI MEI DIF 

%token MAS
/* Declaración de no terminales y sus atributos */
%type <variable_aux> expr
%type <bloque_cond> cond
%type <bloque_case> inicio_case
/* Precedencia y asociatividad de operadores */
%left OR
%left AND
%left NOT
%left '+' '-'
%left '*' '/'
%left MENOS_UNARIO

%%
prog : prog sent ';'
  | prog error ';' { yyerrok; }
  |
  ;
sent: ID ASIG expr { printf("\t%s = %s\n", $1, $3); }
  | SI cond { printf("label %s\n", $2.etq_verdad); } ENTONCES
      sent ';' { nuevaEtq($1); printf("\tgoto %s\n", $1); printf("label %s\n", $2.etq_falso); }
    opcional
    FIN SI { printf("label %s\n", $1); }
  | INICIO lista_sent FIN { ; }
  | MIENTRAS { nuevaEtq($1); printf("label %s\n", $1); } cond { printf("label %s\n", $3.etq_verdad); } HACER
      sent ';'
    FIN MIENTRAS { printf("\tgoto %s\n", $1); printf("label %s\n", $3.etq_falso); }  
  | REPETIR { nuevaEtq($1); printf("label %s\n", $1); }
      sent ';'
    HASTA cond { 
      printf("label %s\n", $6.etq_falso);
      printf("\tgoto %s\n", $1); 
      printf("label %s\n", $6.etq_verdad);
    }
  | sent_case
  | ID MAS ID {
    printf("Estas sumando :D \n");
  }


;
opcional: /* Epsilon */
  | SINO 
      sent ';'
;
lista_sent: /* Epsilon */
  | lista_sent sent ';'
  | lista_sent error ';' { yyerrok; }
;
sent_case: inicio_case
  SINO sent ';'
  FIN CASE { printf("label %s\n", $1.etq_final); }
  | inicio_case
  FIN CASE { printf("label %s\n", $1.etq_final); }
;
inicio_case: CASE expr DE { strcpy($$.variable_expr, $2); nuevaEtq($$.etq_final); }
  | inicio_case CASO expr ':' { nuevaEtq($2); printf("\tif %s != %s goto %s\n", $1.variable_expr, $3, $2); }
      sent ';' {
		printf("\tgoto %s\n", $1.etq_final);
		printf("label %s\n", $2);
		strcpy($$.variable_expr, $1.variable_expr);
		strcpy($$.etq_final, $1.etq_final);
      }
;
expr: NUMERO { generarTerceto("\t%s = %s\n", $$, $1, NULL); }
  | ID { strcpy($$, $1); }
  | expr '+' expr { generarTerceto("\t%s = %s + %s\n", $$, $1, $3); }
  | expr '-' expr { generarTerceto("\t%s = %s - %s\n", $$, $1, $3); }
  | expr '*' expr { generarTerceto("\t%s = %s * %s\n", $$, $1, $3); }
  | expr '/' expr { generarTerceto("\t%s = %s / %s\n", $$, $1, $3); }
  | '-' expr %prec MENOS_UNARIO { generarTerceto("\t%s = - %s\n", $$, $2, NULL); }
  | '(' expr ')' { strcpy($$, $2); }
;
cond: expr '>' expr { generarCondicion($1, ">", $3, &($$)); }
  | expr '<' expr { generarCondicion($1, "<", $3, &($$)); }
  | expr MAI expr { generarCondicion($1, ">=", $3, &($$)); }
  | expr MEI expr { generarCondicion($1, "<=", $3, &($$)); }
  | expr '=' expr { generarCondicion($1, "=", $3, &($$)); }
  | expr DIF expr { generarCondicion($1, "!=", $3, &($$)); }
  | NOT cond { strcpy($$.etq_verdad, $2.etq_falso); strcpy($$.etq_falso, $2.etq_verdad); }
  | cond AND { printf("label %s\n", $1.etq_verdad); }
    cond {
      printf("label %s\n", $1.etq_falso);
      printf("\tgoto %s\n", $4.etq_falso);
      strcpy($$.etq_verdad, $4.etq_verdad);
      strcpy($$.etq_falso, $4.etq_falso);
    }
  | cond OR { printf("label %s\n", $1.etq_falso); }
    cond {
      printf("label %s\n", $1.etq_verdad);
      printf("\tgoto %s\n", $4.etq_verdad);
      strcpy($$.etq_verdad, $4.etq_verdad);
      strcpy($$.etq_falso, $4.etq_falso);
    }
  | '(' cond ')' { strcpy($$.etq_verdad, $2.etq_verdad); strcpy($$.etq_falso, $2.etq_falso); }
;

%%
void main(int argc,char **argv) {
  if (argc>1)
    yyin=fopen(argv[1],"rt");
  else
    yyin=stdin;
  yyparse();
}
void yyerror(char *s) {
  fprintf(stderr, "Error de sintaxis en la linea %d\n", linea_actual);
}
void nuevaTmp(char *s) {
  static actual=0;
  sprintf(s, "tmp%d", ++actual);
}
void nuevaEtq(char *s) {
  static actual=0;
  sprintf(s, "etq%d", ++actual);
}
void generarTerceto(char *terceto, char *Lvalor, char *Rvalor1, char *Rvalor2){
  nuevaTmp(Lvalor);
  printf(terceto, Lvalor, Rvalor1, Rvalor2);
}
void generarCondicion(char *Rvalor1, char *condicion, char *Rvalor2, doble_cond *etqs){
  nuevaEtq((*etqs).etq_verdad);
  nuevaEtq((*etqs).etq_falso);
  printf("\tif %s %s %s goto %s\n", Rvalor1, condicion, Rvalor2, (*etqs).etq_verdad);
  printf("\tgoto %s\n", (*etqs).etq_falso);
}