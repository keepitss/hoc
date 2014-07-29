%{

// #define YYSTYPE double	/* data type of yacc stack */

#include <stdio.h>
#include <ctype.h>
#include <signal.h>
#include <setjmp.h>
#include "hoc.h"

#define code2(c1,c2)		code(c1); code(c2)
#define code3(c1,c2,c3)		code(c1); code(c2); code(c3)

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
	Symbol	*sym;		/* symbal table pointer */
	Inst	*inst;		/* machine instruction */
}

%token	<sym>		NUMBER VAR BLTIN UNDEF
%right	'='
%left	'+' '-'		/* left associative, same precedence */
%left	'*' '/'		/* left assoc., higher precedence */
%left	UNARYMINUS
%right	'^'			/* exponentiation */

%%

list:  /* nothing */
		| list '\n'
		| list asgn '\n'		{ code2(xpop, STOP); return 1; }
		| list expr '\n'		{ code2(print, STOP); return 1; }
		| list error '\n'		{ yyerrok; }
		;

asgn:	  VAR '=' expr			{ code3(varpush, (Inst)$1, assign); }
		;

expr:     NUMBER				{ code2(constpush, (Inst)$1); }
		| VAR					{ code3(varpush, (Inst)$1, eval); }
		| asgn
		| BLTIN '(' expr ')'	{ code2(bltin, (Inst)$1->u.ptr); }
		| '(' expr ')'
		| expr '+' expr 		{ code(add); }
		| expr '-' expr 		{ code(sub); }
		| expr '*' expr 		{ code(mul); }
		| expr '/' expr 		{ code(divop); }
		| expr '^' expr			{ code(power); }
		| '-' expr %prec UNARYMINUS { code(negate); }
		;

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
		double d;
		ungetc(c, stdin);
		scanf("%lf", &d);
		yylval.sym = install("", NUMBER, d);
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
	for (initcode(); yyparse(); initcode())
		execute(prog);
	return 0;
}


