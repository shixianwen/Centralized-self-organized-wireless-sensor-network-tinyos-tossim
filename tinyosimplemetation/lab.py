import sys
import time
import os
from TOSSIM import*
from TestSerialMsg import *

t = Tossim([])
r = t.radio();
f1 = open("log.txt","w")
f = open("topo.txt","r")
f3 = open("test.txt","w")
f4 = open ("serialdrop.txt","w")
sf = SerialForwarder(9001)
sf.process();
#throttle = Throttle(t, 10)

for line in f:
	s = line.split()
	if s:
			print"",s[0],"",s[1],"",s[2];
			r.add(int(s[0]),int(s[1]),float(s[2]))

t.addChannel("lab", sys.stdout)
#t.addChannel("lablab", sys.stdout)
#t.addChannel("lab1", sys.stdout)
t.addChannel("file",f1)
t.addChannel("seqfile",f3)
t.addChannel("filew",f4)
noise = open("radio-noise.txt", "r")  # 7. configure the CPM radio model. the radio noise is a piece of data from real mote platform experiment.
lines = noise.readlines()
for line in lines:
  str = line.strip()
  if (str != ""):
    val = int(str)
    for i in range(0,101):
		t.getNode(i).addNoiseTraceReading(val)

for i in range(0,101):
    t.getNode(i).createNoiseModel()

for i in range(0,101):
	t.getNode(i).bootAtTime(0);

sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
#throttle.initialize();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();


f1.close()
print"5!@$#!@#!@$@#%#$$$!@#!@#log file close"
f4 = file("ready.txt","w")
f4.close()
print"*^%&^#$%!#$!@#!@#!@ready file created"

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
while(os.path.exists("ready.txt")):
  print"markfile exists";

#throttle.printStatistics()
f2 = open("schedule.txt","r")
j=0;
for line in f2:
	msg = TestSerialMsg();
	s1 = line.split()
	print s1
	if s1:
		msg.set_myaddress(int(s1[0]))
		msg.set_motheraddress(int(s1[1]))
	        msg.set_framelenghth(int(s1[3]))
		msg.set_length(int(s1[4]))
		for i in range(0,int(s1[4])):
			msg.setElement_a(i,int(s1[i+5]))
		serialpkt = t.newSerialPacket();
		serialpkt.setData(msg.data)
		serialpkt.setType(msg.get_amType())
		serialpkt.setDestination(100)
		serialpkt.deliver(100, t.time() + 400000000*j)
		j=j+1

while(1):
  for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
    t.runNextEvent();
    sf.process();
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process();   
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process();    
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process();   
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process(); 
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process();   
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process(); 
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process();   
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process(); 
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process(); 
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process();   
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process(); 
#throttle.printStatistics()
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process(); 
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process(); 
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process();   
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process(); 
#throttle.printStatistics()
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process(); 
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process(); 
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process();   
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process(); 
#throttle.printStatistics()
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process(); 
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process(); 
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process();   
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process(); 
#throttle.printStatistics()
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process();   
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process();    
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process();   
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process(); 
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process();   
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process(); 
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process();   
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process(); 
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process(); 
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process();   
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process(); 
#throttle.printStatistics()
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process(); 
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process(); 
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process();   
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process(); 
#throttle.printStatistics()
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process(); 
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process(); 
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process();   
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process(); 
#throttle.printStatistics()
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process(); 
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process(); 
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process();   
for i in range(0, 50000000):          #  make the simulator run 2000 clock ticks.
 # throttle.checkThrottle();
  t.runNextEvent();
  sf.process(); 
#throttle.printStatistics()
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

for i in range(0, 8000000):
  #throttle.checkThrottle();
  t.runNextEvent();
  sf.process();
