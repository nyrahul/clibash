clibash is a tool for creating CLI applications based on bash script.

Think of it as a [cobra](https://github.com/spf13/cobra) for bash CLI applications. To use Cobra you need to use golang. What if one needs to write a cli tool using bash script.

# cli tool generator for bash

```
.
├── cloud
│   └── handler.sh
├── image
│   ├── handler.sh
│   ├── list
│   │   ├── handler.sh
│   │   └── temp
│   │       └── handler.sh
│   └── scan
│       └── handler.sh
└── version
    └── handler.sh
```

Based on the above folder structure, a single-script cli tool is generated which has options based on the given tree structure.

The generated cli tool (for e.g., `mycli`) will have following structure:
```
❯ ./mycli
./mycli [cloud image image_list image_list_temp image_scan version]
cloud [options]
      --label | -l: Assets with label
      --period | -p: Time period for which the assets should be shown
image [options]
      --label  | -l: Assets with label
      --period | -p: Time period for which the assets should be shown
image list [options]
      --filter | -f: image list filters
      --label  | -l: image assets with label
image list temp [options]
      --filter | -f: image list filters
      --label  | -l: image assets with label
image scan [options]
      --spec | -s: Images to be scanned (regex can be specified)
```

To add new commands, just add the folder at a given level and add a `handler.sh` file that handles the given command.
