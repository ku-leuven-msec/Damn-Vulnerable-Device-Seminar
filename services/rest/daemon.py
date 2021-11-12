from daemonize import Daemonize

import sys,getopt
import server

def main(argv):
    print("Starting service: " + service)
    from importlib import import_module
    pid = "/tmp/" + service.lower() + "pid"
    daemon = Daemonize(app=service.lower(), pid=pid, action=server.main)
    daemon.start()

if __name__ == "__main__":
    main(sys.argv[1:])
