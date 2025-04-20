NOVAS        := /nfs/tools/synopsys/verdi/V-2023.12-SP1-1/share/PLI/VCS/LINUX64
EXTRA        := -P ${NOVAS}/novas.tab ${NOVAS}/pli.a

SIM_TOOL     := bsub -Is vcs
SIM_BINY     := bsub -Is ./simv
VERDI_TOOL   := bsub -Is verdi
SIM_OPTIONS  := -full64 -debug_acc+all  +v2k -sverilog -timescale=1ns/10ps \
                ${EXTRA} \
                +error+500\
                +define+SVA_OFF\
                -work DEFAULT\
                +vcs+flush+all \
                +lint=TFIPC-L \
                +define+SV_ASSRT_DISABLE \
                -kdb \

SRC_FILE ?=
SRC_FILE += ../../common/rtl/utils/register.sv
SRC_FILE += ../../common/rtl/utils/fifo.sv
SRC_FILE += ../../common/rtl/interface/apb4_if.sv
SRC_FILE += ../../common/rtl/verif/helper.sv
SRC_FILE += ../../common/rtl/verif/test_base.sv
SRC_FILE += ../../common/rtl/verif/apb4_master.sv
SRC_FILE += ../rtl/uart_if.sv
SRC_FILE += ../rtl/uart_tx.sv
SRC_FILE += ../rtl/uart_rx.sv
SRC_FILE += ../rtl/uart_irq.sv
SRC_FILE += ../rtl/apb4_uart.sv
SRC_FILE += ../model/rs232.sv
SRC_FILE += ../tb/uart_test.sv
SRC_FILE += ../tb/test_top.sv
SRC_FILE += ../tb/apb4_uart_tb.sv

SIM_INC ?=
SIM_INC += +incdir+../rtl/
SIM_INC += +incdir+../../common/rtl/
SIM_INC += +incdir+../../common/rtl/interface

SIM_APP  ?= apb4_uart
SIM_TOP  := $(SIM_APP)_tb

WAVE_CFG ?= # WAVE_ON
RUN_ARGS ?=
RUN_ARGS += +${WAVE_CFG}
RUN_ARGS += +WAVE_NAME=$(SIM_TOP).fsdb

comp:
	@mkdir -p build
	cd build && (${SIM_TOOL} ${SIM_OPTIONS} -top $(SIM_TOP) -l compile.log $(SRC_FILE) $(SIM_INC))

run: comp
	cd build && $(SIM_BINY) -l run.log ${RUN_ARGS}

wave:
	${VERDI_TOOL} -ssf build/$(SIM_TOP).fsdb &

clean:
	rm -rf build
	rm -rf verdiLog
	rm -rf novas.*

.PHONY: wave clean
