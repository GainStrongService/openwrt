OBJS	+= main.o
TARGET	:= lora-test
LIBS	:= libsx1276.a

all: $(TARGET)

$(TARGET): $(OBJS) $(LIBS)
	$(CC) $^ -o $@ -I./

.c.o:
	$(CC) -Wall -c $< -o $@ -I./

clean:
	$(RM) *.o $(TARGET)
.PHONY:clean 
