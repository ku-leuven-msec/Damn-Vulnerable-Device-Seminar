[[0;32m+[0m][0;32m /log/firmware/firmware/opt/dvd/services/telnet/telnetsrvlib/README.rst[0m
1:telnetsrvlib..
4:Telnet server using g.
6: from http://pytelnetsrvlib.sourcefo.
10:asily create a Telnet or SSH server .
11:otiates with a Telnet client, parses.
13:ap the defined Telnet handler into..
34:telnetsrv is availabl.
38: easy_install telnetsrv..
44: pip install telnetsrv..
52:Import the ``TelnetHandler`` base .
53:hen subclass ``TelnetHandler`` to ad.
60: from telnetsrv.threaded im.
60:port TelnetHandler, comman.
61:lass MyHandler(TelnetHandler):..
69: from telnetsrv.green impor.
69:t TelnetHandler, comman.
70:lass MyHandler(TelnetHandler):..
78: from telnetsrv.evtlet impo.
78:rt TelnetHandler, comman.
79:lass MyHandler(TelnetHandler):..
116:   Telnet Server> echo 1.
125:    Telnet Server> echo 1.
136:    Telnet Server> echo 1.
168:    Telnet Server> help..
175:    Telnet Server> help e.
180:    Telnet Server>..
280: will be seamlessly regenerated f.
291:questing a new password) the input sho.
307:  Default: ``"Telnet Server> "``..
313:r the username/password is accepted, i.
315:nnected to the telnet server."``..
327:elf, username, password)`` ..
329:no username or password is requested. .
340:  Should a password be requested?..
361:        TelnetHandler.writeer.
367:nstance of the TelnetHandler class..
377: class TelnetServer(SocketSe.
380: server = TelnetServer(("0.0.0..
386:The TelnetHandler class i.
403: from telnetsrv.green impor.
403:t TelnetHandler, comman.
405: class MyTelnetHandler(TelnetH.
436:(("", 8023), MyTelnetHandler.streams.
443:installed, the TelnetHanlder can be .
445:o invoking the TelnetHandler,..
446:defined in the TelnetHandler is igno.
451:version of the TelnetHandler, you mu.
457:    from telnetsrv.paramiko_ss.
462:version of the TelnetHandler, you mu.
468:    from telnetsrv.paramiko_ss.
477:dler sets up a TelnetHandler class ..
513: or a username/password.  Up to three .
532:elf, username, password)`` ..
533:ce to username/password authentication.
534: is defined, a password is requested. .
552: from telnetsrv.paramiko_ss.
553: from telnetsrv.green impor.
553:t TelnetHandler, comman.
555: class MyTelnetHandler(TelnetH.
570:ndler to use MyTelnetHandler for any.
571:     telnet_handler = MyTe.
574: not require a password..
578:elf, username, password):..
579:# Super secret password:..
580:         if password != 'concord':..
581:meError('Wrong password!')..
583: # Start a telnet server for jus.
584: telnetserver = gevent.
584:0.1', 8023), MyTelnetHandler.streams.
585: telnetserver.start()..
595:om/ianepperson/telnetsrvlib/blob/mas.
