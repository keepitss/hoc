%{

// #define YYSTYPE double	/* data type of yacc stack */

#include <stdio.h>
#include <ctype.h>
#include <signal.h>
#include <setjmp.h>
#include "hoc.h"

extern double Pow(double, double);

char    	*progname;		/* for error message */
int     	lineno = 1;
jmp_buf		begin;

double		mem[26];	/* 26 variables */

void	warning(char *s, char *t);
void	yyerror(char *s);
int		yylex();
void	execerror(char *s, char *t);
void	fpecatch();

%}

%union {				/* stack type */
	double	val;		/* actual value */
	Symbol	*sym;		/* symbal table pointer */
}

%token	<val>		NUMBER
%token	<sym>		VAR BLTIN UNDEF
%type	<val>		expr asgn
%right	'='
%left	'+' '-'		/* left associative, same precedence */
%left	'*' '/'		/* left assoc., higher precedence */
%left	UNARYMINUS
%right	'^'			/* exponentiation */

%%

list:  /* nothing */
		| list '\n'
		| list asgn '\n'
		| list expr '\n'		{ printf("\t%.8g\n", $2); }
		| list error '\n'		{ yyerrok; }
		;

asgn:	  VAR '=' expr			{ $$ = $1->u.val = $3; $1->type = VAR; }


expr:     NUMBER
		| VAR					{
									if ($1->type == UNDEF)
										execerror("undefined variable", $1->name);
									$$ = $1->u.val;
								}
		| asgn
		| BLTIN '(' expr ')'	{ $$ = (*($1->u.ptr))($3); }
		| expr '+' expr 		{ $$ = $1 + $3; }
		| expr '-' expr 		{ $$ = $1 - $3; }
		| expr '*' expr 		{ $$ = $1 * $3; }
		| expr '/' expr 		{ 
									if ($3 == 0.0)
										execerror("division by zero", "");
									$$ = $1 / $3; 
								}
		| expr '^' expr			{ $$ = Pow($1, $3); }
		| '(' expr ')'			{ $$ = $2; }
		| '-' expr %prec UNARYMINUS { $$ = -$2; }

%%

/* print warning message */
void warning(char *s, char *t)
{
	fprintf(stderr, "%s: %s", progname, s);
	if (t)
		fprintf(stderr, " %s", t);
	fprintf(stderr, " near line %d\n", lineno);
}

/* called for yacc syntax error */
void yyerror(char* s)
{
	warning(s, (char*)0);
}

/* lexical parser */
int yylex()
{
	int c;

	while ((c=getchar()) == ' ' || c == '\t')
		;
	if (c == EOF)
		return 0;
	if (c == '.' || isdigit(c)) {	/* number */
		ungetc(c, stdin);
		scanf("%lf", &yylval.val);
		return NUMBER;
	}
	if (isalpha(c)) {
		Symbol *s;
		char sbuf[100], *p = sbuf;
		
		do {
			*p++ = c;
		} while ((c=getchar()) != EOF && isalnum(c));

		ungetc(c, stdin);
		*p = '\0';
		if ((s=lookup(sbuf)) == 0) {
			s = install(sbuf, UNDEF, 0.0);
			// printf("Installed UNDEF symbol %s\n", sbuf);
		}
		yylval.sym = s;
		return s->type == UNDEF ? VAR : s->type;
	}
	if (c == '\n')
		lineno++;

	return c;
}

/* recover from run-time error */
void	execerror(char *s, char *t)
{
	warning(s, t);
	longjmp(begin, 0);
}

/* catch floating point exception */
void	fpecatch()
{
	execerror("floating point exception", (char*)0);
}


int main(int argc, char* argv[])
{
	progname = argv[0];
	init();
	setjmp(begin);
	signal(SIGFPE, fpecatch);
	yyparse();
}


