#Version 14.08.2015
#JANANNA


from socket import *
import threading
import subprocess
import time
import os
import thread
import signal


TIMETOWAITFORABORT = 0.5
global alleine

def handler(clientsocket, clientaddr):
    global alleine
    data="close"
    print "Accepted connection from : ", clientaddr
    time.sleep(TIMETOWAITFORABORT)

#cupboard
    if alleine is 1:
	alleine=0
	stream=StartStream(clientaddr, time_delay)
	stream.start()    
	while alleine== 0:
	    time.sleep(TIMETOWAITFORABORT)
	time.sleep(0.5)
	stream.stopstream()
	time.sleep(0.1)
	print "sendclose0"
	clientsocket.send(data)    
	clientsocket.close()
#cigarrebox
    if alleine is 0:
	alleine=1
	stream1=StartStream(clientaddr, time_delay)
	stream1.start()    
	while alleine== 1:
	    time.sleep(TIMETOWAITFORABORT)

	time.sleep(0.5)

	stream1.stopstream()    

	time.sleep(0.1)
	print "sendclose1"
	clientsocket.send(data)
	clientsocket.close()



class StartStream(threading.Thread):
    def __init__(self, clientaddr, time_delay):
	threading.Thread.__init__(self)
	#subprocess.Popen(self)
	self.running = False
	self.clientaddr = clientaddr

    def run(self):	
	raspivid = subprocess.Popen(["gst-launch-1.0", "-v", "tcpclientsrc", "host=" + self.clientaddr[0] + " ", "port=5000", "!", "gdpdepay", "!", "rtph264depay", "!", "ffdec_h264", "!", "autovideosink"])

	self.running = True
	while(self.running and raspivid.poll() is None):
	    time.sleep(TIMETOWAITFORABORT)

	self.running = False

	if raspivid.poll() == True or self.running == False:
	    print "kill"
	    raspivid.kill()

    def stopstream(self):
	self.running = False  

def get_local_ip():
    s = socket(AF_INET, SOCK_DGRAM)
    s.connect(('8.8.8.8', 1))  # connect() for UDP doesn't send packets
    return s.getsockname()[0]

class GracefulKiller:
    kill_now = False
  def __init__(self):
      signal.signal(signal.SIGINT, self.exit_gracefully)
    signal.signal(signal.SIGTERM, self.exit_gracefully)

  def exit_gracefully(self,signum, frame):
      self.kill_now = True


if __name__ == "__main__":
    global alleine
    alleine=0
    time_delay=0
    host = get_local_ip()
    port = 55567
    buf = 1024
    addr = (host, port)
    serversocket = socket(AF_INET, SOCK_STREAM)
    serversocket.bind(addr)
    serversocket.listen(2)

    killer = GracefulKiller()

    while 1:
	print "Server is listening for connections\n"
	clientsocket, clientaddr = serversocket.accept()
	thread.start_new_thread(handler, (clientsocket, clientaddr))
	if killer.kill_now:
		break

    serversocket.close()
