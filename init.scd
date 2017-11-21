//Recording script
//2 minutes
//Standalone supercollider

//Waltz
//Cover
(
Quarks.install("ddwPrototype");
Window.closeAll;
NetAddr.broadcastFlag = true;
q !? { q.do(_.free) };
q = ();
q.pis !? { q.pis.do(_.free) };
q.pis = ();
"score.scd".loadRelative;
q.camera = "camera.scd".loadRelative[0];
q.pis.postln;
q.ui = "gui.scd".loadRelative[0].value(q.camera);
q.ui.makeWindow;
q.playSound = { |q, filename, ev|
    var path = "media".resolveRelative +/+ filename;
    ev = ev ?? { () };
    SoundFile(path).cue(ev, true);
};
s.waitForBoot {
    1.wait; //Fix
    s.meter(2, 2);
    s.makeWindow;
}
)

