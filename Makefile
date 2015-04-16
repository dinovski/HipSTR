##
## Makefile for StutterTrainer
##

## Default compilation flags.
## Override with:
##   make CXXFLAGS=XXXXX
CXXFLAGS= -O3 -g -D_FILE_OFFSET_BITS=64 -std=c++0x -DMACOSX
#CXXFLAGS= -O0 -g -D_FILE_OFFSET_BITS=64 -std=c++0x

## Source code files, add new files to this list
SRC_COMMON  = error.cpp region.cpp stringops.cpp seqio.cpp zalgorithm.cpp alignment_filters.cpp bam_processor.cpp extract_indels.cpp mathops.cpp
SRC_STUTTER = stutter_main.cpp
SRC_SIEVE   = filter_main.cpp filter_bams.cpp insert_size.cpp
SRC_HIPSTR  = hipstr_main.cpp factor_builder.cpp stutter_model.cpp snp_phasing_quality.cpp snp_tree.cpp em_stutter_genotyper.cpp
SRC_SEQALN  = SeqAlignment/AlignmentData.cpp SeqAlignment/HapAligner.cpp SeqAlignment/RepeatStutterInfo.cpp SeqAlignment/AlignmentModel.cpp SeqAlignment/AlignmentOps.cpp SeqAlignment/HapBlock.cpp SeqAlignment/NWNoRefEndPenalty.cpp SeqAlignment/EMAligner.cpp SeqAlignment/Haplotype.cpp SeqAlignment/RepeatBlock.cpp SeqAlignment/StutterAligner.cpp SeqAlignment/HaplotypeGenerator.cpp

# For each CPP file, generate an object file
OBJ_COMMON  := $(SRC_COMMON:.cpp=.o)
OBJ_STUTTER := $(SRC_STUTTER:.cpp=.o)
OBJ_SIEVE   := $(SRC_SIEVE:.cpp=.o)
OBJ_HIPSTR  := $(SRC_HIPSTR:.cpp=.o)
OBJ_SEQALN  := $(SRC_SEQALN:.cpp=.o)

BAMTOOLS_ROOT=bamtools
LIBDAI_ROOT=/san2/twillems/imputation/str-imputer/libDAI
VCFLIB_ROOT=vcflib

LIBS = -L./ -lz -lm -lgmp -lgmpxx -L$(BAMTOOLS_ROOT)/lib -L$(VCFLIB_ROOT)/tabixpp/
INCLUDE = -I$(BAMTOOLS_ROOT)/src -I$(LIBDAI_ROOT)/include/ -I$(VCFLIB_ROOT)/ -I/usr/local/opt/boost149/include
ARGWEAVER_LIB = argweaver/lib/libargweaver.a
BAMTOOLS_LIB = $(BAMTOOLS_ROOT)/lib/libbamtools.a
LIBDAI_LIB = $(LIBDAI_ROOT)/lib/libdai.a
VCFLIB_LIB = vcflib/libvcflib.a

.PHONY: all
all: BamSieve HipSTR Phaser StutterTrainer test/snp_tree_test test/vcf_snp_tree_test

# Clean the generated files of the main project only (leave Bamtools/vcflib alone)
.PHONY: clean
clean:
	rm -f *.o *.d BamSieve HipSTR Phaser StutterTrainer snp_tree_test vcf_snp_tree_test SeqAlignment/*.o

# Clean all compiled files, including bamtools/vcflib
.PHONY: clean-all
clean-all: clean
	if test -d bamtools/build ; then \
		$(MAKE) -C bamtools/build clean ; \
		rm -rf bamtools/build ; \
	fi

# The GNU Make trick to include the ".d" (dependencies) files.
# If the files don't exist, they will be re-generated, then included.
# If this causes problems with non-gnu make (e.g. on MacOS/FreeBSD), remove it.
include $(subst .cpp,.d,$(SRC))

# The resulting binary executable
StutterTrainer: $(OBJ_COMMON) $(OBJ_STUTTER) $(BAMTOOLS_LIB)
	$(CXX) $(CXXFLAGS) $(INCLUDE) -o $@ $^ $(LIBS)

BamSieve: $(OBJ_COMMON) $(OBJ_SIEVE) $(BAMTOOLS_LIB)
	$(CXX) $(CXXFLAGS) $(INCLUDE) -o $@ $^ $(LIBS)

HipSTR: $(OBJ_COMMON) $(OBJ_HIPSTR) $(BAMTOOLS_LIB) $(VCFLIB_LIB) $(LIBDAI_LIB) $(OBJ_SEQALN)
	$(CXX) $(CXXFLAGS) $(INCLUDE) -o $@ $^ $(LIBS)

Phaser: phase_main.cpp error.cpp $(LIBDAI_LIB)
	$(CXX) $(CXXFLAGS) $(INCLUDE) -o $@ $^ $(LIBS)

test/snp_tree_test: snp_tree.cpp test/snp_tree_test.cpp $(VCFLIB_LIB)
	$(CXX) $(CXXFLAGS) $(INCLUDE) -o $@ $^ $(LIBS)

test/vcf_snp_tree_test: test/vcf_snp_tree_test.cpp snp_tree.cpp $(VCFLIB_LIB)
	$(CXX) $(CXXFLAGS) $(INCLUDE) -o $@ $^ $(LIBS)

# Build each object file independently
%.o: %.cpp $(BAMTOOLS_LIB)
	$(CXX) $(CXXFLAGS) $(INCLUDE) -o $@ -c $<

# Auto-Generate header dependencies for each CPP file.
%.d: %.cpp $(BAMTOOLS_LIB)
	$(CXX) -c -MP -MD $(CXXFLAGS) $(INCLUDE) $< > $@

# Rebuild BAMTools if needed
$(BAMTOOLS_LIB):
	git submodule update --init --recursive bamtools
	git submodule update --recursive bamtools
	( cd bamtools && mkdir build && cd build && cmake .. && $(MAKE) )

# Rebuild VCFLIB if needed                                                                                                                                                                         
$(VCFLIB_LIB):
	git submodule update --init --recursive vcflib
	git submodule update --recursive vcflib
	cd vcflib && $(MAKE)

# TO DO: Rebuild libDAI if needed