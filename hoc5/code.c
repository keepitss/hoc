#include <stdio.h>
#include <memory.h>
#include "hoc.h"
#include "y.tab.h"

#define	NSTACK	256
static	Datum	stack[NSTACK];	/* the stack */
static	Datum	*stackp;		/* next free spot on stack */

#define	NPROG	2000
Inst	prog[NPROG];			/* the machine */
Inst	*progp;					/* next free spot for code generation */
Inst	*pc;					/* program counter during execution */

void initcode()
{
	memset(stack, 0, sizeof(Datum)*NSTACK);
	memset(prog, 0, sizeof(Inst)*NPROG);

	stackp = stack;
	progp = prog;
}

void push(Datum d)		/* push d onto stack */
{
	if (stackp >= &stack[NSTACK])
		execerror("stack overflow", (char *) 0);
	*stackp++ = d;
}

Datum pop()				/* pop and return top elem from stack */
{
	if (stackp <= stack)
		execerror("stack underflow", (char *) 0);
	return *--stackp;
}

void xpop()				/* for when no value is wanted */
{
	pop();
}

Inst *code(Inst f)		/* install one instruction or operand */
{
	Inst *oprogp = progp;
	if (progp >= &prog[NPROG])
		execerror("program too big", (char *) 0);
	*progp++ = f;
	return oprogp;
}

void execute(Inst *p)	/* run the machine */
{
	/*Inst *pc = 0;*/
	for (pc = p; *pc != STOP; )
	{
		(*(*pc++))();
	}
}

void constpush()		/* push constant onto stack */
{
	/*
	printf("%p, %p, %p", stack, stackp, pc);
	fflush(stdout);
	*/
	Datum d;
	d.val = ((Symbol *)*pc++)->u.val;
	push(d);
}

void varpush()			/* push variable onto stack */
{
	Datum d;
	d.sym = (Symbol *)(*pc++);
	push(d);
}

void add()				/* add top two elems on stack */
{
	Datum d1, d2;
	d2 = pop();
	d1 = pop();
	d1.val += d2.val;
	push(d1);
}

void sub()				/* sustract top two elems on stack */
{
	Datum d1, d2;
	d2 = pop();
	d1 = pop();
	d1.val -= d2.val;
	push(d1);
}

void mul()				/* multiply top two elems on stack */
{
	Datum d1, d2;
	d2 = pop();
	d1 = pop();
	d1.val *= d2.val;
	push(d1);
}

void divop()				/* divide top two elems on stack */
{
	Datum d1, d2;
	d2 = pop();
	if (d2.val == 0.0)
		execerror("division by zero", (char *)0);

	d1 = pop();
	d1.val /= d2.val;
	push(d1);
}

void
power(void)
{
	Datum d1, d2;
	d2 = pop();
	d1 = pop();
	d1.val = Pow(d1.val, d2.val);
	push(d1);
}

void
negate(void)
{
	Datum d;
	d = pop();
	d.val = -d.val;
	push(d);
}

void
gt(void)
{
	Datum d1, d2;
	d2 = pop();
	d1 = pop();
	d1.val = (double)(d1.val > d2.val);
	push(d1);
}

void
lt(void)
{
	Datum d1, d2;
	d2 = pop();
	d1 = pop();
	d1.val = (double)(d1.val < d2.val);
	push(d1);
}

void
ge(void)
{
	Datum d1, d2;
	d2 = pop();
	d1 = pop();
	d1.val = (double)(d1.val >= d2.val);
	push(d1);
}

void
le(void)
{
	Datum d1, d2;
	d2 = pop();
	d1 = pop();
	d1.val = (double)(d1.val <= d2.val);
	push(d1);
}

void
eq(void)
{
	Datum d1, d2;
	d2 = pop();
	d1 = pop();
	d1.val = (double)(d1.val == d2.val);
	push(d1);
}

void
ne(void)
{
	Datum d1, d2;
	d2 = pop();
	d1 = pop();
	d1.val = (double)(d1.val != d2.val);
	push(d1);
}

void
and(void)
{
	Datum d1, d2;
	d2 = pop();
	d1 = pop();
	d1.val = (double)(d1.val != 0.0 && d2.val != 0.0);
	push(d1);
}

void
or(void)
{
	Datum d1, d2;
	d2 = pop();
	d1 = pop();
	d1.val = (double)(d1.val != 0.0 || d2.val != 0.0);
	push(d1);
}

void
not(void)
{
	Datum d;
	d = pop();
	d.val = (double)(d.val == 0.0);
	push(d);
}


void eval()				/* evaluate variable on stack */
{
	Datum d;
	d = pop();
	if (d.sym->type == UNDEF)
		execerror("undefined variable", d.sym->name);
	d.val = d.sym->u.val;
	push(d);
}

void assign()			/* assign top value to next value */
{
	Datum d1, d2;
	d1 = pop();
	d2 = pop();
	if (d1.sym->type != VAR && d1.sym->type != UNDEF)
		execerror("assignment to non-variable", d1.sym->name);
	d1.sym->u.val = d2.val;
	d1.sym->type = VAR;
	push(d2);
}

void print()			/* pop top value from stack, print it*/
{
	Datum d;
	d = pop();
	printf("\t%.8g\n", d.val);
}

void bltin()
{
	Datum d;
	d = pop();
	d.val = (*(double (*)(double))(*pc++))(d.val);
	push(d);
}

void
whilecode(void)
{
	Datum d;
	Inst *savepc = pc;

	execute(savepc+2);	/* condition */
	d = pop();
	while (d.val) {
		execute(*((Inst **)(savepc)));	/* body */
		execute(savepc+2);	/* condition */
		d = pop();
	}
	pc = *((Inst **)(savepc+1)); /* next stmt */
}

void
ifcode(void) 
{
	Datum d;
	Inst *savepc = pc;	/* then part */

	execute(savepc+3);	/* condition */
	d = pop();
	if (d.val)
		execute(*((Inst **)(savepc)));	
	else if (*((Inst **)(savepc+1))) /* else part? */
		execute(*((Inst **)(savepc+1)));
	pc = *((Inst **)(savepc+2)); /* next stmt */
}


void
prexpr(void)	/* print numeric value */
{
	Datum d;
	d = pop();
	printf("%.8g ", d.val);
}



