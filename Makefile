# the compiler: clang is preferred.
CC = clang

# compiler flags:
# -Wall		turns on most, but not all, compiler warning.
CFLAGS = -Wall

# framework flags:
FMWKFLAGS = -framework CoreFoundation -framework CoreGraphics

# the build target executable:
TARGET = displix
#
# build destination:
BUILDDIR = .

all: $(TARGET)

$(TARGET): $(TARGET).c
	$(CC) $(CFLAGS) $(FMWKFLAGS) -o $(BUILDDIR)/$(TARGET) $(TARGET).c

clean:
	$(RM) $(BUILDDIR)/$(TARGET)

$(shell mkdir -p $(BUILDDIR))
