-module(chat).

-export([start/0, writeConn/1, readConn/2, transmitter/1]).

writeConn(Conn) ->
	receive
		Msg ->
			gen_tcp:send(Conn, Msg),
			writeConn(Conn)
	end.

readConn(Conn, TransPid) ->
	{ ok, Data } = gen_tcp:recv(Conn, 0),
	TransPid ! Data,
	readConn(Conn, TransPid).

writeAll([Last], Val) ->
	Last ! Val;
writeAll([Head|Tail], Val) ->
	Head ! Val,
	writeAll(Tail, Val).

transmitter(Pids) -> 
	receive
		Pid2 when is_pid(Pid2) ->
			transmitter([Pid2|Pids]);

		Msg ->
			writeAll(Pids, Msg),
			transmitter(Pids)
	end.
	
mainLoop(Sock) ->
	{ok, Conn} = gen_tcp:accept(Sock),
	WritePid = spawn(chat, writeConn, [Conn]),
	TransPid = whereis(transmitter),
	spawn(chat, readConn, [Conn, TransPid]),
	TransPid ! WritePid,
	mainLoop(Sock).
start() ->
	{ok, Sock} = gen_tcp:listen(8080, [binary, {active, false}]),
	TransPid = spawn(chat, transmitter, [[]]),
	register(transmitter, TransPid),
	mainLoop(Sock).
