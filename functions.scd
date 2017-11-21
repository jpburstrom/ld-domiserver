var path = "recordings".resolveRelative;
var backtrackPath = "media".resolveRelative;


var loopToPath = { |song, hour, loop|
    path +/+ "%-%-%.wav".format(song, hour, loop);
};

NetAddr.broadcastFlag = true;

q.r = Recorder(s);

Fdef(\recordSong, { |song, hour, loop, dur, precount=0|
    var backtrackBuf;
    var out = 0; //XXX
    var bufs = List();
    var players = List();
    var latency = 1024/48000;
    var freeBuffers = {bufs.free; backtrackBuf.free; };

    q.r.prepareForRecord(loopToPath.(song, hour, loop), 1);
    //Prep
    backtrackBuf = Buffer.cueSoundFile(s, backtrackPath +/+ "%.wav".format(song), 0, 2);
    s.sync;
    bufs = loop.collect { |i|
        Buffer.cueSoundFile(s, loopToPath.(song, hour, i), 0, 1);
    };

    q.bufs = bufs;
    q.backtrackBuf = backtrackBuf;


    //Record to first sound in
    //TODO: Playback count
    players.add(Synth(\diskIn2, [\bufnum, backtrackBuf, \sustain, dur + precount]));

    (precount - s.latency - latency).wait;
    //players.do { |x| x.play };
    s.bind {
        bufs.do { |x|
            players.add(Synth(("diskIn" ++ x.numChannels).asSymbol, [\bufnum, x, \sustain, dur]));
        };

    };
    latency.wait;
    s.bind {
        q.r.record(bus: s.options.numOutputBusChannels);
    };
    dur.wait;
    q.r.stopRecording;
    players.do {|x| x.free };
    freeBuffers.value;



});

Fdef(\sendSynthdefs, {
    2.do { |i|
        i = i + 1;
        SynthDef("diskIn" ++ i, { | out, amp = 1, bufnum, sustain, ar = 0, dr = 0.01 gate = 1 |
            Out.ar(out, VDiskIn.ar(i, bufnum, BufRateScale.kr(bufnum) )
                * Linen.kr(gate, ar, 1, dr, 2)
                * EnvGen.kr(Env.linen(ar, sustain - ar - dr max: 0 ,dr),1, doneAction: 2) * amp)
        }).add;
};
});
