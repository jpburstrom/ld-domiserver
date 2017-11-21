import os
import subprocess
import threading
import time
import StringIO
from datetime import datetime
import sys
import RPi.GPIO as GPIO
from socket import *

RASPIVIDCMD = ["raspivid"]
TIMETOWAITFORABORT = 0.5
PIR=4
POR=17
GPIO.setmode(GPIO.BCM)
GPIO.setup(PIR, GPIO.IN)
GPIO.setup(POR, GPIO.OUT)
GPIO.output(POR, 1)




#class for controlling the running and shutting down of raspivid
class RaspiVidController(threading.Thread):
    def __init__(self, timeout, hoehe, breite, framerate, bitrate):
        threading.Thread.__init__(self)

        #setup the raspivid cmd
        self.raspividcmd = RASPIVIDCMD
        self.raspividcmd.append("-t")
        self.raspividcmd.append(str(timeout))
        self.raspividcmd.append("-f")
        self.raspividcmd.append("-vf")
        #self.raspividcmd.append(str(hoehe))
        #self.raspividcmd.append("-w")
        #self.raspividcmd.append(str(breite))
        self.raspividcmd.append("-fps")
        self.raspividcmd.append(str(framerate))
        self.raspividcmd.append("-hf")
        self.raspividcmd.append("-b")
        self.raspividcmd.append(str(bitrate))
        self.raspividcmd.append("-o")
        self.raspividcmd.append("-")

       # if preview == False: self.raspividcmd.append("-n")

        #set state to not running
        self.running = False

    def run(self):

        raspivid = subprocess.Popen(self.raspividcmd, shell=False, stdout=subprocess.PIPE)
        test = subprocess.Popen(["gst-launch-1.0", "-v", "fdsrc", "!", "h264parse", "!", "rtph264pay", "config-interval=1", "pt=96", "!", "gdppay", "!", "tcpserversink", "host=192.168.1.107", "port=5000"], shell=False, stdin=raspivid.stdout)

        #loop until its set to stopped or it stops
        self.running = True
        while(self.running and raspivid.poll() is None):
            time.sleep(TIMETOWAITFORABORT)
        self.running = False

        #kill raspivid if still running
        if raspivid.poll() == True or self.running==False:
            print "kill"
            raspivid.kill()
            test.kill()

    def stopController(self):
        self.running = False

#test program

def initPIR(PIR):
    print "Waiting for PIR..."
    while GPIO.input(PIR) == 1:
        print "PIR Ready"
        return 0

# Action if motion detected
def motion():
    print "Motion detected!"
    return

# Action if motion is gone
def motionGone():
    print "Ready for new motion detection!"
    return
#GPIO.setmode(GPIO.BCM)
#GPIO.setup(PIR, GPIO.IN)

PirPreviousState = 0
PirCurrentState = initPIR(PIR)



if __name__ == '__main__':

    host = '192.168.1.41'
    port = 55567
    buf = 1024

    addr = (host, port)


    try:


        while (True):
                PirCurrentState = GPIO.input(PIR)

                if PirCurrentState == 1 and PirPreviousState == 0:
                        vidcontrol = RaspiVidController("0", "720", "1080", "25", "1000000")
                        # PIR is triggered
                        #motion()
                        print("Starting raspivid controller")
                        vidcontrol.start()
                        clientsocket = socket(AF_INET, SOCK_STREAM)
                        clientsocket.connect(addr)

                        data = clientsocket.recv(buf)

                        if data=='close':
                                clientsocket.close()
                                print "Stopping raspivid controller"
                                vidcontrol.stopController()
                                vidcontrol.join()
                                print "Done"
                                time.sleep(1)
                                PirPreviousState=0


                time.sleep(0.1)


    except KeyboardInterrupt:
                print "Cancelled by KeyboardInterrupt"
                vidcontrol.stopController()
                vidcontrol.join()
                GPIO.cleanup()
                exit()




