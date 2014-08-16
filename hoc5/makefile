YFLAGS = -d	-v -t --graph # force creation of y.tab.h
CFLAGS = -std=c99 -Wall -ggdb
OBJS   = hoc.o code.o init.o math.o symbol.o

hoc5:	$(OBJS)
	cc $(OBJS) -lm -o hoc5

hoc.o code.o init.o symbol.o: hoc.h

code.o init.o symbol.o: y.tab.h

y.tab.c: hoc.y
hoc.c: y.tab.c

#x.tab.h: y.tab.h
#	-cmp -s x.tab.h y.tab.h || cp y.tab.h x.tab.h

pr:	hoc.y hoc.h code.c init.c math.c symbol.c
	@pr $?
	@touch pr

clean:
	rm -f $(OBJS) [xy].tab.[ch] hoc5 hoc.c y.dot y.output core

