# Basic Makefile with bits inspired by dash-to-dock

UUID=arc-menu@linxgem33.com
ZIP_FILE=$(UUID).zip
POT_FILEPATH=./po/arc-menu.pot
MO_FILE=arc-menu.mo
GSCHEMA_FILE=org.gnome.shell.extensions.arc-menu.gschema.xml

TO_LOCALIZE=prefs.js menu.js
VERSION=$(shell git log --pretty=format:'%h' -n 1)

ifeq ($(strip $(INSTALL)),system) # check if INSTALL == system
	INSTALL_TYPE=system
	SHARE_PREFIX=$(DESTDIR)/usr/share
	INSTALL_BASE=$(SHARE_PREFIX)/gnome-shell/extensions
else
	INSTALL_TYPE=local
	INSTALL_BASE=~/.local/share/gnome-shell/extensions
endif

JS=*.js
CSS=*.css
MD=*.md
JSON=*.json
TXT=AUTHORS COPYING
DIRS=schemas media
MSG_SRC=$(wildcard ./po/*.po)


all: build

help:
	@echo "Usage: make [help | all | clean | install | jshint | compile | enable | disable]"
	@echo ""
	@echo "all          build the project and create the build directory"
	@echo "clean        delete the build directory"
	@echo "install      install the extension"
	@echo "uninstall    uninstall the extension"
	@echo "enable       enable the extension"
	@echo "disable      disable the extension"
	@echo "jshint       run jshint"
	@echo "compile      compile the gschema xml file"

enable:
	gnome-shell-extension-tool -e $(UUID)

disable:
	gnome-shell-extension-tool -d $(UUID)

clean:
	rm -f ./schemas/gschemas.compiled
	rm -rf ./build
	rm -f $(ZIP_FILE)

jshint:
	jshint $(JS)

test: jshint

install: build
	mkdir -p $(INSTALL_BASE)/$(UUID)
	cp -r ./build/* $(INSTALL_BASE)/$(UUID)
ifeq ($(INSTALL_TYPE),system)
	mkdir -p $(SHARE_PREFIX)/glib-2.0/schemas $(SHARE_PREFIX)/locale
	cp -r ./schemas/$(GSCHEMA_FILE) $(SHARE_PREFIX)/glib-2.0/schemas
	cp -r ./build/locale/* $(SHARE_PREFIX)/locale
endif
	rm -rf ./build

uninstall:
	rm -rf $(INSTALL_BASE)/$(UUID)
ifeq ($(INSTALL_TYPE),system)
	rm -f $(SHARE_PREFIX)/glib-2.0/schemas/$(GSCHEMA_FILE)
	find $(SHARE_PREFIX)/locale -name $(MO_FILE) -type f -delete
endif

translations: $(POT_FILEPATH)
	for l in $(MSG_SRC); do \
		msgmerge -U $$l $(POT_FILEPATH); \
	done;

potfile: $(POT_FILEPATH)

$(POT_FILEPATH): $(TO_LOCALIZE) FORCE
	echo $(POT_FILEPATH)
	xgettext --from-code=UTF-8 -k --keyword=_ --keyword=N_ --add-comments='Translators:' \
		-o $(POT_FILEPATH) --package-name "Arc Menu" $(TO_LOCALIZE)

./po/%.mo: ./po/%.po
	msgfmt -c $< -o $@

compile:
	glib-compile-schemas ./schemas

build: translations compile $(MSG_SRC:.po=.mo)
	mkdir -p ./build
	cp $(JS) $(CSS) $(JSON) $(MD) $(TXT) ./build
	cp -r $(DIRS) ./build
	mkdir -p ./build/locale
	for l in $(MSG_SRC:.po=.mo) ; do \
		lf=./build/locale/`basename $$l .mo`; \
		mkdir -p $$lf/LC_MESSAGES; \
		cp $$l $$lf/LC_MESSAGES/arc-menu.mo; \
	done;
	sed -i 's/"version": -1/"version": "$(VERSION)"/'  build/metadata.json;

zip-file: build
	zip -qr $(ZIP_FILE) ./build
	rm -rf ./build

.PHONY: FORCE
FORCE:
