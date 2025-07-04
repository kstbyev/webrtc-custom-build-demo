# Makefile для компиляции WebRTC Wrapper
# Компилирует C++ код в статическую библиотеку для iOS

# Переменные
CXX = clang++
CXXFLAGS = -std=c++17 -fPIC -Wall -Wextra -O2
INCLUDES = -I./WebRTC.xcframework/ios-arm64/WebRTC.framework/Headers
LIBS = -L./WebRTC.xcframework/ios-arm64/WebRTC.framework -lWebRTC

# Архитектуры iOS
ARCHS = arm64 x86_64
TARGETS = $(addprefix libWebRTCWrapper_, $(ARCHS))

# Файлы
SOURCES = WebRTCWrapper.cpp
OBJECTS = $(SOURCES:.cpp=.o)

# Цели
all: $(TARGETS)

# Компиляция для каждой архитектуры
libWebRTCWrapper_arm64: $(SOURCES)
	$(CXX) $(CXXFLAGS) $(INCLUDES) -target arm64-apple-ios -c $(SOURCES) -o WebRTCWrapper_arm64.o
	ar rcs $@.a WebRTCWrapper_arm64.o

libWebRTCWrapper_x86_64: $(SOURCES)
	$(CXX) $(CXXFLAGS) $(INCLUDES) -target x86_64-apple-ios -c $(SOURCES) -o WebRTCWrapper_x86_64.o
	ar rcs $@.a WebRTCWrapper_x86_64.o

# Создание универсальной библиотеки
universal: $(TARGETS)
	lipo -create $(addsuffix .a, $(TARGETS)) -output libWebRTCWrapper_universal.a

# Очистка
clean:
	rm -f *.o *.a $(TARGETS)

# Установка в Xcode проект
install: universal
	cp libWebRTCWrapper_universal.a WebRTCApp/
	cp WebRTCWrapper.h WebRTCApp/
	cp WebRTCApp-Bridging-Header.h WebRTCApp/

.PHONY: all clean install universal 