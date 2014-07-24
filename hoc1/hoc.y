%{

#define YYSTYPE double	/* data type of yacc stack */

#include <stdio.h>
#include <ctype.h>
char    *progname;		/* for error message */
int     lineno = 1;

void warning(char *s, char *t);
void yyerror(char* s);
int yylex();

%}

%token	NUMBER
%left	'+' '-'		/* left associative, same precedence */
%left	'*' '/'		/* left assoc., higher precedence */

%%

list:  /* nothing */
       | list '\n'
       | list expr '\n'		{ printf("\t%.8g\n", $2); }
       ;

expr:    NUMBER				{ $$ = $1; }
       | expr '+' expr 		{ $$ = $1 + $3; }
       | expr '-' expr 		{ $$ = $1 - $3; }
       | expr '*' expr 		{ $$ = $1 * $3; }
       | expr '/' expr 		{ $$ = $1 / $3; }
       | '(' expr ')'		{ $$ = $2; }

%%

void warning(char *s, char *t)
{
	fprintf(stderr, "%s: %s", progname, s);
	if (t)
		fprintf(stderr, " %s", t);
	fprintf(stderr, " near line %d\n", lineno);
}

void yyerror(char* s)
{
	warning(s, (char*)0);
}

int yylex()
{
	int c;

	while ((c=getchar()) == ' ' || c == '\t')
		;
	if (c == EOF)
		return 0;
	if (c == '.' || isdigit(c)) {	/* number */
		ungetc(c, stdin);
		scanf("%lf", &yylval);
		return NUMBER;
	}
	if (c == '\n')
		lineno++;

	return c;
}

int main(int argc, char* argv[])
{
	progname = argv[0];
	yyparse();
}


