from daemonize import Daemonize

import sys,getopt


def main(argv):
    try:
      opts, args = getopt.getopt(argv,"")
      service = args[0]
    except getopt.GetoptError:
      print('test.py <server name>')
      sys.exit(2)

    print("Starting service: " + service)
    from importlib import import_module
    mod = import_module( service + ".server")
    start = getattr(mod, "main")
    pid = "/tmp/" + service.lower() + "pid"
    daemon = Daemonize(app="Coap", pid=pid, action=start)
    daemon.start()

if __name__ == "__main__":
    main(sys.argv[1:])
