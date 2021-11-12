import gevent
import gevent.server
from telnetsrvlib.telnetsrv.green import TelnetHandler, command

TELNET_IP_BINDING = ''


class MyServer(object):
    '''A simple server class that just keeps track of a connection count.'''

    def __init__(self):
        # Var to track the total connections.
        self.connection_count = 0

        # Dictionary to track individual connections.
        self.user_connect = {}

    def new_connection(self, username):
        '''Register a new connection by username, return the count of connections.'''
        self.connection_count += 1
        try:
            self.user_connect[username] += 1
        except:
            self.user_connect[username] = 1
        return self.connection_count, self.user_connect[username]


class MyTelnetHandler(TelnetHandler):
    myserver = MyServer()

    WELCOME = "Welcome to my server."
    PROMPT = "DVD gateway TELNET>"
    authNeedUser = True
    authNeedPass = True

    def authCallback(self, username, password):
        '''Called to validate the username/password.'''
        # Note that this method will be ignored if the SSH server is invoked.
        # We accept everyone here, as long as any name is given!
        if username != "client" and password != "devpass":
            # complain by raising any exception
            raise ConnectionError

    def writeerror(self, text):
        '''Called to write any error information (like a mistyped command).
        Add a splash of color using ANSI to render the error text in red.
        see http://en.wikipedia.org/wiki/ANSI_escape_code'''
        TelnetHandler.writeerror(self, "\x1b[91m%s\x1b[0m" % text)

    @command(['echo', 'copy', 'repeat'])
    def command_echo(self, params):
        '''<text to echo>
        Echo text back to the console.

        '''
        self.writeresponse(' '.join(params))

    def session_start(self):
        '''Called after the user successfully logs in.'''
        self.writeline('This server is running green.' )

        # Tell myserver that we have a new connection, and provide the username.
        # We get back the login count information.
        globalcount, usercount = self.myserver.new_connection(self.username)

        self.writeline('Hello %s!' % self.username)
        self.writeline('You are connection #%d, you have logged in %s time(s).' % (globalcount, usercount))

        # Track any asyncronous events registered with the timer command
        self.timer_events = []

    @command('timer')
    def command_timer(self, params):
        '''<time> <message>
        In <time> seconds, display <message>.
        Send a message after a delay.
        <time> is in seconds.
        If <message> is more than one word, quotes are required.
        example:
        > TIMER 5 "hello world!"
        '''
        try:
            timestr, message = params[:2]
            time = int(timestr)
        except ValueError:
            self.writeerror("Need both a time and a message")
            return
        self.writeresponse("Waiting %d seconds...", time)
        gevent.spawn_later(time, self.writemessage, message)

def main():
    server = gevent.server.StreamServer(("0.0.0.0", 23), MyTelnetHandler.streamserver_handle)
    server.serve_forever()


if __name__ == "__main__":
    main()
