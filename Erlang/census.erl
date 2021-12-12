-module(census).
-export([word_count/2]).


% ERLANG ASSIGNMENT 
% PROGRAMMING PARADIGMS COURSE 2020/21
% STUDENT: Samuel Dalvai
% ID: 17682 
% EMAIL: samdalvai@unibz.it

%%%%% MAIN FUNCTION OF THE APPLICATION %%%%%

% spawns a reader and send him the message to start
% for example census:word_count("data.txt",100).
% will start the application and let the reader create 100
% scanner processes and so on...
word_count(Filename,N) -> 
	Reader = spawn(fun() -> reader(Filename,nil,[],N,[]) end),
	io:format("Reader process with Pid ~p created.~n", [Reader]),
	send(Reader,start),
	Reader.


%%%%% FUNCTIONS THAT REPRESENT THE PROCESSES OF THE APPLICATION %%%%%

% orchestrates all the operations between processes
% creates summarizer
% creates scanners
% sends Pid of summarizer to scanners
% reads and dispatches lines of a file
% ....
% after each step is completed it sends a message
% to itself to go on with the next step, in this way
% there is no need for an external orchestrator
reader(Filename,Summarizer,Scanners,N,Lines) ->
process_flag(trap_exit,true),
	receive
		start ->
			io:format("Spawning summarizer process...~n"),
			send(self(),{create,summarizer}),
			reader(Filename,Summarizer,Scanners,N,Lines);
		{create,summarizer} ->
			Summ = spawn_link(fun() -> summarizer(temp,temp,temp,temp,temp) end),
			io:format("New summarizer process ~p created.~n",[Summ]),
			send(Summ,init),
			io:format("Spawning ~p scanner processes...~n", [N]),
			send(self(),{create,scanners}),
			reader(Filename,Summ,Scanners,N,Lines);
		{create,scanners} ->
			Num = listLength(Scanners),
			if
				Num < N -> 
					Scan = spawn_link(fun() -> scanner(temp) end),
					send(self(),{create,scanners}),
					reader(Filename,Summarizer,[Scan|Scanners],N,Lines);
				true -> 
					io:format("Finished spawning ~p scanner processes.~n",[listLength(Scanners)]),
					send(self(),{sendPid,scanners}),
					reader(Filename,Summarizer,Scanners,N,Lines)
			end;
		{sendPid,scanners} ->
			io:format("Sending Pid of summarizer to scanners...~n"),
			lists:foreach(fun(To) -> send(To,{summarizerPid,Summarizer}) end,Scanners),
			send(self(),{read,Filename}),
			reader(Filename,Summarizer,Scanners,N,Lines);
		{read,Filename} ->
			io:format("Reading file ~p...~n",[Filename]),
			Input = readFile(Filename),
			io:format("Finished reading file.~n"),
			send(self(),dispatch),
			reader(Filename,Summarizer,Scanners,N,Input);
		dispatch ->
			io:format("Sending Lines to scanners...~n"),
			cyclicSend(Scanners,Scanners,Lines),
			io:format("Finished sending Lines, notifying EOF to scanners...~n"),
			send(self(),{eof,scanners}),
			reader(Filename,Summarizer,Scanners,N,Lines);
		{eof,scanners} ->
			lists:foreach(fun(To) -> send(To,{eof,self()}) end,Scanners),
			reader(Filename,Summarizer,Scanners,N,Lines);
		{eof,summarizer} ->
			io:format("Notifying summarizer ~p about scanners finished...~n",[Summarizer]),
			send(Summarizer,{finish,self()}),
			io:format("Closing file ~p...~n",[Filename]),
			closeFile(Filename),
			reader(Filename,Summarizer,Scanners,N,Lines);
		{finish,scanner,From} ->
			unlink(From),
			ScannUpdate = lists:delete(From,Scanners),
			send(From,terminate),
			if
				ScannUpdate == [] -> 
					io:format("Received all EOF aknowledgments and terminated all scanner processes.~n"),
					send(self(),{eof,summarizer}),
					reader(Filename,Summarizer,ScannUpdate,N,Lines);
				true -> reader(Filename,Summarizer,ScannUpdate,N,Lines)
			end;
		{finish,summarizer,From} ->
			io:format("Received finish aknowledgment from summarizer ~p.~n",[From]),
			io:format("Terminating summarizer process ~p...~n",[From]),
			unlink(From),
			send(From,terminate),
			io:format("Terminating reader process ~p...~n",[self()]),
			send(self(),terminate),
			reader(Filename,nil,Scanners,N,Lines);
		{'EXIT',From,Reason} -> %% restarts the procedure in case a process is lost
			io:format("Process ~p died for reason: ~p~n",[From,Reason]),
			case lists:member(From,Scanners) of
				false ->
					send(self(),{create,summarizer}),
					reader(Filename,nil,Scanners,N,Lines);
				true -> 
					send(self(),{create,scanners}),
					reader(Filename,Summarizer,[],N,Lines)
			end;		
		terminate ->
			io:format("Reader Process ~p terminating...~n",[self()])
	end.

% is in charge of parse the lines and extract the single Tokens
% it then sends the token with the right category to the summarizer 
% for the handling of the data
scanner(Summarizer) ->
	receive
		{summarizerPid,Pid} ->
			scanner(Pid);
		{eof,ReaderPid} -> 
			send(ReaderPid,{finish,scanner,self()}),
			scanner(Summarizer);
		terminate ->
			erlang:exit({self(),die,at,erlang:time()});
		{line,Line} ->
			Parsed = binary:bin_to_list(Line),
			Tokens = string:tokens(Parsed, " "),
			lists:foreach(fun(X) -> send(Summarizer,{getCategory(cleanElem(X)),cleanElem(X)}) end, Tokens),
			scanner(Summarizer);
		X ->
			io:format("Scanner process ~p received unknown message ~p~n", [self(),X]),
			scanner(Summarizer)
	end.

% receives the Tokens with the category from the scanner process/processes
% and updates the data accordingly
% is also in charge of printing the final result
summarizer(Gender,Marital,Age,Income,Occupation) ->
	receive
		init -> 
			GendInit = {{"Female",0},{"Male",0},{"Other",0}},
			MaritInit = {{"Married",0},{"Single",0},{"Divorced",0},{"Widowed",0}},
			AgeInit = {{"0-6",0},{"7-12",0},{"13-18",0},{"19-24",0},{"25-30",0},{"31-45",0},{"46-60",0},{"61+",0}},
			IncomeInit = {{"<$10,000",0},{"$10,000-$25,000",0},{"$25,001-$50,000",0},{"$50,001-$100,000",0},{"$100,001-$250,000",0},{">$250,000",0}},
			OccupInit = {},
			summarizer(GendInit,MaritInit,AgeInit,IncomeInit,OccupInit);
		{gender,X} ->
			UpdateGen = updateGender(X,Gender),
			summarizer(UpdateGen,Marital,Age,Income,Occupation);
		{marital,X} ->
			UpdateMarit = updateMarital(X,Marital),
			summarizer(Gender,UpdateMarit,Age,Income,Occupation);
		{age,X} ->
			UpdateAge = updateAge(X,Age),
			summarizer(Gender,Marital,UpdateAge,Income,Occupation);
		{income,X} -> 
			UpdateInc = updateIncome(X,Income),
			summarizer(Gender,Marital,Age,UpdateInc,Occupation);
		{occupation,X} ->
			UpdateOccup = updateOccupation(X,Occupation),
			summarizer(Gender,Marital,Age,Income,UpdateOccup);
		{finish,ReaderPid} ->
			io:format("Summarizer received finish flag from reader ~p.~n",[ReaderPid]),
			io:format("Displaying final results:~n~n"),
			printResults(Gender,Marital,Age,Income,Occupation),
			send(ReaderPid,{finish,summarizer,self()}),
			summarizer(Gender,Marital,Age,Income,Occupation);
		terminate ->
			io:format("Summarizer process ~p terminating...~n", [self()]),
			erlang:exit({self(),die,at,erlang:time()});
		X ->
			io:format("Summarizer process ~p received unknown message ~p~n", [self(),X]),
			summarizer(Gender,Marital,Age,Income,Occupation)
	end.


%%%%% UTILITY FUNCTIONS FOR SENDING MESSAGES %%%%%

% send a message to a recipient
send(Recipient,Message) ->
	Recipient ! Message.

% send a message in a cycle to N recipients (scanners)
% consuming the List of messages until it is empty
cyclicSend(_,_,[]) ->
	nil;

cyclicSend(Scanners,[],Lines) ->
	cyclicSend(Scanners,Scanners,Lines);

cyclicSend(Scanners,[ScanH|ScanT],[LinesH|LinesT]) ->
	send(ScanH,{line,LinesH}),
	cyclicSend(Scanners,ScanT,LinesT).


%%%%% OTHER UTILIY FUNCTIONS %%%%%

listLength(List) ->
	listLengthAux(List,0).

listLengthAux([],0) -> 0;
listLengthAux([],Acc) -> Acc;
listLengthAux([_|Tail],Acc) ->
	listLengthAux(Tail, Acc+1).

% Reads a file and parses lines
readFile(FileName) ->
	{ok, Data} = file:read_file(FileName),
	binary:split(Data, [<<"\n">>], [global]).

% closes the file
closeFile(FileName) -> file:close(FileName).

% clean elements from \r return characters
cleanElem(X) -> re:replace(X,"\r","",[global,{return,list}]).


%%%%% UTILITY FUNCTIONS FOR UPDATING DATA %%%%%

updateGender(X,Gender) ->
	case X of
		"Female" -> setelement(1,Gender,{"Female",element(2,element(1,Gender))+1});
		"Male" -> setelement(2,Gender,{"Male",element(2,element(2,Gender))+1});
		"Other" -> setelement(3,Gender,{"Other",element(2,element(3,Gender))+1});
		true -> io:format("Error in the update, ~p not recognized!!!~n",[X]), Gender
	end.

updateMarital(X,Marital) ->
	case X of
		"Married" -> setelement(1,Marital,{"Married",element(2,element(1,Marital))+1});
		"Single" -> setelement(2,Marital,{"Single",element(2,element(2,Marital))+1});
		"Divorced" -> setelement(3,Marital,{"Divorced",element(2,element(3,Marital))+1});
		"Widowed" -> setelement(4,Marital,{"Widowed",element(2,element(4,Marital))+1});
		true -> io:format("Error in the update, ~p not recognized!!!~n",[X]), Marital
	end.

updateAge(X,Age) ->
	{Num,_} = string:to_integer(X),
	if
		(Num < 7) -> setelement(1,Age,{"0-6",element(2,element(1,Age))+1});
		(Num > 6) and (Num < 13) -> setelement(2,Age,{"7-12",element(2,element(2,Age))+1});
		(Num > 12) and (Num < 19) -> setelement(3,Age,{"13-18",element(2,element(3,Age))+1});
		(Num > 18) and (Num < 25) -> setelement(4,Age,{"19-24",element(2,element(4,Age))+1});
		(Num > 24) and (Num < 31) -> setelement(5,Age,{"25-30",element(2,element(5,Age))+1});
		(Num > 30) and (Num < 46) -> setelement(6,Age,{"31-45",element(2,element(6,Age))+1});
		(Num > 45) and (Num < 61) -> setelement(7,Age,{"46-60",element(2,element(7,Age))+1});
		(Num > 60) -> setelement(8,Age,{"61+",element(2,element(8,Age))+1});
		true -> io:format("Error in the update, ~p not recognized!!!~n",[X]), Age
	end.

updateIncome(X,Income) ->
	[_,_,Value] = string:replace(X, "$", ""),
	{Num,_} = string:to_integer(Value),
	if
		(Num < 10000) -> setelement(1,Income,{"<$10,000",element(2,element(1,Income))+1});
		(Num > 9999) and (Num < 25001) -> setelement(2,Income,{"$10,000-$25,000",element(2,element(2,Income))+1});
		(Num > 25000) and (Num < 50001) -> setelement(3,Income,{"$25,001-$50,000",element(2,element(3,Income))+1});
		(Num > 50000) and (Num < 100001) -> setelement(4,Income,{"$50,001-$100,000",element(2,element(4,Income))+1});
		(Num > 100000) and (Num < 250001) -> setelement(5,Income,{"$100,001-$250,000",element(2,element(5,Income))+1});
		(Num > 250000) -> setelement(6,Income,{">$250,000",element(2,element(6,Income))+1});
		true -> io:format("Error in the update, ~p not recognized!!!~n",[X]), Income
	end.

% check if the occupation is already present as a Tuple, if so update the number of occurrences
% otherwise add it as a new Tuple to the collection
updateOccupation(X,Occupation) ->
	OccList = tuple_to_list(Occupation),
	Index = indexOfOccupation(OccList,X,1),
	if
		Index == nil -> insertOccupation(Occupation,{X,1});
		true -> setelement(Index,Occupation,{X,element(2,element(Index,Occupation))+1})
	end.

insertOccupation(Occupation, {Name, Value}) -> erlang:append_element(Occupation,{Name, Value}).

indexOfOccupation([],_,_) -> nil;
indexOfOccupation([{HeadName,_}|Tail],Name,Index) ->
	if
		HeadName == Name -> Index;
		true -> indexOfOccupation(Tail,Name,Index+1)
	end.


%%%%% UTILITY FUNCTIONS TO HANDLE CATEGORY OF STRING EXTRACTED

% Get category of token
getCategory(Token) ->
	case isNumeric(Token) of
		true ->	age;
		false -> 
		case isIncome(Token) of
			true -> income;
			false -> 
			case isGender(Token) of
				true -> gender;
				false -> 
				case isMarital(Token) of
					true -> marital;
					false -> occupation
				end
			end
		end
	end.

% check if a Token is numeric
isNumeric(Token) ->
	{Result,_} = string:to_integer(Token),
	case is_number(Result) of
		true -> true;
		false -> false
	end.

isIncome(Token) -> string:str(Token,"$") > 0.

isGender(Token) -> lists:member(Token,["Female","Male","Other"]).

isMarital(Token) -> lists:member(Token,["Married","Single","Divorced","Widowed"]).


%%%%% UTILITY FUNCTIONS TO PRINT DATA

printResults(Gender,Marital,Age,Income,Occupation) ->
	io:format("Gender:~n"),
	printData(Gender),
	io:format("Marital status:~n"),
	printData(Marital),
	io:format("Occupation:~n"),
	printData(Occupation),
	io:format("Age:~n"),
	printData(Age),
	io:format("Yearly income:~n"),
	printData(Income).

printData(Data) ->
	DataList = tuple_to_list(Data),
	lists:foreach(fun(X) -> io:format("~p: ~p~n",[element(1,X),element(2,X)]) end, DataList),
	io:format("~n").