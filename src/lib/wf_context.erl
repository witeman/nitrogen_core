% vim: sw=4 ts=4 et ft=erlang
% Nitrogen Web Framework for Erlang
% Copyright (c) 2008-2010 Rusty Klophaus
% See MIT-LICENSE for licensing information.

-module (wf_context).
-include("wf.hrl").
-compile(export_all).

%%% REQUEST AND RESPONSE BRIDGE %%%

request_bridge() ->
    Context = context(),
    Context#context.request_bridge.

request_bridge(RequestBridge) ->
    Context = context(),
    Context#context { request_bridge = RequestBridge }.

response_bridge() ->
    Context = context(),
    Context#context.response_bridge.

response_bridge(ResponseBridge) ->
    Context = context(),
    context(Context#context { response_bridge = ResponseBridge }).

socket() ->
    Req = wf_context:request_bridge(), 
    Req:socket().

path() ->
    Req = request_bridge(),
    Req:path().

uri() ->
    Req = request_bridge(),
    Req:uri().

peer_ip() ->
    Req = request_bridge(),
    Req:peer_ip().

peer_ip(Proxies) ->
    peer_ip(Proxies,x_forwarded_for).

peer_ip(Proxies,ForwardedHeader) ->
    ConnIP = peer_ip(),
    case header(ForwardedHeader) of
        undefined -> ConnIP;
        RawForwardedIP ->
            ForwardedIP = wf_convert:parse_ip(RawForwardedIP),
            DoesIPMatch = fun(Proxy) ->
                wf_convert:parse_ip(Proxy) =:= ConnIP
            end,
            case lists:any(DoesIPMatch,Proxies) of
                true -> ForwardedIP;
                false -> ConnIP
            end
    end.


request_body() ->
    Req = request_bridge(),
    Req:request_body().

status_code() ->
    Req = request_bridge(),
    Req:status_code().

status_code(StatusCode) ->
    Res = response_bridge(),
    response_bridge(Res:status_code(StatusCode)),
    ok.

content_type(ContentType) ->
    Res = response_bridge(),
    response_bridge(Res:header("Content-Type", ContentType)),
    ok.

headers() ->
    Req = request_bridge(),
    Req:headers().

header(Header) ->
    Req = request_bridge(),
    Req:header(Header).

header(Header, Value) ->
    Res = response_bridge(),
    response_bridge(Res:header(Header, Value)),
    ok.

cookies() ->
    Req = request_bridge(),
    Req:cookies().

cookie(Cookie) when is_atom(Cookie) ->
    cookie(atom_to_list(Cookie));
cookie(Cookie) ->
    Req = request_bridge(),
    Req:cookie(Cookie).

cookie_default(Cookie,DefaultValue) ->
    case cookie(Cookie) of
        undefined -> DefaultValue;
        Value -> Value
    end.

cookie(Cookie, Value) ->
    Res = response_bridge(),
    response_bridge(Res:cookie(Cookie, Value)),
    ok.

cookie(Cookie, Value, Path, MinutesToLive) ->
    Res = response_bridge(),
    response_bridge(Res:cookie(Cookie, Value, Path, MinutesToLive)),
    ok.

delete_cookie(Cookie) ->
    cookie(Cookie,"","/",0).


%%% TRANSIENT CONTEXT %%%

anchor(Anchor) ->
    Context = context(),
    context(Context#context { anchor=Anchor }).

anchor() ->
    Context = context(),
    Context#context.anchor.

data() ->
    Context = context(),
    Context#context.data.

data(Data) ->
    Context = context(),
    context(Context#context { data = Data }).

clear_data() ->
    Context = context(),
    context(Context#context { data = [] }).

-spec add_action(Priority :: wire_priority(), Action :: actions()) -> ok.
add_action(Priority, Action) when ?IS_ACTION_PRIORITY(Priority) ->
    ActionQueue = action_queue(),
    NewActionQueue = wf_action_queue:in(Priority, Action, ActionQueue),
    action_queue(NewActionQueue).

actions() ->
    ActionQueue = action_queue(),
    Actions = wf_action_queue:all(ActionQueue),
    NewActionQueue = wf_action_queue:clear(ActionQueue),
    action_queue(NewActionQueue),
    Actions.

-spec next_action() -> {ok, actions()} | empty.
next_action() ->
	ActionQueue = action_queue(),
	case wf_action_queue:out(ActionQueue) of
		{ok, Action, NewActionQueue} ->
            action_queue(NewActionQueue),
            {ok, Action};
		{error, empty} ->
            empty
	end.

action_queue() ->
	Context = context(),
	Context#context.action_queue.

action_queue(ActionQueue) ->
    Context = context(),
    context(Context#context { action_queue = ActionQueue }).

clear_action_queue() ->
    action_queue(new_action_queue()).

new_action_queue() ->
    wf_action_queue:new().

%%% PAGE CONTEXT %%%

page_context() ->
    Context = context(),
    Context#context.page_context.

page_context(PageContext) ->
    Context = context(),
    context(Context#context { page_context = PageContext }).

series_id() ->
    Page = page_context(),
    Page#page_context.series_id.

series_id(SeriesID) ->
    Page = page_context(),
    page_context(Page#page_context { series_id = SeriesID }).

page_module() -> 
    Page = page_context(),
    Page#page_context.module.

page_module(Module) ->
    Page = page_context(),
    page_context(Page#page_context { module = Module }).

path_info() -> 
    Page = page_context(),
    Page#page_context.path_info.

path_info(PathInfo) ->
    Page = page_context(),
    page_context(Page#page_context { path_info = PathInfo }).

async_mode() ->
    Page = page_context(),
    Page#page_context.async_mode.

async_mode(AsyncMode) ->
    Page = page_context(),
    page_context(Page#page_context { async_mode=AsyncMode }).


%%% EVENT CONTEXT %%%

event_context() ->
    Context = context(),
    Context#context.event_context.

event_context(EventContext) ->
    Context = context(),
    context(Context#context { event_context = EventContext }).


type() ->
    Context = context(),
    Context#context.type.

type(Type) -> % either first_request, postback_request, or static_file
    Context = context(),
    context(Context#context { type = Type }).

event_module() ->
    Event = event_context(),
    Event#event_context.module.

event_module(Module) ->
    Event = event_context(),
    event_context(Event#event_context { module = Module }).

event_tag() ->
    Event = event_context(),
    Event#event_context.tag.

event_tag(Tag) ->
    Event = event_context(),
    event_context(Event#event_context { tag = Tag }).

event_validation_group() ->
    Event = event_context(),
    Event#event_context.validation_group.

event_validation_group(ValidationGroup) ->
    Event = event_context(),
    event_context(Event#event_context { validation_group = ValidationGroup }).

event_handle_invalid() ->
    Event = event_context(),
    Event#event_context.handle_invalid.

event_handle_invalid(HandleInvalid) ->
    Event = event_context(),
    event_context(Event#event_context { handle_invalid = HandleInvalid }).

%%% HANDLERS %%%

handlers() ->
    Context = context(),
    Context#context.handler_list.

handlers(Handlers) ->
    Context = context(),
    context(Context#context { handler_list = Handlers }).

%%% CONTEXT CONSTRUCTION %%%

init_context(RequestBridge, ResponseBridge) ->
    % Create the new context using the default handlers.
    Context = #context {
        request_bridge = RequestBridge,
        response_bridge = ResponseBridge,
        page_context = #page_context { series_id = wf:temp_id() },
        event_context = #event_context {},
        action_queue = new_action_queue(),		
        handler_list = [
            % Core handlers...
            make_handler(config_handler, default_config_handler), 
            make_handler(log_handler, default_log_handler),
            make_handler(process_registry_handler, nprocreg_registry_handler),
            make_handler(cache_handler, default_cache_handler), 
            make_handler(query_handler, default_query_handler),
            make_handler(crash_handler, default_crash_handler),

            % Stateful handlers...
            make_handler(session_handler, simple_session_handler), 
            make_handler(state_handler, default_state_handler), 
            make_handler(identity_handler, default_identity_handler), 
            make_handler(role_handler, default_role_handler), 

            % Handlers that possibly redirect...
            make_handler(route_handler, dynamic_route_handler), 
            make_handler(security_handler, default_security_handler)
        ]
    },
    context(Context).

make_handler(Name, Module) -> 
    #handler_context { 
        name=Name,
        module=Module,
        state=[]
    }.


%%% GET AND SET CONTEXT %%%
% Yes, the context is stored in the process dictionary. It makes the Nitrogen 
% code much cleaner. Trust me.
context() -> get(context).
context(Context) -> put(context, Context).
