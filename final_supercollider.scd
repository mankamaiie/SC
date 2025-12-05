/*

POLY_Synth_Midi
command return everything to start
Play chords with a midi keyboard
Shape the sound using sliders.
SLIDERS:
Filter Cutoff: brightness
Resonance: squelch
Detune: unison width
Volume: overall level
*/


(
s.waitForBoot({

	var w, y, labelHeight=18, sliderHeight=18;
	var cutoffSlider, resSlider, detuneSlider, volSlider;
	var makeLabel;

	~polyParams = (
		cutoff: 1500,
		res: 0.2,
		detune: 0.02,
		amp: 0.3
	);

	~voices = IdentityDictionary.new;


	//POLYPHONIC_SYNTHDEF//


	SynthDef(\polyMoog, {
		|out=0, freq=440, gate=1,
		cutoff=1500, res=0.2, detune=0.02, amp=0.3 |

		var env, osc, filt, rq, sig;

		//ADSR envelope
		env = EnvGen.kr(Env.adsr(0.01, 0.2, 0.7, 0.2), gate, doneAction: 2);

		//two detuned saws
		osc = Saw.ar([
			freq * (1 - detune),
			freq * (1 + detune)
		]).sum * 0.5;

		//map res → rq
		rq = (1 - res).linlin(0, 1, 0.05, 1.0);

		//low-pass filter
		filt = RLPF.ar(
			osc,
			cutoff.clip(100, 12000),
			rq
		);

		//apply envelope & volume, soft clip
		sig = (filt * env * amp).tanh;

		Out.ar(out, sig!2);
	}).add;


	"-> Poly Moog SynthDef added.".postln;


	////////////////////////////////
	// 2. MIDI SETUP (POLYPHONIC)
	////////////////////////////////

	MIDIClient.init;
	MIDIIn.connectAll;

	//NOTE ON = create a new voice
	~noteOn = MIDIdef.noteOn(\polyOn, { |vel, note, chan, src|
		var f = note.midicps;
		var velAmp = vel/127;

		//create a synth for this note
		var synth = Synth(\polyMoog, [
			\freq, f,
			\cutoff, ~polyParams[\cutoff],
			\res, ~polyParams[\res],
			\detune, ~polyParams[\detune],
			\amp, (0.4 * velAmp).clip(0.05, 1)
		]);

		~voices[note] = synth;
	});

	//NOTE OFF = release that voice
	~noteOff = MIDIdef.noteOff(\polyOff, { |vel, note, chan, src|
		var synth = ~voices[note];
		if(synth.notNil) {
			synth.set(\gate, 0);
			~voices.removeAt(note);
		};
	});

	"-> MIDI ready (polyphonic). Play chords!".postln;


	//GUI HERE//

	y = 10;
	w = Window("Class Poly Moog Synth", Rect(100, 100, 330, 230));
	w.alwaysOnTop_(true);
	w.front;

	makeLabel = { |txt|
		StaticText(w, Rect(10, y, 300, labelHeight)).string_(txt);
		y = y + labelHeight + 2;
	};

	makeLabel.("Play MIDI keyboard.");

	//FILTER CUTOFF
	makeLabel.("Filter Cutoff (brightness)");
	cutoffSlider = Slider(w, Rect(10, y, 300, sliderHeight));
	cutoffSlider.action_({ |sl|
		~polyParams[\cutoff] = sl.value.linlin(0,1,200,8000);
		//update all active voices
		~voices.do { |synth| synth.set(\cutoff, ~polyParams[\cutoff]) };
	});
	cutoffSlider.value_(0.3);
	y = y + sliderHeight + 8;

	// RESONANCE
	makeLabel.("Resonance (squelch)");
	resSlider = Slider(w, Rect(10, y, 300, sliderHeight));
	resSlider.action_({ |sl|
		~polyParams[\res] = sl.value;
		~voices.do { |synth| synth.set(\res, ~polyParams[\res]) };
	});
	resSlider.value_(0.2);
	y = y + sliderHeight + 8;

	// DETUNE
	makeLabel.("Detune amount");
	detuneSlider = Slider(w, Rect(10, y, 300, sliderHeight));
	detuneSlider.action_({ |sl|
		~polyParams[\detune] = sl.value.linlin(0,1,0.0,0.08);
		~voices.do { |synth| synth.set(\detune, ~polyParams[\detune]) };
	});
	detuneSlider.value_(0.3);
	y = y + sliderHeight + 8;

	// VOLUME
	makeLabel.("Volume");
	volSlider = Slider(w, Rect(10, y, 300, sliderHeight));
	volSlider.action_({ |sl|
		~polyParams[\amp] = sl.value.linlin(0,1,0.05,0.8);
		~voices.do { |synth| synth.set(\amp, ~polyParams[\amp]) };
	});
	volSlider.value_(0.5);
	y = y + sliderHeight + 8;


	//CLOSE//

	w.onClose_({
		//free all voices
		~voices.do { |synth| synth.free };
		~voices.clear;

		//free MIDI defs
		~noteOn.free;
		~noteOff.free;

		"Poly Moog Synth stopped.".postln;
	});

});
)
