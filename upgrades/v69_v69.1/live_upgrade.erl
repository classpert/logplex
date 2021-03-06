f(UpgradeNode).
UpgradeNode = fun () ->
  case logplex_app:config(git_branch) of
      "v69" ->
          io:format(whereis(user), "at=upgrade_start cur_vsn=69~n", []);
      "v69-R16B01" ->
          io:format(whereis(user), "at=upgrade_start cur_vsn=69-R16B01~n", []);
      "v69-R16B01-swfi" ->
          io:format(whereis(user), "at=upgrade_start cur_vsn=69-R16B01-swfi~n", []);
      "v69.1" ->
          io:format(whereis(user),
                    "at=upgrade type=retry cur_vsn=69 old_vsn=69.1~n", []);
      Else ->
          io:format(whereis(user),
                    "at=upgrade_start old_vsn=~p abort=wrong_version", [tl(Else)]),
          erlang:error({wrong_version, Else})
  end,

  %% stateless

  % Minor changes to the logging/response order for performance
  l(logplex_api),

  application:set_env(logplex, git_branch, "v69.1"),
  ok
end.

f(NodeVersions).
NodeVersions = fun () ->
                       lists:keysort(3,
                           [ {N,
                              element(2, rpc:call(N, application, get_env, [logplex, git_branch])),
                              rpc:call(N, os, getenv, ["INSTANCE_NAME"])}
                             || N <- [node() | nodes()] ])
               end.

f(NodesAt).
NodesAt = fun (Vsn) ->
                  [ N || {N, V, _} <- NodeVersions(), V =:= Vsn ]
          end.


f(RollingUpgrade).
RollingUpgrade = fun (Nodes) ->
  lists:foldl(fun (N, {good, Upgraded}) ->
    case rpc:call(N, erlang, apply, [ UpgradeNode, [] ]) of
      ok ->
        {good, [N | Upgraded]};
      Else ->
        {{bad, N, Else}, Upgraded}
    end;
    (N, {_, _} = Acc) -> Acc
    end,
    {good, []},
    Nodes)
end.


