#!/bin/bash
cd $(dirname "$0")
sass -C natty.scss ../natty.css
postcss --use autoprefixer -o ../natty.css ../natty.css
