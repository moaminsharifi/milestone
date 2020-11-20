.PHONY: all install uninstall

all: link


link:
	chmod +x practice-manager
ifeq ($(wildcard ~/.local/bin/),)
	mkdir -p ~/.local/bin/
endif
ifneq ($(wildcard ~/.local/bin/practice-manager),)
	unlink ~/.local/bin/practice-manager
endif
	ln -s $$PWD/practice-manager ~/.local/bin/practice-manager

unlink:
ifneq ($(wildcard ~/.local/bin/practice-manager),)
	unlink ~/.local/bin/practice-manager
else
	@echo "nothing to unlink"
endif
