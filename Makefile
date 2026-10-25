# SPDX-License-Identifier: GPL-3.0-or-later
# CeylonDemon — Copyright (C) 2026 Madushan Dissanayake.
#
#   make                      release build, x86-64-avx2, network embedded
#   make ARCH=x86-64-bmi2     add BMI2/PEXT (Skylake and later, fast PEXT)
#   make ARCH=native          tune to this machine
#   make EVALFILE=path.aa     embed a different network
#   make clean

CXX      ?= g++
ARCH     ?= x86-64-avx2
EVALFILE ?= networks/ceylondemon-3.1-resonance-v12-400m-full-scratch-e8.aa
TUNE     ?= 0
EXE      ?= dist/CeylonDemon-3.3-$(ARCH)

SRC := src/main.cpp

CXXFLAGS := -std=c++20 -O3 -flto -pthread -DNDEBUG -Wall -Wextra -Wshadow
ifeq ($(TUNE),1)
    CXXFLAGS += -DCEYLON_TUNE
endif
LDFLAGS  := -static

ifeq ($(ARCH),android-arm64)
    ARCHFLAGS := -march=armv8-a+simd -mtune=cortex-a53
    LDFLAGS  :=
else ifeq ($(ARCH),native)
    ARCHFLAGS := -march=native
else ifeq ($(ARCH),x86-64-bmi2)
    ARCHFLAGS := -m64 -mpopcnt -msse -msse2 -mssse3 -msse4.1 -mavx2 -mbmi -mbmi2
else
    ARCHFLAGS := -m64 -mpopcnt -msse -msse2 -mssse3 -msse4.1 -mavx2
endif

# The network is linked into the executable so a release is a single file.
# .incbin uses the assembler include path; Android workflow also copies the network basename to the working directory.
ifneq (,$(wildcard $(EVALFILE)))
    NETFLAGS := -DCEYLON_EMBEDDED_NET=$(notdir $(EVALFILE)) -Wa,-I,$(abspath $(dir $(EVALFILE)))
else
    $(info No $(EVALFILE) found - the engine will look for a network on disk.)
    NETFLAGS :=
endif

# GCC needs a writable directory for intermediate files. MSYS2's make strips
# TMP and TEMP from recipe environments, which leaves the compiler falling back
# to C:\WINDOWS and failing with "Cannot create temporary file". Pin all three
# to an absolute path inside the tree; on Windows GCC reads TMP/TEMP, not
# TMPDIR, so exporting only TMPDIR is not enough. Harmless elsewhere.
TMPDIR := $(CURDIR)/build/tmp
TMP    := $(TMPDIR)
TEMP   := $(TMPDIR)
export TMPDIR TMP TEMP

# Quoted: the path routinely contains spaces on Windows user profiles.
$(shell mkdir -p "$(TMPDIR)" dist)

.PHONY: all clean
all: $(EXE)

$(EXE): $(SRC) $(wildcard src/*.h) $(EVALFILE)
	$(CXX) $(CXXFLAGS) $(ARCHFLAGS) $(NETFLAGS) -o $@ $(SRC) $(LDFLAGS)
	@echo "Built $@"

clean:
	rm -rf dist build
