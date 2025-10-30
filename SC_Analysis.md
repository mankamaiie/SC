# Analysis of "Far Enough" SuperCollider Code by Iakamuri

https://youtu.be/5c1SPnJc4JU?si=kfzIqIgiEJ-q9d_G

## Overview

The code defines and plays four SynthDefs:
- `farEnough`
- `impul`
- `f`
- `bur`

It uses loops, routines, and patterns to play these sounds at different times.  
The result is a long sequence where different sound layers appear, overlap, and fade.

The code also starts recording the output from the SuperCollider server.



## Main SuperCollider Concepts Used

- **Tone Generators:** [`SinOsc`](https://doc.sccode.org/Classes/SinOsc.html), [`LFSaw`](https://doc.sccode.org/Classes/LFSaw.html)
- **Noise / Random Values:** [`LFNoise1`](https://doc.sccode.org/Classes/LFNoise1.html), [`Dust2`](https://doc.sccode.org/Classes/Dust2.html)
- **Timing:** [`Routine`](https://doc.sccode.org/Classes/Routine.html), `fork`, `wait`
- **Envelopes:** [`Env`](https://doc.sccode.org/Classes/Env.html), [`EnvGen`](https://doc.sccode.org/Classes/EnvGen.html)
- **Echo / Delay:** [`DelayN`](https://doc.sccode.org/Classes/DelayN.html), [`AllpassN`](https://doc.sccode.org/Classes/AllpassN.html)
- **Pitch and Dynamics:** [`PitchShift`](https://doc.sccode.org/Classes/PitchShift.html), [`Compander`](https://doc.sccode.org/Classes/Compander.html), [`HPF`](https://doc.sccode.org/Classes/HPF.html)
- **Stereo Output:** [`Pan2`](https://doc.sccode.org/Classes/Pan2.html), [`Out`](https://doc.sccode.org/Classes/Out.html)
- **Pattern Playback:** [`Pbind`](https://doc.sccode.org/Classes/Pbind.html)
- **Recording:** [`Recorder`](https://doc.sccode.org/Classes/Recorder.html)



## SynthDefs Explained

### 1. `farEnough`

```
(

s.waitForBoot({

	SynthDef(\farEnough, {
		arg pitch, freq=70, addFreq=17, attack=1, release = 12;
		var sig, sig1, saws, env, shapeEnv, local, local2;
		sig =
		Mix.new(
			Array.fill(8,
				{SinOsc.ar(freq + addFreq.rand, 0.95.rand, 0.03)}));

		env = EnvGen.kr(
			Env.perc(attack, release ),
			doneAction:2);
		sig1 = sig + (sig *
			Mix.new(
				Array.fill(8,
					{SinOsc.ar(0.02, 0.7.rand, LFNoise1.kr(0.02, 0.08))})));

		sig = sig * env;
		sig1 = sig1 * env;

		sig = PitchShift.ar(sig, 0.1, SinOsc.kr(pitch.rrand(0.1, 0.2), 3.2.rand, 0.9, 3));
		sig1 = PitchShift.ar(sig1, 0.1, SinOsc.kr(pitch.rrand(0.1, 9.2), 0, 0.9, 3));

		saws = Mix.new(
			Array.fill(8,
				{LFSaw.ar(\sawFreq.ir(4000) + addFreq.rand, 0.9.rand, 0.02)}));
		shapeEnv = EnvGen.kr(Env([0.1, 0.02, 0.8, 0.0], [1, 5, 3 , 2]));

		saws = saws * shapeEnv;
		saws = saws * env;

		local = LocalIn.ar(2) + [sig+sig1, sig1+sig];
		local = DelayN.ar(local, 0.8, [0.3, 0.33.rand]);
		local2 = LocalIn.ar(2) + [saws, saws];
		local2 = DelayN.ar(local2, 0.8, [0.02, 0.02.rand]);
		local = local + local2;

		local = Compander.ar(
			local, local,
			0.2, slopeBelow: 1.3,
			slopeAbove: 0.1,
			clampTime:0.1,
			relaxTime:0.01);
		local = local.tanh;
		local = HPF.ar(local, 70);
		//local = BRF.ar(local, 260);
		LocalOut.ar(local * 0.8);
		Out.ar(0, local);

	}).add;

```
**Purpose:** Creates a layered, slowly changing tone with feedback

**Steps:**
1. Mixes 8 sine waves with small random pitch and phase changes.  
2. applies an envelope (`Env.perc`) to control fade-in and fade-out.  
3. Multiplies the mixed tone by another slow, wobbly signal to create variation.  
4. Applies `PitchShift` to slightly change pitch over time.  
5. Adds 8 sawtooth waves (`LFSaw`) with their own envelope for brightness.  
6. Uses feedback (`LocalIn` and `LocalOut`) and short delays (`DelayN`) for depth.  
7. Compresses and filters the sound with `Compander` and `HPF`.  
8. Sends the output to the main speakers (`Out.ar(0, ...)`).

**Result:** A complex tone with slow movement and mild echo.



### 2. `impul`

```
SynthDef(\impul, {
		arg freq = 1000;
		var sig, sig1, env;
		sig = Pan2.ar(
			Mix.ar(
				Array.fill(8,
					{Impulse.ar(freq + 130.rand, 0.7.rand,
						LFNoise1.kr(20, 0.2.rand))})), 0);
		4.do({ sig = AllpassN.ar(sig, 0.050, [0.050.rand, 0.050.rand], 1) });
		sig1 = sig * LFNoise1.ar(23, Dust2.kr(20));
		4.do({ sig1 = AllpassN.ar(sig, 0.050, [0.050.rand, 0.050.rand], 1) });
		env = EnvGen.kr(Env.perc(5, 20), doneAction:2);
		sig = (sig  + sig1)*env;


		Out.ar(0, sig);
	}).add;

```
**Purpose:** Generates short, sharp impulses with reverb diffusion.

**Steps:**
1. Creates 8 impulse signals at random frequencies using [`Impulse.ar`](https://doc.sccode.org/Classes/Impulse.html).  
2. Mixes them and places them in stereo with `Pan2`.  
3. Passes the mix through several `AllpassN` filters to blur and spread the sound.  
4. Adds a noisy version of the same signal that changes in volume randomly (`LFNoise1` and `Dust2`).  
5. Uses an envelope (`Env.perc`) to fade out.  
6. Sends the result to the speakers.

**Result:** Short percussive clicks that echo and spread out.



### 3. `f`

```
SynthDef(\f, {
		arg pitch, addFreq=200;
		var sig, sig1, env, local;
		sig =
		Mix.new(Array.fill(8,
			{SinOsc.ar(\freq.ir(300) + addFreq.rand, 0.45.rand, 0.02)}));

		env = EnvGen.kr(
			Env.perc(
				\attack.ir(0.1),
				\release.ir(10)),
			doneAction:2);

		sig1 = sig + (sig * SinOsc.ar(30, 0.7.rand));

		sig1 = sig1 * env;
		sig = sig * env;
		sig = PitchShift.ar(sig, 0.1, SinOsc.kr(pitch.rrand(0.1, 3.2), 0, 0.9, 3));

		local = LocalIn.ar(2) + [sig+sig1, sig1+sig];
		local = DelayN.ar(local, 0.8, [0.3, 0.33.rand]);
		LocalOut.ar(local * 0.8);
		Out.ar(0, local);
	}).add;
```

**Purpose:** Produces a softer tone layer with subtle pitch changes and feedback.

**Steps:**
1. Mixes 8 sine waves at slightly different frequencies.  
2. Applies an envelope (`Env.perc`).  
3. Modulates one copy of the signal with a slow sine wave for motion.  
4. Adds small pitch shifts (`PitchShift`).  
5. Sends the sound through short feedback delays (`LocalIn`, `DelayN`, `LocalOut`).  
6. Outputs the result to both channels.

**Result:** A smooth sound that slowly moves in pitch and has a short echo.



### 4. `bur`

```
SynthDef(\bur, {
		arg freq=232, gate=10, dauer = 20, amp=1;
		var sig, env, lastEnv;

		sig = SinOsc.ar(freq);
		env = EnvGen.kr(Env.perc, Impulse.kr(gate), doneAction:2);

		sig = sig * env;
		sig = Compander.ar(sig, sig, 0.2, 4.3, clampTime:0.1, relaxTime:0.001);
		lastEnv = EnvGen.kr(Env([0, 1, 1, 0], [0.01, dauer, 3, 0.02]), doneAction:2);
		sig = sig * lastEnv;
		sig = sig * amp;
		Out.ar(0, sig!2);
	}).add;


	s.sync;
```

**Purpose:** Produces repeating sine wave pulses (bursts).

**Steps:**
1. Generates a sine wave with [`SinOsc`](https://doc.sccode.org/Classes/SinOsc.html).  
2. Triggers short envelope shapes using [`EnvGen`](https://doc.sccode.org/Classes/EnvGen.html) with `Impulse.kr`.  
3. Uses another long envelope to shape the full duration of the sound.  
4. Applies `Compander` to keep the volume steady.  
5. Multiplies by amplitude and sends to both speakers.

**Result:** Short, rhythmic sine wave bursts.



## Program Flow

```
s.record("home", 0, 2); //RECORD

	fork{
		for(1, 100000){arg i;
			0.01.wait;
			i = i/100;

			i.postln;

			if(i ==1){Synth(\farEnough, [\addFreq, 4,\attack, 4, \release, 10])};
			if(i ==7){
				Synth(\farEnough, [\addFreq, 21, \release, 13]);
				Synth(\farEnough, [\addFreq, 20,\release, 10]);
			};

			if(i == 11){Synth(\farEnough, [\addFreq, 38,\release, 10])};
			if(i == 17.77){Synth(\farEnough, [\addFreq, 43,\release, 16])};
			if(i == 24){Synth(\farEnough, [\addFreq, 403,\attack, 6, \release, 16])};
			if(i == 26.2){Synth(\farEnough, [\addFreq, 803,\release, 9])};
			if(i == 29.6){Synth(\farEnough, [\addFreq, 2803,\release, 15])};

			if(i == 29.9){Synth(\impul)};
			if(i == 36.9){
				Synth(\impul, [\freq, 700]);
				Synth(\farEnough, [\addFreq, 12,\release, 12]);
				Synth(\farEnough, [\addFreq, 17,\release, 14]);
			};

			if(i == 44.3){Synth(\impul, [\freq, 964])};

			if(i == 47.2){Synth(\f)};
			if(i == 52){Synth(\farEnough, [\addFreq, 2400,\release, 20])};
			if(i == 61.3){
				Synth(\impul, [\freq, 2904]);
				Synth(\farEnough, [\addFreq, 240,\release, 20]);

			};

			if(i == 102.3){Synth(\f,
				[\freq, 400 + 500.rand,
					\attack, 6,
					\release, 20
			]);
			};

			if(i ==143){Synth(\farEnough, [
				\addFreq, 2.1,
				\attack, 14,
				\release, 30]
			)};



		};


	};

	//another routine

	fork{
		"hello".postln;
		62.wait;         ///////////after 62 SECs
		2.do({
			Synth(\f, [
				\freq, 30 + 5.rand,
				\addFreq, 3000.rand,
				\attack, 14,
				\release, 30
			]);
			10.wait;
		});
		10.wait;
		"click".postc();


		4.do({Synth(\bur, [
			\freq, 230 + 30.rand,
			\gate, [11, 2, 5, 9].choose,
		]);
		});
		11.wait;

		Synth(\f);
		4.wait;

		Synth(\f,
			[\freq, 400 + 50.rand,
				\attack, 6,
				\release, 20
			]
		);

		0.3.wait;



		3.do({Synth(\bur, [
			\freq, 230 + 30.rand,
			\gate, [11, 2, 9].choose,
			\dauer, 33,
			\amp, [0.1, 0.8, 0.03].choose,
		]);
		});

		14.wait;

		2.do({Synth(\bur, [
			\freq, 230 + 300.rand,
			\gate, [3, 5].choose,
			\dauer, 13,
			\amp, [0.1, 0.8, 0.03].choose,
		]);
		});



	};


	113.wait; //113 seconds later

	Synth(\f,
			[\freq, 400 + 50.rand,
				\attack, 16,
				\release, 23
			]
		);

	fork{
		p=[
			Pbind(\instrument, \bur,
				\freq, 200 + 30.rand,
				\dur, 0.09.rand,
				\amp, Pfunc({[0.04, 0.6].choose}),
				\dauer, 12
			).play,

			5.3.wait;

			Pbind(\instrument, \bur,
				\dur, 0.09,
				\amp, Pfunc({[0.1, 0.6].choose}),
				\dauer, 16
			).play,

			Pbind(\instrument, \bur,
				\dur, 0.1,
				\amp, Pfunc({[0.04, 0.6].choose}),
				\dauer, 16
			).play,

		];

		19.wait;
		p[0].stop;
		0.2.wait;
		p[1].stop;
		p[2].stop;



	};


	s.sync;
});
)
```
### Setup

1. Waits for the server to start: `s.waitForBoot`.  
2. Loads SynthDefs (`.add`) and syncs (`s.sync`).  
3. Starts recording: `s.record("home", 0, 2)`.


### Main Routine

A long loop runs, increasing  `i` and triggering different sounds at certain values.

Examples:
- `i == 1`: plays `farEnough`
- `i == 29.9`: plays `impul`
- `i == 36.9`: plays `impul` and two `farEnough`
- `i == 47.2, 52, 61.3, 102.3, 143`: plays `f` and more `farEnough`

The loop continues for a long time, slowly adding and changing sounds.



### Second Routine

After 62 seconds:
2. Plays several `f` and `bur` Synths at random settings.  
3. Waits between them to create space 
4. Continues adding `bur` bursts and fades.



### Pattern 

After 113 seconds:
1. Starts another `f` sound.  
2. Launches three [`Pbind`](https://doc.sccode.org/Classes/Pbind.html) patterns that repeatedly play the `bur` Synth with random volume and duration.  
3. After about 20 seconds, the patterns stop one by one.



## Recording

- The code records the final stereo mix using [`Recorder`](https://doc.sccode.org/Classes/Recorder.html).  
- Recording command: `s.record("home", 0, 2)`  
- Audio is taken from output bus 0 (the main output).
