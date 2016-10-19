# $Id: Makefile 2 2015-06-15 13:52:02Z fkluge $

PROJECT=timer_$(CASE)

MOD_SRC=../verilog

SRC = $(wildcard $(MOD_SRC)/scct*.v) test_$(CASE).v
DUMP = test.lxt2

all: $(PROJECT)

$(PROJECT): $(SRC)
	iverilog -I$(MOD_SRC) -o $(PROJECT) $(SRC)

run: $(PROJECT)
	vvp $(PROJECT) -lxt2


view: #$(DUMP)
	gtkwave $(DUMP)

#$(DUMP): $(PROJECT)

