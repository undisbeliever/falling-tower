ROM_NAME    = Falling_Tower
CONFIG_FILE = LOROM_1MBit_copyright.cfg

UNTECH_DIR  = untech/src
SRC_DIR     = src

UNTECH_MODS = common/reset common/sfc-header common/math/division common/math/multiplication
UNTECH_MODS+= common/string common/console metasprite/metasprite

SOURCES     = $(wildcard $(SRC_DIR)/*.s $(SRC_DIR)/*/*.s $(SRC_DIR)/*/*/*.s)
UNTECH_SRC  = $(patsubst %,$(UNTECH_DIR)/%.s,$(UNTECH_MODS))

BINARY      = bin/$(ROM_NAME).sfc

SRC_OBJ     = $(patsubst $(SRC_DIR)/%.s,obj/%.o,$(SOURCES))
UNTECH_OBJ += $(patsubst $(UNTECH_DIR)/%.s,obj/untech/%.o,$(UNTECH_SRC))
SRC_INC     = $(wildcard $(SRC_DIR)/*.h $(SRC_DIR)/*/*.h)
SRC_INC    += $(wildcard $(SRC_DIR)/*.inc $(SRC_DIR)/*.inc)
SRC_INC    += $(wildcard $(UNTECH_DIR)/*/*.h $(UNTECH_DIR)/*/*/*.h)
SRC_INC    += $(wildcard $(UNTECH_DIR)/*/*.inc $(UNTECH_DIR)/*/*/*.inc)
SRC_INC    += $(wildcard $(UNTECH_DIR)/*/*.asm $(UNTECH_DIR)/*/*/*.asm)

OBJECT_DIRS = $(sort $(dir $(UNTECH_OBJ) $(SRC_OBJ)))

# Disable Builtin rules
.SUFFIXES:
.DELETE_ON_ERROR:
MAKEFLAGS += --no-builtin-rules

.PHONY: all
all: dirs resources $(BINARY)

$(BINARY): $(UNTECH_OBJ) $(SRC_OBJ)
	ld65 -vm -m $(@:.sfc=.memlog) -C $(CONFIG_FILE) -o $@ $^
	cd bin/ && ucon64 --snes --nhd --chk $(notdir $@)

$(UNTECH_OBJ): $(SRC_INC) $(CONFIG_FILE) config.h Makefile
obj/untech/%.o: $(UNTECH_DIR)/%.s
	ca65 -I . -I $(UNTECH_DIR) -o $@ $<

$(SRC_OBJ): $(SRC_INC) $(SRC_INC) $(CONFIG_FILE) config.h Makefile
obj/%.o: src/%.s
	ca65 -I . -I $(SRC_DIR) -I $(UNTECH_DIR) -o $@ $<

obj/resources/font.o: $(wildcard resources/font.*)
obj/resources/metasprites.o: $(wildcard resources/metasprites/*)

obj/entity.o: src/entity-collisions.asm

.PHONY: dirs
dirs: bin/ $(OBJECT_DIRS)

bin/ $(OBJECT_DIRS):
	mkdir -p $@


.PHONY: resources
resources:
	$(MAKE) -C resources


.PHONY: clean
clean:
	$(RM) bin/$(BINARY) $(UNTECH_OBJ) $(SRC_OBJ)
	$(MAKE) -C resources clean

