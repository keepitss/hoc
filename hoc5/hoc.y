%{

// #define YYSTYPE double	/* data type of yacc stack */

#include <stdio.h>
#include <ctype.h>
#include <signal.h>
#include <setjmp.h>
#include "hoc.h"

//#define YYDEBUG 1

#define code2(c1,c2)		code(c1); code(c2)
#define code3(c1,c2,c3)		code(c1); code(c2); code(c3)

#define mymsg(str) printf("%s\n", str)

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

%token	<sym>		NUMBER PRINT VAR BLTIN UNDEF WHILE IF ELSE
%type	<inst>		stmt asgn expr stmtlist cond while if end
%right	'='
%left	OR
%left	AND
%left	GT GE LT LE EQ NE
%left	'+' '-'		/* left associative, same precedence */
%left	'*' '/'		/* left assoc., higher precedence */
%left	UNARYMINUS NOT
%right	'^'			/* exponentiation */

%%

list:  /* nothing */
		| list '\n'
		| list asgn '\n'		{ code2(xpop, STOP); mymsg("list: asgn");return 1; }
		| list stmt '\n'		{ code(STOP); mymsg("list: stmt");return 1; }
		| list expr '\n'		{ code2(print, STOP); mymsg("list:expr");return 1; }
		| list error '\n'		{ yyerrok; mymsg("list:error");}
		;

asgn:	  VAR '=' expr			{ $$ = $3; code3(varpush, (Inst)$1, assign); mymsg("var=expr");}
		;

stmt:	  expr					{ code(xpop); mymsg("stmt:expr");}
		| PRINT expr			{ code(prexpr); $$=$2; mymsg("stmt:prn");}
		| while cond stmt end	{
			($1)[1] = (Inst)$3;		/* body of loop */
			($1)[2] = (Inst)$4;		/* end, if cond fails */
			mymsg("while-end");
		  }
		| if cond stmt end		{
			($1)[1] = (Inst)$3;		/* then part */
			($1)[3] = (Inst)$4;		/* end, if cond fails */
			mymsg("if-end");
		  }
		| if cond stmt end ELSE stmt end	{
			($1)[1] = (Inst)$3;		/* then part */
			($1)[2] = (Inst)$6;		/* else part */
			($1)[3] = (Inst)$7;		/* end, if cond fails */
			mymsg("if-else-end");
		  }
		| '{' stmtlist '}'		{ $$ = $2; mymsg("stmtlist");}
		;

cond:	  '(' expr ')'			{ code(STOP); $$ = $2; mymsg("cond");}
		;

while:	  WHILE { $$ = code3(whilecode, STOP, STOP); mymsg("while");}
		;

if:		  IF	{ $$ = code(ifcode); code3(STOP, STOP, STOP); mymsg("if");}
		;

end:	  /* nothing */			{ code(STOP); $$ = progp; mymsg("end");}
		;

stmtlist: /* nothing */			{ $$ = progp; mymsg("list:nothing");}
		| stmtlist '\n'
		| stmtlist stmt
		;

expr:     NUMBER				{ $$ = code2(constpush, (Inst)$1); mymsg("num");}
		| VAR					{ $$ = code3(varpush, (Inst)$1, eval); mymsg("var");}
		| asgn
		| BLTIN '(' expr ')'	{ $$ = $3; code2(bltin, (Inst)$1->u.ptr); mymsg("bltin");}
		| '(' expr ')'			{ $$ = $2; mymsg("(expr)");}
		| expr '+' expr 		{ code(add); mymsg("add");}
		| expr '-' expr 		{ code(sub); mymsg("sub");}
		| expr '*' expr 		{ code(mul); mymsg("mul");}
		| expr '/' expr 		{ code(divop); mymsg("divop");}
		| expr '^' expr			{ code(power); mymsg("power");}
		| '-' expr %prec UNARYMINUS { $$ = $2; code(negate); mymsg("uminus");}
		| expr GT expr			{ code(gt); }
		| expr GE expr			{ code(ge); }
		| expr LT expr			{ code(lt); }
		| expr LE expr			{ code(le); }
		| expr EQ expr			{ code(eq); }
		| expr NE expr			{ code(ne); }
		| expr AND expr			{ code(and); }
		| expr OR expr			{ code(or); }
		| NOT expr				{ $$ = $2; code(not); }
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

int follow(char expect, int ifyes, int ifno) /* look ahead for >=, etc */
{
	int c = getchar();

	if (c == expect)
		return ifyes;
	ungetc(c, stdin);
	return ifno;
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
	switch (c)
	{
		case '>' :	return follow('=', GE, GT);
		case '<' :	return follow('=', LE, LT);
		case '=' :	return follow('=', EQ, '=');
		case '!' :	return follow('=', NE, NOT);
		case '|' :	return follow('|', OR, '|');
		case '&' :	return follow('&', AND, '&');
		case '\n':	lineno++; return '\n';
		default:	return c;
	}
}

/* recover from run-time error */
void execerror(char *s, char *t)
{
	warning(s, t);
	longjmp(begin, 0);
}

/* catch floating point exception */
void fpecatch()
{
	execerror("floating point exception", (char*)0);
}


int main(int argc, char* argv[])
{
	yydebug = 1;
	progname = argv[0];
	init();
	setjmp(begin);
	signal(SIGFPE, fpecatch);
	for (initcode(); yyparse(); initcode())
		execute(prog);
	return 0;
}


