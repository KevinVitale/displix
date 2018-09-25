### Getting resolutions
```bash
$ ./displix
Display count: 1
--	--	--
DISPLAY: 0
	ID:	2077750269
	Modes:	12
	-----	-----	------
	Index	Width	Height
	-----	-----	------
	[0] 	2880	1800
	[1] 	1440	900
	[2] 	3360	2100
	[3] 	2560	1600
	[4] 	2048	1280
	[5] 	1650	1050
	[6] 	1280	800
	[7] 	1152	720
	[8] 	1024	768
	[9] 	840	524
	[10] 	800	600
	[11] 	640	480
```

**NOTE**: Use `-a` to include duplicate, low resolution modes.

### Setting resolutions
Use `-m #`, where `#` is the index of the display mode you want to set:

```bash
$ ./displix -m 0
Display count: 1
	[0] 	2880	1800
```

**NOTE**: Use `-d #` to specify the display, where `#` is the display 
index printed by `displix`.

<hr />

#### How to build
```bash
$ make
```

#### Cleaning
```bash
$ make clean
```

