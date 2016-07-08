var max_results = 300
var min_length = 3
var source = GetURLParameter('source');
var clean = GetURLParameter('clean') == '1';
var unlimited = GetURLParameter('unlimited') == '1';
var compact = GetURLParameter('compact') != '0';
var data;
var xmlDoc;
var xml_data;
var added_images = [];
var dropdown_default = 'all';


$.getJSON(source + '/dialogue.json',function(json) {data = json; init_drop_down(data);});

function init_drop_down(data) {
	$("#episode_menu").append('<option>' + dropdown_default + '</option>');
	$.each(data.episodes, function(x, episode) {
			$("#episode_menu").append('<option>' + episode.name +'</option>');
	});
	var max_results_array = [50, 100, 250, 500, 999999]
	for (i = 0; i < max_results_array.length; i++) {
		$("#results_menu").append('<option>' + max_results_array[i] + '</option>');
	}
	document.getElementById("results_menu").selectedIndex = 3;
}

function image_elements(url, lang, start, end) {
	string = ""
	if (compact) {
		start = Math.floor((start + end) / 2.0)
		end = start
	}
	for (i = start; i <= end; i++) {
		string += "<span onclick=\"toggle_image(this, '" + url + "/" + lang + "/" + i + ".jpg" + "');\">" + timestamp(i) + "</span>";
		if (clean) {
			string += " <span onclick=\"toggle_image(this, '" + url + "/none/" + i + ".jpg" + "');\">(clean)</span>";
		}
		string += "<br/>";
	}
	return string;
}


function timestamp(secs) {
	var t = new Date(1970,0,1);
	t.setSeconds(secs);
	return t.toTimeString().substr(0,8);
}


function toggle_image(el, url) {
	var i = $.inArray(url, added_images);
	if(i >= 0) {
		added_images.splice(i, 1);
		while(el.lastChild && el.lastChild != el.firstChild) {
			el.removeChild(el.lastChild);
		}
	} else {
		$(el).append("<br/><image src=\"" + url + "\"/>");
		added_images.push(url);
	}
}


function search() {
	var q = $("#searchterm").val();
	var regex = new RegExp(q,"gi");
	var max_results = parseInt($('#results_menu').find(":selected").text());
	var results = 0
	var scope = $('#episode_menu').find(":selected").text();
	$("#results").empty();
	if (q.length >= min_length || scope != dropdown_default) {
		$.each(data.episodes, function(i, episode){
			$.each(episode.languages, function(u, language) {
				$.each(language.dialogues, function(o, dialogue) {
				if ((scope == dropdown_default || scope == episode.name) && regex.test(dialogue.t)) {
					if (unlimited || results < max_results){
						$("#results").append("<div><p><span style=\"font-weight:bold\">" + dialogue.t + "</span> (" + episode.name + ": " + timestamp(dialogue.s) + " - " + timestamp(dialogue.e) + ")" + "</p>" + image_elements(source + '/' + episode.name, language.lang, parseInt(dialogue.s) + 1, parseInt(dialogue.e)) + "</div>");
					}
					results++;
				}
				});
			});
		});
		if(results > max_results) {
			$("#results").append("<div><p style=\"font-weight:bold\">+" + (results - max_results)  + " results</p></div>");
		}
	}
}


function GetURLParameter(sParam) {
	var sPageURL = window.location.search.substring(1);
	var sURLVariables = sPageURL.split('&');
	for (var i = 0; i < sURLVariables.length; i++) {
		var sParameterName = sURLVariables[i].split('=');
		if (sParameterName[0] == sParam) {
			return sParameterName[1];
		}
	}
}


$("#searchterm").keyup(function(e) {search()});
$("#episode_menu").change(function(e) {search()});
$("#results_menu").change(function(e) {search()});
