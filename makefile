CPPFLAGS += -std=c++11

CPPFLAGS += -O3 -g

LDLIBS += -ljpeg

bin/% : src/%.cpp
	mkdir -p bin
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $< -o $@ $(LDFLAGS) $(LDLIBS)
