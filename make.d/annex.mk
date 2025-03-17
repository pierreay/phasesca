# Variables
# ==============================================================================

# Full path of the Makefile.
MAKEFILE_PATH := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
# Full path of local binaries directory.
BIN_PATH := ${HOME}/.local/bin
# Hostname based on our PHS definition.
HOSTNAME_PHS := $(shell $(BIN_PATH)/zsh-func.sh phs_get_fp2r $(MAKEFILE_PATH))

# Targets
# ==============================================================================

annex-all: annex-reinit annex-config

annex-reinit:
	$(BIN_PATH)/git-annex-init "$$(realpath .)" "$$(basename $$(realpath .))" "$$($(BIN_PATH)/zsh-func.sh phs_get_fp2r $$(realpath .))"

annex-config: annex-config-remote annex-config-group

annex-config-remote:
ifeq ($(HOSTNAME_PHS),cintra)
	git remote remove local || true
	$(BIN_PATH)/zsh-func.sh git-annex-add-remote -f local $$($(BIN_PATH)/zsh-func.sh phs_get_r2fp ${PHS_FP_SRV_ANNEX} local)
endif
ifeq ($(HOSTNAME_PHS),normandy)
	git remote remove cintra || true
	$(BIN_PATH)/zsh-func.sh git-annex-add-remote -f cintra $$($(BIN_PATH)/zsh-func.sh phs_get_r2fp ${PHS_FP_SRV_ANNEX} cintra)
endif
	git remote -v

annex-config-group:
	$(BIN_PATH)/git-annex-group-reset "$$(realpath .)"
ifeq ($(HOSTNAME_PHS),cintra)
	git annex group . transfer
	git annex wanted . "standard"
endif
ifeq ($(HOSTNAME_PHS),normandy)
	git annex group . source
	git annex wanted . "standard"
endif
