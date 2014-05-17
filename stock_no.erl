-module(stock_no).
%%-compile([{parse_transform, lager_transform}]).
-compile(export_all).

-export([run/1]).

-record(otc_format1, {
    stock_no,
	stock_name,
	itype,
	mtype,
	count_note,
	stock_error_code,
	index_note,
	ref_price,
	limit_up_price,
	limit_down_price,
	decimal_note,
	promote_note,
	special_note,
	warrant_type,
	strick_price,
	perform_qty,
	cancel_qty,
	issued_balance,
	exercise_ratio,
	lot,
	currency,
	line_type
}).		


-record(tse_format1, {
    stock_no,
	stock_name,
	itype,
	mtype,
	count_note,
	stock_error_code,
	index_note,
	ref_price,
	limit_up_price,
	limit_down_price,
	decimal_note,
	promote_note,
	special_note,
	warrant_type,
	strick_price,
	perform_qty,
	cancel_qty,
	issued_balance,
	exercise_ratio,
	lot,
	currency,
	line_type
}).		

-record(tfe_format010, {
    prod_id,
	rise_limit_price1,
	ref_price,
	fall_limit_price1,
	rise_limit_price2,
	fall_limit_price2,
	rise_limit_price3,
	fall_limit_price3,
	prod_kind,
	decimal_locator,
	strike_price_decimal_locator,
	sdate,
	edate
}).				

-record(indexprice, {
	routingkey,
	stock_no,
	sys_time,
	ref_price,
	price,
	open_price,
	high_price,
	low_price,
	close_price,
	amt,
	tamt}).	
	

-record(tseprice, {
	routingkey,
	stock_no,
	sys_time,
	ref_price,
	price,
	qty,
	tqty,
	open_price,
	high_price,
	low_price,
	close_price,
	buy_order_book,
	sell_order_book,
	inner_qty,
	inner_tqty,
	outer_qty,
	outer_tqty,
	amt,
	tamt,
	updown
	}).	
	
start(Command, InputFileName) ->
	{ok, Redis} = eredis:start_link("127.0.0.1", 6379, 0, "", no_reconnect),
	{ok, Redis1} = eredis:start_link("127.0.0.1", 6379, 1, "", no_reconnect),
	case Command of
		stockno -> init_twse_data("twse.fm01.*", Redis);
		stock -> {ok, KeyList} = eredis:q(Redis, [ "KEYS", "twse.fm01.*" ]),
			     FM01 = [  get_fm01(Key,Redis) || Key <- KeyList],
				 Data = lists:flatten([to_json01(FM,Redis1) || FM <- FM01]),
				 io:format("stock Data = ~p~n",[Data]),		
				 file:write_file(InputFileName, 
					lists:concat([["const StockList = ["], Data, " {\"stock_no\": null}];"]));
		futures -> {ok, KeyList} = eredis:q(Redis, [ "KEYS", "twfe.I010.*" ]),
			     FM01 = [  get_fm010(Key,Redis) || Key <- KeyList],
				 Data = lists:flatten([to_json010(FM) || FM <- FM01]),
				 io:format("futures Data = ~p~n",[Data]),		
				 file:write_file(InputFileName, 
					lists:concat([["const TFE_ProdList = ["], Data, " {\"stock_no\": null}];"]));
		index -> {ok, KeyList} = eredis:q(Redis, [ "KEYS", "twse.fm03.*" ]),
			     FM01 = [  get_fm03(Key,Redis) || Key <- KeyList],
				 Data = lists:flatten([to_json03(FM, Redis1) || FM <- FM01]),
				 io:format("index Data = ~p~n",[Data]),		
				 file:write_file(InputFileName, 
					lists:concat([["const IndexList = ["], Data, " {\"index_no\": null}];"]))
%%		options ->
	end.

get_fm03(Key, Redis) ->
	{ok, FM} = eredis:q(Redis, [ "GET", Key ]),
	binary_to_term(FM).	
	
get_fm01(Key, Redis) ->
	{ok, FM} = eredis:q(Redis, [ "GET", Key ]),
	binary_to_term(FM).
	
	
to_json03(FM, Redis1) when is_record(FM, indexprice) ->
	case FM#indexprice.stock_no of
		<<"T00001">> -> Index_Name = "上市加權", IType = "";
		<<"T00002">> -> Index_Name = "不含金融", IType = "";
		<<"T00003">> -> Index_Name = "不含電子", IType = "";
		<<"T00004">> -> Index_Name = "化學工業", IType = "21";
		<<"T00005">> -> Index_Name = "生技醫療", IType = "22";
		<<"T00006">> -> Index_Name = "水泥窯製", IType = "08";
		<<"T00007">> -> Index_Name = "食品", IType = "02";
		<<"T00008">> -> Index_Name = "塑膠化工", IType = "03";
		<<"T00009">> -> Index_Name = "紡織纖維", IType = "04";
		<<"T00010">> -> Index_Name = "機電", IType = "05";
		<<"T00011">> -> Index_Name = "造紙", IType = "09";
		<<"T00012">> -> Index_Name = "營造建材", IType = "14";
		<<"T00013">> -> Index_Name = "雜項", IType = "20";
		<<"T00014">> -> Index_Name = "金融保險", IType = "17";
		<<"T00015">> -> Index_Name = "水泥工業", IType = "01";
		<<"T00016">> -> Index_Name = "食品工業", IType = "02";
		<<"T00017">> -> Index_Name = "塑膠工業", IType = "03";
		<<"T00018">> -> Index_Name = "紡織纖維", IType = "04";
		<<"T00019">> -> Index_Name = "電機機械", IType = "05";
		<<"T00020">> -> Index_Name = "電器電纜", IType = "06";
		<<"T00021">> -> Index_Name = "生技醫療", IType = "21,22";
		<<"T00022">> -> Index_Name = "玻璃陶瓷", IType = "08";
		<<"T00023">> -> Index_Name = "造紙工業", IType = "09";
		<<"T00024">> -> Index_Name = "鋼鐵工業", IType = "10";
		<<"T00025">> -> Index_Name = "橡膠工業", IType = "11";
		<<"T00026">> -> Index_Name = "汽車工業", IType = "12";
		<<"T00027">> -> Index_Name = "電子工業", IType = "24,25,26,27,28,29,30,31";
		<<"T00028">> -> Index_Name = "營造建材", IType = "14";
		<<"T00029">> -> Index_Name = "航運", IType = "15";
		<<"T00030">> -> Index_Name = "觀光事業", IType = "16";
		<<"T00031">> -> Index_Name = "金融保險", IType = "17";
		<<"T00032">> -> Index_Name = "貿易百貨", IType = "18";
		<<"T00033">> -> Index_Name = "其他", IType = "20";
		<<"T00034">> -> Index_Name = "未含金融電子", IType = "";
		<<"T00035">> -> Index_Name = "油電燃氣", IType = "23";
		<<"T00036">> -> Index_Name = "半導體", IType = "24";
		<<"T00037">> -> Index_Name = "電腦周邊", IType = "25";
		<<"T00038">> -> Index_Name = "光電", IType = "26";
		<<"T00039">> -> Index_Name = "通信網路", IType = "27";
		<<"T00040">> -> Index_Name = "電子零組", IType = "28";
		<<"T00041">> -> Index_Name = "電子通路", IType = "29";
		<<"T00042">> -> Index_Name = "資訊服務", IType = "30";
		<<"T00043">> -> Index_Name = "其他電子", IType = "32";
		<<"O00001">> -> Index_Name = "上櫃加權", IType = "";
		<<"O00002">> -> Index_Name = "電子工業", IType = "24,25,26,27,28,29,30,31";
		<<"O00003">> -> Index_Name = "食品工業", IType = "02";
		<<"O00004">> -> Index_Name = "塑膠工業", IType = "03";
		<<"O00005">> -> Index_Name = "紡織纖維", IType = "04";
		<<"O00006">> -> Index_Name = "電機機械", IType = "05";
		<<"O00007">> -> Index_Name = "電器電纜", IType = "06";
		<<"O00008">> -> Index_Name = "玻璃陶瓷", IType = "08";
		<<"O00009">> -> Index_Name = "鋼鐵工業", IType = "10";
		<<"O00010">> -> Index_Name = "橡膠工業", IType = "11";
		<<"O00011">> -> Index_Name = "營造建材", IType = "14";
		<<"O00012">> -> Index_Name = "航運", IType = "15";
		<<"O00013">> -> Index_Name = "觀光", IType = "16";
		<<"O00014">> -> Index_Name = "金融", IType = "17";
		<<"O00015">> -> Index_Name = "貿易百貨", IType = "18";
		<<"O00016">> -> Index_Name = "化學工業", IType = "21";
		<<"O00017">> -> Index_Name = "生技醫療", IType = "22";
		<<"O00018">> -> Index_Name = "油電燃氣", IType = "23";
		<<"O00019">> -> Index_Name = "半導體", IType = "24";
		<<"O00020">> -> Index_Name = "電腦周邊", IType = "25";
		<<"O00021">> -> Index_Name = "光電", IType = "26";
		<<"O00022">> -> Index_Name = "網路通訊", IType = "27";
		<<"O00023">> -> Index_Name = "電子零件", IType = "28";
		<<"O00024">> -> Index_Name = "電子通路", IType = "29";
		<<"O00025">> -> Index_Name = "資訊服務", IType = "30";
		<<"O00026">> -> Index_Name = "未知一", IType = "32";
		<<"O00027">> -> Index_Name = "未知二", IType = "31";
		<<"O00028">> -> Index_Name = "未知三", IType = "80";
		<<"TW50  ">> -> Index_Name = "台灣五十", IType = "";
		<<"TWMC  ">> -> Index_Name = "台灣中型100", IType = "";
		<<"TWIT  ">> -> Index_Name = "資訊科技", IType = "";
		<<"TWEI  ">> -> Index_Name = "台灣發達", IType = "";
		<<"TWDP  ">> -> Index_Name = "台灣高股息", IType = "";
		<<"EMP99 ">> -> Index_Name = "台灣就業99", IType = "";
		<<"CO101 ">> -> Index_Name = "企業經營", IType = "";
		<<"GTSM50">> -> Index_Name = "富櫃五十", IType = "";
		<<"TWTBI ">> -> Index_Name = "指標公債", IType = "";
		<<"GAME  ">> -> Index_Name = "線上遊戲", IType = ""
	end,
	Last_Amt = query_last_amt(FM#indexprice.stock_no, Redis1), %%昨量

	L= lists:concat(["{\"index_no\": \"", binary_to_list(FM#indexprice.stock_no), "\", \"index_name\": \"",  Index_Name, "\",",
		"\"IType\": \"", IType, "\", \"ref_price\": \"", integer_to_list(FM#indexprice.ref_price), "\",",
		"\"last_amt\": ", integer_to_list(Last_Amt), ",\"digits\": ", integer_to_list(2), "},"]),
	L.
	
to_json01(FM, Redis1) when is_record(FM, tse_format1) ->
	[Stock_No | _] = binary:split(FM#tse_format1.stock_no, [<<" ">>]),
	Last_Qty = query_last_qty(Stock_No, Redis1), %%昨量
	L= lists:concat(["{\"stock_no\": \"", binary_to_list(FM#tse_format1.stock_no), "\", \"stock_name\": \"",  binary_to_list(FM#tse_format1.stock_name), "\",",
		"\"itype\": \"", binary_to_list(FM#tse_format1.itype), "\", \"mtype\": \"", binary_to_list(FM#tse_format1.mtype), "\",",
		"\"ref_price\": ", integer_to_list(FM#tse_format1.ref_price), ", \"limit_up_price\": ", integer_to_list(FM#tse_format1.limit_up_price), ",",
		"\"limit_down_price\": ", integer_to_list(FM#tse_format1.limit_down_price), ", \"warrant_type\": \"", binary_to_list(FM#tse_format1.warrant_type), "\",",
		"\"lot\": ", integer_to_list(FM#tse_format1.lot), ", \"currency\": \"", binary_to_list(FM#tse_format1.currency), "\",",
		"\"digits\":2,  \"last_qty\":",integer_to_list(Last_Qty) ,", \"btype\": \"01\"" ,"},"]),
	L;
		
		
to_json01(FM, Redis1) when is_record(FM, otc_format1) ->
	[Stock_No | _] = binary:split(FM#otc_format1.stock_no, [<<" ">>]),
	Last_Qty = query_last_qty(Stock_No, Redis1), %%昨量
	L= lists:concat(["{\"stock_no\": \"", binary_to_list(FM#otc_format1.stock_no), "\", \"stock_name\": \"",  binary_to_list(FM#otc_format1.stock_name), "\",",
		"\"itype\": \"", binary_to_list(FM#otc_format1.itype), "\", \"mtype\": \"", binary_to_list(FM#otc_format1.mtype), "\",",
		"\"ref_price\": ", integer_to_list(FM#otc_format1.ref_price), ", \"limit_up_price\": ", integer_to_list(FM#otc_format1.limit_up_price), ",",
		"\"limit_down_price\": ", integer_to_list(FM#otc_format1.limit_down_price), ", \"warrant_type\": \"", binary_to_list(FM#otc_format1.warrant_type), "\",",
		"\"lot\": ", integer_to_list(FM#otc_format1.lot), ", \"currency\": \"", binary_to_list(FM#otc_format1.currency), "\",",
		"\"digits\":2,  \"last_qty\":", integer_to_list(Last_Qty) , ", \"btype\": \"02\"" ,"},"]),
	L.
		
	
get_fm010(Key, Redis) ->
	{ok, FM} = eredis:q(Redis, [ "GET", Key ]),
	FM.	
	
to_json010((<<_:8/integer, Prod_ID:10/binary, Rise_Limit_Price1:32/integer, Ref_Price:32/integer, 
		Fall_Limit_Price1:32/integer, Rise_Limit_Price2:32/integer, Fall_Limit_Price2:32/integer, 
		Rise_Limit_Price3:32/integer, Fall_Limit_Price3:32/integer, Prod_Kind:1/binary, Decimal_Locator:16/integer, 
		Strike_Price_Decimal_Locator:16/integer, SDate:8/binary, EDate:8/binary>>)) ->
	case binary:part(Prod_ID, 0, 3) of
		<<"TXF">> -> Prod_Name = <<"台指期">>;
		<<"MXF">> -> Prod_Name = <<"小台期">>;
		<<"EXF">> -> Prod_Name = <<"電子期">>;
		<<"FXF">> -> Prod_Name = <<"金融期">>;
		<<"T5F">> -> Prod_Name = <<"台五十">>;
		<<"MSF">> -> Prod_Name = <<"摩台指">>;
		<<"XIF">> -> Prod_Name = <<"未金電">>;
		<<"GTF">> -> Prod_Name = <<"櫃買期">>;
		_ -> Prod_Name = <<"">>
	end,
	case size(Prod_Name) > 0 of
		true ->
			rfc4627:encode({obj, [{prod_id,Prod_ID},{prod_name,Prod_Name},{rise_limit_price1,Rise_Limit_Price1},
				{ref_price,Ref_Price},{fall_limit_price1,Fall_Limit_Price1},{rise_limit_price2,Rise_Limit_Price2},
				{fall_limit_price2,Fall_Limit_Price2},{rise_limit_price3,Rise_Limit_Price3},
				{fall_limit_price3,Fall_Limit_Price3},{prod_kind,Prod_Kind},
				{decimal_locator,Decimal_Locator},{strike_price_decimal_locator,Strike_Price_Decimal_Locator},
				{sdate,SDate}, {edate,EDate}]})++",";
		false -> ""
	end.
	
	
	
run(InputFileName) ->
	OTC_Format1 = ets:tab2list(otc_format1),
	Data = [compose_line(X) || X <- OTC_Format1],
	file:write_file(InputFileName, lists:concat([["const OTC_StockList = ["], Data, " {stock_no: null}];"])).
	
compose_line(A) ->
	L= lists:concat(["{stock_no: \"", binary_to_list(A#otc_format1.stock_no), "\", stock_name: \"",  binary_to_list(A#otc_format1.stock_name), "\",",
		"itype: \"", binary_to_list(A#otc_format1.itype), "\", mtype: \"", binary_to_list(A#otc_format1.mtype), "\",",
		"ref_price: ", integer_to_list(A#otc_format1.ref_price), ", limit_up_price: ", integer_to_list(A#otc_format1.limit_up_price), ",",
		"limit_down_price: ", integer_to_list(A#otc_format1.limit_down_price), ", warrant_type: \"", binary_to_list(A#otc_format1.warrant_type), "\",",
		"lot: ", integer_to_list(A#otc_format1.lot), ", currency: \"", binary_to_list(A#otc_format1.currency), "\"},"]),
	L.
	
get_twse(Key, Redis) ->
	{ok, FM} = eredis:q(Redis, [ "GET", Key ]),
	{Key, FM}.
		
		
		
init_twse_data(Key, Redis) ->	
	InputFileName = "stock.txt",
	{ok, KeyList} = eredis:q(Redis, [ "KEYS", Key ]),
	FMList = [  get_twse(Key1,Redis) || Key1 <- KeyList],
%%	io:format("FMList=~p~n",[FMList]),
%%	[ io:format("Payload=~p~n",[binary_to_term(Payload)]) || {RoutingKey, Payload} <- FMList],
	Data = [ compose_stock_no(binary_to_term(Payload)) || {RoutingKey, Payload} <- FMList],
	io:format("Data=~p, length=~p~n",[Data, length(Data)]),
	file:write_file(InputFileName, lists:flatten(Data)).
	
		
save_file(FM01) ->
	InputFileName = "stock.txt",
	case is_record(FM01, tse_format1) of
		true -> io:format("true FM01 = ~p~n",[FM01]),
			case FM01#tse_format1.itype of
					<<"  ">> -> io:format("FM01#tse_format1.itype = ~p is not industry~n",[FM01#tse_format1.itype]);
					<<"00">> -> io:format("FM01#tse_format1.itype = ~p is not industry~n",[FM01#tse_format1.itype]);
					_ -> 	[Stock_No | _] = binary:split(FM01#tse_format1.stock_no, [<<" ">>]),
						lists:concat([binary_to_list(Stock_No), ","])
			end;
		false -> io:format("false FM01 = ~p~n",[FM01]),
			case FM01#otc_format1.itype of
					<<"  ">> -> io:format("FM01#otc_format1.itype = ~p is not industry~n",[FM01#otc_format1.itype]);
					<<"00">> -> io:format("FM01#otc_format1.itype = ~p is not industry~n",[FM01#otc_format1.itype]);
					_ -> 	[Stock_No | _] = binary:split(FM01#otc_format1.stock_no, [<<" ">>]),
						lists:concat([binary_to_list(Stock_No), ","])
			end
	end.

compose_stock_no(FM01) ->
	case is_record(FM01, tse_format1) of
		true -> %%io:format("true FM01 = ~p~n",[FM01]),
			case FM01#tse_format1.itype of
					<<"  ">> ->  io:format("FM01#tse_format1.itype = ~p is not industry~n",[FM01#tse_format1.itype]), 
						"";
					<<"00">> ->  io:format("FM01#tse_format1.itype = ~p is not industry~n",[FM01#tse_format1.itype]),
						"";
					<<"A1">> ->  io:format("FM01#tse_format1.itype = ~p is not industry~n",[FM01#tse_format1.itype]),
						"";
					<<"A2">> ->  io:format("FM01#tse_format1.itype = ~p is not industry~n",[FM01#tse_format1.itype]),
						"";
					_ -> %%io:format("FM01#tse_format1.itype = ~p is industry~n",[FM01#tse_format1.itype]),
						[Stock_No | _] = binary:split(FM01#tse_format1.stock_no, [<<" ">>]),
						if size(Stock_No) > 4 -> io:format("compose_stock_no size lager 4 Stock_No = ~p~n",[FM01]);
							true -> ok
						end,
						lists:concat([binary_to_list(Stock_No), ","])
			end;
		false -> io:format("false FM01 = ~p~n",[FM01]),
			case FM01#otc_format1.itype of
					<<"  ">> ->  %%io:format("FM01#otc_format1.itype = ~p is not industry~n",[FM01#otc_format1.itype]), 
						"";
					<<"00">> ->  %%io:format("FM01#otc_format1.itype = ~p is not industry~n",[FM01#otc_format1.itype]), 
						"";
					<<"A1">> ->  %%io:format("FM01#otc_format1.itype = ~p is not industry~n",[FM01#otc_format1.itype]), 
						"";
					<<"A2">> ->  %%io:format("FM01#otc_format1.itype = ~p is not industry~n",[FM01#otc_format1.itype]), 
						"";
					_ -> %%io:format("FM01#otc_format1.itype = ~p is industry~n",[FM01#otc_format1.itype]),	
						[Stock_No | _] = binary:split(FM01#otc_format1.stock_no, [<<" ">>]),
						if size(Stock_No) > 4 -> io:format("compose_stock_no size lager 4 Stock_No = ~p~n",[FM01]);
							true -> ok
						end,
						lists:concat([binary_to_list(Stock_No), ","])
			end
	end.
%%	io:format("compose_stock_no Stock_No = ~p~n",[Stock_No]),
%%	Stock_No.
	


to_json(<<"twfe.I010">>, <<Count:8/integer, Payload/binary>>) ->
	Data = [ get_json010(binary:part(Payload, X*59-59, 59)) || X <- lists:seq(1, Count)],
	Header = rfc4627:encode({obj, [{code, <<"twfe.I010">>},{count, Count}]}),
	<<<<"{\"header\":">>/binary, (list_to_binary(Header))/binary, <<",\"data\":[">>/binary, (list_to_binary(Data))/binary, <<"]}">>/binary>>;
%%	rfc4627:encode({obj, [{header,Header},{data,Data}]}); 

			
to_json(<<"twse.fm01">>, <<Count:8/integer, Payload/binary>>) ->
%%io:format("to_json twse.fm01 Payload=~p~n",[Payload]),
	Data = [ get_json01(binary:part(Payload, X*45-45, 45)) || X <- lists:seq(1, Count)],
	Header = rfc4627:encode({obj, [{code, <<"twse.fm01">>},{count, Count}]}),
	<<<<"{\"header\":">>/binary, (list_to_binary(Header))/binary, <<",\"data\":[">>/binary, (list_to_binary(Data))/binary, <<"]}">>/binary>>.

get_json010(<<Prod_ID:10/binary, Rise_Limit_Price1:32/integer, Ref_Price:32/integer, 
		Fall_Limit_Price1:32/integer, Rise_Limit_Price2:32/integer, Fall_Limit_Price2:32/integer, 
		Rise_Limit_Price3:32/integer, Fall_Limit_Price3:32/integer, Prod_Kind:1/binary, Decimal_Locator:16/integer, 
		Strike_Price_Decimal_Locator:16/integer, SDate:8/binary, EDate:8/binary>>) ->
	rfc4627:encode({obj, [{prod_id,Prod_ID},{rise_limit_price1,Rise_Limit_Price1},{ref_price,Ref_Price},
			{fall_limit_price1,Fall_Limit_Price1},{rise_limit_price2,Rise_Limit_Price2},{fall_limit_price2,Fall_Limit_Price2},
			{rise_limit_price3,Rise_Limit_Price3},{fall_limit_price3,Fall_Limit_Price3},{prod_kind,Prod_Kind},
			{decimal_locator,Decimal_Locator},{strike_price_decimal_locator,Strike_Price_Decimal_Locator},
			{sdate,SDate}, {edate,EDate}]}).	

			
get_json01(<<Stock_No:6/binary, Stock_Name:6/binary, IType:2/binary, MType:2/binary, 
		Stock_Error_Code:2/binary, Index_Note:1/binary, Ref_Price:32/integer, 
		Limit_Up_Price:32/integer, Limit_Down_Price:32/integer, Decimal_Note:1/binary, 
		Promote_Note:1/binary, Special_Note:1/binary, Warrant_Type:1/binary,
		Lot:16/integer, Currency:3/binary, Digits:8/integer, Last_Qty:32/integer>>) ->
	%%	io:format("get_json01~n"),
	rfc4627:encode({obj, [{stock_no,Stock_No},{stock_name,Stock_Name},{itype,IType},
			{mtype,MType},{stock_error_code,Stock_Error_Code},{index_note,Index_Note},
			{ref_price,Ref_Price},{limit_up_price,Limit_Up_Price},{limit_down_price,Limit_Down_Price},
			{decimal_note,Decimal_Note},{promote_note,Promote_Note},{special_note,Special_Note},
			{warrant_type,Warrant_Type},{lot,Lot},{currency,Currency},{digits,Digits},{last_qty,Last_Qty}]}).
		
query_last_qty(Stock_No, Redis1) ->
	{ok, Value} = eredis:q(Redis1, [ "GET", <<<<"twse.fm06.">>/binary,Stock_No/binary>>]),
	case Value of 	
		undefined -> 0;
		_ -> FM06 = binary_to_term(Value),
			FM06#tseprice.tqty
	end.
	
		
query_last_amt(Index_No, Redis1) ->
	{ok, Value} = eredis:q(Redis1, [ "GET", <<<<"twse.fm03.">>/binary,Index_No/binary>>]),
	case Value of 	
		undefined -> 0;
		_ -> FM03 = binary_to_term(Value),
			FM03#indexprice.tamt
	end.	
