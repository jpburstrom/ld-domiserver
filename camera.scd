Proto({

    ~startCamera = { |id|
        q.pis[id] !? (_.sendMsg("/camera/start"));
    };

    ~stopCamera = { |id|
        q.pis[id] !? (_.sendMsg("/camera/stop"));
    };

    ~startVideo = { |file|
        "TODO: start video".postln;
    };

    ~stopVideo = { |file|
        "TODO: stop video".postln;
    };


});