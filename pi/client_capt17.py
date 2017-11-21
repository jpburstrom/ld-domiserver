import os
import subprocess
import threading
import time
import StringIO
from datetime import datetime
from PIL import Image
from socket import *

RASPIVIDCMD = ["raspivid"]
TIMETOWAITFORABORT = 0.5

threshold = 30
sensitivity = 10
forceCapture = False
wi=50
hi=25



# Capture a small test image (for motion detection)
def captureTestImage():
    command = "raspistill -w %s -h %s -t 1 -e bmp -o -" % (wi, hi)
    imageData = StringIO.StringIO()
    imageData.write(subprocess.check_output(command, shell=True))
    imageData.seek(0)
    im = Image.open(imageData)
    buffer = im.load()
    imageData.close()
    #return im, buffer
    return buffer



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
        #self.raspividcmd.append("-h")
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





if __name__ == '__main__':

    host = '192.168.1.41'
    port = 55567
    buf = 1024

    addr = (host, port)
    ungleich=0

    while (True):

        if ungleich is 0:
                buffer1 = captureTestImage()


        ungleich = 1
        changedPixels = 0
        buffer2 = captureTestImage()

        for x in xrange(0, wi):
            for y in xrange(0, hi):
                pixdiff = abs(buffer1[x,y][1] - buffer2[x,y][1])
                if pixdiff > threshold:
                    changedPixels += 1

            if changedPixels>sensitivity:
                break

        if changedPixels>sensitivity:
                ungleich = 0
                vidcontrol = RaspiVidController("0", "720", "1080", "25", "1000000")

                try:
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


                except KeyboardInterrupt:
                    print "Cancelled by KeyboardInterrupt"

                finally:
                    clientsocket.close()
                    print "Stopping raspivid controller"
                    vidcontrol.stopController()
                    vidcontrol.join()
                    print "Done"
                    time.sleep(1)



