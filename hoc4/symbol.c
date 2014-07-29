#include <stdlib.h>
#include <string.h>
#include "hoc.h"
#include "y.tab.h"

static Symbol *symlist = 0; /* symbol table: linked list */

Symbol *lookup(char *s)
{
	Symbol *sp;

	for (sp = symlist; sp != (Symbol *) 0; sp = sp->next)
		if (strcmp(sp->name, s) == 0)
			return sp;

	return 0;
}

char *emalloc(unsigned n)
{
	char *p = malloc(n);
	if (p == 0)
		execerror("out of memory", (char *) 0);
	return p;
}

Symbol *install(char *s, int t, double d)
{
	Symbol *sp = (Symbol *) emalloc(sizeof(Symbol));
	sp->name = emalloc(strlen(s)+1); /* +1 for '\0' */
	strcpy(sp->name, s);
	sp->type = t;
	sp->u.val = d;
	sp->next = symlist; /* put at front of list */
	symlist = sp;
	return sp;
}

