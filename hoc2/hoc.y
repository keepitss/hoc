%{

// #define YYSTYPE double	/* data type of yacc stack */

#include <stdio.h>
#include <ctype.h>
#include <signal.h>
#include <setjmp.h>

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
	int		index;		/* index into mem[] */
}

%token	<val>		NUMBER
%token	<index>		VAR
%type	<val>		expr
%right	'='
%left	'+' '-'		/* left associative, same precedence */
%left	'*' '/'		/* left assoc., higher precedence */
%left	UNARYMINUS

%%

list:  /* nothing */
		| list '\n'
		| list ';'
		| list expr '\n'		{ printf("\t%.8g\n", $2); }
		| list expr ';'			{ printf("\t%.8g\n", $2); }
		| list error '\n'		{ yyerrok; }
		| list error ';'		{ yyerrok; }
		;

expr:     NUMBER				{ $$ = $1; }
		| VAR					{ $$ = mem[$1]; }
		| VAR '=' expr			{ $$ = mem[$1] = $3;}
		| expr '+' expr 		{ $$ = $1 + $3; }
		| expr '-' expr 		{ $$ = $1 - $3; }
		| expr '*' expr 		{ $$ = $1 * $3; }
		| expr '/' expr 		{ 
				if ($3 == 0.0)
					execerror("division by zero", "");
				$$ = $1 / $3; }
		| '(' expr ')'		{ $$ = $2; }
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
	if (islower(c)) {
		yylval.index = c - 'a'; /* ASCII only */
		return VAR;
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
	setjmp(begin);
	signal(SIGFPE, fpecatch);
	yyparse();
}


