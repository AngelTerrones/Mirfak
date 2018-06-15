# ------------------------------------------------------------------------------
# Copyright (c) 2018 Angel Terrones <angelterrones@gmail.com>
# ------------------------------------------------------------------------------
include tests/verilator/pprint.mk

# verilate
#--------------------------------------------------
.RTLDIR		:= hardware
VSOURCES	:= $(shell find hardware -name "*.v")
VTOP		:= $(.RTLDIR)/mirfak_core.v
UCONTROL    := -GUCONTROL="\"$(UFILE)"\"
#--------------------------------------------------
.VOBJ := $(BUILD_DIR)/Mirfak_obj
.SUBMAKE := $(MAKE) --no-print-directory --directory=$(.VOBJ) -f
.VERILATE := verilator --trace -Wall -Wno-fatal -cc -y $(.RTLDIR) -CFLAGS "-std=c++11 -O3" -Mdir $(.VOBJ) --prefix VMirfak $(UCONTROL) -O3 --x-assign 1

#--------------------------------------------------
# C++ build
CXX := g++
CFLAGS := -std=c++17 -Wall -O3 # -g # -DDEBUG # -Wno-sign-compare
CFLAGS_NEW := -faligned-new
VERILATOR_ROOT ?= $(shell bash -c 'verilator -V|grep VERILATOR_ROOT | head -1 | sed -e " s/^.*=\s*//"')
VROOT := $(VERILATOR_ROOT)
VINCD := $(VROOT)/include
VINC := -I$(VINCD) -I$(VINCD)/vltstd -I$(.VOBJ)

#--------------------------------------------------
ifeq ($(OS),Windows_NT)
	INCS := $(VINC) -Itests/verilator -I /mingw$(shell getconf LONG_BIT)/include/libelf
else
	INCS := $(VINC) -Itests/verilator
endif

#--------------------------------------------------
GCC7 = $(shell expr `gcc -dumpversion | cut -f1 -d.` = 7 )
ifeq ($(GCC7), 1)
	CFLAGS += $(CFLAGS_NEW)
endif

#--------------------------------------------------
VOBJS := $(.VOBJ)/verilated.o $(.VOBJ)/verilated_vcd_c.o
SOURCES := mirfak_tb.cpp wbmemory.cpp aelf.cpp wbconsole.cpp wbdevice.cpp
OBJS := $(addprefix $(.VOBJ)/, $(subst .cpp,.o,$(SOURCES)))

# ------------------------------------------------------------------------------
# targets
# ------------------------------------------------------------------------------
build-vlib: $(.VOBJ)/VMirfak__ALL.a
build-core: $(BUILD_DIR)/Mirfak.exe

.SECONDARY: $(OBJS)

# Verilator
$(.VOBJ)/VMirfak__ALL.a: $(VSOURCES)
	@printf "%b" "$(.COM_COLOR)$(.VER_STRING)$(.OBJ_COLOR) $<$(.NO_COLOR)\n"
	+@$(.VERILATE) $(VTOP)
	@printf "%b" "$(.COM_COLOR)$(.COM_STRING)$(.OBJ_COLOR) $(@F)$(.NO_COLOR)\n"
	+@$(.SUBMAKE) VMirfak.mk

# C++
$(.VOBJ)/%.o: tests/verilator/%.cpp
	@printf "%b" "$(.COM_COLOR)$(.COM_STRING)$(.OBJ_COLOR) $(@F) $(.NO_COLOR)\n"
	@$(CXX) $(CFLAGS) $(INCS) -c $< -o $@

$(VOBJS): $(.VOBJ)/%.o: $(VINCD)/%.cpp
	@printf "%b" "$(.COM_COLOR)$(.COM_STRING)$(.OBJ_COLOR) $(@F) $(.NO_COLOR)\n"
	@$(CXX) $(CFLAGS) $(INCS) -Wno-format -c $< -o $@

$(BUILD_DIR)/Mirfak.exe: $(VOBJS) $(OBJS) $(.VOBJ)/VMirfak__ALL.a
	@printf "%b" "$(.COM_COLOR)$(.COM_STRING)$(.OBJ_COLOR) $(@F)$(.NO_COLOR)\n"
	@$(CXX) $(INCS) $^ -lelf -o $@
	@printf "%b" "$(.MSJ_COLOR)Compilation $(.OK_COLOR)$(.OK_STRING)$(.NO_COLOR)\n"

.PHONY: build-vlib build-core
