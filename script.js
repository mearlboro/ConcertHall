var counter = null, audio = null, timestep = 0, timer_on = 0;
var sample_rate = 100.0;

var songs = {
	1 : "Score from Mozart (Let-go)",
	2 : "Score from Mozart (Strict)",
	3 : "Strict Improvisation with Single Lead",
	4 : "Strict Improvisation with Dynamic Switch",
	5 : "Let-go Improvisation with Dynamic Switch",
	6 : "Let-go Improvisation with Single Lead",
	7 : "Score from Haydn (strict)",
	8 : "Score from Haydn (let-go)"
};

window.onload = function(e) {
    var piece = location.pathname.split('/').pop().split('.')[0];
    document.getElementById("current").innerHTML = songs[piece];
};


function play(piece) {
	document.getElementById("current").innerHTML = songs[piece];
	document.getElementById("stop").disabled = false;

    // stop whatever is playing first
    if (audio) {
        stop();
    }

	play_song(piece);
	play_animation(piece);
}
function play_song(piece) {
	audio = new Audio("music/" + piece + ".ogg");
	audio.play();
    console.log('Playing');
}
function play_animation(piece) {
	// clear all movement from audience
	for (var seat in window.data[piece]) {
    	var elem = document.getElementById(seat);
        if (elem) elem.style.setProperty('transform', 'translateX(+0%) translateY(+0%) scale(1)');
	}

    // define and start timer, with ticks in miliseconds
	timer_on = 1;
    timestep = 0;
	counter = setInterval(function () { timer(piece) }, 1000 / sample_rate);
}

function stop() {
	document.getElementById("current").innerHTML = "";
	document.getElementById('timecode').innerHTML = "";
	document.getElementById("stop").disabled = true;

    // audio stop and unload music
	audio.pause();
	audio = null;
    console.log('Stopping');

    // animation reset timer
	clearInterval(counter);
    timestep = 0;
	timer_on = 0;
}

function timer(piece) {
	if (timer_on = 0) return;

	timestep ++;
	document.getElementById('timecode').innerHTML = timestep / sample_rate + ' seconds';

	// all seats have the same number of data points
	var count = window.data[piece]['A06']['count'];

	if (timestep >= count) {
		stop();
		return;
	}

	for (var seat in window.data[piece]) {
		loop(piece, seat);
	}
}

function loop(piece, seat) {

    var subj = document.getElementById(seat);

    if (!subj) return;

    var trans = subj.style.transform;

    var x = update(piece, seat, 0, trans),
        y = update(piece, seat, 1, trans),
        z = update(piece, seat, 2, trans);

    subj.style.setProperty('transform', 'translateX(' + x + 'px) translateY(' + y + 'px) scale(' + z + ')');
}

function update(piece, seat, axis, trans) {
	var d = window.data[piece][seat]['acc'][timestep][axis] - window.data[piece][seat]['median'][axis];

    var scale = 3;
    if (axis == 2) return 1 + d / 10.0 * scale;
    else return d * scale;
}
