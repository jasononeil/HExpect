/*
 * Copyright (c) 2011, Jason O'Neil
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *   - Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   - Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE HAXE PROJECT CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE HAXE PROJECT CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */
package hexpect;
import neko.io.Process;
import neko.Lib;

/** 
*  HExpect is a very simple class to check the output of a process line by line for certain expectations.
*  HExpect is synchronous - it will hold up your code until the process has finished executing.
*/
class HExpect
{
	public var cmd(default,null):String;
	public var args(default,null):Array<String>;
	public var proc:Process;
	public var processingStatus(default,null):PROCESSING_STATUS;
	public var outputStream(default,default):STREAM;
	public var captureOutput(default,setCaptureOutput):Bool;
	public var output(default,null):String;

	var eregExpectations:List<EregExpectation>;
	var exactExpectations:List<ExactExpectation>;
	
	var currentResult:Result;

	
	/** Create a new HExpect object.  Pass the command that will be used to execute.*/
	public function new( cmd:String, ?args:Array<String>) 
	{
		// pass on our original parameters (and if "cmd" contains spaces, move those to arguments)
		
		// get an array of the command and all arguments in "cmd"
		var commandArgs = cmd.split(" ");
		// pull out the command from the start of the array, set it for this object
		var procCommand = commandArgs.shift();
		this.cmd = procCommand;
		// set the args from "cmd"
		this.args = commandArgs;
		// add the args from "args" to the end of the array
		if (args != null)
		{
			for (arg in args)
			{
				this.args.push(arg);
			}
		}
		

		// initialise some other stuff
		this.processingStatus = PROCESSING_STATUS.not_processing;
		this.currentResult = null;
		this.eregExpectations = new List();
		this.exactExpectations = new List();
		this.captureOutput = false;
		this.outputStream = STREAM.stdout;
	}

	/** */
	public function expect( name:String , expression:EReg )
	{
		var e:EregExpectation = { name : name, expression : expression };
		eregExpectations.add(e);
	}

	public function expectExact( name:String , string:String )
	{
		var e:ExactExpectation = { name : name, string : string };
		exactExpectations.add(e);
	}

	public function getNextMatch():Result
	{
		return (hasNext()) ? next() : null;
	}

	public function iterator()
	{
		return this;
	}

	public function hasNext():Bool
	{
		// if processing hasn't begun, begin it now
		if (this.processingStatus != PROCESSING_STATUS.started) beginProcessing();
		
		currentResult = null;
		var hasNext:Bool = true;
		var stdoutLine:String;
		var stderrLine:String;

		// Loop through until we get a match
		try
		{
			while (currentResult == null)
			{
				// Get the current line, from whichever stream is currently selected in outputStream
				var line = (this.outputStream == STREAM.stdout) ? proc.stdout.readLine() : proc.stderr.readLine();
				currentResult = searchForMatch(line);

				trace (this.captureOutput);
				if (this.captureOutput)
				{
				trace (line);
					output = output + line + "\n";
				}

				// For now if I try read stderr, it will read past all of the stdout output.
				// I need some way to test if either are present, and read whichever is present...
				//stderrLine = proc.stderr.readLine();
				//searchForMatch(stderrLine);
			}
		}
		catch (e:haxe.io.Eof)
		{
			// the program has finished executing, so return false - this will break the for loop.
			this.processingStatus = PROCESSING_STATUS.finished;
			hasNext = false;
    	}
		
		return hasNext;
	}

	// this function will only return the first match, I think... will not work for lines that match multiple times.
	private function searchForMatch(line:String):Null<Result>
	{
		var result:Null<Result> = null;

		for (expectation in eregExpectations)
		{
			if (expectation.expression.match(line))
			{
				result = {
					name : expectation.name,
					match : expectation.expression.matched(0),
					line : line,
					regex : expectation.expression
				};
				break;
			}
		}

		for (expectation in exactExpectations)
		{
			if (line.indexOf(expectation.string) > -1)
			{
				result = {
					name : expectation.name,
					match : expectation.string,
					line : line,
					regex : null
				};
				break;
			}
		}

		return result;
	}

	public function next():Result
	{
		return currentResult;
	}

	private function beginProcessing()
	{
		trace (cmd + " " + args.join(" "));
		proc = new Process(cmd, args);
		this.processingStatus = PROCESSING_STATUS.started;
	}

	private function setCaptureOutput(capture:Bool)
	{
		this.captureOutput = capture;
		if (capture)
		{
			output = "";
		}
		else
		{
			output = "To capture output please set 'captureOutput' to true before running the loop.";
		}
		return capture;
	}

}

enum PROCESSING_STATUS {
	not_processing;
	started;
	finished;
}

enum STREAM {
	stdout;
	stderr;
}

typedef EregExpectation =
{
	var name:String;
	var expression:EReg;
}

typedef ExactExpectation =
{
	var name:String;
	var string:String;
}

typedef Result =
{
	var name:String;
	var match:String;
	var line:String;
	var regex:EReg;
}