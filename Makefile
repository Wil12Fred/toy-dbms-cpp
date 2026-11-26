CXX      ?= g++
CXXFLAGS ?= -std=c++17 -O2
BUILD    := build

.PHONY: all demo clean
all: $(BUILD)/bdii

$(BUILD)/bdii: main.cc $(wildcard *.h)
	mkdir -p $(BUILD)
	$(CXX) $(CXXFLAGS) -o $@ main.cc

# Runs examples/demo.sql in build/demo-data/ so the data files stay out of the tree.
demo: $(BUILD)/bdii
	rm -rf $(BUILD)/demo-data && mkdir -p $(BUILD)/demo-data
	cd $(BUILD)/demo-data && ../bdii < ../../examples/demo.sql

clean:
	rm -rf $(BUILD)
