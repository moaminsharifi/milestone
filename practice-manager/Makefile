.PHONY: all install uninstall link unlink

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

install:
ifeq ($(wildcard ~/.local/bin/),)
	mkdir -p ~/.local/bin/
endif
	cp practice-manager ~/.local/bin/practice-manager

uninstall:
	rm -f ~/.local/bin/practice-manager
