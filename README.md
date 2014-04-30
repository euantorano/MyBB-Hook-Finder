# MyBB Hook Finder

Locate hooks within MyBB including arguments passed to the hook and the file/line the hook is called in/on.

## Running this script

This script should be ran via the command line like so:

```bash
chmod +x src/mybb_hook_finder.rb
./src/mybb_hook_finder.rb
```

### Options

You can optionally pass a few options into the script when running it via command line. You can view details of the available options at any time by passing the -h flag:

```bash
./src/mybb_hook_finder.rb -h
```

This will detail all available options such as below:

```
	Usage: mybb_hook_finder.rb [options]
		-p, --path PATH                  Specify a path to the MyBB root. Defaults to current directory.
		-o, --output FILE                Specify an output file. Defaults to output.html.
		-n, --nogroup                    Don't group hooks by file.
		-h, --help                       Display this help screen
```

If you do not pass any arguments to the script, it will run ony any and all PHP scripts in the current directory and it's children and will store the output in ```src/output.html```.
