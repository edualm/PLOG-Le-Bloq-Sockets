:- use_module(library(sockets)).
:- ensure_loaded(['utilities.pl']).

port(60001).

servloop :-
    server,
    servloop.

server:-
	port(Port),
	socket_server_open(Port,Socket),
	socket_server_accept(Socket, _Client, Stream, [type(text)]),
	server_loop(Stream),
	socket_server_close(Socket),
	write('Server Exit'), nl.

server_loop(Stream) :-
	repeat,
		read(Stream, ClientRequest),
		write('Received: '), write(ClientRequest), nl, 
		server_input(ClientRequest, ServerReply),
		format(Stream, '~q.~n', [ServerReply]),
		write('Send: '), write(ServerReply), nl, 
		flush_output(Stream),
	(ClientRequest == bye; ClientRequest == end_of_file), !.

server_input(initialize(BoardSizeX, BoardSizeY), ok(Board)) :- 
	createBoard(BoardSizeX, BoardSizeY, Board),
	
	!.

server_input(initialize(BoardSizeX, BoardSizeY), fail) :-
	!.

server_input(playFT(Board, PieceType, PieceOrientation, PieceX, PieceY, ScoringPlayer, BoardSizeX, BoardSizeY), ok(ScoredBoard)) :-
	validateFirstTurn(Board, PieceType, PieceOrientation, PieceX, PieceY, NewBoard),
	fillBoardWithScoring(NewBoard, BoardSizeX, BoardSizeY, 0, 0, ScoringPlayer, ScoredBoard),
	
	!.

server_input(playFT(Board, PieceType, PieceOrientation, PieceX, PieceY, ScoringPlayer, BoardSizeX, BoardSizeY), fail) :-
	!.

server_input(play(Board, PieceType, PieceOrientation, PieceX, PieceY, ScoringPlayer, BoardSizeX, BoardSizeY), ok(ScoredBoard)) :-
	FixedScoring is ScoringPlayer + 3,
	
	validateTurn(Board, PieceType, PieceOrientation, PieceX, PieceY, NewBoard),
	fillBoardWithScoring(NewBoard, BoardSizeX, BoardSizeY, 0, 0, FixedScoring, ScoredBoard),
	
	!.

server_input(play(Board, PieceType, PieceOrientation, PieceX, PieceY, ScoringPlayer, BoardSizeX, BoardSizeY), fail) :-
	!.

server_input(playAI(Board, ScoringPlayer, BoardSizeX, BoardSizeY), ok(ScoredBoard)) :-
	FixedScoring is ScoringPlayer + 3,
	
	playComputerino(Board, ScoringPlayer, BoardSizeX, BoardSizeY, 1, ScoringPlayer, NewBoard),
	fillBoardWithScoring(NewBoard, BoardSizeX, BoardSizeY, 0, 0, FixedScoring, ScoredBoard),
	
	!.
	
server_input(playAIFT(Board, ScoringPlayer, BoardSizeX, BoardSizeY), ok(ScoredBoard)) :-
	FixedScoring is ScoringPlayer + 3,

	playComputerino(Board, ScoringPlayer, BoardSizeX, BoardSizeY, 0, ScoringPlayer, NewBoard),
	fillBoardWithScoring(NewBoard, BoardSizeX, BoardSizeY, 0, 0, FixedScoring, ScoredBoard),

	!.

server_input(checkWinner(Board, BoardSizeX, BoardSizeY), Winner) :-		%	Missing Winner
	not(checkForAvailableTurns(Board, BoardSizeX, BoardSizeY)),
	checkForWinner(Board, BoardSizeX, BoardSizeY, 0, 0, 0, 0, Winner),
	write('Sending winner: '), write(Winner), nl,
	
	!.

server_input(checkWinner(Board, BoardSizeX, BoardSizeY), 0) :-
	write('Sending winner: '), write(0), nl,
	
	!.

server_input(bye, ok) :-
	!.

server_input(end_of_file, ok) :-
	!.

server_input(_, invalid) :-
	!.