import hexpect.HExpect;
import neko.Lib;

class Test 
{

	static function main() 
	{
		trace("Test for HExpect");

		//var inFile = "/home/jason/workspace/Vose-Video-GUI/assets/sampledata/originals/file.MTS";
		//var outFile = "/home/jason/workspace/Vose-Video-GUI/assets/sampledata/transcodes/file.MTS.MP4";
		
		testLs("/home/jason/");
		testCat();
		testFFMpegInfo("/home/jason/workspace/Vose-Video-GUI/assets/sampledata/originals/file.MTS");

		trace("Test Completed.  Thank you!");
	}

	static function testLs(folder:String)
	{
		var process = new HExpect("ls", ["-la",folder]);
		process.expect("Hidden", ~/\d\d:\d\d (\.[\w\s]*\w)\s*$/);

		var hiddenFiles = new List<String>();

		for (match in process)
		{
			switch (match.name)
			{
				case "Hidden":
					hiddenFiles.add(match.regex.matched(1));
			}
		}

		trace ("\n\nHidden Files: ");
		trace (hiddenFiles);
		trace ("Done.\n");
	}

	static function testCat()
	{
		var process = new HExpect("cat /etc/lsb-release");
		process.expect("OS", ~/DISTRIB_DESCRIPTION="([^"]+)"*$/);

		var match = process.getNextMatch();
		trace ("Your linux version is: " + match.regex.matched(1) + "\n");
	}

	static function testFFMpegInfo(infile:String)
	{
		var hours = 0;
		var mins = 0;
		var secs = 0;
		var frames = 0;
		var fps = 0;
		var total = 0;

		var process = new HExpect("ffmpeg", ["-i",infile]);

		process.captureOutput = true;
		process.outputStream = STREAM.stderr;

		process.expect("Duration", ~/Duration.+(\d+):(\d\d):(\d\d).(\d\d)/);
		process.expect("FPS", ~/ (\d+) fps.+\d+ tbr/);

		for (match in process)
		{
			switch (match.name)
			{
				case "Duration":
					hours = Std.parseInt(match.regex.matched(1));
					mins = Std.parseInt(match.regex.matched(2));
					secs = Std.parseInt(match.regex.matched(3));
					frames = Std.parseInt(match.regex.matched(4));
				case "FPS":
					fps = Std.parseInt(match.regex.matched(1));
			}
		}

		total = hours;
        total = total * 60 + mins;
        total = total * 60 + secs;
        total = total * fps + frames;

		trace ("\n\n");
		trace ("FFMPEG OUTPUT: ");
		trace (" \n" + process.output);
		trace ("Video Info: ");
		trace (" Hours: " + hours);
		trace (" Mins: " + mins);
		trace (" Sec: " + secs);
		trace (" Frames: " + frames);
		trace (" FPS: " + fps);
		trace (" Total: " + total);
		trace ("Done.\n");
		
	}
}