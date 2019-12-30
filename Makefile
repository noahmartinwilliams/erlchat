ERLC=erlc $^

%.beam: %.erl
	$(ERLC)
.PHONY:
%: %.beam
	erl -noshell -s $@ start -s init stop
