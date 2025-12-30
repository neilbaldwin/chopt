# CHOPT - Sample Chain Optimiser

### What is CHOPT?

CHOPT is a command-line tool for *optimising* existing sample chains.

### Requirements

#### SoX
CHOPT uses the Sound Exchange (SoX) command-line tool for audio processing so you'll need to install it. There's an excellent little guide to SoX basics here, including how to install it on most platforms: [SoX Installation](https://hyaline.systems/blog/sox-guide/#installing-sox)

#### Command-Line
You'll also need to be familiar with using the command-line (terminal etc.). Nothing too taxing, just comfortable with very basic use.

### Rationale

Many third-party sample chain files are created using evenly spaced sounds. This makes them compatible with samplers that use "equal division" method of *slicing* samples: arguably the fastest and most convenient way to handle sample chains in hardware.

While great for convenience, the downside is that you can find these chains often contain a lot of empty space: the length of every sound in the chain is determined by the length of the longest individual sound within that chain. Consequently the overall size of the chain is also bloated.

If your sampler has the ability to automatically slice a sample by detecting transients or you can manually insert/edit slice points into your samples, you can save a lot of wasted (empty) space in your sample chains by tightly joining the sounds end-to-end.

You could do this manually in a sample editor by selecting and deleting the silence between each sound but it's quite tedious and time consuming if you have a large number of files to process.

This is where CHOPT comes in.  Automatically CHOPT will:

* segment the input file by detecting individual transients
* rebuild the chain adding a definable silence gap between each segment
* optionally normalise each individual segment before rebuilding the chain
* save the optimised chain in a new file (does not change your original file)

#### Installation (assuming you have SoX installed already)

Download the script:
```
curl -LO https://github.com/neilbaldwin/chopt/chopt.sh
```
Make the script executable:
```
chmod +x chopt.sh
```
Move it into your user path:
```
sudo mv chopt.sh /usr/local/bin/
```

#### Usage (Basic)

In your terminal/command prompt, navigate to a folder where you have some sample-chain audio files. Then, to use the default detection and gap parameters (with no normalising):

```
chopt.sh -i <input filename>
```

A new audio file, in the same format as the original, will be output to the same folder as the original but with `"_CHOPT"` appended to the filename.

Using CHOPT with just an input source will use some sensible defaults for the audio processing. However you can specify settings for several parameters which will affect the accuracy and data saving in the output file.
#### Usage (In Depth)

If you want to dig a little deeper, here are the options you can specify when running the script on a file.

**`-m `Minimum Silence**
This specifies the minimum amount of contiguous time, in seconds, that CHOPT (SoX) will use to determine if a sound has decayed to silence. Decreasing this time should lead to tighter cuts but may also lead to false or double-triggering of a slice when processing. Increasing this should ensure no 'false' slice detection but could also cause very short transients to not be detected. Will depend on your source material.

Default value is 0.05 (seconds).

```
chopt.sh -i "BD Chain 01.wav" -m 0.1
```

**`-t `Threshold**
This specifies the amplitude in dB at which CHOPT (SoX) determines that a sound has decayed to silence. Higher values will result in low-level portions of transients being truncated too quickly. Lower values will result in less 'silence' removal from the source material.

Default value is 0.5 (dB).

```
chopt.sh -i "BD Chain 01.wav" -t 0.5
```

**`-g `Gap Length**
This specifies the amount of silence added back into the output file between each slice. Depending on your sampler's ability to detect and process slices you may get away with no gap at all but in my experience with, say, Polyend Tracker, it seems to benefit from having a very small period of silence after each sample to aid with the transient detection.

Default value is 0.5 (seconds).

```
chopt.sh -i "BD Chain 01.wav" -g 1.0
```

**`-n `Normalise (it's the English spelling, get over it)**
Often in a sample chain, especially one that's used, say, a drum loop as the source material, you'll find that once sliced there is a great deal of variance in the amplitude of individual hits. This is natural, of course, and often preferable. However sometimes it's useful to have the individual slices normalised so that they're at 'full volume' when played. CHOPT has you covered here.

You can specify the `-n` option with a dB value (0.0 being the loudest, -6.0 being half as loud and so on) and when the reconstructed chain is outputted, each individual sound will be normalised to the value you specify. This is just peak sample amplitude, nothing fancy.

```
chopt.sh -i "BD Chain 01.wav" -n -3.0
```

### Warranty

Use at your own risk.

My Bash coding skills are *adequate* so even though I have made *some* effort with regard to error trapping and general good practice, it might not be the most robust script in the world.

Also, unless you *really* try, it's almost impossible to ruin your original source files. Having said that it's always prudent to back stuff up and/or make safe copies.
