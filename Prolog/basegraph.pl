% PROLOG ASSIGNMENT 
% PROGRAMMING PARADIGMS COURSE 2020/21
% STUDENT: SAMUEL DALVAI
% ID: 17682 

%%%%% Graph 1 %%%%

edge(s,n1,6).
edge(s,n2,4).
edge(s,n3,3.1).
edge(n1,n3,2.4).
edge(n1,t,7).
edge(n2,n3,3.3).
edge(n2,n4,5).
edge(n3,n4,5.2).
edge(n3,n5,3.6).
edge(n4,n5,1).
edge(n4,t,2.2).
edge(n5,t,2).

/*
%%%% Graph 2 %%%%
edge(a,b,4.2).
edge(a,c,1.2).
edge(a,d,3.0).
edge(a,e,2.2).
edge(b,c,3.5).
edge(b,d,2.0).
edge(b,e,1.7).
edge(c,d,3.4).
edge(c,e,2.2).
edge(d,e,3.2).
*/
connection(N1,N2,Cost):-
	edge(N1,N2,Cost),
	\+(N1=N2).

connection(N1,N2,Cost):-
	edge(N2,N1,Cost),
	\+(N1=N2).

incomplete_node_list(L,N):-
	connection(N,_,_),
	\+ (member(N,L)).

graph_nodes(Acc,L):-
	incomplete_node_list(Acc,N),!,
	graph_nodes([N|Acc],L).

graph_nodes(L,L).

graph_nodes(L) :- 
	graph_nodes([],L),!.

graph_nodes(L1):-
	graph_nodes([],L2),
	sort(L1,S),
	sort(L2,S).

%% ASSIGNMENT STARTS HERE:

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PREDICATE 1
% check if every node int the graph is connected to all nodes
% by creating a list with every node and checking if every node
% is connected to all other nodes
complete(_) :-
	graph_nodes(L),
	complete(_,L).

complete(_,[]).

complete(_, [H|T]) :-
	connectedAll(H),
	complete(_, T).

% create all the nodes as a list and pass it to the method connectedAll
connectedAll(Node) :-
	graph_nodes(L),
	connectedAll(Node,L),
	!.

connectedAll(_,[]). % base case when the list is empty

% if Node is an element of the list, do not check if it is connected to itself
connectedAll(Node,[H|T]) :-
	Node = H,
	connectedAll(Node,T).

% otherwise check if it connected to the other nodes
connectedAll(Node,[H|T]) :-
	connection(Node,H,_),
	connectedAll(Node,T).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PREDICATE 2
% compute the path and the cost from the source node
% to the target node
path(Source,Target,[Source|Path],Cost):-
  	pathacc(Source,Target,[],Path,0,Cost).

% base case, target reached, if cost is 0
% fail, because it means that we have a list
% with just the Source as element
% example: a->a is not a path
pathacc(Target,Target,Path,Path,Cost,Cost) :- 
	\+ Cost = 0.

% check if there is a node that has a connection
% if so check if it was already visited, otherwise append to the list
% creating the path, use accumulators to store the current
% path and cost
pathacc(Source,Target,TempPath,Path,TempCost,Cost):-
  	connection(Source,Node,EdgeCost),
  	\+ member(Node,TempPath),
  	append(TempPath,[Node],TempPath1),
  	TempCost1 is TempCost + EdgeCost,
  	pathacc(Node,Target,TempPath1,Path,TempCost1,Cost).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PREDICATE 3
% for the path compute his length and check that there is no other
% path between the same nodes that is shorter
min_traversal(Source,Target,Path,Cost,Length) :-
	path(Source,Target,Path,Cost),
	traversal_length(Path,Length),
	\+ shorter(Source,Target,Length).

% define utility predicate to compute length of traversal
traversal_length([H|T],Length) :-
	traversal_length([H|T],0,Length).

traversal_length([],Length,Length).
	
traversal_length([_|T],TempLength,Length) :-
	TempLength1 is TempLength + 1,
	traversal_length(T,TempLength1,Length).

% predicate for checking if there is a shorter path
shorter(Source,Target,Length) :-
	path(Source,Target,Path,_),
	traversal_length(Path,Length2),
	Length2 < Length.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PREDICATE 4
% follow same strategy as predicate 1 and check if there is 
% a path between every pair of nodes
connected(_) :-
	graph_nodes(L),
	connected(_,L).

connected(_,[]).

connected(_, [H|T]) :-
	pathToAll(H),
	connected(_, T).

pathToAll(Node) :-
	graph_nodes(L),
	pathToAll(Node, L),
	!.

pathToAll(_,[]).

pathToAll(Node,[H|T]) :-
	Node = H,
	pathToAll(Node,T).

% otherwise check also if it connected
pathToAll(Node,[H|T]) :-
	path(Node,H,_,_),
	pathToAll(Node,T).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PREDICATE 5
% for every path in the graph, check if the first element is
% the same as the last one, then sort the path, add the head
% element of the path to the complete list of the nodes in the 
% graph and sort this list. If the two resulting lists are equal
% we have an hamiltonian cycle.
hcycle(Path,Cost) :-
	path(_,_,[PathH|PathT],Cost),
	last_element(PathH,[PathH|PathT]),
	sorted_path([PathH|PathT],Sorted),
	sorted_graph_nodes(Nodes,PathH),
	equal_nodes(Sorted,Nodes),
	drop_last([PathH|PathT],Path).

last_element(X,[X]).

last_element(X,[_|T]) :- 
	last_element(X,T).

% use msort otherwise duplicates are not kept
sorted_path(Path, Sorted) :-
	msort(Path,Sorted).

% add the first element of the path to the list of
% nodes, since the cycle must be closed
sorted_graph_nodes(SortedNodes,CicleClosure) :-
	graph_nodes(Nodes),
	append(Nodes,[CicleClosure],Nodes2),
	msort(Nodes2,SortedNodes).

% test if the two paths have the same elements
equal_nodes([],[]).

equal_nodes([H1|T1],[H2|T2]) :-
	H1 = H2,
	equal_nodes(T1,T2).

% drop last element of the path, since it must be accounted
%for the cost but does not have to be visited
drop_last([_], []) :- % base case, last element in the list
	!.

% keep the head of the list in the result and iterate over
% the tail 
drop_last([H|T1],[H|T2]) :-
	drop_last(T1,T2).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PREDICATE 6
% find all the possible permutations of hamiltonian cycles
% that do not have a path that costs less 
shcycle(Path,Cost) :-
	hcycle(Path,Cost),
	\+ cheaper(Path,Cost).

cheaper(_,Cost) :-
	hcycle(_,Cost2),
	Cost2 < Cost.
