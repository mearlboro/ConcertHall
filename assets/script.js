---
layout: blank
---

var counter = null, video = null, timestep = 0, timer_on = 0;
var sample_rate = 25.0;
var piece = location.pathname.split('/').pop().split('.')[0];

var signal = {{ site.data | jsonify }};
signal = signal[piece]
var count = signal['A06']['acc'].length;

function play() {
	document.getElementById("stop").disabled = false;

    video = document.getElementsByTagName('video')[0];

    // only play everything if the video is ready
    if (video.readyState == 4) {
        console.log('Playing video');
        video.play();

        // clear all movement from audience
        if (timestep == 0) {
            for (var seat in signal) {
                var elem = document.getElementById(seat);
                if (elem) elem.style.setProperty('transform', 'translateX(+0%) translateY(+0%) scale(1)');
            }
        }

        // define and start timer, with ticks in miliseconds
        timer_on = 1;
        counter = setInterval(timer, 1000 / sample_rate);
    }
}

function pause() {
    // video
	video.pause();
    console.log('Pausing video');

    // only pause the timer to pause animation
	timer_on = 0;
}

function stop() {
	document.getElementById('timecode').innerHTML = "";
	document.getElementById("stop").disabled = true;

    // video stop and seek to start
	video.pause();
    video.currentTime = 0;
    console.log('Stopping video');

    // animation reset timer
	clearInterval(counter);
    timestep = 0;
	timer_on = 0;
}

function timer() {
	if (timer_on == 0) return;

	if (timestep >= count) {
		stop();
		return;
	}

    // to avoid timer delays, sync the timer counter with the video seek time
    timestep = Math.floor(video.currentTime * sample_rate)

	document.getElementById('timecode').innerHTML = timestep / sample_rate + ' seconds';

	for (var seat in signal) {
		loop(seat);
	}
}

function loop(seat) {
    var subj = document.getElementById(seat);
    if (!subj) return;

    var trans = subj.style.transform;
    var x = update(seat, 0, trans),
        y = update(seat, 1, trans),
        z = update(seat, 2, trans);

    subj.style.setProperty('transform', 'translateX(' + x + 'px) translateY(' + y + 'px) scale(' + z + ')');
}

function update(seat, axis, trans) {
	var d = signal[seat]['acc'][timestep][axis]
          - signal[seat]['median'][axis];

    var scale = 10;
    // show z-axis as zoom
    if (axis == 2) return 1 + d / 20.0 * scale;
    else return d * scale;
}
