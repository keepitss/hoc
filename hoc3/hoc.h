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

extern double	Log(double), Log10(double), Sqrt(double), Exp(double);


#endif /* __hoc_h__ */
