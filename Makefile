SHELL = /bin/bash

css_dir   = public/style
sass_dest = $(css_dir)/natty.css

js_url = /js
js_dir = public$(js_url)
js_cat = awk 'BEGINFILE { printf "/* %s */;\n", FILENAME } { print } ENDFILE { print "" }'

all: static draw

static: css js

css:
	sass --sourcemap=none $(css_dir)/src/natty.scss $(sass_dest)
	postcss --use autoprefixer -o $(sass_dest) $(sass_dest)
	cat $(css_dir)/vendor/{normalize,font,toastr}*.css > $(css_dir)/vendor.css

js: js-cat js-min

js-cat:
	$(js_cat) $(js_dir)/vendor/*.js > $(js_dir)/vendor.js
	$(js_cat) $(js_dir)/src/lib/*.js $(js_dir)/src/*.js > $(js_dir)/natty.js
	sed -i '1s;^;"use strict"\;\n\n;' $(js_dir)/natty.js

js-min:
	uglifyjs --compress --mangle --screw-ie8 -p relative \
	         --output         $(js_dir)/natty.min.js \
	         --source-map     $(js_dir)/natty.min.js.map \
	         --source-map-url       $(js_url)/natty.min.js.map \
	                          $(js_dir)/natty.js

draw:
	gcc -Wall -lm -o bin/draw lib/Natty/draw.c
