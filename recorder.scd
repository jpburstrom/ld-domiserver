Proto({

    ~basepath = "recordings".resolveRelative;
    ~backtrackPath = "media".resolveRelative;

    ~out = 0;
    ~bufs = List();
    ~players = List();
    ~latency = s.latency;
    ~extraLatency = 1024/(s.sampleRate ? 48000);

    ~recorder = Recorder(s);
    ~routine = nil;

    ~counter = 0; //internal counter
    ~song = "waltz";
    ~hour = 0;
    ~loop = 0;

    ~hourWrap = 3;
    ~loopWrap = 5;

    ~dur = 3;
    ~prewait = 7;

    ~extraBacktrackAt = false;


    ~recording = false;


    ~freeBuffers = {
        ~bufs.free;
        ~backtrackBuf.free;
    };

    ~loopToPath = { |loop|
        loop = loop ? ~loop;
        ~basepath +/+ "%-%-%.wav".format(~song, ~hour, loop);
    };

    ~sendSynthdefs = {
        SynthDef("pb1", { | out, amp = 1, bufnum, sustain, ar = 0, dr = 0.01 gate = 1 |
            Out.ar(out, Pan2.ar(VDiskIn.ar(1, bufnum, BufRateScale.kr(bufnum)) )
                * Linen.kr(gate, ar, 1, dr, 2)
                * EnvGen.kr(Env.linen(ar, sustain - ar - dr max: 0 ,dr),1, doneAction: 2) * amp)
        }).add;

        SynthDef("pb2", { | out, amp = 1, bufnum, sustain, ar = 0, dr = 0.01 gate = 1 |
            Out.ar(out, VDiskIn.ar(2, bufnum, BufRateScale.kr(bufnum) )
                * Linen.kr(gate, ar, 1, dr, 2)
                * EnvGen.kr(Env.linen(ar, sustain - ar - dr max: 0 ,dr),1, doneAction: 2) * amp)
        }).add;

    };

    ~prep = {
        ~sendSynthdefs.value;
        ~recorder.prepareForRecord(~loopToPath.value, 1);
        ~backtrackBuf = Buffer.cueSoundFile(s, ~backtrackPath +/+ "%.wav".format(~song), 0, 2);
        if (~extraBacktrackAt == ~loop ) {
            ~extraBuf = Buffer.cueSoundFile(s, ~backtrackPath +/+ "%-extra.wav".format(~song), 0, 2);
        };
        ~bufs = ~loop.collect { |i|
            Buffer.cueSoundFile(s, ~loopToPath.(i), 0, 1);
        };
        {s.sync}.try;
    };

    ~playback = {
        forkIfNeeded {
            ~players.add(
                Synth(\pb2, [\bufnum, ~backtrackBuf, \sustain, ~dur + ~prewait]));

            if (~extraBacktrackAt == ~loop ) {
                ~players.add(
                    Synth(\pb2, [\bufnum, ~extraBuf, \sustain, ~dur + ~prewait]));
            };

            (~prewait - ~latency - ~extraLatency).wait;
            s.bind {
                ~bufs.do { |x|
                    ~players.add(Synth(("pb" ++ x.numChannels).asSymbol, [\bufnum, x, \sustain, ~dur]));
                };

            };
        }
    };

    ~increment =  {
        ~counter = ~counter + 1;
        ~prUpdateCounters.value;
    };

    ~prUpdateCounters = {
        ~loop = ~counter % ~loopWrap;
        ~hour = (~counter div: ~loopWrap) % ~hourWrap;
        [~hour, ~loop]
    }    ;

    ~record = {
        q.ui.log("%: Recording hour %, loop %".format(~song, ~hour, ~loop));
        ~recording = true;
        currentEnvironment.changed(\recording);
        ~routine = fork {

            ~prep.value;
            s.sync;

            ~playback.value;

            ~extraLatency.wait;

            s.bind {
                ~recorder.record(bus: s.options.numOutputBusChannels);
            };

            ~dur.wait;

            ~prStop.value;

            ~increment.value;

        }
    };

    ~stop = {
        ~routine.stop;
        ~prStop.value;

    };

    ~prStop = {
        ~recorder.stopRecording;
        ~players.free.clear;
        ~bufs.free.clear;
        ~backtrackBuf.free;
        ~extraBuf.free;
        ~recording = false;
        currentEnvironment.changed(\recording);
    };

    ~reset = { |counter=0|
        ~counter = counter;
        ~prUpdateCounters.value;
    }


});

