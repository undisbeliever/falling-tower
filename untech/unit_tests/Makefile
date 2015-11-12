ROM_NAME    = Unit_Tests
CONFIG_FILE = UnitTests.cfg

UNTECH_DIR  = ../src
TEST_DIR    = tests

UNTECH_SRC  = $(wildcard $(UNTECH_DIR)/*/*.s $(UNTECH_DIR)/*/*/*.s)
TESTS       = $(wildcard $(TEST_DIR)/*.s $(TEST_DIR)/*/*.s $(TEST_DIR)/*/*/*.s)

BINARY      = bin/$(ROM_NAME).sfc

TEST_OBJ    = $(patsubst $(TEST_DIR)/%.s,obj/tests/%.o,$(TESTS))
UNTECH_OBJ += $(patsubst ../src/%.s,obj/untech/%.o,$(UNTECH_SRC))
TEST_INC    = $(wildcard $(TEST_DIR)/*.h)
TEST_INC   += $(wildcard $(TEST_DIR)/*.inc)
SRC_INC     = $(wildcard $(UNTECH_DIR)/*/*.h $(UNTECH_DIR)/*/*/*.h)
SRC_INC    += $(wildcard $(UNTECH_DIR)/*/*.inc $(UNTECH_DIR)/*/*/*.inc)
SRC_INC    += $(wildcard $(UNTECH_DIR)/*/*.asm $(UNTECH_DIR)/*/*/*.asm)

OBJECT_DIRS = $(sort $(dir $(UNTECH_OBJ) $(TEST_OBJ)))

# Disable Builtin rules
.SUFFIXES:
.DELETE_ON_ERROR:
MAKEFLAGS += --no-builtin-rules

.PHONY: all
all: dirs resources $(BINARY)

$(BINARY): $(UNTECH_OBJ) $(TEST_OBJ)
	ld65 -vm -m $(@:.sfc=.memlog) -C $(CONFIG_FILE) -o $@ $^
	cd bin/ && ucon64 --snes --nhd --chk $(notdir $@)

$(UNTECH_OBJ): $(SRC_INC) $(CONFIG_FILE) config.h Makefile
obj/untech/%.o: $(UNTECH_DIR)/%.s
	ca65 -I . -I $(UNTECH_DIR) -o $@ $<

$(TEST_OBJ): $(TEST_INC) $(SRC_INC) $(CONFIG_FILE) config.h Makefile
obj/tests/%.o: tests/%.s
	ca65 -I . -I $(UNTECH_DIR) -o $@ $<

obj/tests/font.o: $(wildcard resources/*)


.PHONY: dirs
dirs: bin/ $(OBJECT_DIRS)

bin/ $(OBJECT_DIRS):
	mkdir -p $@


.PHONY: resources
resources:
	$(MAKE) -C resources


.PHONY: clean
clean:
	$(RM) bin/$(BINARY) $(UNTECH_OBJ) $(TEST_OBJ)
	$(MAKE) -C resources clean

