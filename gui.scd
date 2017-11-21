{ |controller|
    Proto({

        ~pis = q.pis;

        ~win = nil;
        //The first unix cmd is mac only, otherwise use hardcoded ip
        //FIXME
        ~broadcastAddr = try {
            NetAddr(unixCmdGetStdOut("ifconfig | grep broadcast | awk '{print $NF}'").split(Char.nl)[0], 1234);
            } ?? { NetAddr("192.168.1.255", 1234) };

        ~rowCounter = 0;

        ~makeOscFunc = {
            currentEnvironment.debug("env");
            ~oscfunc = OSCFunc({ |args, t, addr|
                var id = args[1].asSymbol;
                currentEnvironment.debug("env");
                if (~pis[id].isNil) {
                    ~pis[id] = addr;
                    id.debug("Adding");
                    ~makePiTest.(id, ~rowCounter);
                    ~rowCounter = ~rowCounter + 1;

                };


            }.inEnvir, "/pong");
        };

        ~makeOscFunc.value;


        ~makePiTest = { |id, counter|
            {
                var addr = ~pis[id];
                var cameraBut = Button()
                .states_([["Test Camera"], ["Stop camera test"]])
                .action_(inEnvir{ |but|
                    if (but.value == 1) {
                        controller.startCamera(id)
                    } {
                        controller.stopCamera(id)
                    }
                });
                var videoBut = Button()
                .states_([["Test Video"], ["Stop video test"]])
                .action_(inEnvir{ |but|
                    if (but.value == 1) {
                        controller.startVideo(id)
                    } {
                        controller.stopVideo(id)
                    }
                });
                ~win.layout.add(StaticText().string_(id), counter, 0);
                ~win.layout.add(cameraBut, counter, 1);
                ~win.layout.add(videoBut, counter, 2);
            }.inEnvir.defer

        };

        ~makeWindow = {

            var pingButton = Button()
            .states_([["Search Pis"]])
            .action_(inEnvir{
                ~broadcastAddr.sendMsg("/ping");
            });
            var resetButton = Button()
            .states_([["Reset"]])
            .action_({
                q.waltz.reset;
                q.love.reset;
            });
            var startButton = Button()
            .states_([["Play"], ["Stop"]])
            .action_(inEnvir { |but|
                if (but.value == 1) {
                    q.score.reset;
                    q.score.play;
                } {
                    var t = TempoClock.tempo;
                    q.score.stop;
                    TempoClock.tempo = 1e+06;
                    s.freeAllBuffers;
                    //s.freeAll;
                    { TempoClock.tempo = t }.defer(0.1)
                };

            });

            var waltzButton = Button()
            .states_([["Waltz"], ["Stop recording"]])
            .action_(inEnvir { |but|
                if (but.value == 1) {
                    q.waltz.record;
                } {
                    q.waltz.stop;
                };
            });


            var loveButton = Button()
            .states_([["Love"], ["Stop recording"]])
            .action_(inEnvir { |but|
                if (but.value == 1) {
                    q.love.record;
                } {
                    q.love.stop;
                };
            });

            Updater(q.waltz, { |b, changed|
                if (changed == \recording) {
                    defer {
                        if (b.recording) {
                            waltzButton.value = 1;
                        } {
                            waltzButton.value = 0;
                        }
                    }
                }
            });

            q.waltz.addDependant(waltzButton);


            Updater(q.love, { |b, changed|
                if (changed == \recording) {
                    defer {
                        if (b.recording) {
                            loveButton.value = 1;
                        } {
                            loveButton.value = 0;
                        }
                    }
                }
            });

            q.love.addDependant(loveButton);

            ~logField = TextField().enabled = false;

            ~win = Window.new("Dominik");
            ~win.layout_(GridLayout.rows(
                [startButton, resetButton, pingButton],
                [StaticText().string_("Manual recording:"), waltzButton, loveButton],
                [[~logField, columns:3]],
                [[nil, columns:3]]
            ));

            ~rowCounter = 4;
            3.do { |x|
                2.do { |y|
                    ~win.layout.setAlignment(x@y, \topLeft);
                }
            };

            ~updater = SkipJack({
                startButton.value = q.score.isPlaying.asInt;

            });

            ~win.onClose = {
                "Freeing stuff".debug;
                ~cleanup.value;
                \Document.asClass ?? {
                    0.exit;
                };
                ~win
            }.inEnvir;

            ~broadcastAddr.sendMsg("/ping");


            ~win.front

        };

        ~log = { |s|
            { ~logField.string = s.asString}.inEnvir.defer;
        };

        ~cleanup = {
            ~updater.stop;
            ~oscfunc.free
        };

        ~free = {
            ~win !? { ~win.close };
            ~win ?? ~cleanup;
        }
    });

}


