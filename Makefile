#--SETTINGS--

# Directory in which there are source files.
SOURCE_DIRECTORY := src

# Directory in which there are resources (like images, sounds, etc.).
RESOURCES_DIRECTORY := res

# Directory in which the program along with the resources will be outputted in.
OUTPUT_DIRECTORY := bin

# The executable's name (add .exe if on windows)
EXECUTABLE_NAME := BG3DRoomEditor

# Run the project immediately after export?
RUN = true

# Type of optimization to use. Options: none, minimal, size, speed, aggressive
OPTIMIZATION = none

#--SCRIPT--

build:
	mkdir -p $(OUTPUT_DIRECTORY)
	odin build $(SOURCE_DIRECTORY) -out:$(OUTPUT_DIRECTORY)/$(EXECUTABLE_NAME) -o:$(OPTIMIZATION)
	# cp -r $(RESOURCES_DIRECTORY) $(OUTPUT_DIRECTORY)	# No need to copy the resource folder, everything is embedded now ;)	

ifeq ($(RUN), true)
	./$(OUTPUT_DIRECTORY)/$(EXECUTABLE_NAME)
endif

clean:
	rm -rf $(OUTPUT_DIRECTORY)