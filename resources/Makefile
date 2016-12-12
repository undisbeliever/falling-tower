
METASPRITE_PCX  := $(wildcard metasprites/*.pcx)
METASPRITE_4BPP := $(patsubst %.pcx,%.4bpp, $(METASPRITE_PCX))
METASPRITE_CLR := $(patsubst %.pcx,%.clr, $(METASPRITE_PCX))


.PHONY: all
all: font metasprites


.PHONY: font
font: font.2bpp font.clr

font.2bpp font.clr: font.pcx
	pcx2snes -n -s8 -c4 -o2 font
	mv font.pic font.2bpp


.PHONY: metasprites
metasprites: $(METASPRITE_4BPP) $(METASPRITE_CLR)

metasprites/%.4bpp metasprites/%.clr: metasprites/%.pcx
	pcx2snes -n -s8 -c16 $(basename $<)
	mv $(basename $<).pic $(basename $<).4bpp


.PHONY: clean
clean:
	$(RM) font.2bpp font.clr
	$(RM) $(METASPRITE_4BPP)
	$(RM) $(METASPRITE_CLR)

