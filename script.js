var counter = null, audio = null, timestep = 0, timer_on = 0;

var songs = {
	1 : "Score from Mozart (let-go)",
	2 : "Score from Mozart (strict)",
	3 : "Strict Improvisation with Single Lead",
	4 : "Strict Improvisation with Dynamic Switch",
	5 : "Let-go Improvisation with Dynamic Switch",
	6 : "Let-go Improvisation with Single Lead",
	7 : "Score from Haydn (strict)",
	8 : "Score from Haydn (let-go)"
};

function play(piece) {
	document.getElementById("playing").innerHTML = "Now playing";
	document.getElementById("current").innerHTML = songs[piece];
	document.getElementById("stop").disabled = false;

	// play song
	play_song(piece);

	// animate the audience
	play_animation(piece);
}

function stop() {
	document.getElementById("playing").innerHTML = "";
	document.getElementById("current").innerHTML = "";
	document.getElementById('timecode').innerHTML = "";
	document.getElementById("stop").disabled = true;

	// stop song
	audio.pause();
	audio = null;

	// stop animating
	clearInterval(counter);
	timer_on = 0;
}

function play_song(piece) {
	audio = new Audio("music/" + piece + ".ogg");
	audio.play();
}

function play_animation(piece) {
	// clear all colours from audience
	for (var seat in window.data[piece]) {
    	var elem = document.getElementById(seat);
        elem.style.setProperty('background', 'rgb(127, 127, 127)');
	}

    // define and start timer, with 100ms ticks
	timestep = 0;
	timer_on = 1;
	counter = setInterval(function () { timer(piece) }, 100);
}

function timer(piece) {
	if (timer_on = 0) return;

	timestep ++;
	document.getElementById('timecode').innerHTML = timestep / 10.0 + ' seconds';

	// all seats have the same number of data points
	var count = window.data[piece]["A06"][count];

	if (timestep >= count) {
		stop();
		return;
	}

	for (var seat in window.data[piece]) {
		loop(piece, seat, window.data[piece][seat]["avg"], window.data[piece][seat]["min"], window.data[piece][seat]["max"], timestep);
	}
}

function loop(piece, seat, avg, min, max, time) {
	var curr = window.data[piece][seat]["data"][time],
	    prev = window.data[piece][seat]["data"][time - 1] || min;

    var subj = document.getElementById(seat);
    var prev_color = window.getComputedStyle(subj).getPropertyValue("background-color");
    var prev_red = parseInt(prev_color.split('(')[1].split(',')[0]);
    var red = Math.abs(127 + (curr - prev) * 100);
    red = Math.min(red, 255); 
    red = Math.max(0, red);

	//console.log(seat + ":" + curr + ',' + prev_red + ',' + (prev - curr) + ',' + red);
    
    subj.style.setProperty('background', 'rgb(' + Math.round(red) + ', 127, 127)')

}