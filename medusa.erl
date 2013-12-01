-module(medusa).
-export([start/0, select_option/0]).


start() ->
    NumOfNodes = 10,
    Tokens = read_file("data.txt"),
    WordLength  = length(Tokens),
    FragSize = WordLength div (NumOfNodes - 1),
    Fragments = make_sublists(FragSize, Tokens),
    create_nodes(NumOfNodes, Fragments),
    select_option().


create_nodes(NumOfNodes, Fragments) ->
    compile:file(snake, [debug_info, export_all]),
    create_node(1, NumOfNodes, Fragments).


create_node(NodeNumber, NodeLimit, _) when NodeNumber > NodeLimit ->
    done;
create_node(NodeNumber, NodeLimit, Fragments) ->
    SenderName = list_to_atom(string:concat("snake_sender_", integer_to_list(NodeNumber))),
    ReceiverName = list_to_atom(string:concat("snake_receiver_", integer_to_list(NodeNumber))),
    register(SenderName, spawn_link(snake, sender, [NodeNumber, NodeLimit])),
    register(ReceiverName, spawn_link(snake, receiver, [NodeNumber, NodeLimit, lists:nth(NodeNumber, Fragments)])),
    create_node(NodeNumber + 1, NodeLimit, Fragments).


select_option() ->
    io:format("~n1 : Longest Word ~n"),
    io:format("2 : Search a Word ~n"),
    io:format("3 : Find Most Frequent Word ~n"),
    io:format("4 : Exit the Program ~n"),
    {ok, [X]} = io:fread("Please enter your choice: ", "~s"),
    case X of
        "1" ->
            snake_sender_1 ! {protocol, 1};
        "2" ->
            {ok, [W]} = io:fread("Enter the word to be searched : ", "~s"),
            io:format("Word is : ~s~n",[W]);
        "3" -> io:format("In 3");
        "4" -> exit("Bye Bye!");
        _ -> io:format("Please enter the correct choice!!~n")
    end,
    timer:sleep(20000).


read_file(FileName)  ->
    {ok, Device} = file:open(FileName, [read]),
    List1 = [],
    Tokens = count_lines(Device, List1),
    Tokens.


count_lines(Device,  List1) ->
    case io:get_line(Device, "") of
        eof  -> file:close(Device),
                List1;
        Line -> Tokens = string:tokens(Line, " "),
                List3 = lists:append(List1, Tokens),
                count_lines(Device, List3)
    end.


make_sublists(FragSize, Tokens) ->
    {Fragment, Remaining} = if length(Tokens) >= FragSize ->
                                    lists:split(FragSize, Tokens);
                               true ->
                                    {Tokens, []}
                            end,
    JoinedFrag = lists:foldl(fun(Item, Accumulation) ->
                                     string:join([Accumulation, Item], " ")
                             end, "", Fragment),
    if Remaining == [] ->
            [JoinedFrag];
       true ->
            UltimateList = make_sublists(FragSize, Remaining),
            lists:append(UltimateList, [JoinedFrag])
    end.
