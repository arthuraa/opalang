#!/usr/bin/env make

# [ Warning ] don't use make to solve dependencies !!
#
# we rely on ocamlbuild which already handles them ; every rule should
# call it only once (no recursion)
#
# More info in tools/build/Makefile.bld and tools/build/README

.PHONY: default
default: node

CONFIG_PATH = tools/build

include $(CONFIG_PATH)/config.make

MAKE ?= $_
OCAMLBUILD_OPT ?= -j 6

ifndef NO_REBUILD_OPA_PACKAGES
OPAOPT += --rebuild
endif

ifneq ($(HAS_CAMLIDL)$(HAS_LIBNATPMP)$(HAS_MINIUPNPC),111)
DISABLED_LIBS = libnattraversal
endif

export

include tools/build/Makefile.bld

##
## STANDARD TARGETS
##

.PHONY: node
node: $(MYOCAMLBUILD)
	$(OCAMLBUILD) $(call target-tools,$(ALL_TOOLS)) opa-node-packages.stamp
	@$(call copy-tools,$(ALL_TOOLS))
	$(MAKE) manpages
	$(MAKE) $(OPA_TOOLS)

.PHONY: all
all: $(MYOCAMLBUILD)
	$(OCAMLBUILD) $(call target-tools,$(ALL_TOOLS)) opa-both-packages.stamp
	@$(call copy-tools,$(ALL_TOOLS))
	$(MAKE) manpages
	$(MAKE) $(OPA_TOOLS)

.PHONY: build
build: all

.PHONY: runtime-libs
runtime-libs: $(MYOCAMLBUILD)
	$(OCAMLBUILD) runtime-libs.stamp

.PHONY: $(BUILD_DIR)/bin/opa
$(BUILD_DIR)/bin/opa: $(MYOCAMLBUILD)
	$(OCAMLBUILD) opa-node-packages.stamp $(target-tool-opa-bin)
	@$(copy-tool-opa-bin)
	@tools/utils/install.sh --quiet --dir $(realpath $(BUILD_DIR)) --ocaml-prefix $(OCAMLLIB)/../../..

.PHONY: opa
opa: $(BUILD_DIR)/bin/opa

.PHONY: opa-flat-packages opa-node-packages opa-both-packages
opa-flat-packages: $(MYOCAMLBUILD)
	$(OCAMLBUILD) opa-packages.stamp
opa-node-packages: $(MYOCAMLBUILD)
	$(OCAMLBUILD) opa-node-packages.stamp
opa-both-packages: $(MYOCAMLBUILD)
	$(OCAMLBUILD) opa-both-packages.stamp

.PHONY: stdlib stdlib-flat stdlib-node
stdlib: opa-both-packages
stdlib-flat: opa-flat-packages
stdlib-node: opa-node-packages

DISTRIB_TOOLS = opa-bin opa-plugin-builder-bin opa-plugin-browser-bin bslServerLib.ml # opa-cloud opa-db-server opa-db-tool opatop opa-translate

OPA_TOOLS = opa-create

.PHONY: distrib
distrib: $(MYOCAMLBUILD)
	$(OCAMLBUILD) $(call target-tools,$(DISTRIB_TOOLS)) opa-node-packages.stamp
	@$(call copy-tools,$(DISTRIB_TOOLS))
	@tools/utils/install.sh --quiet --dir $(realpath $(BUILD_DIR)) --ocaml-prefix $(OCAMLLIB)/../../.. --prefix $(realpath $(BUILD_DIR))
	$(MAKE) manpages
	$(MAKE) $(OPA_TOOLS)

.PHONY: distrib-all
distrib-all: $(MYOCAMLBUILD)
	$(OCAMLBUILD) $(call target-tools,$(DISTRIB_TOOLS)) opa-both-packages.stamp
	@$(call copy-tools,$(DISTRIB_TOOLS))
	$(MAKE) manpages
	$(MAKE) $(OPA_TOOLS)

##
## MANPAGES
##

.PHONY: manpages
manpages: $(MYOCAMLBUILD)
ifndef NO_MANPAGES
	$(MAKE) -C tools/manpages OCAMLBUILD="$(OCAMLBUILD)" BLDDIR=../../$(BUILD_DIR)
else
	@echo "Not building manpages"
endif

##
## OPA-CREATE
##

target-tool-opa-create = tools/opa-create/src/opa-create.exe

.PHONY: opa-create
opa-create: $(MYOCAMLBUILD)
	$(OCAMLBUILD) $(target-tool-opa-create)
	@mkdir -p $(BUILD_DIR)/bin
	$(INSTALL) $(BUILD_DIR)/$(target-tool-opa-create) $(BUILD_DIR)/bin/opa-create
	@chmod 755 $(BUILD_DIR)/bin/opa-create

.PHONY: install-opa-create
install-opa-create:
	@mkdir -p $(PREFIX)/bin
	$(INSTALL) $(BUILD_DIR)/bin/opa-create $(INSTALL_DIR)/bin/opa-create
	@chmod 755 $(INSTALL_DIR)/bin/opa-create

##
## INSTALLATION
##

.PHONY: install*

STDLIB_DIR = $(INSTALL_DIR)/lib/opa/stdlib

FLAT_STDLIB_SUFFIX_DIR=stdlib.qmlflat
STDLIB_FLAT_DIR=$(STDLIB_DIR)/$(FLAT_STDLIB_SUFFIX_DIR)
BUILD_FLAT_DIR=$(BUILD_DIR)/$(FLAT_STDLIB_SUFFIX_DIR)
define install-package
@printf "Installing into $(STDLIB_FLAT_DIR)/$*.opx[K\r"
@mkdir -p "$(STDLIB_FLAT_DIR)/$*.opx/_build"
@find "$(BUILD_FLAT_DIR)/$*.opx" -maxdepth 1 ! -type d -exec $(INSTALL) {} "$(STDLIB_FLAT_DIR)/$*.opx/" \;
@$(INSTALL) $(BUILD_FLAT_DIR)/$*.opx/_build/*.a "$(STDLIB_FLAT_DIR)/$*.opx/_build/"
@$(INSTALL) $(BUILD_FLAT_DIR)/$*.opx/_build/*.cmi "$(STDLIB_FLAT_DIR)/$*.opx/_build/"
@$(INSTALL) $(BUILD_FLAT_DIR)/$*.opx/_build/*.cmxa "$(STDLIB_FLAT_DIR)/$*.opx/_build/"
endef

NODE_STDLIB_SUFFIX_DIR=stdlib.qmljs
STDLIB_NODE_DIR=$(STDLIB_DIR)/$(NODE_STDLIB_SUFFIX_DIR)
BUILD_NODE_DIR=$(BUILD_DIR)/$(NODE_STDLIB_SUFFIX_DIR)
define install-node-package
@printf "Installing into $(STDLIB_NODE_DIR)/$*.opx[K\r"
@mkdir -p "$(STDLIB_NODE_DIR)/$*.opx/_build"
@find "$(BUILD_NODE_DIR)/$*.opx" -maxdepth 1 ! -type d -exec $(INSTALL) {} "$(STDLIB_NODE_DIR)/$*.opx/" \;
@$(INSTALL) $(BUILD_NODE_DIR)/$*.opx/*.js "$(STDLIB_NODE_DIR)/$*.opx/"
endef

PLUGINS_DIR=lib/plugins
define install-plugin
@printf "Installing into $(STDLIB_DIR)/$*.opp^[[K\r"
@mkdir -p "$(STDLIB_DIR)/$*.opp"
@$(INSTALL) $(BUILD_DIR)/$(PLUGINS_DIR)/$*.opp/*.bypass "$(STDLIB_DIR)/$*.opp/";
@$(if $(wildcard $(BUILD_DIR)/$(PLUGINS_DIR)/$*.opp/*NodeJsPackage.js), $(INSTALL) $(BUILD_DIR)/$(PLUGINS_DIR)/$*.opp/*NodeJsPackage.js "$(STDLIB_DIR)/$*.opp/")
@$(if $(wildcard $(BUILD_DIR)/$(PLUGINS_DIR)/$*.opp/package.json), $(INSTALL) $(BUILD_DIR)/$(PLUGINS_DIR)/$*.opp/package.json "$(STDLIB_DIR)/$*.opp/")
@$(if $(wildcard $(BUILD_DIR)/$(PLUGINS_DIR)/$*.opp/*MLRuntime.*), $(INSTALL) $(BUILD_DIR)/$(PLUGINS_DIR)/$*.opp/*MLRuntime.* "$(STDLIB_DIR)/$*.opp/")
endef


# List all packages and plugins in stdlib
OPA_PACKAGES := $(shell cd lib/stdlib && ./all_packages.sh)
OPA_PLUGINS  := $(shell cd lib/stdlib && ./all_plugins.sh && echo "opabsl")

# Rules installing everything that has been compiled
#
# This doesn't rely on install rules generated by Makefile.bld ;
# instead it assumes that what you want to install has been properly
# put in $(BUILD_DIR)/{bin,lib/opa,share/opa,share/man}.
#
# This is the case of tools (because of Makefile.bld),
# and of opa runtime libs (because build rules copy them
# to $(BUILD_DIR)/lib/opa/static).
# This doesn't install the other libs though, use target install-libs
# for that

install-packageopt-%:
	$(if $(wildcard $(BUILD_FLAT_DIR)/$*.opx/_build/*),$(install-package))

install-node-packageopt-%:
	$(if $(wildcard $(BUILD_NODE_DIR)/$*.opx/*.js),$(install-node-package))

install-package-%:
	$(install-package)

install-node-package-%:
	$(install-node-package)

install-packages: $(addprefix install-packageopt-,$(OPA_PACKAGES))
	@printf "Installation to $(STDLIB_FLAT_DIR) done.[K\n"

install-node-packages: $(addprefix install-node-packageopt-,$(OPA_PACKAGES))
	@printf "Installation to $(STDLIB_NODE_DIR) done.[K\n"

install-all-packages: $(addprefix install-package-,$(OPA_PACKAGES))
	@printf "Installation to $(STDLIB_FLAT_DIR) done.[K\n"

install-pluginopt-%:
	$(if $(wildcard $(BUILD_DIR)/$(PLUGINS_DIR)/$*.opp/),$(install-plugin))

install-plugin-%:
	$(install-plugin)

install-plugins: $(addprefix install-pluginopt-,$(OPA_PLUGINS))
	@printf "Installation to $(STDLIB_DIR) done.[K\n"

install-all-plugins: $(addprefix install-plugin-,$(OPA_PLUGINS))
	@printf "Installation to $(STDLIB_DIR) done.[K\n"



install-bin:
	@printf "Installing into $(INSTALL_DIR)/bin[K\r"
	@mkdir -p $(INSTALL_DIR)/bin
	@$(if $(wildcard $(BUILD_DIR)/bin/*),$(INSTALL) -r $(BUILD_DIR)/bin/* $(INSTALL_DIR)/bin)
	@tools/utils/install.sh --quiet --dir $(INSTALL_DIR) --ocamllib $(OCAMLLIB) --ocamlopt $(OCAMLOPT)
	@printf "Installation to $(INSTALL_DIR)/bin done.[K\n"

install-lib:
	@printf "Installing into $(INSTALL_DIR)/lib/opa[K\r"
	@rm -f $(BUILD_DIR)/lib/opa/static/opabslMLRuntime.cmi
	@mkdir -p $(INSTALL_DIR)/lib/opa
	@$(if $(wildcard $(BUILD_DIR)/lib/opa/*),$(INSTALL) -r $(BUILD_DIR)/lib/opa/* $(INSTALL_DIR)/lib/opa/)
	@printf "Installation to $(INSTALL_DIR)/lib/opa done.[K\n"

install-share:
	@printf "Installing into $(INSTALL_DIR)/share/opa[K\r"
	@mkdir -p $(INSTALL_DIR)/share/opa
	@$(if $(wildcard $(BUILD_DIR)/share/opa/*),$(INSTALL) -r $(BUILD_DIR)/share/opa/* $(INSTALL_DIR)/share/opa/)
	@printf "Installation to $(INSTALL_DIR)/share/opa done.[K\n"

install-man:
	@printf "Installing into $(INSTALL_DIR)/share/man[K\r"
	@if [ -d $(BUILD_DIR)/man/man1 ]; then \
	  mkdir -p $(INSTALL_DIR)/share/man/man1; \
	fi
	@$(if $(wildcard $(BUILD_DIR)/man/man1/*.1.gz),$(INSTALL) -r $(BUILD_DIR)/man/man1/*.1.gz $(INSTALL_DIR)/share/man/man1)
	@printf "Installation to $(INSTALL_DIR)/share/man done.[K\n"

install: install-bin install-lib install-share install-plugins install-packages install-node-packages install-man
	@printf "Installation into $(INSTALL_DIR) done.[K\n"

install-node: install-bin install-lib install-share install-plugins install-node-packages install-man
	@printf "Installation into $(INSTALL_DIR) done.[K\n"

.PHONY: uninstall
uninstall:
	rm -rf $(INSTALL_DIR)/lib/opa
	@[ ! -d $(INSTALL_DIR)/lib ] || [ -n "`ls -A $(INSTALL_DIR)/lib`" ] || rmdir $(INSTALL_DIR)/lib
	rm -rf $(INSTALL_DIR)/share/opa
	rm -rf $(INSTALL_DIR)/share/doc/opa
# 	TODO: remove all installed opa manpages
# 	rm -rf $(INSTALL_DIR)/share/man/man1/opa*
	@[ ! -d $(INSTALL_DIR)/share ] || [ -n "`ls -A $(INSTALL_DIR)/share`" ] || rmdir $(INSTALL_DIR)/share
	$(foreach file,$(wildcard $(BUILD_DIR)/bin/*),rm -f $(INSTALL_DIR)/bin/$(notdir $(file));)
	@tools/utils/install.sh --uninstall --dir $(INSTALL_DIR)
	@[ ! -d $(INSTALL_DIR)/bin ] || [ -n "`ls -A 	$(INSTALL_DIR)/bin`" ] || rmdir $(INSTALL_DIR)/bin
	@printf "Uninstall done.[K\n"

# Install our ocamlbuild-generation engine
install-bld:
	@mkdir -p $(INSTALL_DIR)/bin
	@echo "#!/usr/bin/env bash" > $(INSTALL_DIR)/bin/bld
	@echo "set -e" >> $(INSTALL_DIR)/bin/bld
	@echo "set -u" >> $(INSTALL_DIR)/bin/bld
	@chmod 755 $(INSTALL_DIR)/bin/bld
	@echo "BLDDIR=$(PREFIX)/share/opa/bld $(PREFIX)/share/opa/bld/gen_myocamlbuild.sh" >> $(INSTALL_DIR)/bin/bld
	@echo "_build/myocamlbuild -no-plugin $(OCAMLBUILD_OPT) \"\$$@\"" >> $(INSTALL_DIR)/bin/bld
	@mkdir -p $(INSTALL_DIR)/share/opa/bld
	@$(INSTALL) tools/build/gen_myocamlbuild.sh tools/build/myocamlbuild_*fix.ml $(CONFIG_PATH)/config.sh $(CONFIG_PATH)/config.mli $(CONFIG_PATH)/config.ml\
	  $(INSTALL_DIR)/share/opa/bld

# Install an opa wrapper with different stdlib and options (for some backwards-compatibility)
install-qmlflat: # depends on opabsl_for_compiler, but we don't want to run ocamlbuild twice
	@mkdir -p $(INSTALL_DIR)/bin $(INSTALL_DIR)/share/opa/mlstatebsl
	@$(INSTALL) $(BUILD_DIR)/$(PLUGINS_DIR)/opabsl.opp/lib/plugins/opabsl/mlstatebsl/opabsl_*.opa $(INSTALL_DIR)/share/opa/mlstatebsl
	@echo "#!/usr/bin/env bash" > $(INSTALL_DIR)/bin/qmlflat
	@echo "set -e" >> $(INSTALL_DIR)/bin/qmlflat
	@echo "set -u" >> $(INSTALL_DIR)/bin/qmlflat
	@chmod 755 $(INSTALL_DIR)/bin/qmlflat
	@echo 'exec opa --parser classic --no-stdlib --no-server --no-cps --no-closure --no-ei --no-constant-sharing --no-undot --separated off --value-restriction disabled --no-warn duplicateL0  --no-warn typer.warncoerce --no-warn unused --no-discard-of-unused-stdlib --no-warn pattern $(STDLIB_DIR)/opabsl.opp $$(if ! grep -qE "(^| )--no-stdlib( |$$)" <<<"$$*"; then echo $(INSTALL_DIR)/share/opa/mlstatebsl/*.opa; fi) "$$@"' \
	>> $(INSTALL_DIR)/bin/qmlflat

# installs some dev tools on top of the normal install; these should not change often
install-all: install install-bld install-qmlflat tools/maxmem
	@$(INSTALL) tools/platform_helper.sh $(INSTALL_DIR)/bin/
	@$(INSTALL) tools/maxmem $(INSTALL_DIR)/bin/
	@rm tools/maxmem
	@$(INSTALL) tools/plotmem $(INSTALL_DIR)/bin/

##
## DOCUMENTATION
##
# (in this section, multiple calls to ocamlbuild are tolerated)

.PHONY: doc.jsbsl
doc.jsbsl: $(MYOCAMLBUILD)
	$(OCAMLBUILD) $@/index.html

# this rules provides the doc.html target (from Makefile.bld)
# the sed are just there to help sorting by filename-within-directory
.PHONY: doc.odocl
doc.odocl:
	echo $(foreach lib,$(ALL_LIBS),$(lib-cmi-$(lib):%.cmi=%)) \
	| sed 's# \+#\n#g' \
	| sed 's#\(.*\)/\([^/]*\)#\1 \2#' \
	| sort -k 2 -u \
	| sed 's#\(.*\) \([^ ]*\)#\1/\2#' \
	>$@

.PHONY: packages-api
packages-api: $(MYOCAMLBUILD)
	OPAOPT="$(OPAOPT) --api --parser classic" $(OCAMLBUILD) opa-node-packages.stamp
