
.PHONY: all
all: font.2bpp font.clr

font.2bpp font.clr: font.pcx
	pcx2snes -n -s8 -c4 -o2 font
	mv font.pic font.2bpp


.PHONY: clean
clean:
	$(RM) font.2bpp font.clr


