

Tempo.bpm = 60;

q.waltz = "recorder.scd".loadRelative[0];
q.waltz.reset;
//Dur and prewait should add up to total duration of file
//where recording starts after prewait
q.waltz.dur = 120;
q.waltz.prewait = 7;
q.waltz.extraBacktrackAt = 4; //extra track on last loop

q.love = "recorder.scd".loadRelative[0];
q.love.song = "love";
q.love.reset;
q.love.dur = 130;
q.love.prewait = 0;
q.love.extraBacktrackAt = false; //extra track on last loop

//q.feel = "recorder.scd".loadRelative[0];


q.score = Routine({

    var cameraChase = {
        fork {
            6.do { |i|
                var id = "domi%".format(i+1).asSymbol;
                q.camera.startCamera(id);
                20.wait;
                q.camera.stopCamera(id);

            }
        }
    };


    loop {

        //0-2
        q.waltz.record; //returns immediately
        120.wait;

        //2-3
        q.ui.log("Setup: 1 minute");
        60.wait;
        { Pulse.ar(329.6 * LFPulse.ar(5).range(2, 3)) * 0.7.dup * Env.linen(0, 0.2, 0, curve:-4).ar(2) }.play(fadeTime:0);

        //3-5
        q.ui.log("Dance: 2 minutes");
        cameraChase.value;
        //TODO: play back mangled version
        120.wait;

        //5-7
        q.ui.log("Nap: 2 minutes");
        fork  {
            q.camera.startVideo;
            120.wait;
            q.camera.stopVideo;
        };
        110.wait;
         //Alarm clock
        { Pulse.ar(329.6 * LFPulse.ar(5).range(1, 2) * [1, XLine.ar(1, 2, 10)]) * 0.3 * Env.linen(0, 10, 10, curve:-4).ar(2) }.play(fadeTime:0);
        10.wait;

        //7-9
        q.ui.log("Song 2: Love. 2 minutes");
        q.love.record;
        120.wait;

        //9-10
        q.ui.log("Setup: 1 minute");
        60.wait;

        fork {
            q.playSound("endfill.wav");
            s.latency.wait;
            { Pulse.ar(SinOsc.ar(LFNoise2.ar(1).range(1, 10)).range(0.99, 1.01) * 329.6  * [1, XLine.ar(1, 0.25, 10)]) * 0.1 * Env.linen(0, 0.1, 10, curve:-4).ar(2) }.play(fadeTime:0);
        };

        //10-12
        q.ui.log("Speech");
        cameraChase.value;
    }


});

