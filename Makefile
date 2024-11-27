include .cfg.mk

ifneq ($(INC_SOURCE),)
	INC_OPTS=--include $(INC_SOURCE)
endif

all:
	./.gen.sh --out ${CLIOUT} $(INC_OPTS)

