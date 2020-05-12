var counter = null;
var timestep = 0;

function play(piece) {
	document.getElementById("playing").innerHTML = "Now playing";
	document.getElementById("current").innerHTML = "Piece " + piece;
	document.getElementById("stop").disabled = false;

	// play song
	play_song(piece);

	// animate the audience
	play_animation(piece);
}

function stop() {
	document.getElementById("playing").innerHTML = "";
	document.getElementById("current").innerHTML = "";
	document.getElementById("stop").disabled = true;

	stop_song();
	stop_animation();
}

function stop_song() {

}

function stop_animation() {
	clearInterval(counter);
}

function play_song() {

}

function play_animation(piece) {
	// clear all colours from audience
	for (var seat in window.data[piece]) {
    	var elem = document.getElementById(seat);
        elem.style.setProperty('background', 'rgb(127, 127, 127)');
	}

    // define and start timer, with 100ms ticks
	timestep = 0;
	counter = setInterval(function () { timer(piece) }, 100);
}

function timer(piece) {
	timestep ++;
	document.getElementById('timecode').innerHTML = timestep / 10.0;

	// all seats have the same number of data points
	var count = window.data[piece]["A06"][count];

	if (timestep >= count) {
		clearInterval(counter);
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
    var red = Math.abs(prev_red + (curr - prev) * 100);
    red = Math.min(red, 255); 
    red = Math.max(0, red);

	//console.log(seat + ":" + curr + ',' + prev_red + ',' + (prev - curr) + ',' + red);
    
    subj.style.setProperty('background', 'rgb(' + Math.round(red) + ', 127, 127)')

}