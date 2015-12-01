HPCE 2015 CW6
=============

Issued: 2015/12/01
Due: 2015/12/11 22:00

Note: the coursework is due on Friday 11th, _not_ on
the Monday. This is to avoid exams in that week. This
problem is much more focussed than CW5, so decent results
should be possible in that time frame (the whole point
is to get good performance with low-ish effort).

[The Julia Filter](https://youtu.be/a8TXzXGyZM4)
================================================

The object of this exercise is to make an existing video filter faster.
The filter itself is purely aesthetic, and represents the efforts of
a client to come up with something that is pleasing. They have now
turned it over to you to make it practical.

The filter works with mjpeg streams, which are simply files containing
multiple jpeg images concatenated together. One consequence is that
any jpeg file is a single-frame mjpeg stream.

You can build the filter by running:
    
    make bin/julia_filter

The only dependency it has is libjpeg (both for compiling and running).
In many linuxes, you can do something like:

    sudo apt-get install libjpeg-dev

In cygwin it is available through the standard package manager.

For windows you can download binaries from the libjpeg-turbo
project, see:
- http://www.libjpeg-turbo.org/Documentation/OfficialBinaries
- http://sourceforge.net/projects/libjpeg-turbo/files/1.4.2/

Or you could build it from source on all platforms.

When I compile your code I will ensure that `#include "jpeglib.h"`
and `-ljpeg` will both work using standard include and library
search paths.
    
## Running the filter

The filter can be run in two ways:

### Image transform

The input is a jpeg file and the output is a jpeg file. The
dimensions of the two streams do not need to be the same. For example:

    <media/baloo_640x480.jpg bin/julia_filter --max-frames 1 > tmp/transform.jpg
    
or equivalently:

    bin/julia_filter --max-frames 1 --input-file media/baloo_640x480.jpg --output-file tmp/transform.jpg
    
You should then be able to open the file in any image viewer.

### Image source

In this mode there is no input, and the output is an mjpeg stream.

    bin/julia_filter --no-input --max-frames 1 > tmp/source.jpg

### Video transform / source

Because mjpeg is just a stream of jpegs, you can can work with
videos using exactly the same commands. For example, `media/walking_small.mjpeg`
is a 100 frame video, so we can transform it:

    <media/walking_small.mjpeg bin/julia_filter --max-frames 100 > tmp/video_transfom.mjpeg

or act as a video source:

    bin/julia_filter --no-input --max-frames 100 > tmp/video_source.mjpeg

The mjpeg files will be directly playable in some media players, though
it depends on your system. See the section "Working with Videos".

Objectives
==========

The transform is pretty (or so the client thinks, and the client
is right), but currently too slow. Your goal is to make it faster,
in two ways:

- Latency: reduce the time taken to render a single frame.

- Throughput: increase the throughput over a fixed number of frames.

The metric definitions are:
- n : Number of frames
- t_start : Point at which your executable is launched.
- t_end : Point at which frame n is completely written
  to the output file.
- latency = t_end - t_start (with n=1)
- throughput = n / (t_end-t_start), (for general n)

In cases where an implementation does not complete the requested
frames within a (client-determined) time budget, the achieved
throughput metric will be measured as the number of frames that have
been completely written to the output (n'), and then scaled by
the proportion of frames delivered: throughput = (n' / n) * (n' / (t_end-t_start)).

_Note: All else being equal, reducing latency will also increase
throughput. However, there are also certain things that can also be
done if you know you'll be rendering many frames._

The exact test configurations will be chosen by the client,
but some known limits are:
- There will be tests both with and without input video.
- During throughput tests with an input video, the client will indicate
  their desired target frame-rate. Input images will then be written into
  the file at this rate (i.e. at time 0,0+1/fps,0+2/fps,...). They will also
  attempt to consume images at the same rate (i.e. at time 1/fps,2/fps,3/fps...).
  If either the input or output are not ready, the client will block.
- Video resolutions (input and output) will not exceed 2160p (3840x2160).
- Input video streams will be fixed resolution (as they are jpegs we
  could send down different sized jpegs).
- Fractal exponents (see `--zpow` option) will be small integers (you
  can see why if you look at the output for fractional powers).
- There will always be at least as many input frames as requested
  output frames.
  
The julia filter uses floating-point, so there are issues around
bit-exact reliability. As a consequence, RMSE is used to determine correctness
of output, at a tolerance chosen by the client. This tolerance will
mainly be oriented at good visual fidelity (I'm leaving this intentionally
vague).

Because the client is concerned with pretty-ness, they are also
interested in visual innovations. There is a flag called `--aesthetic`,
which means that the implementation decides how to render or
transform the video (staying within the loose idea of fractal
transforms). If you are inclined to play around you can react
to this flag (but make sure if the flag is not set then it does
the original behaviour).
  
Your target platform is _either_ a g2.2xlarge or a c4.4xlarge instance.
By default it is g2.2xlarge - if you want a c4.4xlarge then create a
file called `c4.4xlarge` in the root of your repository. (I have no
reason to think a c4.4xlarge is better, and would assume it is worse;
I'm just giving flexibility). In either platform the environment will
be a HPCE v3 AMI (which includes libjpeg-dev and ffmpeg, as well as
TBB and OpenCL).

The marks allocation is:

- 10% : Correctness/specification

- 40% : Performance (throughput)

- 20% : Performance (latency)

- 30% : Correctness

- 10% (Bonus) : Best aesthetic mode

Working with videos
===================

Working with video streams is not critical in any
sense, but it's nice to see the fruits of your labour,
particularly when you've got it streaming smoothly
at a high resolution. 

If anyone has any suggestions here, let me know (e.g.
for mac).

There are a number of tools that can be used to generate
and view mjpeg streams. Some known methods for viewing an
mjpeg file include:

- FFMPEG (all platforms) : https://www.ffmpeg.org/

- Mplayer (most platforms) : http://www.mplayerhq.hu/design7/news.html 
  There are many variants available.
  
- Media-player Classic (Windows) : https://mpc-hc.org/

- libav (all platforms) : http://libav.org/
  A fork of ffmpeg for... reasons.
  
Of these, both FFMPEG and libav can also be used to prepare
mjpeg files.

### FMPEG

I tend to use ffmpeg, which provides two key tools:

- `ffmpeg` : Used for converting videos, and can also be used
  to get images from cameras.
  
- `ffplay` : Used to display video/audio.

In the scripts directory are some helper scripts I used
which work with ffmpeg:

- `video_to_mjpeg.sh` : Takes an argument as a file-name, converts it
  to an mjpeg stream, and sends it to stdout.
  
- `mjpeg_to_play.sh` : Takes an mjpeg stream from stdin, and displays it.

- `camera_to_mjpeg.sh` : Reads video from a camera, and sends to to stdout
  as an mjpeg stream (will need adapting for linux, and to specify what your
  camera is called).

Typical usage is then:

Convert video to mjpeg:

    scripts/video_to_mjpeg.sh media/big_buck_bunny_scene_small.mp4 > tmp/video.mjpeg
    
Play mjpeg video:

    <tmp/video.mjpeg scripts/mjpeg_to_play.sh

or:

    cat tmp/video.mjpeg | scripts/mjpeg_to_play.sh
    
Play video directly:

    scripts/video_to_mjpeg.sh media/big_buck_bunny_scene_small.mp4 | scripts/mjpeg_to_play.sh
    
Play video through a filter:

    scripts/video_to_mjpeg.sh media/big_buck_bunny_scene_small.mp4 | bin/julia_filter | scripts/mjpeg_to_play.sh

You may want to play around with `--max-iter`:

    scripts/video_to_mjpeg.sh media/big_buck_bunny_scene_small.mp4 | bin/julia_filter --max-iter 8 | scripts/mjpeg_to_play.sh
    
or reduce the width/height:

    scripts/video_to_mjpeg.sh media/big_buck_bunny_scene_small.mp4 | bin/julia_filter --width 256 --height 256 | scripts/mjpeg_to_play.sh

### Installing FFMPEG

#### Windows

Under both windows (native) and cygwin I use these pre-built
binaries:

    http://ffmpeg.zeranoe.com/builds/
    
I use the latest static builds. Unzip them somewhere, and put
the files in your path (or modify the files in the scripts directory).

#### Debian

I manually add an external repository, then install the package:

- Add the line `deb http://www.deb-multimedia.org jessie main non-free`
    to `/etc/apt/sources.list`
- `sudo apt-get update`
- `sudo apt-get install deb-multimedia-keyring`
- `sudo apt-get install ffmpeg`

#### Ubuntu

Depending on your version, you may just be able to do:

    sudo apt-get install ffmpeg
    
On older versions you might be able to use libav instead,
but I haven't verified it on an ubuntu that doesn't
have ffmpeg yet.
