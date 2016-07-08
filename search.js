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


$.getJSON(source + '/dialogue.json',function(json) {data = json});

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
	var results = 0
	$("#results").empty();
	if (q.length >= min_length) {
		$("#results").append("<p>Results for <b>" + q + "</b></p>");
		$.each(data.episodes, function(i,episode){
		$.each(episode.languages, function(u,language) {
			$.each(language.dialogues, function(o,dialogue) {
			if (regex.test(dialogue.t)) {
				if (unlimited || results < max_results){
					$("#results").append("<div><p><span style=\"font-weight:bold\">" + dialogue.t + "</span> (" + episode.name + ": " + timestamp(dialogue.s) + " - " + timestamp(dialogue.e) + ")" + "</p>" + image_elements(source + '/' + episode.name, language.lang, parseInt(dialogue.s) + 1, parseInt(dialogue.e)) + "</div>");
				} else {
					$("#results").append("<div><p><span style=\"font-weight:bold\">" + dialogue.t + "</span> (" + episode.name + ": " + timestamp(dialogue.s) + " - " + timestamp(dialogue.e) + ")" + "</p></div>");
				}
				results++;
			}
			});
		});
		});
	}
}

function GetURLParameter(sParam)
{
	var sPageURL = window.location.search.substring(1);
	var sURLVariables = sPageURL.split('&');
	for (var i = 0; i < sURLVariables.length; i++) 
	{
		var sParameterName = sURLVariables[i].split('=');
		if (sParameterName[0] == sParam) 
		{
			return sParameterName[1];
		}
	}
}


$("#searchterm").keyup(function(e) {search()});
