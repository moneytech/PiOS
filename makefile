TOOL = arm-none-eabi
CFLAGS = -Wall -nostdlib -nostartfiles -ffreestanding --no-common -Wpadded -march=armv6j -mtune=arm1176jzf-s -mfpu=vfp -mfloat-abi=hard -fno-omit-frame-pointer -mno-thumb-interwork -mlong-calls -marm
LINKER_FLAGS = --no-wchar-size-warning --no-undefined

ASSEMBLER_FLAGS = -march=armv6j  -mfpu=vfp -mfloat-abi=hard

# Make sure gcc searches the include folder
C_INCLUDE_PATH=include;csud\include
export C_INCLUDE_PATH

LIBRARIES = csud
BUILD_DIR = bin
SOURCE_DIR = source
INCLUDE_DIR = include
OBJ_DIR = $(BUILD_DIR)/obj
DEPENDENCY_DIR = $(BUILD_DIR)/dependencies

# When building C files, look in all subdirectories of source
VPATH := $(shell find $(SOURCE_DIR)/ -type d)
# (And headers too!)
VPATH += $(shell find $(INCLUDE_DIR)/ -type d)

CHEADERS := $(shell find $(INCLUDE_DIR)/ -name '*.h')
CSOURCE := $(shell find $(SOURCE_DIR)/ -name '*.c')
ASOURCE := $(wildcard $(SOURCE_DIR)/*.s)

_COBJECT := $(patsubst %.c,%.o, $(CSOURCE))
_AOBJECT := $(patsubst %.s,%.o, $(ASOURCE))
AOBJECT = $(addprefix $(OBJ_DIR)/, $(notdir $(_AOBJECT)))
COBJECT = $(addprefix $(OBJ_DIR)/, $(notdir $(_COBJECT)))

# To figure out why objects are being build, uncomment this:
#OLD_SHELL := $(SHELL)
#SHELL = $(warning [Evaluating target:'$@' Prereqs:'$^' Never:'$?'])$(OLD_SHELL)

.PHONY: directories

PiOS: directories $(BUILD_DIR)/kernel.img

# Create the final binary
$(BUILD_DIR)/kernel.img: $(BUILD_DIR)/kernel.elf $(BUILD_DIR)/symbols.txt $(BUILD_DIR)/disassembly.txt
	@$(TOOL)-objcopy $(BUILD_DIR)/kernel.elf -O binary $(BUILD_DIR)/kernel.img

# Create disassembly for ease of debugging
$(BUILD_DIR)/disassembly.txt: $(BUILD_DIR)/kernel.elf
	@$(TOOL)-objdump -D $< > $@
	
# Dump symbol table for functions
$(BUILD_DIR)/symbols.txt: $(BUILD_DIR)/kernel.elf
	@$(TOOL)-objdump -t $< | awk -F ' ' '{if(NF >= 2) print $$(1), "\t", $$(NF);}' > $@

# Link all of the objects (Temporarily removed -l $(LIBRARIES))
$(BUILD_DIR)/kernel.elf: $(AOBJECT) $(COBJECT) libcsud.a
	@$(TOOL)-ld $(LINKER_FLAGS) $(AOBJECT) $(COBJECT) -Map $(BUILD_DIR)/kernel.map -T memorymap -o $(BUILD_DIR)/kernel.elf

# If make was run previously, we will have .d dependency files
# Describing wihich headers the objects depend on, import those targets

-include $(addprefix $(DEPENDENCY_DIR)/, $(notdir $(COBJECT:.o=.d)))
	
#build c files
$(OBJ_DIR)/%.o: %.c
	@$(TOOL)-gcc -c $< -o $@ $(CFLAGS) -MD -MF $(DEPENDENCY_DIR)/$*.d 
	
# Create a temp file
	@mv -f $(DEPENDENCY_DIR)/$*.d $(DEPENDENCY_DIR)/$*.d.tmp
	
# Open dependency file, append OBJ_DIR to target and create empty targets for all dependencies
# So that MAKE doesn't complain if a dependency is removed/renamed and still builds everything that used to depend on it
	@sed -e 's|.*: |$(OBJ_DIR)/$*.o:|' < $(DEPENDENCY_DIR)/$*.d.tmp > $(DEPENDENCY_DIR)/$*.d
	@sed -e 's/.*: //' -e 's/\\$$//' < $(DEPENDENCY_DIR)/$*.d.tmp | fmt -1 | sed -e 's/*//' -e 's/$$/: /' >> $(DEPENDENCY_DIR)/$*.d
	  
# Remove the temp file
	@rm -f $(DEPENDENCY_DIR)/$*.d.tmp

#build s files (Assembly)
$(OBJ_DIR)/%.o: $(SOURCE_DIR)/%.s
	@$(TOOL)-as $(ASSEMBLER_FLAGS) $< -o $@
	
directories:
	@mkdir -p $(OBJ_DIR)
	@mkdir -p $(DEPENDENCY_DIR)
	
.PHONY: clean
    clean:
	@rm -rf $(BUILD_DIR)/*