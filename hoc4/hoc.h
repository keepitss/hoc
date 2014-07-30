#ifndef __hoc_h__
#define __hoc_h__

typedef struct Symbol { /* symbol table entry */
	char	*name;
	short	type;	/* VAR, BLTIN, UNDEF */
	union {
		double	val;	/* if VAR */
		double	(*ptr)(double); /* if BLTIN */
	} u;
	struct Symbol *next;	/* to link to another */
} Symbol;

Symbol *install(char *s, int t, double d), *lookup(char *s);

typedef union Datum { /* interpreter stack type */
	double	val;
	Symbol	*sym;
} Datum;

typedef void (*Inst)();
#define STOP (Inst)0

extern Inst *code(Inst);
extern void initcode();
extern Datum pop();
extern void xpop();
extern void init();
extern void execute(Inst *p);
extern void execerror(char *s, char *t);

extern Inst prog[];
extern void eval(), add(), sub(), mul(), divop(), negate(), power();
extern void assign(), bltin(), varpush(), constpush(), print();

extern double Log(double), Log10(double), Sqrt(double), Exp(double), Pow(double, double);


#endif /* __hoc_h__ */
