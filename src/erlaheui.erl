%% Copyright (c) 2017-2018 Sungwoo Kim
%% 
%% Permission is hereby granted, free of charge, to any person obtaining a copy
%% of this software and associated documentation files (the "Software"), to deal
%% in the Software without restriction, including without limitation the rights
%% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
%% copies of the Software, and to permit persons to whom the Software is
%% furnished to do so, subject to the following conditions:
%% 
%% The above copyright notice and this permission notice shall be included in all
%% copies or substantial portions of the Software.
%% 
%% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
%% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
%% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
%% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
%% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
%% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
%% SOFTWARE.

%% @author Sungwoo Kim <hero.sungwoo@gmail.com>
%% @copyright 2017-2018 Sungwoo Kim
%% @doc Erlaheui, the aheui implementation in erlang.

-module(erlaheui).

%% API exports
-export([c/1]).

%%====================================================
%% API functions
%%====================================================

%% @doc Input aheui source code path.
-spec c(string()) -> {ok, integer()} | {error, atom()}.
c(Path) ->
    case file:read_file(Path) of
        {ok, Bin} ->
            A = binary_to_list(Bin),
            B = make2d(A, []),
            {ok, erlaheui(B, 1, 1, {down, 1}, {1, create_list(27)})};
        Error ->
            Error
    end.


%%====================================================================
%% Internal functions
%%====================================================================
%% erlaheui(Aheui source code, Instruction coord X, Instruction coord Y, {Direction and step}, Storage)
%%          [[ ... ],                            1,                   1, {down,            1}, [[ ... ],   &lt- stack
%%           [ ... ],                                                                           [ ... ],   &lt- stack
%%              .                                                                                  .            .
%%              .                                                                                  .       &lt- queue(22th)
%%              .                                                                                  .            .
%%           [ ... ],                                                                           [ ... ],   &lt- stack
%%           [ ... ]],                                                                          [ ... ]]   &lt- stack(25th)
%% @doc Interprete aheui matrix.
-spec erlaheui(list(), integer(), integer(), atom(), list()) -> {eoa, integer()}.
erlaheui(Src, X, Y, _Dir, _Store) ->
    case aheui_fsm(get(Y, X, Src), _Dir, _Store) of
        {{up, Step}, Store} ->
            {XX, YY} = where_to_go({X, Y}, {y, -Step}, Src),
            erlaheui(Src, XX, YY, {up, Step}, Store);
        {{down, Step}, Store} ->
            {XX, YY} = where_to_go({X, Y}, {y, Step}, Src),
            erlaheui(Src, XX, YY, {down, Step}, Store);
        {{right, Step}, Store} ->
            {XX, YY} = where_to_go({X, Y}, {x, Step}, Src),
            erlaheui(Src, XX, YY, {right, Step}, Store);
        {{left, Step}, Store} ->
            {XX, YY} = where_to_go({X, Y}, {x, -Step}, Src),
            erlaheui(Src, XX, YY, {left, Step}, Store);
        %% end of aheui, ㅎ
        {eoa, V} ->
            V;
        Error ->
            Error
    end.

%% recursive
where_to_go(Current, {Dir, Step}, Map) when Step < -1 ->
    where_to_go(where_to_go(Current, {Dir, Step+1}, Map), {Dir, -1}, Map);
where_to_go(Current, {Dir, Step}, Map) when Step > 1 ->
    where_to_go(where_to_go(Current, {Dir, Step-1}, Map), {Dir, 1}, Map);

where_to_go({X, Y}, {y, -1}, Map) when Y < 1 ->
    where_to_go({X, length(Map) + 1}, {y, -1}, Map);
where_to_go({X, Y}, {y, -1}, Map) ->
    case can_i_move_to({X, Y-1}, Map) of
        yes -> {X, Y-1};
        no -> where_to_go({X, Y-1}, {y, -1}, Map)
    end;
where_to_go({X, Y}, {y, 1}, Map) when Y > length(Map) ->
    where_to_go({X, 0}, {y, 1}, Map);
where_to_go({X, Y}, {y, 1}, Map) ->
    case can_i_move_to({X, Y+1}, Map) of
        yes -> {X, Y+1};
        no -> where_to_go({X, Y+1}, {y, 1}, Map)
    end;

where_to_go({X, Y}, {x, 1}, Map) ->
    case X - length(lists:nth(Y, Map)) of
        D when D > 0 ->
            where_to_go({0, Y}, {x, 1}, Map);
        _ ->
            case can_i_move_to({X+1, Y}, Map) of
                yes -> {X+1, Y};
                no -> where_to_go({X+1, Y}, {x, 1}, Map)
            end
    end;
where_to_go({X, Y}, {x, -1}, Map) when X < 1 ->
    where_to_go({length(lists:nth(Y, Map)) + 1, Y}, {x, -1}, Map);
where_to_go({X, Y}, {x, -1}, Map) ->
    case can_i_move_to({X-1, Y}, Map) of
        yes -> {X-1, Y};
        no -> where_to_go({X-1, Y}, {x, -1}, Map)
    end.

can_i_move_to({X, Y}, Src) ->
    case get(Y, X, Src) of
        {error, _}  -> no;
        _           -> yes
    end.
            

is_nop(A) when A < 44032 -> true;   %% 0xAC00
is_nop(A) when A > 55199 -> true;   %% 0xD79F
is_nop(_) -> false.                 %% 0xAC00 ~ 0xD79F

%% utf8 to unicode
utf8_to_unicode([A1]) -> A1;
utf8_to_unicode([A1,A2]) ->
    {B1,B2} = {A1 - 192, A2- 128},
    {C1, C2} = {B1 bsr 2, 
         ((B1 band 3) bsl 6) + B2},
    (C1 bsl 8) + C2;
utf8_to_unicode([A1,A2,A3]) ->
    {B1,B2,B3} = {A1 - 224, A2- 128, A3 - 128},
    {C1, C2} = {(B1 bsl 4) + (B2 bsr 2), 
         ((B2 band 3) bsl 6) + B3},
    (C1 bsl 8) + C2;
utf8_to_unicode([A1,A2,A3,A4]) ->
    {B1,B2,B3,B4} = {A1 - 240, A2- 128, A3 - 128, A4 - 128},
    {C1, C2, C3} = {(B1 bsl 2) + (B2 bsr 4), 
         ((B2 band 15) bsl 4) + (B3 bsr 2),
         ((B2 band 3) bsl 6) + B4},
    (C1 bsl 16) + (C2 bsl 8) + C3.

%% unicode to utf8
unicode_to_utf8(V) when V < 128 ->      % 7bit
    V;
unicode_to_utf8(V) when V < 2048 ->     % 11bit
    [192 + (V bsr 6), 128 + (V band 63)];
unicode_to_utf8(V) when V < 65536 ->    % 16bit
    [224 + (V bsr 12), 128 + ((V band 4032) bsr 6), 128 + (V band 63)];
unicode_to_utf8(V) when V < 2097152 ->  % 21bit
    [240 + (V bsr 18), 128 + ((V band 208048) bsr 12), 128 + ((V band 4032) bsr 6), 128 + (V band 63)].

    
%% separate hol and dat sound
jamo(B) when is_list(B) ->
    C = [lists:nth(1, B) - 224, lists:nth(2, B) - 128, lists:nth(3, B) - 128],
    D = [(lists:nth(1, C) bsl 4) + (lists:nth(2, C) bsr 2), 
         ((lists:nth(2, C) band 3) bsl 6) + lists:nth(3, C)],
    E = lists:nth(1, D) bsl 8 + lists:nth(2, D),
    case is_nop(E) of
        true ->
            [11, 5, 0]; %% nop.
        false ->
            [trunc(trunc(((E - 44032) - (E -44032) rem 28) / 28) / 21),
             trunc(((E - 44032) - (E - 44032) rem 28) / 28) rem 21,
             (E - 44032) rem 28]
    end.

get(RowI, _, _) when RowI < 1 ->
    {error, y_lower_bound};
get(_, ColI, _) when ColI < 1 -> {error, x_lower_bound};
get(RowI, ColI, A) ->
    case length(A) of
        Ylen when Ylen < RowI ->
            {error, y_upper_bound};
        _ ->
            Row = lists:nth(RowI, A),
            case length(Row) of
                Xlen when Xlen < ColI ->
                    {error, x_upper_bound};
                _ ->
                    lists:nth(ColI, Row)
            end
    end.

%% enqueue
push_or_enqueue({22, _Store}, V) -> 
    {Head, _} = lists:split(21, _Store),
    Target = lists:nth(22, _Store),
    {_, Tail} = lists:split(22, _Store),
    lists:append(lists:append(Head, [lists:append(Target, [V])]), Tail);
%% push
push_or_enqueue({N, _Store}, V) -> 
    {Head, _} = lists:split(N - 1, _Store),
    Target = lists:nth(N, _Store),
    {_, Tail} = lists:split(N, _Store),
    lists:append(lists:append(Head, [[V | Target]]), Tail).    
pop_or_dequeue({N, _Store}) ->
    {Head, _} = lists:split(N-1, _Store),
    _Body = lists:nth(N, _Store),
    {_, Tail} = lists:split(N, _Store),
    {[V], Body} = lists:split(1, _Body),
    {V, lists:append(lists:append(Head, [Body]), Tail)}.
%% return top element of stack or queue
top({N, Store}) ->
    get(N, 1, Store).

%% create empty lists
create_list(N) -> create_list(N, []).
create_list(0, Acc) -> Acc;
create_list(N, Acc) -> create_list(N - 1, [[] | Acc]).

%% nop
aheui_fsm([11, Hol, _], Dir, Store) -> 
    {hol_to_dir(Hol, Dir), Store};
%% end of aheui
aheui_fsm([18, _, _], _, {N, Store}) -> 
    case length(lists:nth(N, Store)) of
        L when L == 0 ->
            {eoa, 0};
        _ ->
            {V, _} = pop_or_dequeue({N, Store}),
            {eoa, V}
    end;
%% add
aheui_fsm([3, Hol, _], Dir, {N, _Store}) ->
    case length(lists:nth(N, _Store)) of
        L when L >= 2 ->
            {A, Store1} = pop_or_dequeue({N, _Store}),
            {B, Store2} = pop_or_dequeue({N, Store1}),
            Store = push_or_enqueue({N, Store2}, A+B),
            {hol_to_dir(Hol, Dir), {N, Store}};
        _ ->
            {reverse_dir(hol_to_dir(Hol, Dir)), {N, _Store}}
    end;
%% mul
aheui_fsm([4, Hol, _], Dir, {N, _Store}) ->
    case length(lists:nth(N, _Store)) of
        L when L >= 2 ->
            {A, Store1} = pop_or_dequeue({N, _Store}),
            {B, Store2} = pop_or_dequeue({N, Store1}),
            Store = push_or_enqueue({N, Store2}, A*B),
            {hol_to_dir(Hol, Dir), {N, Store}};
        _ ->
            {reverse_dir(hol_to_dir(Hol, Dir)), {N, _Store}}
    end;
%% sub
aheui_fsm([16, Hol, _], Dir, {N, _Store}) ->
    case length(lists:nth(N, _Store)) of
        L when L >= 2 ->
            {A, Store1} = pop_or_dequeue({N, _Store}),
            {B, Store2} = pop_or_dequeue({N, Store1}),
            Store = push_or_enqueue({N, Store2}, B-A),
            {hol_to_dir(Hol, Dir), {N, Store}};
        _ ->
            {reverse_dir(hol_to_dir(Hol, Dir)), {N, _Store}}
    end;
%% div
aheui_fsm([2, Hol, _], Dir, {N, _Store}) ->
    case length(lists:nth(N, _Store)) of
        L when L >= 2 ->
            {A, Store1} = pop_or_dequeue({N, _Store}),
            {B, Store2} = pop_or_dequeue({N, Store1}),
            Store = push_or_enqueue({N, Store2}, trunc(B/A)),
            {hol_to_dir(Hol, Dir), {N, Store}};
        _ ->
            {reverse_dir(hol_to_dir(Hol, Dir)), {N, _Store}}
    end;
%% rem
aheui_fsm([5, Hol, _], Dir, {N, _Store}) ->
    case length(lists:nth(N, _Store)) of
        L when L >= 2 ->
            {A, Store1} = pop_or_dequeue({N, _Store}),
            {B, Store2} = pop_or_dequeue({N, Store1}),
            Store = push_or_enqueue({N, Store2}, B rem A),
            {hol_to_dir(Hol, Dir), {N, Store}};
        _ ->
            {reverse_dir(hol_to_dir(Hol, Dir)), {N, _Store}}
    end;
%% print int
aheui_fsm([6, Hol, 21], Dir, {N, _Store}) ->
    case length(lists:nth(N, _Store)) of
        L when L >= 1 ->
            case pop_or_dequeue({N, _Store}) of
                {A, Store} when is_list(A) ->
                    io:fwrite("~w", [utf8_to_unicode(A)]),
                    {hol_to_dir(Hol, Dir), {N, Store}};
                {A, Store} ->
                    io:fwrite("~p", [A]),
                    {hol_to_dir(Hol, Dir), {N, Store}}
            end;
        _ ->
            {reverse_dir(hol_to_dir(Hol, Dir)), {N, _Store}}
    end;
%% print utf8
aheui_fsm([6, Hol, 27], Dir, {N, _Store}) ->
    case length(lists:nth(N, _Store)) of
        L when L >= 1 ->
            case pop_or_dequeue({N, _Store}) of
                {A, Store} when is_list(A) ->
                    io:fwrite("~ts", [A]);
                {A, Store} when A > 128  ->
                    io:fwrite("~s", [unicode_to_utf8(A)]);
                {A, Store} ->
                    io:fwrite("~s", [[A]])
            end,
            {hol_to_dir(Hol, Dir), {N, Store}};
        _ ->
            {reverse_dir(hol_to_dir(Hol, Dir)), {N, _Store}}
    end;
%% just pop
aheui_fsm([6, Hol, _], Dir, {N, _Store}) ->
    case length(lists:nth(N, _Store)) of
        L when L >= 1 ->
            {_, Store} = pop_or_dequeue({N, _Store}),
            {hol_to_dir(Hol, Dir), {N, Store}};
        _ ->
            {reverse_dir(hol_to_dir(Hol, Dir)), {N, _Store}}
    end;
%% get integer
aheui_fsm([7, Hol, 21], Dir, {N, _Store}) ->
    {ok, [V]} = io:fread("", "~d"),
    Store = push_or_enqueue({N, _Store}, V),
    {hol_to_dir(Hol, Dir), {N, Store}};
%% get utf8
aheui_fsm([7, Hol, 27], Dir, {N, _Store}) ->
    case io:fread("", "~c") of
        {ok, [[V]]} when V < 128 -> % 7bit
            Store = push_or_enqueue({N, _Store}, V),
            {hol_to_dir(Hol, Dir), {N, Store}};
        {ok, [[V]]} when V < 224 -> % 11bit
            {ok, [L]} = io:fread("", "~c"),
            Store = push_or_enqueue({N, _Store}, [V | L]),
            {hol_to_dir(Hol, Dir), {N, Store}};
        {ok, [[V]]} when V < 240 -> % 16bit
            {ok, [L]} = io:fread("", "~2c"),
            Store = push_or_enqueue({N, _Store}, [V | L]),
            {hol_to_dir(Hol, Dir), {N, Store}};
        {ok, [[V]]} when V < 248 -> % 21bit
            {ok, [L]} = io:fread("", "~3c"),
            Store = push_or_enqueue({N, _Store}, [V | L]),
            {hol_to_dir(Hol, Dir), {N, Store}};
        eof ->
            Store = push_or_enqueue({N, _Store}, 0),
            {hol_to_dir(Hol, Dir), {N, Store}}
    end;
%% push num
aheui_fsm([7, Hol, Bat], Dir, {N, _Store}) ->
    Store = push_or_enqueue({N, _Store}, bat_to_num(Bat)),
    {hol_to_dir(Hol, Dir), {N, Store}};
%% dup
aheui_fsm([8, Hol, _], Dir, {N, _Store}) ->
    case length(lists:nth(N, _Store)) of
        L when L >= 1 ->
            V = top({N, _Store}),
            {Head, _} = lists:split(N - 1, _Store),
            Target = lists:nth(N, _Store),
            {_, Tail} = lists:split(N, _Store),
            Store = lists:append(lists:append(Head, [[V | Target]]), Tail),
            {hol_to_dir(Hol, Dir), {N, Store}};
        _ ->
            {reverse_dir(hol_to_dir(Hol, Dir)), {N, _Store}}
    end;
%% xchg
aheui_fsm([17, Hol, _], Dir, {N, _Store}) ->
    case length(lists:nth(N, _Store)) of
        L when L >= 2 ->
            Store = xchg({N, _Store}),
            {hol_to_dir(Hol, Dir), Store};
        _ ->
            {reverse_dir(hol_to_dir(Hol, Dir)), {N, _Store}}
    end;
%% select
aheui_fsm([9, Hol, Bat], Dir, {_, Store}) ->
    {hol_to_dir(Hol, Dir), {Bat+1, Store}};
%% pop push
aheui_fsm([10, Hol, Bat], Dir, {N, _Store}) ->
    case length(lists:nth(N, _Store)) of
        L when L >= 1 ->
            {V, Store1} = pop_or_dequeue({N, _Store}),
            Store = push_or_enqueue({Bat+1, Store1}, V),
            {hol_to_dir(Hol, Dir), {N, Store}};
        _ ->
            {reverse_dir(hol_to_dir(Hol, Dir)), {N, _Store}}
    end;
%% cmp
aheui_fsm([12, Hol, _], Dir, {N, _Store}) ->
    case length(lists:nth(N, _Store)) of
        L when L >= 2 ->
            {A, Store1} = pop_or_dequeue({N, _Store}),
            {B, Store2} = pop_or_dequeue({N, Store1}),
            case {A, B} of
                {A, B} when B >= A ->
                    Store = push_or_enqueue({N, Store2}, 1),
                    {hol_to_dir(Hol, Dir), {N, Store}};
                _ ->
                    Store = push_or_enqueue({N, Store2}, 0),
                    {hol_to_dir(Hol, Dir), {N, Store}}
            end;
        _ ->
            {reverse_dir(hol_to_dir(Hol, Dir)), {N, _Store}}
    end;
%% cond
aheui_fsm([14, Hol, _], Dir, {N, _Store}) ->
    case length(lists:nth(N, _Store)) of
        L when L >= 1 ->
            case pop_or_dequeue({N, _Store}) of
                {0, Store} ->
                    {reverse_dir(hol_to_dir(Hol, Dir)), {N, Store}};
                {_, Store} ->
                    {hol_to_dir(Hol, Dir), {N, Store}}
            end;
        _ ->
            {reverse_dir(hol_to_dir(Hol, Dir)), {N, _Store}}
    end;
%% nop
aheui_fsm(_, Dir, Store) -> aheui_fsm(11, Dir, Store).

%% exchange order of top 2 element
xchg({N, Store}) ->
    Target = lists:nth(N, Store),
    {Head, Tail} = lists:split(2, Target),
    {A, _} = lists:split(N - 1, Store),
    B = lists:append(lists:reverse(Head), Tail),
    {_, C} = lists:split(N, Store),
    {N, lists:append(lists:append(A, [B]), C)}.

%% mapping hol sound to direction
hol_to_dir(0, _Dir)             -> {right, 1};                      % a
hol_to_dir(4, _Dir)             -> {left, 1};                       % eo
hol_to_dir(8, _Dir)             -> {up, 1};                         % o
hol_to_dir(13, _Dir)            -> {down, 1};                       % u
hol_to_dir(2, _Dir)             -> {right, 2};                      % ya
hol_to_dir(6, _Dir)             -> {left, 2};                       % yeo
hol_to_dir(12, _Dir)            -> {up, 2};                         % yo
hol_to_dir(17, _Dir)            -> {down, 2};                       % yu
hol_to_dir(18, {up, Step})      -> reverse_dir({up, Step});         % eu
hol_to_dir(18, {down, Step})    -> reverse_dir({down, Step});       % eu
hol_to_dir(18, _Dir)            -> _Dir;                            % eu
hol_to_dir(20, {left, Step})    -> reverse_dir({left, Step});       % i
hol_to_dir(20, {right, Step})   -> reverse_dir({right, Step});      % i
hol_to_dir(20, _Dir)            -> _Dir;                            % i
hol_to_dir(19, _Dir)            -> reverse_dir(_Dir);               % eui
hol_to_dir(_, _Dir)             -> _Dir.                            % nop

%% mapping batchim to number
bat_to_num(0)               -> 0; % Term
bat_to_num(1)               -> 2; % ㄱ
bat_to_num(2)               -> 4; % ㄲ
bat_to_num(3)               -> 4; % ㄳ
bat_to_num(4)               -> 2; % ㄴ

bat_to_num(5)               -> 5; % ㄵ
bat_to_num(6)               -> 5; % ㄶ
bat_to_num(7)               -> 3; % ㄷ
bat_to_num(8)               -> 5; % ㄹ
bat_to_num(9)               -> 7; % ㄺ

bat_to_num(10)              -> 9; % ㄻ
bat_to_num(11)              -> 9; % ㄼ
bat_to_num(12)              -> 7; % ㄽ
bat_to_num(13)              -> 9; % ㄾ
bat_to_num(14)              -> 9; % ㄿ

bat_to_num(15)              -> 8; % ㅀ
bat_to_num(16)              -> 4; % ㅁ
bat_to_num(17)              -> 4; % ㅂ
bat_to_num(18)              -> 6; % ㅄ
bat_to_num(19)              -> 2; % ㅅ

bat_to_num(20)              -> 4; % ㅆ
% bat_to_num(21)            -> 0; % ㅇ
bat_to_num(22)              -> 3; % ㅈ
bat_to_num(23)              -> 4; % ㅊ
bat_to_num(24)              -> 3; % ㅋ

bat_to_num(25)              -> 4; % ㅌ
bat_to_num(26)              -> 4; % ㅍ
% bat_to_num(27)            -> 0; % ㅎ
bat_to_num(_)               -> -1. % error

%% mapping reverse dir
reverse_dir({right, Step})          -> {left, Step};
reverse_dir({left, Step})           -> {right, Step};
reverse_dir({up, Step})             -> {down, Step};
reverse_dir({down, Step})           -> {up, Step}.

%% make aheui 2-demension list
make2d(_BList, _L) when length(_BList) < 3 ->
    _L;
make2d(_BList, _L) ->
    {BList, L} = make1d(_BList, []),
    make2d(BList, lists:append(_L, [L])).
make1d(_BList, LL) when length(_BList) == 0 ->
    {_BList, LL};
make1d(_BList, LL) when length(_BList) > 0 ->
    {_V, BList} = lists:split(1, _BList),
    V = lists:nth(1, _V),
    case lex(V) of
        {more, X} ->
            {A, BList2} = lists:split(X, BList),
            C = [V | A],
            case lex(C) of
                newline ->
                    {BList, LL};
                hangul ->
                    make1d(BList2, lists:append(LL, [jamo(C)]));
                nop ->
                    make1d(BList2, lists:append(LL, [[11, 5, 0]]))
            end;
        {nop, X} ->
            {_, BList2} = lists:split(X, BList),
            make1d(BList2, lists:append(LL, [[11, 5, 0]]));
        nop ->
            make1d(BList, lists:append(LL, [[11, 5, 0]]));
        newline ->
            {BList, LL}
    end.

%% is hangul? or newline? or nop?
lex([13, 10])                               -> newline;       % \r\n
lex(L) when is_list(L)                      -> lex(lists:nth(1, L), lists:nth(2, L), lists:nth(3, L));
lex(10)                                     -> newline;       % \n
lex(13)                                     -> {more, 1};     % might be \r\n
lex(V) when V < 127                         -> nop;
lex(V) when V < 239                         -> {more, 2};     % less then 1110 0000
lex(V) when V < 247                         -> {nop, 3};      % less then 1111 0000
lex(_)                                      -> nop.

lex(_, Y, Z) when (Y < 128) or (Z < 128)    -> nop;
lex(X, _, _) when (X > 234) and (X < 237)   -> hangul;
lex(234, Y, _) when Y > 176                 -> hangul;
lex(237, Y, _) when Y < 158                 -> hangul;
lex(234, 176, Z) when Z >= 128              -> hangul; 
lex(237, 158, Z) when Z =< 163              -> hangul; 
lex(_, _, _)                                -> nop.
